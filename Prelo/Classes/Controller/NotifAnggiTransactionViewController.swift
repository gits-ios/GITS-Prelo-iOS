//
//  NotifAnggiTransactionViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/3/16.
//  Copyright (c) 2016 GITS Indonesia. All rights reserved.
//

import Foundation

// MARK: - Protocol

protocol NotifAnggiTransactionDelegate {
    func decreaseTransactionBadgeNumber()
}

// MARK: - Class

class NotifAnggiTransactionViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
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

    var delegate : NotifAnggiTransactionDelegate?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        var notifTransactionCellNib = UINib(nibName: "NotifAnggiTransactionCell", bundle: nil)
        tableView.registerNib(notifTransactionCellNib, forCellReuseIdentifier: "NotifAnggiTransactionCell")
        
        // Hide and show
        self.showLoading()
        self.hideContent()
        self.hideBottomLoading()
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: "refreshPage", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Get notif is user is logged in
        if (User.IsLoggedIn == true) {
            self.refreshPage()
        }
        
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
        request(APINotifAnggi.GetNotifs(tab: "transaction", page: self.currentPage + 1)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi - Transaction")) {
                let json = JSON(res!)
                let data = json["_data"]
                let dataCount = data.count
                
                // Store data into variable
                for (index : String, item : JSON) in data {
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
                self.currentPage++
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
        var cell : NotifAnggiTransactionCell = self.tableView.dequeueReusableCellWithIdentifier("NotifAnggiTransactionCell") as! NotifAnggiTransactionCell
        cell.selectionStyle = .None
        let n = notifications?[indexPath.item]
        cell.adapt(n!)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.showLoading()
        if let n = notifications?[indexPath.item] {
            if (!n.read) {
                request(APINotifAnggi.ReadNotif(tab: "transaction", id: n.id)).responseJSON { req, resp, res, err in
                    if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi - Transaction")) {
                        let json = JSON(res!)
                        let data : Bool? = json["_data"].bool
                        if (data != nil && data == true) {
                            self.notifications?[indexPath.item].setRead()
                            self.delegate?.decreaseTransactionBadgeNumber()
                            self.navigateReadNotif(n)
                        } else {
                            Constant.showDialog("Notifikasi - Transaction", message: "Oops, terdapat masalah pada notifikasi")
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
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
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
        // Check if user is seller or buyer
        request(APITransaction.TransactionDetail(id: notif.objectId)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi - Transaction")) {
                let json = JSON(res!)
                let data = json["_data"]
                let tpDetail = TransactionDetail.instance(data)
                if let sellerId = tpDetail?.sellerId {
                    if (sellerId == User.Id) { // User is seller
                        // Goto MyProductDetail
                        let myProductDetailVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyProductDetail, owner: nil, options: nil).first as! MyProductDetailViewController
                        myProductDetailVC.transactionId = notif.objectId
                        self.navigationController?.pushViewController(myProductDetailVC, animated: true)
                    } else { // User is buyer
                        // Goto MyPurchaseDetail
                        let myPurchaseDetailVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchaseDetail, owner: nil, options: nil).first as! MyPurchaseDetailViewController
                        myPurchaseDetailVC.transactionId = notif.objectId
                        self.navigationController?.pushViewController(myPurchaseDetailVC, animated: true)
                    }
                } else {
                    Constant.showDialog("Notifikasi - Transaction", message: "Oops, ada masalah saat mengecek data produk")
                }
            } else {
                self.hideLoading()
                self.showContent()
            }
        }
    }
}

// MARK: - Class

class NotifAnggiTransactionCell : UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var vwSingleImage: UIView!
    @IBOutlet weak var imgSingle: UIImageView!
    @IBOutlet weak var vwDoubleImage: UIView!
    @IBOutlet weak var imgDouble1: UIImageView!
    @IBOutlet weak var imgDouble2: UIImageView!
    @IBOutlet weak var vwCaption: UIView!
    @IBOutlet weak var lblCaption: UILabel!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblTrxStatus: UILabel!
    @IBOutlet weak var consWidthLblTrxStatus: NSLayoutConstraint!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var collcTrxProgress: UICollectionView!
    
    var notif : Notification?
    
    override func prepareForReuse() {
        self.contentView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0)
        imgSingle.image = UIImage(named: "raisa.jpg")
        vwSingleImage.hidden = false
        vwDoubleImage.hidden = true
        vwCaption.backgroundColor = Theme.GrayDark
        lblTrxStatus.textColor = Theme.GrayDark
    }

    func adapt(notif : Notification) {
        // Set background color
        if (!notif.read) {
            self.contentView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        }
        
        // Set image
        if (notif.productImages.count == 1) {
            vwSingleImage.hidden = false
            vwDoubleImage.hidden = true
            imgSingle.setImageWithUrl(NSURL(string: notif.productImages.objectAtCircleIndex(0))!, placeHolderImage: nil)
        } else if (notif.productImages.count > 1) {
            vwSingleImage.hidden = true
            vwDoubleImage.hidden = false
            imgDouble1.setImageWithUrl(NSURL(string: notif.productImages.objectAtCircleIndex(0))!, placeHolderImage: nil)
            imgDouble2.setImageWithUrl(NSURL(string: notif.productImages.objectAtCircleIndex(1))!, placeHolderImage: nil)
        }
        
        // Set caption
        lblCaption.text = notif.caption
        if (notif.caption.lowercaseString == "jual") {
            vwCaption.backgroundColor = Theme.ThemeOrange
        } else if (notif.caption.lowercaseString == "beli") {
            vwCaption.backgroundColor = Theme.PrimaryColor
        }
        
        // Set Labels
        lblProductName.text = notif.objectName
        lblTrxStatus.text = notif.statusText
        lblPrice.text = notif.shortPreview
        lblTime.text = notif.time
        
        // Set trx status text color
        if (notif.progress < 0) {
            lblTrxStatus.textColor = UIColor(red: 197/255, green: 13/255, blue: 13/255, alpha: 1)
        }
        
        // Set trx status text width
        let sizeThatShouldFitTheContent = lblTrxStatus.sizeThatFits(lblTrxStatus.frame.size)
        //println("size untuk '\(lblTrxStatus.text)' = \(sizeThatShouldFitTheContent)")
        consWidthLblTrxStatus.constant = sizeThatShouldFitTheContent.width
        
        // Set collection view
        self.notif = notif
        collcTrxProgress.backgroundColor = UIColor.clearColor()
        collcTrxProgress.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcTrxProgressCell")
        collcTrxProgress.delegate = self
        collcTrxProgress.dataSource = self
        collcTrxProgress.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let progress = self.notif?.progress {
            if (progress > 0) {
                return 6
            } else if (progress == -1) { // Expired
                return 1
            } else if (progress == -3) { // Rejected by seller
                return 4
            } else if (progress == -4) { // Not sent
                return 4
            }
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = collcTrxProgress.dequeueReusableCellWithReuseIdentifier("collcTrxProgressCell", forIndexPath: indexPath) as! UICollectionViewCell
        
        // Create icon view
        let vwIcon : UIView = UIView(frame: CGRectMake(0, 0, 25, 25))
        vwIcon.layer.cornerRadius = (vwIcon.frame.size.width) / 2
        
        // Set background color
        let idx = indexPath.row + 1
        if (self.notif?.progress < 0) {
            let nItem = self.collectionView(collectionView, numberOfItemsInSection: 0)
            if (nItem < 6) {
                if (idx < nItem) {
                    if (self.notif?.caption.lowercaseString == "jual") {
                        vwIcon.backgroundColor = Theme.ThemeOrange
                    } else if (self.notif?.caption.lowercaseString == "beli") {
                        vwIcon.backgroundColor = Theme.PrimaryColor
                    }
                } else {
                    vwIcon.backgroundColor = UIColor(red: 197/255, green: 13/255, blue: 13/255, alpha: 1)
                }
            }
        } else if (self.notif?.caption.lowercaseString == "jual") {
            if (idx <= self.notif?.progress) {
                vwIcon.backgroundColor = Theme.ThemeOrange
            } else {
                vwIcon.backgroundColor = Theme.GrayLight
            }
        } else if (self.notif?.caption.lowercaseString == "beli") {
            if (idx <= self.notif?.progress) {
                vwIcon.backgroundColor = Theme.PrimaryColor
            } else {
                vwIcon.backgroundColor = Theme.GrayLight
            }
        }
        
        // Create icon image
        var imgName : String?
        if let progress = self.notif?.progress {
            if (progress == -1 && idx == 1) { // Expired
                imgName = "ic_trx_expired"
            } else if (progress == -3 && idx == 4) { // Rejected by seller
                imgName = "ic_trx_exclamation"
            } else if (progress == -4 && idx == 4) { // Not sent
                imgName = "ic_trx_canceled"
            } else {
                if (idx == 1) { // Not paid
                    imgName = "ic_trx_expired"
                } else if (idx == 2) { // Claimed paid
                    imgName = "ic_trx_wait"
                } else if (idx == 3) { // Confirmed paid
                    imgName = "ic_trx_paid"
                } else if (idx == 4) { // Sent
                    imgName = "ic_trx_shipped"
                } else if (idx == 5) { // Received
                    imgName = "ic_trx_received"
                } else if (idx == 6) { // Reviewed
                    imgName = "ic_trx_done"
                }
            }
        }
        if (imgName != nil) {
            if let imgIcon = UIImage(named: imgName!) {
                let imgVwIcon : UIImageView = UIImageView(frame: CGRectMake(5, 5, 15, 15), image: imgIcon)
                vwIcon.addSubview(imgVwIcon)
            }
        }
        
        // Add view to cell
        cell.addSubview(vwIcon)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(25, 25)
    }
}