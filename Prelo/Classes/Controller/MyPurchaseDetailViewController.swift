//
//  MyPurchaseDetailViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/16/15.
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
    @IBOutlet weak var lblOrderId: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblSellerName: UILabel!
    @IBOutlet weak var lblOrderStatus: UILabel!
    @IBOutlet weak var lblOrderTime: UILabel!
    @IBOutlet weak var consWidthOrderId: NSLayoutConstraint!
    @IBOutlet weak var consWidthOrderStatus: NSLayoutConstraint!
    
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var consHeightGroupDescription: NSLayoutConstraint!
    
    @IBOutlet weak var btnKonfirmasiPembayaran: UIButton!
    
    @IBOutlet weak var lblMetodePembayaran: UILabel!
    @IBOutlet weak var lblTglPembayaran: UILabel!
    
    @IBOutlet weak var lblNamaPengiriman: UILabel!
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
    var loveValue : Int = 5
    var txtvwGrowHandler : GrowingTextViewHandler!
    @IBOutlet weak var consHeightTxtvwReview: NSLayoutConstraint!
    @IBOutlet weak var consTopVwReviewSeller: NSLayoutConstraint!
    let TxtvwReviewPlaceholder = "Tulis review tentang penjual ini"
    
    @IBOutlet var lblChkRvwAgreement: UILabel!
    var isRvwAgreed = false
    
    var transactionId : String?
    var transactionDetail : TransactionProductDetail?
    
    var contactUs : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIXME: masih dummy belum fleksibel
        lblDescription.numberOfLines = 1
        lblReviewContent.numberOfLines = 2
        
        // Tampilkan loading
        contentView.isHidden = true
        loading.startAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        vwShadow.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.7)
        vwShadow.isHidden = true
        vwReviewSeller.isHidden = true
        txtvwReview.delegate = self
        txtvwReview.text = TxtvwReviewPlaceholder
        txtvwReview.textColor = UIColor.lightGray
        txtvwGrowHandler = GrowingTextViewHandler(textView: txtvwReview, withHeightConstraint: consHeightTxtvwReview)
        txtvwGrowHandler.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 3)
        
        self.validateRvwKirimFields()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load content
        getPurchaseDetail()
        
        self.an_subscribeKeyboard (animations: { r, t, o in
            if (o) {
                self.consTopVwReviewSeller.constant = 10
            } else {
                self.consTopVwReviewSeller.constant = 100
            }
        }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func getPurchaseDetail() {
        // API Migrasi
        let _ = request(APITransactionProduct.transactionDetail(id: transactionId!)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Belanjaan Saya")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                //print("Transaction detail: \(data)")
                
                // Set label text and image
                self.transactionDetail = TransactionProductDetail.instance(data)
                self.setupContent()
            }
        }
    }
    
    func setupContent() {
        // Mixpanel
//        let param = [
//            "ID" : ((self.transactionId != nil) ? self.transactionId! : ""),
//            "Progress" : ((self.transactionDetail != nil) ? "\(self.transactionDetail!.progress)" : "")
//        ]
//        Mixpanel.trackPageVisit(PageName.TransactionDetail, otherParam: param)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.TransactionDetail)
        
        // Order status text
        let orderStatusText = transactionDetail?.progressText
        
        // Set title
        self.title = (transactionDetail!.productName)
        
        // Set images and labels
        imgProduct.afSetImage(withURL: (transactionDetail?.productImageURL)!)
        lblProductName.text = transactionDetail?.productName
        lblPrice.text = "Rp \((transactionDetail?.totalPrice)!.string)"
        lblOrderId.text = "Order \((transactionDetail?.orderId)!)"
        lblSellerName.text = " | \((transactionDetail?.sellerUsername)!)"
        lblOrderStatus.text = transactionDetail?.progressText.uppercased()
        lblOrderTime.text = " | \((transactionDetail?.time)!)"
        lblMetodePembayaran.text = (transactionDetail?.paymentMethod != nil) ? (transactionDetail?.paymentMethod) : ""
        lblTglPembayaran.text = transactionDetail?.paymentDate
        lblReviewContent.text = transactionDetail?.reviewComment
        lblNamaPengiriman.text = transactionDetail?.shippingRecipientName
        lblAlamatPengiriman.text = transactionDetail?.shippingAddress
        let provName : String? = CDProvince.getProvinceNameWithID((transactionDetail?.shippingProvinceId)!)
        lblProvinsiPengiriman.text = ((provName != nil) ? provName! : "-")
        let regionName : String? = CDRegion.getRegionNameWithID((transactionDetail?.shippingRegionId)!)
        lblRegionPengiriman.text = ((regionName != nil) ? regionName! : "-")
        lblKodePosPengiriman.text = transactionDetail?.shippingPostalCode
        lblReviewContent.text = transactionDetail?.reviewComment
        
        // lblAlamatPengiriman height fix
        let lblAlamatPengirimanHeight = lblAlamatPengiriman.frame.size.height
        let sizeThatShouldFitTheContent = lblAlamatPengiriman.sizeThatFits(lblAlamatPengiriman.frame.size)
        ////print("sizeThatShouldFitTheContent.height = \(sizeThatShouldFitTheContent.height)")
        consHeightGroupPengiriman.constant = consHeightGroupPengiriman.constant + sizeThatShouldFitTheContent.height - lblAlamatPengirimanHeight
        consHeightAlamatPengiriman.constant = sizeThatShouldFitTheContent.height
        var groupPengirimanFrame : CGRect = groupPengiriman.frame
        groupPengirimanFrame.size.height = consHeightGroupPengiriman.constant
        groupPengiriman.frame = groupPengirimanFrame
        
        // lblDescription
        if (orderStatusText == OrderStatus.PembayaranPending) {
            lblDescription.text = "Pembayaran Kamu sedang diproses"
        } else if (orderStatusText == OrderStatus.TidakDikirimSeller || orderStatusText == OrderStatus.DibatalkanSeller) {
            lblDescription.text = "Jangan khawatir, uang kamu tersimpan sebagai Prelo Balance. Kamu bisa menggunakannya untuk transaksi lain atau tarik uang."
        }
        
        // Nama dan gambar reviewer
        let user : CDUser = CDUser.getOne()!
        lblReviewerName.text = user.username
        let urlReviewer = URL(string: user.profiles.pict)
        imgReviewer.afSetImage(withURL: urlReviewer!)
        
        // Love
        var loveText = ""
        for i in 0 ..< 5 {
            if (i < transactionDetail?.reviewStar) {
                loveText += ""
            } else {
                loveText += ""
            }
        }
        let attrStringLove = NSMutableAttributedString(string: loveText)
        attrStringLove.addAttribute(NSKernAttributeName, value: CGFloat(1.4), range: NSRange(location: 0, length: loveText.length))
        lblHearts.attributedText = attrStringLove
        
        // Review Seller pop up
        lblRvwSellerName.text = transactionDetail?.sellerUsername
        lblRvwProductName.text = transactionDetail?.productName
        
        // Fix order id text width
        let orderIdFitSize = lblOrderId.sizeThatFits(lblOrderId.frame.size)
        consWidthOrderId.constant = orderIdFitSize.width
        
        // Fix order status text width
        let orderStatusFitSize = lblOrderStatus.sizeThatFits(lblOrderStatus.frame.size)
        consWidthOrderStatus.constant = orderStatusFitSize.width
        
        // Fix order status text color
        if (orderStatusText == OrderStatus.Dibayar || orderStatusText == OrderStatus.Direview || orderStatusText == OrderStatus.Selesai) { // teks hijau
            lblOrderStatus.textColor = Theme.PrimaryColor
        } else if (orderStatusText == OrderStatus.TidakDikirimSeller || orderStatusText == OrderStatus.DibatalkanSeller) { // Teks merah
            lblOrderStatus.textColor = UIColor.red
        } else {
            lblOrderStatus.textColor = Theme.ThemeOrange
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
        } else if (orderStatusText == OrderStatus.Direview || orderStatusText == OrderStatus.Selesai) {
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
        contentView.isHidden = false
    }
    
    func arrangeGroups(_ isShowGroups : [Bool]) {
        let narrowSpace : CGFloat = 15
        let wideSpace : CGFloat = 25
        var deltaX : CGFloat = 0
        for i in 0 ..< isShowGroups.count { // asumsi i = 0-9
            let isShowGroup : Bool = isShowGroups[i]
            if isShowGroup {
                groups[i].isHidden = false
                // Manual narrow/wide space
                if (i == 0 || i == 3 || i == 4 || i == 7 || i == 8) { // Narrow space before group
                    deltaX += narrowSpace
                } else if (i == 1 || i == 2 || i == 5 || i == 6 || i == 9) { // Wide space before group
                    deltaX += wideSpace
                }
                consTopGroups[i].constant = deltaX
                deltaX += groups[i].frame.size.height
            } else {
                groups[i].isHidden = true
            }
        }
        // Set content view height
        consHeightContentView.constant = deltaX + narrowSpace
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    @IBAction func disableTextFields(_ sender : AnyObject) {
        txtvwReview.resignFirstResponder()
    }
    
    @IBAction func konfirmasiPembayaranPressed(_ sender: AnyObject) {
        let orderConfirmVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
        orderConfirmVC.orderID = transactionDetail!.id
        self.navigationController?.pushViewController(orderConfirmVC, animated: true)
    }
    
    @IBAction func reviewSellerPressed(_ sender: AnyObject) {
        vwShadow.isHidden = false
        vwReviewSeller.isHidden = false
    }
    
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
    
    @IBAction func rvwBatalPressed(_ sender: AnyObject) {
        vwShadow.isHidden = true
        vwReviewSeller.isHidden = true
    }
    
    @IBAction func rvwKirimPressed(_ sender: AnyObject) {
        if (!isRvwAgreed) {
            Constant.showDialog("Review Penjual", message: "Isi checkbox sebagai tanda persetujuan")
            return
        }
        
        self.sendMode(true)
        let _ = request(APIProduct.postReview(productID: self.transactionDetail!.productId, comment: (txtvwReview.text == TxtvwReviewPlaceholder) ? "" : txtvwReview.text, star: loveValue)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Review Penjual")) {
                let json = JSON(resp.result.value!)
                let dataBool : Bool = json["_data"].boolValue
                let dataInt : Int = json["_data"].intValue
                ////print("dataBool = \(dataBool), dataInt = \(dataInt)")
                if (dataBool == true || dataInt == 1) {
                    Constant.showDialog("Success", message: "Review berhasil ditambahkan")
                } else {
                    Constant.showDialog("Success", message: "Terdapat kesalahan saat memproses data")
                }
                // Hide pop up
                self.sendMode(false)
                self.vwShadow.isHidden = true
                self.vwReviewSeller.isHidden = true
                
                // Reload content
                self.contentView.isHidden = true
                self.loading.startAnimating()
                self.getPurchaseDetail()
            }
        }
    }
    
    @IBAction func hubungiPreloPressed(_ sender: AnyObject) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let c = mainStoryboard.instantiateViewController(withIdentifier: "contactus")
        contactUs = c
        if let v = c.view, let p = self.navigationController?.view
        {
            v.alpha = 0
            v.frame = p.bounds
            self.navigationController?.view.addSubview(v)
            
            v.alpha = 0
            UIView.animate(withDuration: 0.2, animations: {
                v.alpha = 1
            })
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (txtvwReview.textColor == UIColor.lightGray) {
            txtvwReview.text = ""
            txtvwReview.textColor = Theme.GrayDark
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        txtvwGrowHandler.resizeTextView(withAnimation: true)
        self.validateRvwKirimFields()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (txtvwReview.text.isEmpty) {
            txtvwReview.text = TxtvwReviewPlaceholder
            txtvwReview.textColor = UIColor.lightGray
        }
    }
    
    // MARK: - Other Functions
    
    func validateRvwKirimFields() {
        if (txtvwReview.text.isEmpty || txtvwReview.text == self.TxtvwReviewPlaceholder) {
            // Disable tombol kirim
            btnRvwKirim.isUserInteractionEnabled = false
        } else {
            // Enable tombol kirim
            btnRvwKirim.isUserInteractionEnabled = true
        }
    }
    
    func sendMode(_ mode: Bool) {
        if (mode) {
            for i in 0 ..< btnsRvwLove.count {
                let b = btnsRvwLove[i]
                b.isUserInteractionEnabled = false
            }
            self.txtvwReview.isUserInteractionEnabled = false
            self.btnRvwBatal.isUserInteractionEnabled = false
            self.btnRvwKirim.setTitle("MENGIRIM...", for: UIControlState())
            self.btnRvwKirim.isUserInteractionEnabled = false
        } else {
            for i in 0 ..< btnsRvwLove.count {
                let b = btnsRvwLove[i]
                b.isUserInteractionEnabled = true
            }
            self.txtvwReview.isUserInteractionEnabled = true
            self.btnRvwBatal.isUserInteractionEnabled = true
            self.btnRvwKirim.setTitle("KIRIM", for: UIControlState())
            self.btnRvwKirim.isUserInteractionEnabled = true
        }
    }
}
