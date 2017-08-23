//
//  ProductDetailViewController2.swift
//  Prelo
//
//  Created by Djuned on 8/21/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

struct ProductHelperItem {
    var productProfit = 90
    
    var isSharedViaInstagram = false
    var isSharedViaFacebook = false
    var isSharedViaTwitter = false
    
    var isLoved = false
    var loveCount = 0
}

// MARK: - Class
class ProductDetailViewController2: BaseViewController {
    // MARK: - Properties
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
    
    var productItem = ProductHelperItem()
    
    var product : Product?
    var detail : ProductDetail?
    
    var alreadyInCart : Bool = false
    
    // up barang coin - diamond
    var isCoinUse = false
    
    var isNeedReload = false
    
    weak var delegate: MyProductDelegate?
    
    // PopUp
    // standard push popup
    var pushPopUp: PushPopup? // up
    
    // new popup paid push
    var paidPushPopup: PaidPushPopup? // chose up method
    
    // add to cart popup
    var add2cartPopup: AddToCartPopup? // add 2 cart // ab test
    
    // MARK: - Init
    
    // MARK: - Button Action
    @IBAction func btnUpPressed(_ sender: Any) {
    }
    @IBAction func btnSoldPressed(_ sender: Any) {
    }
    @IBAction func btnEditPressed(_ sender: Any) {
    }
    
    @IBAction func btnChatPressed(_ sender: Any) {
    }
    @IBAction func btnRentPressed(_ sender: Any) {
    }
    @IBAction func btnBuyPressed(_ sender: Any) {
    }
    
    @IBAction func btnBuyAffiliatePressed(_ sender: Any) {
    }
    
    @IBAction func btnConfirmPressed(_ sender: Any) {
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
}

// MARK: - Popup Controller
extension ProductDetailViewController2 {
    // MARK: - pop up push
    func launchPushPopUp(withText: String, paidAmount: Int64, coinAmount: Int) {
        self.setupPushPopUp()
        self.pushPopUp?.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.pushPopUp?.setupPopUp(withText, paidAmount: paidAmount, coinAmount: coinAmount)
            self.pushPopUp?.displayPopUp()
        })
    }
    
    func setupPushPopUp() {
        // setup popup
        if (self.pushPopUp == nil) {
            self.pushPopUp = Bundle.main.loadNibNamed("PushPopup", owner: nil, options: nil)?.first as? PushPopup
            self.pushPopUp?.frame = UIScreen.main.bounds
            self.pushPopUp?.tag = 100
            self.pushPopUp?.isHidden = true
            self.pushPopUp?.backgroundColor = UIColor.clear
            self.view.addSubview(self.pushPopUp!)
            
            self.pushPopUp?.initPopUp()
            
            self.pushPopUp?.disposePopUp = {
                self.pushPopUp?.isHidden = true
                self.pushPopUp = nil
                print("Start remove sibview")
                if let viewWithTag = self.view.viewWithTag(100) {
                    viewWithTag.removeFromSuperview()
                } else {
                    print("No!")
                }
            }
        }
        
    }
    
    // MARK: - pop up paid push
    func launchNewPopUp(withText: String, paidAmount: Int64, preloBalance: Int64, poinAmount: Int, poin: Int) {
        self.setupPopUp(withText: withText, paidAmount: paidAmount, preloBalance: preloBalance, poinAmount: poinAmount, poin: poin)
        self.paidPushPopup?.isHidden = false
        
        let isAdsAvailable = IronSource.hasRewardedVideo()
        //print(isAdsAvailable)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.paidPushPopup?.setupPopUp(isAdsAvailable)
            self.paidPushPopup?.displayPopUp()
        })
    }
    
    func setupPopUp(withText: String, paidAmount: Int64, preloBalance: Int64, poinAmount: Int, poin: Int) {
        // setup popup
        if (self.paidPushPopup == nil) {
            self.paidPushPopup = Bundle.main.loadNibNamed("PaidPushPopup", owner: nil, options: nil)?.first as? PaidPushPopup
            self.paidPushPopup?.frame = UIScreen.main.bounds
            self.paidPushPopup?.tag = 100
            self.paidPushPopup?.isHidden = true
            self.paidPushPopup?.backgroundColor = UIColor.clear
            self.view.addSubview(self.paidPushPopup!)
            
            self.paidPushPopup?.initPopUp(withText: withText, paidAmount: paidAmount, preloBalance: preloBalance, poinAmount: poinAmount, poin: poin)
            
            self.paidPushPopup?.disposePopUp = {
                self.paidPushPopup?.isHidden = true
                self.paidPushPopup = nil
                //print("Start remove sibview")
                if let viewWithTag = self.view.viewWithTag(100) {
                    viewWithTag.removeFromSuperview()
                } else {
                    //print("No!")
                }
            }
            
            self.paidPushPopup?.balanceUsed = {
                self.isCoinUse = false
                //self.showLoading()
                if let productId = self.detail?.productID {
                    let _ = request(APIProduct.paidPush(productId: productId)).responseJSON { resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Up Barang")) {
                            let json = JSON(resp.result.value!)
                            let isSuccess = json["_data"]["result"].boolValue
                            let message = json["_data"]["message"].stringValue
                            let paidAmount = json["_data"]["paid_amount"].int64Value
                            //let preloBalance = json["_data"]["my_prelo_balance"].int64Value
                            let coinAmount = json["_data"]["diamond_amount"].intValue
                            //let coin = json["_data"]["my_total_diamonds"].intValue
                            
                            if (isSuccess) {
                                // Prelo Analytic - Up Product - Balance
                                //self.sendUpProductAnalytic(productId, type: "Balance")
                                
                                self.launchPushPopUp(withText: message + " (" + paidAmount.asPrice + " telah otomatis ditarik dari Prelo Balance)", paidAmount: paidAmount, coinAmount: coinAmount)
                                
                                self.delegate?.setFromDraftOrNew(true)
                            } else {
                                self.launchPushPopUp(withText: message, paidAmount: paidAmount, coinAmount: coinAmount)
                            }
                        }
                        self.hideLoading()
                    }
                }
            }
            
            self.paidPushPopup?.poinUsed = {
                self.isCoinUse = true
                //self.showLoading()
                if let productId = self.detail?.productID {
                    let _ = request(APIProduct.paidPushWithCoin(productId: productId)).responseJSON { resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Up Barang")) {
                            let json = JSON(resp.result.value!)
                            let isSuccess = json["_data"]["result"].boolValue
                            let message = json["_data"]["message"].stringValue
                            let paidAmount = json["_data"]["paid_amount"].int64Value
                            //let preloBalance = json["_data"]["my_prelo_balance"].int64Value
                            let coinAmount = json["_data"]["diamond_amount"].intValue
                            //let coin = json["_data"]["my_total_diamonds"].intValue
                            
                            if (isSuccess) {
                                // Prelo Analytic - Up Product - Point
                                //self.sendUpProductAnalytic(productId, type: "Point")
                                
                                self.launchPushPopUp(withText: message + " (" + coinAmount.string + " Poin kamu telah otomatis ditarik)", paidAmount: paidAmount, coinAmount: coinAmount)
                                
                                self.delegate?.setFromDraftOrNew(true)
                            } else {
                                self.launchPushPopUp(withText: message, paidAmount: paidAmount, coinAmount: coinAmount)
                            }
                        }
                        self.hideLoading()
                    }
                }
            }
            
            self.paidPushPopup?.watchVideoAds = {
                // open ads
                //IronSource.showRewardedVideo(with: self, placement: "Up_Product")
                
                //  goto delegate
            }
        }
        
    }
    
    // MARK: - pop up add to cart
    
    func launchAdd2cartPopUp() {
        self.setupAdd2cartPopUp()
        self.add2cartPopup?.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.add2cartPopup?.setupPopUp(self.detail!)
            self.add2cartPopup?.displayPopUp()
        })
    }
    
    func setupAdd2cartPopUp() {
        // setup popup
        if (self.add2cartPopup == nil) {
            self.add2cartPopup = Bundle.main.loadNibNamed("AddToCartPopup", owner: nil, options: nil)?.first as? AddToCartPopup
            self.add2cartPopup?.frame = UIScreen.main.bounds
            self.add2cartPopup?.tag = 100
            self.add2cartPopup?.isHidden = true
            self.add2cartPopup?.backgroundColor = UIColor.clear
            self.view.addSubview(self.add2cartPopup!)
            
            self.add2cartPopup?.initPopUp()
            
            self.add2cartPopup?.disposePopUp = {
                self.add2cartPopup?.isHidden = true
                self.add2cartPopup = nil
                print("Start remove sibview")
                if let viewWithTag = self.view.viewWithTag(100) {
                    viewWithTag.removeFromSuperview()
                } else {
                    print("No!")
                }
            }
            
            self.add2cartPopup?.gotoCart = {
                //self.addProduct2cart()
            }
        }
        
    }
}

// MARK: - Cover Cell
class ProductDetail2CoverCell: UITableViewCell {
    @IBOutlet weak var vwContainerCarousel: UIView!
    
    
    // 216
    static func heightFor() -> CGFloat {
        return 216
    }
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
    
    @IBOutlet weak var vwShareSeller: UIView! // hide
    @IBOutlet weak var consTopVwShareSeller: NSLayoutConstraint! // 68 -> 38
    @IBOutlet weak var lbShareDetail: UILabel!
    @IBOutlet weak var vwInstagram: BorderedView! // subview
    @IBOutlet weak var vwFaceBook: BorderedView! // subview
    @IBOutlet weak var Twitter: BorderedView! // subview
    @IBOutlet weak var imgShareSeller: TintedImageView! // tint
    
    @IBOutlet weak var vwShareBuyer: UIView! // hide
    @IBOutlet weak var consTopVwShareBuyer: NSLayoutConstraint! // 68 -> 38
    @IBOutlet weak var vwLove: BorderedView! // subview
    @IBOutlet weak var lbCountLove: UILabel!
    @IBOutlet weak var vwComment: BorderedView! // subview
    @IBOutlet weak var imgComment: TintedImageView! // tinted
    @IBOutlet weak var lbCountComment: UILabel!
    @IBOutlet weak var imgShareBuyer: TintedImageView! // tint
    
    var shareInstagram: ()->() = {}
    var shareFacebook: ()->() = {}
    var shareTwitter: ()->() = {}
    var shareNative: ()->() = {} // check , is seller or not
    var addLove: ()->() = {}
    var addComment: ()->() = {}
    
    override func awakeFromNib() {
        self.imgSee.tint = true
        self.imgSee.tintColor = self.lbCountSee.textColor
        
        self.imgComment.tint = true
        self.imgComment.tintColor = self.vwComment.borderColor
    }
    
    func adapt(_ productDetail: ProductDetail, isSeller: Bool, productItem: ProductHelperItem) {
        let product = productDetail.json["_data"]
        
        //TODO: mapping ke sewa-rombakAddProduct
        self.lbTitle.text = productDetail.name
        
        let c = productDetail.totalViews > 1000 ? (Double(productDetail.totalViews) / 1000.0).roundString + "K" : productDetail.totalViews.string
        self.lbCountSee.text = c
        
        if productDetail.priceInt > 0 {
            self.lbPriceSell.text = productDetail.price
            self.vwSell.isHidden = false
        } else {
            self.consTopVwRent.constant = 8
            self.vwSell.isHidden = true
        }
        
        if product["rent_price"].int64Value > 0 {
            self.lbPriceRent.text = product["rent_price"].int64Value.asPrice + "/" + product["rent_period_type"].intValue.string
            self.vwRent.isHidden = false
            
            if !self.vwSell.isHidden {
                self.consTopVwRent.constant = 38
            }
        } else {
            self.vwRent.isHidden = true
        }
        
        if self.vwSell.isHidden || self.vwRent.isHidden {
            self.consTopVwShareSeller.constant = 38
            self.consTopVwShareBuyer.constant = 38
        } else {
            self.consTopVwShareSeller.constant = 68
            self.consTopVwShareBuyer.constant = 68
        }
        
        if isSeller {
            self.vwShareSeller.isHidden = false
            self.vwShareBuyer.isHidden = true
            
            let txt = "Share utk keuntungan lebih, keuntungan sekarang: \(productItem.productProfit)%"
            let attTxt = NSMutableAttributedString(string: txt)
            attTxt.addAttributes([NSForegroundColorAttributeName: Theme.PrimaryColor], range: (txt as NSString).range(of: "\(productItem.productProfit)%"))
            self.lbShareDetail.attributedText = attTxt
            
            for i in vwInstagram.subviews {
                if i.isKind(of: UILabel.self) {
                    if ((i as! UILabel).text?.contains("+"))! {
                        (i as! UILabel).text = "+" + UserDefaults.standard.string(forKey: UserDefaultsKey.ComInstagram)! + "%"
                    }
                    if productItem.isSharedViaInstagram {
                        (i as! UILabel).textColor = Theme.PrimaryColor
                    }
                }
                
                if productItem.isSharedViaInstagram {
                    self.vwInstagram.borderColor = Theme.PrimaryColor
                }
            }
            
            for i in vwFaceBook.subviews {
                if i.isKind(of: UILabel.self) {
                    if ((i as! UILabel).text?.contains("+"))! {
                        (i as! UILabel).text = "+" + UserDefaults.standard.string(forKey: UserDefaultsKey.ComFacebook)! + "%"
                    }
                    if productItem.isSharedViaFacebook {
                        (i as! UILabel).textColor = Theme.PrimaryColor
                    }
                }
                
                if productItem.isSharedViaFacebook {
                    self.vwFaceBook.borderColor = Theme.PrimaryColor
                }
            }
            
            for i in Twitter.subviews {
                if i.isKind(of: UILabel.self) {
                    if ((i as! UILabel).text?.contains("+"))! {
                        (i as! UILabel).text = "+" + UserDefaults.standard.string(forKey: UserDefaultsKey.ComTwitter)! + "%"
                    }
                    if productItem.isSharedViaTwitter {
                        (i as! UILabel).textColor = Theme.PrimaryColor
                    }
                }
                
                if productItem.isSharedViaTwitter {
                    self.Twitter.borderColor = Theme.PrimaryColor
                }
            }
            
        } else {
            self.vwShareSeller.isHidden = true
            self.vwShareBuyer.isHidden = false
            
            self.lbCountLove.text = productItem.loveCount.string
            
            if productItem.isLoved {
                self.vwLove.borderColor = Theme.PrimaryColor
                
                for i in vwLove.subviews {
                    if i.isKind(of: UIButton.self) {
                        continue
                    } else if i.isKind(of: TintedImageView.self) {
                        (i as! TintedImageView).tint = true
                        (i as! TintedImageView).tintColor = Theme.PrimaryColor
                    } else if i.isKind(of: UILabel.self) {
                        (i as! UILabel).textColor = Theme.PrimaryColor
                    } else if i.isKind(of: UIView.self) {
                        i.backgroundColor = Theme.PrimaryColor
                    }
                }
            }
            
            self.lbCountComment.text = productDetail.discussionCountText
        }
    }
    
    // count text -> title, sell/rent, seller/buyer
    static func heightFor(_ title: String, listingType: Int, isSeller: Bool) -> CGFloat {
        // 12 + 8 + 20 + 4 + 21 + 12, fs 14pt
        let t = title.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 14), width: AppTools.screenWidth - (12 + 8 + 20 + 4 + 21 + 12))
        
        var h: CGFloat = 38 // type 0/1
        if listingType == 2 {
            h += 38
        }
        
        h += 8
        if isSeller {
            h += 50
        } else {
            h += 34
        }
        
        return 12 + t.height + h // count subtitle height
    }
    
    @IBAction func btnInstagramPressed(_ sender: Any) {
        self.shareInstagram()
    }
    
    @IBAction func btnFacebookPressed(_ sender: Any) {
        self.shareFacebook()
    }
    
    @IBAction func btnTwitterPressed(_ sender: Any) {
        self.shareTwitter()
    }
    
    @IBAction func btnSharePressed(_ sender: Any) {
        self.shareNative()
    }
    
    @IBAction func btnLovePressed(_ sender: Any) {
        self.addLove()
    }
    
    @IBAction func btnCommentPressed(_ sender: Any) {
        self.addComment()
    }
}

// MARK: - Seller Cell
class ProductDetail2SellerCell: UITableViewCell {
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var imgBadge: UIImageView! // hide
    @IBOutlet weak var lbSellerName: UILabel!
    @IBOutlet weak var imgVerifiedSeller: UIImageView! // hide (affiliate)
    @IBOutlet weak var vwContainerLove: UIView!
    @IBOutlet weak var lbLastActiveTime: UILabel!
    
    var floatRatingView: FloatRatingView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgAvatar.layoutIfNeeded()
        imgAvatar.layer.cornerRadius = (imgAvatar.frame.size.width)/2
        imgAvatar.layer.masksToBounds = true
        
        imgAvatar.layer.borderColor = Theme.GrayLight.cgColor
        imgAvatar.layer.borderWidth = 2
        
        // Love floatable
        self.floatRatingView = FloatRatingView(frame: CGRect(x: 0, y: 0, width: 90, height: 16))
        self.floatRatingView.emptyImage = UIImage(named: "ic_love_96px_trp.png")?.withRenderingMode(.alwaysTemplate)
        self.floatRatingView.fullImage = UIImage(named: "ic_love_96px.png")?.withRenderingMode(.alwaysTemplate)
        
        self.floatRatingView.contentMode = UIViewContentMode.scaleAspectFit
        self.floatRatingView.maxRating = 5
        self.floatRatingView.minRating = 0
        
        self.floatRatingView.editable = false
        self.floatRatingView.halfRatings = true
        self.floatRatingView.floatRatings = true
        self.floatRatingView.tintColor = Theme.ThemeRed
        
        self.vwContainerLove.addSubview(self.floatRatingView)
    }
    
    func adapt(_ productDetail: ProductDetail) {
        let product = productDetail.json["_data"]
        
        self.lbSellerName.text = product["seller"]["username"].stringValue
        
        let average_star = product["seller"]["average_star"].floatValue
        self.floatRatingView.rating = average_star
        
        let lastSeenSeller = productDetail.lastSeenSeller
        if (lastSeenSeller != "") {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let lastSeenDate = formatter.date(from: lastSeenSeller) {
                self.lbLastActiveTime.text = "Terakhir aktif: \(lastSeenDate.relativeDescription)"
            }
        }
        
        self.imgAvatar.afSetImage(withURL: productDetail.shopAvatarURL!, withFilter: .circle)
        
        // affiliate
        if productDetail.isCheckout {
            self.imgVerifiedSeller.isHidden = false
        }
        
        if let arr = product["seller"]["achievements"].array, arr.count > 0 {
            let ach = AchievementItem.instance(arr[0])
            
            if ach?.icon != nil {
                self.imgBadge.afSetImage(withURL: (ach?.icon)!, withFilter: .circleWithBadgePlaceHolder)
            }
        }
    }
    
    // 94
    static func heightFor() -> CGFloat {
        return 94
    }
}

// MARK: - Description (Product) Cell
class ProductDetail2DescriptionCell: UITableViewCell {
    @IBOutlet weak var lbSpecialStory: UILabel!
    @IBOutlet weak var lbCategory: ZSWTappableLabel!
    @IBOutlet weak var lbMerk: ZSWTappableLabel!
    @IBOutlet weak var lbWeight: UILabel!
    
    @IBOutlet weak var consHeightVwSize: NSLayoutConstraint! // 0 -> 21
    @IBOutlet weak var lbSize: UILabel!
    
    @IBOutlet weak var lbCondition: UILabel!
    
    @IBOutlet weak var consHeightVwCacat: NSLayoutConstraint! // 0 -> 21
    @IBOutlet weak var lbCacat: UILabel!
    
    @IBOutlet weak var lbAlasanJual: UILabel!
    @IBOutlet weak var lbDescription: UILabel!
    @IBOutlet weak var lbTimeStamp: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.lbAlasanJual.numberOfLines = 0
    }
    
    func adapt(_ productDetail: ProductDetail) {
        let product = productDetail.json["_data"]
        
        self.lbSpecialStory.text = "\"" + productDetail.specialStory + "\""
        
        // category
        if let arr = product["category_breadcrumbs"].array, arr.count > 0 {
            var categoryString : String = ""
            var param : Array<[String : Any]> = []
            for i in 1..<arr.count {
                let d = arr[i]
                let name = d["name"].stringValue
                let p = [
                    "category_name":name,
                    "category_id":d["_id"].stringValue,
                    "range":NSStringFromRange(NSMakeRange(categoryString.length, name.length)),
                    ZSWTappableLabelTappableRegionAttributeName: Int(true),
                    ZSWTappableLabelHighlightedBackgroundAttributeName : UIColor.darkGray,
                    ZSWTappableLabelHighlightedForegroundAttributeName : UIColor.white,
                    NSForegroundColorAttributeName : Theme.PrimaryColorDark
                    ] as [String : Any]
                param.append(p)
                
                categoryString += name
                if (i != arr.count-1) {
                    categoryString += "  "
                }
            }
            
            let mystr = categoryString
            let searchstr = ""
            let ranges: [NSRange]
            
            do {
                // Create the regular expression.
                let regex = try NSRegularExpression(pattern: searchstr, options: [])
                
                // Use the regular expression to get an array of NSTextCheckingResult.
                // Use map to extract the range from each result.
                ranges = regex.matches(in: mystr, options: [], range: NSMakeRange(0, mystr.characters.count)).map {$0.range}
            }
            catch {
                // There was a problem creating the regular expression
                ranges = []
            }
            
            //print(ranges)  // prints [(0,3), (18,3), (27,3)]
            
            let attString : NSMutableAttributedString = NSMutableAttributedString(string: categoryString)
            for p in param
            {
                let r = NSRangeFromString(p["range"] as! String)
                attString.addAttributes(p, range: r)
                if ranges.count > 0 {
                    for i in 0...ranges.count-1 {
                        attString.addAttributes([NSFontAttributeName:UIFont(name: "prelo2", size: 14.0)!], range: ranges[i])
                    }
                }
                
            }
            
            self.lbCategory.attributedText = attString
        } else {
            self.lbCategory.text = "-"
        }
        
        // merk
        if let merk = product["brand"].string {
            let p = [
                "brand_id":product["brand_id"].stringValue,
                "brand":product["brand"].stringValue,
                "range":NSStringFromRange(NSMakeRange(0, merk.length)),
                ZSWTappableLabelTappableRegionAttributeName: Int(true),
                ZSWTappableLabelHighlightedBackgroundAttributeName : UIColor.darkGray,
                ZSWTappableLabelHighlightedForegroundAttributeName : UIColor.white,
                NSForegroundColorAttributeName : Theme.PrimaryColorDark
            ] as [String : Any]
            
            let brandString = merk + (product["brand_id"].stringValue != "" ? " " : "")
            let attString : NSMutableAttributedString = NSMutableAttributedString(string: brandString, attributes: p)
            
            if product["brand_id"].stringValue != "" {
                attString.addAttributes([NSFontAttributeName:UIFont(name: "preloAwesome", size: 14.0)!], range: NSMakeRange(merk.length + 1, 1))
            }
            
            self.lbMerk.attributedText = attString
        } else {
            self.lbMerk.text = "-"
        }
        
        // weight
        let w = productDetail.weight
        if (w > 1000) {
            self.lbWeight.text = (Float(w) / 1000.0).clean + " kg"
        } else {
            self.lbWeight.text = w.description + " gram"
        }
        
        // size
        let ukuran = product["size"].string
        if ukuran != nil && ukuran != "" {
            self.lbSize.text = ukuran
            self.consHeightVwSize.constant = 21
        } else {
            self.consHeightVwSize.constant = 0
        }
        
        // condition
        let condition = product["condition"].stringValue
        self.lbCondition.text = condition
        
        let cacat = product["defect_description"].stringValue
        if cacat != "" && condition == "Cukup ( < 70%)" {
            self.lbCacat.text = product["defect_description"].stringValue
            self.consHeightVwCacat.constant = 21
        } else {
            self.consHeightVwCacat.constant = 0
        }
        
        // alasan jual
        var sellReason = productDetail.sellReason
        if (sellReason == "") {
            sellReason = "-"
        }
        
        self.lbAlasanJual.text = sellReason
        
        // description & dte
        self.lbDescription.text = product["description"].stringValue
        self.lbTimeStamp.text = product["time"].stringValue
    }
    
    
    // count special story, description, + standard
    static func heightFor(_ specialStory: String, description: String, isSize: Bool, isCacat: Bool) -> CGFloat {
        // 12 + 12, ft 14
        //let text = "\"" + specialStory
        let t = specialStory.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 14), width: AppTools.screenWidth - (12 + 12))
        
        let d = description.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 14), width: AppTools.screenWidth - (12 + 12))
        
        var h: CGFloat = 21 * 5 + 8 * 3
        if isSize {
            h += 21
        }
        
        if isCacat {
            h += 21
        }
        
        return 12 + t.height + d.height + h + 21 + 12
    }
}

// MARK: - Description (Product) Sell Cell
class ProductDetail2DescriptionSellCell: UITableViewCell {
    @IBOutlet weak var lbSellerRegion: UILabel!
    
    func adapt(_ productDetail: ProductDetail) {
        let product = productDetail.json["_data"]
        
        var region = product["seller_region"]["name"].stringValue
        if region == "" {
            region = "Unknown"
        }
        
        self.lbSellerRegion.text = region
    }
    
    // count description
    static func heightFor() -> CGFloat {
        // 12 + 8 + 32 + 2 + 8 + 12, ft 12
        let text = "Waktu Jaminan Prelo. Belanja bergaransi dengan waktu jaminan hingga 3x24 jam setelah status barang \"Diterima\" jika barang terbukti KW, memiliki cacat yang tidak diinformasikan, atau berbeda dari yang dipesan."
        let t = text.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 12), width: AppTools.screenWidth - (12 + 8 + 32 + 2 + 8 + 12))
        
        return 79 + t.height + 8 + 12
    }
}

// MARK: - Description (Product) Rent Cell
class ProductDetail2DescriptionRentCell: UITableViewCell {
    @IBOutlet weak var lbDeposit: UILabel!
    
    func adapt(_ productDetail: ProductDetail) {
        let product = productDetail.json["_data"]
        
        self.lbDeposit.text = product["seller_region"]["rent_price_deposit"].int64Value.asPrice
    }
    
    // count description
    static func heightFor() -> CGFloat {
        // 12 + 8 + 32 + 2 + 8 + 12, ft 12
        let text = "Deposi dibayarkan saat menyewa dan akan dikembalikan setelah barang kembali dalam kondisi baik."
        let t = text.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 12), width: AppTools.screenWidth - (12 + 8 + 32 + 2 + 8 + 12))
        
        return 79 + t.height + 8 + 12
    }
}

// MARK: - Title Section Cell
// KOMENTAR / JUAL / SEWA
class ProductDetail2TitleSectionCell: UITableViewCell {
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbAccordion: UILabel! // default hide, hide if commentar, open: , close: 
    
    func adapt(_ title: String, isOpen: Bool, isShow: Bool) {
        self.lbTitle.text = title
        
        if isShow {
            self.lbAccordion.isHidden = false
            
            if isOpen {
                self.lbAccordion.text = ""
            } else {
                self.lbAccordion.text = ""
            }
        } else {
            self.lbAccordion.isHidden = true
        }
    }
    
    // 43
    static func heightFor() -> CGFloat {
        return 43
    }
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
    
    var openShop: ()->() = {}
    var reportComment: ()->() = {}
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgAvatar.layoutIfNeeded()
        imgAvatar.layer.cornerRadius = (imgAvatar.frame.size.width)/2
        imgAvatar.layer.masksToBounds = true
        
        imgAvatar.layer.borderColor = Theme.GrayLight.cgColor
        imgAvatar.layer.borderWidth = 2
    }
    
    func adapt(_ productDiscussion: ProductDiscussion, isBottom: Bool) {
        self.imgAvatar.afSetImage(withURL: productDiscussion.posterImageURL!, withFilter: .circle)
        
        self.lbComment.text = productDiscussion.message
        
        self.lbSellerName.text = productDiscussion.json["sender_username"].stringValue
        
        self.lbTimeStamp.text = productDiscussion.json["time"].stringValue
        
        if User.Id == productDiscussion.json["sender_id"].stringValue {
            self.btnAction.isHidden = true
        } else {
            self.btnAction.isHidden = false
        }
        
        if isBottom {
            self.vw1px.isHidden = true
        } else {
            self.vw1px.isHidden = false
        }
    }
    
    // 72 / 73, count comment
    static func heightFor(_ productDiscussion: ProductDiscussion) -> CGFloat {
        let s = productDiscussion.message.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 72 - 8)
        
        return 59 + s.height
    }
    
    @IBAction func btnSellerPressed(_ sender: Any) {
        self.openShop()
    }
    
    @IBAction func btnReportPressed(_ sender: Any) {
        self.reportComment()
    }
}

// MARK: - Add Comment Cell (btn)
class ProductDetail2AddCommentCell: UITableViewCell {
    var addComment: ()->() = {}
    
    // 75
    static func heightFor() -> CGFloat {
        return 75
    }
    
    @IBAction func btnAddCommentPressed(_ sender: Any) {
        self.addComment()
    }
}

// MARK: - PushPopup
// PaidPushPopup -> ProductDetail VC
class PushPopup: UIView {
    @IBOutlet weak var vwBackgroundOverlay: UIView!
    @IBOutlet weak var vwOverlayPopUp: UIView!
    @IBOutlet weak var vwPopUp: UIView!
    @IBOutlet weak var consCenteryPopUp: NSLayoutConstraint!
    @IBOutlet weak var lbDescription: UILabel!
    
    var disposePopUp : ()->() = {}
    var upLainnya : ()->() = {}
    
    func setupPopUp(_ text: String, paidAmount: Int64, coinAmount: Int) {
        self.lbDescription.text = text
        self.lbDescription.boldSubstring(paidAmount.asPrice)
        self.lbDescription.boldSubstring(coinAmount.string + " Poin")
    }
    
    func initPopUp() {
        // Transparent panel
        self.vwBackgroundOverlay.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        
        self.vwBackgroundOverlay.isHidden = false
        self.vwOverlayPopUp.isHidden = false
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
    }
    
    func displayPopUp() {
        let screenSize = self.bounds
        let screenHeight = screenSize.height
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = (screenHeight - self.vwPopUp.frame.height) / 2 - 32
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = -32
    }
    
    func unDisplayPopUp() {
        let screenSize = self.bounds
        let screenHeight = screenSize.height
        
        // force to bottom first
        self.consCenteryPopUp.constant = 0
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = screenHeight + (screenHeight - self.vwPopUp.frame.height) / 2 - 32
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = screenHeight
    }
    
    @IBAction func btnUpLainnyaPressed(_ sender: Any) {
        self.unDisplayPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.upLainnya()
            self.disposePopUp()
        })
    }
    
    @IBAction func btnOkePressed(_ sender: Any) {
        self.unDisplayPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.disposePopUp()
        })
    }
}

