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
        
        request(APISearch.InsertTopSearch(search: searchKey)).responseJSON{ _, _, _, _ in }
        
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
        if (searchMode)
        {
            return
        }
        requesting = true
        
        var catId : String?
        
        if (standalone) {
            catId = standaloneCategoryID
        } else {
            catId = category!["permalink"].string
        }
        
        request(APISearch.ProductByCategory(categoryId: catId!, sort: "", current: 0, limit: 20, priceMin: 0, priceMax: 999999999))
            .responseJSON{req, resp, res, err in
                self.done = false
                self.requesting = false
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
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
                } else {
                    
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
        
        request(APISearch.ProductByCategory(categoryId: catId!, sort: "", current: (products?.count)!, limit: 20, priceMin: 0, priceMax: 999999999))
            .responseJSON{req, resp, res, err in
                self.requesting = false
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
                    self.setupData(res)
                } else {
                    
                }
                self.setupGrid()
        }
    }
    
    func searchProduct()
    {
        requesting = true
        
        request(APISearch.Find(keyword: (searchBrand == true) ? "" : searchKey, categoryId: "", brandId: (searchBrand == true) ? searchBrandId : "", condition: "", current: (products?.count)!, limit: 20, priceMin: 0, priceMax: 999999999)).responseJSON { req, resp, res, err in
            self.requesting = false
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                self.setupData(res)
            } else {
                
            }
            self.setupGrid()
        }
    }
    
    var storeHeader : UIView?
    func getStoreProduct()
    {
        self.requesting = true
        request(APIPeople.GetShopPage(id: storeId)).responseJSON { req, resp, res, err in
            self.requesting = false
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                self.setupData(res)
            } else
            {
                
            }
            if (self.storeHeader == nil)
            {
                self.storeHeader = UIView()
                self.storeHeader?.frame = CGRectMake(0, -128, UIScreen.mainScreen().bounds.width, 128)
                self.storeHeader?.backgroundColor = UIColor.redColor()
                self.gridView.addSubview(self.storeHeader!)
            }
            self.setupGrid()
            self.gridView.contentInset = UIEdgeInsetsMake(128, 0, 0, 0)
        }
    }
    
    func setupData(res : AnyObject?)
    {
        var obj = JSON(res!)
        println(obj)
        if let arr = obj["_data"].array
        {
            if arr.count == 0
            {
                self.done = true
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
    
    func setupGrid()
    {
        if (gridView.delegate == nil)
        {
            width = ((UIScreen.mainScreen().bounds.size.width-12)/2)
            gridView.dataSource = self
            gridView.delegate = self
        }
        
        gridView.reloadData()
        gridView.contentInset = UIEdgeInsetsMake(-10, 0, 24, 0)
    }
    
    // category view
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (products?.count)!
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

class StoreHeader : UIView
{
    @IBOutlet var captionName : UILabel!
    @IBOutlet var captionLocation : UILabel!
    @IBOutlet var captionDesc : UILabel!
    @IBOutlet var captionReview : UILabel!
}
