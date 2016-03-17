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
    let TransactionDetailButtonCellId = "TransactionDetailButtonCell"
    let TransactionDetailBorderedButtonCellId = "TransactionDetailBorderedButtonCell"
    let TransactionDetailReviewCellId = "TransactionDetailReviewCell"
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
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
            if (userIsSeller()) {
                return 5
            } else {
                return 8
            }
        } else if (progress == TransactionDetailTools.ProgressNotPaid) {
            if (userIsSeller()) {
                return 5
            } else {
                return 5
            }
        } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
            if (userIsSeller()) {
                return 5
            } else {
                return 7
            }
        } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (userIsSeller()) {
                return 9
            } else {
                return 8
            }
        } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
            if (userIsSeller()) {
                return 9
            } else {
                return 9
            }
        } else if (progress == TransactionDetailTools.ProgressReviewed) {
            if (userIsSeller()) {
                return 8
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
                if (idx == 0) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts(trxDetail!.transactionProducts)
                    }
                } else if (idx == 1) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 2) {
                    return DefaultHeight
                }
            } else {
                if (idx == 0) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts(trxDetail!.transactionProducts)
                    }
                } else if (idx == 1) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 2) {
                    return DefaultHeight
                } else if (idx == 3) {
                    return DefaultHeight
                }
            }
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
            if (userIsSeller()) {
                if (idx == 0) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts([trxProductDetail!])
                    }
                } else if (idx == 1) {
                    return DefaultHeight
                } else if (idx == 2) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                    }
                } else if (idx == 3) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 4) {
                    return DefaultHeight
                }
            } else {
                if (idx == 0) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts([trxProductDetail!])
                    }
                } else if (idx == 1) {
                    return DefaultHeight
                } else if (idx == 2) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranBuyer)
                    }
                } else if (idx == 3) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 4) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentReimburse)
                    }
                } else if (idx == 5) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 2)
                } else if (idx == 6) {
                    return DefaultHeight
                } else if (idx == 7) {
                    return DefaultHeight
                }
            }
        } else if (progress == TransactionDetailTools.ProgressNotPaid) {
            if (userIsSeller()) {
                if (idx == 0) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts(trxDetail!.transactionProducts)
                    }
                } else if (idx == 1) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 2) {
                    return DefaultHeight
                } else if (idx == 3) {
                    return 30
                } else if (idx == 4) {
                    return DefaultHeight
                }
            } else {
                if (idx == 0) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts(trxDetail!.transactionProducts)
                    }
                } else if (idx == 1) {
                    return DefaultHeight
                } else if (idx == 2) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 3) {
                    return DefaultHeight
                } else if (idx == 4) {
                    return DefaultHeight
                }
            }
        } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
            if (userIsSeller()) {
                if (idx == 0) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts(trxDetail!.transactionProducts)
                    }
                } else if (idx == 1) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 2) {
                    return DefaultHeight
                } else if (idx == 3) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                    }
                } else if (idx == 4) {
                    return DefaultHeight
                }
            } else {
                if (idx == 0) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts(trxDetail!.transactionProducts)
                    }
                } else if (idx == 1) {
                    return DefaultHeight
                } else if (idx == 2) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranBuyer)
                    }
                } else if (idx == 3) {
                    return DefaultHeight
                } else if (idx == 4) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanBuyer)
                    }
                } else if (idx == 5) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 6) {
                    return DefaultHeight
                }
            }
        } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (userIsSeller()) {
                if (idx == 0) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts(trxDetail!.transactionProducts)
                    }
                } else if (idx == 1) {
                    return DefaultHeight
                } else if (idx == 2) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                    }
                } else if (idx == 3) {
                    return DefaultHeight
                } else if (idx == 4) {
                    if (trxDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents(trxDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                    }
                } else if (idx == 5) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 6) {
                    return DefaultHeight
                } else if (idx == 7) {
                    return DefaultHeight
                } else if (idx == 8) {
                    return DefaultHeight
                }
            } else {
                if (idx == 0) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts([trxProductDetail!])
                    }
                } else if (idx == 1) {
                    return DefaultHeight
                } else if (idx == 2) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranBuyer)
                    }
                } else if (idx == 3) {
                    return DefaultHeight
                } else if (idx == 4) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanBuyer)
                    }
                } else if (idx == 5) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 6) {
                    return DefaultHeight
                } else if (idx == 7) {
                    return DefaultHeight
                }
            }
        } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
            if (userIsSeller()) {
                if (idx == 0) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts([trxProductDetail!])
                    }
                } else if (idx == 1) {
                    return DefaultHeight
                } else if (idx == 2) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                    }
                } else if (idx == 3) {
                    return DefaultHeight
                } else if (idx == 4) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                    }
                } else if (idx == 5) {
                    return DefaultHeight
                } else if (idx == 6) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 7) {
                    return DefaultHeight
                } else if (idx == 8) {
                    return DefaultHeight
                }
            } else {
                if (idx == 0) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts([trxProductDetail!])
                    }
                } else if (idx == 1) {
                    return DefaultHeight
                } else if (idx == 2) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranBuyer)
                    }
                } else if (idx == 3) {
                    return DefaultHeight
                } else if (idx == 4) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanBuyer)
                    }
                } else if (idx == 5) {
                    return DefaultHeight
                } else if (idx == 6) {
                    return TransactionDetailDescriptionCell.heightFor(progress, isSeller: isSeller, order: 1)
                } else if (idx == 7) {
                    return DefaultHeight
                } else if (idx == 8) {
                    return DefaultHeight
                }
            }
        } else if (progress == TransactionDetailTools.ProgressReviewed) {
            if (userIsSeller()) {
                if (idx == 0) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts([trxProductDetail!])
                    }
                } else if (idx == 1) {
                    return DefaultHeight
                } else if (idx == 2) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranSeller)
                    }
                } else if (idx == 3) {
                    return DefaultHeight
                } else if (idx == 4) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanSeller)
                    }
                } else if (idx == 5) {
                    return DefaultHeight
                } else if (idx == 6) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailReviewCell.heightFor(trxProductDetail!.reviewComment)
                    }
                } else if (idx == 7) {
                    return DefaultHeight
                }
            } else {
                if (idx == 0) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForProducts([trxProductDetail!])
                    }
                } else if (idx == 1) {
                    return DefaultHeight
                } else if (idx == 2) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPembayaranBuyer)
                    }
                } else if (idx == 3) {
                    return DefaultHeight
                } else if (idx == 4) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailTableCell.heightForTitleContents2(trxProductDetail!, titleContentType: TransactionDetailTools.TitleContentPengirimanBuyer)
                    }
                } else if (idx == 5) {
                    return DefaultHeight
                } else if (idx == 6) {
                    if (trxProductDetail != nil) {
                        return TransactionDetailReviewCell.heightFor(trxProductDetail!.reviewComment)
                    }
                } else if (idx == 7) {
                    return DefaultHeight
                }
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
                    return self.createBorderedButtonCell(1)
                } else if (idx == 3) {
                    return self.createContactPreloCell()
                }
            }
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
            if (userIsSeller()) {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                } else if (idx == 3) {
                    return self.createDescriptionCell(1)
                } else if (idx == 4) {
                    return self.createContactPreloCell()
                }
            } else {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranBuyer)
                } else if (idx == 3) {
                    return self.createDescriptionCell(1)
                } else if (idx == 4) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentReimburse)
                } else if (idx == 5) {
                    return self.createDescriptionCell(2)
                } else if (idx == 6) {
                    return self.createButtonCell(1)
                } else if (idx == 7) {
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
                    return self.createBorderedButtonCell(2)
                } else if (idx == 4) {
                    return self.createContactPreloCell()
                }
            } else {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    return self.createDescriptionCell(1)
                } else if (idx == 3) {
                    return self.createButtonCell(1)
                } else if (idx == 4) {
                    return self.createContactPreloCell()
                }
            }
        } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
            if (userIsSeller()) {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createDescriptionCell(1)
                } else if (idx == 2) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 3) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                } else if (idx == 4) {
                    return self.createContactPreloCell()
                }
            } else {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranBuyer)
                } else if (idx == 3) {
                    return self.createTitleCell(TitlePengiriman)
                } else if (idx == 4) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanBuyer)
                } else if (idx == 5) {
                    return self.createDescriptionCell(1)
                } else if (idx == 6) {
                    return self.createContactPreloCell()
                }
            }
        } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (userIsSeller()) {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                } else if (idx == 3) {
                    return self.createTitleCell(TitlePengiriman)
                } else if (idx == 4) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                } else if (idx == 5) {
                    return self.createDescriptionCell(1)
                } else if (idx == 6) {
                    return self.createButtonCell(1)
                } else if (idx == 7) {
                    return self.createBorderedButtonCell(1)
                } else if (idx == 8) {
                    return self.createContactPreloCell()
                }
            } else {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranBuyer)
                } else if (idx == 3) {
                    return self.createTitleCell(TitlePengiriman)
                } else if (idx == 4) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanBuyer)
                } else if (idx == 5) {
                    return self.createDescriptionCell(1)
                } else if (idx == 6) {
                    return self.createBorderedButtonCell(1)
                } else if (idx == 7) {
                    return self.createContactPreloCell()
                }
            }
        } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
            if (userIsSeller()) {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                } else if (idx == 3) {
                    return self.createTitleCell(TitlePengiriman)
                } else if (idx == 4) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                } else if (idx == 5) {
                    return self.createTitleCell(TitleReview)
                } else if (idx == 6) {
                    return self.createDescriptionCell(1)
                } else if (idx == 7) {
                    return self.createBorderedButtonCell(1)
                } else if (idx == 8) {
                    return self.createContactPreloCell()
                }
            } else {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranBuyer)
                } else if (idx == 3) {
                    return self.createTitleCell(TitlePengiriman)
                } else if (idx == 4) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanBuyer)
                } else if (idx == 5) {
                    return self.createTitleCell(TitleReview)
                } else if (idx == 6) {
                    return self.createDescriptionCell(1)
                } else if (idx == 7) {
                    return self.createButtonCell(1)
                } else if (idx == 8) {
                    return self.createContactPreloCell()
                }
            }
        } else if (progress == TransactionDetailTools.ProgressReviewed) {
            if (userIsSeller()) {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranSeller)
                } else if (idx == 3) {
                    return self.createTitleCell(TitlePengiriman)
                } else if (idx == 4) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanSeller)
                } else if (idx == 5) {
                    return self.createTitleCell(TitleReview)
                } else if (idx == 6) {
                    return self.createReviewCell()
                } else if (idx == 7) {
                    return self.createContactPreloCell()
                }
            } else {
                if (idx == 0) {
                    return self.createTableProductsCell()
                } else if (idx == 1) {
                    return self.createTitleCell(TitlePembayaran)
                } else if (idx == 2) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPembayaranBuyer)
                } else if (idx == 3) {
                    return self.createTitleCell(TitlePengiriman)
                } else if (idx == 4) {
                    return self.createTableTitleContentsCell(TransactionDetailTools.TitleContentPengirimanBuyer)
                } else if (idx == 5) {
                    return self.createTitleCell(TitleReview)
                } else if (idx == 6) {
                    return self.createReviewCell()
                } else if (idx == 7) {
                    return self.createContactPreloCell()
                }
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Do nothing
    }
    
    // MARK: - Cell creation
    
    func createTableProductsCell() -> TransactionDetailTableCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailTableCellId) as! TransactionDetailTableCell
        
        // Adapt cell
        if (self.progress == TransactionDetailTools.ProgressExpired || self.progress == TransactionDetailTools.ProgressNotPaid || self.progress == TransactionDetailTools.ProgressClaimedPaid) {
            if (trxDetail != nil) {
                cell.adaptTableProducts(trxDetail!.transactionProducts)
            }
        } else if (self.progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (userIsSeller()) {
                if (trxDetail != nil) {
                    cell.adaptTableProducts(trxDetail!.transactionProducts)
                }
            } else {
                if (trxProductDetail != nil) {
                    cell.adaptTableProducts([trxProductDetail!])
                }
            }
        } else {
            if (trxProductDetail != nil) {
                cell.adaptTableProducts([trxProductDetail!])
            }
        }
        
        return cell
    }
    
    func createTableTitleContentsCell(titleContentType : String) -> TransactionDetailTableCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailTableCellId) as! TransactionDetailTableCell
        
        // Adapt cell
        if (self.progress == TransactionDetailTools.ProgressExpired || self.progress == TransactionDetailTools.ProgressNotPaid || self.progress == TransactionDetailTools.ProgressClaimedPaid) {
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
    
    func createDescriptionCell(order : Int) -> TransactionDetailDescriptionCell {
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
                    cell.adapt2(trxProductDetail!, order: order)
                }
            }
        } else {
            if (trxProductDetail != nil) {
                cell.adapt2(trxProductDetail!, order: order)
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
    
    func createButtonCell(order : Int) -> TransactionDetailButtonCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailButtonCellId) as! TransactionDetailButtonCell
        
        // Adapt cell
        if (progress != nil) {
            cell.adapt(self.progress, order: order)
        }
        
        return cell
    }
    
    func createBorderedButtonCell(order : Int) -> TransactionDetailBorderedButtonCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailBorderedButtonCellId) as! TransactionDetailBorderedButtonCell
        
        // Adapt cell
        if (progress != nil) {
            cell.adapt(self.progress, isSeller: isSeller, order: order)
        }
        
        return cell
    }
    
    func createReviewCell() -> TransactionDetailReviewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailReviewCellId) as! TransactionDetailReviewCell
        
        // Adapt cell
        if (trxProductDetail != nil) {
            cell.adapt(trxProductDetail!)
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
    
    // TitleContent type
    static let TitleContentPembayaranBuyer = "tcpembayaranbuyer"
    static let TitleContentPembayaranSeller = "tcpembayaranseller"
    static let TitleContentPengirimanBuyer = "tcpengirimanbuyer"
    static let TitleContentPengirimanSeller = "tcpengirimanseller"
    static let TitleContentReimburse = "tcreimburse"
    
    // Text
    static let TextPembayaranExpiredBuyer = "Pembayaran expired karena kamu belum membayar hingga batas waktu yang ditentukan."
    static let TextPembayaranExpiredSeller = "Pembayaran expired karena buyer belum membayar hingga batas waktu yang ditentukan."
    static let TextHubungiBuyer = "Beritahu buyer bahwa barang sudah dikirim. Minta buyer untuk memberikan review apabila barang sudah diterima."
    static let TextDikembalikan = "Pembayaran produk ini telah dikembalikan kepada buyer."
    static let TextReimburse1 = "Mohon maaf, pesanan kamu tidak bisa dikirim karena keterbatasan pada seller. Jangan khawatir, pembayaranmu telah disimpan dalam bentuk:"
    static let TextReimburse2 = "Kamu dapat menggunakannya untuk transaksi selanjutnya atau tarik tunai PreloBalance."
    static let TextNotPaid = "Transaksi ini belum dibayar dan akan expired pada "
    static let TextNotPaidSeller = "Ingatkan buyer untuk segera membayar."
    static let TextNotPaidBuyer = "Segera konfirmasi pembayaran."
    static let TextClaimedPaidSeller = "Pembayaran buyer sedang diproses."
    static let TextClaimedPaidBuyer = "Hubungi Prelo apabila alamat pengiriman salah."
    static let TextConfirmedPaidSeller1 = "Kirim pesanan sebelum "
    static let TextConfirmedPaidSeller2 = "Jika kamu tidak mengirimkan sampai waktu tersebut, transaksi akan dibatalkan serta uang akan dikembalikan kepada buyer. Hubungi Prelo apabila kamu perlu tambahan waktu untuk mengirim."
    static let TextConfirmedPaidBuyer1 = "Pesanan kamu belum dikirim dan akan expired pada "
    static let TextConfirmedPaidBuyer2 = "Ingatkan seller untuk mengirim pesanan."
    static let TextSentSeller = "Beritahu buyer bahwa barang sudah dikirim. Minta buyer untuk memberikan review apabila barang sudah diterima."
    static let TextSentBuyer = "Berikan review sebagai konfirmasi penerimaan. Prelo akan meneruskan pembayaran ke seller."
    static let TextReceivedSeller = "Barang semestinya sudah diterima. Hubungi buyer untuk mengecek apakah barang sudah diterima dan minta review untuk menyelesaikan transaksi."
    static let TextReceivedBuyer = "Barang semestinya sudah kamu terima. Review seller untuk menyelesaikan transaksi. Belum terima barang? Hubungi Prelo."
}

// MARK: - Class

class TransactionDetailTableCell : UITableViewCell, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    // Cell type
    var isProductCell : Bool = false
    var isTitleContentCell : Bool = false
    
    // Used for productCell
    var trxProducts : [TransactionProductDetail] = []
    
    // Used for titleContentCell
    var trxDetail : TransactionDetail?
    var trxProductDetail : TransactionProductDetail?
    var titleContentType : String = ""
    
    // Cell identifiers
    let TransactionDetailProductCellId = "TransactionDetailProductCell"
    let TransactionDetailTitleContentCellId = "TransactionDetailTitleContentCell"
    
    static func heightForProducts(trxProducts : [TransactionProductDetail]) -> CGFloat {
        return (CGFloat(trxProducts.count) * TransactionDetailTools.TransactionDetailProductCellHeight)
    }
    
    static func heightForTitleContents(trxDetail : TransactionDetail, titleContentType : String) -> CGFloat {
        // FIXME: Pertimbangkan tinggi text yg panjang
        if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyer) {
            return 6 * TransactionDetailTools.TransactionDetailTitleContentCellHeight
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranSeller) {
            return 2 * TransactionDetailTools.TransactionDetailTitleContentCellHeight
        } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanBuyer) {
            return 7 * TransactionDetailTools.TransactionDetailTitleContentCellHeight
        } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanSeller) {
            return 6 * TransactionDetailTools.TransactionDetailTitleContentCellHeight
        } else if (titleContentType == TransactionDetailTools.TitleContentReimburse) {
            return 2 * TransactionDetailTools.TransactionDetailTitleContentCellHeight
        }
        return 0
    }
    
    static func heightForTitleContents2(trxProductDetail : TransactionProductDetail, titleContentType : String) -> CGFloat {
        // FIXME: Pertimbangkan tinggi text yg panjang
        if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyer) {
            return 6 * TransactionDetailTools.TransactionDetailTitleContentCellHeight
        } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranSeller) {
            return 2 * TransactionDetailTools.TransactionDetailTitleContentCellHeight
        } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanBuyer) {
            return 7 * TransactionDetailTools.TransactionDetailTitleContentCellHeight
        } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanSeller) {
            return 6 * TransactionDetailTools.TransactionDetailTitleContentCellHeight
        } else if (titleContentType == TransactionDetailTools.TitleContentReimburse) {
            return 2 * TransactionDetailTools.TransactionDetailTitleContentCellHeight
        }
        return 0
    }
    
    func adaptTableProducts(trxProducts : [TransactionProductDetail]) {
        self.trxProducts = trxProducts
        self.isProductCell = true
        self.isTitleContentCell = false
        self.tableView.separatorStyle = .SingleLine
        self.setupTable()
    }
    
    func adaptTableTitleContents(trxDetail : TransactionDetail, titleContentType : String) {
        self.trxDetail = trxDetail
        self.titleContentType = titleContentType
        self.isProductCell = false
        self.isTitleContentCell = true
        self.tableView.separatorStyle = .None
        self.setupTable()
    }
    
    func adaptTableTitleContents2(trxProductDetail : TransactionProductDetail, titleContentType : String) {
        self.trxProductDetail = trxProductDetail
        self.titleContentType = titleContentType
        self.isProductCell = false
        self.isTitleContentCell = true
        self.tableView.separatorStyle = .None
        self.setupTable()
    }
    
    // MARK: - UITableView delegate functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (isProductCell) {
            return trxProducts.count
        } else {
            if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyer) {
                return 6
            } else if (titleContentType == TransactionDetailTools.TitleContentPembayaranSeller) {
                return 2
            } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanBuyer) {
                return 7
            } else if (titleContentType == TransactionDetailTools.TitleContentPengirimanSeller) {
                return 6
            } else if (titleContentType == TransactionDetailTools.TitleContentReimburse) {
                return 2
            }
            return 0
        }
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
            let idx = indexPath.row
            
            if (titleContentType == TransactionDetailTools.TitleContentPembayaranBuyer) {
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
                        content = trxDetail!.paymentBankSource
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentBankSource
                    }
                    return self.createTitleContentCell("Bank Kamu", content: content)
                } else if (idx == 4) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.paymentBankAccount
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.paymentBankAccount
                    }
                    return self.createTitleContentCell("Rekening Atas Nama", content: content)
                } else if (idx == 5) {
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
                        content = trxDetail!.shippingAddress
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingAddress
                    }
                    return self.createTitleContentCell("Alamat", content: content)
                } else if (idx == 2) {
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
                } else if (idx == 3) {
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
                } else if (idx == 4) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingPostalCode
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingPostalCode
                    }
                    return self.createTitleContentCell("Kode Pos", content: content)
                } else if (idx == 5) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.shippingName
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingName
                    }
                    return self.createTitleContentCell("Kurir", content: content)
                } else if (idx == 6) {
                    var content = ""
                    if (isTrxDetail()) {
                        content = trxDetail!.resiNumber
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.resiNumber
                    }
                    return self.createTitleContentCell("Nomor Resi", content: content)
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
                    return self.createTitleContentCell("Nomor Telepon", content: "022 250 35 93")
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
                        if let p = CDProvince.getProvinceNameWithID(trxDetail!.shippingProvinceId) {
                            content = p
                        }
                    } else if (isTrxProductDetail()) {
                        if let p = CDProvince.getProvinceNameWithID(trxProductDetail!.shippingProvinceId) {
                            content = p
                        }
                    }
                    return self.createTitleContentCell("Provinsi", content: content)
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
                        content = trxDetail!.shippingPostalCode
                    } else if (isTrxProductDetail()) {
                        content = trxProductDetail!.shippingPostalCode
                    }
                    return self.createTitleContentCell("Kode Pos", content: content)
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
                    return self.createTitleContentCell("Prelo Bonus", content: content)
                }
            }
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Do nothing
    }
    
    // MARK: - Cell creation
    
    func createTitleContentCell(title : String, content : String) -> TransactionDetailTitleContentCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionDetailTitleContentCellId) as! TransactionDetailTitleContentCell
        
        // Adapt call
        cell.adapt(title, content: content)
        
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
    
    static func heightFor(progress : Int?, isSeller : Bool?, order : Int) -> CGFloat {
        if (progress != nil && isSeller != nil) {
            var textRect : CGRect?
            if (progress == TransactionDetailTools.ProgressExpired) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextPembayaranExpiredSeller.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    textRect = TransactionDetailTools.TextPembayaranExpiredBuyer.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextDikembalikan.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    if (order == 1) {
                        textRect = TransactionDetailTools.TextReimburse1.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                    } else if (order == 2) {
                        textRect = TransactionDetailTools.TextReimburse2.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressNotPaid) {
                let text = TransactionDetailTools.TextNotPaid + "dd/MM/yyyy hh:mm:ss. " + ((isSeller! == true) ? TransactionDetailTools.TextNotPaidSeller : TransactionDetailTools.TextNotPaidBuyer)
                textRect = text.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
            } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextClaimedPaidSeller.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    textRect = TransactionDetailTools.TextPembayaranExpiredBuyer.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (isSeller! == true) {
                    let text = TransactionDetailTools.TextConfirmedPaidSeller1 + "dd/MM/yyyy hh:mm:ss" + TransactionDetailTools.TextConfirmedPaidSeller2
                    textRect = text.boundsWithFontSize(UIFont.boldSystemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    let text = TransactionDetailTools.TextConfirmedPaidBuyer1 + "dd/MM/yyyy hh:mm:ss" + TransactionDetailTools.TextConfirmedPaidBuyer2
                    textRect = text.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressSent) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextSentSeller.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    textRect = TransactionDetailTools.TextSentBuyer.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                }
            } else if (progress == TransactionDetailTools.ProgressReceived) {
                if (isSeller! == true) {
                    textRect = TransactionDetailTools.TextReceivedSeller.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
                } else {
                    textRect = TransactionDetailTools.TextReceivedSeller.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (2 * TransactionDetailTools.Margin))
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
                    lblDesc.text = TransactionDetailTools.TextNotPaid + expireTime + TransactionDetailTools.TextNotPaidBuyer
                }
            } else if (progress == TransactionDetailTools.ProgressClaimedPaid) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextClaimedPaidSeller
                } else {
                    lblDesc.text = TransactionDetailTools.TextClaimedPaidBuyer
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (isSeller) {
                    let expireTime = trxDetail.shippingExpireTime + ". "
                    // FIXME: ada yg ditebelin
                    lblDesc.text = TransactionDetailTools.TextConfirmedPaidSeller1 + expireTime + TransactionDetailTools.TextConfirmedPaidSeller2
                }
            }
        }
    }
    
    func adapt2(trxProductDetail : TransactionProductDetail, order : Int) {
        if let userId = User.Id {
            let progress = trxProductDetail.progress
            let isSeller = trxProductDetail.isSeller(userId)
            if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextDikembalikan
                } else {
                    if (order == 1) {
                        lblDesc.text = TransactionDetailTools.TextReimburse1
                    } else if (order == 2) {
                        lblDesc.text = TransactionDetailTools.TextReimburse2
                    }
                }
            } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
                if (!isSeller) {
                    let expireTime = "dd/MM/yyyy hh:mm:ss" + ". "
                    lblDesc.text = TransactionDetailTools.TextConfirmedPaidBuyer1 + expireTime + TransactionDetailTools.TextConfirmedPaidBuyer2
                }
            } else if (progress == TransactionDetailTools.ProgressSent) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextSentSeller
                } else {
                    lblDesc.text = TransactionDetailTools.TextSentBuyer
                }
            } else if (progress == TransactionDetailTools.ProgressReceived) {
                if (isSeller) {
                    lblDesc.text = TransactionDetailTools.TextReceivedSeller
                } else {
                    lblDesc.text = TransactionDetailTools.TextReceivedBuyer
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
    
    func adapt(title : String, content : String) {
        self.lblTitle.text = title
        if (content.isEmpty) {
            self.lblContent.text = "---"
        } else {
            self.lblContent.text = content
        }
    }
}

// MARK: - Class

class TransactionDetailButtonCell : UITableViewCell {
    @IBOutlet weak var btn: UIButton!
    
    var progress : Int?
    var order : Int?
    
    func adapt(progress : Int?, order : Int) {
        self.progress = progress
        self.order = order
        if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
            btn.setTitle("TARIK TUNAI", forState: UIControlState.Normal)
        } else if (progress == TransactionDetailTools.ProgressNotPaid) {
            btn.setTitle("KONFIRMASI PEMBAYARAN", forState: UIControlState.Normal)
        } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
            btn.setTitle("KIRIM / TOLAK", forState: UIControlState.Normal)
        } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
            btn.setTitle("REVIEW SELLER", forState: UIControlState.Normal)
        }
    }
    
    @IBAction func btnPressed(sender: AnyObject) {
        if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressNotSent) {
            Constant.showDialog("Button pressed", message: "TARIK TUNAI")
        } else if (progress == TransactionDetailTools.ProgressNotPaid) {
            Constant.showDialog("Button pressed", message: "KONFIRMASI PEMBAYARAN")
        } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
            Constant.showDialog("Button pressed", message: "KIRIM / TOLAK")
        } else if (progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
            Constant.showDialog("Button pressed", message: "REVIEW SELLER")
        }
    }
}

// MARK: - Class

class TransactionDetailBorderedButtonCell : UITableViewCell {
    @IBOutlet weak var btn: BorderedButton!
    
    var progress : Int?
    var order : Int?
    var isSeller : Bool?
    
    func adapt(progress : Int?, isSeller : Bool?, order : Int) {
        self.progress = progress
        self.order = order
        self.isSeller = isSeller
        if (progress == TransactionDetailTools.ProgressExpired) {
            btn.setTitle("PESAN LAGI BARANG YANG SAMA", forState: UIControlState.Normal)
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
            btn.setTitle("HUBUNGI BUYER", forState: UIControlState.Normal)
        } else if (progress == TransactionDetailTools.ProgressNotPaid) {
            if (order == 1) {
                btn.setTitle("HUBUNGI BUYER", forState: UIControlState.Normal)
            } else if (order == 2) {
                btn.setTitle("Tolak Transaksi", forState: UIControlState.Normal)
                btn.titleLabel!.font = UIFont.systemFontOfSize(13)
                btn.borderColor = UIColor.clearColor()
                btn.borderColorHighlight = UIColor.clearColor()
                btn.contentHorizontalAlignment = .Right
            }
        } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (isSeller != nil) {
                if (isSeller! == true) {
                    btn.setTitle("HUBUNGI BUYER", forState: UIControlState.Normal)
                } else {
                    btn.setTitle("HUBUNGI SELLER", forState: UIControlState.Normal)
                }
            }
        }
    }
    
    @IBAction func btnPressed(sender: AnyObject) {
        if (progress == TransactionDetailTools.ProgressExpired) {
            Constant.showDialog("Button pressed", message: "PESAN LAGI BARANG YANG SAMA")
        } else if (progress == TransactionDetailTools.ProgressRejectedBySeller || progress == TransactionDetailTools.ProgressSent || progress == TransactionDetailTools.ProgressReceived) {
            Constant.showDialog("Button pressed", message: "HUBUNGI BUYER")
        } else if (progress == TransactionDetailTools.ProgressNotPaid) {
            if (order == 1) {
                Constant.showDialog("Button pressed", message: "HUBUNGI BUYER")
            } else if (order == 2) {
                Constant.showDialog("Button pressed", message: "Tolak Transaksi")
            }
        } else if (progress == TransactionDetailTools.ProgressConfirmedPaid) {
            if (isSeller != nil) {
                if (isSeller! == true) {
                    Constant.showDialog("Button pressed", message: "HUBUNGI BUYER")
                } else {
                    Constant.showDialog("Button pressed", message: "HUBUNGI SELLER")
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
    
    static func heightFor(reviewComment : String) -> CGFloat {
        let imgReviewerWidth : CGFloat = 64.0
        var textRect : CGRect = reviewComment.boundsWithFontSize(UIFont.systemFontOfSize(13), width: UIScreen.mainScreen().bounds.size.width - (3 * TransactionDetailTools.Margin) - imgReviewerWidth)
        return textRect.height + 42.0 + (2 * TransactionDetailTools.Margin)
    }
    
    func adapt(trxProductDetail : TransactionProductDetail) {
        // Image
        if let url = trxProductDetail.reviewerImageURL {
            imgReviewer.setImageWithUrl(url, placeHolderImage: UIImage(named: "raisa.jpg"))
        }
        
        // Text
        lblName.text = trxProductDetail.reviewerName
        lblContent.text = trxProductDetail.reviewComment
        
        // Love
        var loveText = ""
        var star = trxProductDetail.reviewStar
        for (var i = 0; i < 5; i++) {
            if (i < star) {
                loveText += ""
            } else {
                loveText += ""
            }
        }
        let attrStringLove = NSMutableAttributedString(string: loveText)
        attrStringLove.addAttribute(NSKernAttributeName, value: CGFloat(1.4), range: NSRange(location: 0, length: loveText.length()))
        lblLove.attributedText = attrStringLove
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
