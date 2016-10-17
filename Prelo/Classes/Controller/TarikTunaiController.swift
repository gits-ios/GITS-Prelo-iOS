//
//  TarikTunaiController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class TarikTunaiController: BaseViewController, UIScrollViewDelegate
{
    
    @IBOutlet var txtNamaBank : UILabel!
    @IBOutlet var txtCustomBank: UITextField!
    @IBOutlet var txtNomerRekening : UITextField!
    @IBOutlet var txtNamaRekening : UITextField!
    @IBOutlet var txtPassword : UITextField!
    @IBOutlet var txtJumlah : UITextField!
    
    @IBOutlet var consHeightCustomBank: NSLayoutConstraint!
    
    @IBOutlet var captionPreloBalance : UILabel!
    @IBOutlet var scrollView : UIScrollView!
    
    @IBOutlet var btnWithdraw : UIButton!
    
    var viewSetupPassword : SetupPasswordPopUp?
    var viewShadow : UIView?
    var backEnabled : Bool = true
    
    var isShowBankBRI = false
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        //Mixpanel.trackPageVisit(PageName.Withdraw)
        
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
        
        self.consHeightCustomBank.constant = 0
        
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
                    self.viewSetupPassword = Bundle.main.loadNibNamed(Tags.XibNameSetupPasswordPopUp, owner: nil, options: nil).first as? SetupPasswordPopUp
                    if (self.viewSetupPassword != nil) {
                        self.viewSetupPassword!.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
                        self.viewSetupPassword!.bounds = CGRect(x: self.viewSetupPassword!.bounds.origin.x, y: self.viewSetupPassword!.bounds.origin.y, width: 280, height: 472)
                        self.view.addSubview(self.viewSetupPassword!)
                        if let u = CDUser.getOne() {
                            self.viewSetupPassword!.lblEmail.text = u.email
                        }
                        self.viewSetupPassword!.setPasswordDoneBlock = {
                            self.navigationController?.popViewController(animated: true)
                        }
                        self.viewSetupPassword!.disableBackBlock = {
                            self.backEnabled = false
                        }
                    }
                }
            }
        }
    }
    
    func getBalance()
    {
        // API Migrasi
        let _ = request(APIWallet.getBalance).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Tarik Uang"))
            {
                let json = JSON(resp.result.value!)
                if let i = json["_data"].int
                {
                    let f = NumberFormatter()
                    f.numberStyle = NumberFormatter.Style.currency
                    f.currencySymbol = ""
                    f.locale = Locale(localeIdentifier: "id_ID")
                    self.captionPreloBalance.text = f.string(from: NSNumber(value: i as Int))
                } else if let m = json["_data"].string
                {
                    UIAlertView.SimpleShow("Perhatian", message: m)
                }
            } else
            {
                self.navigationController?.popViewController(animated: true)
            }
            
        }
    }
    
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
            UIAlertView.SimpleShow("Perhatian", message: "Jumlah penarikan minimum adalah Rp. 50.000")
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
                    UIAlertView.SimpleShow("Perhatian", message: message)
                } else
                {
//                    self.getBalance()
                    let nDays = (self.txtNamaBank.text?.lowercased() == "bank lainnya") ? 5 : 3
                    UIAlertView.SimpleShow("Perhatian", message: "Permohonan tarik uang telah diterima. Proses paling lambat membutuhkan \(nDays)x24 jam hari kerja.")
                    
                    // Mixpanel
                    let pt = [
                        "Destination Bank" : namaBank,
                        "Amount" : i
                    ]
                    //Mixpanel.trackEvent(MixpanelEvent.RequestedWithdrawMoney, properties: pt as [NSObject : AnyObject])
                    
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else
            {
                
            }
            
        }
    }
    
    @IBAction func selectBank()
    {
        let p = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdPicker) as! PickerViewController
        
        p.items = ["Bank Mandiri", "Bank BCA", "Bank BNI", "Bank Lainnya"]
        p.title = "Pilih Bank"
        p.selectBlock = { value in
            self.txtNamaBank.text = value
            if (value == "Bank Lainnya") {
                self.consHeightCustomBank.constant = 70
            } else {
                self.consHeightCustomBank.constant = 0
            }
        }
        
        self.navigationController?.pushViewController(p, animated: true)
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        if (self.backEnabled) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

typealias SetPasswordDoneBlock = () -> ()
typealias DisableBackBlock = () -> ()

class SetupPasswordPopUp : UIView {
    @IBOutlet var lblEmail : UILabel!
    @IBOutlet var btnKirimEmail: UIButton!
    var setPasswordDoneBlock : SetPasswordDoneBlock = {}
    var disableBackBlock : DisableBackBlock = {}
    
    @IBAction func sendEmailPressed() {
        self.disableBackBlock()
        self.btnKirimEmail.setTitle("MENGIRIM...", for: UIControlState())
        self.btnKirimEmail.isUserInteractionEnabled = false
        let _ = request(.POST, "\(AppTools.PreloBaseUrl)/api/auth/forgot_password", parameters: ["email":self.lblEmail.text!]).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Tarik Uang - Password Checking")) {
                let json = JSON(resp.result.value!)
                let dataBool : Bool = json["_data"].boolValue
                let dataInt : Int = json["_data"].intValue
                //print("dataBool = \(dataBool), dataInt = \(dataInt)")
                if (dataBool == true || dataInt == 1) {
                    Constant.showDialog("Success", message: "E-mail sudah dikirim ke \(self.lblEmail.text!)")
                } else {
                    Constant.showDialog("Success", message: "Terdapat kesalahan saat memproses data")
                }
            }
            self.setPasswordDoneBlock()
        }
    }
}
