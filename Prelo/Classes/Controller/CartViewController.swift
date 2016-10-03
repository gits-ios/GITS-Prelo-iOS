//
//  CartViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/3/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Crashlytics

// MARK: - Class

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
    var ccPaymentOrderId : String = ""
    
    // Prices and discounts data container
    var bankTransferDigit : Int = 0
    var isUsingPreloBalance : Bool = false
    var isHalfBonusMode : Bool = false // Apakah aturan half bonus aktif
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
    
    // Cell data container
    var cellsData : [NSIndexPath : BaseCartData] = [:]
    
    // Payment reminder
    @IBOutlet weak var lblPaymentReminder: UILabel!
    @IBOutlet weak var consHeightPaymentReminder: NSLayoutConstraint!
    
    // Table, loading, label, send btn
    @IBOutlet var tableView : UITableView!
    @IBOutlet var captionNoItem: UILabel!
    @IBOutlet var loadingCart: UIActivityIndicatorView!
    @IBOutlet var lblSend: UILabel!
    @IBOutlet var consHeightLblSend: NSLayoutConstraint!
    @IBOutlet var btnSend : UIButton!
    
    // Metode pembayaran
    var selectedPayment = "Bank Transfer"
    var availablePayments = ["Bank Transfer", "Credit Card"]
    
    // Sections
    let sectionProducts = 0
    let sectionDataUser = 1
    let sectionAlamatUser = 2
    let sectionPayMethod = 3
    let sectionPaySummary = 4
    
    // Field titles
    let titleNama = "Nama"
    let titleTelepon = "Telepon"
    let titleAlamat = "Mis: Jl. Tamansari III no. 1"
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
    
    // MARK: - Init
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.Checkout)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Checkout)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Keyboard animation
        self.an_subscribeKeyboardWithAnimations({ r, i, o in
            if (o) {
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
            } else {
                self.tableView.contentInset = UIEdgeInsetsZero
            }
        }, completion: nil)
        
        // Perform tour for first time checkout
        let checkTour = NSUserDefaults.standardUserDefaults().boolForKey("cartTour")
        if (checkTour == false) {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "cartTour")
            NSUserDefaults.standardUserDefaults().synchronize()
            NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(CartViewController.performSegTour), userInfo: nil, repeats: false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = PageName.Checkout
        
        // Get unpaid transaction
        request(APITransactionCheck.CheckUnpaidTransaction).responseJSON { resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Checkout - Unpaid Transaction")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if (data["user_has_unpaid_transaction"].boolValue == true) {
                    let nUnpaid = data["n_transaction_unpaid"].intValue
                    self.lblPaymentReminder.text = "Kamu memiliki \(nUnpaid) transaksi yg belum dibayar"
                    self.consHeightPaymentReminder.constant = 40
                }
            }
        }
        
        // Get cart products
        cartProducts = CartProduct.getAll(User.EmailOrEmptyString)
        
        // Init table
        if (cartProducts.count == 0) { // Cart is empty
            tableView.hidden = true
            loadingCart.hidden = true
            captionNoItem.hidden = false
        } else {
            if (user == nil) { // User isn't logged in
                tableView.hidden = true
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            } else { // Show cart
                synchCart()
            }
        }
    }
    
    // Refresh data cart dan seluruh tampilan
    func synchCart() {
        // Hide table
        tableView.hidden = true
        
        // Reset data
        isUsingPreloBalance = false
        discountItems = []
        initUserDataSections()
        
        // Prepare parameter for API refresh cart
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let p = AppToolsObjC.jsonStringFrom(c)
        let a = "{\"address\": \"alamat\", \"province_id\": \"" + selectedProvinsiID + "\", \"region_id\": \"" + selectedKotaID + "\", \"subdistrict_id\": \"" + selectedKecamatanID + "\", \"postal_code\": \"\"}"
        print("cart_products : \(p)")
        print("shipping_address : \(a)")
        
        // API refresh cart
        request(APICart.Refresh(cart: p, address: a, voucher: voucherApplied)).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Keranjang Belanja")) {
                
                // Back to prev page if cart is empty
                if (self.shouldBack == true) {
                    self.navigationController?.popViewControllerAnimated(true)
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
                self.isShowBankBRI = false
                self.isEnableCCPayment = false
                if let ab = data["ab_test"].array {
                    for i in 0...ab.count - 1 {
                        if (ab[i].stringValue.lowercaseString == "half_bonus") {
                            self.isHalfBonusMode = true
                        } else if (ab[i].stringValue.lowercaseString == "bri") {
                            self.isShowBankBRI = true
                        } else if (ab[i].stringValue.lowercaseString == "cc") {
                            self.isEnableCCPayment = true
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
        
        // Prepare textfield value
        var fullname = ""
        var phone = ""
        var address = ""
        var postalcode = ""
        var pID = ""
        var rID = ""
        var sdID = ""
        
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
        
        // Fill cellsData
        let c = BaseCartData.instance(titlePostal, placeHolder: "Kode Pos", value : postalcode)
        c.keyboardType = UIKeyboardType.NumberPad
        self.cellsData = [
            NSIndexPath(forRow: 0, inSection: sectionDataUser):BaseCartData.instance(titleNama, placeHolder: "Nama Lengkap Kamu", value : fullname),
            NSIndexPath(forRow: 1, inSection: sectionDataUser):BaseCartData.instance(titleTelepon, placeHolder: "Nomor Telepon Kamu", value : phone),
            NSIndexPath(forRow: 0, inSection: sectionAlamatUser):BaseCartData.instance(titleAlamat, placeHolder: "Alamat Lengkap Kamu", value : address),
            NSIndexPath(forRow: 1, inSection: sectionAlamatUser):BaseCartData.instance(titleProvinsi, placeHolder: nil, value: pID, pickerPrepBlock: { picker in
                
                picker.items = CDProvince.getProvincePickerItems()
                picker.textTitle = "Pilih Provinsi"
                picker.doneLoading()
                
                picker.selectBlock = { string in
                    self.selectedProvinsiID = PickerViewController.RevealHiddenString(string)
                    
                    // Set picked address
                    self.selectedKotaID = ""
                    self.selectedKecamatanID = ""
                    self.selectedKecamatanName = ""
                    let idxs = [NSIndexPath(forRow: 2, inSection: self.sectionAlamatUser), NSIndexPath(forRow: 3, inSection: self.sectionAlamatUser)]
                    self.cellsData[idxs[0]]?.value = "Pilih Kota/Kabupaten"
                    self.cellsData[idxs[1]]?.value = "Pilih Kecamatan"
                    self.tableView.reloadRowsAtIndexPaths(idxs, withRowAnimation: .Fade)
                }
            }),
            NSIndexPath(forRow: 2, inSection: sectionAlamatUser):BaseCartData.instance(titleKota, placeHolder: nil, value: rID, pickerPrepBlock: { picker in
                
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
                    let idxs = [NSIndexPath(forRow: 1, inSection: self.sectionAlamatUser), NSIndexPath(forRow: 2, inSection: self.sectionAlamatUser), NSIndexPath(forRow: 3, inSection: self.sectionAlamatUser)]
                    self.cellsData[idxs[0]]?.value = CDProvince.getProvinceNameWithID(self.selectedProvinsiID)
                    self.cellsData[idxs[1]]?.value = string.componentsSeparatedByString(PickerViewController.TAG_START_HIDDEN)[0]
                    self.cellsData[idxs[2]]?.value = "Pilih Kecamatan"
                }
            }),
            NSIndexPath(forRow: 3, inSection: sectionAlamatUser):BaseCartData.instance(titleKecamatan, placeHolder: nil, value: sdID, pickerPrepBlock: { picker in
                
                if (self.kecamatanPickerItems.count <= 0) {
                    self.tableView.hidden = true
                    self.loadingCart.hidden = false
                    request(APIMisc.GetSubdistrictsByRegionID(id: self.selectedKotaID)).responseJSON { resp in
                        if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Daftar Kecamatan")) {
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
                        self.tableView.hidden = false
                        self.loadingCart.hidden = true
                    }
                } else {
                    picker.items = self.kecamatanPickerItems
                    picker.textTitle = "Pilih Kecamatan"
                    picker.doneLoading()
                }
                
                picker.selectBlock = { string in
                    self.selectedKecamatanID = PickerViewController.RevealHiddenString(string)
                    self.selectedKecamatanName = string.componentsSeparatedByString(PickerViewController.TAG_START_HIDDEN)[0]
                    self.refreshByLocationChange = true
                    
                    self.synchCart()
                    
                    // Set picked address value
                    let idxs = [NSIndexPath(forRow: 1, inSection: self.sectionAlamatUser), NSIndexPath(forRow: 2, inSection: self.sectionAlamatUser), NSIndexPath(forRow: 3, inSection: self.sectionAlamatUser)]
                    self.cellsData[idxs[0]]?.value = CDProvince.getProvinceNameWithID(self.selectedProvinsiID)
                    self.cellsData[idxs[1]]?.value = CDRegion.getRegionNameWithID(self.selectedKotaID)
                    self.cellsData[idxs[2]]?.value = string.componentsSeparatedByString(PickerViewController.TAG_START_HIDDEN)[0]
                }
            }),
            NSIndexPath(forRow: 4, inSection: sectionAlamatUser):c
        ]
    }
    
    func adjustTotal() {
        // Sum up shipping price
        totalOngkir = 0
        for i in 0...cartProducts.count-1 {
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
        let i = NSIndexPath(forRow: self.cartProducts.count, inSection: self.sectionProducts)
        let i2 = NSIndexPath(forRow: 0, inSection: self.sectionPaySummary)
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
                    if (isHalfBonusMode) {
                        if (discountItems[i].value > self.subtotalPrice / 2) {
                            discountItems[i].value = self.subtotalPrice / 2
                            // Show lblSend
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
                let idxDisc = NSIndexPath(forRow: 1 + i, inSection: self.sectionPaySummary)
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
        
        // Set cellsData for transfer code
        if (priceAfterDiscounts > 0) {
            let idxKode = NSIndexPath(forRow: 1 + discountItems.count, inSection: self.sectionPaySummary)
            let bKode = BaseCartData.instance("Kode Unik Transfer", placeHolder: nil, value: bankTransferDigit.asPrice, enable: false)
            self.cellsData[idxKode] = bKode
        }
        
        // Set cellsData for grand total
        let idxGTotal = NSIndexPath(forRow: (priceAfterDiscounts > 0 ? 2 : 1) + discountItems.count, inSection: self.sectionPaySummary)
        let bGTotal = BaseCartData.instance("Total Pembayaran", placeHolder: nil, value: (priceAfterDiscounts + (priceAfterDiscounts > 0 ? bankTransferDigit : 0)).asPrice, enable: false)
        self.cellsData[idxGTotal] = bGTotal
        
        self.printCellsData()
        self.setupTable()
    }
    
    func setupTable() {
        // Setup table
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.hidden = false
        self.tableView.reloadData()
    }
    
    // MARK: - Cell creations
    
    func createOrGetBaseCartCell(tableView : UITableView, indexPath : NSIndexPath, id : String, isShowBottomLine : Bool) -> BaseCartCell {
        let b : BaseCartCell = tableView.dequeueReusableCellWithIdentifier(id) as! BaseCartCell
        
        b.parent = self
        b.adapt(cellsData[indexPath])
        b.idxPath = indexPath
        b.lastIndex = indexPath
        if (isShowBottomLine) {
            b.bottomLine?.hidden = false
        } else {
            b.bottomLine?.hidden = true
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
    
    func createExpandableCell(tableView : UITableView, indexPath : NSIndexPath) -> ACEExpandableTextCell? {
        var acee = tableView.dequeueReusableCellWithIdentifier("address_cell") as? CartAddressCell
        if (acee == nil) {
            acee = CartAddressCell(style: UITableViewCellStyle.Default, reuseIdentifier: "address_cell")
            acee?.selectionStyle = UITableViewCellSelectionStyle.None
            acee?.expandableTableView = tableView
            
            acee?.textView.font = UIFont.systemFontOfSize(14)
            acee?.textView.textColor = UIColor.darkGrayColor()
        }
        
        if (acee?.lastIndex != nil) {
            cellsData[(acee?.lastIndex)!] = acee?.obtain()
        }
        
        acee?.adapt(cellsData[indexPath]!)
        acee?.lastIndex = indexPath
        
        return acee
    }
    
    func createPayMethodCell(tableView : UITableView, indexPath : NSIndexPath) -> CartPaymethodCell {
        let cell : CartPaymethodCell = tableView.dequeueReusableCellWithIdentifier("cell_paymethod") as! CartPaymethodCell
        cell.isEnableCCPayment = isEnableCCPayment
        cell.methodChosen = { tag in
            self.setPaymentOption(tag)
        }
        if (self.isShowBankBRI) {
            cell.vw3Banks.hidden = true
            cell.vw4Banks.hidden = false
        } else {
            cell.vw3Banks.hidden = false
            cell.vw4Banks.hidden = true
        }
        
        return cell
    }
    
    // MARK: - UITableView functions
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == sectionProducts) {
            return arrayItem.count + 1 // Total products + subtotal cells
        } else if (section == sectionDataUser) {
            return 2
        } else if (section == sectionAlamatUser) {
            return 5
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        var cell : UITableViewCell = UITableViewCell()
        
        if (section == sectionProducts) {
            if (row == arrayItem.count) { // Subtotal
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
            } else { // Cart product
                let i = tableView.dequeueReusableCellWithIdentifier("cell_item2") as! CartCellItem
                let cp = cartProducts[indexPath.row]
                i.selectedPaymentId = cp.packageId
                //i.selectedPaymentId = "" // debug
                i.adapt(arrayItem[indexPath.row])
                i.cartItemCellDelegate = self
                
                if (row != 0) {
                    i.topLine?.hidden = true
                }
                
                i.indexPath = indexPath
                
                cell = i
            }
        } else if (section == sectionDataUser) {
            if (row == 2) { // Currently not used because max row idx is 1
                cell = tableView.dequeueReusableCellWithIdentifier("cell_edit")!
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
        } else if (section == sectionPayMethod) {
            if (row == 0) { // Payment method
                cell = createPayMethodCell(tableView, indexPath: indexPath)
            } else if (row == 1) { // Prelo balance switch
                let cellId = isUsingPreloBalance ? "pbcellInput2" : "pbcellInput1"
                let c = tableView.dequeueReusableCellWithIdentifier(cellId) as! PreloBalanceInputCell
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
                let c = tableView.dequeueReusableCellWithIdentifier(cellId) as! VoucherInputCell
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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let section = indexPath.section
        let row = indexPath.row
        
        if (section == sectionProducts) {
            if (row == arrayItem.count) { // Subtotal
                return 44
            } else { // Cart product
                let json = arrayItem[indexPath.row]
                if let error = json["_error"].string {
                    let options : NSStringDrawingOptions = [.UsesLineFragmentOrigin, .UsesFontLeading]
                    let h = (error as NSString).boundingRectWithSize(CGSizeMake(UIScreen.mainScreen().bounds.width - 114, 0), options: options, attributes: [NSFontAttributeName:UIFont.systemFontOfSize(14)], context: nil).height
                    return 77 + h
                }
                return 94
            }
        } else if (section == sectionDataUser) {
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
        } else if (section == sectionPayMethod) {
            if (row == 0) { // Payment method
                return 198
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
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let v = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 44))
        
        v.backgroundColor = UIColor.whiteColor()
        
        var lblFrame = CGRectZero
        lblFrame.origin.x = 0
        let l = UILabel(frame: lblFrame)
        l.font = UIFont.boldSystemFontOfSize(16)
        l.textColor = UIColor.darkGrayColor()
        
        if (section == sectionProducts) {
            l.text = "RINGKASAN BARANG"
        } else if (section == sectionDataUser) {
            l.text = "DATA KAMU"
        } else if (section == sectionAlamatUser) {
            l.text = "ALAMAT PENGIRIMAN"
        } else if (section == sectionPayMethod) {
            l.text = "METODE PEMBAYARAN"
        } else if (section == sectionPaySummary) {
            l.text = "RINGKASAN PEMBAYARAN"
        }
        
        l.sizeToFit()
        
        l.y = (v.height - l.height) / 2
        
        v.addSubview(l)
        
        return v
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.section == sectionAlamatUser) {
            if (indexPath.row == 3) { // Kecamatan
                if (selectedKotaID == "") {
                    Constant.showDialog("Perhatian", message: "Pilih kota/kabupaten terlebih dahulu")
                    return
                }
            } else if (indexPath.row == 2) { // Kota/Kab
                if (selectedProvinsiID == "") {
                    Constant.showDialog("Perhatian", message: "Pilih provinsi terlebih dahulu")
                    return
                }
            }
        }
        
        let c = tableView.cellForRowAtIndexPath(indexPath)
        if ((c?.canBecomeFirstResponder())!) {
            c?.becomeFirstResponder()
        }
    }
    
    // MARK: - ACEExpandableTextCell functionsahaa
    
    func tableView(tableView: UITableView!, updatedHeight height: CGFloat, atIndexPath indexPath: NSIndexPath!) {
        addressHeight = Int(height)
    }
    
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        if (indexPath != nil) {
            if let cell = cellsData[indexPath] {
                cell.value = text
            }
        }
    }
    
    // MARK: - UITextField functions
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            // This will be crash on iOS 7.1
            let i = tableView.indexPathForCell((textField.superview?.superview!) as! UITableViewCell)
            var s = (i?.section)!
            var r = (i?.row)!
            
            var cell : UITableViewCell?
            
            var con = true
            while (con) {
                let newIndex = NSIndexPath(forRow: r + 1, inSection: s)
                cell = tableView.cellForRowAtIndexPath(newIndex)
                if (cell == nil) {
                    s += 1
                    r = -1
                    if (s == tableView.numberOfSections) { // finish, last cell
                        con = false
                    }
                } else {
                    if ((cell?.canBecomeFirstResponder())!) {
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
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    // MARK: - Actions
    
    @IBAction override func confirm()
    {
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
        let p = AppToolsObjC.jsonStringFrom(c)
        
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
        let a = AppToolsObjC.jsonStringFrom(d)
        
        if (p == "[]" || p == "") {
            Constant.showDialog("Perhatian", message: "Tidak ada barang")
            return
        }
        
        self.btnSend.enabled = false
        
        var usedBalance = 0
        var usedBonus = 0
        if (isUsingPreloBalance || isUsingReferralBonus) {
            if (discountItems.count > 0) {
                for i in 0...discountItems.count - 1 {
                    if (discountItems[i].title.containsString("Referral Bonus")) {
                        usedBonus = discountItems[i].value
                    } else if (discountItems[i].title == "Prelo Balance") {
                        usedBalance = discountItems[i].value
                    }
                }
            }
        }
        
        if (self.selectedPayment == self.availablePayments[0] || self.priceAfterDiscounts <= 0) { // Bank Transfer or Rp0 Transaction
            self.performCheckout(p, address: a, usedBalance: usedBalance, usedBonus: usedBonus)
        } else if (self.selectedPayment == self.availablePayments[1]) { // Credit Cards
            request(APICart.GenerateVeritransUrl(cart: p, address: a, voucher: voucherApplied, payment: selectedPayment, usedPreloBalance: usedBalance, usedReferralBonus: usedBonus, kodeTransfer: bankTransferDigit)).responseJSON { resp in
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Generate Veritrans URL")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    if (data["success"].bool == true) {
                        let webVC = self.storyboard?.instantiateViewControllerWithIdentifier("preloweb") as! PreloWebViewController
                        webVC.url = data["veritrans_redirect_url"].stringValue
                        webVC.titleString = "Pembayaran Kartu Kredit"
                        webVC.creditCardMode = true
                        webVC.ccPaymentSucceed = {
                            self.ccPaymentOrderId = data["order_id"].stringValue
                            self.performCheckout(p, address: a, usedBalance: usedBalance, usedBonus: usedBonus)
                        }
                        webVC.ccPaymentUnfinished = {
                            Constant.showDialog("", message: "Pembayaran dibatalkan")
                            self.btnSend.enabled = true
                        }
                        webVC.ccPaymentFailed = {
                            Constant.showDialog("Pembayaran Gagal", message: "Mohon coba lagi dengan metode pembayaran yang lain")
                            self.btnSend.enabled = true
                        }
                        let baseNavC = BaseNavigationController()
                        baseNavC.setViewControllers([webVC], animated: false)
                        self.presentViewController(baseNavC, animated: true, completion: nil)
                    } else {
                        Constant.showDialog("Generate Veritrans URL", message: "Oops, terdapat kesalahan, silahkan coba beberapa saat lagi")
                        self.btnSend.enabled = true
                    }
                } else {
                    self.btnSend.enabled = true
                }
            }
        }
        
        
    }
    
    func performCheckout(cart : String, address : String, usedBalance : Int, usedBonus : Int) {
        request(APICart.Checkout(cart: cart, address: address, voucher: voucherApplied, payment: selectedPayment, usedPreloBalance: usedBalance, usedReferralBonus: usedBonus, kodeTransfer: bankTransferDigit, ccOrderId: ccPaymentOrderId)).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Checkout")) {
                let json = JSON(resp.result.value!)
                self.checkoutResult = json["_data"]
                
                if (json["_data"]["_have_error"].intValue == 1) {
                    let m = json["_data"]["_message"].stringValue
                    UIAlertView.SimpleShow("Perhatian", message: m)
                    self.btnSend.enabled = true
                    return
                }
                
                var gTotal = 0
                if let totalPrice = self.checkoutResult?["total_price"].int {
                    gTotal += totalPrice
                }
                if let trfCode = self.checkoutResult?["banktransfer_digit"].int {
                    gTotal += trfCode
                }
                
                // Prepare to navigate to order confirm page
                let o = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
                
                o.orderID = (self.checkoutResult?["order_id"].string)!
                if (self.selectedPayment == self.availablePayments[1]) { // Credit card
                    o.total = 0
                } else { // Bank transfer etc
                    o.total = gTotal
                }
                o.transactionId = (self.checkoutResult?["transaction_id"].string)!
                o.isBackTwice = true
                o.isShowBankBRI = self.isShowBankBRI
                
                var imgs : [NSURL] = []
                for i in 0...self.arrayItem.count - 1 {
                    let json = self.arrayItem[i]
                    if let raw : Array<AnyObject> = json["display_picts"].arrayObject {
                        var ori : Array<String> = []
                        for o in raw {
                            if let s = o as? String {
                                ori.append(s)
                            }
                        }
                        
                        if (ori.count > 0) {
                            if let u = NSURL(string: ori.first!) {
                                imgs.append(u)
                            }
                        }
                    }
                }
                o.images = imgs
                
                // Send tracking data before navigate
                if (self.checkoutResult != nil) {
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
                    ]
                    Mixpanel.trackEvent(MixpanelEvent.Checkout, properties: pt as [NSObject : AnyObject])
                    
                    // Answers
                    if (AppTools.IsPreloProduction) {
                        Answers.logStartCheckoutWithPrice(NSDecimalNumber(integer: totalPrice), currency: "IDR", itemCount: NSNumber(integer: items.count), customAttributes: nil)
                        for j in 0...items.count-1 {
                            Answers.logPurchaseWithPrice(NSDecimalNumber(integer: itemsPrice[j]), currency: "IDR", success: true, itemName: items[j], itemType: itemsCategory[j], itemId: itemsId[j], customAttributes: nil)
                        }
                    }
                    
                    // Google Analytics Ecommerce Tracking
                    if (AppTools.IsPreloProduction) {
                        let gaTracker = GAI.sharedInstance().defaultTracker
                        let trxDict = GAIDictionaryBuilder.createTransactionWithId(orderId, affiliation: "iOS Checkout", revenue: totalPrice, tax: totalCommissionPrice, shipping: self.totalOngkir, currencyCode: "IDR").build() as [NSObject : AnyObject]
                        gaTracker.send(trxDict)
                        for i in 0...self.arrayItem.count - 1 {
                            let json = self.arrayItem[i]
                            var cName = CDCategory.getCategoryNameWithID(json["category_id"].stringValue)
                            if (cName == nil) {
                                cName = json["category_id"].stringValue
                            }
                            let trxItemDict = GAIDictionaryBuilder.createItemWithTransactionId(orderId, name: json["name"].stringValue, sku: json["product_id"].stringValue, category: cName, price: json["price"].intValue, quantity: 1, currencyCode: "IDR").build() as [NSObject : AnyObject]
                            gaTracker.send(trxItemDict)
                        }
                    }
                    
                    // MoEngage
                    let moeDict = NSMutableDictionary()
                    moeDict.setObject(orderId, forKey: "Order ID")
                    moeDict.setObject(items, forKey: "Items")
                    moeDict.setObject(itemsCategory, forKey: "Items Category")
                    moeDict.setObject(itemsSeller, forKey: "Items Seller")
                    moeDict.setObject(itemsPrice, forKey: "Items Price")
                    moeDict.setObject(itemsCommissionPercentage, forKey: "Items Commission Percentage")
                    moeDict.setObject(itemsCommissionPrice, forKey: "Items Commission Price")
                    moeDict.setObject(totalCommissionPrice, forKey: "Total Commission Price")
                    moeDict.setObject(self.totalOngkir, forKey: "Shipping Price")
                    moeDict.setObject(totalPrice, forKey: "Total Price")
                    moeDict.setObject(rName!, forKey: "Shipping Region")
                    moeDict.setObject(pName!, forKey: "Shipping Province")
                    let moeEventTracker = MOPayloadBuilder.init(dictionary: moeDict)
                    moeEventTracker.setTimeStamp(NSDate.timeIntervalSinceReferenceDate(), forKey: "startTime")
                    moeEventTracker.setDate(NSDate(), forKey: "startDate")
                    let locManager = CLLocationManager()
                    locManager.requestWhenInUseAuthorization()
                    var currentLocation : CLLocation!
                    var currentLat : Double = 0
                    var currentLng : Double = 0
                    if (CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == .AuthorizedAlways) {
                        currentLocation = locManager.location
                        currentLat = currentLocation.coordinate.latitude
                        currentLng = currentLocation.coordinate.longitude
                    }
                    moeEventTracker.setLocationLat(currentLat, lng: currentLng, forKey: "startingLocation")
                    MoEngage.sharedInstance().trackEvent(MixpanelEvent.Checkout, builderPayload: moeEventTracker)
                }
                o.isFromCheckout = true
                self.navigateToVC(o)
            }
            self.btnSend.enabled = true
        }
    }
    
    func setPaymentOption(tag : Int) {
        selectedPayment = availablePayments[tag]
    }
    
    func itemNeedDelete(indexPath: NSIndexPath) {
        let j = arrayItem[indexPath.row]
        print(j)
        arrayItem.removeAtIndex(indexPath.row)
        
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let x = AppToolsObjC.jsonStringFrom(c)
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
            cartProducts.removeAtIndex(index)
            print(p.cpID)
            UIApplication.appDelegate.managedObjectContext.deleteObject(p)
            UIApplication.appDelegate.saveContext()
        }
        
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        if (arrayItem.count == 0) {
            self.shouldBack = true
        }
        cellsData = [:]
        synchCart()
    }
    
    func itemNeedUpdateShipping(indexPath: NSIndexPath) {
        let j = arrayItem[indexPath.row]
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
                    ActionSheetStringPicker.showPickerWithTitle("Select Shipping", rows: names, initialSelection: 0, doneBlock: { picker, index, value in
                            let sjson = arr?[index]
                            if let pid = sjson?["_id"].string {
                                cp.packageId = pid
                                UIApplication.appDelegate.saveContext()
                                self.adjustTotal()
                            }
                        }, cancelBlock: { picker in
                            
                        }, origin: tableView.cellForRowAtIndexPath(indexPath))
                }
            }
        }
    }
    
    @IBAction func paymentReminderPressed(sender: AnyObject) {
        let notifPageVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil).first as! NotifAnggiTabBarViewController
        self.navigateToVC(notifPageVC)
    }
    
    func printCellsData() {
        print("CELLSDATA")
        if (cellsData.count > 0) {
            for i in 0...cellsData.count - 1 {
                let index = cellsData.startIndex.advancedBy(i)
                let idxPath = cellsData.keys[index]
                let baseCartData = cellsData[idxPath]
                var title = "", value = ""
                if let t = baseCartData?.title {
                    title = t
                }
                if let v = baseCartData?.value {
                    value = v
                }
                print("\(idxPath.section) - \(idxPath.row) : title = \(title), value = \(value)")
            }
        }
    }
    
    // MARK: - Prelo balance cell delegate
    
    func preloBalanceInputCellNeedrefresh(isON: Bool) {
        if (!isON)
        {
            if (discountItems.count > 0) {
                if (discountItems[0].title == "Prelo Balance") {
                    discountItems.removeAtIndex(0)
                    tableView.deleteRowsAtIndexPaths([NSIndexPath(forItem: 2, inSection: sectionPaySummary)], withRowAnimation: .Fade)
                }
            }
        } else {
            if (discountItems.count <= 0 || (discountItems.count > 0 && discountItems[0].title != "Prelo Balance")) {
                let discItem = DiscountItem(title: "Prelo Balance", value: (balanceAvailable <= priceAfterDiscounts ? balanceAvailable : priceAfterDiscounts))
                discountItems.insert(discItem, atIndex: 0)
                tableView.insertRowsAtIndexPaths([NSIndexPath(forItem: 2, inSection: sectionPaySummary)], withRowAnimation: .Fade)
            }
        }
        isUsingPreloBalance = isON
        
        adjustRingkasan()
    }
    
    func preloBalanceInputCellBalanceSubmitted(balance: Int) {
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
    
    func voucherInputCellNeedrefresh(isON: Bool) {
        isShowVoucher = isON
        self.setupTable()
    }
    
    func voucherInputCellSubmitted(voucher: String) {
        self.voucherApplied = voucher
        self.synchCart()
    }
    
    func voucherInputCellTyped(voucher: String) {
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
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    // MARK: - Navigation
    
    func performSegTour() {
        self.performSegueWithIdentifier("segTour", sender: nil)
    }
    
    func navigateToVC(vc: UIViewController) {
        if (previousController != nil) {
            self.previousController!.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "segOK") {
            let c = segue.destinationViewController as! CarConfirmViewController
            c.orderID = (checkoutResult?["order_id"].string)!
            c.totalPayment = (checkoutResult?["final_price"].int)!
            c.paymentMethod = (checkoutResult?["payment_method"].string)!
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
    var keyboardType = UIKeyboardType.Default
    
    var pickerPrepDataBlock : PrepDataBlock?
    
    static func instance(title : String?, placeHolder : String?) -> BaseCartData {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = true
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, enable : Bool) -> BaseCartData {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = enable
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, value : String) -> BaseCartData {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = true
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, value : String, pickerPrepBlock : PrepDataBlock?) -> BaseCartData {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = true
        
        b.pickerPrepDataBlock = pickerPrepBlock
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, value : String?, enable : Bool) -> BaseCartData {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = enable
        
        return b
    }
    
    static func instanceWith(image : UIImage, placeHolder : String) -> BaseCartData {
        let b = BaseCartData()
        b.title = ""
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = true
        b.image = image
        
        return b
    }
    
    static func instanceWith(image : UIImage, placeHolder : String, pickerPrepBlock : PrepDataBlock?) -> BaseCartData {
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
    var lastIndex : NSIndexPath?
    
    var idxPath : NSIndexPath?
    
    @IBOutlet var bottomLine : UIView?
    @IBOutlet var topLine : UIView?
    
    func obtainValue() -> BaseCartData? {
        return nil
    }
    
    func adapt(item : BaseCartData?) {
        
    }
}

// MARK: - Class - Input berupa title dan textfield

class CartCellInput : BaseCartCell, UITextFieldDelegate {
    @IBOutlet var txtField : UITextField!
    @IBOutlet var consWidthTxtField: NSLayoutConstraint!
    
    var textChangedBlock : (NSIndexPath, String) -> () = { _, _ in }
    
    override func canBecomeFirstResponder() -> Bool {
        return txtField.canBecomeFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        return txtField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return txtField.resignFirstResponder()
    }
    
    override func adapt(item : BaseCartData?) {
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
        if (item.title?.lowercaseString == "nama") {
            consWidthTxtField.constant = 200
        } else {
            consWidthTxtField.constant = 115
        }
        
        let value = item.value
        if (value != nil) {
            if (value! == "10%") {
                txtField.font = UIFont.boldSystemFontOfSize(14)
                let l = self.contentView.viewWithTag(666)
                l?.hidden = true
            }
            txtField.text = value
        } else {
            txtField.text = ""
        }
        
        txtField.keyboardType = item.keyboardType
        txtField.enabled = item.enable
        txtField.delegate = self
    }
    
    override func obtainValue() -> BaseCartData? {
        baseCartData?.value = txtField.text
        return baseCartData
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
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
    
    override func canBecomeFirstResponder() -> Bool {
        return parent != nil
    }
    
    override func becomeFirstResponder() -> Bool {
        let p = parent?.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdPicker) as? PickerViewController
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
    
    func pickerDidSelect(item: String) {
        captionValue?.text = PickerViewController.HideHiddenString(item)
    }
    
    override func adapt(item : BaseCartData?) {
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
    override func canBecomeFirstResponder() -> Bool {
        return false
    }
}

// MARK: - Protocol

protocol CartItemCellDelegate
{
    func itemNeedDelete(indexPath : NSIndexPath)
    func itemNeedUpdateShipping(indexPath : NSIndexPath)
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
    
    override func canBecomeFirstResponder() -> Bool {
        return false
    }
    
    var selectedPaymentId : String = ""
    var cartItemCellDelegate : CartItemCellDelegate?
    
    func adapt (json : JSON)
    {
        print(json)
        captionName?.text = json["name"].stringValue
        captionLocation?.text = ""
        captionFrom?.text = ""
        
        if let raw : Array<AnyObject> = json["display_picts"].arrayObject
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
                ivCover?.image = nil
                let u = NSURL(string: ori.first!)
                ivCover?.setImageWithUrl(u!, placeHolderImage: nil)
            }
        }
        
        if let error = json["_error"].string
        {
            let string = error
            let attString = NSMutableAttributedString(string: string)
            attString.addAttributes([NSForegroundColorAttributeName:UIColor.redColor(), NSFontAttributeName:UIFont.systemFontOfSize(14)], range: AppToolsObjC.rangeOf(string, inside: string))
            captionPrice?.attributedText = attString
            captionPrice?.numberOfLines = 0
            shade?.hidden = false
            
            self.btnShippment?.hidden = true
            
            let sellerLocationID = json["seller_region"].stringValue
            if let regionName = CDRegion.getRegionNameWithID(sellerLocationID)
            {
                self.captionFrom?.text = "Dikirim dari " + regionName
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
                self.btnShippment?.setTitle(name, forState: UIControlState.Normal)
                self.btnShippment?.hidden = false
            } else
            {
                self.btnShippment?.hidden = true
            }
            
            let ongkirString = ongkir == 0 ? "(FREE ONGKIR)" : " (+ONGKIR " + ongkir!.asPrice + ")"
            let priceString = json["price"].int!.asPrice + ongkirString
            let string = priceString + "" + ""
            let attString = NSMutableAttributedString(string: string)
            attString.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColorDark, NSFontAttributeName:UIFont.boldSystemFontOfSize(14)], range: AppToolsObjC.rangeOf(priceString, inside: string))
            attString.addAttributes([NSForegroundColorAttributeName:Theme.GrayDark, NSFontAttributeName:UIFont.systemFontOfSize(10)], range: AppToolsObjC.rangeOf(ongkirString, inside: string))
            captionPrice?.attributedText = attString
            shade?.hidden = true
            
            let sellerLocationID = json["seller_region"].stringValue
            if let regionName = CDRegion.getRegionNameWithID(sellerLocationID)
            {
                self.captionFrom?.text = "Dikirim dari " + regionName
            } else
            {
                self.captionFrom?.text = ""
            }
        }
        
    }
    
    var indexPath : NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    
    @IBAction func deleteMe()
    {
        if let d = cartItemCellDelegate
        {
            _ = indexPath.row
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
    var lastIndex : NSIndexPath?
    
    func adapt(item : BaseCartData)
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
    func preloBalanceInputCellNeedrefresh(isON : Bool)
    func preloBalanceInputCellBalanceSubmitted(balance : Int)
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
        self.selectionStyle = .None
        
        self.txtInput?.superview?.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.txtInput?.superview?.layer.borderWidth = 1
        self.txtInput?.superview?.layer.cornerRadius = 2
        
        if (first)
        {
            let toolbar = UIToolbar(frame: CGRectMake(0, 0, /*UIScreen.mainScreen().bounds.width*/200, 44))
            toolbar.translucent = true
            toolbar.tintColor = Theme.PrimaryColor
            
            let doneBtn = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(PreloBalanceInputCell.processPreloInput))
            
            let space = UIBarButtonItem(barButtonSpaceType: .FlexibleSpace)
            
            toolbar.items = [space, doneBtn]
            self.txtInput?.inputAccessoryView = toolbar
            first = false
        }
    }
    
    @IBAction func switched()
    {
        delegate?.preloBalanceInputCellNeedrefresh(switchBalance.on)
    }
    
    func processPreloInput()
    {
        if let s = txtInput?.text
        {
            if let _ = s.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "0987654321").invertedSet)
            {
                UIAlertView.SimpleShow("Perhatian", message: "Jumlah prelo balance yang digunakan tidak valid")
            } else
            {
                let i = s.int
                self.delegate?.preloBalanceInputCellBalanceSubmitted(i)
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.processPreloInput()
        
        textField.resignFirstResponder()
        return false
    }
}

// MARK: - Protocol

protocol VoucherInputCellDelegate {
    func voucherInputCellNeedrefresh(isON : Bool)
    func voucherInputCellSubmitted(voucher : String)
    func voucherInputCellTyped(voucher : String)
}

// MARK: - Class - Input voucher

class VoucherInputCell : UITableViewCell, UITextFieldDelegate {
    @IBOutlet var txtInput : UITextField?
    @IBOutlet var switchVoucher : UISwitch!
    
    var delegate : VoucherInputCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .None
        self.txtInput?.delegate = self
    }
    
    @IBAction func switched() {
        delegate?.voucherInputCellNeedrefresh(switchVoucher.on)
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        delegate?.voucherInputCellTyped(textField.text!)
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        delegate?.voucherInputCellTyped(textField.text!)
    }
}

// MARK: - Class - Total belanja

class CartGrandTotalCell : BaseCartCell
{
    @IBOutlet var captionValue : UILabel!
    
    override func adapt(item : BaseCartData?) {
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
    @IBOutlet var vw3Banks: UIView!
    @IBOutlet var vw4Banks: UIView!
    var isEnableCCPayment : Bool = false
    
    // Tag set in storyboard
    // 0 = Transfer Bank
    // 1 = Kartu Kredit
    @IBOutlet var btnsMethod: [UIButton]!
    
    var methodChosen : (Int) -> () = { _ in }
    
    @IBAction func methodPressed(sender: UIButton) {
        if (sender.tag == 1 && !isEnableCCPayment) { // Disabled method
            UIAlertView.SimpleShow("Coming Soon", message: "Metode pembayaran ini belum tersedia")
            return
        }
        for i in 0...btnsMethod.count - 1 {
            if (sender.isEqual(btnsMethod[i])) { // Clicked button
                if let b = btnsMethod[i].superview as? BorderedView {
                    b.cartSelectAsPayment(true)
                }
                self.methodChosen(sender.tag)
            } else { // Other button
                if let b = btnsMethod[i].superview as? BorderedView {
                    b.cartSelectAsPayment(false)
                }
            }
        }
    }
}

// MARK: - Class

@IBDesignable
class PreloBalanceTextfield: UITextField {
    
    @IBInspectable var inset: CGFloat = 0
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, inset, inset)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return textRectForBounds(bounds)
    }
    
}

// MARK: - Extension

extension BorderedView
{
    func cartSelectAsPayment(select : Bool)
    {
        setColor(select ? Theme.PrimaryColorDark : Theme.GrayLight)
    }
    
    private func setColor(c : UIColor)
    {
        for v in self.subviews
        {
            if (v.isKindOfClass(UILabel.classForCoder()))
            {
                let l = v as! UILabel
                l.textColor = c
            } else if (v.isKindOfClass(TintedImageView.classForCoder()))
            {
                let i = v as! TintedImageView
                i.tintColor = c
            }
        }
    }
}
