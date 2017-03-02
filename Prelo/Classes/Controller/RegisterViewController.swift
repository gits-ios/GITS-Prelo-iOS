//
//  RegisterViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData
import Alamofire

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


// MARK: - Class

class RegisterViewController: BaseViewController, UIGestureRecognizerDelegate, PathLoginDelegate, UITextFieldDelegate {
    
    // MARK: - Properties
    
    @IBOutlet var scrollView : UIScrollView?
    @IBOutlet var txtUsername: UITextField!
    @IBOutlet var txtEmail : UITextField?
    @IBOutlet var txtPassword : UITextField?
    @IBOutlet var txtRepeatPassword : UITextField?
    @IBOutlet var txtName : UITextField?
    @IBOutlet var btnTermCondition : UIButton?
    @IBOutlet var btnRegister : UIButton?
    
    // Predefined values
    var screenBeforeLogin : String = ""
    var loginTabSwipeVC : LoginFransiskaViewController!
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
        
        txtName?.autocapitalizationType = .words
        
        // Set delegate
        txtUsername.delegate = self
        txtEmail!.delegate = self
        txtPassword!.delegate = self
        txtRepeatPassword!.delegate = self
        txtName!.delegate = self
        
        // Setup placeholder
        txtUsername.attributedPlaceholder = NSAttributedString(string: (txtUsername.placeholder)!, attributes: [NSForegroundColorAttributeName: UIColor.init(white: 1, alpha: 1)])
        txtEmail?.attributedPlaceholder = NSAttributedString(string: (txtEmail?.placeholder)!, attributes: [NSForegroundColorAttributeName: UIColor.init(white: 1, alpha: 1)])
        txtPassword?.attributedPlaceholder = NSAttributedString(string: (txtPassword?.placeholder)!, attributes: [NSForegroundColorAttributeName: UIColor.init(white: 1, alpha: 1)])
        txtRepeatPassword?.attributedPlaceholder = NSAttributedString(string: (txtRepeatPassword?.placeholder)!, attributes: [NSForegroundColorAttributeName: UIColor.init(white: 1, alpha: 1)])
        txtName?.attributedPlaceholder = NSAttributedString(string: (txtName?.placeholder)!, attributes: [NSForegroundColorAttributeName: UIColor.init(white: 1, alpha: 1)])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.Register)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Register)
        
        self.an_subscribeKeyboard(
            animations: {r, t, o in
                
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64+r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
                }
                
            }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    @IBAction func disableTextFields(_ sender : AnyObject)
    {
        txtUsername?.resignFirstResponder()
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
        txtRepeatPassword?.resignFirstResponder()
        txtName?.resignFirstResponder()
    }
    
    @IBAction func xBackPressed(_ sender: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func termConditionPressed(_ sender: AnyObject) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let termCondVC = mainStoryboard.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
        termCondVC.url = "https://prelo.co.id/syarat-ketentuan?ref=preloapp"
        termCondVC.titleString = "Syarat dan Ketentuan"
        let baseNavC = BaseNavigationController()
        baseNavC.setViewControllers([termCondVC], animated: false)
        self.present(baseNavC, animated: true, completion: nil)
    }
    
    func fieldsVerified() -> Bool {
        if (txtUsername?.text == "") {
            let placeholder = NSAttributedString(string: "Username harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)])
            txtUsername?.attributedPlaceholder = placeholder
            return false
        } else {
            let usernameRegex = "^[a-zA-Z0-9_]{4,15}$"
            if (txtUsername?.text!.match(usernameRegex) == false) {
                txtUsername?.text = ""
                let placeholder = NSAttributedString(string: "Username: 4-15 char (a-z, A-Z, 0-9, _)", attributes: [NSForegroundColorAttributeName : UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)])
                txtUsername?.attributedPlaceholder = placeholder
                return false
            }
        }
        if (txtEmail?.text == "") {
            let placeholder = NSAttributedString(string: "E-mail harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)])
            txtEmail?.attributedPlaceholder = placeholder
            return false
        } else if (txtEmail?.text!.match("[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}") == false) {
            let placeholder = NSAttributedString(string: "E-mail tidak valid", attributes: [NSForegroundColorAttributeName : UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)])
            txtEmail?.text = ""
            txtEmail?.attributedPlaceholder = placeholder
            return false
        }
        if (txtPassword?.text == "") {
            let placeholder = NSAttributedString(string: "Kata sandi harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)])
            txtPassword?.attributedPlaceholder = placeholder
            return false
        } else if (txtPassword?.text!.length < 6) {
            let placeholder = NSAttributedString(string: "Kata sandi minimal 6 karakter", attributes: [NSForegroundColorAttributeName : UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)])
            txtPassword?.attributedPlaceholder = placeholder
            txtPassword?.text = ""
            return false
        }
        if (txtRepeatPassword?.text == "") {
            let placeholder = NSAttributedString(string: "Kata sandi harus diulangi", attributes: [NSForegroundColorAttributeName : UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)])
            txtRepeatPassword?.attributedPlaceholder = placeholder
            return false
        }
        if (txtPassword?.text != txtRepeatPassword?.text) {
            let placeholder = NSAttributedString(string: "Kata sandi tidak cocok", attributes: [NSForegroundColorAttributeName : UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)])
            txtRepeatPassword?.text = ""
            txtRepeatPassword?.attributedPlaceholder = placeholder
            return false
        }
        if (txtName?.text == "") {
            let placeholder = NSAttributedString(string: "Nama harus diisi", attributes: [NSForegroundColorAttributeName : UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)])
            txtName?.attributedPlaceholder = placeholder
            return false
        }
        return true
    }
    
    @IBAction func registerPressed(_ sender : AnyObject) {
        if (fieldsVerified()) {
            self.btnRegister?.isEnabled = false
            register()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
        disableTextFields(0 as AnyObject)
        let username = txtUsername?.text
        let email = txtEmail?.text
        let password = txtPassword?.text
        let name = txtName?.text
        // API Migrasi
        let _ = request(APIAuth.register(username: username!, fullname: name!, email: email!, password: password!)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Register")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                let m = UIApplication.appDelegate.managedObjectContext
                _ = CDUser.deleteAll()
                let c = NSEntityDescription.insertNewObject(forEntityName: "CDUser", into: m) as! CDUser
                c.id = data["_id"].stringValue
                c.email = data["email"].stringValue
                c.username = data["username"].stringValue
                c.fullname = data["fullname"].stringValue
                
                _ = CDUserProfile.deleteAll()
                let p = NSEntityDescription.insertNewObject(forEntityName: "CDUserProfile", into: m) as! CDUserProfile
                let pr = data["profile"]
                p.pict = pr["pict"].stringValue
                c.profiles = p
                
                _ = CDUserOther.deleteAll()
                let o = NSEntityDescription.insertNewObject(forEntityName: "CDUserOther", into: m) as! CDUserOther
                let oth = data["others"]
                o.lastLogin = oth["last_login"].stringValue
                o.registerTime = oth["register_time"].stringValue
                c.others = o
                
                UIApplication.appDelegate.saveContext()
                
                CartProduct.registerAllAnonymousProductToEmail(User.EmailOrEmptyString)
                
                // Prelo Analytic - Register
                let pdata = [
                    "Email" : data["email"].stringValue,
                    "Username" : data["username"].stringValue,
                    "Register OS" : "iOS",
                    "Register Method" : "Basic"
                ]
                AnalyticManager.sharedInstance.sendWithUserId(eventType: PreloAnalyticEvent.Register, data: pdata, previousScreen: self.screenBeforeLogin, loginMethod: "Basic", userId: c.id)
                
                self.toProfileSetup(data["_id"].string!, userToken : data["token"].string!, userEmail : data["email"].string!, isSocmedAccount : false, loginMethod : "Basic", screenBeforeLogin : self.screenBeforeLogin)
            } else {
                self.btnRegister?.isEnabled = true
            }
        }
        
        // FOR TESTING (TO PROFILE SETUP DIRECTLY)
        //self.toProfileSetup("", userToken : "", userEmail : "", isSocmedAccount : false, loginMethod : "Basic", screenBeforeLogin : self.screenBeforeLogin)
        
        // FOR TESTING (TO PHONE VERIFICATION DIRECTLY)
        /*let phoneVerificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil).first as! PhoneVerificationViewController
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(phoneVerificationVC, animated: true)*/
    }
    
    func toProfileSetup(_ userId : String, userToken : String, userEmail : String, isSocmedAccount : Bool, loginMethod : String, screenBeforeLogin : String) {
        let profileSetupVC = Bundle.main.loadNibNamed(Tags.XibNameProfileSetup, owner: nil, options: nil)?.first as! ProfileSetupViewController
        profileSetupVC.userRelatedDelegate = self.userRelatedDelegate
        profileSetupVC.userId = userId
        profileSetupVC.userToken = userToken
        profileSetupVC.userEmail = userEmail
        profileSetupVC.isSocmedAccount = isSocmedAccount
        profileSetupVC.loginMethod = loginMethod
        profileSetupVC.screenBeforeLogin = screenBeforeLogin
        profileSetupVC.isFromRegister = true
        self.navigationController?.navigationBar.backgroundColor = Theme.PrimaryColor // Reset navbar color
        self.navigationController?.pushViewController(profileSetupVC, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - Facebook Login
    
    @IBAction func loginFacebookPressed(_ sender: AnyObject) {
        // Show loading
        self.showLoading()
        
        let p = ["sender" : self, "screenBeforeLogin" : self.screenBeforeLogin as AnyObject] as [String : AnyObject]
        LoginViewController.LoginWithFacebook(p, onFinish: { resultDict in
            LoginViewController.AfterLoginFacebook(resultDict)
        })
    }
    
    // MARK: - Twitter Login
    
    @IBAction func loginTwitterPressed(_ sender: AnyObject) {
        // Show loading
        self.showLoading()
        
        let p = ["sender" : self, "screenBeforeLogin" : self.screenBeforeLogin as AnyObject] as [String : AnyObject]
        LoginViewController.LoginWithTwitter(p, onFinish: { resultDict in
            LoginViewController.AfterLoginTwitter(resultDict)
        })
    }
    
    // MARK: - Path Login
    
    @IBAction func loginPathPressed(_ sender: AnyObject) {
        // Show loading
        self.showLoading()
        
        let pathLoginVC = Bundle.main.loadNibNamed(Tags.XibNamePathLogin, owner: nil, options: nil)?.first as! PathLoginViewController
        pathLoginVC.delegate = self
        self.navigationController?.pushViewController(pathLoginVC, animated: true)
    }
    
    func pathLoginSuccess(_ userData : JSON, token : String) {
        let pathId = userData["id"].string!
        let pathName = userData["name"].string!
        let email = userData["email"].string!
        if (userData["photo"] != nil) {
            _ = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        }

        // API Migrasi
        let _ = request(APIAuth.loginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Path")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                // Save in core data
                let m = UIApplication.appDelegate.managedObjectContext
                var user : CDUser? = CDUser.getOne()
                if (user == nil) {
                    user = (NSEntityDescription.insertNewObject(forEntityName: "CDUser", into: m) as! CDUser)
                }
                user!.id = data["_id"].string!
                user!.username = data["username"].string!
                user!.email = data["email"].string!
                user!.fullname = data["fullname"].string!
                
                var p : CDUserProfile? = CDUserProfile.getOne()
                if (p == nil) {
                    p = (NSEntityDescription.insertNewObject(forEntityName: "CDUserProfile", into: m) as! CDUserProfile)
                }
                let pr = data["profile"]
                p!.pict = pr["pict"].string!
                
                var o : CDUserOther? = CDUserOther.getOne()
                if (o == nil) {
                    o = (NSEntityDescription.insertNewObject(forEntityName: "CDUserOther", into: m) as! CDUserOther)
                }
                o!.pathID = pathId
                o!.pathUsername = pathName
                o!.pathAccessToken = token
                
                user!.profiles = p!
                user!.others = o!
                UIApplication.appDelegate.saveContext()
                
                // Save in NSUserDefaults
                UserDefaults.standard.set(token, forKey: "pathtoken")
                UserDefaults.standard.synchronize()
                
                // Check if user have set his account
                //self.checkProfileSetup(data["token"].string!)
                LoginViewController.CheckProfileSetup(self, token: data["token"].string!, isSocmedAccount: true, loginMethod: "Path", screenBeforeLogin: self.screenBeforeLogin, isNeedPayload: true)
            }
        }
    }
    
    // MARK: - Other functions
    
    func hideLoading() {
        self.loginTabSwipeVC.hideLoading()
    }
    
    func showLoading() {
        self.loginTabSwipeVC.showLoading()
    }
}
