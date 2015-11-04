//
//  LoginViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/30/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CoreData
//import UIViewController_KeyboardAnimation

class LoginViewController: BaseViewController, UIGestureRecognizerDelegate, UITextFieldDelegate, UIScrollViewDelegate, PathLoginDelegate, UIAlertViewDelegate {

    @IBOutlet var scrollView : UIScrollView?
    @IBOutlet var txtEmail : UITextField?
    @IBOutlet var txtPassword : UITextField?
    
    @IBOutlet var btnLogin : UIButton?
    
    @IBOutlet weak var loadingPanel: UIView?
    @IBOutlet weak var loading: UIActivityIndicatorView?
    
    
    var navController : UINavigationController?
    
    static func Show(parent : UIViewController, userRelatedDelegate : UserRelatedDelegate?, animated : Bool)
    {
        let l = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdLogin) as! LoginViewController
        l.userRelatedDelegate = userRelatedDelegate
        
        let n = BaseNavigationController(rootViewController : l)
        n.setNavigationBarHidden(true, animated: false)
        
        parent.presentViewController(n, animated: animated, completion: nil)
    }
    
    static func SendDeviceRegId(#onFinish: ()?) {
        // Store device registration ID to server
        // Di titik inilah user dianggap login/logout, sehingga di titik inilah user mulai/berhenti menerima push notification
        // Get device token
        var deviceToken : String = ""
        if (User.IsLoggedIn && NSUserDefaults.standardUserDefaults().stringForKey("deviceregid") != nil) {
            deviceToken = NSUserDefaults.standardUserDefaults().stringForKey("deviceregid")!
        }
        request(APIUser.SetDeviceRegId(deviceRegId: deviceToken)).responseJSON {req, _, res, err in
            println("Set deviceRegId req = \(req)")
            if (err != nil) { // Terdapat error
                println("Error setting deviceRegId: \(err!.description)")
            } else {
                let json = JSON(res!)
                if (json["_data"] == nil) {
                    let obj : [String : String] = res as! [String : String]
                    let message = obj["_message"]
                    if (message != nil) {
                        println("Error setting deviceRegId, message: \(message!)")
                    }
                } else {
                    let isSuccess = json["_data"].int!
                    if (isSuccess == 1) { // Berhasil
                        println("Kode deviceRegId berhasil ditambahkan: \(deviceToken)")
                    } else { // Gagal
                        println("Error setting deviceRegId")
                    }
                }
            }
            
            // Execute onFinish
            if (onFinish != nil) {
                onFinish
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)

        scrollView?.delegate = self
        
        txtEmail?.placeholder = "Username / Email"
        
        scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
        
        // Hide loading
        loadingPanel?.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel?.hidden = true
        loading?.stopAnimating()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().track("Login Page")
        
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
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    @IBAction func viewTapped(sender : AnyObject)
    {
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
    }
    
    @IBAction func signUpTapped(sender : AnyObject)
    {
        let registerVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameRegister, owner: nil, options: nil).first as! RegisterViewController
        registerVC.userRelatedDelegate = self.userRelatedDelegate
        self.navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @IBAction func forgotPassword(sender : AnyObject?)
    {
        let a = UIAlertView(title: "Lupa Password", message: "Masukan Username / Email", delegate: self, cancelButtonTitle: "Batal", otherButtonTitles: "OK")
        a.alertViewStyle = UIAlertViewStyle.PlainTextInput
        a.show()
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == 1)
        {
            request(.POST, "http://dev.prelo.id/api/auth/forgot_password", parameters: ["email":(alertView.textFieldAtIndex(0)?.text)!]).responseJSON { req, resp, res, err in
                println(res)
                UIAlertView.SimpleShow("Perhatian", message: "Email pemberitahuan sudah kami kirim ke alamat email kamu :)")
            }
        }
    }
    
    @IBAction func login(sender : AnyObject)
    {
        btnLogin?.enabled = false
        sendLogin()
    }
    
    func sendLogin()
    {
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
        
        btnLogin?.enabled = false
        
        let email = txtEmail?.text
        
        if (email == "")
        {
            UIAlertView.SimpleShow("Perhatian", message: "Silakan isi username / email")
            return
        }
        
        request(APIAuth.Login(email: email!, password: (txtPassword?.text)!))
            .responseJSON
            {_, _, json, err in
                if (err != nil) {
                    Constant.showDialog("Warning", message: (err?.description)!)
                    self.btnLogin?.enabled = true
                } else {
                    let res = JSON(json!)
                    let data = res["_data"]
                    if (data == nil) {
                        let obj : [String : String] = json as! [String : String]
                        let message = obj["_message"]
                        Constant.showDialog("Warning", message: message!)
                        self.btnLogin?.enabled = true
                    } else {
                        println(data)
                        self.getProfile(data["token"].string!)
                    }
                }
        }
    }
    
    // Token is only stored when user have completed setup account and phone verification
    func getProfile(token : String)
    {
        // Set token first, because APIUser.Me need token
        User.SetToken(token)
        
        request(APIUser.Me)
            .responseJSON{_, resp, res, err in
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
                    self.btnLogin?.enabled = true
                    let json = JSON(res!)["_data"]
                    
                    println(json)
                    
                    // Cek apakah user telah melewati setup account dan phone verification
                    
                    var isProfileSet : Bool = false
                    
                    let userProfileData = UserProfile.instance(json)
                    if (userProfileData!.gender != nil &&
                        userProfileData!.phone != nil &&
                        userProfileData!.provinceId != nil &&
                        userProfileData!.regionId != nil &&
                        userProfileData!.shippingIds != nil) {
                            isProfileSet = true
                    }
                    
                    if (isProfileSet) {
                        // Save in core data
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
                        userProfile.gender = userProfileData!.gender
                        userProfile.phone = userProfileData!.phone
                        userProfile.pict = userProfileData!.profPictURL!.absoluteString!
                        userProfile.postalCode = userProfileData!.postalCode
                        userProfile.address = userProfileData!.address
                        userProfile.desc = userProfileData!.desc
                        
                        CDUserOther.deleteAll()
                        let userOther : CDUserOther = (NSEntityDescription.insertNewObjectForEntityForName("CDUserOther", inManagedObjectContext: m!) as! CDUserOther)
                        userOther.shippingIDs = NSKeyedArchiver.archivedDataWithRootObject(userProfileData!.shippingIds!)
                        userOther.fbAccessToken = (userProfileData!.fbAccessToken != nil) ? (userProfileData!.fbAccessToken!) : ""
                        userOther.fbID = (userProfileData!.fbId != nil) ? (userProfileData!.fbId!) : ""
                        userOther.fbUsername = (userProfileData!.fbUsername != nil) ? (userProfileData!.fbUsername!) : ""
                        userOther.instagramAccessToken = (userProfileData!.instagramAccessToken != nil) ? (userProfileData!.instagramAccessToken!) : ""
                        userOther.instagramID = (userProfileData!.instagramId != nil) ? (userProfileData!.instagramId!) : ""
                        userOther.instagramUsername = (userProfileData!.instagramUsername != nil) ? (userProfileData!.instagramUsername!) : ""
                        userOther.lastLogin = (userProfileData!.lastLogin != nil) ? (userProfileData!.lastLogin!) : ""
                        userOther.phoneCode = (userProfileData!.phoneCode != nil) ? (userProfileData!.phoneCode!) : ""
                        userOther.phoneVerified = (userProfileData!.isPhoneVerified != nil) ? (userProfileData!.isPhoneVerified!) : false
                        userOther.registerTime = (userProfileData!.registerTime != nil) ? (userProfileData!.registerTime!) : ""
                        userOther.twitterAccessToken = (userProfileData!.twitterAccessToken != nil) ? (userProfileData!.twitterAccessToken!) : ""
                        userOther.twitterID = (userProfileData!.twitterId != nil) ? (userProfileData!.twitterId!) : ""
                        userOther.twitterTokenSecret = (userProfileData!.twitterTokenSecret != nil) ? (userProfileData!.twitterTokenSecret!) : ""
                        // TODO: belum lengkap (emailVerified, isActiveSeller, seller, shopName, shopPermalink, simplePermalink)
                        
                        // Refresh notifications
                        NotificationPageViewController.refreshNotifications()
                        
                        CartProduct.registerAllAnonymousProductToEmail(User.EmailOrEmptyString)
                        
                        User.StoreUser(userProfileData!.id, token: token, email: userProfileData!.email)
                        if (self.userRelatedDelegate != nil) {
                            self.userRelatedDelegate?.userLoggedIn!()
                        }
                        
                        //Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                        
                        if let c = CDUser.getOne()
                        {
                            Mixpanel.sharedInstance().identify(c.id)
                            Mixpanel.sharedInstance().people.set(["$first_name":c.fullname!, "$name":c.email, "user_id":c.id])
                        } else {
                            Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                            Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
                        }
                        
                        Mixpanel.sharedInstance().track("Logged In")
                    } else {
                        // Delete token because user is considered not logged in
                        User.SetToken(nil)
                    }
                    
                    // Next screen based on isProfileSet
                    if (isProfileSet) {
                        // If user haven't verified phone number, goto PhoneVerificationVC
                        if (userProfileData?.isPhoneVerified != nil && userProfileData?.isPhoneVerified! == true) {
                            // Send deviceRegId before dismiss
                            LoginViewController.SendDeviceRegId(onFinish: self.dismiss())
                        } else {
                            // Delete token because user is considered not logged in
                            User.SetToken(nil)
                            
                            // Goto PhoneVerificationVC
                            self.toPhoneVerification(userProfileData!.id, userToken : token, userEmail : userProfileData!.email)
                        }
                    } else {
                        // Go to profile setup
                        self.toProfileSetup(userProfileData!.id, userToken : token, userEmail : userProfileData!.email, isSocmedAccount : false)
                    }
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("userLoggedIn", object: nil)
                } else {
                    User.Logout()
                    self.btnLogin?.enabled = true
                }
        }
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == txtEmail) {
            txtPassword?.becomeFirstResponder()
        } else {
            sendLogin()
        }
        
        return false
    }
    
    @IBAction func dismissLogin()
    {
        if (self.userRelatedDelegate != nil)
        {
            self.userRelatedDelegate?.userCancelLogin!()
        }
        self.dismiss()
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - Facebook Login
    
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
        loadingPanel?.hidden = false
        loading?.startAnimating()
        
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
                        userProfile.postalCode = userProfileData!.postalCode
                        userProfile.address = userProfileData!.address
                        userProfile.desc = userProfileData!.desc
                        
                        CDUserOther.deleteAll()
                        let userOther : CDUserOther = (NSEntityDescription.insertNewObjectForEntityForName("CDUserOther", inManagedObjectContext: m!) as! CDUserOther)
                        var shippingArr : [String] = []
                        userOther.shippingIDs = NSKeyedArchiver.archivedDataWithRootObject(userProfileData!.shippingIds!)
                        userOther.fbAccessToken = (userProfileData!.fbAccessToken != nil) ? (userProfileData!.fbAccessToken!) : ""
                        userOther.fbID = (userProfileData!.fbId != nil) ? (userProfileData!.fbId!) : ""
                        userOther.fbUsername = (userProfileData!.fbUsername != nil) ? (userProfileData!.fbUsername!) : ""
                        userOther.instagramAccessToken = (userProfileData!.instagramAccessToken != nil) ? (userProfileData!.instagramAccessToken!) : ""
                        userOther.instagramID = (userProfileData!.instagramId != nil) ? (userProfileData!.instagramId!) : ""
                        userOther.instagramUsername = (userProfileData!.instagramUsername != nil) ? (userProfileData!.instagramUsername!) : ""
                        userOther.lastLogin = (userProfileData!.lastLogin != nil) ? (userProfileData!.lastLogin!) : ""
                        userOther.phoneCode = (userProfileData!.phoneCode != nil) ? (userProfileData!.phoneCode!) : ""
                        userOther.phoneVerified = (userProfileData!.isPhoneVerified != nil) ? (userProfileData!.isPhoneVerified!) : false
                        userOther.registerTime = (userProfileData!.registerTime != nil) ? (userProfileData!.registerTime!) : ""
                        userOther.twitterAccessToken = (userProfileData!.twitterAccessToken != nil) ? (userProfileData!.twitterAccessToken!) : ""
                        userOther.twitterID = (userProfileData!.twitterId != nil) ? (userProfileData!.twitterId!) : ""
                        userOther.twitterTokenSecret = (userProfileData!.twitterTokenSecret != nil) ? (userProfileData!.twitterTokenSecret!) : ""
                        // TODO: belum lengkap (emailVerified, isActiveSeller, seller, shopName, shopPermalink, simplePermalink)
                        
                        // Refresh notifications
                        NotificationPageViewController.refreshNotifications()
                        
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
                    self.loadingPanel?.hidden = true
                    self.loading?.stopAnimating()
                    
                    // Next screen based on isProfileSet
                    if (isProfileSet) {
                        // If user haven't verified phone number, goto PhoneVerificationVC
                        if (userProfileData?.isPhoneVerified != nil && userProfileData?.isPhoneVerified! == true) {
                            // Send deviceRegId before dismiss
                            LoginViewController.SendDeviceRegId(onFinish: self.dismiss())
                        } else {
                            // Delete token because user is considered not logged in
                            User.SetToken(nil)
                            
                            // Goto PhoneVerificationVC
                            self.toPhoneVerification(userProfileData!.id, userToken : token, userEmail : userProfileData!.email)
                        }
                    } else {
                        // Go to profile setup
                        self.toProfileSetup(userProfileData!.id, userToken : token, userEmail : userProfileData!.email, isSocmedAccount : true)
                    }
                }
            }
        }
    }
    
    // MARK: - Path Login
    
    @IBAction func loginPathPressed(sender: AnyObject) {
        // Show loading
        loadingPanel?.hidden = false
        loading?.startAnimating()
        
        let pathLoginVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePathLogin, owner: nil, options: nil).first as! PathLoginViewController
        pathLoginVC.delegate = self
        self.navigationController?.pushViewController(pathLoginVC, animated: true)
    }
    
    func pathLoginSuccess(userData : JSON, token : String) {
        let pathId = userData["id"].string!
        let pathName = userData["name"].string!
        let email = userData["email"].string!
        var profilePictureUrl : String?
        if (userData["photo"] != nil) {
            profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        }
        
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
                    
                    // Save in NSUserDefaults
                    NSUserDefaults.standardUserDefaults().setObject(token, forKey: "pathtoken")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    // Check if user have set his account
                    self.checkProfileSetup(data["token"].string!)
                }
            }
        }
    }
    
    func hideLoading() {
        loadingPanel?.hidden = true
        loading?.stopAnimating()
    }
    
    // MARK: Other functions
    
    func toProfileSetup(userId : String, userToken : String, userEmail : String, isSocmedAccount : Bool) {
        let profileSetupVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameProfileSetup, owner: nil, options: nil).first as! ProfileSetupViewController
        profileSetupVC.userRelatedDelegate = self.userRelatedDelegate
        profileSetupVC.userId = userId
        profileSetupVC.userToken = userToken
        profileSetupVC.userEmail = userEmail
        profileSetupVC.isSocmedAccount = isSocmedAccount
        self.navigationController?.pushViewController(profileSetupVC, animated: true)
    }
    
    func toPhoneVerification(userId : String, userToken : String, userEmail : String) {
        let phoneVerificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil).first as! PhoneVerificationViewController
        phoneVerificationVC.userRelatedDelegate = self.userRelatedDelegate
        phoneVerificationVC.userId = userId
        phoneVerificationVC.userToken = userToken
        phoneVerificationVC.userEmail = userEmail
        phoneVerificationVC.isShowBackBtn = false
        self.navigationController?.pushViewController(phoneVerificationVC, animated: true)
    }
}
