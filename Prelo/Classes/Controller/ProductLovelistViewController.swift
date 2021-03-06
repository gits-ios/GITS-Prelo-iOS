//
//  ProductLovelistViewController.swift
//  Prelo
//
//  Created by PreloBook on 12/9/16.
//  Copyright © 2016 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class

class ProductLovelistViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    
    // View related
    @IBOutlet var imgProduct: UIImageView!
    @IBOutlet var lblProductName: UILabel!
    @IBOutlet var lblPrice: UILabel!
    @IBOutlet var lblTime: UILabel!
    @IBOutlet var tblLovers: UITableView!
    var refreshControl : UIRefreshControl!
    
    @IBOutlet weak var loadingPanel: UIView!
    
    
    // Data container
    var productLovelistItems : [ProductLovelistItem] = []
    
    // Predefined values
    var productId : String = ""
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        // Menghilangkan garis antar cell di baris kosong
        tblLovers.tableFooterView = UIView()
        
        // Register custom cell
        let productLovelistCellNib = UINib(nibName: "ProductLovelistCell", bundle: nil)
        tblLovers.register(productLovelistCellNib, forCellReuseIdentifier: "ProductLovelistCell")

//         Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(ProductLovelistViewController.refreshTable), for: UIControlEvents.valueChanged)
        self.tblLovers.addSubview(refreshControl)
        
        // Set title
//        self.title = "Product Lovelist"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ProductLovelist)
        
//        // Refresh table for the first time
//        self.refreshTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshTable()
    }
    
    func refreshTable() {
        self.tblLovers.isHidden = true
        self.productLovelistItems = []
        self.getProducts()
    }
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    func getProducts() {
        showLoading()
        _ = request(APIProduct.getProductLovelist(productId: productId)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Product Lovelist")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                // Store data into variables
                self.lblProductName.text = data["name"].stringValue
                self.lblPrice.text = (data["price"].stringValue).int.asPrice
                if let urlString = data["display_picts"][0].string {
                    if let url = URL(string: urlString) {
                        self.imgProduct.afSetImage(withURL: url)
                    }
                }
                for (_, item) in data["lovers"] {
                    let p = ProductLovelistItem.instance(item)
                    if (p != nil) {
                        self.productLovelistItems.append(p!)
                    }
                }
                
                // Set title
                self.title = data["name"].stringValue
                self.hideLoading()

            } else {
                // back to previous UI
                _ = self.navigationController?.popViewController(animated: true)
            }
            
            // Hide refresh control
            self.refreshControl.endRefreshing()
            self.hideLoading()
            
            // Setup table
            if (self.productLovelistItems.count > 0) {
                self.tblLovers.isHidden = false
                if (self.tblLovers.delegate == nil) {
                    self.tblLovers.dataSource = self
                    self.tblLovers.delegate = self
                }
                self.tblLovers.reloadData()
            }
        }
    }
    
    // MARK: - Tableview functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productLovelistItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 71
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ProductLovelistCell = self.tblLovers.dequeueReusableCell(withIdentifier: "ProductLovelistCell") as! ProductLovelistCell
        cell.adapt(productLovelistItem: productLovelistItems[indexPath.row])
        
        cell.selectionStyle = .none
        cell.alpha = 1.0
        cell.backgroundColor = UIColor.white
        
        cell.chatPressed = {
//            self.tblLovers.isHidden = true
            self.showLoading()
            
            let productId = self.productId
            let buyer = self.productLovelistItems[indexPath.row]
            
            // Get product detail from API
            let _ = request(APIProduct.detail(productId: productId, forEdit: 0)).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hubungi Pembeli")) {
                    let json = JSON(resp.result.value!)
                    if let pDetail = ProductDetail.instance(json) {
                        // Goto chat
                        let t = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdTawar) as! TawarViewController
                        t.previousScreen = PageName.ProductLovelist
                        
                        t.isSellerNotActive = pDetail.IsShopClosed
                        t.phoneNumber = pDetail.SellerPhone
                    
                        // API Migrasi
                        let _ = request(APIInbox.getInboxByProductIDSeller(productId: pDetail.productID, buyerId: buyer.id)).responseJSON {resp in
                            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hubungi Pembeli")) {
                                let json = JSON(resp.result.value!)
                                if (json["_data"]["_id"].stringValue != "") { // Sudah pernah chat
                                    t.tawarItem = Inbox(jsn: json["_data"])
                                    self.navigationController?.pushViewController(t, animated: true)
                                } else { // Belum pernah chat
                                    
                                    pDetail.buyerId = buyer.id
                                    pDetail.buyerName = buyer.username
                                    pDetail.buyerImage = (buyer.imageURL?.absoluteString)!
                                    pDetail.reverse()
                                        
                                    t.tawarItem = pDetail
                                    t.fromSeller = true
                                    
                                    t.toId = buyer.id
                                    t.prodId = t.tawarItem.itemId
                                    
                                    // disable // enable auto tawarkan
                                    t.isTawarkan = false //true
                                    t.isTawarkan_originalPrice = pDetail.priceInt.string
                                    t.tawarFromMe = true
                                    t.threadState = 0 //1
                                    
                                    self.navigationController?.pushViewController(t, animated: true)
                                    self.hideLoading()
                                }
                            }
                        }
                    }
                } else {
                    Constant.showDialog("Product Lovelist", message: "Oops, terdapat kesalahan saat mengakses detail produk")
                    self.hideLoading()
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        self.tblLovers.isHidden = true
        if (!AppTools.isNewShop) {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let listItemVC = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            listItemVC.currentMode = .shop
            listItemVC.shopId = self.productLovelistItems[indexPath.row].id
            listItemVC.previousScreen = PageName.ProductLovelist
            self.navigationController?.pushViewController(listItemVC, animated: true)
        } else {
            let storePageTabBarVC = Bundle.main.loadNibNamed(Tags.XibNameStorePage, owner: nil, options: nil)?.first as! StorePageTabBarViewController
            storePageTabBarVC.shopId = self.productLovelistItems[indexPath.row].id
            storePageTabBarVC.previousScreen = PageName.ProductLovelist
            self.navigationController?.pushViewController(storePageTabBarVC, animated: true)
        }
    }
    
    // MARK: - Other functions
    
    @IBAction func gotoProduct(_ sender: AnyObject) {
        self.showLoading()
        let _ = request(APIProduct.detail(productId: productId, forEdit: 0)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Barang")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                let p = Product.instance(data)
                let productDetailVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                productDetailVC.product = p!
                productDetailVC.previousScreen = PageName.InboxDetail
                self.navigationController?.pushViewController(productDetailVC, animated: true)
                self.hideLoading()
            }
        }
    }
}

// MARK: - Class

class ProductLovelistCell : UITableViewCell {
    
    // MARK: - Properties
    
    @IBOutlet var imgUser: UIImageView!
    @IBOutlet var lblName: UILabel!
    
    var chatPressed : () -> () = {}
    
    // MARK: - Methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imgUser.afCancelRequest()
    }
    
    func adapt(productLovelistItem : ProductLovelistItem) {
        if let url = productLovelistItem.imageURL {
            imgUser.afSetImage(withURL: url, withFilter: .circle)
            imgUser.layer.cornerRadius = (imgUser.frame.size.width) / 2
            
            imgUser.layer.borderColor = Theme.GrayLight.cgColor
            imgUser.layer.borderWidth = 2
        }
        lblName.text = productLovelistItem.username
    }
    
    @IBAction func chatPressed(_ sender: AnyObject) {
        self.chatPressed()
    }
}
