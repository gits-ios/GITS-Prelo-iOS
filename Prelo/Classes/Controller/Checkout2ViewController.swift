//
//  Checkout2ViewController.swift
//  Prelo
//
//  Created by Djuned on 6/8/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Crashlytics
import Alamofire
import DropDown

// MARK: - Class
class Checkout2ViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    
    //-------------
    // from page 1
    //-------------
    
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
    
    //-------------
    // from page 2
    //-------------
    
    // MARK: - Struct
    struct PaymentMethodItem {
        var name: String = ""
        var type: Int = 0
        var chargeDescription: String = ""
        var charge: Int64 = 0
        var provider: paymentMethodProvider = .bankTransfer
    }
    
    struct DiscountItem {
        var title: String = ""
        var value: Int64 = 0
    }
    
    var isShowBankBRI = false
    var isCreditCard = false
    var isIndomaret = false
    var isMandiriClickpay = false
    var isMandiriEcash = false
    var isCimbClicks = false
    var isKredivo = false
    var isDropdownMode = false
    
    // payment method -> bank etc
    var paymentMethods: Array<PaymentMethodItem>! = []
    var selectedPaymentIndex: Int = 0
    var targetBank: String = ""
    
    // discount item -> voucher etc
    var discountItems: Array<DiscountItem>! = []
    var isBalanceUsed: Bool = false
    var isVoucherUsed: Bool = false
    
    // bonus
    var isHalfBonusMode: Bool = false
    var customBonusPercent: Int64 = 0
    var preloBonusUsed: Int64 = 0
    
    var preloBalanceUsed: Int64 = 0
    var preloBalanceTotal: Int64 = 0
    
    var totalAmount: Int64 = 0
    
    var voucherSerial: String?
    var isFreeze: Bool = false
    
    // checkout
    var checkoutResult: JSON!
    
    //-----
    // NEW
    //-----
    
    var isNeedScroll = false
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let Checkout2CourierCell = UINib(nibName: "Checkout2CourierCell", bundle: nil)
        tableView.register(Checkout2CourierCell, forCellReuseIdentifier: "Checkout2CourierCell")
        
        let Checkout2ProductCell = UINib(nibName: "Checkout2ProductCell", bundle: nil)
        tableView.register(Checkout2ProductCell, forCellReuseIdentifier: "Checkout2ProductCell")
        
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
        
        let Checkout2PaymentMethodCell = UINib(nibName: "Checkout2PaymentMethodCell", bundle: nil)
        tableView.register(Checkout2PaymentMethodCell, forCellReuseIdentifier: "Checkout2PaymentMethodCell")
        
        let Checkout2PaymentBankCell = UINib(nibName: "Checkout2PaymentBankCell", bundle: nil)
        tableView.register(Checkout2PaymentBankCell, forCellReuseIdentifier: "Checkout2PaymentBankCell")
        
        let Checkout2PaymentCreditCardCell = UINib(nibName: "Checkout2PaymentCreditCardCell", bundle: nil)
        tableView.register(Checkout2PaymentCreditCardCell, forCellReuseIdentifier: "Checkout2PaymentCreditCardCell")
        
        let Checkout2BlackWhiteCell = UINib(nibName: "Checkout2BlackWhiteCell", bundle: nil)
        tableView.register(Checkout2BlackWhiteCell, forCellReuseIdentifier: "Checkout2BlackWhiteCell")
        
        let Checkout2PreloBalanceCell = UINib(nibName: "Checkout2PreloBalanceCell", bundle: nil)
        tableView.register(Checkout2PreloBalanceCell, forCellReuseIdentifier: "Checkout2PreloBalanceCell")
        
        let Checkout2VoucherCell = UINib(nibName: "Checkout2VoucherCell", bundle: nil)
        tableView.register(Checkout2VoucherCell, forCellReuseIdentifier: "Checkout2VoucherCell")
        
        let Checkout2PaymentSummaryCell = UINib(nibName: "Checkout2PaymentSummaryCell", bundle: nil)
        tableView.register(Checkout2PaymentSummaryCell, forCellReuseIdentifier: "Checkout2PaymentSummaryCell")
        
        let Checkout2PaymentSummaryTotalCell = UINib(nibName: "Checkout2PaymentSummaryTotalCell", bundle: nil)
        tableView.register(Checkout2PaymentSummaryTotalCell, forCellReuseIdentifier: "Checkout2PaymentSummaryTotalCell")
        
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
        tap.cancelsTouchesInView = false
        
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
                "Product IDs" : productIds
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
                let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                notifPageVC.previousScreen = PageName.Checkout
                self.navigationController?.pushViewController(notifPageVC, animated: true)
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
                
                if self.isFirst && self.cartResult.addressBook.count > 0 {
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
                            
                            break
                        }
                    }
                }
                
                // update troli
                self.setupOption(self.cartResult.nTransactionUnpaid)
                let count = CartManager.sharedInstance.getSize() + self.cartResult.nTransactionUnpaid
                notifListener?.setCartCount(count)
                
                self.setupPaymentAndDiscount()
                
                // reset - cart
                self.isEnableToCheckout = true
                
                self.setupDropdownAddress()
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
    
    func setupPaymentAndDiscount() {
        // count total
        var totalWithOngkir = self.cartResult.totalPrice
        
        for o in self.ongkirs {
            totalWithOngkir += o
        }
        
        self.totalAmount = totalWithOngkir
        // count total
        
        // reset
        self.paymentMethods = []
        self.discountItems = []
        self.isFreeze = false
        self.isHalfBonusMode = false
        self.isShowBankBRI = false
        self.isCreditCard = false
        self.isIndomaret = false
        self.isMandiriClickpay = false
        self.isMandiriEcash = false
        self.isCimbClicks = false
        self.isKredivo = false
        self.isDropdownMode = false
        
        // transfer bank
        var p = PaymentMethodItem()
        p.name = "Transfer Bank"
        p.charge = self.cartResult.banktransferDigit
        p.chargeDescription = "Kode Unik Transfer"
        p.provider = .bankTransfer
        self.paymentMethods.append(p)
        
        let ab = self.cartResult.abTest
        for _ab in ab {
            if (_ab == "half_bonus") {
                self.isHalfBonusMode = true
            } else if (_ab == "bri") {
                self.isShowBankBRI = true
            } else if (_ab == "cc") {
                self.isCreditCard = true
            } else if (_ab == "indomaret") {
                self.isIndomaret = true
            } else if (_ab.range(of: "bonus:") != nil) {
                self.customBonusPercent = Int64(_ab.components(separatedBy: "bonus:")[1])!
            } else if (_ab == "target_bank") {
                self.isDropdownMode = true
            } else if (_ab == "kredivo") {
                self.isKredivo = true
            } else if (_ab == "mandiri_clickpay") {
                self.isMandiriClickpay = true
            } else if (_ab == "mandiri_ecash") {
                self.isMandiriEcash = true
            } else if (_ab == "cimb_clicks") {
                self.isCimbClicks = true
            }
        }
        
        // reset selectedBank
        if !self.isDropdownMode {
            self.targetBank = ""
        }
        
        // Discount items
        self.preloBalanceTotal = self.cartResult.preloBalance
        
        if (self.cartResult.isVoucherValid == true) {
            self.voucherSerial = self.cartResult.voucherSerial
            let voucherAmount = self.cartResult.voucherAmount
            self.isVoucherUsed = true
            if voucherAmount > 0 { // if zero, not shown
                let discVoucher = DiscountItem(title: "Voucher '" + self.voucherSerial! + "'", value: voucherAmount)
                self.discountItems.append(discVoucher)
                
                self.isFreeze = true
                self.scrollToSummary()
            }
        } else {
            if self.cartResult.voucherError != "" {
                self.voucherSerial = nil
                self.isVoucherUsed = false
                Constant.showDialog("Invalid Voucher", message: self.cartResult.voucherError)
            }
        }
        
        let bonus = self.cartResult.preloBonus
        if (bonus > 0) {
            self.preloBonusUsed = bonus
            let disc = DiscountItem(title: "Referral Bonus", value: bonus)
            self.discountItems.append(disc)
        }
        
        // Update bonus discount if its more than half of subtotal
        if (self.discountItems.count > 0) {
            for i in 0...self.discountItems.count-1 {
                if (self.discountItems[i].title == "Referral Bonus") {
                    if (self.customBonusPercent > 0) {
                        if (self.preloBonusUsed > self.totalAmount * self.customBonusPercent / 100) {
                            self.preloBonusUsed = self.totalAmount * customBonusPercent / 100
                            self.discountItems[i].value = self.preloBonusUsed
                            // Show lblSend
                            //                            self.lblSend.text = "Maksimal Referral Bonus yang dapat digunakan adalah \(customBonusPercent)% dari subtotal transaksi"
                            //                            self.consHeightLblSend.constant = 31
                        }
                    } else if (isHalfBonusMode) {
                        if (self.preloBonusUsed > self.totalAmount / 2) {
                            self.preloBonusUsed = self.totalAmount / 2
                            self.discountItems[i].value = self.preloBonusUsed
                            // Show lblSend
                            //                            self.lblSend.text = "Maksimal Referral Bonus yang dapat digunakan adalah 50% dari subtotal transaksi"
                            //                            self.consHeightLblSend.constant = 31
                        }
                    } else {
                        if (self.discountItems[i].value > self.totalAmount) {
                            self.preloBonusUsed = self.totalAmount
                            self.discountItems[i].value = self.preloBonusUsed
                        }
                    }
                }
            }
        }
        
        // prelo balance
        // setup balance
        var operan: Int64 = 0
        for d in self.discountItems {
            operan += d.value
        }
        
        self.preloBalanceUsed = (self.totalAmount - operan > self.preloBalanceTotal ? self.preloBalanceTotal : self.totalAmount - operan)
        
        if self.preloBalanceUsed < 0 {
            self.preloBalanceUsed = 0
            self.isBalanceUsed = false
        }
        
        if self.isBalanceUsed {
            var d = DiscountItem()
            d.title = "Prelo Balance"
            d.value = self.preloBalanceUsed
            
            self.discountItems.insert(d, at: 0)
        }
        
        // Kartu Kredit & Indomaret re-count
        var priceAfterDiscounts = self.totalAmount - operan
        if self.isBalanceUsed {
            priceAfterDiscounts -= self.preloBalanceUsed
        }
        
        let creditCardCharge = (self.cartResult.veritransCharge?.creditCard)! + Int64((Double(priceAfterDiscounts) * (self.cartResult.veritransCharge?.creditCardMultiplyFactor)!) + 0.5)
        
        var indomaretCharge = Int64((Double(priceAfterDiscounts) * (self.cartResult.veritransCharge?.indomaretMultiplyFactor)!) + 0.5)
        if (indomaretCharge < (self.cartResult.veritransCharge?.indomaret)!) {
            indomaretCharge = (self.cartResult.veritransCharge?.indomaret)!
        }
        
        let mandiriClickpayCharge = (self.cartResult.veritransCharge?.mandiriClickpay)!
        
        var mandiriEcashCharge = Int64((Double(priceAfterDiscounts) * (self.cartResult.veritransCharge?.mandiriEcashMultiplyFactor)!) + 0.5)
        if (mandiriEcashCharge < (self.cartResult.veritransCharge?.mandiriEcash)!) {
            mandiriEcashCharge = (self.cartResult.veritransCharge?.mandiriEcash)!
        }
        
        let cimbClicksCharge = (self.cartResult.veritransCharge?.cimbClicks)!
        
        let kredivoCharge = Int64((Double(priceAfterDiscounts) * (self.cartResult.kredivoCharge?.installment)!) + 0.5)
        
        if self.isCreditCard {
            var p = PaymentMethodItem()
            p.name = "Kartu Kredit"
            p.charge = creditCardCharge
            p.chargeDescription = "Credit Card Charge"
            p.provider = .veritrans
            self.paymentMethods.append(p)
        }
        
        if self.isIndomaret {
            var p = PaymentMethodItem()
            p.name = "Indomaret"
            p.charge = indomaretCharge
            p.chargeDescription = "Indomaret Charge"
            p.provider = .veritrans
            self.paymentMethods.append(p)
            
            if p.charge == 0 {
                self.isFreeze = true
            }
        }
        
        if self.isKredivo {
            var p = PaymentMethodItem()
            p.name = "Kredivo"
            p.charge = kredivoCharge
            p.chargeDescription = "Kredivo Charge"
            p.provider = .kredivo
            self.paymentMethods.append(p)
        }
        
        if self.isCimbClicks {
            var p = PaymentMethodItem()
            p.name = "CIMB Clicks"
            p.charge = cimbClicksCharge
            p.chargeDescription = "CIMB Clicks Charge"
            p.provider = .veritrans
            self.paymentMethods.append(p)
        }
        
        if self.isMandiriClickpay {
            var p = PaymentMethodItem()
            p.name = "Mandiri Clickpay"
            p.charge = mandiriClickpayCharge
            p.chargeDescription = "Mandiri Clickpay Charge"
            p.provider = .veritrans
            self.paymentMethods.append(p)
        }
        
        if self.isMandiriEcash {
            var p = PaymentMethodItem()
            p.name = "Mandiri Ecash"
            p.charge = mandiriEcashCharge
            p.chargeDescription = "Mandiri Ecash Charge"
            p.provider = .veritrans
            self.paymentMethods.append(p)
        }
        
        // reset if payment out of range
        if self.paymentMethods.count <= self.selectedPaymentIndex {
            self.selectedPaymentIndex = 0
        }
        
        if self.isFirst {
            //self.setupTable()
            
            self.isFirst = false
        }
        
        self.tableView.reloadData()
        
        self.hideLoading()
    }
    
    func setupTable() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    // MARK: - UITableView Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            return 3 + cartResult.cartDetails.count + 3
        } else if !self.isLoading {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            if section == 0 {
                return 2
            } else if section <= cartResult.cartDetails.count {
                return cartResult.cartDetails[section-1].products.count + 2
            } else if section == cartResult.cartDetails.count + 2 {
                return 2 + (self.isNeedLocations.contains(true) ? 1 : 0) + 1
            } else if section == cartResult.cartDetails.count + 1 {
                return 2
            } else if section == cartResult.cartDetails.count + 3 {
                return 1 + self.paymentMethods.count
            } else if section == cartResult.cartDetails.count + 4 {
                return 1 + 2
            } else if section == cartResult.cartDetails.count + 5 {
                return 1 + 1 + (self.paymentMethods.count > 0 && !self.isEqual() ? 1 : 0) + self.discountItems.count + 1
            }
        } else if !self.isLoading {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            let idx = indexPath as IndexPath
            if idx.section == 0 {
                if idx.row == 0 {
                    return Checkout2PaymentMethodCell.heightFor()
                } else {
                    return 2.0 //Checkout2BlackWhiteCell.heightFor()
                }
            } else if idx.section <= cartResult.cartDetails.count {
                if idx.row == 0 {
                    return Checkout2CourierCell.heightFor()
                } else if idx.row <= cartResult.cartDetails[idx.section-1].products.count {
                    return Checkout2ProductCell.heightFor()
                } else {
                    return 2.0 //Checkout2BlackWhiteCell.heightFor()
                }
            } else if idx.section == cartResult.cartDetails.count + 2 {
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
                if idx.row == 0 {
                    return 40.0 //Checkout2TotalBuyingCell.heightFor()
                } else {
                    return Checkout2SplitCell.heightFor()
                }
            } else if idx.section == cartResult.cartDetails.count + 3 {
                if idx.row == 0 {
                    return Checkout2PaymentMethodCell.heightFor()
                } else if idx.row == 1 {
                    return Checkout2PaymentBankCell.heightFor(selectedPaymentIndex == idx.row-1)
                } else { // cc, indomaret, etc
                    return Checkout2PaymentCreditCardCell.heightFor(selectedPaymentIndex == idx.row-1)
                }
            } else if idx.section == cartResult.cartDetails.count + 4 {
                if idx.row == 0 {
                    return Checkout2BlackWhiteCell.heightFor()
                } else if idx.row == 1 {
                    return Checkout2PreloBalanceCell.heightFor(self.isBalanceUsed)
                } else {
                    return Checkout2VoucherCell.heightFor(self.isVoucherUsed)
                }
            } else if idx.section == cartResult.cartDetails.count + 5 {
                if idx.row == 0 {
                    return Checkout2PaymentMethodCell.heightFor()
                } else if idx.row > 0 && idx.row <= 1 + (self.paymentMethods.count > 0 && !self.isEqual() ? 1 : 0) + self.discountItems.count {
                    return Checkout2PaymentSummaryCell.heightFor()
                } else {
                    return Checkout2PaymentSummaryTotalCell.heightFor()
                }
            }
        } else if !self.isLoading {
            return 90
        }
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            let idx = indexPath as IndexPath
            if idx.section == 0 {
                if idx.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentMethodCell") as! Checkout2PaymentMethodCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt("RINGKASAN BARANG")
                    
                    return cell
                } else if idx.row == 1 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2BlackWhiteCell") as! Checkout2BlackWhiteCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.consHeightVwLine1px.constant = 2.0
                    
                    return cell
                }
            } else if ((indexPath as NSIndexPath).section <= cartResult.cartDetails.count) {
                if idx.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2CourierCell") as! Checkout2CourierCell
                    
                    let sellerId = self.cartResult.cartDetails[idx.section-1].id
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt(self.cartResult.cartDetails[idx.section-1].shippingPackages, isEnable: !self.isFreeOngkirs[idx.section-1], selectedIndex: self.selectedOngkirIndexes[idx.section-1], title: self.cartResult.cartDetails[idx.section-1].username)
                    
                    cell.pickCourier = { courierId, ongkir, index, isNeedLocation in
                        self.shippingPackageIds[idx.section-1] = courierId
                        self.ongkirs[idx.section-1] = ongkir
                        self.selectedOngkirIndexes[idx.section-1] = index
                        self.isNeedLocations[idx.section-1] = isNeedLocation
                        
                        CartManager.sharedInstance.updateShippingPackageId(sellerId, shippingPackageId: courierId)
                        
                        self.tableView.reloadData()
                    }
                    
                    cell.dismissKeyborad = {
                        self.dismissKeyboard()
                    }
                    
                    return cell
                } else if idx.row <= cartResult.cartDetails[idx.section-1].products.count {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2ProductCell") as! Checkout2ProductCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    let product = self.cartResult.cartDetails[idx.section-1].products[idx.row-1]
                    
                    //cell.vwLine1px.isHidden = true
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
                                    
                                    Constant.showDialog("Hapus Items", message: "\"\(self.cartResult.cartDetails[idx.section].fullname)\" gagal dihapus")
                                    
                                    self.hideLoading()
                                }
                            }
                        }
                        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
                        alertView.showCustom("Hapus Keranjang", subTitle: "Kamu yakin ingin menghapus \"\(self.cartResult.cartDetails[idx.section-1].products[idx.row-1].name)\"?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                        
                    }
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2BlackWhiteCell") as! Checkout2BlackWhiteCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.consHeightVwLine1px.constant = 2.0
                    
                    return cell
                }
            } else if idx.section == cartResult.cartDetails.count + 2 {
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
                        
                        let isDefault = cartResult.addressBook.count > selectedIndex ? cartResult.addressBook[selectedIndex] == cartResult.defaultAddress : false
                        
                        if isDefault {
                            cell.adapt(cartResult.addressBook[selectedIndex], parent: self)
                        } else {
                            cell.adapt(self.selectedAddress, parent: self)
                        }
                        
                        if self.isNeedScroll {
                            self.scrollToAddress()
                        }
                        
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
                        
                        cell.adapt(self.selectedAddress.coordinateAddress)
                        
                        cell.pickLocation = {
                            let googleMapVC = Bundle.main.loadNibNamed(Tags.XibNameGoogleMap, owner: nil, options: nil)?.first as! GoogleMapViewController
                            googleMapVC.blockDone = { result in
                                
                                self.selectedAddress.coordinate = result["latitude"]! + "," + result["longitude"]!
                                self.selectedAddress.coordinateAddress = result["address"]!
                                
                                //self.tableView.reloadData()
                                self.tableView.reloadRows(at: [idx], with: .fade)
                                
                                if self.selectedAddress.addressId != "" {
                                    self.updateAddress()
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
                if idx.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2TotalBuyingCell") as! Checkout2TotalBuyingCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.btnContinue.isHidden = true
                    cell.adapt(self.totalAmount.asPrice)
                    
                    cell.continueToPayment = {
                        // do nothing
                    }
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2SplitCell") as! Checkout2SplitCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    return cell
                }
            } else if idx.section == cartResult.cartDetails.count + 3 {
                if idx.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentMethodCell") as! Checkout2PaymentMethodCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt("METODE PEMBAYARAN")
                    
                    return cell
                } else if idx.row == 1 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentBankCell") as! Checkout2PaymentBankCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt(self.targetBank, isSelected: selectedPaymentIndex == idx.row-1, parent: self)
                    
                    return cell
                } else { // cc, indomaret, etc
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt(self.paymentMethods[idx.row-1].name, isSelected: selectedPaymentIndex == idx.row-1)
                    
                    return cell
                }
            } else if idx.section == cartResult.cartDetails.count + 4 {
                if idx.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2BlackWhiteCell") as! Checkout2BlackWhiteCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.consHeightVwLine1px.constant = 1.0
                    
                    return cell
                } else if idx.row == 1 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PreloBalanceCell") as! Checkout2PreloBalanceCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt(self, isUsed: self.isBalanceUsed)
                    
                    cell.preloBalanceUsed = {
                        self.isBalanceUsed = !self.isBalanceUsed
                        
                        if self.isBalanceUsed && (self.discountItems.count == 0 || self.discountItems[0].title != "Prelo Balance") {
                            var operan: Int64 = 0
                            
                            for d in self.discountItems {
                                operan += d.value
                            }
                            
                            self.preloBalanceUsed = (self.totalAmount - operan > self.preloBalanceTotal ? self.preloBalanceTotal : self.totalAmount - operan)
                            
                            if self.preloBalanceUsed > 0 {
                                var d = DiscountItem()
                                d.title = "Prelo Balance"
                                d.value = self.preloBalanceUsed
                                
                                self.discountItems.insert(d, at: 0)
                            } else {
                                self.preloBalanceUsed = 0
                            }
                        } else {
                            self.preloBalanceUsed = 0
                            
                            if self.discountItems[0].title == "Prelo Balance" {
                                self.discountItems.remove(at: 0)
                            }
                        }
                        
                        //self.tableView.reloadData()
                        self.tableView.reloadSections(IndexSet.init(arrayLiteral: idx.section, idx.section+1), with: .fade)
                        
                        if self.isBalanceUsed {
                            self.scrollToSummary()
                        }
                    }
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2VoucherCell") as! Checkout2VoucherCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt(self.voucherSerial, isUsed: self.isVoucherUsed, isFreeze: self.isFreeze)
                    
                    cell.voucherUsed = {
                        self.isVoucherUsed = !self.isVoucherUsed
                        
                        //self.tableView.reloadData()
                        self.tableView.reloadSections(IndexSet.init(arrayLiteral: idx.section, idx.section+1), with: .fade)
                        
                        if self.isVoucherUsed {
                            self.scrollToSummary()
                        }
                    }
                    
                    cell.voucherApply = { voucherSerial in
                        self.voucherSerial = voucherSerial
                        
                        self.synchCart()
                    }
                    
                    return cell
                }
            } else if idx.section == cartResult.cartDetails.count + 5 {
                if idx.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentMethodCell") as! Checkout2PaymentMethodCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    cell.adapt("RINGKASAN PEMBAYARAN")
                    
                    return cell
                } else if idx.row > 0 && idx.row <= 1 + (self.paymentMethods.count > 0 && !self.isEqual() ? 1 : 0) + self.discountItems.count {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentSummaryCell") as! Checkout2PaymentSummaryCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    if idx.row == 1 {
                        cell.adapt("Total Belanja", amount: self.totalAmount)
                    } else if idx.row > self.discountItems.count + 1 {
                        // recalculate
                        var operan: Int64 = 0
                        for d in self.discountItems {
                            operan += d.value // include balance
                        }
                        
                        // Kartu Kredit & Indomaret re-count
                        let priceAfterDiscounts = self.totalAmount - operan
                        
                        if self.paymentMethods[self.selectedPaymentIndex].name == "Kartu Kredit" {
                            let creditCardCharge = (self.cartResult.veritransCharge?.creditCard)! + Int64((Double(priceAfterDiscounts) * (self.cartResult.veritransCharge?.creditCardMultiplyFactor)!) + 0.5)
                            
                            self.paymentMethods[self.selectedPaymentIndex].charge = creditCardCharge
                            
                        } else if self.paymentMethods[self.selectedPaymentIndex].name == "Indomaret" {
                            var indomaretCharge = Int64((Double(priceAfterDiscounts) * (self.cartResult.veritransCharge?.indomaretMultiplyFactor)!) + 0.5)
                            if (indomaretCharge < (self.cartResult.veritransCharge?.indomaret)!) {
                                indomaretCharge = (self.cartResult.veritransCharge?.indomaret)!
                            }
                            
                            self.paymentMethods[self.selectedPaymentIndex].charge = indomaretCharge
                            
                        } else if self.paymentMethods[self.selectedPaymentIndex].name == "Mandiri Clickpay" {
                            let mandiriClickpayCharge = (self.cartResult.veritransCharge?.mandiriClickpay)!
                        
                            self.paymentMethods[self.selectedPaymentIndex].charge = mandiriClickpayCharge
                            
                        } else if self.paymentMethods[self.selectedPaymentIndex].name == "Mandiri Ecash" {
                            var mandiriEcashCharge = Int64((Double(priceAfterDiscounts) * (self.cartResult.veritransCharge?.mandiriEcashMultiplyFactor)!) + 0.5)
                            if (mandiriEcashCharge < (self.cartResult.veritransCharge?.mandiriEcash)!) {
                                mandiriEcashCharge = (self.cartResult.veritransCharge?.mandiriEcash)!
                            }
                            
                            self.paymentMethods[self.selectedPaymentIndex].charge = mandiriEcashCharge
                            
                        } else if self.paymentMethods[self.selectedPaymentIndex].name == "CIMB Clicks" {
                            let cimbClicksCharge = (self.cartResult.veritransCharge?.cimbClicks)!
                            
                            self.paymentMethods[self.selectedPaymentIndex].charge = cimbClicksCharge
                            
                        } else if self.paymentMethods[self.selectedPaymentIndex].name == "Kredivo" {
                            let kredivoCharge = Int64((Double(priceAfterDiscounts) * (self.cartResult.kredivoCharge?.installment)!) + 0.5)
                            
                            self.paymentMethods[self.selectedPaymentIndex].charge = kredivoCharge
                            
                        }
                        
                        cell.adapt(self.paymentMethods[self.selectedPaymentIndex].chargeDescription, amount: self.paymentMethods[self.selectedPaymentIndex].charge)
                    } else {
                        cell.adapt(self.discountItems[idx.row-2].title, amount: self.discountItems[idx.row-2].value * -1)
                    }
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentSummaryTotalCell") as! Checkout2PaymentSummaryTotalCell
                    
                    cell.selectionStyle = .none
                    cell.clipsToBounds = true
                    
                    var totalAmount = self.totalAmount
                    
                    for d in self.discountItems {
                        totalAmount -= d.value
                    }
                    
                    // charge
                    if totalAmount == self.paymentMethods[self.selectedPaymentIndex].charge {
                        for i in 0...self.discountItems.count-1 {
                            if self.discountItems[i].title.contains("Voucher") {
                                self.discountItems[i].value += totalAmount
                            }
                        }
                        
                        //self.tableView.reloadData()
                        self.tableView.reloadSections(IndexSet.init(integer: idx.section), with: .fade)
                        
                        totalAmount = 0
                    }
                    
                    if totalAmount > 0 {
                        totalAmount += self.paymentMethods[self.selectedPaymentIndex].charge
                    }
                    
                    // 0
                    if totalAmount < 0 {
                        for i in 0...self.discountItems.count-1 {
                            if self.discountItems[i].title.contains("Voucher") {
                                self.discountItems[i].value += totalAmount
                            }
                        }
                        
                        //self.tableView.reloadData()
                        self.tableView.reloadSections(IndexSet.init(integer: idx.section), with: .fade)
                        
                        totalAmount = 0
                    }
                    
                    cell.adapt(totalAmount)
                    
                    cell.checkout = {
                        if !self.validateField() {
                            return
                        }
                        
                        self.showLoading()
                        let alertView = SCLAlertView(appearance: Constant.appearance)
                        alertView.addButton("Lanjutkan") {
                            self.performCheckout()
                        }
                        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {
                            self.hideLoading()
                        }
                        alertView.showCustom("Perhatian", subTitle: "Kamu akan melakukan transaksi sebesar \(totalAmount.asPrice) menggunakan \(self.paymentMethods[self.selectedPaymentIndex].name). Lanjutkan?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                    }
                    
                    return cell
                }
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
        let idx = indexPath as IndexPath
        if idx.section == cartResult.cartDetails.count + 3 {
            if idx.row == 0 {
                // do nothing
            } else {
                self.selectedPaymentIndex = idx.row-1
                
                //self.tableView.reloadData()
                self.tableView.reloadSections(IndexSet.init(integer: idx.section), with: .fade)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
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
                        
                        Constant.showDialog("Hapus Items", message: "\"\(self.cartResult.cartDetails[idx.section].fullname)\" gagal dihapus")
                        
                        self.hideLoading()
                    }
                }
                
                //print("hapus tapped")
            }
            return [remove]
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            let idx = indexPath as IndexPath
            if idx.section <= cartResult.cartDetails.count && idx.section > 0 {
                if idx.row <= cartResult.cartDetails[idx.section-1].products.count && idx.row > 0 {
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
    
    // MARK: - Checkout
    func performCheckout() {
        
        let p = CartManager.sharedInstance.getCartJsonString()
        let d = [
            "coordinate": self.selectedAddress.coordinate,
            "coordinate_address": self.selectedAddress.coordinateAddress,
            "address": self.selectedAddress.address,
            "province_id": self.selectedAddress.provinceId,
            "region_id": self.selectedAddress.regionId,
            "subdistrict_id": self.selectedAddress.subdistrictId,
            "subdistrict_name": self.selectedAddress.subdistrictName,
            "postal_code": self.selectedAddress.postalCode,
            "recipient_name": self.selectedAddress.name,
            "recipient_phone": self.selectedAddress.phone,
            "email": User.EmailOrEmptyString
        ]
        let a = AppToolsObjC.jsonString(from: d)
        
        let _ = request(APIV2Cart.checkout(cart: p, address: a!, voucher: (self.isVoucherUsed ? self.voucherSerial! : ""), payment: self.paymentMethods[self.selectedPaymentIndex].name, usedPreloBalance: (self.isBalanceUsed ? self.preloBalanceUsed : 0), usedReferralBonus: self.preloBonusUsed, kodeTransfer: self.paymentMethods[0].charge, targetBank: (self.isDropdownMode ? self.targetBank : ""))).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Checkout")) {
                let json = JSON(resp.result.value!)
                self.checkoutResult = json["_data"]
                
                // Error handling
                if (json["_data"]["_have_error"].intValue == 1) {
                    let m = json["_data"]["_message"].stringValue
                    Constant.showDialog("Perhatian", message: m)
                    self.hideLoading()
                    return
                }
                
                if (self.checkoutResult == nil) {
                    Constant.showDialog("Perhatian", message: "Terdapat kesalahan saat melakukan checkout")
                    self.hideLoading()
                    return
                }
                
                // Send tracking data before navigate
                if (self.checkoutResult != nil) {
                    
                    // insert new address if needed
                    if (self.selectedAddress.isSave) {
                        self.insertNewAddress()
                    }
                    
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
                    
                    // Prelo Analytic - Checkout - Item Data
                    var itemsObject : Array<[String : Any]> = []
                    
                    var items : [String] = []
                    var itemsId : [String] = []
                    var itemsCategory : [String] = []
                    var itemsSeller : [String] = []
                    var itemsPrice : [Int64] = []
                    var itemsCommissionPercentage : [Int64] = []
                    var itemsCommissionPrice : [Int64] = []
                    var totalCommissionPrice : Int64 = 0
                    var totalPrice : Int64 = 0
                    
                    for c in self.cartResult.cartDetails {
                        for p in c.products {
                            items.append(p.name)
                            itemsId.append(p.productId)
                            if let cName = CDCategory.getCategoryNameWithID(p.categoryId) {
                                itemsCategory.append(cName)
                            } else {
                                itemsCategory.append("")
                            }
                            itemsSeller.append(p.sellerUsername)
                            itemsPrice.append(p.price)
                            itemsCommissionPercentage.append(p.commission)
                            let cPrice = p.price * p.commission / 100
                            itemsCommissionPrice.append(cPrice)
                            totalCommissionPrice += cPrice
                            
                            // Prelo Analytic - Checkout - Item Data
                            let curItem : [String : Any] = [
                                "Product ID" : p.productId,
                                "Seller Username" : p.sellerUsername,
                                "Price" : p.price,
                                "Commission Percentage" : p.commission,
                                "Commission Price" : cPrice,
                                "Free Shipping" : p.isFreeOngkir,
                                "Category ID" : p.categoryId
                            ]
                            itemsObject.append(curItem)
                            
                            // AppsFlyer
                            let afPdata: [String : Any] = [
                                AFEventParamRevenue     : (p.price).string,
                                AFEventParamContentType : p.categoryId,
                                AFEventParamContentId   : p.productId,
                                AFEventParamCurrency    : "IDR"
                            ]
                            AppsFlyerTracker.shared().trackEvent(AFEventInitiatedCheckout, withValues: afPdata)
                        }
                    }
                    
                    let orderId = self.checkoutResult!["order_id"].stringValue
                    let paymentMethod = self.checkoutResult!["payment_method"].stringValue
                    
                    totalPrice = self.checkoutResult!["total_price"].int64Value
                    
                    // FB Analytics - initiated Checkout
                    if AppTools.IsPreloProduction {
                        do {
                            //Convert to Data
                            let jsonData = try! JSONSerialization.data(withJSONObject: itemsId, options: JSONSerialization.WritingOptions.prettyPrinted)
                            
                            //Convert back to string. Usually only do this for debugging
                            if let JSONString = String(data: jsonData, encoding: String.Encoding.utf8) {
                                print(JSONString)
                                let productIdsString = JSONString.replaceRegex(Regex.init(pattern: "\n| ") , template: "")
                                print(productIdsString)
                                
                                let fbPdata: [String : Any] = [
                                    FBSDKAppEventParameterNameContentType          : "product",
                                    FBSDKAppEventParameterNameContentID            : productIdsString,
                                    FBSDKAppEventParameterNameNumItems             : itemsId.count.string,
                                    FBSDKAppEventParameterNameCurrency             : "IDR"
                                ]
                                FBSDKAppEvents.logEvent(FBSDKAppEventNameInitiatedCheckout, valueToSum: Double(totalPrice), parameters: fbPdata)
                            }
                        }
                    }
                    
                    /*
                     // MixPanel
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
                     */
                    
                    // Prelo Analytic - Checkout
                    let loginMethod = User.LoginMethod ?? ""
                    let localId = User.CartLocalId ?? ""
                    let province = CDProvince.getProvinceNameWithID(self.selectedAddress.provinceId) ?? ""
                    let region = CDRegion.getRegionNameWithID(self.selectedAddress.regionId) ?? ""
                    let subdistrict = self.selectedAddress.subdistrictName
                    
                    let address = [
                        "Province" : province,
                        "Region" : region,
                        "Subdistrict" : subdistrict
                        ] as [String : Any]
                    
                    var pdata = [
                        "Local ID" : localId,
                        "Order ID" : orderId,
                        "Items" : itemsObject,
                        "Total Price" : totalPrice,
                        "Address" : address,
                        "Payment Method" : paymentMethod,
                        "Prelo Balance Used" : (self.checkoutResult!["prelobalance_used"].int64Value != 0 ? true : false)
                        ] as [String : Any]
                    
                    if (self.checkoutResult!["voucher_serial"].stringValue != "") {
                        pdata["Voucher Used"] = self.checkoutResult!["voucher_serial"].stringValue
                    }
                    
                    AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.Checkout, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
                    
                    // reset localid
                    User.SetCartLocalId("")
                    
                    // Answers
                    if (AppTools.IsPreloProduction) {
                        Answers.logStartCheckout(withPrice: NSDecimalNumber(value: totalPrice as Int64), currency: "IDR", itemCount: NSNumber(value: items.count as Int), customAttributes: nil)
                        for j in 0...items.count-1 {
                            Answers.logPurchase(withPrice: NSDecimalNumber(value: itemsPrice[j] as Int64), currency: "IDR", success: true, itemName: items[j], itemType: itemsCategory[j], itemId: itemsId[j], customAttributes: nil)
                        }
                    }
                    
                    // Google Analytics Ecommerce Tracking
                    if (AppTools.IsPreloProduction) {
                        let gaTracker = GAI.sharedInstance().defaultTracker
                        let trxDict = GAIDictionaryBuilder.createTransaction(withId: orderId, affiliation: "iOS Checkout", revenue: totalPrice as NSNumber!, tax: totalCommissionPrice as NSNumber!, shipping: (self.totalAmount - self.cartResult.totalPrice) as NSNumber!, currencyCode: "IDR").build() as NSDictionary? as? [AnyHashable: Any]
                        gaTracker?.send(trxDict)
                        
                        for c in self.cartResult.cartDetails {
                            for p in c.products {
                                var cName = CDCategory.getCategoryNameWithID(p.categoryId)
                                if cName == nil {
                                    cName = p.categoryId
                                }
                                
                                let trxItemDict = GAIDictionaryBuilder.createItem(withTransactionId: orderId, name: p.name, sku: p.productId, category: cName, price: p.price as NSNumber!, quantity: 1, currencyCode: "IDR").build() as NSDictionary? as? [AnyHashable: Any]
                                gaTracker?.send(trxItemDict)
                            }
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
                    moeDict.setObject((self.totalAmount - self.cartResult.totalPrice), forKey: "Shipping Price" as NSCopying)
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
                
                self.hideLoading()
                
                // update troli badge count
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let notifListener = appDelegate.preloNotifListener
                notifListener?.setCartCount(1 + self.cartResult.nTransactionUnpaid)
                
                // cleaning cart - if exist
                CartProduct.deleteAll()
                CartManager.sharedInstance.deleteAll()
                
                // Prepare to navigate to next page
                if (self.paymentMethods[self.selectedPaymentIndex].provider == .bankTransfer) { // bank
                    self.navigateToOrderConfirmVC(false)
                    
                } else if (self.paymentMethods[self.selectedPaymentIndex].provider == .veritrans) { // Credit card, indomaret
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let webVC = mainStoryboard.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
                    webVC.url = self.checkoutResult!["veritrans_redirect_url"].stringValue
                    webVC.titleString = "Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].name)"
                    webVC.creditCardMode = true
                    webVC.ccPaymentSucceed = {
                        self.navigateToOrderConfirmVC(true)
                    }
                    webVC.ccPaymentUnfinished = {
                        Constant.showDialog("Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].name)", message: "Pembayaran tertunda")
                        /*
                        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                        notifPageVC.isBackTwice = true
                        notifPageVC.previousScreen = PageName.Checkout
                        self.navigateToVC(notifPageVC)
                        */
                        
                        // back & push
                        if let count = self.navigationController?.viewControllers.count, count >= 2 {
                            let navController = self.navigationController!
                            var controllers = navController.viewControllers
                            controllers.removeLast()
                            
                            navController.setViewControllers(controllers, animated: false)
                            
                            let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
                            myPurchaseVC.previousScreen = PageName.Checkout
                            
                            navController.pushViewController(myPurchaseVC, animated: true)
                        }
                    }
                    webVC.ccPaymentFailed = {
                        Constant.showDialog("Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].name)", message: "Pembayaran gagal, silahkan coba beberapa saat lagi")
                        /*
                        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                        notifPageVC.isBackTwice = true
                        notifPageVC.previousScreen = PageName.Checkout
                        self.navigateToVC(notifPageVC)
                        */
                        
                        // back & push
                        if let count = self.navigationController?.viewControllers.count, count >= 2 {
                            let navController = self.navigationController!
                            var controllers = navController.viewControllers
                            controllers.removeLast()
                            
                            navController.setViewControllers(controllers, animated: false)
                            
                            let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
                            myPurchaseVC.previousScreen = PageName.Checkout
                            
                            navController.pushViewController(myPurchaseVC, animated: true)
                        }
                    }
                    let baseNavC = BaseNavigationController()
                    baseNavC.setViewControllers([webVC], animated: false)
                    self.present(baseNavC, animated: true, completion: nil)
                    
                } else if (self.paymentMethods[self.selectedPaymentIndex].provider == .kredivo) { // Kredivo
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let webVC = mainStoryboard.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
                    webVC.url = self.checkoutResult!["kredivo_redirect_url"].stringValue
                    webVC.titleString = "Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].name)"
                    webVC.creditCardMode = true
                    webVC.ccPaymentSucceed = {
                        self.navigateToOrderConfirmVC(true)
                    }
                    webVC.ccPaymentUnfinished = {
                        Constant.showDialog("Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].name)", message: "Pembayaran tertunda")
                        /*
                        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                        notifPageVC.isBackTwice = true
                        notifPageVC.previousScreen = PageName.Checkout
                        self.navigateToVC(notifPageVC)
                        */
                        
                        // back & push
                        if let count = self.navigationController?.viewControllers.count, count >= 2 {
                            let navController = self.navigationController!
                            var controllers = navController.viewControllers
                            controllers.removeLast()
                            
                            navController.setViewControllers(controllers, animated: false)
                            
                            let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
                            myPurchaseVC.previousScreen = PageName.Checkout
                            
                            navController.pushViewController(myPurchaseVC, animated: true)
                        }
                    }
                    webVC.ccPaymentFailed = {
                        Constant.showDialog("Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].name)", message: "Pembayaran gagal, silahkan coba beberapa saat lagi")
                        /*
                        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                        notifPageVC.isBackTwice = true
                        notifPageVC.previousScreen = PageName.Checkout
                        self.navigateToVC(notifPageVC)
                        */
                        
                        // back & push
                        if let count = self.navigationController?.viewControllers.count, count >= 2 {
                            let navController = self.navigationController!
                            var controllers = navController.viewControllers
                            controllers.removeLast()
                            
                            navController.setViewControllers(controllers, animated: false)
                            
                            let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
                            myPurchaseVC.previousScreen = PageName.Checkout
                            
                            navController.pushViewController(myPurchaseVC, animated: true)
                        }
                    }
                    let baseNavC = BaseNavigationController()
                    baseNavC.setViewControllers([webVC], animated: false)
                    self.present(baseNavC, animated: true, completion: nil)
                }
            }
            
            self.loadingPanel.isHidden = true
        }
    }
    
    // MARK: - Calculation -> isEqual
    
    func isEqual() -> Bool {
        var a = self.totalAmount
        
        for d in discountItems {
            a -= d.value
        }
        
        return (a == 0)
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
        self.isNeedScroll = false
        if self.cartResult.cartDetails.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: self.cartResult.cartDetails.count + 2), at: UITableViewScrollPosition.top, animated: true)
        }
    }
    
    func scrollToSummary() {
        if self.cartResult.cartDetails.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: self.cartResult.cartDetails.count + 5), at: UITableViewScrollPosition.top, animated: true)
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
        
        if (count < 5) {
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
                    
                    self.isNeedScroll = true
                }
                
                //self.tableView.reloadData()
                self.tableView.reloadSections(IndexSet.init(integer: self.cartResult.cartDetails.count + 2), with: .fade)
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
    func updateAddress() {
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
    func setupProfile() {
        let m = UIApplication.appDelegate.managedObjectContext
        
        if let userProfile = CDUserProfile.getOne() {
            userProfile.coordinate = self.selectedAddress.coordinate
            userProfile.coordinateAddress = self.selectedAddress.coordinateAddress
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
    
    // MARK: - Save New Address
    func insertNewAddress() {
        let provinceName = CDProvince.getProvinceNameWithID(self.selectedAddress.provinceId) ?? ""
        let regionName = CDRegion.getRegionNameWithID(self.selectedAddress.regionId) ?? ""
        
        let _ = request(APIMe.createAddress(addressName: "", recipientName: self.selectedAddress.name, phone: self.selectedAddress.phone, provinceId: self.selectedAddress.provinceId, provinceName: provinceName, regionId: self.selectedAddress.regionId, regionName: regionName, subdistrictId: self.selectedAddress.subdistrictId, subdistricName: self.selectedAddress.subdistrictName, address: self.selectedAddress.address, postalCode: self.selectedAddress.postalCode, coordinate: self.selectedAddress.coordinate, coordinateAddress: self.selectedAddress.coordinateAddress)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Alamat Baru")) {
                //print("New Address - Save!")
            }
        }
    }
    
    // MARK: - Navigation
    func navigateToOrderConfirmVC(_ isMidtrans: Bool) {
        var gTotal: Int64 = 0
        if let totalPrice = self.checkoutResult?["total_price"].int64 {
            gTotal += totalPrice
        }
        if !isMidtrans, let trfCode = self.checkoutResult?["banktransfer_digit"].int64 {
            gTotal += trfCode
        }
        if isMidtrans, let trfCharge = self.checkoutResult?["veritrans_charge_amount"].int64 {
            gTotal += trfCharge
        }
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let o = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
        
        o.orderID = (self.checkoutResult?["order_id"].string)!
        
        o.total = gTotal
        
        o.transactionId = (self.checkoutResult?["transaction_id"].string)!
        o.isBackTwice = true
        o.isShowBankBRI = self.isShowBankBRI
        o.targetBank = self.targetBank
        o.previousScreen = PageName.Checkout
        
        if (self.checkoutResult?["expire_time"].string) != nil {
            o.date = (self.checkoutResult?["expire_time"].string)! // expire_time not found
        }
        
        if (self.checkoutResult?["payment_expired_remaining"].int) != nil {
            o.remaining = (self.checkoutResult?["payment_expired_remaining"].int)! // payment_expired_remaining not found
        }
        
        var imgs : [URL] = []
        for c in self.cartResult.cartDetails {
            for p in c.products {
                imgs.append(p.displayPicts[0])
            }
        }
        o.images = imgs
        o.isFromCheckout = true
        
        if isMidtrans {
            o.isMidtrans = true
        }
        
        self.navigateToVC(o)
    }
    
    func navigateToVC(_ vc: UIViewController) {
        if (previousController != nil) {
            self.previousController!.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
