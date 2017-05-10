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
    
    // Cart Results
    var cartResult: CartV2ResultItem!
    
    // Address -> from previous screen
    var selectedAddress = SelectedAddressItem()
    
    // payment method -> bank etc
    var paymentMethods: Array<PaymentMethodItem>!
    var selectedPaymentIndex: Int = 0
    var selectedBank: String = ""
    
    // discount item -> voucher etc
    var discountItems: Array<DiscountItem>!
    var isBalanceUsed: Bool = false
    var isVoucherUsed: Bool = false
    
    var preloBalanceUsed: Int = 0
    var preloBalanceTotal: Int = 0
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CartManager.sharedInstance.deleteAll()
        
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
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(Checkout2ShipViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
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
    }
    
    func setupPaymentAndDiscount() {
        
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
            return 1 + 2 + self.discountItems.count + 1
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
            } else if idx.row > 0 && idx.row <= 2 + self.discountItems.count {
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
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2VoucherCell") as! Checkout2VoucherCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                cell.adapt(self.cartResult.voucherSerial, isUsed: self.isVoucherUsed)
                
                return cell
            }
        } else if idx.section == 2 {
            if idx.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentMethodCell") as! Checkout2PaymentMethodCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                cell.adapt("RINGKASAN PEMBAYARAN")
                
                return cell
            } else if idx.row > 0 && idx.row <= 2 + self.discountItems.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentSummaryCell") as! Checkout2PaymentSummaryCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                if idx.row == 1 {
                    cell.adapt("Total Belanja", amount: self.cartResult.totalPrice)
                } else if idx.row == 2 {
                    cell.adapt(self.paymentMethods[self.selectedPaymentIndex].chargeDescription, amount: self.paymentMethods[self.selectedPaymentIndex].charge)
                } else {
                    cell.adapt(self.discountItems[idx.row-3].title, amount: self.discountItems[idx.row-3].value * -1)
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentSummaryTotalCell") as! Checkout2PaymentSummaryTotalCell
                
                cell.selectionStyle = .none
                cell.clipsToBounds = true
                
                var totalAmount = self.cartResult.totalPrice
                
                totalAmount += self.paymentMethods[self.selectedPaymentIndex].charge
                
                for d in self.discountItems {
                    totalAmount -= d.value
                }
                
                cell.adapt(totalAmount)
                
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // do nothing
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
        if let bn = bankName {
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
class Checkout2PreloBalanceCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var btnSwitch: UISwitch!
    @IBOutlet weak var txtInputPreloBalance: UITextField!
    @IBOutlet weak var lbDescription: UILabel!
    
    var preloBalanceUsed: ()->() = {}
    
    var parent: Checkout2PayViewController!
    
    func adapt(_ parent: Checkout2PayViewController, isUsed: Bool) {
        self.parent = parent
        
        self.txtInputPreloBalance.text = parent.preloBalanceUsed.string
        self.lbDescription.text = "Prelo Balance kamu" + parent.preloBalanceTotal.asPrice
        self.btnSwitch.isSelected = isUsed
        
        // delegate
        self.txtInputPreloBalance.delegate = self
    }
    
    static func heightFor(_ isUsed: Bool) -> CGFloat {
        if isUsed {
            return 111.0
        }
        return 51.0
    }
    
    @IBAction func btnSwitchPressed(_ sender: Any) {
        self.preloBalanceUsed()
    }
    
    // MARK: - Delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.txtInputPreloBalance {
            if let t = textField.text, t.int <= self.parent.preloBalanceTotal {
                self.parent.preloBalanceUsed = t.int
            }
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
            return 111.0
        }
        return 51.0
    }
    
    @IBAction func btnSwitchPressed(_ sender: Any) {
        self.voucherUsed()
    }
    
    @IBAction func btnApplyPressed(_ sender: Any) {
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
