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

// MARK: - Enum
enum ProductDetail2SectionType {
    // type    <---->    number of cell
    case cover            // 1
    case titleProduct     // 1
    case seller           // 1
    case description      // 1
    case descSell         // 2 // 0
    case descRent         // 2 // 0
    case comment          // 1 + <count-of comment> + 1
    
    var numberOfCell: Int {
        switch(self) {
        case .cover,
             .titleProduct,
             .seller,
             .description     : return 1
        case .descSell,
             .descRent,
             .comment         : return 2
        }
    }
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
    var productDetail : ProductDetail!
    var isOpen = true
    
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
    
    // view
    var listSections: Array<ProductDetail2SectionType> = []
    var thisScreen = ""
    var loginComment = false
    
    // MARK: - Init
    
    func setupTableView() {
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.contentInset = inset
        
        tableView.separatorStyle = .none
        
        tableView.backgroundColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.showLoading()
        
        let ProductDetail2CoverCell = UINib(nibName: "ProductDetail2CoverCell", bundle: nil)
        tableView.register(ProductDetail2CoverCell, forCellReuseIdentifier: "ProductDetail2CoverCell")
        
        let ProductDetail2TitleCell = UINib(nibName: "ProductDetail2TitleCell", bundle: nil)
        tableView.register(ProductDetail2TitleCell, forCellReuseIdentifier: "ProductDetail2TitleCell")
        
        let ProductDetail2SellerCell = UINib(nibName: "ProductDetail2SellerCell", bundle: nil)
        tableView.register(ProductDetail2SellerCell, forCellReuseIdentifier: "ProductDetail2SellerCell")
        
        let ProductDetail2DescriptionCell = UINib(nibName: "ProductDetail2DescriptionCell", bundle: nil)
        tableView.register(ProductDetail2DescriptionCell, forCellReuseIdentifier: "ProductDetail2DescriptionCell")
        
        let ProductDetail2DescriptionSellCell = UINib(nibName: "ProductDetail2DescriptionSellCell", bundle: nil)
        tableView.register(ProductDetail2DescriptionSellCell, forCellReuseIdentifier: "ProductDetail2DescriptionSellCell")
        
        let ProductDetail2DescriptionRentCell = UINib(nibName: "ProductDetail2DescriptionRentCell", bundle: nil)
        tableView.register(ProductDetail2DescriptionRentCell, forCellReuseIdentifier: "ProductDetail2DescriptionRentCell")
        
        let ProductDetail2TitleSectionCell = UINib(nibName: "ProductDetail2TitleSectionCell", bundle: nil)
        tableView.register(ProductDetail2TitleSectionCell, forCellReuseIdentifier: "ProductDetail2TitleSectionCell")
        
        let ProductDetail2CommentCell = UINib(nibName: "ProductDetail2CommentCell", bundle: nil)
        tableView.register(ProductDetail2CommentCell, forCellReuseIdentifier: "ProductDetail2CommentCell")
        
        let ProductDetail2AddCommentCell = UINib(nibName: "ProductDetail2AddCommentCell", bundle: nil)
        tableView.register(ProductDetail2AddCommentCell, forCellReuseIdentifier: "ProductDetail2AddCommentCell")
        
        self.setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.productDetail != nil {
            if AppTools.isNewCart { // v2
                let sellerId = self.productDetail.json["_data"]["seller"]["_id"].stringValue
                if CartManager.sharedInstance.contain(sellerId, productId: self.productDetail.productID) {
                    alreadyInCart = true
                } else {
                    alreadyInCart = false
                }
            } else { // v1
                if (CartProduct.isExist(productDetail.productID, email : User.EmailOrEmptyString)) {
                    alreadyInCart = true
                } else {
                    alreadyInCart = false
                }
            }
        }
        
        if (self.navigationController != nil) {
            if ((self.navigationController?.isNavigationBarHidden)! == true)
            {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }
        }
        
        if (UIApplication.shared.isStatusBarHidden) {
            UIApplication.shared.isStatusBarHidden = false
        }
        
        if (productDetail != nil && productDetail.isMyProduct == true) {
            self.thisScreen = PageName.ProductDetailMine
        } else {
            self.thisScreen = PageName.ProductDetail
        }
        
        // Google Analytics
        GAI.trackPageVisit(self.thisScreen)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setNeedsStatusBarAppearanceUpdate()
        
        if (productDetail == nil || isNeedReload) {
            getDetail()

            isNeedReload = false
        }

    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return UIApplication.shared.isStatusBarHidden
    }
    
    func setupView() {
        
        // Button disable
        if(self.productDetail.status == 4) {
            self.disableButton(self.btnUpVwSeller)
            self.disableButton(self.btnSoldVwSeller)
            self.disableButton(self.btnEditVwSeller)
            
            self.disableButton(self.btnBuyVwBuyer_Buy)
            self.disableButton(self.btnRentVwBuyer_Rent)
            self.disableButton(self.btnBuyVwBuyer_BuyRent)
        }
        
        let sellerId = productDetail.json["_data"]["seller"]["_id"].stringValue
        let listingType = productDetail.json["_data"]["listing_type"].intValue
        
        self.listSections = []
        self.listSections.append(.cover)
        self.listSections.append(.titleProduct)
        self.listSections.append(.seller)
        self.listSections.append(.description)
        
        if listingType == 0 || listingType == 2 {
            self.listSections.append(.descSell)
        }
        if listingType == 1 || listingType == 2 {
            self.listSections.append(.descRent)
        }
        
        // non-affiliate
        if !self.productDetail.isCheckout {
            self.listSections.append(.comment)
        }
        
        if User.Id == sellerId {
            self.vwSeller.isHidden = false
        } else {
            print(listingType)
            if listingType == 0 {
                self.vwBuyer_Buy.isHidden = false
            } else if listingType == 1 {
                self.vwBuyer_Rent.isHidden = false
            } else if listingType == 2 {
                self.vwBuyer_BuyRent.isHidden = false
            } else if productDetail.status == 1 {
                self.vwBuyer_PaymentConfirmation.isHidden = false
            }
            if productDetail.isCheckout { // karena affiliate juga butuh payment confirm
                print("harusnya masuk affiliate")
                self.vwBuyer_Affiliate.isHidden = false
            }
        }
        
        self.tableView.reloadData()
    }
    
    func getDetail() {
        self.showLoading()
        // API Migrasi
        let _ = request(APIProduct.detail(productId: (product?.json)!["_id"].string!, forEdit: 0))
            .responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Barang")) {
                    self.productDetail = ProductDetail.instance(JSON(resp.result.value!))
                    
                    if self.productDetail.isCheckout2Pages {
                        AppTools.switchToSingleCart(false)
                    } else {
                        AppTools.switchToSingleCart(true)
                    }
                    
                    self.title = self.productDetail.name
                    
                    //self.activated = (self.detail?.isActive)!
                    //print((self.detail?.json ?? ""))
                    
                    self.setupView()
                    
                    let userid = CDUser.getOne()?.id
                    let sellerid = self.productDetail.theirId
                    
                    if User.IsLoggedIn && sellerid != userid && !((self.product?.isCheckout)!) {
                       // self.setOptionButton()
                    } else {
                        /*
                        // ads
                        IronSource.setRewardedVideoDelegate(self)
                        
                        let userID = UIDevice.current.identifierForVendor!.uuidString
                        IronSource.setUserId(userID)
                        
                        // init with prelo official appkey
                        IronSource.initWithAppKey("60b14515", adUnits:[IS_REWARDED_VIDEO])
                        
                        // check ads mediation integration
                        ISIntegrationHelper.validateIntegration()
                        */
                    }
                    
                    // Prelo Analytic - Visit Product Detail
                    //self.sendVisitProductDetailAnalytic()
                }
                self.hideLoading()
        }
    }
    
    // MARK: - Button Action
    @IBAction func btnUpPressed(_ sender: Any) {
        self.showLoading()
        if let productId = productDetail?.productID {
            let _ = request(APIProduct.push(productId: productId)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Up Barang")) {
                    Constant.showDialog("Up Barang", message: "Up Barang Berhasil")
                }
                self.hideLoading()
            }
        }
    }
    @IBAction func btnSoldPressed(_ sender: Any) {
        let alertView = SCLAlertView(appearance: Constant.appearance)
        alertView.addButton("Ya") {
            self.showLoading()
            if let productId = self.productDetail?.productID {
                let _ = request(APIProduct.markAsSold(productId: productId, soldTo: "")).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Mark As Sold")) {
                        let json = JSON(resp.result.value!)
                        let isSuccess = json["_data"].boolValue
                        
                            self.disableButton(self.btnUpVwSeller)
                            self.disableButton(self.btnSoldVwSeller)
                            self.disableButton(self.btnEditVwSeller)
                        
                    }
                    self.hideLoading()
                }
            }
        }
        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
        alertView.showCustom("Mark As Sold", subTitle: "Apakah barang ini sudah terjual? (Aksi ini tidak bisa dibatalkan)", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    @IBAction func btnEditPressed(_ sender: Any) {
        self.showLoading()
        
        let addProduct3VC = Bundle.main.loadNibNamed(Tags.XibNameAddProduct3, owner: nil, options: nil)?.first as! AddProductViewController3
        addProduct3VC.editDoneBlock = {
            self.isNeedReload = true
        }
        addProduct3VC.topBannerText = productDetail.rejectionText
        addProduct3VC.delegate = self.delegate
        addProduct3VC.screenBeforeAddProduct = PageName.ProductDetailMine
        
        // API Migrasi
        let _ = request(APIProduct.detail(productId: productDetail.productID, forEdit: 1)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Barang")) {
                addProduct3VC.editProduct = ProductDetail.instance(JSON(resp.result.value!))
                addProduct3VC.product.isSell = false
                addProduct3VC.product.isRent = true
                self.hideLoading()
                self.navigationController?.pushViewController(addProduct3VC, animated: true)
            }
        }
    }
    
    @IBAction func btnChatPressed(_ sender: Any) {
        if let d = self.productDetail
        {
//            let t = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdTawar) as! TawarViewController
//            t.tawarItem = d
//            t.loadInboxFirst = true
//            t.prodId = d.productID
//            t.previousScreen = thisScreen
//            t.isSellerNotActive = d.IsShopClosed
//            t.phoneNumber = d.SellerPhone
//            self.navigationController?.pushViewController(t, animated: true)
        }
    }
    
    @IBAction func btnRentPressed(_ sender: Any) {
    }
    
    @IBAction func btnBuyPressed(_ sender: Any) {
        if !alreadyInCart {
            if AppTools.isNewCart { // v2
                let sellerId = self.productDetail?.json["_data"]["seller"]["_id"].stringValue
                if CartManager.sharedInstance.insertProduct(sellerId!, productId: (self.productDetail?.productID)!) {
                    // FB Analytics - Add to Cart
                    if AppTools.IsPreloProduction {
                        let fbPdata: [String : Any] = [
                            FBSDKAppEventParameterNameContentType          : "product",
                            FBSDKAppEventParameterNameContentID            : (self.productDetail?.productID)!,
                            FBSDKAppEventParameterNameCurrency             : "IDR"
                        ]
                        FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToCart, valueToSum: Double((self.productDetail?.priceInt)!), parameters: fbPdata)
                    }
                    setupView()
                    self.alreadyInCart = true
                }
            } else { // v1
                if (CartProduct.newOne((self.productDetail?.productID)!, email : User.EmailOrEmptyString, name : (self.productDetail?.name)!) == nil) {
                    Constant.showDialog("Failed", message: "Gagal Menyimpan")
                } else {
                    // FB Analytics - Add to Cart
                    if AppTools.IsPreloProduction {
                        let fbPdata: [String : Any] = [
                            FBSDKAppEventParameterNameContentType          : "product",
                            FBSDKAppEventParameterNameContentID            : (self.productDetail?.productID)!,
                            FBSDKAppEventParameterNameCurrency             : "IDR"
                        ]
                        FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToCart, valueToSum: Double((self.productDetail?.priceInt)!), parameters: fbPdata)
                    }
                    setupView()
                    self.alreadyInCart = true
                }
            }
        }
        // popup
        if (self.productDetail?.isAddToCart)! {
            self.launchAdd2cartPopUp()
        } else {
            self.addProduct2cart()
        }
    }
    
    @IBAction func btnBuyAffiliatePressed(_ sender: Any) {
        let _ = request(APIAffiliate.postCheckout(productIds: (product?.id)!, affiliateName: (productDetail?.AffiliateData?.name)!)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Checkout \((self.productDetail?.AffiliateData?.name)!)" /*"Post Affiliate Checkout"*/)) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if let checkoutUrl = data["checkout_url"].string {
                    let webVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
                    webVC.url = checkoutUrl
                    webVC.titleString = (self.productDetail?.AffiliateData?.name)!
                    webVC.affilateMode = true
                    webVC.checkoutPattern = (self.productDetail?.AffiliateData?.checkoutUrlPattern)!
                    webVC.checkoutInitiateUrl = checkoutUrl
                    webVC.checkoutSucceed = { orderId in
                        print(orderId)
                        // TODO: - navigate
                        self.navigateToOrderConfirmVC(orderId)
                        self.showLoading()
                    }
                    webVC.checkoutUnfinished = {
                        Constant.showDialog("Checkout", message: "Checkout tertunda")
                    }
                    webVC.checkoutFailed = {
                        Constant.showDialog("Checkout", message: "Checkout gagal, silahkan coba beberapa saat lagi")
                    }
                    let baseNavC = BaseNavigationController()
                    baseNavC.setViewControllers([webVC], animated: false)
                    self.present(baseNavC, animated: true, completion: nil)
                }
            }
        }
    }
    func navigateToOrderConfirmVC(_ orderId: String) {
        // get data
        let _ = request(APIAffiliate.getCheckoutResult(orderId: orderId)).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Get Affiliate Checkout")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                let tId = data["transaction_id"].stringValue
                let price = data["total_price"].stringValue
                var imgs : [URL] = []
                if let cd = data["cart_details"].array {
                    for c in cd {
                        if let ps = c["products"].array {
                            for p in ps {
                                if let pics = p["display_picts"].array {
                                    for pic in pics {
                                        if let url = URL(string: pic.stringValue) {
                                            imgs.append(url)
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                var backAccounts : Array<BankAccount> = []
                if let arr = data["affiliate_data"]["bank_accounts"].array {
                    
                    if arr.count > 0 {
                        for i in 0...arr.count-1 {
                            backAccounts.append(BankAccount.instance(arr[i])!)
                        }
                    }
                }
                
                let o = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
                
                o.orderID = orderId
                o.total = price.int64
                o.transactionId = tId
                o.isBackTwice = false
                o.isShowBankBRI = false
                o.targetBank = ""
                o.previousScreen = PageName.ProductDetail
                o.images = imgs
                o.isFromCheckout = false
                
                // hidden payment bank transfer
                //o.isMidtrans = true
                
                o.isAffiliate = true
                o.rekenings = backAccounts
                o.targetBank = backAccounts.count > 0 ? backAccounts[0].bank_name : "dummy"
                
                if let an = data["affiliate_data"]["affiliate_name"].string {
                    o.affiliatename = an
                }
                
                if let expire = data["expire_time"].string {
                    o.expireAffiliate = expire
                }
                
                if let er = data["payment_expired_remaining"].int {
                    o.remaining = er
                }
                
                o.title = "Order ID \(orderId)"
                
                self.hideLoading()
                self.navigationController?.pushViewController(o, animated: true)
            }
        }
    }
    
    @IBAction func btnConfirmPressed(_ sender: Any) {
        isNeedReload = true
        
        let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
        myPurchaseVC.previousScreen = PageName.ProductDetail
        self.navigationController?.pushViewController(myPurchaseVC, animated: true)
    }
    
    func addProduct2cart() {
        if AppTools.isNewCart {
            if AppTools.isSingleCart {
                
                isNeedReload = true
                
                let checkout2VC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2, owner: nil, options: nil)?.first as! Checkout2ViewController
                checkout2VC.previousController = self
                checkout2VC.previousScreen = thisScreen
                self.navigationController?.pushViewController(checkout2VC, animated: true)
                return
            } else {
                
                isNeedReload = true
                
                let checkout2ShipVC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2Ship, owner: nil, options: nil)?.first as! Checkout2ShipViewController
                checkout2ShipVC.previousController = self
                checkout2ShipVC.previousScreen = thisScreen
                self.navigationController?.pushViewController(checkout2ShipVC, animated: true)
                return
            }
        } else {
            
            isNeedReload = true
            
            //self.performSegue(withIdentifier: "segCart", sender: nil)
            let cart = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdCart) as! CartViewController
            cart.previousController = self
            cart.previousScreen = thisScreen
            self.navigationController?.pushViewController(cart, animated: true)
            return
        }
    }
    
    func disableButton(_ btn : UIButton) {
        btn.isUserInteractionEnabled = false
        
        if (btn.titleLabel?.text == nil || btn.titleLabel?.text == "") { // Button with uiimage icon
            btn.backgroundColor = UIColor.colorWithColor(UIColor.darkGray, alpha: 0.5)
            return
        }
        
        // Button with uilabel icon
        btn.setBackgroundImage(nil, for: UIControlState())
        btn.backgroundColor = nil
        btn.setTitleColor(Theme.GrayLight)
        btn.layer.borderColor = Theme.GrayLight.cgColor
        btn.layer.borderWidth = 1
        btn.layer.cornerRadius = 1
        btn.layer.masksToBounds = true
    }
    
    // MARK: - Section Helper
    func findSectionFromType(_ type: ProductDetail2SectionType) -> Int {
        if self.listSections.count > 0 {
            for i in 0..<self.listSections.count {
                if self.listSections[i] == type {
                    return i
                }
            }
        }
        
        return -1
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    func gotoProductComment() {
        self.showLoading()
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let c = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductComments) as! ProductCommentsController
        c.pDetail = self.productDetail
        c.previousScreen = thisScreen
        c.sendComment = {
            self.isNeedReload = true
        }
        
        self.hideLoading()
        self.navigationController?.pushViewController(c, animated: true)
    }
}

// MARK: - TableVIew Delegate
extension ProductDetailViewController2: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.listSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let listingType = productDetail.json["_data"]["listing_type"].intValue
        switch(listSections[section]) {
        case .descSell:
            if listingType == 0 && self.listSections[section] == .descSell {
                return 1
            } else if listingType == 2 && !self.isOpen { // close
                return 1
            } else {
                return self.listSections[section].numberOfCell
            }
        case .descRent:
            if listingType == 1 && self.listSections[section] == .descRent {
                return 1
            } else if listingType == 2 && self.isOpen { // close
                return 1
            } else {
                return self.listSections[section].numberOfCell
            }
        case .comment:
            return self.listSections[section].numberOfCell + (self.productDetail.discussions?.count)!
        default:
            return self.listSections[section].numberOfCell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section
        let row = indexPath.row
        let listingType = productDetail.json["_data"]["listing_type"].intValue
        switch(listSections[section]) {
        case .cover:
            return ProductDetail2CoverCell.heightFor()
        case .titleProduct:
            return ProductDetail2TitleCell.heightFor(self.productDetail)
        case .seller:
            return ProductDetail2SellerCell.heightFor()
        case .description:
            return ProductDetail2DescriptionCell.heightFor(self.productDetail)
        case .descSell:
            if listingType == 0 {
                return ProductDetail2DescriptionSellCell.heightFor(self.productDetail)
            } else {
                if row == 0 {
                    return ProductDetail2TitleSectionCell.heightFor()
                }
                return ProductDetail2DescriptionSellCell.heightFor(self.productDetail)
            }
        case .descRent:
            if listingType == 1 {
                return ProductDetail2DescriptionRentCell.heightFor()
            } else {
                if row == 0 {
                    return ProductDetail2TitleSectionCell.heightFor()
                }
                return ProductDetail2DescriptionRentCell.heightFor()
            }
        case .comment:
            if row == 0 {
                return ProductDetail2TitleSectionCell.heightFor()
            } else if row == (self.productDetail?.discussions?.count)! + 1 {
                return ProductDetail2AddCommentCell.heightFor()
            }
            return ProductDetail2CommentCell.heightFor((self.productDetail?.discussions?.objectAtCircleIndex(row - 1))!)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let listingType = productDetail.json["_data"]["listing_type"].intValue
        switch(listSections[section]) {
        case .cover:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2CoverCell") as! ProductDetail2CoverCell
            cell.adapt(self.productDetail)
            
            cell.zoomImage = { index in
                let c = CoverZoomController()
                
                c.labels = self.productDetail.imageLabels
                c.images = self.productDetail.displayPicturers
                c.index = index
                
                self.parent?.present(c, animated: true, completion: nil)
            }
            
            return cell
        case .titleProduct:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2TitleCell") as! ProductDetail2TitleCell
            cell.adapt(self.productDetail, productItem: self.productItem)
            var loveStatus = self.productDetail.json["_data"]["love"].bool
            var textToShare = ""
            if let dtl = self.productDetail {
                textToShare = "Temukan barang bekas berkualitas-ku, \(dtl.name) di Prelo hanya dengan harga \(dtl.price). Nikmati mudahnya jual-beli barang bekas berkualitas dengan aman dari ponselmu. Download aplikasinya sekarang juga di http://prelo.co.id #PreloID"
            }
            cell.shareInstagram = {
                self.showLoading()
                if (UIApplication.shared.canOpenURL(URL(string: "instagram://app")!)) {
                    
                } else {
                    Constant.showDialog("No Instagram app", message: "Silakan install Instagram dari app store terlebih dahulu")
                    self.hideLoading()
                }
            }
            cell.shareTwitter = {
                // share Twitter
            }
            cell.shareFacebook = {
                // share Facebook
            }
            cell.shareNative = {
                var item = PreloShareItem()
                let s = self.productDetail.displayPicturers.first
                item.url = URL(string: s!)
                item.text = (self.productDetail.name)
                item.permalink  = (self.productDetail.permalink)
                item.price = (self.productDetail.price)
                
                PreloShareController.Share(item, inView: (self.navigationController?.view)!, detail : self.productDetail)
            }
            cell.addComment = {
                if (User.IsLoggedIn == false)
                {
                    self.loginComment = true
                    LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
                } else
                {
                    self.gotoProductComment()
                }
            }
            cell.addLove = {
                self.showLoading()
                if(loveStatus == false){
                    // API Migrasi
                    // love product
                    let _ = request(APIProduct.love(productID: self.productDetail.productID)).responseJSON {resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Love Product")) {
                            cell.vwLove.borderColor = Theme.PrimaryColor
                            
                            for i in cell.vwLove.subviews {
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
                            let json = JSON(resp.result.value!)
                            cell.lbCountLove.text = String(json["_data"]["num_lovelist"].int!)
                            loveStatus = json["_data"]["love"].bool!
                            self.hideLoading()
                        }
                    }
                } else {
                    // API Migrasi
                    // unlove product
                    let _ = request(APIProduct.unlove(productID: self.productDetail.productID)).responseJSON {resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Unlove Product")) {
                            cell.vwLove.borderColor = Theme.GrayLight
                            
                            for i in cell.vwLove.subviews {
                                if i.isKind(of: UIButton.self) {
                                    continue
                                } else if i.isKind(of: TintedImageView.self) {
                                    (i as! TintedImageView).tint = true
                                    (i as! TintedImageView).tintColor = Theme.GrayLight
                                } else if i.isKind(of: UILabel.self) {
                                    (i as! UILabel).textColor = Theme.GrayLight
                                } else if i.isKind(of: UIView.self) {
                                    i.backgroundColor = Theme.GrayLight
                                }
                            }
                            let json = JSON(resp.result.value!)
                            cell.lbCountLove.text = String(json["_data"]["num_lovelist"].int!)
                            loveStatus = json["_data"]["love"].bool!
                            self.hideLoading()
                        }
                    }
                }
            }
            return cell
        case .seller:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2SellerCell") as! ProductDetail2SellerCell
            cell.adapt(self.productDetail)
            return cell
        case .description:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2DescriptionCell") as! ProductDetail2DescriptionCell
            cell.adapt(self.productDetail)

            
            cell.openCategory = { name, id in
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let l = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                l.currentMode = .filter
                l.fltrSortBy = "recent"
                l.fltrCategId = id
                l.previousScreen = self.thisScreen
                self.navigationController?.pushViewController(l, animated: true)
            }
            
            cell.openMerk = { name, id in
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let l = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                l.currentMode = .filter
                l.fltrSortBy = "recent"
                l.fltrBrands = [name : id]
                l.previousScreen = self.thisScreen
                self.navigationController?.pushViewController(l, animated: true)
            }
            
            return cell
        case .descSell:
            if listingType == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2DescriptionSellCell") as! ProductDetail2DescriptionSellCell
                cell.adapt(self.productDetail)
                return cell
            } else {
                if row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2TitleSectionCell") as! ProductDetail2TitleSectionCell
                    cell.adapt("JUAL", isOpen: self.isOpen, isShow: true)
                    return cell
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2DescriptionSellCell") as! ProductDetail2DescriptionSellCell
                cell.adapt(self.productDetail)
                return cell
            }
        case .descRent:
            if listingType == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2DescriptionRentCell") as! ProductDetail2DescriptionRentCell
                cell.adapt(self.productDetail)
                return cell
            } else {
                if row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2TitleSectionCell") as! ProductDetail2TitleSectionCell
                    cell.adapt("SEWA", isOpen: !self.isOpen, isShow: true)
                    return cell
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2DescriptionRentCell") as! ProductDetail2DescriptionRentCell
                cell.adapt(self.productDetail)
                return cell
            }
        case .comment:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2TitleSectionCell") as! ProductDetail2TitleSectionCell
                cell.adapt("KOMENTAR", isOpen: true, isShow: false)
                return cell
            } else if row == (self.productDetail?.discussions?.count)! + 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2AddCommentCell") as! ProductDetail2AddCommentCell
                
                cell.addComment = {
                    if (User.IsLoggedIn == false)
                    {
                        self.loginComment = true
                        LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
                    } else
                    {
                        self.gotoProductComment()
                    }
                }
                
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetail2CommentCell") as! ProductDetail2CommentCell
            cell.adapt((self.productDetail?.discussions?.objectAtCircleIndex(row  - 1))!, isBottom: row == (self.productDetail?.discussions?.count)!)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        let listingType = productDetail.json["_data"]["listing_type"].intValue
        switch(listSections[section]) {
        case .seller:
            if (!AppTools.isNewShop) {
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let d = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                d.currentMode = .shop
                if let name = self.productDetail.json["_data"]["seller"]["username"].string {
                    d.shopName = name
                }
                if let name = self.productDetail.json["_data"]["seller"]["_id"].string {
                    d.shopId = name
                }
                d.previousScreen = thisScreen
                self.navigationController?.pushViewController(d, animated: true)
                
            } else {
                let storePageTabBarVC = Bundle.main.loadNibNamed(Tags.XibNameStorePage, owner: nil, options: nil)?.first as! StorePageTabBarViewController
                storePageTabBarVC.shopId = self.productDetail.json["_data"]["seller"]["_id"].string
                storePageTabBarVC.previousScreen = thisScreen
                self.navigationController?.pushViewController(storePageTabBarVC, animated: true)
            }
        case .descSell,
             .descRent:
            if row == 0 && listingType == 2 {
                self.isOpen = !self.isOpen
                
                self.tableView.reloadSections(IndexSet.init(arrayLiteral: self.findSectionFromType(.descSell), self.findSectionFromType(.descRent)), with: .fade)
            }
        default: return
        }
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
            
            self.add2cartPopup?.gotoCart = {
                self.addProduct2cart()
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
                if let productId = self.productDetail?.productID {
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
                if let productId = self.productDetail?.productID {
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
            self.add2cartPopup?.setupPopUp(self.productDetail)
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
                self.addProduct2cart()
            }
        }
        
    }
}

extension ProductDetailViewController2: UserRelatedDelegate {
    func userCancelLogin() {
        
    }
    
    func userLoggedIn() {
        if (loginComment)
        {
            self.gotoProductComment()
        }
    }
    
    func userLoggedOut() {
        
    }
}

// MARK: - Cover Cell
class ProductDetail2CoverCell: UITableViewCell {
    @IBOutlet weak var vwContainerCarousel: UIView!
    
    var carousel: iCarousel = iCarousel()
    var pageIndicator: UIPageControl = UIPageControl()
    
    var images: Array<String> = []
    var currentPage = 0
    
    var zoomImage: (_ index: Int)->() = {_ in }
    
    override func awakeFromNib() {
        self.vwContainerCarousel.backgroundColor = Theme.GrayGranite
        self.vwContainerCarousel.addSubview(carousel)
        self.carousel.type = .timeMachine
        self.carousel.decelerationRate = 0.3
        
        self.pageIndicator.frame = CGRect(x: 0, y: 200, width: self.vwContainerCarousel.bounds.width, height: 16)
        self.vwContainerCarousel.addSubview(pageIndicator)
        
        self.carousel.delegate = self
        self.carousel.dataSource = self
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ productDetail: ProductDetail) {
        self.images = productDetail.displayPicturers
        self.carousel.frame = self.vwContainerCarousel.bounds
        self.carousel.width = AppTools.screenWidth
        
        //print(self.carousel.frame)
        
        self.pageIndicator.numberOfPages = self.images.count
        self.pageIndicator.currentPage = self.currentPage
        
        self.carousel.reloadData()
    }
    
    // 216
    static func heightFor() -> CGFloat {
        return 216
    }
}

extension ProductDetail2CoverCell: iCarouselDataSource, iCarouselDelegate {
    // http://www.theappguruz.com/blog/how-to-use-icarousel-view-controller-in-ios
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return images.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var itemView: UIImageView
        if (view == nil)
        {
            itemView = UIImageView(frame:CGRect(x: 0, y: 0, width: AppTools.screenWidth, height: 216))
            itemView.contentMode = .scaleAspectFit
        }
        else
        {
            itemView = view as! UIImageView;
        }
        itemView.afSetImage(withURL: URL(string: self.images[index])!, withFilter: .fillWithoutPlaceHolder)
        return itemView
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .spacing) {
            return value * 1.1
        }
        return value
    }
    
    func carouselDidScroll(_ carousel: iCarousel) {
        if self.currentPage != carousel.currentItemIndex {
            self.currentPage = carousel.currentItemIndex
            self.pageIndicator.currentPage = self.currentPage
        }
    }
    
    func carouselDidEndScrollingAnimation(_ carousel: iCarousel) {
        self.currentPage = carousel.currentItemIndex
        self.pageIndicator.currentPage = self.currentPage
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        self.zoomImage(index)
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
    @IBOutlet weak var vwComment: BorderedView! // subview , hide for affiliate
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
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ productDetail: ProductDetail, productItem: ProductHelperItem) {
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
        
        if let rent = product["rent"]["price"].int64, let periodType = product["rent"]["period_type"].int, rent > 0 {
            self.lbPriceRent.text = rent.asPrice + "/" + (AddProduct3RentPeriodType(rawValue: periodType)?.title)!
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
        
        let sellerId = product["seller"]["_id"].stringValue
        
        if sellerId == User.Id {
            self.vwShareSeller.isHidden = false
            self.vwShareBuyer.isHidden = true
            
            let txt = "Share untuk keuntungan lebih, keuntungan sekarang: \(productItem.productProfit)%"
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
            
            self.lbCountLove.text = String(product["num_lovelist"].int!)
            
            //if productItem.isLoved {
            if product["love"].bool! {
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
            
            if productDetail.isCheckout {
                self.vwComment.isHidden = true
            } else {
                self.vwComment.isHidden = false
                self.lbCountComment.text = productDetail.discussionCountText
            }
        }
    }
    
    // count text -> title, sell/rent, seller/buyer
    static func heightFor(_ productDetail: ProductDetail) -> CGFloat {
        let product = productDetail.json["_data"]
        
        let title = productDetail.name
        let listingType = product["listing_type"].intValue
        let sellerId = product["seller"]["_id"].stringValue
        
        // 12 + 8 + 20 + 4 + 21 + 12, fs 14pt
        let t = title.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 16), width: AppTools.screenWidth - (12 + 8 + 20 + 4 + 21 + 12))
        
        var h: CGFloat = 45 // type 0/1
        if listingType == 2 {
            h += 31
        }
        
        h += 8
        
        if sellerId == User.Id {
            h += 50
        } else {
            h += 34
        }
        
        return t.height + h // count subtitle height
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
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
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
    
    var openMerk: (_ name: String, _ id: String)->() = {_, _ in }
    var openCategory: (_ name: String, _ id: String)->() = {_, _ in }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.lbAlasanJual.numberOfLines = 0
        
        self.lbCategory.tapDelegate = self
        self.lbMerk.tapDelegate = self
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ productDetail: ProductDetail) {
        let product = productDetail.json["_data"]
        
        self.lbSpecialStory.text = productDetail.specialStory != "" ? "\"" + productDetail.specialStory + "\"" : ""
        
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
    static func heightFor(_ productDetail: ProductDetail) -> CGFloat {
        let product = productDetail.json["_data"]
        
        let specialStory = productDetail.specialStory != "" ? "\"" + productDetail.specialStory + "\"" : ""
        let description = product["description"].stringValue
        let isSize = product["size"].stringValue != "" ? true : false
        let isCacat = product["defect_description"].stringValue != "" ? true : false
        
        var categoryString = ""
        if let arr = product["category_breadcrumbs"].array, arr.count > 0 {
            for i in 1..<arr.count {
                let d = arr[i]
                let name = d["name"].stringValue
                categoryString += name
                if (i != arr.count-1) {
                    categoryString += "  "
                }
            }
        }
        
        let sellReason = productDetail.sellReason
        
        // 12 + 12, ft 14
        //let text = "\"" + specialStory
        let t = specialStory.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: AppTools.screenWidth - (12 + 12))
        
        let d = description.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: AppTools.screenWidth - (12 + 12))
        
        let c = categoryString.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: AppTools.screenWidth - 109)
        
        let r = sellReason.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: AppTools.screenWidth - 109)
        
        var h: CGFloat = 4 * 2 + 21 * 3 + 8 * 3
        if isSize {
            h += 21
        }
        
        if isCacat {
            h += 21
        }
        
        return 12 + t.height + d.height + c.height + r.height + h + 21 + 12
    }
}

extension ProductDetail2DescriptionCell: ZSWTappableLabelTapDelegate {
    func tappableLabel(_ tappableLabel: ZSWTappableLabel!, tappedAt idx: Int, withAttributes attributes: [AnyHashable: Any]!) {
        
        if let name = attributes["brand"] as? String, let id = attributes["brand_id"] as? String { // Brand clicked
            self.openMerk(name, id)
            
        } else if let name = attributes["category_name"] as? String, let id = attributes["category_id"] as? String {
            self.openCategory(name, id)
        }
    }
}

// MARK: - Description (Product) Sell Cell
class ProductDetail2DescriptionSellCell: UITableViewCell {
    @IBOutlet weak var lbSellerRegion: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ productDetail: ProductDetail) {
        let product = productDetail.json["_data"]
        
        var region = product["location"]["subdistrict_name"].stringValue
        if let reg = CDRegion.getRegionNameWithID(product["location"]["region_id"].stringValue) {
            region += ", " + reg
        }
        if region == "" {
            region = "Unknown"
        }
        
        self.lbSellerRegion.text = region
    }
    
    // count description
    static func heightFor(_ productDetail: ProductDetail) -> CGFloat {
        // 12 + 8 + 32 + 2 + 8 + 12, ft 12
        let text = "Waktu Jaminan Prelo. Belanja bergaransi dengan waktu jaminan hingga 3x24 jam setelah status barang \"Diterima\" jika barang terbukti KW, memiliki cacat yang tidak diinformasikan, atau berbeda dari yang dipesan."
        let t = text.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - (12 + 8 + 32 + 2 + 8 + 12))
        
        let product = productDetail.json["_data"]
        var region = product["location"]["subdistrict_name"].stringValue
        if let reg = CDRegion.getRegionNameWithID(product["location"]["region_id"].stringValue) {
            region += ", " + reg
        }
        if region == "" {
            region = "Unknown"
        }
        
        let r = region.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: AppTools.screenWidth - 109)
        
        return 79 - 17 + r.height + t.height + 8 + 12
    }
}

// MARK: - Description (Product) Rent Cell
class ProductDetail2DescriptionRentCell: UITableViewCell {
    @IBOutlet weak var lbDeposit: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ productDetail: ProductDetail) {
        let product = productDetail.json["_data"]
        
        self.lbDeposit.text = product["rent"]["price_deposit"].int64Value.asPrice
    }
    
    // count description
    static func heightFor() -> CGFloat {
        // 12 + 8 + 32 + 2 + 8 + 12, ft 12
        let text = "Deposi dibayarkan saat menyewa dan akan dikembalikan setelah barang kembali dalam kondisi baik."
        let t = text.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - (12 + 8 + 32 + 2 + 8 + 12))
        
        return 79 + t.height + 8 + 12
    }
}

// MARK: - Title Section Cell
// KOMENTAR / JUAL / SEWA
class ProductDetail2TitleSectionCell: UITableViewCell {
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbAccordion: UILabel! // default hide, hide if commentar, open: , close: 
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
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
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
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

