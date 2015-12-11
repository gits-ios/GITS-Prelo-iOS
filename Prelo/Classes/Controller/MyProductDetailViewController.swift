//
//  MyProductDetailViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/22/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyProductDetailViewController : BaseViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate {
    
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
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblSellerName: UILabel!
    @IBOutlet weak var lblOrderStatus: UILabel!
    @IBOutlet weak var lblOrderTime: UILabel!
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
    var transactionDetail : TransactionDetail?
    
    var contactUs : UIViewController?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tampilkan loading
        contentView.hidden = true
        loading.startAnimating()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Agar shadow transparan
        vwShadow.backgroundColor = UIColor.colorWithColor(UIColor.blackColor(), alpha: 0.7)
        
        // Sembunyikan shadow dan pop up
        //vwShadow.hidden = true
        //vwKonfKirim.hidden = true
        
        // Agar icon kamera menjadi bulat
        vwIconKamera.layer.cornerRadius = (vwIconKamera.frame.size.width) / 2
        
        // Set delegate
        fldKonfNoResi.delegate = self
        fldKonfNoResi.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        
        self.validateKonfKirimFields()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load content
        getProductDetail()
        
        // Penanganan kemunculan keyboard
        self.an_subscribeKeyboardWithAnimations ({ r, t, o in
            if (o) {
                self.consTopVwKonfKirim.constant = 10
            } else {
                self.consTopVwKonfKirim.constant = 100
            }
        }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func getProductDetail() {
        request(APITransaction.TransactionDetail(id: transactionId!)).responseJSON {req, _, res, err in
            println("Product detail req = \(req)")
            if (err != nil) { // Terdapat error
                println("Error getting transaction detail: \(err!.description)")
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                println("data = \(data)")
                if (data == nil) { // Data kembalian kosong
                    let obj : [String : String] = res as! [String : String]
                    let message = obj["_message"]
                    println("Empty transaction detail, message: \(message)")
                } else { // Berhasil
                    
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
        
        // Set back button
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: "backPressed:")
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
        lblNamaPengiriman.text = transactionDetail?.shippingRecipientName
        lblNoTelpPengiriman.text = "0222503593"//transactionDetail?.shippingRecipientPhone
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
            lblDescription.text = "Pembayaran sedang diproses"
        } else {
            let expireText = ((transactionDetail?.expireTime != nil) ? (transactionDetail?.expireTime)! : "-")
            lblDescription.text = "Transaksi ini belum dibayar dan akan expired pada \(expireText). Ingatkan Buyer untuk segera membayar"
        }
        
        // Nama dan gambar reviewer
        lblReviewerName.text = transactionDetail?.reviewerName
        if (transactionDetail?.reviewerImageURL != nil) {
            imgReviewer.setImageWithUrl((transactionDetail?.reviewerImageURL)!, placeHolderImage: nil)
        }
        
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
        
        // Konfirmasi Pengiriman pop up
        lblKonfKurir.text = transactionDetail?.shippingName
        lblKonfOngkir.text = transactionDetail?.shippingPrice
        
        // Fix order status text width
        let orderStatusFitSize = lblOrderStatus.sizeThatFits(lblOrderStatus.frame.size)
        consWidthOrderStatus.constant = orderStatusFitSize.width
        
        // Fix order status text color
        if (orderStatusText == OrderStatus.Dibayar || orderStatusText == OrderStatus.Direview) { // teks hijau
            lblOrderStatus.textColor = Theme.PrimaryColor
        } else {
            lblOrderStatus.textColor == Theme.ThemeOrange
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
        } else if (orderStatusText == OrderStatus.Dibayar) {
            p = [true, false, true, true, true, true, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Dikirim) {
            p = [true, false, true, true, false, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.PembayaranPending) {
            p = [true, true, false, false, false, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Direview) {
            p = [true, false, true, true, false, false, true, false, false, true, true]
        } else if (orderStatusText == OrderStatus.Diterima) {
            p = [true, false, false, false, false, false, true, true, true, false, true]
        } else {
            p = [true, false, false, false, false, false, false, false, false, false, true]
        }
        arrangeGroups(p)
        
        // Show content
        loading.stopAnimating()
        contentView.hidden = false
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func arrangeGroups(isShowGroups : [Bool]) {
        let narrowSpace : CGFloat = 15
        let wideSpace : CGFloat = 25
        var deltaX : CGFloat = 0
        for (var i = 0; i < isShowGroups.count; i++) { // asumsi i = 0-10
            let isShowGroup : Bool = isShowGroups[i]
            if isShowGroup {
                groups[i].hidden = false
                // Manual narrow/wide space
                if (i == 0 || i == 5 || i == 4 || i == 7 || i == 8 || i == 9) { // Narrow space before group
                    deltaX += narrowSpace
                } else if (i == 1 || i == 2 || i == 3 || i == 5 || i == 6 || i == 10) { // Wide space before group
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
    
    // MARK: - GestureRecognizer Functions
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UIButton.classForCoder()) || touch.view.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - ImagePickerDelegate Functions
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        
        imgFotoBukti.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        vwFotoBuktiContent.hidden = true
        vwShadow.hidden = false
        vwKonfKirim.hidden = false
        
        self.validateKonfKirimFields()
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        
        vwShadow.hidden = false
        vwKonfKirim.hidden = false
        
        self.validateKonfKirimFields()
    }
    
    // MARK: - UITextFieldDelegate Functions
    
    func textFieldDidChange(textField: UITextField) {
        self.validateKonfKirimFields()
    }
    
    // MARK: - IBActions
    
    @IBAction func disableTextFields(sender : AnyObject) {
        fldKonfNoResi.resignFirstResponder()
    }
    
    @IBAction func konfirmasiPengirimanPressed(sender: AnyObject) {
        vwShadow.hidden = false
        vwKonfKirim.hidden = false
    }
    
    @IBAction func tolakPenawaranPressed(sender: AnyObject) {
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
    
    @IBAction func fotoBuktiPressed(sender: AnyObject) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        if TARGET_IPHONE_SIMULATOR == 1 {
            imagePicker.sourceType = .PhotoLibrary
        } else {
            imagePicker.sourceType = .Camera // Lie, it'll be executed ->
        }
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func konfBatalPressed(sender: AnyObject) {
        vwShadow.hidden = true
        vwKonfKirim.hidden = true
    }
    
    @IBAction func konfKirimPressed(sender: AnyObject) {
        self.sendMode(true)
        
        var dataRep = UIImageJPEGRepresentation(imgFotoBukti.image, 1)
        
        upload(APITransaction.ConfirmShipping(tpId: self.transactionId!, resiNum: fldKonfNoResi.text), multipartFormData: { form in
            form.appendBodyPart(data: dataRep, name: "image", fileName: "image.jpeg", mimeType: "image/jpeg")
            }, encodingCompletion: { result in
                switch result {
                case .Success(let s, _, _) :
                    s.responseJSON {_, _, res, err in
                        println("res = \(res)")
                        if let error = err {
                            Constant.showDialog("Warning", message: "Upload bukti pengiriman gagal")// dengan error: \(err)")
                            self.sendMode(false)
                        } else if let result : AnyObject = res {
                            let json = JSON(result)
                            println("json = \(json)")
                            let data : Bool? = json["_data"].bool
                            if (data == nil || data == false) { // Gagal
                                let msg = json["message"]
                                Constant.showDialog("Warning", message: "Upload bukti pengiriman gagal")//: \(msg)")
                                self.sendMode(false)
                            } else { // Berhasil
                                Constant.showDialog("Success", message: "Konfirmasi pengiriman berhasil dilakukan")
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        }
                    }
                case .Failure(let err) :
                    Constant.showDialog("Warning", message: "Upload bukti pengiriman gagal")// dengan error: \(err)")
                    self.sendMode(false)
                }
        })
    }
    
    @IBAction func hubungiBuyerPressed(sender: AnyObject) {
        // Get product detail from API
        request(Products.Detail(productId: (transactionDetail?.productId)!)).responseJSON {req, _, res, err in
            println("Get product detail req = \(req)")
            if (err != nil) { // Terdapat error
                Constant.showDialog("Warning", message: "Error getting product detail")//: \(err!.description)")
            } else {
                let json = JSON(res!)
                if (json == nil || json == []) { // Data kembalian kosong
                    println("Empty product detail")
                } else { // Berhasil
                    let pDetail = ProductDetail.instance(json)
                    
                    // Goto chat
                    let t = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdTawar) as! TawarViewController
                    t.tawarItem = pDetail
                    self.navigationController?.pushViewController(t, animated: true)
                }
            }
        }
    }
    
    // MARK: - Other Functions
    
    func validateKonfKirimFields() {
        if (fldKonfNoResi.text.isEmpty || imgFotoBukti.image == nil) { // Masih ada yang kosong
            // Disable tombol kirim
            btnKonfKirim.backgroundColor = Theme.PrimaryColor
            btnKonfKirim.userInteractionEnabled = false
        } else {
            // Enable tombol kirim
            btnKonfKirim.backgroundColor = Theme.PrimaryColor
            btnKonfKirim.userInteractionEnabled = true
        }
    }
    
    func sendMode(mode: Bool) {
        if (mode) {
            fldKonfNoResi.userInteractionEnabled = false
            btnFotoBukti.userInteractionEnabled = false
            btnKonfBatal.userInteractionEnabled = false
            btnKonfKirim.userInteractionEnabled = false
            btnKonfKirim.setTitle("MENGIRIM...", forState: .Normal)
            btnKonfKirim.backgroundColor = Theme.PrimaryColorDark
        } else {
            fldKonfNoResi.userInteractionEnabled = true
            btnFotoBukti.userInteractionEnabled = true
            btnKonfBatal.userInteractionEnabled = true
            btnKonfKirim.userInteractionEnabled = true
            btnKonfKirim.setTitle("KIRIM", forState: .Normal)
            btnKonfKirim.backgroundColor = Theme.PrimaryColor
        }
    }
}