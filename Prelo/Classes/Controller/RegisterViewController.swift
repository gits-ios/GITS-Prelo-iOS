//
//  RegisterViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

class RegisterViewController: BaseViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet var scrollView : UIScrollView?
    @IBOutlet var txtUsername: UITextField!
    @IBOutlet var txtEmail : UITextField?
    @IBOutlet var txtPassword : UITextField?
    @IBOutlet var txtRepeatPassword : UITextField?
    @IBOutlet var txtName : UITextField?
    @IBOutlet var btnTermCondition : UIButton?
    @IBOutlet var btnRegister : UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().track("Register Page")
        
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
    
    @IBAction func backPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func fieldsVerified() -> Bool {
        if (txtUsername?.text == "") {
            var placeholder = NSAttributedString(string: "Username harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtUsername?.attributedPlaceholder = placeholder
            return false
        }
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
        return true
    }
    
    @IBAction func registerPressed(sender : AnyObject) {
        if (fieldsVerified()) {
            self.btnRegister?.enabled = false
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
                if (err != nil) { // Terdapat error
                    Constant.showDialog("Warning", message: (err?.description)!)
                    self.btnRegister?.enabled = true
                } else {
                    let res = JSON(json!)
                    let data = res["_data"]
                    if (data == nil) { // Data kembalian kosong
                        let obj : [String : String] = json as! [String : String]
                        let message = obj["_message"]
                        Constant.showDialog("Warning", message: message!)
                        self.btnRegister?.enabled = true
                    } else { // Berhasil
                        println("Register succeed")
                        println(data)
                        User.StoreUser(data, email : email!)
                        let m = UIApplication.appDelegate.managedObjectContext
                        let c = NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser
                        c.id = data["_id"].string!
                        c.email = data["email"].string!
                        c.fullname = data["fullname"].string!
                        
                        let p = NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile
                        let pr = data["profiles"]
                        p.pict = pr["pict"].string!
                        
                        c.profiles = p
                        UIApplication.appDelegate.saveContext()
                        
                        CartProduct.registerAllAnonymousProductToEmail(User.EmailOrEmptyString)
                        if (self.userRelatedDelegate != nil) {
                            self.userRelatedDelegate?.userLoggedIn!()
                        }
                        
                        self.toProfileSetup()
                    }
                }
        }
        
        // FOR TESTING
        //self.toProfileSetup()
    }
    
    func toProfileSetup() {
        let profileSetupVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameProfileSetup, owner: nil, options: nil).first as! ProfileSetupViewController
        profileSetupVC.previousControllerName = "Register"
        profileSetupVC.userRelatedDelegate = self.userRelatedDelegate
        self.navigationController?.pushViewController(profileSetupVC, animated: true)
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