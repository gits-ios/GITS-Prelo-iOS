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
        let categoryPrefCellNib = UINib(nibName: "CategoryPreferencesCell", bundle: nil)
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

        // Mixpanel
        Mixpanel.trackPageVisit(PageName.SetCategoryPreferences)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.SetCategoryPreferences)
        
        // Get categories
        categories = CDCategory.getCategoriesInLevel(1)
        
        // Jaga2 kalo ternyata gagal dapet kategori
        if (categories.count < 4) {
            self.retrieveOfflineCategories()
        }
        
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
        let cell : CategoryPreferencesCell = self.collcCategory.dequeueReusableCellWithReuseIdentifier("CategoryPreferencesCell", forIndexPath: indexPath) as! CategoryPreferencesCell
        cell.adapt(categories[indexPath.item], selectedIds: self.selectedIds)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate Functions
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CategoryPreferencesCell
        let priority : Int? = self.selectedIds.indexOf(categories[indexPath.item].id)
        if (priority != nil) { // Sedang terpilih
            selectedIds.removeAtIndex(priority!)
            print("selectedIds = \(selectedIds)")
            self.setupCollection()
        } else { // Sedang tidak terpilih
            if (self.selectedIds.count < 3) {
                self.selectedIds.append(cell.categoryId)
                print("selectedIds = \(selectedIds)")
                cell.lblPriority.text = "\(self.selectedIds.count)"
                cell.lblPriority.hidden = false
                cell.imgCategory.hidden = true
            }
        }
    }
    
    // MARK: - Other functions
    
    func retrieveOfflineCategories() {
        categories = []
        let category1 = CDCategory()
        category1.id = "55de6dbc5f6522562a2c73ef"
        category1.name = "Women"
        category1.imageName = "http://dev.prelo.id/images/categories/fashion-wanita2.png"
        categories.append(category1)
        let category2 = CDCategory()
        category2.id = "55de6dbc5f6522562a2c73f0"
        category2.name = "Men"
        category2.imageName = "http://dev.prelo.id/images/categories/fashion-pria2.png"
        categories.append(category2)
        let category3 = CDCategory()
        category3.id = "55fbbca14ef9139b408b4569"
        category3.name = "Beauty"
        category3.imageName = "http://dev.prelo.id/images/categories/beauty2.png"
        categories.append(category3)
        let category4 = CDCategory()
        category4.id = "55de6dbc5f6522562a2c73f1"
        category4.name = "Gadget"
        category4.imageName = "http://dev.prelo.id/images/categories/elektronik2.png"
        categories.append(category4)
        let category5 = CDCategory()
        category5.id = "55de6dbc5f6522562a2c73f2"
        category5.name = "Hobby"
        category5.imageName = "http://dev.prelo.id/images/categories/hobi2.png"
        categories.append(category5)
        let category6 = CDCategory()
        category6.id = "55fbbd0d4ef9139b408b456a"
        category6.name = "Sport"
        category6.imageName = "http://dev.prelo.id/images/categories/sport2.png"
        categories.append(category6)
        let category7 = CDCategory()
        category7.id = "55de6dbc5f6522562a2c73f3"
        category7.name = "Book"
        category7.imageName = "http://dev.prelo.id/images/categories/buku2.png"
        categories.append(category7)
        let category8 = CDCategory()
        category8.id = "55de6dbc5f6522562a2c73f4"
        category8.name = "Baby & Kid"
        category8.imageName = "http://dev.prelo.id/images/categories/baby-kid2.png"
        categories.append(category8)
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
        
        let priority : Int? = selectedIds.indexOf(categoryId)
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
                    print("Show category image err: \(err)")
            })
        }
    }
}