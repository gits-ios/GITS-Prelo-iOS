//
//  TransactionDetailViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/11/16.
//  Copyright (c) 2016 GITS Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class

class TransactionDetailViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    // Variables from previous screen
    var trxId : String?
    var trxProductId : String?
    var isSeller : Bool?
    var productName : String = "Detail Transaksi"
    
    // Data container
    var trxDetail : TransactionDetail?
    var trxProductDetail : TransactionProductDetail?
    var progress : Int?
    
    // Cell identifiers
    let TransactionDetailTableCellId = "TransactionDetailTableCell"
    let TransactionDetailDescriptionCellId = "TransactionDetailDescriptionCell"
    let TransactionDetailBorderedButtonCellId = "TransactionDetailBorderedButtonCell"
    let TransactionDetailContactPreloCellId = "TransactionDetailContactPreloCell"
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        getTransactionDetail()
        self.title = productName
    }
    
    func getTransactionDetail() {
        var req : URLRequestConvertible?
        if (trxId != nil) {
            if (userIsSeller()) {
                req = APITransactionAnggi.GetSellerTransaction(id: trxId!)
            } else {
                req = APITransactionAnggi.GetBuyerTransaction(id: trxId!)
            }
        } else if (trxProductId != nil) {
            req = APITransactionAnggi.GetTransactionProduct(id: trxProductId!)
        }
        
        if (req != nil) {
            request(req!).responseJSON { req, resp, res, err in
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Detail Transaksi")) {
                    let json = JSON(res!)
                    let data = json["_data"]
                    
                    if (self.trxId != nil) {
                        self.trxDetail = TransactionDetail.instance(data)
                        self.progress = self.trxDetail?.progress
                    } else {
                        self.trxProductDetail = TransactionProductDetail.instance(data)
                        self.progress = self.trxProductDetail?.progress
                    }
                    
                    self.setupTable()
                }
            }
        }
    }
    
    // MARK: - TableView delegate functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Jumlah baris bergantung pada progres transaksi
        return 4
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Urutan index bergantung pada progres transaksi
        let idx = indexPath.row
        
        if (idx == 0) { // Table cell
            return 0
        } else if (idx == 1) { // Description cell
            return TransactionDetailDescriptionCell.heightFor(progress)
        } else if (idx == 2) { // Bordered button cell
            return 56
        } else if (idx == 3) { // Contact prelo cell
            return 56
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Urutan index bergantung pada progres transaksi
        let idx = indexPath.row
        
        if (idx == 0) { // Table cell
            let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailTableCellId) as! TransactionDetailTableCell
//            cell.adapt
            return cell
        } else if (idx == 1) { // Description cell
            let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailDescriptionCellId) as! TransactionDetailDescriptionCell
            if (trxDetail != nil) {
                cell.adapt(trxDetail!)
            }
            return cell
        } else if (idx == 2) { // Bordered button cell
            let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailBorderedButtonCellId) as! TransactionDetailBorderedButtonCell
            if (trxDetail != nil) {
                cell.adapt(trxDetail!)
            }
            return cell
        } else if (idx == 3) { // Contact prelo cell
            let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailContactPreloCellId) as! TransactionDetailContactPreloCell
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    // MARK: - Other functions
    
    func userIsSeller() -> Bool {
        return (isSeller != nil && isSeller == true)
    }
    
    func hideLoading() {
        loadingPanel.hidden = true
        loading.hidden = true
        loading.stopAnimating()
    }
    
    func showLoading() {
        loadingPanel.hidden = false
        loading.hidden = false
        loading.startAnimating()
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
}

// MARK: - Class

class TransactionDetailTableCell : UITableViewCell {
    @IBOutlet weak var tableView: UITableView!
    
}

// MARK: - Class

class TransactionDetailProductCell : UITableViewCell {
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lblOrderId: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var vwTransactionStatus: UIView!
    @IBOutlet weak var lblTransactionStatus: UILabel!
    
}

// MARK: - Class

class TransactionDetailTools : NSObject {
    static let Margin : CGFloat = 8.0
    static let textPembayaranExpired = "Pembayaran expired karena kamu belum membayar hingga batas waktu yang ditentukan."
}

// MARK: - Class

class TransactionDetailDescriptionCell : UITableViewCell {
    @IBOutlet weak var lblDesc: UILabel!
    
    static func heightFor(progress : Int?) -> CGFloat {
        if (progress != nil) {
            var textRect : CGRect?
            if (progress == -1) { // Pembayaran expired
                textRect = TransactionDetailTools.textPembayaranExpired.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
            }
            if (textRect != nil) {
                return textRect!.height + (2 * TransactionDetailTools.Margin)
            }
        }
        return 60
    }
    
    func adapt(trxDetail : TransactionDetail) {
        let progress = trxDetail.progress
        if (progress == -1) { // Pembayaran expired
            lblDesc.text = TransactionDetailTools.textPembayaranExpired
        }
    }
}

// MARK: - Class

class TransactionDetailTitleCell : UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    
}

// MARK: - Class

class TransactionDetailTitleContentCell : UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    
}

// MARK: - Class

class TransactionDetailButtonCell : UITableViewCell {
    @IBOutlet weak var btn: UIButton!
    
    @IBAction func btnPressed(sender: AnyObject) {
    }
}

// MARK: - Class

class TransactionDetailBorderedButtonCell : UITableViewCell {
    @IBOutlet weak var btn: BorderedButton!
    
    var progress : Int?
    
    func adapt(trxDetail : TransactionDetail) {
        progress = trxDetail.progress
        if (progress == -1) { // Pembayaran expired
            btn.setTitle("PESAN LAGI BARANG YANG SAMA", forState: UIControlState.Normal)
        }
    }
    
    @IBAction func btnPressed(sender: AnyObject) {
        if (progress == -1) { // Pembayaran expired
            Constant.showDialog("Button pressed", message: "PESAN LAGI BARANG YANG SAMA")
        }
    }
}

// MARK: - Class

class TransactionDetailReviewCell : UITableViewCell {
    @IBOutlet weak var imgReviewer: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblLove: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    
    func adapt(trxDetail : TransactionDetail) {
        
    }
}

// MARK: - Class

class TransactionDetailContactPreloCell : UITableViewCell {
    
    @IBAction func btnContactPressed(sender: AnyObject) {
    }
}
