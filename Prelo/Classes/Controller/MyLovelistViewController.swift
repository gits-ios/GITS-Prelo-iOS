//
//  MyLovelistViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/23/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MyLovelistViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, MyLovelistCellDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var viewJualButton: UIView!
    
    var userLovelist : Array <LovedProduct>?
    var selectedProduct : Product?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let myLovelistCellNib = UINib(nibName: "MyLovelistCell", bundle: nil)
        tableView.register(myLovelistCellNib, forCellReuseIdentifier: "MyLovelistCell")
        
        // Set title
        self.title = PageName.Lovelist
        
        // Buat tombol jual menjadi bentuk bulat dan selalu di depan
        viewJualButton.layoutIfNeeded()
        viewJualButton.layer.cornerRadius = (viewJualButton.frame.size.width) / 2
        viewJualButton.layer.shadowColor = UIColor.black.cgColor
        viewJualButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewJualButton.layer.shadowOpacity = 0.3
        viewJualButton.layer.zPosition = CGFloat.greatestFiniteMagnitude;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        loadingPanel.isHidden = false
        loading.startAnimating()
        tableView.isHidden = true
        lblEmpty.isHidden = true
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.Lovelist)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Lovelist)
        
        if (userLovelist?.count == 0 || userLovelist == nil) {
            if (userLovelist == nil) {
                userLovelist = []
            }
            getUserLovelist()
        } else {
            self.loadingPanel.isHidden = true
            self.loading.stopAnimating()
            if (self.userLovelist?.count <= 0) {
                self.lblEmpty.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.setupTable()
            }
        }
    }
    
    func getUserLovelist() {
        // API Migrasi
        let _ = request(APIMe.myLovelist).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Lovelist")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                // Store data into variable
                for (_, item) in data {
                    let l = LovedProduct.instance(item)
                    if (l != nil) {
                        self.userLovelist?.append(l!)
                    }
                }
            }
            
            self.loadingPanel.isHidden = true
            self.loading.stopAnimating()
            if (self.userLovelist?.count <= 0) {
                self.lblEmpty.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.setupTable()
            }
        }
    }
    
    func setupTable() {
        
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
    
    // MARK: - MyLovelistCellDelegate Functions
    
    func showLoading() {
        // Tampilkan loading
        loadingPanel.isHidden = false
        loading.startAnimating()
    }
    
    func hideLoading() {
        // Hilangkan loading
        loadingPanel.isHidden = true
        loading.stopAnimating()
    }
    
    func deleteCell(_ cell: MyLovelistCell) {
        //print("delete cell with productId = \(cell.productId)")
        
        // Delete data in userLovelist
        for i in 0 ..< userLovelist!.count {
            let l = userLovelist?.objectAtCircleIndex(i)
            if (l?.id == cell.productId) {
                userLovelist?.remove(at: i)
            }
        }
        if (self.userLovelist?.count <= 0) {
            self.lblEmpty.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.lblEmpty.isHidden = true
            self.tableView.isHidden = false
            self.setupTable()
        }
    }
    
    func gotoCart() {
        if AppTools.isNewCart {
            if AppTools.isSingleCart {
                let checkout2VC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2, owner: nil, options: nil)?.first as! Checkout2ViewController
                checkout2VC.previousController = self
                checkout2VC.previousScreen = PageName.Lovelist
                self.navigationController?.pushViewController(checkout2VC, animated: true)
            } else {
                let checkout2ShipVC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2Ship, owner: nil, options: nil)?.first as! Checkout2ShipViewController
                checkout2ShipVC.previousController = self
                checkout2ShipVC.previousScreen = PageName.Lovelist
                self.navigationController?.pushViewController(checkout2ShipVC, animated: true)
            }
        } else {
            let c = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdCart) as! CartViewController
            c.previousScreen = PageName.Lovelist
            self.navigationController?.pushViewController(c, animated: true)
        }
    }
    
    // checkout affiliate
    func checkoutAffiliate(_ productId: String, affiliateData: AffiliateItem) {
        let _ = request(APIAffiliate.postCheckout(productIds: productId, affiliateName: (affiliateData.name)!)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Checkout \((affiliateData.name)!)" /*"Post Affiliate Checkout"*/)) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if let checkoutUrl = data["checkout_url"].string {
                    let webVC = BaseViewController.instatiateViewControllerFromStoryboardWithID("preloweb") as! PreloWebViewController
                    webVC.url = checkoutUrl
                    webVC.titleString = (affiliateData.name)!
                    webVC.affilateMode = true
                    webVC.checkoutPattern = (affiliateData.checkoutUrlPattern)!
                    webVC.checkoutInitiateUrl = checkoutUrl
                    webVC.checkoutSucceed = { orderId in
                        print(orderId)
                        self.navigateToOrderConfirmVC(orderId)
                    }
                    webVC.checkoutUnfinished = {
                        Constant.showDialog("Checkout", message: "Checkout tertunda")
                    }
                    webVC.checkoutFailed = {
                        Constant.showDialog("Checkout", message: "Checkout gagal, silahkan coba beberapa saat lagi")
                    }
                    let baseNavC = BaseNavigationController()
                    baseNavC.setViewControllers([webVC], animated: false)
                    self.present(baseNavC, animated: true, completion: nil)
                }
            }
        }
    }
    
    func navigateToOrderConfirmVC(_ orderId: String) {
        // get data
        let _ = request(APIAffiliate.getCheckoutResult(orderId: orderId)).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Get Affiliate Checkout")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                let tId = data["transaction_id"].stringValue
                let price = data["total_price"].stringValue
                var imgs : [URL] = []
                if let cd = data["cart_details"].array {
                    for c in cd {
                        if let ps = c["products"].array {
                            for p in ps {
                                if let pics = p["display_picts"].array {
                                    for pic in pics {
                                        if let url = URL(string: pic.stringValue) {
                                            imgs.append(url)
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                var backAccounts : Array<BankAccount> = []
                if let arr = data["affiliate_data"]["bank_accounts"].array {
                    
                    if arr.count > 0 {
                        for i in 0...arr.count-1 {
                            backAccounts.append(BankAccount.instance(arr[i])!)
                        }
                    }
                }
                
                let o = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
                
                o.orderID = orderId
                o.total = price.int64
                o.transactionId = tId
                o.isBackTwice = false
                o.isShowBankBRI = false
                o.targetBank = ""
                o.previousScreen = PageName.ProductDetail
                o.images = imgs
                o.isFromCheckout = false
                
                // hidden payment bank transfer
                //o.isMidtrans = true
                
                o.isAffiliate = true
                o.rekenings = backAccounts
                o.targetBank = backAccounts.count > 0 ? backAccounts[0].bank_name : "dummy"
                
                if let an = data["affiliate_data"]["affiliate_name"].string {
                    o.affiliatename = an
                }
                
                if let expire = data["expire_time"].string {
                    o.expireAffiliate = expire
                }
                
                if let er = data["payment_expired_remaining"].int {
                    o.remaining = er
                }
                
                o.title = "Order ID \(orderId)"
                self.navigationController?.pushViewController(o, animated: true)
            }
        }
    }
    
    // MARK: - UITableViewDelegate Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (userLovelist?.count > 0) {
            return (self.userLovelist?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MyLovelistCell = self.tableView.dequeueReusableCell(withIdentifier: "MyLovelistCell") as! MyLovelistCell
        
        cell.selectionStyle = .none
        cell.alpha = 1.0
        cell.backgroundColor = UIColor.white
        cell.delegate = self
        
        let u = userLovelist?[(indexPath as NSIndexPath).item]
        cell.adapt(u!)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ////print("Row \(indexPath.row) selected")
        
        // Tampilkan loading
        loadingPanel.isHidden = false
        loading.startAnimating()
        
        // Load detail product
        let selectedLoved : LovedProduct = (userLovelist?[(indexPath as NSIndexPath).item])! as LovedProduct
        let _ = request(APIProduct.detail(productId: selectedLoved.id, forEdit: 0)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Barang")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                // Store data into variable
                self.selectedProduct = Product.instance(data)
                
                // Launch detail scene
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NotificationName.ShowProduct), object: [ self.selectedProduct, PageName.Notification ])
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    // MARK: - IBActions
    
    @IBAction func sellPressed(_ sender: AnyObject) {
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        add.screenBeforeAddProduct = PageName.Lovelist
        self.navigationController?.pushViewController(add, animated: true)
    }
}

// MARK: - MyLovelistCell Protocol

protocol MyLovelistCellDelegate {
    func showLoading()
    func hideLoading()
    func deleteCell(_ cell : MyLovelistCell)
    func gotoCart()
    func checkoutAffiliate(_ productId: String, affiliateData: AffiliateItem)
}

class MyLovelistCell : UITableViewCell {
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblCommentCount: UILabel!
    @IBOutlet weak var lblLoveCount: UILabel!
    
    var sellerId : String!
    var productId : String!
    var price: String!
    
    var delegate : MyLovelistCellDelegate?
    var lovedProduct : LovedProduct!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imgProduct.afCancelRequest()
    }
    
    func adapt(_ lovedProduct : LovedProduct) {
        self.lovedProduct = lovedProduct
        
        if lovedProduct.productImageURL != nil {
            imgProduct.afSetImage(withURL: lovedProduct.productImageURL!)
        }
        lblProductName.text = lovedProduct.name
        lblPrice.text = "\(lovedProduct.price.asPrice)"
        lblCommentCount.text = lovedProduct.numComment.string
        lblLoveCount.text = lovedProduct.numLovelist.string
        sellerId = lovedProduct.sellerId
        productId = lovedProduct.id
        price = lovedProduct.price.string
    }
    
    @IBAction func beliPressed(_ sender: AnyObject) {
        // checkout affiliate -> hunstreet
        if self.lovedProduct.isCheckout && self.lovedProduct.AffiliateData != nil {
            self.delegate?.checkoutAffiliate(self.productId, affiliateData: self.lovedProduct.AffiliateData!)
        } else {
        
        if AppTools.isNewCart { // v2
            if CartManager.sharedInstance.insertProduct(sellerId, productId: productId) {
                // FB Analytics - Add to Cart
                if AppTools.IsPreloProduction {
                    let fbPdata: [String : Any] = [
                        FBSDKAppEventParameterNameContentType          : "product",
                        FBSDKAppEventParameterNameContentID            : productId!,
                        FBSDKAppEventParameterNameCurrency             : "IDR"
                    ]
                    FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToCart, valueToSum: Double(price)!, parameters: fbPdata)
                }
            } else {
                Constant.showDialog("Warning", message: "Barang sudah ada di keranjang belanja Anda")
            }
            self.delegate?.gotoCart()
        } else { // v1
            if (CartProduct.isExist(productId!, email : User.EmailOrEmptyString)) { // Already in cart
                Constant.showDialog("Warning", message: "Barang sudah ada di keranjang belanja Anda")
                self.delegate?.gotoCart()
            } else { // Not in cart
                if (CartProduct.newOne(productId!, email : User.EmailOrEmptyString, name : (lblProductName.text)!) == nil) { // Failed
                    Constant.showDialog("Warning", message: "Gagal menyimpan barang ke keranjang belanja")
                } else { // Success
                    // TODO: Kirim API add to cart
                    // FB Analytics - Add to Cart
                    if AppTools.IsPreloProduction {
                        let fbPdata: [String : Any] = [
                            FBSDKAppEventParameterNameContentType          : "product",
                            FBSDKAppEventParameterNameContentID            : productId!,
                            FBSDKAppEventParameterNameCurrency             : "IDR"
                        ]
                        FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToCart, valueToSum: Double(price)!, parameters: fbPdata)
                    }
                    //Constant.showDialog("Success", message: "Barang berhasil ditambahkan ke keranjang belanja")
                    self.delegate?.gotoCart()
                }
            }
        }
        }
        // Delete cell after add to cart
        //self.deletePressed(nil)
    }
    
    @IBAction func deletePressed(_ sender: AnyObject?) {
        // Show loading
        self.delegate?.showLoading()
        
        // Send unlove API
        let _ = request(APIProduct.unlove(productID: productId)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Unlove")) {
                let json = JSON(resp.result.value!)
                let isLove : Bool = json["_data"]["love"].bool!
                if (!isLove) { // Berhasil unlove
                    // Delete cell
                    self.delegate?.deleteCell(self)
                }
                self.delegate?.hideLoading()
            }
        }
    }
}
