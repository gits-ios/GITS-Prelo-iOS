//
//  RegisterViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class RegisterViewController: BaseViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet var scrollView : UIScrollView?
    @IBOutlet var txtEmail : UITextField?
    @IBOutlet var txtPassword : UITextField?
    @IBOutlet var txtRepeatPassword : UITextField?
    @IBOutlet var txtName : UITextField?
    @IBOutlet var btnTermCondition : UIButton?
    @IBOutlet var btnRegister : UIButton?
    
    var checkboxSelected = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboardWithAnimations(
            {r, t, o in
                
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64+r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
                }
                
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    @IBAction func disableTextFields(sender : AnyObject)
    {
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
        txtRepeatPassword?.resignFirstResponder()
        txtName?.resignFirstResponder()
    }
    
    @IBAction func checkboxButton(sender : UIButton) {
        if (checkboxSelected == 0){
            sender.selected = true
            checkboxSelected = 1
        } else {
            sender.selected = false
            checkboxSelected = 0
        }
    }
    
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func fieldsVerified() -> Bool {
        if (txtEmail?.text == "") {
            var placeholder = NSAttributedString(string: "Email harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtEmail?.attributedPlaceholder = placeholder
            return false
        }
        if (txtEmail?.text.rangeOfString("@") == nil) {
            var placeholder = NSAttributedString(string: "Email tidak valid", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtEmail?.text = ""
            txtEmail?.attributedPlaceholder = placeholder
            return false
        }
        if (txtPassword?.text == "") {
            var placeholder = NSAttributedString(string: "Kata sandi harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtPassword?.attributedPlaceholder = placeholder
            return false
        }
        if (txtRepeatPassword?.text == "") {
            var placeholder = NSAttributedString(string: "Kata sandi harus diulangi", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtRepeatPassword?.attributedPlaceholder = placeholder
            return false
        }
        if (txtPassword?.text != txtRepeatPassword?.text) {
            var placeholder = NSAttributedString(string: "Kata sandi tidak cocok", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtRepeatPassword?.text = ""
            txtRepeatPassword?.attributedPlaceholder = placeholder
            return false
        }
        if (txtName?.text == "") {
            var placeholder = NSAttributedString(string: "Nama harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtName?.attributedPlaceholder = placeholder
            return false
        }
        if (checkboxSelected == 0) {
            btnTermCondition?.setTitleColor(UIColor.redColor())
            return false
        }
        return true
    }
    
    @IBAction func registerPressed(sender : AnyObject) {
        if (fieldsVerified()) {
            btnRegister?.enabled = false
            register()
        }
    }
    
    func register() {
        disableTextFields(NSNull)
        let email = txtEmail?.text
        let password = txtPassword?.text
        let name = txtName?.text
        request(APIUser.Register(fullname: name!, email: email!, password: password!))
            .responseJSON
            {_, _, json, err in
                self.btnRegister?.enabled = true
                if (err != nil) { // Terdapat error
                    Constant.showDialog("Warning", message: (err?.description)!)
                } else {
                    let res = JSON(json!)
                    let data = res["_data"]
                    if (data == nil) { // Data kembalian kosong
                        let obj : [String : String] = json as! [String : String]
                        let message = obj["_message"]
                        Constant.showDialog("Warning", message: message!)
                    } else { // Berhasil
                        println("Register succeed")
                        self.toUserProfile()
                    }
                }
        }
        
        // FOR TESTING
        //self.toUserProfile()
    }
    
    func toUserProfile() {
        let userProfileVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil).first as! UserProfileViewController
        userProfileVC.previousControllerName = "Register"
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UIButton.classForCoder()) || touch.view.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
}