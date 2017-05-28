//
//  PreloMessageViewController.swift
//  Prelo
//
//  Created by Djuned on 3/15/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Crashlytics
import Alamofire
import MessageUI


// MARK: - Class
class PreloMessageViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, MessagePoolDelegate, UIScrollViewDelegate {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    var messages: Array<PreloMessageItem>? // PreloMessageItem
    var isOpens: Array<Bool> = []
    var isFirst: Bool = true
    
    var threadId: String! = ""
    
    var newMessages: Array<PreloMessageItem> = [] // From message pool
    
    @IBOutlet weak var vwTopBannerParent: UIView!
    @IBOutlet weak var consHeightTopBannerParent: NSLayoutConstraint!
    
    var lastContentOffset = CGPoint.zero
    
    @IBOutlet weak var btnScrollToTop: UIButton! // disabled
    @IBOutlet weak var btnScrollToBottom: UIButton! // disabled
    
    @IBOutlet weak var btnBackToTop: BorderedButton!
    
    var deadline = DispatchTime.now()
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.2)
        
        let PreloMessageCell = UINib(nibName: "PreloMessageCell", bundle: nil)
        tableView.register(PreloMessageCell, forCellReuseIdentifier: "PreloMessageCell")
        
        // Setup table
        tableView.tableFooterView = UIView()
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(0, 0, 4, 0)
        tableView.contentInset = inset
        
        tableView.separatorStyle = .none
        
        tableView.backgroundColor = UIColor(hexString: "#E8ECEE") //UIColor(hex: "E5E9EB")
        
        // title
        self.title = "Prelo Message"
        
        // restyling btn back to top
        self.btnBackToTop.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.75)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirst {
            // Setup table
            tableView.dataSource = self
            tableView.delegate = self
            
            getMessage()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.PreloMessage)
        
        if !isFirst {
            if self.threadId != "" {
                // Register delegate for messagepool socket
                if let del = UIApplication.shared.delegate as? AppDelegate {
                    del.messagePool?.registerDelegate(self.threadId, d: self)
                } else {
                    let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
                    Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"PreloMessage Register MessagePool 2"])
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.threadId != "" {
            // Remove messagepool delegate
            if let del = UIApplication.shared.delegate as? AppDelegate {
                del.messagePool?.removeDelegate(self.threadId)
            } else {
                let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"PreloMessage Remove MessagePool"])
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getMessage() {
        self.showLoading()
        
        // clean messages
        self.messages = []
        self.isOpens = []
        
        let _ = request(APIPreloMessage.getMessage).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Get Prelo Message")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if let _messages = data["messages"].array {
                    var curMessages : Array<PreloMessageItem> = []
                    for m in _messages {
                        let message = PreloMessageItem.instance(m)
                        curMessages.append(message!)
                        self.isOpens.append(false)
                    }
                    self.messages = curMessages.reversed()
                    self.tableView.reloadData()
                    self.hideLoading()
                    
                    self.threadId = data["_id"].stringValue
                    print(self.threadId)
                    
                    self.isFirst = false
                    
                    if self.threadId != "" {
                        // Register delegate for messagepool socket
                        if let del = UIApplication.shared.delegate as? AppDelegate {
                            del.messagePool?.registerDelegate(self.threadId, d: self)
                        } else {
                            let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
                            Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"PreloMessage Register MessagePool"])
                        }
                    }
                    
                } else {
                    Constant.showDialog("Prelo Message", message: "Oops, prelo message tidak bisa dibuka")
                    
                    _ = self.navigationController?.popViewController(animated: true)
                    self.hideLoading()
                }
            } else {
                _ = self.navigationController?.popViewController(animated: true)
                self.hideLoading()
            }
        }
    }
    
    // MARK: - Other
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    // MARK: - TableView functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if messages != nil {
            return messages!.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if messages != nil && messages!.count > 0 {
            return PreloMessageCell.heightFor((messages?[(indexPath as NSIndexPath).row])!, isOpen: isOpens[(indexPath as NSIndexPath).row])
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PreloMessageCell") as! PreloMessageCell
        
        if messages != nil && messages!.count > 0 {
            let idx = (indexPath as NSIndexPath).row
            let m = (messages?[idx])!
            
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor(hexString: "#E8ECEE")
            cell.clipsToBounds = true
            cell.adapt(m, isOpen: isOpens[idx])
            
            cell.readMore = {
                self.isOpens[(indexPath as NSIndexPath).row] = true
                tableView.reloadData()
            }
            
            cell.zoomImage = {
                if m.bannerUri != nil {
                    var urlStr = m.bannerUri!.absoluteString
                    if !urlStr.contains("http://") && !urlStr.contains("https://") {
                        urlStr = "https://" + m.bannerUri!.absoluteString
                    }
                    let curl = URL(string: urlStr)!
                    self.openUrl(url: curl)
                } else {
                    /*
                    let c = CoverZoomController()
                    c.labels = [(m.isContainAttachment ? "pesan gambar" : (m.title == "" ? "Prelo Message" : m.title))]
                    c.images = [(m.banner?.absoluteString)!]
                    c.index = 0
                    self.navigationController?.present(c, animated: true, completion: nil)
                     */
                }
            }
            
            cell.openUrl = { url in
                self.openUrl(url: url)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // do nothing
    }
    
    // MARK: - scrollview delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset
        
        /*
        if (currentOffset.y > 4 && currentOffset.y < (tableView.contentSize.height - tableView.height)) {
            //print(currentOffset.y)
            //print((tableView.contentSize.height - tableView.height))
            if (currentOffset.y > self.lastContentOffset.y) {
                // Downward
                self.btnScrollToBottom.isHidden = false
                self.btnScrollToTop.isHidden = true
            } else {
                // Upward
                self.btnScrollToBottom.isHidden = true
                self.btnScrollToTop.isHidden = false
            }
        } else {
            self.btnScrollToBottom.isHidden = true
            self.btnScrollToTop.isHidden = true
        }
         */
        
        if (currentOffset.y > (2 * tableView.height)) {
            self.btnBackToTop.isHidden = false
        } else {
            self.btnBackToTop.isHidden = true
        }
        
        self.lastContentOffset = currentOffset
    }
    
    /*
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.btnScrollToBottom.isHidden = true
        self.btnScrollToTop.isHidden = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.btnScrollToBottom.isHidden = true
        self.btnScrollToTop.isHidden = true
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.btnScrollToBottom.isHidden = true
        self.btnScrollToTop.isHidden = true
    }
     */
    
    // MARK: - Deeplink
    func openUrl(url: URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            var param : [URLQueryItem] = []
            if let items = components.queryItems {
                param = items
            }
            if let del = UIApplication.shared.delegate as? AppDelegate {
                del.handleUniversalLink(url, path: components.path, param: param)
            }
        }
    }
    
    // MARK: - Message pool delegate functions
    
    func messageArrived(_ message: InboxMessage) {
        // do nothing
    }
    
    func preloMessageArrived(_ message: PreloMessageItem) {
        /*
        self.isOpens.insert(false, at: 0)
        self.messages?.insert(message, at: 0)
        self.tableView.reloadData()
         */
        
        self.newMessages.insert(message, at: 0)
        
        self.setupTopBanner()
    }
    
    func showNewMessage() {
        let inset = UIEdgeInsetsMake(0, 0, 4, 0)
        self.tableView.contentInset = inset
        
        self.showLoading()
        
//        print(self.newMessages.count)
//        while self.newMessages.count > 0 {
//            let message = self.newMessages.popLast()
//            self.isOpens.insert(false, at: 0)
//            self.messages?.insert(message!, at: 0)
//        }
        
        // another approach / techniue
        self.getNewMessage(self.newMessages.count)
        self.newMessages.removeAll()
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwTopBannerParent.frame
            curView.origin.y = -self.consHeightTopBannerParent.constant
            self.vwTopBannerParent.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.4, animations: {
            placeSelectionBar()
        })
        
        deadline = DispatchTime.now() + 0.4
        
        // inject center (fixer)
        DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
            self.vwTopBannerParent.isHidden = true
            self.consHeightTopBannerParent.constant = 0
        })
    }
    
    func setupTopBanner() {
        self.vwTopBannerParent.viewWithTag(999)?.removeFromSuperview()
        
        let bannerRecognizer = UITapGestureRecognizer(target: self, action: #selector(PreloMessageViewController.showNewMessage))
        
        let tbText = self.newMessages.count.string + " Prelo Message Baru"
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        var topBannerHeight = CGFloat(30.0)
        let textRect = tbText.boundsWithFontSize(UIFont.systemFont(ofSize: 11), width: screenWidth - 16)
        topBannerHeight += textRect.height
        let topLabelMargin : CGFloat = 8.0
        
        let topBanner : UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: topBannerHeight), backgroundColor: Theme.ThemeOrange)
        topBanner.tag = 999
        topBanner.clipsToBounds = true
        
        let topLabel : UILabel = UILabel(frame: CGRect(x: topLabelMargin, y: 0, width: screenWidth - (topLabelMargin * 2), height: topBannerHeight))
        topLabel.textColor = UIColor.white
        topLabel.font = UIFont.systemFont(ofSize: 11)
        topLabel.lineBreakMode = .byWordWrapping
        topLabel.numberOfLines = 0
        topLabel.text = tbText
        topLabel.clipsToBounds = true
        
        let btn : UIButton = UIButton()
        btn.frame = topBanner.bounds
        btn.addGestureRecognizer(bannerRecognizer)
        btn.clipsToBounds = true
        
        topBanner.addSubview(topLabel)
        topBanner.addSubview(btn)
        
        self.vwTopBannerParent.addSubview(topBanner)
        // fixer
        self.vwTopBannerParent.frame.origin.y = -topBannerHeight
        self.consHeightTopBannerParent.constant = topBannerHeight
        
        self.vwTopBannerParent.isHidden = false
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwTopBannerParent.frame
            curView.origin.y = 0
            self.vwTopBannerParent.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.4, animations: {
            placeSelectionBar()
        })
        
        // inject center (fixer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
            self.vwTopBannerParent.frame.origin.y = 0
            
            let inset = UIEdgeInsetsMake(topBannerHeight, 0, 4, 0)
            self.tableView.contentInset = inset
        })
    }
    
    func scrollToTop() {
        if ((self.messages?.count)! > 0) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: true)
        }
    }
    
    func scrollToBottom() {
        if ((self.messages?.count)! > 0) {
            tableView.scrollToRow(at: IndexPath(row: (self.messages?.count)! - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
        }
    }
    
    func getNewMessage(_ count: Int) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = appDelegate.preloNotifListener
        let newNotifCount = (notifListener?.newNotifCount)! - count
        
        let _ = request(APIPreloMessage.getMessage).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Get New Prelo Message")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if let _messages = data["messages"].array {
                    for m in _messages.count-count..._messages.count-1 {
                        let message = PreloMessageItem.instance(_messages[m])
                        
                        self.isOpens.insert(false, at: 0)
                        self.messages?.insert(message!, at: 0)
                        
                    }
                    notifListener?.setNewNotifCount(newNotifCount)
                    
                    DispatchQueue.main.asyncAfter(deadline: self.deadline, execute: {
                        self.scrollToTop()
                        self.tableView.reloadData()
                        self.hideLoading()
                    })
                } else {
                    Constant.showDialog("Get New Prelo Message", message: "Oops, terdapat kesalahan")
                    
                    self.hideLoading()
                }
            } else {
                Constant.showDialog("Get New Prelo Message", message: "Oops, terdapat kesalahan")
                
                self.hideLoading()
            }
        }
    }
    
    // MARK: - Other
    @IBAction func btnScrollToTopPressed(_ sender: Any) {
        self.scrollToTop()
    }
    
    @IBAction func btnScrollToBottomPressed(_ sender: Any) {
        self.scrollToBottom()
    }
}

// MARK: - PreloMessageCell
class PreloMessageCell: UITableViewCell {
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDesc: ActiveLabel!
    @IBOutlet weak var consHeightBannerImage: NSLayoutConstraint! // default 0 -> 128
    @IBOutlet weak var vwBorder: UIView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var btnReadMore: UIButton! // hidden
    @IBOutlet weak var consTopLblDate: NSLayoutConstraint! // 25.5 -> 4
    @IBOutlet weak var vwGradient: UIView!
    
    var headerUri: URL?
    var desc: String = ""
    
    var readMore : ()->() = {}
    var zoomImage: ()->() = {}
    var openUrl  : (_ url: URL)->() = {_ in }
    
    static func heightFor(_ message : PreloMessageItem, isOpen: Bool) -> CGFloat {
        let standardHeight : CGFloat = 148.0 - 67.0 + 4 - 19.5
        let heightBanner : CGFloat = (((UIScreen.main.bounds.width - 8) / 940.0 /*1024.0*/) * 492.0 /*337.0*/)
        let titleRect = message.title.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 16), width: UIScreen.main.bounds.size.width - 24)
        let textRect = message.desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 24)
        return standardHeight + titleRect.height + (isOpen ? textRect.height - 21.5 : (84.0 > textRect.height ? textRect.height - 21.5 : 67.0)) + (message.banner != nil ? heightBanner : 0) + (message.title == "" ? -19.5 : 0)
        
    }
    
    func adapt(_ message : PreloMessageItem, isOpen: Bool) {
        if message.banner != nil {
            let height = (((UIScreen.main.bounds.width - 8) / 940.0 /*1024.0*/) * 492.0 /*337.0*/)
            self.consHeightBannerImage.constant = height
            self.bannerImage.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 8, height: height)
            self.bannerImage.backgroundColor = UIColor.clear
            
            self.bannerImage.afSetImage(withURL: message.banner!, withFilter: .fitWithPreloMessagePlaceHolder)
            
            /*if message.bannerUri != nil {
                self.headerUri = message.bannerUri!
                vwGradient.isHidden = false
                
                let gradient: CAGradientLayer = CAGradientLayer()
                
                gradient.frame = vwGradient.bounds
                
                gradient.colors = [UIColor.colorWithColor(UIColor.black, alpha: 0).cgColor, UIColor.colorWithColor(UIColor.black, alpha: 0.55).cgColor, UIColor.colorWithColor(UIColor.black, alpha: 1).cgColor]
                gradient.locations = [0.0 , 0.45 , 1.0]
                gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
                gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
                
                if vwGradient.layer.sublayers?.count != nil && (vwGradient.layer.sublayers?.count)! > 1 {
                    vwGradient.layer.sublayers?[0].removeFromSuperlayer()
                }
                
                vwGradient.layer.insertSublayer(gradient, at: 0)
            } else {*/
                self.vwGradient.isHidden = true
            //}
        } else {
            self.consHeightBannerImage.constant = 0
            self.vwGradient.isHidden = true
        }
        
        self.btnReadMore.setTitleColor(Theme.PrimaryColorDark)
        
        self.lblTitle.text = message.title
        self.lblDate.text = message.date
        
//        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(PreloMessageCell.textPressed))
//        self.lblDesc.addGestureRecognizer(longPressRecognizer)
        
        let customType = ActiveType.custom(pattern: "(?:^|\\s|$)prelo.co.id[^\\s]*") //Regex that looks for " prelo.co.id/* "
        let customType2 = ActiveType.custom(pattern: "prelo://[^\\s]*") //Regex that looks for "prelo://* "
        let customType3 = ActiveType.custom(pattern: "(?:^|\\s|$)dev.prelo.id[^\\s]*") //Regex that looks for " prelo.co.id/* "
        self.lblDesc.enabledTypes = [/*.mention, .hashtag,*/ .url, customType, customType2, customType3]
        
        self.lblDesc.URLColor = Theme.PrimaryColorDark
        self.lblDesc.URLSelectedColor = Theme.PrimaryColorDark
        
        self.lblDesc.customColor[customType] = Theme.PrimaryColorDark
        self.lblDesc.customSelectedColor[customType] = Theme.PrimaryColorDark
        
        self.lblDesc.customColor[customType2] = Theme.PrimaryColorDark
        self.lblDesc.customSelectedColor[customType2] = Theme.PrimaryColorDark
        
        self.lblDesc.customColor[customType3] = Theme.PrimaryColorDark
        self.lblDesc.customSelectedColor[customType3] = Theme.PrimaryColorDark
        
        self.lblDesc.handleURLTap{ url in
            var urlStr = url.absoluteString
            if !urlStr.contains("http://") && !urlStr.contains("https://") {
                urlStr = "https://" + url.absoluteString
            }
            let curl = URL(string: urlStr)!
            self.openUrl(curl)
        }
        
        self.lblDesc.handleCustomTap(for: customType) { element in // only prelo.co.id
            let urlStr = "https://" + element
            let curl = URL(string: urlStr)!
            self.openUrl(curl)
        }
        
        self.lblDesc.handleCustomTap(for: customType2) { element in // only prelo://
            // prelo://
            let urlStr = element
            let curl = URL(string: urlStr)!
            self.openUrl(curl)
        }
        
        self.lblDesc.handleCustomTap(for: customType3) { element in // only dev.prelo.id
            let urlStr = "http://" + element
            let curl = URL(string: urlStr)!
            self.openUrl(curl)
        }
        
        self.lblDesc.text = message.desc
        self.desc = message.desc
        
        if message.desc == "pesan gambar" {
            self.lblDesc.font = UIFont.italicSystemFont(ofSize: 14)
            self.lblDesc.textColor = UIColor.lightGray
            self.lblDesc.textAlignment = .center
        } else {
            self.lblDesc.textAlignment = .natural
        }
        
        if isOpen {
            self.lblDesc.numberOfLines = 0
        } else {
            self.lblDesc.numberOfLines = 4
        }
        
        let textRect = message.desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 24)
        if textRect.height <= 84.0 && textRect.height >= 67.0 {
            self.lblDesc.numberOfLines = 5
        }
        
        if textRect.height > 84.0 && !isOpen {
            self.btnReadMore.isHidden = false
            self.consTopLblDate.constant = 29.5
        } else {
            self.btnReadMore.isHidden = true
            self.consTopLblDate.constant = 8
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.bannerImage.afCancelRequest()
        self.lblDesc.font = UIFont.systemFont(ofSize: 14)
        self.lblDesc.textColor = UIColor.init(hex: "#555555")
    }
    
    @IBAction func btnReadMorePressed(_ sender: Any) {
        self.readMore()
    }
    
    @IBAction func btnBannerImagePressed(_ sender: Any) {
        self.zoomImage()
    }
    
    @IBAction func btnBannerLinkPressed(_ sender: Any) {
        if self.headerUri != nil {
            var urlStr = self.headerUri!.absoluteString
            if !urlStr.contains("http://") && !urlStr.contains("https://") && !urlStr.contains("prelo://") {
                urlStr = "http://" + self.headerUri!.absoluteString
            }
            let curl = URL(string: urlStr)!
            self.openUrl(curl)
        }
    }
    
//    func textPressed() {
//        putToPasteBoard(self.desc)
//        Constant.showDialog("Perhatian", message: "Pesan sudah ada di clipboard :)")
//    }
//    
//    func putToPasteBoard(_ text : String) {
//        UIPasteboard.general.string = text
//    }
}
