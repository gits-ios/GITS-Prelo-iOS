//
//  ProductCompareViewController.swift
//  Prelo
//
//  Created by PreloBook on 10/26/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Struct

struct CategoryBreadcrumb {
    var id : String = ""
    var name : String = ""
}

// MARK: - Class

class ProductCompareViewController : BaseViewController, UITableViewDelegate, UITableViewDataSource, ProductCompareMainCellDelegate {
    
    // MARK: - Properties
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingPanel: UIView!
    @IBOutlet var bottomLoadingPanel: UIView!
    
    var refreshControl : UIRefreshControl!
    var nextIdx : Int = 0
    let ItemPerLoad : Int = 10
    var isAllItemLoaded : Bool = false
    
    var aggregateId : String = "55e02ef426cee06d1700016c"
    
    var productCompareMain : ProductCompareMain = ProductCompareMain()
    var productCompareItems : [Product] = []
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let productCompareMainCellNib = UINib(nibName: "ProductCompareMainCell", bundle: nil)
        tableView.register(productCompareMainCellNib, forCellReuseIdentifier: "ProductCompareMainCell")
        let productCompareCellNib = UINib(nibName: "ProductCompareCell", bundle: nil)
        tableView.register(productCompareCellNib, forCellReuseIdentifier: "ProductCompareCell")
        
        // Loading
        self.showLoading()
        self.hideBottomLoading()
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(ProductCompareViewController.refreshTable), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Set title
        self.title = "Daftar Penawaran"
        
        // Refresh table for the first time
        self.refreshTable()
    }
    
    func refreshTable() {
        // Reset data
        self.productCompareMain = ProductCompareMain()
        self.productCompareItems = []
        self.nextIdx = 0
        self.isAllItemLoaded = false
        self.showLoading()
        
        self.getProducts()
    }
    
    func getProducts() {
        _ = request(APIProduct.getProductAggregatePage(aggregateId: self.aggregateId, current: self.nextIdx, limit: (nextIdx + ItemPerLoad))).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Penawaran")) {
                let json = JSON(resp.result.value!)
                self.productCompareMain = ProductCompareMain.instance(json["_data"])!
                let data = json["_data"]["products"]
                let dataCount = data.count
                
                // Store data into variable
                for (_, item) in data {
                    let p = Product.instance(item)
                    if (p != nil) {
                        self.productCompareItems.append(p!)
                    }
                }
                
                // Check if all data are already loaded
                if (dataCount < self.ItemPerLoad) {
                    self.isAllItemLoaded = true
                }
                
                // Set next index
                self.nextIdx += dataCount
            }
            
            // Hide loading (for first time request)
            self.hideLoading()
            
            // Hide bottomLoading (for next request)
            self.hideBottomLoading()
            
            // Hide refreshControl (for refreshing)
            self.refreshControl.endRefreshing()
            
            // Show content
            self.showContent()
        }
    }
    
    // MARK: - UITableView functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + productCompareItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 0) { // Main cell
            return 125
        }
        
        // Product cell
        return 71
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0) { // Main cell
            let cell : ProductCompareMainCell = self.tableView.dequeueReusableCell(withIdentifier: "ProductCompareMainCell") as! ProductCompareMainCell
            cell.adapt(productCompareMain: productCompareMain)
            cell.selectionStyle = .none
            cell.mainCellDelegate = self
            return cell
        }
        
        // Product cell
        let cell : ProductCompareCell = self.tableView.dequeueReusableCell(withIdentifier: "ProductCompareCell") as! ProductCompareCell
        cell.adapt(productCompareItem: productCompareItems[indexPath.row - 1])
        cell.selectionStyle = .none
        cell.buyPressed = {
            var success = true
            if (CartProduct.getOne(self.productCompareItems[indexPath.row - 1].id, email: User.EmailOrEmptyString) == nil) {
                if (CartProduct.newOne(self.productCompareItems[indexPath.row - 1].id, email : User.EmailOrEmptyString, name : self.productCompareItems[indexPath.row - 1].name) == nil) {
                    success = false
                    Constant.showDialog("Failed", message: "Gagal Menyimpan")
                }
            }
            
            if (success) {
                let c = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdCart) as! BaseViewController
                self.navigationController?.pushViewController(c, animated: true)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row > 0) { // Product cell
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NotificationName.ShowProduct), object: productCompareItems[indexPath.row - 1])
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset : CGPoint = scrollView.contentOffset
        let bounds : CGRect = scrollView.bounds
        let size : CGSize = scrollView.contentSize
        let inset : UIEdgeInsets = scrollView.contentInset
        let y : CGFloat = offset.y + bounds.size.height - inset.bottom
        let h : CGFloat = size.height
        
        let reloadDistance : CGFloat = 0
        if (y > h + reloadDistance) {
            // Load next items only if all items not loaded yet and if its not currently loading items
            if (!self.isAllItemLoaded && self.bottomLoadingPanel.isHidden) {
                // Show bottomLoading
                self.showBottomLoading()
                
                // Get products
                self.getProducts()
            }
        }
    }
    
    // MARK: - Main cell delegate
    
    func categoryPressed(_ categoryName: String, categoryID: String) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let l = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        l.currentMode = .filter
        l.fltrCategId = categoryID
        l.fltrSortBy = "recent"
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    func brandPressed(_ brandId: String, brandName: String) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let l = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        l.currentMode = .filter
        l.fltrSortBy = "recent"
        l.fltrBrands = [brandName : brandId]
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    func showBottomLoading() {
        self.bottomLoadingPanel.isHidden = false
    }
    
    func hideBottomLoading() {
        self.bottomLoadingPanel.isHidden = true
    }
    
    func showContent() {
        if (self.productCompareItems.count <= 0) {
            self.tableView.isHidden = true
        } else {
            self.tableView.isHidden = false
            self.setupTable()
        }
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
}

// MARK: - Protocol

protocol ProductCompareMainCellDelegate {
    func categoryPressed(_ categoryName : String, categoryID : String)
    func brandPressed(_ brandId : String, brandName : String)
}

// MARK: - Class

class ProductCompareMainCell : UITableViewCell, ZSWTappableLabelTapDelegate {
    
    // MARK: - Properties
    
    @IBOutlet var imgProduct: UIImageView!
    @IBOutlet var lblProductName: UILabel!
    @IBOutlet var lblCategory: ZSWTappableLabel!
    @IBOutlet var lblBrand: ZSWTappableLabel!
    @IBOutlet var lblProductCount: UILabel!
    
    var mainCellDelegate : ProductCompareMainCellDelegate?
    
    // MARK: - Methods
    
    override func awakeFromNib() {
        lblCategory.tapDelegate = self
        lblBrand.tapDelegate = self
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imgProduct.afCancelRequest()
    }
    
    func adapt(productCompareMain : ProductCompareMain) {
        if let url = productCompareMain.imageURL {
            imgProduct.afSetImage(withURL: url)
        }
        lblProductName.text = productCompareMain.name
        lblProductCount.text = "\(productCompareMain.numProducts) penawaran"
        
        // Brand label
        if (!productCompareMain.brandName.isEmpty) {
            let p = [
                "brand_id" : productCompareMain.brandId,
                "brand" : productCompareMain.brandName,
                "range" : NSStringFromRange(NSMakeRange(0, productCompareMain.brandName.length)),
                ZSWTappableLabelTappableRegionAttributeName: Int(true),
                ZSWTappableLabelHighlightedBackgroundAttributeName : UIColor.darkGray,
                ZSWTappableLabelHighlightedForegroundAttributeName : UIColor.white,
                NSForegroundColorAttributeName : Theme.PrimaryColorDark
            ] as [String : Any]
            lblBrand.attributedText = NSAttributedString(string: productCompareMain.brandName, attributes: p)
        } else {
            lblBrand.text = "Unknown"
        }
        
        // Category label
        let arr = productCompareMain.categoryBreadcrumbs
        var categString : String = ""
        var param : Array<[String : Any]> = []
        if (arr.count > 0) {
            for i in 0..<arr.count {
                let p = [
                    "category_name" : arr[i].name,
                    "category_id" : arr[i].id,
                    "range" : NSStringFromRange(NSMakeRange(categString.length, arr[i].name.length)),
                    ZSWTappableLabelTappableRegionAttributeName : Int(true),
                    ZSWTappableLabelHighlightedBackgroundAttributeName : UIColor.darkGray,
                    ZSWTappableLabelHighlightedForegroundAttributeName : UIColor.white,
                    NSForegroundColorAttributeName : Theme.PrimaryColorDark
                ] as [String : Any]
                param.append(p)
                
                categString += arr[i].name
                if (i != arr.count - 1) {
                    categString += " > "
                }
            }
        }
        let attrStr : NSMutableAttributedString = NSMutableAttributedString(string: categString)
        for p in param {
            let r = NSRangeFromString(p["range"] as! String)
            attrStr.addAttributes(p, range: r)
        }
        lblCategory.attributedText = attrStr
    }
    
    func tappableLabel(_ tappableLabel: ZSWTappableLabel!, tappedAt idx: Int, withAttributes attributes: [AnyHashable : Any]! = [:]) {
        if (mainCellDelegate != nil) {
            if let brandName = attributes["brand"] as? String { // Brand tapped
                let brandID = attributes["brand_id"] as! String
                mainCellDelegate!.brandPressed(brandID, brandName: brandName)
            } else { // Category tapped
                let categName = attributes["category_name"] as! String
                let categID = attributes["category_id"] as! String
                mainCellDelegate!.categoryPressed(categName, categoryID: categID)
            }
        }
    }
}

// MARK: - Class

class ProductCompareCell : UITableViewCell {
    
    // MARK: - Properties
    
    @IBOutlet var imgProduct: UIImageView!
    @IBOutlet var lblPrice: UILabel!
    @IBOutlet var lblProductName: UILabel!
    
    var buyPressed : () -> () = {}
    
    // MARK: - Methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imgProduct.afCancelRequest()
    }
    
    func adapt(productCompareItem : Product) {
        if let url = productCompareItem.coverImageURL {
            imgProduct.afSetImage(withURL: url)
        }
        lblPrice.text = productCompareItem.price
        lblProductName.text = productCompareItem.name
    }
    
    @IBAction func beliPressed(_ sender: AnyObject) {
        self.buyPressed()
    }
}
