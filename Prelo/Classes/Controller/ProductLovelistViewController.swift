//
//  ProductLovelistViewController.swift
//  Prelo
//
//  Created by PreloBook on 12/9/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
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
        
        // Refresh table for the first time
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
                self.lblPrice.text = "Rp" + data["price"].stringValue
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
                self.navigationController?.popViewController(animated: true)
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
        cell.chatPressed = {
            self.tblLovers.isHidden = true
            
            var productId = self.productId
            var buyer = self.productLovelistItems[indexPath.row]
            
            // Get product detail from API
            let _ = request(APIProduct.detail(productId: productId, forEdit: 0)).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hubungi Pembeli")) {
                    let json = JSON(resp.result.value!)
                    if let pDetail = ProductDetail.instance(json) {
                        // Goto chat
                        let t = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdTawar) as! TawarViewController
                    
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
                                    self.navigationController?.pushViewController(t, animated: true)
                                }
                            }
                        }
                    }
                } else {
                    Constant.showDialog("Product Lovelist", message: "Oops, terdapat kesalahan saat mengakses detail produk")
                }
                self.tblLovers.isHidden = false
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tblLovers.isHidden = true
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let listItemVC = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        listItemVC.currentMode = .shop
        listItemVC.shopId = self.productLovelistItems[indexPath.row].id
        self.navigationController?.pushViewController(listItemVC, animated: true)
    }
    
    // MARK: - Other functions
}

// MARK: - Class

class ProductLovelistCell : UITableViewCell {
    
    // MARK: - Properties
    
    @IBOutlet var imgUser: UIImageView!
    @IBOutlet var lblName: UILabel!
    
    var chatPressed : () -> () = {}
    
    // MARK: - Methods
    
    func adapt(productLovelistItem : ProductLovelistItem) {
        if let url = productLovelistItem.imageURL {
            imgUser.afSetImage(withURL: url)
            imgUser.layer.cornerRadius = (imgUser.frame.size.width) / 2
        }
        lblName.text = productLovelistItem.username
    }
    
    @IBAction func chatPressed(_ sender: AnyObject) {
        self.chatPressed()
    }
}
