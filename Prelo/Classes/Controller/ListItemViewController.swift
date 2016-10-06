//
//  ListItemViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import MessageUI

// MARK: - Class

enum ListItemSectionType {
    case Carousel
    case FeaturedHeader
    case Subcategories
    case Segments
    case Products
}

enum ListItemMode {
    case Default
    case Standalone
    case Shop
    case Featured
    case Segment
    case Filter
}

class ListItemViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, UISearchBarDelegate, FilterDelegate, CategoryPickerDelegate, ListBrandDelegate, MFMailComposeViewControllerDelegate {
    
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
    var currScrollPoint : CGPoint = CGPointZero
    var itemsPerReq = 24 // Amount of items per request
    
    // Data container
    var categoryJson : JSON? // Set from previous screen
    var products : Array <Product>? // From API response
    var selectedProduct : Product? // For navigating to product detail
    var listItemSections : [ListItemSectionType] = [.Products]
    
    // Flags
    var requesting : Bool = false
    var done : Bool = false
    var draggingScrollView : Bool = false
    var isContentLoaded : Bool = false
    
    // Mode
    var currentMode = ListItemMode.Default
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
        case .Standalone:
            self.title = standaloneCategoryName
        case .Shop:
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
        refresher!.addTarget(self, action: #selector(ListItemViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
        self.gridView.addSubview(refresher!)
        
        // Setup content for filter, shop, or standalone mode
        if (currentMode == .Standalone || currentMode == .Shop || currentMode == .Filter) {
            self.setupContent()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Status bar style
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        
        // Add status bar tap observer
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListItemViewController.statusBarTapped), name: AppDelegate.StatusBarTapNotificationName, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //print("viewWillDisappear x")
        
        // Remove status bar tap observer
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AppDelegate.StatusBarTapNotificationName, object: nil)
        
        // Show navbar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Default search text
        if (currentMode == .Filter) {
            self.searchBar.text = self.fltrName
        }
        
        // Mixpanel for store mode
        if (currentMode == .Shop) {
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
    
    override func backPressed(sender: UIBarButtonItem) {
        if (self.isBackToFltrSearch) {
            let viewControllers: [UIViewController] = (self.navigationController?.viewControllers)!
            self.navigationController?.popToViewController(viewControllers[1], animated: true);
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func setupContent() {
        if (!isContentLoaded) {
            isContentLoaded = true
            
            // Default, Standalone, Shop, and Filter mode is predefined
            // Featured and Segment mode will be identified here
            // Carousel and Subcategories also will be identified here
            
            // Identify Segment mode
            if let segmentsJson = self.categoryJson?["segments"].array where segmentsJson.count > 0 {
                self.currentMode = .Segment
                for i in 0...segmentsJson.count - 1 {
                    var img : UIImage = UIImage()
                    if let url = NSURL(string: segmentsJson[i]["image"].stringValue) {
                        if let data = NSData(contentsOfURL: url) {
                            if let uiimg = UIImage(data: data) {
                                img = uiimg
                            }
                        }
                    }
                    self.segments.append(SegmentItem(type: segmentsJson[i]["type"].stringValue, name: segmentsJson[i]["name"].stringValue, image: img))
                }
                self.listItemSections.removeAtIndex(self.listItemSections.indexOf(.Products)!)
                self.listItemSections.insert(.Segments, atIndex: 0)
            }
            // Identify Featured mode
            if let isFeatured = self.categoryJson?["is_featured"].bool where isFeatured {
                self.currentMode = .Featured
                self.listItemSections.insert(.FeaturedHeader, atIndex: 0)
            }
            // Identify Subcategories
            if let subcatJson = self.categoryJson?["sub_categories"].array where subcatJson.count > 0 {
                self.isShowSubcategory = true
                for i in 0...subcatJson.count - 1 {
                    var img : UIImage = UIImage()
                    if let url = NSURL(string: subcatJson[i]["image"].stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!) {
                        if let data = NSData(contentsOfURL: url) {
                            if let uiimg = UIImage(data: data) {
                                img = uiimg
                            }
                        }
                    }
                    self.subcategoryItems.append(SubcategoryItem(id: subcatJson[i]["_id"].stringValue, name: subcatJson[i]["name"].stringValue, image: img))
                }
                self.listItemSections.insert(.Subcategories, atIndex: 0)
            }
            // Identify Carousel
            if let carouselJson = self.categoryJson?["carousel"].array where carouselJson.count > 0 {
                self.isShowCarousel = true
                self.carouselItems = []
                for i in 0..<carouselJson.count {
                    var img = UIImage()
                    var link = NSURL()
                    if let url = NSURL(string: carouselJson[i]["image"].stringValue), let data = NSData(contentsOfURL: url), let uiimg = UIImage(data: data) {
                        img = uiimg
                    }
                    if let url = NSURL(string: carouselJson[i]["link"].stringValue) {
                        link = url
                    }
                    let item = CarouselItem.init(name: carouselJson[i]["name"].stringValue, img: img, link: link)
                    self.carouselItems.append(item)
                }
                self.listItemSections.insert(.Carousel, atIndex: 0)
            }
            
            // Adjust content base on the mode
            switch (currentMode) {
            case .Default, .Standalone, .Shop:
                // Upper 4px padding handling
                self.consTopTopHeader.constant = 0
                
                // Top header setup
                self.consHeightVwTopHeader.constant = 0
                
                // Get initial products
                self.getInitialProducts()
            case .Featured:
                // Upper 4px padding handling
                self.consTopTopHeader.constant = 4
                
                // Top header setup
                self.consHeightVwTopHeader.constant = 0
                
                // Set color
                if let name = categoryJson?["name"].string where name.lowercaseString == "all" {
                    self.view.backgroundColor = Theme.GrayGranite // Upper 4px padding color
                    self.gridView.backgroundColor = Theme.GrayGranite // Background color
                }
                
                // Get initial products
                self.getInitialProducts()
            case .Segment:
                // Top header setup
                consHeightVwTopHeader.constant = 40
                
                // Show segments
                self.setDefaultTopHeaderWomen()
                
                // Setup grid
                self.setupGrid()
            case .Filter:
                // Upper 4px padding handling
                self.consTopTopHeader.constant = 4
                self.view.backgroundColor = UIColor(hexString: "#E8ECEE")
                
                // Top header setup
                consHeightVwTopHeader.constant = 52
                
                // Setup filter related views
                for i in 0...vwTopHeaderFilter.subviews.count - 1 {
                    vwTopHeaderFilter.subviews[i].createBordersWithColor(UIColor(hexString: "#e3e3e3"), radius: 0, width: 1)
                }
                vwTopHeaderFilter.hidden = false
                vwTopHeader.hidden = true
                if (fltrBrands.count > 0) {
                    if (fltrBrands.count == 1) {
                        lblFilterMerek.text = Array(fltrBrands.keys)[0]
                    } else {
                        lblFilterMerek.text = Array(fltrBrands.keys)[0] + ", \(fltrBrands.count - 1)+"
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
                if (lblFilterSort.text?.lowercaseString == "highest rp") {
                    lblFilterSort.font = UIFont.boldSystemFontOfSize(12)
                } else {
                    lblFilterSort.font = UIFont.boldSystemFontOfSize(13)
                }
                // Search bar setup
                var searchBarWidth = UIScreen.mainScreen().bounds.size.width * 0.8375
                if (AppTools.isIPad) {
                    searchBarWidth = UIScreen.mainScreen().bounds.size.width - 68
                }
                searchBar = UISearchBar(frame: CGRectMake(0, 0, searchBarWidth, 30))
                if let searchField = self.searchBar.valueForKey("searchField") as? UITextField {
                    searchField.backgroundColor = Theme.PrimaryColorDark
                    searchField.textColor = UIColor.whiteColor()
                    let attrPlaceholder = NSAttributedString(string: "Cari di Prelo", attributes: [NSForegroundColorAttributeName : UIColor.lightGrayColor()])
                    searchField.attributedPlaceholder = attrPlaceholder
                    if let icon = searchField.leftView as? UIImageView {
                        icon.image = icon.image?.imageWithRenderingMode(.AlwaysTemplate)
                        icon.tintColor = UIColor.lightGrayColor()
                    }
                    searchField.borderStyle = UITextBorderStyle.None
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
        self.products = []
        self.footerLoading?.hidden = false
        self.setupGrid() // Agar muncul loading
        
        switch (currentMode) {
        case .Shop, .Filter:
            self.done = false
            self.getProducts()
        case .Featured:
            self.getFeaturedProducts()
        case .Segment:
            if (self.listItemSections.contains(.Products)) {
                self.getProducts()
            } else {
                self.refresher?.endRefreshing()
            }
        default:
            requesting = true
            
            var catId : String?
            if (currentMode == .Standalone) {
                catId = standaloneCategoryID
            } else {
                catId = categoryJson!["_id"].string
            }
            
            var lastTimeUuid = ""
            if (products != nil && products?.count > 0) {
                lastTimeUuid = products![products!.count - 1].updateTimeUuid
            }
            request(APISearch.ProductByCategory(categoryId: catId!, sort: "", current: 0, limit: itemsPerReq, priceMin: 0, priceMax: 999999999, segment: selectedSegment, lastTimeUuid: lastTimeUuid)).responseJSON { resp in
                self.done = false
                self.footerLoading?.hidden = false
                self.requesting = false
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Daftar Barang")) {
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
        case .Default:
            if let catId = categoryJson?["_id"].string {
                self.getCategorizedProducts(catId)
            }
        case .Standalone:
            self.getCategorizedProducts(standaloneCategoryID)
        case .Shop:
            self.getShopProducts()
        case .Featured:
            self.getFeaturedProducts()
        case .Segment:
            if (self.listItemSections.contains(.Products)) {
                if let catId = categoryJson?["_id"].string {
                    self.getCategorizedProducts(catId)
                }
            }
        case .Filter:
            self.getFilteredProducts()
        }
    }
    
    func getCategorizedProducts(catId : String) {
        requesting = true
        
        var lastTimeUuid = ""
        if (products != nil && products?.count > 0) {
            lastTimeUuid = products![products!.count - 1].updateTimeUuid
        }
        request(APISearch.ProductByCategory(categoryId: catId, sort: "", current: (products?.count)!, limit: itemsPerReq, priceMin: 0, priceMax: 999999999, segment: selectedSegment, lastTimeUuid: lastTimeUuid)).responseJSON { resp in
            self.requesting = false
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Product By Category")) {
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
        
        request(Products.GetAllFeaturedProducts(categoryId: self.categoryJson!["_id"].stringValue)).responseJSON { resp in
            self.requesting = false
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Featured Products")) {
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
        request(APISearch.ProductByFilter(name: fltrName, categoryId: fltrCategId, brandIds: AppToolsObjC.jsonStringFrom(Array(fltrBrands.values)), productConditionIds: AppToolsObjC.jsonStringFrom(fltrProdCondIds), segment: fltrSegment, priceMin: fltrPriceMin, priceMax: fltrPriceMax, isFreeOngkir: fltrIsFreeOngkir ? "1" : "", sizes: AppToolsObjC.jsonStringFrom(fltrSizes), sortBy: fltrSortBy, current: products!.count, limit: itemsPerReq, lastTimeUuid: lastTimeUuid)).responseJSON { resp in
            if (fltrNameReq == self.fltrName) { // Jika response ini sesuai dengan request terakhir
                self.requesting = false
                if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Filter Product")) {
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
        request(APIPeople.GetShopPage(id: shopId, current: products!.count, limit: itemsPerReq)).responseJSON { resp in
            self.requesting = false
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Data Shop Pengguna")) {
                self.setupData(resp.result.value)
                
                if (self.shopHeader == nil) {
                    self.shopHeader = NSBundle.mainBundle().loadNibNamed("StoreHeader", owner: nil, options: nil).first as? StoreHeader
                    self.gridView.addSubview(self.shopHeader!)
                }
                
                let json = JSON(resp.result.value!)["_data"]
                print(json)
                
                self.shopName = json["username"].stringValue
                self.shopHeader?.captionName.text = self.shopName
                self.title = self.shopName
                let avatarThumbnail = json["profile"]["pict"].stringValue
                self.shopHeader?.avatar.setImageWithUrl(NSURL(string: avatarThumbnail)!, placeHolderImage: nil)
                let avatarFull = avatarThumbnail.stringByReplacingOccurrencesOfString("thumbnails/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
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
                    let formatter = NSDateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    if let lastSeenDate = formatter.dateFromString(lastSeenDateString) {
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
                        let descMutableString : NSMutableAttributedString = NSMutableAttributedString(string: descToWrite, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(14)])
                        descMutableString.addAttribute(NSForegroundColorAttributeName, value: Theme.PrimaryColorDark, range: NSRange(location: descLengthCollapse + 3, length: 12))
                        self.shopHeader?.captionDesc.attributedText = descMutableString
                        descHeight = Int(descMutableString.string.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.width-16).height)
                    } else {
                        self.shopHeader?.captionDesc.text = desc
                        descHeight = Int(desc.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.width-16).height)
                    }
                    height = 338 + descHeight
                } else {
                    self.shopHeader?.captionDesc.text = "Belum ada deskripsi."
                    self.shopHeader?.captionDesc.textColor = UIColor.lightGrayColor()
                    height = 338 + Int("Belum ada deskripsi.".boundsWithFontSize(UIFont.systemFontOfSize(16), width: UIScreen.mainScreen().bounds.width-14).height)
                }
                self.shopHeader?.width = UIScreen.mainScreen().bounds.width
                self.shopHeader?.height = CGFloat(height)
                self.shopHeader?.y = CGFloat(-height)
                
                self.shopHeader?.seeMoreBlock = {
                    if let completeDesc = self.shopHeader?.completeDesc {
                        self.shopHeader?.captionDesc.text = completeDesc
                        let descHeight = completeDesc.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.width-16).height
                        let newHeight : CGFloat = descHeight + 338.0
                        self.shopHeader?.height = newHeight
                        self.shopHeader?.y = -newHeight
                        self.gridView.contentInset = UIEdgeInsetsMake(newHeight, 0, 0, 0)
                        self.gridView.setContentOffset(CGPointMake(0, -newHeight), animated: false)
                        
                        var refresherBound = self.refresher?.bounds
                        if (refresherBound != nil) {
                            refresherBound!.origin.y = CGFloat(newHeight)
                            self.refresher?.bounds = refresherBound!
                        }
                    }
                }
                
                self.shopHeader?.avatar.superview?.layer.cornerRadius = (self.shopHeader?.avatar.width)!/2
                self.shopHeader?.avatar.superview?.layer.masksToBounds = true
                
                self.shopHeader?.btnEdit.hidden = true
                if let id = json["_id"].string, let me = CDUser.getOne()
                {
                    if (id == me.id)
                    {
                        self.shopHeader?.btnEdit.hidden = false
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
                    let userProfileVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil).first as! UserProfileViewController
                    self.navigationController?.pushViewController(userProfileVC, animated: true)
                }
                
                self.shopHeader?.reviewBlock = {
                    let shopReviewVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameShopReview, owner: nil, options: nil).first as! ShopReviewViewController
                    shopReviewVC.sellerId = self.shopId
                    shopReviewVC.sellerName = self.shopName
                    self.navigationController?.pushViewController(shopReviewVC, animated: true)
                }
                
                self.shopHeader?.zoomAvatarBlock = {
                    let c = CoverZoomController()
                    c.labels = [json["username"].stringValue]
                    c.images = (self.shopHeader?.avatarUrls)!
                    c.index = 0
                    self.navigationController?.presentViewController(c, animated: true, completion: nil)
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
    
    func setupData(res : AnyObject?) {
        guard res != nil else {
            return
        }
        var obj = JSON(res!)
        if let arr = obj["_data"].array {
            if arr.count == 0 {
                self.done = true
                self.footerLoading?.hidden = true
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
                self.footerLoading?.hidden = true
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
        
        if let x = self.products?.count where x < itemsPerReq {
            self.done = true
            self.footerLoading?.hidden = true
        }
    }
    
    func setupGrid() {
        if (currentMode == .Filter && products?.count <= 0 && !requesting) {
            gridView.hidden = true
            vwFilterZeroResult.hidden = false
            if (fltrName != "") {
                lblFilterZeroResult.text = "Tidak ada hasil yang ditemukan untuk '\(fltrName)'"
                btnFilterZeroResult.hidden = false
            } else {
                lblFilterZeroResult.text = "Tidak ada hasil yang ditemukan"
                btnFilterZeroResult.hidden = true
            }
            return
        }
        
        if (gridView.dataSource == nil || gridView.delegate == nil) {
            gridView.dataSource = self
            gridView.delegate = self
        }
        
        if (!(currentMode == .Segment && listItemSections.contains(.Segments))) {
            if (listStage == 1) {
                itemCellWidth = ((UIScreen.mainScreen().bounds.size.width - 16) / 3)
            } else if (listStage == 2) {
                itemCellWidth = ((UIScreen.mainScreen().bounds.size.width - 12) / 2)
            } else if (listStage == 3) {
                itemCellWidth = ((UIScreen.mainScreen().bounds.size.width - 8) / 1)
            }
        }
        
        gridView.reloadData()
        gridView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0)
        gridView.hidden = false
        vwFilterZeroResult.hidden = true
    }
    
    // MARK: - Collection view functions
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return listItemSections.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch listItemSections[section] {
        case .Carousel:
            return 1
        case .FeaturedHeader:
            return 1
        case .Subcategories:
            return self.subcategoryItems.count
        case .Segments:
            return self.segments.count
        case .Products:
            if let p = products {
                return p.count
            }
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        switch listItemSections[indexPath.section] {
        case .Carousel:
            let cell : ListItemCarouselCell = collectionView.dequeueReusableCellWithReuseIdentifier("carousel_cell", forIndexPath: indexPath) as! ListItemCarouselCell
            cell.adapt(carouselItems)
            if (!isCarouselTimerSet) {
                cell.setCarouselTimer()
                isCarouselTimerSet = true
            }
            return cell
        case .FeaturedHeader:
            let cell : ListItemFeaturedHeaderCell = collectionView.dequeueReusableCellWithReuseIdentifier("featured_cell", forIndexPath: indexPath) as! ListItemFeaturedHeaderCell
            if let name = categoryJson?["name"].string {
                cell.adapt(name)
            }
            return cell
        case .Subcategories:
            let cell : ListItemSubcategoryCell = collectionView.dequeueReusableCellWithReuseIdentifier("subcategory_cell", forIndexPath: indexPath) as! ListItemSubcategoryCell
            cell.imgSubcategory.image = subcategoryItems[indexPath.item].image
            cell.lblSubcategory.hidden = true // Unused label
            return cell
        case .Segments:
            let cell : ListItemSegmentCell = collectionView.dequeueReusableCellWithReuseIdentifier("segment_cell", forIndexPath: indexPath) as! ListItemSegmentCell
            cell.imgSegment.image = segments[indexPath.item].image
            return cell
        case .Products:
            // Load next products here
            if (currentMode == .Default || currentMode == .Standalone || currentMode == .Shop || currentMode == .Filter || (currentMode == .Segment && listItemSections.contains(.Products))) {
                if (indexPath.row == (products?.count)! - 4 && requesting == false && done == false) {
                    getProducts()
                }
            }
            
            let cell : ListItemCell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ListItemCell
            let p = products?[indexPath.item]
            cell.adapt(p!)
            if (currentMode == .Featured) {
                // Hide featured ribbon
                cell.imgFeatured.hidden = true
            }
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let viewWidthMinusMargin = UIScreen.mainScreen().bounds.size.width - 8
        switch listItemSections[indexPath.section] {
        case .Carousel:
            var maxHeight : CGFloat = 0
            for i in 0..<self.carouselItems.count {
                let height = ((viewWidthMinusMargin / carouselItems[i].img.size.width) * carouselItems[i].img.size.height)
                if (height > maxHeight) {
                    maxHeight = height
                }
            }
            return CGSize(width: viewWidthMinusMargin, height: maxHeight)
        case .FeaturedHeader:
            return CGSize(width: viewWidthMinusMargin, height: 56)
        case .Subcategories:
            return CGSize(width: viewWidthMinusMargin / 3, height: viewWidthMinusMargin / 3)
        case .Segments:
            let segHeight = viewWidthMinusMargin * segments[indexPath.item].image.size.height / segments[indexPath.item].image.size.width
            return CGSize(width: viewWidthMinusMargin, height: segHeight)
        case .Products:
            return CGSize(width: itemCellWidth!, height: itemCellWidth! + 46)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        switch listItemSections[section] {
        case .Subcategories:
            return 0
        default:
            return 4
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        if (currentMode == .Featured) {
            if (section == 0) {
                return UIEdgeInsetsMake(0, 4, 0, 4)
            }
        }
        if (listItemSections[section] == .Products) {
            if (currentMode == .Filter) {
                return UIEdgeInsetsMake(0, 4, 0, 4)
            }
        }
        return UIEdgeInsetsMake(4, 4, 0, 4)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        switch listItemSections[indexPath.section] {
        case .Carousel:
            break
        case .FeaturedHeader:
            break
        case .Subcategories:
            NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
            
            let p = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
            p.currentMode = .Filter
            p.fltrCategId = subcategoryItems[indexPath.item].id
            p.fltrSortBy = "recent"
            self.navigationController?.pushViewController(p, animated: true)
        case .Segments:
            self.selectedSegment = self.segments[indexPath.item].type
            var txt = " Kamu sedang melihat \(self.segments[indexPath.item].name)"
            if (self.segments[indexPath.item].name.length > 23) {
                txt = txt.stringByReplacingOccurrencesOfString("sedang ", withString: "")
            }
            let attTxt = NSMutableAttributedString(string: txt)
            attTxt.addAttributes([NSFontAttributeName : AppFont.Prelo2.getFont(11)!], range: NSRange.init(location: 0, length: 1))
            attTxt.addAttributes([NSFontAttributeName : UIFont.systemFontOfSize(12)], range: NSRange.init(location: 1, length: txt.length - 1))
            self.lblTopHeader.attributedText = attTxt
            self.listItemSections.removeAtIndex(self.listItemSections.indexOf(.Segments)!)
            self.listItemSections.append(.Products)
            self.refresh()
        case .Products:
            self.selectedProduct = products?[indexPath.item]
            if (currentMode == .Featured) {
                selectedProduct?.setToFeatured()
            }
            self.launchDetail()
        }
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if (kind == UICollectionElementKindSectionHeader) { // Header
            // No header
        } else if (kind == UICollectionElementKindSectionFooter) { // Footer
            let f = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "footer", forIndexPath: indexPath) as! ListFooter
            
            // Default value
            f.btnFooter.hidden = true
            f.lblFooter.hidden = true
            f.loading.hidden = false
            
            // Loading handle
            self.footerLoading = f.loading
            if (self.done) {
                self.footerLoading?.hidden = true
            }
            
            // Adapt
            if (currentMode == .Featured && products?.count > 0) { // 'Lihat semua barang' button, only show if featured products is loaded
                f.btnFooter.hidden = false
                f.btnFooterAction = {
                    NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
                    
                    let p = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                    p.currentMode = .Filter
                    p.fltrCategId = self.categoryJson!["_id"].stringValue
                    p.fltrSortBy = "recent"
                    self.navigationController?.pushViewController(p, animated: true)
                }
            } else { // Default loading footer
                f.btnFooter.hidden = true
            }
            
            return f
        }
        return UICollectionReusableView()
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSizeZero // No header
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if (listItemSections[section] == .Products) {
            if (currentMode == .Featured) {
                return CGSizeMake(collectionView.width, 66)
            }
            return CGSizeMake(collectionView.width, 50)
        }
        return CGSizeZero
    }
    
    // MARK: - Scrollview functions
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        currScrollPoint = scrollView.contentOffset
        draggingScrollView = true
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        draggingScrollView = false
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (draggingScrollView) {
            if (currentMode == .Default || currentMode == .Featured || currentMode == .Filter || (currentMode == .Segment && listItemSections.contains(.Products))) {
                if (currScrollPoint.y < scrollView.contentOffset.y) {
                    if ((self.navigationController?.navigationBarHidden)! == false) {
                        NSNotificationCenter.defaultCenter().postNotificationName("hideBottomBar", object: nil)
                        self.navigationController?.setNavigationBarHidden(true, animated: true)
                        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
                        if (selectedSegment != "") {
                            consHeightVwTopHeader.constant = 0 // Hide top header
                            UIView.animateWithDuration(0.2) {
                                self.view.layoutIfNeeded()
                            }
                        }
                    }
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
                    if (selectedSegment != "") {
                        consHeightVwTopHeader.constant = 40 // Show top header
                        UIView.animateWithDuration(0.2) {
                            self.view.layoutIfNeeded()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Search bar functions
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.fltrName = searchText
        self.done = false
        self.footerLoading?.hidden = false
        self.products = []
        self.getProducts()
        self.setupGrid()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if let searchField = searchBar.valueForKey("searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.imageWithRenderingMode(.AlwaysTemplate)
                icon.tintColor = UIColor.whiteColor()
            }
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        if let searchField = searchBar.valueForKey("searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.imageWithRenderingMode(.AlwaysTemplate)
                icon.tintColor = UIColor.lightGrayColor()
            }
        }
    }
    
    // MARK: - Filter delegate function
    
    func adjustFilter(fltrProdCondIds: [String], fltrPriceMin: NSNumber, fltrPriceMax: NSNumber, fltrIsFreeOngkir: Bool, fltrSizes: [String], fltrSortBy: String) {
        self.fltrProdCondIds = fltrProdCondIds
        self.fltrPriceMin = fltrPriceMin
        self.fltrPriceMax = fltrPriceMax
        self.fltrIsFreeOngkir = fltrIsFreeOngkir
        self.fltrSizes = fltrSizes
        self.fltrSortBy = fltrSortBy
        lblFilterSort.text = self.FltrValSortBy[self.fltrSortBy]
        if (lblFilterSort.text?.lowercaseString == "highest rp") {
            lblFilterSort.font = UIFont.boldSystemFontOfSize(12)
        } else {
            lblFilterSort.font = UIFont.boldSystemFontOfSize(13)
        }
        self.refresh()
        self.setupGrid()
    }
    
    // MARK: - Category picker delegate function
    
    func adjustCategory(categId: String) {
        self.fltrCategId = categId
        lblFilterKategori.text = CDCategory.getCategoryNameWithID(categId)
        self.refresh()
        self.setupGrid()
    }
    
    // MARK: - List brand delegate function
    
    func adjustBrand(fltrBrands: [String : String]) {
        self.fltrBrands = fltrBrands
        if (fltrBrands.count > 0) {
            if (fltrBrands.count == 1) {
                lblFilterMerek.text = Array(fltrBrands.keys)[0]
            } else {
                lblFilterMerek.text = Array(fltrBrands.keys)[0] + ", \(fltrBrands.count - 1)+"
            }
        }
        self.refresh()
        self.setupGrid()
    }
    
    // MARK: - TopHeader
    
    func setDefaultTopHeaderWomen() {
        lblTopHeader.text = "Barang apa yang ingin kamu lihat hari ini?"
        lblTopHeader.font = UIFont.systemFontOfSize(12)
    }
    
    @IBAction func topHeaderPressed(sender: AnyObject) {
        if (!listItemSections.contains(.Segments)) {
            setDefaultTopHeaderWomen()
            selectedSegment = ""
            self.listItemSections.removeAtIndex(self.listItemSections.indexOf(.Products)!)
            self.listItemSections.append(.Segments)
            gridView.reloadData()
        }
    }
    
    @IBAction func topHeaderFilterMerekPressed(sender: AnyObject) {
        let listBrandVC = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdListBrand) as! ListBrandViewController2
        listBrandVC.previousController = self
        listBrandVC.delegate = self
        listBrandVC.selectedBrands = self.fltrBrands
        listBrandVC.sortedBrandKeys = Array(self.fltrBrands.keys)
        self.navigationController?.pushViewController(listBrandVC, animated: true)
    }
    
    @IBAction func topHeaderFilterKategoriPressed(sender: AnyObject) {
        let categPickerVC = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdCategoryPicker) as! CategoryPickerViewController
        categPickerVC.previousController = self
        categPickerVC.delegate = self
        categPickerVC.searchMode = true
        self.navigationController?.pushViewController(categPickerVC, animated: true)
    }
    
    @IBAction func topHeaderFilterSortPressed(sender: AnyObject) {
        let filterVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameFilter, owner: nil, options: nil).first as! FilterViewController
        filterVC.previousController = self
        filterVC.delegate = self
        filterVC.categoryId = self.fltrCategId
        filterVC.initSelectedProdCondId = self.fltrProdCondIds
        filterVC.initSelectedCategSizeVal = self.fltrSizes
        filterVC.selectedIdxSortBy = filterVC.SortByDataValue.indexOf(self.fltrSortBy)!
        filterVC.isFreeOngkir = self.fltrIsFreeOngkir
        filterVC.minPrice = (self.fltrPriceMin > 0) ? self.fltrPriceMin.stringValue : ""
        filterVC.maxPrice = (self.fltrPriceMax > 0) ? self.fltrPriceMax.stringValue : ""
        self.navigationController?.pushViewController(filterVC, animated: true)
    }
    
    // MARK: - Filter zero result
    
    @IBAction func reqBarangPressed(sender: AnyObject) {
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
            self.presentViewController(m, animated: true, completion: nil)
        } else {
            Constant.showDialog("No Active E-mail", message: "Untuk dapat mengirim Request Barang, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
        }
    }
    
    // MARK: - Mail compose delegate functions
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        if (result == MFMailComposeResultSent) {
            Constant.showDialog("Request Barang", message: "E-mail terkirim")
        } else if (result == MFMailComposeResultFailed) {
            Constant.showDialog("Request Barang", message: "E-mail gagal dikirim")
        }
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let c = segue.destinationViewController
        if (c.isKindOfClass(BaseViewController.classForCoder())) {
            let b = c as! BaseViewController
            b.previousController = self
        }
    }
    
    func launchDetail() {
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationName.ShowProduct, object: self.selectedProduct)
    }
    
    // MARK: - Other functions
    
    func statusBarTapped() {
        gridView.setContentOffset(CGPointMake(0, 10), animated: true)
        NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func pinch(pinchedIn : Bool) {
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
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .CurveEaseOut, animations: {
            self.gridView.reloadData()
        }, completion: nil)
    }
}

// MARK: - Class

class CarouselItem {
    var name : String = ""
    var img : UIImage = UIImage()
    var link : NSURL = NSURL()
    
    init(name : String, img : UIImage, link : NSURL) {
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
    
    func adapt(carouselItems : [CarouselItem]) {
        self.carouselItems = carouselItems
        scrlVwCarousel.delegate = self
        
        self.pageCtrlCarousel.numberOfPages = carouselItems.count
        self.pageCtrlCarousel.currentPage = 0
        var rectHeightFix : CGFloat = 0
        let rectWidthFix : CGFloat = UIScreen.mainScreen().bounds.size.width - 8
        self.consWidthContentVwCarousel.constant = rectWidthFix * CGFloat(carouselItems.count)
        for i in 0..<carouselItems.count {
            let height = ((rectWidthFix / carouselItems[i].img.size.width) * carouselItems[i].img.size.height)
            if (height > rectHeightFix) {
                rectHeightFix = height
            }
        }
        for i in 0...carouselItems.count - 1 {
            let rect = CGRectMake(CGFloat(i * Int(rectWidthFix)), 0, rectWidthFix, rectHeightFix)
            let uiImg = UIImageView(frame: rect, image: carouselItems[i].img)
            let uiBtn = UIButton(frame: rect)
            uiBtn.addTarget(self, action: #selector(ListItemCarouselCell.btnCarouselPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            uiBtn.tag = i
            contentVwCarousel.addSubview(uiImg)
            contentVwCarousel.addSubview(uiBtn)
        }
    }
    
    func setCarouselTimer() {
        // Scroll timer
        NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(ListItemCarouselCell.autoScrollCarousel), userInfo: nil, repeats: true)
    }
    
    func btnCarouselPressed(sender: UIButton) {
        let tag = sender.tag
        UIApplication.sharedApplication().openURL(self.carouselItems[tag].link)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        pageCtrlCarousel.currentPage = Int(scrlVwCarousel.contentOffset.x / scrlVwCarousel.width)
    }
    
    func autoScrollCarousel() {
        var nextPage = Int(scrlVwCarousel.contentOffset.x / scrlVwCarousel.width) + 1
        if (nextPage > carouselItems.count - 1) {
            nextPage = 0
        }
        scrlVwCarousel.setContentOffset(CGPointMake(CGFloat(nextPage) * scrlVwCarousel.width, 0), animated: true)
        pageCtrlCarousel.currentPage = nextPage
    }
}

// MARK: - Class

class ListItemFeaturedHeaderCell : UICollectionViewCell {
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDesc: UILabel!
    
    func adapt(categName : String) {
        let edPickCategName = ["all", "home", "semua"]
        if (edPickCategName.contains(categName.lowercaseString)) {
            self.lblTitle.text = "EDITOR'S PICK"
            self.lblTitle.textColor = UIColor.whiteColor()
            self.lblDesc.text = "Daftar barang terbaik yang dipilih oleh tim Prelo"
            self.lblDesc.textColor = UIColor.whiteColor()
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
        
        sectionLove.layer.cornerRadius = sectionLove.frame.size.width/2
        sectionLove.layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        imgSold.hidden = true
        imgReserved.hidden = true
        imgFeatured.hidden = true
        imgFreeOngkir.hidden = true
    }
    
    func adapt(product : Product) {
        let obj = product.json
        captionTitle.text = product.name
        captionPrice.text = product.price
        let loveCount = obj["love"].int
        captionLove.text = String(loveCount == nil ? 0 : loveCount!)
        let commentCount = obj["discussions"].int
        captionComment.text = String(commentCount == nil ? 0 : commentCount!)
        
        avatar.contentMode = .ScaleAspectFill
        avatar.layer.cornerRadius = avatar.bounds.width / 2
        avatar.layer.masksToBounds = true
        
        if (product.specialStory == nil || product.specialStory == "") {
            sectionSpecialStory.hidden = true
        } else {
            sectionSpecialStory.hidden = false
            captionSpecialStory.text = "\"\(product.specialStory!)\""
            if let url = product.avatar {
                avatar.setImageWithUrl(url, placeHolderImage: UIImage(named : "raisa.jpg"))
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
        ivCover.setImageWithUrl(product.coverImageURL!, placeHolderImage: nil)
        
        if let op = product.json["price_original"].int {
            captionOldPrice.text = op.asPrice
            let s = captionOldPrice.text! as NSString
            let attString = NSMutableAttributedString(string: s as String)
            attString.addAttributes([NSStrikethroughStyleAttributeName:NSUnderlineStyle.StyleSingle.rawValue], range: s.rangeOfString(s as String))
            captionOldPrice.attributedText = attString
        }
        
        if let status = product.status {
            if (status == 4 || status == 8) { // sold
                self.imgSold.hidden = false
            } else if (status == 7) { // reserved
                self.imgReserved.hidden = false
            } else if (product.isFeatured) { // featured
                self.imgFeatured.hidden = false
            }
        }
        
        if product.isFreeOngkir {
            imgFreeOngkir.hidden = false
        }
    }
}

// MARK: - Class

class ListFooter : UICollectionReusableView {
    @IBOutlet var loading : UIActivityIndicatorView!
    @IBOutlet var btnFooter: UIButton!
    @IBOutlet var lblFooter: UILabel!
    
    var btnFooterAction : () -> () = {}
    
    @IBAction func btnFooterPressed(sender: AnyObject) {
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
    
    @IBAction func gotoShopReview(sender: AnyObject) {
        self.reviewBlock()
    }
    
    @IBAction func avatarPressed(sender: AnyObject) {
        self.zoomAvatarBlock()
    }
    
    @IBAction func seeMore(sender: AnyObject) {
        if (self.completeDesc != "" && self.captionDesc.text != self.completeDesc) {
            self.seeMoreBlock()
        }
    }
}
