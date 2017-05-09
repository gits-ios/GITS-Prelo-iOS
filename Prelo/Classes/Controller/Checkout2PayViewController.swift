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
class Checkout2PayViewController: BaseViewController {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
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
//        self.tableView.dataSource = self
//        self.tableView.delegate = self
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
class Checkout2PreloBalanceCell: UITableViewCell {
    @IBOutlet weak var btnSwitch: UISwitch!
    @IBOutlet weak var txtInputPreloBalance: UITextField!
    @IBOutlet weak var lbDescription: UILabel!
    
    var preloBalanceUsed: ()->() = {}
    
    func adapt(_ preloBalanceUsed: Int, preloBalanceTotal: Int, isUsed: Bool) {
        self.txtInputPreloBalance.text = preloBalanceUsed.string
        self.lbDescription.text = "Prelo Balance kamu" + preloBalanceTotal.asPrice
        self.btnSwitch.isSelected = isUsed
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
}

// MARK: - Class Checkout2VoucherCell
class Checkout2VoucherCell: UITableViewCell {
    @IBOutlet weak var btnSwitch: UISwitch!
    @IBOutlet weak var txtInputVoucher: UITextField!
    
    var voucherUsed: ()->() = {}
    var voucherApply: (String)->() = {_ in }
    
    func adapt(_ voucher: String, isUsed: Bool) {
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
