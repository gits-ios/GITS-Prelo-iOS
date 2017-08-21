//
//  ProductDetailViewController2.swift
//  Prelo
//
//  Created by Djuned on 8/21/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class
class ProductDetailViewController2: BaseViewController {
    // default height 0
    @IBOutlet weak var vwNotification: UIView!
    @IBOutlet weak var consHeightVwNotification: NSLayoutConstraint!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    // default hide
    @IBOutlet weak var vwSeller: UIView!
    @IBOutlet weak var btnUpVwSeller: UIButton!
    @IBOutlet weak var btnSoldVwSeller: UIButton!
    @IBOutlet weak var btnEditVwSeller: UIButton! // icon
    
    // default hide
    @IBOutlet weak var vwBuyer_BuyRent: UIView!
    @IBOutlet weak var btnChatVwBuyer_BuyRent: UIButton! // icon
    @IBOutlet weak var btnRentVwBuyer_BuyRent: UIButton! // icon
    @IBOutlet weak var btnBuyVwBuyer_BuyRent: UIButton! // icon
    
    // default hide
    @IBOutlet weak var vwBuyer_Buy: UIView!
    @IBOutlet weak var btnChatVwBuyer_Buy: UIButton! // icon
    @IBOutlet weak var btnBuyVwBuyer_Buy: UIButton! // icon
    
    // default hide
    @IBOutlet weak var vwBuyer_Rent: UIView!
    @IBOutlet weak var btnChatVwBuyer_Rent: UIButton! // icon
    @IBOutlet weak var btnRentVwBuyer_Rent: UIButton! // icon
    
    // default hide
    @IBOutlet weak var vwBuyer_Affiliate: UIView!
    @IBOutlet weak var btnBuyVwBuyer_Affiliate: UIButton! // icon
    
    // default hide
    @IBOutlet weak var vwBuyer_PaymentConfirmation: UIView!
    @IBOutlet weak var btnConfirmVwBuyer_PaymentConfirmation: UIButton!
}

// MARK: - Cover Cell
class ProductDetail2CoverCell: UITableViewCell {
    @IBOutlet weak var vwContainerCarousel: UIView!
    
}

// MARK: - Title (Product) Cell
class ProductDetail2TitleCell: UITableViewCell {
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var imgSee: TintedImageView! // tint
    @IBOutlet weak var lbCountSee: UILabel!
    
    // default show
    @IBOutlet weak var vwSell: UIView! // hide
    @IBOutlet weak var lbPriceSell: UILabel!
    
    // default show
    @IBOutlet weak var vwRent: UIView! // hide
    @IBOutlet weak var consTopVwRent: NSLayoutConstraint! // 38 -> 8
    @IBOutlet weak var lbPriceRent: UILabel!
    
    @IBOutlet weak var vwShareSeller: UIView!
    @IBOutlet weak var consTopVwShareSeller: NSLayoutConstraint! // 68 -> 38
    @IBOutlet weak var lbShareDetail: UILabel!
    @IBOutlet weak var vwInstagram: BorderedView! // subview
    @IBOutlet weak var vwFaceBook: BorderedView! // subview
    @IBOutlet weak var Twitter: BorderedView! // subview
    @IBOutlet weak var imgShareSeller: TintedImageView! // tint
    
    @IBOutlet weak var vwShareBuyer: UIView!
    @IBOutlet weak var consTopVwShareBuyer: NSLayoutConstraint! // 68 -> 38
    @IBOutlet weak var vwLove: BorderedView! // subview
    @IBOutlet weak var lbCountLove: UILabel!
    @IBOutlet weak var vwComment: BorderedView! // subview
    @IBOutlet weak var lbCountComment: UILabel!
    @IBOutlet weak var imgShareBuyer: TintedImageView! // tint
    
}

// MARK: - Seller Cell
class ProductDetail2SellerCell: UITableViewCell {
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var imgBadge: UIImageView! // hide
    @IBOutlet weak var lbSellerName: UILabel!
    @IBOutlet weak var imgVerifiedSeller: UIImageView! // hide (affiliate)
    @IBOutlet weak var vwContainerLove: UIView!
    @IBOutlet weak var lbLastActiveTime: UILabel!
    
}

// MARK: - Description (Product) Cell
class ProductDetail2DescriptionCell: UITableViewCell {
    @IBOutlet weak var lbSpecialStory: UILabel!
    @IBOutlet weak var lbCategory: ZSWTappableLabel!
    @IBOutlet weak var lbMerk: ZSWTappableLabel!
    @IBOutlet weak var lbWeight: UILabel!
    
    @IBOutlet weak var consHeightVwSize: NSLayoutConstraint! // 0 -> 17
    @IBOutlet weak var lbSize: UILabel!
    
    @IBOutlet weak var lbCondition: UILabel!
    
    @IBOutlet weak var consHeightVwCacat: NSLayoutConstraint! // 0 -> 17
    @IBOutlet weak var lbCacat: UILabel!
    
    @IBOutlet weak var lbAlasanJual: UILabel!
    @IBOutlet weak var lbDescription: UILabel!
    @IBOutlet weak var lbTimeStamp: UILabel!
    
}

// MARK: - Description (Product) Sell Cell
class ProductDetail2DescriptionSellCell: UITableViewCell {
    @IBOutlet weak var lbSellerRegion: UILabel!
    
}

// MARK: - Description (Product) Rent Cell
class ProductDetail2DescriptionRentCell: UITableViewCell {
    @IBOutlet weak var lbDeposit: UILabel!
    
}

// MARK: - Title Section Cell
// KOMENTAR / JUAL / SEWA
class ProductDetail2TitleSectionCell: UITableViewCell {
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbAccordion: UILabel! // hide if commentar, open: , close: 
    
    
    
}

// MARK: - Comment Cell
// -> Product Comments Controller (v2)
class ProductDetail2CommentCell: UITableViewCell {
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var lbComment: UILabel!
    @IBOutlet weak var lbSellerName: UILabel!
    @IBOutlet weak var lbTimeStamp: UILabel!
    @IBOutlet weak var btnAction: UIButton! // hide if no action (self)
    @IBOutlet weak var vw1px: UIView! // hide if bottom cell
    
}

// MARK: - Add Comment Cell (btn)
class ProductDetail2AddCommentCell: UITableViewCell {
    
}
