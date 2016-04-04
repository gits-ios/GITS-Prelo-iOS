//
//  TawarViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/7/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

protocol  TawarItem
{
    var itemName : String {get}
    var itemId : String {get}
    var productImage : NSURL {get}
    var title : String {get}
    var price : String {get}
    var myId : String {get}
    var myImage : NSURL {get}
    var myName : String {get}
    var theirId : String {get}
    var theirImage : NSURL {get}
    var theirName : String {get}
    var opIsMe : Bool {get}
    var threadId : String {get}
    var threadState : Int {get}
    var bargainPrice : Int {get}
    var bargainerIsMe : Bool {get}
    var productStatus : Int {get}
    
    func setBargainPrice(price : Int)
}

protocol TawarDelegate
{
    func tawarNeedReloadList()
}

class TawarViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIScrollViewDelegate, MessagePoolDelegate, UserRelatedDelegate
{

    var tawarDelegate : TawarDelegate?
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var header : TawarHeader!
    @IBOutlet var btnSend : UIButton!
    @IBOutlet var textView : UITextView!
    @IBOutlet var conMarginBottom : NSLayoutConstraint!
    @IBOutlet var conHeightTextView : NSLayoutConstraint!
    var textViewGrowHandler : GrowingTextViewHandler!
    
    var prodId : String = ""
    var loadInboxFirst = false
    var tawarItem : TawarItem!
    var inboxMessages : [InboxMessage] = []
    var first = true
    var isAtBottom = false
    
    var prodStatus : Int?
    
    var fromSeller = false
    var toId = ""
    
    @IBOutlet var btnTawar1 : UIButton!
    @IBOutlet var btnTawar2 : UIButton!
    @IBOutlet var btnBeli : UIButton!
    @IBOutlet var btnBatal : UIButton!
    @IBOutlet var btnTolak : UIButton!
    @IBOutlet var btnTolak2 : UIButton!
    @IBOutlet var btnConfirm : UIButton!
    @IBOutlet var txtTawar : UITextField!
    @IBOutlet var captionTawarHargaOri : UILabel!
    @IBOutlet var sectionTawar : UIView!
    @IBOutlet var conMarginBottomSectionTawar : NSLayoutConstraint!
    @IBOutlet var conMarginHeightOptions : NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        textViewGrowHandler = GrowingTextViewHandler(textView: textView, withHeightConstraint: conHeightTextView)
        textViewGrowHandler.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 4)
        
        self.prodStatus = tawarItem.productStatus
        
        self.title = tawarItem.title
        header.captionProductName.text = tawarItem.itemName
        if (tawarItem.bargainPrice != 0 && tawarItem.threadState == 2)
        {
            let b = tawarItem.bargainPrice.asPrice
            let p = tawarItem.price
            header.captionPrice.text = tawarItem.bargainPrice.asPrice
            header.captionOldPrice.text = tawarItem.price
            captionTawarHargaOri.text = "Harga asli " + p
        } else
        {
            header.captionPrice.text = tawarItem.price
            header.captionOldPrice.text = ""
            captionTawarHargaOri.text = "Harga asli " + tawarItem.price
        }
        
        if (tawarItem.opIsMe)
        {
            header.captionUsername.text = tawarItem.theirName
        } else
        {
            header.captionUsername.text = tawarItem.myName
        }
        
        header.ivProduct.setImageWithUrl(tawarItem.productImage, placeHolderImage: nil)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        self.btnSend.userInteractionEnabled = false
        textView.delegate = self
        
        btnTawar1.addTarget(self, action: "showTawar:", forControlEvents: UIControlEvents.TouchUpInside)
        btnTawar2.addTarget(self, action: "showTawar:", forControlEvents: UIControlEvents.TouchUpInside)
        
        if (User.IsLoggedIn == true)
        {
            firstSetup()
        }
        
        textViewDidChange(textView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.InboxDetail)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.InboxDetail)
    }
    
    func firstSetup()
    {
        if (loadInboxFirst)
        {
            getInbox()
        } else
        {
            if (tawarItem.threadId != "")
            {
                tawarFromMe = tawarItem.bargainerIsMe
                getMessages()
            }
        }
        adjustButtons()
    }
    
    var threadState = -10
    var firstButton = true
    var tawarFromMe = false
    func adjustButtons()
    {
        println("prodStatus = \(self.prodStatus)")
        if (self.prodStatus != 1) // Jika produk sudah dibeli
        {
            btnTawar1.hidden = true
            btnTawar2.hidden = true
            btnBeli.hidden = true
            btnBatal.hidden = true
            btnTolak.hidden = true
            btnTolak2.hidden = true
            btnConfirm.hidden = true
            
            self.conMarginHeightOptions.constant = 80
            return
        } else {
            btnTawar1.hidden = false
            btnTawar2.hidden = false
            btnBeli.hidden = false
            btnBatal.hidden = false
            btnTolak.hidden = false
            btnTolak2.hidden = false
            btnConfirm.hidden = false
            
            self.conMarginHeightOptions.constant = 114
        }
        
        if (threadState == -10)
        {
            threadState = tawarItem.threadState
        }
        
        if (firstButton)
        {
            btnTolak.addTarget(self, action: "rejectTawar:", forControlEvents: UIControlEvents.TouchUpInside)
            btnTolak2.addTarget(self, action: "rejectTawar:", forControlEvents: UIControlEvents.TouchUpInside)
            btnConfirm.addTarget(self, action: "confirmTawar:", forControlEvents: UIControlEvents.TouchUpInside)
            firstButton = false
        }
        
        btnTawar1.hidden = true
        btnTawar2.hidden = true
        btnBeli.hidden = true
        btnBatal.hidden = true
        btnTolak.hidden = true
        btnTolak2.hidden = true
        btnConfirm.hidden = true
        
        if (threadState == 0 || threadState == 3)
        {
            if (tawarItem.opIsMe)
            {
                btnTawar1.hidden = false
                btnBeli.hidden = false
            } else
            {
                btnTawar2.hidden = false
            }
        } else if (threadState == 1)
        {
            if (tawarFromMe)
            {
                if (tawarItem.opIsMe)
                {
                    btnTolak2.hidden = false
//                    btnTawar1.hidden = false
//                    btnBeli.hidden = false
                } else
                {
                    btnTolak2.hidden = false
                }
            } else
            {
                btnTolak.hidden = false
                btnConfirm.hidden = false
            }
        } else if (threadState == 2)
        {
            if (tawarItem.opIsMe)
            {
                btnTawar1.hidden = false
                btnBeli.hidden = false
            } else
            {
                btnTawar2.hidden = false
//                btnTolak2.hidden = false
            }
        }
        
//        if (tawarItem.opIsMe == false && threadState != 1)
//        {
//            btnTawar1.hidden = true
//            btnBeli.hidden = true
//            btnTawar2.hidden = false
//        } else if (tawarItem.opIsMe == false && threadState == 1)
//        {
//            btnTawar1.hidden = false
//            btnBeli.hidden = false
//            btnTawar2.hidden = true
//        }
//        
//        if (threadState == 1) // udah di tawar
//        {
//            
//            if (tawarItem.opIsMe == false)
//            {
//                btnTawar1.hidden = true
//                btnBeli.hidden = true
//                
//                btnTolak.hidden = false
//                btnConfirm.hidden = false
//                
//            } else
//            {
//                btnTawar1.hidden = false
//                btnBeli.hidden = false
//                
//                btnTolak.hidden = true
//                btnConfirm.hidden = true
//            }
//        } else {
//            
//        }
        
        if (tawarItem.bargainPrice != 0 && threadState == 2)
        {
            header.captionPrice.text = tawarItem.bargainPrice.asPrice
            header.captionOldPrice.text = tawarItem.price
            captionTawarHargaOri.text = "Harga asli " + tawarItem.price
        } else
        {
            let p = tawarItem.price
            header.captionPrice.text = p
            header.captionOldPrice.text = ""
            captionTawarHargaOri.text = "Harga asli " + tawarItem.price
        }
    }
    
    var firstLogin = true
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.an_subscribeKeyboardWithAnimations({ frame, interval, opening in
            
            if (opening)
            {
                self.conMarginBottom.constant = frame.height
                self.conMarginBottomSectionTawar.constant = frame.height
            } else
            {
                self.conMarginBottom.constant = 0
                self.conMarginBottomSectionTawar.constant = 0
            }
            
            }, completion: {finish in
                
        })
        
        if (User.IsLoggedIn == false && firstLogin == true)
        {
            firstLogin = false
            // login
            LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let del = UIApplication.sharedApplication().delegate as! AppDelegate
        del.messagePool.removeDelegate(tawarItem.threadId)
        self.an_unsubscribeKeyboard()
    }
    
    func getInbox()
    {
        self.tableView.hidden = true
        request(APIInbox.GetInboxByProductID(productId: prodId)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Get Inbox By Product ID")) {}
            self.tableView.hidden = false
            let json = JSON(res!)
            let data = json["_data"]
            let i = Inbox(jsn: data)
            //println(data)
            if (i.itemId != "")
            {
                self.tawarItem = i
            }
            self.tawarFromMe = self.tawarItem.bargainerIsMe
            self.adjustButtons()
            self.getMessages()
            //println(res)
        }
    }
    
    func getMessages()
    {
        inboxMessages.removeAll(keepCapacity: false)
        var api = APIInbox.GetInboxMessage(inboxId: tawarItem.threadId)
        if (fromSeller)
        {
            api = APIInbox.GetInboxByProductIDSeller(productId: tawarItem.threadId)
        }
        request(api).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Chat"))
            {
                let json = JSON(res!)
                println(res)
                if let arr = json["_data"]["messages"].array
                {
                    if (arr.count > 0)
                    {
                        for i in 0...arr.count-1
                        {
                            self.inboxMessages.append(InboxMessage(msgJSON: arr[i]))
                        }
                    }
                }
                if (json["_data"]["product_status"].int != nil) {
                    self.prodStatus = json["_data"]["product_status"].int!
                    self.adjustButtons()
                }
                self.tableView.reloadData()
                if (self.first)
                {
                    self.first = false
                    self.scroll()
                }
                
                let del = UIApplication.sharedApplication().delegate as! AppDelegate
                del.messagePool.registerDelegate(self.tawarItem.threadId, d: self)
                
//                if (AppTools.IsPreloProduction == false)
//                {
//                    self.sendDummy()
//                }
                
            } else
            {
                
            }
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        textViewGrowHandler.resizeTextViewWithAnimation(true)
        if (textView.text == "")
        {
            btnSend.setBackgroundImage(AppToolsObjC.imageFromColor(UIColor.grayColor()), forState: .Normal)
            btnSend.userInteractionEnabled = false
        } else
        {
            btnSend.setBackgroundImage(AppToolsObjC.imageFromColor(UIColor(hex: "#25A79D")), forState: .Normal)
            btnSend.userInteractionEnabled = true
        }
    }
    
    @IBAction func beli(sender : UIView?)
    {
        var success = true
        if let x = CartProduct.getOne(tawarItem.itemId, email: User.EmailOrEmptyString)
        {
            
        } else
        {
            if (CartProduct.newOne(tawarItem.itemId, email : User.EmailOrEmptyString, name : tawarItem.itemName) == nil) {
                success = false
                Constant.showDialog("Failed", message: "Gagal Menyimpan")
            }
        }
        
        if (success)
        {
            self.performSegueWithIdentifier("segCart", sender: nil)
        }
    }
    
    @IBAction func showTawar(sender : UIView?)
    {
        sectionTawar.hidden = false
        txtTawar.becomeFirstResponder()
    }
    
    @IBAction func hideTawar(sender : UIView?)
    {
        sectionTawar.hidden = true
        txtTawar.resignFirstResponder()
    }
    
    @IBAction func sendTawar(sender : UIView?)
    {
        let tawarRegex = "^[0-9]*$"
        if (txtTawar.text == "" || txtTawar.text.match(tawarRegex) == false)
        {
            Constant.showDialog("Masukkan angka penawaran", message: "Contoh: 150000")
        } else
        {
            var m = txtTawar.text.int
            if (m < 1000)
            {
                Constant.showDialog("Tawar", message: "Mungkin maksud anda " + m.asPrice + "0")
                return
            }
            self.hideTawar(nil)
            if (tawarItem.threadId == "")
            {
                startNew(1, message : txtTawar.text)
            } else {
                sendChat(1, message: txtTawar.text)
            }
            txtTawar.text = ""
            btnTawar1.hidden = true
            btnTawar2.hidden = true
//            btnBatal.hidden = false
        }
        
        // Mixpanel
        self.sendMixpanelEvent(MixpanelEvent.Bargain)
    }
    
    func rejectTawar(sender : UIView?)
    {
        var message = String(tawarItem.bargainPrice)
        if (tawarFromMe)
        {
            message = "Membatalkan tawaran " + tawarItem.bargainPrice.asPrice
        }
        sendChat(3, message: message)
    }
    
    func confirmTawar(sender : UIView?)
    {
        sendChat(2, message : String(tawarItem.bargainPrice))
    }
    
    @IBAction func addChat(sender : UIView?)
    {
        if (tawarItem.threadId == "")
        {
            startNew(0, message : textView.text)
            return
        }
        
        var m = textView.text
        
        if (m == "")
        {
            return
        }
        
        sendChat(0, message: textView.text)
        textViewGrowHandler.setText("", withAnimation: true)
        
        // Mixpanel
        self.sendMixpanelEvent(MixpanelEvent.ChatSent)
        textViewDidChange(textView)
    }
    
    func sendChat(type : Int, message : String)
    {
        if (type == 1)
        {
            tawarFromMe = true
        } else if (type != 0)
        {
            tawarFromMe = false
        }
        let localId = inboxMessages.count
        let date = NSDate()
        let f = NSDateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        var time = f.stringFromDate(date)
        let i = InboxMessage.messageFromMe(localId, type: type, message: message, time: time)
        if (type != 0)
        {
            i.bargainPrice = message
            
            // fix : Kalau tawaran diterima, tulisannya "0" di hape sendiri, tapi di hape lawan sih tulisannya "terima tawaran RpX" (kadang) (https://trello.com/c/W3Oajm96)
            // kemungkinan karna ini, awal nya gak ada if (type == 1), jadi bisa aja waktu type 2 atau 3, dia ke set bargainprice nya 0, walaupun gak bisa ku reproduce
            if (type == 1)
            {
                tawarItem.setBargainPrice(message.int)
            }
        }
        inboxMessages.append(i)
        
        self.textView.text = ""
        
        if (type != 0) // type = 0 gak ada arti apapun, gak perlu rubah state.
        {
            threadState = type
        }
        
        if let t = tawarItem as? Inbox
        {
            t.forceThreadState = threadState
            self.tawarDelegate?.tawarNeedReloadList()
        }
        
        i.sendTo(tawarItem.threadId, completion: { m in
            self.adjustButtons()
            self.tableView.reloadData()
        })
        
        self.adjustButtons()
        self.tableView.reloadData()
        self.scrollToBottom()
    }
    
    func sendMixpanelEvent(eventName : String)
    {
        // FIXME: Category belum ada di balikan dari API
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
    
    var starting = false
    func startNew(type : Int, message : String)
    {
        if (starting)
        {
            return
        }
        self.starting = true
        var api = APIInbox.StartNewOne(productId: prodId, type: type, message: message)
        if (fromSeller)
        {
            api = APIInbox.StartNewOneBySeller(productId: prodId, type: type, message: message, toId: toId)
        }
        request(api).responseJSON { req, resp, res, err in
            println(res)
            self.starting = false
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Chat"))
            {
                let json = JSON(res!)
                let data = json["_data"]
                let inbox = Inbox(jsn: data)
                self.tawarItem = inbox
                
                let localId = self.inboxMessages.count
                let date = NSDate()
                let f = NSDateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                var time = f.stringFromDate(date)
                let i = InboxMessage.messageFromMe(localId, type: type, message: message, time: time)
                self.inboxMessages.append(i)
                self.textView.text = ""
                self.adjustButtons()
                self.tableView.reloadData()
                self.scrollToBottom()
                
                let del = UIApplication.sharedApplication().delegate as! AppDelegate
                del.messagePool.registerDelegate(self.tawarItem.threadId, d: self)
            } else
            {
                println(err)
            }
        }
    }
    
    func scroll()
    {
        NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "scrollToBottom", userInfo: nil, repeats: false)
    }
    
    func scrollToBottom()
    {
        if (inboxMessages.count > 0)
        {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: inboxMessages.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
        }
        self.isAtBottom = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var chats : Array<DummyChat> = []
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inboxMessages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let m = inboxMessages[indexPath.row]
        var id = m.isMe ? "me" : "them"
        var cell = tableView.dequeueReusableCellWithIdentifier(id) as! TawarCell
        
        cell.inboxMessage = m
        cell.decor()
        
        if (m.isMe)
        {
            
        } else
        {
            cell.avatar.setImageWithUrl(tawarItem.theirImage, placeHolderImage: nil)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let chat = inboxMessages[indexPath.row]
        var m = chat.dynamicMessage
        if (chat.failedToSend)
        {
            m = "[GAGAL MENGIRIM]\n\n" + m
        }
        
        var w : CGFloat = 204
        
        if (chat.isMe)
        {
            w = (UIScreen.mainScreen().bounds.width - 28) * 0.75
        } else
        {
            w = (UIScreen.mainScreen().bounds.width - 72) * 0.75
        }
        
        let s = m.boundsWithFontSize(UIFont.systemFontOfSize(14), width: w)
        return 57 + s.height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.view.endEditing(true)
    }
    
    var dragged = false
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        dragged = true
        self.view.endEditing(true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = scrollView.contentSize.height
        let contentYOffset = scrollView.contentOffset.y
        let distanceFromBottom = height - contentYOffset
        if (distanceFromBottom >= scrollView.height)
        {
            self.isAtBottom = false
        } else
        {
            self.isAtBottom = true
        }
    }
    
    // helper untuk simulate ada message masuk
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
    
    func messageArrived(message: InboxMessage) {
        inboxMessages.append(message)
        if (message.messageType != 0)
        {
            threadState = message.messageType
        }
        if let t = tawarItem as? Inbox
        {
            t.forceThreadState = threadState
            self.tawarDelegate?.tawarNeedReloadList()
        }
        if (message.messageType == 1)
        {
            if (threadState == 1 && message.isMe == true)
            {
                tawarFromMe = true
            } else
            {
                tawarFromMe = false
            }
        }
        
        if (threadState == 1)
        {
            tawarItem.setBargainPrice(message.message.int)
        } else if (threadState == 2)
        {
            
        }
        
        self.tableView.reloadData()
        self.adjustButtons()
        
        if (self.isAtBottom)
        {
            self.scrollToBottom()
        }
    }
    
    func userLoggedIn() {
        firstSetup()
    }
    
    func userLoggedOut() {
        
    }
    
    func userCancelLogin() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func randomElementIndex<T>(s: Set<T>) -> T {
        let n = Int(arc4random_uniform(UInt32(s.count)))
        let i = advance(s.startIndex, n)
        return s[i]
    }
}

class TawarCell : UITableViewCell
{
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
    func decor()
    {
        if (decorated == false)
        {
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
        
        if let m = inboxMessage
        {
            if (m.isMe)
            {
                self.sectionMessage.backgroundColor = Theme.PrimaryColor
                self.captionMessage.textColor = UIColor.whiteColor()
            } else
            {
                self.sectionMessage.backgroundColor = UIColor(hex: "#E8ECEE")
                self.captionMessage.textColor = UIColor.darkGrayColor()
            }
            
            self.btnRetry?.hidden = true
            self.captionSending?.hidden = true
            
            if (m.failedToSend)
            {
                self.captionMessage.text = "[GAGAL MENGIRIM]\n\n" + m.message
                self.captionMessage.textColor = UIColor.whiteColor()
                self.sectionMessage.backgroundColor = UIColor(hex : "#AC281C")
                self.btnRetry?.hidden = false
            } else
            {
                self.captionMessage.text = m.dynamicMessage
            }
            
            if (m.sending)
            {
                self.captionSending?.hidden = false
                self.captionTime.text = "sending..."
            } else {
                self.captionTime.date = m.dateTime
            }
            
            if (m.messageType == 1)
            {
                self.sectionMessage.backgroundColor = Theme.ThemeOrage
                self.captionMessage.textColor = UIColor.whiteColor()
            }
            
            if (m.messageType == 3)
            {
                self.sectionMessage.backgroundColor = UIColor(hex: "#E8ECEE")
                self.captionMessage.textColor = UIColor.darkGrayColor()
            }
            
            self.captionArrow.textColor = self.sectionMessage.backgroundColor
            
//            self.selectionStyle = UITableViewCellSelectionStyle.None
        }
    }
    
    @IBAction func resendMe(sender : UIView)
    {
        if let m = inboxMessage
        {
            m.resend()
            self.decor()
        }
    }
}

class TawarHeader : UIView
{
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

class DummyChat : NSObject
{
    var message = ""
    var isMe = false
    
    init(m : String, me : Bool)
    {
        message = m
        isMe = me
    }
}
