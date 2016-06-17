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

class CartViewController: BaseViewController, ACEExpandableTableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITextFieldDelegate, CartItemCellDelegate, UserRelatedDelegate, PreloBalanceInputCellDelegate {

    // MARK: - Properties
    
    // Data container
    var currentCart : JSON? // Balikan API refresh cart
    var checkoutResult : JSON? // Balikan API checkout
    var products : [CartProduct] = []
    var arrayItem : [JSON] = []
    var selectedProvinsiID = ""
    var selectedKotaID = ""
    var user = CDUser.getOne()
    var banktransfer_digit = 0 // Angka yg diambil dari API
    var bankTransferDigit = 0 // Angka fix kalau2 digit diset menjadi 0 karna gratis dari diskon
    var bonusAvailable = false
    var bonusValue : Int = 0
    var usingPreloBalance = false
    var balanceAvailable = 0
    var totalPreloBalanceDiscount = 0
    struct DiscountItem {
        var title = ""
        var value = 0
    }
    var discountItems : [DiscountItem] = [] // Untuk balance, bonus, voucher
    var subtotalPrice = 0 // Jumlah harga semua produk + ongkir
    var totalOngkir = 0
    var shouldBack = false
    
    /* to be deleted */
    struct PreloBalanceItem {
        var title = ""
        var value = 0
    }
    var preloBalanceItems : [PreloBalanceItem] = [] // Untuk balance, bonus
    
    // Cells
    var cellsData : [NSIndexPath : BaseCartData] = [:]
    var cellViews : [NSIndexPath : UITableViewCell] = [:]
    
    // Table, loading, label, send btn
    @IBOutlet var tableView : UITableView!
    @IBOutlet var captionNoItem: UILabel!
    @IBOutlet var loadingCart: UIActivityIndicatorView!
    @IBOutlet var btnSend : UIButton!
    
    // Metode pembayaran
    @IBOutlet var sectionsPaymentOption : Array<BorderedView> = []
    @IBOutlet var consOffsetPaymentDesc : NSLayoutConstraint?
    @IBOutlet var sectionPaymentDesc: UIView!
    var selectedPayment = "Bank Transfer"
    var availablePayments = ["Bank Transfer", "Credit Card", "Prelo Balance"]
    
    // Ringkasan transaksi
    @IBOutlet var captionRingkasanTotalBelanja: UILabel!
    @IBOutlet var captionRingkasanKodeTransfer: UILabel!
    @IBOutlet var captionRingkasanGrandTotal: UILabel!
    
    // Sections
    let sectionProducts = 0
    let sectionDataUser = 1
    let sectionAlamatUser = 2
    let sectionPayMethod = 3
    let sectionPaySummary = 4
    let sectionPreloBalance = 5
    
    // Placeholders
    let titleNama = "Nama"
    let titleTelepon = "Telepon"
    let titleAlamat = "Mis: Jl. Tamansari III no. 1"
    let titleProvinsi = "Provinsi"
    let titleKota = "Kab / Kota"
    let titlePostal = "Kode Pos"
    
    // Address
    var address = ""
    var addressHeight = 44
    
    // Payment reminder
    @IBOutlet weak var lblPaymentReminder: UILabel!
    @IBOutlet weak var consHeightPaymentReminder: NSLayoutConstraint!
    
    // Voucher
    /* @IBOutlet var txtVoucher : UITextField! to be deleted */
    var voucher : String = ""
    
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
        if (checkTour == false)
        {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "cartTour")
            NSUserDefaults.standardUserDefaults().synchronize()
            _ = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(CartViewController.performSegTour), userInfo: nil, repeats: false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = PageName.Checkout
        
        // Get unpaid transaction
        // API Migrasi
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
        products = CartProduct.getAll(User.EmailOrEmptyString)
        
        // Init table
        if (products.count == 0) {
            tableView.hidden = true
            loadingCart.hidden = true
            captionNoItem.hidden = false
        } else {
            //self.navigationItem.rightBarButtonItem = self.confirmButton.toBarButton()
            let c = CDUser.getOne()
            
            if (c == nil) {
                tableView.hidden = true
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            } else {
                
                synch()
            }
        }
    }
    
    // Membuat cell untuk section data user dan alamat user
    func createCells()
    {
        // Prepare textfield value
        var fullname = ""
        var phone = ""
        var address = ""
        var postalcode = ""
        var pID = ""
        var rID = ""
        
        if let x = user?.fullname
        {
            fullname = x
        }
        
        if let profile = user?.profiles
        {
            if let x = profile.phone
            {
                phone = x
            }
            
            if let x = profile.address
            {
                address = x
            }
            
            if let x = profile.postalCode
            {
                postalcode = x
            }
        }
        
        if let u = CDUser.getOne()
        {
            pID = u.profiles.provinceID
            rID = u.profiles.regionID
            
            if let i = CDProvince.getProvinceNameWithID(pID)
            {
                selectedProvinsiID = pID
                pID = i
            } else
            {
                pID = ""
            }
            
            if let i = CDRegion.getRegionNameWithID(rID)
            {
                selectedKotaID = rID
                rID = i
            } else
            {
                rID = ""
            }
        }
        
        // Create cells
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
                
                // on select block
                picker.selectBlock = { string in
                    self.selectedProvinsiID = PickerViewController.RevealHiddenString(string)
                    let user = CDUser.getOne()!
                    user.profiles.provinceID = self.selectedProvinsiID
                }
            }),
            NSIndexPath(forRow: 2, inSection: sectionAlamatUser):BaseCartData.instance(titleKota, placeHolder: nil, value: rID, pickerPrepBlock: { picker in
                
                picker.items = CDRegion.getRegionPickerItems(self.selectedProvinsiID)
                picker.textTitle = "Pilih Kota/Kabupaten"
                picker.doneLoading()
                
                picker.selectBlock = { string in
                    self.selectedKotaID = PickerViewController.RevealHiddenString(string)
                    let user = CDUser.getOne()!
                    user.profiles.regionID = self.selectedKotaID
                }
                
            }),
            NSIndexPath(forRow: 3, inSection: sectionAlamatUser):c
        ]
    }
    
    func synch()
    {
        // Hide table
        tableView.hidden = true
        
        // Reset data
        usingPreloBalance = false
        cellViews = [:]
        discountItems = []
        createCells()
        
        // Prepare parameter for API refresh cart
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let p = AppToolsObjC.jsonStringFrom(c)
        
        print(p)
        
        var pID = ""
        var rID = ""
        if let u = CDUser.getOne()
        {
            pID = u.profiles.provinceID
            rID = u.profiles.regionID
        }
        
        let a = "{\"address\": \"alamat\", \"province_id\": \"" + pID + "\", \"region_id\": \"" + rID + "\", \"postal_code\": \"\"}"
        
        // API Migrasi
        request(APICart.Refresh(cart: p, address: a, voucher: voucher)).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Keranjang Belanja")) {
                let json = JSON(resp.result.value!)
                print(json)
                self.currentCart = json
                
                self.balanceAvailable = json["_data"]["balance_available"].intValue
                self.banktransfer_digit = json["_data"]["banktransfer_digit"].intValue
                
                self.arrayItem = json["_data"]["cart_details"].array!
                print(self.arrayItem)
                
                if let voucherValid = json["_data"]["voucher_valid"].bool {
                    if (voucherValid == true) {
                        if let voucherAmount = json["_data"]["voucher_amount"].int {
                            self.voucher = json["_data"]["voucher_serial"].stringValue
                            let discVoucher = DiscountItem(title: "Voucher '" + self.voucher + "'", value: voucherAmount)
                            self.discountItems.append(discVoucher)
                        }
                    } else {
                        if let voucherError = json["_data"]["voucher_error"].string {
                            Constant.showDialog("Invalid Voucher", message: voucherError)
                        }
                    }
                }
                
                let bonus = json["_data"]["bonus_available"].intValue
                //bonus = 11 // debug
                if (bonus > 0)
                {
                    self.bonusValue = bonus
                    self.bonusAvailable = true
                    
                    let disc = DiscountItem(title: "Referral Bonus", value: bonus)
                    self.discountItems.append(disc)
                    
                    /* to be deleted */
                    let item = PreloBalanceItem(title: "Referral Bonus", value: bonus)
                    self.preloBalanceItems.append(item)
                }
                
                if (bonus < 1000000) // gak di pake
                {
                    /*let b2 = BaseCartData.instance("Referral Bonus", placeHolder: nil, enable : false)
                    // what for ?
                    if (json["_data"]["bonus_available"].int?.asPrice != nil)
                    {

                    }

                    var totalOngkir = 0
                    if (self.products.count > 0) {
                        for i in 0...self.products.count-1
                        {
                            let cp = self.products[i]
                            print("Cart product : \(cp.toDictionary)")

                            let json = self.arrayItem[i]
                            if let free = json["free_ongkir"].bool
                            {
                                if (free)
                                {
                                    continue
                                }
                            }

                            if let arr = json["shipping_packages"].array
                            {
                                if (arr.count > 0)
                                {
                                    var sh = arr[0]
                                    if (cp.packageId != "")
                                    {
                                        for x in 0...arr.count-1
                                        {
                                            let shipping = arr[x]
                                            if let id = shipping["_id"].string
                                            {
                                                if (id == cp.packageId)
                                                {
                                                    sh = shipping
                                                }
                                            }
                                        }
                                    }
                                    if let price = sh["price"].int
                                    {
                                        totalOngkir += price
                                    }
                                }
                            }
                        }
                    }

                    let preloBonus = json["_data"]["bonus_available"].intValue
                    let preloBonus = bonus
                    let totalPrice = json["_data"]["total_price"].intValue

                    b2.value = (preloBonus < totalPrice+totalOngkir) ? ("-" + preloBonus.asPrice) : ("-" + (totalPrice + totalOngkir).asPrice)

                    b2.enable = false
                    let i2 = NSIndexPath(forRow: self.products.count, inSection: self.sectionProducts)
                    self.cellsData[i2] = b2*/
                    
                } else {
                    if let modalText = json["_data"]["modal_verify_text"].string {
                        Constant.showDialog("Perhatian", message: modalText)
                    }
                }
                
                // Create 'Subtotal' cell
                /* to be deleted
                 let i = NSIndexPath(forRow: self.products.count + (self.bonusAvailable == true ? 1 : 0), inSection: self.sectionProducts)*/
                let i = NSIndexPath(forRow: self.products.count, inSection: self.sectionProducts)
                let b = BaseCartData.instance("Subtotal", placeHolder: nil, enable : false)
                if let price = json["_data"]["total_price"].int?.asPrice
                {
                    b.value = price
                }
                self.cellsData[i] = b
                
                // Setup table
                self.tableView.dataSource = self
                self.tableView.delegate = self
                //self.tableView.reloadData()
                self.tableView.hidden = false
                if (self.shouldBack == true)
                {
                    self.navigationController?.popViewControllerAnimated(true)
                } else if (self.products.count > 0)
                {
                    self.adjustTotal()
                }
            }
        }
    }
    
    func adjustTotal()
    {
        // Sum up shipping price
        totalOngkir = 0
        for i in 0...products.count-1
        {
            let cp = products[i]
            
            let json = arrayItem[i]
            if let free = json["free_ongkir"].bool
            {
                if (free)
                {
                    continue
                }
            }
            
            if let arr = json["shipping_packages"].array
            {
                if (arr.count > 0)
                {
                    var sh = arr[0]
                    if (cp.packageId != "")
                    {
                        for x in 0...arr.count-1
                        {
                            let shipping = arr[x]
                            if let id = shipping["_id"].string
                            {
                                if (id == cp.packageId)
                                {
                                    sh = shipping
                                }
                            }
                        }
                    }
                    if let price = sh["price"].int
                    {
                        totalOngkir += price
                    }
                }
            }
        }
        
        // Update 'Subtotal' cell
        /* to be deleted
        let b = cellsData[NSIndexPath(forRow: products.count + (self.bonusAvailable == true ? 1 : 0), inSection: sectionProducts)]*/
        let b = cellsData[NSIndexPath(forRow: products.count, inSection: sectionProducts)]
        if let total = self.currentCart?["_data"]["total_price"].int, let d = b
        {
//            var p = totalOngkir + total - self.bonusValue
            var p = totalOngkir + total
            if (p < 0)
            {
                p = 0
            }
            
            self.subtotalPrice = p
            d.value = p.asPrice
            
            if let c = cellViews[NSIndexPath(forRow: products.count, inSection: sectionProducts)] as? CartCellInput
            {
                c.txtField.text = d.value
            }
            
            // Second 'Subtotal' cell in sectionPaySummary
            let i = NSIndexPath(forRow: 0, inSection: self.sectionPaySummary)
            let b = BaseCartData.instance("Subtotal", placeHolder: nil, value: p.asPrice, enable: false)
            self.cellsData[i] = b
        }
        
        // Update bonus discount if its more than subtotal
        if (discountItems.count > 0) {
            for i in 0...discountItems.count - 1 {
                if (discountItems[i].title == "Referral Bonus") {
                    if (discountItems[i].value > self.subtotalPrice) {
                        discountItems[i].value = self.subtotalPrice
                    }
                }
            }
        }
        
        adjustRingkasan()
    }
    
    func adjustRingkasan()
    {
        // Set cellsData for discounts, start from row 2 in sectionPaySummary
        if (discountItems.count > 0) {
            for i in 0...discountItems.count - 1 {
                let idxDisc = NSIndexPath(forRow: 2 + i, inSection: self.sectionPaySummary)
                let bDisc = BaseCartData.instance(discountItems[i].title, placeHolder: nil, value: discountItems[i].value.asPrice, enable: false)
                self.cellsData[idxDisc] = bDisc
            }
        }
        
        var p = subtotalPrice
        for i in self.discountItems {
            p -= i.value
        }
        if (p < 0) {
            p = 0
        }
        
        // Set cellsData for total (subTotal minus discounts)
        let idxTotal = NSIndexPath(forRow: 2 + discountItems.count, inSection: self.sectionPaySummary)
        let bTotal = BaseCartData.instance("Total", placeHolder: nil, value: p.asPrice, enable: false)
        self.cellsData[idxTotal] = bTotal
        
        // Set cellsData for transfer code
        let idxKode = NSIndexPath(forRow: 3 + discountItems.count, inSection: self.sectionPaySummary)
        bankTransferDigit = banktransfer_digit
        if (p == 0) {
            bankTransferDigit = 0
        }
        let bKode = BaseCartData.instance("Kode Unik Transfer", placeHolder: nil, value: bankTransferDigit.asPrice, enable: false)
        self.cellsData[idxKode] = bKode
        
        // Set cellsData for grand total
        let idxGTotal = NSIndexPath(forRow: 4 + discountItems.count, inSection: self.sectionPaySummary)
        let bGTotal = BaseCartData.instance("Total Pembayaran", placeHolder: nil, value: (p + bankTransferDigit).asPrice, enable: false)
        self.cellsData[idxGTotal] = bGTotal
        
        self.printCellsData()
        self.tableView.reloadData()
        
        /* to be deleted
        for i in self.preloBalanceItems
        {
            p = p - i.value
        }
        captionRingkasanTotalBelanja.text = p.asPrice
        captionRingkasanKodeTransfer.text = banktransfer_digit.asPrice
        captionRingkasanGrandTotal.text = (p + banktransfer_digit).asPrice*/
    }
    
    // MARK: - Cell creations
    
    func createOrGetBaseCartCell(tableView : UITableView, indexPath : NSIndexPath, id : String, isShowBottomLine : Bool) -> BaseCartCell
    {
        let b : BaseCartCell = tableView.dequeueReusableCellWithIdentifier(id) as! BaseCartCell
        
        /* to be deleted, ane ga paham
        if (b.lastIndex != nil) {
            cellsData[b.lastIndex!] = b.obtainValue() // just set to nil?
        }*/
        
        b.parent = self
        b.adapt(cellsData[indexPath]) // do nothing?
        b.lastIndex = indexPath
        if (isShowBottomLine) {
            b.bottomLine?.hidden = false
        } else {
            b.bottomLine?.hidden = true
        }
        
        return b
    }
    
    func createExpandableCell(tableView : UITableView, indexPath : NSIndexPath) -> ACEExpandableTextCell?
    {
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
        cell.methodChosen = { tag in
            self.setPaymentOption(tag)
        }
        
        return cell
    }
    
    func createVoucherCell(tableView : UITableView, indexPath : NSIndexPath) -> CartVoucherCell {
        let cell : CartVoucherCell = tableView.dequeueReusableCellWithIdentifier("cell_voucher") as! CartVoucherCell
        cell.applyVoucher = { voucher in
            self.voucher = voucher
            self.saveVoucher()
        }
        
        return cell
    }
    
    // MARK: - UITableView functions
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == sectionProducts) {
            return arrayItem.count + 1
        } else if (section == sectionDataUser) {
            return 2
        } else if (section == sectionAlamatUser) {
            return 4
        } else if (section == sectionPayMethod) {
            return 1
        } else if (section == sectionPaySummary) {
            return 6 + discountItems.count
        } else if (section == sectionPreloBalance) {
            return 1 + preloBalanceItems.count + 1
        }
        return 0
        
        /* to be deleted
        if (section == sectionAlamatUser) {
            return 4
        } else if (section == sectionProducts) {
            return arrayItem.count+1+((self.bonusAvailable) ? 1 : 0)
        } else if (section == sectionPreloBalance) { // section prelo balance
            return 1 + preloBalanceItems.count + 1
        } else if (section == sectionDataUser) {
            return 2
        } else {
            return 3
        }*/
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        var cell : UITableViewCell = UITableViewCell()
        
        /* to be deleted
        let cachedCell = cellViews[indexPath]
        if (cachedCell != nil) {
            return cachedCell!
        }*/
        
        if (section == sectionProducts) {
            if (row == arrayItem.count) { // Subtotal
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
            } else { // Cart product
                let i = tableView.dequeueReusableCellWithIdentifier("cell_item2") as! CartCellItem
                let cp = products[indexPath.row]
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
                return createExpandableCell(tableView, indexPath: indexPath)!
            } else if (row == 1 || row == 2) { // Provinsi, Kab/Kota
                 cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input_2", isShowBottomLine: true)
            } else if (row == 3) { // Kode Pos
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
            }
        } else if (section == sectionPayMethod) {
            if (row == 0) {
                cell = createPayMethodCell(tableView, indexPath: indexPath)
            }
        } else if (section == sectionPaySummary) {
            if (row == 0) { // Subtotal
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
            } else if (row == 1) { // Prelo balance switch
                let cellId = usingPreloBalance ? "pbcellInput2" : "pbcellInput1"
                let c = tableView.dequeueReusableCellWithIdentifier(cellId) as! PreloBalanceInputCell
                c.captionTotalBalance.text = "Prelo Balance kamu \(balanceAvailable.asPrice)"
                c.delegate = self
                
                c.txtInput?.text = nil
                c.switchBalance.setOn(usingPreloBalance, animated: false)
                
                return c
            } else {
                var afterDiscountRowIdx = 2
                if (discountItems.count > 0) {
                    afterDiscountRowIdx += discountItems.count
                    if (row - 2 < discountItems.count) { // Discount
                        let discItem = discountItems[row - 2]
                        let discItemCell = tableView.dequeueReusableCellWithIdentifier("pbcellItem") as! PreloBalanceItemCell
                        discItemCell.captionTitle.text = discItem.title
                        discItemCell.captionValue.text = "-\(discItem.value.asPrice)"
                        return discItemCell
                    }
                }
                if (row == afterDiscountRowIdx) { // Total
                    cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
                } else if (row == afterDiscountRowIdx + 1) { // Transfer code
                    cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input", isShowBottomLine: false)
                } else if (row == afterDiscountRowIdx + 2) { // Grand total
                    cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "pbcellTotal", isShowBottomLine: false)
                } else if (row == afterDiscountRowIdx + 3) { // Voucher
                    cell = createVoucherCell(tableView, indexPath: indexPath)
                }
                
            }
        } else if (section == sectionPreloBalance) {
            if (row == 0)
            {
                let identifier = usingPreloBalance ? "pbcellInput2" : "pbcellInput1"
                let c = tableView.dequeueReusableCellWithIdentifier(identifier) as! PreloBalanceInputCell
                c.captionTotalBalance.text = "Prelo Balance kamu \(balanceAvailable.asPrice)"
                c.delegate = self
                
                c.txtInput?.text = nil
                c.switchBalance.setOn(usingPreloBalance, animated: false)
                
                return c
            }
            
            if (row - preloBalanceItems.count == 1)
            {
                let totalCell = tableView.dequeueReusableCellWithIdentifier("pbcellTotal") as! PreloBalanceTotalCell
                //                let p = (subtotalPrice - totalPreloBalanceDiscount)
                var p = subtotalPrice
                for i in self.preloBalanceItems
                {
                    p = p - i.value
                }
                totalCell.captionValue.text = (p < 0 ? 0 : p).asPrice
                return totalCell
            }
            
            let item = preloBalanceItems[row-1]
            let itemCell = tableView.dequeueReusableCellWithIdentifier("pbcellItem") as! PreloBalanceItemCell
            itemCell.captionTitle.text = item.title
            itemCell.captionValue.text = "-\(item.value.asPrice)"
            return itemCell
        }
        
        /* to be deleted
        if (section == sectionProducts) {
            if ((self.bonusAvailable && row == arrayItem.count + 1) || (!self.bonusAvailable && row == arrayItem.count)) { // Subtotal
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
            } else if (self.bonusAvailable && row == arrayItem.count) { // Referral Bonus
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
            } else { // Cart product
                let i = tableView.dequeueReusableCellWithIdentifier("cell_item2") as! CartCellItem
                let cp = products[indexPath.row]
                i.selectedPaymentId = cp.packageId
                //                i.selectedPaymentId = "" // debug
                i.adapt(arrayItem[indexPath.row])
                i.cartItemCellDelegate = self
                
                if (row == 0)
                {
                    
                } else
                {
                    i.topLine?.hidden = true
                }
                
                i.indexPath = indexPath
                
                cell = i
            }
        } else if (section == sectionPreloBalance) {
            if (row == 0)
            {
                let identifier = usingPreloBalance ? "pbcellInput2" : "pbcellInput1"
                let c = tableView.dequeueReusableCellWithIdentifier(identifier) as! PreloBalanceInputCell
                c.captionTotalBalance.text = "Prelo Balance kamu \(balanceAvailable.asPrice)"
                c.delegate = self
                
                c.txtInput?.text = nil
                c.switchBalance.setOn(usingPreloBalance, animated: false)
                
                return c
            }
            
            if (row - preloBalanceItems.count == 1)
            {
                let totalCell = tableView.dequeueReusableCellWithIdentifier("pbcellTotal") as! PreloBalanceTotalCell
                //                let p = (subtotalPrice - totalPreloBalanceDiscount)
                var p = subtotalPrice
                for i in self.preloBalanceItems
                {
                    p = p - i.value
                }
                totalCell.captionValue.text = (p < 0 ? 0 : p).asPrice
                return totalCell
            }
            
            let item = preloBalanceItems[row-1]
            let itemCell = tableView.dequeueReusableCellWithIdentifier("pbcellItem") as! PreloBalanceItemCell
            itemCell.captionTitle.text = item.title
            itemCell.captionValue.text = "-\(item.value.asPrice)"
            return itemCell
            
            //            let c = tableView.dequeueReusableCellWithIdentifier("pbcellInput1") as! PreloBalanceInputCell
            //            c.captionTotalBalance.text = "Prelo Balance kamu \(balanceAvailable.asPrice)"
            //            c.delegate = self
            //            return c
        } else if (section == sectionDataUser) {
            if (row == 2) {
                cell = tableView.dequeueReusableCellWithIdentifier("cell_edit")!
            } else {
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
            }
        } else if (section == sectionAlamatUser) {
            if (row == 0 || row == 3) {
                if (row == 0) {
                    return createExpandableCell(tableView, indexPath: indexPath)!
                }
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
            } else {
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input_2")
            }
        }*/
        
        cellViews[indexPath] = cell
        
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
                if let error = json["_error"].string
                {
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
            } else { // Provinsi, Kab/Kota, Kode Pos
                return 44
            }
        } else if (section == sectionPayMethod) {
            if (row == 0) {
                return 198
            }
        } else if (section == sectionPaySummary) {
            if (row == 1) { // Prelo balance switch
                return usingPreloBalance ? 115 : 60
            } else if (row == discountItems.count + 5) { // Voucher
                return 100
            } else {
                return 36
            }
        } else if (section == sectionPreloBalance) {
            if (row == 0)
            {
                return usingPreloBalance ? 115 : 60
            }
            return 44
        }
        return 0
        
        /* to be deleted
        if (section == sectionProducts) {
            if (row >= arrayItem.count) {
                if (self.bonusAvailable && row == arrayItem.count)
                {
                    return 24
                }
                return 44
            } else {
                let json = arrayItem[indexPath.row]
                if let error = json["_error"].string
                {
                    let options : NSStringDrawingOptions = [.UsesLineFragmentOrigin, .UsesFontLeading]
                    let h = (error as NSString).boundingRectWithSize(CGSizeMake(UIScreen.mainScreen().bounds.width - 114, 0), options: options, attributes: [NSFontAttributeName:UIFont.systemFontOfSize(14)], context: nil).height
                    return 77 + h
                }
                return 94
            }
        } else if (section == sectionPreloBalance) {
            if (row == 0)
            {
                return usingPreloBalance ? 115 : 60
            }
            return 44
        } else if (section == sectionDataUser) {
            if (row == 2) {
                return 20
            } else {
                return 44
            }
        } else {
            if (row == 0 || row == 3) {
                if (row == 0) {
                    return CGFloat(addressHeight)
                }
                return 44
            } else {
                return 44
            }
        }*/
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        /* to be deleted
        if (section == sectionPreloBalance)
        {
            return 0
        }*/
        return 44
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        /* to be deleted
        if (section == sectionPreloBalance)
        {
            return nil
        }*/
        
        let v = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 44))
        
        v.backgroundColor = UIColor(hexString: "#9dd4d0")
        
        var lblFrame = CGRectZero
        lblFrame.origin.x = 8
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
        } else if (section == sectionPreloBalance) {
            l.text = "TO BE DELETED"
        }
        
        /* to be deleted
        if (section == sectionProducts) {
            l.text = "RINGKASAN BARANG"
        } else if (section == sectionDataUser) {
            l.text = "DATA KAMU"
        } else if (section == sectionAlamatUser) {
            l.text = "ALAMAT PENGIRIMAN"
        }*/
        
        l.sizeToFit()
        
        l.y = (v.height - l.height) / 2
        
        v.addSubview(l)
        
        return v
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let c = tableView.cellForRowAtIndexPath(indexPath)
        if ((c?.canBecomeFirstResponder())!) {
            c?.becomeFirstResponder()
        }
        // check if the cell is editable
    }
    
    func tableView(tableView: UITableView!, updatedHeight height: CGFloat, atIndexPath indexPath: NSIndexPath!) {
        addressHeight = Int(height)
    }
    
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        // crash
        if let i = indexPath
        {
            cellsData[i]?.value = text
        }
    }
    
    // MARK: - UITextField functions
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        /* to be deleted
        if (textField == txtVoucher) {
            voucher = txtVoucher.text == nil ? "" : txtVoucher.text!
            return false
        }*/
        
        textField.resignFirstResponder()
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            // This will be crash on iOS 7.1
            let i = tableView.indexPathForCell((textField.superview?.superview!) as! UITableViewCell)
            var s = (i?.section)!
            var r = (i?.row)!
            
            var cell : UITableViewCell?
            
            var con = true
            while (con) {
                let newIndex = NSIndexPath(forRow: r+1, inSection: s)
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
                        r+=1
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
        /* to be deleted, ane ga paham
        for k in cellViews.keys
        {
            let c = cellViews[k]!
            let same = c.isKindOfClass(BaseCartCell.classForCoder())
            if (same == true) {
                let b = c as! BaseCartCell
                cellsData[b.lastIndex!] = b.obtainValue()
            }
        }*/
        
        var name = ""
        var phone = ""
        var postal = ""
        let email = (CDUser.getOne()?.email)!
        for i in cellsData.keys
        {
            let b = cellsData[i]
            if (b?.value == nil || b?.value == "") {
                Constant.showDialog("Warning", message: (b?.title)! + " still empty !")
                return
            }
            
            if (b?.title == titleNama)
            {
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
        
        let user = CDUser.getOne()
        user?.profiles.address = address
        user?.profiles.postalCode = postal
        UIApplication.appDelegate.saveContext()
        
        let d = ["address":address, "province_id":selectedProvinsiID, "region_id":selectedKotaID, "postal_code":postal, "recipient_name":name, "recipient_phone":phone, "email":email]
        let a = AppToolsObjC.jsonStringFrom(d)
        
        if (p == "[]" || p == "")
        {
            Constant.showDialog("Warning", message: "Tidak ada barang")
            return
        }
        
        self.btnSend.enabled = false
        
        var usedBalance = 0
        if usingPreloBalance { // Pengecekan #1
            let discBalance = discountItems[0]
            if (discBalance.title == "Prelo Balance") { // Pengecekan #2
                usedBalance = discBalance.value
            }
            
            /* to be deleted
            let i = preloBalanceItems[0]
            usedBalance = i.value*/
        }
        
        request(APICart.Checkout(cart: p, address: a, voucher: voucher, payment: selectedPayment, usedPreloBalance: usedBalance, kodeTransfer: bankTransferDigit)).responseJSON {resp in
//            print(res)
            self.btnSend.enabled = true
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Checkout")) {
                var json = JSON(resp.result.value!)
                print(json)
                if let error = json["_message"].string
                {
                    Constant.showDialog("Warning", message: error)
                } else {
//                    print(res)
                    let json = JSON(resp.result.value!)
                    self.checkoutResult = json["_data"]
                    
                    //let _have_error = self.checkoutResult?["_have_error"].intValue
                    
                    if (json["_data"]["_have_error"].intValue == 1)
                    {
                        let m = json["_data"]["_message"].stringValue
                        UIAlertView.SimpleShow("Perhatian", message: m)
                        return
                    }
                    
//                    let c = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdCartConfirm) as! CarConfirmViewController
                    
                    var gTotal = 0
                    if let totalPrice = self.checkoutResult?["total_price"].int {
                        gTotal += totalPrice
                    }
                    if let trfCode = self.checkoutResult?["banktransfer_digit"].int {
                        gTotal += trfCode
                    }
                    
                    let o = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
                    
                    o.orderID = (self.checkoutResult?["order_id"].string)!
                    o.total = gTotal
                    o.transactionId = (self.checkoutResult?["transaction_id"].string)!
                    o.overBack = true
                    
                    var imgs : [NSURL] = []
                    
                    for i in 0...self.arrayItem.count-1
                    {
                        let json = self.arrayItem[i]
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
                                if let u = NSURL(string: ori.first!)
                                {
                                    imgs.append(u)
                                }
                            }
                        }
                    }
                    
                    o.images = imgs
                    
                    // pindah ke OrderConfirmViewController
//                    for p in self.products
//                    {
//                        UIApplication.appDelegate.managedObjectContext?.deleteObject(p)
//                    }
//                    UIApplication.appDelegate.saveContext()
                    
                    // Send tracking data
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
                    
                    o.clearCart = true
                    self.navigateToVC(o)
                    
                }
            }
        }
    }
    
    /* to be deleted
    @IBAction func saveVoucher()
    {
        voucher = txtVoucher.text!
        self.synch()
    }*/
    
    func saveVoucher() {
        self.synch()
    }
    
    func setPaymentOption(tag : Int) {
        selectedPayment = availablePayments[tag]
    }
    
    /* to be deleted
    @IBAction func setPaymentOption(sender : UITapGestureRecognizer)
    {
        let v = sender.view!
        let i = v.tag
        
        if (i > 0)
        {
            UIAlertView.SimpleShow("Coming Soon :)", message: "")
            return
        }
        for b in sectionsPaymentOption
        {
            b.cartSelectAsPayment(false)
        }
        
        let b = sender.view as! BorderedView
        b.cartSelectAsPayment(true)
        
        let x = (UIScreen.mainScreen().bounds.size.width-32) * -CGFloat(i)
        consOffsetPaymentDesc?.constant = x
        
        selectedPayment = availablePayments[b.tag]
    }*/

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
        for cp in products
        {
            if (cp.cpID == pid) // delete cart product
            {
                deletedProduct = cp
                break
            }
            index += 1
        }
        
        if let p = deletedProduct
        {
            products.removeAtIndex(index)
            print(p.cpID)
            UIApplication.appDelegate.managedObjectContext.deleteObject(p)
            UIApplication.appDelegate.saveContext()
        }
        
//        let p = products[indexPath.row]
        
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        if (arrayItem.count == 0) {
            self.shouldBack = true
//            self.navigationController?.popViewControllerAnimated(true)
        } //else {
            cellsData = [:]
            for (_, c) in cellViews
            {
                if let b = c as? BaseCartCell
                {
                    b.lastIndex = nil
                } else if let b = c as? CartAddressCell
                {
                    b.lastIndex = nil
                }
            }
//            cellViews = [:]
//            createCells()
            synch()
        //}
    }
    
    func itemNeedUpdateShipping(indexPath: NSIndexPath) {
        let j = arrayItem[indexPath.row]
        let jid = j["product_id"].stringValue
        var cartProduct : CartProduct?
        for cp in products
        {
            if (cp.cpID == jid)
            {
                cartProduct = cp
                break
            }
        }
        
        if let cp = cartProduct
        {
            print(j)
            var names : Array<String> = []
            var arr = j["shipping_packages"].array
            if let shippings = j["shipping_packages"].arrayObject
            {
                for s in shippings
                {
                    let json = JSON(s)
                    if let name = json["name"].string
                    {
                        names.append(name)
                    }
                }
                
                if (names.count > 0)
                {
                    ActionSheetStringPicker.showPickerWithTitle("Select Shipping", rows: names, initialSelection: 0, doneBlock: {picker, index, value in
                        let sjson = arr?[index]
                        if let pid = sjson?["_id"].string
                        {
                            cp.packageId = pid
                            let c = self.cellViews[indexPath] as! CartCellItem
                            c.selectedPaymentId = pid
                            c.adapt(self.arrayItem[indexPath.row])
                            UIApplication.appDelegate.saveContext()
//                            self.tableView.reloadData()
                            self.adjustTotal()
                        }
                        }, cancelBlock: {picker in
                            
                        }, origin: tableView.cellForRowAtIndexPath(indexPath))
                }
            }
        }
    }
    
    @IBAction func paymentReminderPressed(sender: AnyObject) {
        let paymentConfirmationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil).first as! PaymentConfirmationViewController
        self.navigateToVC(paymentConfirmationVC)
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
            totalPreloBalanceDiscount = 0
            if (discountItems.count > 0) {
                if (discountItems[0].title == "Prelo Balance") {
                    discountItems.removeAtIndex(0)
                    tableView.deleteRowsAtIndexPaths([NSIndexPath(forItem: 2, inSection: sectionPaySummary)], withRowAnimation: .Fade)
                }
            }
            
            /* to be deleted */
            if (preloBalanceItems.count > 0)
            {
                preloBalanceItems.removeAtIndex(0)
                //tableView.deleteRowsAtIndexPaths([NSIndexPath(forItem: 1, inSection: sectionPreloBalance)], withRowAnimation: .Fade)
            }
            
        } else {
            if (discountItems.count <= 0 || (discountItems.count > 0 && discountItems[0].title != "Prelo Balance")) {
                let discItem = DiscountItem(title: "Prelo Balance", value: 0)
                discountItems.insert(discItem, atIndex: 0)
                tableView.insertRowsAtIndexPaths([NSIndexPath(forItem: 2, inSection: sectionPaySummary)], withRowAnimation: .Fade)
            }
            
            /* to be deleted */
            let pbitem = PreloBalanceItem(title: "Prelo Balance", value: 0)
            preloBalanceItems.insert(pbitem, atIndex: 0)
            //tableView.insertRowsAtIndexPaths([NSIndexPath(forItem: 1, inSection: sectionPreloBalance)], withRowAnimation: .Fade)
            
        }
        usingPreloBalance = isON
        
        //tableView.reloadRowsAtIndexPaths([NSIndexPath(forItem: 1, inSection: sectionPaySummary), NSIndexPath(forItem: 2, inSection: sectionPaySummary)], withRowAnimation: .Fade)
        
        /* to be deleted
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forItem: 0, inSection: sectionPreloBalance), NSIndexPath(forItem: self.preloBalanceItems.count + 1, inSection: sectionPreloBalance)], withRowAnimation: .Fade)*/
        
        adjustRingkasan()
    }
    
    func preloBalanceInputCellBalanceSubmitted(balance: Int) {
        var balanceFix = balance
        var warning = ""
        if (balanceFix > self.subtotalPrice) {
            balanceFix = self.subtotalPrice
            warning += "Prelo balance yang digunakan disesuaikan karena melebihi subtotal."
        }
        if (balanceFix % 1000 != 0) {
            balanceFix -= balanceFix % 1000
            warning += " Prelo balance yang digunakan harus kelipatan 1000."
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
        totalPreloBalanceDiscount = balanceFix
        
        /* to be deleted */
        var item = preloBalanceItems[0]
        item.value = balanceFix
        preloBalanceItems[0] = item
        totalPreloBalanceDiscount = balanceFix
//        tableView.reloadData()
        
        adjustRingkasan()
    }
    
    // MARK: - User Related Delegate
    
    func userLoggedIn() {
        user = CDUser.getOne()
        products = CartProduct.getAll(User.EmailOrEmptyString)
        tableView.hidden = false
//        createCells()
        synch()
    }
    
    func userCancelLogin() {
        user = CDUser.getOne()
        if (user == nil)
        {
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
    
    static func instance(title : String?, placeHolder : String?) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = true
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, enable : Bool) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = enable
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, value : String) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = true
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, value : String, pickerPrepBlock : PrepDataBlock?) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = true
        
        b.pickerPrepDataBlock = pickerPrepBlock
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, value : String?, enable : Bool) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = enable
        
        return b
    }
    
    static func instanceWith(image : UIImage, placeHolder : String) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = ""
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = true
        b.image = image
        
        return b
    }
    
    static func instanceWith(image : UIImage, placeHolder : String, pickerPrepBlock : PrepDataBlock?) -> BaseCartData
    {
        let b = BaseCartData.instanceWith(image, placeHolder: placeHolder)
        b.pickerPrepDataBlock = pickerPrepBlock
        return b
    }
}

// MARK: - Class

class BaseCartCell : UITableViewCell
{
    @IBOutlet var captionTitle : UILabel?
    var parent : UIViewController?
    
    var baseCartData : BaseCartData?
    var lastIndex : NSIndexPath?
    
    @IBOutlet var bottomLine : UIView?
    @IBOutlet var topLine : UIView?
    
    func obtainValue() -> BaseCartData?
    {
        return nil
    }
    
    func adapt(item : BaseCartData?)
    {
        
    }
}

// MARK: - Class - Input berupa title dan textfield

class CartCellInput : BaseCartCell
{
    @IBOutlet var txtField : UITextField!
    
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
        if (item == nil) {
            captionTitle?.text = "-"
            txtField.text = "-"
            return
        }
        captionTitle?.text = item?.title
        let placeholder = item?.placeHolder
        if (placeholder != nil) {
            txtField.placeholder = placeholder
        }
        
        let value = item?.value
        if (value != nil) {
            if (value! == "10%")
            {
                txtField.font = UIFont.boldSystemFontOfSize(14)
                let l = self.contentView.viewWithTag(666)
                l?.hidden = true
            }
            txtField.text = value
        } else {
            txtField.text = ""
        }
        
        if let t = captionTitle?.text
        {
            let s = t.lowercaseString as NSString
            let i = s.rangeOfString("harga")
            if (i.location != NSNotFound)
            {
                txtField.keyboardType = UIKeyboardType.DecimalPad
            } else
            {
                txtField.keyboardType = (item?.keyboardType)!
            }
        }
        
        txtField.enabled = (item?.enable)!
    }
    
    override func obtainValue() -> BaseCartData? {
        baseCartData?.value = txtField.text
        return baseCartData
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
//            let string = "SOLD OUT"
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

// MARK: - Class - Used prelo balance

class PreloBalanceItemCell : UITableViewCell
{
    @IBOutlet var captionTitle : UILabel!
    @IBOutlet var captionValue : UILabel!
}

// MARK: - Class - Total belanja

class PreloBalanceTotalCell : BaseCartCell
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
    
    // Tag set in storyboard
    // 0 = Transfer Bank
    // 1 = Kartu Kredit
    @IBOutlet var btnsMethod: [UIButton]!
    
    var methodChosen : (Int) -> () = { _ in }
    
    @IBAction func methodPressed(sender: UIButton) {
        if (sender.tag == 1) { // Disabled method
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

// MARK: - Class - Voucher

class CartVoucherCell : UITableViewCell {
    
    @IBOutlet var txtVoucher: UITextField!
    
    var applyVoucher : (String) -> () = { _ in }
    
    @IBAction func applyPressed(sender: AnyObject) {
        if (txtVoucher.text == nil || txtVoucher.text!.isEmpty) {
            return
        }
        self.applyVoucher(txtVoucher.text!)
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
        //        let tintedImageView = self.viewWithTag(1)
        //        let text = self.viewWithTag(2) as? UILabel
        //
        //        tintedImageView?.tintColor = c
        //        text?.textColor = c
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
