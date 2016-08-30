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
    var noHpToVerify : String = ""
    var loginMethod : String = "" // [Basic | Facebook | Twitter]
    var userProfileData : UserProfile?
    
    // MARK: - Init
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Set title
        self.title = "Verifikasi Handphone"
        
        // Show phone number
        fldNoHp.text = self.noHpToVerify
        
        // Field input is uppercase
        self.fieldKodeVerifikasi.autocapitalizationType = UITextAutocapitalizationType.AllCharacters
    }
    
    override func viewDidLoad() {
        if (isShowBackBtn) {
            super.viewDidLoad()
        } else {
            self.navigationItem.hidesBackButton = true
            let newBackButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PhoneVerificationViewController.backPressed2(_:)))
            newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
            self.navigationItem.leftBarButtonItem = newBackButton
        }
        
        self.fldNoHp.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
        //Mixpanel.trackPageVisit(PageName.VerifyPhone)
        
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
    
    func backPressed2(sender: UIBarButtonItem) {
        let alert : UIAlertController = UIAlertController(title: "Perhatian", message: "Verifikasi belum selesai. Halaman ini akan muncul lagi lain kali kamu login. Keluar?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Batal", style: .Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Keluar", style: .Default, handler: { action in
            User.Logout()
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func disableTextFields(sender : AnyObject)
    {
        fieldKodeVerifikasi?.resignFirstResponder()
        fldNoHp.resignFirstResponder()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKindOfClass(UIButton.classForCoder()) || touch.view!.isKindOfClass(UITextField.classForCoder())) {
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
    
    @IBAction func verifikasiPressed(sender: UIButton) {
        if (fieldsVerified()) {
            disableTextFields(NSNull)
            btnVerifikasi.enabled = false
            btnKirimUlang.enabled = false
            
            if (!self.isReverification) {
                // Token belum disimpan pake User.StoreUser karna di titik ini user belum dianggap login
                // But we need to set token temporarily, because APIUser.ResendVerificationSms need token
                User.SetToken(self.userToken)
            }
            
            // API Migrasi
            request(APIUser.VerifyPhone(phone: self.fldNoHp.text!, phoneCode: self.fieldKodeVerifikasi.text!)).responseJSON {resp in
                if (!self.isReverification) {
                    // Delete token because user is considered not logged in
                    User.SetToken(nil)
                }
                
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Verifikasi Nomor HP")) {
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
                                let user : CDUser = (NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m) as! CDUser)
                                user.id = self.userProfileData!.id
                                user.email = self.userProfileData!.email
                                user.fullname = self.userProfileData!.fullname
                                user.username = self.userProfileData!.username
                                
                                CDUserProfile.deleteAll()
                                let userProfile : CDUserProfile = (NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m) as! CDUserProfile)
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
                                let userOther : CDUserOther = (NSEntityDescription.insertNewObjectForEntityForName("CDUserOther", inManagedObjectContext: m) as! CDUserOther)
                                userOther.shippingIDs = NSKeyedArchiver.archivedDataWithRootObject(self.userProfileData!.shippingIds)
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
                            NSNotificationCenter.defaultCenter().postNotificationName("userLoggedIn", object: nil)
                            
                            // Send uuid to server
                            request(APIUser.SetUserUUID)
                            
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
                    self.btnVerifikasi.enabled = true
                    self.btnKirimUlang.enabled = true
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
        // Mixpanel
        let sp = [
            "Phone" : noHp,
            "Login Method" : self.loginMethod,
        ]
        Mixpanel.sharedInstance().registerSuperProperties(sp as [NSObject : AnyObject])
        let p = [
            "$phone" : noHp
        ]
        Mixpanel.sharedInstance().people.set(p)
        Mixpanel.trackEvent(MixpanelEvent.PhoneVerified)
        
        // Dismiss view
        Constant.showDialog("Success", message: "Verifikasi berhasil")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func phoneReverificationSucceed() {
        // Pop 2 views (self and phoneReverificationVC)
        let viewControllers: [UIViewController] = (self.navigationController?.viewControllers)!
        self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: true);
    }
    
    @IBAction func kirimUlangPressed(sender: UIButton) {
        disableTextFields(NSNull)
        btnVerifikasi.enabled = false
        btnKirimUlang.enabled = false
        
        if (!self.isReverification) {
            // Token belum disimpan pake User.StoreUser karna di titik ini user belum dianggap login
            // Set token first, because APIUser.ResendVerificationSms need token
            User.SetToken(self.userToken)
        }
        
        request(APIUser.ResendVerificationSms(phone: self.fldNoHp.text!)).responseJSON {resp in
            if (!self.isReverification) {
                // Delete token because user is considered not logged in
                User.SetToken(nil)
            }
            
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Verifikasi Nomor HP")) {
                let json = JSON(resp.result.value!)
                let data : Bool? = json["_data"].bool
                if (data != nil || data == true) {
                    Constant.showDialog("Success", message: "SMS telah dikirim ulang")
                }
            }
            self.btnVerifikasi.enabled = true
            self.btnKirimUlang.enabled = true
        }
    }
    
    // MARK: - UITextField Delegate
    
    func textFieldDidEndEditing(textField: UITextField) {
        Constant.showDialog("Kirim Ulang", message: "Tekan 'Kirim Ulang' untuk mengirim sms kembali")
    }
}