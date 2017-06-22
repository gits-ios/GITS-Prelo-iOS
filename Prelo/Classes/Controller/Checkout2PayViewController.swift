//
//  Checkout2PayViewController.swift
//  Prelo
//
//  Created by Djuned on 4/12/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Crashlytics
import Alamofire
import DropDown

enum paymentMethodProvider {
    case native
    case veritrans
    case kredivo
}

enum PaymentMethod {
    case bankTransfer
    case creditCard
    case indomaret
    case cimbClicks
    case mandiriClickpay
    case mandiriEcash
    case kredivo
    
    // code for api
    var value : String {
        switch self {
        case .bankTransfer : return "Bank Transfer"
        case .creditCard : return "Credit Card" // Kartu Kredit
        case .indomaret : return "Indomaret"
        case .cimbClicks : return "CIMB Clicks"
        case .mandiriClickpay : return "Mandiri Clickpay"
        case .mandiriEcash : return "Mandiri Ecash"
        case .kredivo : return "Kredivo"
        }
    }
    
    // name for display
    var title : String {
        switch self {
        case .bankTransfer : return "Transfer Bank"
        case .creditCard : return "Kartu Kredit"
        case .indomaret : return "Indomaret"
        case .cimbClicks : return "CIMB Clicks"
        case .mandiriClickpay : return "Mandiri Clickpay"
        case .mandiriEcash : return "Mandiri e-cash"
        case .kredivo : return "Kredivo"
        }
    }
    
    // provider for approach
    var provider : paymentMethodProvider {
        switch self {
        case .bankTransfer : return .native
        case .creditCard,
             .indomaret,
             .cimbClicks,
             .mandiriClickpay,
             .mandiriEcash : return .veritrans
        case .kredivo : return .kredivo
        }
    }
    
    // icon
    var icons : Array<String> {
        switch self {
        case .bankTransfer : return []
        case .creditCard : return  ["ic_checkout_master_card", "ic_checkout_visa"]
        case .indomaret : return  ["ic_checkout_indomaret"]
        case .cimbClicks : return  ["ic_checkout_cimb_clicks"]
        case .mandiriClickpay : return  ["ic_checkout_mandiri_clickpay"]
        case .mandiriEcash : return  ["ic_checkout_mandiri_e-cash"]
        case .kredivo : return  ["ic_checkout_kredivo"]
        }
    }
}

// MARK: - Struct
struct PaymentMethodItem {
    var methodDetail: PaymentMethod = .bankTransfer
    var type: Int = 0
    var chargeDescription: String = ""
    var charge: Int64 = 0
    var methodDescription: String = ""
}

struct DiscountItem {
    var title: String = ""
    var value: Int64 = 0
}

// MARK: - class
class Checkout2PayViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var isFirst = true
    var isShowBankBRI = false
    var isCreditCard = false
    var isMandiriClickpay = false
    var isMandiriEcash = false
    var isCimbClicks = false
    var isIndomaret = false
    var isKredivo = false
    var isDropdownMode = false
    
    // Cart Results
    var cartResult: CartV2ResultItem!
    
    // Address -> from previous screen
    var selectedAddress = SelectedAddressItem()
    
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
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        self.tableView.tableFooterView = UIView()
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.tableView.contentInset = inset
        
        self.tableView.separatorStyle = .none
        
        self.tableView.backgroundColor = UIColor(hexString: "#E8ECEE")
        
        // loading
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.7)
        
        /*
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(Checkout2ShipViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        */
        
        // swipe gesture for carbon (pop view)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        
        let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
        vwLeft.backgroundColor = UIColor.clear
        vwLeft.addGestureRecognizer(swipeRight)
        self.view.addSubview(vwLeft)
        self.view.bringSubview(toFront: vwLeft)
        
        // title
        self.title = "Checkout"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        // Handling keyboard animation
        self.an_subscribeKeyboard(
            animations: {r, t, o in
                
                if (o) {
                    self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
                
        }, completion: nil)
        
        // setup data
        self.setupPaymentAndDiscount()
    }
    
    func setupPaymentAndDiscount() {
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
        p.methodDetail = .bankTransfer
        p.charge = self.cartResult.banktransferDigit
        p.chargeDescription = "Kode Unik Transfer"
        p.methodDescription = ""
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
            p.methodDetail = .creditCard
            p.charge = creditCardCharge
            p.chargeDescription = PaymentMethod.creditCard.value + " Charge"
            p.methodDescription = (self.cartResult.veritransCharge?.creditCardText)!
            self.paymentMethods.append(p)
        }
        
        if self.isIndomaret {
            var p = PaymentMethodItem()
            p.methodDetail = .indomaret
            p.charge = indomaretCharge
            p.chargeDescription = PaymentMethod.indomaret.value + " Charge"
            p.methodDescription = (self.cartResult.veritransCharge?.indomaretText)!
            self.paymentMethods.append(p)
            
            if p.charge == 0 {
                self.isFreeze = true
            }
        }
        
        if self.isKredivo {
            var p = PaymentMethodItem()
            p.methodDetail = .kredivo
            p.charge = kredivoCharge
            p.chargeDescription = PaymentMethod.kredivo.value + " Charge"
            p.methodDescription = (self.cartResult.kredivoCharge?.text)!
            self.paymentMethods.append(p)
        }
        
        if self.isCimbClicks {
            var p = PaymentMethodItem()
            p.methodDetail = .cimbClicks
            p.charge = cimbClicksCharge
            p.chargeDescription = PaymentMethod.cimbClicks.value + " Charge"
            p.methodDescription = (self.cartResult.veritransCharge?.cimbClicksText)!
            self.paymentMethods.append(p)
        }
        
        if self.isMandiriClickpay {
            var p = PaymentMethodItem()
            p.methodDetail = .mandiriClickpay
            p.charge = mandiriClickpayCharge
            p.chargeDescription = PaymentMethod.mandiriClickpay.value + " Charge"
            p.methodDescription = (self.cartResult.veritransCharge?.mandiriClickpayText)!
            self.paymentMethods.append(p)
        }
        
        if self.isMandiriEcash {
            var p = PaymentMethodItem()
            p.methodDetail = .mandiriEcash
            p.charge = mandiriEcashCharge
            p.chargeDescription = PaymentMethod.mandiriEcash.value + " Charge"
            p.methodDescription = (self.cartResult.veritransCharge?.mandiriEcashText)!
            self.paymentMethods.append(p)
        }
        
        // reset if payment out of range
        if self.paymentMethods.count <= self.selectedPaymentIndex {
            self.selectedPaymentIndex = 0
        }
        
        if self.isFirst {
            self.setupTable()
            
            self.isFirst = false
        }
        
        self.tableView.reloadData()
        
        self.hideLoading()
    }
    
    func setupTable() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    // MARK: - Cart synch
    // Refresh data cart dan seluruh tampilan
    func synchCart() {
        self.showLoading()
        
        let p = CartManager.sharedInstance.getCartJsonString()
        let a = "{\"coordinate\": \"" + selectedAddress.coordinate + "\", \"address\": \"alamat\", \"province_id\": \"" + selectedAddress.provinceId + "\", \"region_id\": \"" + selectedAddress.regionId + "\", \"subdistrict_id\": \"" + selectedAddress.subdistrictId + "\", \"postal_code\": \"\"}"
        //print("cart_products : \(String(describing: p))")
        //print("shipping_address : \(a)")
        
        // API refresh cart
        let _ = request(APIV2Cart.refresh(cart: p, address: a, voucher: self.voucherSerial)).responseJSON { resp in
            if (PreloV2Endpoints.validate(true, dataResp: resp, reqAlias: "Keranjang Belanja")) {
                
                // Json
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                self.cartResult = CartV2ResultItem.instance(data)
                
                self.setupPaymentAndDiscount()
                
                //self.scrollToTop()
                self.hideLoading()
                
            } else {
                self.hideLoading()
                
            }
        }
    }
    
    // MARK: - UITableView Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        if cartResult != nil && cartResult.cartDetails.count > 0 {
            return 3
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1 + self.paymentMethods.count
        } else if section == 1 {
            return 1 + 2
        } else if section == 2 {
            return 1 + 1 + (self.paymentMethods.count > 0 && !self.isEqual() ? 1 : 0) + self.discountItems.count + 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let idx = indexPath as IndexPath
        if idx.section == 0 {
            if idx.row == 0 {
                return Checkout2PaymentMethodCell.heightFor()
            } else if idx.row == 1 {
                return Checkout2PaymentBankCell.heightFor(selectedPaymentIndex == idx.row-1)
            } else { // cc, indomaret, etc
                return Checkout2PaymentCreditCardCell.heightFor(selectedPaymentIndex == idx.row-1)
            }
        } else if idx.section == 1 {
            if idx.row == 0 {
                return Checkout2BlackWhiteCell.heightFor()
            } else if idx.row == 1 {
                return Checkout2PreloBalanceCell.heightFor(self.isBalanceUsed)
            } else {
                return Checkout2VoucherCell.heightFor(self.isVoucherUsed)
            }
        } else if idx.section == 2 {
            if idx.row == 0 {
                return Checkout2PaymentMethodCell.heightFor()
            } else if idx.row > 0 && idx.row <= 1 + (self.paymentMethods.count > 0 && !self.isEqual() ? 1 : 0) + self.discountItems.count {
                return Checkout2PaymentSummaryCell.heightFor()
            } else {
                return Checkout2PaymentSummaryTotalCell.heightFor(self.paymentMethods[self.selectedPaymentIndex].methodDescription)
            }
        }
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idx = indexPath as IndexPath
        if idx.section == 0 {
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
                
                cell.adapt(self.paymentMethods[idx.row-1].methodDetail, isSelected: selectedPaymentIndex == idx.row-1)
                
                return cell
            }
        } else if idx.section == 1 {
            if idx.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2BlackWhiteCell") as! Checkout2BlackWhiteCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
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
                    //self.tableView.reloadSections(IndexSet.init(arrayLiteral: idx.section, idx.section+1), with: .fade)
                    self.tableView.reloadRows(at: [idx], with: .fade)
                    
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
        } else if idx.section == 2 {
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
                    
                    if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .creditCard {
                        let creditCardCharge = (self.cartResult.veritransCharge?.creditCard)! + Int64((Double(priceAfterDiscounts) * (self.cartResult.veritransCharge?.creditCardMultiplyFactor)!) + 0.5)
                        
                        self.paymentMethods[self.selectedPaymentIndex].charge = creditCardCharge
                        
                    } else if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .indomaret {
                        var indomaretCharge = Int64((Double(priceAfterDiscounts) * (self.cartResult.veritransCharge?.indomaretMultiplyFactor)!) + 0.5)
                        if (indomaretCharge < (self.cartResult.veritransCharge?.indomaret)!) {
                            indomaretCharge = (self.cartResult.veritransCharge?.indomaret)!
                        }
                        
                        self.paymentMethods[self.selectedPaymentIndex].charge = indomaretCharge
                        
                    } else if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .mandiriClickpay {
                        let mandiriClickpayCharge = (self.cartResult.veritransCharge?.mandiriClickpay)!
                        
                        self.paymentMethods[self.selectedPaymentIndex].charge = mandiriClickpayCharge
                        
                    } else if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .mandiriEcash {
                        var mandiriEcashCharge = Int64((Double(priceAfterDiscounts) * (self.cartResult.veritransCharge?.mandiriEcashMultiplyFactor)!) + 0.5)
                        if (mandiriEcashCharge < (self.cartResult.veritransCharge?.mandiriEcash)!) {
                            mandiriEcashCharge = (self.cartResult.veritransCharge?.mandiriEcash)!
                        }
                        
                        self.paymentMethods[self.selectedPaymentIndex].charge = mandiriEcashCharge
                        
                    } else if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .cimbClicks {
                        let cimbClicksCharge = (self.cartResult.veritransCharge?.cimbClicks)!
                        
                        self.paymentMethods[self.selectedPaymentIndex].charge = cimbClicksCharge
                        
                    } else if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .kredivo {
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
                    
                    self.tableView.reloadData()
                    //self.tableView.reloadSections(IndexSet.init(integer: idx.section), with: .fade)
                    
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
                    
                    self.tableView.reloadData()
                    //self.tableView.reloadSections(IndexSet.init(integer: idx.section), with: .fade)
                    
                    totalAmount = 0
                }
                
                cell.adapt(totalAmount, paymentMethodDescription: self.paymentMethods[self.selectedPaymentIndex].methodDescription)
                
                cell.checkout = {
                    self.showLoading()
                    let alertView = SCLAlertView(appearance: Constant.appearance)
                    alertView.addButton("Lanjutkan") {
                        self.performCheckout()
                    }
                    alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {
                        self.hideLoading()
                    }
                    alertView.showCustom("Perhatian", subTitle: "Kamu akan melakukan transaksi sebesar \(totalAmount.asPrice) menggunakan \(self.paymentMethods[self.selectedPaymentIndex].methodDetail.title). Lanjutkan?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                }
                
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let idx = indexPath as IndexPath
        if idx.section == 0 {
            if idx.row == 0 {
                // do nothing
            } else {
                self.selectedPaymentIndex = idx.row-1
                
                //self.tableView.reloadData()
                self.tableView.reloadSections(IndexSet.init(arrayLiteral: idx.section, idx.section + 1, idx.section + 2), with: .fade)
            }
        }
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
        
        let _ = request(APIV2Cart.checkout(cart: p, address: a!, voucher: (self.isVoucherUsed ? self.voucherSerial! : ""), payment: self.paymentMethods[self.selectedPaymentIndex].methodDetail.value, usedPreloBalance: (self.isBalanceUsed ? self.preloBalanceUsed : 0), usedReferralBonus: self.preloBonusUsed, kodeTransfer: self.paymentMethods[0].charge, targetBank: (self.isDropdownMode ? self.targetBank : ""))).responseJSON { resp in
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
                if (self.paymentMethods[self.selectedPaymentIndex].methodDetail.provider == .native) { // bank
                    self.navigateToOrderConfirmVC(false)
                    
                } else if (self.paymentMethods[self.selectedPaymentIndex].methodDetail.provider == .veritrans) { // Credit card, indomaret
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let webVC = mainStoryboard.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
                    webVC.url = self.checkoutResult!["veritrans_redirect_url"].stringValue
                    webVC.titleString = "Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].methodDetail.title)"
                    webVC.creditCardMode = true
                    webVC.ccPaymentSucceed = {
                        self.navigateToOrderConfirmVC(true)
                    }
                    webVC.ccPaymentUnfinished = {
                        Constant.showDialog("Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].methodDetail.title)", message: "Pembayaran tertunda")
                        /*
                        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                        notifPageVC.isBackThreeTimes = true
                        notifPageVC.previousScreen = PageName.Checkout
                        self.navigateToVC(notifPageVC)
                        */
                        
                        // back2 & push
                        if let count = self.navigationController?.viewControllers.count, count >= 2 {
                            let navController = self.navigationController!
                            var controllers = navController.viewControllers
                            controllers.removeLast()
                            controllers.removeLast()
                            
                            navController.setViewControllers(controllers, animated: false)
                            
                            let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
                            myPurchaseVC.previousScreen = PageName.Checkout
                            
                            navController.pushViewController(myPurchaseVC, animated: true)
                        }
                    }
                    webVC.ccPaymentFailed = {
                        Constant.showDialog("Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].methodDetail.title)", message: "Pembayaran gagal, silahkan coba beberapa saat lagi")
                        /*
                        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                        notifPageVC.isBackThreeTimes = true
                        notifPageVC.previousScreen = PageName.Checkout
                        self.navigateToVC(notifPageVC)
                        */
                        
                        // back2 & push
                        if let count = self.navigationController?.viewControllers.count, count >= 2 {
                            let navController = self.navigationController!
                            var controllers = navController.viewControllers
                            controllers.removeLast()
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
                    
                } else if (self.paymentMethods[self.selectedPaymentIndex].methodDetail.provider == .kredivo) { // Kredivo
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let webVC = mainStoryboard.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
                    webVC.url = self.checkoutResult!["kredivo_redirect_url"].stringValue
                    webVC.titleString = "Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].methodDetail.title)"
                    webVC.creditCardMode = true
                    webVC.ccPaymentSucceed = {
                        self.navigateToOrderConfirmVC(true)
                    }
                    webVC.ccPaymentUnfinished = {
                        Constant.showDialog("Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].methodDetail.title)", message: "Pembayaran tertunda")
                        /*
                        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                        notifPageVC.isBackThreeTimes = true
                        notifPageVC.previousScreen = PageName.Checkout
                        self.navigateToVC(notifPageVC)
                        */
                        
                        // back2 & push
                        if let count = self.navigationController?.viewControllers.count, count >= 2 {
                            let navController = self.navigationController!
                            var controllers = navController.viewControllers
                            controllers.removeLast()
                            controllers.removeLast()
                            
                            navController.setViewControllers(controllers, animated: false)
                            
                            let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
                            myPurchaseVC.previousScreen = PageName.Checkout
                            
                            navController.pushViewController(myPurchaseVC, animated: true)
                        }
                    }
                    webVC.ccPaymentFailed = {
                        Constant.showDialog("Pembayaran \(self.paymentMethods[self.selectedPaymentIndex].methodDetail.title)", message: "Pembayaran gagal, silahkan coba beberapa saat lagi")
                        /*
                        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
                        notifPageVC.isBackThreeTimes = true
                        notifPageVC.previousScreen = PageName.Checkout
                        self.navigateToVC(notifPageVC)
                        */
                        
                        // back2 & push
                        if let count = self.navigationController?.viewControllers.count, count >= 2 {
                            let navController = self.navigationController!
                            var controllers = navController.viewControllers
                            controllers.removeLast()
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
    
    func scrollToSummary() {
        if self.cartResult.cartDetails.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: UITableViewScrollPosition.top, animated: true)
        }
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
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
        o.isBackThreeTimes = true
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
    
    override func backPressed(_ sender: UIBarButtonItem) {
        let alertView = SCLAlertView(appearance: Constant.appearance)
        
        alertView.addButton("Keluar") {
            
            // gesture override
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            
            //print(self.previousController.debugDescription)
            
            // back / pop twice
            if let count = self.navigationController?.viewControllers.count {
             _ = self.navigationController?.popToViewController((self.navigationController?.viewControllers[count-3])!, animated: true)
            }
        }
        
        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
        
        alertView.showCustom("Checkout", subTitle: "Kamu yakin mau keluar dari sini? Dengan meninggalkan halaman ini, pemesanan akan dibatalkan.", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    // MARK: - Swap override
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                //print("Swiped right")
                
                let alertView = SCLAlertView(appearance: Constant.appearance)
                
                alertView.addButton("Keluar") {
                    
                    // gesture override
                    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                    
                    print(self.previousController.debugDescription)
                    
                    // back / pop twice
                    if let count = self.navigationController?.viewControllers.count {
                        _ = self.navigationController?.popToViewController((self.navigationController?.viewControllers[count-3])!, animated: true)
                    }
                }
                
                alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
                
                alertView.showCustom("Checkout", subTitle: "Kamu yakin mau keluar dari sini? Dengan meninggalkan halaman ini, pemesanan akan dibatalkan.", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                
            default:
                break
            }
        }
    }

}

// MARK: - Class Checkout2PaymentMethodCell
class Checkout2PaymentMethodCell: UITableViewCell {
    @IBOutlet weak var lbTitle: UILabel!
    
    func adapt(_ title: String) { // Metode / Ringkasan Pembayaran
        self.lbTitle.text = title
    }
    
    static func heightFor() -> CGFloat {
        return 40.0
    }
}

// MARK: - Class Checkout2PaymentBankCell
class Checkout2PaymentBankCell: UITableViewCell {
    @IBOutlet weak var lbCheck: UILabel!
    @IBOutlet weak var lbBank: UILabel!
    @IBOutlet weak var lbDropdown: UILabel!
    
    // target_bank
    @IBOutlet weak var vw3Banks: UIView!
    @IBOutlet weak var vw4Banks: UIView!
    @IBOutlet weak var vwDropdown: BorderedView!
    
    let dropDown = DropDown()
    var selectedBankIndex: Int = -1
    
    var parent2: Checkout2PayViewController?
    var parent1: Checkout2ViewController?
    
    func adapt(_ bankName: String?, isSelected: Bool, parent: UIViewController) {
        if parent is Checkout2PayViewController {
            self.parent2 = parent as? Checkout2PayViewController
        } else if parent is Checkout2ViewController {
            self.parent1 = parent as? Checkout2ViewController
        }
        
        if let curParent = self.parent2 {
            if curParent.isDropdownMode {
                self.vwDropdown.isHidden = false
                
                if let bn = bankName, bn != "" {
                    self.lbBank.text = bn
                } else {
                    self.lbBank.text = "Pilih Bank Tujuan Transfer"
                }
                
                self.setupDropdownBank()
            } else {
                self.vwDropdown.isHidden = true
                self.selectedBankIndex = -1
                
                if curParent.isShowBankBRI {
                    self.vw3Banks.isHidden = true
                    self.vw4Banks.isHidden = false
                } else {
                    self.vw3Banks.isHidden = false
                    self.vw4Banks.isHidden = true
                }
            }
        } else if let curParent = self.parent1 {
            if curParent.isDropdownMode {
                self.vwDropdown.isHidden = false
                
                if let bn = bankName, bn != "" {
                    self.lbBank.text = bn
                } else {
                    self.lbBank.text = "Pilih Bank Tujuan Transfer"
                }
                
                self.setupDropdownBank()
            } else {
                self.vwDropdown.isHidden = true
                self.selectedBankIndex = -1
                
                if curParent.isShowBankBRI {
                    self.vw3Banks.isHidden = true
                    self.vw4Banks.isHidden = false
                } else {
                    self.vw3Banks.isHidden = false
                    self.vw4Banks.isHidden = true
                }
            }
        }
        
        if isSelected {
            self.lbCheck.isHidden = false
        } else {
            self.lbCheck.isHidden = true
        }
    }
    
    static func heightFor(_ isSelected: Bool) -> CGFloat {
        if isSelected {
            return 99.0
        }
        return 35.0
    }
    
    func setupDropdownBank() {
        //dropDown = DropDown()
        
        var items = ["BCA", "Mandiri", "BNI"]
        var icons = ["rsz_ic_bca@2x", "rsz_ic_mandiri@2x", "rsz_ic_bni@2x"]
        
        if let parent = self.parent2 {
            if parent.isShowBankBRI {
                items.append("BRI")
                icons.append("rsz_ic_bri@2x")
            }
        } else if let parent = self.parent1 {
            if parent.isShowBankBRI {
                items.append("BRI")
                icons.append("rsz_ic_bri@2x")
            }
        }
        
        // The list of items to display. Can be changed dynamically
        dropDown.dataSource = items
        
        // Action triggered on selection
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.lbBank.text = items[index]
            self.selectedBankIndex = index
            
            if let parent = self.parent2 {
                parent.targetBank = items[index]
            } else if let parent = self.parent1 {
                parent.targetBank = items[index]
            }
        }
        
        dropDown.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
            if index < items.count {
                cell.viewWithTag(999)?.removeFromSuperview()
                cell.viewWithTag(888)?.removeFromSuperview()
                
                let icon = UIImage(named: icons[index])
                let y = (cell.height - cell.optionLabel.height) / 2.0
                let rect = CGRect(x: 16, y: y, width: 80, height: cell.optionLabel.height)
                let img = UIImageView(frame: rect, image: icon!)
                img.afInflate()
                img.contentMode = .scaleAspectFit
                img.tag = 999
                
                // Setup your custom UI components
                cell.optionLabel.text = ""
                let rectOption = CGRect(x: 112, y: y, width: cell.width - (112 + 16), height: cell.optionLabel.height)
                
                let label = UILabel(frame: rectOption)
                label.text = items[index]
                label.font = cell.optionLabel.font
                label.tag = 888
                
                cell.addSubview(img)
                cell.addSubview(label)
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        
        //        dropDown.width = self.vwDropdown.width - 16
        
        dropDown.cellHeight = 60
        
        dropDown.anchorView = self.vwDropdown
        
        if selectedBankIndex > -1 {
            dropDown.selectRow(at: selectedBankIndex)
            lbBank.text = items[selectedBankIndex]
        }
        
        // Top of drop down will be below the anchorView
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)! + 4)
        
        // When drop down is displayed with `Direction.top`, it will be above the anchorView
        //dropDown.topOffset = CGPoint(x: 0, y:-(dropDown.anchorView?.plainView.bounds.height)! + 4)
        
        dropDown.direction = .bottom
    }
    
    @IBAction func btnChooseBankPressed(_ sender: Any) {
        dropDown.hide()
        dropDown.show()
    }
}

// MARK: - Class Checkout2PaymentCreditCardCell
class Checkout2PaymentCreditCardCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var lbCheck: UILabel!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbDescription: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var icons: Array<String> = []
    
    var isNeedSetup = true
    
    // Kartu Kredit
    // Indomaret
    // Mandiri Clickpay
    // Kredivo
    
    func adapt(_ paymentMethod: PaymentMethod, isSelected: Bool) {
        self.lbTitle.text = paymentMethod.title
        self.lbDescription.text = "Pembayaran Aman dengan " + paymentMethod.title
        
        self.icons = paymentMethod.icons
        
        if self.isNeedSetup {
            self.isNeedSetup = false
            
            self.setupCollection()
        }
        
        self.collectionView.reloadData()
        
        if isSelected {
            self.lbCheck.isHidden = false
        } else {
            self.lbCheck.isHidden = true
        }
    }
    
    static func heightFor(_ isSelected: Bool) -> CGFloat {
        if isSelected {
            return 62.0
        }
        return 35.0
    }
    
    func setupCollection() {
        // Set collection view
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcProgressCell")
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundView = UIView(frame: self.collectionView.bounds)
        self.collectionView.backgroundColor = UIColor.white
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        //layout.itemSize = CGSize(width: 38, height: 38)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        self.collectionView.collectionViewLayout = layout
        
        self.collectionView.isScrollEnabled = false
    }
    
    // MARK: - CollectionView delegate functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.icons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "collcProgressCell", for: indexPath)
        
        let icon = self.icons[indexPath.row]
        let img = UIImage(named: icon)
        let height = CGFloat(21.0)
        let width = (img?.size.width)! * height / (img?.size.height)!
        
        print(icon)
        print(width)
        print(height)
        
        let imgVw = UIImageView()
        imgVw.height = height
        imgVw.width = width
        
        imgVw.image = img
        imgVw.tag = 999
        
        cell.viewWithTag(999)?.removeFromSuperview()
        cell.addSubview(imgVw)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        let icon = self.icons[indexPath.row]
        let img = UIImage(named: icon)
        let height = CGFloat(21.0)
        let width = (img?.size.width)! * height / (img?.size.height)!
        
        return CGSize(width: width, height: height)
    }
}

// MARK: - Class Checkout2BlackWhiteCell
class Checkout2BlackWhiteCell: UITableViewCell {
    @IBOutlet weak var vwLine1px: UIView!
    @IBOutlet weak var consHeightVwLine1px: NSLayoutConstraint!
    
    static func heightFor() -> CGFloat {
        return 9.0
    }
}

// MARK: - Class Checkout2PreloBalanceCell
class Checkout2PreloBalanceCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var btnSwitch: UISwitch!
    @IBOutlet weak var txtInputPreloBalance: UITextField!
    @IBOutlet weak var lbDescription: UILabel!
    @IBOutlet weak var btnApply: UIButton!
    @IBOutlet weak var consWidthBtnApply: NSLayoutConstraint! // 64
    @IBOutlet weak var consLeadingBtnApply: NSLayoutConstraint! // 8
    
    var preloBalanceUsed: ()->() = {}
    
    var parent2: Checkout2PayViewController?
    var parent1: Checkout2ViewController?
    
    func adapt(_ parent: UIViewController, isUsed: Bool) {
        if parent is Checkout2PayViewController {
            self.parent2 = parent as? Checkout2PayViewController
        } else if parent is Checkout2ViewController {
            self.parent1 = parent as? Checkout2ViewController
        }
        
        if let curParent = parent2 {
            self.txtInputPreloBalance.text = curParent.preloBalanceUsed.asPrice
            self.lbDescription.text = "Prelo Balance kamu " + curParent.preloBalanceTotal.asPrice
            self.btnSwitch.isOn = isUsed
            
            self.txtInputPreloBalance.delegate = self
            self.consWidthBtnApply.constant = 0
            self.consLeadingBtnApply.constant = 0
            
            /*if isUsed {
                curParent.scrollToSummary()
            }*/
        } else if let curParent = parent1 {
            self.txtInputPreloBalance.text = curParent.preloBalanceUsed.asPrice
            self.lbDescription.text = "Prelo Balance kamu " + curParent.preloBalanceTotal.asPrice
            self.btnSwitch.isOn = isUsed
            
            self.txtInputPreloBalance.delegate = self
            self.consWidthBtnApply.constant = 0
            self.consLeadingBtnApply.constant = 0
            
            /*if isUsed {
                curParent.scrollToSummary()
            }*/
        }
    }
    
    static func heightFor(_ isUsed: Bool) -> CGFloat {
        if isUsed {
            return 115.0
        }
        return 51.0
    }
    
    @IBAction func btnSwitchPressed(_ sender: Any) {
        self.preloBalanceUsed()
    }
    
    @IBAction func btnApplyPressed(_ sender: Any) {
        self.txtInputPreloBalance.resignFirstResponder()
        
        if let parent = parent2 {
            var maksimum = parent.totalAmount
            for d in parent.discountItems {
                if d.title != "Prelo Balance" {
                    maksimum -= d.value
                }
            }
            
            if maksimum > parent.preloBalanceTotal {
                maksimum = parent.preloBalanceTotal
            }
            
            if let t = self.txtInputPreloBalance.text {
                let _t = t.replacingOccurrences(of: ".", with: "").replace("Rp", template: "")
                if _t.int64 <= maksimum && _t.int64 >= 0 {
                    
                    parent.preloBalanceUsed = _t.int64
                    
                    if parent.discountItems.count > 0 {
                        for i in 0...parent.discountItems.count-1 {
                            if parent.discountItems[i].title == "Prelo Balance" {
                                parent.discountItems[i].value = parent.preloBalanceUsed
                            }
                        }
                    }
                    
                    parent.tableView.reloadData()
                    parent.scrollToSummary()
                } else {
                    let alertView = SCLAlertView(appearance: Constant.appearance)
                    alertView.addButton("Oke") { self.txtInputPreloBalance.becomeFirstResponder() }
                    alertView.showCustom("Prelo Balance", subTitle: "Prelo Balance yang dapat digunakan mulai dari Rp0 hingga \(maksimum.asPrice)", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                }
            } else {
                //Constant.showDialog("Prelo Balance", message: "Prelo Balance yang dapat digunakan mulai dari 1 hingga \(maksimum) rupiah")
                
                let alertView = SCLAlertView(appearance: Constant.appearance)
                alertView.addButton("Oke") { self.txtInputPreloBalance.becomeFirstResponder() }
                alertView.showCustom("Prelo Balance", subTitle: "Prelo Balance yang dapat digunakan mulai dari 1 hingga \(maksimum) rupiah", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
            }
        } else if let parent = parent1 {
            var maksimum = parent.totalAmount
            for d in parent.discountItems {
                if d.title != "Prelo Balance" {
                    maksimum -= d.value
                }
            }
            
            if maksimum > parent.preloBalanceTotal {
                maksimum = parent.preloBalanceTotal
            }
            
            if let t = self.txtInputPreloBalance.text {
                let _t = t.replacingOccurrences(of: ".", with: "").replace("Rp", template: "")
                if _t.int64 <= maksimum && _t.int64 >= 0 {
                    
                    parent.preloBalanceUsed = _t.int64
                    
                    if parent.discountItems.count > 0 {
                        for i in 0...parent.discountItems.count-1 {
                            if parent.discountItems[i].title == "Prelo Balance" {
                                parent.discountItems[i].value = parent.preloBalanceUsed
                            }
                        }
                    }
                    
                    parent.tableView.reloadData()
                    parent.scrollToSummary()
                } else {
                    let alertView = SCLAlertView(appearance: Constant.appearance)
                    alertView.addButton("Oke") { self.txtInputPreloBalance.becomeFirstResponder() }
                    alertView.showCustom("Prelo Balance", subTitle: "Prelo Balance yang dapat digunakan mulai dari Rp0 hingga \(maksimum.asPrice)", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                }
            } else {
                //Constant.showDialog("Prelo Balance", message: "Prelo Balance yang dapat digunakan mulai dari 1 hingga \(maksimum) rupiah")
                
                let alertView = SCLAlertView(appearance: Constant.appearance)
                alertView.addButton("Oke") { self.txtInputPreloBalance.becomeFirstResponder() }
                alertView.showCustom("Prelo Balance", subTitle: "Prelo Balance yang dapat digunakan mulai dari 1 hingga \(maksimum) rupiah", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
            }
        }
    }
    
    // MARK: - delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.3, delay: 0,options: .curveLinear, animations: {
            self.consLeadingBtnApply.constant = 8
            self.btnApply.frame = CGRect(x: self.btnApply.x - 64, y: self.btnApply.y, width: self.btnApply.frame.width, height: self.btnApply.frame.height)
            
        },completion: { finish in
            self.consWidthBtnApply.constant = 64
        })
        
        if let text = self.txtInputPreloBalance.text {
            let _text = text.replacingOccurrences(of: ".", with: "").replace("Rp", template: "")
            self.txtInputPreloBalance.text = _text
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.consLeadingBtnApply.constant = 0
        self.consWidthBtnApply.constant = 0
        
        if let text = self.txtInputPreloBalance.text {
            if let parent = parent2 {
                let _text = (text != "" ? text.int64.asPrice : parent.preloBalanceUsed.asPrice)
                self.txtInputPreloBalance.text = _text
            } else if let parent = parent1 {
                let _text = (text != "" ? text.int64.asPrice : parent.preloBalanceUsed.asPrice)
                self.txtInputPreloBalance.text = _text
            }
        }
    }
}

// MARK: - Class Checkout2VoucherCell
class Checkout2VoucherCell: UITableViewCell {
    @IBOutlet weak var btnSwitch: UISwitch!
    @IBOutlet weak var txtInputVoucher: UITextField!
    @IBOutlet weak var btnApply: UIButton!
    
    var voucherUsed: ()->() = {}
    var voucherApply: (String)->() = {_ in }
    
    func adapt(_ voucher: String?, isUsed: Bool, isFreeze: Bool) {
        self.txtInputVoucher.text = voucher
        self.btnSwitch.isOn = isUsed
        
        /*
        self.btnSwitch.isEnabled = !isFreeze
        self.txtInputVoucher.isEnabled = !isFreeze
        self.btnApply.isEnabled = !isFreeze
        */
        
        if isFreeze {
            /*
            let view = UIView(frame: self.btnApply.bounds)
            view.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.4)
            view.tag = 999
            
            self.btnApply.viewWithTag(999)?.removeFromSuperview()
            self.btnApply.addSubview(view)
             */
            
            let view = UIView(frame: self.bounds)
            view.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.4)
            view.tag = 999
            
            self.viewWithTag(999)?.removeFromSuperview()
            self.addSubview(view)
        }
    }
    
    static func heightFor(_ isUsed: Bool) -> CGFloat {
        if isUsed {
            return 115.0
        }
        return 51.0
    }
    
    @IBAction func btnSwitchPressed(_ sender: Any) {
        self.voucherUsed()
    }
    
    @IBAction func btnApplyPressed(_ sender: Any) {
        self.txtInputVoucher.resignFirstResponder()
        
        if (self.txtInputVoucher.text != "") {
            self.voucherApply(self.txtInputVoucher.text!)
        }
    }
}

// MARK: - Class Checkout2PaymentSummaryCell
class Checkout2PaymentSummaryCell: UITableViewCell {
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbAmount: UILabel!
    
    func adapt(_ title: String, amount: Int64) {
        self.lbTitle.text = title
        self.lbAmount.text = amount.asPrice
    }
    
    static func heightFor() -> CGFloat {
        return 24.0
    }
}

// MARK: - Class Checkout2PaymentSummaryTotalCell
class Checkout2PaymentSummaryTotalCell: UITableViewCell {
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbAmount: UILabel!
    @IBOutlet weak var consTopBtnCheckout: NSLayoutConstraint! // 8 -> 37
    @IBOutlet weak var lbCharge: UILabel! // hidden -> show
    
    var checkout: ()->() = {}
    
    func adapt(_ amount: Int64, paymentMethodDescription: String) {
        self.lbTitle.text = "Total Pembayaran"
        self.lbAmount.text = amount.asPrice
        
        self.lbCharge.text = paymentMethodDescription
        
        if paymentMethodDescription != "" {
            self.lbCharge.isHidden = false
            self.consTopBtnCheckout.constant = 37
        } else {
            self.lbCharge.isHidden = true
            self.consTopBtnCheckout.constant = 8
        }
    }
    
    static func heightFor(_ paymentMethodDescription: String) -> CGFloat {
        if paymentMethodDescription != "" {
            return 117
        }
        return 88.0
    }
    
    @IBAction func btnCheckoutPressed(_ sender: Any) {
        self.checkout()
    }
}
