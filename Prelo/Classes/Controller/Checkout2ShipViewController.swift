//
//  Checkout2ShipViewController.swift
//  Prelo
//
//  Created by Djuned on 4/12/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire
import DropDown

// MARK: - Helper
class AddressHelper: NSObject {
    static let maxAddress = 5
}

// MARK: - Struct
struct SelectedAddressItem {
    var addressId: String = ""
    var isDefault: Bool = false
    
    var name: String = ""
    var phone: String = ""
    var address: String = ""
    var postalCode: String = ""
    var provinceId: String = ""
    var regionId: String = ""
    var subdistrictId: String = ""
    var subdistrictName: String = ""
    
    // coordinate
    var coordinate: String = ""
    var coordinateAddress: String = ""
    
    var isSave: Bool = false // if default & save -> update local data
}

// MARK: - Class
class Checkout2ShipViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var isFirst = true
    var shouldBack = false
    var isLoading = false
    
    var dropDown = DropDown()
    
    // Address
    var selectedAddress = SelectedAddressItem()
    
    var selectedIndex = 0
    var isNeedSetup = false
    
    // Cart Results
    var cartResult: CartV2ResultItem!
    
    var shippingPackageIds: Array<String>!
    var ongkirs: Array<Int64>!
    var isFreeOngkirs: Array<Bool>!
    var selectedOngkirIndexes: Array<Int>!
    var isNeedLocations: Array<Bool>!
    
    // if contain(s) sold product(s)
    var isEnableToCheckout = true
    
    // troli
    var unpaid = 0
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // disable join with courier
        //let Checkout2SellerCell = UINib(nibName: "Checkout2SellerCell", bundle: nil)
        //tableView.register(Checkout2SellerCell, forCellReuseIdentifier: "Checkout2SellerCell")
        
        let Checkout2ProductCell = UINib(nibName: "Checkout2ProductCell", bundle: nil)
        tableView.register(Checkout2ProductCell, forCellReuseIdentifier: "Checkout2ProductCell")
        
        let Checkout2CourierCell = UINib(nibName: "Checkout2CourierCell", bundle: nil)
        tableView.register(Checkout2CourierCell, forCellReuseIdentifier: "Checkout2CourierCell")
        
        // disable
        //let Checkout2CourierDescriptionCell = UINib(nibName: "Checkout2CourierDescriptionCell", bundle: nil)
        //tableView.register(Checkout2CourierDescriptionCell, forCellReuseIdentifier: "Checkout2CourierDescriptionCell")
        
        let Checkout2SplitCell = UINib(nibName: "Checkout2SplitCell", bundle: nil)
        tableView.register(Checkout2SplitCell, forCellReuseIdentifier: "Checkout2SplitCell")
        
        let Checkout2AddressDropdownCell = UINib(nibName: "Checkout2AddressDropdownCell", bundle: nil)
        tableView.register(Checkout2AddressDropdownCell, forCellReuseIdentifier: "Checkout2AddressDropdownCell")
        
        let Checkout2AddressCompleteCell = UINib(nibName: "Checkout2AddressCompleteCell", bundle: nil)
        tableView.register(Checkout2AddressCompleteCell, forCellReuseIdentifier: "Checkout2AddressCompleteCell")
        
        let Checkout2AddressFillCell = UINib(nibName: "Checkout2AddressFillCell", bundle: nil)
        tableView.register(Checkout2AddressFillCell, forCellReuseIdentifier: "Checkout2AddressFillCell")
        
        let Checkout2AddressLocationCell = UINib(nibName: "Checkout2AddressLocationCell", bundle: nil)
        tableView.register(Checkout2AddressLocationCell, forCellReuseIdentifier: "Checkout2AddressLocationCell")
        
        let Checkout2TotalBuyingCell = UINib(nibName: "Checkout2TotalBuyingCell", bundle: nil)
        tableView.register(Checkout2TotalBuyingCell, forCellReuseIdentifier: "Checkout2TotalBuyingCell")
        
        // Belum ada barang dalam keranjang belanja
        tableView.register(ProvinceCell.self, forCellReuseIdentifier: "cell")
        
        // init dropdown
        DropDown.startListeningToKeyboard()
        let appearance = DropDown.appearance()
        appearance.backgroundColor = UIColor(white: 1, alpha: 1)
        appearance.selectionBackgroundColor = UIColor(red: 0.6494, green: 0.8155, blue: 1.0, alpha: 0.2)
        appearance.separatorColor = UIColor(white: 0.7, alpha: 0.8)
        appearance.cornerRadius = 0
        appearance.shadowColor = UIColor(white: 0.6, alpha: 1)
        appearance.shadowOpacity = 1
        appearance.shadowRadius = 2
        appearance.animationduration = 0.25
        appearance.textColor = .darkGray
        
        // Setup table
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.tableView.contentInset = inset
        
        self.tableView.separatorStyle = .none
        
        // loading
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.7)
        if CartManager.sharedInstance.getSize() > 0 {
            self.isLoading = true
            self.tableView.backgroundColor = UIColor(hexString: "#E8ECEE")
            self.tableView.reloadData()
        } else {
            self.hideLoading()
        }
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(Checkout2ShipViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        // update troli
        self.setupOption(0)
        
        // title
        self.title = "Checkout"
        
        // Prelo Analytic - Go to cart
        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.PreloAnalytic",
                                            qos: .background,
                                            target: nil)
        backgroundQueue.async {
            //print("Work on background queue")
            
            let loginMethod = User.LoginMethod ?? ""
            
            var localId = User.CartLocalId ?? ""
            if (localId == "") {
                let uniqueCode : TimeInterval = Date().timeIntervalSinceReferenceDate
                let uniqueCodeString = uniqueCode.description
                localId = UIDevice.current.identifierForVendor!.uuidString + "-" + uniqueCodeString
                
                User.SetCartLocalId(localId)
            }
            
            let productIds : [String] = CartManager.sharedInstance.getAllProductIds()
            let pdata = [
                "Local ID" : localId,
                "Product IDs" : productIds,
                "Type" : "Two Pages"
            ] as [String : Any]
            AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.GoToCart, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isFirst {
            //self.showLoading()
            
            self.getCart()
        }
        
        // Handling keyboard animation
        self.an_subscribeKeyboard(
            animations: {r, t, o in
                
                if (o) {
                    self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
                
        }, completion: nil)
        
        // Perform tour for first time checkout
        let checkTour = UserDefaults.standard.bool(forKey: "cartTour")
        if (checkTour == false) {
            UserDefaults.standard.set(true, forKey: "cartTour")
            UserDefaults.standard.synchronize()
            Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(Checkout2ShipViewController.performSegTour), userInfo: nil, repeats: false)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // fixer
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    // MARK: - Option Button
    func createUnpaidButton(_ num : Int)->UIButton {
        return createButtonWithIconAndNumber(UIImage(named: "ic_wjp_exclamation.png")!, num: num)
    }
    
    func setupOption(_ count: Int) {
        if count > 0 {
            self.unpaid = count
            let troli = createUnpaidButton(count)
            
            troli.addTarget(self, action: #selector(Checkout2ShipViewController.launchUnpaid), for: UIControlEvents.touchUpInside)
            
            let troliRecognizer = UITapGestureRecognizer(target: self, action: #selector(Checkout2ShipViewController.launchUnpaid))
            troli.viewWithTag(100)?.addGestureRecognizer(troliRecognizer)
            
            self.navigationItem.rightBarButtonItems = [troli.toBarButton()]
        } else {
            self.navigationItem.rightBarButtonItems = []
        }
    }
    
    func launchUnpaid() {
        if self.unpaid > 0 {
            let alertView = SCLAlertView(appearance: Constant.appearance)
            alertView.addButton("Bayar") {
                /*
                let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                notifPageVC.previousScreen = PageName.Checkout
                */
                
                let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
                myPurchaseVC.previousScreen = PageName.Checkout
                self.navigationController?.pushViewController(myPurchaseVC, animated: true)
            }
            alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
            alertView.showCustom("Transaksi", subTitle: "Hi, masih ada \(unpaid) transaksi yang belum kamu bayar loh! Bayar sekarang?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
        } else {
            Constant.showDialog("Transaksi", message: "Kamu sedang tidak memiliki transaksi aktif")
        }
    }
    
    // MARK: - Cart sync
    // just in case getcart return 0
    func getUnpaid() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = appDelegate.preloNotifListener
        
        // Get unpaid transaction
        let _ = request(APITransactionCheck.checkUnpaidTransaction).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Checkout - Unpaid Transaction")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if (data["user_has_unpaid_transaction"].boolValue == true) {
                    let nUnpaid = data["n_transaction_unpaid"].intValue
                    notifListener?.setCartCount(nUnpaid)
                    
                    self.setupOption(nUnpaid)
                }
            }
        }
    }
    
    func getCart() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = appDelegate.preloNotifListener
        
        // Get cart from server
        let _ = request(APIV2Cart.getCart).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Checkout - Get Cart")) {
                let json = JSON(resp.result.value!)
                if let arr = json["_data"].array, arr.count > 0 || CartManager.sharedInstance.getSize() > 0 {
                    for a in arr {
                        let spId = a["shipping_package_id"].stringValue
                        let pIds  = a["product_ids"].arrayValue
                        let sellerId  = a["seller_id"].stringValue
                        
                        for pId in pIds {
                            _ = CartManager.sharedInstance.insertProduct(sellerId, productId: pId.string!)
                        }
                        
                        CartManager.sharedInstance.updateShippingPackageId(sellerId, shippingPackageId: spId)
                    }
                    
                    // init default shipping
                    let userProfile = CDUserProfile.getOne()
                    self.selectedAddress.provinceId = userProfile?.provinceID ?? ""
                    self.selectedAddress.regionId = userProfile?.regionID ?? ""
                    self.selectedAddress.subdistrictId = userProfile?.subdistrictID ?? ""
                    self.selectedAddress.subdistrictName = userProfile?.subdistrictName ?? ""
                    
                    self.selectedAddress.coordinate = userProfile?.coordinate ?? ""
                    self.selectedAddress.coordinateAddress = userProfile?.coordinateAddress ?? ""
                    
                    notifListener?.setCartCount(CartManager.sharedInstance.getSize())
                    
                    self.isLoading = true
                    self.tableView.backgroundColor = UIColor(hexString: "#E8ECEE")
                    self.tableView.reloadData()
                    
                    self.synchCart()
                } else {
                    // reset localid
                    User.SetCartLocalId("")
                    
                    notifListener?.setCartCount(0)
                    
                    self.getUnpaid()
                    
                    self.backToPreviousScreen()
                }
            } else {
                self.backToPreviousScreen()
            }
        }
    }
    
    // Refresh data cart dan seluruh tampilan
    func synchCart() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = appDelegate.preloNotifListener
        
        self.showLoading()
        self.isLoading = true
        
        let p = CartManager.sharedInstance.getCartJsonString()
        let a = "{\"coordinate\": \"" + selectedAddress.coordinate + "\", \"address\": \"alamat\", \"province_id\": \"" + selectedAddress.provinceId + "\", \"region_id\": \"" + selectedAddress.regionId + "\", \"subdistrict_id\": \"" + selectedAddress.subdistrictId + "\", \"postal_code\": \"\"}"
        //print("cart_products : \(String(describing: p))")
        //print("shipping_address : \(a)")
        
        // API refresh cart
        let _ = request(APIV2Cart.refresh(cart: p, address: a, voucher: nil)).responseJSON { resp in
            if (PreloV2Endpoints.validate(true, dataResp: resp, reqAlias: "Keranjang Belanja")) {
                
                // Json
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                self.cartResult = CartV2ResultItem.instance(data)
                
                if self.cartResult.cartDetails.count == 0 {
                    self.backToPreviousScreen()
                }
                
                // Show modal text if any
                if let modalText = self.cartResult.modalVerifyText {
                    if (!modalText.isEmpty) {
                        Constant.showDialog("Perhatian", message: modalText)
                    }
                }
                
                self.shippingPackageIds = []
                self.ongkirs = []
                self.isFreeOngkirs = []
                self.selectedOngkirIndexes = []
                self.isNeedLocations = []
                for sp in self.cartResult.cartDetails {
                    
                    // reset to 0
                    self.shippingPackageIds.append(sp.shippingPackages[0].id)
                    self.ongkirs.append(sp.shippingPackages[0].price)
                    self.isFreeOngkirs.append(sp.shippingPackages[0].name.lowercased() == "free ongkir" && sp.shippingPackages[0].price == 0)
                    self.selectedOngkirIndexes.append(0)
                    self.isNeedLocations.append(sp.shippingPackages[0].isNeedLocation && sp.shippingPackages[0].price != 0)
                }
                
                if self.isFirst {
                    if self.cartResult.addressBook.count > 0 {
                        for i in 0...self.cartResult.addressBook.count-1 {
                            if self.cartResult.addressBook[i].isMainAddress {
                                self.selectedIndex = i
                                
                                // default address
                                self.selectedAddress.addressId = self.cartResult.addressBook[i].id
                                self.selectedAddress.isDefault = true
                                
                                self.selectedAddress.name = self.cartResult.addressBook[i].recipientName
                                self.selectedAddress.phone = self.cartResult.addressBook[i].phone
                                self.selectedAddress.provinceId = self.cartResult.addressBook[i].provinceId
                                self.selectedAddress.regionId = self.cartResult.addressBook[i].regionId
                                self.selectedAddress.subdistrictId = self.cartResult.addressBook[i].subdisrictId
                                self.selectedAddress.subdistrictName = self.cartResult.addressBook[i].subdisrictName
                                self.selectedAddress.address = self.cartResult.addressBook[i].address
                                self.selectedAddress.postalCode = self.cartResult.addressBook[i].postalCode
                                self.selectedAddress.coordinate = self.cartResult.addressBook[i].coordinate
                                self.selectedAddress.coordinateAddress = self.cartResult.addressBook[i].coordinateAddress
                                
                                if self.selectedAddress.address == "" || self.selectedAddress.postalCode == "" || self.selectedAddress.subdistrictName == "" {
                                    self.isNeedSetup = true
                                    
                                    self.selectedAddress.isSave = true
                                }
                                
                                break
                            }
                        }
                    }
                    
                    self.isFirst = false
                    self.setupDropdownAddress()
                }
                
                // update troli
                self.setupOption(self.cartResult.nTransactionUnpaid)
                let count = CartManager.sharedInstance.getSize() + self.cartResult.nTransactionUnpaid
                notifListener?.setCartCount(count)
                
                // reset - cart
                self.isEnableToCheckout = true
                
                self.tableView.reloadData()
                self.scrollToTop()
                
                self.isLoading = false
                self.hideLoading()
                
            } else {
                self.isLoading = false
                self.hideLoading()
                
            }
        }
    }
    
    // MARK: - UITableView Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            return 2 + cartResult.cartDetails.count
        } else if !self.isLoading {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            if section < cartResult.cartDetails.count {
                return cartResult.cartDetails[section].products.count + 2 /*+ (self.isNeedLocations[section] && !self.isFreeOngkirs[section] ? 1 : 0) + 1*/ // disable sellerCell & courierDescriptionCell
            } else if section == cartResult.cartDetails.count {
                return 2 + (self.isNeedLocations.contains(true) ? 1 : 0) + 1
            } else if section == cartResult.cartDetails.count + 1 {
                return 1
            }
        } else if !self.isLoading {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            let idx = indexPath as IndexPath
            if idx.section < cartResult.cartDetails.count {
                if idx.row == 0 {
                    return Checkout2CourierCell.heightFor() //Checkout2SellerCell.heightFor()
                } else if idx.row <= cartResult.cartDetails[idx.section].products.count {
                    return Checkout2ProductCell.heightFor()
                } /*else if idx.row == cartResult.cartDetails[idx.section].products.count + 1 {
                    return Checkout2CourierCell.heightFor()
                }*/ else {
                    /*if idx.row == cartResult.cartDetails[idx.section].products.count + 2 && self.isNeedLocations[idx.section] && !self.isFreeOngkirs[idx.section] {
                        return Checkout2CourierDescriptionCell.heightFor()
                    } else {*/
                        return Checkout2SplitCell.heightFor()
                    //}
                }
            } else if idx.section == cartResult.cartDetails.count {
                if idx.row == 0 {
                    return Checkout2AddressDropdownCell.heightFor()
                } else if idx.row == 1 {
                    if isNeedSetup {
                        return Checkout2AddressFillCell.heightFor()
                    } else {
                        return Checkout2AddressCompleteCell.heightFor()
                    }
                } else {
                    if idx.row == 2 && self.isNeedLocations.contains(true) {
                        return Checkout2AddressLocationCell.heightFor()
                    } else {
                        return Checkout2SplitCell.heightFor()
                    }
                }
            } else if idx.section == cartResult.cartDetails.count + 1 {
                return Checkout2TotalBuyingCell.heightFor()
            }
        } else if !self.isLoading {
            return 90
        }
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            let idx = indexPath as IndexPath
            if ((indexPath as NSIndexPath).section < cartResult.cartDetails.count) {
                // MARK: - Product Sections
                if idx.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2CourierCell") as! Checkout2CourierCell
                    
                    let sellerId = self.cartResult.cartDetails[idx.section].id
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt(self.cartResult.cartDetails[idx.section].shippingPackages, isEnable: !self.isFreeOngkirs[idx.section], selectedIndex: self.selectedOngkirIndexes[idx.section], title: self.cartResult.cartDetails[idx.section].username)
                    
                    cell.pickCourier = { courierId, ongkir, index, isNeedLocation in
                        self.shippingPackageIds[idx.section] = courierId
                        self.ongkirs[idx.section] = ongkir
                        self.selectedOngkirIndexes[idx.section] = index
                        self.isNeedLocations[idx.section] = isNeedLocation
                        
                        CartManager.sharedInstance.updateShippingPackageId(sellerId, shippingPackageId: courierId)
                        
                        self.tableView.reloadData()
                    }
                    
                    cell.dismissKeyborad = {
                        self.dismissKeyboard()
                    }
                    
                    return cell
                    
                    /*let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2SellerCell") as! Checkout2SellerCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    var pids: Array<String> = []
                    for p in self.cartResult.cartDetails[idx.section].products {
                        pids.append(p.productId)
                    }
                    
                    cell.adapt(self.cartResult.cartDetails[idx.section].username, productIds: pids)
                    
                    cell.removeAll = { pids in
                        self.dismissKeyboard()
                        
                        let alertView = SCLAlertView(appearance: Constant.appearance)
                        alertView.addButton("Hapus") {
                            self.showLoading()
                            
                            let _ = request(APIV2Cart.removeItems(pIds: pids)).responseJSON { resp in
                                if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Keranjang Belanja - Hapus Items")) {
                                    print("Keranjang Belanja - Hapus Items, Success")
                                    
                                    for pid in pids {
                                        CartProduct.delete(pid) // v1
                                        CartManager.sharedInstance.deleteProduct(self.cartResult.cartDetails[idx.section].id, productId: pid)
                                    }
                                    
                                    self.updateTroli()
                                    
                                    self.synchCart()
                                } else {
                                    print("Keranjang Belanja - Hapus Items, Failed")
                                    
                                    Constant.showDialog("Hapus Items", message: "\"\(self.cartResult.cartDetails[idx.section].fullname)\" gagal dihapus")
                                    
                                    self.hideLoading()
                                }
                            }
                        }
                        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
                        alertView.showCustom("Hapus Keranjang", subTitle: "Kamu yakin ingin menghapus semua barang dari seller \"\(self.cartResult.cartDetails[idx.section].fullname)\"?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                    }
                    
                    return cell*/
                } else if idx.row <= cartResult.cartDetails[idx.section].products.count {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2ProductCell") as! Checkout2ProductCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    let product = self.cartResult.cartDetails[idx.section].products[idx.row-1]
                    
                    cell.adapt(product)
                    
                    if product.errorMessage != nil {
                        self.isEnableToCheckout = false
                    }
                    
                    cell.remove = { pid in
                        self.dismissKeyboard()
                        
                        let alertView = SCLAlertView(appearance: Constant.appearance)
                        alertView.addButton("Hapus") {
                            self.showLoading()
                            
                            let _ = request(APIV2Cart.removeItems(pIds: [pid])).responseJSON { resp in
                                if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Keranjang Belanja - Hapus Items")) {
                                    print("Keranjang Belanja - Hapus Items, Success")
                                    
                                    CartProduct.delete(pid) // v1
                                    CartManager.sharedInstance.deleteProduct(product.sellerId, productId: pid)
                                    
                                    self.updateTroli()
                                    
                                    self.synchCart()
                                } else {
                                    print("Keranjang Belanja - Hapus Items, Failed")
                                    
                                    Constant.showDialog("Hapus Items", message: "\"\(self.cartResult.cartDetails[idx.section].products[idx.row-1].name)\" gagal dihapus")
                                    
                                    self.hideLoading()
                                }
                            }
                        }
                        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
                        alertView.showCustom("Hapus Keranjang", subTitle: "Kamu yakin ingin menghapus \"\(self.cartResult.cartDetails[idx.section].products[idx.row-1].name)\"?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                        
                    }
                    
                    return cell
                } /*else if idx.row == cartResult.cartDetails[idx.section].products.count + 1 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2CourierCell") as! Checkout2CourierCell
                    
                    let sellerId = self.cartResult.cartDetails[idx.section].id
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt(cartResult.cartDetails[idx.section].shippingPackages, isEnable: !self.isFreeOngkirs[idx.section], selectedIndex: self.selectedOngkirIndexes[idx.section])
                    
                    cell.pickCourier = { courierId, ongkir, index, isNeedLocation in
                        self.shippingPackageIds[idx.section] = courierId
                        self.ongkirs[idx.section] = ongkir
                        self.selectedOngkirIndexes[idx.section] = index
                        self.isNeedLocations[idx.section] = isNeedLocation
                        
                        CartManager.sharedInstance.updateShippingPackageId(sellerId, shippingPackageId: courierId)
                        
                        self.tableView.reloadData()
                    }
                    
                    cell.dismissKeyborad = {
                        self.dismissKeyboard()
                    }
                    
                    return cell
                }*/ else {
                    /*if idx.row == cartResult.cartDetails[idx.section].products.count + 2 && self.isNeedLocations[idx.section] && !self.isFreeOngkirs[idx.section] {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2CourierDescriptionCell") as! Checkout2CourierDescriptionCell
                        
                        cell.selectionStyle = .none
                        cell.clipsToBounds = true
                        
                        cell.adapt(self.shippingPackageIds[idx.section])
                        
                        return cell
                    } else {*/
                        let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2SplitCell") as! Checkout2SplitCell
                        
                        cell.selectionStyle = .none
                        cell.clipsToBounds = true
                        
                        return cell
                    //}
                }
            } else if idx.section == cartResult.cartDetails.count {
                // MARK: - Address Sections
                if idx.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2AddressDropdownCell") as! Checkout2AddressDropdownCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt((cartResult.addressBook.count > selectedIndex ? cartResult.addressBook[selectedIndex] : nil))
                    
                    self.dropDown.anchorView = cell.vwBorder
                    
                    // Top of drop down will be below the anchorView
                    self.dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)! + 4)
                    
                    // When drop down is displayed with `Direction.top`, it will be above the anchorView
                    self.dropDown.topOffset = CGPoint(x: 0, y:-(dropDown.anchorView?.plainView.bounds.height)! - 4)
                    
                    cell.pickAddress = {
                        self.dismissKeyboard()
                        
                        self.dropDown.hide()
                        self.dropDown.show()
                    }
                    
                    return cell
                } else if idx.row == 1 {
                    if isNeedSetup {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2AddressFillCell") as! Checkout2AddressFillCell
                        
                        cell.selectionStyle = .none
                        cell.clipsToBounds = true
                        
                        let isDefault = cartResult.addressBook.count > selectedIndex ? cartResult.addressBook[selectedIndex].id == cartResult.defaultAddress?.id : false
                        
                        cell.adapt(self.selectedAddress, parent: self, isSaveAble: (self.selectedIndex < AddressHelper.maxAddress), isDefault: isDefault)
                        
                        self.scrollToAddress()
                        
                        cell.pickProvince = { provinceId in
                            // self.dismissKeyboard()
                            
                            self.selectedAddress.provinceId = provinceId
                            self.selectedAddress.regionId = ""
                            self.selectedAddress.subdistrictId = ""
                            self.selectedAddress.subdistrictName = ""
                        }
                        
                        cell.pickRegion = { regionId in
                            // self.dismissKeyboard()
                            
                            self.selectedAddress.regionId = regionId
                            self.selectedAddress.subdistrictId = ""
                            self.selectedAddress.subdistrictName = ""
                        }
                        
                        cell.pickSubdistrict = { subdistrictId, subdistrictName in
                            // self.dismissKeyboard()
                            
                            self.selectedAddress.subdistrictId = subdistrictId
                            self.selectedAddress.subdistrictName = subdistrictName
                            
                            self.synchCart()
                        }
                        
                        cell.saveAddress = {
                            // self.dismissKeyboard()
                            
                            self.selectedAddress.isSave = !self.selectedAddress.isSave
                            
                            //print("isSave: \(self.selectedAddress.isSave)")
                        }
                        
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2AddressCompleteCell") as! Checkout2AddressCompleteCell
                        
                        cell.selectionStyle = .none
                        cell.clipsToBounds = true
                        
                        cell.adapt(cartResult.addressBook[selectedIndex])
                        
                        return cell
                    }
                } else {
                    if idx.row == 2 && self.isNeedLocations.contains(true) {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2AddressLocationCell") as! Checkout2AddressLocationCell
                        
                        cell.selectionStyle = .none
                        cell.clipsToBounds = true
                        
                        cell.adapt(self.selectedAddress.coordinateAddress, coordinate: self.selectedAddress.coordinate)
                        
                        cell.pickLocation = {
                            let googleMapVC = Bundle.main.loadNibNamed(Tags.XibNameGoogleMap, owner: nil, options: nil)?.first as! GoogleMapViewController
                            googleMapVC.coordinateString = self.selectedAddress.coordinate
                            googleMapVC.blockDone = { result in
                                
                                self.selectedAddress.coordinate = result["latitude"]! + "," + result["longitude"]!
                                self.selectedAddress.coordinateAddress = result["address"]!
                                
                                //self.tableView.reloadData()
                                self.tableView.reloadRows(at: [idx], with: .fade)
                                
                                if self.selectedAddress.addressId != "" {
                                    self.updateCoordinateAddress()
                                }
                            }
                            self.navigationController?.pushViewController(googleMapVC, animated: true)
                        }
                        
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2SplitCell") as! Checkout2SplitCell
                        
                        cell.selectionStyle = .none
                        cell.clipsToBounds = true
                        
                        return cell
                    }
                }
            } else if idx.section == cartResult.cartDetails.count + 1 {
                // MARK: - Subtotal Sections
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2TotalBuyingCell") as! Checkout2TotalBuyingCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                var totalWithOngkir = self.cartResult.totalPrice
                
                for o in self.ongkirs {
                    totalWithOngkir += o
                }
                
                cell.adapt(totalWithOngkir.asPrice)
                
                cell.continueToPayment = {
                    self.dismissKeyboard()
                    
                    if self.validateField() {
                        //print("oke")
                        
                        let checkout2PayVC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2Pay, owner: nil, options: nil)?.first as! Checkout2PayViewController
                        checkout2PayVC.cartResult = self.cartResult
                        checkout2PayVC.previousController = self.previousController
                        checkout2PayVC.previousScreen = self.previousScreen
                        checkout2PayVC.totalAmount = totalWithOngkir
                        checkout2PayVC.selectedAddress = self.selectedAddress
                        self.navigationController?.pushViewController(checkout2PayVC, animated: true)
                    }
                }
                
                return cell
            }
        } else if !self.isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            
            cell?.selectionStyle = .none
            
            cell?.textLabel!.text = "Belum ada barang dalam keranjang belanja"
            cell?.textLabel!.font = UIFont.systemFont(ofSize: 12)
            cell?.textLabel!.textAlignment = .center
            cell?.textLabel!.textColor = Theme.GrayDark
            
            return cell!
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // do nothing
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        /*
        let more = UITableViewRowAction(style: .normal, title: "More") { action, index in
            print("more button tapped")
        }
        more.backgroundColor = .lightGray
        
        let favorite = UITableViewRowAction(style: .normal, title: "Favorite") { action, index in
            print("favorite button tapped")
        }
        favorite.backgroundColor = .orange
        
        let share = UITableViewRowAction(style: .normal, title: "Share") { action, index in
            print("share button tapped")
        }
        share.backgroundColor = .blue
        
        return [share, favorite, more]
         */
        
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            // Checkout2ProductCell
            let idx = indexPath as IndexPath
            let cell = tableView.cellForRow(at: idx) as! Checkout2ProductCell
            
            let remove = UITableViewRowAction(style: .destructive, title: "Hapus") { action, index in
                let pid = cell.productDetail.productId
                let sellerId = cell.productDetail.sellerId
                
                self.showLoading()
                
                let _ = request(APIV2Cart.removeItems(pIds: [pid])).responseJSON { resp in
                    if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Keranjang Belanja - Hapus Items")) {
                        //print("Keranjang Belanja - Hapus Items, Success")
                        
                        CartProduct.delete(pid) // v1
                        CartManager.sharedInstance.deleteProduct(sellerId, productId: pid)
                        
                        self.updateTroli()
                        
                        self.synchCart()
                    } else {
                        //print("Keranjang Belanja - Hapus Items, Failed")
                        
                        Constant.showDialog("Hapus Items", message: "\"\(self.cartResult.cartDetails[idx.section].products[idx.row-1].name)\" gagal dihapus")
                        
                        self.hideLoading()
                    }
                }
                
                //print("hapus tapped")
            }
            /*
            let detail = UITableViewRowAction(style: .normal, title: "Detail") { action, index in
                let p = Product.instance(cell.productDetail.json)
                
                // Goto product detail
                let productDetailVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                productDetailVC.product = p
                productDetailVC.previousScreen = PageName.Checkout
                self.navigationController?.pushViewController(productDetailVC, animated: true)
            }
            detail.backgroundColor = UIColor.blue
            
            return [remove, detail]
            */
            return [remove]
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            let idx = indexPath as IndexPath
            if idx.section < cartResult.cartDetails.count {
                if idx.row <= cartResult.cartDetails[idx.section].products.count && idx.row > 0 {
                    return true
                }
                return false
            }
            return false
        }
        return false
    }
    
    // MARK: - Validation (Address)
    func validateField() -> Bool {
        if (self.selectedAddress.name == "" ||
            self.selectedAddress.phone == "" ||
            self.selectedAddress.provinceId == "" ||
            self.selectedAddress.regionId == "" ||
            self.selectedAddress.subdistrictId == "" ||
            self.selectedAddress.subdistrictName == "" ||
            self.selectedAddress.address == "" ||
            self.selectedAddress.postalCode == "") {
            
            self.scrollToAddress()
            
            Constant.showDialog("Form belum lengkap", message: "Harap lengkapi alamat Kamu")
            return false
        }
        
        if (self.isNeedLocations.contains(true) && (self.selectedAddress.coordinateAddress == "" || self.selectedAddress.coordinate == "")) {
            self.scrollToAddress()
            
            Constant.showDialog("Form belum lengkap", message: "Harap lengkapi lokasi")
            return false
        }
        
        if !self.isEnableToCheckout {
            self.scrollToTop()
            
            Constant.showDialog("Gagal melanjutkan", message: "Terdapat kesalahan, coba cek pesanan Kamu")
            return false
        }
        
        return true
    }
    
    // MARK: - Other
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    func scrollToTop() {
        if self.cartResult.cartDetails.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: true)
        }
    }
    
    func scrollToAddress() {
        if self.cartResult.cartDetails.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: self.cartResult.cartDetails.count), at: UITableViewScrollPosition.top, animated: true)
        }
    }
    
    func backToPreviousScreen() {
        // Back to prev page if cart is empty
        if (self.shouldBack == true) {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
    }
    
    func updateTroli() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = appDelegate.preloNotifListener
        
        var count = CartManager.sharedInstance.getSize()
        if count == 0 {
            self.shouldBack = true
        }
        count += self.cartResult.nTransactionUnpaid
        
        notifListener?.setCartCount(count)
    }
    
    // MARK: - Setup Dropdown Address
    func setupDropdownAddress() {
        dropDown.dataSource = []
        
        let count = cartResult.addressBook.count
        
        for address in cartResult.addressBook {
            
            let text = address.recipientName + " (" + address.addressName + ") " + address.address + " " + address.subdisrictName + ", " + address.regionName + " " + address.provinceName + " " + address.postalCode

            dropDown.dataSource.append(text)
        }
        
        if (count <= AddressHelper.maxAddress) { // + Alamat baru selalu bisa tidak bisa di save saat index == 5
            dropDown.dataSource.append("+ Alamat baru")
        }
        
        dropDown.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
            if index < count {
                cell.viewWithTag(999)?.removeFromSuperview()
                
                // Setup your custom UI components
                cell.optionLabel.text = ""
                let y = (cell.height - cell.optionLabel.height) / 2.0
                let rectOption = CGRect(x: 16, y: y, width: cell.width - (16 + 16), height: cell.optionLabel.height)
                
                let label = UILabel(frame: rectOption)
                label.font = cell.optionLabel.font
                label.tag = 999
                
                let attString : NSMutableAttributedString = NSMutableAttributedString(string: item)
                
                attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)], range: (item as NSString).range(of: self.cartResult.addressBook[index].recipientName))
                
                // Setup your custom UI components
                label.attributedText = attString
                
                cell.addSubview(label)
            } else {
                cell.viewWithTag(999)?.removeFromSuperview()
                
                // Setup your custom UI components
                cell.optionLabel.text = ""
                let y = (cell.height - cell.optionLabel.height) / 2.0
                let rectOption = CGRect(x: 16, y: y, width: cell.width - (16 + 16), height: cell.optionLabel.height)
                
                let label = UILabel(frame: rectOption)
                label.font = cell.optionLabel.font
                label.tag = 999
                
                // Setup your custom UI components
                label.text = item
                
                cell.addSubview(label)
            }
        }
        
        
        // Action triggered on selection
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            if index != self.selectedIndex {
                self.selectedAddress.isSave = false
                if index < count {
                    self.isNeedSetup = false
                    self.selectedIndex = index
                    
                    self.selectedAddress.addressId = self.cartResult.addressBook[index].id
                    self.selectedAddress.isDefault = self.cartResult.addressBook[index].isMainAddress
                    
                    self.selectedAddress.name = self.cartResult.addressBook[index].recipientName
                    self.selectedAddress.phone = self.cartResult.addressBook[index].phone
                    self.selectedAddress.provinceId = self.cartResult.addressBook[index].provinceId
                    self.selectedAddress.regionId = self.cartResult.addressBook[index].regionId
                    self.selectedAddress.subdistrictId = self.cartResult.addressBook[index].subdisrictId
                    self.selectedAddress.subdistrictName = self.cartResult.addressBook[index].subdisrictName
                    self.selectedAddress.address = self.cartResult.addressBook[index].address
                    self.selectedAddress.postalCode = self.cartResult.addressBook[index].postalCode
                    self.selectedAddress.coordinate = self.cartResult.addressBook[index].coordinate
                    self.selectedAddress.coordinateAddress = self.cartResult.addressBook[index].coordinateAddress
                    
                    if self.selectedAddress.address == "" || self.selectedAddress.postalCode == "" || self.selectedAddress.subdistrictName == "" {
                        self.isNeedSetup = true
                        
                        self.selectedAddress.isSave = true
                    }
                    
                    self.synchCart()
                } else {
                    self.isNeedSetup = true
                    self.selectedIndex = count
                    
                    self.selectedAddress.addressId = ""
                    self.selectedAddress.isDefault = false
                    
                    self.selectedAddress.name = ""
                    self.selectedAddress.phone = ""
                    self.selectedAddress.provinceId = ""
                    self.selectedAddress.regionId = ""
                    self.selectedAddress.subdistrictId = ""
                    self.selectedAddress.subdistrictName = ""
                    self.selectedAddress.address = ""
                    self.selectedAddress.postalCode = ""
                    self.selectedAddress.coordinate = ""
                    self.selectedAddress.coordinateAddress = ""
                }
                
                //self.tableView.reloadData()
                self.tableView.reloadSections(IndexSet.init(integersIn: 0...self.cartResult.cartDetails.count + 1), with: .fade)
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        dropDown.cellHeight = 40
        dropDown.selectRow(at: self.selectedIndex)
//        dropDown.direction = .bottom
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    // MARK: - Update Exist Address
    // coordinate
    func updateCoordinateAddress() {
        let _ = request(APIMe.updateCoordinate(addressId: self.selectedAddress.addressId, coordinate: self.selectedAddress.coordinate, coordinateAddress: self.selectedAddress.coordinateAddress)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Alamat Baru")) {
                //print("Update Address - Save!")
            }
        }
        
        if self.selectedAddress.isDefault {
            self.setupProfile()
        }
    }
    
    // MARK: - Update user Profile
    // coordinate
    func setupProfile() {
        let m = UIApplication.appDelegate.managedObjectContext
        
        if let userProfile = CDUserProfile.getOne() {
            userProfile.coordinate = self.selectedAddress.coordinate
            userProfile.coordinateAddress = self.selectedAddress.coordinateAddress
            //userProfile.address = self.selectedAddress.address
            //userProfile.postalCode = self.selectedAddress.postalCode
            //userProfile.recipientName = self.selectedAddress.name
            //userProfile.phone = self.selectedAddress.phone
        }
        
        // Save data
        if (m.saveSave() == false) {
            //print("Failed")
        } else {
            //print("Data saved")
        }
    }
    
    // MARK: - Cart Tour
    func performSegTour() {
        //self.performSegue(withIdentifier: "segTour", sender: nil)
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tourvc = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdCheckoutTour) as! CheckoutTourViewController
        self.present(tourvc, animated: true, completion: nil)
    }
}

// MARK: - Class Checkout2SellerCell
class Checkout2SellerCell: UITableViewCell {
    @IBOutlet weak var lbSellerName: UILabel!
    
    var productIds: [String]!
    
    var removeAll: ([String])->() = {_ in }
    
    func adapt(_ sellerName: String, productIds: [String]) {
        self.productIds = productIds
        self.lbSellerName.text = sellerName
    }
    
    static func heightFor() -> CGFloat {
        return 48.0
    }
    
    @IBAction func btnRemoveAllPressed(_ sender: Any) {
        self.removeAll(self.productIds)
    }
}

// MARK: - Class Checkout2ProductCell
class Checkout2ProductCell: UITableViewCell {
    @IBOutlet weak var deleteImage: UIButton!
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lbProductName: UILabel!
    @IBOutlet weak var lbProductPrice: UILabel!
    @IBOutlet weak var lbSellerRegion: UILabel!
    @IBOutlet weak var consWidthBtn: NSLayoutConstraint!
    @IBOutlet weak var vwLine1px: UIView!
    
    var productDetail: ProductItem!
    
    var remove: (String)->() = {_ in }
    
    func adapt(_ productDetail: ProductItem) {
        self.consWidthBtn.constant = 40.0
        
        self.productDetail = productDetail
        
        self.imgProduct.afSetImage(withURL: productDetail.displayPicts[0], withFilter: .fill)
        self.lbProductName.text = productDetail.name
        self.lbProductPrice.text = productDetail.price.asPrice
        
        let region = CDRegion.getRegionNameWithID(productDetail.sellerRegionId) ?? "<region not found>"
        self.lbSellerRegion.text = region
        
        if let err = productDetail.errorMessage {
            self.lbProductPrice.text = err
            
            self.lbProductPrice.textColor = UIColor.red
        } else {
            self.lbProductPrice.textColor = Theme.PrimaryColorDark
        }
    }
    
    static func heightFor() -> CGFloat {
        return 77.0
    }
    
    @IBAction func btnRemovePressed(_ sender: Any) {
        self.remove(self.productDetail.productId)
    }
}

// MARK: - Class Checkout2CourierCell
class Checkout2CourierCell: UITableViewCell {
    @IBOutlet weak var lbCourier: UILabel!
    @IBOutlet weak var lbDropdown: UILabel!
    @IBOutlet weak var btnPickCourier: UIButton!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var vwLine1px: UIView!
    
    var selectedIndex = 0
    
    var dropDown = DropDown()
    
    var shippingPackages: Array<ShippingPackageItem>!
    
    var disableColor = UIColor.lightGray
    
    var isEnable = true
    
    var pickCourier: (_ courierId: String, _ ongkir: Int64, _ index: Int, _ isNeedLocation: Bool)->() = {_, _, _, _ in }
    
    var dismissKeyborad: ()->() = {}
    
    func adapt(_ shippingPackages: Array<ShippingPackageItem>, isEnable: Bool, selectedIndex: Int, title: String) {
        self.shippingPackages = shippingPackages
        self.selectedIndex = selectedIndex
        
        if !isEnable {
            self.lbDropdown.textColor = self.disableColor
            
            self.lbCourier.text = "Free Ongkir"
            
            self.isEnable = false
        } else {
            self.setupDropdown()
            
            self.lbDropdown.textColor = Theme.PrimaryColorDark
            
            self.lbCourier.text = shippingPackages[selectedIndex].name + " (" + shippingPackages[selectedIndex].price.asPrice + ")"
            
            self.isEnable = true
        }
        
        // title for seller name
        self.lbTitle.text = title
        self.lbTitle.font = UIFont.boldSystemFont(ofSize: 14)
        
        self.vwLine1px.isHidden = true
    }
    
    static func heightFor() -> CGFloat {
        return 37.0
    }
    
    func setupDropdown() {
        dropDown.dataSource = []
        
        let count = shippingPackages.count
        
        for shippingPackage in shippingPackages {
            
            let text = shippingPackage.name + " (" + shippingPackage.price.asPrice + ")"
            
            dropDown.dataSource.append(text)
        }
        
        dropDown.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
            if index < count {
                cell.viewWithTag(999)?.removeFromSuperview()
                
                // Setup your custom UI components
                cell.optionLabel.text = ""
                let y = (cell.height - cell.optionLabel.height) / 2.0
                let rectOption = CGRect(x: 16, y: y, width: self.btnPickCourier.bounds.width - (16 + 16), height: cell.optionLabel.height)
                
                let label = UILabel(frame: rectOption)
                label.font = cell.optionLabel.font
                label.tag = 999
                
                // Setup your custom UI components
                label.text = item
                label.lineBreakMode = .byTruncatingMiddle
                label.adjustsFontSizeToFitWidth = true
                
                cell.addSubview(label)
            }
        }
        
        // Action triggered on selection
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            if index != self.selectedIndex {
                self.selectedIndex = index
                
                self.lbCourier.text = self.shippingPackages[self.selectedIndex].name + " (" + self.shippingPackages[self.selectedIndex].price.asPrice + ")"
                
                // update VC
                self.pickCourier(self.shippingPackages[self.selectedIndex].id, self.shippingPackages[self.selectedIndex].price, self.selectedIndex, self.shippingPackages[self.selectedIndex].isNeedLocation)
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        dropDown.cellHeight = 40
        dropDown.selectRow(at: self.selectedIndex)
        //dropDown.direction = .bottom
        dropDown.anchorView = self.btnPickCourier
        
        // Top of drop down will be below the anchorView
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)! + 4)
        
        // When drop down is displayed with `Direction.top`, it will be above the anchorView
        dropDown.topOffset = CGPoint(x: 0, y:-(dropDown.anchorView?.plainView.bounds.height)! - 4)
    }
    
    @IBAction func btnPickCourierPressed(_ sender: Any) {
        if self.isEnable {
            self.dismissKeyborad()
            
            dropDown.hide()
            dropDown.show()
        }
    }
}

// MARK: - Class Checkout2CourierDescriptionCell
class Checkout2CourierDescriptionCell: UITableViewCell {
    @IBOutlet weak var lbDescriptionCourier: UILabel!
    
    func adapt(_ courierName: String) {
        self.lbDescriptionCourier.text = "Silahkan lengkapi lokasi jika kamu memilih kurir " + courierName
    }
    
    static func heightFor() -> CGFloat {
        return 35.0
    }
}

// MARK: - Class Checkout2SplitCell
class Checkout2SplitCell: UITableViewCell {
    static func heightFor() -> CGFloat {
        return 4.0
    }
}

// MARK: - Class Checkout2AddressDropdownCell
class Checkout2AddressDropdownCell: UITableViewCell {
    @IBOutlet weak var vwBorder: BorderedView!
    @IBOutlet weak var lbDetailAddress: UILabel!
    
    var pickAddress: ()->() = {}
    
    func adapt(_ address: AddressItem?) {
        if let addr = address {
            var text = ""
            text += addr.recipientName + " (" + addr.addressName + ") "
            text += addr.address + " " + addr.subdisrictName + ", "
            text += addr.regionName + ", " + addr.provinceName + " "
            text += addr.postalCode
            
            let attString : NSMutableAttributedString = NSMutableAttributedString(string: text)
            
            attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)], range: (text as NSString).range(of: addr.recipientName))
            
            self.lbDetailAddress.attributedText = attString
        } else {
            self.lbDetailAddress.text = "+ Alamat baru"
        }
    }
    
    static func heightFor() -> CGFloat {
        return 68.0
    }
    
    @IBAction func btnPickAddressPressed(_ sender: Any) {
        self.pickAddress()
    }
}

// MARK: - Class Checkout2AddressCompleteCell
class Checkout2AddressCompleteCell: UITableViewCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbAddress: UILabel!
    @IBOutlet weak var lbSubdistrictAndRegion: UILabel!
    @IBOutlet weak var lbProvinceAndPostalCode: UILabel!
    @IBOutlet weak var lbPhone: UILabel!
    
    func adapt(_ address: AddressItem) {
        self.lbName.text = address.recipientName
        self.lbAddress.text = address.address
        self.lbSubdistrictAndRegion.text = address.subdisrictName + ", " + address.regionName
        self.lbProvinceAndPostalCode.text = address.provinceName + " " + address.postalCode
        self.lbPhone.text = /*"Telepon: " +*/ address.phone
    }
    
    static func heightFor() -> CGFloat {
        return 109.0
    }
}

// MARK: - Class Checkout2AddressFillCell
class Checkout2AddressFillCell: UITableViewCell, PickerViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var lbProvince: UILabel!
    @IBOutlet weak var lbProvincePicker: UILabel!
    @IBOutlet weak var btnPickProvince: UIButton!
    @IBOutlet weak var lbRegion: UILabel!
    @IBOutlet weak var lbRegionPicker: UILabel!
    @IBOutlet weak var btnPickRegion: UIButton!
    @IBOutlet weak var lbSubdistrict: UILabel!
    @IBOutlet weak var lbSubdistrictPicker: UILabel!
    @IBOutlet weak var btnPickSubdistric: UIButton!
    @IBOutlet weak var txtAddress: UITextField!
    @IBOutlet weak var txtPostalCode: UITextField!
    @IBOutlet weak var lbCheckbox: UILabel!
    
    // province/region/subdistrict id -> global
    
    var pickProvince: (String)->() = {_ in } // change province & color
    var pickRegion: (String)->() = {_ in } // change region & color
    var pickSubdistrict: (_ id: String, _ name: String)->() = {_, _ in } // change subdistrict & color
    var saveAddress: ()->() = {}
    
    var disableColor = UIColor.lightGray
    var placeholderColor = UIColor.init(hex: "#CCCCCC")
    var activeColor = UIColor.init(hex: "#6F6F6F")
    
    var selectedProvinceId: String = ""
    var selectedRegionId: String = ""
    var selectedSubdistrictId: String = ""
    
    var kecamatanPickerItems : [String] = []
    var isPickingProvinsi : Bool = false
    var isPickingKabKota : Bool = false
    var isPickingKecamatan : Bool = false
    
    var parent2: Checkout2ShipViewController?
    var parent1: Checkout2ViewController?
    var isDefault: Bool = false
    var isSaveAble: Bool = true
    var isSave: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // delegate
        self.txtName.delegate = self
        self.txtPhone.delegate = self
        self.txtAddress.delegate = self
        self.txtPostalCode.delegate = self
        
        // numeric keyboards hack
        let ViewForDoneButtonOnKeyboard = UIToolbar()
        ViewForDoneButtonOnKeyboard.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let btnDoneOnKeyboard = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneBtnfromKeyboardClicked))
        ViewForDoneButtonOnKeyboard.items = [flex, btnDoneOnKeyboard, UIBarButtonItem()]
        txtPhone.inputAccessoryView = ViewForDoneButtonOnKeyboard
        txtPostalCode.inputAccessoryView = ViewForDoneButtonOnKeyboard
    }
    
    @IBAction func doneBtnfromKeyboardClicked (sender: Any) {
        print("Done Button Clicked.")
        //Hide Keyboard by endEditing or Anything you want.
        self.endEditing(true)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.lbProvince.text = "Pilih Provinsi"
        self.lbProvince.textColor = self.placeholderColor
        
        self.lbRegion.text = "Pilih Kota/Kabupaten"
        self.lbRegion.textColor = self.placeholderColor
        
        self.lbSubdistrict.text = "Pilih Kecamatan"
        self.lbSubdistrict.textColor = self.placeholderColor
        
        self.isSaveAble = true
        self.isDefault = false
        self.isSave = false
        self.lbCheckbox.isHidden = true
    }
    
    func adapt(_ address: SelectedAddressItem, parent: UIViewController, isSaveAble: Bool, isDefault: Bool) {
        if parent is Checkout2ShipViewController {
            self.parent2 = parent as? Checkout2ShipViewController
        } else if parent is Checkout2ViewController {
            self.parent1 = parent as? Checkout2ViewController
        }
        
        // init data
        self.txtName.text = address.name
        self.txtPhone.text = address.phone
        if let provinceName = CDProvince.getProvinceNameWithID(address.provinceId), provinceName != "" {
            self.lbProvince.text = provinceName
            self.lbProvince.textColor = self.activeColor
        }
        if let regionName = CDRegion.getRegionNameWithID(address.regionId), regionName != "" {
            self.lbRegion.text = regionName
            self.lbRegion.textColor = self.activeColor
        }
        if address.subdistrictName != "" {
            self.lbSubdistrict.text = address.subdistrictName
            self.lbSubdistrict.textColor = self.activeColor
        }
        self.txtAddress.text = address.address
        self.txtPostalCode.text = address.postalCode
        
        // init default address
        if isDefault {
            // init default
            self.isDefault = true
            self.lbCheckbox.isHidden = false
            self.isSave = true
            
            self.btnPickProvince.isEnabled = false
            self.btnPickRegion.isEnabled = false
            self.btnPickSubdistric.isEnabled = false
            
            self.lbProvincePicker.textColor = self.disableColor
            self.lbRegionPicker.textColor = self.disableColor
            self.lbSubdistrictPicker.textColor = self.disableColor
            
        // init non-default
        } else {
            self.btnPickProvince.isEnabled = true
            self.btnPickRegion.isEnabled = true
            self.btnPickSubdistric.isEnabled = true
            
            self.lbProvincePicker.textColor = Theme.PrimaryColorDark
            self.lbRegionPicker.textColor = Theme.PrimaryColorDark
            self.lbSubdistrictPicker.textColor = Theme.PrimaryColorDark
            
            self.switchCheckbox(address.isSave)
            
            // new address over book
            if !isSaveAble {
                self.isSave = false
                
                self.isDefault = true
                self.isSaveAble = false
            }
        }
    }
    
    func switchCheckbox(_ isSave: Bool) {
        self.isSave = isSave
        
        if isSave {
            self.lbCheckbox.isHidden = false
        } else {
            self.lbCheckbox.isHidden = true
        }
    }
    
    static func heightFor() -> CGFloat {
        return 328.0
    }
    
    // MARK: - Picker Delegate
    func pickerDidSelect(_ item: String) {
        if (isPickingProvinsi) {
            lbProvince?.text = PickerViewController.HideHiddenString(item)
            lbProvince.textColor = UIColor.darkGray
            isPickingProvinsi = false
        } else if (isPickingKabKota) {
            lbRegion?.text = PickerViewController.HideHiddenString(item)
            lbRegion.textColor = UIColor.darkGray
            isPickingKabKota = false
            kecamatanPickerItems = []
        } else if (isPickingKecamatan) {
            lbSubdistrict?.text = PickerViewController.HideHiddenString(item)
            lbSubdistrict.textColor = UIColor.darkGray
            isPickingKecamatan = false
        }
    }
    
    func pickerCancelled() {
        isPickingProvinsi = false
        isPickingKabKota = false
        isPickingKecamatan = false
    }
    
    func pickKecamatan() {
        isPickingKecamatan = true
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = kecamatanPickerItems
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.selectedSubdistrictId = PickerViewController.RevealHiddenString(string)
            self.lbSubdistrict.text = string.components(separatedBy: PickerViewController.TAG_START_HIDDEN)[0]
            
            self.pickSubdistrict(self.selectedSubdistrictId, self.lbSubdistrict.text!) // region id -> global
        }
        p?.title = "Kecamatan"
        
        if let parent = self.parent2 {
            parent.navigationController?.pushViewController(p!, animated: true)
        } else if let parent = self.parent1 {
            parent.navigationController?.pushViewController(p!, animated: true)
        }
    }
    
    @IBAction func btnPickProvincePressed(_ sender: Any) {
        isPickingProvinsi = true
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = CDProvince.getProvincePickerItems()
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.selectedProvinceId = PickerViewController.RevealHiddenString(string)
            
            self.lbRegion.text = "Pilih Kota/Kabupaten"
            self.lbRegion.textColor = self.placeholderColor
            
            self.lbSubdistrict.text = "Pilih Kecamatan"
            self.lbSubdistrict.textColor = self.placeholderColor
            
            self.pickProvince(self.selectedProvinceId)
        }
        p?.title = "Provinsi"
        
        if let parent = self.parent2 {
            parent.navigationController?.pushViewController(p!, animated: true)
        } else if let parent = self.parent1 {
            parent.navigationController?.pushViewController(p!, animated: true)
        }
    }
    
    @IBAction func btnPickRegionPressed(_ sender: Any) {
        isPickingKabKota = true
        if (selectedProvinceId == "") {
            Constant.showDialog("Perhatian", message: "Pilih provinsi terlebih dahulu")
        } else {
            let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
            p?.items = CDRegion.getRegionPickerItems(selectedProvinceId)
            p?.pickerDelegate = self
            p?.selectBlock = { string in
                self.selectedRegionId = PickerViewController.RevealHiddenString(string)
                self.selectedSubdistrictId = ""
                
                self.lbSubdistrict.text = "Pilih Kecamatan"
                self.lbSubdistrict.textColor = self.placeholderColor
                
                self.pickRegion(self.selectedRegionId) // province id -> global
            }
            p?.title = "Kota/Kabupaten"
            
            if let parent = self.parent2 {
                parent.navigationController?.pushViewController(p!, animated: true)
            } else if let parent = self.parent1 {
                parent.navigationController?.pushViewController(p!, animated: true)
            }
        }
    }
    
    @IBAction func btnPickSubdistrictPressed(_ sender: Any) {
        if (selectedRegionId == "") {
            Constant.showDialog("Perhatian", message: "Pilih kota/kabupaten terlebih dahulu")
        } else {
            if (kecamatanPickerItems.count <= 0) {
                if let parent = self.parent2 {
                    parent.showLoading()
                } else if let parent = self.parent1 {
                    parent.showLoading()
                }
                
                // Retrieve kecamatanPickerItems
                let _ = request(APIMisc.getSubdistrictsByRegionID(id: self.selectedRegionId)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Kecamatan")) {
                        let json = JSON(resp.result.value!)
                        let data = json["_data"].arrayValue
                        
                        if (data.count > 0) {
                            for i in 0...data.count - 1 {
                                self.kecamatanPickerItems.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)
                            }
                            
                            self.pickKecamatan()
                        } else {
                            Constant.showDialog("Oops", message: "Kecamatan tidak ditemukan")
                        }
                    }
                    if let parent = self.parent2 {
                        parent.hideLoading()
                    } else if let parent = self.parent1 {
                        parent.hideLoading()
                    }
                }
            } else {
                self.pickKecamatan()
            }
        }
    }
    
    @IBAction func btnSavePressed(_ sender: Any) {
        if !self.isDefault {
            self.switchCheckbox(!self.isSave)
            
            self.saveAddress()
        } else if !self.isSaveAble {
            Constant.showDialog("Alamat Baru", message: "Buku Alamat telah mencapai batas, alamat ini tidak dapat disimpan.")
        }
    }
    
    // MARK: - Delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let parent = self.parent2 {
            if textField == txtName {
                parent.selectedAddress.name = textField.text!
            } else if textField == txtPhone {
                parent.selectedAddress.phone = textField.text!
            } else if textField == txtAddress {
                parent.selectedAddress.address = textField.text!
            } else if textField == txtPostalCode {
                parent.selectedAddress.postalCode = textField.text!
            }
        } else if let parent = self.parent1 {
            if textField == txtName {
                parent.selectedAddress.name = textField.text!
            } else if textField == txtPhone {
                parent.selectedAddress.phone = textField.text!
            } else if textField == txtAddress {
                parent.selectedAddress.address = textField.text!
            } else if textField == txtPostalCode {
                parent.selectedAddress.postalCode = textField.text!
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Class Checkout2AddressLocationCell
class Checkout2AddressLocationCell: UITableViewCell {
    @IBOutlet weak var lbLocation: UILabel!
    
    var pickLocation: ()->() = {} // open map
    
    var placeholderColor = UIColor.init(hex: "#CCCCCC")
    var activeColor = UIColor.init(hex: "#6F6F6F")
    
    func adapt(_ locationName: String?, coordinate: String?) {
        if let loc = locationName, let cor = coordinate, loc != "" && cor != "" {
            self.lbLocation.text = "Koordinat alamat sudah dipilih" //loc
            self.lbLocation.textColor = activeColor //Theme.PrimaryColorDark
        } else {
            self.lbLocation.text = "Pilih Lokasi (untuk Same Day Service)"
            self.lbLocation.textColor = Theme.PrimaryColorDark //placeholderColor
        }
    }
    
    static func heightFor() -> CGFloat {
        return 45.0
    }
    
    @IBAction func btnPickLocationPressed(_ sender: Any) {
        self.pickLocation()
    }
}

// MARK: - Class Checkout2TotalBuyingCell
class Checkout2TotalBuyingCell: UITableViewCell {
    @IBOutlet weak var lbTotalPrice: UILabel!
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var lbtitle: UILabel! // default
    
    var continueToPayment: ()->() = {}
    
    func adapt(_ totalPrice: String) {
        self.lbTotalPrice.text = totalPrice
    }
    
    static func heightFor() -> CGFloat {
        return 96.0
    }
    
    @IBAction func btnContinuePressed(_ sender: Any) {
        self.continueToPayment()
    }
}
