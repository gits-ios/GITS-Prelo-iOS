//
//  ListItemViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class ListItemViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    // MARK: - Struct
    
    struct SegmentItem {
        var type : String = ""
        var name : String = ""
        var image : UIImage = UIImage()
    }
    
    // MARK: - Properties
    
    // Top buttton view, used for segment
    @IBOutlet var consTopVwTopHeader: NSLayoutConstraint!
    @IBOutlet var lblTopHeader: UILabel!
    
    // Grid view and loading
    @IBOutlet var gridView: UICollectionView!
    @IBOutlet var loading : UIActivityIndicatorView?
    
    // Data container
    var width: CGFloat? = 200
    var category : JSON?
    var products : Array <Product>?
    var selectedProduct : Product?
    var requesting : Bool = false
    
    // Standalone
    var standalone : Bool = false
    var standaloneCategoryName : String = ""
    var standaloneCategoryID : String = ""
    
    // For search result
    var searchMode = false
    var searchKey = ""
    var searchBrand = false
    var searchBrandId = ""
    
    // For shop page
    var storeMode = false
    var storeId = ""
    var storeName = ""
    var storePictPath = ""
    
    // Banner header
    var bannerImageUrl = ""
    var bannerTargetUrl = ""
    
    // For column partition in collectionview
    var listStage = 2 // 1 = gallery / very small, 2 = normal, 3 = instagram like
    
    // Refresh control
    var refresher : UIRefreshControl?
    
    // Segment view
    var segmentMode : Bool = false // Bernilai true jika sedang menampilkan pilihan segment
    var segments : [SegmentItem] = []
    var selectedSegment : String = ""
    
    // Featured products
    var featuredProductsMode : Bool = false
    var carouselItems : [CarouselItem] = []
    var isCarouselTimerSet : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // listStage initiation for iPad
        if (AppTools.isIPad) {
            listStage = 1
        }
        
        // Set title
        if (standalone) {
            self.titleText = standaloneCategoryName
        } else {
            if let name = category?["name"].string {
                self.title = name
            }
        }
        if (searchMode) {
            if (searchBrand) {
                self.title = searchKey
            } else {
                self.title = "\"" + searchKey + "\""
            }
        } else if (storeMode) {
            self.title = storeName
        }
        
        // Send top search input for searchMode
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListItemViewController.statusBarTapped), name: AppDelegate.StatusBarTapNotificationName, object: nil)
        
        if (self.category?["name"].stringValue == "Women") { // Special case for 'Women' category
            consTopVwTopHeader.constant = 40
            self.setDefaultTopHeaderWomen()
            segmentMode = true
            if let segmentsJson = self.category?["segments"].array where segmentsJson.count > 0 {
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
        } else if (self.category?["name"].stringValue == "All" && self.category?["is_featured"].boolValue == true) { // Special case for 'All' category
            consTopVwTopHeader.constant = 0
            
            // Get featured products
            if (products?.count == 0 || products == nil) {
                if (products == nil) {
                    products = []
                }
                getFeaturedProducts()
            }
        } else {
            consTopVwTopHeader.constant = 0
            
            // Get initial products
            if (products?.count == 0 || products == nil) {
                if (products == nil) {
                    products = []
                }
                getProducts()
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear x")
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AppDelegate.StatusBarTapNotificationName, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (storeMode) {
            // Remove redirect alert if any
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            if let redirAlert = appDelegate.redirAlert {
                redirAlert.dismissWithClickedButtonIndex(-1, animated: true)
            }
        }
    }
    
    func refresh() {
        if (storeMode) {
            getStoreProduct()
            return
        }
        
        if (searchMode || segmentMode) {
            refresher?.endRefreshing()
            return
        }
        
        requesting = true
        
        var catId : String?
        
        if (standalone) {
            catId = standaloneCategoryID
        } else {
            catId = category!["_id"].string
        }
        
        // API Migrasi
        request(APISearch.ProductByCategory(categoryId: catId!, sort: "", current: 0, limit: 12, priceMin: 0, priceMax: 999999999, segment: selectedSegment)).responseJSON {resp in
            self.done = false
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
    
    func statusBarTapped()
    {
        gridView.setContentOffset(CGPointMake(0, 10), animated: true)
        NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var done = false
    func getProducts()
    {
        if (searchMode)
        {
            self.searchProduct()
            return
        } else if (storeMode)
        {
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

            self.getStoreProduct()
            return
        }
        
        if (category == nil && standalone == false) {
            return
        }
        
        requesting = true
        
        var catId : String?
        
        if (standalone) {
            catId = standaloneCategoryID
        } else {
            print(category)
            catId = category!["_id"].string
        }
        
        // API Migrasi
        request(APISearch.ProductByCategory(categoryId: catId!, sort: "", current: (products?.count)!, limit: 12, priceMin: 0, priceMax: 999999999, segment: selectedSegment)).responseJSON {resp in
            self.requesting = false
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Product By Category")) {
                self.setupData(resp.result.value)
            }
            self.setupGrid()
        }
    }
    
    func getFeaturedProducts() {
        requesting = true
        
        // API Migrasi
        request(Products.GetAllFeaturedProducts()).responseJSON { resp in
            self.requesting = false
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Featured Products")) {
                self.setupData(resp.result.value)
                
                // Init carousel data
                var res = JSON(resp.result.value!)
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
            self.featuredProductsMode = true
            self.setupGrid()
        }
    }
    
    func searchProduct()
    {
        requesting = true
        
        // API Migrasi
        request(APISearch.Find(keyword: (searchBrand == true) ? "" : searchKey, categoryId: "", brandId: (searchBrand == true) ? searchBrandId : "", condition: "", current: (products?.count)!, limit: 12, priceMin: 0, priceMax: 999999999)).responseJSON {resp in
            self.requesting = false
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Search Product"))
            {
                self.setupData(resp.result.value)
            } else {
                
            }
            self.setupGrid()
        }
    }
    
    var storeHeader : StoreHeader?
    func getStoreProduct()
    {
        self.requesting = true
        // API Migrasi
        request(APIPeople.GetShopPage(id: storeId)).responseJSON {resp in
            self.requesting = false
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Data Shop Pengguna"))
            {
                self.setupData(resp.result.value)
                
                if (self.storeHeader == nil)
                {
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
                
                self.setupGrid()
                self.gridView.contentInset = UIEdgeInsetsMake(CGFloat(height), 0, 0, 0)
            } else
            {
                
            }
        }
    }
    
    func setupData(res : AnyObject?)
    {
        guard res != nil else
        {
            return
        }
        print(res)
        var obj = JSON(res!)
        print(obj)
        if let arr = obj["_data"].array
        {
            if arr.count == 0
            {
                self.done = true
                self.loading?.hidden = true
            } else
            {
                for (_, item) in obj["_data"]
                {
                    let p = Product.instance(item)
                    if (p != nil) {
                        self.products?.append(p!)
                    }
                }
            }
        }
        else if let arr = obj["_data"]["products"].array
        {
            if arr.count == 0
            {
                self.done = true
            } else
            {
                for item in arr
                {
                    let p = Product.instance(item)
                    if (p != nil) {
                        self.products?.append(p!)
                    }
                }
            }
        }
        
        if let x = self.products?.count where x < 10
        {
            self.done = true
            self.loading?.hidden = true
        }
    }
    
    var first = true
    func setupGrid()
    {
        if (first)
        {
            first = false
            gridView.dataSource = self
            gridView.delegate = self
        }
        
        width = ((UIScreen.mainScreen().bounds.size.width-12)/2)
        
        if (listStage == 1)
        {
            width = ((UIScreen.mainScreen().bounds.size.width-12)/3)
        }
        
        if (listStage == 3)
        {
            width = ((UIScreen.mainScreen().bounds.size.width-16)/1)
        }
        
        gridView.reloadData()
        gridView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0)
        gridView.hidden = false
    }
    
    // MARK: - Collection view functions
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (segmentMode) {
            return segments.count
        } else if let c = products?.count {
            return c
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if (segmentMode) {
            let cell : ListItemSegmentCell = collectionView.dequeueReusableCellWithReuseIdentifier("segment_cell", forIndexPath: indexPath) as! ListItemSegmentCell
            cell.imgSegment.image = segments[indexPath.item].image
            
            return cell
        } else {
            if (indexPath.row == (products?.count)!-4 && requesting == false && done == false && storeMode == false && featuredProductsMode == false) {
                getProducts()
            }
            
            let cell : ListItemCell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ListItemCell
            
            let p = products?[indexPath.item]
            cell.adapt(p!)
            
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if (segmentMode) {
            let viewWidth = self.view.width
            let segWidth = viewWidth - 16
            let segHeight = segWidth * segments[indexPath.item].image.size.height / segments[indexPath.item].image.size.width
            return CGSize(width: viewWidth, height: segHeight)
        } else {
            return CGSize(width: width!, height: width!+46)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let s : CGFloat = (listStage == 1 ? 1 : 4)
        if (segmentMode) {
            return UIEdgeInsetsMake(4, 0, 0, 0)
        } else if (isBannerExist() || standalone || featuredProductsMode) {
            return UIEdgeInsetsMake(4, s, 0, s)
        } else {
            return UIEdgeInsetsMake(0, s, 0, s)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if (segmentMode) {
            self.selectedSegment = self.segments[indexPath.item].type
            var txt = " Kamu sedang melihat Women bagian \(self.segments[indexPath.item].name)"
            if (self.segments[indexPath.item].name.length > 10) {
                txt = txt.stringByReplacingOccurrencesOfString("sedang ", withString: "")
            }
            let attTxt = NSMutableAttributedString(string: txt)
            attTxt.addAttributes([NSFontAttributeName : AppFont.Prelo2.getFont(11)!], range: NSRange.init(location: 0, length: 1))
            attTxt.addAttributes([NSFontAttributeName : UIFont.systemFontOfSize(12)], range: NSRange.init(location: 1, length: txt.length - 1))
            self.lblTopHeader.attributedText = attTxt
            segmentMode = false
            self.gridView.hidden = true
            refresh()
        } else {
            selectedProduct = products?[indexPath.item]
//            performSegueWithIdentifier("segDetail", sender: nil)
            launchDetail()
        }
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if (kind == UICollectionElementKindSectionHeader) { // Header
            let h = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "header", forIndexPath: indexPath) as! ListHeader
            if (featuredProductsMode) {
                h.adaptCarousel(self.carouselItems)
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
            self.loading = f.loading
            if (self.done)
            {
                self.loading?.hidden = true
            }
            if (featuredProductsMode) {
                f.btnFooter.hidden = false
                f.btnFooterAction = {
                    NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
                    
                    let p = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                    p.standalone = true
                    p.standaloneCategoryName = "All"
                    p.standaloneCategoryID = "55de6d4e9ffd40362ae310a7"
                    self.navigationController?.pushViewController(p, animated: true)
                }
            } else {
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
            for i in 0...self.carouselItems.count - 1 {
                let height = ((headerWidth / carouselItems[i].img.size.width) * carouselItems[i].img.size.height)
                if (height > headerHeight) {
                    headerHeight = height
                }
            }
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
        }
        return CGSizeMake(collectionView.width, 50)
    }
    
    // MARK: - Banner and TopHeader
    
    func isBannerExist() -> Bool {
        // Jika is_featured adl true, banner dianggap tidak exist
        return (self.bannerImageUrl != "" && self.category?["is_featured"].boolValue == false)
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
//            gridView.contentInset = UIEdgeInsetsZero
            gridView.reloadData()
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "segDetail") {

        }
        
        let c = segue.destinationViewController
        if (c.isKindOfClass(BaseViewController.classForCoder()))
        {
            let b = c as! BaseViewController
            b.previousController = self
        }
    }
    
    func launchDetail()
    {
//        self.navigationController?.pushViewController(d, animated: true)
//        self.presentViewController(nav, animated: YES, completion: nil)
//        self.previousController?.navigationController?.setNavigationBarHidden(false, animated: true)
        NSNotificationCenter.defaultCenter().postNotificationName("pushnew", object: self.selectedProduct)
    }
    
    var currScrollPoint : CGPoint = CGPointZero
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        currScrollPoint = scrollView.contentOffset
        dragging = true
    }
    
    var dragging = false
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        dragging = false
    }
    
    var reloaded = false
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (dragging)
        {
            if (!storeMode) {
                if (currScrollPoint.y < scrollView.contentOffset.y)
                {
                    if ((self.navigationController?.navigationBarHidden)! == false)
                    {
                        if (!segmentMode)
                        {
                            NSNotificationCenter.defaultCenter().postNotificationName("hideBottomBar", object: nil)
                            self.navigationController?.setNavigationBarHidden(true, animated: true)
                            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
                            if (selectedSegment != "") {
                                consTopVwTopHeader.constant = 0
                                UIView.animateWithDuration(0.2) {
                                    self.view.layoutIfNeeded()
                                }
                            }
                        }
                    }
                } else
                {
                    NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
                    if (selectedSegment != "") {
                        consTopVwTopHeader.constant = 40
                        UIView.animateWithDuration(0.2) {
                            self.view.layoutIfNeeded()
                        }
                    }
                }
            }
        }
    }
    
    func pinch(pinchedIn : Bool)
    {
        print("current stage : \(listStage)")
        listStage += (pinchedIn ? 1 : -1)
        if (listStage > 3)
        {
            listStage = 1
        }
        if (listStage < 1)
        {
            listStage = 3
        }
        
        print("next stage : \(listStage)")
        
        setupGrid()
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .CurveEaseOut, animations: {
            
            self.gridView.reloadData()
            
            }, completion: nil)
    }

}

class ListItemSegmentCell : UICollectionViewCell {
    @IBOutlet var imgSegment: UIImageView!
    
    override func prepareForReuse() {
        imgSegment.image = nil
    }
}

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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sectionLove.layer.cornerRadius = sectionLove.frame.size.width/2
        sectionLove.layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        imgSold.hidden = true
        imgReserved.hidden = true
        imgFeatured.hidden = true
    }
    
    func adapt(product : Product)
    {
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
        
        if (product.specialStory == nil || product.specialStory == "")
        {
            sectionSpecialStory.hidden = true
        } else
        {
            sectionSpecialStory.hidden = false
            captionSpecialStory.text = "\"\(product.specialStory!)\""
            if let url = product.avatar
            {
                avatar.setImageWithUrl(url, placeHolderImage: UIImage(named : "raisa.jpg"))
            } else
            {
                avatar.image = nil
            }
        }
        
        let loved = obj["is_preloved"].bool
        if (loved == true)
        {
            captionMyLove.text = ""
        } else
        {
            captionMyLove.text = ""
        }
        
        _ = obj["display_picts"][0].string
        ivCover.image = nil
        ivCover.setImageWithUrl(product.coverImageURL!, placeHolderImage: nil)
        
        if let op = product.json["price_original"].int
        {
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
            } else if (product.isFeatured) {
                self.imgFeatured.hidden = false
            }
        }
    }
}

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

class ListHeader : UICollectionReusableView, UIScrollViewDelegate
{
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        vwBanner.hidden = true
        vwTextOnly.hidden = true
        vwCarousel.hidden = true
        
        var carouselRect = scrlVwCarousel.frame
        carouselRect.size.width = UIScreen.mainScreen().bounds.width - 8
        scrlVwCarousel.frame = carouselRect
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
        self.consWidthContentVwCarousel.constant = scrlVwCarousel.width * CGFloat(carouselItems.count)
        for i in 0...carouselItems.count - 1 {
            let rect = CGRectMake(CGFloat(i * Int(scrlVwCarousel.width)), 0, scrlVwCarousel.width, scrlVwCarousel.height)
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

class ListFooter : UICollectionReusableView
{
    @IBOutlet var loading : UIActivityIndicatorView!
    @IBOutlet var btnFooter: UIButton!
    
    var btnFooterAction : () -> () = {}
    
    @IBAction func btnFooterPressed(sender: AnyObject) {
        self.btnFooterAction()
    }
}

class StoreHeader : UIView
{
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
    
    @IBAction func edit()
    {
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
