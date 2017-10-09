//
//  NotifAnggiTransactionViewController.swift
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


// MARK: - NotifAnggiTransaction Protocol

protocol NotifAnggiTransactionDelegate: class {
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
    
    weak var delegate : NotifAnggiTransactionDelegate?
    
    var isToDelete : Bool = false
    
    var notifIds : [String] = []
    
    var isMacro : Bool = false
    
    var countDecreaseNotifCount = 0
    
    var isRefreshing = false
    
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
        
        //        btnBatal.layer.borderWidth = 1
        //        btnBatal.layer.borderColor = UIColor.white.cgColor
        //
        //        btnHapus.layer.borderWidth = 1
        //        btnHapus.layer.borderColor = UIColor.white.cgColor
        
        // Transparent panel
        self.backgroundOverlay.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
    }
    
    func refreshPage() {
        self.isRefreshing = true
        
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
            var dataCount = 0
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Transaksi")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                dataCount = data.count
                
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
            
            if self.currentPage == 1 {
                // Show content
                self.showContent()
                
                if self.isMacro {
                    self.notifIds = []
                    for idx in 0...(self.notifications?.count)!-1 {
                        self.notifIds.append(self.notifications![idx].id)
                    }
                    //self.tableView.reloadData()
                    self.tableView.reloadSections(IndexSet.init(integer: 0), with: .fade)
                }
            } else if dataCount > 0 {
                let lastRow = self.tableView.numberOfRows(inSection: 0) - 1
                var idxs : Array<IndexPath> = []
                for i in 1...dataCount {
                    idxs.append(IndexPath(row: lastRow+i, section: 0))
                    if self.isMacro {
                        self.notifIds.append(self.notifications![lastRow+i].id)
                    }
                }
                self.tableView.insertRows(at: idxs, with: .fade)
            }
            
            self.isRefreshing = false
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
            cell.alpha = 1.0
            cell.backgroundColor = UIColor.white
            
            if let n = notifications?[(indexPath as NSIndexPath).item] {
                cell.adapt(n, idx: (indexPath as NSIndexPath).item, isPriceHidden: true)
                cell.delegate = self
                
                if isToDelete {
                    cell.vwCheckBox.isHidden = false
                    cell.consLeadingImage.constant = 48
                    cell.vwOverlay.isHidden = false
                    
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
                    cell.vwOverlay.isHidden = true
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
                //tableView.reloadData()
                tableView.reloadRows(at: [indexPath], with: .fade)
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
        if (y > h + reloadDistance && !self.isRefreshing) {
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
    
    @IBAction func btnCheckBoxAllPressed(_ sender: Any) {
        if (isMacro) {
            self.lblCheckBox.isHidden = true
            self.isMacro = false
            self.notifIds = []
            //self.tableView.reloadData()
            self.tableView.reloadSections(IndexSet.init(integer: 0), with: .fade)
            
        } else {
            self.lblCheckBox.isHidden = false
            self.isMacro = true
            self.notifIds = []
            for idx in 0...(self.notifications?.count)!-1 {
                notifIds.append(self.notifications![idx].id)
            }
            //self.tableView.reloadData()
            self.tableView.reloadSections(IndexSet.init(integer: 0), with: .fade)
        }
    }
    
    @IBAction func btnBatalPressed(_ sender: Any) {
        self.isToDelete = false
        self.consHeightCheckBoxAll.constant = 0
        self.lblCheckBox.isHidden = true
        self.consHeightButtonView.constant = 0
        self.notifIds = []
        //self.tableView.reloadData()
        self.tableView.reloadSections(IndexSet.init(integer: 0), with: .fade)
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
        
        let _ = request(APINotification.deleteNotif(tab: "transaction", notifIds: AppToolsObjC.jsonString(from: self.notifIds))).responseJSON { resp in
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
                        self.delegate?.decreaseTransactionBadgeNumber()
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
        
        // Prelo Analytic - Click Notification (in App)
        self.sendClickNotificationAnalytic(notif.objectId, tipe: notif.type)
        
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
        
        transactionDetailVC.previousScreen = PageName.Notification
        
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
    @IBOutlet weak var vwOverlay: UIView! // default : hidden
    
    
    var notif : NotificationObj?
    var idx : Int?
    
    var delegate : NotifAnggiTransactionCellDelegate?
    
    var isDiffUnread : Bool = true
    var isNeedSetup = true
    
    override func prepareForReuse() {
        self.contentView.backgroundColor = UIColor.white.withAlphaComponent(0)
        //        imgSingle.image = UIImage(named: "raisa.jpg")
        vwSingleImage.isHidden = false
        vwDoubleImage.isHidden = true
        vwCaption.backgroundColor = Theme.GrayDark
        
        // Set trx status text color
        if (notif?.progress < 0 || notif?.progress == 34 || TransactionDetailTools.isNegativeProgress(notif?.progress)) {
            lblTrxStatus.textColor = Theme.ThemeRed
        } else {
            lblTrxStatus.textColor = Theme.GrayDark
        }
        
        if imgSingle != nil {
            imgSingle.afCancelRequest()
        }
        if imgDouble1 != nil {
            imgDouble1.afCancelRequest()
        }
        if imgDouble2 != nil {
            imgDouble2.afCancelRequest()
        }
    }
    
    func adapt(_ notif : NotificationObj, idx : Int, isPriceHidden : Bool) {
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
        } else if (notif.caption.lowercased() == "disewa") {
            vwCaption.backgroundColor = Theme.ThemeOrange
        } else if (notif.caption.lowercased() == "sewa") {
            vwCaption.backgroundColor = Theme.PrimaryColor
        }
        
        // Set Labels
        lblProductName.text = notif.objectName
        lblTrxStatus.text = notif.statusText
        lblPrice.text = notif.shortPreview
        lblTime.text = notif.time
        lblPrice.isHidden = true
//        lblPrice.isHidden = isPriceHidden
        
        // Set trx status text color
        if (notif.progress < 0 || notif.progress == 34 || TransactionDetailTools.isNegativeProgress(notif.progress)) {
            lblTrxStatus.textColor = Theme.ThemeRed
        } else {
            lblTrxStatus.textColor = Theme.GrayDark
        }
        
        // Set trx status text width
        let sizeThatShouldFitTheContent = lblTrxStatus.sizeThatFits(lblTrxStatus.frame.size)
        ////print("size untuk '\(lblTrxStatus.text)' = \(sizeThatShouldFitTheContent)")
        consWidthLblTrxStatus.constant = sizeThatShouldFitTheContent.width
        
        if isNeedSetup {
            isNeedSetup = false
            
            self.setupCollection()
        }
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
    
    func setupCollection() {
        // Set collection view
        collcTrxProgress.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcTrxProgressCell")
        collcTrxProgress.delegate = self
        collcTrxProgress.dataSource = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NotifAnggiTransactionCell.handleTap))
        tapGestureRecognizer.delegate = self
        collcTrxProgress.backgroundView = UIView(frame: collcTrxProgress.bounds)
        collcTrxProgress.backgroundView!.addGestureRecognizer(tapGestureRecognizer)
        collcTrxProgress.backgroundColor = UIColor.clear
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
            } else if (progress == TransactionDetailTools.ProgressNotReturned) {
                return 6
            } else { // Default
                if (notif?.caption.lowercased() == "disewa" || notif?.caption.lowercased() == "sewa") {
                    return 7
                } else {
                    // Default jual || beli
                    return 6
                }
            }
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = collcTrxProgress.dequeueReusableCell(withReuseIdentifier: "collcTrxProgressCell", for: indexPath)
        
        // Create icon view
        let vwIcon : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        vwIcon.backgroundColor = Theme.GrayLight // Default color
        var imgName : String?
        if let progress = self.notif?.progress {
            switch indexPath.row {
            case 0:
                if TransactionDetailTools.isReservationProgress(progress) {
                    imgName = "ic_trx_reserved"
                    vwIcon.backgroundColor = activeColorType()
                } else if TransactionDetailTools.isRefundProgress(progress){
                    imgName = "ic_trx_refund1"
                    if indexPath.row < (progress - 29) {
                        vwIcon.backgroundColor = Theme.ThemeRed
                    }
                } else { // Normal transaction
                    imgName = "ic_trx_expired"
                    if TransactionDetailTools.isNegativeProgress(progress) {
                        if progress == TransactionDetailTools.ProgressExpired || progress == TransactionDetailTools.ProgressFraudDetected {
                            vwIcon.backgroundColor = Theme.ThemeRed
                        } else {
                            vwIcon.backgroundColor = activeColorType()
                        }
                    } else {
                        if indexPath.row < progress {
                            vwIcon.backgroundColor = activeColorType()
                        }
                    }
                }
            case 1:
                if TransactionDetailTools.isReservationProgress(progress) {
                    if progress == TransactionDetailTools.ProgressReserved {
                        imgName = "ic_trx_reservation_done"
                    } else if progress == TransactionDetailTools.ProgressReserveDone {
                        imgName = "ic_trx_reservation_done"
                        vwIcon.backgroundColor = activeColorType()
                    } else if progress == TransactionDetailTools.ProgressReservationCancelled {
                        imgName = "ic_trx_reservation_cancelled"
                        vwIcon.backgroundColor = Theme.ThemeRed
                    }
                } else if TransactionDetailTools.isRefundProgress(progress){
                    imgName = "ic_trx_refund2"
                    if indexPath.row < (progress - 29) {
                        vwIcon.backgroundColor = Theme.ThemeRed
                    }
                } else { // Normal transaction
                    imgName = "ic_trx_wait"
                    if TransactionDetailTools.isNegativeProgress(progress) {
                        vwIcon.backgroundColor = activeColorType()
                    }
                    else {
                        if indexPath.row < progress {
                            vwIcon.backgroundColor = activeColorType()
                        }
                    }
                }
            case 2:
                if TransactionDetailTools.isRefundProgress(progress) {
                    imgName = "ic_trx_refund3"
                    if indexPath.row < (progress - 29) {
                        vwIcon.backgroundColor = Theme.ThemeRed
                    }
                } else { // Normal transaction
                    imgName = "ic_trx_paid"
                    if TransactionDetailTools.isNegativeProgress(progress) {
                        vwIcon.backgroundColor = activeColorType()
                    } else {
                        if indexPath.row < progress {
                            vwIcon.backgroundColor = activeColorType()
                        }
                    }
                }
            case 3:
                if TransactionDetailTools.isRefundProgress(progress) {
                    imgName = "ic_trx_refund4"
                    if progress == 34 {
                        vwIcon.backgroundColor = Theme.ThemeRed
                    }
                } else { // Normal Transaction
                    if TransactionDetailTools.isNegativeProgress(progress) {
                        if progress == TransactionDetailTools.ProgressRejectedBySeller {
                            imgName = "ic_trx_exclamation"
                            vwIcon.backgroundColor = Theme.ThemeRed
                        } else if progress == TransactionDetailTools.ProgressNotSent{
                            imgName = "ic_trx_canceled"
                            vwIcon.backgroundColor = Theme.ThemeRed
                        } else {
                            imgName = "ic_trx_shipped"
                            vwIcon.backgroundColor = activeColorType()
                        }
                    } else {
                        imgName = "ic_trx_shipped"
                        if (self.notif?.caption.lowercased() == "disewa" || self.notif?.caption.lowercased() == "sewa") {
                            // Rent transaction code
                            if indexPath.row < (progress - 45) { // Normalize value to equalize normal & rent transaction code
                                vwIcon.backgroundColor = activeColorType()
                            }
                        } else {
                            if indexPath.row < progress {
                                vwIcon.backgroundColor = activeColorType()
                            }
                        }
                    }
                }
            case 4:
                imgName = "ic_trx_received"
                if (self.notif?.caption.lowercased() == "disewa" || self.notif?.caption.lowercased() == "sewa") {
                    // Rent transaction code
                    if indexPath.row < (progress - 45) { // Normalize value to equalize normal & rent transaction code
                        vwIcon.backgroundColor = activeColorType()
                    }
                } else {
                    if indexPath.row < progress {
                        vwIcon.backgroundColor = activeColorType()
                    }
                }
            case 5:
                if progress == TransactionDetailTools.ProgressNotReturned {
                    imgName = "ic_trx_canceled"
                    vwIcon.backgroundColor = Theme.ThemeRed
                } else if (self.notif?.caption.lowercased() == "disewa" || self.notif?.caption.lowercased() == "sewa") {
                    // Rent transaction code
                    imgName = "ic_trx_returned"
                    if indexPath.row < (progress - 45) { // Normalize value to equalize normal & rent transaction code
                        vwIcon.backgroundColor = activeColorType()
                    }
                } else {
                    imgName = "ic_trx_done"
                    if indexPath.row < progress {
                        vwIcon.backgroundColor = activeColorType()
                    }
                }
                
            case 6:
                if progress == TransactionDetailTools.ProgressReconciliation {
                    imgName = "ic_trx_reconciliation"
                    vwIcon.backgroundColor = Theme.ThemeRed
                } else {
                    imgName = "ic_trx_done"
                    if (self.notif?.caption.lowercased() == "disewa" || self.notif?.caption.lowercased() == "sewa") {
                        // Rent transaction code
                        if indexPath.row < (progress - 45) { // Normalize value to equalize normal & rent transaction code
                            vwIcon.backgroundColor = activeColorType()
                        }
                    } else {
                        if indexPath.row < progress {
                            vwIcon.backgroundColor = activeColorType()
                        }
                    }
                }
            default :
                break
            }
        }
        
        if (imgName != nil) {
            let imgIcon = UIImage(named: imgName!)
            let imgVwIcon : UIImageView = UIImageView(frame: CGRect(x: 4, y: 4, width: 16, height: 16), image: imgIcon!)
            vwIcon.removeAllSubviews()
            vwIcon.addSubview(imgVwIcon)
        }
        
        // Add view to cell
        cell.createBordersWithColor(UIColor.clear, radius: cell.width/2, width: 0)
        cell.addSubview(vwIcon)
        
        return cell
    }
    
    func activeColorType() -> UIColor{
        if (self.notif?.caption.lowercased() == "jual") {
            return Theme.ThemeOrange
        } else if (self.notif?.caption.lowercased() == "beli") {
            return Theme.PrimaryColor
        } else if (self.notif?.caption.lowercased() == "disewa") {
            return Theme.ThemeOrange
        } else if (self.notif?.caption.lowercased() == "sewa") {
            return Theme.PrimaryColor
        } else {
            return Theme.GrayGranite
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 24, height: 24)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (idx != nil) {
            delegate?.cellCollectionTapped(self.idx!)
        }
    }
}
