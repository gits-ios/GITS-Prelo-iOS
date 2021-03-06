//
//  TransactionDetailViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/11/16.
//  Copyright (c) 2016 PT Kleo Appara Indonesia. All rights reserved.
//
//  I made this as neat as possible, if you find some code structure/algorithm that's not efficient, it's because the bloody changes outta original design
//  Please keep this code neat =)

import Foundation
import Alamofire
import MessageUI

// MARK: - Class

class TransactionDetailViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, FloatRatingViewDelegate {
    
    // Table and loading
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var vwShadow: UIView!
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
    var hideableCell : [Int : Bool?] = [:] // [cell_index : is_hidden]
    var isFroze: [Int : Bool?] = [:] // [cell_index : is_froze]
    var hideProductCell : [Bool] = [] // [is_hidden]
    
    // Cell identifiers
    let TransactionDetailTableCellId = "TransactionDetailTableCell"
    let TransactionDetailDescriptionCellId = "TransactionDetailDescriptionCell"
    let TransactionDetailTitleCellId = "TransactionDetailTitleCell"
    let TransactionDetailButtonCellId = "TransactionDetailButtonCell"
    let TransactionDetailBorderedButtonCellId = "TransactionDetailBorderedButtonCell"
    let TransactionDetailReviewCellId = "TransactionDetailReviewCell"
    let TransactionDetailContactPreloCellId = "TransactionDetailContactPreloCell"
    
    // Titles
    let TitlePembayaran = "PEMBAYARAN"
    let TitlePengiriman = "PENGIRIMAN"
    let TitleReview = "REVIEW"
    let TitleReserved = "RESERVED"
    
    let TitleAffiliate = "TRANSAKSI"
    
    // Contact us view
    var contactUs : UIViewController?
    
    // TolakPesanan pop up
    @IBOutlet weak var vwTolakPesanan: UIView!
    @IBOutlet weak var txtvwAlasanTolak: UITextView!
    @IBOutlet weak var btnTolakBatal: UIButton!
    @IBOutlet weak var btnTolakKirim: UIButton!
    var txtvwTolakGrowHandler : GrowingTextViewHandler!
    @IBOutlet weak var consHeightTxtvwAlasanTolak: NSLayoutConstraint!
    @IBOutlet weak var consTopVwTolakPesanan: NSLayoutConstraint! // centery
    let TxtvwAlasanTolakPlaceholder = "Tulis alasan penolakan pesanan"
    
    // ReviewSeller pop up
    @IBOutlet weak var vwReviewSeller: UIView!
    @IBOutlet weak var lblRvwSellerName: UILabel!
    @IBOutlet weak var lblRvwProductName: UILabel!
    @IBOutlet weak var txtvwReview: UITextView!
    @IBOutlet weak var btnRvwBatal: UIButton!
    @IBOutlet weak var btnRvwKirim: UIButton!
    // disable
    var btnsRvwLove: [UIButton] = []
    @IBOutlet var btnLove1: UIButton!
    @IBOutlet var btnLove2: UIButton!
    @IBOutlet var btnLove3: UIButton!
    @IBOutlet var btnLove4: UIButton!
    @IBOutlet var btnLove5: UIButton!
    var lblsRvwLove: [UILabel] = []
    @IBOutlet var lblLove1: UILabel!
    @IBOutlet var lblLove2: UILabel!
    @IBOutlet var lblLove3: UILabel!
    @IBOutlet var lblLove4: UILabel!
    @IBOutlet var lblLove5: UILabel!
    // new
    @IBOutlet var vwLoveWithListener: UIView!
    var loveValue : Int = 5
    var txtvwReviewGrowHandler : GrowingTextViewHandler!
    @IBOutlet weak var consHeightTxtvwReview: NSLayoutConstraint!
    @IBOutlet weak var consTopVwReviewSeller: NSLayoutConstraint! // centery
    let TxtvwReviewPlaceholder = "Tulis review tentang penjual ini"
    @IBOutlet var lblChkRvwAgreement: UILabel!
    var isRvwAgreed = false
    
    // TundaPengiriman pop up
    @IBOutlet var vwTundaPengiriman: UIView!
    @IBOutlet var consTopVwTundaPengiriman: NSLayoutConstraint! // centery
    @IBOutlet var lblChkTundaAgreement: UILabel!
    var isTundaAgreed = false
    @IBOutlet var btnTundaBatal: UIButton!
    @IBOutlet var btnTundaKirim: UIButton!
    
    // Others
    var isShowBankBRI : Bool = false
    var veritransRedirectUrl : String = ""
    var isRefundable : Bool = false
    
    var floatRatingView: FloatRatingView!
    
    // new popup report trx
    var newPopup: TransactionReportPopup?
    var isReportable: Bool? // nil -> bisa, true -> udah selesai, false -> sedang diproes
    
    // affiliate
    var isAffiliate: Bool = false
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Hide pop up
        self.vwTolakPesanan.isHidden = true
        self.vwReviewSeller.isHidden = true
        self.vwTundaPengiriman.isHidden = true
        
        // Transparent panel
        vwShadow.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        
        // Penanganan kemunculan keyboard // top is centery
        self.an_subscribeKeyboard (animations: { r, t, o in
            if (o) {
                self.consTopVwTolakPesanan.constant = -90
                self.consTopVwReviewSeller.constant = -90
                self.consTopVwTundaPengiriman.constant = -90
            } else {
                self.consTopVwTolakPesanan.constant = 0
                self.consTopVwReviewSeller.constant = 0
                self.consTopVwTundaPengiriman.constant = 0
            }
        }, completion: nil)
        
        // Load content
        getTransactionDetail()
        
        // Screen title
        self.title = productName
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Atur textview tolak
        txtvwAlasanTolak.delegate = self
        txtvwAlasanTolak.text = TxtvwAlasanTolakPlaceholder
        txtvwAlasanTolak.textColor = UIColor.lightGray
        txtvwTolakGrowHandler = GrowingTextViewHandler(textView: txtvwAlasanTolak, withHeightConstraint: consHeightTxtvwAlasanTolak)
        txtvwTolakGrowHandler.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 2)
        
        self.validateTolakPesananFields()
        
        // Atur textview review
        txtvwReview.delegate = self
        txtvwReview.text = TxtvwReviewPlaceholder
        txtvwReview.textColor = UIColor.lightGray
        txtvwReviewGrowHandler = GrowingTextViewHandler(textView: txtvwReview, withHeightConstraint: consHeightTxtvwReview)
        txtvwReviewGrowHandler.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 3)
    }
    
    func getTransactionDetail() {
        self.showLoading()
        
        var req : URLRequestConvertible?
        if (trxId != nil) {
            if (userIsSeller()) {
                req = APITransactionAnggi.getSellerTransaction(id: trxId!)
            } else {
                req = APITransactionAnggi.getBuyerTransaction(id: trxId!)
            }
        } else if (trxProductId != nil) {
            req = APITransactionAnggi.getTransactionProduct(id: trxProductId!)
        }
        
        if (req != nil) {
            let _ = request(req!).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Transaksi")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    
                    if (self.trxId != nil) {
                        self.trxDetail = TransactionDetail.instance(data)
                        self.progress = self.trxDetail?.progress
                        
                        // Update title
                        self.title = "Order ID " + self.trxDetail!.orderId
                        
                        // affiliate
                        if (self.trxDetail?.isAffiliate)! {
                            TransactionDetailTools.setAffiliateName((self.trxDetail?.AffiliateData?.name)!)
                            TransactionDetailTools.setAffiliateConfirmURL((self.trxDetail?.AffiliateData?.confirmPaymentUrl)!)
                            TransactionDetailTools.setAffiliateURL((self.trxDetail?.AffiliateData?.transactionDetailUrl)!)
                            TransactionDetailTools.setAffiliateRefundURL((self.trxDetail?.AffiliateData?.refundTransactionUrl)!)
                            TransactionDetailTools.setAffiliateBankAccount((self.trxDetail?.AffiliateData?.backAccounts)!)
                            self.isAffiliate = true
                        }
                    } else {
                        self.trxProductDetail = TransactionProductDetail.instance(data)
                        self.progress = self.trxProductDetail?.progress
                        
                        // Update title
                        self.title = "Order ID " + self.trxProductDetail!.orderId
                        
                        // init
                        self.isReportable = self.trxProductDetail?.reportable
                        
                        // affiliate
                        if (self.trxProductDetail?.isAffiliate)! {
                            TransactionDetailTools.setAffiliateName((self.trxProductDetail?.AffiliateData?.name)!)
                            TransactionDetailTools.setAffiliateConfirmURL((self.trxProductDetail?.AffiliateData?.confirmPaymentUrl)!)
                            TransactionDetailTools.setAffiliateURL((self.trxProductDetail?.AffiliateData?.transactionDetailUrl)!)
                            TransactionDetailTools.setAffiliateRefundURL((self.trxProductDetail?.AffiliateData?.refundTransactionUrl)!)
                            TransactionDetailTools.setAffiliateBankAccount((self.trxProductDetail?.AffiliateData?.backAccounts)!)
                            self.isAffiliate = true
                        }
                    }
                    
                    // AB test check
                    self.isShowBankBRI = false
                    if let ab = data["ab_test"].array , ab.count > 0 {
                        for i in 0..<ab.count {
                            if (ab[i].stringValue.lowercased() == "bri") {
                                self.isShowBankBRI = true
                            }
                        }
                    }
                    
                    // Veritrans / Kredivo url check
                    if let vrtUrl = data["veritrans_redirect_url"].string {
                        self.veritransRedirectUrl = vrtUrl
                    } else if let kdvUrl = data["kredivo_redirect_url"].string {
                        self.veritransRedirectUrl = kdvUrl
                    }
                    
                    // Refundable check
                    if let r = data["refundable"].bool {
                        self.isRefundable = r
                    }
                    
                    // Mixpanel
//                    let param = [
//                        "ID" : ((self.trxId != nil) ? self.trxId! : ((self.trxProductId != nil) ? self.trxProductId! : "")),
//                        "Progress" : ((self.progress != nil) ? "\(self.progress!)" : "")
//                    ]
//                    Mixpanel.trackPageVisit(PageName.TransactionDetail, otherParam: param)
                    
                    self.setupHideableCell()
                    self.setupHideProductCell()
                    self.setupTable()
                    self.setupPopUpContent()
                    self.hideLoading()
                }
            }
        }
    }
    
    func setupPopUpContent() {
        // Review seller pop up
        // Set btnLoves and lblLoves manually
//        btnsRvwLove.append(self.btnLove1)
//        btnsRvwLove.append(self.btnLove2)
//        btnsRvwLove.append(self.btnLove3)
//        btnsRvwLove.append(self.btnLove4)
//        btnsRvwLove.append(self.btnLove5)
//        lblsRvwLove.append(self.lblLove1)
//        lblsRvwLove.append(self.lblLove2)
//        lblsRvwLove.append(self.lblLove3)
//        lblsRvwLove.append(self.lblLove4)
//        lblsRvwLove.append(self.lblLove5)
        
        // Love floatable
        self.floatRatingView = FloatRatingView(frame: CGRect(x: 0, y: 0, width: 217, height: 37))
        self.floatRatingView.emptyImage = UIImage(named: "ic_love_96px_trp.png")?.withRenderingMode(.alwaysTemplate)
        self.floatRatingView.fullImage = UIImage(named: "ic_love_96px.png")?.withRenderingMode(.alwaysTemplate)
        // Optional params
        self.floatRatingView.delegate = self
        self.floatRatingView.contentMode = UIViewContentMode.scaleAspectFit
        self.floatRatingView.maxRating = 5
        self.floatRatingView.minRating = 1
        self.floatRatingView.rating = Float(loveValue)
        self.floatRatingView.editable = true
        self.floatRatingView.halfRatings = false
        self.floatRatingView.floatRatings = false
        self.floatRatingView.tintColor = Theme.ThemeRed
        
        self.vwLoveWithListener.addSubview(self.floatRatingView )
        
        if (trxProductDetail != nil) {
            self.lblRvwSellerName.text = trxProductDetail!.sellerUsername
            self.lblRvwProductName.text = trxProductDetail!.productName
        }
    }
    
    // Selain diatur di sini, hideable cell juga harus ditentukan saat memanggil createTitleCell(_:)
    func setupHideableCell() {
        hideableCell = [:]
        isFroze = [:]
        if isAffiliate {
            // No hideable cell
        } else {
            if (progress == TransactionDetailTools.ProgressExpired) {
                if (userIsSeller()) {
                    // No hideable cell
                } else {
                    // No hideable cell
                }
            } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
                if (userIsSeller()) {
                    hideableCell[3] = true
                    isFroze[3] = false
                    //hideableCell[6] = true
                    //isFroze[6] = false
                } else {
                    hideableCell[3] = true
                    isFroze[3] = false
                    hideableCell[6] = true
                    isFroze[6] = false
                }
            } else if (progress == TransactionDetailTools.ProgressNotPaid) {
                if (userIsSeller()) {
                    // No hideable cell
                } else {
                    hideableCell[3] = true
                    isFroze[3] = false
                }
            } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
                if (userIsSeller()) {
                    hideableCell[3] = true
                    isFroze[3] = false
                } else {
                    hideableCell[3] = true
                    isFroze[3] = false
                    hideableCell[6] = true
                    isFroze[6] = false
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (userIsSeller()) {
                    hideableCell[3] = true
                    isFroze[3] = false
                    hideableCell[6] = true
                    isFroze[6] = false
                } else {
                    hideableCell[3] = true
                    isFroze[3] = false
                    hideableCell[6] = true
                    isFroze[6] = false
                }
            } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
                if (userIsSeller()) {
                    hideableCell[3] = true
                    isFroze[3] = false
                    hideableCell[6] = true
                    isFroze[6] = false
                    hideableCell[9] = false // force open
                    isFroze[9] = true
                } else {
                    hideableCell[3] = true
                    isFroze[3] = false
                    hideableCell[6] = true
                    isFroze[6] = false
                    hideableCell[9] = false // force open
                    isFroze[9] = true
                }
            } else if (progress == TransactionDetailTools.ProgressReviewed) {
                if (userIsSeller()) {
                    hideableCell[3] = true
                    isFroze[3] = false
                    hideableCell[6] = true
                    isFroze[6] = false
                    hideableCell[9] = false // force open
                    isFroze[9] = false
                } else {
                    hideableCell[3] = true
                    isFroze[3] = false
                    hideableCell[6] = true
                    isFroze[6] = false
                    hideableCell[9] = false // force open
                    isFroze[9] = false
                }
            } else if (progress == TransactionDetailTools.ProgressReserved) {
                hideableCell[3] = true
                isFroze[3] = false
            } else if (progress == TransactionDetailTools.ProgressReserveDone) {
                hideableCell[3] = true
                isFroze[3] = false
            } else if (progress == TransactionDetailTools.ProgressReservationCancelled) {
                // No hideable cell
            } else if (progress == TransactionDetailTools.ProgressFraudDetected) {
                // No hideable cell
            } else if (progress == TransactionDetailTools.ProgressRefundRequested || progress == TransactionDetailTools.ProgressRefundVerified || progress == TransactionDetailTools.ProgressRefundSent || progress == TransactionDetailTools.ProgressRefundSuccess) {
                if (userIsSeller()) {
                    hideableCell[3] = true
                    isFroze[3] = false
                    hideableCell[6] = true
                    isFroze[6] = false
                } else {
                    hideableCell[3] = true
                    isFroze[3] = false
                }
            }
        }
    }
    
    func setupHideProductCell() {
        hideProductCell = []
        if (self.trxDetail != nil) {
            for _ in 0...trxDetail!.transactionProducts.count - 1 {
                hideProductCell.append(true)
            }
        } else {
            hideProductCell.append(true)
        }
    }
    
    // MARK: - TableView delegate functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isAffiliate {
            if progress == TransactionDetailTools.ProgressReviewed {
                return 6
            } else if progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived {
                return 7
            } else  {
                return 5
            }
        } else {
            // Jumlah baris bergantung pada progres transaksi
            if (progress == TransactionDetailTools.ProgressExpired) {
                if (userIsSeller()) {
                    return 3
                } else {
                    return 4
                }
            } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
                if (userIsSeller()) {
                    return 6 // 9 // 6
                } else {
                    return 12 // 9
                }
            } else if (progress == TransactionDetailTools.ProgressNotPaid) {
                if (userIsSeller()) {
                    return 4
                } else {
                    return 7
                }
            } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
                if (userIsSeller()) {
                    return 6
                } else {
                    return 9
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (userIsSeller()) {
                    return 12
                } else {
                    return 10
                }
            } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
                if (userIsSeller()) {
                    return 12 //9 //10
                } else {
                    if (isRefundable) {
                        return 13
                    } else {
                        return 12
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressReviewed) {
                if (userIsSeller()) {
                    return 11
                } else {
                    return 11
                }
            } else if (progress == TransactionDetailTools.ProgressReserved) {
                return 8
            } else if (progress == TransactionDetailTools.ProgressReserveDone) {
                return 6
            } else if (progress == TransactionDetailTools.ProgressReservationCancelled) {
                return 3
            } else if (progress == TransactionDetailTools.ProgressFraudDetected) {
                return 5
            } else if (progress == TransactionDetailTools.ProgressRefundRequested) {
                if (userIsSeller()) {
                    return 10
                } else {
                    return 7
                }
            } else if (progress == TransactionDetailTools.ProgressRefundVerified) {
                if (userIsSeller()) {
                    return 11
                } else {
                    return 9
                }
            } else if (progress == TransactionDetailTools.ProgressRefundSent) {
                if (userIsSeller()) {
                    return 12
                } else {
                    return 8
                }
            } else if (progress == TransactionDetailTools.ProgressRefundSuccess) {
                if (userIsSeller()) {
                    return 10
                } else {
                    return 10
                }
            }
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Urutan index bergantung pada progres transaksi
        let idx = (indexPath as NSIndexPath).row
        let DefaultHeight : CGFloat = 56
        let BorderlessBtnHeight : CGFloat = 30
        let SeparatorHeight : CGFloat = 1
        let ContactPreloHeight : CGFloat = 72
        
        if (hideableCell[idx] != nil) {
            if let hid = hideableCell[idx]! {
                if (hid == true) {
                    return 0
                }
            }
        }
        
        if isAffiliate {
            if progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived {
                if idx == 0 {
                    return TransactionDetailTableCell.heightForProducts(hideProductCell)
                } else if idx == 1 {
                    return DefaultHeight
                } else if idx == 2 {
                    return TransactionDetailDescriptionCell.heightForAffiliate(progress)
                } else if idx == 3 {
                    return DefaultHeight
                } else if idx == 4 {
                    return DefaultHeight
                } else if idx == 5 {
                    return DefaultHeight
                } else if idx == 6 {
                    return ContactPreloHeight
                }
            } else if progress == TransactionDetailTools.ProgressReviewed {
                if idx == 0 {
                    return TransactionDetailTableCell.heightForProducts(hideProductCell)
                } else if idx == 1 {
                    return DefaultHeight
                } else if idx == 2 {
                    return TransactionDetailDescriptionCell.heightForAffiliate(progress)
                } else if idx == 3 {
                    return DefaultHeight
                } else if idx == 4 {
                    return TransactionDetailReviewCell.heightFor(trxProductDetail!.reviewComment)
                } else if idx == 5 {
                    return ContactPreloHeight
                }
            } else  {
                if idx == 0 {
                    return TransactionDetailTableCell.heightForProducts(hideProductCell)
                } else if idx == 1 {
                    return DefaultHeight
                } else if idx == 2 {
                    return TransactionDetailDescriptionCell.heightForAffiliate(progress)
                } else if idx == 3 {
                    return DefaultHeight
                } else if idx == 4 {
                    return ContactPreloHeight
                }
            }
        } else {
            if (progress == TransactionDetailTools.ProgressExpired) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 2) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        return ContactPreloHeight
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                        }
                        // tambahan
                    } /*else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                        }
                        // tambahan
                    }*/ else if (idx == 4) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 5) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                        // tambahan
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                        }
                        // tambahan
                    } else if (idx == 7) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 8) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentReimburse)
                        }
                    } else if (idx == 9) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 2)
                    } else if (idx == 10) {
                        return DefaultHeight
                    } else if (idx == 11) {
                        return ContactPreloHeight
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressNotPaid) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranBuyer)
                        }
                    } else if (idx == 4) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        return ContactPreloHeight
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                        }
                    } else if (idx == 4) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 5) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranBuyer)
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanBuyer)
                        }
                    } else if (idx == 7) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 8) {
                        return ContactPreloHeight
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                        }
                    } else if (idx == 7) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 8) {
                        return DefaultHeight
                    } else if (idx == 9) {
                        return DefaultHeight
                    } else if (idx == 10) {
                        return BorderlessBtnHeight
                    } else if (idx == 11) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanBuyer)
                        }
                    } else if (idx == 7) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 8) {
                        return DefaultHeight
                    } else if (idx == 9) {
                        return ContactPreloHeight
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                        }
                    } else if (idx == 7) {
                        return SeparatorHeight
                    } else if (idx == 8) {
                        return DefaultHeight
                    } else if (idx == 9) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1, boolParam: isRefundable)
                    } else if (idx == 10) {
                        return DefaultHeight // text
                    } else if (idx == 11) {
                        return DefaultHeight // hubungi pembeli
                    } else if (idx == 12) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanBuyer)
                        }
                    } else if (idx == 7) {
                        return SeparatorHeight
                    } else if (idx == 8) {
                        return DefaultHeight
                    } else if (idx == 9) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1, boolParam: isRefundable)
                    } else if (idx == 10) {
                        return DefaultHeight
                    } else if (idx == 11) {
                        if (isRefundable) {
                            return DefaultHeight // Tombol refund
                        } else {
                            return ContactPreloHeight
                        }
                    } else if (idx == 12) {
                        return ContactPreloHeight
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressReviewed) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                        }
                    } else if (idx == 7) {
                        return SeparatorHeight
                    } else if (idx == 8) {
                        return DefaultHeight
                    } else if (idx == 9) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailReviewCell.heightFor(trxProductDetail!.reviewComment)
                        }
                    } else if (idx == 10) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanBuyer)
                        }
                    } else if (idx == 7) {
                        return SeparatorHeight
                    } else if (idx == 8) {
                        return DefaultHeight
                    } else if (idx == 9) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailReviewCell.heightFor(trxProductDetail!.reviewComment)
                        }
                    } else if (idx == 10) {
                        return ContactPreloHeight
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressReserved) {
                if (idx == 0) {
                    return TransactionDetailTableCell.heightForProducts(hideProductCell)
                }  else if (idx == 1) {
                    return SeparatorHeight
                }else if (idx == 2) {
                    return DefaultHeight
                } else if (idx == 3) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 4) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentReserved)
                    }
                } else if (idx == 5) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 2)
                } else if (idx == 6) {
                    return DefaultHeight
                } else if (idx == 7) {
                    return ContactPreloHeight
                }
            } else if (progress == TransactionDetailTools.ProgressReserveDone) {
                if (idx == 0) {
                    return TransactionDetailTableCell.heightForProducts(hideProductCell)
                } else if (idx == 1) {
                    return SeparatorHeight
                } else if (idx == 2) {
                    return DefaultHeight
                } else if (idx == 3) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranReservasi)
                    }
                } else if (idx == 4) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 5) {
                    return ContactPreloHeight
                }
            } else if (progress == TransactionDetailTools.ProgressReservationCancelled) {
                if (idx == 0) {
                    return TransactionDetailTableCell.heightForProducts(hideProductCell)
                } else if (idx == 1) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 2) {
                    return ContactPreloHeight
                }
            } else if (progress == TransactionDetailTools.ProgressFraudDetected) {
                if (idx == 0) {
                    return TransactionDetailTableCell.heightForProducts(hideProductCell)
                } else if (idx == 1) {
                    return SeparatorHeight
                } else if (idx == 2) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 3) {
                    return DefaultHeight
                } else if (idx == 4) {
                    return ContactPreloHeight
                }
            } else if (progress == TransactionDetailTools.ProgressRefundRequested) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                        }
                    } else if (idx == 7) {
                        return SeparatorHeight
                    } else if (idx == 8) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1, addText: trxProductDetail!.refundReasonText)
                        }
                    } else if (idx == 9) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 6) {
                        return ContactPreloHeight
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressRefundVerified) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                        }
                    } else if (idx == 7) {
                        return SeparatorHeight
                    } else if (idx == 8) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 9) {
                        return DefaultHeight
                    } else if (idx == 10) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 6) {
                        return DefaultHeight
                    } else if (idx == 7) {
                        return DefaultHeight
                    } else if (idx == 8) {
                        return ContactPreloHeight
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressRefundSent) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                        }
                    } else if (idx == 7) {
                        return SeparatorHeight
                    } else if (idx == 8) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 9) {
                        return DefaultHeight
                    } else if (idx == 10) {
                        return DefaultHeight
                    } else if (idx == 11) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 6) {
                        return DefaultHeight
                    } else if (idx == 7) {
                        return ContactPreloHeight
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressRefundSuccess) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return DefaultHeight
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                        }
                    } else if (idx == 7) {
                        return SeparatorHeight
                    } else if (idx == 8) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 9) {
                        return ContactPreloHeight
                    }
                } else {
                    if (idx == 0) {
                        return TransactionDetailTableCell.heightForProducts(hideProductCell)
                    } else if (idx == 1) {
                        return SeparatorHeight
                    } else if (idx == 2) {
                        return DefaultHeight
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return SeparatorHeight
                    } else if (idx == 5) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                    } else if (idx == 6) {
                        if (trxProductDetail != nil) {
                            return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentReimburse)
                        }
                    } else if (idx == 7) {
                        return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 2)
                    } else if (idx == 8) {
                        return DefaultHeight
                    } else if (idx == 9) {
                        return ContactPreloHeight
                    }
                }
            }
            return 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Urutan index bergantung pada progres transaksi
        let idx = (indexPath as NSIndexPath).row
        
        if isAffiliate {
            if progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived {
                if idx == 0 {
                    return self.createTableProductsCell()
                } else if idx == 1 {
                    return self.createAffiliateTitleCell(TitleAffiliate)
                } else if idx == 2 {
                    return self.createDescriptionCell(1)
                } else if idx == 3 {
                    return self.createButtonCell(1)
                } else if idx == 4 {
                    return self.createBorderedButtonCell(2) // order 1 always refund
                } else if idx == 5 {
                    return self.createBorderedButtonCell(1)
                } else if idx == 6 {
                    return self.createContactPreloCell()
                }
            } else if progress == TransactionDetailTools.ProgressReviewed {
                if idx == 0 {
                    return self.createTableProductsCell()
                } else if idx == 1 {
                    return self.createAffiliateTitleCell(TitleAffiliate)
                } else if idx == 2 {
                    return self.createDescriptionCell(1)
                } else if idx == 3 {
                    return self.createAffiliateTitleCell(TitleReview)
                } else if idx == 4 {
                    return self.createReviewCell()
                } else if idx == 5 {
                    return self.createContactPreloCell()
                }
            } else  {
                if idx == 0 {
                    return self.createTableProductsCell()
                } else if idx == 1 {
                    return self.createAffiliateTitleCell(TitleAffiliate)
                } else if idx == 2 {
                    return self.createDescriptionCell(1)
                } else if idx == 3 {
                    return self.createButtonCell(1)
                } else if idx == 4 {
                    return self.createContactPreloCell()
                }
            }
        } else {
        
            if (progress == TransactionDetailTools.ProgressExpired) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 2) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 2) {
                        //return self.createBorderedButtonCell(1)
                        return self.createButtonCell(1)
                    } else if (idx == 3) {
                        return self.createContactPreloCell()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                        // tambahan
                    } /*else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                        // tambahan
                    }*/ else if (idx == 4) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 5) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return self.createTableTitleContentsCell(self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                        // tambahan
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                        // tambahan
                    } else if (idx == 7) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 8) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentReimburse)
                    } else if (idx == 9) {
                        return self.createDescriptionCell(2)
                    } else if (idx == 10) {
                        return self.createButtonCell(1)
                    } else if (idx == 11) {
                        return self.createContactPreloCell()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressNotPaid) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 2) {
                        return self.createBorderedButtonCell(1)
                    } else if (idx == 3) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranBuyer)
                    } else if (idx == 4) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 5) {
                        return self.createButtonCell(1)
                    } else if (idx == 6) {
                        return self.createContactPreloCell()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                    } else if (idx == 4) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 5) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranBuyer)
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanBuyer)
                    } else if (idx == 7) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 8) {
                        return self.createContactPreloCell()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                    } else if (idx == 7) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 8) {
                        return self.createButtonCell(1)
                    } else if (idx == 9) {
                        return self.createBorderedButtonCell(1)
                    } else if (idx == 10) {
                        return self.createBorderedButtonCell(2)
                    } else if (idx == 11) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return self.createTableTitleContentsCell(self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanBuyer)
                    } else if (idx == 7) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 8) {
                        return self.createBorderedButtonCell(1)
                    } else if (idx == 9) {
                        return self.createContactPreloCell()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                    } else if (idx == 7) {
                        return self.createSeparatorCell()
                    } else if (idx == 8) {
                        return self.createTitleCell(TitleReview, detailCellIndexes: [9])
                    } else if (idx == 9) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 10) {
                        return self.createBorderedButtonCell(1)
                    } else if (idx == 11) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return self.createTableTitleContentsCell(self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanBuyer)
                    } else if (idx == 7) {
                        return self.createSeparatorCell()
                    } else if (idx == 8) {
                        return self.createTitleCell(TitleReview, detailCellIndexes: [9])
                    } else if (idx == 9) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 10) {
                        return self.createButtonCell(1)
                    } else if (idx == 11) {
                        if (isRefundable) {
                            return self.createBorderedButtonCell(1)
                        } else {
                            return self.createContactPreloCell()
                        }
                    } else if (idx == 12) {
                        return self.createContactPreloCell()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressReviewed) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                    } else if (idx == 7) {
                        return self.createSeparatorCell()
                    } else if (idx == 8) {
                        return self.createTitleCell(TitleReview, detailCellIndexes: [9])
                    } else if (idx == 9) {
                        return self.createReviewCell()
                    } else if (idx == 10) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return self.createTableTitleContentsCell(self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanBuyer)
                    } else if (idx == 7) {
                        return self.createSeparatorCell()
                    } else if (idx == 8) {
                        return self.createTitleCell(TitleReview, detailCellIndexes: [9])
                    } else if (idx == 9) {
                        return self.createReviewCell()
                    } else if (idx == 10) {
                        return self.createContactPreloCell()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressReserved) {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createSeparatorCell()
                } else if (idx == 2) {
                    return self.createTitleCell(TitleReserved, detailCellIndexes: [3])
                } else if (idx == 3) {
                    return self.createDescriptionCell(1)
                } else if (idx == 4) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentReserved)
                } else if (idx == 5) {
                    return self.createDescriptionCell(2)
                } else if (idx == 6) {
                    return self.createBorderedButtonCell(1)
                } else if (idx == 7) {
                    return self.createContactPreloCell()
                }
            } else if (progress == TransactionDetailTools.ProgressReserveDone) {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createSeparatorCell()
                } else if (idx == 2) {
                    return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                } else if (idx == 3) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranReservasi)
                } else if (idx == 4) {
                    return self.createDescriptionCell(1)
                } else if (idx == 5) {
                    return self.createContactPreloCell()
                }
            } else if (progress == TransactionDetailTools.ProgressReservationCancelled) {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createDescriptionCell(1)
                } else if (idx == 2) {
                    return self.createContactPreloCell()
                }
            } else if (progress == TransactionDetailTools.ProgressFraudDetected) {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createSeparatorCell()
                } else if (idx == 2) {
                    return self.createDescriptionCell(1)
                } else if (idx == 3) {
                    return self.createButtonCell(1)
                } else if (idx == 4) {
                    return self.createContactPreloCell()
                }
            } else if (progress == TransactionDetailTools.ProgressRefundRequested) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                    } else if (idx == 7) {
                        return self.createSeparatorCell()
                    } else if (idx == 8) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 9) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return self.createTableTitleContentsCell(self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 6) {
                        return self.createContactPreloCell()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressRefundVerified) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                    } else if (idx == 7) {
                        return self.createSeparatorCell()
                    } else if (idx == 8) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 9) {
                        return self.createBorderedButtonCell(1)
                    } else if (idx == 10) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return self.createTableTitleContentsCell(self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 6) {
                        return self.createButtonCell(1)
                    } else if (idx == 7) {
                        return self.createBorderedButtonCell(1)
                    } else if (idx == 8) {
                        return self.createContactPreloCell()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressRefundSent) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                    } else if (idx == 7) {
                        return self.createSeparatorCell()
                    } else if (idx == 8) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 9) {
                        return self.createButtonCell(1)
                    } else if (idx == 10) {
                        return self.createBorderedButtonCell(1)
                    } else if (idx == 11) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return self.createTableTitleContentsCell(self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 6) {
                        return self.createBorderedButtonCell(1)
                    } else if (idx == 7) {
                        return self.createContactPreloCell()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressRefundSuccess) {
                if (userIsSeller()) {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createTitleCell(TitlePengiriman, detailCellIndexes: [6])
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                    } else if (idx == 7) {
                        return self.createSeparatorCell()
                    } else if (idx == 8) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 9) {
                        return self.createContactPreloCell()
                    }
                } else {
                    if (idx == 0) {
                        return self.createTableProductsCell()
                    } else if (idx == 1) {
                        return self.createSeparatorCell()
                    } else if (idx == 2) {
                        return self.createTitleCell(TitlePembayaran, detailCellIndexes: [3])
                    } else if (idx == 3) {
                        if (trxProductDetail != nil) {
                            return self.createTableTitleContentsCell(self.getTitleContentPembayaranBuyerPaidType(trxProductDetail!))
                        }
                    } else if (idx == 4) {
                        return self.createSeparatorCell()
                    } else if (idx == 5) {
                        return self.createDescriptionCell(1)
                    } else if (idx == 6) {
                        return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentReimburse)
                    } else if (idx == 7) {
                        return self.createDescriptionCell(2)
                    } else if (idx == 8) {
                        return self.createButtonCell(1)
                    } else if (idx == 9) {
                        return self.createContactPreloCell()
                    }
                }
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Do nothing
    }
    
    // MARK: - Cell creation
    
    func createTableProductsCell() -> TransactionDetailTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailTableCellId) as! TransactionDetailTableCell
        
        // Adapt cell
        if (self.progress == TransactionDetailTools.ProgressExpired || self.progress == TransactionDetailTools.ProgressNotPaid || self.progress == TransactionDetailTools.ProgressClaimedPaid || self.progress == TransactionDetailTools.ProgressFraudDetected) {
            if (trxDetail != nil) {
                cell.adaptTableProducts(trxDetail!.transactionProducts, hideProductCell: hideProductCell)
            }
        } else if (self.progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (userIsSeller()) {
                if (trxDetail != nil) {
                    cell.adaptTableProducts(trxDetail!.transactionProducts, hideProductCell: hideProductCell)
                }
            } else {
                if (trxProductDetail != nil) {
                    cell.adaptTableProducts([trxProductDetail!], hideProductCell: hideProductCell)
                }
            }
        } else {
            if (trxProductDetail != nil) {
                cell.adaptTableProducts([trxProductDetail!], hideProductCell: hideProductCell)
            }
        }
        cell.toProductDetail = { productId in
            self.showLoading()
            let _ = request(APIProduct.detail(productId: productId, forEdit: 0)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Barang")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    let p = Product.instance(data)
                    let productDetailVC = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                    productDetailVC.product = p!
                    productDetailVC.previousScreen = PageName.TransactionDetail
                    self.navigationController?.pushViewController(productDetailVC, animated: true)
                }
                self.hideLoading()
            }
        }
        cell.switchDetailProduct = { idx in
            self.hideProductCell[idx] = !self.hideProductCell[idx]
            self.tableView.reloadData()
        }
        
        return cell
    }
    
    func createTableTitleContentsCell(_ titleContentType : String) -> TransactionDetailTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailTableCellId) as! TransactionDetailTableCell
        
        cell.root = self
        
        // Adapt cell
        if (self.progress == TransactionDetailTools.ProgressExpired || self.progress == TransactionDetailTools.ProgressNotPaid || self.progress == TransactionDetailTools.ProgressClaimedPaid || self.progress == TransactionDetailTools.ProgressFraudDetected) {
            if (trxDetail != nil) {
                cell.adaptTableTitleContents(trxDetail!, titleContentType: titleContentType)
            }
        } else if (self.progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (userIsSeller()) {
                if (trxDetail != nil) {
                    cell.adaptTableTitleContents(trxDetail!, titleContentType: titleContentType)
                }
            } else {
                if (trxProductDetail != nil) {
                    cell.adaptTableTitleContents2(trxProductDetail!, titleContentType: titleContentType)
                }
            }
        } else {
            if (trxProductDetail != nil) {
                cell.adaptTableTitleContents2(trxProductDetail!, titleContentType: titleContentType)
            }
        }
        
        return cell
    }
    
    func createDescriptionCell(_ order : Int) -> TransactionDetailDescriptionCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailDescriptionCellId) as! TransactionDetailDescriptionCell
        
        // Adapt cell
        if isAffiliate {
            var progress = 0
            if trxDetail != nil {
                progress = trxDetail!.progress
            } else {
                progress = trxProductDetail!.progress
            }
            cell.adaptAffiliate(progress)
        } else {
            if (self.progress == TransactionDetailTools.ProgressExpired || self.progress == TransactionDetailTools.ProgressNotPaid || self.progress == TransactionDetailTools.ProgressClaimedPaid || self.progress == TransactionDetailTools.ProgressFraudDetected) {
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
                        cell.adapt2(trxProductDetail!, order: order)
                    }
                }
            } else {
                if (trxProductDetail != nil) {
                    cell.adapt2(trxProductDetail!, order: order)
                }
            }
        }
        return cell
    }
    
    func createTitleCell(_ title : String, detailCellIndexes : [Int]) -> TransactionDetailTitleCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailTitleCellId) as! TransactionDetailTitleCell
        
        let isOpen = self.hideableCell[detailCellIndexes[0]] ?? false
        let isFroze = self.isFroze[detailCellIndexes[0]] ?? false
        
        // Adapt cell
        cell.adapt(title, detailCellIndexes: detailCellIndexes, isOpen: isOpen!, isFroze: isFroze!)
        
        // Configure actions
        cell.switchDetail = {
            for i in detailCellIndexes {
                if (self.hideableCell[i] != nil) {
                    if let hid = self.hideableCell[i]! {
                        self.hideableCell[i] = !hid
                    }
                }
            }
            self.tableView.reloadData()
        }
        
        return cell
    }
    
    func createAffiliateTitleCell(_ title : String) -> TransactionDetailTitleCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailTitleCellId) as! TransactionDetailTitleCell
        
        // Adapt cell
        cell.adaptAffiliate(title)
        
        return cell
    }
    
    func createButtonCell(_ order : Int) -> TransactionDetailButtonCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailButtonCellId) as! TransactionDetailButtonCell
        
        // Veritrans payment check
        if (veritransRedirectUrl != "") {
            cell.isVeritransPayment = true
        }
        
        // Adapt cell
        if isAffiliate {
            cell.adaptAffiliate(TransactionDetailTools.AffiliateName, progress: self.progress!)
        } else {
            if (progress != nil) {
                cell.adapt(self.progress, order: order)
            }
            
            if self.isReportable == false {
                cell.btn.setTitle("BATALKAN LAPORAN", for: UIControlState.normal)
            }
        }
        
        // Configure actions
        cell.retrieveCash = {
//            let t = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdTarikTunai) as! TarikTunaiController
//            self.navigationController?.pushViewController(t, animated: true)
            
            let t = Bundle.main.loadNibNamed(Tags.XibNameTarikTunai2, owner: nil, options: nil)?.first as! TarikTunaiViewController2
            t.previousScreen = PageName.TransactionDetail
            self.navigationController?.pushViewController(t, animated: true)
        }
        cell.confirmPayment = {
            if (self.trxDetail != nil) {
                var imgs : [URL] = []
                let tProducts = self.trxDetail!.transactionProducts
                for i in 0...(tProducts.count - 1) {
                    let tProduct : TransactionProductDetail = tProducts[i]
                    if let url = tProduct.productImageURL {
                        imgs.append(url as URL)
                    }
                }
                let orderConfirmVC = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
                orderConfirmVC.transactionId = self.trxDetail!.id
                orderConfirmVC.orderID = self.trxDetail!.orderId
                orderConfirmVC.total = self.trxDetail!.totalPrice + self.trxDetail!.bankTransferDigit
                orderConfirmVC.images = imgs
                orderConfirmVC.isFromCheckout = false
                orderConfirmVC.isBackToRoot = false
                orderConfirmVC.isShowBankBRI = self.isShowBankBRI
                orderConfirmVC.date = self.trxDetail!.expireTime
                orderConfirmVC.targetBank = self.trxDetail!.paymentBankTarget
                orderConfirmVC.remaining = self.trxDetail!.remainingTime
                orderConfirmVC.previousScreen = PageName.TransactionDetail
                self.navigationController?.pushViewController(orderConfirmVC, animated: true)
            }
        }
        cell.continuePayment = {
            let webVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
            webVC.url = self.veritransRedirectUrl
            webVC.titleString = "Lanjut Pembayaran"
            webVC.creditCardMode = true
            webVC.ccPaymentSucceed = {
                let o = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
                
                o.orderID = self.trxDetail!.orderId
                o.total = 0
                o.transactionId = self.trxDetail!.id
                o.isBackTwice = true
                o.isShowBankBRI = self.isShowBankBRI
                o.date = self.trxDetail!.expireTime
                o.remaining = self.trxDetail!.remainingTime
                var imgs : [URL] = []
                for i in 0..<self.trxDetail!.transactionProducts.count {
                    if let u = self.trxDetail!.transactionProducts[i].productImageURL {
                        imgs.append(u)
                    }
                }
                o.images = imgs
                o.isFromCheckout = false
                self.navigationController?.pushViewController(o, animated: true)
            }
            webVC.ccPaymentUnfinished = {
                // Do nothing
            }
            webVC.ccPaymentFailed = {
                Constant.showDialog("Lanjut Pembayaran", message: "Pembayaran gagal, silahkan coba beberapa saat lagi")
            }
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([webVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        }
        cell.confirmShipping = {
            if (self.trxDetail != nil) {
                let confirmShippingVC = Bundle.main.loadNibNamed(Tags.XibNameConfirmShipping, owner: nil, options: nil)?.first as! ConfirmShippingViewController
                confirmShippingVC.trxDetail = self.trxDetail!
                confirmShippingVC.setDefaultKurir()
                confirmShippingVC.previousScreen = PageName.TransactionDetail
                self.navigationController?.pushViewController(confirmShippingVC, animated: true)
            }
        }
        cell.reviewSeller = {
            if self.isReportable == false {
                //Constant.showDialog("BATALKAN LAPORAN", message: "test")
                
                let alertView = SCLAlertView(appearance: Constant.appearance)
                alertView.addButton("Batalkan Laporan") {
                    let _ = request(APITransactionProduct.cancelReport(tpId: self.trxProductId!)).responseJSON { resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Pembatalan Laporan")) {
                            let json = JSON(resp.result.value!)
                            let data = json["_data"]
                            if let isHold = data["is_hold"].bool {
                                if !isHold {
                                    Constant.showDialog("Pembatalan Laporan", message: "Laporan berhasil dibatalkan")
                                    self.isReportable = true // ga bisa report -> report selesai
                                    self.tableView.reloadData()
                                } else {
                                    Constant.showDialog("Pembatalan Laporan", message: "Laporan gagal dibatalkan")
                                }
                            } else { // isHold nya null
                                Constant.showDialog("Pembatalan Laporan", message: "Laporan berhasil dibatalkan")
                                self.isReportable = nil // bisa report lagi
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
                alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
                alertView.showCustom("Pembatalan Laporan", subTitle: "Batalkan laporan transaksi ini jika kamu sudah menerima barang. Jangan lupa review penjual.", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                
            } else {
                self.vwShadow.isHidden = false
                self.vwReviewSeller.isHidden = false
            }
        }
        cell.seeFAQ = {
            let helpVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
            helpVC.url = "https://prelo.co.id/faq?ref=preloapp#tidak-lolos"
            helpVC.titleString = "FAQ"
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([helpVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        }
        cell.confirmReturnShipping = {
            let confirmShippingVC = Bundle.main.loadNibNamed(Tags.XibNameConfirmShipping, owner: nil, options: nil)?.first as! ConfirmShippingViewController
            confirmShippingVC.isRefundMode = true
            confirmShippingVC.tpId = self.trxProductId!
            confirmShippingVC.setDefaultKurir()
            confirmShippingVC.previousScreen = PageName.TransactionDetail
            self.navigationController?.pushViewController(confirmShippingVC, animated: true)
        }
        cell.confirmReturned = {
            /*
            let alert : UIAlertController = UIAlertController(title: "Perhatian", message: "Dengan melakukan konfirmasi penerimaan, artinya kamu sudah menerima kembali barang refund. Uang akan dikembalikan kepada pembeli. Lanjutkan?", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Lanjutkan", style: .default, handler: { action in
                _ = request(APITransactionProduct.confirmReceiveRefundedProduct(tpId: self.trxProductId!)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Konfirmasi Penerimaan")) {
                        let json = JSON(resp.result.value!)
                        let data = json["_data"].boolValue
                        if (data == true) {
                            Constant.showDialog("Konfirmasi Penerimaan", message: "Konfirmasi Penerimaan telah berhasil dilakukan")
                            _ = self.navigationController?.popViewController(animated: true)
                        } else {
                            Constant.showDialog("Konfirmasi Penerimaan", message: "Konfirmasi Penerimaan telah berhasil dilakukan")
                        }
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
             */
            
            let alertView = SCLAlertView(appearance: Constant.appearance)
            alertView.addButton("Lanjutkan") {
                _ = request(APITransactionProduct.confirmReceiveRefundedProduct(tpId: self.trxProductId!)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Konfirmasi Penerimaan")) {
                        let json = JSON(resp.result.value!)
                        let data = json["_data"].boolValue
                        if (data == true) {
                            Constant.showDialog("Konfirmasi Penerimaan", message: "Konfirmasi Penerimaan telah berhasil dilakukan")
                            _ = self.navigationController?.popViewController(animated: true)
                        } else {
                            Constant.showDialog("Konfirmasi Penerimaan", message: "Konfirmasi Penerimaan telah berhasil dilakukan")
                        }
                    }
                }
            }
            alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
            alertView.showCustom("Perhatian", subTitle: "Dengan melakukan konfirmasi penerimaan, artinya kamu sudah menerima kembali barang refund. Uang akan dikembalikan kepada pembeli. Lanjutkan?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
        }
        // Configure actions
        cell.orderAgain = {
            if (self.trxDetail != nil) {
                var success = true
                let tProducts = self.trxDetail!.transactionProducts
                for i in 0...(tProducts.count - 1) {
                    let tProduct : TransactionProductDetail = tProducts[i]
                    
                    if AppTools.isNewCart { // v2
                        if CartManager.sharedInstance.insertProduct(tProduct.sellerId, productId: tProduct.productId) {
                            
                            // FB Analytics - Add to Cart
                            if AppTools.IsPreloProduction {
                                let fbPdata: [String : Any] = [
                                    FBSDKAppEventParameterNameContentType          : "product",
                                    FBSDKAppEventParameterNameContentID            : tProduct.productId,
                                    FBSDKAppEventParameterNameCurrency             : "IDR"
                                ]
                                FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToCart, valueToSum: Double(tProduct.productPrice), parameters: fbPdata)
                            }
                        } else {
                            success = false
                        }
                    } else { // v1
                        
                        if (!CartProduct.isExist(tProduct.productId, email: User.EmailOrEmptyString)) {
                            if (CartProduct.newOne(tProduct.productId, email: User.EmailOrEmptyString, name: tProduct.productName) == nil) {
                                success = false
                            }else {
                                // FB Analytics - Add to Cart
                                if AppTools.IsPreloProduction {
                                    let fbPdata: [String : Any] = [
                                        FBSDKAppEventParameterNameContentType          : "product",
                                        FBSDKAppEventParameterNameContentID            : tProduct.productId,
                                        FBSDKAppEventParameterNameCurrency             : "IDR"
                                    ]
                                    FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToCart, valueToSum: Double(tProduct.productPrice), parameters: fbPdata)
                                }
                            }
                        }
                    }
                }
                if (!success && !AppTools.isNewCart) {
                    Constant.showDialog("Add to Cart", message: "Terdapat kesalahan saat menambahkan barang ke keranjang belanja")
                }
                if AppTools.isNewCart {
                    if AppTools.isSingleCart {
                        let checkout2VC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2, owner: nil, options: nil)?.first as! Checkout2ViewController
                        checkout2VC.previousController = self
                        checkout2VC.previousScreen = PageName.TransactionDetail
                        self.navigationController?.pushViewController(checkout2VC, animated: true)
                    } else {
                        let checkout2ShipVC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2Ship, owner: nil, options: nil)?.first as! Checkout2ShipViewController
                        checkout2ShipVC.previousController = self
                        checkout2ShipVC.previousScreen = PageName.TransactionDetail
                        self.navigationController?.pushViewController(checkout2ShipVC, animated: true)
                    }
                } else {
                    //self.performSegue(withIdentifier: "segCart", sender: nil)
                    let cart = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdCart) as! CartViewController
                    cart.previousController = self
                    cart.previousScreen = PageName.TransactionDetail
                    self.navigationController?.pushViewController(cart, animated: true)
                }
            }
        }
        cell.seeAffiliate = {
            let webVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
            webVC.url = TransactionDetailTools.AffiliateURL
            webVC.titleString = TransactionDetailTools.AffiliateName
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([webVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        }
        cell.confirmPaymentAffiliate = {
            let webVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
            webVC.url = TransactionDetailTools.AffiliateConfirmURL
            webVC.titleString = TransactionDetailTools.AffiliateName
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([webVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        }
        cell.orderAgainAffiliate = {
            self.showLoading()
            
            var productId = ""
            if self.trxDetail != nil {
                productId = (self.trxDetail?.transactionProducts[0].productId)!
            } else if self.trxProductDetail != nil {
                productId = (self.trxProductDetail?.productId)!
            }
            
            let _ = request(APIProduct.detail(productId: productId, forEdit: 0)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Barang")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    let p = Product.instance(data)
                    let productDetailVC = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                    productDetailVC.product = p!
                    productDetailVC.previousScreen = PageName.TransactionDetail
                    self.navigationController?.pushViewController(productDetailVC, animated: true)
                }
                self.hideLoading()
            }
        }
        
        return cell
    }
    
    func createBorderedButtonCell(_ order : Int) -> TransactionDetailBorderedButtonCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailBorderedButtonCellId) as! TransactionDetailBorderedButtonCell
        
        // Adapt cell
        if isAffiliate {
            cell.adaptAffiliate(TransactionDetailTools.AffiliateName, order: order)
        } else {
            if (progress != nil) {
                cell.adapt(self.progress, isSeller: isSeller, order: order)
            }
        }
        
//        // Configure actions
//        cell.orderAgain = {
//            if (self.trxDetail != nil) {
//                var success = true
//                let tProducts = self.trxDetail!.transactionProducts
//                for i in 0...(tProducts.count - 1) {
//                    let tProduct : TransactionProductDetail = tProducts[i]
//                    if (!CartProduct.isExist(tProduct.productId, email: User.EmailOrEmptyString)) {
//                        if (CartProduct.newOne(tProduct.productId, email: User.EmailOrEmptyString, name: tProduct.productName) == nil) {
//                            success = false
//                        }
//                    }
//                }
//                if (!success) {
//                    Constant.showDialog("Add to Cart", message: "Terdapat kesalahan saat menambahkan barang ke keranjang belanja")
//                }
//                self.performSegue(withIdentifier: "segCart", sender: nil)
//            }
//        }
        cell.rejectTransaction = {
            self.vwShadow.isHidden = false
            self.vwTolakPesanan.isHidden = false
        }
        cell.contactBuyer = {
            self.showLoading()
            
            var productId = ""
            var buyerId = ""
            if (self.trxDetail != nil) {
                productId = self.trxDetail!.transactionProducts[0].productId
                buyerId = self.trxDetail!.transactionProducts[0].buyerId
            } else if (self.trxProductDetail != nil) {
                productId = self.trxProductDetail!.productId
                buyerId = self.trxProductDetail!.buyerId
            }
            // Get product detail from API
            let _ = request(APIProduct.detail(productId: productId, forEdit: 0)).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hubungi Pembeli")) {
                    let json = JSON(resp.result.value!)
                    if let pDetail = ProductDetail.instance(json) {
                    
                        // Goto chat
                        let t = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdTawar) as! TawarViewController
                        t.previousScreen = PageName.TransactionDetail
                        
                        t.isSellerNotActive = pDetail.IsShopClosed
                        t.phoneNumber = pDetail.SellerPhone
                    
                        // API Migrasi
                        let _ = request(APIInbox.getInboxByProductIDSeller(productId: pDetail.productID, buyerId: buyerId)).responseJSON {resp in
                            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hubungi Pembeli")) {
                                let json = JSON(resp.result.value!)
                                if (json["_data"]["_id"].stringValue != "") { // Sudah pernah chat
                                    t.tawarItem = Inbox(jsn: json["_data"])
                                    self.navigationController?.pushViewController(t, animated: true)
                                } else { // Belum pernah chat
                                    var j : JSON?
                                    if (self.trxDetail != nil) {
                                        j = self.trxDetail!.transactionProducts[0].json["review"]
                                    } else if (self.trxProductDetail != nil) {
                                        j = self.trxProductDetail!.json["review"]
                                    }
                                    if (j != nil) {
                                        pDetail.buyerId = j!["buyer_id"].stringValue
                                        pDetail.buyerName = j!["buyer_fullname"].stringValue
                                        pDetail.buyerImage = j!["buyer_pict"].stringValue
                                        pDetail.reverse()
                                        
                                        t.tawarItem = pDetail
                                        t.fromSeller = true
                                        
                                        t.toId = j!["buyer_id"].stringValue
                                        t.prodId = t.tawarItem.itemId
                                        self.navigationController?.pushViewController(t, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
                self.hideLoading()
            }
        }
        cell.contactSeller = {
            self.showLoading()
            
            // Get product detail from API
            var productId = ""
            if (self.trxDetail != nil) {
                productId = self.trxDetail!.transactionProducts[0].productId
            } else if (self.trxProductDetail != nil) {
                productId = self.trxProductDetail!.productId
            }
            let _ = request(APIProduct.detail(productId: productId, forEdit: 0)).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hubungi Pembeli")) {
                    let json = JSON(resp.result.value!)
                    if let pDetail = ProductDetail.instance(json) {
                        
                        // Goto chat
                        let t = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdTawar) as! TawarViewController
                        t.tawarItem = pDetail
                        t.loadInboxFirst = true
                        t.prodId = pDetail.productID
                        t.previousScreen = PageName.TransactionDetail
                        t.isSellerNotActive = pDetail.IsShopClosed
                        t.phoneNumber = pDetail.SellerPhone
                        self.navigationController?.pushViewController(t, animated: true)
                    }
                }
                self.hideLoading()
            }
        }
        cell.cancelReservation = {
            cell.btn.setTitle("LOADING...", for: UIControlState())
            cell.btn.isUserInteractionEnabled = false
            var isSuccess = false
            var productId = ""
            if (self.trxProductDetail != nil) {
                productId = self.trxProductDetail!.productId
            }
            // API Migrasi
            let _ = request(APIGarageSale.cancelReservation(productId: productId)).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Cancel Reservation")) {
                    let json = JSON(resp.result.value!)
                    if let success = json["_data"].bool {
                        if (success) {
                            isSuccess = true
                            
                            // Reload content
                            self.getTransactionDetail()
                        }
                    }
                }
                if (!isSuccess) {
                    cell.btn.setTitle(cell.TitleBatalkanReservasi, for: UIControlState())
                    cell.btn.isUserInteractionEnabled = true
                }
            }
        }
        cell.delayShipping = {
            self.vwShadow.isHidden = false
            self.vwTundaPengiriman.isHidden = false
        }
        cell.initRefund = {
            /*
            let refundReqVC = Bundle.main.loadNibNamed(Tags.XibNameRequestRefund, owner: nil, options: nil)?.first as! RefundRequestViewController
            if (self.trxProductId != nil) {
                refundReqVC.tpId = self.trxProductId!
                refundReqVC.pId = (self.trxProductDetail?.productId)!
            }
            refundReqVC.previousScreen = PageName.TransactionDetail
            self.navigationController?.pushViewController(refundReqVC, animated: true)
             */
            
            // new popup -> report & refund
            self.launchNewPopUp()
        }
        cell.seeAffiliate = {
            let webVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
            webVC.url = TransactionDetailTools.AffiliateURL
            webVC.titleString = TransactionDetailTools.AffiliateName
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([webVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        }
        cell.refundAffiliate = { // refund
            let webVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
            webVC.url = TransactionDetailTools.AffiliateRefundURL
            webVC.titleString = TransactionDetailTools.AffiliateName
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([webVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        }
        
        return cell
    }
    
    func createReviewCell() -> TransactionDetailReviewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailReviewCellId) as! TransactionDetailReviewCell
        
        // Adapt cell
        if (trxProductDetail != nil) {
            cell.adapt(trxProductDetail!)
        }
        
        return cell
    }
    
    func createContactPreloCell() -> TransactionDetailContactPreloCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailContactPreloCellId) as! TransactionDetailContactPreloCell
        
        // Adapt cell
        cell.lblKeterangan.isHidden = true // Not used
        cell.consTopLblContact.constant = 8 // Set to 48 if lblKeterangan is used
        cell.showContactPrelo = {
            let helpVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
            helpVC.url = "https://prelo.co.id/faq?ref=preloapp"
            helpVC.titleString = "Bantuan"
            helpVC.contactPreloMode = true
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([helpVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        }
        
        return cell
    }
    
    func createSeparatorCell() -> UITableViewCell {
        let cell = UITableViewCell(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1))
        cell.backgroundColor = UIColor(hexString: "#E8E8E8")
        return cell
    }
    
    // MARK: - UITextViewDelegate Functions
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView == txtvwAlasanTolak) {
            if (txtvwAlasanTolak.textColor == UIColor.lightGray) {
                txtvwAlasanTolak.text = ""
                txtvwAlasanTolak.textColor = Theme.GrayDark
            }
        } else if (textView == txtvwReview) {
            if (txtvwReview.textColor == UIColor.lightGray) {
                txtvwReview.text = ""
                txtvwReview.textColor = Theme.GrayDark
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if (textView == txtvwAlasanTolak) {
            txtvwTolakGrowHandler.resizeTextView(withAnimation: true)
            self.validateTolakPesananFields()
        } else if (textView == txtvwReview) {
            txtvwReviewGrowHandler.resizeTextView(withAnimation: true)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView == txtvwAlasanTolak) {
            if (txtvwAlasanTolak.text.isEmpty) {
                txtvwAlasanTolak.text = TxtvwAlasanTolakPlaceholder
                txtvwAlasanTolak.textColor = UIColor.lightGray
            }
        } else if (textView == txtvwReview) {
            if (txtvwReview.text.isEmpty) {
                txtvwReview.text = TxtvwReviewPlaceholder
                txtvwReview.textColor = UIColor.lightGray
            }
        }
    }
    
    // MARK: - GestureRecognizer Functions
    
    @IBAction func disableTextFields(_ sender : AnyObject) {
        txtvwAlasanTolak.resignFirstResponder()
        txtvwReview.resignFirstResponder()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - Tolak Pesanan Pop Up
    
    func validateTolakPesananFields() {
        if (txtvwAlasanTolak.text.isEmpty || txtvwAlasanTolak.text == self.TxtvwAlasanTolakPlaceholder) {
            // Disable tombol kirim
            btnTolakKirim.isUserInteractionEnabled = false
        } else {
            // Enable tombol kirim
            btnTolakKirim.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func tolakBatalPressed(_ sender: AnyObject) {
        vwShadow.isHidden = true
        vwTolakPesanan.isHidden = true
    }
    
    @IBAction func tolakKirimPressed(_ sender: AnyObject) {
        self.sendMode(true)
        if (self.trxId != nil) {
            // API Migrasi
        let _ = request(APITransactionProduct.rejectTransaction(tpId: self.trxId!, reason: self.txtvwAlasanTolak.text)).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Tolak Pengiriman")) {
                    let json = JSON(resp.result.value!)
                    let data : Bool? = json["_data"].bool
                    if (data != nil || data == true) {
                        Constant.showDialog("Success", message: "Tolak pesanan berhasil dilakukan")
                        
                        // Hide pop up
                        self.sendMode(false)
                        self.vwShadow.isHidden = true
                        self.vwTolakPesanan.isHidden = true
                        
                        // Reload content
                        self.getTransactionDetail()
                    }
                }
            }
        }
    }
    
    // MARK: - Review Seller Pop Up
    
    @IBAction func rvwLovePressed(_ sender: UIButton) {
        var isFound = false
        for i in 0 ..< btnsRvwLove.count {
            let b = btnsRvwLove[i]
            if (!isFound) {
                if (sender == b) {
                    isFound = true
                    loveValue = i + 1
                    //print("loveValue = \(loveValue)")
                }
                lblsRvwLove[i].text = ""
            } else {
                lblsRvwLove[i].text = ""
            }
        }
    }
    
    @IBAction func rvwAgreementPressed(_ sender: AnyObject) {
        isRvwAgreed = !isRvwAgreed
        if (isRvwAgreed) {
            lblChkRvwAgreement.text = "";
            lblChkRvwAgreement.font = AppFont.prelo2.getFont(19)!
            lblChkRvwAgreement.textColor = Theme.ThemeOrange
        } else {
            lblChkRvwAgreement.text = "";
            lblChkRvwAgreement.font = AppFont.preloAwesome.getFont(24)!
            lblChkRvwAgreement.textColor = Theme.GrayLight
        }
    }
    
    @IBAction func reviewBatalPressed(_ sender: AnyObject) {
        self.vwShadow.isHidden = true
        self.vwReviewSeller.isHidden = true
    }
    
    @IBAction func reviewKirimPressed(_ sender: AnyObject) {
        if (txtvwReview.text.isEmpty || txtvwReview.text == self.TxtvwReviewPlaceholder) {
            Constant.showDialog("Review Penjual", message: "Isi review tidak boleh kosong")
            return
        } else if (!isRvwAgreed) {
            Constant.showDialog("Review Penjual", message: "Isi checkbox sebagai tanda persetujuan")
            return
        }
        
        self.sendMode(true)
        if (self.trxProductDetail != nil) {
            let _ = request(APIProduct.postReview(productID: self.trxProductDetail!.productId, comment: (txtvwReview.text == TxtvwReviewPlaceholder) ? "" : txtvwReview.text, star: loveValue)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Review Penjual")) {
                    let json = JSON(resp.result.value!)
                    let dataBool : Bool = json["_data"].boolValue
                    let dataInt : Int = json["_data"].intValue
                    ////print("dataBool = \(dataBool), dataInt = \(dataInt)")
                    if (dataBool == true || dataInt == 1) {
                        // Prelo Analytic - Review and Rate Seller
                        self.sendReviewRateSellerAnalytic()
                        
                        Constant.showDialog("Success", message: "Review berhasil ditambahkan")
                    } else {
                        Constant.showDialog("Success", message: "Terdapat kesalahan saat memproses data")
                    }
                    
                    // Hide pop up
                    self.sendMode(false)
                    self.vwShadow.isHidden = true
                    self.vwReviewSeller.isHidden = true
                    
                    // Reload content
                    self.getTransactionDetail()
                }
            }
        }
    }
    
    // MARK: - Tunda Pengiriman Pop Up
    
    @IBAction func tundaAgreementPressed(_ sender: AnyObject) {
        isTundaAgreed = !isTundaAgreed
        if (isTundaAgreed) {
            lblChkTundaAgreement.text = "";
            lblChkTundaAgreement.font = AppFont.prelo2.getFont(19)!
            lblChkTundaAgreement.textColor = Theme.ThemeOrange
        } else {
            lblChkTundaAgreement.text = "";
            lblChkTundaAgreement.font = AppFont.preloAwesome.getFont(24)!
            lblChkTundaAgreement.textColor = Theme.GrayLight
        }
    }
    
    @IBAction func tundaBatalPressed(_ sender: AnyObject) {
        self.vwShadow.isHidden = true
        self.vwTundaPengiriman.isHidden = true
    }
    
    @IBAction func tundaKirimPressed(_ sender: AnyObject) {
        if (!isTundaAgreed) {
            Constant.showDialog("Tunda Pengiriman", message: "Isi checkbox sebagai tanda persetujuan")
            return
        }
        
        self.sendMode(true)
        if (self.trxDetail != nil) {
            var arrId : String = "["
            for i in 0...trxDetail!.transactionProducts.count - 1 {
                arrId += "\"" + trxDetail!.transactionProducts[i].id + "\""
                if (i < trxDetail!.transactionProducts.count - 1) {
                    arrId += ","
                }
            }
            arrId += "]"
            let _ = request(APITransactionAnggi.delayShipping(arrTpId: arrId)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Tunda Pengiriman")) {
                    let json = JSON(resp.result.value!)
                    let msg = json["_data"].stringValue
                    Constant.showDialog("Tunda Pengiriman", message: msg)
                    
                    // Prelo Analytic - Delay Shipping
                    self.sendDelayShippingAnalytic()
                    
                    // Hide pop up
                    self.vwShadow.isHidden = true
                    self.vwTundaPengiriman.isHidden = true
                }
                self.sendMode(false)
            }
        }
    }
    
    // MARK: - Other functions
    
    func sendMode(_ mode: Bool) {
        if (mode) {
            // Disable tolak pesanan content
            txtvwAlasanTolak.isUserInteractionEnabled = false
            btnTolakBatal.isUserInteractionEnabled = false
            btnTolakKirim.setTitle("MENGIRIM...", for: UIControlState())
            btnTolakKirim.isUserInteractionEnabled = false
            btnTolakKirim.backgroundColor = Theme.PrimaryColorDark
            
            // Disable review seller content
            for i in 0 ..< btnsRvwLove.count {
                let b = btnsRvwLove[i]
                b.isUserInteractionEnabled = false
            }
            self.txtvwReview.isUserInteractionEnabled = false
            self.btnRvwBatal.isUserInteractionEnabled = false
            self.btnRvwKirim.setTitle("MENGIRIM...", for: UIControlState())
            self.btnRvwKirim.isUserInteractionEnabled = false
            
            // Disable tunda pengiriman content
            self.btnTundaBatal.isUserInteractionEnabled = false
            self.btnTundaKirim.setTitle("MENGIRIM...", for: UIControlState())
            self.btnTundaKirim.isUserInteractionEnabled = false
        } else {
            // Enable tolak pesanan content
            txtvwAlasanTolak.isUserInteractionEnabled = true
            btnTolakBatal.isUserInteractionEnabled = true
            btnTolakKirim.setTitle("KIRIM", for: UIControlState())
            btnTolakKirim.isUserInteractionEnabled = true
            btnTolakKirim.backgroundColor = Theme.PrimaryColor
            
            // Enable review seller content
            for i in 0 ..< btnsRvwLove.count {
                let b = btnsRvwLove[i]
                b.isUserInteractionEnabled = true
            }
            self.txtvwReview.isUserInteractionEnabled = true
            self.btnRvwBatal.isUserInteractionEnabled = true
            self.btnRvwKirim.setTitle("KONFIRMASI PENERIMAAN", for: UIControlState())
            self.btnRvwKirim.isUserInteractionEnabled = true
            
            // Enable tunda pengiriman content
            self.btnTundaBatal.isUserInteractionEnabled = true
            self.btnTundaKirim.setTitle("TUNDA", for: UIControlState())
            self.btnTundaKirim.isUserInteractionEnabled = true
        }
    }
    
    func userIsSeller() -> Bool {
        return (isSeller != nil && isSeller == true)
    }
    
    func hideLoading() {
        vwShadow.isHidden = true
        loading.isHidden = true
        loading.stopAnimating()
    }
    
    func showLoading() {
        vwShadow.isHidden = false
        loading.isHidden = false
        loading.startAnimating()
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
    
    func getTitleContentPembayaranBuyerPaidType(_ trxProductDetail : TransactionProductDetail) -> String {
        if (trxProductDetail.paymentMethod.lowercased() == "credit card") {
            return TransactionDetailTools.TitleContentPembayaranBuyerPaidCC
        } else if (trxProductDetail.paymentMethod.lowercased() == "indomaret") {
            return TransactionDetailTools.TitleContentPembayaranBuyerPaidIndomaret
        } else if (trxProductDetail.paymentMethod.lowercased() == "kredivo") {
            return TransactionDetailTools.TitleContentPembayaranBuyerPaidKredivo
        } else if (trxProductDetail.paymentMethod.lowercased() == "cimb clicks") {
            return TransactionDetailTools.TitleContentPembayaranBuyerPaidCimbClicks
        } else if (trxProductDetail.paymentMethod.lowercased() == "mandiri clickpay") {
            return TransactionDetailTools.TitleContentPembayaranBuyerPaidMandiriClickpay
        } else if (trxProductDetail.paymentMethod.lowercased() == "mandiri ecash") {
            return TransactionDetailTools.TitleContentPembayaranBuyerPaidMandiriEcash
        } else if (trxProductDetail.paymentMethod.lowercased() == "permata va") {
            return TransactionDetailTools.TitleContentPembayaranBuyerPaidPermataVa
        } else if (trxProductDetail.paymentBankSource.lowercased() == "prelo bonus") {
            return TransactionDetailTools.TitleContentPembayaranBuyerPaidBonus
        } else {
            return TransactionDetailTools.TitleContentPembayaranBuyerPaidTransfer
        }
    }
    
    // MARK: - FloatRatingViewDelegate
    
    func floatRatingView(_ ratingView: FloatRatingView, isUpdating rating:Float) {
        self.loveValue = Int(self.floatRatingView.rating)
    }
    
    func floatRatingView(_ ratingView: FloatRatingView, didUpdate rating: Float) {
        self.loveValue = Int(self.floatRatingView.rating)
//        Constant.showDialog("Rate / Love", message: "Original \(self.floatRatingView.rating.description) --> \(self.loveValue.string)")
    }
    
    // Prelo Analytic - Review and Rate Seller
    func sendReviewRateSellerAnalytic() {
        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.PreloAnalytic",
                                            qos: .background,
                                            attributes: .concurrent,
                                            target: nil)
        backgroundQueue.async {
            let tp = self.trxProductDetail!
            
            let loginMethod = User.LoginMethod ?? ""
            
            /*
            let province = CDProvince.getProvinceNameWithID(tp.shippingProvinceId) ?? ""
            let region = CDRegion.getRegionNameWithID(tp.shippingRegionId) ?? ""
            
            let shipping = [
                "Province" : province,
                "Region" : region,
                "Price" : tp.shippingPrice
            ] as [String : Any]
             */
            
            let pdata = [
                "Order ID" : tp.orderId,
                "Product ID" : tp.productId ,
                //"Price" : tp.productPrice,
                //"Commission Percentage" : tp.commission,
                //"Commission Price" : tp.commissionPrice,
                "Seller Username" : tp.sellerUsername,
                //"Shipping" : shipping,
                "Rate" : self.loveValue,
                "Current State" : tp.progressText
            ] as [String : Any]
            
            AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ReviewAndRateSeller, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
        }
    }
    
    // Prelo Analytic - Delay Shipping
    func sendDelayShippingAnalytic() {
        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.PreloAnalytic",
                                            qos: .background,
                                            attributes: .concurrent,
                                            target: nil)
        backgroundQueue.async {
            /*
            var itemsObject : Array<[String : Any]> = []
            
            let arrayProduct = self.trxDetail?.transactionProducts
            
            var totalCommissionPrice = 0
            var i = 0
            for tp in arrayProduct! {
                let shippingPrice = Int(tp.shippingPrice) ?? 0
                
                let curItem : [String : Any] = [
                    "Product ID" : tp.productId ,
                    "Price" : tp.productPrice,
                    "Commission Percentage" : tp.commission,
                    "Commission Price" : tp.commissionPrice,
                    "Shipping Price" : shippingPrice,
                ]
                
                itemsObject.append(curItem)
                
                totalCommissionPrice += tp.commissionPrice
                
                i += 1
            }
            
            let loginMethod = User.LoginMethod ?? ""
            let province = CDProvince.getProvinceNameWithID((self.trxDetail?.shippingProvinceId)!) ?? ""
            let region = CDRegion.getRegionNameWithID((self.trxDetail?.shippingRegionId)!) ?? ""
            
            let shipping = [
                "Province" : province,
                "Region" : region
            ] as [String : Any]
            
            let pdata = [
                "Order ID" : (self.trxDetail?.orderId)!,
                "Seller Username" : (CDUser.getOne()?.username)!, // me
                "Items" : itemsObject,
                //                "Total Original Price" : self.trxDetail.totalPrice,
                "Total Price" : (self.trxDetail?.totalPriceTotall)!,
                "Total Commission" : totalCommissionPrice,
                "Shipping" : shipping
            ] as [String : Any]
            AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.DelayShipping, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
             */
            
            let arrayProduct = self.trxDetail?.transactionProducts
            let loginMethod = User.LoginMethod ?? ""
            let province = CDProvince.getProvinceNameWithID((self.trxDetail?.shippingProvinceId)!) ?? ""
            let region = CDRegion.getRegionNameWithID((self.trxDetail?.shippingRegionId)!) ?? ""
            let subdistrict = (self.trxDetail?.shippingSubdistrictName)!
            
            let address = [
                "Province" : province,
                "Region" : region,
                "Subdistrict" : subdistrict
            ] as [String : Any]
            
            for tp in arrayProduct! {
                let pdata : [String : Any] = [
                    "Order ID" : tp.orderId,
                    "Product ID" : tp.productId,
                    "Seller Username" : tp.sellerUsername, // me
                    "Price" : tp.productPrice,
                    "Commission Percentage" : tp.commission,
                    "Commission Price" : tp.commissionPrice,
                    "Address" : address
                ]
                
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.DelayShipping, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
            }
        }
    }
    
    // MARK: - Setup popup
    
    func launchNewPopUp() {
        if self.isReportable == nil {
            self.isReportable = self.trxProductDetail?.reportable
        }
        
        self.setupPopUp(isReportable)
        self.newPopup?.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.newPopup?.setupPopUp()
            self.newPopup?.displayPopUp()
        })
    }
    
    func setupPopUp(_ isReportable: Bool?) {
        // setup popup
        if (self.newPopup == nil) {
            self.newPopup = Bundle.main.loadNibNamed("TransactionReportPopup", owner: nil, options: nil)?.first as? TransactionReportPopup
            self.newPopup?.frame = UIScreen.main.bounds
            self.newPopup?.tag = 100
            self.newPopup?.isHidden = true
            self.newPopup?.backgroundColor = UIColor.clear
            self.view.addSubview(self.newPopup!)
            
            self.newPopup?.initPopUp(isReportable)
            
            self.newPopup?.disposePopUp = {
                self.newPopup?.isHidden = true
                self.newPopup = nil
                //print("Start remove sibview")
                if let viewWithTag = self.view.viewWithTag(100) {
                    viewWithTag.removeFromSuperview()
                } else {
                    //print("No!")
                }
            }
            
            self.newPopup?.reportTrx = {
                // TODO: - report trx VC
                let reportTrxVC = Bundle.main.loadNibNamed(Tags.XibNameReportTransaction, owner: nil, options: nil)?.first as! ReportTransactionViewController
                if (self.trxProductId != nil) {
                    reportTrxVC.tpId = self.trxProductId!
                    reportTrxVC.sellerId = (self.trxProductDetail?.sellerId)!
                    reportTrxVC.wjpTime = (self.trxProductDetail?.wjpTime)!
                    reportTrxVC.blockDone = { result in
                        self.isReportable = result
                        
                        self.tableView.reloadData()
                    }
                    //reportTrxVC.pId = (self.trxProductDetail?.productId)!
                }
                reportTrxVC.previousScreen = PageName.TransactionDetail
                self.navigationController?.pushViewController(reportTrxVC, animated: true)
            }
            
            self.newPopup?.refundTrx = {
                let refundReqVC = Bundle.main.loadNibNamed(Tags.XibNameRequestRefund, owner: nil, options: nil)?.first as! RefundRequestViewController
                if (self.trxProductId != nil) {
                    refundReqVC.tpId = self.trxProductId!
                    refundReqVC.pId = (self.trxProductDetail?.productId)!
                }
                refundReqVC.previousScreen = PageName.TransactionDetail
                self.navigationController?.pushViewController(refundReqVC, animated: true)
            }
        }
        
    }
}

// MARK: - Class

class TransactionDetailTools : NSObject {
    // Progress number
    static let ProgressExpired = -1
    static let ProgressReservationCancelled = -2
    static let ProgressRejectedBySeller = -3
    static let ProgressNotSent = -4
    static let ProgressFraudDetected = -6
    static let ProgressNotPaid = 1
    static let ProgressClaimedPaid = 2
    static let ProgressConfirmedPaid = 3
    static let ProgressSent = 4
    static let ProgressReceived = 5
    static let ProgressReviewed = 6
    static let ProgressReserved = 7
    static let ProgressReserveDone = 8
    static let ProgressRefundRequested = 30
    static let ProgressRefundVerified = 31
    static let ProgressRefundSent = 32
    static let ProgressRefundSuccess = 33
    
    // Layouting
    static let Margin : CGFloat = 8.0
    static let TransactionDetailProductCellHeight : CGFloat = 109
    static let TransactionDetailDetailedProductCellHeight : CGFloat = 207
    
    // TitleContent type
    static let TitleContentPembayaranBuyer = "tcpembayaranbuyer"
    static let TitleContentPembayaranBuyerPaidTransfer = "tcpembayaranbuyerpaidtransfer"
    static let TitleContentPembayaranBuyerPaidCC = "tcpembayaranbuyerpaidcc"
    static let TitleContentPembayaranBuyerPaidBonus = "tcpembayaranbuyerpaidbonus"
    static let TitleContentPembayaranBuyerPaidIndomaret = "tcpembayaranbuyerpaidindomaret"
    static let TitleContentPembayaranBuyerPaidKredivo = "tcpembayaranbuyerpaidkredivo"
    static let TitleContentPembayaranBuyerPaidCimbClicks = "tcpembayaranbuyerpaidcimbclicks"
    static let TitleContentPembayaranBuyerPaidMandiriClickpay = "tcpembayaranbuyerpaidmandiryclickpay"
    static let TitleContentPembayaranBuyerPaidMandiriEcash = "tcpembayaranbuyerpaidmandiriecash"
    static let TitleContentPembayaranBuyerPaidPermataVa = "tcpembayaranbuyerpaidpermatava"
    static let TitleContentPembayaranSeller = "tcpembayaranseller"
    static let TitleContentPengirimanBuyer = "tcpengirimanbuyer"
    static let TitleContentPengirimanSeller = "tcpengirimanseller"
    static let TitleContentReimburse = "tcreimburse"
    static let TitleContentReserved = "tcreserved"
    static let TitleContentPembayaranReservasi = "tcpembayaranreservasi"
    
    static let TitleContentAffiliate = "tcaffiliate"
    
    // Text
    static let TextPreloPhone = "022 250 35 93"
    static let TextPembayaranExpiredBuyer = "Pembayaran expired karena kamu belum membayar hingga batas waktu yang ditentukan."
    static let TextPembayaranExpiredSeller = "Pembayaran expired karena pembeli belum membayar hingga batas waktu yang ditentukan."
    static let TextHubungiBuyer = "Beritahu pembeli bahwa barang sudah dikirim. Minta pembeli untuk memberikan review apabila barang sudah diterima."
    static let TextDikembalikanDitolak = "Pembayaran barang ini telah dikembalikan kepada pembeli." // reject by seller
    static let TextDikembalikanTidakDikirim = "Pembayaran barang ini telah dikembalikan kepada pembeli. Lupa konfirmasi pengiriman? Hubungi Prelo." // not sent seller
    static let TextReimburse1 = "Mohon maaf, pesanan kamu tidak bisa dikirim karena keterbatasan pada penjual. Jangan khawatir, pembayaranmu telah disimpan dalam bentuk:"
    static let TextReimburse2 = "Kamu dapat menggunakannya untuk transaksi selanjutnya atau tarik uang Prelo Balance."
    static let TextNotPaid = "Transaksi ini belum dibayar dan akan expired pada "
    static let TextNotPaidSeller = "Ingatkan pembeli untuk segera membayar."
    static let TextNotPaidBuyerTransfer = "Segera konfirmasi pembayaran."
    static let TextNotPaidBuyerVeritrans = "Segera lanjutkan pembayaran."
    static let TextClaimedPaidSeller = "Pembayaran pembeli sedang dikonfirmasi oleh Prelo, mohon tunggu."
    static let TextClaimedPaidBuyer = "Hubungi Prelo apabila alamat pengiriman salah."
    static let TextConfirmedPaidSeller1 = "Kirim pesanan dalam 3 hari kerja setelah konfirmasi pembayaran (sebelum "
    static let TextConfirmedPaidSeller2 = "Jika kamu tidak mengirimkan sampai waktu tersebut, transaksi akan dibatalkan serta uang akan dikembalikan kepada pembeli."
    static let TextConfirmedPaidBuyer1 = "Pesanan kamu belum dikirim dan akan expired pada "
    static let TextConfirmedPaidBuyer2 = "Ingatkan penjual untuk mengirim pesanan."
    
    static let refundRejectNoteBuyer = "Catatan:\n1. Pembayaran transaksi ini dilindungi oleh Waktu Jaminan Prelo yang berlangsung selama 3 x 24 jam sejak status transaksi Diterima.\n2. Klik Laporkan Transaksi ini digunakan apabila resi atau barang yang diterima bermasalah serta bila barang belum kamu terima tetapi status transaksi Diterima.\n3. Jangan lupa untuk me-review penjual jika barang sudah kamu terima.\n4. Jika kamu melakukan Refund ketika laporan sedang diproses, maka laporan otomatis akan dibatalkan. \n\nLakukan review hanya jika barang benar-benar sudah diterima."
    static let noteBuyer = "Catatan:\n1. Waktu Jaminan Prelo untuk transaksi ini telah berakhir. Uang pembayaran telah otomatis disalurkan ke penjual.\n2. Segera lakukan review jika barang sudah kamu terima."
    
    static let TextSentSeller = "Pembayaran transaksi ini dilindungi oleh Waktu Jaminan Prelo sejak status transaksi menjadi Diterima. Uang dapat langsung kamu tarik setelah Waktu Jaminan Prelo berakhir atau jika barang telah selesai direview.\n\nIngatkan pembeli untuk memberi review."
    static let TextSentBuyer = refundRejectNoteBuyer //"Pembayaran transaksi ini dilindungi oleh Waktu Jaminan Prelo yang berlangsung selama 3x24 jam sejak status transaksi menjadi Diterima. Refund dapat dilakukan selama jangka waktu tersebut jika terdapat keluhan terkait barang. Jangan lupa lakukan review jika barang sudah diterima.\n\nResi tidak valid atau foto resi tidak sesuai? Hubungi Prelo."
    //static let TextSentBuyerNoRefund = "Refund sudah tidak dapat dilakukan karena sudah melebihi batas Waktu Jaminan Prelo (3x24 jam sejak barang diterima). Jangan lupa lakukan review."
    static let TextReceivedSeller = "Pembayaran transaksi ini dilindungi oleh Waktu Jaminan Prelo yang berlangsung selama 3x24 jam sejak status transaksi menjadi Diterima. Uang dapat langsung kamu tarik setelah Waktu Jaminan Prelo berakhir atau jika barang telah selesai direview.\n\nIngatkan pembeli untuk memberi review."
    static let TextReceivedBuyer = refundRejectNoteBuyer //"Barang semestinya sudah kamu terima. Pembayaran transaksi ini dilindungi oleh Waktu Jaminan Prelo yang berlangsung selama 3x24 jam sejak status transaksi menjadi Diterima. Refund dapat dilakukan selama jangka waktu tersebut jika terdapat keluhan terkait barang. Jangan lupa lakukan review.\n\nResi tidak valid atau foto resi tidak sesuai? Belum terima barang? Hubungi Prelo."
    static let TextReceivedBuyerNoRefund = noteBuyer //"Refund sudah tidak dapat dilakukan karena sudah melebihi batas Waktu Jaminan Prelo (3x24 jam sejak status transaksi menjadi Diterima). Jangan lupa lakukan review.\n\nResi tidak valid atau foto resi tidak sesuai? Belum terima barang? Hubungi Prelo."
    static let TextReserved1 = "Barang ini telah direservasi khusus untuk kamu. Kamu dapat menyelesaikan pembelian barang ini dengan menyelesaikan pembayaran pada"
    static let TextReserved2 = "Apabila kamu tidak menyelesaikan pembelian sampai dengan batas waktu yang ditentukan, reservasi barang kamu akan dibatalkan.\n\nTunjukkan halaman ini sebagai bukti reservasi kamu."
    static let TextReserveDone = "Terima kasih sudah berbelanja di Prelo! Temukan barang preloved lainnya di Prelo dan tunggu event menarik selanjutnya dari Prelo."
    static let TextReservationCancelled = "Reservasi kamu sudah resmi dibatalkan. Apabila kamu ingin memesan kembali, kamu bisa memilih barang ini di menu Garage Sale."
    static let TextFraudDetected = "Transaksi ini tidak lolos verifikasi."
    static let TextRefundRequestBuyer = "Pengajuan refund sudah diterima oleh Prelo. Mohon tunggu notifikasi dari Customer Service Prelo."
    static let TextRefundRequestSeller1 = "Buyer meminta proses refund karena "
    static let TextRefundRequestSeller2 = ". Tunggu konfirmasi dari Customer Service Prelo."
    static let TextRefundVerifiedBuyer = "Pengajuan refund sudah disetujui oleh Prelo. Hubungi penjual untuk mendapatkan alamat pengiriman. Lakukan konfirmasi jika pengiriman sudah dilakukan."
    static let TextRefundVerifiedSeller = "Pengajuan refund sudah disetujui oleh Prelo. Hubungi pembeli untuk memberikan alamat pengembalian barang."
    static let TextRefundSentBuyer = "Terima kasih telah melakukan konfirmasi pengembalian. Uang kamu akan dikembalikan via Prelo Balance maksimal dalam 4 x 24 jam."
    static let TextRefundSentSeller = "Barang kamu telah dikirimkan kembali oleh pembeli. Lakukan konfirmasi penerimaan jika barang sudah diterima."
    static let TextRefundSuccessBuyer1 = "Proses refund sukses. Pembayaranmu telah dikembalikan dalam bentuk:"
    static let TextRefundSuccessBuyer2 = "Kamu dapat menggunakannya untuk transaksi selanjutnya atau tarik uang Prelo Balance."
    static let TextRefundSuccessSeller = "Proses refund sukses. Pembayaran sudah dikembalikan kepada pembeli."
    
    // MARK: - Affiliate
    fileprivate static var _AffiliateName = "Affiliate"
    static var AffiliateName : String {
        get {
            return _AffiliateName
        }
    }
    
    fileprivate static var _AffiliateConfirmURL = "Affiliate"
    static var AffiliateConfirmURL : String {
        get {
            return _AffiliateConfirmURL
        }
    }
    
    fileprivate static var _AffiliateURL = "Affiliate"
    static var AffiliateURL : String {
        get {
            return _AffiliateURL
        }
    }
    
    fileprivate static var _AffiliateRefundURL = "Affiliate"
    static var AffiliateRefundURL : String {
        get {
            return _AffiliateRefundURL
        }
    }
    
    fileprivate static var _AffiliateBankAccounts: Array<BankAccount> = []
    static var AffiliateBankAccounts : Array<BankAccount> {
        get {
            return _AffiliateBankAccounts
        }
    }
    
    // Affiliate
    static let TextAffiliateUnpaid = "Transaksi ini belum dibayar. Segera konfirmasi pembayaran di " + TransactionDetailTools.AffiliateName + ". Untuk transaksi menggunakan transfer bank, transfer ke rekening " + TransactionDetailTools.AffiliateName + " di:\n\n" + TransactionDetailTools.AffiliateBankAccounts[0].bank_name + "\n" + TransactionDetailTools.AffiliateBankAccounts[0].no.replace(" ", template: "") + "\n" + TransactionDetailTools.AffiliateBankAccounts[0].name + "\n\nCek e-mail dari " + TransactionDetailTools.AffiliateName + " untuk rincian pembayaran. Apabila kamu sudah melakukan konfirmasi pembayaran, harap tunggu notifikasi selanjutnya."
    static let TextAffiliateExpired = "Pembayaran ini expired karena kamu belum membayar hingga batas waktu yang ditentukan."
    static let TextAffiliatePaid = "Pesanan kamu sedang diproses oleh " + TransactionDetailTools.AffiliateName + "."
    static let TextAffiliateReject = "Mohon maaf, pesanan kamu tidak bisa dikirim karena keterbatasan pada penjual. Uang kamu telah dikembalikan melalui sistem " + TransactionDetailTools.AffiliateName + "."
    static let TextAffiliateReceived = "Transaksi telah selesai. Terima kasih telah berbelanja di " + TransactionDetailTools.AffiliateName + " melalui Prelo. Jika barang yang diterima bermasalah, klik tombol Refund untuk melihat kebijakan refund dari " + TransactionDetailTools.AffiliateName + "."
    static let TextAffiliateSuccess = "Transaksi telah selesai. Terima kasih telah berbelanja di " + TransactionDetailTools.AffiliateName + " melalui Prelo."
    static let TextAffiliateSend = "Pesanan kamu telah dikirim oleh " + TransactionDetailTools.AffiliateName + ". Jika barang yang diterima bermasalah, klik tombol Refund untuk melihat kebijakan refund dari " + TransactionDetailTools.AffiliateName + "."
    
    // Icon
    static let IcDownArrow = ""
    static let IcUpArrow = ""
    
    // Courier image
    static let ImgCouriers = [
        "jne" : UIImage(named : "courier_jne"),
        "tiki" : UIImage(named : "courier_tiki"),
        "pos" : UIImage(named : "courier_pos")
    ]
    
    // Functions
    static func isReservationProgress(_ progress : Int?) -> Bool {
        return (progress == 7 || progress == 8 || progress == -2)
    }
    
    static func isRefundProgress(_ progress : Int?) -> Bool {
        return (progress == 30 || progress == 31 || progress == 32 || progress == 33)
    }
    
    static func setAffiliateName(_ affiliateName: String) {
        _AffiliateName = affiliateName
    }
    
    static func setAffiliateConfirmURL(_ affiliateConfirmURL: String) {
        _AffiliateConfirmURL = affiliateConfirmURL
    }
    
    static func setAffiliateURL(_ affiliateURL: String) {
        _AffiliateURL = affiliateURL
    }
    
    static func setAffiliateRefundURL(_ affiliateRefundURL: String) {
        _AffiliateRefundURL = affiliateRefundURL
    }
    
    static func setAffiliateBankAccount(_ affiliateBankAccounts: Array<BankAccount>) {
        _AffiliateBankAccounts = affiliateBankAccounts
    }
}

// MARK: - Class

class TransactionDetailTableCell : UITableViewCell, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    // Cell type
    var isProductCell : Bool = false
    var isTitleContentCell : Bool = false
    
    // Used for productCell
    var trxProducts : [TransactionProductDetail] = []
    var hideProductCell : [Bool] = []
    
    // Used for titleContentCell
    var trxDetail : TransactionDetail?
    var trxProductDetail : TransactionProductDetail?
    var titleContentType : String = ""
    
    // Cell identifiers
    let TransactionDetailProductCellId = "TransactionDetailProductCell"
    let TransactionDetailTitleContentCellId = "TransactionDetailTitleContentCell"
    let TransactionDetailTitleContentHeaderCellId = "TransactionDetailTitleContentHeaderCell"
    
    // Actions
    var toProductDetail : (String) -> () = { _ in }
    var switchDetailProduct : (Int) -> () = { _ in }
    
    var root : UIViewController?
    
    static func heightForProducts(_ hideProductCell : [Bool]) -> CGFloat {
        var height : CGFloat = 0
        for i in 0...hideProductCell.count - 1 {
            if (hideProductCell[i] == true) {
                height += TransactionDetailTools.TransactionDetailProductCellHeight
            } else {
                height += TransactionDetailTools.TransactionDetailDetailedProductCellHeight
            }
        }
        return height
    }
    
    static func heightForTitleContents(_ trxDetail : TransactionDetail, titleContentType : String) -> CGFloat {
        var height : CGFloat = 8

        if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyer) {
            height += TransactionDetailTitleContentCell.heightFor((trxDetail.totalPrice + trxDetail.bonusUsed + trxDetail.preloBalanceUsed + trxDetail.voucherAmount).asPrice)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.bonusUsed.asPrice)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.preloBalanceUsed.asPrice)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.voucherAmount.asPrice)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.totalPrice.asPrice)
            //height += TransactionDetailTitleContentCell.heightFor(trxDetail.bankTransferDigit.asPrice)
            height += TransactionDetailTitleContentCell.heightFor((trxDetail.totalPrice + trxDetail.bankTransferDigit).asPrice)
//            height += TransactionDetailTitleContentCell.heightFor(trxDetail.paymentMethod)
//            height += TransactionDetailTitleContentCell.heightFor(trxDetail.paymentDate)
//            height += TransactionDetailTitleContentCell.heightFor(trxDetail.paymentBankTarget)
//            height += TransactionDetailTitleContentCell.heightFor(trxDetail.paymentNominal.asPrice)
            
            // 0
            
            // Indomaret
            if (trxDetail.paymentMethodInt == 4) {
                if (trxDetail.paymentCode != "") {
                    height += TransactionDetailTitleContentCell.heightFor(trxDetail.paymentCode) + 20 // space
                } else {
                    height += TransactionDetailTitleContentCell.heightFor("Klik tombol \"LANJUTKAN PEMBAYARAN\" untuk mendapatkan kode bayar") + 20 // space
                }
                
                // Mandiri Ecash
            } else if (trxDetail.paymentMethodInt == 7) {
                height += TransactionDetailTitleContentCell.heightForTitleNil("Pembayaran melalui Mandiri e-cash harus diselesaikan di website Mandiri. Pastikan kamu telah mendaftarkan nomor ponsel untuk Mandiri e-cash.") + 20 // space
            
                // CIMB Clicks
            } else if (trxDetail.paymentMethodInt == 8) {
                height += TransactionDetailTitleContentCell.heightForTitleNil("Pembayaran melalui CIMB Clicks harus diselesaikan di website CIMB Clicks. Pastikan kamu telah memiliki User ID CIMB Clicks dan sudah mendaftarkan mPIN sebelum melakukan pembayaran.") + 20 // space
            
                // Permata VA
            } else if (trxDetail.paymentMethodInt == 9) {
                height += TransactionDetailTitleContentCell.heightForTitleNil("Pembayaran dapat dilakukan melalui jaringan ATM dan internet banking bank Permata atau bank lain yang tergabung dalam jaringan ATM Bersama, Prima, atau Alto. Cek e-mail untuk instruksi pembayaran melalui virtual account yang lebih jelas.") + 20 // space
                
                if (trxDetail.vaNumber != "") {
                    height += TransactionDetailTitleContentCell.heightFor(trxDetail.vaNumber) + 20 // space
                } else {
                    height += TransactionDetailTitleContentCell.heightFor("Klik tombol \"LANJUTKAN PEMBAYARAN\" untuk mendapatkan VA number") + 20 // space
                }
            }
            
            // 6
            
            var title = ""
            var content = ""
            if (trxDetail.paymentMethodInt == 1) {
                title = "Charge Kartu Kredit"
                content = trxDetail.veritransChargeAmount.asPrice
            } else if (trxDetail.paymentMethodInt == 4) {
                title = "Charge Indomaret"
                content = trxDetail.veritransChargeAmount.asPrice
            } else if (trxDetail.paymentMethodInt == 5) {
                title = "Charge Kredivo"
                content = trxDetail.kredivoChargeAmount.asPrice
            } else if (trxDetail.paymentMethodInt == 6) {
                title = "Charge Mandiri Clickpay"
                content = trxDetail.veritransChargeAmount.asPrice
            } else if (trxDetail.paymentMethodInt == 7) {
                title = "Charge Mandiri e-cash"
                content = trxDetail.veritransChargeAmount.asPrice
            } else if (trxDetail.paymentMethodInt == 8) {
                title = "Charge CIMB Clicks"
                content = trxDetail.veritransChargeAmount.asPrice
            } else if (trxDetail.paymentMethodInt == 9) {
                title = "Charge Virtual Account"
                content = trxDetail.veritransChargeAmount.asPrice
            } else {
                title = "Kode Unik"
                content = trxDetail.bankTransferDigit.asPrice
            }
            height += TransactionDetailTitleContentCell.heightFor(title, content: content)
            
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranSeller) {
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.paymentDate)
        } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanBuyer) {
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingRecipientName)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingRecipientPhone)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingAddress)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingSubdistrictName)
            if let r = CDRegion.getRegionNameWithID(trxDetail.shippingRegionId) {
                height += TransactionDetailTitleContentCell.heightFor(r)
            }
            if let p = CDProvince.getProvinceNameWithID(trxDetail.shippingProvinceId) {
                height += TransactionDetailTitleContentCell.heightFor(p)
            }
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingPostalCode)
            if let img = TransactionDetailTools.ImgCouriers[trxDetail.shippingName.components(separatedBy: " ")[0].lowercased()] {
               height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingName, image: img!)
            } else {
                height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingName)
            }
            if trxDetail.resiNumber != "" {
                height += TransactionDetailTitleContentCell.heightFor(trxDetail.resiNumber)
                height += TransactionDetailTitleContentCell.heightFor("Lihat foto resiœ")
            }
            if trxDetail.isShowShipHistory {
                if let msg = trxDetail.shipHistoryMsg {
                    height += TransactionDetailTitleContentHeaderCell.heightFor(msg)
                } else {
                    height += TransactionDetailTitleContentHeaderCell.DefaultCellHeight
                }
                for i in 0..<trxDetail.shipHistory.count {
                    height += TransactionDetailTitleContentCell.heightFor(trxDetail.shipHistory[i].date, content: trxDetail.shipHistory[i].status)
                }
            }
        } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanSeller) {
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingRecipientName)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingRecipientPhone)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingAddress)
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingSubdistrictName)
            if let r = CDRegion.getRegionNameWithID(trxDetail.shippingRegionId) {
                height += TransactionDetailTitleContentCell.heightFor(r)
            }
            if let p = CDProvince.getProvinceNameWithID(trxDetail.shippingProvinceId) {
                height += TransactionDetailTitleContentCell.heightFor(p)
            }
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.shippingPostalCode)
            var image = UIImage()
            if let img = TransactionDetailTools.ImgCouriers[trxDetail.requestCourier.components(separatedBy: " ")[0].lowercased()] {
                image = img!
            }
            height += TransactionDetailTitleContentCell.heightFor(trxDetail.requestCourier, image: image)
            if trxDetail.resiNumber != "" {
                height += TransactionDetailTitleContentCell.heightFor(trxDetail.resiNumber)
                height += TransactionDetailTitleContentCell.heightFor("Lihat foto resiœ")
            }
            if trxDetail.isShowShipHistory {
                if let msg = trxDetail.shipHistoryMsg {
                    height += TransactionDetailTitleContentHeaderCell.heightFor(msg)
                } else {
                    height += TransactionDetailTitleContentHeaderCell.DefaultCellHeight
                }
                for i in 0..<trxDetail.shipHistory.count {
                    height += TransactionDetailTitleContentCell.heightFor(trxDetail.shipHistory[i].date, content: trxDetail.shipHistory[i].status)
                }
            }
        }
        
        return height
    }
    
    static func heightForTitleContents2(_ trxProductDetail : TransactionProductDetail, titleContentType : String) -> CGFloat {
        var height : CGFloat = 8
        
        // Bank Transfer
        if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidTransfer) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentBankTarget)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentNominal.asPrice)
            
            // Credit Card
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidCC) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            height += TransactionDetailTitleContentCell.heightFor("**** **** **** \(trxProductDetail.maskedCCLast)")
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentNominal.asPrice)
            
            // Bonus
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidBonus) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            
            // Indomaret
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidIndomaret) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentCode)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentNominal.asPrice)
            
            // Kedivo
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidKredivo) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentCode)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentNominal.asPrice)
            
            // CIMB CLicks
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidCimbClicks) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentCode)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentNominal.asPrice)
            
            // Mandiri Clickpay
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidMandiriClickpay) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentCode)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentNominal.asPrice)
            
            // Mandiri Ecash
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidMandiriEcash) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentCode)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentNominal.asPrice)
            
            // Permata VA
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidPermataVa) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentCode)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentNominal.asPrice)
            
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranSeller) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            
        } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanBuyer) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingRecipientName)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingRecipientPhone)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingAddress)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingSubdistrictName)
            if let r = CDRegion.getRegionNameWithID(trxProductDetail.shippingRegionId) {
                height += TransactionDetailTitleContentCell.heightFor(r)
            }
            if let p = CDProvince.getProvinceNameWithID(trxProductDetail.shippingProvinceId) {
                height += TransactionDetailTitleContentCell.heightFor(p)
            }
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingPostalCode)
            if let img = TransactionDetailTools.ImgCouriers[trxProductDetail.shippingName.components(separatedBy: " ")[0].lowercased()] {
                height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingName, image: img!)
            } else {
                height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingName)
            }
            if trxProductDetail.resiNumber != "" {
                height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.resiNumber)
                height += TransactionDetailTitleContentCell.heightFor("Lihat foto resiœ")
            }
            if trxProductDetail.isShowShipHistory {
                if let msg = trxProductDetail.shipHistoryMsg {
                    height += TransactionDetailTitleContentHeaderCell.heightFor(msg)
                } else {
                    height += TransactionDetailTitleContentHeaderCell.DefaultCellHeight
                }
                for i in 0..<trxProductDetail.shipHistory.count {
                    height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shipHistory[i].date, content: trxProductDetail.shipHistory[i].status)
                }
            }
            
        } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanSeller) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingRecipientName)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingRecipientPhone)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingAddress)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingSubdistrictName)
            if let r = CDRegion.getRegionNameWithID(trxProductDetail.shippingRegionId) {
                height += TransactionDetailTitleContentCell.heightFor(r)
            }
            if let p = CDProvince.getProvinceNameWithID(trxProductDetail.shippingProvinceId) {
                height += TransactionDetailTitleContentCell.heightFor(p)
            }
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shippingPostalCode)
            var image = UIImage()
            if let img = TransactionDetailTools.ImgCouriers[trxProductDetail.requestCourier.components(separatedBy: " ")[0].lowercased()] {
                image = img!
            }
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.requestCourier, image: image)
            if trxProductDetail.resiNumber != "" {
                height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.resiNumber)
                height += TransactionDetailTitleContentCell.heightFor("Lihat foto resiœ")
            }
            if trxProductDetail.isShowShipHistory {
                if let msg = trxProductDetail.shipHistoryMsg {
                    height += TransactionDetailTitleContentHeaderCell.heightFor(msg)
                } else {
                    height += TransactionDetailTitleContentHeaderCell.DefaultCellHeight
                }
                for i in 0..<trxProductDetail.shipHistory.count {
                    height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.shipHistory[i].date, content: trxProductDetail.shipHistory[i].status)
                }
            }
            
        } else if (titleContentType == TransactionDetailTools.TitleContentReimburse) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.myPreloBalance.asPrice)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.myPreloBonus.asPrice)
            
        } else if (titleContentType == TransactionDetailTools.TitleContentReserved) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.garageSalePlace)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.garageSaleEventDate)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.garageSaleEventTime)
            
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranReservasi) {
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentMethod)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentDate)
            height += TransactionDetailTitleContentCell.heightFor(trxProductDetail.paymentNominal.asPrice)
        }
        
        return height
    }
    
    func adaptTableProducts(_ trxProducts : [TransactionProductDetail], hideProductCell : [Bool]) {
        self.trxProducts = trxProducts
        self.hideProductCell = hideProductCell
        self.isProductCell = true
        self.isTitleContentCell = false
        self.tableView.separatorStyle = .singleLine
        self.setupTable()
    }
    
    func adaptTableTitleContents(_ trxDetail : TransactionDetail, titleContentType : String) {
        self.trxDetail = trxDetail
        self.titleContentType = titleContentType
        self.isProductCell = false
        self.isTitleContentCell = true
        self.tableView.separatorStyle = .none
        self.setupTable()
    }
    
    func adaptTableTitleContents2(_ trxProductDetail : TransactionProductDetail, titleContentType : String) {
        self.trxProductDetail = trxProductDetail
        self.titleContentType = titleContentType
        self.isProductCell = false
        self.isTitleContentCell = true
        self.tableView.separatorStyle = .none
        self.setupTable()
    }
    
    // MARK: - UITableView delegate functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (isProductCell) {
            return trxProducts.count
        } else {
            if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyer) {
                return 9 //4
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidTransfer) {
                return 4
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidCC) {
                return 4
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidBonus) {
                return 2
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidIndomaret) {
                return 4
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidKredivo) {
                return 4
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidCimbClicks) {
                return 4
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidMandiriClickpay) {
                return 4
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidMandiriEcash) {
                return 4
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidPermataVa) {
                return 4
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranSeller) {
                return 2
            } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanBuyer) {
                var nRow = 10
                if (isTrxDetail()) {
                    if trxDetail!.isShowShipHistory {
                        nRow += 1
                        nRow += trxDetail!.shipHistory.count
                    }
                } else if (isTrxProductDetail()) {
                    if trxProductDetail!.isShowShipHistory {
                        nRow += 1
                        nRow += trxProductDetail!.shipHistory.count
                    }
                }
                return nRow
            } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanSeller) {
                var nRow = 10
                if (isTrxDetail()) {
                    if trxDetail!.isShowShipHistory {
                        nRow += 1
                        nRow += trxDetail!.shipHistory.count
                    }
                } else if (isTrxProductDetail()) {
                    if trxProductDetail!.isShowShipHistory {
                        nRow += 1
                        nRow += trxProductDetail!.shipHistory.count
                    }
                }
                return nRow
            } else if (titleContentType == TransactionDetailTools.TitleContentReimburse) {
                return 2
            } else if (titleContentType == TransactionDetailTools.TitleContentReserved) {
                return 3
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranReservasi) {
                return 3
            }
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let idx = (indexPath as NSIndexPath).row
        if (isProductCell) {
            if (hideProductCell[idx] == true) {
                return TransactionDetailTools.TransactionDetailProductCellHeight
            } else {
                return TransactionDetailTools.TransactionDetailDetailedProductCellHeight
            }
        } else if (isTitleContentCell) {
            if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyer) {
                if (idx == 0) {
                    if (isTrxDetail() && trxDetail!.paymentMethodInt == 7) {
                        return TransactionDetailTitleContentCell.heightForTitleNil("Pembayaran melalui Mandiri e-cash harus diselesaikan di website Mandiri. Pastikan kamu telah mendaftarkan nomor ponsel untuk Mandiri e-cash.") + 20
                    } else if (isTrxDetail() && trxDetail!.paymentMethodInt == 8) {
                        return TransactionDetailTitleContentCell.heightForTitleNil("Pembayaran melalui CIMB Clicks harus diselesaikan di website CIMB Clicks. Pastikan kamu telah memiliki User ID CIMB Clicks dan sudah mendaftarkan mPIN sebelum melakukan pembayaran.") + 20
                    } else if (isTrxDetail() && trxDetail!.paymentMethodInt == 9) {
                        return TransactionDetailTitleContentCell.heightForTitleNil("Pembayaran dapat dilakukan melalui jaringan ATM dan internet banking bank Permata atau bank lain yang tergabung dalam jaringan ATM Bersama, Prima, atau Alto. Cek e-mail untuk instruksi pembayaran melalui virtual account yang lebih jelas.") + 20
                    } else {
                        return 0
                    }
                } else if (idx == 1) {
                    if (isTrxDetail() && trxDetail!.paymentMethodInt == 4) {
                        if trxDetail!.paymentCode != "" {
                            return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentCode) + 20 // space
                        } else {
                            return TransactionDetailTitleContentCell.heightFor("Klik tombol \"LANJUTKAN PEMBAYARAN\" untuk mendapatkan kode bayar") + 20
                        }
                    } else if (isTrxDetail() && trxDetail!.paymentMethodInt == 9) {
                        if trxDetail!.vaNumber != "" {
                            return TransactionDetailTitleContentCell.heightFor(trxDetail!.vaNumber) + 20 // space
                        } else {
                            return TransactionDetailTitleContentCell.heightFor("Klik tombol \"LANJUTKAN PEMBAYARAN\" untuk mendapatkan VA number") + 20
                        }
                    } else {
                        return 0
                    }
                } else if (idx == 2) {
                    if (isTrxDetail()) {
                        let p = trxDetail!.totalPrice + trxDetail!.bonusUsed + trxDetail!.preloBalanceUsed + trxDetail!.voucherAmount
                        return TransactionDetailTitleContentCell.heightFor(p.asPrice)
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.bonusUsed.asPrice)
                    }
                } else if (idx == 4) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.preloBalanceUsed.asPrice)
                    }
                } else if (idx == 5) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.voucherAmount.asPrice)
                    }
                } else if (idx == 6) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.totalPrice.asPrice)
                    }
                } else if (idx == 7) {
                    if (isTrxDetail()) {
                        //return TransactionDetailTitleContentCell.heightFor(trxDetail!.bankTransferDigit.asPrice)
                        var title = ""
                        var content = ""
                        if (trxDetail!.paymentMethodInt == 1) {
                            title = "Charge Kartu Kredit"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 4) {
                            title = "Charge Indomaret"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 5) {
                            title = "Charge Kredivo"
                            content = trxDetail!.kredivoChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 6) {
                            title = "Charge Mandiri Clickpay"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 7) {
                            title = "Charge Mandiri e-cash"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 8) {
                            title = "Charge CIMB Clicks"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 9) {
                            title = "Charge Virtual Account"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else {
                            title = "Kode Unik"
                            content = trxDetail!.bankTransferDigit.asPrice
                        }
                        return TransactionDetailTitleContentCell.heightFor(title, content: content)
                    }
                } else if (idx == 8) {
                    if (isTrxDetail()) {
                        let p = trxDetail!.totalPrice + trxDetail!.bankTransferDigit
                        return TransactionDetailTitleContentCell.heightFor(p.asPrice)
                    }
                }
                
                // Bank Transfer
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidTransfer) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentMethod)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentMethod)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentDate)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    }
                } else if (idx == 2) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentBankTarget)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentBankTarget)
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentNominal.asPrice)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentNominal.asPrice)
                    }
                }
                
                // Cedit Card
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidCC) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentMethod)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentMethod)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentDate)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    }
                } else if (idx == 2) {
                    if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor("**** **** **** \(trxProductDetail!.maskedCCLast)")
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentNominal.asPrice)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentNominal.asPrice)
                    }
                }
                
                // Bonus
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidBonus) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentBankSource)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentBankSource)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentDate)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    }
                }
                
                // Indomaret
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidIndomaret) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentMethod)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentMethod)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentDate)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    }
                } else if (idx == 2) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentCode)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentCode)
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentNominal.asPrice)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentNominal.asPrice)
                    }
                }
                
                // Kredivo
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidKredivo) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentMethod)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentMethod)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentDate)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    }
                } else if (idx == 2) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentCode)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentCode)
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentNominal.asPrice)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentNominal.asPrice)
                    }
                }
                
                // CIMB Clicks
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidCimbClicks) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentMethod)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentMethod)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentDate)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    }
                } else if (idx == 2) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentCode)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentCode)
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentNominal.asPrice)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentNominal.asPrice)
                    }
                }
                
                // Mandiri Clickpay
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidMandiriClickpay) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentMethod)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentMethod)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentDate)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    }
                } else if (idx == 2) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentCode)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentCode)
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentNominal.asPrice)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentNominal.asPrice)
                    }
                }
                
                // Mandiri Ecash
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidMandiriEcash) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentMethod)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentMethod)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentDate)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    }
                } else if (idx == 2) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentCode)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentCode)
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentNominal.asPrice)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentNominal.asPrice)
                    }
                }
                
                // Permata VA
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidPermataVa) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentMethod)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentMethod)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentDate)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    }
                } else if (idx == 2) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentCode)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentCode)
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentNominal.asPrice)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentNominal.asPrice)
                    }
                }
                
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranSeller) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentMethod)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentMethod)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.paymentDate)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    }
                }
                
            } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanBuyer) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingRecipientName)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingRecipientName)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingRecipientPhone)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingRecipientPhone)
                    }
                } else if (idx == 2) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingAddress)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingAddress)
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingSubdistrictName)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingSubdistrictName)
                    }
                } else if (idx == 4) {
                    if (isTrxDetail()) {
                        if let r = CDRegion.getRegionNameWithID(trxDetail!.shippingRegionId) {
                            return TransactionDetailTitleContentCell.heightFor(r)
                        }
                    } else if (isTrxProductDetail()) {
                        if let r = CDRegion.getRegionNameWithID(trxProductDetail!.shippingRegionId) {
                            return TransactionDetailTitleContentCell.heightFor(r)
                        }
                    }
                } else if (idx == 5) {
                    if (isTrxDetail()) {
                        if let p = CDProvince.getProvinceNameWithID(trxDetail!.shippingProvinceId) {
                            return TransactionDetailTitleContentCell.heightFor(p)
                        }
                    } else if (isTrxProductDetail()) {
                        if let p = CDProvince.getProvinceNameWithID(trxProductDetail!.shippingProvinceId) {
                            return TransactionDetailTitleContentCell.heightFor(p)
                        }
                    }
                } else if (idx == 6) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingPostalCode)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingPostalCode)
                    }
                } else if (idx == 7) {
//                    if (isTrxDetail()) {
//                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingName)
//                    } else if (isTrxProductDetail()) {
//                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingName)
//                    }
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingName
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingName
                    }
                    if let img = TransactionDetailTools.ImgCouriers[content.components(separatedBy: " ")[0].lowercased()] {
                        return TransactionDetailTitleContentCell.heightFor(content, image: img!)
                    } else {
                        return TransactionDetailTitleContentCell.heightFor(content)
                    }
                } else if (idx == 8) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.resiNumber)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.resiNumber)
                    }
                } else if (idx == 9) {
                    return TransactionDetailTitleContentCell.heightFor("Lihat foto resiœ")
                } else if (idx == 10) {
                    if (isTrxDetail()) {
                        if let msg = trxDetail!.shipHistoryMsg {
                            return TransactionDetailTitleContentHeaderCell.heightFor(msg)
                        } else {
                            return TransactionDetailTitleContentHeaderCell.DefaultCellHeight
                        }
                    } else if (isTrxProductDetail()) {
                        if let msg = trxProductDetail!.shipHistoryMsg {
                            return TransactionDetailTitleContentHeaderCell.heightFor(msg)
                        } else {
                            return TransactionDetailTitleContentHeaderCell.DefaultCellHeight
                        }
                    }
                } else if (idx > 10) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shipHistory[idx - 11].date, content: trxDetail!.shipHistory[idx - 11].status)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shipHistory[idx - 11].date, content: trxProductDetail!.shipHistory[idx - 11].status)
                    }
                }
                
            } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanSeller) {
                if (idx == 0) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingRecipientName)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingRecipientName)
                    }
                } else if (idx == 1) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingRecipientPhone)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingRecipientPhone)
                    }
                } else if (idx == 2) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingAddress)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingAddress)
                    }
                } else if (idx == 3) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingSubdistrictName)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingSubdistrictName)
                    }
                } else if (idx == 4) {
                    if (isTrxDetail()) {
                        if let r = CDRegion.getRegionNameWithID(trxDetail!.shippingRegionId) {
                            return TransactionDetailTitleContentCell.heightFor(r)
                        }
                    } else if (isTrxProductDetail()) {
                        if let r = CDRegion.getRegionNameWithID(trxProductDetail!.shippingRegionId) {
                            return TransactionDetailTitleContentCell.heightFor(r)
                        }
                    }
                } else if (idx == 5) {
                    if (isTrxDetail()) {
                        if let p = CDProvince.getProvinceNameWithID(trxDetail!.shippingProvinceId) {
                            return TransactionDetailTitleContentCell.heightFor(p)
                        }
                    } else if (isTrxProductDetail()) {
                        if let p = CDProvince.getProvinceNameWithID(trxProductDetail!.shippingProvinceId) {
                            return TransactionDetailTitleContentCell.heightFor(p)
                        }
                    }
                } else if (idx == 6) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shippingPostalCode)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shippingPostalCode)
                    }
                } else if (idx == 7) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.requestCourier
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.requestCourier
                    }
                    var image = UIImage()
                    if let img = TransactionDetailTools.ImgCouriers[content.components(separatedBy: " ")[0].lowercased()] {
                        image = img!
                    }
                    return TransactionDetailTitleContentCell.heightFor(content, image: image)
                } else if (idx == 8) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.resiNumber)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.resiNumber)
                    }
                } else if (idx == 9) {
                    return TransactionDetailTitleContentCell.heightFor("Lihat foto resiœ")
                } else if (idx == 10) {
                    if (isTrxDetail()) {
                        if let msg = trxDetail!.shipHistoryMsg {
                            return TransactionDetailTitleContentHeaderCell.heightFor(msg)
                        } else {
                            return TransactionDetailTitleContentHeaderCell.DefaultCellHeight
                        }
                    } else if (isTrxProductDetail()) {
                        if let msg = trxProductDetail!.shipHistoryMsg {
                            return TransactionDetailTitleContentHeaderCell.heightFor(msg)
                        } else {
                            return TransactionDetailTitleContentHeaderCell.DefaultCellHeight
                        }
                    }
                } else if (idx > 10) {
                    if (isTrxDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxDetail!.shipHistory[idx - 11].date, content: trxDetail!.shipHistory[idx - 11].status)
                    } else if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.shipHistory[idx - 11].date, content: trxProductDetail!.shipHistory[idx - 11].status)
                    }
                }
                
            } else if (titleContentType == TransactionDetailTools.TitleContentReimburse) {
                if (idx == 0) {
                    if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.myPreloBalance.asPrice)
                    }
                } else if (idx == 1) {
                    if (isTrxProductDetail()) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.myPreloBonus.asPrice)
                    }
                }
                
            } else if (titleContentType == TransactionDetailTools.TitleContentReserved) {
                if (isTrxProductDetail()) {
                    if (idx == 0) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.garageSalePlace)
                    } else if (idx == 1) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.garageSaleEventDate)
                    } else if (idx == 2) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.garageSaleEventTime)
                    }
                }
                
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranReservasi) {
                if (isTrxProductDetail()) {
                    if (idx == 0) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentMethod)
                    } else if (idx == 1) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentDate)
                    } else if (idx == 2) {
                        return TransactionDetailTitleContentCell.heightFor(trxProductDetail!.paymentNominal.asPrice)
                    }
                }
            }
            
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (isProductCell) {
            let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailProductCellId) as! TransactionDetailProductCell
            
            // Adapt cell
            cell.adapt(trxProducts[(indexPath as NSIndexPath).row])
            if ((indexPath as NSIndexPath).row == trxProducts.count - 1) {
                cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, CGFloat.greatestFiniteMagnitude)
            }
            
            // Configure actions
            cell.switchDetail = {
                self.switchDetailProduct((indexPath as NSIndexPath).row)
            }
            return cell
        } else if (isTitleContentCell) {
            let idx = (indexPath as NSIndexPath).row
            
            if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyer) {
                if (idx == 0) {
                    if (trxDetail!.paymentMethodInt == 7) {
                        return self.createTitleContentCell("", content: "Pembayaran melalui Mandiri e-cash harus diselesaikan di website Mandiri. Pastikan kamu telah mendaftarkan nomor ponsel untuk Mandiri e-cash.", alignment: .left, url: nil, textToCopy: nil)
                    } else if (trxDetail!.paymentMethodInt == 8) {
                        return self.createTitleContentCell("", content: "Pembayaran melalui CIMB Clicks harus diselesaikan di website CIMB Clicks. Pastikan kamu telah memiliki User ID CIMB Clicks dan sudah mendaftarkan mPIN sebelum melakukan pembayaran.", alignment: .left, url: nil, textToCopy: nil)
                    } else if (trxDetail!.paymentMethodInt == 9) {
                        return self.createTitleContentCell("", content: "Pembayaran dapat dilakukan melalui jaringan ATM dan internet banking bank Permata atau bank lain yang tergabung dalam jaringan ATM Bersama, Prima, atau Alto. Cek e-mail untuk instruksi pembayaran melalui virtual account yang lebih jelas.", alignment: .left, url: nil, textToCopy: nil)
                    }
                } else if (idx == 1) {
                    if (trxDetail!.paymentMethodInt == 4) {
                        if (trxDetail!.paymentCode != "") {
                            var content = ""
                            var textToCopy = ""
                            content = " "
                            if (isTrxDetail()) {
                                let p = trxDetail!.paymentCode
                                textToCopy = "\(p)"
                                content += p
                            }
                            return self.createTitleContentCell("Kode Bayar", content: content, alignment: .right, url: nil, textToCopy: textToCopy)
                        } else {
                            return self.createTitleContentCell("Kode Bayar", content: "Klik tombol \"LANJUTKAN PEMBAYARAN\" untuk mendapatkan kode bayar", alignment: .right, url: nil, textToCopy: nil)
                        }
                    } else if (trxDetail!.paymentMethodInt == 9) {
                        if (trxDetail!.vaNumber != "") {
                            var content = ""
                            var textToCopy = ""
                            content = " "
                            if (isTrxDetail()) {
                                let p = trxDetail!.vaNumber
                                textToCopy = "\(p)"
                                content += p
                            }
                            return self.createTitleContentCell("VA Number", content: content, alignment: .right, url: nil, textToCopy: textToCopy)
                        } else {
                            return self.createTitleContentCell("VA Number", content: "Klik tombol \"LANJUTKAN PEMBAYARAN\" untuk mendapatkan VA number", alignment: .right, url: nil, textToCopy: nil)
                        }
                    }
                } else if (idx == 2) {
                    var content = ""
                    if (isTrxDetail()) {
                        let p = trxDetail!.totalPrice + trxDetail!.bonusUsed + trxDetail!.preloBalanceUsed + trxDetail!.voucherAmount
                        content = p.asPrice
                    }
                    return self.createTitleContentCell("Harga + Ongkir", content: content, alignment: .right, url: nil, textToCopy: nil)
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = "-" + trxDetail!.bonusUsed.asPrice
                    }
                    return self.createTitleContentCell("Referral Bonus", content: content, alignment: .right, url: nil, textToCopy: nil)
                } else if (idx == 4) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = "-" + trxDetail!.preloBalanceUsed.asPrice
                    }
                    let cell = self.createTitleContentCell("Prelo Balance", content: content, alignment: .right, url: nil, textToCopy: nil)
                    return cell
                } else if (idx == 5) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = "-" + trxDetail!.voucherAmount.asPrice
                    }
                    let cell = self.createTitleContentCell("Voucher", content: content, alignment: .right, url: nil, textToCopy: nil)
                    cell.showVwLine()
                    return cell
                } else if (idx == 6) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.totalPrice.asPrice
                    }
                    return self.createTitleContentCell("Subtotal", content: content, alignment: .right, url: nil, textToCopy: nil)
                } else if (idx == 7) {
                    var title = ""
                    var content = ""
                    if (isTrxDetail()) {
                        if (trxDetail!.paymentMethodInt == 1) {
                            title = "Charge Kartu Kredit"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 4) {
                            title = "Charge Indomaret"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 5) {
                            title = "Charge Kredivo"
                            content = trxDetail!.kredivoChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 6) {
                            title = "Charge Mandiri Clickpay"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 7) {
                            title = "Charge Mandiri e-cash"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 8) {
                            title = "Charge CIMB Clicks"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else if (trxDetail!.paymentMethodInt == 9) {
                            title = "Charge Virtual Account"
                            content = trxDetail!.veritransChargeAmount.asPrice
                        } else {
                            title = "Kode Unik"
                            content = trxDetail!.bankTransferDigit.asPrice
                        }
                    }
                    let cell = self.createTitleContentCell(title, content: content, alignment: .right, url: nil, textToCopy: nil)
                    cell.showVwLine()
                    return cell
                } else if (idx == 8) {
                    var content = ""
                    var textToCopy = ""
                    content = " "
                    if (isTrxDetail()) {
                        var p = trxDetail!.totalPrice
                        if (trxDetail!.paymentMethodInt == 1) {
                            p += trxDetail!.veritransChargeAmount
                        } else if (trxDetail!.paymentMethodInt == 4) {
                            p += trxDetail!.veritransChargeAmount
                        } else if (trxDetail!.paymentMethodInt == 5) {
                            p += trxDetail!.kredivoChargeAmount
                        } else if (trxDetail!.paymentMethodInt == 6) {
                            p += trxDetail!.veritransChargeAmount
                        } else if (trxDetail!.paymentMethodInt == 7) {
                            p += trxDetail!.veritransChargeAmount
                        } else if (trxDetail!.paymentMethodInt == 8) {
                            p += trxDetail!.veritransChargeAmount
                        } else if (trxDetail!.paymentMethodInt == 9) {
                            p += trxDetail!.veritransChargeAmount
                        } else {
                            p += trxDetail!.bankTransferDigit
                        }
                        textToCopy = "\(p)"
                        content += p.asPrice
                    }
                    return self.createTitleContentCell("Total Pembayaran", content: content, alignment: .right, url: nil, textToCopy: textToCopy)
                }
                
                // Bank Transfer
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidTransfer) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentMethod
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentMethod
                    }
                    return self.createTitleContentCell("Metode", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentDate
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentDate
                    }
                    return self.createTitleContentCell("Tanggal", content: content)
                } else if (idx == 2) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentBankTarget
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentBankTarget
                    }
                    return self.createTitleContentCell("Bank Tujuan", content: content)
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentNominal.asPrice
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentNominal.asPrice
                    }
                    return self.createTitleContentCell("Nominal", content: content)
                }
                
                // Credit Card
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidCC) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentMethod
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentMethod
                    }
                    return self.createTitleContentCell("Metode", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentDate
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentDate
                    }
                    return self.createTitleContentCell("Tanggal", content: content)
                } else if (idx == 2) {
                    if (isTrxProductDetail()) {
                        return self.createTitleContentCell("Nomor Kartu", content: "**** **** **** \(trxProductDetail!.maskedCCLast)")
                    }
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentNominal.asPrice
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentNominal.asPrice
                    }
                    return self.createTitleContentCell("Nominal", content: content)
                }
                
                // Bonus
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidBonus) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentBankSource
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentBankSource
                    }
                    return self.createTitleContentCell("Metode", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentDate
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentDate
                    }
                    return self.createTitleContentCell("Tanggal", content: content)
                }
                
                // Indomaret
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidIndomaret) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentMethod
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentMethod
                    }
                    return self.createTitleContentCell("Metode", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentDate
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentDate
                    }
                    return self.createTitleContentCell("Tanggal", content: content)
                } else if (idx == 2) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentCode
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentCode
                    }
                    return self.createTitleContentCell("Kode", content: content)
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentNominal.asPrice
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentNominal.asPrice
                    }
                    return self.createTitleContentCell("Nominal", content: content)
                }
                
                // Kredivo
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidKredivo) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentMethod
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentMethod
                    }
                    return self.createTitleContentCell("Metode", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentDate
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentDate
                    }
                    return self.createTitleContentCell("Tanggal", content: content)
                } else if (idx == 2) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentType
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentType
                    }
                    return self.createTitleContentCell("Tipe", content: content)
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentNominal.asPrice
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentNominal.asPrice
                    }
                    return self.createTitleContentCell("Nominal", content: content)
                }
                
                // CIMB Clicks
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidCimbClicks) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentMethod
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentMethod
                    }
                    return self.createTitleContentCell("Metode", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentDate
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentDate
                    }
                    return self.createTitleContentCell("Tanggal", content: content)
                } else if (idx == 2) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentCode
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentCode
                    }
                    return self.createTitleContentCell("Kode", content: content)
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentNominal.asPrice
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentNominal.asPrice
                    }
                    return self.createTitleContentCell("Nominal", content: content)
                }
                
                // Mandiri Clickpay
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidMandiriClickpay) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentMethod
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentMethod
                    }
                    return self.createTitleContentCell("Metode", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentDate
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentDate
                    }
                    return self.createTitleContentCell("Tanggal", content: content)
                } else if (idx == 2) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentCode
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentCode
                    }
                    return self.createTitleContentCell("Kode", content: content)
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentNominal.asPrice
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentNominal.asPrice
                    }
                    return self.createTitleContentCell("Nominal", content: content)
                }
                
                // Mandiri Ecash
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidMandiriEcash) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentMethod
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentMethod
                    }
                    return self.createTitleContentCell("Metode", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentDate
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentDate
                    }
                    return self.createTitleContentCell("Tanggal", content: content)
                } else if (idx == 2) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentCode
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentCode
                    }
                    return self.createTitleContentCell("Kode", content: content)
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentNominal.asPrice
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentNominal.asPrice
                    }
                    return self.createTitleContentCell("Nominal", content: content)
                }
                
                // Permata VA
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyerPaidPermataVa) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentMethod
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentMethod
                    }
                    return self.createTitleContentCell("Metode", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentDate
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentDate
                    }
                    return self.createTitleContentCell("Tanggal", content: content)
                } else if (idx == 2) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentCode
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentCode
                    }
                    return self.createTitleContentCell("Kode", content: content)
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentNominal.asPrice
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentNominal.asPrice
                    }
                    return self.createTitleContentCell("Nominal", content: content)
                }
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranSeller) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentMethod
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentMethod
                    }
                    return self.createTitleContentCell("Metode", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentDate
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentDate
                    }
                    return self.createTitleContentCell("Tanggal", content: content)
                }
            } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanBuyer) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingRecipientName
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingRecipientName
                    }
                    return self.createTitleContentCell("Nama", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingRecipientPhone
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingRecipientPhone
                    }
                    return self.createTitleContentCell("Nomor Telepon", content: content)
                } else if (idx == 2) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingAddress
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingAddress
                    }
                    return self.createTitleContentCell("Alamat", content: content)
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingSubdistrictName
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingSubdistrictName
                    }
                    return self.createTitleContentCell("Kecamatan", content: content)
                } else if (idx == 4) {
                    var content = ""
                    if (isTrxDetail()) {
                        if let r = CDRegion.getRegionNameWithID(trxDetail!.shippingRegionId) {
                            content = r
                        }
                    } else if (isTrxProductDetail()) {
                        if let r = CDRegion.getRegionNameWithID(trxProductDetail!.shippingRegionId) {
                            content = r
                        }
                    }
                    return self.createTitleContentCell("Kota", content: content)
                } else if (idx == 5) {
                    var content = ""
                    if (isTrxDetail()) {
                        if let p = CDProvince.getProvinceNameWithID(trxDetail!.shippingProvinceId) {
                            content = p
                        }
                    } else if (isTrxProductDetail()) {
                        if let p = CDProvince.getProvinceNameWithID(trxProductDetail!.shippingProvinceId) {
                            content = p
                        }
                    }
                    return self.createTitleContentCell("Provinsi", content: content)
                } else if (idx == 6) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingPostalCode
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingPostalCode
                    }
                    return self.createTitleContentCell("Kode Pos", content: content)
                } else if (idx == 7) {
                    var title = "Kurir"
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingName
                        if trxDetail!.progress == TransactionDetailTools.ProgressClaimedPaid {
                            title = "Request Kurir"
                        }
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingName
                        if trxProductDetail!.progress == TransactionDetailTools.ProgressClaimedPaid {
                            title = "Request Kurir"
                        }
                    }
                    
                    if let img = TransactionDetailTools.ImgCouriers[content.components(separatedBy: " ")[0].lowercased()] {
                        return self.createTitleContentCell(title, content: content, image: img!)
                    } else {
                        return self.createTitleContentCell(title, content: content)
                    }
                } else if (idx == 8) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.resiNumber
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.resiNumber
                    }
                    if (content != "") {
                        return self.createTitleContentCell("Nomor Resi", content: content + " ", alignment: nil, url: nil, textToCopy: content)
//                        return self.createTitleContentCell("Nomor Resi", content: content)
                    }
                } else if (idx == 9) {
                    var content = "Lihat foto resiœ"
                    if (isTrxDetail()) {
                        content += trxDetail!.resiPhotoUrl
                    } else if (isTrxProductDetail()) {
                        content += trxProductDetail!.resiPhotoUrl
                    }
                    var nrcontent = ""
                    if (isTrxDetail()) {
                        nrcontent = trxDetail!.resiNumber
                    } else if (isTrxProductDetail()) {
                        nrcontent = trxProductDetail!.resiNumber
                    }
                    if (nrcontent != "") {
                        return self.createTitleContentCell("", content: content)
                    }
                } else if (idx == 10) {
                    var msg : String?
                    if (isTrxDetail()) {
                        msg = trxDetail!.shipHistoryMsg
                    } else if (isTrxProductDetail()) {
                        msg = trxProductDetail!.shipHistoryMsg
                    }
                    return self.createTitleContentHeaderCellShipHistory(msg)
                } else if (idx > 10) {
                    var date = ""
                    var status = ""
                    if (isTrxDetail()) {
                        date = trxDetail!.shipHistory[idx - 11].date
                        status = trxDetail!.shipHistory[idx - 11].status
                    } else if (isTrxProductDetail()) {
                        date = trxProductDetail!.shipHistory[idx - 11].date
                        status = trxProductDetail!.shipHistory[idx - 11].status
                    }
                    return self.createTitleContentCellShipHistory(date, status: status)
                }
            } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanSeller) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingRecipientName
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingRecipientName
                    }
                    return self.createTitleContentCell("Nama", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingRecipientPhone
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingRecipientPhone
                    }
                    return self.createTitleContentCell("Nomor Telepon", content: content)
                } else if (idx == 2) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingAddress
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingAddress
                    }
                    return self.createTitleContentCell("Alamat", content: content)
                } else if (idx == 3) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingSubdistrictName
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingSubdistrictName
                    }
                    return self.createTitleContentCell("Kecamatan", content: content)
                } else if (idx == 4) {
                    var content = ""
                    if (isTrxDetail()) {
                        if let r = CDRegion.getRegionNameWithID(trxDetail!.shippingRegionId) {
                            content = r
                        }
                    } else if (isTrxProductDetail()) {
                        if let r = CDRegion.getRegionNameWithID(trxProductDetail!.shippingRegionId) {
                            content = r
                        }
                    }
                    return self.createTitleContentCell("Kota", content: content)
                } else if (idx == 5) {
                    var content = ""
                    if (isTrxDetail()) {
                        if let p = CDProvince.getProvinceNameWithID(trxDetail!.shippingProvinceId) {
                            content = p
                        }
                    } else if (isTrxProductDetail()) {
                        if let p = CDProvince.getProvinceNameWithID(trxProductDetail!.shippingProvinceId) {
                            content = p
                        }
                    }
                    return self.createTitleContentCell("Provinsi", content: content)
                } else if (idx == 6) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingPostalCode
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingPostalCode
                    }
                    return self.createTitleContentCell("Kode Pos", content: content)
                } else if (idx == 7) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.requestCourier
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.requestCourier
                    }
                    
                    if let img = TransactionDetailTools.ImgCouriers[content.components(separatedBy: " ")[0].lowercased()] {
                        return self.createTitleContentCell("Kurir", content: content, image: img!)
                    } else {
                        return self.createTitleContentCell("Kurir", content: content) // (content.contains("Free Ongkir") ? "" : content)
                    }
                } else if (idx == 8) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.resiNumber
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.resiNumber
                    }
                    if (content != "") {
//                        return self.createTitleContentCell("Nomor Resi", content: content)
                        return self.createTitleContentCell("Nomor Resi", content: content + " ", alignment: nil, url: nil, textToCopy: content)
                    }
                } else if (idx == 9) {
                    var content = "Lihat foto resiœ"
                    if (isTrxDetail()) {
                        content += trxDetail!.resiPhotoUrl
                    } else if (isTrxProductDetail()) {
                        content += trxProductDetail!.resiPhotoUrl
                    }
                    var nrcontent = ""
                    if (isTrxDetail()) {
                        nrcontent = trxDetail!.resiNumber
                    } else if (isTrxProductDetail()) {
                        nrcontent = trxProductDetail!.resiNumber
                    }
                    if (nrcontent != "") {
                        return self.createTitleContentCell("", content: content)
                    }
                } else if (idx == 10) {
                    var msg : String?
                    if (isTrxDetail()) {
                        msg = trxDetail!.shipHistoryMsg
                    } else if (isTrxProductDetail()) {
                        msg = trxProductDetail!.shipHistoryMsg
                    }
                    return self.createTitleContentHeaderCellShipHistory(msg)
                } else if (idx > 10) {
                    var date = ""
                    var status = ""
                    if (isTrxDetail()) {
                        date = trxDetail!.shipHistory[idx - 11].date
                        status = trxDetail!.shipHistory[idx - 11].status
                    } else if (isTrxProductDetail()) {
                        date = trxProductDetail!.shipHistory[idx - 11].date
                        status = trxProductDetail!.shipHistory[idx - 11].status
                    }
                    return self.createTitleContentCellShipHistory(date, status: status)
                }
            } else if (titleContentType == TransactionDetailTools.TitleContentReimburse) {
                if (idx == 0) {
                    var content = ""
                    if (isTrxProductDetail()) {
                        content = trxProductDetail!.myPreloBalance.asPrice
                    }
                    return self.createTitleContentCell("Prelo Balance", content: content)
                } else if (idx == 1) {
                    var content = ""
                    if (isTrxProductDetail()) {
                        content = trxProductDetail!.myPreloBonus.asPrice
                    }
                    return self.createTitleContentCell("Referral Bonus", content: content)
                }
            } else if (titleContentType == TransactionDetailTools.TitleContentReserved) {
                if (isTrxProductDetail()) {
                    if (idx == 0) {
                        return self.createTitleContentCell("Tempat", content: trxProductDetail!.garageSalePlace, alignment: nil, url: trxProductDetail!.garageSaleMapsUrl, textToCopy: nil)
                    } else if (idx == 1) {
                        return self.createTitleContentCell("Tanggal", content: trxProductDetail!.garageSaleEventDate)
                    } else if (idx == 2) {
                        return self.createTitleContentCell("Waktu", content: trxProductDetail!.garageSaleEventTime)
                    }
                }
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranReservasi) {
                if (isTrxProductDetail()) {
                    if (idx == 0) {
                        return self.createTitleContentCell("Metode", content: trxProductDetail!.paymentMethod)
                    } else if (idx == 1) {
                        return self.createTitleContentCell("Tanggal", content: trxProductDetail!.paymentDate)
                    } else if (idx == 2) {
                        return self.createTitleContentCell("Nominal", content: trxProductDetail!.paymentNominal.asPrice)
                    }
                }
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let idx = (indexPath as NSIndexPath).row
        if (isProductCell) {
            self.toProductDetail(trxProducts[idx].productId)
        } else if (isTitleContentCell) {
            if let cell = tableView.cellForRow(at: indexPath) as? TransactionDetailTitleContentCell {
                if (cell.tapUrl != "") {
                    if let url = URL(string: cell.tapUrl) {
                        UIApplication.shared.openURL(url)
                    }
                } else if (cell.textToCopy != "") {
                    UIPasteboard.general.string = cell.textToCopy
                    Constant.showDialog("Copied!", message: "\(cell.lblTitle.text!) telah disalin ke clipboard")
                }
            }
        }
    }
    
    // MARK: - Cell creation
    
    func createTitleContentCell(_ title : String, content : String, alignment : NSTextAlignment?, url : String?, textToCopy : String?) -> TransactionDetailTitleContentCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailTitleContentCellId) as! TransactionDetailTitleContentCell
        
        // Adapt cell
        cell.adapt(title, content: content, alignment: alignment, url: url, textToCopy: textToCopy)
        
        return cell
    }
    
    func createTitleContentCell(_ title : String, content : String) -> TransactionDetailTitleContentCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailTitleContentCellId) as! TransactionDetailTitleContentCell
        
        // Adapt cell
        cell.adapt(title, content: content)
        
        cell.root = self.root!
        
        return cell
    }
    
    func createTitleContentCell(_ title : String, content : String, image : UIImage) -> TransactionDetailTitleContentCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailTitleContentCellId) as! TransactionDetailTitleContentCell
        
        // Adapt cell
        cell.adapt(title, content: content, image: image)
        
        return cell
    }
    
    func createTitleContentCellShipHistory(_ date : String, status : String) -> TransactionDetailTitleContentCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailTitleContentCellId) as! TransactionDetailTitleContentCell
        
        // Adapt cell
        cell.adaptShipHistory(date, status: status)
        
        return cell
    }
    
    func createTitleContentHeaderCellShipHistory(_ msg : String?) -> TransactionDetailTitleContentHeaderCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailTitleContentHeaderCellId) as! TransactionDetailTitleContentHeaderCell
        
        // Adapt cell
        cell.adaptShipHistory(msg)
        
        return cell
    }
    
    // MARK: - Other functions
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
    
    func isTrxDetail() -> Bool {
        return (trxDetail != nil)
    }
    
    func isTrxProductDetail() -> Bool {
        return (trxProductDetail != nil)
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
    @IBOutlet var lblDetail: UILabel?
    @IBOutlet var lblDetailIcon: UILabel?
    @IBOutlet var lblHasilPenjualan: UILabel?
    @IBOutlet var lblOngkosKirim: UILabel?
    @IBOutlet var lblPrice2: UILabel?
    @IBOutlet var consWidthLblDetail: NSLayoutConstraint?
    @IBOutlet var consWidthLblDetailIcon: NSLayoutConstraint?
    
    var imgVwIcon : UIImageView?
    var switchDetail : () -> () = {}
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
//        imgProduct.image = UIImage(named: "raisa.jpg")
        imgProduct.afCancelRequest()
        imgVwIcon?.removeFromSuperview()
        vwTransactionStatus.backgroundColor = Theme.GrayDark
        lblTransactionStatus.textColor = Theme.GrayDark
    }
    
    func adapt(_ trxProductDetail : TransactionProductDetail) {
        // Set image
        if let url = trxProductDetail.productImageURL {
            imgProduct.afSetImage(withURL: url)
        }
        
        // Set text
        lblOrderId.text = "Order ID " + trxProductDetail.orderId
        lblTime.text = "| " + trxProductDetail.time
        lblProductName.text = trxProductDetail.productName
        lblPrice2?.text = "\(trxProductDetail.totalPrice - trxProductDetail.commissionPrice)"
        lblHasilPenjualan?.text = "\(trxProductDetail.productPrice - trxProductDetail.commissionPrice)"
        lblOngkosKirim?.text = "\(trxProductDetail.totalPrice - trxProductDetail.productPrice)"
        lblTransactionStatus.text = trxProductDetail.progressText.uppercased()
        if let userId = User.Id {
            if (trxProductDetail.isSeller(userId)) {
                lblPrice.text = trxProductDetail.productPrice.asPrice
                lblUsername.text = "| " + trxProductDetail.buyerUsername
            } else {
                lblPrice.text = trxProductDetail.productPrice.asPrice
                lblUsername.text = "(+Ongkir Rp\(trxProductDetail.totalPrice - trxProductDetail.productPrice))"
            }
        }
        
        // Set color
        if (trxProductDetail.progress < 0) {
            vwTransactionStatus.backgroundColor = Theme.ThemeRed
            lblTransactionStatus.textColor = Theme.ThemeRed
        } else if (TransactionDetailTools.isRefundProgress(trxProductDetail.progress)) {
            vwTransactionStatus.backgroundColor = Theme.ThemeRed
            lblTransactionStatus.textColor = Theme.ThemeRed
        } else if let userId = User.Id {
            if (trxProductDetail.isSeller(userId)) {
                vwTransactionStatus.backgroundColor = Theme.ThemeOrange
                lblTransactionStatus.textColor = Theme.ThemeOrange
            } else {
                vwTransactionStatus.backgroundColor = Theme.PrimaryColor
                lblTransactionStatus.textColor = Theme.PrimaryColor
            }
        }
        
        // Fix text width
        let fitSizeLblOrderId = lblOrderId.sizeThatFits(lblOrderId.frame.size)
        consWidthLblOrderId.constant = fitSizeLblOrderId.width
        let fitSizeLblPrice = lblPrice.sizeThatFits(lblPrice.frame.size)
        consWidthLblPrice.constant = fitSizeLblPrice.width
        
        // Set icon
        vwTransactionStatus.layoutIfNeeded()
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
        } else if (progress == TransactionDetailTools.ProgressReserved) {
            imgName = "ic_trx_reserved"
        } else if (progress == TransactionDetailTools.ProgressReserveDone) {
            imgName = "ic_trx_reservation_done"
        } else if (progress == TransactionDetailTools.ProgressReservationCancelled) {
            imgName = "ic_trx_reservation_cancelled"
        } else if (progress == TransactionDetailTools.ProgressFraudDetected) {
            imgName = "ic_trx_expired"
        } else if (progress == TransactionDetailTools.ProgressRefundRequested) {
            imgName = "ic_trx_refund1"
        } else if (progress == TransactionDetailTools.ProgressRefundVerified) {
            imgName = "ic_trx_refund2"
        } else if (progress == TransactionDetailTools.ProgressRefundSent) {
            imgName = "ic_trx_refund3"
        } else if (progress == TransactionDetailTools.ProgressRefundSuccess) {
            imgName = "ic_trx_refund4"
        }
        if (imgName != nil) {
            if let imgIcon = UIImage(named: imgName!) {
                imgVwIcon = UIImageView(frame: CGRect(x: 5, y: 5, width: 15, height: 15), image: imgIcon)
                vwTransactionStatus.addSubview(imgVwIcon!)
            }
        }
        
        // Set hideable detail
        if let userId = User.Id {
            if (trxProductDetail.isSeller(userId)) {
                consWidthLblDetail?.constant = 38
                consWidthLblDetailIcon?.constant = 26
            } else {
                consWidthLblDetail?.constant = 0
                consWidthLblDetailIcon?.constant = 0
            }
        }
    }
    
    @IBAction func detailPressed(_ sender: AnyObject) {
        if (consWidthLblDetail != nil && consWidthLblDetail!.constant > 0) {
            if (lblDetailIcon?.text == TransactionDetailTools.IcDownArrow) {
                lblDetailIcon?.text = TransactionDetailTools.IcUpArrow
            } else {
                lblDetailIcon?.text = TransactionDetailTools.IcDownArrow
            }
            self.switchDetail()
        }
    }
}

// MARK: - Class

class TransactionDetailDescriptionCell : UITableViewCell {
    @IBOutlet weak var lblDesc: UILabel!
    
    static func heightFor(_ progress : Int?, isSeller : Bool?, order : Int) -> CGFloat {
        if (progress != nil && isSeller != nil) {
            var textRect : CGRect?
            if (progress == TransactionDetailTools.ProgressExpired) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextPembayaranExpiredSeller.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    textRect = TransactionDetailTools.TextPembayaranExpiredBuyer.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
                if (isSeller! == true) {
                    if progress == TransactionDetailTools.ProgressRejectedBySeller {
                        textRect = TransactionDetailTools.TextDikembalikanDitolak.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    } else {
                        textRect = TransactionDetailTools.TextDikembalikanTidakDikirim.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    }
                } else {
                    if (order == 1) {
                        textRect = TransactionDetailTools.TextReimburse1.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    } else if (order == 2) {
                        textRect = TransactionDetailTools.TextReimburse2.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressNotPaid) {
                let text = TransactionDetailTools.TextNotPaid + "dd/MM/yyyy hh:mm:ss. " + ((isSeller! == true) ? TransactionDetailTools.TextNotPaidSeller : TransactionDetailTools.TextNotPaidBuyerTransfer) // Asumsi: TextNotPaidBuyerTransfer & TextNotPaidBuyerVeritrans panjangnya sama
                textRect = text.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin) - 8) // Dikurangin 8 lagi karna ada galat perhitungan
            } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextClaimedPaidSeller.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    textRect = TransactionDetailTools.TextPembayaranExpiredBuyer.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (isSeller! == true) {
                    let text = TransactionDetailTools.TextConfirmedPaidSeller1 + "dd/MM/yyyy hh:mm:ss" + TransactionDetailTools.TextConfirmedPaidSeller2
                    textRect = text.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    let text = TransactionDetailTools.TextConfirmedPaidBuyer1 + "dd/MM/yyyy hh:mm:ss" + TransactionDetailTools.TextConfirmedPaidBuyer2
                    textRect = text.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } /*else if (progress == TransactionDetailTools.ProgressSent) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextSentSeller.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressReceived) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextReceivedSeller.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            }*/ else if (progress == TransactionDetailTools.ProgressReserved) {
                if (order == 1) {
                    textRect = TransactionDetailTools.TextReserved1.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else if (order == 2) {
                    textRect = TransactionDetailTools.TextReserved2.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressReserveDone) {
                textRect = TransactionDetailTools.TextReserveDone.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
            } else if (progress == TransactionDetailTools.ProgressReservationCancelled) {
                textRect = TransactionDetailTools.TextReservationCancelled.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
            } else if (progress == TransactionDetailTools.ProgressFraudDetected) {
                textRect = TransactionDetailTools.TextFraudDetected.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
            } else if (progress == TransactionDetailTools.ProgressRefundRequested) {
                if (isSeller! == false) {
                    textRect = TransactionDetailTools.TextRefundRequestBuyer.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressRefundVerified) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextRefundVerifiedSeller.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    textRect = TransactionDetailTools.TextRefundVerifiedBuyer.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressRefundSent) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextRefundSentSeller.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    textRect = TransactionDetailTools.TextRefundSentBuyer.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressRefundSuccess) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextRefundSuccessSeller.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    if (order == 1) {
                        textRect = TransactionDetailTools.TextRefundSuccessBuyer1.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    } else if (order == 2) {
                        textRect = TransactionDetailTools.TextRefundSuccessBuyer2.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    }
                }
            }
            if (textRect != nil) {
                return textRect!.height + (2 * TransactionDetailTools.Margin)
            }
        }
        return 0
    }
    
    static func heightFor(_ progress : Int?, isSeller : Bool?, order : Int, addText : String) -> CGFloat {
        if (progress != nil && isSeller != nil) {
            var textRect : CGRect?
            if (progress == TransactionDetailTools.ProgressRefundRequested) {
                if (isSeller! == true) {
                    let text = TransactionDetailTools.TextRefundRequestSeller1 + addText + TransactionDetailTools.TextRefundRequestSeller2
                    textRect = text.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            }
            if (textRect != nil) {
                return textRect!.height + (2 * TransactionDetailTools.Margin)
            }
        }
        return 0
    }
    
    static func heightFor(_ progress : Int?, isSeller : Bool?, order : Int, boolParam : Bool) -> CGFloat {
        if (progress != nil && isSeller != nil) {
            var textRect : CGRect?
            if (progress == TransactionDetailTools.ProgressReceived) {
                if (isSeller! == false) {
                    if (boolParam == true) { // In this case, boolParam = isRefundable
                        textRect = TransactionDetailTools.TextReceivedBuyer.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    } else {
                        textRect = TransactionDetailTools.TextReceivedBuyerNoRefund.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    }
                } else {
                    textRect = TransactionDetailTools.TextReceivedSeller.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressSent) {
                if (isSeller! == false) {
                    textRect = TransactionDetailTools.TextSentBuyer.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    /*if (boolParam == true) { // In this case, boolParam = isRefundable
                        textRect = TransactionDetailTools.TextSentBuyer.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    } else {
                        textRect = TransactionDetailTools.TextSentBuyerNoRefund.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                    }*/
                } else {
                    textRect = TransactionDetailTools.TextSentSeller.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            }
            if (textRect != nil) {
                return textRect!.height + (2 * TransactionDetailTools.Margin)
            }
        }
        return 0
    }
    
    // affiliate
    static func heightForAffiliate(_ progress : Int?) -> CGFloat {
        var textRect : CGRect?
        if (progress == TransactionDetailTools.ProgressNotPaid) {
            textRect = TransactionDetailTools.TextAffiliateUnpaid.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
        } else if (progress == TransactionDetailTools.ProgressExpired) {
            textRect = TransactionDetailTools.TextAffiliateExpired.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
        } else if (progress == TransactionDetailTools.ProgressClaimedPaid || progress == TransactionDetailTools.ProgressConfirmedPaid) {
            textRect = TransactionDetailTools.TextAffiliatePaid.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller) {
            textRect = TransactionDetailTools.TextAffiliateReject.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
        } else if (progress == TransactionDetailTools.ProgressReceived) {
            textRect = TransactionDetailTools.TextAffiliateReceived.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
        } else if (progress == TransactionDetailTools.ProgressReviewed) {
            textRect = TransactionDetailTools.TextAffiliateSuccess.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
        } else if (progress == TransactionDetailTools.ProgressSent) {
            textRect = TransactionDetailTools.TextAffiliateSend.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
        }
        
        if (textRect != nil) {
            return textRect!.height + (2 * TransactionDetailTools.Margin)
        }
        return 0
    }
    
    func adapt(_ trxDetail : TransactionDetail) {
        if let userId = User.Id {
            let progress = trxDetail.progress
            let isSeller = !trxDetail.isBuyer(userId)
            if (progress == TransactionDetailTools.ProgressExpired) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextPembayaranExpiredSeller
                } else {
                    lblDesc.text = TransactionDetailTools.TextPembayaranExpiredBuyer
                }
            } else if (progress == TransactionDetailTools.ProgressNotPaid) {
                let expireTime = trxDetail.expireTime + ". "
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextNotPaid + expireTime + TransactionDetailTools.TextNotPaidSeller
                } else {
                    var lastText = ""
                    if (trxDetail.paymentMethodInt == 1 || trxDetail.paymentMethodInt == 4 || trxDetail.paymentMethodInt == 5) {
                        lastText = TransactionDetailTools.TextNotPaidBuyerVeritrans
                    } else {
                        lastText = TransactionDetailTools.TextNotPaidBuyerTransfer
                    }
                    lblDesc.text = TransactionDetailTools.TextNotPaid + expireTime + lastText
                }
            } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextClaimedPaidSeller
                } else {
                    lblDesc.text = TransactionDetailTools.TextClaimedPaidBuyer
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (isSeller) {
                    let expireTime = trxDetail.shippingExpireTime + "). "
                    lblDesc.text = TransactionDetailTools.TextConfirmedPaidSeller1 + expireTime + TransactionDetailTools.TextConfirmedPaidSeller2
                    lblDesc.boldSubstring("3 hari kerja setelah konfirmasi pembayaran")
                    lblDesc.boldSubstring("transaksi akan dibatalkan")
                    lblDesc.boldSubstring("uang akan dikembalikan kepada pembeli")
                }
            } else if (progress == TransactionDetailTools.ProgressFraudDetected) {
                lblDesc.text = TransactionDetailTools.TextFraudDetected
            }
        }
    }
    
    func adapt2(_ trxProductDetail : TransactionProductDetail, order : Int) {
        if let userId = User.Id {
            let progress = trxProductDetail.progress
            let isSeller = trxProductDetail.isSeller(userId)
            if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
                if (isSeller) {
                    if progress == TransactionDetailTools.ProgressRejectedBySeller {
                        lblDesc.text = TransactionDetailTools.TextDikembalikanDitolak
                    } else {
                        lblDesc.text = TransactionDetailTools.TextDikembalikanTidakDikirim
                    }
                } else {
                    if (order == 1) {
                        lblDesc.text = TransactionDetailTools.TextReimburse1
                    } else if (order == 2) {
                        lblDesc.text = TransactionDetailTools.TextReimburse2
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (!isSeller) {
                    let expireTime = trxProductDetail.shippingExpireTime + ". "
                    lblDesc.text = TransactionDetailTools.TextConfirmedPaidBuyer1 + expireTime + TransactionDetailTools.TextConfirmedPaidBuyer2
                }
            } else if (progress == TransactionDetailTools.ProgressSent) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextSentSeller
                } else {
                    lblDesc.text = TransactionDetailTools.TextSentBuyer
                }
                if (lblDesc.text?.contains("1."))! {
                    let fontSize = lblDesc.font.pointSize
                    let attributesDictionary = [NSFontAttributeName : lblDesc.font]
                    let fullAttributedString = NSMutableAttributedString(string: "", attributes: attributesDictionary)
                    
                    // Create a NSCharacterSet of delimiters.
                    let separators = NSCharacterSet(charactersIn: "\n")
                    // Split based on characters.
                    let strings = lblDesc.text?.components(separatedBy: separators as CharacterSet)
                    
                    for string: String in strings!
                    {
                        let formattedString: String = "\(string)\n"
                        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: formattedString)
                        
                        var paragraphStyle: NSMutableParagraphStyle
                        paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 15, options: NSDictionary() as! [String : AnyObject])]
                        paragraphStyle.defaultTabInterval = 15
                        paragraphStyle.firstLineHeadIndent = 0
                        paragraphStyle.headIndent = 15
                        
                        attributedString.addAttributes([NSParagraphStyleAttributeName: paragraphStyle], range: NSMakeRange(0, attributedString.length))
                        
                        let mystr = formattedString
                        let searchstr = "Waktu Jaminan Prelo|Diterima|Laporkan Transaksi|benar-benar sudah diterima"
                        let ranges: [NSRange]
                        
                        do {
                            // Create the regular expression.
                            let regex = try NSRegularExpression(pattern: searchstr, options: [])
                            
                            // Use the regular expression to get an array of NSTextCheckingResult.
                            // Use map to extract the range from each result.
                            ranges = regex.matches(in: mystr, options: [], range: NSMakeRange(0, mystr.characters.count)).map {$0.range}
                        }
                        catch {
                            // There was a problem creating the regular expression
                            ranges = []
                        }
                        
                        for range in ranges {
                            attributedString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: fontSize)], range: range)
                        }
                        attributedString.addAttributes([NSFontAttributeName:UIFont.italicSystemFont(ofSize: fontSize)], range: (formattedString as NSString).range(of: "review"))
                        attributedString.addAttributes([NSFontAttributeName:UIFont.italicSystemFont(ofSize: fontSize)], range: (formattedString as NSString).range(of: "Refund"))
                        
                        fullAttributedString.append(attributedString)
                    }
                    
                    lblDesc.attributedText = fullAttributedString
                } else {
                    lblDesc.boldSubstring("Waktu Jaminan Prelo")
                    lblDesc.boldSubstring("Diterima")
                }
                /*if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextSentSeller
                } else {
                    lblDesc.text = TransactionDetailTools.TextSentBuyer
                    /*if (trxProductDetail.refundable) {
                        lblDesc.text = TransactionDetailTools.TextSentBuyer
                    } else {
                        lblDesc.text = TransactionDetailTools.TextSentBuyerNoRefund
                    }*/
                    
                    lblDesc.boldSubstring("Laporkan Transaksi")
                    lblDesc.boldSubstring("\n1.")
                    lblDesc.boldSubstring("Diterima\n2.")
                    lblDesc.boldSubstring("Diterima\n3.")
                    lblDesc.italicSubstring("review")
                }
                lblDesc.boldSubstring("Waktu Jaminan Prelo")
                lblDesc.boldSubstring("Diterima")*/
            } else if (progress == TransactionDetailTools.ProgressReceived) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextReceivedSeller
                } else {
                    if (trxProductDetail.refundable) {
                        lblDesc.text = TransactionDetailTools.TextReceivedBuyer
                    } else {
                        lblDesc.text = TransactionDetailTools.TextReceivedBuyerNoRefund
                    }
                }
                if (lblDesc.text?.contains("1."))! {
                    let fontSize = lblDesc.font.pointSize
                    let attributesDictionary = [NSFontAttributeName : lblDesc.font]
                    let fullAttributedString = NSMutableAttributedString(string: "", attributes: attributesDictionary)
                    
                    // Create a NSCharacterSet of delimiters.
                    let separators = NSCharacterSet(charactersIn: "\n")
                    // Split based on characters.
                    let strings = lblDesc.text?.components(separatedBy: separators as CharacterSet)
                    
                    for string: String in strings!
                    {
                        let formattedString: String = "\(string)\n"
                        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: formattedString)
                        
                        var paragraphStyle: NSMutableParagraphStyle
                        paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 15, options: NSDictionary() as! [String : AnyObject])]
                        paragraphStyle.defaultTabInterval = 15
                        paragraphStyle.firstLineHeadIndent = 0
                        paragraphStyle.headIndent = 15
                        
                        attributedString.addAttributes([NSParagraphStyleAttributeName: paragraphStyle], range: NSMakeRange(0, attributedString.length))
                        
                        let mystr = formattedString
                        let searchstr = "Waktu Jaminan Prelo|Diterima|Laporkan Transaksi|benar-benar sudah diterima"
                        let ranges: [NSRange]
                        
                        do {
                            // Create the regular expression.
                            let regex = try NSRegularExpression(pattern: searchstr, options: [])
                            
                            // Use the regular expression to get an array of NSTextCheckingResult.
                            // Use map to extract the range from each result.
                            ranges = regex.matches(in: mystr, options: [], range: NSMakeRange(0, mystr.characters.count)).map {$0.range}
                        }
                        catch {
                            // There was a problem creating the regular expression
                            ranges = []
                        }
                        
                        for range in ranges {
                            attributedString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: fontSize)], range: range)
                        }
                        attributedString.addAttributes([NSFontAttributeName:UIFont.italicSystemFont(ofSize: fontSize)], range: (formattedString as NSString).range(of: "review"))
                        attributedString.addAttributes([NSFontAttributeName:UIFont.italicSystemFont(ofSize: fontSize)], range: (formattedString as NSString).range(of: "Refund"))
                        
                        fullAttributedString.append(attributedString)
                    }
                    
                    lblDesc.attributedText = fullAttributedString
                } else {
                    lblDesc.boldSubstring("Waktu Jaminan Prelo")
                }
                /*if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextReceivedSeller
                    
                    lblDesc.boldSubstring("Diterima")
                } else {
                    if (trxProductDetail.refundable) {
                        lblDesc.text = TransactionDetailTools.TextReceivedBuyer
                        
                        lblDesc.boldSubstring("Laporkan Transaksi")
                        lblDesc.boldSubstring("Diterima\n2.")
                        lblDesc.boldSubstring("Diterima\n3.")
                        lblDesc.italicSubstring("review")
                    } else {
                        lblDesc.text = TransactionDetailTools.TextReceivedBuyerNoRefund
                        
                        lblDesc.boldSubstring("\n2.")
                    }
                    lblDesc.boldSubstring("\n1.")
                }
                lblDesc.boldSubstring("Waktu Jaminan Prelo")*/
            } else if (progress == TransactionDetailTools.ProgressReserved) {
                if (order == 1) {
                    lblDesc.text = TransactionDetailTools.TextReserved1
                } else if (order == 2) {
                    lblDesc.text = TransactionDetailTools.TextReserved2
                }
            } else if (progress == TransactionDetailTools.ProgressReserveDone) {
                lblDesc.text = TransactionDetailTools.TextReserveDone
            } else if (progress == TransactionDetailTools.ProgressReservationCancelled) {
                lblDesc.text = TransactionDetailTools.TextReservationCancelled
            } else if (progress == TransactionDetailTools.ProgressRefundRequested) {
                if (isSeller) {
                    let reason = trxProductDetail.refundReasonText
                    lblDesc.text = TransactionDetailTools.TextRefundRequestSeller1 + reason + TransactionDetailTools.TextRefundRequestSeller2
                    lblDesc.boldSubstring(reason)
                } else {
                    lblDesc.text = TransactionDetailTools.TextRefundRequestBuyer
                }
            } else if (progress == TransactionDetailTools.ProgressRefundVerified) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextRefundVerifiedSeller
                } else {
                    lblDesc.text = TransactionDetailTools.TextRefundVerifiedBuyer
                }
            } else if (progress == TransactionDetailTools.ProgressRefundSent) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextRefundSentSeller
                } else {
                    lblDesc.text = TransactionDetailTools.TextRefundSentBuyer
                }
            } else if (progress == TransactionDetailTools.ProgressRefundSuccess) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextRefundSuccessSeller
                } else {
                    if (order == 1) {
                        lblDesc.text = TransactionDetailTools.TextRefundSuccessBuyer1
                    } else if (order == 2) {
                        lblDesc.text = TransactionDetailTools.TextRefundSuccessBuyer2
                    }
                }
            }
        }
    }
    
    // affiliate
    func adaptAffiliate(_ progress : Int) {
        if progress == TransactionDetailTools.ProgressNotPaid {
            lblDesc.text = TransactionDetailTools.TextAffiliateUnpaid
            let teks = TransactionDetailTools.AffiliateBankAccounts[0].bank_name + "\n" + TransactionDetailTools.AffiliateBankAccounts[0].no.replace(" ", template: "") + "\n" + TransactionDetailTools.AffiliateBankAccounts[0].name
            lblDesc.boldSubstring(teks)
        } else if progress == TransactionDetailTools.ProgressExpired {
            lblDesc.text = TransactionDetailTools.TextAffiliateExpired
            lblDesc.italicSubstring("expired")
        } else if progress == TransactionDetailTools.ProgressClaimedPaid || progress == TransactionDetailTools.ProgressConfirmedPaid {
            lblDesc.text = TransactionDetailTools.TextAffiliatePaid
        } else if progress == TransactionDetailTools.ProgressRejectedBySeller {
            lblDesc.text = TransactionDetailTools.TextAffiliateReject
        } else if progress == TransactionDetailTools.ProgressReceived {
            lblDesc.text = TransactionDetailTools.TextAffiliateReceived
            lblDesc.italicSubstring("refund")
        } else if progress == TransactionDetailTools.ProgressReviewed {
            lblDesc.text = TransactionDetailTools.TextAffiliateSuccess
        } else if progress == TransactionDetailTools.ProgressSent {
            lblDesc.text = TransactionDetailTools.TextAffiliateSend
            lblDesc.italicSubstring("refund")
        }
    }
}

// MARK: - Class

class TransactionDetailTitleCell : UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet var lblDetail: UILabel!
    @IBOutlet var lblDetailIcon: UILabel!
    
    var switchDetail : () -> () = {}
    var detailCellIndexes : [Int] = []
    
    var isFroze = false
    
    func adapt(_ title : String, detailCellIndexes : [Int], isOpen : Bool, isFroze : Bool) {
        lblTitle.text = title
        self.detailCellIndexes = detailCellIndexes
        if (detailCellIndexes.count > 0) {
            lblDetail.isHidden = false
            lblDetail.isHidden = false
        } else {
            lblDetail.isHidden = true
            lblDetail.isHidden = true
        }
        
        lblDetailIcon.isHidden = false
        
        if (!isOpen && !isFroze) {
            lblDetailIcon.text = TransactionDetailTools.IcUpArrow
        } else if (isOpen && !isFroze) {
            lblDetailIcon.text = TransactionDetailTools.IcDownArrow
        } else { // is_froze
            lblDetailIcon.text = TransactionDetailTools.IcDownArrow
        }
        
        self.isFroze = isFroze
    }
    
    // affiliate
    func adaptAffiliate(_ title : String) {
        lblTitle.text = title
        lblDetail.isHidden = true
        lblDetailIcon.isHidden = true
    }
    
    @IBAction func detailPressed(_ sender: AnyObject) {
        if !isFroze {
            if (lblDetailIcon.text == TransactionDetailTools.IcDownArrow) {
                lblDetailIcon.text = TransactionDetailTools.IcUpArrow
            } else {
                lblDetailIcon.text = TransactionDetailTools.IcDownArrow
            }
            if (detailCellIndexes.count > 0) {
                self.switchDetail()
            }
        }
    }
}

// MARK: - class oveeride tapgesture
class MyTapGestureRecognizer: UITapGestureRecognizer {
    var headline: String?
}

// MARK: - Class

class TransactionDetailTitleContentCell : UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    @IBOutlet var consWidthLblTitle: NSLayoutConstraint!
    @IBOutlet var consLeadingLblContent: NSLayoutConstraint!
    @IBOutlet var vwLine: UIView!
    @IBOutlet var vwBackground: UIView!
    var imgContent: UIImageView?
    
    var tapUrl : String = ""
    var textToCopy : String = ""
    
    var root : UIViewController?
    
    override func prepareForReuse() {
        consWidthLblTitle.constant = 130
        consLeadingLblContent.constant = 8
        vwBackground.backgroundColor = UIColor.clear
        imgContent?.removeFromSuperview()
        lblTitle.font = UIFont.boldSystemFont(ofSize: 13)
        lblTitle.textAlignment = .left
    }
    
    static func heightFor(_ text : String) -> CGFloat {
        let titleWidth : CGFloat = 130.0
        let textRect : CGRect = text.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (3 * TransactionDetailTools.Margin) - titleWidth)
        return textRect.height + 4
    }
    
    static func heightFor(_ text : String, image : UIImage) -> CGFloat {
        let titleWidth : CGFloat = 130.0
        let imageWidth : CGFloat = image.size.width
        let imageHeight : CGFloat = image.size.height
        let textRect : CGRect = text.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (3 * TransactionDetailTools.Margin) - titleWidth - (imageWidth + 4))
        return (imageHeight >= textRect.height) ? imageHeight : (textRect.height + 4)
    }
    
    static func heightFor(_ title : String, content : String) -> CGFloat {
        let titleWidth : CGFloat = 130.0
        let titleRect : CGRect = title.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: titleWidth)
        let contentRect : CGRect = content.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (3 * TransactionDetailTools.Margin) - titleWidth)
        return ((titleRect.height >= contentRect.height ? titleRect.height : contentRect.height) + 4.0)
    }
    
    static func heightForTitleNil(_ content : String) -> CGFloat {
        let contentRect : CGRect = content.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (2 * TransactionDetailTools.Margin))
        return contentRect.height
    }
    
    func tapFunction2(sender:MyTapGestureRecognizer) {
        if let url = sender.headline {
            if url != "" {
                let c = CoverZoomController()
                c.labels = ["foto resi"]
                c.images = [url]
                c.index = 0
                self.root!.navigationController?.present(c, animated: true, completion: nil)
            }
        }
    }
    
    func formatURL(loc:String) -> Array<String> {
        // Create a NSCharacterSet of delimiters.
        let separators = NSCharacterSet(charactersIn: "œ")
        // Split based on characters.
        return loc.components(separatedBy: separators as CharacterSet)
    }
    
    func adapt(_ title : String, content : String) {
        self.lblTitle.text = title
        if (content.isEmpty) {
            self.lblContent.text = "-"
        } else {
            if title == "" && content.contains("Lihat foto resiœ") == true {
                self.lblContent.isUserInteractionEnabled = true
                self.lblContent.textColor = Theme.PrimaryColor
                let tap = MyTapGestureRecognizer(target: self, action: #selector(TransactionDetailTitleContentCell.tapFunction2))
                tap.headline = formatURL(loc: content)[1]
                self.lblContent.addGestureRecognizer(tap)
                self.lblContent.text = "Lihat foto resi"
            } else {
                self.lblContent.text = content
            }
        }
    }
    
    func adapt(_ title : String, content : String, alignment : NSTextAlignment?, url : String?, textToCopy : String?) {
        // for detail in CIMB clicks & Mandiri e-cash
        if title == "" {
            self.consWidthLblTitle.constant = 0
            self.consLeadingLblContent.constant = 0
        } else {
            self.lblTitle.text = title
        }
        if (content.isEmpty) {
            self.lblContent.text = "-"
        } else {
            self.lblContent.text = content
        }
        if (alignment != nil) {
            self.lblContent.textAlignment = alignment!
        }
        if (url != nil) {
            self.tapUrl = url!
            self.lblContent.textColor = Theme.PrimaryColor
        }
        if (textToCopy != nil) {
            self.textToCopy = textToCopy!
            let attrStr = NSMutableAttributedString(string: content)
            attrStr.addAttributes([NSForegroundColorAttributeName:Theme.GrayDark], range: NSMakeRange(0, content.length))
            attrStr.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColor], range: (content as NSString).range(of: ""))
            attrStr.addAttributes([NSFontAttributeName:UIFont(name: "preloAwesome", size: 14.0)!], range: (content as NSString).range(of: ""))
            self.lblContent.attributedText = attrStr
        } else {
            self.lblContent.textColor = Theme.GrayDark
        }
    }
    
    func adapt(_ title : String, content : String, image : UIImage) {
        self.lblTitle.text = title
        if (content.isEmpty) {
            self.lblContent.text = "-"
        } else {
            self.lblContent.text = content
        }
        let imgRect = CGRect(x: 130.0 + 8 + 8, y: lblContent.y, width: image.size.width, height: image.size.height)
        imgContent = UIImageView(frame: imgRect, image: image)
        self.addSubview(imgContent!)
        self.consLeadingLblContent.constant = 8 + 4 + imgRect.width
    }
    
    func adaptShipHistory(_ date : String, status : String) {
        self.adapt(date, content: status)
        self.lblTitle.font = UIFont.systemFont(ofSize: 13)
        self.lblTitle.textAlignment = .center
        self.vwBackground.backgroundColor = UIColor(hexString: "#F1F1F1")
    }
    
    func showVwLine() {
        vwLine.isHidden = false
    }
}

// MARK: - Class

class TransactionDetailTitleContentHeaderCell : UITableViewCell {
    @IBOutlet var lblTopTitle: UILabel!
    @IBOutlet var vwOneColumnHeader: UIView!
    @IBOutlet var lblOneColumn: UILabel!
    @IBOutlet var vwTwoColumnHeader: UIView!
    @IBOutlet var lblTwoColumn1: UILabel!
    @IBOutlet var lblTwoColumn2: UILabel!
    static let DefaultCellHeight : CGFloat = 64
    
    static func heightFor(_ text : String) -> CGFloat {
        let textRect : CGRect = text.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (4 * TransactionDetailTools.Margin))
        return textRect.height + 33 + 20
    }
    
    func adaptShipHistory(_ msg : String?) {
        lblTopTitle.text = "Riwayat Pengiriman"
        lblOneColumn.text = msg
        lblTwoColumn1.text = "Tanggal"
        lblTwoColumn2.text = "Status Tracking"
        if (msg != nil) {
            vwOneColumnHeader.isHidden = false
            vwTwoColumnHeader.isHidden = true
        } else {
            vwOneColumnHeader.isHidden = true
            vwTwoColumnHeader.isHidden = false
        }
    }
}

// MARK: - Class

class TransactionDetailButtonCell : UITableViewCell {
    @IBOutlet weak var btn: UIButton!
    
    var progress : Int?
    var order : Int!
    var isVeritransPayment : Bool = false
    var retrieveCash : () -> () = {}
    var confirmPayment : () -> () = {}
    var continuePayment : () -> () = {}
    var confirmShipping : () -> () = {}
    var reviewSeller : () -> () = {}
    var seeFAQ : () -> () = {}
    var confirmReturnShipping : () -> () = {}
    var confirmReturned : () -> () = {}
    var orderAgain : () -> () = {}
    var confirmPaymentAffiliate : () -> () = {}
    var seeAffiliate : () -> () = {}
    var orderAgainAffiliate : () -> () = {}
    var isAffiliate : Bool = false
    
    func adapt(_ progress : Int?, order : Int) {
        self.progress = progress
        self.order = order
        self.isAffiliate = false
        if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
            btn.setTitle("TARIK UANG", for: UIControlState())
        } else if (progress == TransactionDetailTools.ProgressNotPaid) {
            if (isVeritransPayment) {
                btn.setTitle("LANJUTKAN PEMBAYARAN", for: UIControlState())
            } else {
                btn.setTitle("KONFIRMASI PEMBAYARAN", for: UIControlState())
            }
        } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
            btn.setTitle("KIRIM / TOLAK", for: UIControlState())
        } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
            btn.setTitle("REVIEW PENJUAL", for: UIControlState())
        } else if (progress == TransactionDetailTools.ProgressFraudDetected) {
            btn.setTitle("FAQ", for: UIControlState())
        } else if (progress == TransactionDetailTools.ProgressRefundVerified) {
            btn.setTitle("KONFIRMASI PENGEMBALIAN", for: UIControlState())
        } else if (progress == TransactionDetailTools.ProgressRefundSent) {
            btn.setTitle("KONFIRMASI PENERIMAAN", for: UIControlState())
        } else if (progress == TransactionDetailTools.ProgressRefundSuccess) {
            btn.setTitle("TARIK UANG", for: UIControlState())
        } else if (progress == TransactionDetailTools.ProgressExpired) {
            let TitlePesanLagi = "PESAN LAGI BARANG YANG SAMA"
            btn.setTitle(TitlePesanLagi, for: UIControlState())
        }
    }
    
    // affiliate
    func adaptAffiliate(_ affiliateName: String, progress: Int) {
        self.progress = progress
        self.isAffiliate = true
        if progress == TransactionDetailTools.ProgressExpired {
            btn.setTitle("PESAN LAGI BARANG YANG SAMA", for: UIControlState())
        } else if progress == TransactionDetailTools.ProgressNotPaid {
            btn.setTitle("KONFIRMASI PEMBAYARAN", for: UIControlState())
        } else if progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived {
            btn.setTitle("REVIEW " + affiliateName.uppercased(), for: UIControlState())
        } else {
            btn.setTitle("LIHAT DI " + affiliateName.uppercased(), for: UIControlState())
        }
    }
    
    @IBAction func btnPressed(_ sender: AnyObject) {
        if isAffiliate {
            if progress == TransactionDetailTools.ProgressExpired {
                self.orderAgainAffiliate()
            } else if progress == TransactionDetailTools.ProgressNotPaid {
                self.confirmPaymentAffiliate()
            } else if progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived {
                self.reviewSeller() // review affiliate
            } else {
                self.seeAffiliate()
            }
        } else {
            if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
                self.retrieveCash()
            } else if (progress == TransactionDetailTools.ProgressNotPaid) {
                if (isVeritransPayment) {
                    self.continuePayment()
                } else {
                    self.confirmPayment()
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                self.confirmShipping()
            } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
                self.reviewSeller()
            } else if (progress == TransactionDetailTools.ProgressFraudDetected) {
                self.seeFAQ()
            } else if (progress == TransactionDetailTools.ProgressRefundVerified) {
                self.confirmReturnShipping()
            } else if (progress == TransactionDetailTools.ProgressRefundSent) {
                self.confirmReturned()
            } else if (progress == TransactionDetailTools.ProgressRefundSuccess) {
                self.retrieveCash()
            } else if (progress == TransactionDetailTools.ProgressExpired) {
                self.orderAgain()
            }
        }
    }
}

// MARK: - Class

class TransactionDetailBorderedButtonCell : UITableViewCell {
    @IBOutlet weak var btn: BorderedButton!
    
    var progress : Int?
    var order : Int?
    var isSeller : Bool?
//    var orderAgain : () -> () = {}
    var rejectTransaction : () -> () = {}
    var contactBuyer : () -> () = {}
    var contactSeller : () -> () = {}
    var cancelReservation : () -> () = {}
    var delayShipping : () -> () = {}
    var initRefund : () -> () = {}
    var seeAffiliate : () -> () = {}
    var refundAffiliate : () -> () = {}
    var isAffiliate : Bool = false
    var isRefund : Bool = false
    
//    let TitlePesanLagi = "PESAN LAGI BARANG YANG SAMA"
    let TitleHubungiBuyer = "HUBUNGI PEMBELI"
    let TitleHubungiSeller = "HUBUNGI PENJUAL"
    let TitleTolakPesanan = "Tolak Pesanan"
    let TitleBatalkanReservasi = "BATALKAN RESERVASI"
    let TitleTundaPengiriman = "Tunda Pengiriman"
    var TitleInitRefund = "LAPORKAN TRANSAKSI INI" //"REFUND"
    
    func adapt(_ progress : Int?, isSeller : Bool?, order : Int) {
        self.progress = progress
        self.order = order
        self.isSeller = isSeller
        self.isAffiliate = false
//        if (progress == TransactionDetailTools.ProgressExpired) {
//            btn.setTitle(TitlePesanLagi, for: UIControlState())
//        } else
        if (progress == TransactionDetailTools.ProgressRejectedBySeller) {
            btn.setTitle(TitleHubungiBuyer, for: UIControlState())
        } else if (progress == TransactionDetailTools.ProgressNotPaid) {
            if (order == 1) {
                btn.setTitle(TitleHubungiBuyer, for: UIControlState())
            } else if (order == 2) {
                btn.setTitle(TitleTolakPesanan, for: UIControlState())
                btn.titleLabel!.font = UIFont.systemFont(ofSize: 13)
                btn.borderColor = UIColor.clear
                btn.borderColorHighlight = UIColor.clear
                btn.contentHorizontalAlignment = .right
            }
        } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (isSeller != nil) {
                if (isSeller! == true) {
                    if (order == 1) {
                        btn.setTitle(TitleHubungiBuyer, for: UIControlState())
                    } else if (order == 2) {
                        btn.setTitle(TitleTundaPengiriman, for: UIControlState())
                        btn.titleLabel!.font = UIFont.systemFont(ofSize: 13)
                        btn.borderColor = UIColor.clear
                        btn.borderColorHighlight = UIColor.clear
                        btn.contentHorizontalAlignment = .right
                    }
                } else {
                    btn.setTitle(TitleHubungiSeller, for: UIControlState())
                }
            }
        } else if (progress == TransactionDetailTools.ProgressReserved) {
            btn.setTitle(TitleBatalkanReservasi, for: UIControlState())
        } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
            if (isSeller != nil) {
                if (isSeller! == true) {
                    btn.setTitle(TitleHubungiBuyer, for: UIControlState())
                } else {
                    btn.setTitle(TitleInitRefund, for: UIControlState())
                }
            }
        } else if (progress == TransactionDetailTools.ProgressRefundVerified || progress == TransactionDetailTools.ProgressRefundSent) {
            if (isSeller != nil) {
                if (isSeller! == true) {
                    btn.setTitle(TitleHubungiBuyer, for: UIControlState())
                } else {
                    btn.setTitle(TitleHubungiSeller, for: UIControlState())
                }
            }
        }
    }
    
    // affiliate
    func adaptAffiliate(_ affiliateName: String, order: Int) {
        self.isAffiliate = true
        self.isRefund = (order == 1)
        if isRefund {
            btn.setTitle("REFUND DI " + affiliateName.uppercased(), for: UIControlState())
        } else {
            btn.setTitle("LIHAT DI " + affiliateName.uppercased(), for: UIControlState())
        }
    }
    
    @IBAction func btnPressed(_ sender: AnyObject) {
        if isAffiliate {
            if isRefund {
                self.refundAffiliate()
            } else {
                self.seeAffiliate()
            }
        } else {
//            if (progress == TransactionDetailTools.ProgressExpired) {
//                self.orderAgain()
//            } else
            if (progress == TransactionDetailTools.ProgressRejectedBySeller) {
                self.contactBuyer()
            } else if (progress == TransactionDetailTools.ProgressNotPaid) {
                if (order == 1) {
                    self.contactBuyer()
                } else if (order == 2) {
                    self.rejectTransaction()
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (isSeller != nil) {
                    if (isSeller! == true) {
                        if (order == 1) {
                            self.contactBuyer()
                        } else {
                            self.delayShipping()
                        }
                    } else {
                        self.contactSeller()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressReserved) {
                self.cancelReservation()
            } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
                if (isSeller != nil) {
                    if (isSeller! == true) {
                        self.contactBuyer()
                    } else {
                        self.initRefund()
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressRefundVerified || progress == TransactionDetailTools.ProgressRefundSent) {
                if (isSeller != nil) {
                    if (isSeller! == true) {
                        self.contactBuyer()
                    } else {
                        self.contactSeller()
                    }
                }
            }
        }
    }
}

// MARK: - Class

class TransactionDetailReviewCell : UITableViewCell {
    @IBOutlet weak var imgReviewer: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblLove: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    @IBOutlet var vwLove: UIView!
    var floatRatingView: FloatRatingView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imgReviewer.afCancelRequest()
    }
    
    static func heightFor(_ reviewComment : String) -> CGFloat {
        let imgReviewerWidth : CGFloat = 64.0
        let textRect : CGRect = reviewComment.boundsWithFontSize(UIFont.systemFont(ofSize: 13), width: UIScreen.main.bounds.size.width - (3 * TransactionDetailTools.Margin) - imgReviewerWidth)
        return textRect.height + 42.0 + (2 * TransactionDetailTools.Margin)
    }
    
    func adapt(_ trxProductDetail : TransactionProductDetail) {
        // Image
        
        self.imgReviewer?.layoutIfNeeded()
        self.imgReviewer?.layer.cornerRadius = (self.imgReviewer?.width ?? 0) / 2
        self.imgReviewer?.layer.masksToBounds = true
        
        self.imgReviewer?.layer.borderColor = Theme.GrayLight.cgColor
        self.imgReviewer?.layer.borderWidth = 3

        if let url = trxProductDetail.reviewerImageURL {
            imgReviewer.afSetImage(withURL: url, withFilter: .circle)
        }
        
        // Text
        lblName.text = trxProductDetail.reviewerName
        lblContent.text = trxProductDetail.reviewComment
        
//        // Love
//        var loveText = ""
//        let star = trxProductDetail.reviewStar
//        for i in 0 ..< 5 {
//            if (i < star) {
//                loveText += ""
//            } else {
//                loveText += ""
//            }
//        }
//        let attrStringLove = NSMutableAttributedString(string: loveText)
//        attrStringLove.addAttribute(NSKernAttributeName, value: CGFloat(1.4), range: NSRange(location: 0, length: loveText.length))
//        lblLove.attributedText = attrStringLove
        
        // Love floatable
        self.floatRatingView = FloatRatingView(frame: CGRect(x: 0, y: 2.5, width: 90, height: 16))
        self.floatRatingView.emptyImage = UIImage(named: "ic_love_96px_trp.png")?.withRenderingMode(.alwaysTemplate)
        self.floatRatingView.fullImage = UIImage(named: "ic_love_96px.png")?.withRenderingMode(.alwaysTemplate)
        // Optional params
        //                self.floatRatingView.delegate = self
        self.floatRatingView.contentMode = UIViewContentMode.scaleAspectFit
        self.floatRatingView.maxRating = 5
        self.floatRatingView.minRating = 0
        self.floatRatingView.rating = Float(trxProductDetail.reviewStar)
        self.floatRatingView.editable = false
        self.floatRatingView.halfRatings = true
        self.floatRatingView.floatRatings = true
        self.floatRatingView.tintColor = Theme.ThemeRed
        
        self.vwLove.addSubview(self.floatRatingView )
    }
}

// MARK: - Class

class TransactionDetailContactPreloCell : UITableViewCell {
    @IBOutlet var lblKeterangan: UILabel!
    @IBOutlet var consTopLblContact: NSLayoutConstraint!
    
    var showContactPrelo : () -> () = {}
    
    @IBAction func btnContactPressed(_ sender: AnyObject) {
        self.showContactPrelo()
    }
}

class TransactionReportPopup: UIView {
    @IBOutlet weak var vwBackgroundOverlay: UIView!
    @IBOutlet weak var vwOverlayPopUp: UIView!
    @IBOutlet weak var vwPopUp: UIView!
    @IBOutlet weak var consCenteryPopUp: NSLayoutConstraint!
    @IBOutlet weak var lbReport: UILabel!
    @IBOutlet weak var lbRefund: UILabel!
    @IBOutlet weak var lbTitleReport: UILabel!
    @IBOutlet weak var btnReport: UIButton!
    @IBOutlet weak var imgReport: TintedImageView!
    @IBOutlet weak var imgRefund: TintedImageView!
    
    let gray = UIColor(hexString: "#939393")
    
    var disposePopUp : ()->() = {}
    var reportTrx : ()->() = {}
    var refundTrx : ()->() = {}
    
    func setupPopUp() {
        // do nothing
        
        self.lbReport.textColor = gray
        self.lbRefund.textColor = gray
        
        // setup bold/italic teks
        self.lbReport.boldSubstring("Waktu Jaminan Prelo")
        self.lbRefund.boldSubstring("Waktu Jaminan Prelo")
        self.lbRefund.italicSubstring("Refund")
    }
    
    func initPopUp(_ isReportable: Bool?) {
        let path = UIBezierPath(roundedRect:vwPopUp.bounds,
                                byRoundingCorners:[.topRight, .topLeft],
                                cornerRadii: CGSize(width: 4, height:  4))
        
        let maskLayer = CAShapeLayer()
        
        maskLayer.path = path.cgPath
        vwPopUp.layer.mask = maskLayer
        
        // Transparent panel
        self.vwBackgroundOverlay.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        
        self.vwBackgroundOverlay.isHidden = false
        self.vwOverlayPopUp.isHidden = false
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        
        // setup
        self.imgReport.tint = true
        self.imgReport.tintColor = Theme.PrimaryColor
        
        self.imgRefund.tint = true
        self.imgRefund.tintColor = Theme.PrimaryColor
        
        if isReportable != nil {
            // disable report button
            self.btnReport.isEnabled = false
            
            self.lbTitleReport.textColor = Theme.GrayLight
            self.lbReport.textColor = Theme.GrayLight
            
            //self.imgReport.tint = true
            self.imgReport.tintColor = Theme.GrayLight
            
            if !(isReportable!) {
                self.lbReport.text = "Laporan kamu sedang diproses"
            } else {
                self.lbReport.text = "Laporan kamu telah selesai diproses"
            }
        }
    }
    
    func displayPopUp() {
        let screenSize = self.bounds
        let screenHeight = screenSize.height
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = (screenHeight - self.vwPopUp.frame.height) / 2 - 32
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = -32
    }
    
    func unDisplayPopUp() {
        let screenSize = self.bounds
        let screenHeight = screenSize.height
        
        // force to bottom first
        self.consCenteryPopUp.constant = 0
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = screenHeight + (screenHeight - self.vwPopUp.frame.height) / 2 - 32
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = screenHeight
    }
    
    @IBAction func btnReportPressed(_ sender: Any) {
        self.unDisplayPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.reportTrx()
            self.disposePopUp()
        })
    }
    
    @IBAction func btnRefundPressed(_ sender: Any) {
        self.unDisplayPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.refundTrx()
            self.disposePopUp()
        })
    }
    
    @IBAction func btnTidakPressed(_ sender: Any) {
        self.unDisplayPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.disposePopUp()
        })
    }
}
