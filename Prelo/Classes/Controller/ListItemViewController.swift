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
    var itemsPerReq = 12 // Amount of items per request
    
    // Store header
    var storeHeader : StoreHeader?
    
    // Data container
    var categoryJson : JSON? // Set from previous screen
    var products : Array <Product>? // From API response
    var selectedProduct : Product? // For navigating to product detail
    
    // Flags
    var requesting : Bool = false
    var done : Bool = false
    var draggingScrollView : Bool = false
    var isContentLoaded : Bool = false
    
    // For standalone mode, used for category-filtered product list
    var standaloneMode : Bool = false
    var standaloneCategoryName : String = ""
    var standaloneCategoryID : String = ""
    
    // For search result mode
    var searchMode = false
    var searchKey = ""
    var searchBrand = false
    var searchBrandId = ""
    
    // For shop page mode
    var storeMode = false
    var storeId = ""
    var storeName = ""
    var storePictPath = ""
    
    // For segment mode
    var segmentMode : Bool = false // Bernilai true jika sedang menampilkan pilihan segment
    var segments : [SegmentItem] = []
    var selectedSegment : String = ""
    
    // For featured products mode
    var featuredProductsMode : Bool = false
    var carouselItems : [CarouselItem] = []
    var isCarouselTimerSet : Bool = false
    
    // For subcategory mode
    var subcategoryMode : Bool = false
    var subcategoryItems : [SubcategoryItem] = []
    
    // For filter/search result mode
    // Predefined values
    var filterMode = false
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
    @IBOutlet var lblFilterZeroResult: UILabel!
    // Others
    var fltrName : String = ""
    let FltrValSortBy : [String : String] = ["recent" : "Recent", "lowest_price" : "Lowest Rp", "highest_price" : "Highest Rp", "popular" : "Popular"]
    
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
        if (standaloneMode) {
            self.titleText = standaloneCategoryName
        } else if (searchMode) {
            if (searchBrand) {
                self.title = searchKey
            } else {
                self.title = "\"" + searchKey + "\""
            }
        } else if (storeMode) {
            self.title = storeName
        } else {
            if let name = categoryJson?["name"].string {
                self.title = name
            }
        }
        
        // Hide top header first
        self.consHeightVwTopHeader.constant = 0
        
        // Send top search API for searchMode
        if (searchMode) {
            request(APISearch.InsertTopSearch(search: searchKey)).responseJSON{resp in
                if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Insert Top Search")) {
                    
                }
            }
        }
        
        // Initiate refresh control
        refresher = UIRefreshControl()
        refresher!.tintColor = Theme.PrimaryColor
        refresher!.addTarget(self, action: #selector(ListItemViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
        self.gridView.addSubview(refresher!)
        
        // Setup content
        if (filterMode || storeMode || standaloneMode) {
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
        if (filterMode) {
            self.searchBar.text = self.fltrName
        }
        
        // Mixpanel for store mode
        if (storeMode) {
            if (User.IsLoggedIn && self.storeId == User.Id!) {
                // Mixpanel
                Mixpanel.trackPageVisit(PageName.ShopMine)
                
                // Google Analytics
                GAI.trackPageVisit(PageName.ShopMine)
            } else {
                // Mixpanel
                let p = [
                    "Seller" : storeName,
                    "Seller ID" : self.storeId
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
            
            // Identify current mode and set content based on the mode
            if (filterMode) {
                // Setup filter related views
                for i in 0...vwTopHeaderFilter.subviews.count - 1 {
                    vwTopHeaderFilter.subviews[i].createBordersWithColor(UIColor.lightGrayColor(), radius: 0, width: 1)
                }
                vwTopHeaderFilter.hidden = false
                vwTopHeader.hidden = true
                consHeightVwTopHeader.constant = 52
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
                if (products?.count == 0 || products == nil) {
                    if (products == nil) {
                        products = []
                    }
                    getProducts()
                }
                
            } else if (self.categoryJson?["name"].stringValue == "Women") { // Special case for 'Women' category
                consHeightVwTopHeader.constant = 40
                self.setDefaultTopHeaderWomen()
                segmentMode = true
                if let segmentsJson = self.categoryJson?["segments"].array where segmentsJson.count > 0 {
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
                }
                gridView.dataSource = self
                gridView.delegate = self
                gridView.reloadData()
            } else if (self.categoryJson?["name"].stringValue == "All" && self.categoryJson?["is_featured"].boolValue == true) { // Special case for 'Featured' category
                self.featuredProductsMode = true
                consHeightVwTopHeader.constant = 0
                self.gridView.backgroundColor = Theme.GrayGranite
                
                // Get featured products
                getFeaturedProducts()
            } else if (self.categoryJson?["name"].stringValue == "Book") { // Special case for 'Book' category
                self.subcategoryMode = true
                
                if let subcatJson = self.categoryJson?["sub_categories"].array where subcatJson.count > 0 {
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
                }
                
                consHeightVwTopHeader.constant = 0
                
                // Get initial products
                if (products?.count == 0 || products == nil) {
                    if (products == nil) {
                        products = []
                    }
                    getProducts()
                }
            } else {
                consHeightVwTopHeader.constant = 0
                
                // Get initial products
                if (products?.count == 0 || products == nil) {
                    if (products == nil) {
                        products = []
                    }
                    getProducts()
                }
            }
            
            // Upper 4px padding handler
            if (self.featuredProductsMode) {
                self.consTopTopHeader.constant = 4
                self.view.backgroundColor = Theme.GrayGranite
            } else if (self.searchMode) {
                self.consTopTopHeader.constant = 4
                self.view.backgroundColor = UIColor(hexString: "#E8ECEE")
            } else if (self.filterMode) {
                self.consTopTopHeader.constant = 4
                self.view.backgroundColor = UIColor(hexString: "#E8ECEE")
            } else if (self.storeMode || self.standaloneMode) {
                self.consTopTopHeader.constant = 0
            }
        }
    }
    
    func refresh() {
        if (searchMode || segmentMode) {
            // No refresh
            self.refresher?.endRefreshing()
        } else if (filterMode || storeMode) {
            self.done = false
            self.footerLoading?.hidden = false
            self.products = []
            self.getProducts()
        } else if (featuredProductsMode) {
            self.getFeaturedProducts()
        } else {
            requesting = true
            
            var catId : String?
            if (standaloneMode) {
                catId = standaloneCategoryID
            } else {
                catId = categoryJson!["_id"].string
            }
            
            // API Migrasi
            request(APISearch.ProductByCategory(categoryId: catId!, sort: "", current: 0, limit: itemsPerReq, priceMin: 0, priceMax: 999999999, segment: selectedSegment)).responseJSON {resp in
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
        if (categoryJson == nil && !(standaloneMode || searchMode || storeMode || filterMode)) {
            return
        }
        
        if (filterMode) {
            self.getFilteredProducts()
        } else if (searchMode) {
            self.getSearchProduct()
        } else if (storeMode) {
            self.getStoreProduct()
        } else {
            requesting = true
            
            var catId : String?
            if (standaloneMode) {
                catId = standaloneCategoryID
            } else {
                //print(categoryJson)
                catId = categoryJson!["_id"].string
            }
            
            // API Migrasi
            request(APISearch.ProductByCategory(categoryId: catId!, sort: "", current: (products?.count)!, limit: itemsPerReq, priceMin: 0, priceMax: 999999999, segment: selectedSegment)).responseJSON { resp in
                self.requesting = false
                if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Product By Category")) {
                    self.setupData(resp.result.value)
                }
                self.setupGrid()
            }
        }
    }
    
    func getFeaturedProducts() {
        requesting = true
        
        // API Migrasi
        request(Products.GetAllFeaturedProducts()).responseJSON { resp in
            self.requesting = false
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Featured Products")) {
                self.products = []
                
                self.setupData(resp.result.value)
                
                // Init carousel data
                var res = JSON(resp.result.value!)
                self.carouselItems = []
                if let carouselData = res["_data"]["carousel"].array {
                    for i in 0...carouselData.count - 1 {
                        var img = UIImage()
                        var link = NSURL()
                        if let url = NSURL(string: carouselData[i]["image"].stringValue), let data = NSData(contentsOfURL: url), let uiimg = UIImage(data: data) {
                            img = uiimg
                        }
                        if let url = NSURL(string: carouselData[i]["link"].stringValue) {
                            link = url
                        }
                        let item = CarouselItem.init(name: carouselData[i]["name"].stringValue, img: img, link: link)
                        self.carouselItems.append(item)
                    }
                }
            }
            self.refresher?.endRefreshing()
            self.setupGrid()
        }
    }
    
    func getFilteredProducts() {
        requesting = true
        var fltrNameReq = self.fltrName
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
    
    func getSearchProduct() {
        requesting = true
        
        // API Migrasi
        request(APISearch.Find(keyword: (searchBrand == true) ? (searchBrandId == "" ? searchKey : "") : searchKey, categoryId: "", brandId: (searchBrand == true) ? searchBrandId : "", condition: "", current: (products?.count)!, limit: itemsPerReq, priceMin: 0, priceMax: 999999999)).responseJSON {resp in
            self.requesting = false
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Search Product")) {
                self.setupData(resp.result.value)
            }
            self.setupGrid()
        }
    }
    
    func getStoreProduct() {
        self.requesting = true
        
        // API Migrasi
        request(APIPeople.GetShopPage(id: storeId)).responseJSON { resp in
            self.requesting = false
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Data Shop Pengguna")) {
                self.setupData(resp.result.value)
                
                if (self.storeHeader == nil) {
                    self.storeHeader = NSBundle.mainBundle().loadNibNamed("StoreHeader", owner: nil, options: nil).first as? StoreHeader
                    self.gridView.addSubview(self.storeHeader!)
                }
                
                let json = JSON(resp.result.value!)["_data"]
                print(json)
                
                self.storeName = json["username"].stringValue
                self.storeHeader?.captionName.text = self.storeName
                self.title = self.storeName
                let avatarThumbnail = json["profile"]["pict"].stringValue
                self.storeHeader?.avatar.setImageWithUrl(NSURL(string: avatarThumbnail)!, placeHolderImage: nil)
                let avatarFull = avatarThumbnail.stringByReplacingOccurrencesOfString("thumbnails/", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                self.storeHeader?.avatarUrls.append(avatarFull)
                
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
                self.storeHeader?.captionLove.attributedText = attrStringLove
                
                // Reviewer count
                let numReview = json["num_reviewer"].intValue
                self.storeHeader?.captionReview.text = "(\(numReview) Review)"
                
                // Last seen
                if let lastSeenDateString = json["others"]["last_seen"].string {
                    let formatter = NSDateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    if let lastSeenDate = formatter.dateFromString(lastSeenDateString) {
                        self.storeHeader?.captionLastActive.text = lastSeenDate.relativeDescription
                    }
                }
                
                // Chat percentage
                if let chatPercentage = json["others"]["replied_chat_percentage"].int {
                    self.storeHeader?.captionChatPercentage.text = "\(chatPercentage)%"
                }
                
                var height = 0
                
                if let desc = json["profile"]["description"].string
                {
                    self.storeHeader?.completeDesc = desc
                    let descLengthCollapse = 160
                    var descHeight : Int = 0
                    //let oneLineHeight = Int("lol".boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.width-16).height)
                    if (desc.length > descLengthCollapse) { // Jika lebih dari 160 karakter, buat menjadi collapse text
                        // Ambil 160 karakter pertama, beri ellipsis, tambah tulisan 'Selengkapnya'
                        let descToWrite = desc.substringToIndex(descLengthCollapse - 1) + "... Selengkapnya"
                        let descMutableString : NSMutableAttributedString = NSMutableAttributedString(string: descToWrite, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(14)])
                        descMutableString.addAttribute(NSForegroundColorAttributeName, value: Theme.PrimaryColorDark, range: NSRange(location: descLengthCollapse + 3, length: 12))
                        self.storeHeader?.captionDesc.attributedText = descMutableString
                        descHeight = Int(descMutableString.string.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.width-16).height)
                    } else {
                        self.storeHeader?.captionDesc.text = desc
                        descHeight = Int(desc.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.width-16).height)
                    }
                    height = 338 + descHeight
                } else {
                    self.storeHeader?.captionDesc.text = "Belum ada deskripsi."
                    self.storeHeader?.captionDesc.textColor = UIColor.lightGrayColor()
                    height = 338 + Int("Belum ada deskripsi.".boundsWithFontSize(UIFont.systemFontOfSize(16), width: UIScreen.mainScreen().bounds.width-14).height)
                }
                self.storeHeader?.width = UIScreen.mainScreen().bounds.width
                self.storeHeader?.height = CGFloat(height)
                self.storeHeader?.y = CGFloat(-height)
                
                self.storeHeader?.seeMoreBlock = {
                    if let completeDesc = self.storeHeader?.completeDesc {
                        self.storeHeader?.captionDesc.text = completeDesc
                        let descHeight = completeDesc.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.width-16).height
                        let newHeight : CGFloat = descHeight + 338.0
                        self.storeHeader?.height = newHeight
                        self.storeHeader?.y = -newHeight
                        self.gridView.contentInset = UIEdgeInsetsMake(newHeight, 0, 0, 0)
                        self.gridView.setContentOffset(CGPointMake(0, -newHeight), animated: false)
                        
                        var refresherBound = self.refresher?.bounds
                        if (refresherBound != nil) {
                            refresherBound!.origin.y = CGFloat(newHeight)
                            self.refresher?.bounds = refresherBound!
                        }
                    }
                }
                
                self.storeHeader?.avatar.superview?.layer.cornerRadius = (self.storeHeader?.avatar.width)!/2
                self.storeHeader?.avatar.superview?.layer.masksToBounds = true
                
                self.storeHeader?.btnEdit.hidden = true
                if let id = json["_id"].string, let me = CDUser.getOne()
                {
                    if (id == me.id)
                    {
                        self.storeHeader?.btnEdit.hidden = false
                    }
                }
                
                // Total products and sold products
                if let productCount = json["total_product"].int {
                    if let soldProductCount = json["total_product_sold"].int {
                        self.storeHeader?.captionTotal.text = "\(productCount) BARANG, \(soldProductCount) TERJUAL"
                    } else {
                        self.storeHeader?.captionTotal.text = "\(productCount) BARANG"
                    }
                } else {
                    if let count = self.products?.count {
                        self.storeHeader?.captionTotal.text = String(count) + " BARANG"
                    }
                }
                
                self.storeHeader?.captionLocation.text = "Unknown"
                
                if let regionId = json["profile"]["region_id"].string, let province_id = json["profile"]["province_id"].string
                {
                    // yang ini go, region sama province nya null.
                    if let region = CDRegion.getRegionNameWithID(regionId), let province = CDProvince.getProvinceNameWithID(province_id)
                    {
                        self.storeHeader?.captionLocation.text = region + ", " + province
                    }
                }
                
                self.storeHeader?.editBlock = {
                    let userProfileVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil).first as! UserProfileViewController
                    self.navigationController?.pushViewController(userProfileVC, animated: true)
                }
                
                self.storeHeader?.reviewBlock = {
                    let shopReviewVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameShopReview, owner: nil, options: nil).first as! ShopReviewViewController
                    shopReviewVC.sellerId = self.storeId
                    shopReviewVC.sellerName = self.storeName
                    self.navigationController?.pushViewController(shopReviewVC, animated: true)
                }
                
                self.storeHeader?.zoomAvatarBlock = {
                    let c = CoverZoomController()
                    c.labels = [json["username"].stringValue]
                    c.images = (self.storeHeader?.avatarUrls)!
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
        
        if (storeMode) {
            self.done = true
            self.footerLoading?.hidden = true
        }
    }
    
    func setupGrid() {
        if (filterMode && products?.count <= 0 && !requesting && fltrName != "") {
            gridView.hidden = true
            vwFilterZeroResult.hidden = false
            lblFilterZeroResult.text = "Tidak ada hasil yang ditemukan untuk '\(fltrName)'"
            return
        }
        
        if (gridView.dataSource == nil || gridView.delegate == nil) {
            gridView.dataSource = self
            gridView.delegate = self
        }
        
        if (listStage == 1) {
            itemCellWidth = ((UIScreen.mainScreen().bounds.size.width - 12) / 3)
        } else if (listStage == 2) {
            itemCellWidth = ((UIScreen.mainScreen().bounds.size.width - 12) / 2)
        } else if (listStage == 3) {
            itemCellWidth = ((UIScreen.mainScreen().bounds.size.width - 16) / 1)
        }
        
        gridView.reloadData()
        gridView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0)
        gridView.hidden = false
        vwFilterZeroResult.hidden = true
    }
    
    // MARK: - Collection view functions
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if (subcategoryMode) {
            return 2
        } else {
            return 1
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (segmentMode) { // Segment listing
            return segments.count
        } else if (subcategoryMode && section == 0) { // Subcategory listing
            return subcategoryItems.count
        } else if let c = products?.count { // Product listing
            return c
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if (segmentMode) { // Segment listing
            let cell : ListItemSegmentCell = collectionView.dequeueReusableCellWithReuseIdentifier("segment_cell", forIndexPath: indexPath) as! ListItemSegmentCell
            cell.imgSegment.image = segments[indexPath.item].image
            
            return cell
        } else if (subcategoryMode && indexPath.section == 0) { // Subcategory listing
            let cell : ListItemSubcategoryCell = collectionView.dequeueReusableCellWithReuseIdentifier("subcategory_cell", forIndexPath: indexPath) as! ListItemSubcategoryCell
            cell.imgSubcategory.image = subcategoryItems[indexPath.item].image
            cell.lblSubcategory.hidden = true // Unused label
            return cell
        } else { // Product listing
            if (indexPath.row == (products?.count)!-4 && requesting == false && done == false && storeMode == false && featuredProductsMode == false) {
                getProducts()
            }
            
            let cell : ListItemCell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ListItemCell
            
            let p = products?[indexPath.item]
            cell.adapt(p!)
            if (featuredProductsMode) {
                // Hide featured ribbon
                cell.imgFeatured.hidden = true
            }
            
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let viewWidth = UIScreen.mainScreen().bounds.size.width
        if (segmentMode) { // Segment listing
            let segWidth = viewWidth - 16
            let segHeight = segWidth * segments[indexPath.item].image.size.height / segments[indexPath.item].image.size.width
            return CGSize(width: viewWidth, height: segHeight)
        } else if (subcategoryMode && indexPath.section == 0) { // Subcategory listing
            let viewMinusMargin = viewWidth - 16
            return CGSize(width: viewMinusMargin / 3, height: viewMinusMargin / 3)
        } else { // Product listing
            return CGSize(width: itemCellWidth!, height: itemCellWidth! + 46)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let s : CGFloat = (listStage == 1 ? 1 : 4)
        if (segmentMode) { // Segment listing
            return UIEdgeInsetsMake(4, 0, 0, 0)
        } else if (subcategoryMode && section == 0) { // Subcategory listing
            return UIEdgeInsetsMake(0, 4, 0, 4)
        } else if (isBannerExist() || standaloneMode || featuredProductsMode) {
            return UIEdgeInsetsMake(4, s, 0, s)
        } else {
            return UIEdgeInsetsMake(0, s, 0, s)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if (segmentMode) { // Segment listing
            self.selectedSegment = self.segments[indexPath.item].type
            var txt = " Kamu sedang melihat \(self.segments[indexPath.item].name)"
            if (self.segments[indexPath.item].name.length > 23) {
                txt = txt.stringByReplacingOccurrencesOfString("sedang ", withString: "")
            }
            let attTxt = NSMutableAttributedString(string: txt)
            attTxt.addAttributes([NSFontAttributeName : AppFont.Prelo2.getFont(11)!], range: NSRange.init(location: 0, length: 1))
            attTxt.addAttributes([NSFontAttributeName : UIFont.systemFontOfSize(12)], range: NSRange.init(location: 1, length: txt.length - 1))
            self.lblTopHeader.attributedText = attTxt
            segmentMode = false
            self.products?.removeAll()
            self.setupGrid()
            refresh()
        } else if (subcategoryMode && indexPath.section == 0) { // Subcategory listing
            NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
            
            let p = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
            p.filterMode = true
            p.fltrCategId = subcategoryItems[indexPath.item].id
            p.fltrSortBy = "recent"
            self.navigationController?.pushViewController(p, animated: true)
        } else { // Product listing
            selectedProduct = products?[indexPath.item]
            if (featuredProductsMode) {
                selectedProduct?.setToFeatured()
            }
            launchDetail()
        }
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if (kind == UICollectionElementKindSectionHeader) { // Header
            let h = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "header", forIndexPath: indexPath) as! ListHeader
            if (featuredProductsMode) {
                if (self.carouselItems.count > 0) {
                    h.adaptCarousel(self.carouselItems)
                }
                if (!isCarouselTimerSet) {
                    h.setCarouselTimer()
                    isCarouselTimerSet = true
                }
            } else if (isBannerExist()) {
                h.adaptBanner(self.bannerImageUrl, targetUrl: bannerTargetUrl)
            }
            return h
        } else if (kind == UICollectionElementKindSectionFooter) { // Footer
            let f = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "footer", forIndexPath: indexPath) as! ListFooter
            
            // Default value
            f.btnFooter.hidden = true
            f.lblFooter.hidden = true
            f.loading.hidden = false
            
            // Loading handle
            self.footerLoading = f.loading
            if (self.done)
            {
                self.footerLoading?.hidden = true
            }
            
            // Adapt
            if (featuredProductsMode && carouselItems.count > 0) { // 'Lihat semua barang' button, only show if featured products is loaded
                f.btnFooter.hidden = false
                f.btnFooterAction = {
                    NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
                    
                    let p = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                    p.filterMode = true
                    p.fltrCategId = "55de6d4e9ffd40362ae310a7"
                    p.fltrSortBy = "recent"
                    self.navigationController?.pushViewController(p, animated: true)
                }
            } else if (subcategoryMode && indexPath.section == 0) { // 'Header' for section idx 1, we use section 0's footer so it won't be floating
                self.footerLoading?.hidden = true
                f.lblFooter.hidden = false
            } else { // Default loading footer
                f.btnFooter.hidden = true
            }
            
            return f
        }
        return UICollectionReusableView()
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if (featuredProductsMode) {
            let headerWidth : CGFloat = collectionView.frame.size.width - 8
            var headerHeight : CGFloat = 0
            if (carouselItems.count > 0) {
                for i in 0...self.carouselItems.count - 1 {
                    let height = ((headerWidth / carouselItems[i].img.size.width) * carouselItems[i].img.size.height)
                    if (height > headerHeight) {
                        headerHeight = height
                    }
                }
            }
            headerHeight += 56 // Editor's pick title
            return CGSizeMake(headerWidth, headerHeight)
        } else if (isBannerExist()) {
            let headerWidth : CGFloat = collectionView.frame.size.width - 8
            var headerHeight : CGFloat = 0
            if let bannerImageUrl = NSURL(string: self.bannerImageUrl) {
                if let imgData = NSData.init(contentsOfURL: bannerImageUrl) {
                    if let img = UIImage.init(data: imgData) {
                        headerHeight = ((headerWidth / img.size.width) * img.size.height)
                    }
                }
            }
            return CGSizeMake(headerWidth, headerHeight)
        }
        return CGSizeZero
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if (segmentMode) {
            return CGSizeZero
        } else if (featuredProductsMode) {
            return CGSizeMake(collectionView.width, 66)
        } else if (subcategoryMode && section == 0) { // 'Header' for section idx 1, we use section 0's footer so it won't be floating
            return CGSizeMake(collectionView.width, 38)
        }
        return CGSizeMake(collectionView.width, 50)
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
            if (!storeMode && !standaloneMode) {
                if (currScrollPoint.y < scrollView.contentOffset.y) {
                    if ((self.navigationController?.navigationBarHidden)! == false) {
                        if (!segmentMode) {
                            NSNotificationCenter.defaultCenter().postNotificationName("hideBottomBar", object: nil)
                            self.navigationController?.setNavigationBarHidden(true, animated: true)
                            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
                            if (selectedSegment != "") {
                                consHeightVwTopHeader.constant = 0
                                UIView.animateWithDuration(0.2) {
                                    self.view.layoutIfNeeded()
                                }
                            }
                        }
                    }
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
                    if (selectedSegment != "") {
                        consHeightVwTopHeader.constant = 40
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
    
    // MARK: - Banner and TopHeader
    
    func isBannerExist() -> Bool {
        // Jika is_featured adl true, banner dianggap tidak exist
        return (self.bannerImageUrl != "" && self.categoryJson?["is_featured"].boolValue == false)
    }
    
    func setDefaultTopHeaderWomen() {
        lblTopHeader.text = "Barang apa yang ingin kamu lihat hari ini?"
        lblTopHeader.font = UIFont.systemFontOfSize(12)
    }
    
    @IBAction func topHeaderPressed(sender: AnyObject) {
        if (!segmentMode) {
            setDefaultTopHeaderWomen()
            selectedSegment = ""
            segmentMode = true
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
        NSNotificationCenter.defaultCenter().postNotificationName("pushnew", object: self.selectedProduct)
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

class ListItemCell : UICollectionViewCell
{
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

class ListHeader : UICollectionReusableView, UIScrollViewDelegate {
    // Banner
    @IBOutlet var vwBanner: UIView!
    @IBOutlet var banner : UIImageView!
    @IBOutlet var btnBanner : UIButton!
    var targetUrl : String = ""
    
    // Text only
    @IBOutlet var vwTextOnly: UIView!
    @IBOutlet var lblTextOnly: UILabel!
    
    // Carousel
    @IBOutlet var vwCarousel: UIView!
    @IBOutlet var scrlVwCarousel: UIScrollView!
    @IBOutlet var contentVwCarousel: UIView!
    @IBOutlet var pageCtrlCarousel: UIPageControl!
    @IBOutlet var consWidthContentVwCarousel: NSLayoutConstraint!
    var carouselItems : [CarouselItem] = []
    @IBOutlet var lblBottomCarousel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        vwBanner.hidden = true
        vwTextOnly.hidden = true
        vwCarousel.hidden = true
        
        var carouselRect = scrlVwCarousel.frame
        carouselRect.size.width = UIScreen.mainScreen().bounds.width - 8
        scrlVwCarousel.frame = carouselRect
        
        let attTxt = NSMutableAttributedString.init(attributedString: lblBottomCarousel.attributedText!)
        attTxt.addAttributes([NSFontAttributeName:AppFont.PreloAwesome.getFont(14)!], range: (lblBottomCarousel.text! as NSString).rangeOfString(""))
        lblBottomCarousel.attributedText = attTxt
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        vwBanner.hidden = true
        vwTextOnly.hidden = true
        vwCarousel.hidden = true
    }
    
    func adaptBanner(imgStr : String, targetUrl : String) {
        vwBanner.hidden = false
        vwTextOnly.hidden = true
        vwCarousel.hidden = true
        
        if let bannerImgUrl = NSURL(string: imgStr) {
            banner.setImageWithUrl(bannerImgUrl, placeHolderImage: nil)
        }
        self.targetUrl = targetUrl
    }
    
    func adaptTextOnly(txt : String) {
        vwBanner.hidden = true
        vwTextOnly.hidden = false
        vwCarousel.hidden = true
        
        lblTextOnly.text = txt
    }
    
    func adaptCarousel(carouselItems : [CarouselItem]) {
        vwBanner.hidden = true
        vwTextOnly.hidden = true
        vwCarousel.hidden = false
        
        self.carouselItems = carouselItems
        scrlVwCarousel.delegate = self
        
        self.pageCtrlCarousel.numberOfPages = carouselItems.count
        self.pageCtrlCarousel.currentPage = 0
        var rectHeightFix : CGFloat = 0
        let rectWidthFix : CGFloat = UIScreen.mainScreen().bounds.size.width - 8
        self.consWidthContentVwCarousel.constant = rectWidthFix * CGFloat(carouselItems.count)
        for i in 0...carouselItems.count - 1 {
            let height = ((rectWidthFix / carouselItems[i].img.size.width) * carouselItems[i].img.size.height)
            if (height > rectHeightFix) {
                rectHeightFix = height
            }
        }
        for i in 0...carouselItems.count - 1 {
            let rect = CGRectMake(CGFloat(i * Int(rectWidthFix)), 0, rectWidthFix, rectHeightFix)
            let uiImg = UIImageView(frame: rect, image: carouselItems[i].img)
            let uiBtn = UIButton(frame: rect)
            uiBtn.addTarget(self, action: #selector(ListHeader.btnCarouselPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            uiBtn.tag = i
            contentVwCarousel.addSubview(uiImg)
            contentVwCarousel.addSubview(uiBtn)
        }
    }
    
    func setCarouselTimer() {
        // Scroll timer
        NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(ListHeader.autoScrollCarousel), userInfo: nil, repeats: true)
    }
    
    @IBAction func btnBannerPressed(sender: AnyObject) {
        if let url = NSURL(string: targetUrl) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    @IBAction func btnTextOnlyPressed(sender: AnyObject) {
        print("TEXTONLY")
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
