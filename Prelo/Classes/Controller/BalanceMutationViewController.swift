//
//  BalanceMutationViewController.swift
//  Prelo
//
//  Created by PreloBook on 7/13/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class

class BalanceMutationViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var lblBalanceAmount: UILabel!
    @IBOutlet var tblMutation: UITableView!
    @IBOutlet var lblEmpty: UILabel!
    @IBOutlet var loadingPanel: UIView!
    @IBOutlet var btnRefresh: UIButton!
    @IBOutlet var bottomLoadingPanel: UIView!
    
    var refreshControl : UIRefreshControl!
    var nextIdx : Int = 0
    let ItemPerLoad : Int = 10
    var isAllItemLoaded : Bool = false
    
    var balanceMutationItems : [BalanceMutationItem]?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tblMutation.tableFooterView = UIView()
        
        // Register custom cell
        let balanceMutationCellNib = UINib(nibName: "BalanceMutationCell", bundle: nil)
        tblMutation.registerNib(balanceMutationCellNib, forCellReuseIdentifier: "BalanceMutationCell")
        
        // Loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        bottomLoadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        self.showLoading()
        self.hideBottomLoading()
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(BalanceMutationViewController.refreshTable), forControlEvents: UIControlEvents.ValueChanged)
        self.tblMutation.addSubview(refreshControl)
        
        // Set title
        self.title = PageName.Mutation
        
        // Set label
        self.lblBalanceAmount.text = "..."
        
        // Refresh table for the first time
        self.refreshTable()
    }
    
    func refreshTable() {
        // Reset data
        self.balanceMutationItems = []
        self.nextIdx = 0
        self.isAllItemLoaded = false
        self.showLoading()
        
        getBalanceMutations()
    }
    
    func getBalanceMutations() {
        request(APIUser.GetBalanceMutations(current: self.nextIdx, limit: (nextIdx + ItemPerLoad))).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Mutasi Prelo Balance")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]["prelo_balances"]
                let dataCount = data.count
                
                // Set Prelo Balance text
                let f = NSNumberFormatter()
                f.numberStyle = NSNumberFormatterStyle.CurrencyStyle
                f.currencySymbol = ""
                f.locale = NSLocale(localeIdentifier: "id_ID")
                self.lblBalanceAmount.text = f.stringFromNumber(NSNumber(integer: json["_data"]["total_prelo_balance"].intValue))
                
                // Store data into variable
                for (_, item) in data {
                    let b = BalanceMutationItem.instance(item)
                    if (b != nil) {
                        self.balanceMutationItems?.append(b!)
                    }
                }
                
                // Check if all data are already loaded
                if (dataCount < self.ItemPerLoad) {
                    self.isAllItemLoaded = true
                }
                
                // Set next index
                self.nextIdx += dataCount
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
    
    // MARK: - UITableView functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (balanceMutationItems != nil) {
            return balanceMutationItems!.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 62
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : BalanceMutationCell = self.tblMutation.dequeueReusableCellWithIdentifier("BalanceMutationCell") as! BalanceMutationCell
        let b = balanceMutationItems?[indexPath.item]
        cell.adapt(b!)
        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let b = balanceMutationItems?[indexPath.row] {
            if (b.type != "" && b.isSeller != nil) {
                let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let transactionDetailVC : TransactionDetailViewController = (mainStoryboard.instantiateViewControllerWithIdentifier("TransactionDetail") as? TransactionDetailViewController)!
                
                if (b.type.lowercaseString == "transaction") {
                    transactionDetailVC.trxId = b.reasonId
                } else if (b.type.lowercaseString == "transaction_product") {
                    transactionDetailVC.trxProductId = b.reasonId
                }
                
                if (b.isSeller!) {
                    transactionDetailVC.isSeller = true
                } else {
                    transactionDetailVC.isSeller = false
                }
                
                self.navigationController?.pushViewController(transactionDetailVC, animated: true)
            }
        }
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
            if (!self.isAllItemLoaded && self.bottomLoadingPanel.hidden) {
                // Show bottomLoading
                self.showBottomLoading()
                
                // Get balance mutations
                self.getBalanceMutations()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func tarikUangPressed(sender: AnyObject) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let t = mainStoryboard.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdTarikTunai) as! TarikTunaiController
        self.navigationController?.pushViewController(t, animated: true)
    }
    
    @IBAction func refreshPressed(sender: AnyObject) {
        self.refreshTable()
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loadingPanel.hidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.hidden = true
    }
    
    func showBottomLoading() {
        self.bottomLoadingPanel.hidden = false
    }
    
    func hideBottomLoading() {
        self.bottomLoadingPanel.hidden = true
    }
    
    func showContent() {
        if (self.balanceMutationItems?.count <= 0) {
            self.lblEmpty.hidden = false
            self.btnRefresh.hidden = false
            self.tblMutation.hidden = true
        } else {
            self.lblEmpty.hidden = true
            self.btnRefresh.hidden = true
            self.tblMutation.hidden = false
            self.setupTable()
        }
    }
    
    func setupTable() {
        if (self.tblMutation.delegate == nil) {
            tblMutation.dataSource = self
            tblMutation.delegate = self
        }
        
        tblMutation.reloadData()
    }
}

// MARK: - Class

class BalanceMutationCell : UITableViewCell {
    
    @IBOutlet var lblPlusMinus: UILabel!
    @IBOutlet var lblMutation: UILabel!
    @IBOutlet var lblBalance: UILabel!
    @IBOutlet var lblDescription: UILabel!
    @IBOutlet var lblTime: UILabel!
    
    func adapt(mutation : BalanceMutationItem) {
        if (mutation.entryType == 0) { // Kredit
            lblPlusMinus.text = ""
            lblPlusMinus.textColor = Theme.ThemeOrange
            lblMutation.textColor = Theme.ThemeOrange
        } else if (mutation.entryType == 1) { // Debit
            lblPlusMinus.text = ""
            lblPlusMinus.textColor = Theme.PrimaryColor
            lblMutation.textColor = Theme.PrimaryColor
        }
        lblMutation.text = mutation.amount
        lblBalance.text = mutation.totalAmount
        lblDescription.text = mutation.reasonDetail
        lblTime.text = mutation.time
    }
}