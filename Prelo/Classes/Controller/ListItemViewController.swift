//
//  ListItemViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class ListItemViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var gridView: UICollectionView!
    
    var width: CGFloat? = 200
    var category : JSON?
    var products : Array <Product>?
    var selectedProduct : Product?
    var requesting : Bool = false
    
    var standalone : Bool = false
    var standaloneCategoryName : String = ""
    var standaloneCategoryID : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if (standalone) {
            self.titleText = standaloneCategoryName
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        gridView.contentInset = UIEdgeInsetsMake(-10, 0, 24, 0)
        
        if (products?.count == 0 || products == nil) {
            if (products == nil) {
                products = []
            }
            getProducts()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarTapped", name: AppDelegate.StatusBarTapNotificationName, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        println("viewWillDisappear x")
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AppDelegate.StatusBarTapNotificationName, object: nil)
    }
    
    func statusBarTapped()
    {
        gridView.setContentOffset(CGPointMake(0, 10), animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getProducts()
    {
        if (category == nil && standalone == false) {
            return
        }
        
        requesting = true
        
        var catId : String?
        
        if (standalone) {
            catId = standaloneCategoryID
        } else {
            catId = category!["permalink"].string
        }
        
        request(Products.ListByCategory(categoryId: catId!, location: "", sort: "", current: (products?.count)!, limit: 20, priceMin: 0, priceMax: 999999999))
            .responseJSON{ req, _, res, err in
                self.requesting = false
                if (err != nil) {
                    println(err)
                } else {
                    var obj = JSON(res!)
                    for (index : String, item : JSON) in obj["_data"]
                    {
                        let p = Product.instance(item)
                        if (p != nil) {
                            self.products?.append(p!)
                        }
                    }
                }
                self.setupGrid()
        }
    }
    
    func setupGrid()
    {
        if (gridView.delegate == nil)
        {
            width = ((UIScreen.mainScreen().bounds.size.width-24)/2)
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
        if (indexPath.row == (products?.count)!-4 && requesting == false) {
            getProducts()
        }
        
        var cell:ListItemCell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ListItemCell
        
        let p = products?[indexPath.item]
        cell.adapt(p!)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: width!, height: width!+50)
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
        NSNotificationCenter.defaultCenter().postNotificationName("pushnew", object: selectedProduct);
    }

}

class ListItemCell : UICollectionViewCell
{
    @IBOutlet var ivCover: UIImageView!
    @IBOutlet var captionTitle: UILabel!
    @IBOutlet var captionPrice: UILabel!
    @IBOutlet var captionLove: UILabel!
    @IBOutlet var captionMyLove: UILabel!
    @IBOutlet var captionComment: UILabel!
    @IBOutlet var sectionLove : UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.layer.borderWidth = 1
        
        sectionLove.layer.cornerRadius = sectionLove.frame.size.width/2
        sectionLove.layer.masksToBounds = true
    }
    
    func adapt(product : Product)
    {
        let obj = product.json
        captionTitle.text = product.name
        captionPrice.text = "Rp. " + String(obj["price"].int!)
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
    }
}
