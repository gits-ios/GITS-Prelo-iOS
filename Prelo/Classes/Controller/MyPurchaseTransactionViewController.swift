//
//  MyPurchaseTransactionViewController.swift
//  Prelo
//
//  Created by PreloBook on 10/4/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class

class MyPurchaseTransactionViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var tableView : UITableView!
    @IBOutlet var lblEmpty : UILabel!
    @IBOutlet var btnRefresh: UIButton!
    @IBOutlet var loading : UIActivityIndicatorView!
    @IBOutlet var bottomLoading: UIActivityIndicatorView!
    @IBOutlet var consBottomTableView: NSLayoutConstraint!
    @IBOutlet var viewJualButton: UIView!
    @IBOutlet var searchBar: UISearchBar!
    var refreshControl : UIRefreshControl!
    
    // Data container
    let ConsBottomTableViewWhileUpdating : CGFloat = 36
    let ItemPerLoad : Int = 10
    var currentPage : Int = 0
    var isAllItemLoaded : Bool = false
    var userProducts : [Notification] = []
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        self.title = "Belanjaan Saya"
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let notifTransactionCellNib = UINib(nibName: "NotifAnggiTransactionCell", bundle: nil)
        tableView.register(notifTransactionCellNib, forCellReuseIdentifier: "NotifAnggiTransactionCell")
        
        // Hide and show
        self.showLoading()
        self.hideContent()
        self.hideBottomLoading()
        
        // Set constraint
        consBottomTableView.constant = 0
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(NotifAnggiTransactionViewController.refreshPage), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Buat tombol jual menjadi bentuk bulat dan selalu di depan
        viewJualButton.layer.cornerRadius = (viewJualButton.frame.size.width) / 2
        viewJualButton.layer.shadowColor = UIColor.black.cgColor
        viewJualButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewJualButton.layer.shadowOpacity = 0.3
        self.view.bringSubview(toFront: viewJualButton)
        
        // Search bar setup
        searchBar.delegate = self
        searchBar.placeholder = "Cari Barang"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (userProducts.isEmpty) {
            getMyPurchase()
        } else {
            self.hideLoading()
            self.showContent()
        }
    }
    
    func refreshPage() {
        // Reset data
        self.userProducts = []
        self.currentPage = 0
        self.isAllItemLoaded = false
        self.showLoading()
        self.hideContent()
        
        self.getMyPurchase()
    }
    
    func getMyPurchase() {
        var searchText = ""
        if let txt = searchBar.text {
            searchText = txt
        }
        let _ = request(APINotification.getNotifsBuy(page: currentPage + 1, name : searchText)).responseJSON { resp in
            if (searchText == self.searchBar.text) { // Jika response ini sesuai dengan request terakhir
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Jualan Saya - Transaksi")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    let dataCount = data.count
                    
                    // Store data into variable
                    for (_, item) in data {
                        if let n = Notification.instance(item) {
                            self.userProducts.append(n)
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
                self.consBottomTableView.constant = 0
                
                // Hide refreshControl (for refreshing)
                self.refreshControl.endRefreshing()
                
                // Show content
                self.showContent()
            }
        }
    }
    
    // MARK: - Tableview functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userProducts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell : NotifAnggiTransactionCell = self.tableView.dequeueReusableCell(withIdentifier: "NotifAnggiTransactionCell") as? NotifAnggiTransactionCell {
            cell.selectionStyle = .none
            cell.isDiffUnread = false
            let p = userProducts[(indexPath as NSIndexPath).item]
            cell.adapt(p, idx: (indexPath as NSIndexPath).item)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.readNotif((indexPath as NSIndexPath).item)
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
            if (!self.isAllItemLoaded && self.bottomLoading.isHidden) {
                // Show bottomLoading
                self.consBottomTableView.constant = ConsBottomTableViewWhileUpdating
                self.showBottomLoading()
                
                // Get balance mutations
                self.getMyPurchase()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func sellPressed(_ sender: AnyObject) {
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        add.screenBeforeAddProduct = PageName.MyOrders
        self.navigationController?.pushViewController(add, animated: true)
    }
    
    func readNotif(_ idx : Int) {
        self.showLoading()
        if (idx < userProducts.count) {
            let p = userProducts[idx]
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let transactionDetailVC : TransactionDetailViewController = (mainStoryboard.instantiateViewController(withIdentifier: "TransactionDetail") as? TransactionDetailViewController)!
            
            // Set trxId/trxProductId
            if (p.progress == TransactionDetailTools.ProgressExpired ||
                p.progress == TransactionDetailTools.ProgressNotPaid ||
                p.progress == TransactionDetailTools.ProgressClaimedPaid ||
                p.progress == TransactionDetailTools.ProgressFraudDetected) {
                transactionDetailVC.trxId = p.objectId
            } else if (p.progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (p.caption.lowercased() == "jual") {
                    transactionDetailVC.trxId = p.objectId
                } else if (p.caption.lowercased() == "beli") {
                    transactionDetailVC.trxProductId = p.objectId
                }
            } else {
                transactionDetailVC.trxProductId = p.objectId
            }
            
            // Set isSeller
            if (p.caption.lowercased() == "jual") {
                transactionDetailVC.isSeller = true
            } else if (p.caption.lowercased() == "beli") {
                transactionDetailVC.isSeller = false
            }
            self.navigationController?.pushViewController(transactionDetailVC, animated: true)
        }
    }
    
    // MARK: - Search bar functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.refreshPage()
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loading.isHidden = false
        self.loading.startAnimating()
    }
    
    func hideLoading() {
        self.loading.isHidden = true
        self.loading.stopAnimating()
    }
    
    func showBottomLoading() {
        self.bottomLoading.isHidden = false
        self.bottomLoading.startAnimating()
    }
    
    func hideBottomLoading() {
        self.bottomLoading.isHidden = true
        self.bottomLoading.stopAnimating()
    }
    
    func showContent() {
        if (self.userProducts.count <= 0) {
            self.lblEmpty.isHidden = false
            self.btnRefresh.isHidden = false
        } else {
            self.tableView.isHidden = false
            self.setupTable()
        }
    }
    
    func hideContent() {
        self.tableView.isHidden = true
        self.lblEmpty.isHidden = true
        self.btnRefresh.isHidden = true
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
}
