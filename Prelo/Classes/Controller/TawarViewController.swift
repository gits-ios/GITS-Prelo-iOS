//
//  TawarViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/7/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire
import MessageUI

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


// MARK: - Protocol

protocol  TawarItem {
    var itemName : String {get}
    var itemId : String {get}
    var productImage : URL {get}
    var title : String {get}
    var price : String {get} // Original product price
    var myId : String {get}
    var myImage : URL {get}
    var myName : String {get}
    var theirId : String {get}
    var theirImage : URL {get}
    var theirName : String {get}
    var opIsMe : Bool {get} // True if user is buyer
    var threadId : String {get}
    var threadState : Int {get}
    var bargainPrice : Int {get} // Current bargain price
    var bargainerIsMe : Bool {get}
    var productStatus : Int {get}
    var finalPrice : Int {get} // Final price after bargain accept/reject
    var markAsSoldTo : String {get}
    
    func setBargainPrice(_ price : Int)
    func setFinalPrice(_ price : Int)
}

// MARK: - Protocol

protocol TawarDelegate {
    func tawarNeedReloadList()
}

// MARK: - Class

class TawarViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIScrollViewDelegate, MessagePoolDelegate, UserRelatedDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate {

    // MARK: - Properties
    
    // Outlets
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    // Outlets in header section
    @IBOutlet weak var header : TawarHeader!
    @IBOutlet weak var conMarginHeightOptions : NSLayoutConstraint!
    @IBOutlet weak var btnTawar1 : UIButton!
    @IBOutlet weak var btnTawar2 : UIButton!
    @IBOutlet weak var btnBeli : UIButton!
    @IBOutlet weak var btnBatal : UIButton!
    @IBOutlet weak var btnTolak : UIButton!
    @IBOutlet weak var btnTolak2 : UIButton!
    @IBOutlet weak var btnConfirm : UIButton!
    @IBOutlet weak var btnSold: UIButton!
    @IBOutlet weak var btnBeliSold: UIButton!
    // Outlets in chat field section
    @IBOutlet weak var btnSend : UIButton!
    @IBOutlet weak var textView : UITextView!
    @IBOutlet weak var conMarginBottom : NSLayoutConstraint!
    @IBOutlet weak var conHeightTextView : NSLayoutConstraint!
    @IBOutlet weak var vwMediaButton: UIView!
    // Outlets in tawar pop up
    @IBOutlet weak var txtTawar : UITextField!
    @IBOutlet weak var captionTawarHargaOri : UILabel!
    @IBOutlet weak var sectionTawar : UIView!
    @IBOutlet weak var conMarginBottomSectionTawar : NSLayoutConstraint!
    // Outlets in upload gambar pop up
    @IBOutlet weak var sectionUploadGbr: UIView!
    @IBOutlet weak var conBottomSectionUploadGbr: NSLayoutConstraint!
    @IBOutlet weak var imgUploadGbr: UIImageView!
    @IBOutlet weak var txtVwUploadGbr: UITextView!
    @IBOutlet weak var conHeightTxtVwUploadGbr: NSLayoutConstraint!
    @IBOutlet weak var btnBatalUploadGbr: UIButton!
    @IBOutlet weak var btnKirimUploadGbr: UIButton!
    
    // Grow handler
    var textViewGrowHandler : GrowingTextViewHandler!
    var txtVwUploadGbrGrowHandler : GrowingTextViewHandler!
    
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
    
    // dipakai jika start dari lovelist --> tawarkan
    var isTawarkan : Bool = false
    var isTawarkan_originalPrice : String = ""
    
    // aggregate chat
    var isSellerNotActive: Bool = false
    // seller phone number
    var phoneNumber: String = "" //"08112353131"
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        self.title = tawarItem.theirName

        // Init textViewGrowHandler
        textViewGrowHandler = GrowingTextViewHandler(textView: textView, withHeightConstraint: conHeightTextView)
        textViewGrowHandler.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 4)
        txtVwUploadGbrGrowHandler = GrowingTextViewHandler(textView: txtVwUploadGbr, withHeightConstraint: conHeightTxtVwUploadGbr)
        txtVwUploadGbrGrowHandler.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 3)
        
        // Loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.hideLoading()
        
        // UploadGbr pop up setup
        sectionUploadGbr.backgroundColor = UIColor.colorWithColor(.black, alpha: 0.5)
        
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
        
        header.ivProduct.image = nil
        
        // Product image
        header.ivProduct.afSetImage(withURL: tawarItem.productImage)
        
        // Hide textview and price for Prelo Message
        if (self.isChatWithPreloMessage()) {
            self.conMarginBottom.constant = -(self.conHeightTextView.constant + 6)
            header.captionPrice.isHidden = true
            header.captionUsername.isHidden = true
        }
        
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        
        // Init chat field section
        textViewDidChange(textView)
        textView.delegate = self
        
        // Uploadgbr txtvw
        txtVwUploadGbr.delegate = self
        
        // Buttons action setup
        btnTawar1.addTarget(self, action: #selector(TawarViewController.showTawar(_:)), for: UIControlEvents.touchUpInside)
        btnTawar2.addTarget(self, action: #selector(TawarViewController.showTawar(_:)), for: UIControlEvents.touchUpInside)
        btnTolak.addTarget(self, action: #selector(TawarViewController.rejectTawar(_:)), for: UIControlEvents.touchUpInside)
        btnTolak2.addTarget(self, action: #selector(TawarViewController.rejectTawar(_:)), for: UIControlEvents.touchUpInside)
        btnConfirm.addTarget(self, action: #selector(TawarViewController.confirmTawar(_:)), for: UIControlEvents.touchUpInside)
        btnSold.addTarget(self, action: #selector(TawarViewController.markAsSold), for: UIControlEvents.touchUpInside)
        
        // Setup messages
        if (User.IsLoggedIn) {
            firstSetup()
        }
        
        
        // OVERRIDE BUTTON COLOR
        // ORANYE PRELO
        btnTawar1.backgroundColor = Theme.ThemeOrange
        btnTawar2.backgroundColor = Theme.ThemeOrange
        
        // WHITE
        //        btnTolak
        //        btnTolak2
        //        btnBatal
        
        // HIJAU PRELO
        btnConfirm.backgroundColor = Theme.PrimaryColor
        btnSold.backgroundColor = Theme.PrimaryColor
        btnBeli.backgroundColor = Theme.PrimaryColor
        btnBeliSold.backgroundColor = Theme.PrimaryColor
        
        if (User.IsLoggedIn) {
            if isTawarkan {
                self.startNew(1, message : isTawarkan_originalPrice, withImg: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.InboxDetail)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.InboxDetail)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Keyboard animation handling
        self.an_subscribeKeyboard(animations: { frame, interval, opening in
            if (opening) {
                self.conMarginBottom.constant = frame.height
                self.conMarginBottomSectionTawar.constant = frame.height
                self.conBottomSectionUploadGbr.constant = frame.height
            } else {
                self.conMarginBottom.constant = 0
                self.conMarginBottomSectionTawar.constant = 0
                self.setUploadGbrPopUpPositionCenterVertically()
            }
        }, completion: nil)
        
        // Show login page if user is not logged in
        if (!User.IsLoggedIn && isShowLogin) {
            isShowLogin = false
            LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
        }
        
        if self.prodId == "" {
            self.prodId = self.tawarItem.itemId
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove messagepool delegate
        if let del = UIApplication.shared.delegate as? AppDelegate {
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
        self.tableView.isHidden = true
        
        let _ = request(APIInbox.getInboxByProductID(productId: prodId)).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Get Inbox By Product ID")) {
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
            self.tableView.isHidden = false
        }
    }
    
    func getMessages() {
        inboxMessages.removeAll(keepingCapacity: false)
        
        var api = APIInbox.getInboxMessage(inboxId: tawarItem.threadId)
        if (fromSeller) {
            api = APIInbox.getInboxByProductIDSeller(productId: tawarItem.threadId, buyerId: toId)
        }
        // API Migrasi
        let _ = request(api).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Chat")) {
                
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
                if let del = UIApplication.shared.delegate as? AppDelegate {
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
        btnTawar1.isHidden = true
        btnTawar2.isHidden = true
        btnBeli.isHidden = true
        btnBatal.isHidden = true
        btnTolak.isHidden = true
        btnTolak2.isHidden = true
        btnConfirm.isHidden = true
        btnSold.isHidden = true
        btnBeliSold.isHidden = true
        
        // Enable buttons
        btnTawar1.isEnabled = true
        btnTawar2.isEnabled = true
        
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
                if (tawarItem.markAsSoldTo == tawarItem.theirId) { // mark as sold, im seller
//                    self.conMarginHeightOptions.constant = 149 // 114 // 80
                    if (threadState == 0 || threadState == 2 || threadState == 3) {
                        self.conMarginHeightOptions.constant = 149
                    } else if (threadState == 1) {
                        self.conMarginHeightOptions.constant = 114
                    }
                } else if (threadState == 4 || threadState == 3) { // start chat from seller
                    self.conMarginHeightOptions.constant = 149
                } else if (threadState == 1) {
                    self.conMarginHeightOptions.constant = 114
                } else {
                    self.conMarginHeightOptions.constant = 80
                    return
                }
            }
        }
        
        // Arrange buttons
        if (self.prodStatus != 1) { // Product is sold
            /*
            if (tawarItem.opIsMe && tawarItem.markAsSoldTo == User.Id) { // I am buyer & mark as sold to me
                btnTawar1.isHidden = false
                btnBeli.isHidden = false
//                btnBeliSold.isHidden = false // default
            } else if (!tawarItem.opIsMe && tawarItem.markAsSoldTo == tawarItem.theirId) { // I am seller & mark as sold to their
                btnTawar2.isHidden = false
                btnSold.isHidden = false
            }
             */
            if (threadState == 0 || threadState == 2 || threadState == 3 || threadState == 4) { // No one is bargaining
                if (tawarItem.opIsMe && tawarItem.markAsSoldTo == User.Id) { // I am buyer & mark as sold to me
                    btnTawar1.isHidden = false
                    btnBeli.isHidden = false
                } else if (!tawarItem.opIsMe && tawarItem.markAsSoldTo == tawarItem.theirId) { // I am seller & mark as sold to their
                    btnTawar2.isHidden = false
                    btnSold.isHidden = false
                } else if (threadState == 4 || threadState == 3) { // start chat from seller
                    btnTawar2.isHidden = false
                    btnSold.isHidden = false
                }
            } else if (threadState == 1) { // Someone is bargaining
                if (tawarFromMe) { // I am bargaining
                    if (tawarItem.opIsMe) { // I am buyer
                        btnTolak2.isHidden = false
                    } else { // I am seller
                        btnTolak2.isHidden = false
                    }
                } else { // Other is bargaining
                    btnTolak.isHidden = false
                    btnConfirm.isHidden = false
                }
            }

        } else { // Product isn't sold
            if (threadState == 0 || threadState == 2 || threadState == 3) { // No one is bargaining
                if (tawarItem.opIsMe) { // I am buyer
                    btnTawar1.isHidden = false
                    btnBeli.isHidden = false
                } else { // I am seller
                    btnTawar2.isHidden = false
                    btnSold.isHidden = false
                }
            } else if (threadState == 1) { // Someone is bargaining
                if (tawarFromMe) { // I am bargaining
                    if (tawarItem.opIsMe) { // I am buyer
                        btnTolak2.isHidden = false
                    } else { // I am seller
                        btnTolak2.isHidden = false
                    }
                } else { // Other is bargaining
                    btnTolak.isHidden = false
                    btnConfirm.isHidden = false
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
    
    func textViewDidChange(_ textView: UITextView) {
        if (textView == self.textView) {
            textViewGrowHandler.resizeTextView(withAnimation: true)
            if (textView.text == "") {
                btnSend.setBackgroundImage(AppToolsObjC.image(from: UIColor.gray), for: UIControlState())
                btnSend.isUserInteractionEnabled = false
            } else {
                btnSend.setBackgroundImage(AppToolsObjC.image(from: UIColor(hexString: "#25A79D")), for: UIControlState())
                btnSend.isUserInteractionEnabled = true
            }
        } else if (textView == self.txtVwUploadGbr) {
            txtVwUploadGbrGrowHandler.resizeTextView(withAnimation: true)
        }
    }
    
    // MARK: - Tableview functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inboxMessages.count + (isShowBubble ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if ((indexPath as NSIndexPath).row == 0 && isShowBubble) { // Bubble cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "bubble") as! TawarBubbleCell
            cell.selectionStyle = .none
            cell.viewWithTag(999)?.removeFromSuperview()
            cell.viewWithTag(888)?.removeFromSuperview()
            
            let btnClose = UIButton(frame: CGRect(x: cell.width - 38, y: 8, width: 30, height: 30))
            btnClose.addTarget(self, action: #selector(TawarViewController.closeBubble), for: UIControlEvents.touchUpInside)
            btnClose.tag = 888
            //btnClose.backgroundColor = UIColor.black.alpha(0.3)
            cell.addSubview(btnClose)
            
            if (self.tawarItem.opIsMe) { // I am buyer
                if (isSellerNotActive) {
                    let attrStr = NSMutableAttributedString(string: "Penjual ini sedang tidak aktif di Prelo. Hubungi penjual secara langsung bahwa kamu menemukan iklan ini di Prelo.\n\n")
                    cell.lblText.attributedText = attrStr
                    
                    let subview = UIView(frame: CGRect(x: 0, y: 110 - 40, width: 290 - 14, height: 40))
                    subview.tag = 999
                    
                    let width = 290/2 - 1
                    
                    let telpBtn = UIButton(frame: CGRect(x: 0, y: 0, width: width, height: 20))
                    telpBtn.setTitle("Telepon Penjual", for: .normal)
                    telpBtn.backgroundColor = UIColor.clear
                    telpBtn.setTitleColor(Theme.PrimaryColor)
                    telpBtn.removeBorders()
                    telpBtn.addTarget(self, action: #selector(TawarViewController.phoneSeller), for: UIControlEvents.touchUpInside)
                    telpBtn.setTitleFont(FontName.Helvetica, size: 12)
                    let imgH = UIImage(named: "ic_hubungi_prelo")?.resizeWithMaxWidthOrHeight(28)
                    telpBtn.setImage(imgH, for: .normal)
                    telpBtn.imageView?.contentMode = .scaleAspectFit
                    telpBtn.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
                    
                    let splitLbl = UILabel(frame: CGRect(x: width, y: 0, width: 2, height: 20))
                    splitLbl.font = cell.lblText.font
                    splitLbl.text = "|"
                    splitLbl.textAlignment = .center
                    splitLbl.textColor = Theme.PrimaryColor
                    
                    let smsBtn = UIButton(frame: CGRect(x: width + 2, y: 0, width: width - 32, height: 20))
                    smsBtn.setTitle(" SMS Penjual", for: .normal)
                    smsBtn.backgroundColor = UIColor.clear
                    smsBtn.setTitleColor(Theme.PrimaryColor)
                    smsBtn.removeBorders()
                    smsBtn.addTarget(self, action: #selector(TawarViewController.smsSeller), for: UIControlEvents.touchUpInside)
                    smsBtn.setTitleFont(FontName.Helvetica, size: 12)
                    let imgC = UIImage(named: "ic_comment")?.resizeWithMaxWidthOrHeight(28)
                    smsBtn.setImage(imgC, for: .normal)
                    smsBtn.imageView?.contentMode = .scaleAspectFit
                    smsBtn.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
                    
                    subview.addSubview(telpBtn)
                    subview.addSubview(splitLbl)
                    subview.addSubview(smsBtn)
                    //subview.backgroundColor = UIColor.white
                    cell.addSubview(subview)
                } else {
                    let attrStr = NSMutableAttributedString(string: "Pastikan kamu bertransaksi 100% aman hanya melalui rekening bersama Prelo. Waspada apabila kamu diminta bertransaksi di luar Prelo, terutama jika terdapat permintaan yang kurang wajar.")
                    cell.lblText.attributedText = attrStr
                    cell.lblText.setSubstringColor("rekening bersama Prelo", color: Theme.PrimaryColor)
                }
            } else { // I am seller
                let attrStr = NSMutableAttributedString(string: "Klik MARK AS SOLD jika barang sudah dibeli oleh \(self.tawarItem.theirName). Waspada apabila kamu diminta bertransaksi di luar Prelo, terutama jika terdapat permintaan yang kurang wajar.")
                cell.lblText.attributedText = attrStr
                cell.lblText.boldSubstring("MARK AS SOLD")
                cell.lblText.setSubstringColor(self.tawarItem.theirName, color: Theme.PrimaryColor)
            }
            return cell
        } else { // Chat cell
            let m = inboxMessages[(indexPath as NSIndexPath).row - (isShowBubble ? 1 : 0)]
            let id = m.isMe ? (m.attachmentType == "image" ? "imageMe" : "me") : (m.attachmentType == "image" ? "imageThem" : "them")
            let cell = tableView.dequeueReusableCell(withIdentifier: id) as! TawarCell
            
            cell.inboxMessage = m
            cell.decor()
            
            if (!m.isMe) {
                cell.avatar?.afSetImage(withURL: tawarItem.theirImage, withFilter: .circle)
            }
            
            cell.toShopPage = {
                self.gotoShopPage(0 as AnyObject)
            }
            
            cell.zoomImgMessage = {
                let c = CoverZoomController()
                c.labels = [m.attachmentType]
                c.images = [m.attachmentURL.absoluteString]
                c.index = 0
                self.navigationController?.present(c, animated: true, completion: nil)
            }
            
            cell.selectionStyle = .none
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if ((indexPath as NSIndexPath).row == 0 && isShowBubble) { // Bubble cell
            if (self.tawarItem.opIsMe) { // I am buyer
                return 110
            } else { // I am seller
                return 110
            }
        } else { // Chat cell
            let chat = inboxMessages[(indexPath as NSIndexPath).row - (isShowBubble ? 1 : 0)]
            if (chat.attachmentType == "image") {
//                if let data = try? Data(contentsOf: chat.attachmentURL) {
//                    if let img = UIImage(data: data) {
//                        return img.size.height
//                    }
//                }
                return 260
            } else {
                var m = chat.dynamicMessage
                if (chat.failedToSend) {
                    m = "[GAGAL MENGIRIM]\n\n" + m
                }
                
                var w : CGFloat = 204
                
                if (chat.isMe) {
                    w = (UIScreen.main.bounds.width - 28) * 0.75
                } else {
                    w = (UIScreen.main.bounds.width - 72) * 0.75
                }
                
                let s = m.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: w)
                
                var c = CGFloat(0)
                if chat.dynamicMessage.lowercased().range(of: "tawar") != nil && (chat.dynamicMessage.range(of: "Rp") != nil) {
                    c = 6
                }
                
                return 57 + s.height + c
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if ((indexPath as NSIndexPath).row == 0 && isShowBubble) { // Bubble cell
            //isShowBubble = false
            //tableView.reloadData()
        } else { // Chat cell
            tableView.deselectRow(at: indexPath, animated: true)
            self.view.endEditing(true)
        }
    }
    
    func scrollWithInterval(_ intrvl : TimeInterval) {
        Timer.scheduledTimer(timeInterval: intrvl, target: self, selector: #selector(TawarViewController.scrollToBottom), userInfo: nil, repeats: false)
    }
    
    func scrollToBottom() {
        if (inboxMessages.count > 0) {
            tableView.scrollToRow(at: IndexPath(row: inboxMessages.count - 1 + (isShowBubble ? 1 : 0), section: 0), at: UITableViewScrollPosition.bottom, animated: false)
        }
    }
    
    // MARK: - Scrollview functions
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    // MARK: - Chat actions
    
    @IBAction func addChat(_ sender : UIView?) {
        if (tawarItem.threadId == "") {
            startNew(0, message : textView.text, withImg: nil)
            return
        }
        
        let m = textView.text
        if (m == "") {
            return
        }
        
        sendChat(0, message: m!, image: nil)
        textViewGrowHandler.setText("", withAnimation: true)
        
        textViewDidChange(textView)
    }
    
    func sendChat(_ type : Int, message : String, image: UIImage?) {
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
        
        // Create a URL in the /tmp directory
        var imageURL = URL(string: "http://lorempixel.com/output/animals-q-g-640-480-4.jpg")
        if (image != nil) {
            if let url = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempImg-" + self.inboxMessages.count.string + ".png") {
                imageURL = url
            }
            if (imageURL != nil) {
                do {
                    try UIImageJPEGRepresentation(image!, 1)?.write(to: imageURL!)
                } catch { }
            }
        }
        
        // Append inboxMessages
        let localId = inboxMessages.count
        let date = Date()
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let time = f.string(from: date)
        let i = InboxMessage.messageFromMe(localId, type: type, message: message, time: time, attachmentType: (image != nil ? "image" : ""), attachmentURL: imageURL!)
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
        i.sendTo(tawarItem.threadId, withImg: image, completion: { m in
            self.adjustButtons()
            self.tableView.reloadData()
            self.hideLoading()
        })
        
        // Prelo Analytic - Send Media on Chat
        if image != nil {
            self.sendMediaOnChatAnalytic("Image")
        }
        
        self.adjustButtons()
        self.tableView.reloadData()
        self.scrollToBottom()
    }
    
    func startNew(_ type : Int, message : String, withImg : UIImage?) {
        // Set tawarFromMe
        if (type == 1) {
            tawarFromMe = true
        } else if (type != 0) {
            tawarFromMe = false
        }
        
        // Make sure this is executed once
        if (starting) {
            return
        }
        self.starting = true
        
        let url = "\(AppTools.PreloBaseUrl)/api/inbox/"
        var param = [
            "product_id" : prodId,
            "message_type" : String(type),
            "message" : message,
            "platform_sent_from" : "ios"
            ] as [String : Any]
        if (fromSeller) {
            param = [
                "product_id" : prodId,
                "message_type" : String(type),
                "message" : message,
                "to" : toId,
                "platform_sent_from" : "ios"
            ]
        }
        var images : [UIImage] = []
        if let img = withImg {
            images.append(img)
        }
        let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
        
        AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, andUserAgent: userAgent!, to: url, success: {op, res in
            self.starting = false
            let json = JSON(res!)
            let data = json["_data"]
            let inbox = Inbox(jsn: data)
            self.tawarItem = inbox
            
            // Create a URL in the /tmp directory
            var imageURL = URL(string: "http://lorempixel.com/output/animals-q-g-640-480-4.jpg")
            if (withImg != nil) {
                if let url = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempImg-" + self.inboxMessages.count.string + ".png") {
                    imageURL = url
                }
                if (imageURL != nil) {
                    do {
                        try UIImageJPEGRepresentation(withImg!, 1)?.write(to: imageURL!)
                    } catch { }
                }
            }

            
            let localId = self.inboxMessages.count
            let date = Date()
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let time = f.string(from: date)
            let i = InboxMessage.messageFromMe(localId, type: type, message: message, time: time, attachmentType: (withImg != nil ? "image" : ""), attachmentURL: imageURL!)
            if (type == 1) {
                self.tawarItem.setBargainPrice(message.int)
            }

            self.inboxMessages.append(i)
            self.textView.text = ""
            
            // Change threadState
            if (type != 0) { // Kalo type = 0 gak ada arti apapun, gak perlu rubah state.
                self.threadState = type
            }
            
            self.adjustButtons()
            self.tableView.reloadData()
            self.scrollToBottom()
            
            // Register to messagePool
            if let del = UIApplication.shared.delegate as? AppDelegate {
                del.messagePool?.registerDelegate(self.tawarItem.threadId, d: self)
            } else {
                let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"MessagePool 3"])
            }
            
            // Prelo Analytic - Start Chat
            let loginMethod = User.LoginMethod ?? ""
            let pdata = [
                "Product ID" : self.prodId
            ] as [String : Any]
            AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.StartChat, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
            
            // Prelo Analytic - Send Media on Chat
            if withImg != nil {
                self.sendMediaOnChatAnalytic("Image")
            }
            
            self.hideLoading()
        }, failure: { op, err in
            self.adjustButtons()
            self.tableView.reloadData()
            self.hideLoading()
        })
        
        
        
//        var api = APIInbox.startNewOne(productId: prodId, type: type, message: message)
//        if (fromSeller) {
//            api = APIInbox.startNewOneBySeller(productId: prodId, type: type, message: message, toId: toId)
//        }
//        let _ = request(api).responseJSON { resp in
//            self.starting = false
//            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Chat")) {
//                let json = JSON(resp.result.value!)
//                let data = json["_data"]
//                let inbox = Inbox(jsn: data)
//                self.tawarItem = inbox
//                
//                let localId = self.inboxMessages.count
//                let date = Date()
//                let f = DateFormatter()
//                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
//                let time = f.string(from: date)
//                let i = InboxMessage.messageFromMe(localId, type: type, message: message, time: time, attachmentType: "", attachmentURL: URL(string: "http://lorempixel.com/output/animals-q-g-640-480-4.jpg")!)
//                self.inboxMessages.append(i)
//                self.textView.text = ""
//                self.adjustButtons()
//                self.tableView.reloadData()
//                self.scrollToBottom()
//                
//                // Register to messagePool
//                if let del = UIApplication.shared.delegate as? AppDelegate {
//                    del.messagePool?.registerDelegate(self.tawarItem.threadId, d: self)
//                } else {
//                    let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
//                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"MessagePool 3"])
//                }
//            } else {
//                self.adjustButtons()
//                print(resp.result.error)
//            }
//        }
    }
    
    // Helper untuk simulate ada message masuk
    func sendDummy(_ type : Int = 0, message : String = "DUMMY", delay : TimeInterval = 3)
    {
//        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
            Thread.sleep(forTimeInterval: delay)
            DispatchQueue.main.async(execute: {
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
    
    @IBAction func btnCameraPressed(_ sender: UIButton) {
        let i = UIImagePickerController()
        i.sourceType = .photoLibrary
        i.delegate = self
        
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            let a = UIAlertController(title: "Ambil gambar dari:", message: nil, preferredStyle: .actionSheet)
            a.popoverPresentationController?.sourceView = self.vwMediaButton
            a.popoverPresentationController?.sourceRect = self.vwMediaButton.bounds
            a.addAction(UIAlertAction(title: "Kamera", style: .default, handler: { act in
                i.sourceType = .camera
                self.present(i, animated: true, completion: nil)
            }))
            a.addAction(UIAlertAction(title: "Album", style: .default, handler: { act in
                self.present(i, animated: true, completion: nil)
            }))
            a.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in }))
            self.present(a, animated: true, completion: nil)
        } else {
            self.present(i, animated: true, completion: nil)
        }
    }
    
    // MARK: - UIImagePickerController functions
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.sectionUploadGbr.isHidden = false
            self.imgUploadGbr.image = img
            self.setUploadGbrPopUpPositionCenterVertically()
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Tawar pop up
    
    @IBAction func showTawar(_ sender : UIView?) {
        sectionTawar.isHidden = false
        txtTawar.becomeFirstResponder()
    }
    
    @IBAction func hideTawar(_ sender : UIView?) {
        sectionTawar.isHidden = true
        txtTawar.resignFirstResponder()
    }
    
    @IBAction func sendTawar(_ sender : UIView?) {
        guard txtTawar.text != nil else {
            return
        }
        
        let tawarRegex = "^[0-9]*$"
        if (txtTawar.text == "" || txtTawar.text!.match(tawarRegex) == false) {
            Constant.showDialog("Masukkan hanya angka penawaran", message: "Contoh: 150000")
        } else {
            let m = txtTawar.text!.int
            if (m < 1000) {
                Constant.showDialog("Tawar", message: "Mungkin maksud kamu " + m.asPrice + "0")
                return
            }
            var originalPrice = tawarItem.price.replacingOccurrences(of: "Rp", with: "", options: .literal, range: nil)
            originalPrice = originalPrice.replacingOccurrences(of: ".", with: "", options: .literal, range: nil)
            let halfPrice = originalPrice.int / 2
            if m <= halfPrice && CDUser.getOne()?.id == tawarItem!.myId && tawarItem!.opIsMe == true {
                Constant.showDialog("Tawar", message: "Tawaran yang kamu ajukan terlalu rendah, hanya penjual yang dapat memberikan penawaran dengan harga tersebut")
                return
            }
            self.hideTawar(nil)
            if (tawarItem.threadId == "") {
                startNew(1, message : txtTawar.text!, withImg: nil)
            } else {
                sendChat(1, message: txtTawar.text!, image: nil)
            }
            txtTawar.text = ""
            btnTawar1.isEnabled = false
            btnTawar2.isEnabled = false
//            btnTawar1.isHidden = true
//            btnTawar2.isHidden = true
            self.tawarItem.setBargainPrice(m)
            
            // Prelo Analytics - Successful Bargain - New
//            self.sendSuccessfulBargainAnalytic("New")
        }
    }
    
    func rejectTawar(_ sender : UIView?) {
        var message = String(tawarItem.bargainPrice)
        if (tawarFromMe) {
            message = "Membatalkan tawaran " + tawarItem.bargainPrice.asPrice
        }
        sendChat(3, message: message, image: nil)
        
        // Prelo Analytics - Successful Bargain - Reject
//        self.sendSuccessfulBargainAnalytic("Reject")
    }
    
    func confirmTawar(_ sender : UIView?) {
        sendChat(2, message : String(tawarItem.bargainPrice), image: nil)
        if (tawarItem.bargainPrice != 0) {
            self.tawarItem.setFinalPrice(self.tawarItem.bargainPrice)
        }
        
        // Prelo Analytics - Successful Bargain - Accept
        self.sendSuccessfulBargainAnalytic("Accept")
    }
    
    // MARK: - UploadGbr pop up
    
    func setUploadGbrPopUpPositionCenterVertically() {
        self.conBottomSectionUploadGbr.constant = (UIScreen.main.bounds.height / 2) - 151
    }
    
    func hideAndResetUploadGbrPopUp() {
        self.imgUploadGbr.image = nil
        self.txtVwUploadGbr.text = ""
        self.textViewDidChange(txtVwUploadGbr)
    }
    
    @IBAction func btnBatalUploadGbrPressed(_ sender: UIButton) {
        self.hideAndResetUploadGbrPopUp()
        self.sectionUploadGbr.isHidden = true
    }
    
    @IBAction func btnKirimUploadGbrPressed(_ sender: UIButton) {
        self.showLoading()
        if (tawarItem.threadId == "") {
            startNew(0, message : self.txtVwUploadGbr.text, withImg: self.imgUploadGbr.image)
        } else {
            sendChat(0, message: self.txtVwUploadGbr.text, image: self.imgUploadGbr.image)
        }
        self.hideAndResetUploadGbrPopUp()
        self.sectionUploadGbr.isHidden = true
    }
    
    // MARK: - Message pool delegate functions
    
    func messageArrived(_ message: InboxMessage) {
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
    
    func preloMessageArrived(_ message: PreloMessageItem) {
        // do nothing
    }
    
    // MARK: - User related delegate functions
    
    func userLoggedIn() {
        firstSetup()
    }
    
    func userLoggedOut() {
        
    }
    
    func userCancelLogin() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Navigation
    
    @IBAction func gotoProduct(_ sender: AnyObject) {
        if (!isChatWithPreloMessage() && tawarItem.itemId != "") {
            let _ = request(APIProduct.detail(productId: tawarItem.itemId, forEdit: 0)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Barang")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    let p = Product.instance(data)
                    let productDetailVC = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                    productDetailVC.product = p!
                    productDetailVC.previousScreen = PageName.InboxDetail
                    self.navigationController?.pushViewController(productDetailVC, animated: true)
                }
            }
        }
    }
    
    @IBAction func gotoShopPage(_ sender: AnyObject) {
        if (!isChatWithPreloMessage() && tawarItem.theirId != "") {
            if (!AppTools.isNewShop) {
                let shopPage = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                shopPage.currentMode = .shop
                shopPage.shopId = tawarItem.theirId
                shopPage.previousScreen = PageName.InboxDetail
                self.navigationController?.pushViewController(shopPage, animated: true)
            } else {
                let storePageTabBarVC = Bundle.main.loadNibNamed(Tags.XibNameStorePage, owner: nil, options: nil)?.first as! StorePageTabBarViewController
                storePageTabBarVC.shopId = tawarItem.theirId
                self.navigationController?.pushViewController(storePageTabBarVC, animated: true)
            }
        }
    }
    
    @IBAction func beli(_ sender : UIView?) {
        var success = true
        if (CartProduct.getOne(tawarItem.itemId, email: User.EmailOrEmptyString) == nil) {
            if (CartProduct.newOne(tawarItem.itemId, email : User.EmailOrEmptyString, name : tawarItem.itemName) == nil) {
                success = false
                Constant.showDialog("Failed", message: "Gagal Menyimpan")
            }
        }
        
        if (success) {
//            self.performSegue(withIdentifier: "segCart", sender: nil)
            let cart = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdCart) as! CartViewController
            cart.previousController = self
            cart.previousScreen = PageName.InboxDetail
            self.navigationController?.pushViewController(cart, animated: true)
        }
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    func markAsSold() {
//        let alert : UIAlertController = UIAlertController(title: "Mark As Sold", message: "Apakah barang ini sudah dibeli dan diterima oleh pembeli? (Aksi ini tidak bisa dibatalkan)", preferredStyle: UIAlertControllerStyle.alert)
//        alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: nil))
//        alert.addAction(UIAlertAction(title: "Ya", style: .default, handler: { action in
//            self.prodStatus = 2
//            Constant.showDialog("Success", message: "Barang telah ditandai sebagai barang terjual")
//            var finalPrice = ""
//            if (self.tawarItem.bargainPrice != 0 && self.tawarItem.threadState == 2) {
//                finalPrice = self.tawarItem.bargainPrice.asPrice
//            } else {
//                finalPrice = self.tawarItem.price
//            }
//            self.sendChat(4, message: "Barang ini dijual kepada \(self.tawarItem.theirName) dengan harga \(finalPrice)", image: nil)
//            
//            // Mixpanel
//            let pt = [
//                "Product Id" : self.prodId,
//                "Seller Id" : CDUser.getOne()?.id, // seller
//                "Buyer Id" : self.toId, // buyer
//                "Price" : finalPrice
//            ]
//            Mixpanel.trackEvent(MixpanelEvent.ChatMarkAsSold, properties: pt)
//        }))
//        self.present(alert, animated: true, completion: nil)
        
        /*
        let alert : UIAlertController = UIAlertController(title: "Mark As Sold", message: "Apakah barang ini sudah DIBAYAR oleh pembeli ini? (Aksi ini TIDAK dapat dibatalkan)", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Ya", style: .default, handler: { action in
            let alert2 : UIAlertController = UIAlertController(title: "Mark As Sold", message: "Apakah kamu yakin? (Aksi ini TIDAK dapat dibatalkan)", preferredStyle: UIAlertControllerStyle.alert)
            alert2.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: nil))
            alert2.addAction(UIAlertAction(title: "Ya", style: .default, handler: { action in
                self.prodStatus = 2
                Constant.showDialog("Success", message: "Barang telah ditandai sebagai barang terjual")
                var finalPrice = ""
                if (self.tawarItem.bargainPrice != 0 && self.tawarItem.threadState == 2) {
                    finalPrice = self.tawarItem.bargainPrice.asPrice
                } else {
                    finalPrice = self.tawarItem.price
                }
                self.sendChat(4, message: "Barang ini dijual kepada \(self.tawarItem.theirName) dengan harga \(finalPrice)", image: nil)
                
                /*
                // Mixpanel
                let pt = [
                    "Product Id" : self.prodId,
                    "Seller Id" : CDUser.getOne()?.id, // seller
                    "Buyer Id" : self.toId, // buyer
                    "Price" : finalPrice
                ]
                Mixpanel.trackEvent(MixpanelEvent.ChatMarkAsSold, properties: pt)
                 */
                
                // Prelo Analytic - Mark As Sold
                let loginMethod = User.LoginMethod ?? ""
                let pdata = [
                    "Product ID": self.prodId,
                    "Screen" : PageName.InboxDetail
                ] as [String : Any]
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.MarkAsSold, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
            }))
            self.present(alert2, animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
         */
        
        let alertView = SCLAlertView(appearance: Constant.appearance)
        alertView.addButton("Ya") {
            
            let alertView2 = SCLAlertView(appearance: Constant.appearance)
            alertView2.addButton("Ya") {
                self.prodStatus = 2
                Constant.showDialog("Success", message: "Barang telah ditandai sebagai barang terjual")
                var finalPrice = ""
                if (self.tawarItem.bargainPrice != 0 && self.tawarItem.threadState == 2) {
                    finalPrice = self.tawarItem.bargainPrice.asPrice
                } else {
                    finalPrice = self.tawarItem.price
                }
                self.sendChat(4, message: "Barang ini dijual kepada \(self.tawarItem.theirName) dengan harga \(finalPrice)", image: nil)
                
                // Prelo Analytic - Mark As Sold
                let loginMethod = User.LoginMethod ?? ""
                let pdata = [
                    "Product ID": self.prodId,
                    "Screen" : PageName.InboxDetail
                ] as [String : Any]
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.MarkAsSold, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
            }
            alertView2.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
            alertView2.showCustom("Mark As Sold", subTitle: "Apakah kamu yakin? (Aksi ini TIDAK dapat dibatalkan)", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
            
        }
        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
        alertView.showCustom("Mark As Sold", subTitle: "Apakah barang ini sudah DIBAYAR oleh pembeli ini? (Aksi ini TIDAK dapat dibatalkan)", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    func randomElementIndex<T>(_ s: Set<T>) -> T {
        let n = Int(arc4random_uniform(UInt32(s.count)))
        let i = s.index(s.startIndex, offsetBy: n)
        return s[i]
    }
    
    func sendMixpanelEvent(_ eventName : String) {
        let pt = [
            "Product Name" : tawarItem.itemName,
            "Category 1" : "",
            "Category 2" : "",
            "Category 3" : "",
            "Buyer Name" : (tawarItem.opIsMe ? tawarItem.myName : tawarItem.theirName),
            "Seller Name" : (tawarItem.opIsMe ? tawarItem.theirName : tawarItem.myName),
            "Is Seller" : !tawarItem.opIsMe
        ] as [String : Any]
        Mixpanel.trackEvent(eventName, properties: pt as [AnyHashable: Any])
    }
    
    func isChatWithPreloMessage() -> Bool {
        return (tawarItem.theirId == "56c73cc61b97db64088b4567" || tawarItem.theirId == "56c73e581b97db1b628b4567")
    }
    
    // Prelo Analytic - Successful Bargain
    func sendSuccessfulBargainAnalytic(_ bargainType: String) {
        let loginMethod = User.LoginMethod ?? ""
        let bargainPrice = Double(self.tawarItem.bargainPrice)
        var _originalPrice = tawarItem.price.replacingOccurrences(of: "Rp", with: "", options: .literal, range: nil)
        _originalPrice = _originalPrice.replacingOccurrences(of: ".", with: "", options: .literal, range: nil)
        let originalPrice = Double(_originalPrice.int)
        let percentagePrice = (bargainPrice * 100.0 / originalPrice)
        let pdata = [
            "Product ID" : self.prodId,
            //"User Target" : (tawarItem.opIsMe ? tawarItem.myName : tawarItem.theirName),
            //"Bargain Type" : bargainType,
            "Percentage" : percentagePrice,
            "From Seller" : !tawarItem.opIsMe
        ] as [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.SuccessfulBargain, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
    }
    
    // Prelo Analytic - Send Media on Chat
    func sendMediaOnChatAnalytic(_ mediaType: String) {
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            //"Seller Username" : (tawarItem.opIsMe ? tawarItem.theirName : tawarItem.myName),
            //"Buyer Username" : (tawarItem.opIsMe ? tawarItem.myName : tawarItem.theirName),
            "Media Type" : mediaType
        ] as [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.SendMediaOnChat, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
    }
    
    // MARK: - Helper
    func putToPasteBoard(_ text : String) {
        UIPasteboard.general.string = text
        
    }
    
    func phoneSeller() {
        if let url = URL(string: "tel:" + phoneNumber) {
            if (UIApplication.shared.canOpenURL(url)) {
                UIApplication.shared.openURL(url)
            } else {
                putToPasteBoard(phoneNumber)
                Constant.showDialog("Perhatian", message: "Nomor seller sudah ada di clipboard :)")
            }
        }
    }
    
    func smsSeller() {
        if (MFMessageComposeViewController.canSendText()) {
            let composer = MFMessageComposeViewController()
            composer.recipients = [phoneNumber]
            composer.messageComposeDelegate = self
            self.present(composer, animated: true, completion: nil)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func closeBubble() {
        if (isShowBubble) { // Bubble cell
            isShowBubble = false
            tableView.reloadData()
        }
    }
}

// MARK: - Class

class TawarCell : UITableViewCell {
    @IBOutlet var avatar : UIImageView?
    @IBOutlet var captionMessage : UILabel?
    @IBOutlet var captionArrow : UILabel!
    @IBOutlet var captionTime : KDEDateLabel!
    @IBOutlet var sectionMessage : UIView!
    @IBOutlet var captionSending : UILabel?
    @IBOutlet var btnRetry : UIButton?
    @IBOutlet var imgMessage: UIImageView?
    
    @IBOutlet weak var newCaptionMessage: UITextView!
    
    
    var zoomImgMessage : () -> () = {}
    
    var inboxMessage : InboxMessage?
    
    let formatter = DateFormatter()
    var formattedLongTime : String?
    
    var decorated = false
    
    var toShopPage : () -> () = {}
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
//        imgMessage?.image = nil
        imgMessage?.afCancelRequest()
        captionTime.date = nil
    }
    
    func decor(){
        if (decorated == false) {
            formatter.dateFormat = "dd MMM"
            self.avatar?.layoutIfNeeded()
            self.avatar?.layer.cornerRadius = (self.avatar?.width ?? 0) / 2
            self.avatar?.layer.masksToBounds = true
            
            self.avatar?.layer.borderColor = Theme.GrayLight.cgColor
            self.avatar?.layer.borderWidth = 2
            
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
                self.newCaptionMessage?.textColor = UIColor.white
            } else {
                self.sectionMessage.backgroundColor = UIColor(hexString: "#E8ECEE")
                self.newCaptionMessage?.textColor = UIColor.darkGray
            }
            
            self.btnRetry?.isHidden = true
            self.captionSending?.isHidden = true
            
            if (m.failedToSend) {
                self.newCaptionMessage?.text = "[GAGAL MENGIRIM]\n\n" + m.message
                self.newCaptionMessage?.textColor = UIColor.white
                self.sectionMessage.backgroundColor = UIColor(hexString : "#AC281C")
                self.btnRetry?.isHidden = false
            } else {
                if (m.attachmentType == "image") {
                    self.newCaptionMessage?.isHidden = true
                    self.imgMessage?.isHidden = false
                    self.imgMessage?.afSetImage(withURL: m.attachmentURL)
                } else {
                    self.newCaptionMessage?.isHidden = false
                    self.imgMessage?.isHidden = true
                    self.newCaptionMessage?.text = m.dynamicMessage
                }
            }
            
            if (m.sending) {
                self.captionSending?.isHidden = false
                self.captionTime.text = "mengirim..."
            } else {
                self.captionTime.date = m.dateTime
            }
            
//            if (m.messageType == 1 && !m.isMe) {
//                self.sectionMessage.backgroundColor = UIColor(hexString: "#E8ECEE") // Theme.ThemeOrange
//                self.newCaptionMessage?.textColor = UIColor.darkGray // UIColor.white
//            }
//            
//            if (m.messageType == 3) {
//                self.sectionMessage.backgroundColor = UIColor(hexString: "#E8ECEE")
//                self.newCaptionMessage?.textColor = UIColor.darkGray
//            }
            
//            if (m.attachmentType != "image" && m.dynamicMessage.range(of: "Tawar \n") != nil) {
//                let boldText = m.dynamicMessage.replace("Tawar \n", template: "")
//
//                self.newCaptionMessage.boldSubstring(boldText)
//            }
            
            if (m.attachmentType != "image" && m.dynamicMessage.lowercased().range(of: "tawar") != nil && m.dynamicMessage.range(of: "Rp") != nil) {
                let mystr = m.dynamicMessage
                
                let strs = ["Terima tawaran\n", "Tolak tawaran\n", "Membatalkan tawaran\n", "Tawar\n"]
                
                for i in 0...strs.count-1 {
                    if (mystr.contains(strs[i])) {
                        self.newCaptionMessage.boldSubstring(strs[i])
                    }
                }
                
                let idx = mystr.index(of: "Rp")
                self.newCaptionMessage.increaseSizeSubstring(mystr.substring(from: idx!), size: 20)
            }
            
            self.captionArrow.textColor = self.sectionMessage.backgroundColor
        }
    }
    
    @IBAction func imgMessageTapped(_ sender: UIButton) {
        self.zoomImgMessage()
    }
    
    @IBAction func resendMe(_ sender : UIView) {
        if let m = inboxMessage {
            m.resend()
            self.decor()
        }
    }
    
    @IBAction func gotoShopPage(_ sender: AnyObject) {
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
