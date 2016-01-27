//
//  PhoneVerificationViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import Crashlytics

protocol PhoneVerificationDelegate {
    func phoneVerified(newPhone : String)
}

class PhoneVerificationViewController : BaseViewController, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lblNoHp: UILabel!
    @IBOutlet weak var fldNoHp: UITextField!
    @IBOutlet weak var fieldKodeVerifikasi: UITextField!
    @IBOutlet weak var btnVerifikasi: UIButton!
    @IBOutlet weak var btnKirimUlang: UIButton!
    
    var delegate : PhoneVerificationDelegate?
    
    // Variable from previous scene
    var userId : String = ""
    var userToken : String = ""
    var userEmail : String = ""
    var isShowBackBtn : Bool = false
    var isReverification : Bool = false
    var reverificationNoHP : String = ""
    var loginMethod : String = "" // [Basic | Facebook | Twitter]
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Set title
        self.title = "Verifikasi Handphone"
        
        // Show phone number
        if (self.isReverification) {
            fldNoHp.text = self.reverificationNoHP
        } else {
            let userProfile : CDUserProfile = CDUserProfile.getOne()!
            fldNoHp.text = userProfile.phone
        }
        
        // Field input is uppercase
        self.fieldKodeVerifikasi.autocapitalizationType = UITextAutocapitalizationType.AllCharacters
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fldNoHp.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.VerifyPhone)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.VerifyPhone)
        
        self.an_subscribeKeyboardWithAnimations(
            {r, t, o in
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    @IBAction func disableTextFields(sender : AnyObject)
    {
        fieldKodeVerifikasi?.resignFirstResponder()
        fldNoHp.resignFirstResponder()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UIButton.classForCoder()) || touch.view.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    func fieldsVerified() -> Bool {
        if (fieldKodeVerifikasi.text == "") {
            Constant.showDialog("Warning", message: "Kode verifikasi harus diisi, cek sms kamu")
            return false
        }
        return true
    }
    
    @IBAction func verifikasiPressed(sender: UIButton) {
        if (fieldsVerified()) {
            if (!self.isReverification) {
                // Token belum disimpan pake User.StoreUser karna di titik ini user belum dianggap login
                // Set token first, because APIUser.ResendVerificationSms need token
                User.SetToken(self.userToken)
            }
            
            request(APIUser.VerifyPhone(phone: self.fldNoHp.text!, phoneCode: self.fieldKodeVerifikasi.text)).responseJSON { req, resp, res, err in
                if (!self.isReverification) {
                    // Delete token because user is considered not logged in
                    User.SetToken(nil)
                }
                
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Verifikasi Nomor HP")) {
                    let json = JSON(res!)
                    let isSuccess = json["_data"].bool!
                    if (isSuccess) { // Berhasil
                        if (self.isReverification) { // User is changing phone number from edit profile
                            self.phoneReverificationSucceed()
                            
                            if let d = self.delegate {
                                d.phoneVerified(self.fldNoHp.text!)
                            }
                        } else { // User is setting up new account
                            // Set user to logged in
                            User.StoreUser(self.userId, token: self.userToken, email: self.userEmail)
                            if let d = self.userRelatedDelegate
                            {
                                d.userLoggedIn!()
                            }
                            
                            // Set User-Agent for every HTTP request
                            let webViewDummy = UIWebView()
                            let userAgent = webViewDummy.stringByEvaluatingJavaScriptFromString("navigator.userAgent")
                            NSUserDefaults.setObjectAndSync(userAgent, forKey: UserDefaultsKey.UserAgent)
                            
                            /* TO BE DELETED, dipindah ke ProfileSetupVC
                            if let c = CDUser.getOne()
                            {
                            Mixpanel.sharedInstance().identify(c.id)
                            Mixpanel.sharedInstance().people.set(["$first_name":c.fullname!, "$name":c.email, "user_id":c.id])
                            } else {
                            Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                            Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
                            }*/
                            
                            // Set crashlytics user information
                            let user = CDUser.getOne()!
                            Crashlytics.sharedInstance().setUserIdentifier(user.profiles.phone!)
                            Crashlytics.sharedInstance().setUserEmail(user.email)
                            Crashlytics.sharedInstance().setUserName(user.fullname!)
                            
                            // Send deviceRegId before finish
                            LoginViewController.SendDeviceRegId(onFinish: self.phoneVerificationSucceed())
                        }
                    } else { // Gagal
                        Constant.showDialog("Warning", message: "Error verifying phone number")
                    }
                }
            }
        }
    }
    
    func phoneVerificationSucceed() {
        // Mixpanel
        let sp = [
            "Phone" : self.fldNoHp.text,
            "Login Method" : self.loginMethod,
            "Orders Purchased Count" : 0,
            "Initial Value Count" : 0,
            "Items Purchased Count" : 0,
            "Items Purchased Categories 1" : [],
            "Items Purchased Categories 2" : [],
            "Items Purchased Categories 3" : [],
            "Items Sold Count" : 0,
            "Lifetime Value Purchased" : 0,
            "Lifetime Value Commission" : 0,
            "Lifetime Value Sold" : 0,
            "Items in Cart Count" : 0
        ]
        Mixpanel.sharedInstance().registerSuperProperties(sp as [NSObject : AnyObject])
        let p = [
            "$phone" : self.fldNoHp.text
        ]
        Mixpanel.sharedInstance().people.set(p)
        Mixpanel.trackEvent(MixpanelEvent.PhoneVerified)
        
        // Dismiss view
        Constant.showDialog("Success", message: "Verifikasi berhasil")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func phoneReverificationSucceed() {
        // Pop 2 views (self and phoneReverificationVC)
        let viewControllers: [UIViewController] = self.navigationController?.viewControllers as! [UIViewController]
        self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: true);
    }
    
    @IBAction func kirimUlangPressed(sender: UIButton) {
        if (!self.isReverification) {
            // Token belum disimpan pake User.StoreUser karna di titik ini user belum dianggap login
            // Set token first, because APIUser.ResendVerificationSms need token
            User.SetToken(self.userToken)
        }
        
        request(APIUser.ResendVerificationSms(phone: self.fldNoHp.text!)).responseJSON { req, resp, res, err in
            if (!self.isReverification) {
                // Delete token because user is considered not logged in
                User.SetToken(nil)
            }
            
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Verifikasi Nomor HP")) {
                let json = JSON(res!)
                let data : Bool? = json["_data"].bool
                if (data != nil || data == true) {
                    Constant.showDialog("Success", message: "SMS telah dikirim ulang, kode verifikasi yang berlaku ada di SMS yang dikirim terakhir")
                }
            }
        }
    }
    
    // MARK: - UITextField Delegate
    func textFieldDidEndEditing(textField: UITextField) {
        Constant.showDialog("Kirim Ulang", message: "Tekan 'Kirim Ulang' untuk mengirim sms kembali")
    }
}