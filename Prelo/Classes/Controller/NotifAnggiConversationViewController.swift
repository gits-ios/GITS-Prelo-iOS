//
//  NotifAnggiConversationViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/3/16.
//  Copyright (c) 2016 GITS Indonesia. All rights reserved.
//

import Foundation

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
    
    var notifications : [Notification]?
    
    var delegate : NotifAnggiConversationDelegate?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let notifConversationCellNib = UINib(nibName: "NotifAnggiConversationCell", bundle: nil)
        tableView.registerNib(notifConversationCellNib, forCellReuseIdentifier: "NotifAnggiConversationCell")
        
        // Hide and show
        self.showLoading()
        self.hideContent()
        self.hideBottomLoading()
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(NotifAnggiConversationViewController.refreshPage), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Transparent panel
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        bottomLoadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
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
        request(APINotifAnggi.GetNotifs(tab: "conversation", page: self.currentPage + 1)).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Notifikasi - Percakapan")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                let dataCount = data.count
                
                // Store data into variable
                for (_, item) in data {
                    let n = Notification.instance(item)
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (notifications != nil) {
            return notifications!.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell : NotifAnggiConversationCell = self.tableView.dequeueReusableCellWithIdentifier("NotifAnggiConversationCell") as? NotifAnggiConversationCell {
            cell.selectionStyle = .None
            let n = notifications?[indexPath.item]
            cell.adapt(n!)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.showLoading()
        if let n = notifications?[indexPath.item] {
            if (!n.read) {
                // API Migrasi
        request(APINotifAnggi.ReadNotif(tab: "conversation", id: n.objectId)).responseJSON {resp in
                    if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Notifikasi - Percakapan")) {
                        let json = JSON(resp.result.value!)
                        let data : Bool? = json["_data"].bool
                        if (data != nil && data == true) {
                            self.notifications?[indexPath.item].setRead()
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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 81
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset : CGPoint = scrollView.contentOffset
        let bounds : CGRect = scrollView.bounds
        let size : CGSize = scrollView.contentSize
        let inset : UIEdgeInsets = scrollView.contentInset
        let y : CGFloat = offset.y + bounds.size.height - inset.bottom
        let h : CGFloat = size.height
        
        let reloadDistance : CGFloat = 0
        if (y > h + reloadDistance) {
            // Load next items only if all items not loaded yet and if its not currently loading items
            if (!self.isAllItemLoaded && !self.bottomLoading.isAnimating()) {
                // Show bottomLoading
                self.showBottomLoading()
                
                // Get notif
                self.getNotif()
            }
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func refreshPressed(sender: AnyObject) {
        self.refreshPage()
    }
    
    // MARK: - Other functions
    
    func hideLoading() {
        loadingPanel.hidden = true
        loading.hidden = true
        loading.stopAnimating()
    }
    
    func showLoading() {
        loadingPanel.hidden = false
        loading.hidden = false
        loading.startAnimating()
    }
    
    func hideBottomLoading() {
        bottomLoadingPanel.hidden = true
        bottomLoading.hidden = true
        bottomLoading.stopAnimating()
    }
    
    func showBottomLoading() {
        bottomLoadingPanel.hidden = false
        bottomLoading.hidden = false
        bottomLoading.startAnimating()
    }
    
    func hideContent() {
        tableView.hidden = true
        lblEmpty.hidden = true
        btnRefresh.hidden = true
    }
    
    func showContent() {
        if (self.notifications?.count <= 0) {
            self.lblEmpty.hidden = false
            self.btnRefresh.hidden = false
        } else {
            self.tableView.hidden = false
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
    
    func navigateReadNotif(notif : Notification) {
        if (notif.type == 2000) { // Chat
            // Get inbox detail
            // API Migrasi
        request(APIInbox.GetInboxMessage(inboxId: notif.objectId)).responseJSON {resp in
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Notifikasi - Percakapan")) {
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
            request(Products.Detail(productId: notif.objectId)).responseJSON {resp in
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Notifikasi - Percakapan")) {
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
        self.contentView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0)
        imgSingle.image = UIImage(named: "raisa.jpg")
        vwCaption.backgroundColor = Theme.GrayDark
        lblConvStatus.textColor = Theme.GrayDark
    }
    
    func adapt(notif : Notification) {
        // Set background color
        if (!notif.read) {
            self.contentView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        }
        
        // Set image
        if (notif.productImages.count > 0) {
            imgSingle.setImageWithUrl(NSURL(string: notif.productImages.objectAtCircleIndex(0))!, placeHolderImage: nil)
        }
        
        // Set caption
        lblCaption.text = notif.caption
        if (notif.caption.lowercaseString == "komentar") {
            vwCaption.backgroundColor = Theme.PrimaryColor
        } else if (notif.caption.lowercaseString == "chat") {
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
