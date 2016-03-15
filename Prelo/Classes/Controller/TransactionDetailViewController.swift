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
    let TransactionDetailTitleCellId = "TransactionDetailTitleCell"
    let TransactionDetailBorderedButtonCellId = "TransactionDetailBorderedButtonCell"
    let TransactionDetailContactPreloCellId = "TransactionDetailContactPreloCell"
    
    // Titles
    let TitlePembayaran = "PEMBAYARAN"
    let TitlePengiriman = "PENGIRIMAN"
    let TitleReview = "REVIEW"
    
    // Contact us view
    var contactUs : UIViewController?
    
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
        if (progress == TransactionDetailTools.ProgressExpired) {
            if (userIsSeller()) {
                return 3
            } else {
                return 4
            }
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller) {
            if (userIsSeller()) {
                return 9
            } else {
                return 8
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Urutan index bergantung pada progres transaksi
        let idx = indexPath.row
        let DefaultHeight : CGFloat = 56
        
        if (progress == TransactionDetailTools.ProgressExpired) {
            if (userIsSeller()) {
                if (idx == 0) { // Table cell
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightFor(trxDetail!.transactionProducts)
                    }
                } else if (idx == 1) { // Description cell
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller)
                } else if (idx == 2) { // Contact prelo cell
                    return DefaultHeight
                }
            } else {
                if (idx == 0) { // Table cell
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightFor(trxDetail!.transactionProducts)
                    }
                } else if (idx == 1) { // Description cell
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller)
                } else if (idx == 2) { // Bordered button cell
                    return DefaultHeight
                } else if (idx == 3) { // Contact prelo cell
                    return DefaultHeight
                }
            }
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller) {
            if (userIsSeller()) {
                if (idx == 0) {
                    
                } else if (idx == 1) {
                    
                } else if (idx == 2) {
                    
                } else if (idx == 3) {
                    
                } else if (idx == 4) {
                    
                } else if (idx == 5) {
                    
                } else if (idx == 6) {
                    
                } else if (idx == 7) {
                    
                } else if (idx == 8) {
                    
                }
            } else {
                
            }
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Urutan index bergantung pada progres transaksi
        let idx = indexPath.row
        
        if (progress == TransactionDetailTools.ProgressExpired) {
            if (userIsSeller()) {
                if (idx == 0) {
                    return self.createTableCell()
                } else if (idx == 1) {
                    return self.createDescriptionCell()
                } else if (idx == 2) {
                    return self.createContactPreloCell()
                }
            } else {
                if (idx == 0) {
                    return self.createTableCell()
                } else if (idx == 1) {
                    return self.createDescriptionCell()
                } else if (idx == 2) {
                    return self.createBorderedButtonCell()
                } else if (idx == 3) {
                    return self.createContactPreloCell()
                }
            }
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller) {
            if (userIsSeller()) {
                if (idx == 0) {
                    return self.createTableCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    
                } else if (idx == 3) {
                    return self.createTitleCell(TitlePengiriman)
                } else if (idx == 4) {
                    
                } else if (idx == 5) {
                    return self.createTitleCell(TitleReview)
                } else if (idx == 6) {
                    return self.createDescriptionCell()
                } else if (idx == 7) {
                    return self.createBorderedButtonCell()
                } else if (idx == 8) {
                    return self.createContactPreloCell()
                }
            } else {
                
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    // MARK: - Cell creation
    
    func createTableCell() -> TransactionDetailTableCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailTableCellId) as! TransactionDetailTableCell
        
        // Adapt cell
        if (self.progress == TransactionDetailTools.ProgressExpired || self.progress == TransactionDetailTools.ProgressNotPaid || self.progress == TransactionDetailTools.ProgressClaimedPaid) {
            if (trxDetail != nil) {
                cell.adapt(trxDetail!.transactionProducts)
            }
        } else if (self.progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (userIsSeller()) {
                if (trxDetail != nil) {
                    cell.adapt(trxDetail!.transactionProducts)
                }
            } else {
                if (trxProductDetail != nil) {
                    cell.adapt([trxProductDetail!])
                }
            }
        } else {
            if (trxProductDetail != nil) {
                cell.adapt([trxProductDetail!])
            }
        }
        
        return cell
    }
    
    func createDescriptionCell() -> TransactionDetailDescriptionCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailDescriptionCellId) as! TransactionDetailDescriptionCell
        
        // Adapt cell
        if (self.progress == TransactionDetailTools.ProgressExpired || self.progress == TransactionDetailTools.ProgressNotPaid || self.progress == TransactionDetailTools.ProgressClaimedPaid) {
            if (trxDetail != nil) {
                cell.adapt(trxDetail!)
            }
        } else if (self.progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (userIsSeller()) {
                if (trxDetail != nil) {
                    cell.adapt(trxDetail!)
                }
            } else {
                if (trxProductDetail != nil) {
                    
                }
            }
        } else {
            if (trxProductDetail != nil) {
                
            }
        }
        
        return cell
    }
    
    func createTitleCell(title : String) -> TransactionDetailTitleCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailTitleCellId) as! TransactionDetailTitleCell
        
        // Adapt cell
        cell.adapt(title)
        
        return cell
    }
    
    func createBorderedButtonCell() -> TransactionDetailBorderedButtonCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailBorderedButtonCellId) as! TransactionDetailBorderedButtonCell
        
        // Adapt cell
        if (self.progress == TransactionDetailTools.ProgressExpired || self.progress == TransactionDetailTools.ProgressNotPaid || self.progress == TransactionDetailTools.ProgressClaimedPaid) {
            if (trxDetail != nil) {
                cell.adapt(trxDetail!)
            }
        } else if (self.progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (userIsSeller()) {
                if (trxDetail != nil) {
                    cell.adapt(trxDetail!)
                }
            } else {
                if (trxProductDetail != nil) {
                    
                }
            }
        } else {
            if (trxProductDetail != nil) {
                
            }
        }
        
        return cell
    }
    
    func createContactPreloCell() -> TransactionDetailContactPreloCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailContactPreloCellId) as! TransactionDetailContactPreloCell
        
        // Adapt cell
        cell.showContactPrelo = {
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let c = mainStoryboard.instantiateViewControllerWithIdentifier("contactus") as! UIViewController
            self.contactUs = c
            if let v = c.view, let p = self.navigationController?.view {
                v.alpha = 0
                v.frame = p.bounds
                self.navigationController?.view.addSubview(v)
                
                v.alpha = 0
                UIView.animateWithDuration(0.2, animations: {
                    v.alpha = 1
                })
            }
        }
        
        return cell
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

class TransactionDetailTools : NSObject {
    // Progress number
    static let ProgressExpired = -1
    static let ProgressRejectedBySeller = -3
    static let ProgressNotSent = -4
    static let ProgressNotPaid = 1
    static let ProgressClaimedPaid = 2
    static let ProgressConfirmedPaid = 3
    static let ProgressSent = 4
    static let ProgressReceived = 5
    static let ProgressReviewed = 6
    
    // Layouting
    static let Margin : CGFloat = 8.0
    static let TransactionDetailProductCellHeight : CGFloat = 109
    static let TransactionDetailTitleContentCellHeight : CGFloat = 20
    
    // Text
    static let TextPembayaranExpiredBuyer = "Pembayaran expired karena kamu belum membayar hingga batas waktu yang ditentukan."
    static let TextPembayaranExpiredSeller = "Pembayaran expired karena buyer belum membayar hingga batas waktu yang ditentukan."
    static let TextHubungiBuyer = "Beritahu buyer bahwa barang sudah dikirim. Minta buyer untuk memberikan review apabila barang sudah diterima."
    static let TextHubungiBuyerTolak = "Beritahu buyer bahwa barang tidak dikirim."
}

// MARK: - Class

class TransactionDetailTableCell : UITableViewCell, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var trxProducts : [TransactionProductDetail] = []
    
    // Cell type
    var isProductCell : Bool = false
    var isTitleContentCell : Bool = false
    
    // Cell identifiers
    let TransactionDetailProductCellId = "TransactionDetailProductCell"
    let TransactionDetailTitleContentCellId = "TransactionDetailTitleContentCell"
    
    static func heightFor(trxProducts : [TransactionProductDetail]) -> CGFloat {
        return (CGFloat(trxProducts.count) * TransactionDetailTools.TransactionDetailProductCellHeight)
    }
    
    func adapt(trxProducts : [TransactionProductDetail]) {
        self.trxProducts = trxProducts
        self.isProductCell = true
        self.setupTable()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trxProducts.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (isProductCell) {
            return TransactionDetailTools.TransactionDetailProductCellHeight
        } else if (isTitleContentCell) {
            return TransactionDetailTools.TransactionDetailTitleContentCellHeight
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (isProductCell) {
            let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailProductCellId) as! TransactionDetailProductCell
            cell.adapt(trxProducts[indexPath.row])
            return cell
        } else if (isTitleContentCell) {
            return UITableViewCell()
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Do nothing
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

class TransactionDetailProductCell : UITableViewCell {
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lblOrderId: UILabel!
    @IBOutlet weak var consWidthLblOrderId: NSLayoutConstraint!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var consWidthLblPrice: NSLayoutConstraint!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var vwTransactionStatus: UIView!
    @IBOutlet weak var lblTransactionStatus: UILabel!
    
    override func prepareForReuse() {
        imgProduct.image = UIImage(named: "raisa.jpg")
        vwTransactionStatus.backgroundColor = Theme.GrayDark
        lblTransactionStatus.textColor = Theme.GrayDark
    }
    
    func adapt(trxProductDetail : TransactionProductDetail) {
        // Set image
        if let url = trxProductDetail.productImageURL {
            imgProduct.setImageWithUrl(url, placeHolderImage: nil)
        }
        
        // Set text
        lblOrderId.text = "Order " + trxProductDetail.orderId
        lblTime.text = "| " + trxProductDetail.time
        lblProductName.text = trxProductDetail.productName
        lblPrice.text = trxProductDetail.productPrice.asPrice
        lblUsername.text = "| " + trxProductDetail.sellerUsername
        lblTransactionStatus.text = trxProductDetail.progressText.uppercaseString
        
        // Set color
        if (trxProductDetail.progress < 0) {
            vwTransactionStatus.backgroundColor = Theme.ThemeRed
            lblTransactionStatus.textColor = Theme.ThemeRed
        } else if let userId = User.Id {
            if (trxProductDetail.isSeller(userId)) {
                vwTransactionStatus.backgroundColor = Theme.ThemeRed
                lblTransactionStatus.textColor = Theme.ThemeOrange
            } else {
                vwTransactionStatus.backgroundColor = Theme.ThemeRed
                lblTransactionStatus.textColor = Theme.PrimaryColor
            }
        }
        
        // Fix text width
        let fitSizeLblOrderId = lblOrderId.sizeThatFits(lblOrderId.frame.size)
        consWidthLblOrderId.constant = fitSizeLblOrderId.width
        let fitSizeLblPrice = lblPrice.sizeThatFits(lblPrice.frame.size)
        consWidthLblPrice.constant = fitSizeLblPrice.width
        
        // Set icon
        vwTransactionStatus.layer.cornerRadius = (vwTransactionStatus.frame.size.width) / 2
        var imgName : String?
        let progress = trxProductDetail.progress
        if (progress == TransactionDetailTools.ProgressExpired) {
            imgName = "ic_trx_expired"
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller) {
            imgName = "ic_trx_exclamation"
        } else if (progress == TransactionDetailTools.ProgressNotSent) {
            imgName = "ic_trx_canceled"
        } else if (progress == TransactionDetailTools.ProgressNotPaid) {
            imgName = "ic_trx_expired"
        } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
            imgName = "ic_trx_wait"
        } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
            imgName = "ic_trx_paid"
        } else if (progress == TransactionDetailTools.ProgressSent) {
            imgName = "ic_trx_shipped"
        } else if (progress == TransactionDetailTools.ProgressReceived) {
            imgName = "ic_trx_received"
        } else if (progress == TransactionDetailTools.ProgressReviewed) {
            imgName = "ic_trx_done"
        }
        if (imgName != nil) {
            if let imgIcon = UIImage(named: imgName!) {
                let imgVwIcon : UIImageView = UIImageView(frame: CGRectMake(5, 5, 15, 15), image: imgIcon)
                vwTransactionStatus.addSubview(imgVwIcon)
            }
        }
    }
}

// MARK: - Class

class TransactionDetailDescriptionCell : UITableViewCell {
    @IBOutlet weak var lblDesc: UILabel!
    
    static func heightFor(progress : Int?, isSeller : Bool?) -> CGFloat {
        if (progress != nil && isSeller != nil) {
            var textRect : CGRect?
            if (progress == TransactionDetailTools.ProgressExpired) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextPembayaranExpiredSeller.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    textRect = TransactionDetailTools.TextPembayaranExpiredBuyer.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            }
            if (textRect != nil) {
                return textRect!.height + (2 * TransactionDetailTools.Margin)
            }
        }
        return 0
    }
    
    func adapt(trxDetail : TransactionDetail) {
        if let userId = User.Id {
            let progress = trxDetail.progress
            let isSeller = !trxDetail.isBuyer(userId)
            if (progress == TransactionDetailTools.ProgressExpired) {
                if (isSeller == true) {
                    lblDesc.text = TransactionDetailTools.TextPembayaranExpiredSeller
                } else {
                    lblDesc.text = TransactionDetailTools.TextPembayaranExpiredBuyer
                }
            }
        }
    }
    
    func adapt2(trxProductDetail : TransactionProductDetail) {
        if let userId = User.Id {
            let progress = trxProductDetail.progress
            let isSeller = trxProductDetail.isSeller(userId)
            if (progress == TransactionDetailTools.ProgressExpired) {
                if (isSeller == true) {
                    lblDesc.text = TransactionDetailTools.TextHubungiBuyerTolak
                } else {
                    lblDesc.text = TransactionDetailTools.TextPembayaranExpiredBuyer
                }
            }
        }
    }
}

// MARK: - Class

class TransactionDetailTitleCell : UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    
    func adapt(title : String) {
        lblTitle.text = title
    }
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
        if (progress == TransactionDetailTools.ProgressExpired) {
            btn.setTitle("PESAN LAGI BARANG YANG SAMA", forState: UIControlState.Normal)
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller) {
            btn.setTitle("HUBUNGI BUYER", forState: UIControlState.Normal)
        }
    }
    
    @IBAction func btnPressed(sender: AnyObject) {
        if (progress == TransactionDetailTools.ProgressExpired) {
            Constant.showDialog("Button pressed", message: "PESAN LAGI BARANG YANG SAMA")
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller) {
            Constant.showDialog("Button pressed", message: "HUBUNGI BUYER")
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

typealias ShowContactPrelo = () -> ()

class TransactionDetailContactPreloCell : UITableViewCell {
    var showContactPrelo : ShowContactPrelo = {}
    
    @IBAction func btnContactPressed(sender: AnyObject) {
        self.showContactPrelo()
    }
}
