//
//  MyPurchaseCompletedViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/14/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyPurchaseCompletedViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var btnRefresh: UIButton!
    @IBOutlet weak var bottomLoading: UIActivityIndicatorView!
    @IBOutlet weak var consBottomTableView: NSLayoutConstraint!
    let ConsBottomTableViewWhileUpdating : CGFloat = 36
    
    var userPurchases : Array <UserTransactionItem>?
    
    var refreshControl : UIRefreshControl!
    
    let ItemPerLoad : Int = 10
    var nextIdx : Int = 0
    var isAllItemLoaded : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        var transactionListCellNib = UINib(nibName: "TransactionListCell", bundle: nil)
        tableView.registerNib(transactionListCellNib, forCellReuseIdentifier: "TransactionListCell")
        
        // Hide bottom refresh first
        bottomLoading.stopAnimating()
        consBottomTableView.constant = 0
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loading.startAnimating()
        tableView.hidden = true
        lblEmpty.hidden = true
        btnRefresh.hidden = true
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.MyOrders, otherParam: ["Tab" : "Complete"])
        
        // Google Analytics
        GAI.trackPageVisit(PageName.MyOrders)
        
        if (userPurchases?.count == 0 || userPurchases == nil) {
            if (userPurchases == nil) {
                userPurchases = []
            }
            getUserPurchases()
        } else {
            self.loading.stopAnimating()
            self.loading.hidden = true
            if (self.userPurchases?.count <= 0) {
                self.lblEmpty.hidden = false
                self.btnRefresh.hidden = false
            } else {
                self.tableView.hidden = false
                self.setupTable()
            }
        }
    }
    
    func getUserPurchases() {
        request(APITransaction.Purchases(status: "done", current: "\(nextIdx)", limit: "\(nextIdx + ItemPerLoad)")).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Belanjaan Saya - Selesai")) {
                let json = JSON(res!)
                let data = json["_data"]
                let dataCount = data.count
                
                // Store data into variable
                for (index : String, item : JSON) in data {
                    let u = UserTransactionItem.instanceTransactionItem(item)
                    if (u != nil) {
                        self.userPurchases?.append(u!)
                    }
                }
                
                // Check if all data already loaded
                if (dataCount < self.ItemPerLoad) {
                    self.isAllItemLoaded = true
                }
                
                // Set next index
                self.nextIdx += dataCount
            }
            
            // Hide loading (for first time request)
            self.loading.stopAnimating()
            
            // Hide bottomLoading (for next request)
            self.bottomLoading.stopAnimating()
            self.consBottomTableView.constant = 0
            
            // Hide refreshControl (for refreshing)
            self.refreshControl.endRefreshing()
            
            if (self.userPurchases?.count <= 0) {
                self.lblEmpty.hidden = false
                self.btnRefresh.hidden = false
            } else {
                self.tableView.hidden = false
                self.setupTable()
            }
        }
    }
    
    func refresh(sender: AnyObject) {
        // Reset data
        self.userPurchases = []
        self.nextIdx = 0
        self.isAllItemLoaded = false
        self.tableView.hidden = true
        self.lblEmpty.hidden = true
        self.btnRefresh.hidden = true
        self.loading.hidden = false
        getUserPurchases()
    }
    
    @IBAction func refreshPressed(sender: AnyObject) {
        self.refresh(sender)
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (userPurchases?.count > 0) {
            return (self.userPurchases?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->
        UITableViewCell {
            var cell : TransactionListCell = self.tableView.dequeueReusableCellWithIdentifier("TransactionListCell") as! TransactionListCell
            if (!refreshControl.refreshing) {
                let u = userPurchases?[indexPath.item]
                cell.adaptItem(u!)
            }
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (userPurchases != nil && userPurchases!.count >= indexPath.item) {
            let trxItem = userPurchases![indexPath.item]
            if (TransactionDetailTools.isReservationProgress(trxItem.progress)) {
                let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let transactionDetailVC : TransactionDetailViewController = (mainStoryboard.instantiateViewControllerWithIdentifier("TransactionDetail") as? TransactionDetailViewController)!
                transactionDetailVC.trxProductId = trxItem.id
                transactionDetailVC.isSeller = false
                self.navigationController?.pushViewController(transactionDetailVC, animated: true)
            } else {
                let myPurchaseDetailVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchaseDetail, owner: nil, options: nil).first as! MyPurchaseDetailViewController
                myPurchaseDetailVC.transactionId = trxItem.id
                self.navigationController?.pushViewController(myPurchaseDetailVC, animated: true)
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
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
                // Tampilkan loading di bawah
                consBottomTableView.constant = ConsBottomTableViewWhileUpdating
                bottomLoading.startAnimating()
                
                // Get user purchases
                self.getUserPurchases()
            }
        }
    }
}
