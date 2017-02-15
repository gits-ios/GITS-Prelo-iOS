//
//  CartViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/3/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire
import DropDown

// MARK: - Class

enum PaymentMethod {
    case bankTransfer
    case creditCard
    case indomaret
    
    var value : String {
        switch self {
        case .bankTransfer : return "Bank Transfer"
        case .creditCard : return "Credit Card"
        case .indomaret : return "Indomaret"
        }
    }
}

class CartViewController: BaseViewController, ACEExpandableTableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITextFieldDelegate, CartItemCellDelegate, UserRelatedDelegate, PreloBalanceInputCellDelegate, VoucherInputCellDelegate {
    
    // MARK: - Struct
    
    struct DiscountItem {
        var title : String = ""
        var value : Int = 0
    }

    // MARK: - Properties
    
    // Data container
    var user : CDUser? = CDUser.getOne()
    var currentCart : JSON? // Balikan API refresh cart
    var checkoutResult : JSON? // Balikan API checkout
    var arrayItem : [JSON] = [] // Bagian cart_details dari balikan API refresh cart
    var cartProducts : [CartProduct] = [] // Products dari core data
    var selectedProvinsiID : String = ""
    var selectedKotaID : String = ""
    var selectedKecamatanID : String = ""
    var selectedKecamatanName : String = ""
    var kecamatanPickerItems : [String] = []
    var shouldBack : Bool = false
    var refreshByLocationChange : Bool = false
    
    // Prices and discounts data container
    var bankTransferDigit : Int = 0
    var isUsingPreloBalance : Bool = false
    var isHalfBonusMode : Bool = false // Apakah aturan half bonus aktif
    var customBonusPercent : Int = 0 // Aturan bonus custom
    var isUsingReferralBonus : Bool = false
    var balanceAvailable : Int = 0
    var isShowVoucher : Bool = false
    var isVoucherApplied : Bool = false
    var voucherApplied : String = ""
    var voucherTyped : String = ""
    var discountItems : [DiscountItem] = [] // Untuk balance, bonus, voucher
    var subtotalPrice : Int = 0 // Jumlah harga semua produk + ongkir
    var priceAfterDiscounts : Int = 0 // subtotalPrice dikurangi semua diskon
    var totalOngkir : Int = 0 // Jumlah ongkir dari semua produk
    var grandTotal : Int = 0 // Total pembayaran
    
    // Cell data container
    var cellsData : [IndexPath : BaseCartData] = [:]
    
    // Payment reminder
    @IBOutlet weak var lblPaymentReminder: UILabel!
    @IBOutlet weak var consHeightPaymentReminder: NSLayoutConstraint!
    
    // Table, loading, label, send btn
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var captionNoItem: UILabel!
    @IBOutlet weak var loadingCart: UIActivityIndicatorView!
    @IBOutlet weak var lblSend: UILabel!
    @IBOutlet weak var consHeightLblSend: NSLayoutConstraint!
    @IBOutlet weak var btnSend : UIButton!
    
    // Metode pembayaran
    var selectedPayment : PaymentMethod = .bankTransfer
    
    // Sections
    let sectionProducts = 0
    let sectionDataUser = 1
    let sectionAlamatUser = 2
    let sectionPayMethod = 3
    let sectionPaySummary = 4
    
    // Field titles
    let titleNama = "Nama"
    let titleTelepon = "Telepon"
    let titleAlamat = "Alamat" //"Mis: Jl. Tamansari III no. 1"
    let titleProvinsi = "Provinsi"
    let titleKota = "Kota/Kab"
    let titleKecamatan = "Kecamatan"
    let titlePostal = "Kode Pos"
    
    // Address
    var address = ""
    var addressHeight = 44
    
    // Others
    var isShowBankBRI : Bool = false
    var isEnableCCPayment : Bool = false
    var isEnableIndomaretPayment : Bool = false
    
    var transactionCount = 0
    
    // AddressBok
    var addresses: Array<AddressItem> = []
    var isNeedSetup = false
    var selectedIndex = 0
    var isSave = false
    var isFirst = true
    
    var dropDown: DropDown!
    
    var selectedBankIndex = -1
    var targetBank = ""
    
    // MARK: - Init
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.Checkout)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Checkout)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Keyboard animation
        self.an_subscribeKeyboard(animations: { r, i, o in
            if (o) {
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
            } else {
                self.tableView.contentInset = UIEdgeInsets.zero
            }
        }, completion: nil)
        
        // Perform tour for first time checkout
        let checkTour = UserDefaults.standard.bool(forKey: "cartTour")
        if (checkTour == false) {
            UserDefaults.standard.set(true, forKey: "cartTour")
            UserDefaults.standard.synchronize()
            Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CartViewController.performSegTour), userInfo: nil, repeats: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = PageName.Checkout
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = appDelegate.preloNotifListener
        notifListener?.setCartCount(0)
        
        if (user != nil) {
            self.getUnpaid()
        }
        
        // Get cart products
        cartProducts = CartProduct.getAll(User.EmailOrEmptyString)
        
        // Init table
        if (cartProducts.count == 0) { // Cart is empty
            tableView.isHidden = true
            loadingCart.isHidden = true
            captionNoItem.isHidden = false
        } else {
            if (user == nil) { // User isn't logged in
                tableView.isHidden = true
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            } else { // Show cart
                notifListener?.increaseCartCount(cartProducts.count)
                
                initUserDataSections()
                synchCart()
                
                self.getAddresses()
            }
            
        }
    }
    
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
                            }
                        }
                        
                        self.setupDropdownAddress()
                        
                        self.tableView.reloadData()
                    }
                }
                
            }
        }
    }
    
    func setupDropdownAddress() {
        dropDown = DropDown()
        
        // The list of items to display. Can be changed dynamically
        //                dropDown.dataSource = ["Car", "Motorcycle", "Truck"]
        dropDown.dataSource = []
        
        for i in 0...addresses.count - 1 {
//            dropDown.dataSource.append(addresses[i].addressName)
            
            let address = addresses[i]
            let text = address.recipientName + " (" + address.addressName + ") " + address.address + " " + address.subdisrictName + ", " + address.regionName + " " + address.provinceName + " " + address.postalCode
            
//            let attString : NSMutableAttributedString = NSMutableAttributedString(string: text)
//            
//            attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)], range: (text as NSString).range(of: address.recipientName))
//            
            dropDown.dataSource.append(text)
        }
        
        if (addresses.count < 5) {
            dropDown.dataSource.append("Alamat Baru")
        }
        
        dropDown.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
            if index < self.addresses.count {
            let attString : NSMutableAttributedString = NSMutableAttributedString(string: item)
            
            attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)], range: (item as NSString).range(of: self.addresses[index].recipientName))
            
            // Setup your custom UI components
            cell.optionLabel.attributedText = attString
            }
        }
        
        
        // Action triggered on selection
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            if index != self.selectedIndex {
                if index < self.addresses.count {
                    self.isNeedSetup = false
                    self.selectedIndex = index
                } else {
                    self.isNeedSetup = true
                    self.selectedIndex = self.addresses.count
                }
                
                self.initUserDataSections()
                self.tableView.reloadData()
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        
        dropDown.width = UIScreen.main.bounds.width - 16
        
//        dropDown.cellHeight = 30
        
        dropDown.selectRow(at: self.selectedIndex)
        
    }
    
    func getUnpaid() {
        // Get unpaid transaction
        let _ = request(APITransactionCheck.checkUnpaidTransaction).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Checkout - Unpaid Transaction")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if (data["user_has_unpaid_transaction"].boolValue == true) {
                    let nUnpaid = data["n_transaction_unpaid"].intValue
                    self.lblPaymentReminder.text = "Kamu memiliki \(nUnpaid) transaksi yg belum dibayar"
                    self.consHeightPaymentReminder.constant = 40
                    
                    self.transactionCount = nUnpaid
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let notifListener = appDelegate.preloNotifListener
                    notifListener?.increaseCartCount(nUnpaid)
                }
            }
        }
    }
    
    // Refresh data cart dan seluruh tampilan
    func synchCart() {
        // Hide table
        if isFirst {
            tableView.isHidden = true
            loadingCart.isHidden = false
            isFirst = false
        }
            
        // Reset data
        isUsingPreloBalance = false
        discountItems = []
//        initUserDataSections()
        
        // Prepare parameter for API refresh cart
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        if (c.count <= 0 && self.shouldBack == false) {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        let p = AppToolsObjC.jsonString(from: c)
        let a = "{\"address\": \"alamat\", \"province_id\": \"" + selectedProvinsiID + "\", \"region_id\": \"" + selectedKotaID + "\", \"subdistrict_id\": \"" + selectedKecamatanID + "\", \"postal_code\": \"\"}"
        print("cart_products : \(p)")
        print("shipping_address : \(a)")
        
        // API refresh cart
        let _ = request(APICart.refresh(cart: p!, address: a, voucher: voucherApplied)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Keranjang Belanja")) {
                
                // Back to prev page if cart is empty
                if (self.shouldBack == true) {
                    _ = self.navigationController?.popViewController(animated: true)
                    return
                }
                
                // Json
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                self.currentCart = data
                self.arrayItem = data["cart_details"].array!
                //print("arrayItem = \(self.arrayItem)")
                
                // Ab test check
                self.isHalfBonusMode = false
                self.customBonusPercent = 0
                self.isShowBankBRI = false
                self.isEnableCCPayment = false
                self.isEnableIndomaretPayment = false
                if let ab = data["ab_test"].array {
                    for i in 0...ab.count - 1 {
                        if (ab[i].stringValue.lowercased() == "half_bonus") {
                            self.isHalfBonusMode = true
                        } else if (ab[i].stringValue.lowercased() == "bri") {
                            self.isShowBankBRI = true
                        } else if (ab[i].stringValue.lowercased() == "cc") {
                            self.isEnableCCPayment = true
                        } else if (ab[i].stringValue.lowercased() == "indomaret") {
                            self.isEnableIndomaretPayment = true
                        } else if (ab[i].stringValue.lowercased().range(of: "bonus:") != nil) {
                            self.customBonusPercent = Int(ab[i].stringValue.components(separatedBy: "bonus:")[1])!
                        }
                    }
                }
                
                // Show modal text if any
                if let modalText = data["modal_verify_text"].string {
                    if (!modalText.isEmpty) {
                        Constant.showDialog("Perhatian", message: modalText)
                    }
                }
                
                // Discount items
                self.balanceAvailable = data["balance_available"].intValue
                if let voucherValid = data["voucher_valid"].bool {
                    if (voucherValid == true) {
                        if let voucherAmount = data["voucher_amount"].int {
                            self.isVoucherApplied = true
                            self.voucherApplied = data["voucher_serial"].stringValue
                            let discVoucher = DiscountItem(title: "Voucher '" + self.voucherApplied + "'", value: voucherAmount)
                            self.discountItems.append(discVoucher)
                        }
                    } else {
                        if let voucherError = data["voucher_error"].string {
                            Constant.showDialog("Invalid Voucher", message: voucherError)
                        }
                    }
                }
                let bonus = data["bonus_available"].intValue
                if (bonus > 0) {
                    self.isUsingReferralBonus = true
                    let disc = DiscountItem(title: "Referral Bonus", value: bonus)
                    self.discountItems.append(disc)
                } else {
                    self.isUsingReferralBonus = false
                }
                
                // Bank transfer digit
                self.bankTransferDigit = data["banktransfer_digit"].intValue
                
                self.adjustTotal()
                
                // Reset refreshByLocationChange
                self.refreshByLocationChange = false
            }
        }
    }
    
    // Membuat cellsData untuk section data user dan alamat user
    func initUserDataSections() {
        
        // Prepare textfield value --> global
        var fullname = ""
        var phone = ""
        var address = ""
        var postalcode = ""
        var pID = ""
        var rID = ""
        var sdID = ""
        
        if isFirst {
//            isFirst = false
        if let x = user?.fullname {
            fullname = x
        }
        
        if let profile = user?.profiles {
            if let x = profile.phone {
                phone = x
            }
            
            if let x = profile.address {
                address = x
            }
            
            if let x = profile.postalCode {
                postalcode = x
            }
            
            pID = profile.provinceID
            rID = profile.regionID
            
            if (!self.refreshByLocationChange) {
                if let i = CDProvince.getProvinceNameWithID(pID) {
                    selectedProvinsiID = pID
                    pID = i
                } else {
                    pID = "Pilih Provinsi"
                }
                
                if let i = CDRegion.getRegionNameWithID(rID) {
                    selectedKotaID = rID
                    rID = i
                } else {
                    rID = "Pilih Kota/Kabupaten"
                }
                
                selectedKecamatanID = profile.subdistrictID
                selectedKecamatanName = profile.subdistrictName
                sdID = (profile.subdistrictName != "") ? profile.subdistrictName : "Pilih Kecamatan"
            }
        }
        }
        
        if (addresses.count > selectedIndex) {
            fullname = addresses[selectedIndex].recipientName
            phone = addresses[selectedIndex].phone
            address = addresses[selectedIndex].address
            postalcode = addresses[selectedIndex].postalCode
            selectedProvinsiID = addresses[selectedIndex].provinceId
            pID = addresses[selectedIndex].provinceName
            selectedKotaID = addresses[selectedIndex].regionId
            rID = addresses[selectedIndex].regionName
            selectedKecamatanID = addresses[selectedIndex].subdisrictId
            sdID = addresses[selectedIndex].subdisrictName
            
            synchCart()
        }
        
        if (address == "" || postalcode == "") {
            isNeedSetup = true
        }
        
        // Fill cellsData
        let c = BaseCartData.instance(titlePostal, placeHolder: "Kode Pos", value : postalcode)
        c.keyboardType = UIKeyboardType.numberPad
        self.cellsData = [
            /*
            IndexPath(row: 0, section: sectionDataUser):BaseCartData.instance(titleNama, placeHolder: "Nama Lengkap Kamu", value : fullname),
            IndexPath(row: 1, section: sectionDataUser):BaseCartData.instance(titleTelepon, placeHolder: "Nomor Telepon Kamu", value : phone),
            IndexPath(row: 0, section: sectionAlamatUser):BaseCartData.instance(titleAlamat, placeHolder: "Alamat Lengkap Kamu", value : address),
            IndexPath(row: 1, section: sectionAlamatUser):BaseCartData.instance(titleProvinsi, placeHolder: nil, value: pID, pickerPrepBlock: { picker in
                
                picker.items = CDProvince.getProvincePickerItems()
                picker.textTitle = "Pilih Provinsi"
                picker.doneLoading()
                
                picker.selectBlock = { string in
                    self.selectedProvinsiID = PickerViewController.RevealHiddenString(string)
                    
                    // Set picked address
                    self.selectedKotaID = ""
                    self.selectedKecamatanID = ""
                    self.selectedKecamatanName = ""
                    let idxs = [IndexPath(row: 2, section: self.sectionAlamatUser), IndexPath(row: 3, section: self.sectionAlamatUser)]
                    self.cellsData[idxs[0]]?.value = "Pilih Kota/Kabupaten"
                    self.cellsData[idxs[1]]?.value = "Pilih Kecamatan"
                    self.tableView.reloadRows(at: idxs, with: .fade)
                }
            }),
            IndexPath(row: 2, section: sectionAlamatUser):BaseCartData.instance(titleKota, placeHolder: nil, value: rID, pickerPrepBlock: { picker in
                
                picker.items = CDRegion.getRegionPickerItems(self.selectedProvinsiID)
                picker.textTitle = "Pilih Kota/Kabupaten"
                picker.doneLoading()
                
                picker.selectBlock = { string in
                    self.kecamatanPickerItems = []
                    self.selectedKotaID = PickerViewController.RevealHiddenString(string)
                    self.refreshByLocationChange = true
                    
                    self.synchCart()
                    
                    // Set picked address value
                    self.selectedKecamatanID = ""
                    self.selectedKecamatanName = ""
                    let idxs = [IndexPath(row: 1, section: self.sectionAlamatUser), IndexPath(row: 2, section: self.sectionAlamatUser), IndexPath(row: 3, section: self.sectionAlamatUser)]
                    self.cellsData[idxs[0]]?.value = CDProvince.getProvinceNameWithID(self.selectedProvinsiID)
                    self.cellsData[idxs[1]]?.value = string.components(separatedBy: PickerViewController.TAG_START_HIDDEN)[0]
                    self.cellsData[idxs[2]]?.value = "Pilih Kecamatan"
                }
            }),
            IndexPath(row: 3, section: sectionAlamatUser):BaseCartData.instance(titleKecamatan, placeHolder: nil, value: sdID, pickerPrepBlock: { picker in
                
                if (self.kecamatanPickerItems.count <= 0) {
                    self.tableView.isHidden = true
                    self.loadingCart.isHidden = false
                    let _ = request(APIMisc.getSubdistrictsByRegionID(id: self.selectedKotaID)).responseJSON { resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Kecamatan")) {
                            let json = JSON(resp.result.value!)
                            let data = json["_data"].arrayValue
                            
                            if (data.count > 0) {
                                for i in 0...data.count - 1 {
                                    self.kecamatanPickerItems.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)
                                }
                                
                                picker.items = self.kecamatanPickerItems
                                picker.textTitle = "Pilih Kecamatan"
                                picker.doneLoading()
                                
                                picker.tableView.reloadData()
                            } else {
                                Constant.showDialog("Warning", message: "Oops, kecamatan tidak ditemukan")
                            }
                        }
                        self.tableView.isHidden = false
                        self.loadingCart.isHidden = true
                    }
                } else {
                    picker.items = self.kecamatanPickerItems
                    picker.textTitle = "Pilih Kecamatan"
                    picker.doneLoading()
                }
                
                picker.selectBlock = { string in
                    self.selectedKecamatanID = PickerViewController.RevealHiddenString(string)
                    self.selectedKecamatanName = string.components(separatedBy: PickerViewController.TAG_START_HIDDEN)[0]
                    self.refreshByLocationChange = true
                    
                    self.synchCart()
                    
                    // Set picked address value
                    let idxs = [IndexPath(row: 1, section: self.sectionAlamatUser), IndexPath(row: 2, section: self.sectionAlamatUser), IndexPath(row: 3, section: self.sectionAlamatUser)]
                    self.cellsData[idxs[0]]?.value = CDProvince.getProvinceNameWithID(self.selectedProvinsiID)
                    self.cellsData[idxs[1]]?.value = CDRegion.getRegionNameWithID(self.selectedKotaID)
                    self.cellsData[idxs[2]]?.value = string.components(separatedBy: PickerViewController.TAG_START_HIDDEN)[0]
                }
            }),
            IndexPath(row: 4, section: sectionAlamatUser):c
            */
            
            IndexPath(row: 1, section: sectionAlamatUser):BaseCartData.instance(titleNama, placeHolder: "Nama Lengkap Kamu", value : fullname),
            IndexPath(row: 2, section: sectionAlamatUser):BaseCartData.instance(titleTelepon, placeHolder: "Nomor Telepon Kamu", value : phone),
            IndexPath(row: 3, section: sectionAlamatUser):BaseCartData.instance(titleProvinsi, placeHolder: nil, value: pID, pickerPrepBlock: { picker in
                
                picker.items = CDProvince.getProvincePickerItems()
                picker.textTitle = "Pilih Provinsi"
                picker.doneLoading()
                
                picker.selectBlock = { string in
                    self.selectedProvinsiID = PickerViewController.RevealHiddenString(string)
                    
                    // Set picked address
                    self.selectedKotaID = ""
                    self.selectedKecamatanID = ""
                    self.selectedKecamatanName = ""
                    let idxs = [IndexPath(row: 4, section: self.sectionAlamatUser), IndexPath(row: 5, section: self.sectionAlamatUser)]
                    self.cellsData[idxs[0]]?.value = "Pilih Kota/Kabupaten"
                    self.cellsData[idxs[1]]?.value = "Pilih Kecamatan"
                    self.tableView.reloadRows(at: idxs, with: .fade)
                }
            }),
            IndexPath(row: 4, section: sectionAlamatUser):BaseCartData.instance(titleKota, placeHolder: nil, value: rID, pickerPrepBlock: { picker in
                
                picker.items = CDRegion.getRegionPickerItems(self.selectedProvinsiID)
                picker.textTitle = "Pilih Kota/Kabupaten"
                picker.doneLoading()
                
                picker.selectBlock = { string in
                    self.kecamatanPickerItems = []
                    self.selectedKotaID = PickerViewController.RevealHiddenString(string)
                    self.refreshByLocationChange = true
                    
                    self.synchCart()
                    
                    // Set picked address value
                    self.selectedKecamatanID = ""
                    self.selectedKecamatanName = ""
                    let idxs = [IndexPath(row: 3, section: self.sectionAlamatUser), IndexPath(row: 4, section: self.sectionAlamatUser), IndexPath(row: 5, section: self.sectionAlamatUser)]
                    self.cellsData[idxs[0]]?.value = CDProvince.getProvinceNameWithID(self.selectedProvinsiID)
                    self.cellsData[idxs[1]]?.value = string.components(separatedBy: PickerViewController.TAG_START_HIDDEN)[0]
                    self.cellsData[idxs[2]]?.value = "Pilih Kecamatan"
                }
            }),
            IndexPath(row: 5, section: sectionAlamatUser):BaseCartData.instance(titleKecamatan, placeHolder: nil, value: sdID, pickerPrepBlock: { picker in
                
                if (self.kecamatanPickerItems.count <= 0) {
                    self.tableView.isHidden = true
                    self.loadingCart.isHidden = false
                    let _ = request(APIMisc.getSubdistrictsByRegionID(id: self.selectedKotaID)).responseJSON { resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Kecamatan")) {
                            let json = JSON(resp.result.value!)
                            let data = json["_data"].arrayValue
                            
                            if (data.count > 0) {
                                for i in 0...data.count - 1 {
                                    self.kecamatanPickerItems.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)
                                }
                                
                                picker.items = self.kecamatanPickerItems
                                picker.textTitle = "Pilih Kecamatan"
                                picker.doneLoading()
                                
                                picker.tableView.reloadData()
                            } else {
                                Constant.showDialog("Warning", message: "Oops, kecamatan tidak ditemukan")
                            }
                        }
                        self.tableView.isHidden = false
                        self.loadingCart.isHidden = true
                    }
                } else {
                    picker.items = self.kecamatanPickerItems
                    picker.textTitle = "Pilih Kecamatan"
                    picker.doneLoading()
                }
                
                picker.selectBlock = { string in
                    self.selectedKecamatanID = PickerViewController.RevealHiddenString(string)
                    self.selectedKecamatanName = string.components(separatedBy: PickerViewController.TAG_START_HIDDEN)[0]
                    self.refreshByLocationChange = true
                    
                    self.synchCart()
                    
                    // Set picked address value
                    let idxs = [IndexPath(row: 3, section: self.sectionAlamatUser), IndexPath(row: 4, section: self.sectionAlamatUser), IndexPath(row: 5, section: self.sectionAlamatUser)]
                    self.cellsData[idxs[0]]?.value = CDProvince.getProvinceNameWithID(self.selectedProvinsiID)
                    self.cellsData[idxs[1]]?.value = CDRegion.getRegionNameWithID(self.selectedKotaID)
                    self.cellsData[idxs[2]]?.value = string.components(separatedBy: PickerViewController.TAG_START_HIDDEN)[0]
                }
            }),
            IndexPath(row: 6, section: sectionAlamatUser):BaseCartData.instance(titleAlamat, placeHolder: "Alamat Lengkap Kamu", value : address),
            IndexPath(row: 7, section: sectionAlamatUser):BaseCartData.instance(titlePostal, placeHolder: "Kode Pos Kamu", value : postalcode)
        ]
    }
    
    func adjustTotal() {
        // Sum up shipping price
        totalOngkir = 0
        if (cartProducts.count <= 0) {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        for i in 0..<cartProducts.count {
            let cp = cartProducts[i]
            
            let json = arrayItem[i]
            if let free = json["free_ongkir"].bool {
                if (free) {
                    continue
                }
            }
            
            if let arr = json["shipping_packages"].array {
                if (arr.count > 0) {
                    var sh = arr[0]
                    if (cp.packageId != "") {
                        for x in 0...arr.count-1 {
                            let shipping = arr[x]
                            if let id = shipping["_id"].string {
                                if (id == cp.packageId) {
                                    sh = shipping
                                }
                            }
                        }
                    }
                    if let price = sh["price"].int {
                        totalOngkir += price
                    }
                }
            }
        }
        
        // Create 'Subtotal' cell in cellsData
        let i = IndexPath(row: self.cartProducts.count + (arrayItem.count > 2 ? 1 : 0), section: self.sectionProducts)
        let i2 = IndexPath(row: 0, section: self.sectionPaySummary)
        let b = BaseCartData.instance("Subtotal", placeHolder: nil, enable : false)
        if let totalPrice = self.currentCart?["total_price"].int {
            self.subtotalPrice = totalPrice + totalOngkir
            if (self.subtotalPrice < 0) {
                self.subtotalPrice = 0
            }
            b.value = self.subtotalPrice.asPrice
        }
        self.cellsData[i] = b
        self.cellsData[i2] = b
        
        // Hide lblSend (for referral bonus description)
        self.consHeightLblSend.constant = 0
        
        // Update bonus discount if its more than half of subtotal
        if (discountItems.count > 0) {
            for i in 0...discountItems.count - 1 {
                if (discountItems[i].title == "Referral Bonus") {
                    if (customBonusPercent > 0) {
                        if (discountItems[i].value > self.subtotalPrice * customBonusPercent / 100) {
                            discountItems[i].value = self.subtotalPrice * customBonusPercent / 100
                            // Show lblSend
                            self.lblSend.text = "Maksimal Referral Bonus yang dapat digunakan adalah \(customBonusPercent)% dari subtotal transaksi"
                            self.consHeightLblSend.constant = 31
                        }
                    } else if (isHalfBonusMode) {
                        if (discountItems[i].value > self.subtotalPrice / 2) {
                            discountItems[i].value = self.subtotalPrice / 2
                            // Show lblSend
                            self.lblSend.text = "Maksimal Referral Bonus yang dapat digunakan adalah 50% dari subtotal transaksi"
                            self.consHeightLblSend.constant = 31
                        }
                    } else {
                        if (discountItems[i].value > self.subtotalPrice) {
                            discountItems[i].value = self.subtotalPrice
                        }
                    }
                }
            }
        }
        
        self.adjustRingkasan()
    }
    
    func adjustRingkasan() {
        // Set cellsData for discounts, start from row idx 1 in sectionPaySummary
        if (discountItems.count > 0) {
            for i in 0...discountItems.count - 1 {
                let idxDisc = IndexPath(row: 1 + i, section: self.sectionPaySummary)
                let bDisc = BaseCartData.instance(discountItems[i].title, placeHolder: nil, value: "-\(discountItems[i].value.asPrice)", enable: false)
                self.cellsData[idxDisc] = bDisc
            }
        }
        
        // Set price after discounts
        priceAfterDiscounts = subtotalPrice
        for i in self.discountItems {
            priceAfterDiscounts -= i.value
        }
        if (priceAfterDiscounts < 0) {
            priceAfterDiscounts = 0
        }
        
        // Determine payment charge & set cellsData for payment charge
        let creditCardCharge = 2500 + Int((Double(priceAfterDiscounts) * 0.032) + 0.5)
        var indomaretCharge = Int((Double(priceAfterDiscounts) * 0.02) + 0.5)
        if (indomaretCharge < 5000) {
            indomaretCharge = 5000
        }
        if (priceAfterDiscounts > 0) {
            let idxPaymentCharge = IndexPath(row: 1 + discountItems.count, section: self.sectionPaySummary)
            if (selectedPayment == .bankTransfer) {
                let bKode = BaseCartData.instance("Kode Unik Transfer", placeHolder: nil, value: bankTransferDigit.asPrice, enable: false)
                self.cellsData[idxPaymentCharge] = bKode
            } else if (selectedPayment == .creditCard) {
                let bCharge = BaseCartData.instance("Credit Card Charge", placeHolder: nil, value: creditCardCharge.asPrice, enable: false)
                self.cellsData[idxPaymentCharge] = bCharge
            } else if (selectedPayment == .indomaret) {
                let bCharge = BaseCartData.instance("Indomaret Charge", placeHolder: nil, value: indomaretCharge.asPrice, enable: false)
                self.cellsData[idxPaymentCharge] = bCharge
            }
        }
        
        // Set cellsData for grand total
        let idxGTotal = IndexPath(row: (priceAfterDiscounts > 0 ? 2 : 1) + discountItems.count, section: self.sectionPaySummary)
        var paymentCharge = 0
        if (selectedPayment == .bankTransfer) {
            paymentCharge = bankTransferDigit
        } else if (selectedPayment == .creditCard) {
            paymentCharge = creditCardCharge
        } else if (selectedPayment == .indomaret) {
            paymentCharge = indomaretCharge
        }
        self.grandTotal = priceAfterDiscounts + (priceAfterDiscounts > 0 ? paymentCharge : 0)
        let bGTotal = BaseCartData.instance("Total Pembayaran", placeHolder: nil, value: self.grandTotal.asPrice, enable: false)
        self.cellsData[idxGTotal] = bGTotal
        
        self.printCellsData()
        self.setupTable()
    }
    
    func setupTable() {
        // Setup table
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.isHidden = false
        self.tableView.reloadData()
//        
//        let inset = UIEdgeInsetsMake(4, 0, 4, 0)
//        self.tableView.contentInset = inset
//        self.tableView.backgroundColor = UIColor(hex: "E5E9EB")
    }
    
    // MARK: - Cell creations
    
    func createOrGetBaseCartCell(_ tableView : UITableView, indexPath : IndexPath, id : String, isShowBottomLine : Bool) -> BaseCartCell {
        let b : BaseCartCell = tableView.dequeueReusableCell(withIdentifier: id) as! BaseCartCell
        
        b.parent = self
        b.adapt(cellsData[indexPath])
        b.idxPath = indexPath
        b.lastIndex = indexPath
        if (isShowBottomLine) {
            b.bottomLine?.isHidden = false
        } else {
            b.bottomLine?.isHidden = true
        }
        
        if (id == "cell_input") {
            if let c = b as? CartCellInput {
                c.textChangedBlock = { idxPath, newValue in
                    self.cellsData[idxPath]?.value = newValue
                }
            }
        }
        
        return b
    }
    
    func createExpandableCell(_ tableView : UITableView, indexPath : IndexPath) -> ACEExpandableTextCell? {
        var acee = tableView.dequeueReusableCell(withIdentifier: "address_cell") as? CartAddressCell
        if (acee == nil) {
            acee = CartAddressCell(style: UITableViewCellStyle.default, reuseIdentifier: "address_cell")
            acee?.selectionStyle = UITableViewCellSelectionStyle.none
            acee?.expandableTableView = tableView
            
            acee?.textView.font = UIFont.systemFont(ofSize: 14)
            acee?.textView.textColor = UIColor.darkGray
        }
        
        if (acee?.lastIndex != nil) {
            cellsData[(acee?.lastIndex)!] = acee?.obtain()
        }
        
        acee?.adapt(cellsData[indexPath]!)
        acee?.lastIndex = indexPath
        
        return acee
    }
    
    func createPayMethodCell(_ tableView : UITableView, indexPath : IndexPath) -> CartPaymethodCell {
        let cell : CartPaymethodCell = tableView.dequeueReusableCell(withIdentifier: "cell_paymethod") as! CartPaymethodCell
        cell.isEnableCCPayment = isEnableCCPayment
        cell.isEnableIndomaretPayment = isEnableIndomaretPayment
        cell.isShowBankBRI = isShowBankBRI
        // new
        cell.isDropdownMode = true
        cell.parent = self
        cell.selectedBankIndex = self.selectedBankIndex
        cell.methodChosen = { mthd in
            self.setPaymentOption(mthd)
            self.adjustRingkasan()
        }
//        if (self.isShowBankBRI) {
//            cell.vw3Banks.isHidden = true
//            cell.vw4Banks.isHidden = false
//        } else {
//            cell.vw3Banks.isHidden = false
//            cell.vw4Banks.isHidden = true
//        }
        cell.adapt(selectedPayment: selectedPayment)
        
        return cell
    }
    
    // MARK: - UITableView functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section == 0 || section == 2) {
            return 4
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 4))
        
        v.backgroundColor = UIColor(hex: "E5E9EB")
        
        return v
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == sectionProducts) {
            return arrayItem.count + (arrayItem.count > 2 ? 2 : 1) // Total products + clear all cell + subtotal cell
        } else if (section == sectionDataUser) {
            return 0 // 2
        } else if (section == sectionAlamatUser) {
            if isNeedSetup {
                return 9
            } else {
                return 2
            }
//            return 5
        } else if (section == sectionPayMethod) {
            if (isVoucherApplied) {
                return 2 // Pay method, Prelo balance switch
            } else {
                return 3 // Pay method, Prelo balance switch, Voucher switch
            }
            
        } else if (section == sectionPaySummary) {
            return (priceAfterDiscounts > 0 ? 3 : 2) + discountItems.count // Subtotal, N discount items, Transfer digit (jika priceAfterDiscounts > 0), Grandtotal
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = (indexPath as NSIndexPath).section
        let row = (indexPath as NSIndexPath).row
        var cell : UITableViewCell = UITableViewCell()
        
        if (section == sectionProducts) {
            if (arrayItem.count > 2 && row == 0) { // Clear all
                cell = tableView.dequeueReusableCell(withIdentifier: "cell_clearall") as! CartCellClearAll
            } else if (row == (arrayItem.count + (arrayItem.count > 2 ? 1 : 0))) { // Subtotal
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
            } else { // Cart product
                let i = tableView.dequeueReusableCell(withIdentifier: "cell_item2") as! CartCellItem
                let cp = cartProducts[(indexPath as NSIndexPath).row - (arrayItem.count > 2 ? 1 : 0)]
                i.selectedPaymentId = cp.packageId
                //i.selectedPaymentId = "" // debug
                i.adapt(arrayItem[(indexPath as NSIndexPath).row - (arrayItem.count > 2 ? 1 : 0)])
                i.cartItemCellDelegate = self
                
//                if (row != 0) {
                    i.topLine?.isHidden = true
//                }
                
                i.indexPath = indexPath
                
                cell = i
            }
        } /*else if (section == sectionDataUser) {
            if (row == 2) { // Currently not used because max row idx is 1
                cell = tableView.dequeueReusableCell(withIdentifier: "cell_edit")!
            } else if (row == 0) { // Nama
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: true)
            } else if (row == 1) { // Telepon
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
            }
        } else if (section == sectionAlamatUser) {
            if (row == 0) { // Alamat
                cell =  createExpandableCell(tableView, indexPath: indexPath)!
            } else if (row == 1 || row == 2 || row == 3) { // Provinsi, Kab/Kota, Kecamatan
                 cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input_2", isShowBottomLine: true)
            } else if (row == 4) { // Kode Pos
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
            }
         }*/ else if (section == sectionAlamatUser) {
            if (isNeedSetup) { // 9 row
                if (row == 0) { // dropdown
                    let c = tableView.dequeueReusableCell(withIdentifier: "cell_dropDown") as! DropdownCell
                    if addresses.count > selectedIndex {
                        c.adapt(addresses[selectedIndex])
                    } else {
                        c.adaptNew("Alamat Baru")
                    }
                    c.selectionStyle = .none
                    dropDown.anchorView = c.vwDropdown
                    cell = c
                } else if (row == 1 || row == 2) { // Nama, Telepon
                    cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: true)
                } else if (row == 3 || row == 4 || row == 5) { // Provinsi, Kab/Kota, Kecamatan
                    cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input_2", isShowBottomLine: true)
                } else if (row == 6) { // Alamat
                    cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: true)
                } else if (row == 7) { // Kode Pos
                    cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
                } else {
                    let c = tableView.dequeueReusableCell(withIdentifier: "cell_saveAddress") as! SaveAlamatCell
                    c.adapt(isSave)
                    c.selectionStyle = .none
                    cell = c
                }
            } else { // 2 row
                if (row == 0) { // dropdown
                    let c = tableView.dequeueReusableCell(withIdentifier: "cell_dropDown") as! DropdownCell
                    c.adapt(addresses[selectedIndex])
                    c.selectionStyle = .none
                    dropDown.anchorView = c.vwDropdown
                    cell = c
                } else { // Provinsi, Kab/Kota, Kode Pos, Kecamatan
                    let c = tableView.dequeueReusableCell(withIdentifier: "cell_fullAddress") as! FullAlamatCell
                    c.adapt(addresses[selectedIndex])
                    c.selectionStyle = .none
                    cell = c
                }
            }
            
        } else if (section == sectionPayMethod) {
            if (row == 0) { // Payment method
                cell = createPayMethodCell(tableView, indexPath: indexPath)
            } else if (row == 1) { // Prelo balance switch
                let cellId = isUsingPreloBalance ? "pbcellInput2" : "pbcellInput1"
                let c = tableView.dequeueReusableCell(withIdentifier: cellId) as! PreloBalanceInputCell
                c.delegate = self
                c.txtInput?.text = nil
                c.switchBalance.setOn(isUsingPreloBalance, animated: false)
                if (isUsingPreloBalance) {
                    c.captionTotalBalance.text = "Prelo Balance kamu \(balanceAvailable.asPrice)"
                    
                    // Set textfield if used prelo balance is already set
                    let discBalance = discountItems[0]
                    if (discBalance.title == "Prelo Balance") { // Pengecekan #2
                        c.txtInput?.text = String(discBalance.value)
                    }
                }
                cell = c
            } else if (row == 2) { // Voucher switch
                let cellId = isShowVoucher ? "vccellInput2" : "vccellInput1"
                let c = tableView.dequeueReusableCell(withIdentifier: cellId) as! VoucherInputCell
                c.delegate = self
                c.txtInput?.text = nil
                c.switchVoucher.setOn(isShowVoucher, animated: false)
                cell = c
            }
        } else if (section == sectionPaySummary) {
            if (row == 0) { // Subtotal
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
            } else {
                var afterDiscountRowIdx = 1
                if (discountItems.count > 0) {
                    afterDiscountRowIdx += discountItems.count
                    if (row - 1 < discountItems.count) { // Discount
                        cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
                    }
                }
                if (row == afterDiscountRowIdx && priceAfterDiscounts > 0) { // Transfer code
                    cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
                } else if ((row == afterDiscountRowIdx && priceAfterDiscounts <= 0) || row == afterDiscountRowIdx + 1) { // Grand total
                    cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cellGrandTotal", isShowBottomLine: false)
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = (indexPath as NSIndexPath).section
        let row = (indexPath as NSIndexPath).row
        
        if (section == sectionProducts) {
            if (arrayItem.count > 2 && row == 0) { // Clear all
                return 32
            } else if (row == (arrayItem.count + (arrayItem.count > 2 ? 1 : 0))) { // Subtotal
                return 44
            } else { // Cart product
                let json = arrayItem[(indexPath as NSIndexPath).row - (arrayItem.count > 2 ? 1 : 0)]
                if let error = json["_error"].string {
                    let options : NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
                    let h = (error as NSString).boundingRect(with: CGSize(width: UIScreen.main.bounds.width - 114, height: 0), options: options, attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 14)], context: nil).height
                    return 77 + h
                }
                return 94
            }
        } /*else if (section == sectionDataUser) {
            if (row == 2) { // Currently not used because max row idx is 1
                return 20
            } else { // Nama, Telepon
                return 44
            }
        } else if (section == sectionAlamatUser) {
            if (row == 0) { // Alamat
                return CGFloat(addressHeight)
            } else { // Provinsi, Kab/Kota, Kode Pos, Kecamatan
                return 44
            }
         }*/ else if (section == sectionAlamatUser) {
            if (isNeedSetup) {
                return 44
            } else {
                if (row == 0) { // dropdown
                    return 44
                } else { // Provinsi, Kab/Kota, Kode Pos, Kecamatan
                    return 120
                }
            }
            
        } else if (section == sectionPayMethod) {
            if (row == 0) { // Payment method
                if (selectedPayment == .bankTransfer) {
                    return 198
                } else {
                    return 144
                }
            } else if (row == 1) { // Prelo balance switch
                return isUsingPreloBalance ? 107 : 47
            } else if (row == 2) { // Voucher switch
                return isShowVoucher ? 107 : 47
            }
        } else if (section == sectionPaySummary) {
            return 36
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        /*if (section == 0) {
            return 48
        } else*/ if (section != 1) {
            return 44
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let height = CGFloat(44)
//        if (section == 0) {
//            height += 4
//        }
        
        let v = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height))
        
        v.backgroundColor = UIColor.white
        
        var lblFrame = CGRect.zero
        lblFrame.origin.x = 8
        let l = UILabel(frame: lblFrame)
        l.font = UIFont.boldSystemFont(ofSize: 16)
        l.textColor = UIColor.darkGray
        
        if (section == sectionProducts) {
            l.text = "RINGKASAN BARANG"
        } /*else if (section == sectionDataUser) {
            l.text = "DATA KAMU"
        }*/ else if (section == sectionAlamatUser) {
            l.text = "ALAMAT PENGIRIMAN"
        } else if (section == sectionPayMethod) {
            l.text = "METODE PEMBAYARAN"
        } else if (section == sectionPaySummary) {
            l.text = "RINGKASAN PEMBAYARAN"
        }
        
        l.sizeToFit()
        
        l.y = (v.height - l.height) / 2 //+ (section == 0 ? 2 : 0)
        
        v.addSubview(l)
        
//        if section == 0 {
//            let v1 = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 4))
//            
//            v1.backgroundColor = UIColor(hex: "E5E9EB")
//            
//            v.addSubview(v1)
//        }
        
        return v
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ((indexPath as NSIndexPath).section == sectionProducts) {
            if (arrayItem.count > 2 && (indexPath as NSIndexPath).row == 0) { // Clear all
                let alert = UIAlertController(title: "Hapus Keranjang", message: "Kamu yakin ingin menghapus semua barang dalam keranjang?", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in
                    alert.dismiss(animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Hapus", style: .default, handler: { act in
                    alert.dismiss(animated: true, completion: nil)
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let notifListener = appDelegate.preloNotifListener
                    notifListener?.increaseCartCount(-1 * self.arrayItem.count)
                    self.arrayItem.removeAll()
                    CartProduct.deleteAll()
                    self.shouldBack = true
                    //                    self.cellsData = [:]
                    self.synchCart()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        } else if ((indexPath as NSIndexPath).section == sectionAlamatUser) {
            if ((indexPath as NSIndexPath).row == 0) { // Choose address book
                
                let c = tableView.cellForRow(at: indexPath) as! DropdownCell
                /*
                // dropdown menu
                var items = addresses
                
                let alamatCount = items.count
                let alamatAlert = UIAlertController(title: "Daftar Alamat", message: nil, preferredStyle: .actionSheet)
                alamatAlert.popoverPresentationController?.sourceView = c
                alamatAlert.popoverPresentationController?.sourceRect = c.vwDropdown.frame
                for i in 0...alamatCount - 1 {
                    alamatAlert.addAction(UIAlertAction(title: items[i].addressName, style: .default, handler: { act in
                        if (self.selectedIndex != i) {
                            self.isNeedSetup = false
                            self.selectedIndex = i
                            self.initUserDataSections()
                            self.tableView.reloadData()
                        }
                        alamatAlert.dismiss(animated: true, completion: nil)
                    }))
                }
                
                if (alamatCount < 5) {
                    alamatAlert.addAction(UIAlertAction(title: "Alamat Baru", style: .default, handler: { act in
                        if (self.selectedIndex != alamatCount) {
                            self.isNeedSetup = true
                            self.selectedIndex = alamatCount
                            self.initUserDataSections()
                            self.tableView.reloadData()
                        }
                        alamatAlert.dismiss(animated: true, completion: nil)
                    }))
                }
                
                alamatAlert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in
                    alamatAlert.dismiss(animated: true, completion: nil)
                }))
                self.present(alamatAlert, animated: true, completion: nil)
                */
                
                dropDown.show()
                
            } else if ((indexPath as NSIndexPath).row == 6 /*3*/) { // Kecamatan
                if (selectedKotaID == "") {
                    Constant.showDialog("Perhatian", message: "Pilih kota/kabupaten terlebih dahulu")
                    return
                }
            } else if ((indexPath as NSIndexPath).row == 5 /*2*/) { // Kota/Kab
                if (selectedProvinsiID == "") {
                    Constant.showDialog("Perhatian", message: "Pilih provinsi terlebih dahulu")
                    return
                }
            } else if ((indexPath as NSIndexPath).row == 8) { // save
                isSave = !isSave
                tableView.reloadData()
            }
        }
        
        let c = tableView.cellForRow(at: indexPath)
        if ((c?.canBecomeFirstResponder)!) {
            c?.becomeFirstResponder()
        }
    }
    
    // MARK: - ACEExpandableTextCell functionsahaa
    
    func tableView(_ tableView: UITableView!, updatedHeight height: CGFloat, at indexPath: IndexPath!) {
        addressHeight = Int(height)
    }
    
    func tableView(_ tableView: UITableView!, updatedText text: String!, at indexPath: IndexPath!) {
        if (indexPath != nil) {
            if let cell = cellsData[indexPath] {
                cell.value = text
            }
        }
    }
    
    // MARK: - UITextField functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            // This will be crash on iOS 7.1
            let i = tableView.indexPath(for: (textField.superview?.superview!) as! UITableViewCell)
            var s = ((i as NSIndexPath?)?.section)!
            var r = ((i as NSIndexPath?)?.row)!
            
            var cell : UITableViewCell?
            
            var con = true
            while (con) {
                let newIndex = IndexPath(row: r + 1, section: s)
                cell = tableView.cellForRow(at: newIndex)
                if (cell == nil) {
                    s += 1
                    r = -1
                    if (s == tableView.numberOfSections) { // finish, last cell
                        con = false
                    }
                } else {
                    if ((cell?.canBecomeFirstResponder)!) {
                        cell?.becomeFirstResponder()
                        con = false
                    } else {
                        r += 1
                    }
                }
            }
        }
        return true
    }
    
    // MARK: - UIScrollView functions
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    // MARK: - Actions
    
    @IBAction override func confirm()
    {
        if (selectedPayment == .bankTransfer && targetBank == "")
        {
            Constant.showDialog("Perhatian", message: "Bank Tujuan Transfer harus diisi")
            return
        }
        if (voucherTyped != "" && !isVoucherApplied) {
            Constant.showDialog("Perhatian", message: "Mohon klik Apply untuk menggunakan voucher")
            return
        }
        if (selectedProvinsiID == "") {
            Constant.showDialog("Perhatian", message: "Provinsi harus diisi")
            return
        }
        if (selectedKotaID == "") {
            Constant.showDialog("Perhatian", message: "Kota/Kabupaten harus diisi")
            return
        }
        if (selectedKecamatanID == "") {
            Constant.showDialog("Perhatian", message: "Kecamatan harus diisi")
            return
        }
        
        // Prepare param for API checkout
        var name = ""
        var phone = ""
        var postal = ""
        let email = (self.user?.email)!
        
        //self.printCellsData()
        for i in cellsData.keys {
            let b = cellsData[i]
            if (b?.value == nil || b?.value == "") {
                var msgObj = (b?.title)!
                if (msgObj == titleAlamat) {
                    msgObj = "Alamat"
                }
                Constant.showDialog("Perhatian", message: "Harap isi kolom " + msgObj)
                return
            }
            
            if (b?.title == titleNama) {
                name = (b?.value)!
            }
            
            if (b?.title == titleTelepon) {
                phone = (b?.value)!
            }
            
            if (b?.title == titleAlamat) {
                address = (b?.value)!
            }
            
            if (b?.title == titlePostal) {
                postal = (b?.value)!
            }
            
            print((b?.title)! + " : " + (b?.value)!)
        }
        
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let p = AppToolsObjC.jsonString(from: c)
        
        user?.profiles.address = address
        user?.profiles.postalCode = postal
        UIApplication.appDelegate.saveContext()
        
        let d = [
            "address":address,
            "province_id":selectedProvinsiID,
            "region_id":selectedKotaID,
            "subdistrict_id":selectedKecamatanID,
            "subdistrict_name":selectedKecamatanName,
            "postal_code":postal,
            "recipient_name":name,
            "recipient_phone":phone,
            "email":email
        ]
        let a = AppToolsObjC.jsonString(from: d)
        
        if (p == "[]" || p == "") {
            Constant.showDialog("Perhatian", message: "Tidak ada barang")
            return
        }
        
        self.btnSend.isEnabled = false
        
        var usedBalance = 0
        var usedBonus = 0
        if (isUsingPreloBalance || isUsingReferralBonus) {
            if (discountItems.count > 0) {
                for i in 0...discountItems.count - 1 {
                    if (discountItems[i].title.contains("Referral Bonus")) {
                        usedBonus = discountItems[i].value
                    } else if (discountItems[i].title == "Prelo Balance") {
                        usedBalance = discountItems[i].value
                    }
                }
            }
        }
        
        let alert : UIAlertController = UIAlertController(title: "Perhatian", message: "Kamu akan melakukan transaksi sebesar \(self.grandTotal.asPrice) menggunakan \(self.selectedPayment.value). Lanjutkan?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { action in
            self.btnSend.isEnabled = true
        }))
        alert.addAction(UIAlertAction(title: "Lanjutkan", style: .default, handler: { action in
            self.performCheckout(p!, address: a!, usedBalance: usedBalance, usedBonus: usedBonus)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func performCheckout(_ cart : String, address : String, usedBalance : Int, usedBonus : Int) {
        let _ = request(APICart.checkout(cart: cart, address: address, voucher: voucherApplied, payment: selectedPayment.value, usedPreloBalance: usedBalance, usedReferralBonus: usedBonus, kodeTransfer: bankTransferDigit, targetBank: (self.selectedPayment == .bankTransfer ? targetBank : ""))).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Checkout")) {
                let json = JSON(resp.result.value!)
                self.checkoutResult = json["_data"]
                
                // Error handling
                if (json["_data"]["_have_error"].intValue == 1) {
                    let m = json["_data"]["_message"].stringValue
                    UIAlertView.SimpleShow("Perhatian", message: m)
                    self.btnSend.isEnabled = true
                    return
                }
                
                if (self.checkoutResult == nil) {
                    Constant.showDialog("Perhatian", message: "Terdapat kesalahan saat melakukan checkout")
                    self.btnSend.isEnabled = true
                    return
                }
                
                // Send tracking data before navigate
                if (self.checkoutResult != nil) {
                    // insert new address if needed
                    if (self.isSave) {
                        // update
                            // do nothing - auto
                        
                        // new
                            self.insertNewAddress()
                    }
                    
                    // Mixpanel
                    var pName : String? = ""
                    var rName : String? = ""
                    if let u = CDUser.getOne()
                    {
                        pName = CDProvince.getProvinceNameWithID(u.profiles.provinceID)
                        if (pName == nil) {
                            pName = ""
                        }
                        rName = CDRegion.getRegionNameWithID(u.profiles.regionID)
                        if (rName == nil) {
                            rName = ""
                        }
                    }
                    
                    var items : [String] = []
                    var itemsId : [String] = []
                    var itemsCategory : [String] = []
                    var itemsSeller : [String] = []
                    var itemsPrice : [Int] = []
                    var itemsCommissionPercentage : [Int] = []
                    var itemsCommissionPrice : [Int] = []
                    var totalCommissionPrice = 0
                    var totalPrice = 0
                    for i in 0...self.arrayItem.count - 1 {
                        let json = self.arrayItem[i]
                        items.append(json["name"].stringValue)
                        itemsId.append(json["product_id"].stringValue)
                        var cName = CDCategory.getCategoryNameWithID(json["category_id"].stringValue)
                        if (cName == nil) {
                            cName = ""
                        }
                        itemsCategory.append(cName!)
                        itemsSeller.append(json["seller_username"].stringValue)
                        itemsPrice.append(json["price"].intValue)
                        totalPrice += json["price"].intValue
                        itemsCommissionPercentage.append(json["commission"].intValue)
                        let cPrice = json["price"].intValue * json["commission"].intValue / 100
                        itemsCommissionPrice.append(cPrice)
                        totalCommissionPrice += cPrice
                    }
                    
                    let orderId = self.checkoutResult!["order_id"].stringValue
                    let pt = [
                        "Order ID" : orderId,
                        "Items" : items,
                        "Items Category" : itemsCategory,
                        "Items Seller" : itemsSeller,
                        "Items Price" : itemsPrice,
                        "Items Commission Percentage" : itemsCommissionPercentage,
                        "Items Commission Price" : itemsCommissionPrice,
                        "Total Commission Price" : totalCommissionPrice,
                        "Shipping Price" : self.totalOngkir,
                        "Total Price" : totalPrice,
                        "Shipping Region" : rName!,
                        "Shipping Province" : pName!,
                        "Bonus Used" : 0,
                        "Balance Used" : 0
                        ] as [String : Any]
                    Mixpanel.trackEvent(MixpanelEvent.Checkout, properties: pt as [AnyHashable: Any])
                    
                    // Answers
                    if (AppTools.IsPreloProduction) {
                        Answers.logStartCheckout(withPrice: NSDecimalNumber(value: totalPrice as Int), currency: "IDR", itemCount: NSNumber(value: items.count as Int), customAttributes: nil)
                        for j in 0...items.count-1 {
                            Answers.logPurchase(withPrice: NSDecimalNumber(value: itemsPrice[j] as Int), currency: "IDR", success: true, itemName: items[j], itemType: itemsCategory[j], itemId: itemsId[j], customAttributes: nil)
                        }
                    }
                    
                    // Google Analytics Ecommerce Tracking
                    if (AppTools.IsPreloProduction) {
                        let gaTracker = GAI.sharedInstance().defaultTracker
                        let trxDict = GAIDictionaryBuilder.createTransaction(withId: orderId, affiliation: "iOS Checkout", revenue: totalPrice as NSNumber!, tax: totalCommissionPrice as NSNumber!, shipping: self.totalOngkir as NSNumber!, currencyCode: "IDR").build() as NSDictionary? as? [AnyHashable: Any]
                        gaTracker?.send(trxDict)
                        for i in 0...self.arrayItem.count - 1 {
                            let json = self.arrayItem[i]
                            var cName = CDCategory.getCategoryNameWithID(json["category_id"].stringValue)
                            if (cName == nil) {
                                cName = json["category_id"].stringValue
                            }
                            let trxItemDict = GAIDictionaryBuilder.createItem(withTransactionId: orderId, name: json["name"].stringValue, sku: json["product_id"].stringValue, category: cName, price: json["price"].intValue as NSNumber!, quantity: 1, currencyCode: "IDR").build() as NSDictionary? as? [AnyHashable: Any]
                            gaTracker?.send(trxItemDict)
                        }
                    }
                    
                    // MoEngage
                    let moeDict = NSMutableDictionary()
                    moeDict.setObject(orderId, forKey: "Order ID" as NSCopying)
                    moeDict.setObject(items, forKey: "Items" as NSCopying)
                    moeDict.setObject(itemsCategory, forKey: "Items Category" as NSCopying)
                    moeDict.setObject(itemsSeller, forKey: "Items Seller" as NSCopying)
                    moeDict.setObject(itemsPrice, forKey: "Items Price" as NSCopying)
                    moeDict.setObject(itemsCommissionPercentage, forKey: "Items Commission Percentage" as NSCopying)
                    moeDict.setObject(itemsCommissionPrice, forKey: "Items Commission Price" as NSCopying)
                    moeDict.setObject(totalCommissionPrice, forKey: "Total Commission Price" as NSCopying)
                    moeDict.setObject(self.totalOngkir, forKey: "Shipping Price" as NSCopying)
                    moeDict.setObject(totalPrice, forKey: "Total Price" as NSCopying)
                    moeDict.setObject(rName!, forKey: "Shipping Region" as NSCopying)
                    moeDict.setObject(pName!, forKey: "Shipping Province" as NSCopying)
                    let moeEventTracker = MOPayloadBuilder.init(dictionary: moeDict)
                    moeEventTracker?.setTimeStamp(Date.timeIntervalSinceReferenceDate, forKey: "startTime")
                    moeEventTracker?.setDate(Date(), forKey: "startDate")
                    let locManager = CLLocationManager()
                    locManager.requestWhenInUseAuthorization()
                    var currentLocation : CLLocation!
                    var currentLat : Double = 0
                    var currentLng : Double = 0
                    if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways) {
                        currentLocation = locManager.location
                        currentLat = currentLocation.coordinate.latitude
                        currentLng = currentLocation.coordinate.longitude
                    }
                    moeEventTracker?.setLocationLat(currentLat, lng: currentLng, forKey: "startingLocation")
                    MoEngage.sharedInstance().trackEvent(MixpanelEvent.Checkout, builderPayload: moeEventTracker)
                }
                
//                let appDelegate = UIApplication.shared.delegate as! AppDelegate
//                let notifListener = appDelegate.preloNotifListener
//                notifListener?.increaseCartCount(1)
                
                // Prepare to navigate to next page
                if (self.selectedPayment == .bankTransfer) {
                    self.navigateToOrderConfirmVC()
                    
                    // set 0 badge
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let notifListener = appDelegate.preloNotifListener
                    notifListener?.setCartCount(1 + self.transactionCount)
                } else { // Credit card, indomaret
                    let webVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
                    webVC.url = self.checkoutResult!["veritrans_redirect_url"].stringValue
                    webVC.titleString = "Pembayaran \(self.selectedPayment.value)"
                    webVC.creditCardMode = true
                    webVC.ccPaymentSucceed = {
                        self.navigateToOrderConfirmVC()
                        
                        // set 0 badge
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let notifListener = appDelegate.preloNotifListener
                        notifListener?.setCartCount(1 + self.transactionCount)
                    }
                    webVC.ccPaymentUnfinished = {
                        Constant.showDialog("Pembayaran \(self.selectedPayment.value)", message: "Pembayaran tertunda")
                        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                        notifPageVC.isBackTwice = true
                        self.navigateToVC(notifPageVC)
                    }
                    webVC.ccPaymentFailed = {
                        Constant.showDialog("Pembayaran \(self.selectedPayment.value)", message: "Pembayaran gagal, silahkan coba beberapa saat lagi")
                        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                        notifPageVC.isBackTwice = true
                        self.navigateToVC(notifPageVC)
                    }
                    let baseNavC = BaseNavigationController()
                    baseNavC.setViewControllers([webVC], animated: false)
                    self.present(baseNavC, animated: true, completion: nil)
                }
            }
            self.btnSend.isEnabled = true
        }
    }
    
    func navigateToOrderConfirmVC() {
        var gTotal = 0
        if let totalPrice = self.checkoutResult?["total_price"].int {
            gTotal += totalPrice
        }
        if let trfCode = self.checkoutResult?["banktransfer_digit"].int {
            gTotal += trfCode
        }
        
        let o = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
        
        o.orderID = (self.checkoutResult?["order_id"].string)!
        if (self.selectedPayment == .creditCard) {
            o.total = 0
        } else if (self.selectedPayment == .indomaret) {
            o.total = 0
        } else { // Bank transfer etc
            o.total = gTotal
        }
        o.transactionId = (self.checkoutResult?["transaction_id"].string)!
        o.isBackTwice = true
        o.isShowBankBRI = self.isShowBankBRI
        o.targetBank = self.targetBank
        
        if (self.checkoutResult?["expire_time"].string) != nil {
            o.date = (self.checkoutResult?["expire_time"].string)! // expire_time not found
        }
        
        var imgs : [URL] = []
        for i in 0...self.arrayItem.count - 1 {
            let json = self.arrayItem[i]
            if let raw : Array<AnyObject> = json["display_picts"].arrayObject as Array<AnyObject>? {
                var ori : Array<String> = []
                for o in raw {
                    if let s = o as? String {
                        ori.append(s)
                    }
                }
                
                if (ori.count > 0) {
                    if let u = URL(string: ori.first!) {
                        imgs.append(u)
                    }
                }
            }
        }
        o.images = imgs
        o.isFromCheckout = true
        self.navigateToVC(o)
    }
    
    func setPaymentOption(_ mthd : PaymentMethod) {
        selectedPayment = mthd
    }
    
    func itemNeedDelete(_ indexPath: IndexPath) {
        let j = arrayItem[(indexPath as NSIndexPath).row - (arrayItem.count > 2 ? 1 : 0)]
        print(j)
        arrayItem.remove(at: (indexPath as NSIndexPath).row - (arrayItem.count > 2 ? 1 : 0))
        
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let x = AppToolsObjC.jsonString(from: c)
        print(x)
        
        let pid = j["product_id"].stringValue
        
        var deletedProduct : CartProduct?
        var index = 0
        for cp in cartProducts {
            if (cp.cpID == pid) { // delete cart product
                deletedProduct = cp
                break
            }
            index += 1
        }
        
        if let p = deletedProduct {
            cartProducts.remove(at: index)
            print(p.cpID)
            UIApplication.appDelegate.managedObjectContext.delete(p)
            UIApplication.appDelegate.saveContext()
        }
        
//        tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        if (arrayItem.count == 0) {
            self.shouldBack = true
        }
//        cellsData = [:]
        synchCart()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = appDelegate.preloNotifListener
        notifListener?.increaseCartCount(-1)
    }
    
    func itemNeedUpdateShipping(_ indexPath: IndexPath) {
        let j = arrayItem[(indexPath as NSIndexPath).row - (arrayItem.count > 2 ? 1 : 0)]
        let jid = j["product_id"].stringValue
        var cartProduct : CartProduct?
        for cp in cartProducts {
            if (cp.cpID == jid) {
                cartProduct = cp
                break
            }
        }
        
        if let cp = cartProduct {
            print(j)
            var names : Array<String> = []
            var arr = j["shipping_packages"].array
            if let shippings = j["shipping_packages"].arrayObject {
                for s in shippings {
                    let json = JSON(s)
                    if let name = json["name"].string {
                        names.append(name)
                    }
                }
                
                if (names.count > 0) {
                    ActionSheetStringPicker.show(withTitle: "Select Shipping", rows: names, initialSelection: 0, doneBlock: { picker, index, value in
                            let sjson = arr?[index]
                            if let pid = sjson?["_id"].string {
                                cp.packageId = pid
                                UIApplication.appDelegate.saveContext()
                                self.adjustTotal()
                            }
                        }, cancel: { picker in
                            
                        }, origin: tableView.cellForRow(at: indexPath))
                }
            }
        }
    }
    
    @IBAction func paymentReminderPressed(_ sender: AnyObject) {
        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
        self.navigateToVC(notifPageVC)
    }
    
    func printCellsData() {
        print("CELLSDATA")
        if (cellsData.count > 0) {
            for i in 0...cellsData.count - 1 {
                let index = cellsData.index(cellsData.startIndex, offsetBy: i)
                let idxPath = cellsData.keys[index]
                let baseCartData = cellsData[idxPath]
                var title = "", value = ""
                if let t = baseCartData?.title {
                    title = t
                }
                if let v = baseCartData?.value {
                    value = v
                }
                print("\((idxPath as NSIndexPath).section) - \((idxPath as NSIndexPath).row) : title = \(title), value = \(value)")
            }
        }
    }
    
    // MARK: - Prelo balance cell delegate
    
    func preloBalanceInputCellNeedrefresh(_ isON: Bool) {
        if (!isON)
        {
            if (discountItems.count > 0) {
                if (discountItems[0].title == "Prelo Balance") {
                    discountItems.remove(at: 0)
                    tableView.deleteRows(at: [IndexPath(item: 2, section: sectionPaySummary)], with: .fade)
                }
            }
        } else {
            if (discountItems.count <= 0 || (discountItems.count > 0 && discountItems[0].title != "Prelo Balance")) {
                let discItem = DiscountItem(title: "Prelo Balance", value: (balanceAvailable <= priceAfterDiscounts ? balanceAvailable : priceAfterDiscounts))
                discountItems.insert(discItem, at: 0)
                tableView.insertRows(at: [IndexPath(item: 2, section: sectionPaySummary)], with: .fade)
            }
        }
        isUsingPreloBalance = isON
        
        adjustRingkasan()
    }
    
    func preloBalanceInputCellBalanceSubmitted(_ balance: Int) {
        var balanceFix = balance
        var warning = ""
        var priceAfterDiscountsWithoutBalance = priceAfterDiscounts
        if isUsingPreloBalance { // Pengecekan #1
            let discBalance = discountItems[0]
            if (discBalance.title == "Prelo Balance") { // Pengecekan #2
                priceAfterDiscountsWithoutBalance += discBalance.value
            }
        }
        if (balanceFix > priceAfterDiscountsWithoutBalance) {
            balanceFix = priceAfterDiscountsWithoutBalance
            warning += "Prelo balance yang digunakan disesuaikan karena melebihi subtotal. "
        }
        if (warning != "") {
            Constant.showDialog("Prelo Balance", message: warning)
        }
        if (balanceFix > balanceAvailable)
        {
            UIAlertView.SimpleShow("Perhatian", message: "Prelo balance yang tersedia tidak mencukupi")
            return
        }
        if (discountItems.count > 0) {
            var discBalance = discountItems[0]
            discBalance.value = balanceFix
            discountItems[0] = discBalance
        }
        
        adjustRingkasan()
    }
    
    // MARK: - Voucher cell delegate
    
    func voucherInputCellNeedrefresh(_ isON: Bool) {
        isShowVoucher = isON
        self.setupTable()
    }
    
    func voucherInputCellSubmitted(_ voucher: String) {
        self.voucherApplied = voucher
        self.synchCart()
    }
    
    func voucherInputCellTyped(_ voucher: String) {
        self.voucherTyped = voucher
    }
    
    // MARK: - User Related Delegate
    
    func userLoggedIn() {
        user = CDUser.getOne()
        cartProducts = CartProduct.getAll(User.EmailOrEmptyString)
        synchCart()
    }
    
    func userCancelLogin() {
        user = CDUser.getOne()
        if (user == nil) {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Navigation
    
    func performSegTour() {
        self.performSegue(withIdentifier: "segTour", sender: nil)
    }
    
    func navigateToVC(_ vc: UIViewController) {
        if (previousController != nil) {
            self.previousController!.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "segOK") {
            let c = segue.destination as! CarConfirmViewController
            c.orderID = (checkoutResult?["order_id"].string)!
            c.totalPayment = (checkoutResult?["final_price"].int)!
            c.paymentMethod = (checkoutResult?["payment_method"].string)!
        }
        
    }
    
    // MARK: - New Address
    
    func insertNewAddress() {
        var fullname = ""
        var phone = ""
        var address = ""
        var postalcode = ""
        var pID = ""
        var rID = ""
        var sdID = ""
        
        for i in cellsData.keys {
            let b = cellsData[i]

//            print(b?.value!)
            
            if (b?.title == titleNama) {
                fullname = (b?.value)!
            }
            
            if (b?.title == titleTelepon) {
                phone = (b?.value)!
            }
            
            if (b?.title == titleAlamat) {
                address = (b?.value)!
            }
            
            if (b?.title == titlePostal) {
                postalcode = (b?.value)!
            }
            
            if (b?.title == titleProvinsi) {
                pID = (b?.value)!
            }
            
            if (b?.title == titleKota) {
                rID = (b?.value)!
            }
            
            if (b?.title == titleKecamatan) {
                sdID = (b?.value)!
            }
        }
        
        let _ = request(APIMe.createAddress(addressName: "", recipientName: fullname, phone: phone, provinceId: selectedProvinsiID, provinceName: pID, regionId: selectedKotaID, regionName: rID, subdistrictId: selectedKecamatanID, subdistricName: sdID, address: address, postalCode: postalcode)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Alamat Baru")) {
//                Constant.showDialog("Alamat Baru", message: "Alamat berhasil ditambahkan")
            }
        }
    }
}

// MARK: - Class

class BaseCartData : NSObject
{
    var title : String?
    var placeHolder : String?
    var value : String?
    var enable : Bool = true
    var image : UIImage?
    var keyboardType = UIKeyboardType.default
    
    var pickerPrepDataBlock : PrepDataBlock?
    
    static func instance(_ title : String?, placeHolder : String?) -> BaseCartData {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = true
        
        return b
    }
    
    static func instance(_ title : String?, placeHolder : String?, enable : Bool) -> BaseCartData {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = enable
        
        return b
    }
    
    static func instance(_ title : String?, placeHolder : String?, value : String) -> BaseCartData {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = true
        
        return b
    }
    
    static func instance(_ title : String?, placeHolder : String?, value : String, pickerPrepBlock : PrepDataBlock?) -> BaseCartData {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = true
        
        b.pickerPrepDataBlock = pickerPrepBlock
        
        return b
    }
    
    static func instance(_ title : String?, placeHolder : String?, value : String?, enable : Bool) -> BaseCartData {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = enable
        
        return b
    }
    
    static func instanceWith(_ image : UIImage, placeHolder : String) -> BaseCartData {
        let b = BaseCartData()
        b.title = ""
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = true
        b.image = image
        
        return b
    }
    
    static func instanceWith(_ image : UIImage, placeHolder : String, pickerPrepBlock : PrepDataBlock?) -> BaseCartData {
        let b = BaseCartData.instanceWith(image, placeHolder: placeHolder)
        b.pickerPrepDataBlock = pickerPrepBlock
        return b
    }
}

// MARK: - Class

class BaseCartCell : UITableViewCell {
    @IBOutlet var captionTitle : UILabel?
    var parent : UIViewController?
    
    var baseCartData : BaseCartData?
    var lastIndex : IndexPath?
    
    var idxPath : IndexPath?
    
    @IBOutlet var bottomLine : UIView?
    @IBOutlet var topLine : UIView?
    
    func obtainValue() -> BaseCartData? {
        return nil
    }
    
    func adapt(_ item : BaseCartData?) {
        
    }
}

// MARK: - Class - Input berupa title dan textfield

class CartCellInput : BaseCartCell, UITextFieldDelegate {
    @IBOutlet var txtField : UITextField!
//    @IBOutlet var consWidthTxtField: NSLayoutConstraint!
    
    var textChangedBlock : (IndexPath, String) -> () = { _, _ in }
    
    override var canBecomeFirstResponder : Bool {
        return txtField.canBecomeFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        return txtField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return txtField.resignFirstResponder()
    }
    
    override func adapt(_ item : BaseCartData?) {
        baseCartData = item
        guard let item = item else {
            captionTitle?.text = "-"
            txtField.text = "-"
            return
        }
        
        captionTitle?.text = item.title
        let placeholder = item.placeHolder
        if (placeholder != nil) {
            txtField.placeholder = placeholder
        }
        if (item.title?.lowercased() == "nama") {
//            consWidthTxtField.constant = 200
        } else {
//            consWidthTxtField.constant = 115
        }
        
        let value = item.value
        if (value != nil) {
            if (value! == "10%") {
                txtField.font = UIFont.boldSystemFont(ofSize: 14)
                let l = self.contentView.viewWithTag(666)
                l?.isHidden = true
            }
            txtField.text = value
        } else {
            txtField.text = ""
        }
        
        txtField.keyboardType = item.keyboardType
        txtField.isEnabled = item.enable
        txtField.delegate = self
    }
    
    override func obtainValue() -> BaseCartData? {
        baseCartData?.value = txtField.text
        return baseCartData
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        var text = ""
        if (textField.text != nil) {
            text = textField.text!
        }
        if (idxPath != nil) {
            self.textChangedBlock(idxPath!, text)
        }
    }
}

// MARK: - Class - Input berupa title dan picker

class CartCellInput2 : BaseCartCell, PickerViewDelegate
{
    @IBOutlet var captionValue : UILabel?
    
    override var canBecomeFirstResponder : Bool {
        return parent != nil
    }
    
    override func becomeFirstResponder() -> Bool {
        let p = parent?.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = []
        p?.pickerDelegate = self
        p?.prepDataBlock = baseCartData?.pickerPrepDataBlock
        p?.title = baseCartData?.title
        parent?.view.endEditing(true)
        parent?.navigationController?.pushViewController(p!, animated: true)
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
    
    func pickerDidSelect(_ item: String) {
        captionValue?.text = PickerViewController.HideHiddenString(item)
    }
    
    override func adapt(_ item : BaseCartData?) {
        baseCartData = item
        captionTitle?.text = item?.title
        let value = item?.value
        if (value != nil) {
            captionValue?.text = value
        } else {
            captionValue?.text = ""
        }
    }
    
    override func obtainValue() -> BaseCartData? {
        baseCartData?.value = captionValue?.text
        return baseCartData
    }
}

// MARK: - Class - 'Edit data kamu'

class CartCellEdit : UITableViewCell
{
    override var canBecomeFirstResponder : Bool {
        return false
    }
}

// MARK: - Class - Clear CartCellEdit

class CartCellClearAll : UITableViewCell {
    
}

// MARK: - Protocol

protocol CartItemCellDelegate
{
    func itemNeedDelete(_ indexPath : IndexPath)
    func itemNeedUpdateShipping(_ indexPath : IndexPath)
}


// MARK: - Class - Item produk

class CartCellItem : UITableViewCell
{
    @IBOutlet var shade : UIView?
    @IBOutlet var captionName : UILabel?
    @IBOutlet var captionPrice : UILabel?
    @IBOutlet var captionLocation : UILabel?
    @IBOutlet var btnShippment : UIButton?
    @IBOutlet var ivCover : UIImageView?
    @IBOutlet var captionFrom : UILabel?
    
    @IBOutlet var bottomLine : UIView?
    @IBOutlet var topLine : UIView?
    
    override var canBecomeFirstResponder : Bool {
        return false
    }
    
    var selectedPaymentId : String = ""
    var cartItemCellDelegate : CartItemCellDelegate?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        ivCover?.afCancelRequest()
    }
    
    func adapt (_ json : JSON)
    {
        print(json)
        captionName?.text = json["name"].stringValue
        captionLocation?.text = ""
        captionFrom?.text = ""
        
        if let raw : Array<AnyObject> = json["display_picts"].arrayObject as Array<AnyObject>?
        {
            var ori : Array<String> = []
            for o in raw
            {
                if let s = o as? String
                {
                    ori.append(s)
                }
            }
            
            if (ori.count > 0)
            {
//                ivCover?.image = nil
                let u = URL(string: ori.first!)
                ivCover?.afSetImage(withURL: u!)
            }
        }
        
        if let error = json["_error"].string
        {
            let string = error
            let attString = NSMutableAttributedString(string: string)
            attString.addAttributes([NSForegroundColorAttributeName:UIColor.red, NSFontAttributeName:UIFont.systemFont(ofSize: 14)], range: AppToolsObjC.range(of: string, inside: string))
            captionPrice?.attributedText = attString
            captionPrice?.numberOfLines = 0
            shade?.isHidden = false
            
            self.btnShippment?.isHidden = true
            
            let sellerLocationID = json["seller_region"].stringValue
            if let regionName = CDRegion.getRegionNameWithID(sellerLocationID)
            {
                self.captionFrom?.text = "Dari " + regionName
            } else
            {
                self.captionFrom?.text = ""
            }
            
        } else {
            let sh = json["shipping_packages"].array!
            var first = sh.first
            for i in 0...sh.count-1
            {
                let s = sh[i]
                let id = s["_id"].string!
                if (id == selectedPaymentId)
                {
                    first = s
                }
            }
            if (selectedPaymentId == "")
            {
                first = sh.first
            }
            let ongkir = json["free_ongkir"].bool == true ? 0 : first?["price"].int
            
            if let name = first?["name"].string
            {
                self.btnShippment?.setTitle(name, for: UIControlState())
                self.btnShippment?.isHidden = false
            } else
            {
                self.btnShippment?.isHidden = true
            }
            
            let ongkirString = ongkir == 0 ? "(FREE ONGKIR)" : " (+ONGKIR " + ongkir!.asPrice + ")"
            let priceString = json["price"].int!.asPrice + ongkirString
            let string = priceString + "" + ""
            let attString = NSMutableAttributedString(string: string)
            attString.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColorDark, NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)], range: AppToolsObjC.range(of: priceString, inside: string))
            attString.addAttributes([NSForegroundColorAttributeName:Theme.GrayDark, NSFontAttributeName:UIFont.systemFont(ofSize: 10)], range: AppToolsObjC.range(of: ongkirString, inside: string))
            captionPrice?.attributedText = attString
            shade?.isHidden = true
            
            let sellerLocationID = json["seller_region"].stringValue
            if let regionName = CDRegion.getRegionNameWithID(sellerLocationID)
            {
                self.captionFrom?.text = "Dari " + regionName
            } else
            {
                self.captionFrom?.text = ""
            }
        }
        
    }
    
    var indexPath : IndexPath = IndexPath(row: 0, section: 0)
    
    @IBAction func deleteMe()
    {
        if let d = cartItemCellDelegate
        {
            d.itemNeedDelete(indexPath)
        }
    }
    
    @IBAction func switchShipping()
    {
        if let d = cartItemCellDelegate
        {
            d.itemNeedUpdateShipping(indexPath)
        }
    }
}

// MARK: - Class

class CartAddressCell : ACEExpandableTextCell
{
    var baseCartData : BaseCartData?
    var lastIndex : IndexPath?
    
    func adapt(_ item : BaseCartData)
    {
        baseCartData = item
        self.textView.placeholder = item.title
        self.text = item.value
    }
    
    func obtain() -> BaseCartData?
    {
        return baseCartData
    }
}

// MARK: - Protocol

protocol PreloBalanceInputCellDelegate
{
    func preloBalanceInputCellNeedrefresh(_ isON : Bool)
    func preloBalanceInputCellBalanceSubmitted(_ balance : Int)
}

// MARK: - Class - Input prelo balance

class PreloBalanceInputCell : UITableViewCell, UITextFieldDelegate
{
    @IBOutlet var txtInput : UITextField?
    @IBOutlet var captionTotalBalance : UILabel!
    @IBOutlet var switchBalance : UISwitch!
    
    var delegate : PreloBalanceInputCellDelegate?
    var first = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        
        self.txtInput?.superview?.layer.borderColor = UIColor.lightGray.cgColor
        self.txtInput?.superview?.layer.borderWidth = 1
        self.txtInput?.superview?.layer.cornerRadius = 2
        
        if (first)
        {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, /*UIScreen.mainScreen().bounds.width*/width: 200, height: 44))
            toolbar.isTranslucent = true
            toolbar.tintColor = Theme.PrimaryColor
            
            let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(PreloBalanceInputCell.processPreloInput))
            
            let space = UIBarButtonItem(barButtonSpaceType: .flexibleSpace)
            
            toolbar.items = [space, doneBtn]
            self.txtInput?.inputAccessoryView = toolbar
            first = false
        }
    }
    
    @IBAction func switched()
    {
        delegate?.preloBalanceInputCellNeedrefresh(switchBalance.isOn)
    }
    
    func processPreloInput()
    {
        if let s = txtInput?.text
        {
            if let _ = s.rangeOfCharacter(from: CharacterSet(charactersIn: "0987654321").inverted)
            {
                UIAlertView.SimpleShow("Perhatian", message: "Jumlah prelo balance yang digunakan tidak valid")
            } else
            {
                let i = s.int
                self.delegate?.preloBalanceInputCellBalanceSubmitted(i)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.processPreloInput()
        
        textField.resignFirstResponder()
        return false
    }
}

// MARK: - Protocol

protocol VoucherInputCellDelegate {
    func voucherInputCellNeedrefresh(_ isON : Bool)
    func voucherInputCellSubmitted(_ voucher : String)
    func voucherInputCellTyped(_ voucher : String)
}

// MARK: - Class - Input voucher

class VoucherInputCell : UITableViewCell, UITextFieldDelegate {
    @IBOutlet var txtInput : UITextField?
    @IBOutlet var switchVoucher : UISwitch!
    
    var delegate : VoucherInputCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.txtInput?.delegate = self
    }
    
    @IBAction func switched() {
        delegate?.voucherInputCellNeedrefresh(switchVoucher.isOn)
    }
    
    @IBAction func processVoucher() {
        if let s = txtInput?.text {
            if (s != "") {
                delegate?.voucherInputCellSubmitted(s)
            } else {
                Constant.showDialog("Perhatian", message: "Isi kode voucher terlebih dahulu")
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.voucherInputCellTyped(textField.text!)
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.voucherInputCellTyped(textField.text!)
    }
}

// MARK: - Class - Total belanja

class CartGrandTotalCell : BaseCartCell
{
    @IBOutlet var captionValue : UILabel!
    
    override func adapt(_ item : BaseCartData?) {
        baseCartData = item
        if (item == nil) {
            captionValue.text = "-"
            return
        }
        captionValue.text = item!.value
    }
    
    override func obtainValue() -> BaseCartData? {
        baseCartData?.value = captionValue.text
        return baseCartData
    }
}

// MARK: - Class - Metode pembayaran

class CartPaymethodCell : UITableViewCell {
    @IBOutlet weak var vw3Banks: UIView!
    @IBOutlet weak var vw4Banks: UIView!
    @IBOutlet weak var vwDropdownBanks: UIView!
    @IBOutlet weak var vwDropdown: UIView! // borderview
    @IBOutlet weak var lblDropdown: UILabel! // bank name
    var isEnableCCPayment : Bool = false
    var isEnableIndomaretPayment : Bool = false
    var isShowBankBRI : Bool = false
    var isDropdownMode : Bool = false
    var parent: UIViewController?
    
    @IBOutlet var lblDesc: [UILabel]!
    
    var dropDown: DropDown!
    var selectedBankIndex = -1
    
    // Tag set in storyboard
    // 0 = Transfer Bank
    // 1 = Kartu Kredit
    // 2 = Indomaret
    let tagBankTrf = 0
    let tagCreditCard = 1
    let tagIndomaret = 2
    @IBOutlet var btnsMethod: [UIButton]!
    
    @IBOutlet var imgIndomaret: TintedImageView!
    
    var methodChosen : (PaymentMethod) -> () = { _ in }
    
    func adapt(selectedPayment : PaymentMethod) {
        if isDropdownMode {
            // assign new methd
            vw3Banks.isHidden = true
            vw4Banks.isHidden = true
            vwDropdownBanks.isHidden = false
            vwDropdown.layer.borderColor = Theme.GrayLight.cgColor
            vwDropdown.layer.borderWidth = 1
            lblDropdown.text = "Pilih Bank Tujuan Transfer"
            
            self.setupDropdownBank()
        } else {
            vwDropdownBanks.isHidden = true
        }
        
        if (selectedPayment == .indomaret) {
            imgIndomaret.tint = false
        } else {
            imgIndomaret.tint = true
            imgIndomaret.tintColor = Theme.GrayLight
        }
        
        var txtDesc = ""
        if (selectedPayment == .bankTransfer) {
            txtDesc = "Pembayaran aman dengan sistem Rekber ke rekening Prelo"
        } else if (selectedPayment == .creditCard) {
            txtDesc = "Pembayaran aman melalui kartu kredit"
        } else if (selectedPayment == .indomaret) {
            txtDesc = "Pembayaran aman melalui Indomaret"
        }
        for lbl in lblDesc {
            lbl.text = txtDesc
            lbl.font = UIFont.systemFont(ofSize: 11)
        }
    }
    
    @IBAction func methodPressed(_ sender: UIButton) {
        if (sender.tag == tagCreditCard && !isEnableCCPayment) { // Disabled method
            UIAlertView.SimpleShow("Coming Soon", message: "Metode pembayaran ini belum tersedia")
            return
        }
        if (sender.tag == tagIndomaret && !isEnableIndomaretPayment) { // Disabled method
            UIAlertView.SimpleShow("Coming Soon", message: "Metode pembayaran ini belum tersedia")
            return
        }
        for i in 0...btnsMethod.count - 1 {
            if (sender.isEqual(btnsMethod[i])) { // Clicked button
                if let b = btnsMethod[i].superview as? BorderedView {
                    b.cartSelectAsPayment(true, useOriginalColor: (i == tagIndomaret))
                }
                var mthd : PaymentMethod!
                if (sender.tag == tagBankTrf) {
                    mthd = .bankTransfer
                } else if (sender.tag == tagCreditCard) {
                    mthd = .creditCard
                } else if (sender.tag == tagIndomaret) {
                    mthd = .indomaret
                }
                self.methodChosen(mthd)
            } else { // Other button
                if let b = btnsMethod[i].superview as? BorderedView {
                    b.cartSelectAsPayment(false, useOriginalColor: (i == tagIndomaret))
                }
            }
        }
    }
    
    @IBAction func dropDownPressed(_ sender: Any) {
        // dropdown menu
        /*
        var items = ["BCA", "Mandiri", "BNI"]
        
        if isShowBankBRI {
            items.append("BRI")
        }
        
        let bankCount = items.count
        let bankAlert = UIAlertController(title: "Pilih Bank", message: nil, preferredStyle: .actionSheet)
        bankAlert.popoverPresentationController?.sourceView = self.vwDropdown
        bankAlert.popoverPresentationController?.sourceRect = self.vwDropdown.frame
        for i in 0...bankCount - 1 {
            bankAlert.addAction(UIAlertAction(title: items[i], style: .default, handler: { act in
                self.lblDropdown.text = items[i]
                bankAlert.dismiss(animated: true, completion: nil)
            }))
        }
        bankAlert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in
            bankAlert.dismiss(animated: true, completion: nil)
        }))
        parent?.present(bankAlert, animated: true, completion: nil)
         */
        
        dropDown.show()
    }
    
    func setupDropdownBank() {
        dropDown = DropDown()
        
        var items = ["BCA", "Mandiri", "BNI"]
        
        if isShowBankBRI {
            items.append("BRI")
        }
        
        // The list of items to display. Can be changed dynamically
        dropDown.dataSource = items
        
        // Action triggered on selection
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.lblDropdown.text = items[index]
            self.selectedBankIndex = index
            let p = self.parent as! CartViewController
            p.selectedBankIndex = index
            p.targetBank = items[index]
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        
        dropDown.width = self.vwDropdown.width - 16
        
        dropDown.anchorView = self.vwDropdown
        
        if selectedBankIndex > -1 {
            dropDown.selectRow(at: selectedBankIndex)
            lblDropdown.text = items[selectedBankIndex]
        }
    }
}

// MARK: - Class

@IBDesignable
class PreloBalanceTextfield: UITextField {
    
    @IBInspectable var inset: CGFloat = 0
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: inset, dy: inset)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
    
}

// MARK: - Extension

extension BorderedView
{
    func cartSelectAsPayment(_ select : Bool, useOriginalColor : Bool)
    {
        if (useOriginalColor) {
            if (select) {
                for v in self.subviews {
                    if (v.isKind(of: UILabel.classForCoder())) {
                        let l = v as! UILabel
                        l.textColor = Theme.PrimaryColorDark
                    } else if (v.isKind(of: TintedImageView.classForCoder())) {
                        let i = v as! TintedImageView
                        i.tint = false
                    }
                }
            } else {
                setColor(Theme.GrayLight)
            }
        } else {
            setColor(select ? Theme.PrimaryColorDark : Theme.GrayLight)
        }
    }
    
    fileprivate func setColor(_ c : UIColor)
    {
        for v in self.subviews
        {
            if (v.isKind(of: UILabel.classForCoder()))
            {
                let l = v as! UILabel
                l.textColor = c
            } else if (v.isKind(of: TintedImageView.classForCoder()))
            {
                let i = v as! TintedImageView
                i.tint = true
                i.tintColor = c
            }
        }
    }
}

// MARK: - DropdownCell [NEW]
// cell_dropDown
class DropdownCell: UITableViewCell {
    @IBOutlet weak var vwDropdown: UIView!
    @IBOutlet weak var lblDropdown: UILabel!
    
    func adapt(_ address: AddressItem) {
        vwDropdown.layer.borderColor = Theme.GrayLight.cgColor
        vwDropdown.layer.borderWidth = 1
        
        let text = address.recipientName + " (" + address.addressName + ") " + address.address + " " + address.subdisrictName + ", " + address.regionName + " " + address.provinceName + " " + address.postalCode
        
        let attString : NSMutableAttributedString = NSMutableAttributedString(string: text)
        
        attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)], range: (text as NSString).range(of: address.recipientName))
        
        lblDropdown.attributedText = attString
    }
    
    func adaptNew(_ title: String) {
        lblDropdown.text = title
    }
    
}

// MARK: - SaveAlamatCell [NEW]
// cell_saveAddress
class SaveAlamatCell: UITableViewCell {
    @IBOutlet weak var lblCheckbox: UILabel! // hidden
    
    // checked -> isHidden false
    func adapt(_ isChecked: Bool) {
        lblCheckbox.isHidden = !isChecked
    }
    
}

// MARK: - FullAlamatCell [NEW]
// cell_fullAddress
class FullAlamatCell: UITableViewCell { // height 120
    @IBOutlet weak var lblRecipientName: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblSubdistrictRegion: UILabel!
    @IBOutlet weak var lblProvince: UILabel!
    @IBOutlet weak var lblPhone: UILabel!
    
    func adapt(_ address: AddressItem) {
        lblRecipientName.text = address.recipientName
        lblAddress.text = address.address
        lblSubdistrictRegion.text = address.subdisrictName + ", " + address.regionName
        lblProvince.text = address.provinceName + " " + address.postalCode
        lblPhone.text = "Telepon " + address.phone
    }
    
}
