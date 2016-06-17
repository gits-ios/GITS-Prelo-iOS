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
    @IBOutlet var txtNomerRekening : UITextField!
    @IBOutlet var txtNamaRekening : UITextField!
    @IBOutlet var txtPassword : UITextField!
    @IBOutlet var txtJumlah : UITextField!
    
    @IBOutlet var captionPreloBalance : UILabel!
    @IBOutlet var scrollView : UIScrollView!
    
    @IBOutlet var btnWithdraw : UIButton!
    
    var viewSetupPassword : SetupPasswordPopUp?
    var viewShadow : UIView?
    var backEnabled : Bool = true
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        //Mixpanel.trackPageVisit(PageName.Withdraw)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Withdraw)
        
        self.an_subscribeKeyboardWithAnimations({ f, i , o in
            
            if (o)
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
            } else
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
            
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.an_unsubscribeKeyboard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Tarik Uang"
        
        scrollView.delegate = self
        
        captionPreloBalance.text = "..."
        
        txtNamaBank.textAlignment = NSTextAlignment.Right
        txtNomerRekening.textAlignment = NSTextAlignment.Right
        
        // Munculkan pop up jika user belum mempunyai password
        // API Migrasi
        request(APIUser.CheckPassword).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Tarik Uang")) {
                let json = JSON(resp.result.value!)
                let data : Bool? = json["_data"].bool
                if (data != nil && data == true) {
                    self.getBalance()
                } else {
                    let screenSize : CGRect = UIScreen.mainScreen().bounds
                    self.viewShadow = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height), backgroundColor: UIColor.blackColor().colorWithAlphaComponent(0.5))
                    if (self.viewShadow != nil) {
                        self.view.addSubview(self.viewShadow!)
                    }
                    self.viewSetupPassword = NSBundle.mainBundle().loadNibNamed(Tags.XibNameSetupPasswordPopUp, owner: nil, options: nil).first as? SetupPasswordPopUp
                    if (self.viewSetupPassword != nil) {
                        self.viewSetupPassword!.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
                        self.viewSetupPassword!.bounds = CGRect(x: self.viewSetupPassword!.bounds.origin.x, y: self.viewSetupPassword!.bounds.origin.y, width: 280, height: 472)
                        self.view.addSubview(self.viewSetupPassword!)
                        if let u = CDUser.getOne() {
                            self.viewSetupPassword!.lblEmail.text = u.email
                        }
                        self.viewSetupPassword!.setPasswordDoneBlock = {
                            self.navigationController?.popViewControllerAnimated(true)
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
        request(APIWallet.GetBalance).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Tarik Uang"))
            {
                let json = JSON(resp.result.value!)
                if let i = json["_data"].int
                {
                    let f = NSNumberFormatter()
                    f.numberStyle = NSNumberFormatterStyle.CurrencyStyle
                    f.currencySymbol = ""
                    f.locale = NSLocale(localeIdentifier: "id_ID")
                    self.captionPreloBalance.text = f.stringFromNumber(NSNumber(integer: i))
                } else if let m = json["_data"].string
                {
                    UIAlertView.SimpleShow("Perhatian", message: m)
                }
            } else
            {
                self.navigationController?.popViewControllerAnimated(true)
            }
            
        }
    }
    
    @IBAction func withdraw()
    {
        if (txtNamaBank.text == "Pilih Bank") {
            Constant.showDialog("Form belum lengkap", message: "Harap pilih Bank Kamu")
            return
        }
        if (txtNomerRekening.text == nil || txtNomerRekening.text!.isEmpty) {
            Constant.showDialog("Form belum lengkap", message: "Harap isi Nomor Rekening")
            return
        }
        if (txtNamaRekening.text == nil || txtNamaRekening.text!.isEmpty) {
            Constant.showDialog("Form belum lengkap", message: "Harap isi Atas Nama Rekening")
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
        
        namaBank = namaBank.stringByReplacingOccurrencesOfString("Bank ", withString: "")
        let norek = txtNomerRekening.text == nil ? "" : txtNomerRekening.text!
        let namarek = txtNamaRekening.text == nil ? "" : txtNamaRekening.text!
        let pass = txtPassword.text == nil ? "" : txtPassword.text!
        
        self.btnWithdraw.enabled = false
        
        // API Migrasi
        request(APIWallet.Withdraw(amount: amount, targetBank: namaBank, norek: norek, namarek: namarek, password: pass)).responseJSON {resp in
            self.btnWithdraw.enabled = true
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Submit Tarik Uang"))
            {
                let json = JSON(resp.result.value!)
                if let message = json["_message"].string
                {
                    UIAlertView.SimpleShow("Perhatian", message: message)
                } else
                {
//                    self.getBalance()
                    UIAlertView.SimpleShow("Perhatian", message: "Permohonan tarik uang telah diterima")
                    
                    // Mixpanel
                    let pt = [
                        "Destination Bank" : namaBank,
                        "Amount" : i
                    ]
                    //Mixpanel.trackEvent(MixpanelEvent.RequestedWithdrawMoney, properties: pt as [NSObject : AnyObject])
                    
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
            } else
            {
                
            }
            
        }
    }
    
    @IBAction func selectBank()
    {
        let p = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdPicker) as! PickerViewController
        
        p.items = ["Bank Mandiri", "Bank BCA", "Bank BNI"]
        p.title = "Pilih Bank"
        p.selectBlock = { value in
            self.txtNamaBank.text = value
        }
        
        self.navigationController?.pushViewController(p, animated: true)
    }
    
    override func backPressed(sender: UIBarButtonItem) {
        if (self.backEnabled) {
            self.navigationController?.popViewControllerAnimated(true)
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
        self.btnKirimEmail.setTitle("MENGIRIM...", forState: .Normal)
        self.btnKirimEmail.userInteractionEnabled = false
        request(.POST, "\(AppTools.PreloBaseUrl)/api/auth/forgot_password", parameters: ["email":self.lblEmail.text!]).responseJSON {resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Tarik Uang - Password Checking")) {
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
