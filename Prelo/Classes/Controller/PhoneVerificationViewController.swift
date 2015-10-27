//
//  PhoneVerificationViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class PhoneVerificationViewController : BaseViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lblNoHp: UILabel!
    @IBOutlet weak var fieldKodeVerifikasi: UITextField!
    @IBOutlet weak var btnVerifikasi: UIButton!
    @IBOutlet weak var btnKirimUlang: UIButton!
    
    // Variable from previous scene
    var userId : String = ""
    var userToken : String = ""
    var userEmail : String = ""
    var isShowBackBtn : Bool = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        // Show phone number
        let userProfile : CDUserProfile = CDUserProfile.getOne()!
        lblNoHp.text = userProfile.phone
        
        // Tombol back
        self.navigationItem.hidesBackButton = true
        if (isShowBackBtn) {
            let newBackButton = UIBarButtonItem(title: " Verifikasi Handphone", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
            newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
            self.navigationItem.leftBarButtonItem = newBackButton
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Mixpanel.sharedInstance().track("Phone Verification")
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
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func disableTextFields(sender : AnyObject)
    {
        fieldKodeVerifikasi?.resignFirstResponder()
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
            // Token belum disimpan pake User.StoreUser karna di titik ini user belum dianggap login
            // Set token first, because APIUser.ResendVerificationSms need token
            User.SetToken(self.userToken)
            
            request(APIUser.VerifyPhone(phone: self.lblNoHp.text!, phoneCode: self.fieldKodeVerifikasi.text)).responseJSON {req, _, res, err in
                // Delete token because user is considered not logged in
                User.SetToken(nil)
                
                println("Verify phone req = \(req)")
                if (err != nil) {
                    Constant.showDialog("Warning", message: "Verify phone error: \(err?.description)")
                } else {
                    let json = JSON(res!)
                    let data : Bool? = json["_data"].bool
                    if (data == nil || data == false) { // Gagal
                        Constant.showDialog("Warning", message: "Verify phone error")
                    } else { // Berhasil
                        println("data = \(data)")
                        
                        // Set user to logged in
                        User.StoreUser(self.userId, token: self.userToken, email: self.userEmail)
                        if let d = self.userRelatedDelegate
                        {
                            d.userLoggedIn!()
                        }
                        if let c = CDUser.getOne()
                        {
                            Mixpanel.sharedInstance().identify(c.id)
                            Mixpanel.sharedInstance().people.set(["$first_name":c.fullname!, "$name":c.email, "user_id":c.id])
                        } else {
                            Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                            Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
                        }
                        
                        // Dismiss view
                        Constant.showDialog("Success", message: "Verifikasi berhasil")
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func kirimUlangPressed(sender: UIButton) {
        // Token belum disimpan pake User.StoreUser karna di titik ini user belum dianggap login
        // Set token first, because APIUser.ResendVerificationSms need token
        User.SetToken(self.userToken)
        
        request(APIUser.ResendVerificationSms(phone: self.lblNoHp.text!)).responseJSON {req, _, res, err in
            // Delete token because user is considered not logged in
            User.SetToken(nil)
            
            println("Resend verification sms req = \(req)")
            if (err != nil) {
                Constant.showDialog("Warning", message: "Resend sms error: \(err?.description)")
            } else {
                let json = JSON(res!)
                let data : Bool? = json["_data"].bool
                if (data == nil || data == false) { // Gagal
                    Constant.showDialog("Warning", message: "Resend sms error")
                } else { // Berhasil
                    println("data = \(data)")
                    Constant.showDialog("Success", message: "Sms telah dikirim ulang")
                }
            }
        }
    }
}