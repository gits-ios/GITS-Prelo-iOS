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

// MARK: - Protocol
struct SelectedAddressItem {
    var name: String = ""
    var phone: String = ""
    var address: String = ""
    var postalCode: String = ""
    var provinceId: String = ""
    var regionId: String = ""
    var subdistrictId: String = ""
    var subdistrictName: String = ""
}

// MARK: - Class
class Checkout2ShipViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var isFirst = true
    var shouldBack = false
    
    var dropDown = DropDown()
    
    // Address
    var selectedAddress = SelectedAddressItem()
    
    var selectedIndex = 0
    var isNeedSetup = false
    var isSave = false
    var isNeedLocation = false
    
    // Cart Results
    var cartResult: CartV2ResultItem!
    
//    var selectedShippingIds: Array<String>!
    var ongkirs: Array<Int>!
    var isFreeOngkirs: Array<Bool>!
    var selectedOngkirIndexes: Array<Int>!
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let Checkout2SellerCell = UINib(nibName: "Checkout2SellerCell", bundle: nil)
        tableView.register(Checkout2SellerCell, forCellReuseIdentifier: "Checkout2SellerCell")
        
        let Checkout2ProductCell = UINib(nibName: "Checkout2ProductCell", bundle: nil)
        tableView.register(Checkout2ProductCell, forCellReuseIdentifier: "Checkout2ProductCell")
        
        let Checkout2CourierCell = UINib(nibName: "Checkout2CourierCell", bundle: nil)
        tableView.register(Checkout2CourierCell, forCellReuseIdentifier: "Checkout2CourierCell")
        
        let Checkout2CourierDescriptionCell = UINib(nibName: "Checkout2CourierDescriptionCell", bundle: nil)
        tableView.register(Checkout2CourierDescriptionCell, forCellReuseIdentifier: "Checkout2CourierDescriptionCell")
        
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
        
        self.tableView.backgroundColor = UIColor(hexString: "#E8ECEE")
        
        // loading
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.7)
        
        // title
        self.title = "Checkout"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isFirst {
            self.showLoading()
            
            self.getCart()
        }
    }
    
    // MARK: - Cart sync
    func getCart() {
        // Get cart from server
        let _ = request(APICart.getCart).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Checkout - Get Cart")) {
                let json = JSON(resp.result.value!)
                if let arr = json["_data"].array {
                    for a in arr {
                        let spId = a["shipping_package_id"].stringValue
                        let pId  = a["product_id"].stringValue
                        let pName  = a["product_name"].stringValue
                        
                        if let cp = CartProduct.getOne(pId, email: User.EmailOrEmptyString) {
                            if cp.packageId != spId {
                                cp.packageId = spId
                            }
                        } else {
                            if let cp2 = CartProduct.newOne(pId, email: User.EmailOrEmptyString, name: pName) {
                                cp2.packageId = spId
                            }
                        }
                    }
                    
                    // init default shipping
                    let userProfile = CDUserProfile.getOne()
                    self.selectedAddress.provinceId = (userProfile?.provinceID)!
                    self.selectedAddress.regionId = (userProfile?.regionID)!
                    self.selectedAddress.subdistrictId = (userProfile?.subdistrictID)!
                    self.selectedAddress.subdistrictName = (userProfile?.subdistrictName)!
                    
                    self.synchCart()
                }
            }
        }
    }
    
    // Refresh data cart dan seluruh tampilan
    func synchCart() {
        self.showLoading()
        
        // Prepare parameter for API refresh cart
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        if (c.count <= 0 && self.shouldBack == false) {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        let p = AppToolsObjC.jsonString(from: c)
        let a = "{\"address\": \"alamat\", \"province_id\": \"" + selectedAddress.provinceId + "\", \"region_id\": \"" + selectedAddress.regionId + "\", \"subdistrict_id\": \"" + selectedAddress.subdistrictId + "\", \"postal_code\": \"\"}"
        //print("cart_products : \(String(describing: p))")
        //print("shipping_address : \(a)")
        
        // API refresh cart
        let _ = request(APIV2Cart.refresh(cart: p!, address: a, voucher: nil)).responseJSON { resp in
            if (PreloV2Endpoints.validate(true, dataResp: resp, reqAlias: "Keranjang Belanja")) {
                
                // Back to prev page if cart is empty
                if (self.shouldBack == true) {
                    _ = self.navigationController?.popViewController(animated: true)
                    return
                }
                
                // Json
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                self.cartResult = CartV2ResultItem.instance(data)
                
//                self.selectedShippingIds = []
                self.ongkirs = []
                self.isFreeOngkirs = []
                self.selectedOngkirIndexes = []
                for sp in self.cartResult.cartDetails {
//                    self.selectedShippingIds.append(sp.shippingPackageId)
//                    for s in sp.shippingPackages {
//                        if s.id == sp.shippingPackageId {
//                            self.ongkirs.append(s.price)
//                            self.isFreeOngkirs.append(s.price == 0)
//                            
//                            break
//                        }
//                    }
                    
                    // reset to 0
                    self.ongkirs.append(sp.shippingPackages[0].price)
                    self.isFreeOngkirs.append(sp.shippingPackages[0].price == 0)
                    self.selectedOngkirIndexes.append(0)
                }
                
                if self.isFirst && self.cartResult.addressBook.count > 0 {
                    for i in 0...self.cartResult.addressBook.count-1 {
                        if self.cartResult.addressBook[i].isMainAddress {
                            self.selectedIndex = i
                            break
                        }
                    }
                    
                    self.isFirst = false
                }
                
                self.setupDropdownAddress()
                
                self.tableView.reloadData()
                
                self.hideLoading()
            }
        }
    }
    
    // MARK: - UITableView Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            return 2 + cartResult.cartDetails.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < cartResult.cartDetails.count {
            if cartResult.cartDetails[section].isNeedLocation == true {
                self.isNeedLocation = true
            }
            return cartResult.cartDetails[section].products.count + 2 + (cartResult.cartDetails[section].isNeedLocation ? 1 : 0) + 1
        } else if section == cartResult.cartDetails.count {
            return 2 + (isNeedLocation ? 1 : 0) + 1
        } else if section == cartResult.cartDetails.count + 1 {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let idx = indexPath as IndexPath
        if idx.section < cartResult.cartDetails.count {
            if cartResult.cartDetails[idx.section].isNeedLocation == true {
                self.isNeedLocation = true
            }
            if idx.row == 0 {
                return Checkout2SellerCell.heightFor()
            } else if idx.row <= cartResult.cartDetails[idx.section].products.count {
                return Checkout2ProductCell.heightFor()
            } else if idx.row == cartResult.cartDetails[idx.section].products.count + 1 {
                return Checkout2CourierCell.heightFor()
            } else {
                if idx.row == cartResult.cartDetails[idx.section].products.count + 2 && cartResult.cartDetails[idx.section].isNeedLocation {
                    return Checkout2CourierDescriptionCell.heightFor()
                } else {
                    return Checkout2SplitCell.heightFor()
                }
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
                if idx.row == 2 && isNeedLocation {
                    return Checkout2AddressLocationCell.heightFor()
                } else {
                    return Checkout2SplitCell.heightFor()
                }
            }
        } else if idx.section == cartResult.cartDetails.count + 1 {
            return Checkout2TotalBuyingCell.heightFor()
        }
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idx = indexPath as IndexPath
        if ((indexPath as NSIndexPath).section < cartResult.cartDetails.count) {
            if cartResult.cartDetails[idx.section].isNeedLocation == true {
                self.isNeedLocation = true
            }
            if idx.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2SellerCell") as! Checkout2SellerCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                var pids: Array<String> = []
                for p in self.cartResult.cartDetails[idx.section].products {
                    pids.append(p.productId)
                }
                
                cell.adapt(self.cartResult.cartDetails[idx.section].fullname, productIds: pids)
                
                return cell
            } else if idx.row <= cartResult.cartDetails[idx.section].products.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2ProductCell") as! Checkout2ProductCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                cell.adapt(self.cartResult.cartDetails[idx.section].products[idx.row-1])
                
                return cell
            } else if idx.row == cartResult.cartDetails[idx.section].products.count + 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2CourierCell") as! Checkout2CourierCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                cell.adapt(cartResult.cartDetails[idx.section].shippingPackages, isEnable: !self.isFreeOngkirs[idx.section], selectedIndex: self.selectedOngkirIndexes[idx.section])
                
                cell.pickCourier = { courierId, ongkir, index in
                    //self.selectedShippingIds[idx.section] = result // update shipping
                    
                    self.ongkirs[idx.section] = ongkir
                    self.selectedOngkirIndexes[idx.section] = index
                    
                    for p in self.cartResult.cartDetails[idx.section].products {
                        if let cp = CartProduct.getOne(p.productId, email: User.EmailOrEmptyString) {
                            if cp.packageId != courierId {
                                cp.packageId = courierId
                            }
                        }
                    }
                }
                
                return cell
            } else {
                if idx.row == cartResult.cartDetails[idx.section].products.count + 2 && cartResult.cartDetails[idx.section].isNeedLocation {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2CourierDescriptionCell") as! Checkout2CourierDescriptionCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt("GO-SEND") // TODO: - Dinamis
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2SplitCell") as! Checkout2SplitCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    return cell
                }
            }
        } else if idx.section == cartResult.cartDetails.count {
            if idx.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2AddressDropdownCell") as! Checkout2AddressDropdownCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                cell.adapt((cartResult.addressBook.count > selectedIndex ? cartResult.addressBook[selectedIndex] : nil))
                
                self.dropDown.anchorView = cell.vwBorder
                
                // Top of drop down will be below the anchorView
                self.dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)! + 4)
                
                cell.pickAddress = {
                    self.dropDown.hide()
                    self.dropDown.show()
                }
                
                return cell
            } else if idx.row == 1 {
                if isNeedSetup {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2AddressFillCell") as! Checkout2AddressFillCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt(cartResult.addressBook.count > selectedIndex ? cartResult.addressBook[selectedIndex] : nil, isDefault: cartResult.addressBook.count > selectedIndex ? cartResult.addressBook[selectedIndex] == cartResult.defaultAddress : false, isSave: isSave, parent: self)
                    
                    // inject
                    if selectedAddress.provinceId != "" {
                        cell.lbProvince.text = CDProvince.getProvinceNameWithID(selectedAddress.provinceId)
                        cell.lbProvince.textColor = cell.activeColor
                        cell.selectedProvinceId = self.selectedAddress.provinceId
                    }
                    if selectedAddress.regionId != "" {
                        cell.lbRegion.text = CDRegion.getRegionNameWithID(selectedAddress.regionId)
                        cell.lbRegion.textColor = cell.activeColor
                        cell.selectedRegionId = self.selectedAddress.regionId
                    }
                    if selectedAddress.subdistrictId != "" {
                        cell.lbSubdistrict.text = selectedAddress.subdistrictId
                        cell.lbSubdistrict.textColor = cell.activeColor
                        cell.selectedSubdistrictId = self.selectedAddress.subdistrictId
                    }
                    
                    cell.pickProvince = { provinceId in
                        self.selectedAddress.provinceId = provinceId
                        self.selectedAddress.regionId = ""
                        self.selectedAddress.subdistrictId = ""
                        self.selectedAddress.subdistrictName = ""
                    }
                    
                    cell.pickRegion = { regionId in
                        self.selectedAddress.regionId = regionId
                        self.selectedAddress.subdistrictId = ""
                        self.selectedAddress.subdistrictName = ""
                    }
                    
                    cell.pickSubdistrict = { subdistrictId, subdistrictName in
                        self.selectedAddress.subdistrictId = subdistrictId
                        self.selectedAddress.subdistrictName = subdistrictName
                        
                        self.synchCart()
                        
                        self.tableView.reloadData()
                    }
                    
                    cell.saveAddress = {
                        self.isSave = !self.isSave
                        self.tableView.reloadData()
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
                if idx.row == 2 && isNeedLocation {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2AddressLocationCell") as! Checkout2AddressLocationCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt("") // TODO: - Coordinate
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2SplitCell") as! Checkout2SplitCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    return cell
                }
            }
        } else if idx.section == cartResult.cartDetails.count + 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2TotalBuyingCell") as! Checkout2TotalBuyingCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            var totalWithOngkir = cartResult.totalPrice
            
            for o in ongkirs {
                totalWithOngkir += o
            }
            
            cell.adapt(totalWithOngkir.asPrice)
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // do nothing
    }
    
    // MARK: - Other
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    // MARK: - Setup Dropdown Address
    func setupDropdownAddress() {
        dropDown.dataSource = []
        
        let count = cartResult.addressBook.count
        
        for address in cartResult.addressBook {
            
            let text = address.recipientName + " (" + address.addressName + ") " + address.address + " " + address.subdisrictName + ", " + address.regionName + " " + address.provinceName + " " + address.postalCode

            dropDown.dataSource.append(text)
        }
        
        if (count < 5) {
            dropDown.dataSource.append("Alamat Baru")
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
                if index < count {
                    self.isNeedSetup = false
                    self.selectedIndex = index
                    
                    self.selectedAddress.provinceId = self.cartResult.addressBook[index].provinceId
                    self.selectedAddress.regionId = self.cartResult.addressBook[index].regionId
                    self.selectedAddress.subdistrictId = self.cartResult.addressBook[index].subdisrictId
                    self.selectedAddress.subdistrictName = self.cartResult.addressBook[index].subdisrictName
                    
                    self.synchCart()
                } else {
                    self.isNeedSetup = true
                    self.selectedIndex = count
                    
                    self.selectedAddress.provinceId = ""
                    self.selectedAddress.regionId = ""
                    self.selectedAddress.subdistrictId = ""
                    self.selectedAddress.subdistrictName = ""
                }
                
                self.tableView.reloadData()
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        dropDown.cellHeight = 40
        dropDown.selectRow(at: self.selectedIndex)
        dropDown.direction = .bottom
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
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lbProductName: UILabel!
    @IBOutlet weak var lbProductPrice: UILabel!
    
    var productDetail: ProductItem!
    
    var remove: (String)->() = {_ in }
    
    func adapt(_ productDetail: ProductItem) {
        self.productDetail = productDetail
        
        self.imgProduct.afSetImage(withURL: productDetail.displayPicts[0], withFilter: .fill)
        self.lbProductName.text = productDetail.name
        self.lbProductPrice.text = productDetail.price.asPrice
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
    
    var selectedIndex = 0
    
    var dropDown = DropDown()
    
    var shippingPackages: Array<ShippingPackageItem>!
    
    var disableColor = UIColor.lightGray
    
    var isEnable = true
    
    var pickCourier: (_ courierId: String, _ ongkir: Int, _ index: Int)->() = {_, _, _ in }
    
    func adapt(_ shippingPackages: Array<ShippingPackageItem>, isEnable: Bool, selectedIndex: Int) {
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
                self.pickCourier(self.shippingPackages[self.selectedIndex].shippingId, self.shippingPackages[self.selectedIndex].price, self.selectedIndex)
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        dropDown.cellHeight = 40
        dropDown.selectRow(at: self.selectedIndex)
        dropDown.direction = .bottom
        dropDown.anchorView = self.btnPickCourier
        
        // Top of drop down will be below the anchorView
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)! + 4)
    }
    
    @IBAction func btnPickCourierPressed(_ sender: Any) {
        if self.isEnable {
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
            self.lbDetailAddress.text = "Alamat Baru"
        }
    }
    
    static func heightFor() -> CGFloat {
        return 76.0
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
        self.lbPhone.text = "Telepon: " + address.phone
    }
    
    static func heightFor() -> CGFloat {
        return 138.0
    }
}

// MARK: - Class Checkout2AddressFillCell
class Checkout2AddressFillCell: UITableViewCell, PickerViewDelegate {
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
    
    var parent: Checkout2ShipViewController!
    
    func adapt(_ address: AddressItem?, isDefault: Bool, isSave: Bool, parent: Checkout2ShipViewController) {
        self.parent = parent
        
        self.lbProvince.text = "Pilih Provinsi"
        self.lbProvince.textColor = self.placeholderColor
        
        self.lbRegion.text = "Pilih Kota/Kabupaten"
        self.lbRegion.textColor = self.placeholderColor
        
        self.lbSubdistrict.text = "Pilih Kecamatan"
        self.lbSubdistrict.textColor = self.placeholderColor
        
        if let addr = address {
            self.txtName.text = addr.recipientName
            self.txtPhone.text = addr.phone
            self.lbProvince.text = addr.provinceName
            self.lbRegion.text = addr.regionName
            self.lbSubdistrict.text = addr.subdisrictName
            self.txtAddress.text = addr.address
            self.txtPostalCode.text = addr.postalCode
            
            self.lbProvince.textColor = self.activeColor
            self.lbRegion.textColor = self.activeColor
            self.lbSubdistrict.textColor = self.activeColor
        }
        
        if isDefault {
            self.btnPickProvince.isEnabled = false
            self.btnPickRegion.isEnabled = false
            self.btnPickSubdistric.isEnabled = false
            
            self.lbProvincePicker.textColor = self.disableColor
            self.lbRegionPicker.textColor = self.disableColor
            self.lbSubdistrictPicker.textColor = self.disableColor
            
            self.lbCheckbox.isHidden = false // force save
        } else {
            self.btnPickProvince.isEnabled = true
            self.btnPickRegion.isEnabled = true
            self.btnPickSubdistric.isEnabled = true
            
            self.lbProvincePicker.textColor = Theme.PrimaryColorDark
            self.lbRegionPicker.textColor = Theme.PrimaryColorDark
            self.lbSubdistrictPicker.textColor = Theme.PrimaryColorDark
            
            if isSave {
                self.lbCheckbox.isHidden = false
            } else {
                self.lbCheckbox.isHidden = true
            }
        }
    }
    
    static func heightFor() -> CGFloat {
        return 340.0
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
        parent.navigationController?.pushViewController(p!, animated: true)
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
        parent.navigationController?.pushViewController(p!, animated: true)
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
            parent.navigationController?.pushViewController(p!, animated: true)
        }
    }
    
    @IBAction func btnPickSubdistrictPressed(_ sender: Any) {
        if (selectedRegionId == "") {
            Constant.showDialog("Perhatian", message: "Pilih kota/kabupaten terlebih dahulu")
        } else {
            if (kecamatanPickerItems.count <= 0) {
                parent.showLoading()
                
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
                    self.parent.hideLoading()
                }
            } else {
                self.pickKecamatan()
            }
        }
    }
    
    @IBAction func btnSavePressed(_ sender: Any) {
        self.saveAddress()
    }
}

// MARK: - Class Checkout2AddressLocationCell
class Checkout2AddressLocationCell: UITableViewCell {
    @IBOutlet weak var lbLocation: UILabel!
    
    var pickLocation: ()->() = {} // open map
    
    func adapt(_ locationName: String?) {
        if let loc = locationName {
            self.lbLocation.text = loc
        } else {
            self.lbLocation.text = "Pilih Lokasi"
        }
    }
    
    static func heightFor() -> CGFloat {
        return 37.0
    }
    
    @IBAction func btnPickLocationPressed(_ sender: Any) {
    }
}

// MARK: - Class Checkout2TotalBuyingCell
class Checkout2TotalBuyingCell: UITableViewCell {
    @IBOutlet weak var lbTotalPrice: UILabel!
    
    var continueToPayment: ()->() = {}
    
    func adapt(_ totalPrice: String) {
        self.lbTotalPrice.text = totalPrice
    }
    
    static func heightFor() -> CGFloat {
        return 108.0
    }
    
    @IBAction func btnContinuePressed(_ sender: Any) {
        self.continueToPayment()
    }
}
