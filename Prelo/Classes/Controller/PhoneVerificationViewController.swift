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
    
    override func viewDidLoad() {
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: " Verifikasi Handphone", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
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
            Constant.showDialog("Success", message: "Verifikasi berhasil")
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func kirimUlangPressed(sender: UIButton) {
        Constant.showDialog("Success", message: "Sms telah dikirim ulang")
    }
}