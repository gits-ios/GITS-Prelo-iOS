//
//  MyPurchaseTransactionViewController.swift
//  Prelo
//
//  Created by PreloBook on 10/4/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class

class MyPurchaseTransactionViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var tableView : UITableView!
    @IBOutlet var lblEmpty : UILabel!
    @IBOutlet var btnRefresh: UIButton!
    @IBOutlet var loading : UIActivityIndicatorView!
    @IBOutlet var bottomLoading: UIActivityIndicatorView!
    @IBOutlet var consBottomTableView: NSLayoutConstraint!
    @IBOutlet weak var viewJualButton: UIView!
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
        tableView.registerNib(notifTransactionCellNib, forCellReuseIdentifier: "NotifAnggiTransactionCell")
        
        // Hide and show
        self.showLoading()
        self.hideContent()
        self.hideBottomLoading()
        
        // Set constraint
        consBottomTableView.constant = 0
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(NotifAnggiTransactionViewController.refreshPage), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Buat tombol jual menjadi bentuk bulat dan selalu di depan
        viewJualButton.layer.cornerRadius = (viewJualButton.frame.size.width) / 2
        viewJualButton.layer.shadowColor = UIColor.blackColor().CGColor
        viewJualButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewJualButton.layer.shadowOpacity = 0.3
        self.view.bringSubviewToFront(viewJualButton)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (userProducts.isEmpty) {
            getMyProducts()
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
        
        self.getMyProducts()
    }
    
    func getMyProducts() {
        request(APINotifAnggi.GetNotifsBuy(page: currentPage + 1)).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Jualan Saya - Transaksi")) {
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
    
    // MARK: - Tableview functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userProducts.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 81
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell : NotifAnggiTransactionCell = self.tableView.dequeueReusableCellWithIdentifier("NotifAnggiTransactionCell") as? NotifAnggiTransactionCell {
            cell.selectionStyle = .None
            cell.isDiffUnread = false
            let p = userProducts[indexPath.item]
            cell.adapt(p, idx: indexPath.item)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.readNotif(indexPath.item)
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
            if (!self.isAllItemLoaded && self.bottomLoading.hidden) {
                // Show bottomLoading
                self.consBottomTableView.constant = ConsBottomTableViewWhileUpdating
                self.showBottomLoading()
                
                // Get balance mutations
                self.getMyProducts()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func sellPressed(sender: AnyObject) {
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        add.screenBeforeAddProduct = PageName.MyOrders
        self.navigationController?.pushViewController(add, animated: true)
    }
    
    func readNotif(idx : Int) {
        self.showLoading()
        if (idx < userProducts.count) {
            let p = userProducts[idx]
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let transactionDetailVC : TransactionDetailViewController = (mainStoryboard.instantiateViewControllerWithIdentifier("TransactionDetail") as? TransactionDetailViewController)!
            
            // Set trxId/trxProductId
            if (p.progress == TransactionDetailTools.ProgressExpired ||
                p.progress == TransactionDetailTools.ProgressNotPaid ||
                p.progress == TransactionDetailTools.ProgressClaimedPaid ||
                p.progress == TransactionDetailTools.ProgressFraudDetected) {
                transactionDetailVC.trxId = p.objectId
            } else if (p.progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (p.caption.lowercaseString == "jual") {
                    transactionDetailVC.trxId = p.objectId
                } else if (p.caption.lowercaseString == "beli") {
                    transactionDetailVC.trxProductId = p.objectId
                }
            } else {
                transactionDetailVC.trxProductId = p.objectId
            }
            
            // Set isSeller
            if (p.caption.lowercaseString == "jual") {
                transactionDetailVC.isSeller = true
            } else if (p.caption.lowercaseString == "beli") {
                transactionDetailVC.isSeller = false
            }
            self.navigationController?.pushViewController(transactionDetailVC, animated: true)
        }
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loading.hidden = false
        self.loading.startAnimating()
    }
    
    func hideLoading() {
        self.loading.hidden = true
        self.loading.stopAnimating()
    }
    
    func showBottomLoading() {
        self.bottomLoading.hidden = false
        self.bottomLoading.startAnimating()
    }
    
    func hideBottomLoading() {
        self.bottomLoading.hidden = true
        self.bottomLoading.stopAnimating()
    }
    
    func showContent() {
        if (self.userProducts.count <= 0) {
            self.lblEmpty.hidden = false
            self.btnRefresh.hidden = false
        } else {
            self.tableView.hidden = false
            self.setupTable()
        }
    }
    
    func hideContent() {
        self.tableView.hidden = true
        self.lblEmpty.hidden = true
        self.btnRefresh.hidden = true
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
}
