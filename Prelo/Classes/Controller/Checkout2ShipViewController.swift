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

// MARK: - Class
class Checkout2ShipViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var isFirst = true
    
    // AddressBook
    var addresses: Array<AddressItem> = []
    var isNeedSetup = false
    var selectedIndex = 0
    var isSave = false
    var defaultAddressIndex = 0
    var defaultSubdistrictId = ""
    
    var dropDown: DropDown!
    
    // Address
    var selectedProvinceId: String!
    var selectedRegionId: String!
    var selectedSubdistrictId: String!
    var selectedSubdistrictName: String!
    var selectedAddress: AddressItem?
    
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
        
        // title
        self.title = "Checkout"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isFirst {
            self.isFirst = false
            self.showLoading()
            
            // Setup table
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.tableFooterView = UIView()
            
            //TOP, LEFT, BOTTOM, RIGHT
            let inset = UIEdgeInsetsMake(0, 0, 0, 0)
            self.tableView.contentInset = inset
            
            self.tableView.separatorStyle = .none
            
            self.tableView.backgroundColor = UIColor(hexString: "#E8ECEE")
            
            self.getCart()
        }
    }
    
    // MARK: - badge trolli sync
    /*func getUnpaid() {// Get unpaid transaction
        let _ = request(APITransactionCheck.checkUnpaidTransaction).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Checkout - Unpaid Transaction")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if (data["user_has_unpaid_transaction"].boolValue == true) {
                    let nUnpaid = data["n_transaction_unpaid"].intValue
                    self.lblPaymentReminder.text = "Kamu memiliki \(nUnpaid) transaksi yg belum dibayar"
                    self.consHeightPaymentReminder.constant = 40
                    
                    self.transactionCount = nUnpaid
                    print(nUnpaid)
                    notifListener?.setCartCount(nUnpaid)
                    self.continueLoad()
                } else {
                    
                    notifListener?.setCartCount(0)
                    self.continueLoad()
                }
            } else {
                notifListener?.setCartCount(0)
                self.continueLoad()
            }
        }
    }*/
    
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
                }
            }
        }
    }
    
    // MARK: - Get Addresses
    func getAddresses() {
        let _ = request(APIMe.getAddressBook).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Address Book")) {
                if let x: AnyObject = resp.result.value as AnyObject? {
                    var json = JSON(x)
                    json = json["_data"]
                    
                    if let arr = json.array {
                        for i in 0...arr.count - 1 {
                            let address = AddressItem.instance(arr[i])
                            self.addresses.append(address!)
                            if (address?.isMainAddress)! {
                                self.selectedIndex = i
                                self.defaultAddressIndex = i
                                
                                // setup on init by using default address
                                //self.defaultSubdistrictId = (address?.subdisrictId)!
                                //self.selectedAddress = address!
                            }
                        }
                        
                        self.setupDropdownAddress()
                        //self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    // MARK: - UITableView Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        dropDown = DropDown()
        dropDown.dataSource = []
        
        for i in 0...addresses.count - 1 {
            
            let address = addresses[i]
            let text = address.recipientName + " (" + address.addressName + ") " + address.address + " " + address.subdisrictName + ", " + address.regionName + " " + address.provinceName + " " + address.postalCode

            dropDown.dataSource.append(text)
        }
        
        if (addresses.count < 5) {
            dropDown.dataSource.append("Alamat Baru")
        }
        
        dropDown.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
            if index < self.addresses.count {
                cell.viewWithTag(999)?.removeFromSuperview()
                
                // Setup your custom UI components
                cell.optionLabel.text = ""
                let y = (cell.height - cell.optionLabel.height) / 2.0
                let rectOption = CGRect(x: 16, y: y, width: cell.width - (16 + 16), height: cell.optionLabel.height)
                
                let label = UILabel(frame: rectOption)
                label.font = cell.optionLabel.font
                label.tag = 999
                
                let attString : NSMutableAttributedString = NSMutableAttributedString(string: item)
                
                attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)], range: (item as NSString).range(of: self.addresses[index].recipientName))
                
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
                if index < self.addresses.count {
                    self.isNeedSetup = false
                    self.selectedIndex = index
                    self.selectedAddress = self.addresses[index]
                } else {
                    self.isNeedSetup = true
                    self.selectedIndex = self.addresses.count
                    self.selectedAddress = nil
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
        return 70.0
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
    
    var productDetail: ProductDetail!
    
    var remove: (String)->() = {_ in }
    
    func adapt(_ productDetail: ProductDetail) {
        self.productDetail = productDetail
    }
    
    static func heightFor() -> CGFloat {
        return 97.0
    }
    
    @IBAction func btnRemovePressed(_ sender: Any) {
        self.remove(self.productDetail.itemId)
    }
}

// MARK: - Class Checkout2CourierCell
class Checkout2CourierCell: UITableViewCell {
    @IBOutlet weak var lbCourier: UILabel!
    @IBOutlet weak var lbDropdown: UILabel!
    
    var disableColor = UIColor.lightGray
    
    var pickCourier: ()->() = {}
    
    func adapt(_ courierName: String, courierFee: String, isEnable: Bool) {
        self.lbCourier.text = courierName + " (" + courierFee + ")"
        
        if isEnable {
            self.lbDropdown.textColor = self.disableColor
        } else {
            self.lbDropdown.textColor = Theme.PrimaryColorDark
        }
    }
    
    static func heightFor() -> CGFloat {
        return 37.0
    }
    
    @IBAction func btnPickCourierPressed(_ sender: Any) {
        self.pickCourier()
    }
}

// MARK: - Class Checkout2CourierDescriptionCell
class Checkout2CourierDescriptionCell: UITableViewCell {
    @IBOutlet weak var lbDescriptionCourier: UILabel!
    
    func adapt(_ courierName: String) {
        self.lbDescriptionCourier.text = "Silahkan lengkapi lokasi jika kamu memilih kurir " + courierName
    }
    
    static func heightFor(_ isNeed: Bool) -> CGFloat {
        if isNeed {
            return 35.0
        }
        return 0.0
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
    @IBOutlet weak var lbDetailAddress: UILabel!
    
    var pickAddress: ()->() = {}
    
    func adapt(_ address: AddressItem) {
        self.lbDetailAddress.text = address.recipientName + " (" + address.addressName + ") " + address.address + " " + address.subdisrictName + ", " + address.regionName + ", " + address.provinceName + " " + address.postalCode
    }
    
    static func heightFor(_ isNeed: Bool) -> CGFloat {
        return 92.0
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
    
    static func heightFor(_ isNeed: Bool) -> CGFloat {
        return 138.0
    }
}

// MARK: - Class Checkout2AddressFillCell
class Checkout2AddressFillCell: UITableViewCell {
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
    
    var pickProvince: ()->() = {} // change province & color
    var pickRegion: ()->() = {} // change region & color
    var pickSubdistrict: ()->() = {} // change subdistrict & color
    
    var disableColor = UIColor.lightGray
    var placeholderColor = UIColor.init(hex: "#CCCCCC")
    var activeColor = UIColor.init(hex: "#6F6F6F")
    
    func adapt(_ address: AddressItem?, isDefault: Bool, isSave: Bool) {
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
    
    static func heightFor(_ isNeed: Bool) -> CGFloat {
        return 312.0
    }
    
    @IBAction func btnPickProvincePressed(_ sender: Any) {
        self.pickProvince()
    }
    
    @IBAction func btnPickRegionPressed(_ sender: Any) {
        self.pickRegion() // province id -> global
    }
    
    @IBAction func btnPickSubdistrictPressed(_ sender: Any) {
        self.pickRegion() // region id -> global
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
        return 40.0
    }
    
    @IBAction func btnContinuePressed(_ sender: Any) {
        self.continueToPayment()
    }
}
