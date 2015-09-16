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
    @IBOutlet weak var lblOrderTime: UILabel!
    
    func adapt(userPurchase : UserPurchase) {
        imgProduct.setImageWithUrl(userPurchase.productImageURL!, placeHolderImage: nil)
        lblProductName.text = userPurchase.productName
        lblPrice.text = userPurchase.productPrice.string
        lblCommentCount.text = userPurchase.productCommentCount.string
        lblLoveCount.text = userPurchase.productLoveCount.string
        lblOrderStatus.text = userPurchase.progressText
        lblOrderTime.text = userPurchase.time
    }
}
