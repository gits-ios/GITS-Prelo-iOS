//
//  TarikTunaiViewController2.swift
//  Prelo
//
//  Created by Djuned on 1/23/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class TarikTunaiViewController2: BaseViewController, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var vwBankKamu: UIView!
    @IBOutlet weak var txtNamaBank : UILabel!
    @IBOutlet weak var txtCustomBank: UITextField!
    @IBOutlet weak var txtNomerRekening : UITextField!
    @IBOutlet weak var txtNamaRekening : UITextField!
    @IBOutlet weak var txtPassword : UITextField!
    @IBOutlet weak var txtJumlah : UITextField!
    @IBOutlet weak var lblDropdownBank: UILabel!
    @IBOutlet weak var lblDropdownHistory: UILabel!
    
    @IBOutlet weak var consHeightCustomBank: NSLayoutConstraint!
    
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
    
    var initHeight = CGFloat(0) // 67 + 104 + height table row + 36 + 4
    
    var viewSetupPassword : SetupPasswordPopUp? // TarikTunaiController.swift
    var viewShadow : UIView?
    var backEnabled : Bool = true
    
    var isShowBankBRI = false
    
    var historyWithdraws : Array<HistoryWithdrawItem> = []
    
    var isHistoryShown = false
    
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.an_unsubscribeKeyboard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Tarik Uang"
        
        scrollView.delegate = self
        
        captionPreloBalance.text = "..."
//        captionPreloWJP.text = "..."
//        captionWithdrawAmount.text = "..."
        
        self.consHeightCustomBank.constant = 0
        
        self.consHeightSeparatorHeaderTable.constant = 0
        self.consHeightHistory.constant = 0
        
        self.consHeightVwWJP.constant = 0
        self.consHeightSection1.constant = 0
        self.consHeightSection2.constant = 0
        
        self.consHeightSeparator3.constant = 0
        
        txtNamaBank.textAlignment = NSTextAlignment.right
        txtNomerRekening.textAlignment = NSTextAlignment.right
        
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
                            _ = self.navigationController?.popViewController(animated: true)
                        }
                        self.viewSetupPassword!.disableBackBlock = {
                            self.backEnabled = false
                        }
                    }
                }
            }
        }
        
        let TarikTunaiCell = UINib(nibName: "TarikTunai2Cell", bundle: nil)
        tableViewHistory.register(TarikTunaiCell, forCellReuseIdentifier: "TarikTunaiCell")
        
        tableViewHistory.register(ProvinceCell.self, forCellReuseIdentifier: "cell")
    }
    
    func getBalance() {
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
                    
                    self.tableViewHistory.reloadData()
                }
            } else
            {
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
            let cell = tableViewHistory.dequeueReusableCell(withIdentifier: "TarikTunaiCell") as! TarikTunaiCell
        
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
        if (txtNamaBank.text == "Pilih Bank") {
            Constant.showDialog("Form belum lengkap", message: "Harap pilih Bank Kamu")
            return
        }
        if (txtNamaBank.text == "Bank Lainnya" && (txtCustomBank.text == nil || txtCustomBank.text!.isEmpty)) {
            Constant.showDialog("Form belum lengkap", message: "Harap isi Nama Bank")
            return
        }
        if (txtNomerRekening.text == nil || txtNomerRekening.text!.isEmpty) {
            Constant.showDialog("Form belum lengkap", message: "Harap isi Nomor Rekening")
            return
        }
        if (txtNamaRekening.text == nil || txtNamaRekening.text!.isEmpty) {
            Constant.showDialog("Form belum lengkap", message: "Harap isi Rekening Atas Nama")
            return
        }
        if (txtJumlah.text == nil || txtJumlah.text!.isEmpty) {
            Constant.showDialog("Form belum lengkap", message: "Harap isi Jumlah Penarikan")
            return
        }
        
        let amount = txtJumlah.text == nil ? "" : txtJumlah.text!
        let i = (amount as NSString).integerValue
        
        /* Minimum transfer disabled
         if i < 50000
         {
         Constant.showDialog("Perhatian", message: "Jumlah penarikan minimum adalah Rp. 50.000")
         return
         }*/
        
        var namaBank = ""
        if let nb = txtNamaBank.text
        {
            namaBank = nb
        }
        
        namaBank = namaBank.replacingOccurrences(of: "Bank ", with: "")
        if (namaBank.lowercased() == "lainnya") {
            namaBank = txtCustomBank.text!
        }
        let norek = txtNomerRekening.text == nil ? "" : txtNomerRekening.text!
        let namarek = txtNamaRekening.text == nil ? "" : txtNamaRekening.text!
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
                } else
                {
                    //                    self.getBalance()
                    let nDays = (self.txtNamaBank.text?.lowercased() == "bank lainnya") ? 5 : 3
                    Constant.showDialog("Perhatian", message: "Permohonan tarik uang telah diterima. Proses paling lambat membutuhkan \(nDays)x24 jam hari kerja.")
                    
                    // Mixpanel
                    let pt = [
                        "Destination Bank" : namaBank,
                        "Amount" : i
                        ] as [String : Any]
                    Mixpanel.trackEvent(MixpanelEvent.RequestedWithdrawMoney, properties: pt as [NSObject : AnyObject])
                    
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else
            {
                
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
        bankAlert.popoverPresentationController?.sourceView = self.vwBankKamu
        bankAlert.popoverPresentationController?.sourceRect = self.lblDropdownBank.frame
        for i in 0...bankCount - 1 {
            bankAlert.addAction(UIAlertAction(title: items[i], style: .default, handler: { act in
                self.txtNamaBank.text = items[i]
                if (items[i] == "Lainnya") {
                    self.consHeightCustomBank.constant = 70
                } else {
                    self.consHeightCustomBank.constant = 0
                }
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
            self.setupPopUp()
            self.displayPopUp()
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
        
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        if (self.backEnabled) {
            _ = self.navigationController?.popViewController(animated: true)
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
    func setupPopUp() {
        
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
    }
    
    func initPopUp() {
        // Transparent panel
        self.vwBackgroundOverlay.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        
        self.vwBackgroundOverlay.isHidden = false
        self.vwOverlayPopUp.isHidden = false
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
    }
    
    func displayPopUp() {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = (screenHeight - self.vwPopUp.frame.height) / 2
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = 0
    }
    
    func unDisplayPopUp() {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = 0
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = screenHeight + (screenHeight - self.vwPopUp.frame.height) / 2
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = screenHeight
    }
    
    @IBAction func btnOkePressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
        })
    }

}
// MARK: - class TarikTunaiCell

class TarikTunaiCell: UITableViewCell {
    @IBOutlet weak var lblTiket: UILabel!
    @IBOutlet weak var lblTanggal: UILabel!
    @IBOutlet weak var lblPenarikan: UILabel!
    
}
