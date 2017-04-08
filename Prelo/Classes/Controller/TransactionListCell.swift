//
//  TransactionListCell.swift
//  Prelo
//
//  Created by Fransiska on 9/16/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class TransactionListCell : UITableViewCell {
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet var imgFreeOngkir: UIImageView!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblCommentCount: UILabel!
    @IBOutlet weak var lblLoveCount: UILabel!
    @IBOutlet weak var lblOrderStatus: UILabel!
    @IBOutlet weak var consWidthLblOrderStatus: NSLayoutConstraint!
    @IBOutlet weak var lblOrderTime: UILabel!
    
    @IBOutlet var vwShareStatus: UIView!
    @IBOutlet var lblInstagram: UILabel!
    @IBOutlet var lblFacebook: UILabel!
    @IBOutlet var lblTwitter: UILabel!
    @IBOutlet var lblPercentage: UILabel!
    
    @IBOutlet var imgProduct2 : UIImageView!
    @IBOutlet var imgProduct3 : UIImageView!
    @IBOutlet var captionMore : UILabel!
    
    @IBOutlet var imgs : [UIView] = []
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imgFreeOngkir.isHidden = true
        vwShareStatus.isHidden = true
        lblInstagram.textColor = UIColor.lightGray
        lblFacebook.textColor = UIColor.lightGray
        lblTwitter.textColor = UIColor.lightGray
        lblPercentage.text = "-"
        imgProduct.image = nil
        lblProductName.text = "Nama Barang"
        lblPrice.text = "Rp -"
        lblCommentCount.text = "0"
        lblLoveCount.text = "0"
        lblOrderStatus.text = "-"
        lblOrderStatus.textColor = Theme.ThemeOrange
        lblOrderTime.text = "-"
        
        imgProduct.afCancelRequest()
        if imgProduct2 != nil {
            imgProduct2.afCancelRequest()
        }
        if imgProduct3 != nil {
            imgProduct3.afCancelRequest()
        }
    }
    
    func adaptItem(_ userPurchase : UserTransactionItem) {
        if (userPurchase.productImageURL != nil) {
            imgProduct.afSetImage(withURL: userPurchase.productImageURL!)
        }
        if (userPurchase.isFreeOngkir) {
            imgFreeOngkir.isHidden = false
        }
        lblProductName.text = userPurchase.productName
        lblPrice.text = "\(userPurchase.totalPrice.asPrice)"
        lblCommentCount.text = "\(userPurchase.productCommentCount)"
        lblLoveCount.text = "\(userPurchase.productLoveCount)"
        lblOrderStatus.text = userPurchase.progressText.uppercased()
        lblOrderTime.text = userPurchase.time
        
        // Fix order status text width
        let sizeThatShouldFitTheContent = lblOrderStatus.sizeThatFits(lblOrderStatus.frame.size)
        //print("size untuk '\(lblOrderStatus.text)' = \(sizeThatShouldFitTheContent)")
        consWidthLblOrderStatus.constant = sizeThatShouldFitTheContent.width
        
        // Fix order status text color
        let orderStatusText = userPurchase.progressText
        if (orderStatusText == OrderStatus.Dibayar || orderStatusText == OrderStatus.Direview || orderStatusText == OrderStatus.Selesai) { // teks hijau
            lblOrderStatus.textColor = Theme.PrimaryColor
        } else if (orderStatusText == OrderStatus.TidakDikirimSeller || orderStatusText == OrderStatus.DibatalkanSeller) { // Teks merah
            lblOrderStatus.textColor = UIColor.red
        } else {
            lblOrderStatus.textColor = Theme.ThemeOrange
        }
    }
    
    func adapt(_ userPurchase : UserTransaction) {
        if (userPurchase.productImageURL != nil) {
            imgProduct.afSetImage(withURL: userPurchase.productImageURL!)
        }
        lblProductName.text = userPurchase.productName
        lblPrice.text = "\(userPurchase.totalPrice.asPrice)"
        lblCommentCount.text = ""
        lblLoveCount.text = ""
        lblOrderStatus.text = userPurchase.progressText.uppercased()
        lblOrderTime.text = userPurchase.time
        
        // Fix order status text width
        let sizeThatShouldFitTheContent = lblOrderStatus.sizeThatFits(lblOrderStatus.frame.size)
        //print("size untuk '\(lblOrderStatus.text)' = \(sizeThatShouldFitTheContent)")
        consWidthLblOrderStatus.constant = sizeThatShouldFitTheContent.width
        
        // Fix order status text color
        let orderStatusText = userPurchase.progressText
        if (orderStatusText == OrderStatus.Dibayar || orderStatusText == OrderStatus.Direview || orderStatusText == OrderStatus.Selesai) { // teks hijau
            lblOrderStatus.textColor = Theme.PrimaryColor
        } else if (orderStatusText == OrderStatus.TidakDikirimSeller || orderStatusText == OrderStatus.DibatalkanSeller) { // Teks merah
            lblOrderStatus.textColor = UIColor.red
        } else {
            lblOrderStatus.textColor = Theme.ThemeOrange
        }
        
        let images = userPurchase.productImages
        for v in imgs
        {
            v.isHidden = true
        }
        
        if (images.count > 0)
        {
            for i in 0...images.count-1
            {
                if (i > imgs.count-1)
                {
                    break
                }
                
                let v = imgs[i]
                v.isHidden = false
                let url = images[i]
                if (i == 0)
                {
                    imgProduct.afSetImage(withURL: url)
                }
                
                if (i == 1)
                {
                    imgProduct2.afSetImage(withURL: url)
                }
                
                if (i == 2)
                {
                    imgProduct3.afSetImage(withURL: url)
                }
                
                if (i == 3)
                {
                    captionMore.text = String(images.count-3) + "+"
                }
            }
        }
    }
}
