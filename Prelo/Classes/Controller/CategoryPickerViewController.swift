//
//  CategoryPickerViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/26/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

typealias BlockCategorySelected = ([String : AnyObject]) -> ()

class CategoryPickerViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{

    @IBOutlet var gridView : UICollectionView!
    
    var categories : Array<JSON> = []
    var blockDone : BlockCategorySelected?
    var searchMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        
        self.title = "Pilih Kategori"

        // Do any additional setup after loading the view.
        let data = NSUserDefaults.standardUserDefaults().objectForKey("pre_categories") as? NSData
        let cache = JSON(NSKeyedUnarchiver.unarchiveObjectWithData(data!)!)
        if let children = cache["_data"][0]["children"].arrayObject
        {
            for o in children
            {
                categories.append(JSON(o))
            }
            
            gridView.dataSource = self
            gridView.delegate = self
            
            gridView.reloadData()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! CategoryPickerParentCell
        
        let j = categories[indexPath.item]
        
        if let name = j["name"].string
        {
            c.captionTitle.text = name
        }
        
        if let imageName = j["image_name"].string {
            c.imageView.backgroundColor = UIColor.whiteColor()
            c.imageView.setImageWithUrl(NSURL(string: imageName)!, placeHolderImage: nil)
//            if let url = NSURL(string: imageName) {
//                if let data = NSData(contentsOfURL: url) {
//                    c.imageView.contentMode = UIViewContentMode.ScaleAspectFit
//                    c.imageView.image = UIImage(data: data)
//                }
//            }
        }
        
        return c
    }
    
    let w = (UIScreen.mainScreen().bounds.size.width-24)/2
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(w, w*120/100)
    }
    
    var selectedCategory : JSON?
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedCategory = categories[indexPath.item]
        self.performSegueWithIdentifier("segChild", sender: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let c = segue.destinationViewController as! CategoryChildrenPickerViewController
        c.parent = selectedCategory!
        c.blockDone = blockDone
        c.backTreshold = 3
        c.searchMode = self.searchMode
    }

}

class CategoryPickerParentCell : UICollectionViewCell
{
    @IBOutlet var imageView : UIImageView!
    @IBOutlet var captionTitle : UILabel!
}

class CategoryChildrenPickerViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate
{
    var parent : JSON = JSON(["name":""])
    var blockDone : BlockCategorySelected?
    var searchMode = false
    
    @IBOutlet var tableView : UITableView!
    
    var categories : Array<JSON> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        println(parent)
        if let name = parent["name"].string
        {
            self.title = name.capitalizedString
        } else
        {
            self.title = "Pilih Kategori"
        }
        
        if let children = parent["children"].arrayObject
        {
            for o in children
            {
                categories.append(JSON(o))
                tableView.dataSource = self
                tableView.delegate = self
                tableView.tableFooterView = UIView()
                tableView.reloadData()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var c = tableView.dequeueReusableCellWithIdentifier("cell") as? UITableViewCell
        if (c == nil)
        {
            c = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
        }
        
        let j = categories[indexPath.row]
        if let name = j["name"].string
        {
            println(j)
            c?.textLabel!.text = name
        }
        
        return c!
    }
    
    var selectedCategory : JSON?
    var backTreshold = 1
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        selectedCategory = categories[indexPath.row]
        var x = 0
        let c = selectedCategory!["children"].arrayObject
        if (c != nil)
        {
            x = (c?.count)!
        }
        if (x != 0)
        {
            let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdCategoryChildrenPicker) as! CategoryChildrenPickerViewController
            p.parent = selectedCategory!
            p.blockDone = self.blockDone
            p.backTreshold = backTreshold+1
            p.searchMode = self.searchMode
            self.navigationController?.pushViewController(p, animated: true)
        } else
        {
            let data = ["parent":parent.rawValue, "child":selectedCategory!.rawValue]
            if (searchMode)
            {
                let p = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                p.category = selectedCategory
                self.navigationController?.pushViewController(p, animated: true)
            } else
            {
                self.blockDone!(data)
                
                let c = self.navigationController?.viewControllers.count
                let v = self.navigationController?.viewControllers[c!-backTreshold] as! UIViewController
                self.navigationController?.popToViewController(v, animated: true)
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
}
