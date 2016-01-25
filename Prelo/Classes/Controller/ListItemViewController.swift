//
//  ListItemViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class ListItemViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate
{
    @IBOutlet var gridView: UICollectionView!
    @IBOutlet var loading : UIActivityIndicatorView?
    
    var width: CGFloat? = 200
    var category : JSON?
    var products : Array <Product>?
    var selectedProduct : Product?
    var requesting : Bool = false
    
    var standalone : Bool = false
    var standaloneCategoryName : String = ""
    var standaloneCategoryID : String = ""
    
    var searchMode = false
    var searchKey = ""
    var searchBrand = false
    var searchBrandId = ""
    
    var storeMode = false
    var storeId = ""
    var storeName = ""
    var storePictPath = ""
    
    var refresher : UIRefreshControl?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if (standalone) {
            self.titleText = standaloneCategoryName
        } else
        {
            if let name = category?["name"].string
            {
                self.title = name
            }
        }
        
        if (searchMode)
        {
            if (searchBrand)
            {
                self.title = searchKey
            } else
            {
                self.title = "\"" + searchKey + "\""
            }
        } else if (storeMode)
        {
            self.title = storeName
        }
        
        request(APISearch.InsertTopSearch(search: searchKey)).responseJSON{ req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Insert Top Search")) {
                
            }
        }
        
        refresher = UIRefreshControl()
        refresher!.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.gridView.addSubview(refresher!)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarTapped", name: AppDelegate.StatusBarTapNotificationName, object: nil)
        
//        gridView.contentInset = UIEdgeInsetsMake(-10, 0, 24, 0)
        
        if (products?.count == 0 || products == nil) {
            if (products == nil) {
                products = []
            }
            getProducts()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        println("viewWillDisappear x")
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AppDelegate.StatusBarTapNotificationName, object: nil)
    }
    
    func refresh()
    {
        if (storeMode)
        {
            getStoreProduct()
            return
        }
        
        if (searchMode)
        {
            return
        }
        requesting = true
        
        var catId : String?
        
        if (standalone) {
            catId = standaloneCategoryID
        } else {
            catId = category!["_id"].string
        }
        
        request(APISearch.ProductByCategory(categoryId: catId!, sort: "", current: 0, limit: 20, priceMin: 0, priceMax: 999999999)).responseJSON { req, resp, res, err in
            self.done = false
            self.requesting = false
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Daftar Produk")) {
                self.products = []
                var obj = JSON(res!)
                for (index : String, item : JSON) in obj["_data"]
                {
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
            println(category)
            catId = category!["_id"].string
        }
        
        request(APISearch.ProductByCategory(categoryId: catId!, sort: "", current: (products?.count)!, limit: 20, priceMin: 0, priceMax: 999999999)).responseJSON { req, resp, res, err in
            self.requesting = false
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Product By Category")) {
                self.setupData(res)
            }
            self.setupGrid()
        }
    }
    
    func searchProduct()
    {
        requesting = true
        
        request(APISearch.Find(keyword: (searchBrand == true) ? "" : searchKey, categoryId: "", brandId: (searchBrand == true) ? searchBrandId : "", condition: "", current: (products?.count)!, limit: 20, priceMin: 0, priceMax: 999999999)).responseJSON { req, resp, res, err in
            self.requesting = false
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Search Product"))
            {
                self.setupData(res)
            } else {
                
            }
            self.setupGrid()
        }
    }
    
    var storeHeader : StoreHeader?
    func getStoreProduct()
    {
        self.requesting = true
        request(APIPeople.GetShopPage(id: storeId)).responseJSON { req, resp, res, err in
            self.requesting = false
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Data Shop Pengguna"))
            {
                println(res)
                self.setupData(res)
                
                if (self.storeHeader == nil)
                {
                    self.storeHeader = NSBundle.mainBundle().loadNibNamed("StoreHeader", owner: nil, options: nil).first as? StoreHeader
                    self.gridView.addSubview(self.storeHeader!)
                }
                
                let json = JSON(res!)["_data"]
                println(json)
                
                self.storeHeader?.captionName.text = json["username"].string
                self.storeHeader?.captionDesc.text = json["profile"]["description"].string
                self.storeHeader?.avatar.setImageWithUrl(NSURL(string: json["profile"]["pict"].string!)!, placeHolderImage: nil)
                
                // Love
                let reviewScore = json["average_star"].floatValue
                var loveText = ""
                for (var i = 0; i < 5; i++) {
                    if (Float(i) <= reviewScore - 0.5) {
                        loveText += ""
                    } else {
                        loveText += ""
                    }
                }
                let attrStringLove = NSMutableAttributedString(string: loveText)
                attrStringLove.addAttribute(NSKernAttributeName, value: CGFloat(1.4), range: NSRange(location: 0, length: loveText.length()))
                self.storeHeader?.captionLove.attributedText = attrStringLove
                
                // Reviewer count
                let numReview = json["num_reviewer"].intValue
                self.storeHeader?.captionReview.text = "(\(numReview) Review)"
                
                var height = 0
                
                if let desc = self.storeHeader?.captionDesc.text
                {
                    height = 272 + Int(desc.boundsWithFontSize(UIFont.systemFontOfSize(16), width: UIScreen.mainScreen().bounds.width-16).height)
                } else {
                    self.storeHeader?.captionDesc.text = "Belum ada deskripsi."
                    self.storeHeader?.captionDesc.textColor = UIColor.lightGrayColor()
                    height = 272 + Int("Belum ada deskripsi.".boundsWithFontSize(UIFont.systemFontOfSize(16), width: UIScreen.mainScreen().bounds.width-16).height)
                }
                self.storeHeader?.width = UIScreen.mainScreen().bounds.width
                self.storeHeader?.height = CGFloat(height)
                self.storeHeader?.y = CGFloat(-height)
                
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
                
                if let count = self.products?.count
                {
                    self.storeHeader?.captionTotal.text = String(count) + " PRODUK"
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
                
                self.setupGrid()
                self.gridView.contentInset = UIEdgeInsetsMake(CGFloat(height), 0, 0, 0)
            } else
            {
                
            }
        }
    }
    
    func setupData(res : AnyObject?)
    {
        println(res)
        var obj = JSON(res!)
        println(obj)
        if let arr = obj["_data"].array
        {
            if arr.count == 0
            {
                self.done = true
                self.loading?.hidden = true
            } else
            {
                for (index : String, item : JSON) in obj["_data"]
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
    }
    
    var first = true
    func setupGrid()
    {
        if (first)
        {
            first = false
            width = ((UIScreen.mainScreen().bounds.size.width-12)/2)
            gridView.dataSource = self
            gridView.delegate = self
//            self.gridView.registerClass(ListFooter.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footer")
        }
        
        gridView.reloadData()
        gridView.contentInset = UIEdgeInsetsMake(-10, 0, 24, 0)
    }
    
    // category view
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let c = products?.count
        {
            return c
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        if (indexPath.row == (products?.count)!-4 && requesting == false && done == false && storeMode == false) {
            getProducts()
        }
        
        var cell:ListItemCell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ListItemCell
        
        let p = products?[indexPath.item]
        cell.adapt(p!)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: width!, height: width!+46)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        selectedProduct = products?[indexPath.item]
//        performSegueWithIdentifier("segDetail", sender: nil)
        launchDetail()
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let f = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "footer", forIndexPath: indexPath) as! ListFooter
        self.loading = f.loading
        if (self.done)
        {
            self.loading?.hidden = true
        }
        return f
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
                        NSNotificationCenter.defaultCenter().postNotificationName("hideBottomBar", object: nil)
                        self.navigationController?.setNavigationBarHidden(true, animated: true)
                        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
                    }
                } else
                {
                    NSNotificationCenter.defaultCenter().postNotificationName("showBottomBar", object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
                }
            }
        }
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sectionLove.layer.cornerRadius = sectionLove.frame.size.width/2
        sectionLove.layer.masksToBounds = true
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
        
        let firstImg = obj["display_picts"][0].string
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
    }
}

class ListFooter : UICollectionReusableView
{
    @IBOutlet var loading : UIActivityIndicatorView!
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
    
    var editBlock : ()->() = {}
    var reviewBlock : ()->() = {}
    
    @IBAction func edit()
    {
        self.editBlock()
    }
    
    @IBAction func gotoShopReview(sender: AnyObject) {
        self.reviewBlock()
    }
}
