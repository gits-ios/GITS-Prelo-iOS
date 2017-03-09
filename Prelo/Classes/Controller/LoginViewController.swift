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
import Alamofire

// MARK: - Class

class LoginViewController: BaseViewController, UIGestureRecognizerDelegate, UITextFieldDelegate, UIScrollViewDelegate, PathLoginDelegate/*, UIAlertViewDelegate*/ {
    
    // MARK: - Properties

    @IBOutlet var scrollView : UIScrollView?
    @IBOutlet var txtEmail : UITextField?
    @IBOutlet var txtPassword : UITextField?
    @IBOutlet var btnLogin : UIButton?
    
    // Predefined values
    var isFromTourVC : Bool = false
    var screenBeforeLogin : String = ""
    var loginTabSwipeVC : LoginFransiskaViewController!
    
    // MARK: - Static functions
    
    static func Show(_ parent : UIViewController, userRelatedDelegate : UserRelatedDelegate?, animated : Bool) {
        LoginViewController.Show(parent, userRelatedDelegate: userRelatedDelegate, animated: animated, isFromTourVC: false)
    }
    
    static func Show(_ parent : UIViewController, userRelatedDelegate : UserRelatedDelegate?, animated : Bool, isFromTourVC : Bool) {
        // Create view controller
        let l = Bundle.main.loadNibNamed(Tags.XibNameLoginFransiska, owner: nil, options: nil)?.first as! LoginFransiskaViewController
        let parentType = "\(type(of: parent))"
        if (parentType == "KumangTabBarViewController") {
            if (isFromTourVC) {
                l.screenBeforeLogin = PageName.SetCategoryPreferences
            } else {
                l.screenBeforeLogin = PageName.DashboardLoggedOut
            }
        } else if (parentType == "CartViewController") {
            l.screenBeforeLogin = PageName.Checkout
        } else if (parentType == "AddProductViewController" || parentType == "AddProductViewController2") {
            l.screenBeforeLogin = PageName.AddProduct
        } else if (parentType == "NotificationPageViewController") {
            l.screenBeforeLogin = PageName.Notification
        } else if (parentType == "ProductDetailViewController") {
            l.screenBeforeLogin = PageName.ProductDetail
        }
        //print("screenBeforeLogin = \(l.screenBeforeLogin)")
        l.userRelatedDelegate = userRelatedDelegate
        l.isFromTourVC = isFromTourVC
        l.setupTabSwipe()
        
        // Setup navigation controller
        let n = BaseNavigationController(rootViewController : l)
        n.navigationBar.isTranslucent = true
        n.navigationBar.setBackgroundImage(UIImage(), for: .default)
        n.navigationBar.shadowImage = UIImage()
        n.navigationBar.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        parent.present(n, animated: animated, completion: nil)
    }
    
    static func SendDeviceRegId(_ onFinish: @escaping () -> () = {}) {
        // Store device registration ID to server
        // Di titik inilah user dianggap login/logout, sehingga di titik inilah user mulai/berhenti menerima push notification
        // Get device token
        var deviceToken : String = ""
        if (User.IsLoggedIn && UserDefaults.standard.string(forKey: "deviceregid") != nil) {
            deviceToken = UserDefaults.standard.string(forKey: "deviceregid")!
        }
        let _ = request(APIMe.setDeviceRegId(deviceRegId: deviceToken)).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Set Device Registration ID")) {
                let json = JSON(resp.result.value!)
                let isSuccess = json["_data"].int!
                if (isSuccess == 1) { // Berhasil
                    print("Kode deviceRegId berhasil ditambahkan: \(deviceToken)")
                } else { // Gagal
                    print("Error setting deviceRegId")
                }
            }
            
            // Execute onFinish
            onFinish()
        }
    }
    
    // Check if user have set his account in ProfileSetupVC and PhoneVerificationVC
    // Param token is only used when user have set his account via setup account and phone verification
    static func CheckProfileSetup(_ sender : BaseViewController, token : String, isSocmedAccount : Bool, loginMethod : String, screenBeforeLogin : String, isNeedPayload : Bool) {
        let vcLogin = sender as? LoginViewController
        let vcRegister = sender as? RegisterViewController
        
        var isProfileSet : Bool = false
        
        // Set token first, because APIMe.Me need token
        User.SetToken(token)
        
        // Get user profile from API and check if required data is set
        // Required data: gender, phone, province, region, shipping
        // API Migrasi
        let _ = request(APIMe.me).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Profil Pengguna")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                let userProfileData = UserProfile.instance(data)
                
                /* CATEGPREF DISABLED
                // Update user preferenced categories in NSUserDefaults
                let catPrefIds = userProfileData!.categoryPrefIds
                if (catPrefIds.count >= 3) {
                    NSUserDefaults.standardUserDefaults().setObject(catPrefIds[0], forKey: UserDefaultsKey.CategoryPref1)
                    NSUserDefaults.standardUserDefaults().setObject(catPrefIds[1], forKey: UserDefaultsKey.CategoryPref2)
                    NSUserDefaults.standardUserDefaults().setObject(catPrefIds[2], forKey: UserDefaultsKey.CategoryPref3)
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
                */
                
                if (userProfileData != nil &&
                    userProfileData!.email != "" &&
                    userProfileData!.gender != "" &&
                    userProfileData!.phone != "" &&
                    userProfileData!.provinceId != "" &&
                    userProfileData!.regionId != "" &&
                    userProfileData!.shippingIds.count > 0 &&
                    userProfileData!.isPhoneVerified == true) {
                        isProfileSet = true
                }
                
                if (isProfileSet) {
                    // Refresh notifications badge
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let notifListener = delegate.preloNotifListener
                    notifListener?.getTotalUnreadNotifCount()
                    
                    // Save in core data
                    let m = UIApplication.appDelegate.managedObjectContext
                    _ = CDUser.deleteAll()
                    let user : CDUser = (NSEntityDescription.insertNewObject(forEntityName: "CDUser", into: m) as! CDUser)
                    user.id = userProfileData!.id
                    user.email = userProfileData!.email
                    user.fullname = userProfileData!.fullname
                    user.username = userProfileData!.username
                    
                    _ = CDUserProfile.deleteAll()
                    let userProfile : CDUserProfile = (NSEntityDescription.insertNewObject(forEntityName: "CDUserProfile", into: m) as! CDUserProfile)
                    user.profiles = userProfile
                    userProfile.regionID = userProfileData!.regionId
                    userProfile.provinceID = userProfileData!.provinceId
                    userProfile.subdistrictID = userProfileData!.subdistrictId
                    userProfile.subdistrictName = userProfileData!.subdistrictName
                    userProfile.gender = userProfileData!.gender
                    userProfile.phone = userProfileData!.phone
                    userProfile.pict = userProfileData!.profPictURL!.absoluteString
                    userProfile.postalCode = userProfileData!.postalCode
                    userProfile.address = userProfileData!.address
                    userProfile.desc = userProfileData!.desc
                    
                    _ = CDUserOther.deleteAll()
                    let userOther : CDUserOther = (NSEntityDescription.insertNewObject(forEntityName: "CDUserOther", into: m) as! CDUserOther)
                    userOther.shippingIDs = NSKeyedArchiver.archivedData(withRootObject: userProfileData!.shippingIds)
                    userOther.lastLogin = userProfileData!.lastLogin
                    userOther.phoneCode = userProfileData!.phoneCode
                    userOther.phoneVerified = userProfileData!.isPhoneVerified
                    userOther.registerTime = userProfileData!.registerTime
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
                    userOther.emailVerified = userProfileData!.isEmailVerified ? 1 : 0
                    // TODO: belum lengkap (isActiveSeller, seller, shopName, shopPermalink, simplePermalink)
                    
                    UIApplication.appDelegate.saveContext()
                    
                    // Save in NSUserDefaults
                    User.StoreUser(userProfileData!.id, token : token, email : userProfileData!.email)
                    
                    // Tell app that the user has logged in
                    if let d = sender.userRelatedDelegate
                    {
                        d.userLoggedIn!()
                    }
                    
                    // Memanggil notif observer yg mengimplement userLoggedIn (AppDelegate & KumangTabBarVC)
                    // Di dalamnya akan memanggil MessagePool.start()
                    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "userLoggedIn"), object: nil)
                    
                    CartProduct.registerAllAnonymousProductToEmail(User.EmailOrEmptyString)
                    
                    // Send uuid to server
                    let _ = request(APIMe.setUserUUID)
                    
                    /*
                    // Mixpanel
                    if let c = CDUser.getOne() {
                        let provinceName = CDProvince.getProvinceNameWithID(c.profiles.provinceID)
                        let regionName = CDRegion.getRegionNameWithID(c.profiles.regionID)
                        let sp : [AnyHashable: Any] = [
                            "User ID" : c.id,
                            "Email" : c.email,
                            "Username" : c.username,
                            "Phone" : ((c.profiles.phone != nil) ? c.profiles.phone! : ""),
                            "Fullname" : ((c.fullname != nil) ? c.fullname! : ""),
                            "Gender" : ((c.profiles.gender != nil) ? c.profiles.gender! : ""),
                            "Province Input" : ((provinceName != nil) ? provinceName! : ""),
                            "City Input" : ((regionName != nil) ? regionName! : ""),
                            "Referral Code Used" : userProfileData!.json["others"]["referral_code_used"].stringValue,
                            "Login Method" : loginMethod
                        ]
                        Mixpanel.sharedInstance().registerSuperProperties(sp)
                        
                        let pt = [
                            "Previous Screen" : screenBeforeLogin,
                            "Login Method" : loginMethod
                        ]
                        Mixpanel.trackEvent(MixpanelEvent.Login, properties: pt)
                        
                        Mixpanel.sharedInstance().identify(c.id)
                    }
                     */
                    
                    // Prelo Analytic - login
                    let username = (CDUser.getOne()?.username)!
                    let pdata = [
                        "Username" : username,
                        "Username History" : User.UsernameHistory
                    ] as [String : Any]
                    AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.Login, data: pdata, previousScreen: screenBeforeLogin, loginMethod: loginMethod)
                    User.UpdateUsernameHistory(username)
                    User.SetLoginMethod(loginMethod)
                    
                    // Prelo Analytic - Update User
                    AnalyticManager.sharedInstance.updateUser(isNeedPayload: isNeedPayload)
                    
                    // Set crashlytics user information
                    Crashlytics.sharedInstance().setUserIdentifier(user.profiles.phone!)
                    Crashlytics.sharedInstance().setUserEmail(user.email)
                    Crashlytics.sharedInstance().setUserName(user.fullname!)
                    
                    // MoEngage
                    MoEngage.sharedInstance().setUserAttribute(user.id, forKey: "user_id")
                    MoEngage.sharedInstance().setUserAttribute(user.username, forKey: "username")
                    MoEngage.sharedInstance().setUserAttribute(user.fullname, forKey: "user_fullname")
                    MoEngage.sharedInstance().setUserAttribute(user.email, forKey: "user_email")
                    MoEngage.sharedInstance().setUserAttribute(user.profiles.phone!, forKey: "phone")
                } else {
                    // Delete token because user is considered not logged in
                    User.SetToken(nil)
                }
                
                // Next screen based on isProfileSet
                if (isProfileSet) {
                    // Send deviceRegId, then dismiss
                    LoginViewController.SendDeviceRegId({
                        sender.dismiss(animated: true, completion: nil)
                    })
                } else {
                    // Reset navbar color
                    sender.navigationController?.navigationBar.backgroundColor = Theme.PrimaryColor
                    
                    // Go to profile setup or phone verification
                    if (userProfileData!.email != "" &&
                        userProfileData!.gender != "" &&
                        userProfileData!.phone != "" &&
                        userProfileData!.provinceId != "" &&
                        userProfileData!.regionId != "" &&
                        userProfileData!.shippingIds.count > 0) { // User has finished profile setup
                            // Goto PhoneVerificationVC
                            let phoneVerificationVC = Bundle.main.loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil)?.first as! PhoneVerificationViewController
                            phoneVerificationVC.userRelatedDelegate = sender.userRelatedDelegate
                            phoneVerificationVC.userId = userProfileData!.id
                            phoneVerificationVC.userToken = token
                            phoneVerificationVC.userEmail = userProfileData!.email
                            phoneVerificationVC.isShowBackBtn = false
                            phoneVerificationVC.loginMethod = loginMethod
                            phoneVerificationVC.userProfileData = userProfileData
                            phoneVerificationVC.noHpToVerify = userProfileData!.phone
                            phoneVerificationVC.previousScreen = PageName.Login
                            sender.navigationController?.pushViewController(phoneVerificationVC, animated: true)
                    } else { // User hasn't finished profile setup
                        let profileSetupVC = Bundle.main.loadNibNamed(Tags.XibNameProfileSetup, owner: nil, options: nil)?.first as! ProfileSetupViewController
                        profileSetupVC.userRelatedDelegate = sender.userRelatedDelegate
                        profileSetupVC.userId = userProfileData!.id
                        profileSetupVC.userToken = token
                        profileSetupVC.userEmail = userProfileData!.email
                        profileSetupVC.isSocmedAccount = isSocmedAccount
                        profileSetupVC.loginMethod = loginMethod
                        profileSetupVC.screenBeforeLogin = screenBeforeLogin
                        profileSetupVC.isFromRegister = false
                        if (userProfileData!.phone != "") {
                            profileSetupVC.fieldNoHP.text = userProfileData!.phone
                        }
                        if (userProfileData!.provinceId != "") {
                            profileSetupVC.selectedProvinsiID = userProfileData!.provinceId
                            profileSetupVC.lblProvinsi.text = CDProvince.getProvinceNameWithID(userProfileData!.provinceId)
                            profileSetupVC.lblProvinsi.textColor = Theme.GrayDark
                        }
                        if (userProfileData!.regionId != "") {
                            profileSetupVC.selectedKabKotaID = userProfileData!.regionId
                            profileSetupVC.lblKabKota.text = CDRegion.getRegionNameWithID(userProfileData!.regionId)
                            profileSetupVC.lblKabKota.textColor = Theme.GrayDark
                        }
                        sender.navigationController?.pushViewController(profileSetupVC, animated: true)
                    }
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
    
    // Required param: "sender"
    static func LoginWithFacebook(_ param : [String : AnyObject], onFinish : @escaping (NSMutableDictionary) -> ()) {
        guard let sender = param["sender"] as? BaseViewController else {
            return
        }
        
        // Log in and get permission from facebook
        let fbLoginManager = FBSDKLoginManager()
        
        // Ask for publish permissions
        fbLoginManager.logIn(withPublishPermissions: ["publish_actions"], handler: {(result : FBSDKLoginManagerLoginResult?, error : Error?) -> Void in
            if (error != nil) { // Process error
                LoginViewController.LoginFacebookCancelled(sender, reason: "Terdapat kesalahan saat login Facebook")
            } else if (result == nil || result!.isCancelled) { // User cancellation
                LoginViewController.LoginFacebookCancelled(sender, reason: "Login Facebook dibatalkan")
            } else { // Success
                guard var permissions = FBSDKAccessToken.current().permissions else {
                    // Handle not getting permission
                    LoginViewController.LoginFacebookCancelled(sender, reason: "Login Facebook dibatalkan karena terdapat akses yg diblokir")
                    return
                }
                
                if permissions.contains("publish_actions") {
                    if (permissions.contains("email")) {
                        // Continue work
                        LoginViewController.ContinueLoginWithFacebook(param, onFinish: onFinish)
                    } else {
                        // Ask for read permissions
                        fbLoginManager.logIn(withReadPermissions: ["email"], handler: {(result : FBSDKLoginManagerLoginResult?, error: Error?) -> Void in
                            if (error != nil) { // Process error
                                LoginViewController.LoginFacebookCancelled(sender, reason: "Terdapat kesalahan saat login Facebook")
                            } else if (result == nil || result!.isCancelled) { // User cancellation
                                LoginViewController.LoginFacebookCancelled(sender, reason: "Login Facebook dibatalkan")
                            } else { // Success
                                permissions = FBSDKAccessToken.current().permissions
                                if permissions.contains("email") {
                                    // Continue work
                                    LoginViewController.ContinueLoginWithFacebook(param, onFinish: onFinish)
                                } else {
                                    // Handle not getting permission
                                    LoginViewController.LoginFacebookCancelled(sender, reason: "Login Facebook dibatalkan karena terdapat data yang tidak dapat diakses")
                                }
                            }
                        })
                    }
                } else {
                    // Handle not getting permission
                    LoginViewController.LoginFacebookCancelled(sender, reason: "Login Facebook dibatalkan karena terdapat akses yg diblokir")
                }
            }
        })
    }
    
    static func ContinueLoginWithFacebook(_ param : [String : AnyObject], onFinish : @escaping (NSMutableDictionary) -> ()) {
        guard let sender = param["sender"] as? BaseViewController else {
            return
        }
        var screenBeforeLogin : String = ""
        if let scrBfrLogin = param["screenBeforeLogin"] as? String {
            screenBeforeLogin = scrBfrLogin
        }
        
        if FBSDKAccessToken.current() != nil {
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email, name"], tokenString: FBSDKAccessToken.current().tokenString, version: nil, httpMethod: "GET")
            graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                
                if ((error) != nil) {
                    LoginViewController.LoginFacebookCancelled(sender, reason: "Terdapat kesalahan saat mengakses data Facebook")
                } else {
                    if let res = result as? NSDictionary {
                        let resultDict = NSMutableDictionary(dictionary: res)
                        resultDict.setValue(sender, forKey: "sender")
                        resultDict.setValue(screenBeforeLogin, forKey: "screenBeforeLogin")
                        onFinish(resultDict)
                    } else {
                        LoginViewController.LoginFacebookCancelled(sender, reason: "Format data Facebook salah")
                    }
                }
            })
        } else {
            LoginViewController.LoginFacebookCancelled(sender, reason: "Terdapat kesalahan saat login Facebook, token tidak ditemukan")
        }
    }
    
    // Required dict key: "sender", "screenBeforeLogin"
    static func AfterLoginFacebook(_ resultDict : NSMutableDictionary) {
        guard let sender = resultDict.object(forKey: "sender") as? BaseViewController, let screenBeforeLogin = resultDict.object(forKey: "screenBeforeLogin") as? String else {
            return
        }
        
        let userId = resultDict["id"] as? String
        let name = resultDict["name"] as? String
        let email = resultDict["email"] as? String
        
        // userId & name is required
        if (userId != nil && name != nil) {
            let emailToSend : String = (email != nil) ? email! : ""
            _ = "https://graph.facebook.com/\(userId)/picture?type=large" // FIXME: harusnya dipasang di profile kan?
            let accessToken = FBSDKAccessToken.current().tokenString
            
            //print("result = \(result)")
            //print("profilePictureUrl = \(profilePictureUrl)")
            //print("accessToken = \(accessToken)")
            
            // API Migrasi
            let _ = request(APIAuth.loginFacebook(email: emailToSend, fullname: name!, fbId: userId!, fbUsername: name!, fbAccessToken: accessToken!)).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Facebook")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    // Save in core data
                    let m = UIApplication.appDelegate.managedObjectContext
                    var user : CDUser? = CDUser.getOne()
                    if (user == nil) {
                        user = (NSEntityDescription.insertNewObject(forEntityName: "CDUser", into: m) as! CDUser)
                    }
                    user!.id = data["_id"].stringValue
                    user!.username = data["username"].stringValue
                    user!.email = data["email"].stringValue
                    user!.fullname = data["fullname"].stringValue
                    
                    let p = NSEntityDescription.insertNewObject(forEntityName: "CDUserProfile", into: m) as! CDUserProfile
                    let pr = data["profile"]
                    p.pict = pr["pict"].string!
                    
                    user!.profiles = p
                    UIApplication.appDelegate.saveContext()
                    
                    /*
                    // Mixpanel event for login/register with facebook
                    var pMixpanel = [
                        "Previous Screen" : screenBeforeLogin,
                        "Facebook ID" : userId!,
                        "Facebook Username" : name!,
                        "Facebook Access Token" : accessToken
                    ]
                    if let _ = sender as? LoginViewController {
                        pMixpanel["Login Method"] = "Facebook"
                        Mixpanel.trackEvent(MixpanelEvent.Login, properties: pMixpanel)
                    } else if let _ = sender as? RegisterViewController {
                        Mixpanel.trackEvent(MixpanelEvent.Register, properties: pMixpanel)
                    }
                     */
                    
                    // Prelo Analytic - Register
                    var isNeedPayload = false
                    if let _ = sender as? RegisterViewController {
                        let pdata = [
                            "Email" : user!.email,
                            "Username" : (CDUser.getOne()?.username)!,
                            "Register OS" : "iOS",
                            "Register Method" : "Facebook"
                        ]
                        AnalyticManager.sharedInstance.sendWithUserId(eventType: PreloAnalyticEvent.Register, data: pdata, previousScreen: screenBeforeLogin, loginMethod: "Facebook", userId: user!.id)
                        
                        isNeedPayload = true
                        
                        // Prelo Analytic - Update User - Register
                        AnalyticManager.sharedInstance.registerUser(method: "Facebook", metadata: data)
                    }
                    
                    // Check if user have set his account
                    //self.checkProfileSetup(data["token"].string!)
                    LoginViewController.CheckProfileSetup(sender, token: data["token"].string!, isSocmedAccount: true, loginMethod: "Facebook", screenBeforeLogin: screenBeforeLogin, isNeedPayload: isNeedPayload)
                } else {
                    LoginViewController.LoginFacebookCancelled(sender, reason: nil)
                }
            }
        } else { // If there's no userId or name
            LoginViewController.LoginFacebookCancelled(sender, reason: "Terdapat kesalahan data saat login Facebook")
        }
    }
    
    static func LoginFacebookCancelled(_ sender : BaseViewController, reason : String?) {
        let vcLogin = sender as? LoginViewController
        let vcRegister = sender as? RegisterViewController
        let vcProductDetail = sender as? ProductDetailViewController
        let vcAddProductShare = sender as? AddProductShareViewController
        let vcUserProfile = sender as? UserProfileViewController
        
        if (vcLogin != nil || vcRegister != nil) { // Jika login dari halaman login atau register
            User.Logout()
        } else {
            User.LogoutFacebook()
        }
        
        // Hide loading
        if (vcLogin != nil) {
            vcLogin!.hideLoading()
        }
        if (vcRegister != nil) {
            vcRegister!.hideLoading()
        }
        if (vcProductDetail != nil) {
            vcProductDetail!.hideLoading()
        }
        if (vcAddProductShare != nil) {
            vcAddProductShare!.hideLoading()
        }
        if (vcUserProfile != nil) {
            vcUserProfile!.hideLoading()
        }
        
        // Show alert if there's reason
        if (reason != nil) {
            Constant.showDialog("Login Facebook", message: reason!)
        }
    }
    
    // Required param: "sender"
    static func LoginWithTwitter(_ param : [String : AnyObject], onFinish : @escaping (NSMutableDictionary) -> ()) {
        guard let sender = param["sender"] as? BaseViewController else {
            return
        }
        var screenBeforeLogin : String = ""
        if let scrBfrLogin = param["screenBeforeLogin"] as? String {
            screenBeforeLogin = scrBfrLogin
        }
        
        Twitter.sharedInstance().logIn { session, error in
            if (session != nil) {
                let twId = session!.userID
                let twUsername = session!.userName
                let twToken = session!.authToken
                let twSecret = session!.authTokenSecret
                var twFullname = ""
                var twEmail = ""
                
                let twShareEmailVC = TWTRShareEmailViewController() { email, error in
                    
                    let err = error.debugDescription
                    print(err)
                    
                    if (email != nil || err.contains("Your application may not have access to email addresses or the user may not have an email address.")) {
                        
                        var isExecute = false
                        
                        if (email != nil) {
                            twEmail = email!
                            
                            isExecute = true
                        } else if User.IsLoggedIn {
                            twEmail = (CDUser.getOne()?.email)!
                            
                            isExecute = true
                            
                            /*
                            let x = UIAlertController(title: "Share Twitter", message: "Masukkan E-mail akun Twitter kamu", preferredStyle: .alert)
                            x.addTextField(configurationHandler: { textfield in
                                textfield.placeholder = "E-mail"
                                textfield.text = twEmail
                            })
                            
                            let actionOK = UIAlertAction(title: "Kirim", style: .default, handler: { act in
                                
                                twEmail = x.textFields![0].text!
                                isExecute = true
                            })
                            
                            let actionCancel = UIAlertAction(title: "Batal", style: .cancel, handler: { act in
                                
                                isExecute = false
                            })
                            
                            x.addAction(actionOK)
                            x.addAction(actionCancel)
                            UIApplication.shared.keyWindow?.rootViewController?.present(x, animated: true, completion: nil)
                            */
                        }
                        //print("twEmail = \(twEmail)")
                        
                        if isExecute {
                            let twClient = TWTRAPIClient()
                            let twShowUserEndpoint = "https://api.twitter.com/1.1/users/show.json"
                            let twParams = [
                                "user_id" : twId,
                                "screen_name" : twUsername
                            ]
                            var twErr : NSError?
                            
                            let twReq = Twitter.sharedInstance().apiClient.urlRequest(withMethod: "GET", url: twShowUserEndpoint, parameters: twParams, error: &twErr)
                            
                            if (twErr != nil) { // Error
                                LoginViewController.LoginTwitterCancelled(sender, reason: "Error getting twitter data")
                            } else {
                                twClient.sendTwitterRequest(twReq, completion: { (resp, res, err) -> Void in
                                    if (err != nil) { // Error
                                        LoginViewController.LoginTwitterCancelled(sender, reason: "Error getting twitter data")
                                    } else { // Succes
                                        do {
                                            let json : Any = try JSONSerialization.jsonObject(with: res!, options: .allowFragments)
                                            let data = JSON(json)
                                            print("Twitter user show json: \(data)")
                                            
                                            twFullname = data["name"].string!
                                            
                                            let resultDict = NSMutableDictionary()
                                            resultDict.setValue(sender, forKey: "sender")
                                            resultDict.setValue(screenBeforeLogin, forKey: "screenBeforeLogin")
                                            resultDict.setValue(twEmail, forKey: "twEmail")
                                            resultDict.setValue(twFullname, forKey: "twFullname")
                                            resultDict.setValue(twUsername, forKey: "twUsername")
                                            resultDict.setValue(twId, forKey: "twId")
                                            resultDict.setValue(twToken, forKey: "twToken")
                                            resultDict.setValue(twSecret, forKey: "twSecret")
                                            onFinish(resultDict)
                                        } catch {
                                            LoginViewController.LoginTwitterCancelled(sender, reason: "Error getting twitter data")
                                        }
                                    }
                                })
                            }
                        } else {
                            LoginViewController.LoginTwitterCancelled(sender, reason: "Error: E-mail gagal didapatkan karena e-mail akun twitter belum diverifikasi, atau gagal diakses oleh Prelo")
                        }
                    } else {
                        LoginViewController.LoginTwitterCancelled(sender, reason: "Error: E-mail gagal didapatkan karena e-mail akun twitter belum diverifikasi, atau gagal diakses oleh Prelo")
                    }
                }
                sender.present(twShareEmailVC, animated: true, completion: nil)
                
            } else {
                LoginViewController.LoginTwitterCancelled(sender, reason: "Twitter login cancelled")
            }
        }
    }
    
    static func AfterLoginTwitter(_ resultDict : NSMutableDictionary) {
        guard let sender = resultDict.object(forKey: "sender") as? BaseViewController,
            let screenBeforeLogin = resultDict.object(forKey: "screenBeforeLogin") as? String,
            let twEmail = resultDict.object(forKey: "twEmail") as? String,
            let twFullname = resultDict.object(forKey: "twFullname") as? String,
            let twUsername = resultDict.object(forKey: "twUsername") as? String,
            let twId = resultDict.object(forKey: "twId") as? String,
            let twToken = resultDict.object(forKey: "twToken") as? String,
            let twSecret = resultDict.object(forKey: "twSecret") as? String else {
            return
        }
        
        let _ = request(APIAuth.loginTwitter(email: twEmail, fullname: twFullname, username: twUsername, id: twId, accessToken: twToken, tokenSecret: twSecret)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Twitter")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if (data == nil || data == []) { // Data kembalian kosong
                    if (json["_message"] != nil) {
                        LoginViewController.LoginTwitterCancelled(sender, reason: json["_message"].string!)
                    }
                } else { // Berhasil
                    print("Twitter login data: \(data)")
                    
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
                    
                    let p = NSEntityDescription.insertNewObject(forEntityName: "CDUserProfile", into: m) as! CDUserProfile
                    let pr = data["profile"]
                    p.pict = pr["pict"].string!
                    
                    user!.profiles = p
                    UIApplication.appDelegate.saveContext()
                    
                    // Save in NSUserDefaults
                    UserDefaults.standard.set(twToken, forKey: "twittertoken")
                    UserDefaults.standard.synchronize()
                    
                    /*
                    // Mixpanel event for login/register with facebook
                    var pMixpanel = [
                        "Previous Screen" : screenBeforeLogin,
                        "Twitter ID" : twId,
                        "Twitter Username" : twUsername,
                        "Twitter Access Token" : twToken,
                        "Twitter Token Secret" : twSecret
                    ]
                    if let _ = sender as? LoginViewController {
                        pMixpanel["Login Method"] = "Twitter"
                        Mixpanel.trackEvent(MixpanelEvent.Login, properties: pMixpanel)
                    } else if let _ = sender as? RegisterViewController {
                        Mixpanel.trackEvent(MixpanelEvent.Register, properties: pMixpanel)
                    }
                     */
                    
                    // Prelo Analytic - Register
                    var isNeedPayload = false
                    if let _ = sender as? RegisterViewController {
                        let pdata = [
                            "Email" : user!.email,
                            "Username" : (CDUser.getOne()?.username)!,
                            "Register OS" : "iOS",
                            "Register Method" : "Twitter"
                        ]
                        AnalyticManager.sharedInstance.sendWithUserId(eventType: PreloAnalyticEvent.Register, data: pdata, previousScreen: screenBeforeLogin, loginMethod: "Twitter", userId: user!.id)
                        
                        isNeedPayload = true
                        
                        // Prelo Analytic - Update User - Register
                        AnalyticManager.sharedInstance.registerUser(method: "Twitter", metadata: data)
                    }
                    
                    // Check if user have set his account
                    LoginViewController.CheckProfileSetup(sender, token: data["token"].stringValue, isSocmedAccount: true, loginMethod: "Twitter", screenBeforeLogin: screenBeforeLogin, isNeedPayload: isNeedPayload)
                }
            } else {
                LoginViewController.LoginTwitterCancelled(sender, reason: nil)
            }
        }
    }
    
    static func LoginTwitterCancelled(_ sender : BaseViewController, reason : String?) {
        
        let vcLogin = sender as? LoginViewController
        let vcRegister = sender as? RegisterViewController
        let vcProductDetail = sender as? ProductDetailViewController
        let vcAddProductShare = sender as? AddProductShareViewController
        let vcUserProfile = sender as? UserProfileViewController
        
        if (vcLogin != nil || vcRegister != nil) { // Jika login dari halaman login atau register
            User.Logout()
        } else {
            User.LogoutTwitter()
        }
        
        // Hide loading
        if (vcLogin != nil) {
            vcLogin!.hideLoading()
        }
        if (vcRegister != nil) {
            vcRegister!.hideLoading()
        }
        if (vcProductDetail != nil) {
            vcProductDetail!.hideLoading()
        }
        if (vcAddProductShare != nil) {
            vcAddProductShare!.hideLoading()
        }
        if (vcUserProfile != nil) {
            vcUserProfile!.hideLoading()
        }
        
        // Show alert if there's reason
        if (reason != nil) {
            Constant.showDialog("Login Twitter", message: reason!)
        }
    }
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Scrollview setup
        scrollView?.delegate = self
        scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
        
        // Setup placeholder
        txtEmail?.attributedPlaceholder = NSAttributedString(string: (txtEmail?.placeholder)!, attributes: [NSForegroundColorAttributeName: UIColor.white])
        txtPassword?.attributedPlaceholder = NSAttributedString(string: (txtPassword?.placeholder)!, attributes: [NSForegroundColorAttributeName: UIColor.white])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.Login)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Login)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboard(animations: { r, t, o in
            if (o) {
                self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64 + r.height, 0)
            } else {
                self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
            }
        }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
//        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    @IBAction func viewTapped(_ sender : AnyObject) {
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
    }
    
    @IBAction func forgotPassword(_ sender : AnyObject?) {
        /*
        let x = UIAlertController(title: "Lupa Password", message: "Masukkan E-mail", preferredStyle: .alert)
        x.addTextField(configurationHandler: { textfield in
            textfield.placeholder = "E-mail"
        })
        let actionOK = UIAlertAction(title: "Kirim", style: .default, handler: { act in
            
            let txtField = x.textFields![0]
            self.callAPIForgotPassword((txtField.text)!)
        })
        
        let actionCancel = UIAlertAction(title: "Batal", style: .cancel, handler: { act in
            
        })
        
        x.addAction(actionOK)
        x.addAction(actionCancel)
        self.present(x, animated: true, completion: nil)
         */
        
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        
        let alertView = SCLAlertView(appearance: appearance)
        let txt = alertView.addTextField("E-mail")
        alertView.addButton("Kirim") {
            self.callAPIForgotPassword((txt.text)!)
        }
        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
        alertView.showCustom("Lupa Password", subTitle: "Masukkan E-mail", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    func callAPIForgotPassword(_ email : String) {
        _ = request(APIAuth.forgotPassword(email: email)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Lupa Password")) {
                Constant.showDialog("Perhatian", message: "E-mail pemberitahuan sudah dikirim ke e-mail kamu :)")
            }
        }
    }
    
    @IBAction func login(_ sender : AnyObject) {
        sendLogin()
    }
    
    func sendLogin() {
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
        
        // Show loading
        self.showLoading()
        
        let email = txtEmail?.text
        let pwd = txtPassword?.text
        
        if (email == "") {
            Constant.showDialog("Perhatian", message: "Email atau username harus diisi")
            self.hideLoading()
            return
        }
        if (pwd == "") {
            Constant.showDialog("Perhatian", message: "Password harus diisi")
            self.hideLoading()
            return
        }
        
        let _ = request(APIAuth.login(email: email!, password: pwd!)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                //self.getProfile(data["token"].string!)
                LoginViewController.CheckProfileSetup(self, token: data["token"].string!, isSocmedAccount: false, loginMethod: "Basic", screenBeforeLogin: self.screenBeforeLogin, isNeedPayload: false)
            } else {
                self.hideLoading()
            }
        }
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == txtEmail) {
            txtPassword?.becomeFirstResponder()
        } else {
            sendLogin()
        }
        
        return false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    // MARK: - Facebook Login
    
    @IBAction func loginFacebookPressed(_ sender: AnyObject) {
        // Show loading
        self.showLoading()
        
        let p = ["sender" : self, "screenBeforeLogin" : self.screenBeforeLogin] as [String : Any]
        LoginViewController.LoginWithFacebook(p as [String : AnyObject], onFinish: { resultDict in
            LoginViewController.AfterLoginFacebook(resultDict)
        })
    }
    
    // MARK: - Twitter Login
    
    @IBAction func loginTwitterPressed(_ sender: AnyObject) {
        // Show loading
        self.showLoading()
        
        let p = ["sender" : self, "screenBeforeLogin" : self.screenBeforeLogin] as [String : Any]
        LoginViewController.LoginWithTwitter(p as [String : AnyObject], onFinish: { resultDict in
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
        /*var profilePictureUrl : String?
        if (userData["photo"] != nil) {
            profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        }*/
        
        // API Migrasi
        let _ = request(APIAuth.loginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON { resp in
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
                
                let p = NSEntityDescription.insertNewObject(forEntityName: "CDUserProfile", into: m) as! CDUserProfile
                let pr = data["profile"]
                p.pict = pr["pict"].string!
                
                user!.profiles = p
                UIApplication.appDelegate.saveContext()
                
                // Save in NSUserDefaults
                UserDefaults.standard.set(token, forKey: "pathtoken")
                UserDefaults.standard.synchronize()
                
                // Check if user have set his account
                //self.checkProfileSetup(data["token"].string!)
                LoginViewController.CheckProfileSetup(self, token: data["token"].string!, isSocmedAccount: true, loginMethod: "Path", screenBeforeLogin: self.screenBeforeLogin, isNeedPayload: false)
            }
        }
    }
    
    func showLoading() {
        loginTabSwipeVC.showLoading()
    }
    
    func hideLoading() {
        loginTabSwipeVC.hideLoading()
    }
}
