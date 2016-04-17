//
//  RegisterViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

class RegisterViewController: BaseViewController, UIGestureRecognizerDelegate, PathLoginDelegate, UITextFieldDelegate {
    
    @IBOutlet var scrollView : UIScrollView?
    @IBOutlet var txtUsername: UITextField!
    @IBOutlet var txtEmail : UITextField?
    @IBOutlet var txtPassword : UITextField?
    @IBOutlet var txtRepeatPassword : UITextField?
    @IBOutlet var txtName : UITextField?
    @IBOutlet var btnTermCondition : UIButton?
    @IBOutlet var btnRegister : UIButton?
    
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var screenBeforeLogin : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
        
        // Hide loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = true
        loading.stopAnimating()
        
        txtName?.autocapitalizationType = .Words
        
        // Set delegate
        txtUsername.delegate = self
        txtEmail!.delegate = self
        txtPassword!.delegate = self
        txtRepeatPassword!.delegate = self
        txtName!.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.Register)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Register)
        
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
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    @IBAction func disableTextFields(sender : AnyObject)
    {
        txtUsername?.resignFirstResponder()
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
        txtRepeatPassword?.resignFirstResponder()
        txtName?.resignFirstResponder()
    }
    
    @IBAction func xBackPressed(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func termConditionPressed(sender: AnyObject) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let termCondVC = mainStoryboard.instantiateViewControllerWithIdentifier("preloweb") as! PreloWebViewController
        termCondVC.url = "https://prelo.co.id/syarat-ketentuan?ref=preloapp"
        termCondVC.titleString = "Syarat dan Ketentuan"
        let baseNavC = BaseNavigationController()
        baseNavC.setViewControllers([termCondVC], animated: false)
        self.presentViewController(baseNavC, animated: true, completion: nil)
    }
    
    func fieldsVerified() -> Bool {
        if (txtUsername?.text == "") {
            var placeholder = NSAttributedString(string: "Username harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtUsername?.attributedPlaceholder = placeholder
            return false
        } else {
            let usernameRegex = "^[a-zA-Z0-9_]{4,15}$"
            if (txtUsername?.text!.match(usernameRegex) == false) {
                txtUsername?.text = ""
                var placeholder = NSAttributedString(string: "Username: 4-15 char (a-z, A-Z, 0-9, _)", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
                txtUsername?.attributedPlaceholder = placeholder
                return false
            }
        }
        if (txtEmail?.text == "") {
            var placeholder = NSAttributedString(string: "E-mail harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtEmail?.attributedPlaceholder = placeholder
            return false
        }
        if (txtEmail?.text!.rangeOfString("@") == nil) {
            var placeholder = NSAttributedString(string: "E-mail tidak valid", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtEmail?.text = ""
            txtEmail?.attributedPlaceholder = placeholder
            return false
        }
        if (txtPassword?.text == "") {
            var placeholder = NSAttributedString(string: "Kata sandi harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtPassword?.attributedPlaceholder = placeholder
            return false
        } else if (txtPassword?.text!.length < 6) {
            var placeholder = NSAttributedString(string: "Kata sandi minimal 6 karakter", attributes: [NSForegroundColorAttributeName : UIColor.redColor()])
            txtPassword?.attributedPlaceholder = placeholder
            txtPassword?.text = ""
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == self.txtUsername) {
            textField.resignFirstResponder()
            self.txtEmail?.becomeFirstResponder()
        } else if (textField == self.txtEmail) {
            textField.resignFirstResponder()
            self.txtPassword?.becomeFirstResponder()
        }  else if (textField == self.txtPassword) {
            textField.resignFirstResponder()
            self.txtRepeatPassword?.becomeFirstResponder()
        } else if (textField == self.txtRepeatPassword) {
            textField.resignFirstResponder()
            self.txtName?.becomeFirstResponder()
        } else if (textField == self.txtName) {
            textField.resignFirstResponder()
            self.registerPressed(textField)
        }
        return true
    }
    
    func register() {
        disableTextFields(NSNull)
        let username = txtUsername?.text
        let email = txtEmail?.text
        let password = txtPassword?.text
        let name = txtName?.text
        // API Migrasi
//        request(APIAuth.Register(username: username!, fullname: name!, email: email!, password: password!)).responseJSON {resp in
//            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Register")) {
//                let json = JSON(resp.result.value!)
//                let data = json["_data"]
//                
//                let m = UIApplication.appDelegate.managedObjectContext
//                CDUser.deleteAll()
//                let c = NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser
//                c.id = data["_id"].stringValue
//                c.email = data["email"].stringValue
//                c.username = data["username"].stringValue
//                c.fullname = data["fullname"].stringValue
//                
//                CDUserProfile.deleteAll()
//                let p = NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile
//                let pr = data["profile"]
//                p.pict = pr["pict"].stringValue
//                c.profiles = p
//                
//                CDUserOther.deleteAll()
//                let o = NSEntityDescription.insertNewObjectForEntityForName("CDUserOther", inManagedObjectContext: m!) as! CDUserOther
//                let oth = data["others"]
//                o.lastLogin = oth["last_login"].stringValue
//                o.registerTime = oth["register_time"].stringValue
//                c.others = o
//                
//                UIApplication.appDelegate.saveContext()
//                
//                CartProduct.registerAllAnonymousProductToEmail(User.EmailOrEmptyString)
//                
//                self.toProfileSetup(data["_id"].string!, userToken : data["token"].string!, userEmail : data["email"].string!, isSocmedAccount : false, loginMethod : "Basic", screenBeforeLogin : self.screenBeforeLogin)
//            } else {
//                self.btnRegister?.enabled = true
//            }
//        }
        
        // FOR TESTING (TO PROFILE SETUP DIRECTLY)
        //self.toProfileSetup("", userToken : "", userEmail : "", isSocmedAccount : false, loginMethod : "Basic", screenBeforeLogin : self.screenBeforeLogin)
        
        // FOR TESTING (TO PHONE VERIFICATION DIRECTLY)
        /*let phoneVerificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil).first as! PhoneVerificationViewController
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(phoneVerificationVC, animated: true)*/
    }
    
    func toProfileSetup(userId : String, userToken : String, userEmail : String, isSocmedAccount : Bool, loginMethod : String, screenBeforeLogin : String) {
        let profileSetupVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameProfileSetup, owner: nil, options: nil).first as! ProfileSetupViewController
        profileSetupVC.userRelatedDelegate = self.userRelatedDelegate
        profileSetupVC.userId = userId
        profileSetupVC.userToken = userToken
        profileSetupVC.userEmail = userEmail
        profileSetupVC.isSocmedAccount = isSocmedAccount
        profileSetupVC.loginMethod = loginMethod
        profileSetupVC.screenBeforeLogin = screenBeforeLogin
        profileSetupVC.isFromRegister = true
        self.navigationController?.pushViewController(profileSetupVC, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKindOfClass(UIButton.classForCoder()) || touch.view!.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - Facebook Login
    
    @IBAction func loginFacebookPressed(sender: AnyObject) {
        // Show loading
        loadingPanel?.hidden = false
        loading?.startAnimating()
        
        LoginViewController.LoginWithFacebook(self, screenBeforeLogin: self.screenBeforeLogin)
    }
    
    // MARK: - Twitter Login
    
    @IBAction func loginTwitterPressed(sender: AnyObject) {
        // Show loading
        loadingPanel.hidden = false
        loading.startAnimating()
        
        LoginViewController.LoginWithTwitter(self, screenBeforeLogin: self.screenBeforeLogin)
    }
    
    // MARK: - Path Login
    
    @IBAction func loginPathPressed(sender: AnyObject) {
        // Show loading
        loadingPanel.hidden = false
        loading.startAnimating()
        
        let pathLoginVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePathLogin, owner: nil, options: nil).first as! PathLoginViewController
        pathLoginVC.delegate = self
        self.navigationController?.pushViewController(pathLoginVC, animated: true)
    }
    
    func pathLoginSuccess(userData : JSON, token : String) {
        let pathId = userData["id"].string!
        let pathName = userData["name"].string!
        let email = userData["email"].string!
        if (userData["photo"] != nil) {
            let profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        }

        // API Migrasi
//        request(APIAuth.LoginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON {resp in
//            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Login Path")) {
//                let json = JSON(resp.result.value!)
//                let data = json["_data"]
//                
//                // Save in core data
//                let m = UIApplication.appDelegate.managedObjectContext
//                var user : CDUser? = CDUser.getOne()
//                if (user == nil) {
//                    user = (NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser)
//                }
//                user!.id = data["_id"].string!
//                user!.username = data["username"].string!
//                user!.email = data["email"].string!
//                user!.fullname = data["fullname"].string!
//                
//                var p : CDUserProfile? = CDUserProfile.getOne()
//                if (p == nil) {
//                    p = (NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile)
//                }
//                let pr = data["profile"]
//                p!.pict = pr["pict"].string!
//                
//                var o : CDUserOther? = CDUserOther.getOne()
//                if (o == nil) {
//                    o = (NSEntityDescription.insertNewObjectForEntityForName("CDUserOther", inManagedObjectContext: m!) as! CDUserOther)
//                }
//                o!.pathID = pathId
//                o!.pathUsername = pathName
//                o!.pathAccessToken = token
//                
//                user!.profiles = p!
//                user!.others = o!
//                UIApplication.appDelegate.saveContext()
//                
//                // Save in NSUserDefaults
//                NSUserDefaults.standardUserDefaults().setObject(token, forKey: "pathtoken")
//                NSUserDefaults.standardUserDefaults().synchronize()
//                
//                // Check if user have set his account
//                //self.checkProfileSetup(data["token"].string!)
//                LoginViewController.CheckProfileSetup(self, token: data["token"].string!, isSocmedAccount: true, loginMethod: "Path", screenBeforeLogin: self.screenBeforeLogin)
//            }
//        }
    }
    
    func hideLoading() {
        loadingPanel.hidden = true
        loading.stopAnimating()
        loading.hidden = true
    }
}