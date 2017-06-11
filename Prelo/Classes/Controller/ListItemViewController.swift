//
//  ListItemViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import MessageUI
import Alamofire
import AlamofireImage

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}

// MARK: - Class

enum ListItemSectionType {
    case carousel
    case featuredHeader
    case subcategories
    case segments
    case products
    case aboutShop
}

enum ListItemMode {
    case `default`
    case standalone
    case shop
    case featured
    case segment
    case filter
    case newShop
}

class ListItemViewController: BaseViewController, MFMailComposeViewControllerDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, FilterDelegate, CategoryPickerDelegate, ListBrandDelegate, FBNativeAdDelegate, FBNativeAdsManagerDelegate {
    
    // MARK: - Struct
    
    struct SegmentItem {
        var type : String = ""
        var name : String = ""
        //var image : UIImage = UIImage()
        var imageLink : URL?
        
        var subCategories : [JSON]?
    }
    
    struct SubcategoryItem {
        var id : String = ""
        var name : String = ""
        //var image : UIImage = UIImage()
        var imageLink : URL?
    }
    
    // MARK: - Properties
    
    // From listcategoryvc
    var scrollCategoryName : UIScrollView?
    
    // Top buttton view, used for segment mode
    @IBOutlet var vwTopHeader: UIView!
    @IBOutlet var consHeightVwTopHeader: NSLayoutConstraint!
    @IBOutlet var lblTopHeader: UILabel!
    
    // Banner header
    var bannerImageUrl = ""
    var bannerTargetUrl = ""
    
    // Gridview and layout
    @IBOutlet var gridView: UICollectionView!
    @IBOutlet var consTopGridView: NSLayoutConstraint!
    @IBOutlet var consTopTopHeader: NSLayoutConstraint!
    var footerLoading : UIActivityIndicatorView?
    var refresher : UIRefreshControl?
    var itemCellWidth: CGFloat? = 200
    var listStage = 2 // Column amount in list: 1 = 3 column, 2 = 2 column, 3 = 1 column
    var currScrollPoint : CGPoint = CGPoint.zero
    var itemsPerReq = 24 // Amount of items per request
    
    // Data container
    var categoryJson : JSON? // Set from previous screen
    var products : Array <Product>? // From API response
    var selectedProduct : Product? // For navigating to product detail
    var listItemSections : [ListItemSectionType] = [.products]
    
    // Flags
    var requesting : Bool = false
    var done : Bool = false
    var draggingScrollView : Bool = false
    var isContentLoaded : Bool = false
    
    // Mode
    var currentMode = ListItemMode.default
    // For standalone mode, used for category-filtered product list
    var standaloneCategoryName : String = ""
    var standaloneCategoryID : String = ""
    // For shop page mode
    var shopId = ""
    var shopName = ""
    var shopHeader : StoreHeader?
    var shopAvatar : URL?
    // For segment mode
    var segments : [SegmentItem] = []
    var selectedSegment : String = ""
    // For filter/search result mode
    // Predefined values
    var isBackToFltrSearch = false
    var fltrCategId : String = ""
    var fltrSegment : String = ""
    var fltrBrands : [String : String] = [:] // [name:id]
    // Predefined values from filtervc
    var fltrProdCondIds : [String] = []
    var fltrPriceMin : NSNumber = 0
    var fltrPriceMax : NSNumber = 0
    var fltrIsFreeOngkir : Bool = false
    var fltrSizes : [String] = []
    var fltrSortBy : String = "" // "recent"/"lowest_price"/"highest_price"/"popular"
    var fltrLocation : [String] = ["Semua Provinsi", "", "0", ""] // name , id, type --> 0: province, 1: region, 2: subdistrict, parentids --> <province id>;<region id>
    var fltrAggregateId : String = "" // agregateid
    // Views
    @IBOutlet var vwTopHeaderFilter: UIView!
    @IBOutlet var consTopTopHeaderFilter: NSLayoutConstraint!
    @IBOutlet var lblFilterMerek: UILabel!
    @IBOutlet var lblFilterKategori: UILabel!
    @IBOutlet var lblFilterSort: UILabel!
    var searchBar : UISearchBar!
    @IBOutlet var vwFilterZeroResult: UIView!
    @IBOutlet var btnFilterZeroResult: UIButton!
    @IBOutlet var lblFilterZeroResult: UILabel!
    // Others
    var fltrName : String = ""
    let FltrValSortBy : [String : String] = ["recent" : "Terkini", "lowest_price" : "Lowest Rp", "highest_price" : "Highest Rp", "popular" : "Populer"]
    
    // For carousel
    var isShowCarousel : Bool = false
    var carouselItems : [CarouselItem] = []
    var isCarouselTimerSet : Bool = false
    
    // For subcategory
    var isShowSubcategory : Bool = false
    var subcategoryItems : [SubcategoryItem] = []
    
    // state navbar for .shop
    var isFirst = true
    var isTransparent = true
    var initY = CGFloat(0)
    
    var floatRatingView: FloatRatingView!
    
    // delegate for newShop
    weak var delegate: NewShopHeaderDelegate?
    var newShopHeader : StoreInfo?
    var shopData: JSON!
    var isExpand = false
    var star = Float(0)
    
    var isFeatured: Bool = false
    
    // FB-ads
    var adRowStep: Int = 19 // fit for 1, 2, 3
    
    var adsManager: FBNativeAdsManager!
    
    var adsCellProvider: FBNativeAdCollectionViewCellProvider!
    
    // filter
    var isHiddenTop = false
    
    // need refresh
    var curTime: TimeInterval!
    var interval: Double!
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        curTime = NSDate().timeIntervalSince1970 // init time
        //interval = 60.0 * 60.0 * 3 // 3 hours
        
        var minute = UserDefaults.standard.integer(forKey: UserDefaultsKey.RefreshTime)
        if minute <= 0 {
            minute = 60 * 3
        }
        interval = 60.0 * Double(minute)
        
        let frequency = UserDefaults.standard.integer(forKey: UserDefaultsKey.AdsFrequency)
        if frequency > 0 {
            self.adRowStep = frequency // 37
        }
        
        if currentMode == .shop || currentMode == .newShop {
            self.navigationController?.navigationBar.isTranslucent = true
        }
        
        if (currentMode == .newShop) {
            let StoreInfo = UINib(nibName: "StorePageShopHeader", bundle: nil)
            gridView.register(StoreInfo, forCellWithReuseIdentifier: "StorePageShopHeader")
        }
        
        // listStage initiation
        if (AppTools.isIPad) {
            listStage = 1
        } else {
            listStage = 2
        }
        
        // Set title
        switch currentMode {
        case .standalone:
            self.title = standaloneCategoryName
//        case .shop:
//            self.title = shopName
        default:
            if let name = categoryJson?["name"].string {
                self.title = name
            }
        }
        
        // Hide top header first
        self.consHeightVwTopHeader.constant = 0
        
        // Initiate refresh control
        refresher = UIRefreshControl()
        refresher!.tintColor = Theme.PrimaryColor
        refresher!.addTarget(self, action: #selector(ListItemViewController.refresh), for: UIControlEvents.valueChanged)
        self.gridView.addSubview(refresher!)
        
        // Setup content for filter, shop, or standalone mode
        if (currentMode == .standalone || currentMode == .shop || currentMode == .filter || currentMode == .newShop) {
            self.setupContent()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Status bar style
        self.setStatusBarStyle(style: .lightContent)
        
        // Add status bar tap observer
        NotificationCenter.default.addObserver(self, selector: #selector(ListItemViewController.statusBarTapped), name: NSNotification.Name(rawValue: AppDelegate.StatusBarTapNotificationName), object: nil)
        
//        // ads
//        if (currentMode == .filter) {
//            configureAdManagerAndLoadAds()
//        }
        
        // fixer
        self.repositionScrollCategoryNameContent(false)
        
        if currentMode == .filter {
            self.setStatusBarBackgroundColor(color: Theme.PrimaryColor)
            
            // Prelo Analytic - Filter
            self.sendFilterAnalytic()
        }
        
        if currentMode == .shop || currentMode == .newShop {
            self.navigationController?.navigationBar.isTranslucent = true
        }
        
        // for handle navigation
        if (currentMode == .shop && self.isTransparent) {
            self.isTransparent = !self.isTransparent
            self.transparentNavigationBar(true)
            self.isFirst = false
            
        } else if (currentMode == .newShop && (self.delegate?.getTransparentcy())!) {
            self.delegate?.setTransparentcy(!((self.delegate?.getTransparentcy())!))
            self.transparentNavigationBar(true)
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ////print("viewWillDisappear x")
        
        // Show navbar - non animated
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "showBottomBar"), object: nil)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.repositionScrollCategoryNameContent(false)
        self.showStatusBar()
        
        // Remove status bar tap observer
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: AppDelegate.StatusBarTapNotificationName), object: nil)
        
        // Status bar color
        if (currentMode == .filter) {
            self.setStatusBarBackgroundColor(color: UIColor.clear)
         
            // reset header
            self.consTopTopHeaderFilter.constant = 0
            self.consTopGridView.constant = 0
            
        } else if (currentMode == .shop || currentMode == .newShop) {
            self.defaultNavigationBar()
            
        } else if (currentMode == .segment) {
            if (selectedSegment != "") {
                consHeightVwTopHeader.constant = 40 // Show top header
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.layoutIfNeeded()
                })
            }
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (self.isBackToFltrSearch) {
            // gesture override
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
            // swipe gesture for carbon (pop view)
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
            swipeRight.direction = UISwipeGestureRecognizerDirection.right
            
            let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
            vwLeft.backgroundColor = UIColor.clear
            vwLeft.addGestureRecognizer(swipeRight)
            self.view.addSubview(vwLeft)
            self.view.bringSubview(toFront: vwLeft)
        }
        
        // Default search text && status bar color for filter mode
        if (currentMode == .filter) {
            self.searchBar.text = self.fltrName
            self.setStatusBarBackgroundColor(color: Theme.PrimaryColor)
            
            if isHiddenTop {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                UIView.animate(withDuration: 0.2, animations: {
                    self.consTopTopHeaderFilter.constant = UIApplication.shared.statusBarFrame.height
                    self.consTopGridView.constant = UIApplication.shared.statusBarFrame.height
                })
            }
        }
        
        // Mixpanel for store mode
        if (currentMode == .shop || currentMode == .newShop) {
            if (User.IsLoggedIn && self.shopId == User.Id!) {
                // Mixpanel
//                Mixpanel.trackPageVisit(PageName.ShopMine)
                
                // Google Analytics
                GAI.trackPageVisit(PageName.ShopMine)
            } else {
                // Mixpanel
//                let p = [
//                    "Seller" : shopName,
//                    "Seller ID" : self.shopId
//                ]
//                Mixpanel.trackPageVisit(PageName.Shop, otherParam: p)
                
                // Google Analytics
                GAI.trackPageVisit(PageName.Shop)
            }
        }
        
        // fixer
        self.repositionScrollCategoryNameContent(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // fixer
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        if (self.isBackToFltrSearch) {
            let viewControllers: [UIViewController] = (self.navigationController?.viewControllers)!
            
            // gesture override
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            
            _ = self.navigationController?.popToViewController(viewControllers[1], animated: true);
        } else {
            
            // gesture override
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Swipe Navigation Override
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                //print("Swiped right")
                
                // gesture override
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                
                let viewControllers: [UIViewController] = (self.navigationController?.viewControllers)!
                    _ = self.navigationController?.popToViewController(viewControllers[1], animated: true);
                
            default:
                break
            }
        }
    }
    
    // MARK: - Setup
    
    func setupContent() {
        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.Prelo",
                                            qos: .background,
                                            attributes: .concurrent,
                                            target: nil)
        backgroundQueue.async {
            
            if (!self.isContentLoaded) {
                self.isContentLoaded = true
                
                if !Reachability.isConnectedToNetwork() {
                    self.isContentLoaded = false
                    return
                }
                
                // Default, Standalone, Shop, and Filter mode is predefined
                // Featured and Segment mode will be identified here
                // Carousel and Subcategories also will be identified here
                
                // Identify Segment mode
                if let segmentsJson = self.categoryJson?["segments"].array, segmentsJson.count > 0 {
                    self.currentMode = .segment
                    for i in 0...segmentsJson.count - 1 {
                        //var img : UIImage = UIImage()
                        var imgUrl : URL!
                        if let url = URL(string: segmentsJson[i]["image"].stringValue) {
                            imgUrl = url
                            //if let data = try? Data(contentsOf: url) {
                            //    if let uiimg = UIImage(data: data) {
                            //        img = uiimg
                            //    }
                            //}
                        }
                        //self.segments.append(SegmentItem(type: segmentsJson[i]["type"].stringValue, name: segmentsJson[i]["name"].stringValue, image: img))
                        self.segments.append(SegmentItem(type: segmentsJson[i]["type"].stringValue, name: segmentsJson[i]["name"].stringValue, imageLink: imgUrl, subCategories: segmentsJson[i]["sub_categories"].array))
                    }
                    self.listItemSections.remove(at: self.listItemSections.index(of: .products)!)
                    self.listItemSections.insert(.segments, at: 0)
                }
                // Identify Featured mode
                if let isFeatured = self.categoryJson?["is_featured"].bool, isFeatured {
                    self.currentMode = .featured
                    self.listItemSections.insert(.featuredHeader, at: 0)
                    
                    self.isFeatured = true
                }
                // Identify Subcategories
                if let subcatJson = self.categoryJson?["sub_categories"].array, subcatJson.count > 0 && self.currentMode != .segment {
                    self.isShowSubcategory = true
                    for i in 0...subcatJson.count - 1 {
                        //var img : UIImage = UIImage()
                        var imgUrl : URL!
                        if let url = URL(string: subcatJson[i]["image"].stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!) {
                            imgUrl = url
                            //if let data = try? Data(contentsOf: url) {
                            //    if let uiimg = UIImage(data: data) {
                            //        img = uiimg
                            //    }
                            //}
                        }
                        //self.subcategoryItems.append(SubcategoryItem(id: subcatJson[i]["_id"].stringValue, name: subcatJson[i]["name"].stringValue, image: img))
                        self.subcategoryItems.append(SubcategoryItem(id: subcatJson[i]["_id"].stringValue, name: subcatJson[i]["name"].stringValue, imageLink: imgUrl))
                    }
                    self.listItemSections.insert(.subcategories, at: 0)
                }
                // Identify Carousel
                if let carouselJson = self.categoryJson?["carousel"].array, carouselJson.count > 0 {
                    self.isShowCarousel = true
                    self.carouselItems = []
                    for i in 0..<carouselJson.count {
                        //var img = UIImage()
                        var imgLink : URL!
                        var link : URL!
                        //if let url = URL(string: carouselJson[i]["image"].stringValue), let data = try? Data(contentsOf: url), let uiimg = UIImage(data: data) {
                        //    img = uiimg
                        //}
                        if let url = URL(string: carouselJson[i]["image"].stringValue) {
                            imgLink = url
                        }
                        if let url = URL(string: carouselJson[i]["link"].stringValue) {
                            link = url
                        }
                        //let item = CarouselItem.init(name: carouselJson[i]["name"].stringValue, img: img, link: link)
                        let item = CarouselItem.init(name: carouselJson[i]["name"].stringValue, imgLink: imgLink, link: link)
                        self.carouselItems.append(item)
                    }
                    self.listItemSections.insert(.carousel, at: 0)
                }
                
                // Adjust content base on the mode
                switch (self.currentMode) {
                case .default, .standalone:
                    DispatchQueue.main.async(execute: {
                        // Upper 4px padding handling
                        self.consTopTopHeader.constant = 4
                        
                        // Top header setup
                        self.consHeightVwTopHeader.constant = 0
                    })
                    // Get initial products
                    self.getInitialProducts()
                case .shop, .newShop:
                    DispatchQueue.main.async(execute: {
                        // Upper 4px padding handling
                        self.consTopTopHeader.constant = 0
                        
                        // Top header setup
                        self.consHeightVwTopHeader.constant = 0
                    })
                    // Get initial products
                    self.getInitialProducts()
                case .featured:
                    DispatchQueue.main.async(execute: {
                        // Upper 4px padding handling
                        self.consTopTopHeader.constant = 4
                        
                        // Top header setup
                        self.consHeightVwTopHeader.constant = 0
                        
                        // Set color
                        if let name = self.categoryJson?["name"].string, name.lowercased() == "all" {
                            self.view.backgroundColor = Theme.GrayGranite // Upper 4px padding color
                            self.gridView.backgroundColor = Theme.GrayGranite // Background color
                        }
                    })
                    // Get initial products
                    self.getInitialProducts()
                case .segment:
                    DispatchQueue.main.async(execute: {
                        // Top header setup
                        self.consHeightVwTopHeader.constant = 40
                        
                        // Show segments
                        self.setDefaultTopHeaderWomen()
                        
                        // Setup grid
                        self.setupGrid()
                    })
                case .filter:
                    DispatchQueue.main.async(execute: {
                        // Upper 4px padding handling
                        self.consTopTopHeader.constant = 4
                        self.view.backgroundColor = UIColor(hexString: "#E8ECEE")
                        
                        // Top header setup
                        self.consHeightVwTopHeader.constant = 52
                        
                        // Setup filter related views
                        for i in 0...self.vwTopHeaderFilter.subviews.count - 1 {
                            self.vwTopHeaderFilter.subviews[i].createBordersWithColor(UIColor(hexString: "#e3e3e3"), radius: 0, width: 1)
                        }
                        self.vwTopHeaderFilter.isHidden = false
                        self.vwTopHeader.isHidden = true
                        if (self.fltrBrands.count > 0) {
                            if (self.fltrBrands.count == 1) {
                                self.lblFilterMerek.text = [String](self.fltrBrands.keys)[0]
                            } else {
                                self.lblFilterMerek.text = [String](self.fltrBrands.keys)[0] + ", \(self.fltrBrands.count - 1)+"
                            }
                        } else {
                            self.lblFilterMerek.text = "All"
                        }
                        if (self.fltrCategId == "") {
                            self.lblFilterKategori.text = "All"
                        } else {
                            self.lblFilterKategori.text = CDCategory.getCategoryNameWithID(self.fltrCategId)
                        }
                        self.lblFilterSort.text = self.FltrValSortBy[self.fltrSortBy]
                        if (self.lblFilterSort.text?.lowercased() == "highest rp") {
                            self.lblFilterSort.font = UIFont.boldSystemFont(ofSize: 12)
                        } else {
                            self.lblFilterSort.font = UIFont.boldSystemFont(ofSize: 13)
                        }
                        // Search bar setup
                        var searchBarWidth = UIScreen.main.bounds.size.width * 0.8375
                        if (AppTools.isIPad) {
                            searchBarWidth = UIScreen.main.bounds.size.width - 68
                        }
                        self.searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: searchBarWidth, height: 30))
                        if let searchField = self.searchBar.value(forKey: "searchField") as? UITextField {
                            searchField.backgroundColor = Theme.PrimaryColorDark
                            searchField.textColor = UIColor.white
                            let attrPlaceholder = NSAttributedString(string: "Cari di Prelo", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
                            searchField.attributedPlaceholder = attrPlaceholder
                            if let icon = searchField.leftView as? UIImageView {
                                icon.image = icon.image?.withRenderingMode(.alwaysTemplate)
                                icon.tintColor = UIColor.lightGray
                            }
                            searchField.borderStyle = UITextBorderStyle.none
                        }
                        self.searchBar.delegate = self
                        self.searchBar.placeholder = "Cari di Prelo"
                        self.navigationItem.rightBarButtonItem = self.searchBar.toBarButton()
                    })
                    // Get initial products
                    self.getInitialProducts()
                }
                
                // ads
                if (self.currentMode == .filter || self.currentMode == .default) {
                    self.configureAdManagerAndLoadAds()
                }
            } else if (self.products != nil && (self.products?.count)! <= 24 && (self.products?.count)! > 0) || self.currentMode == .featured {
                
                // refrsher
                let _curTime = NSDate().timeIntervalSince1970
                
                if (_curTime - self.curTime) >= self.interval {
                    self.curTime = _curTime
                    
                    /*DispatchQueue.main.async(execute: {
                     self.refresher?.beginRefreshing()
                     })*/
                    
                    self.refresh()
                }
            }
        }
    }
    
    func getInitialProducts() {
        if (products?.count == 0 || products == nil) {
            if (products == nil) {
                products = []
            }
            getProducts()
        }
    }
    
    func refresh() {
        if !Reachability.isConnectedToNetwork() {
            Constant.showDisconnectBanner()
            self.refresher?.endRefreshing()
            return
        }
        
        if (self.currentMode == .shop && self.isFirst == false) {
            self.transparentNavigationBar(false)
        }
        
        self.requesting = true
        self.products = []
        self.done = false
        self.footerLoading?.isHidden = false
        DispatchQueue.main.async(execute: {
            self.gridView.reloadData()
            //self.setupGrid() // Agar muncul loading
        })
        
        switch (currentMode) {
        case .shop, .filter, .newShop:
            self.getProducts()
        case .featured:
            self.getFeaturedProducts()
        case .segment:
            if (self.listItemSections.contains(.products)) {
                self.getProducts()
            } else {
                self.refresher?.endRefreshing()
                DispatchQueue.main.async(execute: {
                    //self.setupGrid()
                    self.gridView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0)
                })
            }
        default:
            requesting = true
            
            var catId : String?
            if (currentMode == .standalone) {
                catId = standaloneCategoryID
            } else {
                catId = categoryJson!["_id"].string
            }
            
            var lastTimeUuid = ""
            if (products != nil && products?.count > 0) {
                lastTimeUuid = products![products!.count - 1].updateTimeUuid
            }
            let _ = request(APISearch.productByCategory(categoryId: catId!, sort: "", current: 0, limit: itemsPerReq, priceMin: 0, priceMax: 999999999, segment: selectedSegment, lastTimeUuid: lastTimeUuid)).responseJSON { resp in
                self.footerLoading?.isHidden = false
                self.requesting = false
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Barang")) {
                    self.products = []
                    var obj = JSON(resp.result.value!)
                    for (_, item) in obj["_data"] {
                        let p = Product.instance(item)
                        if (p != nil) {
                            self.products?.append(p!)
                        }
                    }
                    self.refresher?.endRefreshing()
                    DispatchQueue.main.async(execute: {
                        self.setupGrid()
                    })
                }
            }
        }
    }
    
    func getProducts() {
        switch (self.currentMode) {
        case .default:
            if let catId = self.categoryJson?["_id"].string {
                self.getCategorizedProducts(catId)
            }
        case .standalone:
            self.getCategorizedProducts(self.standaloneCategoryID)
        case .shop:
            self.getShopProducts()
        case .featured:
            self.getFeaturedProducts()
        case .segment:
            if (self.listItemSections.contains(.products)) {
                if let catId = self.categoryJson?["_id"].string {
                    self.getCategorizedProducts(catId)
                }
            }
        case .filter:
            self.getFilteredProducts()
        
        case .newShop:
            self.getNewShopProducts()
        }
    }
    
    func getCategorizedProducts(_ catId : String) {
        requesting = true
        
        let current = products!.count
        let lastSec = self.gridView.numberOfSections - 1
        
        var lastTimeUuid = ""
        if (products != nil && products?.count > 0) {
            lastTimeUuid = products![products!.count - 1].updateTimeUuid
        }
        let _ = request(APISearch.productByCategory(categoryId: catId, sort: "recent", current: current, limit: itemsPerReq, priceMin: 0, priceMax: 999999999, segment: selectedSegment, lastTimeUuid: lastTimeUuid)).responseJSON { resp in
            self.requesting = false
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Product By Category")) {
                self.setupData(resp.result.value)
                
                if self.currentMode == .segment && !self.listItemSections.contains(.subcategories) {
                    self.setupSubcategoriesInsideSegment()
                }
            }
            self.refresher?.endRefreshing()
            
            if current == 0 {
                DispatchQueue.main.async(execute: {
                    self.setupGrid()
                })
            } else {
                DispatchQueue.main.async(execute: {
                    //UIView.performWithoutAnimation {
                        self.gridView.reloadSections(NSIndexSet(index: lastSec) as IndexSet)
                    //}
                })
            }
        }
    }
    
    func getFeaturedProducts() {
        if (categoryJson == nil) {
            return
        }
        
        requesting = true
        
        let req = request(APIProduct.getAllFeaturedProducts(categoryId: self.categoryJson!["_id"].stringValue)).responseJSON { resp in
            self.requesting = false
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Featured Products")) {
                self.products = []
                
                self.setupData(resp.result.value)
            }
            self.refresher?.endRefreshing()
            DispatchQueue.main.async(execute: {
                self.setupGrid()
            })
        }
        
        
        // testing gzip
        if AppTools.isDev {
            let t = ((APIProduct.getAllFeaturedProducts(categoryId: self.categoryJson!["_id"].stringValue)).urlRequest?.allHTTPHeaderFields?.description) ?? ""
            req.responseData(completionHandler: { (resp) in
                /*
                Constant.showDialog("Response", message: (resp.data?.debugDescription)! + "\n\n" + resp.debugDescription)
                Constant.showDialog("Response Header", message: (resp.response?.allHeaderFields.description)!)
                Constant.showDialog("Request", message: t)
                */
                print("\nRequest:\n" + t)
                print("\nResponse Header:\n" + (resp.response?.allHeaderFields.description)!)
                print("\nResponse:\n" + (resp.data?.debugDescription)! + "\n" + resp.debugDescription)
            })
        }
    }
    
    func getFilteredProducts() {
        requesting = true
        
        let current = products!.count
        let lastSec = self.gridView.numberOfSections - 1
        
        let fltrNameReq = self.fltrName
        var lastTimeUuid = ""
        if (products != nil && products?.count > 0) {
            lastTimeUuid = products![products!.count - 1].updateTimeUuid
        }
        
        let parentids = self.fltrLocation[3].components(separatedBy: ";")
        let provinceId =  self.fltrLocation[2].int == 0 ? self.fltrLocation[1] : parentids[0]
        let regionId =  self.fltrLocation[2].int == 1 ? self.fltrLocation[1] : (parentids.count > 1 ? parentids[1] : "")
        let subDistrictId =  self.fltrLocation[2].int == 2 ? self.fltrLocation[1] : ""
        
        let _ = request(APISearch.productByFilter(name: fltrName, aggregateId: fltrAggregateId, categoryId: fltrCategId, brandIds: AppToolsObjC.jsonString(from: [String](fltrBrands.values)), productConditionIds: AppToolsObjC.jsonString(from: fltrProdCondIds), segment: fltrSegment, priceMin: fltrPriceMin, priceMax: fltrPriceMax, isFreeOngkir: fltrIsFreeOngkir ? "1" : "", sizes: AppToolsObjC.jsonString(from: fltrSizes), sortBy: fltrSortBy, current: NSNumber(value: current), limit: NSNumber(value: itemsPerReq), lastTimeUuid: lastTimeUuid, provinceId : provinceId, regionId: regionId, subDistrictId: subDistrictId)).responseJSON { resp in
            if (fltrNameReq == self.fltrName) { // Jika response ini sesuai dengan request terakhir
                self.requesting = false
                if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Filter Product")) {
                    self.setupData(resp.result.value)
                }
                self.refresher?.endRefreshing()
                
                if current == 0 {
                    DispatchQueue.main.async(execute: {
                        self.setupGrid()
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        //UIView.performWithoutAnimation {
                            self.gridView.reloadSections(NSIndexSet(index: lastSec) as IndexSet)
                        //}
                    })
                }
                
            } else {
                self.refresher?.endRefreshing()
            }
        }
    }
    
    func getShopProducts() {
        // need for navbar
        let current = self.products!.count
        
        self.requesting = true
        
        // API Migrasi
        let _ = request(APIUser.getShopPage(id: shopId, current: current, limit: itemsPerReq)).responseJSON { resp in
            self.requesting = false
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Data Shop Pengguna")) {
                self.setupData(resp.result.value)
                DispatchQueue.main.async(execute: {
                if (self.shopHeader == nil) {
                    self.shopHeader = Bundle.main.loadNibNamed("StoreHeader", owner: nil, options: nil)?.first as? StoreHeader
                    self.gridView.addSubview(self.shopHeader!)
                }
                
                let json = JSON(resp.result.value!)["_data"]
                //print(json)
                
                self.shopName = json["username"].stringValue
                self.shopHeader?.captionName.text = self.shopName
//                UIView.animate(withDuration: 0.5) {
//                    self.title = self.shopName
//                }
                let avatarThumbnail = json["profile"]["pict"].stringValue
                self.shopAvatar = URL(string: avatarThumbnail)!
                self.shopHeader?.avatar.afSetImage(withURL: self.shopAvatar!, withFilter: .circle)
                let avatarFull = avatarThumbnail.replacingOccurrences(of: "thumbnails/", with: "", options: NSString.CompareOptions.literal, range: nil)
                self.shopHeader?.avatarUrls.append(avatarFull)
                
                // Love
                let reviewScore = json["average_star"].floatValue
                var loveText = ""
                for i in 0 ..< 5 {
                    if (Float(i) <= reviewScore - 0.5) {
                        loveText += ""
                    } else {
                        loveText += ""
                    }
                }
                let attrStringLove = NSMutableAttributedString(string: loveText)
                attrStringLove.addAttribute(NSKernAttributeName, value: CGFloat(1.4), range: NSRange(location: 0, length: loveText.length))
                self.shopHeader?.captionLove.attributedText = attrStringLove
                
                // Love floatable
                self.floatRatingView = FloatRatingView(frame: CGRect(x: 0, y: 0, width: 90, height: 16))
                self.floatRatingView.emptyImage = UIImage(named: "ic_love_96px_trp.png")?.withRenderingMode(.alwaysTemplate)
                self.floatRatingView.fullImage = UIImage(named: "ic_love_96px.png")?.withRenderingMode(.alwaysTemplate)
                // Optional params
//                self.floatRatingView.delegate = self
                self.floatRatingView.contentMode = UIViewContentMode.scaleAspectFit
                self.floatRatingView.maxRating = 5
                self.floatRatingView.minRating = 0
                self.floatRatingView.rating = reviewScore
                self.floatRatingView.editable = false
                self.floatRatingView.halfRatings = true
                self.floatRatingView.floatRatings = true
                self.floatRatingView.tintColor = Theme.ThemeRed
                
                self.shopHeader?.vwLove.addSubview(self.floatRatingView )
                
                // Reviewer count
                let numReview = json["num_reviewer"].intValue
                self.shopHeader?.captionReview.text = "(\(numReview) Review)"
                
                // Last seen
                if let lastSeenDateString = json["others"]["last_seen"].string {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    if let lastSeenDate = formatter.date(from: lastSeenDateString) {
                        self.shopHeader?.captionLastActive.text = lastSeenDate.relativeDescription
                    }
                }
                
                // Chat percentage
                if let chatPercentage = json["others"]["replied_chat_percentage"].int {
                    self.shopHeader?.captionChatPercentage.text = "\(chatPercentage)%"
                }
                
                var height = 0
                
                if let desc = json["profile"]["description"].string
                {
                    self.shopHeader?.completeDesc = desc
                    let descLengthCollapse = 160
                    var descHeight : Int = 0
                    //let oneLineHeight = Int("lol".boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.width-16).height)
                    if (desc.length > descLengthCollapse) { // Jika lebih dari 160 karakter, buat menjadi collapse text
                        // Ambil 160 karakter pertama, beri ellipsis, tambah tulisan 'Selengkapnya'
                        let descToWrite = desc.substringToIndex(descLengthCollapse - 1) + "... Selengkapnya"
                        let descMutableString : NSMutableAttributedString = NSMutableAttributedString(string: descToWrite, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)])
                        descMutableString.addAttribute(NSForegroundColorAttributeName, value: Theme.PrimaryColorDark, range: NSRange(location: descLengthCollapse + 3, length: 12))
                        self.shopHeader?.captionDesc.attributedText = descMutableString
                        descHeight = Int(descMutableString.string.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.width-16).height)
                    } else {
                        self.shopHeader?.captionDesc.text = desc
                        descHeight = Int(desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.width-16).height)
                    }
                    // 388 -> 398
                    height = 388 + descHeight
                } else {
                    self.shopHeader?.captionDesc.text = "Belum ada deskripsi."
                    self.shopHeader?.captionDesc.textColor = UIColor.lightGray
                    height = 388 + Int("Belum ada deskripsi.".boundsWithFontSize(UIFont.systemFont(ofSize: 16), width: UIScreen.main.bounds.width-14).height)
                }
                self.shopHeader?.width = UIScreen.main.bounds.width
                self.shopHeader?.height = CGFloat(height)
                self.shopHeader?.y = CGFloat(-height)
                
                // bound to top
                self.initY = CGFloat(-height)
                
                self.shopHeader?.seeMoreBlock = {
                    if let completeDesc = self.shopHeader?.completeDesc {
                        self.shopHeader?.captionDesc.text = completeDesc
                        let descHeight = completeDesc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.width-16).height
                        let newHeight : CGFloat = descHeight + 388
                        self.shopHeader?.height = newHeight
                        self.shopHeader?.y = -newHeight
                        self.gridView.contentInset = UIEdgeInsetsMake(newHeight, 0, 0, 0)
                        self.gridView.setContentOffset(CGPoint(x: 0, y: -newHeight), animated: false)
                        
                        var refresherBound = self.refresher?.bounds
                        if (refresherBound != nil) {
                            refresherBound!.origin.y = CGFloat(newHeight)
                            self.refresher?.bounds = refresherBound!
                        }
                        
                        // bound to top
                        self.initY = CGFloat(-newHeight)
                    }
                }
                
                self.shopHeader?.avatar.superview?.layoutIfNeeded()
                self.shopHeader?.avatar.superview?.layer.cornerRadius = (self.shopHeader?.avatar.width)!/2
                self.shopHeader?.avatar.superview?.layer.masksToBounds = true
                
                self.shopHeader?.avatar.superview?.layer.borderColor = Theme.GrayLight.cgColor
                self.shopHeader?.avatar.superview?.layer.borderWidth = 3.5
                
                self.shopHeader?.btnEdit.isHidden = true
                if let id = json["_id"].string, let me = CDUser.getOne()
                {
                    if (id == me.id)
                    {
//                        self.shopHeader?.btnEdit.isHidden = false
                        self.setEditButton()
                    }
                }
                
                // setup badge
                
//                self.shopHeader?.badges = [ (URL(string: "https://trello-avatars.s3.amazonaws.com/c86b504990d8edbb569ab7c02fb55e3d/50.png")!), (URL(string: "https://trello-avatars.s3.amazonaws.com/3a83ed4d4b42810c05608cdc5547e709/50.png")!), (URL(string: "https://trello-avatars.s3.amazonaws.com/7a98b746bc71ccaf9af1d16c4a6b152e/50.png")!) ]
                
                self.shopHeader?.badges = []
                
                if (AppTools.isOldShopWithBadges) {
                    if let arr = json["featured_badges"].array {
                        if arr.count > 0 {
                            for i in 0...arr.count-1 {
                                self.shopHeader?.badges.append(URL(string: arr[i]["icon"].string!)!)
                            }
                        }
                    }
                    
                    self.shopHeader?.consTopVwImage.constant = 28
                } else {
                    self.shopHeader?.consTopVwImage.constant = 58
                }
                
                self.shopHeader?.setupCollection()
                
                // Total products and sold products
                if let productCount = json["total_product"].int {
                    if let soldProductCount = json["total_product_sold"].int {
                        self.shopHeader?.captionTotal.text = "\(productCount) BARANG, \(soldProductCount) TERJUAL"
                    } else {
                        self.shopHeader?.captionTotal.text = "\(productCount) BARANG"
                    }
                } else {
                    if let count = self.products?.count {
                        self.shopHeader?.captionTotal.text = String(count) + " BARANG"
                    }
                }
                
                self.shopHeader?.captionLocation.text = "Unknown"
                
                if let regionId = json["profile"]["region_id"].string, let province_id = json["profile"]["province_id"].string
                {
                    // yang ini go, region sama province nya null.
                    if let region = CDRegion.getRegionNameWithID(regionId), let province = CDProvince.getProvinceNameWithID(province_id)
                    {
                        self.shopHeader?.captionLocation.text = region + ", " + province
                    }
                }

//                self.shopHeader?.editBlock = {
//                    let userProfileVC = Bundle.main.loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil)?.first as! UserProfileViewController
//                    self.navigationController?.pushViewController(userProfileVC, animated: true)
                
//                    let userProfileVC2 = Bundle.main.loadNibNamed(Tags.XibNameUserProfile2, owner: nil, options: nil)?.first as! UserProfileViewController2
//                    self.navigationController?.pushViewController(userProfileVC2, animated: true)
//                }
                
                self.shopHeader?.reviewBlock = {
                    let shopReviewVC = Bundle.main.loadNibNamed(Tags.XibNameShopReview, owner: nil, options: nil)?.first as! ShopReviewViewController
                    shopReviewVC.sellerId = self.shopId
                    shopReviewVC.sellerName = self.shopName
                    self.navigationController?.pushViewController(shopReviewVC, animated: true)
                }
                
                self.shopHeader?.zoomAvatarBlock = {
                    let c = CoverZoomController()
                    c.labels = [json["username"].stringValue]
                    c.images = (self.shopHeader?.avatarUrls)!
                    c.index = 0
                    self.navigationController?.present(c, animated: true, completion: nil)
                }
                
                self.shopHeader?.badgesBlock = {
                    let shopAchievementVC = Bundle.main.loadNibNamed(Tags.XibNameShopAchievement, owner: nil, options: nil)?.first as! ShopAchievementViewController
                    shopAchievementVC.sellerId = self.shopId
                    shopAchievementVC.sellerName = self.shopName
                    self.navigationController?.pushViewController(shopAchievementVC, animated: true)
                }
                
                self.refresher?.endRefreshing()
                var refresherBound = self.refresher?.bounds
                if (refresherBound != nil) {
                    refresherBound!.origin.y = CGFloat(height)
                    self.refresher?.bounds = refresherBound!
                }
                
                self.setupGrid()
                self.gridView.contentInset = UIEdgeInsetsMake(CGFloat(height), 0, 0, 0)
                
                if (self.isFirst == false && current == 0) {
                    self.transparentNavigationBar(true)
                }
                })
            }
        }
    }
    
    func getNewShopProducts() {
        let current = products!.count
        let lastSec = self.gridView.numberOfSections - 1
        
        self.requesting = true
        
        // API Migrasi
        let _ = request(APIUser.getShopPage(id: shopId, current: current, limit: itemsPerReq)).responseJSON { resp in
            self.requesting = false
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Data Shop Pengguna")) {
                self.setupData(resp.result.value)
                
                let json = JSON(resp.result.value!)["_data"]
                
                self.shopData = json
                
                if current == 0 {
                    DispatchQueue.main.async(execute: {
                        self.delegate?.setupBanner(json: json)
                        self.shopName = json["username"].stringValue
                        self.star = json["average_star"].float!
                        let avatarThumbnail = json["profile"]["pict"].stringValue
                        self.shopAvatar = URL(string: avatarThumbnail)!
                        self.listItemSections.insert(.aboutShop, at: 0)
                        
                        let screenSize = UIScreen.main.bounds
                        let screenHeight = screenSize.height - (64 + 45) // (170 + 45)
                        //                    let height = CGFloat((self.products?.count)! + 1) * 65
                        
                        var height = StoreInfo.heightFor(self.shopData, isExpand: self.isExpand) + 4
                        
                        let pCount = (self.products?.count)!
                        
                        if pCount > 0 {
                            if AppTools.isIPad {
                                height += CGFloat(Int(CGFloat(pCount) / 3.0 + 0.7)) * (self.itemCellWidth! + 70)
                            } else {
                                height += CGFloat(Int(CGFloat(pCount) / 2.0 + 0.53)) * (self.itemCellWidth! + 70)
                            }
                        } else {
                            height += 4
                        }
                        
                        var bottom = CGFloat(0)
                        if (height < screenHeight) {
                            bottom += screenHeight - height
                        }
                        
                        /*
                         if bottom > 50 {
                         bottom -= 50
                         } else  {
                         bottom = 1
                         }
                         */
                        
                        self.refresher?.endRefreshing()
                        self.setupGrid()
                        
                        //TOP, LEFT, BOTTOM, RIGHT
                        let inset = UIEdgeInsetsMake(0, 0, bottom, 0)
                        self.gridView.contentInset = inset
                    })
                } else {
                    self.refresher?.endRefreshing()
                    DispatchQueue.main.async(execute: {
                        //UIView.performWithoutAnimation {
                            self.gridView.reloadSections(NSIndexSet(index: lastSec) as IndexSet)
                        //}
                    })
                }
                
            } else {
                DispatchQueue.main.async(execute: {
                    // gesture override
                    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                    
                    self.delegate?.popView()
                })
            }
        }
        
    }
    
    func setupData(_ res : Any?) {
        guard res != nil else {
            return
        }
        
        var obj = JSON(res!)
        if let arr = obj["_data"].array {
            if arr.count == 0 {
                self.done = true
                DispatchQueue.main.async(execute: {
                    self.footerLoading?.isHidden = true
                })
            } else {
                for (_, item) in obj["_data"] {
                    let p = Product.instance(item)
                    if (p != nil) {
                        self.products?.append(p!)
                    }
                }
            }
        } else if let arr = obj["_data"]["products"].array {
            if arr.count == 0 {
                self.done = true
                DispatchQueue.main.async(execute: {
                    self.footerLoading?.isHidden = true
                })
            } else {
                for item in arr {
                    let p = Product.instance(item)
                    if (p != nil) {
                        self.products?.append(p!)
                    }
                }
            }
        }
        
        if let x = self.products?.count, x < itemsPerReq {
            self.done = true
            self.footerLoading?.isHidden = true
        }
    }
    
    func setupSubcategoriesInsideSegment() {
        if segments.count == 0 {
            return
        }
        
        self.subcategoryItems = []
        
        var idx = 0
        for i in 0..<segments.count {
            if segments[i].type == self.selectedSegment {
                idx = i
                
                if segments[i].subCategories == nil {
                    return
                }
                
                break
            }
        }
            
        // Identify Subcategories
        if let subcatJson = segments[idx].subCategories, subcatJson.count > 0 {
            self.isShowSubcategory = true
            for i in 0...subcatJson.count - 1 {
                //var img : UIImage = UIImage()
                var imgUrl : URL!
                if let url = URL(string: subcatJson[i]["image"].stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!) {
                    imgUrl = url
                    //if let data = try? Data(contentsOf: url) {
                    //    if let uiimg = UIImage(data: data) {
                    //        img = uiimg
                    //    }
                    //}
                }
                //self.subcategoryItems.append(SubcategoryItem(id: subcatJson[i]["_id"].stringValue, name: subcatJson[i]["name"].stringValue, image: img))
                self.subcategoryItems.append(SubcategoryItem(id: subcatJson[i]["_id"].stringValue, name: subcatJson[i]["name"].stringValue, imageLink: imgUrl))
            }
            DispatchQueue.main.async(execute: {
                self.listItemSections.insert(.subcategories, at: 0)
            })
        }
    }
    
    func setupGrid() {
        if (self.currentMode == .filter && self.products?.count <= 0 && !self.requesting) {
            self.gridView.isHidden = true
            self.vwFilterZeroResult.isHidden = false
            if (self.fltrName != "") {
                self.lblFilterZeroResult.text = "Tidak ada hasil yang ditemukan untuk '\(self.fltrName)'"
                self.btnFilterZeroResult.isHidden = false
            } else {
                self.lblFilterZeroResult.text = "Tidak ada hasil yang ditemukan"
                self.btnFilterZeroResult.isHidden = true
            }
            return
        }
        
        if (self.gridView.dataSource == nil || self.gridView.delegate == nil) {
            self.gridView.dataSource = self
            self.gridView.delegate = self
        }
        
        if (!(self.currentMode == .segment && self.listItemSections.contains(.segments))) {
            if (self.listStage == 1) {
                self.itemCellWidth = ((UIScreen.main.bounds.size.width - 16) / 3)
            } else if (self.listStage == 2) {
                self.itemCellWidth = ((UIScreen.main.bounds.size.width - 12) / 2)
            } else if (self.listStage == 3) {
                self.itemCellWidth = ((UIScreen.main.bounds.size.width - 8) / 1)
            }
        }
        
        if (self.isFeatured == true || (self.currentMode == .segment && self.listItemSections.contains(.segments))) {
            self.gridView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0)
        } else if (self.currentMode == .filter || self.currentMode == .shop || self.currentMode == .newShop) {
            self.gridView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0)
        } else if self.currentMode == .segment {
            self.gridView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        }
        self.gridView.isHidden = false
        self.vwFilterZeroResult.isHidden = true
        
        self.gridView.reloadData()
    }
    
    // MARK: - Collection view functions
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return listItemSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch listItemSections[section] {
        case .carousel:
            return 1
        case .featuredHeader:
            return 1
        case .subcategories:
            // fixer subcategory hidden in segment (women & men)
            if lblTopHeader.text == "Barang apa yang ingin kamu lihat hari ini?" {
                return 0
            }
            return self.subcategoryItems.count
        case .segments:
            return self.segments.count
        case .products:
            if let p = products, adsCellProvider != nil && p.count > 0 {
                return Int(adsCellProvider.adjustCount(UInt(p.count), forStride: UInt(adRowStep)))
            }
            else if let p = products {
                return p.count
            }
            return 0
        case .aboutShop:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch listItemSections[(indexPath as NSIndexPath).section] {
        case .carousel:
            let cell : ListItemCarouselCell = collectionView.dequeueReusableCell(withReuseIdentifier: "carousel_cell", for: indexPath) as! ListItemCarouselCell
            cell.adapt(carouselItems)
            if (!isCarouselTimerSet) {
                cell.setCarouselTimer()
                isCarouselTimerSet = true
            }
            return cell
        case .featuredHeader:
            let cell : ListItemFeaturedHeaderCell = collectionView.dequeueReusableCell(withReuseIdentifier: "featured_cell", for: indexPath) as! ListItemFeaturedHeaderCell
            if let name = categoryJson?["name"].string {
                cell.adapt(name, featuredTitle: categoryJson?["featured_title"].string, featuredDescription: categoryJson?["featured_description"].string)
            }
            return cell
        case .subcategories:
            let cell : ListItemSubcategoryCell = collectionView.dequeueReusableCell(withReuseIdentifier: "subcategory_cell", for: indexPath) as! ListItemSubcategoryCell
            //cell.imgSubcategory.image = subcategoryItems[(indexPath as NSIndexPath).item].image
            cell.adapt(subcategoryItems[(indexPath as NSIndexPath).item].imageLink)
            cell.lblSubcategory.isHidden = true // Unused label
            return cell
        case .segments:
            let cell : ListItemSegmentCell = collectionView.dequeueReusableCell(withReuseIdentifier: "segment_cell", for: indexPath) as! ListItemSegmentCell
            //cell.imgSegment.image = segments[(indexPath as NSIndexPath).item].image
            cell.adapt(segments[(indexPath as NSIndexPath).item].imageLink)
            return cell
        case .products:
            if adsCellProvider != nil && adsCellProvider.isAdCell(at: indexPath, forStride: UInt(adRowStep)) {
                return adsCellProvider.collectionView(gridView, cellForItemAt: indexPath)
            }
            else {
                var idx  = (indexPath as NSIndexPath).item
                if (adsCellProvider != nil && adRowStep != 0) {
                    idx = indexPath.row - indexPath.row / adRowStep
                }
                
                // Load next products here
                if (currentMode == .default || currentMode == .standalone || currentMode == .shop || currentMode == .filter || (currentMode == .segment && listItemSections.contains(.products)) || currentMode == .newShop) {
                    if (idx == (products?.count)! - 4 && requesting == false && done == false) {
                        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.Prelo",
                                                            qos: .background,
                                                            attributes: .concurrent,
                                                            target: nil)
                        backgroundQueue.async {
                            if !Reachability.isConnectedToNetwork() {
                                Constant.showDisconnectBanner()
                                return
                            }
                            //print("Work on background queue")
                            self.getProducts()
                        }
                    }
                }
                
                let cell : ListItemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ListItemCell
                if (products?.count > idx) {
                    let p = products?[idx]
                    cell.adapt(p!, listStage: self.listStage, currentMode: self.currentMode, shopAvatar: self.shopAvatar, parent: self)
                    cell.isFeatured = self.isFeatured
                }
                if (currentMode == .featured) {
                    // Hide featured ribbon
                    cell.imgFeatured.isHidden = true
                }
                
                return cell
            }
        case .aboutShop:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StorePageShopHeader", for: indexPath) as! StoreInfo
            cell.adapt(self.shopData, count: self.products!.count, isExpand: self.isExpand, star: self.star)
            
            cell.alpha = 1.0
            cell.backgroundColor = UIColor.white
            
            return cell
        }
    }
    /*
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if listItemSections.count > (indexPath as NSIndexPath).section {
        switch listItemSections[(indexPath as NSIndexPath).section] {
        case .products:
            if cell is ListItemCell {
                let c = cell as! ListItemCell
                c.ivCover.af_cancelImageRequest()
                c.avatar.af_cancelImageRequest()
            }
            break
        default: break
        }
        }
    }
    */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let viewWidthMinusMargin = UIScreen.main.bounds.size.width - 8
        switch listItemSections[(indexPath as NSIndexPath).section] {
        case .carousel:
            //var maxHeight : CGFloat = 0
            //for i in 0..<self.carouselItems.count {
            //    let height = ((viewWidthMinusMargin / carouselItems[i].img.size.width) * carouselItems[i].img.size.height)
            //    if (height > maxHeight) {
            //        maxHeight = height
            //    }
            //}
            //return CGSize(width: viewWidthMinusMargin, height: maxHeight)
            return ListItemCarouselCell.sizeFor()
        case .featuredHeader:
            return CGSize(width: viewWidthMinusMargin, height: 56)
        case .subcategories:
            //return CGSize(width: viewWidthMinusMargin / 3, height: viewWidthMinusMargin / 3)
            return ListItemSubcategoryCell.sizeFor()
        case .segments:
            //let segHeight = viewWidthMinusMargin * segments[(indexPath as NSIndexPath).item].image.size.height / segments[(indexPath as NSIndexPath).item].image.size.width
            //return CGSize(width: viewWidthMinusMargin, height: segHeight)
            return ListItemSegmentCell.sizeFor()
        case .products:
            if !AppTools.isIPad && adsCellProvider != nil && adsCellProvider.isAdCell(at: indexPath, forStride: UInt(adRowStep)) {
                return CGSize(width: ((UIScreen.main.bounds.size.width - 8) / 1), height: adsCellProvider.collectionView(gridView, heightForRowAt: indexPath))
            }
            else {
                return CGSize(width: itemCellWidth!, height: itemCellWidth! + 66)
            }
        case .aboutShop:
            return CGSize(width: viewWidthMinusMargin, height: StoreInfo.heightFor(shopData, isExpand: isExpand))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch listItemSections[section] {
        case .products:
//            if AppTools.isIPad {
//                return 3.9
//            } else {
//                return 4
//            }
            return 3.9 // safe point
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch listItemSections[section] {
        case .subcategories:
            return 0
        default:
            return 4
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if (currentMode == .featured) {
            if (section == 0) {
                return UIEdgeInsetsMake(0, 4, 0, 4)
            }
        }
        if (listItemSections[section] == .products) {
            if (currentMode == .filter) {
                return UIEdgeInsetsMake(0, 4, 0, 4)
            }
        }
        if (listItemSections[section] == .subcategories) {
            return UIEdgeInsetsMake(0, 4, 0, 4)
        }
        return UIEdgeInsetsMake(4, 4, 0, 4)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch listItemSections[(indexPath as NSIndexPath).section] {
        case .carousel:
            break
        case .featuredHeader:
            break
        case .subcategories:
            let p = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            p.currentMode = .filter
            p.fltrCategId = subcategoryItems[(indexPath as NSIndexPath).item].id
            p.fltrSortBy = "recent"
            
            // fixer subcategory hidden in segment (women & men)
            if self.selectedSegment != "" {
                p.fltrSegment = self.selectedSegment
            }
            
            self.navigationController?.pushViewController(p, animated: true)
        case .segments:
            self.selectedSegment = self.segments[(indexPath as NSIndexPath).item].type
            var txt = " Kamu sedang melihat \(self.segments[(indexPath as NSIndexPath).item].name)"
            if (self.segments[(indexPath as NSIndexPath).item].name.length > 23) {
                txt = txt.replacingOccurrences(of: "sedang ", with: "")
            }
            let attTxt = NSMutableAttributedString(string: txt)
            attTxt.addAttributes([NSFontAttributeName : AppFont.prelo2.getFont(11)!], range: NSRange.init(location: 0, length: 1))
            attTxt.addAttributes([NSFontAttributeName : UIFont.systemFont(ofSize: 12)], range: NSRange.init(location: 1, length: txt.length - 1))
            self.lblTopHeader.attributedText = attTxt
            self.listItemSections.remove(at: self.listItemSections.index(of: .segments)!)
            self.listItemSections.append(.products)
            
            // update time
            self.curTime = NSDate().timeIntervalSince1970
            
            self.refresh()
        case .products:
            var idx  = (indexPath as NSIndexPath).item
            if (adsCellProvider != nil && adRowStep != 0) {
                idx = indexPath.row - indexPath.row / adRowStep
            }
            
            self.selectedProduct = products?[idx]
            if self.selectedProduct?.isAggregate == false && self.selectedProduct?.isAffiliate == false {
                if (currentMode == .featured) {
                    self.selectedProduct?.setToFeatured()
                }
                self.launchDetail()
            } else if self.selectedProduct?.isAffiliate == false {
                let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                l.currentMode = .filter
                l.fltrAggregateId = (self.selectedProduct?.id)!
                l.fltrSortBy = "recent"
                l.fltrName = ""
                
                // Prelo Analytic - Visit Aggregate
                let loginMethod = User.LoginMethod ?? ""
                let pdata = [
                    "Aggregate ID": (self.selectedProduct?.id)!,
                    "Aggregate Name" : (self.selectedProduct?.name)!
                ] as [String : Any]
                
                // previous screen is current screen
                var currentPage = PageName.Home
                if currentMode == .filter {
                    currentPage = PageName.SearchResult
                } else if currentMode == .shop || currentMode == .newShop {
                    if User.IsLoggedIn && User.Id! == self.shopId {
                        currentPage = PageName.ShopMine
                    } else {
                        currentPage = PageName.Shop
                    }
                }
                
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.VisitAggregate, data: pdata, previousScreen: currentPage, loginMethod: loginMethod)
                
                self.navigationController?.pushViewController(l, animated: true)
            } else {
                let urlString = self.selectedProduct?.json["affiliate_data"]["affiliate_url"].stringValue
                
                let url = NSURL(string: urlString!)!
                UIApplication.shared.openURL(url as URL)
            }
        case .aboutShop:
            self.isExpand = !self.isExpand
            self.gridView.reloadSections(NSIndexSet(index: indexPath.section) as IndexSet)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if (kind == UICollectionElementKindSectionHeader) { // Header
            // No header
        } else if (kind == UICollectionElementKindSectionFooter) { // Footer
            let f = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath) as! ListFooter
            
            // Default value
            f.btnFooter.isHidden = true
            f.lblFooter.isHidden = true
            f.loading.isHidden = false
            
            if (self.shopId == User.Id && self.currentMode == .newShop) {
                f.loading.isHidden = true
                let newLoader = UIActivityIndicatorView()
                newLoader.frame = f.loading.frame
                newLoader.center.x = UIScreen.main.bounds.width - newLoader.bounds.width
                newLoader.tag = 888
                newLoader.startAnimating()
                newLoader.color = f.loading.color
                
                f.viewWithTag(888)?.removeFromSuperview()
                
                if !self.done {
                    f.addSubview(newLoader)
                }
            }
            
            // Loading handle
            self.footerLoading = f.loading
            if (self.done) {
                self.footerLoading?.isHidden = true
            }
            
            // Adapt
            if (currentMode == .featured && products?.count > 0) { // 'Lihat semua barang' button, only show if featured products is loaded
                f.btnFooter.backgroundColor = Theme.PrimaryColor
                f.btnFooter.setTitleColor(UIColor.white)
                
                f.btnFooter.isHidden = false
                f.btnFooterAction = {
                    let p = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                    p.currentMode = .filter
                    p.fltrCategId = self.categoryJson!["_id"].stringValue
                    p.fltrSortBy = "recent"
                    self.navigationController?.pushViewController(p, animated: true)
                }
            } else { // Default loading footer
                f.btnFooter.isHidden = true
            }
            
            return f
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero // No header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if (listItemSections[section] == .products) {
            if (currentMode == .featured) {
                return CGSize(width: collectionView.width, height: 42/*66*/)
            }
            return CGSize(width: collectionView.width, height: 48/*50*/)
        }
        return CGSize.zero
    }
    
    // MARK: - Scrollview functions
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        currScrollPoint = scrollView.contentOffset
        draggingScrollView = true
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        draggingScrollView = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (draggingScrollView && !requesting) {
            if (currentMode == .default || currentMode == .featured || currentMode == .filter || (currentMode == .segment && listItemSections.contains(.products))) {
                if (currScrollPoint.y < scrollView.contentOffset.y) {
                    if ((self.navigationController?.isNavigationBarHidden)! == false) {
                        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "hideBottomBar"), object: nil)
                        self.navigationController?.setNavigationBarHidden(true, animated: true)
                        self.hideStatusBar()
                        if (selectedSegment != "") {
                            consHeightVwTopHeader.constant = 0 // Hide top header
                            UIView.animate(withDuration: 0.2, animations: {
                                self.view.layoutIfNeeded()
                            })
                        }
                        self.repositionScrollCategoryNameContent(true)
                        if (currentMode == .filter) {
                            self.isHiddenTop = true
                            UIView.animate(withDuration: 0.2, animations: {
                                self.consTopTopHeaderFilter.constant = UIApplication.shared.statusBarFrame.height
                                self.consTopGridView.constant = UIApplication.shared.statusBarFrame.height
                            })
                        }
                    }
                } else {
                    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "showBottomBar"), object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    self.showStatusBar()
                    if (selectedSegment != "") {
                        consHeightVwTopHeader.constant = 40 // Show top header
                        UIView.animate(withDuration: 0.2, animations: {
                            self.view.layoutIfNeeded()
                        })
                    }
                    self.repositionScrollCategoryNameContent(true)
                    if (currentMode == .filter) {
                        self.isHiddenTop = false
                        UIView.animate(withDuration: 0.2, animations: {
                            self.consTopTopHeaderFilter.constant = 0
                            self.consTopGridView.constant = 0
                        })
                    }
                }
            }
        }
        if (currentMode == .shop) {
            scrollViewShop(scrollView)
        } else if (currentMode == .newShop) {
            // hidding header smoothly
            scrollViewHeaderShop(scrollView)
        }
    }
    
    func scrollViewShop(_ scrollView: UIScrollView) {
//        let pointY = (self.shopHeader?.height)! - 33 // --> 214 -> 207 --> 388 -> 33 // minus
        let pointY = self.initY + 170 // 214 - 44
        if (scrollView.contentOffset.y < pointY) {
            self.transparentNavigationBar(true)
        } else if (scrollView.contentOffset.y >= pointY) {
            self.transparentNavigationBar(false)
        }
    }
    
    func scrollViewHeaderShop(_ scrollView: UIScrollView) {
//        let pointY = CGFloat(1)
//        let screenSize = UIScreen.main.bounds
//        let screenHeight = screenSize.height - 170
//        let height = scrollView.contentSize.height
//        if (scrollView.contentOffset.y < pointY && height >= screenHeight) {
//            self.delegate?.increaseHeader()
//            self.transparentNavigationBar(true)
//        } else if (scrollView.contentOffset.y >= pointY && height >= screenHeight) {
//            self.delegate?.dereaseHeader()
//            self.transparentNavigationBar(false)
//        }
        
        let pointY = CGFloat(1)
        if (scrollView.contentOffset.y < pointY) {
//            self.delegate?.increaseHeader()
            self.transparentNavigationBar(true)
        } else if (scrollView.contentOffset.y >= pointY) {
//            self.delegate?.dereaseHeader()
            self.transparentNavigationBar(false)
        }
    }
    
    func repositionScrollCategoryNameContent(_ animated: Bool) {
        // This function is made as a temporary solution for a bug where the scroll category name content size is become wrong after scroll
        if (scrollCategoryName != nil) {
            if animated {
                UIView.animate(withDuration: 0.2, animations: {
                    let bottomOffset = CGPoint(x: self.scrollCategoryName!.contentOffset.x, y: self.scrollCategoryName!.contentSize.height - self.scrollCategoryName!.bounds.size.height)
                    self.scrollCategoryName!.setContentOffset(bottomOffset, animated: false)
                })
            } else {
                let bottomOffset = CGPoint(x: self.scrollCategoryName!.contentOffset.x, y: self.scrollCategoryName!.contentSize.height - self.scrollCategoryName!.bounds.size.height)
                self.scrollCategoryName!.setContentOffset(bottomOffset, animated: false)
            }
        }
    }
    
    // MARK: - Search bar functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.fltrName = searchText
        self.done = false
        self.footerLoading?.isHidden = false
        self.products = []
        self.getProducts()
        self.setupGrid()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if let searchField = searchBar.value(forKey: "searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.withRenderingMode(.alwaysTemplate)
                icon.tintColor = UIColor.white
            }
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if let searchField = searchBar.value(forKey: "searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.withRenderingMode(.alwaysTemplate)
                icon.tintColor = UIColor.lightGray
            }
        }
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        // Prelo Analytic - Search by Keyword
        sendSearchByKeywordAnalytic(self.searchBar.text!)
        
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Filter delegate function
    
    func adjustFilter(_ fltrProdCondIds: [String], fltrPriceMin: NSNumber, fltrPriceMax: NSNumber, fltrIsFreeOngkir: Bool, fltrSizes: [String], fltrSortBy: String, fltrLocation: [String]) {
        self.fltrProdCondIds = fltrProdCondIds
        self.fltrPriceMin = fltrPriceMin
        self.fltrPriceMax = fltrPriceMax
        self.fltrIsFreeOngkir = fltrIsFreeOngkir
        self.fltrSizes = fltrSizes
        self.fltrSortBy = fltrSortBy
        self.fltrLocation = fltrLocation
        lblFilterSort.text = self.FltrValSortBy[self.fltrSortBy]
        if (lblFilterSort.text?.lowercased() == "highest rp") {
            lblFilterSort.font = UIFont.boldSystemFont(ofSize: 12)
        } else {
            lblFilterSort.font = UIFont.boldSystemFont(ofSize: 13)
        }
        self.refresh()
        self.setupGrid()
    }
    
    // MARK: - Category picker delegate function
    
    func adjustCategory(_ categId: String) {
        self.fltrCategId = categId
        lblFilterKategori.text = CDCategory.getCategoryNameWithID(categId)
        self.refresh()
        self.setupGrid()
    }
    
    // MARK: - List brand delegate function
    
    func adjustBrand(_ fltrBrands: [String : String]) {
        self.fltrBrands = fltrBrands
        if (fltrBrands.count > 0) {
            if (fltrBrands.count == 1) {
                lblFilterMerek.text = [String](fltrBrands.keys)[0]
            } else {
                lblFilterMerek.text = [String](fltrBrands.keys)[0] + ", \(fltrBrands.count - 1)+"
            }
        }
        self.refresh()
        self.setupGrid()
    }
    
    // MARK: - TopHeader
 
    func setDefaultTopHeaderWomen() {
        lblTopHeader.text = "Barang apa yang ingin kamu lihat hari ini?"
        lblTopHeader.font = UIFont.systemFont(ofSize: 12)
    }
    
    @IBAction func topHeaderPressed(_ sender: AnyObject) {
        if (!listItemSections.contains(.segments)) {
            setDefaultTopHeaderWomen()
            selectedSegment = ""
            if self.listItemSections.contains(.subcategories) {
                self.listItemSections.remove(at: self.listItemSections.index(of: .subcategories)!)
            }
            self.listItemSections.remove(at: self.listItemSections.index(of: .products)!)
            self.listItemSections.append(.segments)
            
            // update time
            //self.curTime = NSDate().timeIntervalSince1970
            
            self.gridView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0)
            
            gridView.reloadData()
        }
    }
    
    @IBAction func topHeaderFilterMerekPressed(_ sender: AnyObject) {
        let listBrandVC = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdListBrand) as! ListBrandViewController2
        listBrandVC.previousController = self
        listBrandVC.delegate = self
        listBrandVC.selectedBrands = self.fltrBrands
        listBrandVC.sortedBrandKeys = [String](self.fltrBrands.keys)
        self.navigationController?.pushViewController(listBrandVC, animated: true)
    }
    
    @IBAction func topHeaderFilterKategoriPressed(_ sender: AnyObject) {
        let categPickerVC = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdCategoryPicker) as! CategoryPickerViewController
        categPickerVC.previousController = self
        categPickerVC.delegate = self
        categPickerVC.searchMode = true
        self.navigationController?.pushViewController(categPickerVC, animated: true)
    }
    
    @IBAction func topHeaderFilterSortPressed(_ sender: AnyObject) {
        let filterVC = Bundle.main.loadNibNamed(Tags.XibNameFilter, owner: nil, options: nil)?.first as! FilterViewController
        filterVC.previousController = self
        filterVC.delegate = self
        filterVC.categoryId = self.fltrCategId
        filterVC.initSelectedProdCondId = self.fltrProdCondIds
        filterVC.initSelectedCategSizeVal = self.fltrSizes
        filterVC.selectedIdxSortBy = filterVC.SortByDataValue.index(of: self.fltrSortBy)!
        filterVC.isFreeOngkir = self.fltrIsFreeOngkir
        filterVC.minPrice = (self.fltrPriceMin > 0) ? self.fltrPriceMin.stringValue : ""
        filterVC.maxPrice = (self.fltrPriceMax > 0) ? self.fltrPriceMax.stringValue : ""
        filterVC.locationId = self.fltrLocation[1]
        filterVC.locationName = self.fltrLocation[0]
        filterVC.locationType = self.fltrLocation[2].int
        filterVC.locationParentIDs = self.fltrLocation[3]
        self.navigationController?.pushViewController(filterVC, animated: true)
    }
    
    // MARK: - Filter zero result
    
    @IBAction func reqBarangPressed(_ sender: AnyObject) {
        var username = "Your beloved user"
        if let u = CDUser.getOne() {
            username = u.username
        }
        let msgBody = "Dear Prelo,<br/><br/>Saya sedang mencari barang bekas berkualitas ini:<br/>\(fltrName)<br/><br/>Jika ada pengguna di Prelo yang menjual barang tersebut, harap memberitahu saya melalui e-mail.<br/><br/>Terima kasih Prelo <3<br/><br/>--<br/>\(username)<br/>Sent from Prelo iOS"
        
        let m = MFMailComposeViewController()
        if (MFMailComposeViewController.canSendMail()) {
            m.setToRecipients(["contact@prelo.id"])
            m.setSubject("Request Barang")
            m.setMessageBody(msgBody, isHTML: true)
            m.mailComposeDelegate = self
            self.present(m, animated: true, completion: nil)
        } else {
            Constant.showDialog("No Active E-mail", message: "Untuk dapat mengirim Request Barang, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
        }
    }
    
    // MARK: - Mail compose delegate functions
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if (result == MFMailComposeResult.sent) {
            Constant.showDialog("Request Barang", message: "E-mail terkirim")
        } else if (result == MFMailComposeResult.failed) {
            Constant.showDialog("Request Barang", message: "E-mail gagal dikirim")
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let c = segue.destination
        if (c.isKind(of: BaseViewController.classForCoder())) {
            let b = c as! BaseViewController
            b.previousController = self
        }
    }
    
    func launchDetail() {
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NotificationName.ShowProduct), object: [ self.selectedProduct!, (self.currentMode != .filter ? (self.currentMode == .shop || self.currentMode == .newShop ? PageName.Shop : PageName.Home ) :  PageName.SearchResult ) ])
    }
    
    // MARK: - Other functions
    
    func statusBarTapped() {
        gridView.setContentOffset(CGPoint(x: 0, y: 10), animated: true)
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "showBottomBar"), object: nil)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.repositionScrollCategoryNameContent(true)
    }
    
    func pinch(_ pinchedIn : Bool) {
        ////print("current stage : \(listStage)")
        listStage += (pinchedIn ? 1 : -1)
        if (listStage > 3) {
            listStage = 1
        }
        if (listStage < 1) {
            listStage = 3
        }
        ////print("next stage : \(listStage)")
        
        setupGrid()
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.gridView.reloadData()
        }, completion: nil)
    }
    
    // MARK: - navbar styler
    func transparentNavigationBar(_ isActive: Bool) {
        if (currentMode == .shop) {
            if isActive && !self.isTransparent {
                UIView.animate(withDuration: 0.5) {
                    // Transparent navigation bar
                    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                    self.navigationController?.navigationBar.shadowImage = UIImage()
                    self.navigationController?.navigationBar.isTranslucent = true
                    
                    self.navigationController?.navigationBar.layoutIfNeeded()
                    
                    self.title = ""
                }
                self.isTransparent = true
            } else if !isActive && self.isTransparent {
                UIView.animate(withDuration: 0.5) {
                    self.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
                    self.navigationController?.navigationBar.shadowImage = nil
                    self.navigationController?.navigationBar.isTranslucent = true
                    
                    // default prelo
                    UINavigationBar.appearance().barTintColor = Theme.PrimaryColor
                    
                    self.navigationController?.navigationBar.layoutIfNeeded()
                    
                    self.title = self.shopName
                }
                self.isTransparent = false
            }
        } else if (currentMode == .newShop) {
            if isActive && !(self.delegate?.getTransparentcy())! {
                self.delegate?.increaseHeader()

                UIView.animate(withDuration: 0.5) {
                    // Transparent navigation bar
                    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                    self.navigationController?.navigationBar.shadowImage = UIImage()
                    self.navigationController?.navigationBar.isTranslucent = true
                    
                    self.navigationController?.navigationBar.layoutIfNeeded()
                    
                    self.delegate?.setShopTitle("")
                }
                self.delegate?.setTransparentcy(true)
            } else if !isActive && (self.delegate?.getTransparentcy())!  {
                self.delegate?.dereaseHeader()
                
                UIView.animate(withDuration: 0.5) {
                    self.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
                    self.navigationController?.navigationBar.shadowImage = nil
                    self.navigationController?.navigationBar.isTranslucent = true
                    
                    // default prelo
                    UINavigationBar.appearance().barTintColor = Theme.PrimaryColor
                    
                    self.navigationController?.navigationBar.layoutIfNeeded()
                    
                    self.delegate?.setShopTitle(self.shopName)
                }
                self.delegate?.setTransparentcy(false)
            }
        }
    }
    
    func defaultNavigationBar() {
        UIView.animate(withDuration: 0.5) {
            self.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
            self.navigationController?.navigationBar.shadowImage = nil
//            self.navigationController?.navigationBar.tintColor = nil
            self.navigationController?.navigationBar.isTranslucent = false
            
            // default prelo
            UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
            UINavigationBar.appearance().barTintColor = Theme.PrimaryColor
            self.navigationController?.navigationBar.tintColor = UIColor.white
            
            self.navigationController?.navigationBar.layoutIfNeeded()
        }
    }
    
    // MARK: - Edit Profile button (right top) .shop
    func setEditButton() {
        let btnEdit = self.createButtonWithIcon(UIImage(named: "ic_edit_white")!) //self.createButtonWithIcon(AppFont.preloAwesome, icon: "")
        
        btnEdit.addTarget(self, action: #selector(ListItemViewController.editProfile), for: UIControlEvents.touchUpInside)
        
        if (self.navigationItem.rightBarButtonItem == nil) {
            self.navigationItem.rightBarButtonItem = btnEdit.toBarButton()
        }
    }
    
    func editProfile()
    {
//        let userProfileVC = Bundle.main.loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil)?.first as! UserProfileViewController
//        self.navigationController?.pushViewController(userProfileVC, animated: true)
//        
        let userProfileVC2 = Bundle.main.loadNibNamed(Tags.XibNameUserProfile2, owner: nil, options: nil)?.first as! UserProfileViewController2
        self.navigationController?.pushViewController(userProfileVC2, animated: true)
    }
    
    // MARK: - Ads
    func configureAdManagerAndLoadAds() {
        if adsManager == nil {
            /*
            if (AppTools.isDev) {
                //FBAdSettings.setLogLevel(FBAdLogLevel.log)
            
                var hashedIds : Array<String> = []
                hashedIds.append("c175de056cdb0cca0c902686eb3fa862503918d5") // pw - new id
                //hashedIds.append("81c2cf31791f7f7513d28f30c48d4186ca00b11f") // nadine - ipad
                //FBAdSettings.addTestDevices(hashedIds)
            
                //FBAdSettings.setLogLevel(FBAdLogLevel.none)
                FBAdSettings.clearTestDevices()
            }
             */
            adsManager = FBNativeAdsManager(placementID: "860723977338277_1233930046684333", forNumAdsRequested: 5)
            adsManager.delegate = self
            adsManager.loadAds()
        }
    }
    
    func nativeAdsLoaded() {
        /*
         FBNativeAdViewAttributes *attributes = [[FBNativeAdViewAttributes alloc] init];
         
         attributes.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
         attributes.buttonColor = [UIColor colorWithRed:66/255.0 green:108/255.0 blue:173/255.0 alpha:1];
         attributes.buttonTitleColor = [UIColor whiteColor];
         
         FBNativeAdView *adView = [FBNativeAdView nativeAdViewWithNativeAd:nativeAd
         withType:FBNativeAdViewTypeGenericHeight300 withAttributes:attributes];
         
         [self.view addSubview:adView];
         
         CGSize size = self.view.bounds.size;
         CGFloat xOffset = size.width / 2 - 160;
         CGFloat yOffset = (size.height > size.width) ? 100 : 20;
         adView.frame = CGRectMake(xOffset, yOffset, 320, 300);
         
         // Register the native ad view and its view controller with the native ad instance
         [nativeAd registerViewForInteraction:adView withViewController:self];
         */
        
        let attributes = FBNativeAdViewAttributes.init()
        attributes.backgroundColor = UIColor.white
        attributes.buttonColor = Theme.PrimaryColor
        attributes.buttonTitleColor = UIColor.white
        
        if (adsCellProvider == nil) {
            var l = FBNativeAdViewType.genericHeight120
            if AppTools.isIPad {
                if self.itemCellWidth! + 66 > 400 {
                    l = FBNativeAdViewType.genericHeight400
                } else {
                    l = FBNativeAdViewType.genericHeight300
                }
            }
            
            adsCellProvider = FBNativeAdCollectionViewCellProvider(manager: adsManager, for: l, for: attributes)
            
            adsCellProvider.delegate = self
        }
        
        if gridView != nil {
            gridView.reloadData()
        }
    }
    
    func nativeAdsFailedToLoadWithError(_ error: Error) {
        //print(error)
    }
    
    func nativeAdDidClick(_ nativeAd: FBNativeAd) {
        //print("Ad tapped: \(nativeAd.title)")
    }
    
    // Prelo Analytic - Filter
    func sendFilterAnalytic() {
        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.PreloAnalytic",
                                            qos: .background,
                                            attributes: .concurrent,
                                            target: nil)
        backgroundQueue.async {
            //print("Work on background queue")
            var brands: Array<String> = []
            for i in self.fltrBrands {
                brands.append(String(i.key))
            }
            
            let parentids = self.fltrLocation[3].components(separatedBy: ";")
            let provinceId =  self.fltrLocation[2].int == 0 ? self.fltrLocation[1] : parentids[0]
            let regionId =  self.fltrLocation[2].int == 1 ? self.fltrLocation[1] : (parentids.count > 1 ? parentids[1] : "")
            let subDistrictId =  self.fltrLocation[2].int == 2 ? self.fltrLocation[1] : ""
            
            let location = [
                "Province ID": provinceId,
                "Region ID": regionId,
                "Subdistrict ID": subDistrictId
            ]
            let loginMethod = User.LoginMethod ?? ""
            let pdata = [
                "Category" : self.lblFilterKategori.text ?? "",
                "Brand" : brands,
                "Condition" : self.fltrProdCondIds.count > 0 ? true : false,
                "Location": location,
                "Min Price" : self.fltrPriceMin > 0 ? true : false,
                "Max Price" : self.fltrPriceMax > 0 ? true : false,
                "Free Shipping" : self.fltrIsFreeOngkir
            ] as [String : Any]
            AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.Filter, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
        }
    }
    
    // Prelo Analytic - Search by Keyword
    func sendSearchByKeywordAnalytic(_ keyword: String) {
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            "Search Query" : keyword
        ]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.SearchByKeyword, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
    }
}

// MARK: - Class

class CarouselItem {
    var name : String = ""
    //var img : UIImage = UIImage()
    var link : URL!
    var imgLink : URL!
    
//    init(name : String, img : UIImage, link : URL) {
//        self.name = name
//        self.img = img
//        self.link = link
//    }
    
    init(name : String, imgLink : URL, link : URL) {
        self.name = name
        self.imgLink = imgLink
        self.link = link
    }
}

// MARK: - Class

class ListItemSubcategoryCell : UICollectionViewCell {
    
    @IBOutlet var imgSubcategory: UIImageView!
    @IBOutlet var lblSubcategory: UILabel!
    
    override func prepareForReuse() {
        //imgSubcategory.image = nil
        imgSubcategory.afCancelRequest()
    }
    
    static func sizeFor() -> CGSize {
        let wh : CGFloat = (UIScreen.main.bounds.width - 8) / 3
        return CGSize(width: wh, height: wh)
    }
    
    func adapt(_ imageURL : URL?) {
        let wh : CGFloat = (UIScreen.main.bounds.width - 8) / 3
        let rect = CGRect(x: 0, y: 0, width: wh, height: wh)
        imgSubcategory.frame = rect
        if let img = imageURL {
            imgSubcategory.afSetImage(withURL: img, withFilter: .fitWithStandarPlaceHolder)
        } else {
            imgSubcategory.image = UIImage(named: (AppTools.isIPad ? "placeholder-transparent-ipad-lightgray" : "placeholder-transparent-lightgray"))
            imgSubcategory.contentMode = .scaleAspectFit
            imgSubcategory.afInflate()
        }
    }
}

// MARK: - Class

class ListItemSegmentCell : UICollectionViewCell {
    @IBOutlet var imgSegment: UIImageView!
    
    override func prepareForReuse() {
        //imgSegment.image = nil
        imgSegment.afCancelRequest()
    }
    
    static func sizeFor() -> CGSize {
        let rectWidthFix : CGFloat = UIScreen.main.bounds.size.width - 8
        let heightBanner : CGFloat = ((rectWidthFix / 1024.0) * 514.0)
        return CGSize(width: rectWidthFix, height: heightBanner)
    }
    
    func adapt(_ imageURL : URL?) {
        let rectWidthFix : CGFloat = UIScreen.main.bounds.size.width - 8
        let rectHeightFix : CGFloat = ((rectWidthFix / 1024.0) * 514.0)
        let rect = CGRect(x: 0, y: 0, width: rectWidthFix, height: rectHeightFix)
        imgSegment.frame = rect
        if let img = imageURL {
            imgSegment.afSetImage(withURL: img, withFilter: .fitWithStandarPlaceHolder)
        } else {
            imgSegment.image = UIImage(named: (AppTools.isIPad ? "placeholder-transparent-ipad-lightgray" : "placeholder-transparent-lightgray"))
            imgSegment.contentMode = .scaleAspectFit
            imgSegment.afInflate()
        }
    }
}

// MARK: - Class

class ListItemCarouselCell : UICollectionViewCell, UIScrollViewDelegate {
    @IBOutlet var scrlVwCarousel: UIScrollView!
    @IBOutlet var contentVwCarousel: UIView!
    @IBOutlet var pageCtrlCarousel: UIPageControl!
    @IBOutlet var consWidthContentVwCarousel: NSLayoutConstraint!
    var carouselItems : [CarouselItem] = []
    
    static func sizeFor() -> CGSize {
        let rectWidthFix : CGFloat = UIScreen.main.bounds.size.width - 8
        let heightBanner : CGFloat = ((rectWidthFix / 1024.0) * 337.0)
        return CGSize(width: rectWidthFix, height: heightBanner)
    }
    
    func adapt(_ carouselItems : [CarouselItem]) {
        self.carouselItems = carouselItems
        scrlVwCarousel.delegate = self
        
        self.pageCtrlCarousel.numberOfPages = carouselItems.count
        self.pageCtrlCarousel.currentPage = 0
        let rectWidthFix : CGFloat = UIScreen.main.bounds.size.width - 8
        let rectHeightFix : CGFloat = ((rectWidthFix / 1024.0) * 337.0) //0
        self.consWidthContentVwCarousel.constant = rectWidthFix * CGFloat(carouselItems.count)
//        for i in 0..<carouselItems.count {
//            let height = ((rectWidthFix / carouselItems[i].img.size.width) * carouselItems[i].img.size.height)
//            if (height > rectHeightFix) {
//                rectHeightFix = height
//            }
//        }
        for i in 0...carouselItems.count - 1 {
            let rect = CGRect(x: CGFloat(i * Int(rectWidthFix)), y: 0, width: rectWidthFix, height: rectHeightFix)
            //let uiImg = UIImageView(frame: rect, image: carouselItems[i].img)
            let uiImg = UIImageView(frame: rect)
            uiImg.afSetImage(withURL: carouselItems[i].imgLink, withFilter: .fitWithStandarPlaceHolder)
            let uiBtn = UIButton(frame: rect)
            uiBtn.addTarget(self, action: #selector(ListItemCarouselCell.btnCarouselPressed(_:)), for: UIControlEvents.touchUpInside)
            uiBtn.tag = i
            self.contentVwCarousel.addSubview(uiImg)
            self.contentVwCarousel.addSubview(uiBtn)
        }
    }
    
    func setCarouselTimer() {
        // Scroll timer
        Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ListItemCarouselCell.autoScrollCarousel), userInfo: nil, repeats: true)
    }
    
    func btnCarouselPressed(_ sender: UIButton) {
        let tag = sender.tag
        UIApplication.shared.openURL(self.carouselItems[tag].link)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageCtrlCarousel.currentPage = Int(scrlVwCarousel.contentOffset.x / scrlVwCarousel.width)
    }
    
    func autoScrollCarousel() {
        var nextPage = Int(scrlVwCarousel.contentOffset.x / scrlVwCarousel.width) + 1
        if (nextPage > carouselItems.count - 1) {
            nextPage = 0
        }
        scrlVwCarousel.setContentOffset(CGPoint(x: CGFloat(nextPage) * scrlVwCarousel.width, y: 0), animated: true)
        pageCtrlCarousel.currentPage = nextPage
    }
}

// MARK: - Class

class ListItemFeaturedHeaderCell : UICollectionViewCell {
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDesc: UILabel!
    
    func adapt(_ categName : String, featuredTitle : String? , featuredDescription : String?) {
        let edPickCategName = ["all", "home", "semua"]
        if (edPickCategName.contains(categName.lowercased())) {
            self.lblTitle.text = featuredTitle ?? "EDITOR'S PICK"
            self.lblTitle.textColor = UIColor.white
            self.lblDesc.text = featuredDescription ?? "Daftar barang terbaik yang dipilih oleh tim Prelo"
            self.lblDesc.textColor = UIColor.white
        } else {
            self.lblTitle.text = featuredTitle ?? "HIGHLIGHTS"
            self.lblTitle.textColor = UIColor(hexString: "#5d5d5d")
            self.lblDesc.text = featuredDescription ?? "Barang \(categName) pilihan tim Prelo"
            self.lblDesc.textColor = UIColor(hexString: "#5d5d5d")
        }
    }
}

// MARK: - Class ListItemCell

class ListItemCell : UICollectionViewCell {
    @IBOutlet weak var ivCover: UIImageView!
    @IBOutlet weak var captionTitle: UILabel!
    @IBOutlet weak var captionPrice: UILabel!
    @IBOutlet weak var captionOldPrice: UILabel!
    @IBOutlet weak var captionLove: UILabel!
    @IBOutlet weak var captionMyLove: UILabel!
    @IBOutlet weak var captionComment: UILabel!
    @IBOutlet weak var sectionLove : UIView!
    @IBOutlet weak var avatar : UIImageView!
    @IBOutlet weak var captionSpecialStory : UILabel!
    @IBOutlet weak var sectionSpecialStory : UIView!
    @IBOutlet weak var imgSold: UIImageView!
    @IBOutlet weak var imgReserved: UIImageView!
    @IBOutlet weak var imgFeatured: UIImageView!
    @IBOutlet weak var imgFreeOngkir: UIImageView!
    @IBOutlet weak var btnTawar: UIButton!
    @IBOutlet weak var btnLove: UIButton!
    
    @IBOutlet weak var consHeightFO: NSLayoutConstraint!
    @IBOutlet weak var consWidthFO: NSLayoutConstraint!
    
    @IBOutlet weak var consbtnWidthTawar: NSLayoutConstraint!
    @IBOutlet weak var consbtnWidthLove: NSLayoutConstraint!
    @IBOutlet weak var consbtnHeightTawar: NSLayoutConstraint!
    @IBOutlet weak var consbtnHeightLove: NSLayoutConstraint!
    
    @IBOutlet weak var affiliateLogo: UIImageView!
    @IBOutlet weak var consWidthAffiliateLogo: NSLayoutConstraint!
    @IBOutlet weak var consHeightAffiliateLogo: NSLayoutConstraint!
    
    var newLove : Bool?
    var pid : String?
    var cid : String?
    var sid : String?
    
    //var sname : String = "" // seller name
    var isFeatured : Bool = false
    var currentMode : ListItemMode = .filter
    
    var parent : BaseViewController!
    var product: Product!
    
    var isNeedSetup = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        
        self.ivCover.alpha = 1.0
        self.ivCover.backgroundColor = UIColor.white
        
        sectionLove.layoutIfNeeded()
        sectionLove.layer.cornerRadius = sectionLove.frame.size.width/2
        sectionLove.layer.masksToBounds = true
        
        // TODO : if used (switch)
        btnTawar.isHidden = true
//        consbtnWidthTawar.constant = 30
//        consbtnHeightTawar.constant = 30
//        let image = UIImage(named: "ic_chat_tawar.png")?.withRenderingMode(.alwaysTemplate)
//        btnTawar.setImage(image, for: .normal)
//        btnTawar.tintColor = UIColor.lightGray
//        btnTawar.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        
        btnLove.isHidden = true
        affiliateLogo.isHidden = true
    }
    
    override func prepareForReuse() {
        imgSold.isHidden = true
        imgReserved.isHidden = true
        imgFeatured.isHidden = true
        imgFreeOngkir.isHidden = true
        btnTawar.isHidden = true
        btnLove.isHidden = true
        affiliateLogo.isHidden = true
        //captionOldPrice.isHidden = false
        
        ivCover.afCancelRequest()
        avatar.afCancelRequest()
        affiliateLogo.afCancelRequest()
        
        isFeatured = false
        
        imgFreeOngkir.image = UIImage(named: "ic_free_ongkir")
    }
    
    func adapt(_ product : Product, listStage : Int, currentMode : ListItemMode, shopAvatar : URL?, parent: BaseViewController) {
        self.product = product
        
        let obj = product.json
        captionTitle.text = product.name
        captionPrice.text = product.price
        let loveCount = obj["love"].int
        captionLove.text = String(loveCount == nil ? 0 : loveCount!)
        let commentCount = obj["discussions"].int
        captionComment.text = String(commentCount == nil ? 0 : commentCount!)
        
        self.pid = obj["_id"].string
        self.cid = obj["category_id"].string
        self.sid = obj["seller_id"].string
        
        //self.sname = ""
        
        if !self.isFeatured {
            self.isFeatured = product.isFeatured
        }
        
        if self.isNeedSetup {
            self.isNeedSetup = false
            
            self.setupCell(parent, currentMode: currentMode, shopAvatar: shopAvatar, listStage: listStage)
        }
        
        if (product.specialStory == nil || product.specialStory == "") {
            sectionSpecialStory.isHidden = true
        } else {
            sectionSpecialStory.isHidden = false
            captionSpecialStory.text = "\"\(product.specialStory!)\""
            
            if currentMode != .shop && currentMode != .newShop {
                if let url = product.avatar {
                    avatar.afSetImage(withURL: url, withFilter: .circle)
                } else {
                    avatar.image = nil
                }
            }
        }
        
        /*
        let loved = obj["is_preloved"].bool
        if (loved == true) {
            captionMyLove.text = ""
        } else {
            captionMyLove.text = ""
        }
        */
        
        let myId = CDUser.getOne()?.id
        if ((self.sid != myId) && product.isAggregate == false && product.isAffiliate == false) {
            btnLove.isHidden = false
            
            //-------------------
            // inside setup cell
            //-------------------
            
            newLove = obj["love"].bool
            if (newLove == true) {
                buttonLoveChange(isLoved: true)
            } else {
                buttonLoveChange(isLoved: false)
            }
            
            // affiliate checkout -> hunstreet
            if product.isCheckout {
                self.imgFreeOngkir.afSetImage(withURL: (product.AffiliateData?.icon)!, withFilter: .circle)
                /*if let url = product.avatar {
                    self.imgFreeOngkir.afSetImage(withURL: url, withFilter: .circle)
                } else if currentMode == .shop || currentMode == .newShop {
                    self.imgFreeOngkir.afSetImage(withURL: shopAvatar!, withFilter: .circle)
                }*/
                self.imgFreeOngkir.isHidden = false
            }
        }
        
        self.ivCover.afSetImage(withURL: product.coverImageURL!)
        ////print(product.coverImageURL!)
        
        if let op = product.json["price_original"].int {
            captionOldPrice.text = op.asPrice
            let s = captionOldPrice.text! as NSString
            let attString = NSMutableAttributedString(string: s as String)
            attString.addAttributes([NSStrikethroughStyleAttributeName:NSUnderlineStyle.styleSingle.rawValue], range: s.range(of: s as String))
            captionOldPrice.attributedText = attString
        }
        
        if product.isAggregate {
            captionOldPrice.text = "Mulai dari"
        } else if product.isAffiliate {
            let url = URL(string: product.json["affiliate_data"]["affiliate_icon"].stringValue)
            
            //-------------------
            // inside setup cell
            //-------------------
            
            //affiliateLogo.afSetImage(withURL: url!, withFilter: .noneWithoutPlaceHolder)
            
            // CRASH sometimes
            affiliateLogo.afSetImage(withURL: url!, withFilter: .fitWithoutPlaceHolder)
            
            /*
            let imageTransition = UIImageView.ImageTransition.crossDissolve(0.2)
            
            let filter = AspectScaledToFitSizeFilter(
                size: affiliateLogo.frame.size
            )
            
            affiliateLogo.af_setImage(
                withURL: url!,
                filter: filter,
                imageTransition: imageTransition,
                completion: { res in
                    self.affiliateLogo.image?.afInflate()
            })
 */
            affiliateLogo.isHidden = false
        }
        
        if let status = product.status {
            if (status == 4 || status == 8) { // sold
                self.imgSold.isHidden = false
            } else if (status == 7) { // reserved
                self.imgReserved.isHidden = false
            } else if (product.isFeatured) { // featured
                self.imgFeatured.isHidden = false
            }
        }
        
        if product.isFreeOngkir {
            imgFreeOngkir.isHidden = false
        }
    }
    
    func setupCell(_ parent: BaseViewController, currentMode: ListItemMode, shopAvatar: URL?, listStage: Int) {
        self.parent = parent
        self.currentMode = currentMode
        
        avatar.contentMode = .scaleAspectFill
        avatar.layoutIfNeeded()
        avatar.layer.cornerRadius = avatar.bounds.width / 2
        avatar.layer.masksToBounds = true
        
        avatar.layer.borderColor = Theme.GrayLight.cgColor
        avatar.layer.borderWidth = 1
        
        if let url = shopAvatar, currentMode == .shop || currentMode == .newShop {
            avatar.afSetImage(withURL: url, withFilter: .circle)
        }
        
        // for standard product
        var const : CGFloat = CGFloat(30)
        
        if listStage == 1 && AppTools.isIPad == false {
            const = CGFloat(15)
        } else if listStage == 3 {
            if AppTools.isIPad == false  {
                const = CGFloat(39)
            } else {
                const = CGFloat(45)
            }
        }
        
        consbtnWidthLove.constant = const
        consbtnHeightLove.constant = const
        btnLove.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        
        consHeightFO.constant = const
        consWidthFO.constant = const
        
        // for affiliate icon
        
        let w = const / 3 * 8
        affiliateLogo.frame = CGRect(x: self.bounds.width - w - 4, y: self.bounds.maxY - const - 4, width: w, height: const)
        
        affiliateLogo.contentMode = .scaleAspectFit
        consWidthAffiliateLogo.constant = w
        consHeightAffiliateLogo.constant = const
    }
    
    func buttonLoveChange(isLoved : Bool) {
        if isLoved == true {
            let image = UIImage(named: "ic_love_96px.png")?.withRenderingMode(.alwaysTemplate)
            btnLove.setImage(image, for: .normal)
            btnLove.tintColor = Theme.ThemeRed
        } else {
            let image = UIImage(named: "ic_love_96px_trp.png")?.withRenderingMode(.alwaysTemplate)
            btnLove.setImage(image, for: .normal)
            btnLove.tintColor = Theme.GrayLight
        }
    
    }
    
    @IBAction func btnLovePressed(_ sender: Any) {
        if product.isAggregate == false && product.isAffiliate == false {
            if (User.IsLoggedIn == true) {
                if (newLove == true) {
                    newLove = false
                    buttonLoveChange(isLoved: false)
                    callApiUnlove()
                } else {
                    newLove = true
                    buttonLoveChange(isLoved: true)
                    callApiLove()
                }
            } else {
                // call login
                LoginViewController.Show(self.parent.previousController!, userRelatedDelegate: self.parent.previousController as! UserRelatedDelegate?, animated: true)
            }
        }
    }

    func callApiLove()
    {
        /*
        // Mixpanel
        let pt = [
            "Product Name" : self.captionTitle.text,
            "Category Id" : self.cid,
            "Seller Id" : self.sid
        ]
        Mixpanel.trackEvent(MixpanelEvent.ToggledLikeProduct, properties: pt)
         */
        
        // API Migrasi
        let _ = request(APIProduct.love(productID: self.pid!)).responseJSON {resp in
            //print(resp)
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Love Product"))
            {
//                Constant.showDialog("Lovelist", message: self.captionTitle.text! + " berhasil ditambahkan ke Lovelist")
                
                // Prelo Analytic - Love
                let loginMethod = User.LoginMethod ?? ""
                let pdata = [
                    "Product ID": self.pid!,
                    "Seller ID" : self.sid!,
                    "Screen" : (self.currentMode != .filter ? (self.currentMode == .shop || self.currentMode == .newShop ? PageName.Shop : PageName.Home ) :  PageName.SearchResult ),
                    "Is Featured" : self.isFeatured
                ] as [String : Any]
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.LoveProduct, data: pdata, previousScreen: self.parent.previousScreen, loginMethod: loginMethod)
            } else
            {
                self.newLove = false
                self.buttonLoveChange(isLoved: false)
            }
        }
    }
    
    func callApiUnlove()
    {
        // API Migrasi
        let _ = request(APIProduct.unlove(productID: self.pid!)).responseJSON {resp in
            //print(resp)
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Unlove Product"))
            {
//                Constant.showDialog("Lovelist", message: self.captionTitle.text! + " berhasil dihapus dari Lovelist")
                
                // Prelo Analytic - UnLove
                let loginMethod = User.LoginMethod ?? ""
                let pdata = [
                    "Product ID": self.pid!,
                    "Seller ID" : self.sid!,
                    "Screen" : (self.currentMode != .filter ? (self.currentMode == .shop || self.currentMode == .newShop ? PageName.Shop : PageName.Home ) :  PageName.SearchResult ),
                    "Is Featured" : self.isFeatured
                ] as [String : Any]
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.UnloveProduct, data: pdata, previousScreen: self.parent.previousScreen, loginMethod: loginMethod)
            } else
            {
                self.newLove = true
                self.buttonLoveChange(isLoved: true)
            }
        }
    }
}

// MARK: - Class

class ListFooter : UICollectionReusableView {
    @IBOutlet weak var loading : UIActivityIndicatorView!
    @IBOutlet weak var btnFooter: UIButton!
    @IBOutlet weak var lblFooter: UILabel!
    
    var btnFooterAction : () -> () = {}
    
    @IBAction func btnFooterPressed(_ sender: AnyObject) {
        self.btnFooterAction()
    }
}

// MARK: - Class

class StoreHeader : UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var captionName : UILabel!
    @IBOutlet weak var captionLocation : UILabel!
    @IBOutlet weak var captionDesc : UILabel!
    @IBOutlet weak var captionLove: UILabel!
    @IBOutlet weak var captionReview : UILabel!
    @IBOutlet weak var avatar : UIImageView!
    @IBOutlet weak var btnEdit : UIButton!
    @IBOutlet weak var captionTotal : UILabel!
    @IBOutlet weak var captionLastActive: UILabel!
    @IBOutlet weak var captionChatPercentage: UILabel!
    @IBOutlet weak var colectionView: UICollectionView!
    @IBOutlet weak var consWidthColectionView: NSLayoutConstraint!
    @IBOutlet weak var consTopVwImage: NSLayoutConstraint! // 28 --> 58
    @IBOutlet weak var vwCollectionView: UIView!
    var completeDesc : String = ""
    @IBOutlet weak var vwLove: UIView!
    
    var editBlock : ()->() = {}
    var reviewBlock : ()->() = {}
    var zoomAvatarBlock : ()->() = {}
    var seeMoreBlock : ()->() = {}
    
    var avatarUrls : [String] = []
    
    var badges : Array<URL>! = []
    var badgesBlock : ()->() = {}
    
    @IBAction func edit() {
        self.editBlock()
    }
    
    @IBAction func gotoShopReview(_ sender: AnyObject) {
        self.reviewBlock()
    }
    
    @IBAction func avatarPressed(_ sender: AnyObject) {
        self.zoomAvatarBlock()
    }
    
    @IBAction func seeMore(_ sender: AnyObject) {
        if (self.completeDesc != "" && self.captionDesc.text != self.completeDesc) {
            self.seeMoreBlock()
        }
    }
    
    @IBAction func btnBadgesPressed(_ sender: Any) {
        self.badgesBlock()
    }
    
    func setupCollection() {
        
        let width = 39 * CGFloat(self.badges.count) + 9
        
        // Set collection view
        self.colectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcProgressCell")
        self.colectionView.delegate = self
        self.colectionView.dataSource = self
        self.colectionView.backgroundView = UIView(frame: self.colectionView.bounds)
        self.colectionView.backgroundColor = UIColor.clear
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        layout.itemSize = CGSize(width: 38, height: 38)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        self.colectionView.collectionViewLayout = layout
        
        self.colectionView.isScrollEnabled = false
        self.consWidthColectionView.constant = width
    }
    
    // MARK: - CollectionView delegate functions
    
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.badges!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = self.colectionView.dequeueReusableCell(withReuseIdentifier: "collcProgressCell", for: indexPath)
//        if (badges.count > (indexPath as NSIndexPath).row) {
            // Create icon view
            let vwIcon : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
            
            let img = UIImageView(frame: CGRect(x: 2, y: 2, width: 34, height: 34))
            img.layoutIfNeeded()
            img.layer.cornerRadius = (img.width ) / 2
            img.layer.masksToBounds = true
            img.afSetImage(withURL: badges[(indexPath as NSIndexPath).row], withFilter: .circleWithBadgePlaceHolder)
            
            vwIcon.addSubview(img)
            
            // Add view to cell
            cell.addSubview(vwIcon)
//        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 38, height: 38)
    }
}

// MARK: - cell Store Info / Header
class StoreInfo : UICollectionViewCell {
    @IBOutlet weak var captionDesc : UILabel!
    @IBOutlet weak var captionTotal : UILabel!
    @IBOutlet weak var captionLastActive: UILabel!
    @IBOutlet weak var captionChatPercentage: UILabel!
    @IBOutlet weak var vwGroup: UIView!
    
    var completeDesc : String = ""
    
    var seeMoreBlock : ()->() = {}
    
    @IBOutlet var vwLove: UIView!
    var floatRatingView: FloatRatingView!
    
    @IBOutlet weak var vwVerified: UIView!
    @IBOutlet weak var consHeightVwVerified: NSLayoutConstraint!
    
    static func heightFor(_ json: JSON, isExpand: Bool) -> CGFloat {
        var height = 21 + 94
        var completeDesc = ""
        if let desc = json["profile"]["description"].string
        {
            completeDesc = desc
            let descLengthCollapse = 160
            var descHeight : Int = 0
            
            if isExpand == false {
                if (desc.length > descLengthCollapse) { let descToWrite = desc.substringToIndex(descLengthCollapse - 1) + "... Selengkapnya"
                    descHeight = Int(descToWrite.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.width-24).height)
                } else {
                    descHeight = Int(desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.width-24).height)
                }
                
            } else {
                descHeight = Int(completeDesc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.width-24).height)
            }
            height += descHeight
            
        } else {
            completeDesc = "Belum ada deskripsi."
            height += Int(completeDesc.boundsWithFontSize(UIFont.systemFont(ofSize: 16), width: UIScreen.main.bounds.width-24).height)
        }
        
        if let isAffiliate = json["is_affiliate"].bool, isAffiliate {
            height += 21
        }
        
        return CGFloat(height)
    }
    
    func adapt(_ json:JSON, count: Int, isExpand: Bool, star: Float) {
        // love
        
        // Love floatable
        self.floatRatingView = FloatRatingView(frame: CGRect(x: UIScreen.main.bounds.width - 90 - 24 - 118 - 8, y: 2, width: 90, height: 16))
        self.floatRatingView.emptyImage = UIImage(named: "ic_love_96px_trp.png")?.withRenderingMode(.alwaysTemplate)
        self.floatRatingView.fullImage = UIImage(named: "ic_love_96px.png")?.withRenderingMode(.alwaysTemplate)
        // Optional params
        //                self.floatRatingView.delegate = self
        self.floatRatingView.contentMode = UIViewContentMode.scaleAspectFit
        self.floatRatingView.maxRating = 5
        self.floatRatingView.minRating = 0
        self.floatRatingView.rating = star
        self.floatRatingView.editable = false
        self.floatRatingView.halfRatings = true
        self.floatRatingView.floatRatings = true
        self.floatRatingView.tintColor = Theme.ThemeRed
        
        self.vwLove.addSubview(self.floatRatingView )
        
        if let isAffiliate = json["is_affiliate"].bool, isAffiliate {
            self.vwVerified.isHidden = false
            self.consHeightVwVerified.constant = 21
        } else {
            self.vwVerified.isHidden = true
            self.consHeightVwVerified.constant = 0
        }
        
        // Last seen
        if let lastSeenDateString = json["others"]["last_seen"].string {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let lastSeenDate = formatter.date(from: lastSeenDateString) {
                self.captionLastActive.text = lastSeenDate.relativeDescription
            }
        }
        
        // Chat percentage
        if let chatPercentage = json["others"]["replied_chat_percentage"].int {
            self.captionChatPercentage.text = "\(chatPercentage)%"
        }
        
        if let desc = json["profile"]["description"].string
        {
            completeDesc = desc
            let descLengthCollapse = 160
            
            if isExpand == false {
                if (desc.length > descLengthCollapse) {
                    let descToWrite = desc.substringToIndex(descLengthCollapse - 1) + "... Selengkapnya"
                    let descMutableString : NSMutableAttributedString = NSMutableAttributedString(string: descToWrite, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)])
                    descMutableString.addAttribute(NSForegroundColorAttributeName, value: Theme.PrimaryColorDark, range: NSRange(location: descLengthCollapse + 3, length: 12))
                    self.captionDesc.attributedText = descMutableString
//                    self.captionDesc.text = descToWrite
                } else {
                    let descMutableString : NSMutableAttributedString = NSMutableAttributedString(string: desc, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)])
                    self.captionDesc.attributedText = descMutableString
//                    self.captionDesc.text = desc
                }
            } else {
                let descMutableString : NSMutableAttributedString = NSMutableAttributedString(string: completeDesc, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)])
                self.captionDesc.attributedText = descMutableString
//                self.captionDesc.text = completeDesc
            }
            
        } else {
            self.captionDesc.text = "Belum ada deskripsi."
            self.captionDesc.textColor = UIColor.lightGray
        }
        
        
        // Total products and sold products
        if let productCount = json["total_product"].int {
            if let soldProductCount = json["total_product_sold"].int {
                self.captionTotal.text = "\(productCount) BARANG | \(soldProductCount) TERJUAL"
            } else {
                self.captionTotal.text = "\(productCount) BARANG"
            }
        } else {
            self.captionTotal.text = String(count) + " BARANG"
        }
    }
}

class ButtonJualView: UIView {
    var icon: UILabel = UILabel()  // icon foto
    var label: UILabel = UILabel() // label JUAL
    var btn: UIButton = UIButton() // button
    
    var parent: UIViewController!
    var currentPage: String!
    
    func addCustomView(parent: UIViewController, currentPage: String) {
        self.parent = parent
        self.currentPage = currentPage
        
        self.frame = CGRect(x: 0, y: 0, width: 64, height: 64)
        self.backgroundColor = UIColor.init(hexString: "#FD9226")
        
        icon.frame = CGRect(x: 8, y: 12, width: 48, height: 26)
        icon.textColor = UIColor.white
        icon.textAlignment = NSTextAlignment.center
        icon.text = ""
        icon.font = AppFont.preloAwesome.getFont(22)!
        self.addSubview(icon)
        
        label.frame = CGRect(x: 15, y: 38, width: 34.5, height: 16)
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        label.text = "JUAL"
        label.font = UIFont.boldSystemFont(ofSize: 13)
        self.addSubview(label)
        
        btn.frame = CGRect(x: 0, y: 0, width: 64, height: 64)
        btn.backgroundColor = UIColor.clear
        btn.addTarget(self, action: #selector(ButtonJualView.sellPressed(_:)), for: UIControlEvents.touchUpInside)
        
        self.addSubview(btn)
        
        self.layoutIfNeeded()
        self.layer.cornerRadius = (self.frame.size.width) / 2
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.layer.shadowOpacity = 0.3
    }
    
    func sellPressed(_ sender: AnyObject) {
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        add.screenBeforeAddProduct = self.currentPage
        self.parent.navigationController?.pushViewController(add, animated: true)
    }
}
