//
//  NotifAnggiConversationViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/3/16.
//  Copyright (c) 2016 GITS Indonesia. All rights reserved.
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

protocol NotifAnggiConversationDelegate {
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
    
    var refreshControl : UIRefreshControl!
    var currentPage : Int = 0
    let ItemPerLoad : Int = 10
    var isAllItemLoaded : Bool = false
    
    var notifications : [NotificationObj]?
    
    var delegate : NotifAnggiConversationDelegate?
    
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
        if let cell : NotifAnggiConversationCell = self.tableView.dequeueReusableCell(withIdentifier: "NotifAnggiConversationCell") as? NotifAnggiConversationCell {
            cell.selectionStyle = .none
            let n = notifications?[(indexPath as NSIndexPath).item]
            cell.adapt(n!)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.showLoading()
        if let n = notifications?[(indexPath as NSIndexPath).item] {
            if (!n.read) {
                // API Migrasi
        let _ = request(APINotification.readNotif(tab: "conversation", id: n.objectId)).responseJSON {resp in
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
        if (notif.type == 2000) { // Chat
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
                    self.navigationController?.pushViewController(t, animated: true)
                } else {
                    Constant.showDialog("Notifikasi - Percakapan", message: "Oops, notifikasi inbox tidak bisa dibuka")
                    self.hideLoading()
                    self.showContent()
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
                    self.navigationController?.pushViewController(p, animated: true)
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
    
    override func prepareForReuse() {
        self.contentView.backgroundColor = UIColor.white.withAlphaComponent(0)
        imgSingle.image = UIImage(named: "raisa.jpg")
        vwCaption.backgroundColor = Theme.GrayDark
        lblConvStatus.textColor = Theme.GrayDark
    }
    
    func adapt(_ notif : NotificationObj) {
        // Set background color
        if (!notif.read) {
            self.contentView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        }
        
        // Set image
        if (notif.productImages.count > 0) {
            imgSingle.setImageWithUrl(URL(string: notif.productImages.objectAtCircleIndex(0))!, placeHolderImage: nil)
        }
        
        // Set caption
        lblCaption.text = notif.caption
        if (notif.caption.lowercased() == "komentar") {
            vwCaption.backgroundColor = Theme.PrimaryColor
        } else if (notif.caption.lowercased() == "chat") {
            vwCaption.backgroundColor = Theme.ThemeOrange
        }
        
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
}
