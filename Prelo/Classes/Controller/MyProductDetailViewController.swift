//
//  MyProductDetailViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/22/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyProductDetailViewController : BaseViewController {
    
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
    
    @IBOutlet weak var lblMetodePembayaran: UILabel!
    @IBOutlet weak var lblTglPembayaran: UILabel!
    
    @IBOutlet weak var btnKonfirmasiPengiriman: UIButton!
    
    @IBOutlet weak var lblKurirPengiriman: UILabel!
    @IBOutlet weak var lblNoPengiriman: UILabel!
    @IBOutlet weak var lblTglPengiriman: UILabel!
    
    @IBOutlet weak var btnHubungiBuyer: UIButton!
    
    @IBOutlet weak var imgReviewer: UIImageView!
    @IBOutlet weak var lblReviewerName: UILabel!
    @IBOutlet weak var lblHearts: UILabel!
    @IBOutlet weak var lblReviewContent: UILabel!
    
    var transactionId : String?
    var transactionDetail : TransactionDetail?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tampilkan loading
        contentView.hidden = true
        loading.startAnimating()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.sharedInstance().track("My Product Detail")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load content
        getProductDetail()
    }
    
    func getProductDetail() {
        request(APITransaction.TransactionDetail(id: transactionId!)).responseJSON {req, _, res, err in
            println("Product detail req = \(req)")
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
            p = [true, true, false, false, false, false, false, false, true, false, true]
        } else if (orderStatusText == OrderStatus.Dibayar) {
            p = [true, false, true, true, true, false, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Dikirim) {
            p = [true, false, true, false, false, true, false, false, false, false, true]
        } else if (orderStatusText == OrderStatus.Direview) {
            p = [true, false, true, false, false, true, true, false, false, true, true]
        } else if (orderStatusText == OrderStatus.Diterima) {
            p = [true, false, false, false, false, false, true, true, true, false, true]
        } else {
            p = [true, false, false, false, false, false, false, false, false, false, true]
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
        lblDescription.text = "Transaksi ini belum dibayar dan akan expired pada \(transactionDetail?.paymentDate). Ingatkan Buyer untuk segera membayar"
        // TODO: ganti jadi expiration date
        
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
        
        // Fix order status text width
        let orderStatusFitSize = lblOrderStatus.sizeThatFits(lblOrderStatus.frame.size)
        consWidthOrderStatus.constant = orderStatusFitSize.width
        
        // Fix order status text color
        if (orderStatusText == OrderStatus.Dibayar || orderStatusText == OrderStatus.Direview) { // teks hijau
            lblOrderStatus.textColor = Theme.PrimaryColor
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
    
    func arrangeGroups(isShowGroups : [Bool]) {
        let narrowSpace : CGFloat = 15
        let wideSpace : CGFloat = 25
        var deltaX : CGFloat = 0
        for (var i = 0; i < isShowGroups.count; i++) { // asumsi i = 0-10
            let isShowGroup : Bool = isShowGroups[i]
            if isShowGroup {
                groups[i].hidden = false
                // Manual narrow/wide space
                if (i == 0 || i == 3 || i == 4 || i == 7 || i == 8 || i == 9) { // Narrow space before group
                    deltaX += narrowSpace
                } else if (i == 1 || i == 2 || i == 5 || i == 6 || i == 10) { // Wide space before group
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
    
    @IBAction func konfirmasiPengirimanPressed(sender: AnyObject) {
        
    }
    
    @IBAction func hubungiBuyerPressed(sender: AnyObject) {
        
    }
}