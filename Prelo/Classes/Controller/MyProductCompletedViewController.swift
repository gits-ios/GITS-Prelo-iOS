//
//  MyProductCompletedViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/22/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyProductCompletedViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var lblEmpty : UILabel!
    @IBOutlet var btnRefresh: UIButton!
    @IBOutlet var loading : UIActivityIndicatorView!
    @IBOutlet weak var bottomLoading: UIActivityIndicatorView!
    @IBOutlet weak var consBottomTableView: NSLayoutConstraint!
    let ConsBottomTableViewWhileUpdating : CGFloat = 36
    
    var refreshControl : UIRefreshControl!
    
    let ItemPerLoad : Int = 10
    var nextIdx : Int = 0
    var isAllItemLoaded : Bool = false
    
    var userProducts : Array <UserTransactionItem>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let transactionListCellNib = UINib(nibName: "TransactionListCell", bundle: nil)
        tableView.registerNib(transactionListCellNib, forCellReuseIdentifier: "TransactionListCell")
        
        // Hide bottom refresh first
        bottomLoading.stopAnimating()
        consBottomTableView.constant = 0
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(MyProductCompletedViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loading.startAnimating()
        tableView.hidden = true
        lblEmpty.hidden = true
        btnRefresh.hidden = true
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.MyProducts, otherParam: ["Tab" : "Complete"])
        
        // Google Analytics
        GAI.trackPageVisit(PageName.MyProducts)
        
        if (userProducts?.count == 0 || userProducts == nil) {
            if (userProducts == nil) {
                userProducts = []
            }
            getUserProducts()
        } else {
            self.loading.stopAnimating()
            self.loading.hidden = true
            if (self.userProducts?.count <= 0) {
                self.lblEmpty.hidden = false
                self.btnRefresh.hidden = false
            } else {
                self.tableView.hidden = false
                self.setupTable()
            }
        }
    }
    
    func getUserProducts() {
        // API Migrasi
        request(APITransaction.Sells(status: "done", current: "\(nextIdx)", limit: "\(nextIdx + ItemPerLoad)")).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Jualan Saya - Selesai")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                let dataCount = data.count
                
                // Store data into variable
                for (_, item) in data {
                    let u = UserTransactionItem.instanceTransactionItem(item)
                    if (u != nil) {
                        self.userProducts?.append(u!)
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
            
            if (self.userProducts?.count <= 0) {
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
        self.userProducts = []
        self.nextIdx = 0
        self.isAllItemLoaded = false
        self.tableView.hidden = true
        self.lblEmpty.hidden = true
        self.btnRefresh.hidden = true
        self.loading.hidden = false
        getUserProducts()
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
        if (userProducts?.count > 0) {
            return (self.userProducts?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->
        UITableViewCell {
            let cell : TransactionListCell = self.tableView.dequeueReusableCellWithIdentifier("TransactionListCell") as! TransactionListCell
            if (!refreshControl.refreshing) {
                let u = userProducts?[indexPath.item]
                cell.adaptItem(u!)
            }
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let myProductDetailVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyProductDetail, owner: nil, options: nil).first as! MyProductDetailViewController
        myProductDetailVC.transactionId = userProducts?[indexPath.item].id
        self.navigationController?.pushViewController(myProductDetailVC, animated: true)
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
                
                // Get user products
                self.getUserProducts()
            }
        }
    }
}