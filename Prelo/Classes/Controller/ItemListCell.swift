//
//  ItemListCell.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/15/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import UIKit

class ItemListCell: UITableViewCell {
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet var imgFreeOngkir: UIImageView!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet var iconPrice: UIImageView!
    @IBOutlet var lblRentPrice: UILabel!
    @IBOutlet var iconRentPrice: UIImageView!
    @IBOutlet weak var lblCommentCount: UILabel!
    @IBOutlet weak var lblLoveCount: UILabel!
    
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
    }
    
    func adapt(_ userPurchase : UserTransaction) {
        if (userPurchase.productImageURL != nil) {
            imgProduct.afSetImage(withURL: userPurchase.productImageURL!)
        }
        lblProductName.text = userPurchase.productName
        lblPrice.text = "\(userPurchase.totalPrice.asPrice)"
        lblCommentCount.text = ""
        lblLoveCount.text = ""
        
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

    
    func showHideInfoProdTransCell(state: Int){
        switch state {
        case 1:
            iconPrice.isHidden = false
            lblPrice.isHidden = false
            iconRentPrice.isHidden = true
            lblRentPrice.isHidden = true
        case 2:
            iconPrice.isHidden = true
            lblPrice.isHidden = true
            iconRentPrice.isHidden = false
            lblRentPrice.isHidden = false
        default:
            iconPrice.isHidden = false
            lblPrice.isHidden = false
            iconRentPrice.isHidden = false
            lblRentPrice.isHidden = false
        }
    }
}
