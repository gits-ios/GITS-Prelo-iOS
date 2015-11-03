//
//  TransactionListCell.swift
//  Prelo
//
//  Created by Fransiska on 9/16/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class TransactionListCell : UITableViewCell {
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblCommentCount: UILabel!
    @IBOutlet weak var lblLoveCount: UILabel!
    @IBOutlet weak var lblOrderStatus: UILabel!
    @IBOutlet weak var consWidthLblOrderStatus: NSLayoutConstraint!
    @IBOutlet weak var lblOrderTime: UILabel!
    
    @IBOutlet var imgProduct2 : UIImageView!
    @IBOutlet var imgProduct3 : UIImageView!
    @IBOutlet var captionMore : UILabel!
    
    @IBOutlet var imgs : [UIView] = []
    
    func adapt(userPurchase : UserTransaction) {
        if (userPurchase.productImageURL != nil) {
            imgProduct.setImageWithUrl(userPurchase.productImageURL!, placeHolderImage: nil)
        }
        lblProductName.text = userPurchase.productName
        lblPrice.text = "\(userPurchase.totalPrice.asPrice)"
        lblCommentCount.text = ""
        lblLoveCount.text = ""
        lblOrderStatus.text = userPurchase.progressText.uppercaseString
        lblOrderTime.text = userPurchase.time
        
        // Fix order status text width
        let sizeThatShouldFitTheContent = lblOrderStatus.sizeThatFits(lblOrderStatus.frame.size)
        //println("size untuk '\(lblOrderStatus.text)' = \(sizeThatShouldFitTheContent)")
        consWidthLblOrderStatus.constant = sizeThatShouldFitTheContent.width
        
        // Fix order status text color
        let orderStatusText = userPurchase.progressText
        if (orderStatusText == OrderStatus.Dibayar || orderStatusText == OrderStatus.Direview) { // teks hijau
            lblOrderStatus.textColor = Theme.PrimaryColor
        } else if (orderStatusText == OrderStatus.TidakDikirimSeller || orderStatusText == OrderStatus.DibatalkanSeller) { // Teks merah
            lblOrderStatus.textColor == UIColor.redColor()
        } else {
            lblOrderStatus.textColor == Theme.ThemeOrange
        }
        
        let images = userPurchase.productImages
        for v in imgs
        {
            v.hidden = true
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
                v.hidden = false
                let url = images[i]
                if (i == 0)
                {
                    imgProduct.setImageWithUrl(url, placeHolderImage: nil)
                }
                
                if (i == 1)
                {
                    imgProduct2.setImageWithUrl(url, placeHolderImage: nil)
                }
                
                if (i == 2)
                {
                    imgProduct3.setImageWithUrl(url, placeHolderImage: nil)
                }
                
                if (i == 3)
                {
                    captionMore.text = String(images.count-3) + "+"
                }
            }
        }
    }
}
