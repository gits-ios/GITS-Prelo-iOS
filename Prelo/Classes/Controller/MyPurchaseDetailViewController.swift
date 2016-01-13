//
//  MyPurchaseDetailViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/16/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyPurchaseDetailViewController: BaseViewController, UITextViewDelegate {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var consHeightContentView: NSLayoutConstraint!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    // Groups index:
    // 0 : Group Product Detail
    // 1 : Group Description
    // 2 : Group Title Pembayaran
    // 3 : Group Konfirmasi Pembayaran
    // 4 : Group Detail Pembayaran
    // 5 : Group Pengiriman
    // 6 : Group Title Review
    // 7 : Group Review Seller
    // 8 : Group Content Review
    // 9 : Group Ada Masalah
    var groups: [UIView] = []
    @IBOutlet weak var groupProductDetail: UIView!
    @IBOutlet weak var groupDescription: UIView!
    @IBOutlet weak var groupTitlePembayaran: UIView!
    @IBOutlet weak var groupKonfPembayaran: UIView!
    @IBOutlet weak var groupDetailPembayaran: UIView!
    @IBOutlet weak var groupPengiriman: UIView!
    @IBOutlet weak var groupTitleReview: UIView!
    @IBOutlet weak var groupReviewSeller: UIView!
    @IBOutlet weak var groupContentReview: UIView!
    @IBOutlet weak var groupAdaMasalah: UIView!
    
    var consTopGroups: [NSLayoutConstraint] = []
    @IBOutlet weak var consTopProductDetail: NSLayoutConstraint!
    @IBOutlet weak var consTopDescription: NSLayoutConstraint!
    @IBOutlet weak var consTopTitlePembayaran: NSLayoutConstraint!
    @IBOutlet weak var consTopKonfPembayaran: NSLayoutConstraint!
    @IBOutlet weak var consTopDetailPembayaran: NSLayoutConstraint!
    @IBOutlet weak var consTopPengiriman: NSLayoutConstraint!
    @IBOutlet weak var consTopTitleReview: NSLayoutConstraint!
    @IBOutlet weak var consTopReviewSeller: NSLayoutConstraint!
    @IBOutlet weak var consTopContentReview: NSLayoutConstraint!
    @IBOutlet weak var consTopAdaMasalah: NSLayoutConstraint!
    
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblSellerName: UILabel!
    @IBOutlet weak var lblOrderStatus: UILabel!
    @IBOutlet weak var lblOrderTime: UILabel!
    @IBOutlet weak var consWidthOrderStatus: NSLayoutConstraint!
    
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var consHeightGroupDescription: NSLayoutConstraint!
    
    @IBOutlet weak var btnKonfirmasiPembayaran: UIButton!
    
    @IBOutlet weak var lblMetodePembayaran: UILabel!
    @IBOutlet weak var lblTglPembayaran: UILabel!
    
    @IBOutlet weak var lblNamaPengiriman: UILabel!
    @IBOutlet weak var lblNoTelpPengiriman: UILabel!
    @IBOutlet weak var lblAlamatPengiriman: UILabel!
    @IBOutlet weak var lblProvinsiPengiriman: UILabel!
    @IBOutlet weak var lblRegionPengiriman: UILabel!
    @IBOutlet weak var lblKodePosPengiriman: UILabel!
    @IBOutlet weak var consHeightGroupPengiriman: NSLayoutConstraint!
    @IBOutlet weak var consHeightAlamatPengiriman: NSLayoutConstraint!
    
    @IBOutlet weak var btnReviewSeller: UIButton!
    
    @IBOutlet weak var imgReviewer: UIImageView!
    @IBOutlet weak var lblReviewerName: UILabel!
    @IBOutlet weak var lblHearts: UILabel!
    @IBOutlet weak var lblReviewContent: UILabel!
    
    @IBOutlet weak var vwShadow: UIView!
    @IBOutlet weak var vwReviewSeller: UIView!
    @IBOutlet weak var lblRvwSellerName: UILabel!
    @IBOutlet weak var lblRvwProductName: UILabel!
    @IBOutlet weak var txtvwReview: UITextView!
    @IBOutlet weak var btnRvwBatal: UIButton!
    @IBOutlet weak var btnRvwKirim: UIButton!
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
    var loveValue : Int = 0
    var txtvwGrowHandler : GrowingTextViewHandler!
    @IBOutlet weak var consHeightTxtvwReview: NSLayoutConstraint!
    @IBOutlet weak var consTopVwReviewSeller: NSLayoutConstraint!
    let TxtvwReviewPlaceholder = "Tulis review tentang seller ini"
    
    var transactionId : String?
    var transactionDetail : TransactionDetail?
    
    var contactUs : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIXME: masih dummy belum fleksibel
        lblDescription.numberOfLines = 1
        lblReviewContent.numberOfLines = 2
        
        // Tampilkan loading
        contentView.hidden = true
        loading.startAnimating()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        vwShadow.backgroundColor = UIColor.colorWithColor(UIColor.blackColor(), alpha: 0.7)
        vwShadow.hidden = true
        vwReviewSeller.hidden = true
        txtvwReview.delegate = self
        txtvwReview.text = TxtvwReviewPlaceholder
        txtvwReview.textColor = UIColor.lightGrayColor()
        txtvwGrowHandler = GrowingTextViewHandler(textView: txtvwReview, withHeightConstraint: consHeightTxtvwReview)
        txtvwGrowHandler.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 3)
        
        self.validateRvwKirimFields()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load content
        getPurchaseDetail()
        
        self.an_subscribeKeyboardWithAnimations ({ r, t, o in
            if (o) {
                self.consTopVwReviewSeller.constant = 10
            } else {
                self.consTopVwReviewSeller.constant = 150
            }
        }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func getPurchaseDetail() {
        request(APITransaction.TransactionDetail(id: transactionId!)).responseJSON {req, _, res, err in
            println("Purchase detail req = \(req)")
            if (err != nil) { // Terdapat error
                println("Error getting transaction detail: \(err!.description)")
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                if (data == nil) { // Data kembalian kosong
                    let obj : [String : String] = res as! [String : String]
                    let message = obj["_message"]
                    println("Empty transaction detail, message: \(message)")
                } else { // Berhasil
                    println("Transaction detail: \(data)")
                    
                    // Set label text and image
                    self.transactionDetail = TransactionDetail.instance(data)
                    self.setupContent()
                }
            }
        }
    }
    
    func setupContent() {
        // Mixpanel
        let param = [
            "Product" : ((self.transactionDetail != nil) ? self.transactionDetail!.productName : ""),
            "Product ID" : ((self.transactionDetail != nil) ? self.transactionDetail!.productId : ""),
            "Seller" : ((self.transactionDetail != nil) ? self.transactionDetail!.sellerName : "")
        ]
        Mixpanel.trackPageVisit(PageName.TransactionDetail, otherParam: param)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.TransactionDetail)
        
        // Order status text
        let orderStatusText = transactionDetail?.progressText
        
        // Set title
        self.title = (transactionDetail!.productName)
        
        // Set images and labels
        imgProduct.setImageWithUrl((transactionDetail?.productImageURL)!, placeHolderImage: nil)
        lblProductName.text = transactionDetail?.productName
        lblPrice.text = "Rp \((transactionDetail?.productPrice)!.string)"
        lblSellerName.text = transactionDetail?.sellerName
        lblOrderStatus.text = transactionDetail?.progressText.uppercaseString
        lblOrderTime.text = transactionDetail?.time
        lblMetodePembayaran.text = (transactionDetail?.paymentMethod != nil) ? (transactionDetail?.paymentMethod) : ""
        lblTglPembayaran.text = transactionDetail?.paymentDate
        lblReviewContent.text = transactionDetail?.reviewComment
        lblNamaPengiriman.text = transactionDetail?.shippingRecipientName
        lblNoTelpPengiriman.text = "0222503593"
        lblAlamatPengiriman.text = transactionDetail?.shippingAddress
        let provName : String? = CDProvince.getProvinceNameWithID((transactionDetail?.shippingProvinceId)!)
        lblProvinsiPengiriman.text = ((provName != nil) ? provName! : "-")
        let regionName : String? = CDRegion.getRegionNameWithID((transactionDetail?.shippingRegionId)!)
        lblRegionPengiriman.text = ((regionName != nil) ? regionName! : "-")
        lblKodePosPengiriman.text = transactionDetail?.shippingPostalCode
        lblReviewContent.text = transactionDetail?.reviewComment
        
        // lblAlamatPengiriman height fix
        let lblAlamatPengirimanHeight = lblAlamatPengiriman.frame.size.height
        var sizeThatShouldFitTheContent = lblAlamatPengiriman.sizeThatFits(lblAlamatPengiriman.frame.size)
        //println("sizeThatShouldFitTheContent.height = \(sizeThatShouldFitTheContent.height)")
        consHeightGroupPengiriman.constant = consHeightGroupPengiriman.constant + sizeThatShouldFitTheContent.height - lblAlamatPengirimanHeight
        consHeightAlamatPengiriman.constant = sizeThatShouldFitTheContent.height
        var groupPengirimanFrame : CGRect = groupPengiriman.frame
        groupPengirimanFrame.size.height = consHeightGroupPengiriman.constant
        groupPengiriman.frame = groupPengirimanFrame
        
        // lblDescription
        if (orderStatusText == OrderStatus.PembayaranPending) {
            lblDescription.text = "Pembayaran Kamu sedang diproses"
        } else if (orderStatusText == OrderStatus.TidakDikirimSeller || orderStatusText == OrderStatus.DibatalkanSeller) {
            lblDescription.text = "Jangan khawatir, uang kamu tersimpan sebagai Prelo Balance. Kamu bisa menggunakannya untuk transaksi lain atau tarik tunai."
        }
        
        // Nama dan gambar reviewer
        let user : CDUser = CDUser.getOne()!
        lblReviewerName.text = user.fullname
        let urlReviewer = NSURL(string: DAO.UserPhotoStringURL(user.profiles.pict, userID: user.id))
        imgReviewer.setImageWithUrl(urlReviewer!, placeHolderImage: nil)
        
        // Love
        var loveText = ""
        for (var i = 0; i < 5; i++) {
            if (i < transactionDetail?.reviewStar) {
                loveText += ""
            } else {
                loveText += ""
            }
        }
        let attrStringLove = NSMutableAttributedString(string: loveText)
        attrStringLove.addAttribute(NSKernAttributeName, value: CGFloat(1.4), range: NSRange(location: 0, length: loveText.length()))
        lblHearts.attributedText = attrStringLove
        
        // Review Seller pop up
        lblRvwSellerName.text = transactionDetail?.sellerName
        lblRvwProductName.text = transactionDetail?.productName
        
        // Fix order status text width
        let orderStatusFitSize = lblOrderStatus.sizeThatFits(lblOrderStatus.frame.size)
        consWidthOrderStatus.constant = orderStatusFitSize.width
        
        // Fix order status text color
        if (orderStatusText == OrderStatus.Dibayar || orderStatusText == OrderStatus.Direview) { // teks hijau
            lblOrderStatus.textColor = Theme.PrimaryColor
        } else if (orderStatusText == OrderStatus.TidakDikirimSeller || orderStatusText == OrderStatus.DibatalkanSeller) { // Teks merah
            lblOrderStatus.textColor == UIColor.redColor()
        } else {
            lblOrderStatus.textColor == Theme.ThemeOrange
        }
        
        // Set groups and top constraints manually
        groups.append(self.groupProductDetail)
        groups.append(self.groupDescription)
        groups.append(self.groupTitlePembayaran)
        groups.append(self.groupKonfPembayaran)
        groups.append(self.groupDetailPembayaran)
        groups.append(self.groupPengiriman)
        groups.append(self.groupTitleReview)
        groups.append(self.groupReviewSeller)
        groups.append(self.groupContentReview)
        groups.append(self.groupAdaMasalah)
        
        consTopGroups.append(self.consTopProductDetail)
        consTopGroups.append(self.consTopDescription)
        consTopGroups.append(self.consTopTitlePembayaran)
        consTopGroups.append(self.consTopKonfPembayaran)
        consTopGroups.append(self.consTopDetailPembayaran)
        consTopGroups.append(self.consTopPengiriman)
        consTopGroups.append(self.consTopTitleReview)
        consTopGroups.append(self.consTopReviewSeller)
        consTopGroups.append(self.consTopContentReview)
        consTopGroups.append(self.consTopAdaMasalah)
        
        // Set btnLoves and lblLoves manually
        btnsRvwLove.append(self.btnLove1)
        btnsRvwLove.append(self.btnLove2)
        btnsRvwLove.append(self.btnLove3)
        btnsRvwLove.append(self.btnLove4)
        btnsRvwLove.append(self.btnLove5)
        lblsRvwLove.append(self.lblLove1)
        lblsRvwLove.append(self.lblLove2)
        lblsRvwLove.append(self.lblLove3)
        lblsRvwLove.append(self.lblLove4)
        lblsRvwLove.append(self.lblLove5)
        
        // Arrange groups
        var p : [Bool] = []
        if (orderStatusText == OrderStatus.Dipesan) {
            p = [true, false, true, true, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Dibayar) {
            p = [true, false, true, false, true, true, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Dikirim) {
            p = [true, false, true, false, true, true, true, true, false, true]
        } else if (orderStatusText == OrderStatus.PembayaranPending) {
            p = [true, true, false, false, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Direview) {
            p = [true, false, true, false, true, true, true, false, true, true]
        } else if (orderStatusText == OrderStatus.TidakDikirimSeller) {
            p = [true, true, false, false, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Diterima) {
            p = [true, false, true, false, true, true, true, true, false, true]
        } else if (orderStatusText == OrderStatus.DibatalkanSeller) {
            p = [true, true, false, false, false, false, false, false, false, true]
        } else { // Default
            p = [true, false, false, false, false, false, false, false, false, true]
        }
        arrangeGroups(p)
        
        // Show content
        loading.stopAnimating()
        contentView.hidden = false
    }
    
    func arrangeGroups(isShowGroups : [Bool]) {
        let narrowSpace : CGFloat = 15
        let wideSpace : CGFloat = 25
        var deltaX : CGFloat = 0
        for (var i = 0; i < isShowGroups.count; i++) { // asumsi i = 0-9
            let isShowGroup : Bool = isShowGroups[i]
            if isShowGroup {
                groups[i].hidden = false
                // Manual narrow/wide space
                if (i == 0 || i == 3 || i == 4 || i == 7 || i == 8) { // Narrow space before group
                    deltaX += narrowSpace
                } else if (i == 1 || i == 2 || i == 5 || i == 6 || i == 9) { // Wide space before group
                    deltaX += wideSpace
                }
                consTopGroups[i].constant = deltaX
                deltaX += groups[i].frame.size.height
            } else {
                groups[i].hidden = true
            }
        }
        // Set content view height
        consHeightContentView.constant = deltaX + narrowSpace
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UIButton.classForCoder()) || touch.view.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    @IBAction func disableTextFields(sender : AnyObject) {
        txtvwReview.resignFirstResponder()
    }
    
    @IBAction func konfirmasiPembayaranPressed(sender: AnyObject) {
        let orderConfirmVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
        orderConfirmVC.orderID = transactionDetail!.id
        self.navigationController?.pushViewController(orderConfirmVC, animated: true)
    }
    
    @IBAction func reviewSellerPressed(sender: AnyObject) {
        vwShadow.hidden = false
        vwReviewSeller.hidden = false
    }
    
    @IBAction func rvwLovePressed(sender: UIButton) {
        var isFound = false
        for (var i = 0; i < btnsRvwLove.count; i++) {
            let b = btnsRvwLove[i]
            if (!isFound) {
                if (sender == b) {
                    isFound = true
                    loveValue = i + 1
                    println("loveValue = \(loveValue)")
                }
                lblsRvwLove[i].text = ""
            } else {
                lblsRvwLove[i].text = ""
            }
        }
    }
    
    @IBAction func rvwBatalPressed(sender: AnyObject) {
        vwShadow.hidden = true
        vwReviewSeller.hidden = true
    }
    
    @IBAction func rvwKirimPressed(sender: AnyObject) {
        self.sendMode(true)
        request(Products.PostReview(productID: self.transactionDetail!.productId, comment: (txtvwReview.text == TxtvwReviewPlaceholder) ? "" : txtvwReview.text, star: loveValue)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err)) {
                let json = JSON(res!)
                let data : Bool? = json["_data"].bool
                if (data != nil || data == true) {
                    println("data = \(data)")
                    Constant.showDialog("Success", message: "Review berhasil ditambahkan")
                    self.sendMode(false)
                    self.vwShadow.hidden = true
                    self.vwReviewSeller.hidden = true
                    
                    // Reload content
                    self.contentView.hidden = true
                    self.loading.startAnimating()
                    self.getPurchaseDetail()
                }
            }
        }
    }
    
    @IBAction func hubungiPreloPressed(sender: AnyObject) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let c = mainStoryboard.instantiateViewControllerWithIdentifier("contactus") as! UIViewController
        contactUs = c
        if let v = c.view, let p = self.navigationController?.view
        {
            v.alpha = 0
            v.frame = p.bounds
            self.navigationController?.view.addSubview(v)
            
            v.alpha = 0
            UIView.animateWithDuration(0.2, animations: {
                v.alpha = 1
            })
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if (txtvwReview.textColor == UIColor.lightGrayColor()) {
            txtvwReview.text = ""
            txtvwReview.textColor = Theme.GrayDark
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        txtvwGrowHandler.resizeTextViewWithAnimation(true)
        self.validateRvwKirimFields()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if (txtvwReview.text.isEmpty) {
            txtvwReview.text = TxtvwReviewPlaceholder
            txtvwReview.textColor = UIColor.lightGrayColor()
        }
    }
    
    // MARK: - Other Functions
    
    func validateRvwKirimFields() {
        if (txtvwReview.text.isEmpty || txtvwReview.text == self.TxtvwReviewPlaceholder) {
            // Disable tombol kirim
            btnRvwKirim.userInteractionEnabled = false
        } else {
            // Enable tombol kirim
            btnRvwKirim.userInteractionEnabled = true
        }
    }
    
    func sendMode(mode: Bool) {
        if (mode) {
            for (var i = 0; i < btnsRvwLove.count; i++) {
                let b = btnsRvwLove[i]
                b.userInteractionEnabled = false
            }
            self.txtvwReview.userInteractionEnabled = false
            self.btnRvwBatal.userInteractionEnabled = false
            self.btnRvwKirim.setTitle("MENGIRIM...", forState: .Normal)
            self.btnRvwKirim.userInteractionEnabled = false
        } else {
            for (var i = 0; i < btnsRvwLove.count; i++) {
                let b = btnsRvwLove[i]
                b.userInteractionEnabled = true
            }
            self.txtvwReview.userInteractionEnabled = true
            self.btnRvwBatal.userInteractionEnabled = true
            self.btnRvwKirim.setTitle("KIRIM", forState: .Normal)
            self.btnRvwKirim.userInteractionEnabled = true
        }
    }
}
