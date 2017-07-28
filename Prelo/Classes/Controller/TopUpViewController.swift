//
//  TopUpViewController.swift
//  Prelo
//
//  Created by Prelo on 7/26/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

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
class TopUpViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var isShowBankBRI = false
    var isCreditCard = false
    var isIndomaret = false
    var isMandiriClickpay = false
    var isMandiriEcash = false
    var isCimbClicks = false
    var isKredivo = false
    var isPermataVa = false
    var isDropdownMode = false
    
    // payment method -> bank etc
    var paymentMethods: Array<PaymentMethodItem>! = []
    var selectedPaymentIndex: Int = 0
    var targetBank: String = ""
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init
        _ = PaymentMethodHelper.sharedInstance
        
        let TopUpHeaderCell = UINib(nibName: "TopUpHeaderCell", bundle: nil)
        tableView.register(TopUpHeaderCell, forCellReuseIdentifier: "TopUpHeaderCell")
        
        let TopUpAmountCell = UINib(nibName: "TopUpAmountCell", bundle: nil)
        tableView.register(TopUpAmountCell, forCellReuseIdentifier: "TopUpAmountCell")
        
        let TopUpMethodCell = UINib(nibName: "TopUpMethodCell", bundle: nil)
        tableView.register(TopUpMethodCell, forCellReuseIdentifier: "TopUpMethodCell")
        
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
        let Checkout2SplitCell = UINib(nibName: "Checkout2SplitCell", bundle: nil)
        tableView.register(Checkout2SplitCell, forCellReuseIdentifier: "Checkout2SplitCell")

    }
    
    func setupPaymentAndDiscount() {
        // reset
        self.paymentMethods = []
        self.isShowBankBRI = false
        self.isCreditCard = false
        self.isIndomaret = false
        self.isMandiriClickpay = false
        self.isMandiriEcash = false
        self.isCimbClicks = false
        self.isKredivo = false
        self.isPermataVa = false
        self.isDropdownMode = false
        
    }
    
    // MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let idx = indexPath as IndexPath
        if idx.row == 0 {
            return 90
        }
        if idx.row == 1 {
            return 2
        }
        if idx.row == 2 {
            return 66
        }
        if idx.row == 3 {
            return 2
        }
        if idx.row == 4 {
            return 44
        }
        if idx.row == 5 {
            return 120
        }
        if idx.row == 6 {
            return 60
        }
        if idx.row == 7 {
            return 60
        }
        if idx.row == 8 {
            return 60
        }
        if idx.row == 9 {
            return 60
        }
        if idx.row == 10 {
            return 60
        }
        if idx.row == 11 {
            return 60
        }
        if idx.row == 12 {
            return 60
        }
        if idx.row == 13 {
            return 60
        }
        if idx.row == 14 {
            return 100
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idx = indexPath as IndexPath
        if idx.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopUpHeaderCell") as! TopUpHeaderCell
            return cell
        }
        if idx.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2SplitCell") as! Checkout2SplitCell
            return cell
        }
        if idx.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopUpAmountCell") as! TopUpAmountCell
            return cell
        }
        if idx.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2SplitCell") as! Checkout2SplitCell
            return cell
        }
        if idx.row == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopUpMethodCell") as! TopUpMethodCell
            return cell
        }
        if idx.row == 5 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentBankCell") as! Checkout2PaymentBankCell
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            return cell
        }
        if idx.row == 6 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            
            return cell
        }
        if idx.row == 7 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            
            return cell
        }
        if idx.row == 8 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            return cell
        }
        if idx.row == 9 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            
            return cell
        }
        if idx.row == 10 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            
            return cell
        }
        if idx.row == 11 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            
            return cell
        }
        if idx.row == 12 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            
            return cell
        }
        if idx.row == 13 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            
            return cell
        }
        if idx.row == 14 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentSummaryTotalCell") as! Checkout2PaymentSummaryTotalCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

// MARK: - Class Cell
class TopUpHeaderCell: UITableViewCell {
    @IBOutlet weak var preloBalanceAmount: UILabel!
    
}

class TopUpAmountCell: UITableViewCell {
    @IBOutlet weak var txtJumlahUang: UITextField!
    @IBOutlet weak var lblNotification: UILabel!
    
    
}

class TopUpMethodCell: UITableViewCell {
    
}
