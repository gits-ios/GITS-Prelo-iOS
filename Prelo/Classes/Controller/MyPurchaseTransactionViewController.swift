//
//  MyPurchaseTransactionViewController.swift
//  Prelo
//
//  Created by PreloBook on 10/4/16.
//  Copyright © 2016 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class

class MyPurchaseTransactionViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var lblEmpty : UILabel!
    @IBOutlet weak var btnRefresh: UIButton!
    @IBOutlet weak var loading : UIActivityIndicatorView!
    @IBOutlet weak var vwBottomLoading: UIView!
    @IBOutlet weak var bottomLoading: UIActivityIndicatorView!
    @IBOutlet weak var viewJualButton: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    var refreshControl : UIRefreshControl!
    
    // Data container
    let ItemPerLoad : Int = 10
    var currentPage : Int = 0
    var isAllItemLoaded : Bool = false
    var userProducts : [NotificationObj] = []
    
    var isRefreshing = false
    
    var isFirst = true
    
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
        
        self.vwBottomLoading.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        // Hide and show
        self.showLoading()
        self.hideContent()
        self.hideBottomLoading()
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(NotifAnggiTransactionViewController.refreshPage), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Buat tombol jual menjadi bentuk bulat dan selalu di depan
        viewJualButton.layoutIfNeeded()
        viewJualButton.layer.cornerRadius = (viewJualButton.frame.size.width) / 2
        viewJualButton.layer.shadowColor = UIColor.black.cgColor
        viewJualButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewJualButton.layer.shadowOpacity = 0.3
        self.view.bringSubview(toFront: viewJualButton)
        
        // MARK: HACK Menu Add
        self.circleMenu = CircleMenu()
        circleMenu?.setupView(self, name: PageName.MyOrders, parent: self.viewJualButton, frame: self.viewJualButton.frame)
        
        // Search bar setup
        searchBar.delegate = self
        searchBar.placeholder = "Cari Barang"
        
        self.getMyPurchase()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /*
        if (userProducts.isEmpty) {
            getMyPurchase()
        } else {
            self.hideLoading()
            self.showContent()
        }*/
        
        if isFirst {
            isFirst = false
        } else {
            self.hideLoading()
        }
    }
    
    func refreshPage() {
        self.isRefreshing = true
        
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
                var dataCount = 0
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Jualan Saya - Transaksi")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    dataCount = data.count
                    
                    // Store data into variable
                    for (_, item) in data {
                        if let n = NotificationObj.instance(item) {
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
                
                // Hide refreshControl (for refreshing)
                self.refreshControl.endRefreshing()
                
                if self.currentPage == 1 {
                    // Show content
                    self.showContent()
                } else if dataCount > 0 {
                    let lastRow = self.tableView.numberOfRows(inSection: 0) - 1
                    var idxs : Array<IndexPath> = []
                    for i in 1...dataCount {
                        idxs.append(IndexPath(row: lastRow+i, section: 0))
                    }
                    self.tableView.insertRows(at: idxs, with: .fade)
                }
            }
            
            self.isRefreshing = false
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
            if ((indexPath as NSIndexPath).item < self.userProducts.count) {
                
                cell.selectionStyle = .none
                cell.alpha = 1.0
                cell.backgroundColor = UIColor.white
                cell.isDiffUnread = false
                
                let p = userProducts[(indexPath as NSIndexPath).item]
                cell.adapt(p, idx: (indexPath as NSIndexPath).item, isPriceHidden: false)
                
                return cell
            }
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
        if (y > h + reloadDistance && !self.isRefreshing) {
            // Load next items only if all items not loaded yet and if its not currently loading items
            if (!self.isAllItemLoaded && self.bottomLoading.isHidden) {
                // Show bottomLoading
                self.showBottomLoading()
                
                // Get balance mutations
                self.getMyPurchase()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func sellPressed(_ sender: AnyObject) {
        /*
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        add.screenBeforeAddProduct = PageName.MyOrders
        self.navigationController?.pushViewController(add, animated: true)
        */
        
        let addProduct3VC = Bundle.main.loadNibNamed(Tags.XibNameAddProduct3, owner: nil, options: nil)?.first as! AddProductViewController3
        addProduct3VC.screenBeforeAddProduct = PageName.MyOrders
        self.navigationController?.pushViewController(addProduct3VC, animated: true)
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
            
            transactionDetailVC.previousScreen = PageName.MyOrders
            
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
        self.vwBottomLoading.isHidden = false
        self.bottomLoading.isHidden = false
        self.bottomLoading.startAnimating()
    }
    
    func hideBottomLoading() {
        self.vwBottomLoading.isHidden = true
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
