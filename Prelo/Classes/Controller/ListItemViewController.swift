//
//  ListItemViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import MessageUI
import Alamofire

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
}

enum ListItemMode {
    case `default`
    case standalone
    case shop
    case featured
    case segment
    case filter
}

class ListItemViewController: BaseViewController, MFMailComposeViewControllerDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, FilterDelegate, CategoryPickerDelegate, ListBrandDelegate {
    
    // MARK: - Struct
    
    struct SegmentItem {
        var type : String = ""
        var name : String = ""
        var image : UIImage = UIImage()
    }
    
    struct SubcategoryItem {
        var id : String = ""
        var name : String = ""
        var image : UIImage = UIImage()
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
    // Views
    @IBOutlet var vwTopHeaderFilter: UIView!
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
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        case .shop:
            self.title = shopName
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
        if (currentMode == .standalone || currentMode == .shop || currentMode == .filter) {
            self.setupContent()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Status bar style
        self.setStatusBarStyle(style: .lightContent)
        
        // Add status bar tap observer
        NotificationCenter.default.addObserver(self, selector: #selector(ListItemViewController.statusBarTapped), name: NSNotification.Name(rawValue: AppDelegate.StatusBarTapNotificationName), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //print("viewWillDisappear x")
        
        // Remove status bar tap observer
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: AppDelegate.StatusBarTapNotificationName), object: nil)
        
        // Show navbar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.repositionScrollCategoryNameContent()
        self.showStatusBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Default search text
        if (currentMode == .filter) {
            self.searchBar.text = self.fltrName
        }
        
        // Mixpanel for store mode
        if (currentMode == .shop) {
            if (User.IsLoggedIn && self.shopId == User.Id!) {
                // Mixpanel
                Mixpanel.trackPageVisit(PageName.ShopMine)
                
                // Google Analytics
                GAI.trackPageVisit(PageName.ShopMine)
            } else {
                // Mixpanel
                let p = [
                    "Seller" : shopName,
                    "Seller ID" : self.shopId
                ]
                Mixpanel.trackPageVisit(PageName.Shop, otherParam: p)
                
                // Google Analytics
                GAI.trackPageVisit(PageName.Shop)
            }
        }
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        if (self.isBackToFltrSearch) {
            let viewControllers: [UIViewController] = (self.navigationController?.viewControllers)!
            _ = self.navigationController?.popToViewController(viewControllers[1], animated: true);
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    func setupContent() {
        if (!isContentLoaded) {
            isContentLoaded = true
            
            // Default, Standalone, Shop, and Filter mode is predefined
            // Featured and Segment mode will be identified here
            // Carousel and Subcategories also will be identified here
            
            // Identify Segment mode
            if let segmentsJson = self.categoryJson?["segments"].array, segmentsJson.count > 0 {
                self.currentMode = .segment
                for i in 0...segmentsJson.count - 1 {
                    var img : UIImage = UIImage()
                    if let url = URL(string: segmentsJson[i]["image"].stringValue) {
                        if let data = try? Data(contentsOf: url) {
                            if let uiimg = UIImage(data: data) {
                                img = uiimg
                            }
                        }
                    }
                    self.segments.append(SegmentItem(type: segmentsJson[i]["type"].stringValue, name: segmentsJson[i]["name"].stringValue, image: img))
                }
                self.listItemSections.remove(at: self.listItemSections.index(of: .products)!)
                self.listItemSections.insert(.segments, at: 0)
            }
            // Identify Featured mode
            if let isFeatured = self.categoryJson?["is_featured"].bool, isFeatured {
                self.currentMode = .featured
                self.listItemSections.insert(.featuredHeader, at: 0)
            }
            // Identify Subcategories
            if let subcatJson = self.categoryJson?["sub_categories"].array, subcatJson.count > 0 {
                self.isShowSubcategory = true
                for i in 0...subcatJson.count - 1 {
                    var img : UIImage = UIImage()
                    if let url = URL(string: subcatJson[i]["image"].stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!) {
                        if let data = try? Data(contentsOf: url) {
                            if let uiimg = UIImage(data: data) {
                                img = uiimg
                            }
                        }
                    }
                    self.subcategoryItems.append(SubcategoryItem(id: subcatJson[i]["_id"].stringValue, name: subcatJson[i]["name"].stringValue, image: img))
                }
                self.listItemSections.insert(.subcategories, at: 0)
            }
            // Identify Carousel
            if let carouselJson = self.categoryJson?["carousel"].array, carouselJson.count > 0 {
                self.isShowCarousel = true
                self.carouselItems = []
                for i in 0..<carouselJson.count {
                    var img = UIImage()
                    var link : URL!
                    if let url = URL(string: carouselJson[i]["image"].stringValue), let data = try? Data(contentsOf: url), let uiimg = UIImage(data: data) {
                        img = uiimg
                    }
                    if let url = URL(string: carouselJson[i]["link"].stringValue) {
                        link = url
                    }
                    let item = CarouselItem.init(name: carouselJson[i]["name"].stringValue, img: img, link: link)
                    self.carouselItems.append(item)
                }
                self.listItemSections.insert(.carousel, at: 0)
            }
            
            // Adjust content base on the mode
            switch (currentMode) {
            case .default, .standalone, .shop:
                // Upper 4px padding handling
                self.consTopTopHeader.constant = 0
                
                // Top header setup
                self.consHeightVwTopHeader.constant = 0
                
                // Get initial products
                self.getInitialProducts()
            case .featured:
                // Upper 4px padding handling
                self.consTopTopHeader.constant = 4
                
                // Top header setup
                self.consHeightVwTopHeader.constant = 0
                
                // Set color
                if let name = categoryJson?["name"].string, name.lowercased() == "all" {
                    self.view.backgroundColor = Theme.GrayGranite // Upper 4px padding color
                    self.gridView.backgroundColor = Theme.GrayGranite // Background color
                }
                
                // Get initial products
                self.getInitialProducts()
            case .segment:
                // Top header setup
                consHeightVwTopHeader.constant = 40
                
                // Show segments
                self.setDefaultTopHeaderWomen()
                
                // Setup grid
                self.setupGrid()
            case .filter:
                // Upper 4px padding handling
                self.consTopTopHeader.constant = 4
                self.view.backgroundColor = UIColor(hexString: "#E8ECEE")
                
                // Top header setup
                consHeightVwTopHeader.constant = 52
                
                // Setup filter related views
                for i in 0...vwTopHeaderFilter.subviews.count - 1 {
                    vwTopHeaderFilter.subviews[i].createBordersWithColor(UIColor(hexString: "#e3e3e3"), radius: 0, width: 1)
                }
                vwTopHeaderFilter.isHidden = false
                vwTopHeader.isHidden = true
                if (fltrBrands.count > 0) {
                    if (fltrBrands.count == 1) {
                        lblFilterMerek.text = [String](fltrBrands.keys)[0]
                    } else {
                        lblFilterMerek.text = [String](fltrBrands.keys)[0] + ", \(fltrBrands.count - 1)+"
                    }
                } else {
                    lblFilterMerek.text = "All"
                }
                if (fltrCategId == "") {
                    lblFilterKategori.text = "All"
                } else {
                    lblFilterKategori.text = CDCategory.getCategoryNameWithID(fltrCategId)
                }
                lblFilterSort.text = self.FltrValSortBy[self.fltrSortBy]
                if (lblFilterSort.text?.lowercased() == "highest rp") {
                    lblFilterSort.font = UIFont.boldSystemFont(ofSize: 12)
                } else {
                    lblFilterSort.font = UIFont.boldSystemFont(ofSize: 13)
                }
                // Search bar setup
                var searchBarWidth = UIScreen.main.bounds.size.width * 0.8375
                if (AppTools.isIPad) {
                    searchBarWidth = UIScreen.main.bounds.size.width - 68
                }
                searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: searchBarWidth, height: 30))
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
                searchBar.delegate = self
                searchBar.placeholder = "Cari di Prelo"
                self.navigationItem.rightBarButtonItem = searchBar.toBarButton()
                
                // Get initial products
                self.getInitialProducts()
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
        self.requesting = true
        self.products = []
        self.done = false
        self.footerLoading?.isHidden = false
        self.setupGrid() // Agar muncul loading
        
        switch (currentMode) {
        case .shop, .filter:
            self.getProducts()
        case .featured:
            self.getFeaturedProducts()
        case .segment:
            if (self.listItemSections.contains(.products)) {
                self.getProducts()
            } else {
                self.refresher?.endRefreshing()
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
                    self.setupGrid()
                }
            }
        }
    }
    
    func getProducts() {
        switch (currentMode) {
        case .default:
            if let catId = categoryJson?["_id"].string {
                self.getCategorizedProducts(catId)
            }
        case .standalone:
            self.getCategorizedProducts(standaloneCategoryID)
        case .shop:
            self.getShopProducts()
        case .featured:
            self.getFeaturedProducts()
        case .segment:
            if (self.listItemSections.contains(.products)) {
                if let catId = categoryJson?["_id"].string {
                    self.getCategorizedProducts(catId)
                }
            }
        case .filter:
            self.getFilteredProducts()
        }
    }
    
    func getCategorizedProducts(_ catId : String) {
        requesting = true
        
        var lastTimeUuid = ""
        if (products != nil && products?.count > 0) {
            lastTimeUuid = products![products!.count - 1].updateTimeUuid
        }
        let _ = request(APISearch.productByCategory(categoryId: catId, sort: "recent", current: (products?.count)!, limit: itemsPerReq, priceMin: 0, priceMax: 999999999, segment: selectedSegment, lastTimeUuid: lastTimeUuid)).responseJSON { resp in
            self.requesting = false
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Product By Category")) {
                self.setupData(resp.result.value)
            }
            self.setupGrid()
        }
    }
    
    func getFeaturedProducts() {
        if (categoryJson == nil) {
            return
        }
        
        requesting = true
        
        _ = request(APIProduct.getAllFeaturedProducts(categoryId: self.categoryJson!["_id"].stringValue)).responseJSON { resp in
            self.requesting = false
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Featured Products")) {
                self.products = []
                
                self.setupData(resp.result.value)
            }
            self.refresher?.endRefreshing()
            self.setupGrid()
        }
    }
    
    func getFilteredProducts() {
        requesting = true
        
        let fltrNameReq = self.fltrName
        var lastTimeUuid = ""
        if (products != nil && products?.count > 0) {
            lastTimeUuid = products![products!.count - 1].updateTimeUuid
        }
        let _ = request(APISearch.productByFilter(name: fltrName, categoryId: fltrCategId, brandIds: AppToolsObjC.jsonString(from: [String](fltrBrands.values)), productConditionIds: AppToolsObjC.jsonString(from: fltrProdCondIds), segment: fltrSegment, priceMin: fltrPriceMin, priceMax: fltrPriceMax, isFreeOngkir: fltrIsFreeOngkir ? "1" : "", sizes: AppToolsObjC.jsonString(from: fltrSizes), sortBy: fltrSortBy, current: NSNumber(value: products!.count), limit: NSNumber(value: itemsPerReq), lastTimeUuid: lastTimeUuid)).responseJSON { resp in
            if (fltrNameReq == self.fltrName) { // Jika response ini sesuai dengan request terakhir
                self.requesting = false
                if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Filter Product")) {
                    self.setupData(resp.result.value)
                }
                self.refresher?.endRefreshing()
                self.setupGrid()
            }
        }
    }
    
    func getShopProducts() {
        self.requesting = true
        
        // API Migrasi
        let _ = request(APIUser.getShopPage(id: shopId, current: products!.count, limit: itemsPerReq)).responseJSON { resp in
            self.requesting = false
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Data Shop Pengguna")) {
                self.setupData(resp.result.value)
                
                if (self.shopHeader == nil) {
                    self.shopHeader = Bundle.main.loadNibNamed("StoreHeader", owner: nil, options: nil)?.first as? StoreHeader
                    self.gridView.addSubview(self.shopHeader!)
                }
                
                let json = JSON(resp.result.value!)["_data"]
                print(json)
                
                self.shopName = json["username"].stringValue
                self.shopHeader?.captionName.text = self.shopName
                self.title = self.shopName
                let avatarThumbnail = json["profile"]["pict"].stringValue
                self.shopHeader?.avatar.afSetImage(withURL: URL(string: avatarThumbnail)!)
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
                    height = 338 + descHeight
                } else {
                    self.shopHeader?.captionDesc.text = "Belum ada deskripsi."
                    self.shopHeader?.captionDesc.textColor = UIColor.lightGray
                    height = 338 + Int("Belum ada deskripsi.".boundsWithFontSize(UIFont.systemFont(ofSize: 16), width: UIScreen.main.bounds.width-14).height)
                }
                self.shopHeader?.width = UIScreen.main.bounds.width
                self.shopHeader?.height = CGFloat(height)
                self.shopHeader?.y = CGFloat(-height)
                
                self.shopHeader?.seeMoreBlock = {
                    if let completeDesc = self.shopHeader?.completeDesc {
                        self.shopHeader?.captionDesc.text = completeDesc
                        let descHeight = completeDesc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.width-16).height
                        let newHeight : CGFloat = descHeight + 338.0
                        self.shopHeader?.height = newHeight
                        self.shopHeader?.y = -newHeight
                        self.gridView.contentInset = UIEdgeInsetsMake(newHeight, 0, 0, 0)
                        self.gridView.setContentOffset(CGPoint(x: 0, y: -newHeight), animated: false)
                        
                        var refresherBound = self.refresher?.bounds
                        if (refresherBound != nil) {
                            refresherBound!.origin.y = CGFloat(newHeight)
                            self.refresher?.bounds = refresherBound!
                        }
                    }
                }
                
                self.shopHeader?.avatar.superview?.layoutIfNeeded()
                self.shopHeader?.avatar.superview?.layer.cornerRadius = (self.shopHeader?.avatar.width)!/2
                self.shopHeader?.avatar.superview?.layer.masksToBounds = true
                
                self.shopHeader?.btnEdit.isHidden = true
                if let id = json["_id"].string, let me = CDUser.getOne()
                {
                    if (id == me.id)
                    {
                        self.shopHeader?.btnEdit.isHidden = false
                    }
                }
                
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

                self.shopHeader?.editBlock = {
                    let userProfileVC = Bundle.main.loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil)?.first as! UserProfileViewController
                    self.navigationController?.pushViewController(userProfileVC, animated: true)
                }
                
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
                
                self.refresher?.endRefreshing()
                var refresherBound = self.refresher?.bounds
                if (refresherBound != nil) {
                    refresherBound!.origin.y = CGFloat(height)
                    self.refresher?.bounds = refresherBound!
                }
                self.setupGrid()
                self.gridView.contentInset = UIEdgeInsetsMake(CGFloat(height), 0, 0, 0)
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
                self.footerLoading?.isHidden = true
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
                self.footerLoading?.isHidden = true
            } else {
                for item in arr
                {
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
    
    func setupGrid() {
        if (currentMode == .filter && products?.count <= 0 && !requesting) {
            gridView.isHidden = true
            vwFilterZeroResult.isHidden = false
            if (fltrName != "") {
                lblFilterZeroResult.text = "Tidak ada hasil yang ditemukan untuk '\(fltrName)'"
                btnFilterZeroResult.isHidden = false
            } else {
                lblFilterZeroResult.text = "Tidak ada hasil yang ditemukan"
                btnFilterZeroResult.isHidden = true
            }
            return
        }
        
        if (gridView.dataSource == nil || gridView.delegate == nil) {
            gridView.dataSource = self
            gridView.delegate = self
        }
        
        if (!(currentMode == .segment && listItemSections.contains(.segments))) {
            if (listStage == 1) {
                itemCellWidth = ((UIScreen.main.bounds.size.width - 16) / 3)
            } else if (listStage == 2) {
                itemCellWidth = ((UIScreen.main.bounds.size.width - 12) / 2)
            } else if (listStage == 3) {
                itemCellWidth = ((UIScreen.main.bounds.size.width - 8) / 1)
            }
        }
        
        gridView.reloadData()
        gridView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0)
        gridView.isHidden = false
        vwFilterZeroResult.isHidden = true
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
            return self.subcategoryItems.count
        case .segments:
            return self.segments.count
        case .products:
            if let p = products {
                return p.count
            }
            return 0
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
                cell.adapt(name)
            }
            return cell
        case .subcategories:
            let cell : ListItemSubcategoryCell = collectionView.dequeueReusableCell(withReuseIdentifier: "subcategory_cell", for: indexPath) as! ListItemSubcategoryCell
            cell.imgSubcategory.image = subcategoryItems[(indexPath as NSIndexPath).item].image
            cell.lblSubcategory.isHidden = true // Unused label
            return cell
        case .segments:
            let cell : ListItemSegmentCell = collectionView.dequeueReusableCell(withReuseIdentifier: "segment_cell", for: indexPath) as! ListItemSegmentCell
            cell.imgSegment.image = segments[(indexPath as NSIndexPath).item].image
            return cell
        case .products:
            // Load next products here
            if (currentMode == .default || currentMode == .standalone || currentMode == .shop || currentMode == .filter || (currentMode == .segment && listItemSections.contains(.products))) {
                if ((indexPath as NSIndexPath).row == (products?.count)! - 4 && requesting == false && done == false) {
                    getProducts()
                }
            }
            
            
            let cell : ListItemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ListItemCell
            if (products?.count > (indexPath as NSIndexPath).item) {
                let p = products?[(indexPath as NSIndexPath).item]
                cell.adapt(p!)
            }
            if (currentMode == .featured) {
                // Hide featured ribbon
                cell.imgFeatured.isHidden = true
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let viewWidthMinusMargin = UIScreen.main.bounds.size.width - 8
        switch listItemSections[(indexPath as NSIndexPath).section] {
        case .carousel:
            var maxHeight : CGFloat = 0
            for i in 0..<self.carouselItems.count {
                let height = ((viewWidthMinusMargin / carouselItems[i].img.size.width) * carouselItems[i].img.size.height)
                if (height > maxHeight) {
                    maxHeight = height
                }
            }
            return CGSize(width: viewWidthMinusMargin, height: maxHeight)
        case .featuredHeader:
            return CGSize(width: viewWidthMinusMargin, height: 56)
        case .subcategories:
            return CGSize(width: viewWidthMinusMargin / 3, height: viewWidthMinusMargin / 3)
        case .segments:
            let segHeight = viewWidthMinusMargin * segments[(indexPath as NSIndexPath).item].image.size.height / segments[(indexPath as NSIndexPath).item].image.size.width
            return CGSize(width: viewWidthMinusMargin, height: segHeight)
        case .products:
            return CGSize(width: itemCellWidth!, height: itemCellWidth! + 46)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
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
        return UIEdgeInsetsMake(4, 4, 0, 4)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch listItemSections[(indexPath as NSIndexPath).section] {
        case .carousel:
            break
        case .featuredHeader:
            break
        case .subcategories:
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "showBottomBar"), object: nil)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.repositionScrollCategoryNameContent()
            self.showStatusBar()
            
            let p = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            p.currentMode = .filter
            p.fltrCategId = subcategoryItems[(indexPath as NSIndexPath).item].id
            p.fltrSortBy = "recent"
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
            self.refresh()
        case .products:
            self.selectedProduct = products?[(indexPath as NSIndexPath).item]
            if (currentMode == .featured) {
                selectedProduct?.setToFeatured()
            }
            self.launchDetail()
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
            
            // Loading handle
            self.footerLoading = f.loading
            if (self.done) {
                self.footerLoading?.isHidden = true
            }
            
            // Adapt
            if (currentMode == .featured && products?.count > 0) { // 'Lihat semua barang' button, only show if featured products is loaded
                f.btnFooter.isHidden = false
                f.btnFooterAction = {
                    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "showBottomBar"), object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    self.repositionScrollCategoryNameContent()
                    self.showStatusBar()
                    
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
                return CGSize(width: collectionView.width, height: 66)
            }
            return CGSize(width: collectionView.width, height: 50)
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
        if (draggingScrollView) {
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
                        self.repositionScrollCategoryNameContent()
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
                    self.repositionScrollCategoryNameContent()
                }
            }
        }
    }
    
    func repositionScrollCategoryNameContent() {
        // This function is made as a temporary solution for a bug where the scroll category name content size is become wrong after scroll
        if (scrollCategoryName != nil) {
            let bottomOffset = CGPoint(x: 0, y: Int(self.scrollCategoryName!.contentSize.height - self.scrollCategoryName!.bounds.size.height))
            self.scrollCategoryName!.setContentOffset(bottomOffset, animated: false)
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
    
    // MARK: - Filter delegate function
    
    func adjustFilter(_ fltrProdCondIds: [String], fltrPriceMin: NSNumber, fltrPriceMax: NSNumber, fltrIsFreeOngkir: Bool, fltrSizes: [String], fltrSortBy: String) {
        self.fltrProdCondIds = fltrProdCondIds
        self.fltrPriceMin = fltrPriceMin
        self.fltrPriceMax = fltrPriceMax
        self.fltrIsFreeOngkir = fltrIsFreeOngkir
        self.fltrSizes = fltrSizes
        self.fltrSortBy = fltrSortBy
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
            self.listItemSections.remove(at: self.listItemSections.index(of: .products)!)
            self.listItemSections.append(.segments)
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
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NotificationName.ShowProduct), object: self.selectedProduct)
    }
    
    // MARK: - Other functions
    
    func statusBarTapped() {
        gridView.setContentOffset(CGPoint(x: 0, y: 10), animated: true)
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "showBottomBar"), object: nil)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.repositionScrollCategoryNameContent()
    }
    
    func pinch(_ pinchedIn : Bool) {
        //print("current stage : \(listStage)")
        listStage += (pinchedIn ? 1 : -1)
        if (listStage > 3) {
            listStage = 1
        }
        if (listStage < 1) {
            listStage = 3
        }
        //print("next stage : \(listStage)")
        
        setupGrid()
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.gridView.reloadData()
        }, completion: nil)
    }
}

// MARK: - Class

class CarouselItem {
    var name : String = ""
    var img : UIImage = UIImage()
    var link : URL!
    
    init(name : String, img : UIImage, link : URL) {
        self.name = name
        self.img = img
        self.link = link
    }
}

// MARK: - Class

class ListItemSubcategoryCell : UICollectionViewCell {
    
    @IBOutlet var imgSubcategory: UIImageView!
    @IBOutlet var lblSubcategory: UILabel!
    
    override func prepareForReuse() {
        imgSubcategory.image = nil
    }
}

// MARK: - Class

class ListItemSegmentCell : UICollectionViewCell {
    @IBOutlet var imgSegment: UIImageView!
    
    override func prepareForReuse() {
        imgSegment.image = nil
    }
}

// MARK: - Class

class ListItemCarouselCell : UICollectionViewCell, UIScrollViewDelegate {
    @IBOutlet var scrlVwCarousel: UIScrollView!
    @IBOutlet var contentVwCarousel: UIView!
    @IBOutlet var pageCtrlCarousel: UIPageControl!
    @IBOutlet var consWidthContentVwCarousel: NSLayoutConstraint!
    var carouselItems : [CarouselItem] = []
    
    func adapt(_ carouselItems : [CarouselItem]) {
        self.carouselItems = carouselItems
        scrlVwCarousel.delegate = self
        
        self.pageCtrlCarousel.numberOfPages = carouselItems.count
        self.pageCtrlCarousel.currentPage = 0
        var rectHeightFix : CGFloat = 0
        let rectWidthFix : CGFloat = UIScreen.main.bounds.size.width - 8
        self.consWidthContentVwCarousel.constant = rectWidthFix * CGFloat(carouselItems.count)
        for i in 0..<carouselItems.count {
            let height = ((rectWidthFix / carouselItems[i].img.size.width) * carouselItems[i].img.size.height)
            if (height > rectHeightFix) {
                rectHeightFix = height
            }
        }
        for i in 0...carouselItems.count - 1 {
            let rect = CGRect(x: CGFloat(i * Int(rectWidthFix)), y: 0, width: rectWidthFix, height: rectHeightFix)
            let uiImg = UIImageView(frame: rect, image: carouselItems[i].img)
            let uiBtn = UIButton(frame: rect)
            uiBtn.addTarget(self, action: #selector(ListItemCarouselCell.btnCarouselPressed(_:)), for: UIControlEvents.touchUpInside)
            uiBtn.tag = i
            contentVwCarousel.addSubview(uiImg)
            contentVwCarousel.addSubview(uiBtn)
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
    
    func adapt(_ categName : String) {
        let edPickCategName = ["all", "home", "semua"]
        if (edPickCategName.contains(categName.lowercased())) {
            self.lblTitle.text = "EDITOR'S PICK"
            self.lblTitle.textColor = UIColor.white
            self.lblDesc.text = "Daftar barang terbaik yang dipilih oleh tim Prelo"
            self.lblDesc.textColor = UIColor.white
        } else {
            self.lblTitle.text = "HIGHLIGHTS"
            self.lblTitle.textColor = UIColor(hexString: "#5d5d5d")
            self.lblDesc.text = "Barang \(categName) pilihan tim Prelo"
            self.lblDesc.textColor = UIColor(hexString: "#5d5d5d")
        }
    }
}

// MARK: - Class

class ListItemCell : UICollectionViewCell {
    @IBOutlet var ivCover: UIImageView!
    @IBOutlet var captionTitle: UILabel!
    @IBOutlet var captionPrice: UILabel!
    @IBOutlet var captionOldPrice: UILabel!
    @IBOutlet var captionLove: UILabel!
    @IBOutlet var captionMyLove: UILabel!
    @IBOutlet var captionComment: UILabel!
    @IBOutlet var sectionLove : UIView!
    @IBOutlet var avatar : UIImageView!
    @IBOutlet var captionSpecialStory : UILabel!
    @IBOutlet var sectionSpecialStory : UIView!
    @IBOutlet var imgSold: UIImageView!
    @IBOutlet var imgReserved: UIImageView!
    @IBOutlet var imgFeatured: UIImageView!
    @IBOutlet var imgFreeOngkir: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sectionLove.layoutIfNeeded()
        sectionLove.layer.cornerRadius = sectionLove.frame.size.width/2
        sectionLove.layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        imgSold.isHidden = true
        imgReserved.isHidden = true
        imgFeatured.isHidden = true
        imgFreeOngkir.isHidden = true
    }
    
    func adapt(_ product : Product) {
        let obj = product.json
        captionTitle.text = product.name
        captionPrice.text = product.price
        let loveCount = obj["love"].int
        captionLove.text = String(loveCount == nil ? 0 : loveCount!)
        let commentCount = obj["discussions"].int
        captionComment.text = String(commentCount == nil ? 0 : commentCount!)
        
        avatar.contentMode = .scaleAspectFill
        avatar.layoutIfNeeded()
        avatar.layer.cornerRadius = avatar.bounds.width / 2
        avatar.layer.masksToBounds = true
        
        if (product.specialStory == nil || product.specialStory == "") {
            sectionSpecialStory.isHidden = true
        } else {
            sectionSpecialStory.isHidden = false
            captionSpecialStory.text = "\"\(product.specialStory!)\""
            if let url = product.avatar {
                avatar.afSetImage(withURL: url)
            } else {
                avatar.image = nil
            }
        }
        
        let loved = obj["is_preloved"].bool
        if (loved == true) {
            captionMyLove.text = ""
        } else {
            captionMyLove.text = ""
        }
        
        _ = obj["display_picts"][0].string
        ivCover.image = nil
        ivCover.afSetImage(withURL: product.coverImageURL!)
        
        if let op = product.json["price_original"].int {
            captionOldPrice.text = op.asPrice
            let s = captionOldPrice.text! as NSString
            let attString = NSMutableAttributedString(string: s as String)
            attString.addAttributes([NSStrikethroughStyleAttributeName:NSUnderlineStyle.styleSingle.rawValue], range: s.range(of: s as String))
            captionOldPrice.attributedText = attString
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
}

// MARK: - Class

class ListFooter : UICollectionReusableView {
    @IBOutlet var loading : UIActivityIndicatorView!
    @IBOutlet var btnFooter: UIButton!
    @IBOutlet var lblFooter: UILabel!
    
    var btnFooterAction : () -> () = {}
    
    @IBAction func btnFooterPressed(_ sender: AnyObject) {
        self.btnFooterAction()
    }
}

// MARK: - Class

class StoreHeader : UIView {
    @IBOutlet var captionName : UILabel!
    @IBOutlet var captionLocation : UILabel!
    @IBOutlet var captionDesc : UILabel!
    @IBOutlet var captionLove: UILabel!
    @IBOutlet var captionReview : UILabel!
    @IBOutlet var avatar : UIImageView!
    @IBOutlet var btnEdit : UIButton!
    @IBOutlet var captionTotal : UILabel!
    @IBOutlet var captionLastActive: UILabel!
    @IBOutlet var captionChatPercentage: UILabel!
    
    var completeDesc : String = ""
    
    var editBlock : ()->() = {}
    var reviewBlock : ()->() = {}
    var zoomAvatarBlock : ()->() = {}
    var seeMoreBlock : ()->() = {}
    
    var avatarUrls : [String] = []
    
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
}
