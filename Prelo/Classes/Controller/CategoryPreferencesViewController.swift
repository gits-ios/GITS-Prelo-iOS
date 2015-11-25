//
//  CategoryPreferencesViewController.swift
//  Prelo
//
//  Created by Fransiska Hadiwidjana on 11/10/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class CategoryPreferencesViewController : BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collcCategory: UICollectionView!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var categories : [CDCategory] = []
    var selectedIds : [String] = []
    
    var parent : BaseViewController?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register custom cell
        var categoryPrefCellNib = UINib(nibName: "CategoryPreferencesCell", bundle: nil)
        collcCategory.registerNib(categoryPrefCellNib, forCellWithReuseIdentifier: "CategoryPreferencesCell")
        
        // Sembunyikan tombol back
        self.navigationItem.hidesBackButton = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        self.loadingPanel.hidden = false
        self.loading.startAnimating()
        self.collcCategory.hidden = true

        Mixpanel.trackPageVisit("Set Category Preferences")
        
        while (!NSUserDefaults.isCategorySaved()) {
            // Wait until category is saved
            println("Still saving category...")
        }
        
        // Get categories
        categories = CDCategory.getCategoriesInLevel(1)
        
        // Setup table
        self.setupCollection()
        
        // Show collection
        self.loadingPanel.hidden = true
        self.loading.stopAnimating()
        self.collcCategory.hidden = false
    }
    
    func setupCollection() {
        if (self.collcCategory.delegate == nil) {
            self.collcCategory.dataSource = self
            self.collcCategory.delegate = self
        }
    
        collcCategory.reloadData()
    }
    
    // MARK: - IBActions
    
    @IBAction func submitPressed(sender: AnyObject) {
        if (selectedIds.count < 3) {
            Constant.showDialog("Warning", message: "Pilih 3 kategori favorit kamu")
        } else {
            // Store to userdefaults one by one lol
            NSUserDefaults.standardUserDefaults().setObject(selectedIds[0], forKey: UserDefaultsKey.CategoryPref1)
            NSUserDefaults.standardUserDefaults().setObject(selectedIds[1], forKey: UserDefaultsKey.CategoryPref2)
            NSUserDefaults.standardUserDefaults().setObject(selectedIds[2], forKey: UserDefaultsKey.CategoryPref3)
            NSUserDefaults.standardUserDefaults().synchronize()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func skipPressed(sender: AnyObject) {
        // To login
        self.dismissViewControllerAnimated(true, completion: nil)
        LoginViewController.Show(self.parent!, userRelatedDelegate: self.parent as! KumangTabBarViewController, animated: true, isFromTourVC: true)
    }
    
    // MARK: - UICollectionViewDataSource Functions
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell : CategoryPreferencesCell = self.collcCategory.dequeueReusableCellWithReuseIdentifier("CategoryPreferencesCell", forIndexPath: indexPath) as! CategoryPreferencesCell
        cell.adapt(categories[indexPath.item], selectedIds: self.selectedIds)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate Functions
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var cell = collectionView.cellForItemAtIndexPath(indexPath) as! CategoryPreferencesCell
        let priority : Int? = find(self.selectedIds, categories[indexPath.item].id)
        if (priority != nil) { // Sedang terpilih
            selectedIds.removeAtIndex(priority!)
            println("selectedIds = \(selectedIds)")
            self.setupCollection()
        } else { // Sedang tidak terpilih
            if (self.selectedIds.count < 3) {
                self.selectedIds.append(cell.categoryId)
                println("selectedIds = \(selectedIds)")
                cell.lblPriority.text = "\(self.selectedIds.count)"
                cell.lblPriority.hidden = false
                cell.imgCategory.hidden = true
            }
        }
    }
}

class CategoryPreferencesCell : UICollectionViewCell {
    
    @IBOutlet weak var imgCategory: UIImageView!
    @IBOutlet weak var lblCategoryName: UILabel!
    @IBOutlet weak var lblPriority: UILabel!
    
    var categoryId : String!
    
    func adapt(category : CDCategory, selectedIds : [String]) {
        categoryId = category.id
        
        lblCategoryName.text = category.name
        // Manual fixing
        if (lblCategoryName.text == "Men") {
            lblCategoryName.text = "Men Fashion"
        } else if (lblCategoryName.text == "Women") {
            lblCategoryName.text = "Women Fashion"
        } else if (lblCategoryName.text == "Beauty") {
            lblCategoryName.text = "Beauty & Grooming"
        } else if (lblCategoryName.text == "Sports") {
            lblCategoryName.text = "Sports & Outdoors"
        } else if (lblCategoryName.text == "Baby & Kid") {
            lblCategoryName.text = "Baby & Kids"
        }
        
        let priority : Int? = find(selectedIds, categoryId)
        if (priority != nil) {
            lblPriority.text = "\(priority! + 1)"
            lblPriority.hidden = false
            imgCategory.hidden = true
        } else {
            lblPriority.hidden = true
            imgCategory.hidden = false
            let url = NSURL(string: category.imageName)!
            let urlReq = NSURLRequest(URL: url)
            imgCategory.setImageWithUrlRequest(urlReq, placeHolderImage: nil, success: {(_, _, img: UIImage!, _) -> Void in
                self.imgCategory.image = img.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                self.imgCategory.tintColor = UIColor.whiteColor()
                }, failure: { (_, _, err) -> Void in
                    println("Show category image err: \(err)")
            })
        }
    }
}