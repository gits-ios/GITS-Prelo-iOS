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
    @IBOutlet var groups: [UIView]!
    @IBOutlet var consTopGroups: [NSLayoutConstraint]!
    
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
    
    @IBOutlet weak var lblKurirPengiriman: UILabel!
    @IBOutlet weak var lblNoPengiriman: UILabel!
    @IBOutlet weak var lblTglPengiriman: UILabel!
    
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
    @IBOutlet var btnsRvwLove: [UIButton]!
    var loveValue : Int = 0
    var txtvwGrowHandler : GrowingTextViewHandler!
    @IBOutlet weak var consHeightTxtvwReview: NSLayoutConstraint!
    @IBOutlet weak var consTopVwReviewSeller: NSLayoutConstraint!
    let TxtvwReviewPlaceholder = "Tulis review tentang seller ini"
    
    var transactionId : String?
    var transactionDetail : TransactionDetail?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TESTING
        /*lblDescription.text = "Kuawali hariku dengan mendoakanmu"
        let descriptionFitSize = lblDescription.sizeThatFits(lblDescription.frame.size)
        println("descriptionFitSize = \(descriptionFitSize)")
        println("\(heightForView(lblDescription.text!, font: AppFont.Prelo2.getFont(14.0)!, width: lblDescription.frame.size.width))")
        println("tinggi label = \(lblDescription.frame.size.height)")
        
        lblDescription.text = ""
        let descriptionFitSize2 = lblDescription.sizeThatFits(lblDescription.frame.size)
        println("descriptionFitSize2 = \(descriptionFitSize2)")
        println("\(heightForView(lblDescription.text!, font: AppFont.Prelo2.getFont(14.0)!, width: lblDescription.frame.size.width))")
        println("tinggi label = \(lblDescription.frame.size.height)")
        
        lblDescription.text = "Kuawali hariku dengan mendoakanmu agar kau slalu sehat dan bahagia di sana sebelum kau melupakanku lebih jauh sebelum kau meninggalkanku lebih jauh kutak pernah berharap kau dapat merindukan kebradaanku yang menyedihkan ini"
        let descriptionFitSize3 = lblDescription.sizeThatFits(lblDescription.frame.size)
        println("descriptionFitSize3 = \(descriptionFitSize3)")
        println("\(heightForView(lblDescription.text!, font: AppFont.Prelo2.getFont(14.0)!, width: lblDescription.frame.size.width))")
        println("tinggi label = \(lblDescription.frame.size.height)")
        
        let font : UIFont = UIFont.systemFontOfSize(14)
        let expectedLblDescriptionSize : CGRect = lblDescription.text!.boundsWithFontSize(AppFont.Prelo2.getFont(14)!, width: lblDescription.frame.size.width)
        let rect = lblDescription.text?.boundingRectWithSize(CGSizeMake(lblDescription.frame.size.width, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName : font], context: nil)
        println("exp = \(expectedLblDescriptionSize)")
        println("widt = \(lblDescription.frame.size)")
        println("rect =  \(rect)")
        
        consHeightGroupDescription.constant = descriptionFitSize3.height*/
        lblDescription.numberOfLines = 1
        lblReviewContent.numberOfLines = 2
        
        // Tampilkan loading
        contentView.hidden = true
        loading.startAnimating()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.sharedInstance().track("My Purchase Detail")
        
        vwShadow.backgroundColor = UIColor.colorWithColor(UIColor.blackColor(), alpha: 0.7)
        vwShadow.hidden = true
        vwReviewSeller.hidden = true
        txtvwReview.delegate = self
        txtvwReview.text = TxtvwReviewPlaceholder
        txtvwReview.textColor = UIColor.lightGrayColor()
        txtvwGrowHandler = GrowingTextViewHandler(textView: txtvwReview, withHeightConstraint: consHeightTxtvwReview)
        txtvwGrowHandler.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 3)
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
        
        // Arrange groups
        let orderStatusText = transactionDetail?.progressText
        var p : [Bool] = []
        if (orderStatusText == OrderStatus.Dipesan) {
            p = [true, false, true, true, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Dibayar) {
            p = [true, false, true, false, true, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Dikirim) {
            p = [true, false, true, false, true, true, true, true, false, true]
        } else if (orderStatusText == OrderStatus.PembayaranPending) {
            p = [true, true, false, false, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Direview) {
            p = [true, false, true, false, true, true, true, false, true, true]
        } else if (orderStatusText == OrderStatus.TidakDikirimSeller) {
            p = [true, true, false, false, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Diterima) {
            p = [true, false, true, false, true, true, false, false, false, true]
        } else if (orderStatusText == OrderStatus.DibatalkanSeller) {
            p = [true, true, false, false, false, false, false, false, false, true]
        } else { // Default
            p = [true, false, false, false, false, false, false, false, false, true]
        }
        arrangeGroups(p)
        
        // Set back button
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: " \(transactionDetail!.productName)", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
        
        // Set images and labels
        imgProduct.setImageWithUrl((transactionDetail?.productImageURL)!, placeHolderImage: nil)
        lblProductName.text = transactionDetail?.productName
        lblPrice.text = "Rp \((transactionDetail?.productPrice)!.string)"
        lblSellerName.text = transactionDetail?.sellerName
        lblOrderStatus.text = transactionDetail?.progressText.uppercaseString
        lblOrderTime.text = transactionDetail?.time
        lblMetodePembayaran.text = (transactionDetail?.paymentMethod != nil) ? (transactionDetail?.paymentMethod) : ""
        lblTglPembayaran.text = transactionDetail?.paymentDate
        lblKurirPengiriman.text = transactionDetail?.shippingName
        lblNoPengiriman.text = transactionDetail?.resiNumber
        lblTglPengiriman.text = transactionDetail?.shippingDate
        lblReviewContent.text = transactionDetail?.reviewComment
        
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
        
        // Show content
        loading.stopAnimating()
        contentView.hidden = false
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // TODO: DELETE IF UNNECESSARY
    func heightForView(text : String, font : UIFont, width : CGFloat) -> CGRect{
        let label : UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame
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
                b.titleLabel!.text = ""
            } else {
                b.titleLabel!.text = ""
            }
        }
    }
    
    @IBAction func rvwBatalPressed(sender: AnyObject) {
        vwShadow.hidden = true
        vwReviewSeller.hidden = true
    }
    
    @IBAction func rvwKirimPressed(sender: AnyObject) {
        self.sendMode(true)
        request(Products.PostReview(productID: self.transactionDetail!.productId, comment: (txtvwReview.text == TxtvwReviewPlaceholder) ? "" : txtvwReview.text, star: loveValue)).responseJSON {req, _, res, err in
            println("Post review req = \(req)")
            if (err != nil) { // Terdapat error
                Constant.showDialog("Warning", message: "Error posting review")//: \(err!.description)")
                self.sendMode(false)
            } else {
                let json = JSON(res!)
                let data : Bool? = json["_data"].bool
                if (data == nil || data == false) { // Gagal
                    println("Error posting review")
                    self.sendMode(false)
                } else { // Berhasil
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
    
    func textViewDidBeginEditing(textView: UITextView) {
        if (txtvwReview.textColor == UIColor.lightGrayColor()) {
            txtvwReview.text = ""
            txtvwReview.textColor = Theme.GrayDark
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        txtvwGrowHandler.resizeTextViewWithAnimation(true)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if (txtvwReview.text.isEmpty) {
            txtvwReview.text = TxtvwReviewPlaceholder
            txtvwReview.textColor = UIColor.lightGrayColor()
        }
    }
    
    // MARK: - Other Functions
    
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
