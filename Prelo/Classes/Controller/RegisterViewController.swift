//
//  RegisterViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

class RegisterViewController: BaseViewController, UIGestureRecognizerDelegate, PathLoginDelegate {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
        
        // Hide loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = true
        loading.stopAnimating()
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
        let username = txtUsername?.text
        let email = txtEmail?.text
        let password = txtPassword?.text
        let name = txtName?.text
        request(APIAuth.Register(username: username!, fullname: name!, email: email!, password: password!))
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
                        
                        let m = UIApplication.appDelegate.managedObjectContext
                        let c = NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser
                        c.id = data["username"].string!
                        c.email = data["email"].string!
                        c.fullname = data["fullname"].string!
                        
                        let p = NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile
                        let pr = data["profile"]
                        p.pict = pr["pict"].string!
                        
                        c.profiles = p
                        UIApplication.appDelegate.saveContext()
                        
                        CartProduct.registerAllAnonymousProductToEmail(User.EmailOrEmptyString)
                        
                        /*User.StoreUser(data, email : email!)
                        if (self.userRelatedDelegate != nil) {
                            self.userRelatedDelegate?.userLoggedIn!()
                        }
                        
                        if let c = CDUser.getOne()
                        {
                            Mixpanel.sharedInstance().identify(c.id)
                            Mixpanel.sharedInstance().people.set(["$first_name":c.fullname, "$name":c.email, "user_id":c.id])
                        } else {
                            Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                            Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
                        }*/ // TO BE DELETED
                        
                        self.toProfileSetup(data["_id"].string!, userToken : data["token"].string!, userEmail : data["email"].string!)
                    }
                }
        }
        
        // FOR TESTING (TO PROFILE SETUP DIRECTLY)
        //self.toProfileSetup("", userToken : "", userEmail : "")
        
        // FOR TESTING (TO PHONE VERIFICATION DIRECTLY)
        /*let phoneVerificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil).first as! PhoneVerificationViewController
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(phoneVerificationVC, animated: true)*/
    }
    
    func toProfileSetup(userId : String, userToken : String, userEmail : String) {
        let profileSetupVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameProfileSetup, owner: nil, options: nil).first as! ProfileSetupViewController
        profileSetupVC.userRelatedDelegate = self.userRelatedDelegate
        profileSetupVC.userId = userId
        profileSetupVC.userToken = userToken
        profileSetupVC.userEmail = userEmail
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
    
    // MARK : Facebook Login
    
    @IBAction func loginFacebookPressed(sender: AnyObject) {
        // Log in and get permission from facebook
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logInWithReadPermissions(["public_profile", "email"], handler: {(result : FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
            if (error != nil) { // Process error
                println("Process error")
                User.LogoutFacebook()
            } else if result.isCancelled { // User cancellation
                println("User cancel")
                User.LogoutFacebook()
            } else { // Success
                if result.grantedPermissions.contains("email") && result.grantedPermissions.contains("public_profile") {
                    // Do work
                    self.fbLogin()
                } else {
                    // Handle not getting permission
                }
            }
        })
    }
    
    func fbLogin()
    {
        // Show loading
        loadingPanel.hidden = false
        loading.startAnimating()
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email, name"], tokenString: FBSDKAccessToken.currentAccessToken().tokenString, version: nil, HTTPMethod: "GET")
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                
                if ((error) != nil) {
                    // Handle error
                    println("Error fetching facebook profile")
                } else {
                    // Handle Profile Photo URL String
                    let userId =  result["id"] as! String
                    let name = result["name"] as! String
                    let email = result["email"] as! String
                    let profilePictureUrl = "https://graph.facebook.com/\(userId)/picture?type=large" // FIXME: harusnya dipasang di profile kan?
                    let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                    
                    println("result = \(result)")
                    println("profilePictureUrl = \(profilePictureUrl)")
                    println("accessToken = \(accessToken)")
                    
                    request(APIAuth.LoginFacebook(email: email, fullname: name, fbId: userId, fbAccessToken: accessToken)).responseJSON {req, _, res, err in
                        println("Fb login req = \(req)")
                        if (err != nil) { // Terdapat error
                            Constant.showDialog("Warning", message: (err?.description)!)
                        } else {
                            let json = JSON(res!)
                            let data = json["_data"]
                            if (data == nil || data == []) { // Data kembalian kosong
                                println("Empty facebook login data")
                            } else { // Berhasil
                                println("Facebook login data = \(data)")
                                
                                // Save in core data
                                let m = UIApplication.appDelegate.managedObjectContext
                                var user : CDUser? = CDUser.getOne()
                                if (user == nil) {
                                    user = (NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser)
                                }
                                user!.id = data["username"].string!
                                user!.email = data["email"].string!
                                user!.fullname = data["fullname"].string!
                                
                                let p = NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile
                                let pr = data["profile"]
                                p.pict = pr["pict"].string!
                                
                                user!.profiles = p
                                UIApplication.appDelegate.saveContext()
                                
                                // Check if user have set his account
                                self.checkProfileSetup(data["token"].string!)
                            }
                        }
                    }
                }
            })
        }
    }
    
    // Return true if user have set his account in profile setup page
    // Param token is only used when user have set his account via setup account and phone verification
    func checkProfileSetup(token : String) {
        var isProfileSet : Bool = false
        
        // Set token first, because APIUser.Me need token
        User.SetToken(token)
        
        // Get user profile from API and check if required data is set
        // Required data: gender, phone, province, region, shipping
        request(APIUser.Me).responseJSON {req, _, res, err in
            println("Get profile req = \(req)")
            if (err != nil) { // Terdapat error
                Constant.showDialog("Warning", message: (err?.description)!)
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                if (data == nil || data == []) { // Data kembalian kosong
                    println("Empty profile data")
                } else { // Berhasil
                    println("Data = \(data)")
                    let userProfileData = UserProfile.instance(data)
                    
                    if (userProfileData!.gender != nil &&
                        userProfileData!.phone != nil &&
                        userProfileData!.provinceId != nil &&
                        userProfileData!.regionId != nil &&
                        userProfileData!.shippingIds != nil) {
                        isProfileSet = true
                    }
                    
                    if (isProfileSet) {
                        // Set in core data
                        let m = UIApplication.appDelegate.managedObjectContext
                        CDUser.deleteAll()
                        let user : CDUser = (NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser)
                        user.id = userProfileData!.id
                        user.email = userProfileData!.email
                        user.fullname = userProfileData!.fullname
                        
                        CDUserProfile.deleteAll()
                        let userProfile : CDUserProfile = (NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile)
                        user.profiles = userProfile
                        userProfile.regionID = userProfileData!.regionId!
                        userProfile.provinceID = userProfileData!.provinceId!
                        userProfile.gender = userProfileData!.gender!
                        userProfile.phone = userProfileData!.phone!
                        userProfile.pict = userProfileData!.profPictURL!.absoluteString!
                        // TODO: belum lengkap (postalCode, adress, desc, userOther jg), simpan token facebook kalau fungsi ini dipanggil dari fbLogin, simpan token path kalau fungsi ini dipanggil dari pathLoginSuccess
                        
                        // Tell app that the user has logged in
                        // Save in NSUserDefaults
                        User.StoreUser(userProfileData!.id, token : token, email : userProfileData!.email)
                        if let d = self.userRelatedDelegate
                        {
                            d.userLoggedIn!()
                        }
                        
                        CartProduct.registerAllAnonymousProductToEmail(User.EmailOrEmptyString)
                        
                        if let c = CDUser.getOne()
                        {
                            Mixpanel.sharedInstance().identify(c.id)
                            Mixpanel.sharedInstance().people.set(["$first_name":c.fullname!, "$name":c.email, "user_id":c.id])
                        } else {
                            Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                            Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
                        }
                    } else {
                        // Delete token because user is considered not logged in
                        User.SetToken(nil)
                    }
                    
                    // Hide loading
                    self.loadingPanel.hidden = true
                    self.loading.stopAnimating()
                    
                    // Next screen based on isProfileSet
                    if (isProfileSet) {
                        // Go to dashboard
                        self.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        // Go to profile setup
                        self.toProfileSetup(userProfileData!.id, userToken : token, userEmail : userProfileData!.email)
                    }
                }
            }
        }
    }
    
    // MARK : Path Login
    
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
        let profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?

        request(APIAuth.LoginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON {req, _, res, err in
            println("Path login req = \(req)")
            
            if (err != nil) { // Terdapat error
                Constant.showDialog("Warning", message: (err?.description)!)
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                if (data == nil || data == []) { // Data kembalian kosong
                    println("Empty path login data")
                } else { // Berhasil
                    println("Path login data: \(data)")
                    
                    // Save in core data
                    let m = UIApplication.appDelegate.managedObjectContext
                    var user : CDUser? = CDUser.getOne()
                    if (user == nil) {
                        user = (NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser)
                    }
                    user!.id = data["username"].string!
                    user!.email = data["email"].string!
                    user!.fullname = data["fullname"].string!
                    
                    let p = NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile
                    let pr = data["profile"]
                    p.pict = pr["pict"].string!
                    
                    user!.profiles = p
                    UIApplication.appDelegate.saveContext()
                    
                    // Check if user have set his account
                    self.checkProfileSetup(data["token"].string!)
                }
            }
        }
    }
}