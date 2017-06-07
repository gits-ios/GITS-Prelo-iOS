//
//  CategoryPreferencesViewController.swift
//  Prelo
//
//  Created by Fransiska Hadiwidjana on 11/10/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class CategoryPreferencesViewController : BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collcCategory: UICollectionView!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var categories : [CDCategory] = []
    var selectedIds : [String] = []
    
    var parentVC : BaseViewController?
    
    var isUseCategoriesOffline = false
    var categoriesOffline : [[String : String]] = []
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register custom cell
        let categoryPrefCellNib = UINib(nibName: "CategoryPreferencesCell", bundle: nil)
        collcCategory.register(categoryPrefCellNib, forCellWithReuseIdentifier: "CategoryPreferencesCell")
        
        // Sembunyikan tombol back
        self.navigationItem.hidesBackButton = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.loadingPanel.isHidden = false
        self.loading.startAnimating()
        self.collcCategory.isHidden = true

        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.SetCategoryPreferences)
        
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
        self.loadingPanel.isHidden = true
        self.loading.stopAnimating()
        self.collcCategory.isHidden = false
    }
    
    func setupCollection() {
        if (self.collcCategory.delegate == nil) {
            self.collcCategory.dataSource = self
            self.collcCategory.delegate = self
        }
    
        collcCategory.reloadData()
    }
    
    // MARK: - IBActions
    
    @IBAction func submitPressed(_ sender: AnyObject) {
        if (selectedIds.count < 3) {
            Constant.showDialog("Warning", message: "Pilih 3 kategori favorit kamu")
        } else {
            // Store to userdefaults one by one lol
            UserDefaults.standard.set(selectedIds[0], forKey: UserDefaultsKey.CategoryPref1)
            UserDefaults.standard.set(selectedIds[1], forKey: UserDefaultsKey.CategoryPref2)
            UserDefaults.standard.set(selectedIds[2], forKey: UserDefaultsKey.CategoryPref3)
            UserDefaults.standard.synchronize()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func skipPressed(_ sender: AnyObject) {
        // To login
        self.dismiss(animated: true, completion: nil)
        LoginViewController.Show(self.parentVC!, userRelatedDelegate: self.parentVC as! KumangTabBarViewController, animated: true, isFromTourVC: true)
    }
    
    // MARK: - UICollectionViewDataSource Functions
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (isUseCategoriesOffline) {
            return categoriesOffline.count
        } else {
            return categories.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell : CategoryPreferencesCell = self.collcCategory.dequeueReusableCell(withReuseIdentifier: "CategoryPreferencesCell", for: indexPath) as! CategoryPreferencesCell
        if (isUseCategoriesOffline) {
            cell.adapt2(categoriesOffline[(indexPath as NSIndexPath).item], selectedIds: self.selectedIds)
        } else {
            cell.adapt(categories[(indexPath as NSIndexPath).item], selectedIds: self.selectedIds)
        }
        return cell
    }
    
    // MARK: - UICollectionViewDelegate Functions
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CategoryPreferencesCell
        var priority : Int?
        if (isUseCategoriesOffline) {
			priority = self.selectedIds.index(of: categoriesOffline[(indexPath as NSIndexPath).item]["id"]!)
        } else {
			priority = self.selectedIds.index(of: categories[(indexPath as NSIndexPath).item].id)
        }
        if (priority != nil) { // Sedang terpilih
            selectedIds.remove(at: priority!)
            //print("selectedIds = \(selectedIds)")
            self.setupCollection()
        } else { // Sedang tidak terpilih
            if (self.selectedIds.count < 3) {
                self.selectedIds.append(cell.categoryId)
                //print("selectedIds = \(selectedIds)")
                cell.lblPriority.text = "\(self.selectedIds.count)"
                cell.lblPriority.isHidden = false
                cell.imgCategory.isHidden = true
            }
        }
    }
    
    // MARK: - Other functions
    
    func retrieveOfflineCategories() {
        self.isUseCategoriesOffline = true
        let category1 = [
            "id" : "55de6dbc5f6522562a2c73ef",
            "name" : "Women",
            "imageName" : "http://dev.prelo.id/images/categories/fashion-wanita2.png"
        ]
        let category2 = [
            "id" : "55de6dbc5f6522562a2c73f0",
            "name" : "Men",
            "imageName" : "http://dev.prelo.id/images/categories/fashion-pria2.png"
        ]
        let category3 = [
            "id" : "55fbbca14ef9139b408b4569",
            "name" : "Beauty",
            "imageName" : "http://dev.prelo.id/images/categories/beauty2.png"
        ]
        let category4 = [
            "id" : "55de6dbc5f6522562a2c73f1",
            "name" : "Gadget",
            "imageName" : "http://dev.prelo.id/images/categories/elektronik2.png"
        ]
        let category5 = [
            "id" : "55de6dbc5f6522562a2c73f2",
            "name" : "Hobby",
            "imageName" : "http://dev.prelo.id/images/categories/hobi2.png"
        ]
        let category6 = [
            "id" : "55fbbd0d4ef9139b408b456a",
            "name" : "Sport",
            "imageName" : "http://dev.prelo.id/images/categories/sport2.png"
        ]
        let category7 = [
            "id" : "55de6dbc5f6522562a2c73f3",
            "name" : "Book",
            "imageName" : "http://dev.prelo.id/images/categories/buku2.png"
        ]
        let category8 = [
            "id" : "55de6dbc5f6522562a2c73f4",
            "name" : "Baby & Kid",
            "imageName" : "http://dev.prelo.id/images/categories/baby-kid2.png"
        ]
        categoriesOffline.append(category1)
        categoriesOffline.append(category2)
        categoriesOffline.append(category3)
        categoriesOffline.append(category4)
        categoriesOffline.append(category5)
        categoriesOffline.append(category6)
        categoriesOffline.append(category7)
        categoriesOffline.append(category8)
    }
}

class CategoryPreferencesCell : UICollectionViewCell {
    
    @IBOutlet weak var imgCategory: UIImageView!
    @IBOutlet weak var lblCategoryName: UILabel!
    @IBOutlet weak var lblPriority: UILabel!
    
    var categoryId : String!
    
    func adapt(_ category : CDCategory, selectedIds : [String]) {
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
        
        let priority : Int? = selectedIds.index(of: categoryId)
        if (priority != nil) {
            lblPriority.text = "\(priority! + 1)"
            lblPriority.isHidden = false
            imgCategory.isHidden = true
        } else {
            lblPriority.isHidden = true
            imgCategory.isHidden = false
            let url = URL(string: category.imageName)!
            let urlReq = Foundation.URLRequest(url: url)
            imgCategory.setImageWithUrlRequest(urlReq, placeHolderImage: nil, success: {(_, _, img: UIImage!, _) -> Void in
                self.imgCategory.image = img.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                self.imgCategory.tintColor = UIColor.white
                }, failure: { (_, _, err) -> Void in
                    //print("Show category image err: \(err)")
            })
        }
    }
    
    func adapt2(_ category : [String : String], selectedIds : [String]) {
        categoryId = category["id"]
        
        lblCategoryName.text = category["name"]
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
        
        let priority : Int? = selectedIds.index(of: categoryId)
        if (priority != nil) {
            lblPriority.text = "\(priority! + 1)"
            lblPriority.isHidden = false
            imgCategory.isHidden = true
        } else {
            lblPriority.isHidden = true
            imgCategory.isHidden = false
            let url = URL(string: category["imageName"]!)!
            let urlReq = Foundation.URLRequest(url: url)
            imgCategory.setImageWithUrlRequest(urlReq, placeHolderImage: nil, success: {(_, _, img: UIImage!, _) -> Void in
                self.imgCategory.image = img.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                self.imgCategory.tintColor = UIColor.white
                }, failure: { (_, _, err) -> Void in
                    //print("Show category image err: \(err)")
            })
        }
    }
}
