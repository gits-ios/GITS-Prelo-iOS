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
    
    func adapt(userPurchase : UserTransaction) {
        imgProduct.setImageWithUrl(userPurchase.productImageURL!, placeHolderImage: nil)
        lblProductName.text = userPurchase.productName
        lblPrice.text = "Rp " + userPurchase.productPrice.string
        lblCommentCount.text = userPurchase.productCommentCount.string
        lblLoveCount.text = userPurchase.productLoveCount.string
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
    }
}
