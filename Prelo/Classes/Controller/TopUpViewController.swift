//
//  TopUpViewController.swift
//  Prelo
//
//  Created by Prelo on 7/26/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Crashlytics
import Alamofire
import DropDown

// MARK: - Class
class TopUpViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var preloBalance = ""
    
    var isFirst = true
    var shouldBack = false
    var isLoading = false
    
    var isShowBankBRI = false
    var isIndomaret = false
    var isCimbClicks = false
    var isMandiriClickpay = false
    var isMandiriEcash = false
    var isDropdownMode = false
    
    // payment method -> bank etc
    var paymentMethods: Array<PaymentMethodItem>! = []
    var selectedPaymentIndex: Int = 0
    var targetBank: String = ""
    
    var tempIndexPath : IndexPath = []
    var reloadTabel = false
    var tempTextField = 0
    var tempTotalAmount = 0
    var random = arc4random_uniform(201) + 300
    var tempTopUpId = ""
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        self.setupPaymentAndDiscount()
        
        // Setup table
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        
        // title
        self.title = "Top Up"
        
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
        
        let Checkout2PaymentMethodCell = UINib(nibName: "Checkout2PaymentMethodCell", bundle: nil)
        tableView.register(Checkout2PaymentMethodCell, forCellReuseIdentifier: "Checkout2PaymentMethodCell")
        
        let Checkout2SplitCell = UINib(nibName: "Checkout2SplitCell", bundle: nil)
        tableView.register(Checkout2SplitCell, forCellReuseIdentifier: "Checkout2SplitCell")
        let Checkout2PaymentSummaryTotalCell = UINib(nibName: "Checkout2PaymentSummaryTotalCell", bundle: nil)
        tableView.register(Checkout2PaymentSummaryTotalCell, forCellReuseIdentifier: "Checkout2PaymentSummaryTotalCell")

    }

    func setupPaymentAndDiscount() {
        // reset
        self.paymentMethods = []
        self.isShowBankBRI = false
        self.isIndomaret = false
        self.isCimbClicks = false
        self.isMandiriClickpay = false
        self.isMandiriEcash = false
        self.isDropdownMode = false
        
        // reset selectedBank
        if !self.isDropdownMode {
            self.targetBank = ""
            
            // transfer bank
            var p = PaymentMethodItem()
            p.methodDetail = .bankTransfer
            self.paymentMethods.append(p)
        } else {
            // transfer bank
            var p = PaymentMethodItem()
            p.methodDetail = .bankTransfer
            self.paymentMethods.append(p)
        }
        
        if self.isIndomaret {
            var p = PaymentMethodItem()
            p.methodDetail = .indomaret
            self.paymentMethods.append(p)
        }
        
        if self.isCimbClicks {
            var p = PaymentMethodItem()
            p.methodDetail = .cimbClicks
            self.paymentMethods.append(p)
        }
        
        if self.isMandiriClickpay {
            var p = PaymentMethodItem()
            p.methodDetail = .mandiriClickpay
            self.paymentMethods.append(p)
        }
        
        if self.isMandiriEcash {
            var p = PaymentMethodItem()
            p.methodDetail = .mandiriEcash
            self.paymentMethods.append(p)
        }
        
        // reset if payment out of range
        if self.paymentMethods.count <= self.selectedPaymentIndex {
            self.selectedPaymentIndex = 0
        }
        
        var p = PaymentMethodItem()
        p.methodDetail = .permataVa
        self.paymentMethods.append(p)
        
        p.methodDetail = .indomaret
        self.paymentMethods.append(p)
        
        p.methodDetail = .cimbClicks
        self.paymentMethods.append(p)
        
        p.methodDetail = .mandiriClickpay
        self.paymentMethods.append(p)
        
        p.methodDetail = .mandiriEcash
        self.paymentMethods.append(p)
            
        print("payment method")
        print(self.paymentMethods.count)
        
    }
    
    
    // MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return 15
        return 10
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let idx = indexPath as IndexPath
        
//        if idx.row == 0 {
//            return 90
//        }
//        if idx.row == 1 {
//            return 2
//        }
//        if idx.row == 2 {
//            return 66
//        }
//        if idx.row == 3 {
//            return 2
//        }
//        if idx.row == 4 {
//            return 44
//        }
//        if idx.row == 5 {
//            return 80
//        }
//        if idx.row == 6 {
//            return 35
//        }
//        if idx.row == 7 {
//            return 35
//        }
//        if idx.row == 8 {
//            return 35
//        }
//        if idx.row == 9 {
//            return 35
//        }
//        if idx.row == 10 {
//            return 35
//        }
//        if idx.row == 11 {
//            return 44
//        }
//        if idx.row == 12 {
//            return 40
//        }
//        if idx.row == 13 {
//            return 40
//        }
//        if idx.row == 14 {
//            return 100
//        }
//        return 35
        
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
            return 80
        }
        if idx.row == 6 {
            return 44
        }
        if idx.row == 7 {
            return 40
        }
        if idx.row == 8 {
            return 40
        }
        if idx.row == 9 {
            return 100
        }
        return 35

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idx = indexPath as IndexPath
        if idx.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopUpHeaderCell") as! TopUpHeaderCell
            cell.adapt(preloBalance: self.preloBalance)
            return cell
        }
        if idx.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2SplitCell") as! Checkout2SplitCell
            return cell
        }
        if idx.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopUpAmountCell") as! TopUpAmountCell
            cell.txtJumlahUang.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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
            cell.adapt(self.targetBank, paymentMethodItem: self.paymentMethods[0], isSelected: selectedPaymentIndex == 0, parent: self)
            return cell
        }
//        if idx.row == 6 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
//            
//            cell.selectionStyle = .none
//            cell.clipsToBounds = true
//            
//            cell.adapt(self.paymentMethods[1], isSelected: selectedPaymentIndex == 1)
//            
//            return cell
//        }
//        if idx.row == 7 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
//            
//            cell.selectionStyle = .none
//            cell.clipsToBounds = true
//            
//            cell.adapt(self.paymentMethods[2], isSelected: selectedPaymentIndex == 2)
//            
//            
//            return cell
//        }
//        if idx.row == 8 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
//            
//            cell.selectionStyle = .none
//            cell.clipsToBounds = true
//            
//            cell.adapt(self.paymentMethods[3], isSelected: selectedPaymentIndex == 3)
//            
//            return cell
//        }
//        if idx.row == 9 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
//            
//            cell.selectionStyle = .none
//            cell.clipsToBounds = true
//            
//            cell.adapt(self.paymentMethods[4], isSelected: selectedPaymentIndex == 4)
//            
//            return cell
//        }
//        if idx.row == 10 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentCreditCardCell") as! Checkout2PaymentCreditCardCell
//            
//            cell.selectionStyle = .none
//            cell.clipsToBounds = true
//            
//            cell.adapt(self.paymentMethods[5], isSelected: selectedPaymentIndex == 5)
//            
//            return cell
//        }
        if idx.row == 6 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentMethodCell") as! Checkout2PaymentMethodCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            cell.adapt("RINGKASAN PEMBAYARAN")
            
            return cell
        }
        
        if idx.row == 7 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentSummaryCell") as! Checkout2PaymentSummaryCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
    
            tempIndexPath = idx
            
            cell.adapt("Total Belanja", amount: Int64(tempTextField))
            return cell
        }
        if idx.row == 8 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentSummaryCell") as! Checkout2PaymentSummaryCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            //cell.adapt("Total Belanja", amount: self.totalAmount)
            
            print("payment method nya")
            print(self.paymentMethods[self.selectedPaymentIndex].methodDetail)
            if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .bankTransfer {
                cell.adapt(self.paymentMethods[self.selectedPaymentIndex].methodDetail.chargeDescription, amount: Int64(random))
            } else if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .indomaret {
                cell.adapt(self.paymentMethods[self.selectedPaymentIndex].methodDetail.chargeDescription, amount: self.paymentMethods[self.selectedPaymentIndex].charge)
            } else if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .mandiriClickpay {
                cell.adapt(self.paymentMethods[self.selectedPaymentIndex].methodDetail.chargeDescription, amount: self.paymentMethods[self.selectedPaymentIndex].charge)
            } else if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .mandiriEcash {
                cell.adapt(self.paymentMethods[self.selectedPaymentIndex].methodDetail.chargeDescription, amount: self.paymentMethods[self.selectedPaymentIndex].charge)
            } else if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .cimbClicks {
                cell.adapt(self.paymentMethods[self.selectedPaymentIndex].methodDetail.chargeDescription, amount: self.paymentMethods[self.selectedPaymentIndex].charge)
            } else if self.paymentMethods[self.selectedPaymentIndex].methodDetail == .permataVa {
                cell.adapt(self.paymentMethods[self.selectedPaymentIndex].methodDetail.chargeDescription, amount: self.paymentMethods[self.selectedPaymentIndex].charge)
            } else {
                cell.adapt(self.paymentMethods[self.selectedPaymentIndex].methodDetail.chargeDescription, amount: self.paymentMethods[self.selectedPaymentIndex].charge)
            }
            
            return cell
        }
        if idx.row == 9 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Checkout2PaymentSummaryTotalCell") as! Checkout2PaymentSummaryTotalCell
            
            cell.selectionStyle = .none
            cell.clipsToBounds = true
            
            cell.adapt(Int64(tempTotalAmount) + Int64(random), paymentMethodDescription: "")
            
            cell.checkout = {
                if !self.validateField() {
                    return
                }
                
                let alertView = SCLAlertView(appearance: Constant.appearance)
                alertView.addButton("Lanjutkan") {
                    self.performCheckout()
                }
                alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {
                }
                alertView.showCustom("Perhatian", subTitle: "Kamu akan melakukan topUp sebesar \(self.tempTotalAmount) menggunakan \(self.paymentMethods[self.selectedPaymentIndex].methodDetail.title). Lanjutkan?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
            }

            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func validateField() -> Bool {
        if (self.tempTextField == 0){
            Constant.showDialog("Perhatian", message: "Mohon isi jumlah uang")
            return false
        }
        if (self.tempTextField < 10000){
            let ndx = IndexPath(row:2, section: 0)
            let cell2 = tableView.cellForRow(at:ndx) as! TopUpAmountCell
            cell2.lblNotification.textColor = UIColor.red
            return false
        }
        if self.targetBank == "" {
            Constant.showDialog("Perhatian", message: "Bank Tujuan Transfer harus diisi")
            return false
        }
        return true
    }
    
    func navigateToOrderConfirmVC(_ isMidtrans: Bool) {
        print("ada masuk navigasi ini")
        let o = Bundle.main.loadNibNamed(Tags.XibNameTopUpConfirm, owner: nil, options: nil)?.first as! TopUpConfirmViewController
        
        o.orderID = self.tempTopUpId
        o.total = Int64(self.tempTotalAmount) + Int64(self.random)
        
        o.isBackTwice = true
        o.isShowBankBRI = self.isShowBankBRI
        o.targetBank = self.targetBank
        o.previousScreen = PageName.BalanceMutation
        
        
        o.isFromCheckout = false
        
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
    
    func performCheckout() {
        
        // request api top up
        let _ = request(APIWallet.topUp(amount: self.tempTotalAmount, banktransfer_digit: Int(self.random), payment_method: "Bank Transfer", target_bank: self.targetBank)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Top Up Request")){
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                print("masuk kesini")
                print(json)
                print(data)
                print(data["_id"])
                self.tempTopUpId = data["_id"].string!
                // Prepare to navigate to next page
                if (self.paymentMethods[self.selectedPaymentIndex].methodDetail.provider == .native) { // bank
                    self.navigateToOrderConfirmVC(false)
                }
            }
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let idx = indexPath as IndexPath
        print("index yang di klik")
        print(idx)
        //if(idx.row >= 5 && idx.row <= 10){
        if(idx.row == 5){
            self.selectedPaymentIndex = idx.row - 5
            let sec = idx.section
            var reloadIdxs: [IndexPath] = [idx]
            reloadIdxs.append(IndexPath.init(row: 5, section: sec))
//            reloadIdxs.append(IndexPath.init(row: 6, section: sec))
//            reloadIdxs.append(IndexPath.init(row: 7, section: sec))
//            reloadIdxs.append(IndexPath.init(row: 8, section: sec))
//            reloadIdxs.append(IndexPath.init(row: 9, section: sec))
//            reloadIdxs.append(IndexPath.init(row: 10, section: sec))
            reloadIdxs.append(IndexPath.init(row: 8, section: sec))
            self.tableView.reloadRows(at: reloadIdxs, with: .fade)
        }

    }
    
    func textFieldDidChange(_ textField: UITextField) {
        let ndx = IndexPath(row:2, section: 0)
        let cell2 = tableView.cellForRow(at:ndx) as! TopUpAmountCell
        var txt = "0"
        txt = cell2.txtJumlahUang.text!
        if(txt.isEmpty){
            txt = "0"
        }
        tempTextField = Int(txt)!
        cell2.lblNotification.textColor = UIColor.black
        reloadTable()
    }
    func reloadTable(){
        let ndx = IndexPath(row:2, section: 0)
        let cell2 = tableView.cellForRow(at:ndx) as! TopUpAmountCell
        var txt = "0"
        txt = cell2.txtJumlahUang.text!
        if(txt.isEmpty){
            txt = "0"
        }
        tempTotalAmount = Int(txt)!
        print("ini txt nya")
        print(txt)
        
        let sec = tempIndexPath.section
        var reloadIdxs: [IndexPath] = [tempIndexPath]
        reloadIdxs.append(IndexPath.init(row: 7, section: sec))
        reloadIdxs.append(IndexPath.init(row: 9, section: sec))
        self.tableView.reloadRows(at: reloadIdxs, with: .fade)
        
        
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TopUpViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}

// MARK: - Class Cell
class TopUpHeaderCell: UITableViewCell {
    @IBOutlet weak var preloBalanceAmount: UILabel!
    
    func adapt(preloBalance : String){
        self.preloBalanceAmount.text = preloBalance
    }
    
}

class TopUpAmountCell: UITableViewCell {
    @IBOutlet weak var txtJumlahUang: UITextField!
    @IBOutlet weak var lblNotification: UILabel!
}

class TopUpMethodCell: UITableViewCell {
    
}
