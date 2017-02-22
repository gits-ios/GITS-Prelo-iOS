//
//  PhoneVerificationViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import Crashlytics
import CoreData
import Alamofire

protocol PhoneVerificationDelegate {
    func phoneVerified(_ newPhone : String)
}

class PhoneVerificationViewController : BaseViewController, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lblNoHp: UILabel!
    @IBOutlet weak var fldNoHp: UITextField!
    @IBOutlet weak var fieldKodeVerifikasi: UITextField!
    @IBOutlet weak var btnVerifikasi: UIButton!
    @IBOutlet weak var btnKirimUlang: UIButton!
    
    var delegate : PhoneVerificationDelegate?
    
    var backAlert : UIAlertController? = nil
    
    // Variable from previous scene
    var userId : String = ""
    var userToken : String = ""
    var userEmail : String = ""
    var isShowBackBtn : Bool = false
    var isReverification : Bool = false
    var noHpToVerify : String = ""
    var loginMethod : String = "" // [Basic | Facebook | Twitter]
    var userProfileData : UserProfile?
    
    // MARK: - Init
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Set title
        self.title = "Verifikasi Handphone"
        
        // Show phone number
        fldNoHp.text = self.noHpToVerify
        
        // Field input is uppercase
        self.fieldKodeVerifikasi.autocapitalizationType = UITextAutocapitalizationType.allCharacters
    }
    
    override func viewDidLoad() {
        if (isShowBackBtn) {
            super.viewDidLoad()
        } else {
            self.navigationItem.hidesBackButton = true
            let newBackButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PhoneVerificationViewController.backPressed2(_:)))
            newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], for: UIControlState())
            self.navigationItem.leftBarButtonItem = newBackButton
        }
        
        self.fldNoHp.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.VerifyPhone)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.VerifyPhone)
        
        self.an_subscribeKeyboard(
            animations: {r, t, o in
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
            }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func backPressed2(_ sender: UIBarButtonItem) {
        backAlert = UIAlertController(title: "Perhatian", message: "Verifikasi belum selesai. Halaman ini akan muncul lagi lain kali kamu login. Keluar?", preferredStyle: UIAlertControllerStyle.alert)
        backAlert!.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { action in
            self.backAlert!.dismiss(animated: true, completion: nil)
            self.backAlert = nil
        }))
        backAlert!.addAction(UIAlertAction(title: "Keluar", style: .default, handler: { action in
            User.Logout()
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(backAlert!, animated: true, completion: nil)
    }
    
    @IBAction func disableTextFields(_ sender : AnyObject)
    {
        fieldKodeVerifikasi?.resignFirstResponder()
        fldNoHp.resignFirstResponder()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - Submit
    
    func fieldsVerified() -> Bool {
        if (fieldKodeVerifikasi.text == "") {
            Constant.showDialog("Warning", message: "Kode verifikasi harus diisi, cek sms kamu")
            return false
        }
        return true
    }
    
    @IBAction func verifikasiPressed(_ sender: UIButton) {
        if (fieldsVerified()) {
            disableTextFields(NSNull)
            btnVerifikasi.isEnabled = false
            btnKirimUlang.isEnabled = false
            
            if (!self.isReverification) {
                // Token belum disimpan pake User.StoreUser karna di titik ini user belum dianggap login
                // But we need to set token temporarily, because APIMe.ResendVerificationSms need token
                User.SetToken(self.userToken)
            }
            
            // API Migrasi
            let _ = request(APIMe.verifyPhone(phone: self.fldNoHp.text!, phoneCode: self.fieldKodeVerifikasi.text!)).responseJSON {resp in
                if (!self.isReverification) {
                    // Delete token because user is considered not logged in
                    User.SetToken(nil)
                }
                
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Verifikasi Nomor HP")) {
                    let json = JSON(resp.result.value!)
                    let isSuccess = json["_data"].bool!
                    if (isSuccess) { // Berhasil
                        if (self.isReverification) { // User is changing phone number from edit profile
                            self.phoneReverificationSucceed()
                            
                            if let d = self.delegate {
                                d.phoneVerified(self.fldNoHp.text!)
                            }
                        } else { // User is setting up new account
                            if (self.userProfileData != nil) {
                                // Save in core data
                                let m = UIApplication.appDelegate.managedObjectContext
                                CDUser.deleteAll()
                                let user : CDUser = (NSEntityDescription.insertNewObject(forEntityName: "CDUser", into: m) as! CDUser)
                                user.id = self.userProfileData!.id
                                user.email = self.userProfileData!.email
                                user.fullname = self.userProfileData!.fullname
                                user.username = self.userProfileData!.username
                                
                                CDUserProfile.deleteAll()
                                let userProfile : CDUserProfile = (NSEntityDescription.insertNewObject(forEntityName: "CDUserProfile", into: m) as! CDUserProfile)
                                user.profiles = userProfile
                                userProfile.regionID = self.userProfileData!.regionId
                                userProfile.provinceID = self.userProfileData!.provinceId
                                userProfile.subdistrictID = self.userProfileData!.subdistrictId
                                userProfile.subdistrictName = self.userProfileData!.subdistrictName
                                userProfile.gender = self.userProfileData!.gender
                                userProfile.phone = self.fldNoHp.text!
                                userProfile.pict = self.userProfileData!.profPictURL!.absoluteString
                                userProfile.postalCode = self.userProfileData!.postalCode
                                userProfile.address = self.userProfileData!.address
                                userProfile.desc = self.userProfileData!.desc
                                
                                CDUserOther.deleteAll()
                                let userOther : CDUserOther = (NSEntityDescription.insertNewObject(forEntityName: "CDUserOther", into: m) as! CDUserOther)
                                userOther.shippingIDs = NSKeyedArchiver.archivedData(withRootObject: self.userProfileData!.shippingIds)
                                userOther.lastLogin = self.userProfileData!.lastLogin
                                userOther.phoneCode = self.userProfileData!.phoneCode
                                userOther.phoneVerified = self.userProfileData!.isPhoneVerified
                                userOther.registerTime = self.userProfileData!.registerTime
                                userOther.fbAccessToken = self.userProfileData!.fbAccessToken
                                userOther.fbID = self.userProfileData!.fbId
                                userOther.fbUsername = self.userProfileData!.fbUsername
                                userOther.instagramAccessToken = self.userProfileData!.instagramAccessToken
                                userOther.instagramID = self.userProfileData!.instagramId
                                userOther.instagramUsername = self.userProfileData!.instagramUsername
                                userOther.twitterAccessToken = self.userProfileData!.twitterAccessToken
                                userOther.twitterID = self.userProfileData!.twitterId
                                userOther.twitterUsername = self.userProfileData!.twitterUsername
                                userOther.twitterTokenSecret = self.userProfileData!.twitterTokenSecret
                                userOther.pathAccessToken = self.userProfileData!.pathAccessToken
                                userOther.pathID = self.userProfileData!.pathId
                                userOther.pathUsername = self.userProfileData!.pathUsername
                                userOther.emailVerified = (self.userProfileData!.isEmailVerified) ? 1 : 0
                                // TODO: belum lengkap (isActiveSeller, seller, shopName, shopPermalink, simplePermalink)
                                
                                UIApplication.appDelegate.saveContext()
                            }
                            
                            // Save in NSUserDefaults
                            User.StoreUser(self.userId, token: self.userToken, email: self.userEmail)
                            
                            // Tell app that the user has logged in
                            if let d = self.userRelatedDelegate
                            {
                                d.userLoggedIn!()
                            }
                            
                            // Memanggil notif observer yg mengimplement userLoggedIn (AppDelegate & KumangTabBarVC)
                            // Di dalamnya akan memanggil MessagePool.start()
                            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "userLoggedIn"), object: nil)
                            
                            // Send uuid to server
                            let _ = request(APIMe.setUserUUID)
                            
                            // Set crashlytics user information
                            let user = CDUser.getOne()!
                            Crashlytics.sharedInstance().setUserIdentifier(user.profiles.phone!)
                            Crashlytics.sharedInstance().setUserEmail(user.email)
                            Crashlytics.sharedInstance().setUserName(user.fullname!)
                            
                            // MoEngage
                            MoEngage.sharedInstance().setUserAttribute(user.id, forKey: "user_id")
                            MoEngage.sharedInstance().setUserAttribute(user.username, forKey: "username")
                            MoEngage.sharedInstance().setUserAttribute(user.fullname, forKey: "user_fullname")
                            MoEngage.sharedInstance().setUserAttribute(user.email, forKey: "user_email")
                            MoEngage.sharedInstance().setUserAttribute(user.profiles.phone!, forKey: "phone")
                            
                            // Send deviceRegId before finish
                            LoginViewController.SendDeviceRegId({
                                self.phoneVerificationSucceed()
                            })
                        }
                    } else { // Gagal
                        Constant.showDialog("Warning", message: "Error verifying phone number")
                    }
                } else {
                    self.btnVerifikasi.isEnabled = true
                    self.btnKirimUlang.isEnabled = true
                }
            }
        }
    }
    
    func phoneVerificationSucceed() {
        var noHp = ""
        if let p = self.fldNoHp.text
        {
            noHp = p
        }
        
        /*
        // Mixpanel
        let sp = [
            "Phone" : noHp,
            "Login Method" : self.loginMethod,
        ]
        Mixpanel.sharedInstance().registerSuperProperties(sp as [AnyHashable: Any])
        let p = [
            "$phone" : noHp
        ]
        Mixpanel.sharedInstance().people.set(p)
        Mixpanel.trackEvent(MixpanelEvent.PhoneVerified)
         */
        
        // Prelo Analytic
        let pdata = [
            "Phone" : noHp
        ]
        AnalyticManager.sharedInstance.send(eventType: MixpanelEvent.PhoneVerified, data: pdata, previousScreen: self.previousScreen, loginMethod: self.loginMethod)
        
        // Dismiss view
        Constant.showDialog("Success", message: "Verifikasi berhasil")
        self.dismiss(animated: true, completion: nil)
    }
    
    func phoneReverificationSucceed() {
        // Pop 2 views (self and phoneReverificationVC)
        let viewControllers: [UIViewController] = (self.navigationController?.viewControllers)!
        self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: true);
    }
    
    @IBAction func kirimUlangPressed(_ sender: UIButton) {
        disableTextFields(NSNull)
        btnVerifikasi.isEnabled = false
        btnKirimUlang.isEnabled = false
        
        if (!self.isReverification) {
            // Token belum disimpan pake User.StoreUser karna di titik ini user belum dianggap login
            // Set token first, because APIMe.ResendVerificationSms need token
            User.SetToken(self.userToken)
        }
        
        let _ = request(APIMe.resendVerificationSms(phone: self.fldNoHp.text!)).responseJSON {resp in
            if (!self.isReverification) {
                // Delete token because user is considered not logged in
                User.SetToken(nil)
            }
            
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Verifikasi Nomor HP")) {
                let json = JSON(resp.result.value!)
                let data : Bool? = json["_data"].bool
                if (data != nil || data == true) {
                    Constant.showDialog("Success", message: "SMS telah dikirim ulang")
                }
            }
            self.btnVerifikasi.isEnabled = true
            self.btnKirimUlang.isEnabled = true
        }
    }
    
    // MARK: - UITextField Delegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (backAlert == nil) { // Jika tidak sedang memunculkan back alert
            Constant.showDialog("Kirim Ulang", message: "Tekan 'Kirim Ulang' untuk mengirim sms kembali")
        }
    }
}
