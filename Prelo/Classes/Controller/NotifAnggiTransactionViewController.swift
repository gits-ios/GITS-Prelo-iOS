//
//  NotifAnggiTransactionViewController.swift
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


// MARK: - NotifAnggiTransaction Protocol

protocol NotifAnggiTransactionDelegate {
    func decreaseTransactionBadgeNumber()
}

// MARK: - Class

class NotifAnggiTransactionViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, NotifAnggiTransactionCellDelegate {
    
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

    var delegate : NotifAnggiTransactionDelegate?
    
    var isToDelete : Bool = false
    
    var notifIds : [String] = []
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let notifTransactionCellNib = UINib(nibName: "NotifAnggiTransactionCell", bundle: nil)
        tableView.register(notifTransactionCellNib, forCellReuseIdentifier: "NotifAnggiTransactionCell")
        
        // Hide and show
        self.showLoading()
        self.hideContent()
        self.hideBottomLoading()
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(NotifAnggiTransactionViewController.refreshPage), for: UIControlEvents.valueChanged)
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
        let _ = request(APINotification.getNotifs(tab: "transaction", page: self.currentPage + 1)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Transaksi")) {
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
        if let cell : NotifAnggiTransactionCell = self.tableView.dequeueReusableCell(withIdentifier: "NotifAnggiTransactionCell") as? NotifAnggiTransactionCell, notifications != nil, notifications!.count > (indexPath as NSIndexPath).item {
            cell.selectionStyle = .none
            if let n = notifications?[(indexPath as NSIndexPath).item] {
                cell.adapt(n, idx: (indexPath as NSIndexPath).item)
                cell.delegate = self
                
                if (isToDelete == true) {
                    cell.vwCheckBox.isHidden = false
                    cell.consLeadingImage.constant = 48
                    
                    let idx = notifIds.index(of: n.id)
                    if idx != nil {
                        cell.lblCheckBox.isHidden = false
                    } else {
                        cell.lblCheckBox.isHidden = true
                    }
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
                } else {
                    notifIds.append(n.id)
                }
                tableView.reloadData()
            }
        } else {
            self.readNotif((indexPath as NSIndexPath).item)
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
    
    // MARK: - NotifAnggiTransactionCell delegate function
    
    func cellCollectionTapped(_ idx: Int) {
        self.readNotif(idx)
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
    
    func readNotif(_ idx : Int) {
        self.showLoading()
        if let n = notifications?[idx] {
            if (!n.read) {
                // API Migrasi
                let _ = request(APINotification.readNotif(tab: "transaction", id: n.objectId, type: n.type.string)).responseJSON {resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Transaksi")) {
                        let json = JSON(resp.result.value!)
                        let data : Bool? = json["_data"].bool
                        if (data != nil && data == true) {
                            self.notifications?[idx].setRead()
                            self.delegate?.decreaseTransactionBadgeNumber()
                            self.navigateReadNotif(n)
                        } else {
                            Constant.showDialog("Notifikasi - Transaksi", message: "Oops, terdapat masalah pada notifikasi")
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
    
    func navigateReadNotif(_ notif : NotificationObj) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let transactionDetailVC : TransactionDetailViewController = (mainStoryboard.instantiateViewController(withIdentifier: "TransactionDetail") as? TransactionDetailViewController)!
        
        // Set trxId/trxProductId
        if (notif.progress == TransactionDetailTools.ProgressExpired ||
            notif.progress == TransactionDetailTools.ProgressNotPaid ||
            notif.progress == TransactionDetailTools.ProgressClaimedPaid ||
            notif.progress == TransactionDetailTools.ProgressFraudDetected) {
            transactionDetailVC.trxId = notif.objectId
        } else if (notif.progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (notif.caption.lowercased() == "jual") {
                transactionDetailVC.trxId = notif.objectId
            } else if (notif.caption.lowercased() == "beli") {
                transactionDetailVC.trxProductId = notif.objectId
            }
        } else {
            transactionDetailVC.trxProductId = notif.objectId
        }
        
        // Set isSeller
        if (notif.caption.lowercased() == "jual") {
            transactionDetailVC.isSeller = true
        } else if (notif.caption.lowercased() == "beli") {
            transactionDetailVC.isSeller = false
        }
        self.navigationController?.pushViewController(transactionDetailVC, animated: true)
        
        // Check if user is seller or buyer
        /*// API Migrasi
        let _ = request(APITransaction.TransactionDetail(id: notif.objectId)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Transaksi")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                let tpDetail = TransactionProductDetail.instance(data)
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
                    Constant.showDialog("Notifikasi - Transaksi", message: "Oops, ada masalah saat mengecek data barang")
                }
            } else {
                self.hideLoading()
                self.showContent()
            }
        }*/
    }
}

// MARK: - NotifAnggiTransactionCell Protocol

protocol NotifAnggiTransactionCellDelegate {
    func cellCollectionTapped(_ idx : Int)
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
    
    // for delete notif
    @IBOutlet weak var consLeadingImage: NSLayoutConstraint! // default : 0 --> 48
    @IBOutlet weak var vwCheckBox: UIView! // default : hidden
    @IBOutlet weak var lblCheckBox: UILabel! // default : hidden
    
    
    var notif : NotificationObj?
    var idx : Int?
    
    var delegate : NotifAnggiTransactionCellDelegate?
    
    var isDiffUnread : Bool = true
    
    override func prepareForReuse() {
        self.contentView.backgroundColor = UIColor.white.withAlphaComponent(0)
        imgSingle.image = UIImage(named: "raisa.jpg")
        vwSingleImage.isHidden = false
        vwDoubleImage.isHidden = true
        vwCaption.backgroundColor = Theme.GrayDark
        lblTrxStatus.textColor = Theme.GrayDark
    }

    func adapt(_ notif : NotificationObj, idx : Int) {
        // Set background color
        if (!notif.read && isDiffUnread) {
            self.contentView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        }
        
        // Set image
        if (notif.productImages.count == 1) {
            vwSingleImage.isHidden = false
            vwDoubleImage.isHidden = true
            imgSingle.afSetImage(withURL: URL(string: notif.productImages.objectAtCircleIndex(0))!)
        } else if (notif.productImages.count > 1) {
            vwSingleImage.isHidden = true
            vwDoubleImage.isHidden = false
            imgDouble1.afSetImage(withURL: URL(string: notif.productImages.objectAtCircleIndex(0))!)
            imgDouble2.afSetImage(withURL: URL(string: notif.productImages.objectAtCircleIndex(1))!)
        }
        
        // Set caption
        lblCaption.text = notif.caption
        if (notif.caption.lowercased() == "jual") {
            vwCaption.backgroundColor = Theme.ThemeOrange
        } else if (notif.caption.lowercased() == "beli") {
            vwCaption.backgroundColor = Theme.PrimaryColor
        }
        
        // Set Labels
        lblProductName.text = notif.objectName
        lblTrxStatus.text = notif.statusText
        lblPrice.text = notif.shortPreview
        lblTime.text = notif.time
        
        // Set trx status text color
        if (notif.progress < 0) {
            lblTrxStatus.textColor = Theme.ThemeRed
        }
        
        // Set trx status text width
        let sizeThatShouldFitTheContent = lblTrxStatus.sizeThatFits(lblTrxStatus.frame.size)
        //print("size untuk '\(lblTrxStatus.text)' = \(sizeThatShouldFitTheContent)")
        consWidthLblTrxStatus.constant = sizeThatShouldFitTheContent.width
        
        // Set collection view
        collcTrxProgress.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcTrxProgressCell")
        collcTrxProgress.delegate = self
        collcTrxProgress.dataSource = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NotifAnggiTransactionCell.handleTap))
        tapGestureRecognizer.delegate = self
        collcTrxProgress.backgroundView = UIView(frame: collcTrxProgress.bounds)
        collcTrxProgress.backgroundView!.addGestureRecognizer(tapGestureRecognizer)
        collcTrxProgress.backgroundColor = UIColor.clear
        collcTrxProgress.reloadData()
        
        // Set var
        self.notif = notif
        self.idx = idx
    }
    
    func handleTap() {
        if (idx != nil) {
            delegate?.cellCollectionTapped(self.idx!)
        }
    }
    
    // MARK: - CollectionView delegate functions
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let progress = self.notif?.progress {
            if (TransactionDetailTools.isReservationProgress(progress)) {
                return 2
            } else if (TransactionDetailTools.isRefundProgress(progress)) {
                return 4
            } else if (progress == TransactionDetailTools.ProgressExpired) {
                return 1
            } else if (progress == TransactionDetailTools.ProgressRejectedBySeller) {
                return 4
            } else if (progress == TransactionDetailTools.ProgressNotSent) {
                return 4
            } else if (progress == TransactionDetailTools.ProgressFraudDetected) {
                return 1
            } else { // Default
                return 6
            }
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = collcTrxProgress.dequeueReusableCell(withReuseIdentifier: "collcTrxProgressCell", for: indexPath) 
        
        // Create icon view
        let vwIcon : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        vwIcon.layer.cornerRadius = (vwIcon.frame.size.width) / 2
        
        // Set background color
        let idx = (indexPath as NSIndexPath).row + 1
        if (TransactionDetailTools.isReservationProgress(self.notif?.progress)) {
            if (idx == 1) {
                if (self.notif?.caption.lowercased() == "jual") {
                    vwIcon.backgroundColor = Theme.ThemeOrange
                } else if (self.notif?.caption.lowercased() == "beli") {
                    vwIcon.backgroundColor = Theme.PrimaryColor
                }
            } else {
                let progress = self.notif!.progress
                if (progress == 7) {
                    vwIcon.backgroundColor = Theme.GrayLight
                } else if (progress == 8) {
                    if (self.notif?.caption.lowercased() == "jual") {
                        vwIcon.backgroundColor = Theme.ThemeOrange
                    } else if (self.notif?.caption.lowercased() == "beli") {
                        vwIcon.backgroundColor = Theme.PrimaryColor
                    }
                } else if (progress == -2) {
                    vwIcon.backgroundColor = Theme.ThemeRed
                }
            }
        } else if (TransactionDetailTools.isRefundProgress(self.notif?.progress)) {
            if (idx - 1 <= (self.notif?.progress ?? 30) - 30) {
                vwIcon.backgroundColor = Theme.ThemeRed
            } else {
                vwIcon.backgroundColor = Theme.GrayLight
            }
        } else {
            if (self.notif?.progress < 0) {
                let nItem = self.collectionView(collectionView, numberOfItemsInSection: 0)
                if (nItem < 6) {
                    if (idx < nItem) {
                        if (self.notif?.caption.lowercased() == "jual") {
                            vwIcon.backgroundColor = Theme.ThemeOrange
                        } else if (self.notif?.caption.lowercased() == "beli") {
                            vwIcon.backgroundColor = Theme.PrimaryColor
                        }
                    } else {
                        vwIcon.backgroundColor = Theme.ThemeRed
                    }
                }
            } else if (self.notif?.caption.lowercased() == "jual") {
                if (idx <= self.notif?.progress) {
                    vwIcon.backgroundColor = Theme.ThemeOrange
                } else {
                    vwIcon.backgroundColor = Theme.GrayLight
                }
            } else if (self.notif?.caption.lowercased() == "beli") {
                if (idx <= self.notif?.progress) {
                    vwIcon.backgroundColor = Theme.PrimaryColor
                } else {
                    vwIcon.backgroundColor = Theme.GrayLight
                }
            }
        }
        
        // Create icon image
        var imgName : String?
        if let progress = self.notif?.progress {
            if (TransactionDetailTools.isReservationProgress(progress)) {
                if (idx == 1) { // Reserved
                    imgName = "ic_trx_reserved"
                } else {
                    if (progress == TransactionDetailTools.ProgressReserved || progress == TransactionDetailTools.ProgressReserveDone) { // Done
                        imgName = "ic_trx_reservation_done"
                    } else if (progress == TransactionDetailTools.ProgressReservationCancelled) { // Reservation cancelled
                        imgName = "ic_trx_reservation_cancelled"
                    }
                }
            } else if (TransactionDetailTools.isRefundProgress(progress)) {
                if (idx == 1) {
                    imgName = "ic_trx_refund1"
                } else if (idx == 2) {
                    imgName = "ic_trx_refund2"
                } else if (idx == 3) {
                    imgName = "ic_trx_refund3"
                } else if (idx == 4) {
                    imgName = "ic_trx_refund4"
                }
            } else {
                if ((progress == TransactionDetailTools.ProgressExpired || progress == TransactionDetailTools.ProgressFraudDetected) && idx == 1) { // Expired
                    imgName = "ic_trx_expired"
                } else if (progress == TransactionDetailTools.ProgressRejectedBySeller && idx == 4) { // Rejected by seller
                    imgName = "ic_trx_exclamation"
                } else if (progress == TransactionDetailTools.ProgressNotSent && idx == 4) { // Not sent
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
        }
        if (imgName != nil) {
            if let imgIcon = UIImage(named: imgName!) {
                let imgVwIcon : UIImageView = UIImageView(frame: CGRect(x: 5, y: 5, width: 15, height: 15), image: imgIcon)
                vwIcon.addSubview(imgVwIcon)
            }
        }
        
        // Add view to cell
        cell.addSubview(vwIcon)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 25, height: 25)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (idx != nil) {
            delegate?.cellCollectionTapped(self.idx!)
        }
    }
}
