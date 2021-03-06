//
//  MyPurchaseProcessingViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/14/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
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

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MyPurchaseProcessingViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var lblEmpty : UILabel!
    @IBOutlet var btnRefresh: UIButton!
    @IBOutlet var loading: UIActivityIndicatorView!
    @IBOutlet weak var bottomLoading: UIActivityIndicatorView!
    @IBOutlet weak var consBottomTableView: NSLayoutConstraint!
    let ConsBottomTableViewWhileUpdating : CGFloat = 36
    
    var userPurchases : Array <UserTransactionItem>?
    
    var refreshControl : UIRefreshControl!
    
    let ItemPerLoad : Int = 10
    var nextIdx : Int = 0
    var isAllItemLoaded : Bool = false
    
    var isRefreshing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let transactionListCellNib = UINib(nibName: "TransactionListCell", bundle: nil)
        tableView.register(transactionListCellNib, forCellReuseIdentifier: "TransactionListCell")
        
        // Hide bottom refresh first
        bottomLoading.stopAnimating()
        consBottomTableView.constant = 0
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(MyPurchaseProcessingViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loading.startAnimating()
        tableView.isHidden = true
        lblEmpty.isHidden = true
        btnRefresh.isHidden = true
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.MyOrders, otherParam: ["Tab" : "In Progress"])
        
        // Google Analytics
        GAI.trackPageVisit(PageName.MyOrders)
        
        if (userPurchases?.count == 0 || userPurchases == nil) {
            if (userPurchases == nil) {
                userPurchases = []
            }
            getUserPurchases()
        } else {
            self.loading.stopAnimating()
            self.loading.isHidden = true
            if (self.userPurchases?.count <= 0) {
                self.lblEmpty.isHidden = false
                self.btnRefresh.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.setupTable()
            }
        }
    }
    
    func getUserPurchases() {
        // API Migrasi
        let _ = request(APITransactionProduct.purchases(status: "process", current: "\(nextIdx)", limit: "\(nextIdx + ItemPerLoad)")).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Belanjaan Saya - Diproses")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                let dataCount = data.count
                
                // Store data into variable
                for (_, item) in data {
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
                self.lblEmpty.isHidden = false
                self.btnRefresh.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.setupTable()
            }
            
            self.isRefreshing = false
        }
    }
    
    func refresh(_ sender: AnyObject) {
        self.isRefreshing = true
        
        // Reset data
        self.userPurchases = []
        self.nextIdx = 0
        self.isAllItemLoaded = false
        self.tableView.isHidden = true
        self.lblEmpty.isHidden = true
        self.btnRefresh.isHidden = true
        self.loading.isHidden = false
        getUserPurchases()
    }
    
    @IBAction func refreshPressed(_ sender: AnyObject) {
        self.refresh(sender)
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (userPurchases?.count > 0) {
            return (self.userPurchases?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->
        UITableViewCell {
        let cell : TransactionListCell = self.tableView.dequeueReusableCell(withIdentifier: "TransactionListCell") as! TransactionListCell
            
            cell.alpha = 1.0
            cell.backgroundColor = UIColor.white
            
        if (!refreshControl.isRefreshing) {
            let u = userPurchases?[(indexPath as NSIndexPath).item]
            cell.adaptItem(u!)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (userPurchases != nil && userPurchases!.count >= (indexPath as NSIndexPath).item) {
            let trxItem = userPurchases![(indexPath as NSIndexPath).item]
            if (TransactionDetailTools.isReservationProgress(trxItem.progress)) {
                let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let transactionDetailVC : TransactionDetailViewController = (mainStoryboard.instantiateViewController(withIdentifier: "TransactionDetail") as? TransactionDetailViewController)!
                transactionDetailVC.trxProductId = trxItem.id
                transactionDetailVC.isSeller = false
                transactionDetailVC.previousScreen = PageName.MyOrders
                self.navigationController?.pushViewController(transactionDetailVC, animated: true)
            } else {
                let myPurchaseDetailVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseDetail, owner: nil, options: nil)?.first as! MyPurchaseDetailViewController
                myPurchaseDetailVC.transactionId = trxItem.id
                self.navigationController?.pushViewController(myPurchaseDetailVC, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
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
                // Tampilkan loading di bawah
                consBottomTableView.constant = ConsBottomTableViewWhileUpdating
                bottomLoading.startAnimating()
                
                // Get user purchases
                self.getUserPurchases()
            }
        }
    }
}

