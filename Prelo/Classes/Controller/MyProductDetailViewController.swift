//
//  MyProductDetailViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/22/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
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


class MyProductDetailViewController : BaseViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var consHeightContentView: NSLayoutConstraint!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    // Groups index:
    // 0 : Group Product Detail
    // 1 : Group Description
    // 2 : Group Pembayaran
    // 3 : Group Konfirmasi Pengiriman
    // 4 : Group Tolak Penawaran
    // 5 : Group Pengiriman
    // 6 : Group Title Review
    // 7 : Group Belum Review
    // 8 : Group Hubungi Buyer
    // 9 : Group Content Review
    // 10 : Group Ada Masalah
    var groups: [UIView] = []
    @IBOutlet weak var groupProductDetail: UIView!
    @IBOutlet weak var groupDescription: UIView!
    @IBOutlet weak var groupPembayaran: UIView!
    @IBOutlet weak var groupPengiriman: UIView!
    @IBOutlet weak var groupKonfPengiriman: UIView!
    @IBOutlet weak var groupTolakPenawaran: UIView!
    @IBOutlet weak var groupTitleReview: UIView!
    @IBOutlet weak var groupBelumReview: UIView!
    @IBOutlet weak var groupHubungiBuyer: UIView!
    @IBOutlet weak var groupContentReview: UIView!
    @IBOutlet weak var groupAdaMasalah: UIView!
    
    var consTopGroups: [NSLayoutConstraint] = []
    @IBOutlet weak var consTopProductDetail: NSLayoutConstraint!
    @IBOutlet weak var consTopDescription: NSLayoutConstraint!
    @IBOutlet weak var consTopPembayaran: NSLayoutConstraint!
    @IBOutlet weak var consTopPengiriman: NSLayoutConstraint!
    @IBOutlet weak var consTopKonfPengiriman: NSLayoutConstraint!
    @IBOutlet weak var consTopTolakPenawaran: NSLayoutConstraint!
    @IBOutlet weak var consTopTitleReview: NSLayoutConstraint!
    @IBOutlet weak var consTopBelumReview: NSLayoutConstraint!
    @IBOutlet weak var consTopHubungiBuyer: NSLayoutConstraint!
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
    
    @IBOutlet weak var lblMetodePembayaran: UILabel!
    @IBOutlet weak var lblTglPembayaran: UILabel!
    
    @IBOutlet weak var btnKonfirmasiPengiriman: UIButton!
    
    @IBOutlet weak var lblNamaPengiriman: UILabel!
    @IBOutlet weak var lblNoTelpPengiriman: UILabel!
    @IBOutlet weak var lblAlamatPengiriman: UILabel!
    @IBOutlet weak var lblProvinsiPengiriman: UILabel!
    @IBOutlet weak var lblRegionPengiriman: UILabel!
    @IBOutlet weak var lblKodePosPengiriman: UILabel!
    @IBOutlet weak var consHeightGroupPengiriman: NSLayoutConstraint!
    @IBOutlet weak var consHeightAlamatPengiriman: NSLayoutConstraint!
    
    @IBOutlet weak var btnHubungiBuyer: UIButton!
    
    @IBOutlet weak var imgReviewer: UIImageView!
    @IBOutlet weak var lblReviewerName: UILabel!
    @IBOutlet weak var lblHearts: UILabel!
    @IBOutlet weak var lblReviewContent: UILabel!
    
    @IBOutlet weak var vwTolakPesanan: UIView!
    @IBOutlet weak var txtvwAlasanTolak: UITextView!
    @IBOutlet weak var btnTolakBatal: UIButton!
    @IBOutlet weak var btnTolakKirim: UIButton!
    var txtvwGrowHandler : GrowingTextViewHandler!
    @IBOutlet weak var consHeightTxtvwAlasanTolak: NSLayoutConstraint!
    @IBOutlet weak var consTopVwTolakPesanan: NSLayoutConstraint!
    let TxtvwAlasanTolakPlaceholder = "Tulis alasan penolakan pesanan"
    
    @IBOutlet weak var vwShadow: UIView!
    @IBOutlet weak var vwKonfKirim: UIView!
    @IBOutlet weak var lblKonfKurir: UILabel!
    @IBOutlet weak var lblKonfOngkir: UILabel!
    @IBOutlet weak var fldKonfNoResi: UITextField!
    @IBOutlet weak var vwFotoBuktiContent: UIView!
    @IBOutlet weak var vwIconKamera: UIView!
    @IBOutlet weak var imgFotoBukti: UIImageView!
    @IBOutlet weak var btnFotoBukti: UIButton!
    @IBOutlet weak var btnKonfBatal: UIButton!
    @IBOutlet weak var btnKonfKirim: UIButton!
    @IBOutlet weak var consTopVwKonfKirim: NSLayoutConstraint!
    var imagePicker : UIImagePickerController!
    
    var transactionId : String?
    var transactionDetail : TransactionProductDetail?
    
    var contactUs : UIViewController?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tampilkan loading
        contentView.isHidden = true
        loading.startAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Agar shadow transparan
        vwShadow.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.7)
        
        // Sembunyikan shadow dan pop up
        //vwShadow.hidden = true
        //vwKonfKirim.hidden = true
        //vwTolakPesanan.hidden = true
        
        // Agar icon kamera menjadi bulat
        vwIconKamera.layer.cornerRadius = (vwIconKamera.frame.size.width) / 2
        
        // Set delegate textfield
        fldKonfNoResi.delegate = self
        
        // suggested by kumang
        fldKonfNoResi.addTarget(self, action: #selector(MyProductDetailViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        
        // Atur textview
        txtvwAlasanTolak.delegate = self
        txtvwAlasanTolak.text = TxtvwAlasanTolakPlaceholder
        txtvwAlasanTolak.textColor = UIColor.lightGray
        txtvwGrowHandler = GrowingTextViewHandler(textView: txtvwAlasanTolak, withHeightConstraint: consHeightTxtvwAlasanTolak)
        txtvwGrowHandler.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 2)
        
        self.validateKonfKirimFields()
        self.validateTolakPesananFields()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load content
        getProductDetail()
        
        // Penanganan kemunculan keyboard
        self.an_subscribeKeyboard (animations: { r, t, o in
            if (o) {
                self.consTopVwKonfKirim.constant = 10
                self.consTopVwTolakPesanan.constant = 10
            } else {
                self.consTopVwKonfKirim.constant = 100
                self.consTopVwTolakPesanan.constant = 100
            }
        }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func getProductDetail() {
        // API Migrasi
        let _ = request(APITransactionProduct.transactionDetail(id: transactionId!)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Jualan Saya")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                // Set label text and image
                self.transactionDetail = TransactionProductDetail.instance(data)
                self.setupContent()
            }
        }
    }
    
    func setupContent() {
        // Mixpanel
        let param = [
            "ID" : ((self.transactionId != nil) ? self.transactionId! : ""),
            "Progress" : ((self.transactionDetail != nil) ? "\(self.transactionDetail!.progress)" : "")
        ]
        Mixpanel.trackPageVisit(PageName.TransactionDetail, otherParam: param)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.TransactionDetail)
        
        // Order status text
        let orderStatusText = transactionDetail?.progressText
        
        // Set title
        self.title = (transactionDetail!.productName)
        
        // Set images and labels
        imgProduct.downloadedFrom(url: (transactionDetail?.productImageURL)!)
        lblProductName.text = transactionDetail?.productName
        lblPrice.text = "Rp \((transactionDetail?.totalPrice)!.string)"
        lblOrderId.text = "Order \((transactionDetail?.orderId)!)"
        lblSellerName.text = " | \((transactionDetail?.sellerUsername)!)"
        lblOrderStatus.text = transactionDetail?.progressText.uppercased()
        lblOrderTime.text = " | \((transactionDetail?.time)!)"
        lblMetodePembayaran.text = (transactionDetail?.paymentMethod != nil) ? (transactionDetail?.paymentMethod) : ""
        lblTglPembayaran.text = transactionDetail?.paymentDate
        lblNamaPengiriman.text = transactionDetail?.shippingRecipientName
        lblNoTelpPengiriman.text = transactionDetail?.shippingRecipientPhone
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
        //print("sizeThatShouldFitTheContent.height = \(sizeThatShouldFitTheContent.height)")
        consHeightGroupPengiriman.constant = consHeightGroupPengiriman.constant + sizeThatShouldFitTheContent.height - lblAlamatPengirimanHeight
        consHeightAlamatPengiriman.constant = (sizeThatShouldFitTheContent.height < 21) ? 21 : sizeThatShouldFitTheContent.height
        var groupPengirimanFrame : CGRect = groupPengiriman.frame
        groupPengirimanFrame.size.height = consHeightGroupPengiriman.constant
        groupPengiriman.frame = groupPengirimanFrame
        
        // lblDescription
        if (orderStatusText == OrderStatus.PembayaranPending) {
            lblDescription.text = "Pembayaran sedang diproses"
        } else {
            let expireText = ((transactionDetail?.expireTime != nil) ? (transactionDetail?.expireTime)! : "-")
            lblDescription.text = "Transaksi ini belum dibayar dan akan expired pada \(expireText). Ingatkan Pembeli untuk segera membayar"
        }
        let sizeFitDescription = lblDescription.sizeThatFits(lblDescription.frame.size)
        consHeightGroupDescription.constant = sizeFitDescription.height
        var groupDescFrame : CGRect = groupDescription.frame
        groupDescFrame.size.height = consHeightGroupDescription.constant
        groupDescription.frame = groupDescFrame
        
        // Nama dan gambar reviewer
        lblReviewerName.text = transactionDetail?.reviewerName
        if (transactionDetail?.reviewerImageURL != nil) {
            imgReviewer.downloadedFrom(url: (transactionDetail?.reviewerImageURL)!)
        }
        
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
        
        // Konfirmasi Pengiriman pop up
        lblKonfKurir.text = transactionDetail?.shippingName
        lblKonfOngkir.text = transactionDetail?.shippingPrice
        
        // Fix order id text width
        let orderIdFitSize = lblOrderId.sizeThatFits(lblOrderId.frame.size)
        consWidthOrderId.constant = orderIdFitSize.width
        
        // Fix order status text width
        let orderStatusFitSize = lblOrderStatus.sizeThatFits(lblOrderStatus.frame.size)
        consWidthOrderStatus.constant = orderStatusFitSize.width
        
        // Fix order status text color
        if (orderStatusText == OrderStatus.Dibayar || orderStatusText == OrderStatus.Direview || orderStatusText == OrderStatus.Selesai) { // teks hijau
            lblOrderStatus.textColor = Theme.PrimaryColor
        } else {
            lblOrderStatus.textColor = Theme.ThemeOrange
        }
        
        // Set groups and top constraints manually
        groups.append(self.groupProductDetail)
        groups.append(self.groupDescription)
        groups.append(self.groupPembayaran)
        groups.append(self.groupPengiriman)
        groups.append(self.groupKonfPengiriman)
        groups.append(self.groupTolakPenawaran)
        groups.append(self.groupTitleReview)
        groups.append(self.groupBelumReview)
        groups.append(self.groupHubungiBuyer)
        groups.append(self.groupContentReview)
        groups.append(self.groupAdaMasalah)
        
        consTopGroups.append(self.consTopProductDetail)
        consTopGroups.append(self.consTopDescription)
        consTopGroups.append(self.consTopPembayaran)
        consTopGroups.append(self.consTopPengiriman)
        consTopGroups.append(self.consTopKonfPengiriman)
        consTopGroups.append(self.consTopTolakPenawaran)
        consTopGroups.append(self.consTopTitleReview)
        consTopGroups.append(self.consTopBelumReview)
        consTopGroups.append(self.consTopHubungiBuyer)
        consTopGroups.append(self.consTopContentReview)
        consTopGroups.append(self.consTopAdaMasalah)
        
        // Arrange groups
        var p : [Bool] = []
        if (orderStatusText == OrderStatus.Dipesan) {
            p = [true, true, false, false, false, false, false, false, true, false, true]
        } else if (orderStatusText == OrderStatus.BelumDibayar) {
            p = [true, true, false, false, false, false, false, false, true, false, true]
        } else if (orderStatusText == OrderStatus.Dibayar) {
            p = [true, false, true, true, true, true, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Dikirim) {
            p = [true, false, true, true, false, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.PembayaranPending) {
            p = [true, true, false, false, false, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Direview || orderStatusText == OrderStatus.Selesai) {
            p = [true, false, true, true, false, false, true, false, false, true, true]
        } else if (orderStatusText == OrderStatus.Diterima) {
            p = [true, false, true, true, false, false, true, true, true, false, true]
        } else {
            p = [true, false, false, false, false, false, false, false, false, false, true]
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
        for i in 0 ..< isShowGroups.count { // asumsi i = 0-10
            let isShowGroup : Bool = isShowGroups[i]
            if isShowGroup {
                groups[i].isHidden = false
                // Manual narrow/wide space
                if (i == 0 || i == 5 || i == 4 || i == 7 || i == 8 || i == 9) { // Narrow space before group
                    deltaX += narrowSpace
                } else if (i == 1 || i == 2 || i == 3 || i == 5 || i == 6 || i == 10) { // Wide space before group
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
    
    // MARK: - GestureRecognizer Functions
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - ImagePickerDelegate Functions
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        
        imgFotoBukti.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        vwFotoBuktiContent.isHidden = true
        vwShadow.isHidden = false
        vwKonfKirim.isHidden = false
        
        self.validateKonfKirimFields()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
        
        vwShadow.isHidden = false
        vwKonfKirim.isHidden = false
        
        self.validateKonfKirimFields()
    }
    
    // MARK: - UITextFieldDelegate Functions
    
    func textFieldDidChange(_ textField: UITextField) {
        self.validateKonfKirimFields()
    }
    
    // MARK: - UITextViewDelegate Funcitons
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (txtvwAlasanTolak.textColor == UIColor.lightGray) {
            txtvwAlasanTolak.text = ""
            txtvwAlasanTolak.textColor = Theme.GrayDark
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        txtvwGrowHandler.resizeTextView(withAnimation: true)
        self.validateTolakPesananFields()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (txtvwAlasanTolak.text.isEmpty) {
            txtvwAlasanTolak.text = TxtvwAlasanTolakPlaceholder
            txtvwAlasanTolak.textColor = UIColor.lightGray
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func disableTextFields(_ sender : AnyObject) {
        fldKonfNoResi.resignFirstResponder()
        txtvwAlasanTolak.resignFirstResponder()
    }
    
    @IBAction func konfirmasiPengirimanPressed(_ sender: AnyObject) {
        vwShadow.isHidden = false
        vwKonfKirim.isHidden = false
    }
    
    @IBAction func tolakPenawaranPressed(_ sender: AnyObject) {
        vwShadow.isHidden = false
        vwTolakPesanan.isHidden = false
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
    
    @IBAction func fotoBuktiPressed(_ sender: AnyObject) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        // suggestion by kumang
        // kemungkinan kalaw ada device yang kamera nya rusak, .Camera gakan bisa juga
        // jadi kayaknya bagusan di cek dulu, jangan pake if target_iphone_xx
        imagePicker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) == true ? .camera : .photoLibrary
        
//        if TARGET_IPHONE_SIMULATOR == 1 {
//            imagePicker.sourceType = .PhotoLibrary
//        } else {
//            imagePicker.sourceType = .Camera // Lie, it'll be executed ->
//        }
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func tolakBatalPressed(_ sender: AnyObject) {
        vwShadow.isHidden = true
        vwTolakPesanan.isHidden = true
    }
    
    @IBAction func tolakKirimPressed(_ sender: AnyObject) {
        self.sendMode(true)
        // API Migrasi
        let _ = request(APITransactionProduct.rejectTransaction(tpId: self.transactionId!, reason: self.txtvwAlasanTolak.text)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Tolak Pengiriman")) {
                let json = JSON(resp.result.value!)
                let data : Bool? = json["_data"].bool
                if (data != nil || data == true) {
                    Constant.showDialog("Success", message: "Tolak pesanan berhasil dilakukan")
                    self.sendMode(false)
                    self.vwShadow.isHidden = true
                    self.vwTolakPesanan.isHidden = true
                    
                    // Reload content
                    self.contentView.isHidden = true
                    self.loading.startAnimating()
                    self.getProductDetail()
                }
            }
        }
    }
    
    @IBAction func konfBatalPressed(_ sender: AnyObject) {
        vwShadow.isHidden = true
        vwKonfKirim.isHidden = true
    }
    
    @IBAction func konfKirimPressed(_ sender: AnyObject) {
        self.sendMode(true)
        
        let url = "\(AppTools.PreloBaseUrl)/api/transaction_product/\(self.transactionId!)/sent"
        var noHp = ""
        if let p = fldKonfNoResi.text
        {
            noHp = p
        }
        let param = [
            "resi_number" : noHp
        ]
        var images : [UIImage] = []
        images.append(imgFotoBukti.image!)
        
        let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
        
        AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, andUserAgent: userAgent!, to: url, success: { op, res in
            print("KonfKirim res = \(res)")
            let json = JSON(res)
            let data : Bool? = json["_data"].bool
            if (data == nil || data == false) { // Gagal
//                let msg = json["message"]
                Constant.showDialog("Warning", message: "Upload bukti pengiriman gagal")//: \(msg)")
                self.sendMode(false)
            } else { // Berhasil
                Constant.showDialog("Success", message: "Konfirmasi pengiriman berhasil dilakukan")
                self.navigationController?.popViewController(animated: true)
            }
        }, failure: { op, err in
            Constant.showDialog("Warning", message: "Upload bukti pengiriman gagal")// dengan error: \(err)")
            self.sendMode(false)
        })
    }
    
    var detail : ProductDetail?
    @IBAction func hubungiBuyerPressed(_ sender: AnyObject) {
        // Get product detail from API
        let _ = request(APIProduct.detail(productId: (transactionDetail?.productId)!, forEdit: 0)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hubungi Pembeli")) {
                let json = JSON(resp.result.value!)
                //let pDetail = ProductDetail.instance(json)
                //pDetail?.reverse()
                self.detail = ProductDetail.instance(json)
                
                // Goto chat
                let t = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdTawar) as! TawarViewController
                
                // API Migrasi
        let _ = request(APIInbox.getInboxByProductIDSeller(productId: (self.detail?.productID)!, buyerId: (self.transactionDetail?.buyerId)!)).responseJSON {resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hubungi Pembeli")) {
                        let json = JSON(resp.result.value!)
                        if (json["_data"]["_id"].stringValue != "") { // Sudah pernah chat
                            t.tawarItem = Inbox(jsn: json["_data"])
                            self.navigationController?.pushViewController(t, animated: true)
                        } else { // Belum pernah chat
                            if let json = self.transactionDetail?.json["review"]
                            {
                                self.detail?.buyerId = json["buyer_id"].stringValue
                                self.detail?.buyerName = json["buyer_fullname"].stringValue
                                self.detail?.buyerImage = json["buyer_pict"].stringValue
                                self.detail?.reverse()
                                
                                t.tawarItem = self.detail
                                t.fromSeller =  true
            
                                t.toId = json["buyer_id"].stringValue
                                t.prodId = t.tawarItem.itemId
                                self.navigationController?.pushViewController(t, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Other Functions
    
    func validateTolakPesananFields() {
        if (txtvwAlasanTolak.text.isEmpty || txtvwAlasanTolak.text == self.TxtvwAlasanTolakPlaceholder) {
            // Disable tombol kirim
            btnTolakKirim.isUserInteractionEnabled = false
        } else {
            // Enable tombol kirim
            btnTolakKirim.isUserInteractionEnabled = true
        }
    }
    
    func validateKonfKirimFields() {
        let noResi = fldKonfNoResi.text == nil ? "" : fldKonfNoResi.text!
        if (noResi.isEmpty || imgFotoBukti.image == nil) { // Masih ada yang kosong
            // Disable tombol kirim
            btnKonfKirim.backgroundColor = Theme.PrimaryColor
            btnKonfKirim.isUserInteractionEnabled = false
        } else {
            // Enable tombol kirim
            btnKonfKirim.backgroundColor = Theme.PrimaryColor
            btnKonfKirim.isUserInteractionEnabled = true
        }
    }
    
    func sendMode(_ mode: Bool) {
        if (mode) {
            // Disable konfkirim content
            fldKonfNoResi.isUserInteractionEnabled = false
            btnFotoBukti.isUserInteractionEnabled = false
            btnKonfBatal.isUserInteractionEnabled = false
            btnKonfKirim.isUserInteractionEnabled = false
            btnKonfKirim.setTitle("MENGIRIM...", for: UIControlState())
            btnKonfKirim.backgroundColor = Theme.PrimaryColorDark
            
            // Disable tolak pesanan content
            txtvwAlasanTolak.isUserInteractionEnabled = false
            btnTolakBatal.isUserInteractionEnabled = false
            btnTolakKirim.setTitle("MENGIRIM...", for: UIControlState())
            btnTolakKirim.isUserInteractionEnabled = false
            btnTolakKirim.backgroundColor = Theme.PrimaryColorDark
        } else {
            // Enable konfkirim content
            fldKonfNoResi.isUserInteractionEnabled = true
            btnFotoBukti.isUserInteractionEnabled = true
            btnKonfBatal.isUserInteractionEnabled = true
            btnKonfKirim.isUserInteractionEnabled = true
            btnKonfKirim.setTitle("KIRIM", for: UIControlState())
            btnKonfKirim.backgroundColor = Theme.PrimaryColor
            
            // Enable tolak pesanan content
            txtvwAlasanTolak.isUserInteractionEnabled = true
            btnTolakBatal.isUserInteractionEnabled = true
            btnTolakKirim.setTitle("KIRIM", for: UIControlState())
            btnTolakKirim.isUserInteractionEnabled = true
            btnTolakKirim.backgroundColor = Theme.PrimaryColor
        }
    }
}
