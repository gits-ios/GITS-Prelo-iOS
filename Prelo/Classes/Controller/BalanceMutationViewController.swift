//
//  BalanceMutationViewController.swift
//  Prelo
//
//  Created by PreloBook on 7/13/16.
//  Copyright © 2016 PT Kleo Appara Indonesia. All rights reserved.
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
    
    @IBOutlet weak var lblBalanceAmount: UILabel!
    @IBOutlet weak var tblMutation: UITableView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var btnRefresh: UIButton!
    @IBOutlet weak var bottomLoadingPanel: UIView!
    
    var refreshControl : UIRefreshControl!
    var nextIdx : Int = 0
    let ItemPerLoad : Int = 10
    var isAllItemLoaded : Bool = false
    
    var balanceMutationItems : [BalanceMutationItem]?
    
    var topUpItems : [TopUpItem]? = []
    
    var totalPreloBalance : Int64 = 0
    
    var isRefreshing = false
    
    var isTopUp = false
    
    @IBOutlet weak var lblMutasi: UILabel!
    @IBOutlet weak var lblPreloBalance: UILabel!
    @IBOutlet weak var vwMutasiSelected: UIView!
    @IBOutlet weak var vwTopUpSelected: UIView!
    
    @IBOutlet weak var mutasiButton: UIButton!
    @IBOutlet weak var topUpButton: UIButton!
    @IBAction func mutasiButtonPressed(_ sender: Any) {
        isTopUp = false
        lblMutasi.text = "Mutasi"
        lblPreloBalance.text = "Prelo Balance"
        vwMutasiSelected.isHidden = false
        vwTopUpSelected.isHidden = true
        refreshTable()
    }
    @IBAction func topUpButtonPressed(_ sender: Any) {
        isTopUp = true
        lblMutasi.text = "Transaksi"
        lblPreloBalance.text = "Status"
        vwMutasiSelected.isHidden = true
        vwTopUpSelected.isHidden = false
        refreshTable()
    }
    
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vwTopUpSelected.isHidden = true
        
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
        self.isRefreshing = true
        
        // Reset data
        self.balanceMutationItems = []
        self.topUpItems = []
        self.nextIdx = 0
        self.isAllItemLoaded = false
//        self.showLoading()
        
        getBalanceMutations()
        getTopUp()
    }
    
    func getBalanceMutations() {
        let _ = request(APIMe.getBalanceMutations(current: self.nextIdx, limit: (nextIdx + ItemPerLoad))).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Mutasi Prelo Balance")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]["prelo_balances"]
                let dataCount = data.count
                
                // Set Prelo Balance text
                if (self.nextIdx == 0) { // First request
                    self.totalPreloBalance = json["_data"]["total_prelo_balance"].int64Value
                }
//                let f = NumberFormatter()
//                f.numberStyle = NumberFormatter.Style.currency
//                f.currencySymbol = ""
//                f.locale = Locale(identifier: "id_ID")
//                self.lblBalanceAmount.text = f.string(from: NSNumber(value: self.totalPreloBalance as Int))
                self.lblBalanceAmount.text = self.totalPreloBalance.asPrice
                
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
            
            self.isRefreshing = false
        }
    }
    func getTopUp(){
        let _ = request(APIMe.getTopUps(current: self.nextIdx, limit: (nextIdx + ItemPerLoad))).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Top Up Prelo Balance")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                let dataCount = data.count
                
                for (_, item) in data {
                    let b = TopUpItem.instance(item)
                    if (b != nil) {
                        self.topUpItems?.append(b!)
                    }
                }
                print(self.topUpItems?.count)
                
            }
            
            // Hide loading (for first time request)
            self.hideLoading()
            
            // Hide bottomLoading (for next request)
            self.hideBottomLoading()
            
            // Hide refreshControl (for refreshing)
            self.refreshControl.endRefreshing()
            
            // Show content
            self.showContent()
            
            self.isRefreshing = false
        }
    }
    
    // MARK: - UITableView functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(isTopUp)
        if(isTopUp){
            print("masuk sini coba")
            print(topUpItems!.count)
            print(topUpItems != nil)
            if (topUpItems != nil) {
                return topUpItems!.count
            }
        } else {
            if (balanceMutationItems != nil) {
                return balanceMutationItems!.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(isTopUp){
            let cell : BalanceMutationCell = self.tblMutation.dequeueReusableCell(withIdentifier: "BalanceMutationCell") as! BalanceMutationCell
            if topUpItems?.count > 0 {
                if let b = topUpItems?[(indexPath as NSIndexPath).row] {
                    return BalanceMutationCell.heightFor2(b, lblDescription: cell.lblDescription, lblReasonAdmin: cell.lblReasonAdmin, lblWJP: cell.lblWJP)
                }
            }
        } else {
            let cell : BalanceMutationCell = self.tblMutation.dequeueReusableCell(withIdentifier: "BalanceMutationCell") as! BalanceMutationCell
            if balanceMutationItems?.count > 0 {
                if let b = balanceMutationItems?[(indexPath as NSIndexPath).row] {
                    return BalanceMutationCell.heightFor(b, lblDescription: cell.lblDescription, lblReasonAdmin: cell.lblReasonAdmin, lblWJP: cell.lblWJP)
                }
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : BalanceMutationCell = self.tblMutation.dequeueReusableCell(withIdentifier: "BalanceMutationCell") as! BalanceMutationCell
        if(isTopUp){
            if topUpItems?.count > 0 {
                
                cell.selectionStyle = .none
                cell.alpha = 1.0
                cell.backgroundColor = UIColor.white
                
                if let b = topUpItems?[(indexPath as NSIndexPath).item] {
                    cell.adapt2(b)
                    
                }
            }
        } else {
            if balanceMutationItems?.count > 0 {
                
                cell.selectionStyle = .none
                cell.alpha = 1.0
                cell.backgroundColor = UIColor.white
                
                if let b = balanceMutationItems?[(indexPath as NSIndexPath).item] {
                    cell.adapt(b)
                    if b.isHold {
                        cell.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) //UIColor(hex: "E5E9EB")
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(isTopUp){
            if let b = topUpItems?[(indexPath as NSIndexPath).row] {
                print(b.id)
                print(b.json)
                if(b.progress == 0){
                    let o = Bundle.main.loadNibNamed(Tags.XibNameTopUpConfirm, owner: nil, options: nil)?.first as! TopUpConfirmViewController
                    
                    o.orderID = b.ticket_number
                    o.total = Int64(b.amount + b.banktransfer_digit)
                    //o.date = b.create_time
                    
                    o.isBackTwice = false
                    o.targetBank = b.target_bank
                    o.previousScreen = PageName.BalanceMutation
                    
                    o.isFromCheckout = false
                    
                    self.navigateToVC(o)
                }
            }
        } else {
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
                    
                    transactionDetailVC.previousScreen = PageName.Mutation
                    
                    self.navigationController?.pushViewController(transactionDetailVC, animated: true)
                }
            }
        }
    }
    
    func navigateToVC(_ vc: UIViewController) {
        if (previousController != nil) {
            self.previousController!.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if(isTopUp){
        } else {
            let offset : CGPoint = scrollView.contentOffset
            let bounds : CGRect = scrollView.bounds
            let size : CGSize = scrollView.contentSize
            let inset : UIEdgeInsets = scrollView.contentInset
            let y : CGFloat = offset.y + bounds.size.height - inset.bottom
            let h : CGFloat = size.height
            
            let reloadDistance : CGFloat = 0
            if (y > h + reloadDistance && !self.isRefreshing) {
                // Load next items only if all items not loaded yet and if its not currently loading items
                if (!self.isAllItemLoaded && self.bottomLoadingPanel.isHidden) {
                    // Show bottomLoading
                    self.showBottomLoading()
                    
                    // Get balance mutations
                    self.getBalanceMutations()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func tarikUangPressed(_ sender: AnyObject) {
//        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let t = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdTarikTunai) as! TarikTunaiController
//        self.navigationController?.pushViewController(t, animated: true)
        
//        let t = Bundle.main.loadNibNamed(Tags.XibNameTarikTunai2, owner: nil, options: nil)?.first as! TarikTunaiViewController2
//        t.previousScreen = PageName.Mutation
//        self.navigationController?.pushViewController(t, animated: true)
        
        let t = Bundle.main.loadNibNamed(Tags.XibNameTarikTunai3, owner: nil, options: nil)?.first as! TarikTunaiViewController3
        t.previousScreen = PageName.Mutation
        self.navigationController?.pushViewController(t, animated: true)
    }
    
    @IBAction func topUpPressed(_ sender: Any) {
        let t = Bundle.main.loadNibNamed(Tags.XibNameTopUp, owner: nil, options: nil)?.first as! TopUpViewController
        t.preloBalance = self.lblBalanceAmount.text!
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
        if(isTopUp){
            if (self.topUpItems?.count <= 0) {
                self.lblEmpty.isHidden = false
                self.btnRefresh.isHidden = true
                self.tblMutation.isHidden = true
            } else {
                self.lblEmpty.isHidden = true
                self.btnRefresh.isHidden = true
                self.tblMutation.isHidden = false
                self.setupTable()
            }
        } else {
            if (self.balanceMutationItems?.count <= 0) {
                self.lblEmpty.isHidden = false
                self.btnRefresh.isHidden = true
                self.tblMutation.isHidden = true
            } else {
                self.lblEmpty.isHidden = true
                self.btnRefresh.isHidden = true
                self.tblMutation.isHidden = false
                self.setupTable()
            }
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
    
    @IBOutlet weak var lblPlusMinus: UILabel!
    @IBOutlet weak var lblMutation: UILabel!
    @IBOutlet weak var lblBalance: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblReasonAdmin: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblWJP: UILabel!
    @IBOutlet weak var imgWJP: UIImageView! // default hide
    
    var idTopUp: String! = ""
    
    @IBOutlet weak var consHeightLblDescription: NSLayoutConstraint!
    @IBOutlet weak var consHeightLblReasonAdmin: NSLayoutConstraint!
    @IBOutlet weak var consHeightLblWJP: NSLayoutConstraint!
    
    override func prepareForReuse() {
        self.contentView.backgroundColor = UIColor(hexString: "#FFFFFF")
    }
    
    static func heightFor(_ mutation : BalanceMutationItem, lblDescription : UILabel, lblReasonAdmin : UILabel, lblWJP : UILabel) -> CGFloat {
        
        lblDescription.text = mutation.reasonDetail
        lblReasonAdmin.text = mutation.reasonAdmin
        let rectDesc = UIScreen.main.bounds.size.width - 118
        let rectReason = UIScreen.main.bounds.size.width - 118
        let sizeFixDesc = mutation.reasonDetail.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: rectDesc)
        let sizeFixReasonAdmin = mutation.reasonAdmin.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: rectReason)
        
        var wjpSize = CGFloat(0)
        if (mutation.isHold) {
//            let wjp = "Pemasukan transaksi ini masih dalam Waktu Jaminan Prelo sehingga tidak bisa ditarik (tunggu hingga 3x24 jam setelah barang diterima)"
            
            let wjp = mutation.notes
            
            lblWJP.text = wjp
            let rectWJP = UIScreen.main.bounds.size.width - 50
            
            let sizeFixWJP = wjp.boundsWithFontSize(UIFont.systemFont(ofSize: 10), width: rectWJP)
            
            wjpSize += (sizeFixWJP.height + 16)
        }
        
        return 56 + sizeFixDesc.height + 2 + (lblReasonAdmin.text! != "" ? sizeFixReasonAdmin.height + 2 : 0) + wjpSize
    }
    
    static func heightFor2(_ mutation : TopUpItem, lblDescription : UILabel, lblReasonAdmin : UILabel, lblWJP : UILabel) -> CGFloat {
        lblReasonAdmin.text = mutation.progress_detail
        let rectDesc = UIScreen.main.bounds.size.width - 118
        let rectReason = UIScreen.main.bounds.size.width - 118
        let reason = mutation.progress_detail + mutation.ticket_number
        let sizeFixReasonAdmin = reason.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: rectReason)
        
        var wjpSize = CGFloat(0)
        
        return 58 + (lblReasonAdmin.text! != "" ? sizeFixReasonAdmin.height + 2 : 0) + wjpSize
    }
    
    func adapt(_ mutation : BalanceMutationItem) {
        lblPlusMinus.isHidden = false
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
        let rectDesc = UIScreen.main.bounds.size.width - 118
        let sizeFixDesc = mutation.reasonDetail.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: rectDesc)
        consHeightLblDescription.constant = sizeFixDesc.height + 2
        
        let rectReason = UIScreen.main.bounds.size.width - 118
        let sizeFixReasonAdmin = mutation.reasonAdmin.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: rectReason)
        consHeightLblReasonAdmin.constant = (mutation.reasonAdmin != "" ? sizeFixReasonAdmin.height + 2 : 0)
        
        if (mutation.isHold) {
//            let wjp = "Pemasukan transaksi ini masih dalam Waktu Jaminan Prelo sehingga tidak bisa ditarik (tunggu hingga 3x24 jam setelah barang diterima)"
            
            let wjp = mutation.notes
            
            lblWJP.text = wjp
            
            let attrStr = NSMutableAttributedString(string: wjp)
            
            attrStr.addAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 10.0)], range: (wjp as NSString).range(of: "Waktu Jaminan Prelo"))
            
            lblWJP.attributedText = attrStr
            
            let rectWJP = UIScreen.main.bounds.size.width - 50
            
            let sizeFixWJP = wjp.boundsWithFontSize(UIFont.systemFont(ofSize: 10), width: rectWJP)
            
            consHeightLblWJP.constant = sizeFixWJP.height + 8
            imgWJP.isHidden = false
        } else {
            consHeightLblWJP.constant = 0
            imgWJP.isHidden = true
        }

    }
    func adapt2(_ mutation : TopUpItem) {
        if(mutation.progress == 0){
            self.contentView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        }
        lblPlusMinus.isHidden = true
        lblDescription.isHidden = true
        imgWJP.isHidden = true
        idTopUp = mutation.id
        lblMutation.text = mutation.amount.asPrice
        let attrStrId = NSMutableAttributedString(string: mutation.ticket_number)
        attrStrId.addAttributes([NSForegroundColorAttributeName:UIColor(hexString: "#14988B")], range: NSMakeRange(0, mutation.ticket_number.length))
        //self.lblReasonAdmin.attributedText = attrStrId
        let attrStrReason = NSMutableAttributedString(string: mutation.progress_detail + " ")
        attrStrReason.append(attrStrId)
        
        var lblReasonText = attrStrReason
        var lblTempReasonText = mutation.progress_detail + " " + mutation.ticket_number
        lblReasonAdmin.attributedText = lblReasonText
        lblTime.text = mutation.time
        if(mutation.progress == 0){
            lblBalance.text = "BELUM BAYAR"
            lblMutation.textColor = Theme.ThemeOrange
            lblBalance.textColor = Theme.ThemeRed
        } else if (mutation.progress == 2){
            lblBalance.text = "BERHASIL"
            lblMutation.textColor = UIColor(hexString: "#14988B")
            lblBalance.textColor = UIColor(hexString: "#14988B")
        } else if (mutation.progress == 1){
            lblBalance.text = "SUDAH BAYAR"
            lblMutation.textColor = UIColor(hexString: "#14988B")
            lblBalance.textColor = UIColor(hexString: "#14988B")
        } else {
            lblBalance.text = "DITOLAK"
            lblMutation.textColor = Theme.ThemeOrange
            lblBalance.textColor = Theme.ThemeRed
        }
        
        // Label height fix
        consHeightLblDescription.constant = 0
        consHeightLblWJP.constant = 0
        let rectReason = UIScreen.main.bounds.size.width - 118
        let sizeFixReasonAdmin = lblTempReasonText.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: rectReason)
        consHeightLblReasonAdmin.constant = (lblTempReasonText != "" ? sizeFixReasonAdmin.height + 2 : 0)
        
    }
}
