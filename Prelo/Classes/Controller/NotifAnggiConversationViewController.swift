//
//  NotifAnggiConversationViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/3/16.
//  Copyright (c) 2016 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

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

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


// MARK: - NotifAnggiConversation Protocol

protocol NotifAnggiConversationDelegate: class {
    func decreaseConversationBadgeNumber()
}

// MARK: - Class

class NotifAnggiConversationViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var btnRefresh: UIButton!
    @IBOutlet weak var bottomLoadingPanel: UIView!
    @IBOutlet weak var bottomLoading: UIActivityIndicatorView!
    
    
    // for delete notif
    @IBOutlet weak var consHeightCheckBoxAll: NSLayoutConstraint! // default : 0 --> 64
    @IBOutlet weak var lblCheckBox: UILabel! // default : hidden
    
    @IBOutlet weak var consHeightButtonView: NSLayoutConstraint! // default : 0 --> 56
    @IBOutlet weak var btnBatal: UIButton!
    @IBOutlet weak var btnHapus: UIButton! // to update label with count
    
    // for confirm delete
    @IBOutlet weak var overlayPopUp: UIView!
    @IBOutlet weak var backgroundOverlay: UIView!
    
    var refreshControl : UIRefreshControl!
    var currentPage : Int = 0
    let ItemPerLoad : Int = 10
    var isAllItemLoaded : Bool = false
    
    var notifications : [NotificationObj]?
    
    weak var delegate : NotifAnggiConversationDelegate?
    
    var isToDelete : Bool = false
    
    var notifIds : [String] = []
    
    var isMacro : Bool = false
    
    var countDecreaseNotifCount = 0
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let notifConversationCellNib = UINib(nibName: "NotifAnggiConversationCell", bundle: nil)
        tableView.register(notifConversationCellNib, forCellReuseIdentifier: "NotifAnggiConversationCell")
        
        // Hide and show
        self.showLoading()
        self.hideContent()
        self.hideBottomLoading()
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(NotifAnggiConversationViewController.refreshPage), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Transparent panel
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        bottomLoadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
//        btnBatal.layer.borderWidth = 1
//        btnBatal.layer.borderColor = UIColor.white.cgColor
//        
//        btnHapus.layer.borderWidth = 1
//        btnHapus.layer.borderColor = UIColor.white.cgColor
        
        
        // Transparent panel
        self.backgroundOverlay.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
    }
    
    func refreshPage() {
        // Reset data
        self.notifications = []
        self.currentPage = 0
        self.isAllItemLoaded = false
        self.showLoading()
        self.hideContent()
        
        getNotif()
    }
    
    func getNotif() {
        // API Migrasi
        let _ = request(APINotification.getNotifs(tab: "conversation", page: self.currentPage + 1)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Percakapan")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                let dataCount = data.count
                
                // Store data into variable
                for (_, item) in data {
                    let n = NotificationObj.instance(item)
                    if (n != nil) {
                        self.notifications?.append(n!)
                    }
                }
                
                // Check if all data are already loaded
                if (dataCount < self.ItemPerLoad) {
                    self.isAllItemLoaded = true
                }
                
                // Set next page
                self.currentPage += 1
            }
            
            // Hide loading (for first time request)
            self.hideLoading()
            
            // Hide bottomLoading (for next request)
            self.hideBottomLoading()
            
            // Hide refreshControl (for refreshing)
            self.refreshControl.endRefreshing()
            
            if self.isMacro {
                self.notifIds = []
                for idx in 0...(self.notifications?.count)!-1 {
                    self.notifIds.append(self.notifications![idx].id)
                }
                self.tableView.reloadData()
            }
            
            // Show content
            self.showContent()
        }
    }
    
    // MARK: - TableView delegate functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (notifications != nil) {
            return notifications!.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell : NotifAnggiConversationCell = self.tableView.dequeueReusableCell(withIdentifier: "NotifAnggiConversationCell") as? NotifAnggiConversationCell, notifications != nil, notifications!.count > (indexPath as NSIndexPath).item {
            cell.selectionStyle = .none
            if let n = notifications?[(indexPath as NSIndexPath).item] {
                cell.adapt(n)
            
                if isToDelete {
                    cell.vwCheckBox.isHidden = false
                    cell.consLeadingImage.constant = 48
                    
                    let idx = notifIds.index(of: n.id)
                    if idx != nil {
                        cell.lblCheckBox.isHidden = false
                    } else {
                        cell.lblCheckBox.isHidden = true
                    }
                    self.btnHapus.setTitle("HAPUS (" + notifIds.count.string + ")",for: .normal)
                } else {
                    cell.vwCheckBox.isHidden = true
                    cell.consLeadingImage.constant = 0
                    
                    cell.lblCheckBox.isHidden = true
                }
            }
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (isToDelete) {
            if let n = notifications?[(indexPath as NSIndexPath).item] {
                let idx = notifIds.index(of: n.id)
                if idx != nil {
                    notifIds.remove(at: idx!)
                    if !((self.notifications?[(indexPath as NSIndexPath).item].read)!) {
                        self.countDecreaseNotifCount -= 1
                    }
                } else {
                    notifIds.append(n.id)
                    if !((self.notifications?[(indexPath as NSIndexPath).item].read)!) {
                        self.countDecreaseNotifCount += 1
                    }
                }
                tableView.reloadData()
            }
        } else {
            self.showLoading()
            if let n = notifications?[(indexPath as NSIndexPath).item] {
                if (!n.read) {
                    // API Migrasi
                    let _ = request(APINotification.readNotif(tab: "conversation", id: n.objectId, type: n.type.string)).responseJSON {resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Percakapan")) {
                            let json = JSON(resp.result.value!)
                            let data : Bool? = json["_data"].bool
                            if (data != nil && data == true) {
                                self.notifications?[(indexPath as NSIndexPath).item].setRead()
                                self.delegate?.decreaseConversationBadgeNumber()
                                self.navigateReadNotif(n)
                            } else {
                                Constant.showDialog("Notifikasi - Percakapan", message: "Oops, terdapat masalah pada notifikasi")
                                self.hideLoading()
                            }
                        } else {
                            self.hideLoading()
                        }
                    }
                } else {
                    self.navigateReadNotif(n)
                }
            } else {
                self.hideLoading()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset : CGPoint = scrollView.contentOffset
        let bounds : CGRect = scrollView.bounds
        let size : CGSize = scrollView.contentSize
        let inset : UIEdgeInsets = scrollView.contentInset
        let y : CGFloat = offset.y + bounds.size.height - inset.bottom
        let h : CGFloat = size.height
        
        let reloadDistance : CGFloat = 0
        if (y > h + reloadDistance) {
            // Load next items only if all items not loaded yet and if its not currently loading items
            if (!self.isAllItemLoaded && !self.bottomLoading.isAnimating) {
                // Show bottomLoading
                self.showBottomLoading()
                
                // Get notif
                self.getNotif()
            }
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func refreshPressed(_ sender: AnyObject) {
        self.refreshPage()
    }
    
    @IBAction func btnCheckBoxAllPressed(_ sender: Any) {
        if (isMacro) {
            self.lblCheckBox.isHidden = true
            self.isMacro = false
            self.notifIds = []
            self.tableView.reloadData()

        } else {
            self.lblCheckBox.isHidden = false
            self.isMacro = true
            self.notifIds = []
            for idx in 0...(self.notifications?.count)!-1 {
                notifIds.append(self.notifications![idx].id)
            }
            self.tableView.reloadData()
        }
    }
    
    @IBAction func btnBatalPressed(_ sender: Any) {
        self.isToDelete = false
        self.consHeightCheckBoxAll.constant = 0
        self.lblCheckBox.isHidden = true
        self.consHeightButtonView.constant = 0
        self.notifIds = []
        self.tableView.reloadData()
    }
    
    @IBAction func btnHapusPressed(_ sender: Any) {
        // do something
        if notifIds.count > 0 {
            self.backgroundOverlay.isHidden = false
            self.overlayPopUp.isHidden = false
        } else {
            Constant.showDialog("Perhatian", message: "Pesan wajib dipilih")
        }
        
    }
    
    @IBAction func btnBatalPopUpPressed(_ sender: Any) {
        self.backgroundOverlay.isHidden = true
        self.overlayPopUp.isHidden = true
    }
    
    @IBAction func btnHapusPopUpPressed(_ sender: Any) {
        self.backgroundOverlay.isHidden = true
        self.overlayPopUp.isHidden = true
        // call api
        
        let _ = request(APINotification.deleteNotif(tab: "conversation", notifIds: AppToolsObjC.jsonString(from: self.notifIds))).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Delete Notifications")) {
                
                self.refreshPage()
                self.notifIds = []
                self.isMacro = false
                
                self.isToDelete = false
                self.consHeightCheckBoxAll.constant = 0
                self.lblCheckBox.isHidden = true
                self.consHeightButtonView.constant = 0
                
                Constant.showDialog("Hapus Pesan", message: "Pesan telah berhasil dihapus")
                
                if self.countDecreaseNotifCount > 0 {
                    for _ in 0...self.countDecreaseNotifCount-1 {
                        self.delegate?.decreaseConversationBadgeNumber()
                    }
                }
            }
        }

        
        // messagebox --> inside success api
//        Constant.showDialog("Hapus Pesan", message: "Pesan berhasil dihapus")
    }
    
    // MARK: - Other functions
    
    func hideLoading() {
        loadingPanel.isHidden = true
        loading.isHidden = true
        loading.stopAnimating()
    }
    
    func showLoading() {
        loadingPanel.isHidden = false
        loading.isHidden = false
        loading.startAnimating()
    }
    
    func hideBottomLoading() {
        bottomLoadingPanel.isHidden = true
        bottomLoading.isHidden = true
        bottomLoading.stopAnimating()
    }
    
    func showBottomLoading() {
        bottomLoadingPanel.isHidden = false
        bottomLoading.isHidden = false
        bottomLoading.startAnimating()
    }
    
    func hideContent() {
        tableView.isHidden = true
        lblEmpty.isHidden = true
        btnRefresh.isHidden = true
    }
    
    func showContent() {
        if (self.notifications?.count <= 0) {
            self.lblEmpty.isHidden = false
            self.btnRefresh.isHidden = false
        } else {
            self.tableView.isHidden = false
            self.setupTable()
        }
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
    
    func navigateReadNotif(_ notif : NotificationObj) {
        
        // Prelo Analytic - Click Notification (in App)
        self.sendClickNotificationAnalytic(notif.objectId, tipe: notif.type)
        
        if (notif.type == 2000) { // Chat
            if (notif.userUsernameFrom == "Prelo") {
                let preloMessageVC = Bundle.main.loadNibNamed(Tags.XibNamePreloMessage, owner: nil, options: nil)?.first as! PreloMessageViewController
                preloMessageVC.previousScreen = PageName.Notification
                self.navigationController?.pushViewController(preloMessageVC, animated: true)
            } else {
                // Get inbox detail
                // API Migrasi
                let _ = request(APIInbox.getInboxMessage(inboxId: notif.objectId)).responseJSON {resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Percakapan")) {
                        let json = JSON(resp.result.value!)
                        let data = json["_data"]
                        let inboxData = Inbox(jsn: data)
                        
                        // Goto inbox
                        let t = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdTawar) as! TawarViewController
                        t.tawarItem = inboxData
                        t.previousScreen = PageName.Notification
                        t.isSellerNotActive = data["shop_closed"].bool ?? false
                        t.phoneNumber = data["seller_phone"].string ?? ""
                        self.navigationController?.pushViewController(t, animated: true)
                    } else {
                        Constant.showDialog("Notifikasi - Percakapan", message: "Oops, notifikasi inbox tidak bisa dibuka")
                        self.hideLoading()
                        self.showContent()
                    }
                }
            }
        } else if (notif.type == 3000) { // Komentar
            // Get product detail
            let _ = request(APIProduct.detail(productId: notif.objectId, forEdit: 0)).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Percakapan")) {
                    let json = JSON(resp.result.value!)
                    let pDetail = ProductDetail.instance(json)
                    
                    // Goto product comments
                    let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdProductComments) as! ProductCommentsController
                    p.pDetail = pDetail
                    p.previousScreen = PageName.Notification
                    self.navigationController?.pushViewController(p, animated: true)
                } else {
                    Constant.showDialog("Notifikasi - Percakapan", message: "Oops, notifikasi komentar tidak bisa dibuka")
                    self.hideLoading()
                    self.showContent()
                }
            }
            
        } else if (notif.type == 4000) { // Lovelist
            let productLovelistVC = Bundle.main.loadNibNamed(Tags.XibNameProductLovelist, owner: nil, options: nil)?.first as! ProductLovelistViewController
            productLovelistVC.productId = notif.objectId
            self.navigationController?.pushViewController(productLovelistVC, animated: true)
            
        } else if (notif.type == 4001) { // Another lovelist
            // Get product detail
            let _ = request(APIProduct.detail(productId: notif.objectId, forEdit: 0)).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Percakapan")) {
                    let json = JSON(resp.result.value!)
                    let p = Product.instance(json["_data"])
                    
                    // Goto product detail
                    let productDetailVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                    productDetailVC.product  = p
                    productDetailVC.previousScreen = PageName.Notification
                    self.navigationController?.pushViewController(productDetailVC, animated: true)
                } else {
                    Constant.showDialog("Notifikasi - Percakapan", message: "Oops, notifikasi komentar tidak bisa dibuka")
                    self.hideLoading()
                    self.showContent()
                }
            }
        } else {
            Constant.showDialog("Notifikasi - Percakapan", message: "Oops, notifikasi tidak bisa dibuka")
            self.hideLoading()
            self.showContent()
        }
    }
    
    // Prelo Analytic - Click Notification (in App)
    func sendClickNotificationAnalytic(_ targetId: String, tipe: Int) {
        let type = [
            1000 : "Transaction",
            2000 : "Chat",
            3000 : "Comment",
            4000 : "Lovelist",
            4001 : "Sale Lovelist"
        ]
        
        let curType = type[tipe] ?? tipe.string
        
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            "Object ID" : targetId,
            "Type" : curType
        ] as [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ClickNotificationInApp, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
    }
}

// MARK: - Class

class NotifAnggiConversationCell: UITableViewCell {
    @IBOutlet weak var imgSingle: UIImageView!
    @IBOutlet weak var vwCaption: UIView!
    @IBOutlet weak var lblCaption: UILabel!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblPreview: UILabel!
    @IBOutlet weak var lblConvStatus: UILabel!
    @IBOutlet weak var consWidthLblConvStatus: NSLayoutConstraint!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var consWidthLblTime: NSLayoutConstraint!
    @IBOutlet var vwCompleteContent: UIView!
    @IBOutlet var vwPreviewNTimeOnly: UIView!
    @IBOutlet var lblPreview2: UILabel!
    @IBOutlet var lblTime2: UILabel!
    @IBOutlet var lblProductName2: UILabel!
    @IBOutlet weak var consHeightLblProductName2: NSLayoutConstraint!
    
    // for delete notif
    @IBOutlet weak var vwCheckBox: UIView! // default : hidden
    @IBOutlet weak var consLeadingImage: NSLayoutConstraint! // default : 0 --> 48
    @IBOutlet weak var lblCheckBox: UILabel! // default : hidden (uncheck)
    
    override func awakeFromNib() {
        vwPreviewNTimeOnly.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0)
        vwCompleteContent.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0)
    }
    
    override func prepareForReuse() {
        imgSingle.afCancelRequest()
        
        self.contentView.backgroundColor = UIColor.white.withAlphaComponent(0)
//        imgSingle.image = UIImage(named: "raisa.jpg")
        imgSingle.image = UIImage(named: "placeholder-standar")
        vwCaption.backgroundColor = Theme.GrayDark
        lblConvStatus.textColor = Theme.GrayDark
        
        imgSingle.backgroundColor = UIColor.clear
        imgSingle.contentMode = .scaleAspectFill
        vwCaption.isHidden = false
    }
    
    func adapt(_ notif : NotificationObj) {
        // Set background color
        if (!notif.read) {
            self.contentView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        }
        
        // Set image
        if (notif.userUsernameFrom != "Prelo") {
            if (notif.productImages.count > 0) {
                imgSingle.afSetImage(withURL: URL(string: notif.productImages.objectAtCircleIndex(0))!)
            } else {
                imgSingle.image = UIImage(named: "placeholder-standar")
                imgSingle.afInflate()
            }
        }
        
        // Set caption
        lblCaption.text = notif.caption
        if (notif.type == 3000) { // komentar
            vwCaption.backgroundColor = Theme.PrimaryColor
        } else if (notif.type == 2000) { // chat
            vwCaption.backgroundColor = Theme.ThemeOrange
        } else if (notif.type == 4000 || notif.type == 4001) { // lovelist
            vwCaption.backgroundColor = Theme.ThemeRed
        }
        
        if (notif.type == 4000 || notif.type == 4001) { // lovelist
            // Show group
            vwCompleteContent.isHidden = true
            vwPreviewNTimeOnly.isHidden = false
            
            // Set labels
            lblPreview2.text = notif.shortPreview
            lblTime2.text = notif.time
            
            if (notif.type == 4001) {
                consHeightLblProductName2.constant = 16
                lblProductName2.text = notif.objectName
            } else {
                consHeightLblProductName2.constant = 0
                lblProductName2.isHidden = true
            }
            
            // Bold subtext in label
            lblPreview2.boldSubstring(notif.userUsernameFrom)
            lblPreview2.boldSubstring(notif.objectName)
        } else {
            // Hide group
            vwCompleteContent.isHidden = false
            vwPreviewNTimeOnly.isHidden = true
            
            // Set labels
            lblUsername.text = notif.userUsernameFrom
            lblProductName.text = notif.objectName
            lblPreview.text = notif.shortPreview
            lblConvStatus.text = notif.statusText
            lblTime.text = notif.time
            
            // Set conv status text width
            var sizeThatShouldFitTheContent = lblConvStatus.sizeThatFits(lblConvStatus.frame.size)
            //print("size untuk '\(lblConvStatus.text)' = \(sizeThatShouldFitTheContent)")
            consWidthLblConvStatus.constant = sizeThatShouldFitTheContent.width
            
            // Set time text width
            sizeThatShouldFitTheContent = lblTime.sizeThatFits(lblTime.frame.size)
            //print("size untuk '\(lblTime)' = \(sizeThatShouldFitTheContent)")
            consWidthLblTime.constant = sizeThatShouldFitTheContent.width
        }
        
        if (notif.userUsernameFrom == "Prelo") {
            let oldImage = UIImage(named: "ic_prelo_logo_text_white@2x")?.resizeWithMaxWidth(120)
            
            // Setup a new context with the correct size
            let width: CGFloat = 128
            let height: CGFloat = 128
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), NO, 0.0)
            let context: CGContext = UIGraphicsGetCurrentContext()!
            UIGraphicsPushContext(context)
            
            // Now we can draw anything we want into this new context.
            let origin: CGPoint = CGPoint(x: (width - oldImage!.size.width) / 2.0,
                                          y: (height - oldImage!.size.height) / 2.0)
            oldImage?.draw(at: origin)
            
            // Clean up and get the new image.
            UIGraphicsPopContext();
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext();
            
            lblUsername.text = "Prelo Message"
            imgSingle.backgroundColor = Theme.PrimaryColor
            imgSingle.image = newImage
            imgSingle.afInflate()
            imgSingle.contentMode = .scaleAspectFit
            vwCaption.isHidden = true
        }
    }
}
