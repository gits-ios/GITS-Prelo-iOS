//
//  TawarViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/7/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Crashlytics

// MARK: - Protocol

protocol  TawarItem {
    var itemName : String {get}
    var itemId : String {get}
    var productImage : NSURL {get}
    var title : String {get}
    var price : String {get} // Original product price
    var myId : String {get}
    var myImage : NSURL {get}
    var myName : String {get}
    var theirId : String {get}
    var theirImage : NSURL {get}
    var theirName : String {get}
    var opIsMe : Bool {get} // True if user is buyer
    var threadId : String {get}
    var threadState : Int {get}
    var bargainPrice : Int {get} // Current bargain price
    var bargainerIsMe : Bool {get}
    var productStatus : Int {get}
    var finalPrice : Int {get} // Final price after bargain accept/reject
    var markAsSoldTo : String {get}
    
    func setBargainPrice(price : Int)
    func setFinalPrice(price : Int)
}

// MARK: - Protocol

protocol TawarDelegate {
    func tawarNeedReloadList()
}

// MARK: - Class

class TawarViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIScrollViewDelegate, MessagePoolDelegate, UserRelatedDelegate {

    // MARK: - Properties
    
    // Outlets
    @IBOutlet var tableView : UITableView!
    @IBOutlet var loadingPanel: UIView!
    // Outlets in header section
    @IBOutlet var header : TawarHeader!
    @IBOutlet var conMarginHeightOptions : NSLayoutConstraint!
    @IBOutlet var btnTawar1 : UIButton!
    @IBOutlet var btnTawar2 : UIButton!
    @IBOutlet var btnBeli : UIButton!
    @IBOutlet var btnBatal : UIButton!
    @IBOutlet var btnTolak : UIButton!
    @IBOutlet var btnTolak2 : UIButton!
    @IBOutlet var btnConfirm : UIButton!
    @IBOutlet var btnSold: UIButton!
    @IBOutlet var btnBeliSold: UIButton!
    // Outlets in chat field section
    @IBOutlet var btnSend : UIButton!
    @IBOutlet var textView : UITextView!
    @IBOutlet var conMarginBottom : NSLayoutConstraint!
    @IBOutlet var conHeightTextView : NSLayoutConstraint!
    // Outlets in tawar pop up
    @IBOutlet var txtTawar : UITextField!
    @IBOutlet var captionTawarHargaOri : UILabel!
    @IBOutlet var sectionTawar : UIView!
    @IBOutlet var conMarginBottomSectionTawar : NSLayoutConstraint!
    
    // Grow handler
    var textViewGrowHandler : GrowingTextViewHandler!
    
    // Delegate
    var tawarDelegate : TawarDelegate?
    
    // Predefined values
    var tawarItem : TawarItem! // inboxId is defined here
    var prodId : String = "" // Product ID
    var loadInboxFirst = false // True when inboxId is not defined yet
    var fromSeller = false // True when seller starts the conversation
    var toId = "" // Opposite's user ID, used for fromSeller mode
    
    // Data container
    var inboxMessages : [InboxMessage] = []
    var prodStatus : Int? // Product status
    var threadState = -10
    var chats : Array<DummyChat> = []
    
    // Flags
    var isScrollToBottom = true
    var isShowLogin = true
    var tawarFromMe = false // True if user is currently bargaining
    var starting = false // True if currently sending start chat API
    var isShowBubble = true // True if should show yellow bubble
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        self.title = tawarItem.theirName

        // Init textViewGrowHandler
        textViewGrowHandler = GrowingTextViewHandler(textView: textView, withHeightConstraint: conHeightTextView)
        textViewGrowHandler.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 4)
        
        // Loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        self.hideLoading()
        
        // Set product status
        self.prodStatus = tawarItem.productStatus
        
        // Set isShowBubble
        if (self.prodStatus > 1) { // Product is sold
            if (!self.tawarItem.opIsMe) { // I am seller
                isShowBubble = false
            } else { // I am buyer
                if (tawarItem.markAsSoldTo != User.Id) {
                    isShowBubble = false
                }
            }
        }
        
        // Init header
        header.captionProductName.text = tawarItem.itemName
        if (tawarItem.bargainPrice != 0 && tawarItem.threadState == 2) {
            let p = tawarItem.price
            header.captionPrice.text = tawarItem.bargainPrice.asPrice
            header.captionOldPrice.text = tawarItem.price
            captionTawarHargaOri.text = "Harga asli " + p
        } else {
            header.captionPrice.text = tawarItem.price
            header.captionOldPrice.text = ""
            captionTawarHargaOri.text = "Harga asli " + tawarItem.price
        }
        // Username in header
        if (tawarItem.opIsMe) { // If I am buyer
            header.captionUsername.text = tawarItem.theirName
        } else { // If I am seller
            header.captionUsername.text = tawarItem.myName
        }
        // Product image
        header.ivProduct.setImageWithUrl(tawarItem.productImage, placeHolderImage: nil)
        
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        
        // Init chat field section
        textViewDidChange(textView)
        textView.delegate = self
        
        // Buttons action setup
        btnTawar1.addTarget(self, action: #selector(TawarViewController.showTawar(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        btnTawar2.addTarget(self, action: #selector(TawarViewController.showTawar(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        btnTolak.addTarget(self, action: #selector(TawarViewController.rejectTawar(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        btnTolak2.addTarget(self, action: #selector(TawarViewController.rejectTawar(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        btnConfirm.addTarget(self, action: #selector(TawarViewController.confirmTawar(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        btnSold.addTarget(self, action: #selector(TawarViewController.markAsSold), forControlEvents: UIControlEvents.TouchUpInside)
        
        // Setup messages
        if (User.IsLoggedIn) {
            firstSetup()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.InboxDetail)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.InboxDetail)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Keyboard animation handling
        self.an_subscribeKeyboardWithAnimations({ frame, interval, opening in
            if (opening) {
                self.conMarginBottom.constant = frame.height
                self.conMarginBottomSectionTawar.constant = frame.height
            } else {
                self.conMarginBottom.constant = 0
                self.conMarginBottomSectionTawar.constant = 0
            }
        }, completion: nil)
        
        // Show login page if user is not logged in
        if (!User.IsLoggedIn && isShowLogin) {
            isShowLogin = false
            LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove messagepool delegate
        if let del = UIApplication.sharedApplication().delegate as? AppDelegate {
            del.messagePool?.removeDelegate(tawarItem.threadId)
        } else {
            let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
            Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"TawarScreen"])
        }
        
        // Remove keyboard handling
        self.an_unsubscribeKeyboard()
    }
    
    func firstSetup() {
        if (loadInboxFirst) {
            getInbox()
        } else {
            if (tawarItem.threadId != "") {
                tawarFromMe = tawarItem.bargainerIsMe
                getMessages()
            }
        }
        adjustButtons()
    }
    
    func getInbox() {
        self.tableView.hidden = true
        
        request(APIInbox.GetInboxByProductID(productId: prodId)).responseJSON { resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Get Inbox By Product ID")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                let i = Inbox(jsn: data)
                //print(data)
                if (i.itemId != "") {
                    self.tawarItem = i
                }
                self.tawarFromMe = self.tawarItem.bargainerIsMe
                self.adjustButtons()
                self.getMessages()
                //print(res)
            }
            self.tableView.hidden = false
        }
    }
    
    func getMessages() {
        inboxMessages.removeAll(keepCapacity: false)
        
        var api = APIInbox.GetInboxMessage(inboxId: tawarItem.threadId)
        if (fromSeller) {
            api = APIInbox.GetInboxByProductIDSeller(productId: tawarItem.threadId, buyerId: toId)
        }
        // API Migrasi
        request(api).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Chat")) {
                
                // Obtain inbox messages
                let json = JSON(resp.result.value!)
                if let arr = json["_data"]["messages"].array {
                    if (arr.count > 0) {
                        for i in 0...arr.count-1 {
                            self.inboxMessages.append(InboxMessage(msgJSON: arr[i]))
                        }
                    }
                }
                
                // Obtain product status and adjust buttons
                if (json["_data"]["product_status"].int != nil) {
                    self.prodStatus = json["_data"]["product_status"].int!
                    self.adjustButtons()
                }
                
                // Reload table
                self.tableView.reloadData()
                
                // Scroll to bottom for once, when user just open chat page
                if (self.isScrollToBottom) {
                    self.isScrollToBottom = false
                    self.scrollWithInterval(0.4)
                }
                
                // Register delegate for messagepool socket
                if let del = UIApplication.sharedApplication().delegate as? AppDelegate {
                    del.messagePool?.registerDelegate(self.tawarItem.threadId, d: self)
                } else {
                    let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"MessagePool 2"])
                }
                
                /* FOR TESTING
                if (AppTools.IsPreloProduction == false) {
                    self.sendDummy()
                }*/
            }
        }
    }
    
    func adjustButtons() {
        // threadState = 0, means default state (no one is bargaining)
        // threadState = 1, means someone is currently bargaining
        // threadState = 2, means bargain is accepted, back to default state
        // threadState = 3, means bargain is rejected, back to default state
        // Make sure threadState is defined
        if (threadState == -10) { // If threadState is undefined
            threadState = tawarItem.threadState
        }
        
        // Hide all buttons first
        btnTawar1.hidden = true
        btnTawar2.hidden = true
        btnBeli.hidden = true
        btnBatal.hidden = true
        btnTolak.hidden = true
        btnTolak2.hidden = true
        btnConfirm.hidden = true
        btnSold.hidden = true
        btnBeliSold.hidden = true
        
        // Set header height
        if (tawarItem.opIsMe) { // I am buyer
            if (self.prodStatus == 1) { // Product isn't sold
                self.conMarginHeightOptions.constant = 114
            } else { // Product is sold
                if (tawarItem.markAsSoldTo == User.Id) { // Mark as sold to me
                    self.conMarginHeightOptions.constant = 114
                } else {
                    self.conMarginHeightOptions.constant = 80
                    return
                }
            }
        } else { // I am seller
            if (self.prodStatus == 1) { // Product isn't sold
                if (threadState == 0 || threadState == 2 || threadState == 3) { // No one is bargaining
                    self.conMarginHeightOptions.constant = 149
                } else if (threadState == 1) { // Someone is bargaining
                    self.conMarginHeightOptions.constant = 114
                }
            } else { // Product is sold
                self.conMarginHeightOptions.constant = 80
                return
            }
        }
        
        // Arrange buttons
        if (self.prodStatus != 1) { // Product is sold
            if (tawarItem.opIsMe && tawarItem.markAsSoldTo == User.Id) { // I am buyer & mark as sold to me
                btnBeliSold.hidden = false
            }
        } else { // Product isn't sold
            if (threadState == 0 || threadState == 2 || threadState == 3) { // No one is bargaining
                if (tawarItem.opIsMe) { // I am buyer
                    btnTawar1.hidden = false
                    btnBeli.hidden = false
                } else { // I am seller
                    btnTawar2.hidden = false
                    btnSold.hidden = false
                }
            } else if (threadState == 1) { // Someone is bargaining
                if (tawarFromMe) { // I am bargaining
                    if (tawarItem.opIsMe) { // I am buyer
                        btnTolak2.hidden = false
                    } else { // I am seller
                        btnTolak2.hidden = false
                    }
                } else { // Other is bargaining
                    btnTolak.hidden = false
                    btnConfirm.hidden = false
                }
            }
        }
        
        // Setup price in header and bargain pop up
        if (tawarItem.finalPrice > 0 && tawarItem.finalPrice.asPrice != tawarItem.price) { // Accepted bargain
            header.captionPrice.text = tawarItem.finalPrice.asPrice
            header.captionOldPrice.text = tawarItem.price
            captionTawarHargaOri.text = "Harga asli " + tawarItem.price
        } else {
            let p = tawarItem.price
            header.captionPrice.text = p
            header.captionOldPrice.text = ""
            captionTawarHargaOri.text = "Harga asli " + tawarItem.price
        }
    }
    
    // MARK: - Textview functions
    
    func textViewDidChange(textView: UITextView) {
        textViewGrowHandler.resizeTextViewWithAnimation(true)
        if (textView.text == "") {
            btnSend.setBackgroundImage(AppToolsObjC.imageFromColor(UIColor.grayColor()), forState: .Normal)
            btnSend.userInteractionEnabled = false
        } else {
            btnSend.setBackgroundImage(AppToolsObjC.imageFromColor(UIColor(hexString: "#25A79D")), forState: .Normal)
            btnSend.userInteractionEnabled = true
        }
    }
    
    // MARK: - Tableview functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inboxMessages.count + (isShowBubble ? 1 : 0)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if (indexPath.row == 0 && isShowBubble) { // Bubble cell
            let cell = tableView.dequeueReusableCellWithIdentifier("bubble") as! TawarBubbleCell
            cell.selectionStyle = .None
            if (self.tawarItem.opIsMe) { // I am buyer
                let attrStr = NSMutableAttributedString(string: "Kamu bisa bertransaksi langsung dengan penjual tanpa jaminan atau klik BELI untuk bertransaksi 100% aman dengan rekening bersama Prelo")
                cell.lblText.attributedText = attrStr
                cell.lblText.boldSubstring("klik BELI")
                cell.lblText.setSubstringColor("rekening bersama Prelo", color: Theme.PrimaryColor)
            } else { // I am seller
                let attrStr = NSMutableAttributedString(string: "Klik MARK AS SOLD jika barang sudah dibeli oleh \(self.tawarItem.theirName)")
                cell.lblText.attributedText = attrStr
                cell.lblText.boldSubstring("MARK AS SOLD")
                cell.lblText.setSubstringColor(self.tawarItem.theirName, color: Theme.PrimaryColor)
            }
            return cell
        } else { // Chat cell
            let m = inboxMessages[indexPath.row - (isShowBubble ? 1 : 0)]
            let id = m.isMe ? "me" : "them"
            let cell = tableView.dequeueReusableCellWithIdentifier(id) as! TawarCell
            
            cell.inboxMessage = m
            cell.decor()
            
            if (!m.isMe) {
                cell.avatar.setImageWithUrl(tawarItem.theirImage, placeHolderImage: nil)
            }
            
            cell.toShopPage = {
                self.gotoShopPage(0)
            }
            
            cell.selectionStyle = .None
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if (indexPath.row == 0 && isShowBubble) { // Bubble cell
            if (self.tawarItem.opIsMe) { // I am buyer
                return 106
            } else { // I am seller
                return 74
            }
        } else { // Chat cell
            let chat = inboxMessages[indexPath.row - (isShowBubble ? 1 : 0)]
            var m = chat.dynamicMessage
            if (chat.failedToSend) {
                m = "[GAGAL MENGIRIM]\n\n" + m
            }
            
            var w : CGFloat = 204
            
            if (chat.isMe) {
                w = (UIScreen.mainScreen().bounds.width - 28) * 0.75
            } else {
                w = (UIScreen.mainScreen().bounds.width - 72) * 0.75
            }
            
            let s = m.boundsWithFontSize(UIFont.systemFontOfSize(14), width: w)
            return 57 + s.height
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if (indexPath.row == 0 && isShowBubble) { // Bubble cell
            isShowBubble = false
            tableView.reloadData()
        } else { // Chat cell
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            self.view.endEditing(true)
        }
    }
    
    func scrollWithInterval(intrvl : NSTimeInterval) {
        NSTimer.scheduledTimerWithTimeInterval(intrvl, target: self, selector: #selector(TawarViewController.scrollToBottom), userInfo: nil, repeats: false)
    }
    
    func scrollToBottom() {
        if (inboxMessages.count > 0) {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: inboxMessages.count - 1 + (isShowBubble ? 1 : 0), inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
        }
    }
    
    // MARK: - Scrollview functions
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    // MARK: - Chat actions
    
    @IBAction func addChat(sender : UIView?) {
        if (tawarItem.threadId == "") {
            startNew(0, message : textView.text)
            return
        }
        
        let m = textView.text
        if (m == "") {
            return
        }
        
        sendChat(0, message: m)
        textViewGrowHandler.setText("", withAnimation: true)
        
        textViewDidChange(textView)
    }
    
    func sendChat(type : Int, message : String) {
        // type
        // 0: normal chat
        // 1: bargain
        // 2: confirm bargain
        // 3: reject bargain
        // 4: mark as sold
        
        // Set tawarFromMe
        if (type == 1) {
            tawarFromMe = true
        } else if (type != 0) {
            tawarFromMe = false
        }
        
        // Append inboxMessages
        let localId = inboxMessages.count
        let date = NSDate()
        let f = NSDateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let time = f.stringFromDate(date)
        let i = InboxMessage.messageFromMe(localId, type: type, message: message, time: time)
        if (type != 0) {
            i.bargainPrice = message
            
            // fix : Kalau tawaran diterima, tulisannya "0" di hape sendiri, tapi di hape lawan sih tulisannya "terima tawaran RpX" (kadang) (https://trello.com/c/W3Oajm96)
            // kemungkinan karna ini, awal nya gak ada if (type == 1), jadi bisa aja waktu type 2 atau 3, dia ke set bargainprice nya 0, walaupun gak bisa ku reproduce
            if (type == 1) {
                tawarItem.setBargainPrice(message.int)
            }
        }
        inboxMessages.append(i)
        
        // Reset textview
        self.textView.text = ""
        
        // Change threadState
        if (type != 0) { // Kalo type = 0 gak ada arti apapun, gak perlu rubah state.
            threadState = type
        }
        
        // Reload tawar list
        if let t = tawarItem as? Inbox {
            t.forceThreadState = threadState
            self.tawarDelegate?.tawarNeedReloadList()
        }
        
        // Send message
        i.sendTo(tawarItem.threadId, completion: { m in
            self.adjustButtons()
            self.tableView.reloadData()
        })
        
        self.adjustButtons()
        self.tableView.reloadData()
        self.scrollToBottom()
    }
    
    func startNew(type : Int, message : String) {
        // Make sure this is executed once
        if (starting) {
            return
        }
        self.starting = true
        
        var api = APIInbox.StartNewOne(productId: prodId, type: type, message: message)
        if (fromSeller) {
            api = APIInbox.StartNewOneBySeller(productId: prodId, type: type, message: message, toId: toId)
        }
        request(api).responseJSON { resp in
            self.starting = false
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Chat")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                let inbox = Inbox(jsn: data)
                self.tawarItem = inbox
                
                let localId = self.inboxMessages.count
                let date = NSDate()
                let f = NSDateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                let time = f.stringFromDate(date)
                let i = InboxMessage.messageFromMe(localId, type: type, message: message, time: time)
                self.inboxMessages.append(i)
                self.textView.text = ""
                self.adjustButtons()
                self.tableView.reloadData()
                self.scrollToBottom()
                
                // Register to messagePool
                if let del = UIApplication.sharedApplication().delegate as? AppDelegate {
                    del.messagePool?.registerDelegate(self.tawarItem.threadId, d: self)
                } else {
                    let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"MessagePool 3"])
                }
            } else {
                print(resp.result.error)
            }
        }
    }
    
    // Helper untuk simulate ada message masuk
    func sendDummy(type : Int = 0, message : String = "DUMMY", delay : NSTimeInterval = 3)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            NSThread.sleepForTimeInterval(delay)
            dispatch_async(dispatch_get_main_queue(), {
                let i = InboxMessage()
                i.senderId = self.tawarItem.theirId
                i.messageType = type
                i.message = message
                i.isMe = i.senderId == CDUser.getOne()?.id
                i.time = ""
                i.id = ""
                self.messageArrived(i)
            })
        })
    }
    
    // MARK: - Tawar pop up
    
    @IBAction func showTawar(sender : UIView?) {
        sectionTawar.hidden = false
        txtTawar.becomeFirstResponder()
    }
    
    @IBAction func hideTawar(sender : UIView?) {
        sectionTawar.hidden = true
        txtTawar.resignFirstResponder()
    }
    
    @IBAction func sendTawar(sender : UIView?) {
        guard txtTawar.text != nil else {
            return
        }
        
        let tawarRegex = "^[0-9]*$"
        if (txtTawar.text == "" || txtTawar.text!.match(tawarRegex) == false) {
            Constant.showDialog("Masukkan hanya angka penawaran", message: "Contoh: 150000")
        } else {
            let m = txtTawar.text!.int
            if (m < 1000) {
                Constant.showDialog("Tawar", message: "Mungkin maksud anda " + m.asPrice + "0")
                return
            }
            self.hideTawar(nil)
            if (tawarItem.threadId == "") {
                startNew(1, message : txtTawar.text!)
            } else {
                sendChat(1, message: txtTawar.text!)
            }
            txtTawar.text = ""
            btnTawar1.hidden = true
            btnTawar2.hidden = true
            self.tawarItem.setBargainPrice(m)
        }
    }
    
    func rejectTawar(sender : UIView?) {
        var message = String(tawarItem.bargainPrice)
        if (tawarFromMe) {
            message = "Membatalkan tawaran " + tawarItem.bargainPrice.asPrice
        }
        sendChat(3, message: message)
    }
    
    func confirmTawar(sender : UIView?) {
        sendChat(2, message : String(tawarItem.bargainPrice))
        if (tawarItem.bargainPrice != 0) {
            self.tawarItem.setFinalPrice(self.tawarItem.bargainPrice)
        }
    }
    
    // MARK: - Message pool delegate functions
    
    func messageArrived(message: InboxMessage) {
        inboxMessages.append(message)
        if (message.messageType != 0) {
            threadState = message.messageType
        }
        if let t = tawarItem as? Inbox {
            t.forceThreadState = threadState
            self.tawarDelegate?.tawarNeedReloadList()
        }
        if (message.messageType == 1) {
            self.tawarItem.setBargainPrice(message.message.int)
            if (threadState == 1 && message.isMe == true) {
                tawarFromMe = true
            } else {
                tawarFromMe = false
            }
        } else if (message.messageType == 2) {
            if (tawarItem.bargainPrice != 0) {
                self.tawarItem.setFinalPrice(self.tawarItem.bargainPrice)
            }
        } else if (message.messageType == 4) {
            self.prodStatus = 2
        }
        
        if (threadState == 1) {
            tawarItem.setBargainPrice(message.message.int)
        }
        
        self.tableView.reloadData()
        self.adjustButtons()
        self.scrollToBottom()
    }
    
    // MARK: - User related delegate functions
    
    func userLoggedIn() {
        firstSetup()
    }
    
    func userLoggedOut() {
        
    }
    
    func userCancelLogin() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - Navigation
    
    @IBAction func gotoProduct(sender: AnyObject) {
        if (tawarItem.itemId != "") {
            request(Products.Detail(productId: tawarItem.itemId)).responseJSON { resp in
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Detail Barang")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    let p = Product.instance(data)
                    let productDetailVC = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                    productDetailVC.product = p!
                    self.navigationController?.pushViewController(productDetailVC, animated: true)
                }
            }
        }
    }
    
    @IBAction func gotoShopPage(sender: AnyObject) {
        if (tawarItem.theirId != "") {
            let shopPage = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
            shopPage.storeMode = true
            shopPage.storeId = tawarItem.theirId
            self.navigationController?.pushViewController(shopPage, animated: true)
        }
    }
    
    @IBAction func beli(sender : UIView?) {
        var success = true
        if (CartProduct.getOne(tawarItem.itemId, email: User.EmailOrEmptyString) == nil) {
            if (CartProduct.newOne(tawarItem.itemId, email : User.EmailOrEmptyString, name : tawarItem.itemName) == nil) {
                success = false
                Constant.showDialog("Failed", message: "Gagal Menyimpan")
            }
        }
        
        if (success) {
            self.performSegueWithIdentifier("segCart", sender: nil)
        }
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loadingPanel.hidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.hidden = true
    }
    
    func markAsSold() {
        let alert : UIAlertController = UIAlertController(title: "Mark As Sold", message: "Apakah barang ini sudah dibeli dan diterima oleh pembeli? (Aksi ini tidak bisa dibatalkan)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Batal", style: .Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Ya", style: .Default, handler: { action in
            self.prodStatus = 2
            Constant.showDialog("Success", message: "Barang telah ditandai sebagai barang terjual")
            var finalPrice = ""
            if (self.tawarItem.bargainPrice != 0 && self.tawarItem.threadState == 2) {
                finalPrice = self.tawarItem.bargainPrice.asPrice
            } else {
                finalPrice = self.tawarItem.price
            }
            self.sendChat(4, message: "Barang ini dijual kepada \(self.tawarItem.theirName) dengan harga \(finalPrice)")
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func randomElementIndex<T>(s: Set<T>) -> T {
        let n = Int(arc4random_uniform(UInt32(s.count)))
        let i = s.startIndex.advancedBy(n)
        return s[i]
    }
    
    func sendMixpanelEvent(eventName : String) {
        let pt = [
            "Product Name" : tawarItem.itemName,
            "Category 1" : "",
            "Category 2" : "",
            "Category 3" : "",
            "Buyer Name" : (tawarItem.opIsMe ? tawarItem.myName : tawarItem.theirName),
            "Seller Name" : (tawarItem.opIsMe ? tawarItem.theirName : tawarItem.myName),
            "Is Seller" : !tawarItem.opIsMe
        ]
        Mixpanel.trackEvent(eventName, properties: pt as [NSObject : AnyObject])
    }
}

// MARK: - Class

class TawarCell : UITableViewCell {
    @IBOutlet var avatar : UIImageView!
    @IBOutlet var captionMessage : UILabel!
    @IBOutlet var captionArrow : UILabel!
    @IBOutlet var captionTime : KDEDateLabel!
    @IBOutlet var sectionMessage : UIView!
    @IBOutlet var captionSending : UILabel?
    @IBOutlet var btnRetry : UIButton?
    
    var inboxMessage : InboxMessage?
    
    let formatter = NSDateFormatter()
    var formattedLongTime : String?
    
    var decorated = false
    
    var toShopPage : () -> () = {}
    
    func decor(){
        if (decorated == false) {
            formatter.dateFormat = "dd MMM"
            self.avatar.layer.cornerRadius = self.avatar.width / 2
            self.avatar.layer.masksToBounds = true
            self.sectionMessage.layer.cornerRadius = 4
            self.sectionMessage.layer.masksToBounds = true
            decorated = true
            
            self.captionTime.dateFormatTextBlock = { (date) in
                return date.relativeDescription
            }
        }
        
        if let m = inboxMessage {
            if (m.isMe) {
                self.sectionMessage.backgroundColor = Theme.PrimaryColor
                self.captionMessage.textColor = UIColor.whiteColor()
            } else {
                self.sectionMessage.backgroundColor = UIColor(hexString: "#E8ECEE")
                self.captionMessage.textColor = UIColor.darkGrayColor()
            }
            
            self.btnRetry?.hidden = true
            self.captionSending?.hidden = true
            
            if (m.failedToSend) {
                self.captionMessage.text = "[GAGAL MENGIRIM]\n\n" + m.message
                self.captionMessage.textColor = UIColor.whiteColor()
                self.sectionMessage.backgroundColor = UIColor(hexString : "#AC281C")
                self.btnRetry?.hidden = false
            } else {
                self.captionMessage.text = m.dynamicMessage
            }
            
            if (m.sending) {
                self.captionSending?.hidden = false
                self.captionTime.text = "sending..."
            } else {
                self.captionTime.date = m.dateTime
            }
            
            if (m.messageType == 1) {
                self.sectionMessage.backgroundColor = Theme.ThemeOrage
                self.captionMessage.textColor = UIColor.whiteColor()
            }
            
            if (m.messageType == 3) {
                self.sectionMessage.backgroundColor = UIColor(hexString: "#E8ECEE")
                self.captionMessage.textColor = UIColor.darkGrayColor()
            }
            
            self.captionArrow.textColor = self.sectionMessage.backgroundColor
        }
    }
    
    @IBAction func resendMe(sender : UIView) {
        if let m = inboxMessage {
            m.resend()
            self.decor()
        }
    }
    
    @IBAction func gotoShopPage(sender: AnyObject) {
        self.toShopPage()
    }
}

// MARK: - Class

class TawarBubbleCell : UITableViewCell {
    @IBOutlet var lblText : UILabel!
}

// MARK: - Class

class TawarHeader : UIView {
    @IBOutlet var ivProduct : UIImageView!
    @IBOutlet var captionProductName : UILabel!
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var captionOldPrice : UILabel!
    @IBOutlet var captionUsername : UILabel!
    @IBOutlet var btnTawar : UIButton!
    @IBOutlet var btnTawarFull : UIButton!
    @IBOutlet var btnBeli : UIButton!
    @IBOutlet var btnBatal : UIButton!
}

// MARK: - Class

class DummyChat : NSObject {
    var message = ""
    var isMe = false
    
    init(m : String, me : Bool) {
        message = m
        isMe = me
    }
}
