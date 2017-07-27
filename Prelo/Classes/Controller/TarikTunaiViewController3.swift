//
//  TarikTunaiViewController2.swift
//  Prelo
//
//  Created by Djuned on 1/23/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

// MARK: - Pop up TT
enum PopUpTarikTunaiMode3 {
    case wjp
    case confirmation
}

class TarikTunaiViewController3: BaseViewController, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, PickerViewDelegate {
    
//    @IBOutlet weak var vwBankKamu: UIView!
//    @IBOutlet weak var txtNamaBank : UILabel!
//    @IBOutlet weak var txtCustomBank: UITextField!
//    @IBOutlet weak var txtNomerRekening : UITextField!
//    @IBOutlet weak var txtNamaRekening : UITextField!
    @IBOutlet weak var txtPassword : UITextField!
    @IBOutlet weak var txtJumlah : UITextField!
    @IBOutlet weak var lblDropdownBank: UILabel!
    @IBOutlet weak var lblDropdownHistory: UILabel!
    
    
    @IBOutlet weak var captionPreloBalance : UILabel!
    @IBOutlet weak var captionPreloWJP: UILabel!
    @IBOutlet weak var captionWithdrawAmount: UILabel!
    @IBOutlet weak var scrollView : UIScrollView!
    
    @IBOutlet weak var btnWithdraw : UIButton!
    
    @IBOutlet weak var consHeightHistory: NSLayoutConstraint! // 0 --> height table row + 36
    @IBOutlet weak var consHeightSeparatorHeaderTable: NSLayoutConstraint! // 0 --> 36
    @IBOutlet weak var tableViewHistory: UITableView!
    
    @IBOutlet weak var consHeightVwWJP: NSLayoutConstraint! // 178 --> [67 104 height table row + 36] 0
    @IBOutlet weak var consHeightSection1: NSLayoutConstraint! // 67 --> 0
    @IBOutlet weak var consHeightSection2: NSLayoutConstraint! // 104 --> 0
    @IBOutlet weak var consHeightSeparator3: NSLayoutConstraint! // 4 --> 0
    
    // for wjp -- pop up
    @IBOutlet weak var vwBackgroundOverlay: UIView! // hidden
    @IBOutlet weak var vwOverlayPopUp: UIView! // hidden
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var consCenteryPopUp: NSLayoutConstraint! // align center y --> 603 [window height] -> 0
    @IBOutlet weak var vwPopUp: UIView!
    
    // for confirmation -- pop up
    @IBOutlet weak var lblPUCBankName: UILabel!
    @IBOutlet weak var lblPUCRekeningNumber: UILabel!
    @IBOutlet weak var lblPUCRekeningName: UILabel!
    @IBOutlet weak var lblPUCAmount: UILabel!
    @IBOutlet weak var consCenteryPopUpConfirm: NSLayoutConstraint!
    @IBOutlet weak var vwPopUpConfirm: UIView!
    
    @IBOutlet weak var loadingPanel: UIView!
    
    var initHeight = CGFloat(0) // 67 + 104 + height table row + 36 + 4
    
    var viewSetupPassword : SetupPasswordPopUp? // TarikTunaiController.swift
    var viewShadow : UIView?
    var backEnabled : Bool = true
    
    var isShowBankBRI = false
    
    var historyWithdraws : Array<HistoryWithdrawItem> = []
    
    var isHistoryShown = false
    
    var isNeedReload = false
    
    // view rekening
    // udah punya rekening
    @IBOutlet weak var vwWithRekening: UIView!
    // buat dropdown
    @IBOutlet weak var lblDropDownRek: UILabel!
    @IBOutlet weak var btnDropDownRek: UIButton!
    
    // udah punya rekening pakai rekening yang udah ada
    @IBOutlet weak var vwOldRekening: UIView!
    @IBOutlet weak var lblBankOldRekening: UILabel!
    @IBOutlet weak var lblRekOldRekening: UILabel!
    @IBOutlet weak var lblNameOldRekening: UILabel!
    
    // udah punya rekening tapi mau buat lagi
    @IBOutlet weak var vwNewRekening: UIView!
    @IBOutlet weak var lblBankNewRekening: UILabel!
    @IBOutlet weak var txtRekNewRekening: UITextField!
    @IBOutlet weak var txtNameNewRekening: UITextField!
    @IBOutlet weak var txtBranchNewRekening: UITextField!
    @IBOutlet weak var lblCheckBoxNewRekening: UILabel!
    @IBOutlet weak var btnSimpanNewRekening: UIButton!
    @IBOutlet weak var vwCheckBoxNewRekeningUncheck: UIView!
    @IBOutlet weak var simpanRekeningUncheck: UILabel!
    
    // belum punya rekening
    @IBOutlet weak var vwWithoutRekening: UIView!
    @IBOutlet weak var lblBankWithoutRekening: UILabel!
    @IBOutlet weak var txtRekWithoutRekening: UITextField!
    @IBOutlet weak var txtNameWithoutRekening: UITextField!
    @IBOutlet weak var txtBranchWithoutRekening: UITextField!
    @IBOutlet weak var lblCheckBoxWithoutRekening: UILabel!
    
    
    var pickerDropDown = false
    
    
    var rekening: Array<RekeningItem> = []
    var rekeningUtama: RekeningItem? = nil
    
    @IBOutlet weak var consJumlahPTop: NSLayoutConstraint!
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        //        Mixpanel.trackPageVisit(PageName.Withdraw)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Withdraw)
        
        self.an_subscribeKeyboard(animations: { f, i , o in
            
            if (o)
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
            } else
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
            
        }, completion: nil)
        
        tableViewHistory.tableFooterView = UIView()
        tableViewHistory.delegate = self
        tableViewHistory.dataSource = self
        tableViewHistory.separatorStyle = .none
        
        if isNeedReload {
            print("masuk sini")
            initiateField()
            
            isNeedReload = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.an_unsubscribeKeyboard()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        //getRekening()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // fixer
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        self.title = "Tarik Uang"
        
        scrollView.delegate = self
        
        captionPreloBalance.text = "..."
//        captionPreloWJP.text = "..."
//        captionWithdrawAmount.text = "..."
        
        
        self.consHeightSeparatorHeaderTable.constant = 0
        self.consHeightHistory.constant = 0
        
        self.consHeightVwWJP.constant = 0
        self.consHeightSection1.constant = 0
        self.consHeightSection2.constant = 0
        
        self.consHeightSeparator3.constant = 0
        
//        txtNamaBank.textAlignment = NSTextAlignment.right
//        txtNomerRekening.textAlignment = NSTextAlignment.right
        
        // Munculkan pop up jika user belum mempunyai password
        // API Migrasi
        let _ = request(APIMe.checkPassword).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Tarik Uang")) {
                let json = JSON(resp.result.value!)
                let data : Bool? = json["_data"].bool
                if (data != nil && data == true) {
                    self.getBalance()
                } else {
                    let screenSize : CGRect = UIScreen.main.bounds
                    self.viewShadow = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height), backgroundColor: UIColor.black.withAlphaComponent(0.5))
                    if (self.viewShadow != nil) {
                        self.view.addSubview(self.viewShadow!)
                    }
                    self.viewSetupPassword = Bundle.main.loadNibNamed(Tags.XibNameSetupPasswordPopUp, owner: nil, options: nil)?.first as? SetupPasswordPopUp
                    if (self.viewSetupPassword != nil) {
                        self.viewSetupPassword!.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
                        self.viewSetupPassword!.bounds = CGRect(x: self.viewSetupPassword!.bounds.origin.x, y: self.viewSetupPassword!.bounds.origin.y, width: 280, height: 472)
                        self.view.addSubview(self.viewSetupPassword!)
                        if let u = CDUser.getOne() {
                            self.viewSetupPassword!.lblEmail.text = u.email
                        }
                        self.viewSetupPassword!.setPasswordDoneBlock = {
                            // gesture override
                            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                            
                            _ = self.navigationController?.popViewController(animated: true)
                        }
                        self.viewSetupPassword!.disableBackBlock = {
                            self.backEnabled = false
                        }
                    }
                }
            }
            
        }
        
        let TarikTunaiCell = UINib(nibName: "TarikTunaiCell3", bundle: nil)
        tableViewHistory.register(TarikTunaiCell, forCellReuseIdentifier: "TarikTunaiCell3")
        
        tableViewHistory.register(ProvinceCell.self, forCellReuseIdentifier: "cell")
        
        // swipe gesture for carbon (pop view)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        
        let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
        vwLeft.backgroundColor = UIColor.clear
        vwLeft.addGestureRecognizer(swipeRight)
        self.view.addSubview(vwLeft)
        self.view.bringSubview(toFront: vwLeft)
        
        initiateField()
    }
    
    func initiateField() {
        if(self.lblDropDownRek.text != "Label" && self.lblDropDownRek.text != "+ tambah rekening"){
            let arr2 = self.lblDropDownRek.text?.components(separatedBy: " / ")
            
            self.lblBankOldRekening.text = arr2?[0]
            self.lblRekOldRekening.text = arr2?[1]
            self.lblNameOldRekening.text = arr2?[2]
        }
        
        // kalau udah punya rekening
        if(rekening.count != 0){
            vwWithoutRekening.isHidden = true
            vwWithRekening.isHidden = false
            if (self.lblDropDownRek.text == "+ tambah rekening"){
                // kalau mau buat baru
                vwNewRekening.isHidden = false
                vwOldRekening.isHidden = true
                self.consJumlahPTop.constant = 5
                if (self.rekening.count == 5){
                    self.lblCheckBoxNewRekening.isHidden = true
                    self.btnSimpanNewRekening.isEnabled = false
                    self.vwCheckBoxNewRekeningUncheck.isHidden = true
                    self.simpanRekeningUncheck.isHidden = true
                    self.consJumlahPTop.constant = -25
                }
            } else {
                vwNewRekening.isHidden = true
                vwOldRekening.isHidden = false
                self.consJumlahPTop.constant = -140
                if(pickerDropDown == false){
                    lblDropDownRek.text =  (rekeningUtama?.target_bank)! + " / " + (rekeningUtama?.account_number)! + " / " + (rekeningUtama?.name)!
                }
            }
        } else {
            // kalau belum punya rekening
            
            vwWithoutRekening.isHidden = false
            vwWithRekening.isHidden = true
            self.consJumlahPTop.constant = -30
        }
    }
    
    // check box new rekening with rekening
    @IBAction func btnCheckBoxNewRekening(_ sender: Any) {
        if(self.lblCheckBoxNewRekening.isHidden){
           self.lblCheckBoxNewRekening.isHidden = false
        } else {
            self.lblCheckBoxNewRekening.isHidden = true
        }
    }
    
    // check box new rekening without rekening
    @IBAction func btnCheckBoxWithoutRekening(_ sender: Any) {
        if(self.lblCheckBoxWithoutRekening.isHidden){
            self.lblCheckBoxWithoutRekening.isHidden = false
        } else {
            self.lblCheckBoxWithoutRekening.isHidden = true
        }
    }
    

    var item = ""
    var itemDropdown : Array<String> = []
    var bankPickerItems : [String] = []
    @IBAction func btnPilihBankWithoutRekeningPressed(_ sender: Any) {
        // Retrieve bankPickerItems
        bankPickerItems = []
        let _ = request(APIReference.getAllBank()).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Bank")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"].arrayValue
                if (data.count > 0) {
                    for i in 0...data.count - 1 {
                        self.bankPickerItems.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)
                    }
                    
                    self.pickBank()
                }
            }
        }
    }
    @IBAction func btnPilihBankNewRekeningPressed(_ sender: Any) {
        // Retrieve bankPickerItems
        bankPickerItems = []
        let _ = request(APIReference.getAllBank()).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Bank")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"].arrayValue
                if (data.count > 0) {
                    for i in 0...data.count - 1 {
                        self.bankPickerItems.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)
                    }
                    
                    self.pickBank()
                }
            }
        }
    }
    
    func pickBank(){
        
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.bankMode = true
        p?.items = self.bankPickerItems
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.item = PickerViewController.RevealHiddenString(string)
        }
        p?.showSearch = true
        p?.title = "Bank"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    // drop down choose rekening or add new
    @IBAction func btnDropDownRekPressed(_ sender: Any) {
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        for i in 0 ... rekening.count-1{
            itemDropdown.append(rekening[i].target_bank + " / " + rekening[i].account_number + " / " + rekening[i].name)
        }
        if(rekening.count == 1){
            p?.items = [itemDropdown[0],"+ tambah rekening"]
        } else if (rekening.count == 2){
            p?.items = [itemDropdown[0], itemDropdown[1], "+ tambah rekening"]
        } else if (rekening.count == 3){
            p?.items = [itemDropdown[0], itemDropdown[1], itemDropdown[2], "+ tambah rekening"]
        } else if (rekening.count == 4){
            p?.items = [itemDropdown[0], itemDropdown[1], itemDropdown[2], itemDropdown[3], "+ tambah rekening"]
        } else if (rekening.count == 5){
            p?.items = [itemDropdown[0], itemDropdown[1], itemDropdown[2], itemDropdown[3], itemDropdown[4], "+ tambah rekening"]
        }
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.item = PickerViewController.RevealHiddenString(string)
        }
        p?.title = "Daftar rekening"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    func pickerDidSelect(_ item: String) {
        if(rekening.count == 0){
            self.lblBankWithoutRekening.text = PickerViewController.HideHiddenString(item)
        } else {
            isNeedReload = true
            var arrTemp : Array<String> = PickerViewController.HideHiddenString(item).components(separatedBy: " / ")
            if(arrTemp.count == 3){
                self.lblDropDownRek.text = PickerViewController.HideHiddenString(item)
                self.pickerDropDown = true
            } else {
                if(arrTemp[0] == "+ tambah rekening") {
                    isNeedReload = true
                    self.lblDropDownRek.text = PickerViewController.HideHiddenString(item)
                    self.pickerDropDown = true
                } else {
                    self.lblBankNewRekening.text = PickerViewController.HideHiddenString(item)
                }
            }
        }
    }
    
    func getRekening(){
        isNeedReload = true
        rekening = []
        //self.showLoading()
        // use API
        let _ = request(APIMe.getBankAccount).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Rekening List")) {
                if let x: AnyObject = resp.result.value as AnyObject? {
                    var json = JSON(x)
                    json = json["_data"]
                    //                    print("ini json rekening")
                    //                    print(json)
                    if let arr = json.array {
                        
                        if(arr.count != 0){
                            for i in 0 ..< arr.count {
                                //                                print("isi array")
                                //                                print(i)
                                //                                print(arr[i])
                                let rekening2 = RekeningItem.instance(arr[i])
                                print(arr[i]["target_bank"])
                                self.rekening.append(rekening2!)
                                if(arr[i]["is_default"]).boolValue{
                                    self.rekeningUtama = RekeningItem.instance(arr[i])!
                                    self.lblBankOldRekening.text = self.rekeningUtama?.target_bank
                                    self.lblRekOldRekening.text = self.rekeningUtama?.account_number
                                    self.lblNameOldRekening.text = self.rekeningUtama?.name
                                }
                            }
                        }
                    }
                    self.initiateField()
                    //self.hideLoading()
                }
                
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func getBalance() {
        self.showLoading()
        // API Migrasi
        let _ = request(APIWallet.getBalanceAndWithdraw).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Tarik Uang"))
            {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                if let m = data.string
                {
                    Constant.showDialog("Perhatian", message: m)
                }
                
                else {
                    if let i = data["total_prelo_balance"].int
                    {
//                        let f = NumberFormatter()
//                        f.numberStyle = NumberFormatter.Style.currency
//                        f.currencySymbol = ""
//                        f.locale = Locale(identifier: "id_ID")
//                        self.captionPreloBalance.text = f.string(from: NSNumber(value: i as Int))
                        self.captionPreloBalance.text = i.asPrice
                    }
                    
                    if let i = data["total_protected_balance"].int
                    {
                        self.captionPreloWJP.text = i.asPrice
                        
                        if (i != 0) {
                            self.consHeightSection1.constant = 67
                        }
                    }
                    
                    if let i = data["total_withdraw_amount"].int
                    {
                        self.captionWithdrawAmount.text = i.asPrice
                        
                        if (i != 0) {
                            self.consHeightSection2.constant = 104
                        }
                    }
                    
                    if let arr = data["withdraw_history"].array {
                        if arr.count > 0 {
                            for i in 0...arr.count-1 {
                                self.historyWithdraws.append(HistoryWithdrawItem.instance(arr[i])!)
                            }
                        }
                    }
                    
                    self.isShowBankBRI = false
                    if let abTest = data["ab_test"].array {
                        if abTest.contains("bri") {
                            self.isShowBankBRI = true
                        }
                    }
                    
                    self.consHeightVwWJP.constant = self.consHeightSection1.constant + self.consHeightSection2.constant
                    if  self.consHeightVwWJP.constant != 0 {
                        self.consHeightVwWJP.constant += 4
                        self.consHeightSeparator3.constant = 4
                    }
                    self.initHeight = self.consHeightVwWJP.constant
                    
                    self.getRekening()
                    
                    self.tableViewHistory.reloadData()
                    self.hideLoading()
                }
            } else
            {
                // gesture override
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                
                _ = self.navigationController?.popViewController(animated: true)
            }
            
        }
    }
    
    // MARK: - Table view functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (historyWithdraws.count > 0) {
            return historyWithdraws.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (historyWithdraws.count > 0) {
            let cell = tableViewHistory.dequeueReusableCell(withIdentifier: "TarikTunaiCell3") as! TarikTunaiCell3
        
            cell.backgroundColor = UIColor.colorWithColor(UIColor.gray, alpha: 0.2)
            cell.selectionStyle = .none
        
            let idx = (indexPath as NSIndexPath).row
            cell.lblTiket.text = historyWithdraws[idx].ticketNumber
            cell.lblTanggal.text = historyWithdraws[idx].createTime
            cell.lblPenarikan.text = historyWithdraws[idx].amount.asPrice
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            
            cell?.backgroundColor = UIColor.colorWithColor(UIColor.gray, alpha: 0.2)
            cell?.selectionStyle = .none
            
            cell?.textLabel!.text = "Belum ada riwayat"
            cell?.textLabel!.font = UIFont.systemFont(ofSize: 10)
            cell?.textLabel!.textColor = UIColor.darkGray
            cell?.textLabel!.textAlignment = .center
            
            return cell!
        }
    }
    
    // MARK: - Action
    
    @IBAction func withdraw()
    {
        if(rekening.count == 0){
            if (lblBankWithoutRekening.text == "Pilih Bank") {
                Constant.showDialog("Form belum lengkap", message: "Harap pilih Bank Kamu")
                return
            }
            if (txtRekWithoutRekening.text == "") {
                Constant.showDialog("Form belum lengkap", message: "Harap masukkan nomor rekening")
                return
            }
            if (txtNameWithoutRekening.text == "") {
                Constant.showDialog("Form belum lengkap", message: "Harap masukkan nama pemilik rekening")
                return
            }
            if (txtBranchWithoutRekening.text == "") {
                Constant.showDialog("Form belum lengkap", message: "Harap masukkan cabang tempat membuat rekening")
                return
            }
        } else if(lblDropDownRek.text == "+ tambah rekening"){
            if (lblBankNewRekening.text == "Pilih Bank") {
                Constant.showDialog("Form belum lengkap", message: "Harap pilih Bank Kamu")
                return
            }
            if (txtRekNewRekening.text == "") {
                Constant.showDialog("Form belum lengkap", message: "Harap masukkan nomor rekening")
                return
            }
            if (txtNameNewRekening.text == "") {
                Constant.showDialog("Form belum lengkap", message: "Harap masukkan nama pemilik rekening")
                return
            }
            if (txtBranchNewRekening.text == "") {
                Constant.showDialog("Form belum lengkap", message: "Harap masukkan cabang tempat membuat rekening")
                return
            }
        }

//        if (txtNamaBank.text == "Pilih Bank") {
//            Constant.showDialog("Form belum lengkap", message: "Harap pilih Bank Kamu")
//            return
//        }
//        if (txtNamaBank.text == "Lainnya" && (txtCustomBank.text == nil || txtCustomBank.text!.isEmpty)) {
//            Constant.showDialog("Form belum lengkap", message: "Harap isi Nama Bank")
//            return
//        }
//        if (txtNomerRekening.text == nil || txtNomerRekening.text!.isEmpty) {
//            Constant.showDialog("Form belum lengkap", message: "Harap isi Nomor Rekening")
//            return
//        }
//        if (txtNamaRekening.text == nil || txtNamaRekening.text!.isEmpty) {
//            Constant.showDialog("Form belum lengkap", message: "Harap isi Rekening Atas Nama")
//            return
//        }
        if (txtJumlah.text == nil || txtJumlah.text!.isEmpty) {
            Constant.showDialog("Form belum lengkap", message: "Harap isi Jumlah Penarikan")
            return
        }
        
        // cal popup
        // show pop up
        self.initPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.setupPopUp(.confirmation)
            self.displayPopUp(.confirmation)
            
            // if oke -> continueWithdraw
        })
    }
    
    func continueWithdraw() {
    
        let amount = txtJumlah.text == nil ? "" : txtJumlah.text!
        let i = (amount as NSString).integerValue
        
        /* Minimum transfer disabled
         if i < 50000
         {
         Constant.showDialog("Perhatian", message: "Jumlah penarikan minimum adalah Rp. 50.000")
         return
         }*/
        
        var namaBank = ""
        var norek = ""
        var namarek = ""
        
        if(rekening.count == 0){
            // belum punya rekening
            if let nb = lblBankWithoutRekening.text
            {
                namaBank = nb
            }
            norek = txtRekWithoutRekening.text == nil ? "" : txtRekWithoutRekening.text!
            namarek = txtNameWithoutRekening.text == nil ? "" : txtNameWithoutRekening.text!
            
        } else{
            if(lblDropDownRek.text == "+ tambah rekening"){
                
                if let nb = lblBankNewRekening.text
                {
                    namaBank = nb
                }
                norek = txtRekNewRekening.text == nil ? "" : txtRekNewRekening.text!
                namarek = txtNameNewRekening.text == nil ? "" : txtNameNewRekening.text!
                
            } else {
                if let nb = lblBankOldRekening.text
                {
                    namaBank = nb
                }
                norek = lblRekOldRekening.text == nil ? "" : lblRekOldRekening.text!
                namarek = lblNameOldRekening.text == nil ? "" : lblNameOldRekening.text!
            }
        }
        
        let pass = txtPassword.text == nil ? "" : txtPassword.text!
        
        self.btnWithdraw.isEnabled = false
        
        // API Migrasi
        let _ = request(APIWallet.withdraw(amount: amount, targetBank: namaBank, norek: norek, namarek: namarek, password: pass)).responseJSON {resp in
            self.btnWithdraw.isEnabled = true
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Submit Tarik Uang"))
            {
                let json = JSON(resp.result.value!)
                if let message = json["_message"].string
                {
                    Constant.showDialog("Perhatian", message: message)
                    
                    // Prelo Analytic - Request Withdraw Money
                    self.sendRequestWithdrwaMoney(namaBank, amount: i, isSuccess: false, reason: message)
                } else
                {
                    if(self.rekening.count == 0){
                        // belum punya rekening
                        
                        if(self.lblCheckBoxWithoutRekening.isHidden == false){
                            let _ = request(APIMe.addBankAccount(target_bank: self.lblBankWithoutRekening.text!, account_number: self.txtRekWithoutRekening.text!, name: self.txtNameWithoutRekening.text!, branch: self.txtBranchWithoutRekening.text!)).responseJSON { resp in
                                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Tambah Rekening")) {
                                    Constant.showDialog("Tambah Rekening", message: "Rekening berhasil ditambahkan")
                                    _ = self.navigationController?.popViewController(animated: true)
                                }
                            }
                            
                        }
                        
                    } else{
                        if(self.lblDropDownRek.text == "+ tambah rekening"){
                            if(self.lblCheckBoxNewRekening.isHidden == false){
                                let _ = request(APIMe.addBankAccount(target_bank: self.lblBankNewRekening.text!, account_number: self.txtRekNewRekening.text!, name: self.txtNameNewRekening.text!, branch: self.txtBranchNewRekening.text!)).responseJSON { resp in
                                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Tambah Rekening")) {
                                        Constant.showDialog("Tambah Rekening", message: "Rekening berhasil ditambahkan")
                                        _ = self.navigationController?.popViewController(animated: true)
                                    }
                                }
                                
                            }
                            
                            
                        } else {
                            
                        }
                    }
                    //                    self.getBalance()
                    let nDays = ("" /*self.txtNamaBank.text?.lowercased()*/ == "lainnya") ? 5 : 3
                    Constant.showDialog("Perhatian", message: "Permohonan tarik uang telah diterima. Proses paling lambat membutuhkan \(nDays)x24 jam hari kerja.")
                    
                    /*
                    // Mixpanel
                    let pt = [
                        "Destination Bank" : namaBank,
                        "Amount" : i
                        ] as [String : Any]
                    Mixpanel.trackEvent(MixpanelEvent.RequestedWithdrawMoney, properties: pt as [NSObject : AnyObject])
                    */
                    
                    // Prelo Analytic - Request Withdraw Money
                    self.sendRequestWithdrwaMoney(namaBank, amount: i, isSuccess: true, reason: "")
                    
                    // gesture override
                    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                    
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
            } else
            {
                let json = JSON(resp.result.value!)
                let reason = json["_message"].string!
                
                // Prelo Analytic - Request Withdraw Money
                self.sendRequestWithdrwaMoney(namaBank, amount: i, isSuccess: false, reason: reason)
                
                
            }
            
        }
    }
    
    @IBAction func selectBank()
    {
        var items = ["BCA", "Mandiri", "BNI"]
        
        if isShowBankBRI {
            items.append("BRI")
        }
        
        items.append("Lainnya")
        
        let bankCount = items.count
        let bankAlert = UIAlertController(title: "Pilih Bank", message: nil, preferredStyle: .actionSheet)
//        bankAlert.popoverPresentationController?.sourceView = self.vwBankKamu
        bankAlert.popoverPresentationController?.sourceRect = self.lblDropdownBank.frame
        for i in 0...bankCount - 1 {
            bankAlert.addAction(UIAlertAction(title: items[i], style: .default, handler: { act in
//                self.txtNamaBank.text = items[i]
                
                bankAlert.dismiss(animated: true, completion: nil)
            }))
        }
        bankAlert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in
            bankAlert.dismiss(animated: true, completion: nil)
        }))
        self.present(bankAlert, animated: true, completion: nil)
    }
    
    @IBAction func wjpPressed(_ sender: Any) {
        //Constant.showDialog("WJP", message: "coba")
        // show pop up
        self.initPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.setupPopUp(.wjp)
            self.displayPopUp(.wjp)
        })
    }
    
    @IBAction func historyPressed(_ sender: Any) {
        if !isHistoryShown {
            lblDropdownHistory.text = ""
            
            consHeightHistory.constant = 36 + (historyWithdraws.count > 0 ? CGFloat(historyWithdraws.count*30) : 30)
            consHeightSeparatorHeaderTable.constant = 36
            consHeightSection2.constant += consHeightHistory.constant
            consHeightVwWJP.constant += consHeightHistory.constant
        } else {
            lblDropdownHistory.text = ""
            
            consHeightHistory.constant = 0
            consHeightSeparatorHeaderTable.constant = 0
            consHeightSection2.constant = 104
            consHeightVwWJP.constant = initHeight
        }
        
        isHistoryShown = !isHistoryShown
    }
    
    @IBAction func resetPasswordPressed(_ sender: Any) {
        /*
        let x = UIAlertController(title: "Lupa Password", message: "Masukkan E-mail", preferredStyle: .alert)
        x.addTextField(configurationHandler: { textfield in
            textfield.placeholder = "E-mail"
        })
        let actionOK = UIAlertAction(title: "Kirim", style: .default, handler: { act in
            
            let txtField = x.textFields![0]
            self.callAPIForgotPassword((txtField.text)!)
        })
        
        let actionCancel = UIAlertAction(title: "Batal", style: .cancel, handler: { act in
            
        })
        
        x.addAction(actionOK)
        x.addAction(actionCancel)
        self.present(x, animated: true, completion: nil)
         */
        
        let alertView = SCLAlertView(appearance: Constant.appearance)
        let txt = alertView.addTextField("E-mail")
        alertView.addButton("Kirim") {
            self.callAPIForgotPassword((txt.text)!)
        }
        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
        alertView.showCustom("Lupa Password", subTitle: "Masukkan E-mail", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
        
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        if (self.backEnabled) {
            
            // gesture override
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Other
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    // MARK: - Swipe Navigation Override
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                //print("Swiped right")
                
                if (self.backEnabled) {
                    
                    // gesture override
                    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                    
                    _ = self.navigationController?.popViewController(animated: true)
                }
                
            default:
                break
            }
        }
    }
    
    // MARK: - forgot password
    func callAPIForgotPassword(_ email : String) {
        _ = request(APIAuth.forgotPassword(email: email)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Lupa Password")) {
                Constant.showDialog("Perhatian", message: "E-mail pemberitahuan sudah dikirim ke e-mail kamu :)")
            }
        }
    }
    
    // MARK: - Pop up
    func setupPopUp(_ popUpMode: PopUpTarikTunaiMode) {
        if popUpMode == .wjp {
        
        let wjpDetail = "Waktu Jaminan Prelo adalah waktu untuk para Pembeli memeriksa barang yang dia terima (terhitung sejak 3x24 jam setelah barang diterima oleh Pembeli).\n\nPembeli bisa melakukan pengembalian barang dan refund jika:\n- barang terbukti KW\n- ada cacat yang tidak diinformasikan\n- barang berbeda dari yang dipesan\n\nPenjual dapat melakukan tarik uang setelah Waktu Jaminan Prelo selesai."
        
        self.lblDescription.text = wjpDetail
        
        let mystr = wjpDetail
        let searchstr = "Waktu Jaminan Prelo|3x24 jam"
        let ranges: [NSRange]
        
        do {
            // Create the regular expression.
            let regex = try NSRegularExpression(pattern: searchstr, options: [])
            
            // Use the regular expression to get an array of NSTextCheckingResult.
            // Use map to extract the range from each result.
            ranges = regex.matches(in: mystr, options: [], range: NSMakeRange(0, mystr.characters.count)).map {$0.range}
        }
        catch {
            // There was a problem creating the regular expression
            ranges = []
        }
        
        let attString : NSMutableAttributedString = NSMutableAttributedString(string: wjpDetail)
        for i in 0...ranges.count-1 {
            attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)], range: ranges[i])
        }
        
        attString.addAttributes([NSFontAttributeName:UIFont.italicSystemFont(ofSize: 14)], range: (wjpDetail as NSString).range(of: "refund"))
        
        self.lblDescription.attributedText = attString
 
        /* coba pakai html tag */
        /*
        let attrStr = try! NSAttributedString(
            data: "<p style='font-size:14pt'><b>Waktu Jaminan Prelo</b> adalah waktu untuk para Pembeli memeriksa barang yang dia terima (terhitung sejak <b>3x24</b> jam setelah barang diterima oleh Pembeli).<br/><br/>Pembeli bisa melakukan pengembalian barang dan refund jika:<br/>- barang terbukti KW<br/>- ada cacat yang tidak diinformasikan<br/>- barang berbeda dari yang dipesan<br/><br/>Penjual dapat melakukan tarik uang setelah <b>Waktu Jaminan Prelo</b> selesai.</p>".data(using: String.Encoding.unicode, allowLossyConversion: true)!,
            options: [ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
            documentAttributes: nil)
        self.lblDescription.attributedText = attrStr
         */
            
        } else if popUpMode == .confirmation {
            print("masuk sini ga")
            if(rekening.count == 0){
                self.lblPUCBankName.text = self.lblBankWithoutRekening.text
                self.lblPUCRekeningNumber.text = self.txtRekWithoutRekening.text
                self.lblPUCRekeningName.text = self.txtNameWithoutRekening.text
            } else{
                if(lblDropDownRek.text == "+ tambah rekening"){
                    self.lblPUCBankName.text = self.lblBankNewRekening.text
                    self.lblPUCRekeningNumber.text = self.txtRekNewRekening.text
                    self.lblPUCRekeningName.text = self.txtNameNewRekening.text
                    
                } else {
                    self.lblPUCBankName.text = self.lblBankOldRekening.text
                    self.lblPUCRekeningNumber.text = self.lblRekOldRekening.text
                    self.lblPUCRekeningName.text = self.lblNameOldRekening.text
                }
            }
            
            if let j = self.txtJumlah.text {
                self.lblPUCAmount.text = j.int.asPrice
            }
        }
    }
    
    func initPopUp() {
        let path = UIBezierPath(roundedRect:vwPopUp.bounds,
                                byRoundingCorners:[.topRight, .topLeft],
                                cornerRadii: CGSize(width: 4, height:  4))
        
        let maskLayer = CAShapeLayer()
        
        maskLayer.path = path.cgPath
        vwPopUpConfirm.layer.mask = maskLayer
        
        // Transparent panel
        self.vwBackgroundOverlay.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        
        self.vwBackgroundOverlay.isHidden = false
        self.vwOverlayPopUp.isHidden = false
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        self.consCenteryPopUpConfirm.constant = screenHeight
    }
    
    func displayPopUp(_ popUpMode: PopUpTarikTunaiMode) {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        self.consCenteryPopUpConfirm.constant = screenHeight
        
        // 1
        let placeSelectionBar = { () -> () in
            if popUpMode == .wjp {
                // parent
                var curView = self.vwPopUp.frame
                curView.origin.y = (screenHeight - self.vwPopUp.frame.height) / 2
                self.vwPopUp.frame = curView
            } else if popUpMode == .confirmation {
                // parent
                var curView = self.vwPopUpConfirm.frame
                curView.origin.y = (screenHeight - self.vwPopUpConfirm.frame.height) / 2
                self.vwPopUpConfirm.frame = curView
            }
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        if popUpMode == .wjp {
            self.consCenteryPopUp.constant = 0
        } else if popUpMode == .confirmation {
            self.consCenteryPopUpConfirm.constant = 0
        }
    }
    
    func unDisplayPopUp() {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = 0
        self.consCenteryPopUpConfirm.constant = 0
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            
            var curView = self.vwPopUp.frame
            curView.origin.y = screenHeight + (screenHeight - self.vwPopUp.frame.height) / 2
            self.vwPopUp.frame = curView
            
            var cur2View = self.vwPopUpConfirm.frame
            cur2View.origin.y = screenHeight + (screenHeight - self.vwPopUpConfirm.frame.height) / 2
            self.vwPopUpConfirm.frame = cur2View
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = screenHeight
        self.consCenteryPopUpConfirm.constant = screenHeight
    }
    
    // wjp
    @IBAction func btnOkePressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
        })
    }

    // confirmation
    @IBAction func btnBatalPressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
        })
    }
    
    @IBAction func btnTarikPressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            
            self.continueWithdraw()
        })
    }
    
    func sendRequestWithdrwaMoney(_ namaBank: String, amount: Int, isSuccess: Bool, reason: String) {
        // Prelo Analytic - Request Withdraw Money
        let loginMethod = User.LoginMethod ?? ""
        var pdata = [
            "Destination Bank" : namaBank,
            "Amount" : amount,
            "Success" : isSuccess
        ] as [String : Any]
        
        if !isSuccess && reason != "" {
            pdata["Failed Reason"] = reason
        }
        
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.RequestWithdrawMoney, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
    }
}
// MARK: - class TarikTunaiCell

class TarikTunaiCell3: UITableViewCell {
    @IBOutlet weak var lblTiket: UILabel!
    @IBOutlet weak var lblTanggal: UILabel!
    @IBOutlet weak var lblPenarikan: UILabel!
    
}
