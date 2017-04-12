//
//  Checkout2ShipViewController.swift
//  Prelo
//
//  Created by Djuned on 4/12/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class
class Checkout2ShipViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var isFirst = true
    
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
            
            // getCart()
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
    
    var pickCourier: ()->() = {}
    
    func adapt(_ courierName: String, courierFee: String) {
        self.lbCourier.text = courierName + " (" + courierFee + ")"
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
    @IBOutlet weak var lbRegion: UILabel!
    @IBOutlet weak var lbSubdistrict: UILabel!
    @IBOutlet weak var txtAddress: UITextField!
    @IBOutlet weak var txtPostalCode: UITextField!
    
    // province/region/subdistrict id -> global
    
    var pickProvince: ()->() = {}
    var pickRegion: ()->() = {}
    var pickSubdistrict: ()->() = {}
    
    func adapt(_ address: AddressItem?) {
        if let addr = address {
            self.txtName.text = addr.recipientName
            self.txtPhone.text = addr.phone
            self.lbProvince.text = addr.provinceName
            self.lbRegion.text = addr.regionName
            self.lbSubdistrict.text = addr.subdisrictName
            self.txtAddress.text = addr.address
            self.txtPostalCode.text = addr.postalCode
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
