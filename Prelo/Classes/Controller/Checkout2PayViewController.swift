//
//  Checkout2PayViewController.swift
//  Prelo
//
//  Created by Djuned on 4/12/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire
import DropDown

// MARK: - class
class Checkout2PayViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    // MARK: - Struct
    struct PaymentMethodItem {
        var name: String = ""
        var type: Int = 0
        var chargeDescription: String = ""
        var charge: Int = 0
    }
    
    struct DiscountItem {
        var title: String = ""
        var value: Int = 0
    }
    
    var isFirst = true
    var isShowBankBRI = false
    
    // Cart Results
    var cartResult: CartV2ResultItem!
    
    // Address -> from previous screen
    var selectedAddress = SelectedAddressItem()
    
    // payment method -> bank etc
    var paymentMethods: Array<PaymentMethodItem>! = []
    var selectedPaymentIndex: Int = 0
    var selectedBank: String = ""
    
    // discount item -> voucher etc
    var discountItems: Array<DiscountItem>! = []
    var isBalanceUsed: Bool = false
    var isVoucherUsed: Bool = false
    
    // bonus
    var isHalfBonusMode: Bool = false
    var customBonusPercent: Int = 0
    
    var preloBalanceUsed: Int = 0
    var preloBalanceTotal: Int = 0
    
    var totalAmount: Int = 0
    
    var voucherSerial: String?
    
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
        
        // title
        self.title = "Checkout"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
        self.paymentMethods = []
        
        // transfer bank
        var p = PaymentMethodItem()
        p.name = "Transfer Bank"
        p.charge = self.cartResult.banktransferDigit
        p.chargeDescription = "Kode Unik Transfer"
        self.paymentMethods.append(p)
        
        let ab = self.cartResult.abTest
        for _ab in ab {
            if (_ab == "half_bonus") {
                self.isHalfBonusMode = true
            } else if (_ab == "bri") {
                self.isShowBankBRI = true
            } else if (_ab == "cc") {
                var p = PaymentMethodItem()
                p.name = "Kartu Kredit"
                p.charge = (self.cartResult.veritransCharge?.creditCard)!
                p.chargeDescription = "Credit Card Charge"
                self.paymentMethods.append(p)
            } else if (_ab == "indomaret") {
                var p = PaymentMethodItem()
                p.name = "Indomaret"
                p.charge = (self.cartResult.veritransCharge?.indomaret)!
                p.chargeDescription = "Indomaret Charge"
                self.paymentMethods.append(p)
            } else if (_ab.range(of: "bonus:") != nil) {
                self.customBonusPercent = Int(_ab.components(separatedBy: "bonus:")[1])!
            } else if (_ab == "target_bank") {
//                self.isDropdownMode = true
            }
        }
        
        // reset if payment out of range
        if self.paymentMethods.count <= self.selectedPaymentIndex {
            self.selectedPaymentIndex = 0
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
            let disc = DiscountItem(title: "Referral Bonus", value: bonus)
            self.discountItems.append(disc)
        }
        
        // Update bonus discount if its more than half of subtotal
        if (self.discountItems.count > 0) {
            for i in 0...self.discountItems.count-1 {
                if (self.discountItems[i].title == "Referral Bonus") {
                    if (self.customBonusPercent > 0) {
                        if (self.discountItems[i].value > self.totalAmount * self.customBonusPercent / 100) {
                            self.discountItems[i].value = self.totalAmount * customBonusPercent / 100
                            // Show lblSend
//                            self.lblSend.text = "Maksimal Referral Bonus yang dapat digunakan adalah \(customBonusPercent)% dari subtotal transaksi"
//                            self.consHeightLblSend.constant = 31
                        }
                    } else if (isHalfBonusMode) {
                        if (discountItems[i].value > self.totalAmount / 2) {
                            discountItems[i].value = self.totalAmount / 2
                            // Show lblSend
//                            self.lblSend.text = "Maksimal Referral Bonus yang dapat digunakan adalah 50% dari subtotal transaksi"
//                            self.consHeightLblSend.constant = 31
                        }
                    } else {
                        if (discountItems[i].value > self.totalAmount) {
                            discountItems[i].value = self.totalAmount
                        }
                    }
                }
            }
        }

        
        if self.isFirst {
            self.setupTable()
            
            // setup balance
            var operan = 0
            for d in self.discountItems {
                operan += d.value
            }
            
            self.preloBalanceUsed = (self.totalAmount > self.preloBalanceTotal ? self.preloBalanceTotal - operan : self.totalAmount - operan)
            
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
                
                self.scrollToTop()
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
                return Checkout2PaymentSummaryTotalCell.heightFor()
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
                
                cell.adapt(self.selectedBank, isSelected: selectedPaymentIndex == idx.row-1)
                
                return cell
            } else { // cc, indomaret, etc
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                cell.adapt(self.paymentMethods[idx.row-1].name, isSelected: selectedPaymentIndex == idx.row-1)
                
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
                    
                    if self.isBalanceUsed && self.discountItems[0].title != "Prelo Balance" {
                        var operan = 0
                        
                        for d in self.discountItems {
                            operan += d.value
                        }
                        
                        self.preloBalanceUsed = (self.totalAmount > self.preloBalanceTotal ? self.preloBalanceTotal - operan : self.totalAmount - operan)
                        
                        var d = DiscountItem()
                        d.title = "Prelo Balance"
                        d.value = self.preloBalanceUsed
                        
                        self.discountItems.insert(d, at: 0)
                    } else {
                        self.preloBalanceUsed = 0
                        
                        if self.discountItems[0].title == "Prelo Balance" {
                            self.discountItems.remove(at: 0)
                        }
                    }
                    
                    self.tableView.reloadData()
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2VoucherCell") as! Checkout2VoucherCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                cell.adapt(self.voucherSerial, isUsed: self.isVoucherUsed)
                
                cell.voucherUsed = {
                    self.isVoucherUsed = !self.isVoucherUsed
                    
                    self.tableView.reloadData()
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
                
                if totalAmount != 0 {
                    totalAmount += self.paymentMethods[self.selectedPaymentIndex].charge
                }
                
                cell.adapt(totalAmount)
                
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
                
                self.tableView.reloadData()
            }
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
}

// MARK: - Class Checkout2PaymentMethodCell
class Checkout2PaymentMethodCell: UITableViewCell {
    @IBOutlet weak var lbTitle: UILabel!
    
    func adapt(_ title: String) { // Metode / Ringkasan Pembayaran
        self.lbTitle.text = title
    }
    
    static func heightFor() -> CGFloat {
        return 52.0
    }
}

// MARK: - Class Checkout2PaymentBankCell
class Checkout2PaymentBankCell: UITableViewCell {
    @IBOutlet weak var lbCheck: UILabel!
    @IBOutlet weak var lbBank: UILabel!
    @IBOutlet weak var lbDropdown: UILabel!
    
    func adapt(_ bankName: String?, isSelected: Bool) {
        if let bn = bankName, bn != "" {
            self.lbBank.text = bn
        } else {
            self.lbBank.text = "Pilih Bank Tujuan Transfer"
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
}

// MARK: - Class Checkout2PaymentCreditCardCell
class Checkout2PaymentCreditCardCell: UITableViewCell {
    @IBOutlet weak var lbCheck: UILabel!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbDescription: UILabel!
    
    // Kartu Kredit
    // Indomaret
    // Mandiri Clickpay
    // Kredivo
    
    func adapt(_ paymentMethodName: String, isSelected: Bool) {
        self.lbTitle.text = paymentMethodName
        self.lbDescription.text = "Pembayaran Aman dengan " + paymentMethodName
        
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
}

// MARK: - Class Checkout2BlackWhiteCell
class Checkout2BlackWhiteCell: UITableViewCell {
    static func heightFor() -> CGFloat {
        return 15.0
    }
}

// MARK: - Class Checkout2PreloBalanceCell
class Checkout2PreloBalanceCell: UITableViewCell {
    @IBOutlet weak var btnSwitch: UISwitch!
    @IBOutlet weak var txtInputPreloBalance: UITextField!
    @IBOutlet weak var lbDescription: UILabel!
    
    var preloBalanceUsed: ()->() = {}
    
    var parent: Checkout2PayViewController!
    
    func adapt(_ parent: Checkout2PayViewController, isUsed: Bool) {
        self.parent = parent
        
        self.txtInputPreloBalance.text = parent.preloBalanceUsed.string
        self.lbDescription.text = "Prelo Balance kamu " + parent.preloBalanceTotal.asPrice
        self.btnSwitch.isSelected = isUsed
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
        
        var maksimum = self.parent.totalAmount
        for d in self.parent.discountItems {
            if d.title != "Prelo Balance" {
                maksimum -= d.value
            }
        }
        
        if let t = self.txtInputPreloBalance.text, t.int <= self.parent.preloBalanceTotal && t.int <= maksimum && t.int > 0 {
            self.parent.preloBalanceUsed = t.int
            
            if self.parent.discountItems.count > 0 {
                for i in 0...self.parent.discountItems.count-1 {
                    if self.parent.discountItems[i].title == "Prelo Balance" {
                        self.parent.discountItems[i].value = self.parent.preloBalanceUsed
                    }
                }
            }
            
            self.parent.tableView.reloadData()
            self.parent.scrollToSummary()
            
        } else if self.txtInputPreloBalance.text == "" {
            // do nothing
            self.parent.scrollToSummary()
        } else {
//            Constant.showDialog("Prelo Balance", message: "Prelo Balance yang dapat digunakan mulai dari 1 hingga \(maksimum) rupiah")
            
            let alertView = SCLAlertView(appearance: Constant.appearance)
            alertView.addButton("Oke") { self.txtInputPreloBalance.becomeFirstResponder() }
            alertView.showCustom("Prelo Balance", subTitle: "Prelo Balance yang dapat digunakan mulai dari 1 hingga \(maksimum) rupiah", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
        }
    }
}

// MARK: - Class Checkout2VoucherCell
class Checkout2VoucherCell: UITableViewCell {
    @IBOutlet weak var btnSwitch: UISwitch!
    @IBOutlet weak var txtInputVoucher: UITextField!
    
    var voucherUsed: ()->() = {}
    var voucherApply: (String)->() = {_ in }
    
    func adapt(_ voucher: String?, isUsed: Bool) {
        self.txtInputVoucher.text = voucher
        self.btnSwitch.isSelected = isUsed
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
    
    func adapt(_ title: String, amount: Int) {
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
    
    var checkout: ()->() = {}
    
    func adapt(_ amount: Int) {
        self.lbTitle.text = "Total Pembayaran"
        self.lbAmount.text = amount.asPrice
    }
    
    static func heightFor() -> CGFloat {
        return 104.0
    }
    
    @IBAction func btnCheckoutPressed(_ sender: Any) {
        self.checkout()
    }
}
