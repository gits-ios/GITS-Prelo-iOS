//
//  BalanceMutationViewController.swift
//  Prelo
//
//  Created by PreloBook on 7/13/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
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

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
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
    
    var totalPreloBalance : Int = 0
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tblMutation.tableFooterView = UIView()
        
        // Register custom cell
        let balanceMutationCellNib = UINib(nibName: "BalanceMutationCell", bundle: nil)
        tblMutation.register(balanceMutationCellNib, forCellReuseIdentifier: "BalanceMutationCell")
        
        // Loading
        loadingPanel.backgroundColor = UIColor(white: 1, alpha: 0.5)
        bottomLoadingPanel.backgroundColor = UIColor(white: 1, alpha: 0.5)
        self.showLoading()
        self.hideBottomLoading()
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(BalanceMutationViewController.refreshTable), for: UIControlEvents.valueChanged)
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
//        self.showLoading()
        
        getBalanceMutations()
    }
    
    func getBalanceMutations() {
        let _ = request(APIMe.getBalanceMutations(current: self.nextIdx, limit: (nextIdx + ItemPerLoad))).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Mutasi Prelo Balance")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]["prelo_balances"]
                let dataCount = data.count
                
                // Set Prelo Balance text
                if (self.nextIdx == 0) { // First request
                    self.totalPreloBalance = json["_data"]["total_prelo_balance"].intValue
                }
                let f = NumberFormatter()
                f.numberStyle = NumberFormatter.Style.currency
                f.currencySymbol = ""
                f.locale = Locale(identifier: "id_ID")
                self.lblBalanceAmount.text = f.string(from: NSNumber(value: self.totalPreloBalance as Int))
                
                // Store data into variable
                var nextTotalAmount = self.totalPreloBalance
                if (self.balanceMutationItems?.count > 0) {
                    if let b = self.balanceMutationItems?[self.balanceMutationItems!.count - 1] {
                        if (b.entryType == 0) { // Kredit
                            nextTotalAmount = b.totalAmount + b.amount
                        } else if (b.entryType == 1) { // Debit
                            nextTotalAmount = b.totalAmount - b.amount
                        }
                    }
                }
                for (_, item) in data {
                    let b = BalanceMutationItem.instance(item, totalAmount: nextTotalAmount)
                    if (b != nil) {
                        self.balanceMutationItems?.append(b!)
                        if (b!.entryType == 0) { // Kredit 
                            nextTotalAmount += b!.amount
                        } else if (b!.entryType == 1) { // Debit
                            nextTotalAmount -= b!.amount
                        }
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (balanceMutationItems != nil) {
            return balanceMutationItems!.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell : BalanceMutationCell = self.tblMutation.dequeueReusableCell(withIdentifier: "BalanceMutationCell") as! BalanceMutationCell
        if balanceMutationItems?.count > 0 {
            if let b = balanceMutationItems?[(indexPath as NSIndexPath).row] {
                return BalanceMutationCell.heightFor(b, lblDescription: cell.lblDescription, lblReasonAdmin: cell.lblReasonAdmin)
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : BalanceMutationCell = self.tblMutation.dequeueReusableCell(withIdentifier: "BalanceMutationCell") as! BalanceMutationCell
        if balanceMutationItems?.count > 0 {
            if let b = balanceMutationItems?[(indexPath as NSIndexPath).item] {
                cell.adapt(b)
                if b.isHold {
                    cell.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) //UIColor(hex: "E5E9EB")
                } else {
                    cell.backgroundColor = UIColor.clear
                }
            }
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let b = balanceMutationItems?[(indexPath as NSIndexPath).row] {
            if (b.type != "" && b.isSeller != nil) {
                let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let transactionDetailVC : TransactionDetailViewController = (mainStoryboard.instantiateViewController(withIdentifier: "TransactionDetail") as? TransactionDetailViewController)!
                
                if (b.type.lowercased() == "transaction") {
                    transactionDetailVC.trxId = b.reasonId
                } else if (b.type.lowercased() == "transaction_product") {
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset : CGPoint = scrollView.contentOffset
        let bounds : CGRect = scrollView.bounds
        let size : CGSize = scrollView.contentSize
        let inset : UIEdgeInsets = scrollView.contentInset
        let y : CGFloat = offset.y + bounds.size.height - inset.bottom
        let h : CGFloat = size.height
        
        let reloadDistance : CGFloat = 0
        if (y > h + reloadDistance && self.balanceMutationItems?.count > 0) {
            // Load next items only if all items not loaded yet and if its not currently loading items
            if (!self.isAllItemLoaded && self.bottomLoadingPanel.isHidden) {
                // Show bottomLoading
                self.showBottomLoading()
                
                // Get balance mutations
                self.getBalanceMutations()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func tarikUangPressed(_ sender: AnyObject) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let t = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdTarikTunai) as! TarikTunaiController
        self.navigationController?.pushViewController(t, animated: true)
    }
    
    @IBAction func refreshPressed(_ sender: AnyObject) {
        self.refreshTable()
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    func showBottomLoading() {
        self.bottomLoadingPanel.isHidden = false
    }
    
    func hideBottomLoading() {
        self.bottomLoadingPanel.isHidden = true
    }
    
    func showContent() {
        if (self.balanceMutationItems?.count <= 0) {
            self.lblEmpty.isHidden = false
            self.btnRefresh.isHidden = false
            self.tblMutation.isHidden = true
        } else {
            self.lblEmpty.isHidden = true
            self.btnRefresh.isHidden = true
            self.tblMutation.isHidden = false
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
    @IBOutlet var lblReasonAdmin: UILabel!
    @IBOutlet var lblTime: UILabel!
    
    @IBOutlet var consHeightLblDescription: NSLayoutConstraint!
    @IBOutlet var consHeightLblReasonAdmin: NSLayoutConstraint!
    
    static func heightFor(_ mutation : BalanceMutationItem, lblDescription : UILabel, lblReasonAdmin : UILabel) -> CGFloat {
        
//        let maxLblWidth = UIScreen.mainScreen().bounds.size.width - 126
//        let maxLblHeight = CGFloat.max
//        
//        var heightLblDesc : CGFloat = 0
//        if let h = lblDescription.attributedText?.boundingRectWithSize(CGSizeMake(maxLblWidth, maxLblHeight), options: .UsesLineFragmentOrigin, context: nil).height {
//            heightLblDesc = h
//        }
//        
//        var heightLblReason : CGFloat = 0
//        if let h = lblReasonAdmin.text?.boundsWithFontSize(UIFont.systemFontOfSize(12), width: maxLblWidth) {
//            
//        }
//        if let h = lblReasonAdmin.text?.boundingRectWithSize(CGSizeMake(maxLblWidth, maxLblHeight), options: .UsesLineFragmentOrigin, context: nil).height {
//            heightLblReason = h
//        }
//        
//        return 56 + heightLblDesc + heightLblReason
        
        lblDescription.text = mutation.reasonDetail
        lblReasonAdmin.text = mutation.reasonAdmin
        var rectDesc = lblDescription.frame.size
//        rectDesc.width = UIScreen.main.bounds.size.width - 111
        var rectReason = lblReasonAdmin.frame.size
//        rectReason.width = UIScreen.main.bounds.size.width - 111
        let sizeFixDesc = mutation.reasonDetail.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: rectDesc.width)
        let sizeFixReasonAdmin = mutation.reasonAdmin.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: rectReason.width)
        return 56 + sizeFixDesc.height + (lblReasonAdmin.text! != "" ? sizeFixReasonAdmin.height : 0)
    }
    
    func adapt(_ mutation : BalanceMutationItem) {
        if (mutation.entryType == 0) { // Kredit
            lblPlusMinus.text = ""
            lblPlusMinus.textColor = Theme.ThemeOrange
            lblMutation.textColor = Theme.ThemeOrange
        } else if (mutation.entryType == 1) { // Debit
            lblPlusMinus.text = ""
            lblPlusMinus.textColor = Theme.PrimaryColor
            lblMutation.textColor = Theme.PrimaryColor
        }
        lblMutation.text = mutation.amount.asPrice
        lblBalance.text = mutation.totalAmount.asPrice
        lblReasonAdmin.text = mutation.reasonAdmin
        lblTime.text = mutation.time
        
        // lblDescription text
        let trxIdStartIdx = mutation.reasonDetail.indexOfCharacter("#")
        var trxIdLength = 0
        if (trxIdStartIdx != -1) {
            trxIdLength = mutation.reasonDetail.components(separatedBy: "#")[1].components(separatedBy: " ")[0].length + 1
        }
        let attrStrDesc = NSMutableAttributedString(string: mutation.reasonDetail)
        attrStrDesc.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColor], range: NSMakeRange(trxIdStartIdx, trxIdLength))
        self.lblDescription.attributedText = attrStrDesc
        
        // Label height fix
        var rectDesc = lblDescription.frame.size
//        rectDesc.width = UIScreen.main.bounds.size.width - 111
        let sizeFixDesc = mutation.reasonDetail.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: rectDesc.width)
        consHeightLblDescription.constant = sizeFixDesc.height
        var rectReason = lblReasonAdmin.frame.size
//        rectReason.width = UIScreen.main.bounds.size.width - 111
        let sizeFixReasonAdmin = mutation.reasonAdmin.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: rectReason.width)
        consHeightLblReasonAdmin.constant = (mutation.reasonAdmin != "" ? sizeFixReasonAdmin.height : 0)
    }
}
