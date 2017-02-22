//
//  CategoryPickerViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/26/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Alamofire

typealias BlockCategorySelected = ([String : AnyObject]) -> ()

// MARK: - Protocol

protocol CategoryPickerDelegate {
    func adjustCategory(_ categId : String)
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
    let cellWidth = (UIScreen.main.bounds.size.width - 32) / 3
    
    // Delegate
    var delegate : CategoryPickerDelegate? = nil
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Status bar style
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
        
        // Set title
        self.title = "Pilih Kategori"

        // Get category before setup data
        self.getCategory()
    }
    
    func getCategory() {
        let _ = request(APIReference.categoryList).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "List Kategori")) {
                UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: resp.result.value!), forKey: "pre_categories")
                UserDefaults.standard.synchronize()
                self.setupData()
            }
        }
    }
    
    func setupData() {
        let data = UserDefaults.standard.object(forKey: "pre_categories") as? Data
        let cache = JSON(NSKeyedUnarchiver.unarchiveObject(with: data!)!)
        if let children = cache["_data"][0]["children"].arrayObject {
            
            // Get children for 'All' category
            for o in children {
                categories.append(JSON(o))
            }
            
            // Include 'All' itself for searchMode
            if (searchMode) {
                categories.insert(cache["_data"][0], at: 0)
            }
            
            // Hide loading
            loading.isHidden = true
            
            // Setup collection view
            gridView.dataSource = self
            gridView.delegate = self
            gridView.reloadData()
        }
    }
    
    // MARK: - Collection view functions
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: cellWidth * 120 / 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(8, 8, 8, 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CategoryPickerParentCell
        
        let j = categories[(indexPath as NSIndexPath).item]
        
        if let name = j["name"].string {
            c.captionTitle.text = name
        }
        
        if let imageName = j["image_name"].string {
            c.imageView.backgroundColor = UIColor.white
            c.imageView.afSetImage(withURL: URL(string: imageName)!, withFilter: .fitWithPreloPlaceHolder)
        }
        
        c.createBordersWithColor(UIColor.lightGray, radius: 0, width: 1)
        
        return c
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Set selected category
        selectedCategory = categories[(indexPath as NSIndexPath).item]
        
        if (searchMode && (indexPath as NSIndexPath).row == 0) { // Memilih kategori 'All' (semua kategori)
            if (self.previousController != nil) {
                self.delegate?.adjustCategory(selectedCategory!["_id"].stringValue)
                self.navigationController?.popViewController(animated: true)
            } else {
                let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                l.currentMode = .filter
                l.isBackToFltrSearch = true
                l.fltrCategId = selectedCategory!["_id"].stringValue
                l.fltrSortBy = "recent"
                l.previousScreen = PageName.Search
                self.navigationController?.pushViewController(l, animated: true)
            }
            return
        }
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            self.performSegue(withIdentifier: "segChild", sender: nil)
        } else {
            let c = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdCategoryChildrenPicker) as! CategoryChildrenPickerViewController
            c.parentJson = selectedCategory!
            c.blockDone = blockDone
            c.backTreshold = 3
            c.root = self.root
            c.searchMode = self.searchMode
            c.categoryImageName = categories[(indexPath as NSIndexPath).item]["image_name"].stringValue
            c.categoryLv1Id = categories[(indexPath as NSIndexPath).item]["_id"].stringValue
            c.delegate = self.delegate
            c.previousController = self.previousController
            self.navigationController?.pushViewController(c, animated: true)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let c = segue.destination as! CategoryChildrenPickerViewController
        c.parentJson = selectedCategory!
        c.blockDone = blockDone
        c.backTreshold = 3
        c.root = self.root
        c.searchMode = self.searchMode
        c.categoryImageName = selectedCategory!["image_name"].stringValue
        c.categoryLv1Id = selectedCategory!["_id"].stringValue
        c.delegate = self.delegate
        c.previousController = self.previousController
    }

}

// MARK: - Class

class CategoryPickerParentCell : UICollectionViewCell {
    @IBOutlet var imageView : UIImageView!
    @IBOutlet var captionTitle : UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.afCancelRequest()
    }
}

// MARK: - Class

class CategoryChildrenPickerViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var tableView : UITableView!
    
    // Predefined values
    var root : UIViewController?
    var parentJson : JSON = JSON(["name":""])
    var blockDone : BlockCategorySelected?
    var backTreshold = 1
    var searchMode = false
    var categoryImageName : String = ""
    var categoryLv1Id : String = ""
    
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
        if let name = parentJson["name"].string {
            self.title = name.capitalized
        } else {
            self.title = "Pilih Kategori"
        }
        
        // Get children categories
        if let children = parentJson["children"].arrayObject {
            for o in children {
                categories.append(JSON(o))
            }
        }
        
        // Include parent category itself for searchMode
        if (searchMode) {
            var parentCateg = parentJson
            parentCateg["name"] = JSON("Semua " + parentJson["name"].stringValue)
            categories.insert(parentCateg, at: 0)
        }
        
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.reloadData()
    }
    
    // MARK: - Table view functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var c = tableView.dequeueReusableCell(withIdentifier: "cell")
        if (c == nil) {
            c = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        }
        
        let j = categories[(indexPath as NSIndexPath).row]
        if let name = j["name"].string {
            c?.textLabel!.text = name
        }
        
        return c!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Get level 2 category name (used for add product page)
        selectedCategory = categories[(indexPath as NSIndexPath).row]
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
        if (!(searchMode && (indexPath as NSIndexPath).row == 0) && childCount > 0) {
            let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdCategoryChildrenPicker) as! CategoryChildrenPickerViewController
            p.parentJson = selectedCategory!
            p.blockDone = self.blockDone
            p.backTreshold = backTreshold + 1
            p.searchMode = self.searchMode
            p.root = root
            p.categoryImageName = self.categoryImageName
            p.categoryLv1Id = self.categoryLv1Id
            p.categoryLv2Name = self.categoryLv2Name
            p.delegate = self.delegate
            p.previousController = self.previousController
            self.navigationController?.pushViewController(p, animated: true)
        } else {
            let data = [
                "parent":parentJson.rawValue,
                "child":selectedCategory!.rawValue,
                "category_image_name":self.categoryImageName,
                "category_level1_id":self.categoryLv1Id,
                "category_level2_name":self.categoryLv2Name
            ] as [String : Any]
            if (searchMode) {
                if (self.previousController != nil) {
                    self.delegate?.adjustCategory(selectedCategory!["_id"].stringValue)
                    self.navigationController?.popToViewController(self.previousController!, animated: true)
                } else {
                    let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                    l.currentMode = .filter
                    l.isBackToFltrSearch = true
                    l.fltrCategId = selectedCategory!["_id"].stringValue
                    l.fltrSortBy = "recent"
                    l.previousScreen = PageName.Search
                    self.navigationController?.pushViewController(l, animated: true)
                }
            } else {
                self.blockDone!(data as [String : AnyObject])
                
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
