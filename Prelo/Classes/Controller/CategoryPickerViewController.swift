//
//  CategoryPickerViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/26/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

typealias BlockCategorySelected = ([String : AnyObject]) -> ()

// MARK: - Protocol

protocol CategoryPickerDelegate {
    func adjustCategory(categId : String)
}

// MARK: - Class

class CategoryPickerViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: - Properties
    
    // Views
    @IBOutlet var gridView : UICollectionView!
    @IBOutlet var loading: UIActivityIndicatorView!
    
    // Predefined values
    var root : UIViewController? // For returning to page before category picker
    var blockDone : BlockCategorySelected?
    var searchMode = false
    
    // Data container
    var categories : Array<JSON> = []
    var selectedCategory : JSON?
    let cellWidth = (UIScreen.mainScreen().bounds.size.width - 32) / 3
    
    // Delegate
    var delegate : CategoryPickerDelegate? = nil
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Status bar style
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        
        // Set title
        self.title = "Pilih Kategori"

        // Get category before setup data
        self.getCategory()
    }
    
    func getCategory() {
        request(References.CategoryList).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "List Kategori")) {
                NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(resp.result.value!), forKey: "pre_categories")
                NSUserDefaults.standardUserDefaults().synchronize()
                self.setupData()
            }
        }
    }
    
    func setupData() {
        let data = NSUserDefaults.standardUserDefaults().objectForKey("pre_categories") as? NSData
        let cache = JSON(NSKeyedUnarchiver.unarchiveObjectWithData(data!)!)
        if let children = cache["_data"][0]["children"].arrayObject {
            
            // Get children for 'All' category
            for o in children {
                categories.append(JSON(o))
            }
            
            // Include 'All' itself for searchMode
            if (searchMode) {
                categories.insert(cache["_data"][0], atIndex: 0)
            }
            
            // Hide loading
            loading.hidden = true
            
            // Setup collection view
            gridView.dataSource = self
            gridView.delegate = self
            gridView.reloadData()
        }
    }
    
    // MARK: - Collection view functions
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(cellWidth, cellWidth * 120 / 100)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(8, 8, 8, 8)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! CategoryPickerParentCell
        
        let j = categories[indexPath.item]
        
        if let name = j["name"].string {
            c.captionTitle.text = name
        }
        
        if let imageName = j["image_name"].string {
            c.imageView.backgroundColor = UIColor.whiteColor()
            c.imageView.setImageWithUrl(NSURL(string: imageName)!, placeHolderImage: nil)
        }
        
        c.createBordersWithColor(UIColor.lightGrayColor(), radius: 0, width: 1)
        
        return c
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // Set selected category
        selectedCategory = categories[indexPath.item]
        
        if (searchMode && indexPath.row == 0) { // Memilih kategori 'All' (semua kategori)
            if (self.previousController != nil) {
                self.delegate?.adjustCategory(selectedCategory!["_id"].stringValue)
                self.navigationController?.popViewControllerAnimated(true)
            } else {
                let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                l.filterMode = true
                l.fltrCategId = selectedCategory!["_id"].stringValue
                l.fltrSortBy = "recent"
                self.navigationController?.pushViewController(l, animated: true)
            }
            return
        }
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            self.performSegueWithIdentifier("segChild", sender: nil)
        } else {
            let c = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdCategoryChildrenPicker) as! CategoryChildrenPickerViewController
            c.parent = selectedCategory!
            c.blockDone = blockDone
            c.backTreshold = 3
            c.root = self.root
            c.searchMode = self.searchMode
            c.categoryImageName = categories[indexPath.item]["image_name"].stringValue
            c.delegate = self.delegate
            c.previousController = self.previousController
            self.navigationController?.pushViewController(c, animated: true)
        }
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
        c.root = self.root
        c.searchMode = self.searchMode
        c.categoryImageName = selectedCategory!["image_name"].stringValue
        c.delegate = self.delegate
        c.previousController = self.previousController
    }

}

// MARK: - Class

class CategoryPickerParentCell : UICollectionViewCell {
    @IBOutlet var imageView : UIImageView!
    @IBOutlet var captionTitle : UILabel!
}

// MARK: - Class

class CategoryChildrenPickerViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var tableView : UITableView!
    
    // Predefined values
    var root : UIViewController?
    var parent : JSON = JSON(["name":""])
    var blockDone : BlockCategorySelected?
    var backTreshold = 1
    var searchMode = false
    var categoryImageName : String = ""
    
    // Data container
    var categories : Array<JSON> = []
    var categoryLv2Name : String = ""
    var selectedCategory : JSON?
    
    // Delegate
    var delegate : CategoryPickerDelegate? = nil
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        if let name = parent["name"].string {
            self.title = name.capitalizedString
        } else {
            self.title = "Pilih Kategori"
        }
        
        // Get children categories
        if let children = parent["children"].arrayObject {
            for o in children {
                categories.append(JSON(o))
            }
        }
        
        // Include parent category itself for searchMode
        if (searchMode) {
            var parentCateg = parent
            parentCateg["name"] = JSON("Semua " + parent["name"].stringValue)
            categories.insert(parentCateg, atIndex: 0)
        }
        
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.reloadData()
    }
    
    // MARK: - Table view functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var c = tableView.dequeueReusableCellWithIdentifier("cell")
        if (c == nil) {
            c = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
        }
        
        let j = categories[indexPath.row]
        if let name = j["name"].string {
            c?.textLabel!.text = name
        }
        
        return c!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Get level 2 category name (used for add product page)
        selectedCategory = categories[indexPath.row]
        if let lv = selectedCategory!["level"].int {
            if (lv == 2) {
                self.categoryLv2Name = selectedCategory!["name"].stringValue
            }
        }
        
        var childCount = 0
        let children = selectedCategory!["children"].arrayObject
        if (children != nil) {
            childCount = children!.count
        }
        if (!(searchMode && indexPath.row == 0) && childCount > 0) {
            let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdCategoryChildrenPicker) as! CategoryChildrenPickerViewController
            p.parent = selectedCategory!
            p.blockDone = self.blockDone
            p.backTreshold = backTreshold + 1
            p.searchMode = self.searchMode
            p.root = root
            p.categoryImageName = self.categoryImageName
            p.categoryLv2Name = self.categoryLv2Name
            p.delegate = self.delegate
            p.previousController = self.previousController
            self.navigationController?.pushViewController(p, animated: true)
        } else {
            let data = [
                "parent":parent.rawValue,
                "child":selectedCategory!.rawValue,
                "category_image_name":self.categoryImageName,
                "category_level2_name":self.categoryLv2Name
            ]
            if (searchMode) {
                if (self.previousController != nil) {
                    self.delegate?.adjustCategory(selectedCategory!["_id"].stringValue)
                    self.navigationController?.popToViewController(self.previousController!, animated: true)
                } else {
                    let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                    l.filterMode = true
                    l.fltrCategId = selectedCategory!["_id"].stringValue
                    l.fltrSortBy = "recent"
                    self.navigationController?.pushViewController(l, animated: true)
                }
            } else {
                self.blockDone!(data)
                
                if let r = self.root {
                    self.navigationController?.popToViewController(r, animated: true)
                } else {
                    let c = self.navigationController?.viewControllers.count
                    let v = (self.navigationController?.viewControllers[c! - backTreshold])!
                    self.navigationController?.popToViewController(v, animated: true)
                }
            }
        }
    }
}
