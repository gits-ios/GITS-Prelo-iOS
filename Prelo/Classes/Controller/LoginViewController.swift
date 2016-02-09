//
//  LoginViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/30/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CoreData
import TwitterKit
import Crashlytics
//import UIViewController_KeyboardAnimation

class LoginViewController: BaseViewController, UIGestureRecognizerDelegate, UITextFieldDelegate, UIScrollViewDelegate, PathLoginDelegate, UIAlertViewDelegate {

    @IBOutlet var scrollView : UIScrollView?
    @IBOutlet var txtEmail : UITextField?
    @IBOutlet var txtPassword : UITextField?
    
    @IBOutlet var btnLogin : UIButton?
    
    @IBOutlet weak var loadingPanel: UIView?
    @IBOutlet weak var loading: UIActivityIndicatorView?
    
    @IBOutlet var btnClose : UIButton?
    @IBOutlet weak var groupRegister: UIView!
    var isFromTourVC : Bool = false
    var screenBeforeLogin : String = ""
    
    var navController : UINavigationController?
    
    static func Show(parent : UIViewController, userRelatedDelegate : UserRelatedDelegate?, animated : Bool)
    {
        LoginViewController.Show(parent, userRelatedDelegate: userRelatedDelegate, animated: animated, isFromTourVC: false)
    }
    
    static func Show(parent : UIViewController, userRelatedDelegate : UserRelatedDelegate?, animated : Bool, isFromTourVC : Bool)
    {
        let l = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdLogin) as! LoginViewController
        let parentType = "\(parent.dynamicType)"
        if (parentType == "Prelo.KumangTabBarViewController") {
            if (isFromTourVC) {
                l.screenBeforeLogin = PageName.SetCategoryPreferences
            } else {
                l.screenBeforeLogin = PageName.DashboardLoggedOut
            }
        } else if (parentType == "Prelo.CartViewController") {
            l.screenBeforeLogin = PageName.Checkout
        } else if (parentType == "Prelo.AddProductViewController" || parentType == "Prelo.AddProductViewController2") {
            l.screenBeforeLogin = PageName.AddProduct
        } else if (parentType == "Prelo.NotificationPageViewController") {
            l.screenBeforeLogin = PageName.Notification
        } else if (parentType == "Prelo.ProductDetailViewController") {
            l.screenBeforeLogin = PageName.ProductDetail
        }
        //println("screenBeforeLogin = \(l.screenBeforeLogin)")
        l.userRelatedDelegate = userRelatedDelegate
        l.isFromTourVC = isFromTourVC
        
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
        request(APIUser.SetDeviceRegId(deviceRegId: deviceToken)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Set Device Registration ID")) {
                let json = JSON(res!)
                let isSuccess = json["_data"].int!
                if (isSuccess == 1) { // Berhasil
                    println("Kode deviceRegId berhasil ditambahkan: \(deviceToken)")
                } else { // Gagal
                    println("Error setting deviceRegId")
                }
            }
            
            // Execute onFinish
            if (onFinish != nil) {
                onFinish
            }
        }
    }
    
    // Return true if user have set his account in profile setup page
    // Param token is only used when user have set his account via setup account and phone verification
    static func CheckProfileSetup(sender : BaseViewController, token : String, isSocmedAccount : Bool, loginMethod : String, screenBeforeLogin : String) {
        let vcLogin = sender as? LoginViewController
        let vcRegister = sender as? RegisterViewController
        
        var isProfileSet : Bool = false
        
        // Set token first, because APIUser.Me need token
        User.SetToken(token)
        
        // Get user profile from API and check if required data is set
        // Required data: gender, phone, province, region, shipping
        request(APIUser.Me).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Profil Pengguna")) {
                let json = JSON(res!)
                let data = json["_data"]
                
                let userProfileData = UserProfile.instance(data)
                
                // Update user preferenced categories in NSUserDefaults
                let catPrefIds = userProfileData!.categoryPrefIds
                if (catPrefIds != nil && catPrefIds!.count >= 3) {
                    NSUserDefaults.standardUserDefaults().setObject(catPrefIds![0], forKey: UserDefaultsKey.CategoryPref1)
                    NSUserDefaults.standardUserDefaults().setObject(catPrefIds![1], forKey: UserDefaultsKey.CategoryPref2)
                    NSUserDefaults.standardUserDefaults().setObject(catPrefIds![2], forKey: UserDefaultsKey.CategoryPref3)
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
                
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
                    user.username = userProfileData!.username
                    
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
                    userOther.shippingIDs = NSKeyedArchiver.archivedDataWithRootObject(userProfileData!.shippingIds!)
                    userOther.lastLogin = (userProfileData!.lastLogin != nil) ? (userProfileData!.lastLogin!) : ""
                    userOther.phoneCode = (userProfileData!.phoneCode != nil) ? (userProfileData!.phoneCode!) : ""
                    userOther.phoneVerified = (userProfileData!.isPhoneVerified != nil) ? (userProfileData!.isPhoneVerified!) : false
                    userOther.registerTime = (userProfileData!.registerTime != nil) ? (userProfileData!.registerTime!) : ""
                    userOther.fbAccessToken = userProfileData!.fbAccessToken
                    userOther.fbID = userProfileData!.fbId
                    userOther.fbUsername = userProfileData!.fbUsername
                    userOther.instagramAccessToken = userProfileData!.instagramAccessToken
                    userOther.instagramID = userProfileData!.instagramId
                    userOther.instagramUsername = userProfileData!.instagramUsername
                    userOther.twitterAccessToken = userProfileData!.twitterAccessToken
                    userOther.twitterID = userProfileData!.twitterId
                    userOther.twitterUsername = userProfileData!.twitterUsername
                    userOther.twitterTokenSecret = userProfileData!.twitterTokenSecret
                    userOther.pathAccessToken = userProfileData!.pathAccessToken
                    userOther.pathID = userProfileData!.pathId
                    userOther.pathUsername = userProfileData!.pathUsername
                    userOther.emailVerified = ((userProfileData!.isEmailVerified != nil) && (userProfileData!.isEmailVerified! == true)) ? 1 : 0
                    // TODO: belum lengkap (isActiveSeller, seller, shopName, shopPermalink, simplePermalink)
                    
                    // Refresh notifications
                    NotificationPageViewController.refreshNotifications()
                    
                    // Tell app that the user has logged in
                    // Save in NSUserDefaults
                    User.StoreUser(userProfileData!.id, token : token, email : userProfileData!.email)
                    if let d = sender.userRelatedDelegate
                    {
                        d.userLoggedIn!()
                    }
                    
                    // Memanggil notif observer yg mengimplement userLoggedIn (AppDelegate)
                    // Di dalamnya akan memanggil MessagePool.start()
                    NSNotificationCenter.defaultCenter().postNotificationName("userLoggedIn", object: nil)
                    
                    CartProduct.registerAllAnonymousProductToEmail(User.EmailOrEmptyString)
                    
                    // Mixpanel
                    if let c = CDUser.getOne() {
                        let provinceName = CDProvince.getProvinceNameWithID(c.profiles.provinceID)
                        let regionName = CDRegion.getRegionNameWithID(c.profiles.regionID)
                        let sp = [
                            "User ID" : c.id,
                            "Email" : c.email,
                            "Username" : c.username,
                            "Phone" : ((c.profiles.phone != nil) ? c.profiles.phone! : ""),
                            "Fullname" : ((c.fullname != nil) ? c.fullname! : ""),
                            "Gender" : ((c.profiles.gender != nil) ? c.profiles.gender! : ""),
                            "Province Input" : ((provinceName != nil) ? provinceName! : ""),
                            "City Input" : ((regionName != nil) ? regionName! : ""),
                            "Referral Code Used" : userProfileData!.json["others"]["referral_code_used"].stringValue,
                            "Login Method" : loginMethod,
                            "Orders Purchased Count" : 0,
                            "Items Purchased Count" : 0,
                            "Items Purchased Categories 1" : [],
                            "Items Purchased Categories 2" : [],
                            "Items Purchased Categories 3" : [],
                            "Items Sold Count" : 0,
                            "Lifetime Value Purchased" : 0,
                            "Lifetime Value Commission" : 0,
                            "Lifetime Value Sold" : 0,
                            "Items in Cart Count" : 0
                        ]
                        Mixpanel.sharedInstance().registerSuperProperties(sp)
                        
                        let pt = [
                            "Previous Screen" : screenBeforeLogin,
                            "Login Method" : loginMethod
                        ]
                        Mixpanel.trackEvent(MixpanelEvent.Login, properties: pt)
                        
                        Mixpanel.sharedInstance().identify(c.id)
                    }
                    /*if let c = CDUser.getOne()
                    {
                    Mixpanel.sharedInstance().identify(c.id)
                    Mixpanel.sharedInstance().people.set(["$first_name":c.fullname!, "$name":c.email, "user_id":c.id])
                    } else {
                    Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                    Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
                    }*/
                    
                    // Set crashlytics user information
                    Crashlytics.sharedInstance().setUserIdentifier(user.profiles.phone!)
                    Crashlytics.sharedInstance().setUserEmail(user.email)
                    Crashlytics.sharedInstance().setUserName(user.fullname!)
                } else {
                    // Delete token because user is considered not logged in
                    User.SetToken(nil)
                }
                
                // Next screen based on isProfileSet
                if (isProfileSet) {
                    // If user haven't verified phone number, goto PhoneVerificationVC
                    if (userProfileData?.isPhoneVerified != nil && userProfileData?.isPhoneVerified! == true) {
                        // Send deviceRegId before dismiss
                        LoginViewController.SendDeviceRegId(onFinish: sender.dismiss())
                    } else {
                        // Delete token because user is considered not logged in
                        User.SetToken(nil)
                        
                        // Goto PhoneVerificationVC
                        let phoneVerificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil).first as! PhoneVerificationViewController
                        phoneVerificationVC.userRelatedDelegate = sender.userRelatedDelegate
                        phoneVerificationVC.userId = userProfileData!.id
                        phoneVerificationVC.userToken = token
                        phoneVerificationVC.userEmail = userProfileData!.email
                        phoneVerificationVC.isShowBackBtn = false
                        phoneVerificationVC.loginMethod = loginMethod
                        sender.navigationController?.pushViewController(phoneVerificationVC, animated: true)
                    }
                } else {
                    // Go to profile setup
                    let profileSetupVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameProfileSetup, owner: nil, options: nil).first as! ProfileSetupViewController
                    profileSetupVC.userRelatedDelegate = sender.userRelatedDelegate
                    profileSetupVC.userId = userProfileData!.id
                    profileSetupVC.userToken = token
                    profileSetupVC.userEmail = userProfileData!.email
                    profileSetupVC.isSocmedAccount = isSocmedAccount
                    profileSetupVC.loginMethod = loginMethod
                    profileSetupVC.screenBeforeLogin = screenBeforeLogin
                    sender.navigationController?.pushViewController(profileSetupVC, animated: true)
                }
            } else {
                // Delete token because user is considered not logged in
                User.SetToken(nil)
                
                if (vcLogin != nil) {
                    vcLogin!.hideLoading()
                }
                if (vcRegister != nil) {
                    vcRegister!.hideLoading()
                }
            }
        }
    }
    
    static func LoginWithTwitter(sender : BaseViewController, screenBeforeLogin : String) {
        let vcLogin = sender as? LoginViewController
        let vcRegister = sender as? RegisterViewController
        
        Twitter.sharedInstance().logInWithCompletion { session, error in
            if (session != nil) {
                let twId = session!.userID
                let twUsername = session!.userName
                let twToken = session!.authToken
                let twSecret = session!.authTokenSecret
                var twFullname = ""
                var twEmail = ""
                
                let twShareEmailVC = TWTRShareEmailViewController() { email, error in
                    if (email != nil) {
                        twEmail = email!
                        //println("twEmail = \(twEmail)")
                        
                        let twClient = TWTRAPIClient()
                        let twShowUserEndpoint = "https://api.twitter.com/1.1/users/show.json"
                        let twParams = [
                            "user_id" : twId,
                            "screen_name" : twUsername
                        ]
                        var twErr : NSError?
                        
                        let twReq = Twitter.sharedInstance().APIClient.URLRequestWithMethod("GET", URL: twShowUserEndpoint, parameters: twParams, error: &twErr)
                        
                        if (twErr != nil) { // Error
                            Constant.showDialog("Warning", message: "Error getting twitter data")//: \(twErr)")
                            sender.dismiss()
                        } else {
                            twClient.sendTwitterRequest(twReq) { (resp, res, err) -> Void in
                                if (err != nil) { // Error
                                    Constant.showDialog("Warning", message: "Error getting twitter data")//: \(err)")
                                    if (vcLogin != nil) {
                                        vcLogin!.hideLoading()
                                    }
                                    if (vcRegister != nil) {
                                        vcRegister!.hideLoading()
                                    }
                                } else { // Succes
                                    var jsonErr : NSError?
                                    let json : AnyObject? = NSJSONSerialization.JSONObjectWithData(res!, options: nil, error: &jsonErr)
                                    let data = JSON(json!)
                                    println("Twitter user show json: \(data)")
                                    
                                    twFullname = data["name"].string!
                                    
                                    request(APIAuth.LoginTwitter(email: twEmail, fullname: twFullname, username: twUsername, id: twId, accessToken: twToken, tokenSecret: twSecret)).responseJSON { req, resp, res, err in
                                        if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Login Twitter")) {
                                            let json = JSON(res!)
                                            let data = json["_data"]
                                            if (data == nil || data == []) { // Data kembalian kosong
                                                if (json["_message"] != nil) {
                                                    Constant.showDialog("Warning", message: json["_message"].string!)
                                                    if (vcLogin != nil) {
                                                        vcLogin!.hideLoading()
                                                    }
                                                    if (vcRegister != nil) {
                                                        vcRegister!.hideLoading()
                                                    }
                                                }
                                            } else { // Berhasil
                                                println("Twitter login data: \(data)")
                                                
                                                // Save in core data
                                                let m = UIApplication.appDelegate.managedObjectContext
                                                var user : CDUser? = CDUser.getOne()
                                                if (user == nil) {
                                                    user = (NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser)
                                                }
                                                user!.id = data["_id"].string!
                                                user!.username = data["username"].string!
                                                user!.email = data["email"].string!
                                                user!.fullname = data["fullname"].string!
                                                
                                                let p = NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile
                                                let pr = data["profile"]
                                                p.pict = pr["pict"].string!
                                                
                                                user!.profiles = p
                                                UIApplication.appDelegate.saveContext()
                                                
                                                // Save in NSUserDefaults
                                                NSUserDefaults.standardUserDefaults().setObject(twToken, forKey: "twittertoken")
                                                NSUserDefaults.standardUserDefaults().synchronize()
                                                
                                                // Check if user have set his account
                                                LoginViewController.CheckProfileSetup(sender, token: data["token"].string!, isSocmedAccount: true, loginMethod: "Twitter", screenBeforeLogin: screenBeforeLogin)
                                            }
                                        } else {
                                            if (vcLogin != nil) {
                                                vcLogin!.hideLoading()
                                            }
                                            if (vcRegister != nil) {
                                                vcRegister!.hideLoading()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Constant.showDialog("Warning", message: "Error getting Twitter email")
                        if (vcLogin != nil) {
                            vcLogin!.hideLoading()
                        }
                        if (vcRegister != nil) {
                            vcRegister!.hideLoading()
                        }
                    }
                }
                sender.presentViewController(twShareEmailVC, animated: true, completion: nil)
                
            } else {
                Constant.showDialog("Info", message: "Twitter login canceled")
                if (vcLogin != nil) {
                    vcLogin!.hideLoading()
                }
                if (vcRegister != nil) {
                    vcRegister!.hideLoading()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)

        scrollView?.delegate = self
        
        txtEmail?.placeholder = "Username / Email"
        
        scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
        
        // Hide close button if necessary
        if (isFromTourVC) {
            self.btnClose!.hidden = true
            self.groupRegister.hidden = true
        }
        
        // Hide loading
        loadingPanel?.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel?.hidden = true
        loading?.stopAnimating()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.Login)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Login)
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
        registerVC.screenBeforeLogin = self.screenBeforeLogin
        self.navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @IBAction func forgotPassword(sender : AnyObject?)
    {
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1)
        {
            let x = UIAlertController(title: "Lupa Password", message: "Masukkan Email", preferredStyle: .Alert)
            x.addTextFieldWithConfigurationHandler({ textfield in
                textfield.placeholder = "Email"
            })
            let actionOK = UIAlertAction(title: "OK", style: .Default, handler: { act in

                let txtField = x.textFields![0] as! UITextField
                self.callAPIForgotPassword((txtField.text)!)
            })
            
            let actionCancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: { act in
                
            })
            
            x.addAction(actionOK)
            x.addAction(actionCancel)
            self.presentViewController(x, animated: true, completion: nil)
        } else
        {
            let a = UIAlertView(title: "Lupa Password", message: "Masukkan Email", delegate: self, cancelButtonTitle: "Batal", otherButtonTitles: "OK")
            a.alertViewStyle = UIAlertViewStyle.PlainTextInput
            a.show()
        }
    }
    
    func callAPIForgotPassword(email : String)
    {
        request(.POST, "\(AppTools.PreloBaseUrl)/api/auth/forgot_password", parameters: ["email":email]).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Lupa Password")) {
                UIAlertView.SimpleShow("Perhatian", message: "Email pemberitahuan sudah kami kirim ke alamat email kamu :)")
            }
        }
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == 1)
        {
            request(.POST, "\(AppTools.PreloBaseUrl)/api/auth/forgot_password", parameters: ["email":(alertView.textFieldAtIndex(0)?.text)!]).responseJSON { req, resp, res, err in
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Lupa Password")) {
                    UIAlertView.SimpleShow("Perhatian", message: "Email pemberitahuan sudah kami kirim ke alamat email kamu :)")
                }
            }
        }
    }
    
    @IBAction func login(sender : AnyObject)
    {
        sendLogin()
    }
    
    func sendLogin()
    {
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
        
        // Show loading
        loadingPanel?.hidden = false
        loading?.startAnimating()
        
        let email = txtEmail?.text
        let pwd = txtPassword?.text
        
        if (email == "")
        {
            UIAlertView.SimpleShow("Perhatian", message: "Silakan isi username/email")
            self.hideLoading()
            return
        }
        if (pwd == "")
        {
            UIAlertView.SimpleShow("Perhatian", message: "Silakan isi password")
            self.hideLoading()
            return
        }
        
        request(APIAuth.Login(email: email!, password: pwd!)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Login")) {
                let json = JSON(res!)
                let data = json["_data"]
                //self.getProfile(data["token"].string!)
                LoginViewController.CheckProfileSetup(self, token: data["token"].string!, isSocmedAccount: false, loginMethod: "Basic", screenBeforeLogin: self.screenBeforeLogin)
            } else {
                self.hideLoading()
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
                    
                    request(APIAuth.LoginFacebook(email: email, fullname: name, fbId: userId, fbAccessToken: accessToken)).responseJSON { req, resp, res, err in
                        if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Login Facebook")) {
                            let json = JSON(res!)
                            let data = json["_data"]
                            // Save in core data
                            let m = UIApplication.appDelegate.managedObjectContext
                            var user : CDUser? = CDUser.getOne()
                            if (user == nil) {
                                user = (NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser)
                            }
                            user!.id = data["_id"].string!
                            user!.username = data["username"].string!
                            user!.email = data["email"].string!
                            user!.fullname = data["fullname"].string!
                            
                            let p = NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile
                            let pr = data["profile"]
                            p.pict = pr["pict"].string!
                            
                            user!.profiles = p
                            UIApplication.appDelegate.saveContext()
                            
                            // Check if user have set his account
                            //self.checkProfileSetup(data["token"].string!)
                            LoginViewController.CheckProfileSetup(self, token: data["token"].string!, isSocmedAccount: true, loginMethod: "Facebook", screenBeforeLogin: self.screenBeforeLogin)
                        }
                    }
                }
            })
        }
    }
    
    // MARK: Twitter Login
    
    @IBAction func loginTwitterPressed(sender: AnyObject) {
        // Show loading
        loadingPanel?.hidden = false
        loading?.startAnimating()
        
        LoginViewController.LoginWithTwitter(self, screenBeforeLogin: self.screenBeforeLogin)
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
        
        request(APIAuth.LoginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Login Path")) {
                let json = JSON(res!)
                let data = json["_data"]
                // Save in core data
                let m = UIApplication.appDelegate.managedObjectContext
                var user : CDUser? = CDUser.getOne()
                if (user == nil) {
                    user = (NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser)
                }
                user!.id = data["_id"].string!
                user!.username = data["username"].string!
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
                //self.checkProfileSetup(data["token"].string!)
                LoginViewController.CheckProfileSetup(self, token: data["token"].string!, isSocmedAccount: true, loginMethod: "Path", screenBeforeLogin: self.screenBeforeLogin)
            }
        }
    }
    
    func hideLoading() {
        loadingPanel?.hidden = true
        loading?.stopAnimating()
    }
}
