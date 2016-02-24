//
//  UserProfileViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData
import TwitterKit

class UserProfileViewController : BaseViewController, PickerViewDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextViewDelegate, PhoneVerificationDelegate, PathLoginDelegate, InstagramLoginDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var scrollView : UIScrollView?
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var btnUserImage: UIButton!
    
    @IBOutlet weak var lblLoginInstagram: UILabel!
    @IBOutlet weak var lblLoginFacebook: UILabel!
    @IBOutlet weak var lblLoginTwitter: UILabel!
    @IBOutlet weak var lblLoginPath: UILabel!
    
    @IBOutlet weak var fieldNama: UITextField!
    @IBOutlet weak var lblNoHP: UILabel!
    @IBOutlet weak var lblJenisKelamin: UILabel!
    @IBOutlet weak var lblProvinsi: UILabel!
    @IBOutlet weak var lblKabKota: UILabel!
    @IBOutlet weak var fieldAlamat: UITextField!
    @IBOutlet weak var fieldKodePos: UITextField!
    
    @IBOutlet weak var fieldTentangShop: UITextView!
    @IBOutlet weak var fieldTentangShopHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var lblJneCheckbox: UILabel!
    @IBOutlet weak var lblTikiCheckbox: UILabel!
    
    @IBOutlet weak var btnSimpanData: UIButton!
    
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var jneSelected : Bool = false
    var tikiSelected : Bool = false
    let JNE_REGULAR_ID = "54087faabaede1be0b000001"
    let TIKI_REGULAR_ID = "5405c038ace83c4304ec0caf"
    
    var selectedProvinsiID = ""
    var selectedKabKotaID = ""
    var isPickingProvinsi : Bool = false
    var isPickingKabKota : Bool = false
    var isPickingJenKel : Bool = false
    var isUserPictUpdated : Bool = false
    
    var isLoggedInInstagram : Bool = false
    var isLoggedInFacebook : Bool = false
    var isLoggedInTwitter : Bool = false
    var isLoggedInPath : Bool = false
    
    var asset : ALAssetsLibrary?
    
    let FldTentangShopPlaceholder = "Produk kamu terpercaya? Yakinkan di sini"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Edit Profil"
        setNavBarButtons()
        initiateFields()
        
        // Tampilan loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = true
        loading.stopAnimating()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.EditProfile)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.EditProfile)
        
        // Update fieldTentangShop height
        self.textViewDidChange(fieldTentangShop)
        
        // Handling keyboard animation
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
    
    func setNavBarButtons() {
        // Tombol apply
        let applyButton = UIBarButtonItem(title: "", style:UIBarButtonItemStyle.Done, target:self, action: "simpanDataPressed:")
        applyButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.rightBarButtonItem = applyButton
    }
    
    @IBAction func disableTextFields(sender : AnyObject)
    {
        fieldNama?.resignFirstResponder()
        fieldAlamat?.resignFirstResponder()
        fieldKodePos?.resignFirstResponder()
        fieldTentangShop?.resignFirstResponder()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UIButton.classForCoder()) || touch.view.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    func initiateFields() {
        let m = UIApplication.appDelegate.managedObjectContext
        
        // Fetch data from core data
        let user : CDUser = CDUser.getOne()!
        let userProfile : CDUserProfile = CDUserProfile.getOne()!
        let userOther : CDUserOther = CDUserOther.getOne()!
        
        // Set fields' default value
        if (userProfile.pict != "") {
            //println("userProfile.pict = \(userProfile.pict)")
            let url = NSURL(string: userProfile.pict)
            if (url != nil) {
                self.imgUser.image = nil
                self.imgUser.setImageWithUrl(url!, placeHolderImage: nil)
                self.imgUser.layer.cornerRadius = (self.imgUser.frame.size.width)/2
                self.imgUser.layer.masksToBounds = true
            }
        }
        if (user.fullname != nil) {
            fieldNama.text = user.fullname
        }
        if (userProfile.phone != nil) {
            lblNoHP.text = userProfile.phone
        }
        if let gender = userProfile.gender
        {
            lblJenisKelamin.text = gender
        }
        if (userProfile.address != nil) {
            fieldAlamat.text = userProfile.address
        }
        if (userProfile.postalCode != nil) {
            fieldKodePos.text = userProfile.postalCode
        }
        
        // About shop
        if (userProfile.desc != nil) {
            fieldTentangShop.text = userProfile.desc
            fieldTentangShop.textColor = Theme.GrayDark
        } else {
            fieldTentangShop.text = FldTentangShopPlaceholder
            fieldTentangShop.textColor = UIColor.lightGrayColor()
        }
        fieldTentangShop.delegate = self
        
        // Province and region
        lblProvinsi.text = CDProvince.getProvinceNameWithID(userProfile.provinceID)
        lblKabKota.text = CDRegion.getRegionNameWithID(userProfile.regionID)
        self.selectedProvinsiID = userProfile.provinceID
        self.selectedKabKotaID = userProfile.regionID
        
        // Shipping
        let shippingIds : [String] = NSKeyedUnarchiver.unarchiveObjectWithData(userOther.shippingIDs) as! [String]
        //println("shippingIds = \(shippingIds)")
        for (var i = 0; i < shippingIds.count; i++) {
            let shipId : String = shippingIds[i]
            let shipName : String = CDShipping.getShippingCompleteNameWithId(shipId)!
            if (shipName == "JNE Reguler") {
                jneSelected = true
                lblJneCheckbox.text = "";
                lblJneCheckbox.font = AppFont.Prelo2.getFont(19)!
                lblJneCheckbox.textColor = Theme.ThemeOrange
            } else if (shipName == "TIKI Reguler") {
                tikiSelected = true
                lblTikiCheckbox.text = "";
                lblTikiCheckbox.font = AppFont.Prelo2.getFont(19)!
                lblTikiCheckbox.textColor = Theme.ThemeOrange
            }
        }
        
        // Socmed
        if (self.checkFbLogin(userOther)) { // Sudah login
            self.lblLoginFacebook.text = userOther.fbUsername!
            self.isLoggedInFacebook = true
        }
        if (self.checkInstagramLogin(userOther)) { // Sudah login
            self.lblLoginInstagram.text = userOther.instagramUsername!
            self.isLoggedInInstagram = true
        }
        if (self.checkTwitterLogin(userOther)) { // Sudah login
            self.lblLoginTwitter.text = "@\(userOther.twitterUsername!)"
            self.isLoggedInTwitter = true
        }
        if (self.checkPathLogin(userOther)) { // Sudah login
            self.lblLoginPath.text = userOther.pathUsername!
            self.isLoggedInPath = true
        }
    }
    
    func checkFbLogin(userOther : CDUserOther) -> Bool {
        return (userOther.fbAccessToken != nil) &&
            (userOther.fbAccessToken != "") &&
            (userOther.fbID != nil) &&
            (userOther.fbID != "") &&
            (userOther.fbUsername != nil) &&
            (userOther.fbUsername != "")
    }
    
    func checkInstagramLogin(userOther : CDUserOther) -> Bool {
        return (userOther.instagramAccessToken != nil) &&
            (userOther.instagramAccessToken != "") &&
            (userOther.instagramID != nil) &&
            (userOther.instagramID != "") &&
            (userOther.instagramUsername != nil) &&
            (userOther.instagramUsername != "")
    }
    
    func checkTwitterLogin(userOther : CDUserOther) -> Bool {
        return (userOther.twitterAccessToken != nil) &&
            (userOther.twitterAccessToken != "") &&
            (userOther.twitterID != nil) &&
            (userOther.twitterID != "") &&
            (userOther.twitterUsername != nil) &&
            (userOther.twitterUsername != "") &&
            (userOther.twitterTokenSecret != nil) &&
            (userOther.twitterTokenSecret != "")
    }
    
    func checkPathLogin(userOther : CDUserOther) -> Bool {
        return (userOther.pathAccessToken != nil) &&
            (userOther.pathAccessToken != "") &&
            (userOther.pathID != nil) &&
            (userOther.pathID != "") &&
            (userOther.pathUsername != nil) &&
            (userOther.pathUsername != "")
    }
    
    func pickerDidSelect(item: String) {
        if (isPickingJenKel) {
            lblJenisKelamin?.text = PickerViewController.HideHiddenString(item)
            isPickingJenKel = false
        } else if (isPickingProvinsi) {
            lblProvinsi?.text = PickerViewController.HideHiddenString(item)
            isPickingProvinsi = false
        } else if (isPickingKabKota) {
            lblKabKota?.text = PickerViewController.HideHiddenString(item)
            isPickingKabKota = false
        }
    }
    
    @IBAction func pilihFotoPressed(sender: UIButton) {
        ImagePickerViewController.ShowFrom(self, maxSelect: 1, doneBlock:
            { imgs in
                if (imgs.count > 0) {
                    self.imgUser.image = ImageSourceCell.defaultImage
                    
                    let img : APImage = imgs[0]
                    
                    if ((img.image) != nil)
                    {
                        self.imgUser.image = img.image
                        self.isUserPictUpdated = true
                    } else if (imgs[0].usingAssets == true) {
                        
                        if (self.asset == nil) {
                            self.asset = ALAssetsLibrary()
                        }
                        
                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                            self.asset?.assetForURL((img.url)!, resultBlock: { asset in
                                if let ast = asset {
                                    let rep = ast.defaultRepresentation()
                                    let ref = rep.fullScreenImage().takeUnretainedValue()
                                    let i = UIImage(CGImage: ref)
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.imgUser.image = i
                                        self.isUserPictUpdated = true
                                    })
                                }
                                }, failureBlock: { error in
                                    // error
                            })
                        })
                    }
                }
            }
        )
    }
    
    @IBAction func loginInstagramPressed(sender: UIButton) {
        // Show loading
        loadingPanel.hidden = false
        loading.startAnimating()
        
        if (!isLoggedInInstagram) { // Then login
            let instaLogin = InstagramLoginViewController()
            instaLogin.instagramLoginDelegate = self
            self.navigationController?.pushViewController(instaLogin, animated: true)
        } else { // Then logout
            let logoutAlert = UIAlertView(title: "Instagram Logout", message: "Yakin mau logout akun Instagram \(self.lblLoginInstagram.text!)?", delegate: self, cancelButtonTitle: "No")
            logoutAlert.addButtonWithTitle("Yes")
            logoutAlert.show()
        }
    }
    
    func instagramLoginSuccess(token: String, id: String, name: String) {
        request(APISocial.PostInstagramData(id: id, username: name, token: token)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Login Instagram")) {
                let json = JSON(res!)
                let data = json["_data"].bool
                if (data != nil && data == true) { // Berhasil
                    // Save in core data
                    let userOther : CDUserOther = CDUserOther.getOne()!
                    userOther.instagramID = id
                    userOther.instagramUsername = name
                    userOther.instagramAccessToken = token
                    UIApplication.appDelegate.saveContext()
                    
                    // Adjust path button
                    self.lblLoginInstagram.text = name
                    self.isLoggedInInstagram = true
                    
                    // Hide loading
                    self.hideLoading()
                } else { // Terdapat error
                    Constant.showDialog("Warning", message: "Post instagram data error")
                    self.hideLoading()
                }
            } else {
                self.hideLoading()
            }
        }
    }
    
    func instagramLoginSuccess(token: String) {
        // Do nothing
    }
    
    func instagramLoginFailed() {
        // Hide loading
        self.hideLoading()
    }
    
    @IBAction func loginFacebookPressed(sender: UIButton) {
        // Show loading
        loadingPanel.hidden = false
        loading.startAnimating()
        
        if (!isLoggedInFacebook) { // Then login
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
        } else { // Then logout
            let logoutAlert = UIAlertView(title: "Facebook Logout", message: "Yakin mau logout akun Facebook \(self.lblLoginFacebook.text!)?", delegate: self, cancelButtonTitle: "No")
            logoutAlert.addButtonWithTitle("Yes")
            logoutAlert.show()
        }
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
                    let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                    
                    println("result = \(result)")
                    println("accessToken = \(accessToken)")
                    
                    request(APISocial.PostFacebookData(id: userId, username: name, token: accessToken)).responseJSON { req, resp, res, err in
                        if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Login Facebook")) {
                            let json = JSON(res!)
                            let data = json["_data"].bool
                            
                            // Save in core data
                            let userOther : CDUserOther = CDUserOther.getOne()!
                            userOther.fbID = userId
                            userOther.fbUsername = name
                            userOther.fbAccessToken = accessToken
                            UIApplication.appDelegate.saveContext()
                            
                            // Adjust fb button
                            self.lblLoginFacebook.text = name
                            self.isLoggedInFacebook = true
                            
                            // Hide loading
                            self.hideLoading()
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func loginTwitterPressed(sender: UIButton) {
        // Show loading
        loadingPanel.hidden = false
        loading.startAnimating()
        
        if (!isLoggedInTwitter) { // Then login
            Twitter.sharedInstance().logInWithCompletion { session, error in
                if (session != nil) {
                    let twId = session!.userID
                    let twUsername = session!.userName
                    let twToken = session!.authToken
                    let twSecret = session!.authTokenSecret
                    
                    request(APISocial.PostTwitterData(id: twId, username: twUsername, token: twToken, secret: twSecret)).responseJSON { req, resp, res, err in
                        if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Login Twitter")) {
                            let json = JSON(res!)
                            let data = json["_data"].bool
                            
                            // Save in core data
                            let userOther : CDUserOther = CDUserOther.getOne()!
                            userOther.twitterID = twId
                            userOther.twitterUsername = twUsername
                            userOther.twitterAccessToken = twToken
                            userOther.twitterTokenSecret = twSecret
                            UIApplication.appDelegate.saveContext()
                            
                            // Save in NSUserDefaults
                            NSUserDefaults.standardUserDefaults().setObject(twToken, forKey: "twittertoken")
                            NSUserDefaults.standardUserDefaults().synchronize()
                            
                            // Adjust twitter button
                            self.lblLoginTwitter.text = "@\(twUsername)"
                            self.isLoggedInTwitter = true
                            
                            // Hide loading
                            self.hideLoading()
                        }
                    }
                } else {
                    self.hideLoading()
                }
            }
        } else { // Then logout
            let logoutAlert = UIAlertView(title: "Twitter Logout", message: "Yakin mau logout akun Twitter \(self.lblLoginTwitter.text!)?", delegate: self, cancelButtonTitle: "No")
            logoutAlert.addButtonWithTitle("Yes")
            logoutAlert.show()
        }
    }
    
    @IBAction func loginPathPressed(sender: UIButton) {
        // Show loading
        loadingPanel.hidden = false
        loading.startAnimating()
        
        if (!isLoggedInPath) { // Then login
            let pathLoginVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePathLogin, owner: nil, options: nil).first as! PathLoginViewController
            pathLoginVC.delegate = self
            self.navigationController?.pushViewController(pathLoginVC, animated: true)
        } else { // Then logout
            let logoutAlert = UIAlertView(title: "Path Logout", message: "Yakin mau logout akun Path \(self.lblLoginPath.text!)?", delegate: self, cancelButtonTitle: "No")
            logoutAlert.addButtonWithTitle("Yes")
            logoutAlert.show()
        }
    }
    
    func pathLoginSuccess(userData: JSON, token: String) {
        let pathId = userData["id"].string!
        let pathName = userData["name"].string!
        let email = userData["email"].string!
        
        request(APISocial.PostPathData(id: pathId, username: pathName, token: token)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Login Path")) {
                let json = JSON(res!)
                let data = json["_data"].bool
                
                // Save in core data
                let userOther : CDUserOther = CDUserOther.getOne()!
                userOther.pathID = pathId
                userOther.pathUsername = pathName
                userOther.pathAccessToken = token
                UIApplication.appDelegate.saveContext()
                
                // Adjust path button
                self.lblLoginPath.text = pathName
                self.isLoggedInPath = true
                
                // Hide loading
                self.hideLoading()
            }
        }
    }
    
    func hideLoading() {
        loadingPanel.hidden = true
        loading.stopAnimating()
    }
    
    @IBAction func nomorHpPressed(sender: AnyObject) {
        let phoneReverificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneReverification, owner: nil, options: nil).first as! PhoneReverificationViewController
        phoneReverificationVC.verifiedHP = lblNoHP.text
        phoneReverificationVC.prevVC = self
        self.navigationController?.pushViewController(phoneReverificationVC, animated: true)
    }
    
    @IBAction func jenisKelaminPressed(sender: AnyObject) {
        isPickingJenKel = true
        
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = ["Wanita", "Pria"]
        p?.pickerDelegate = self
        p?.title = "Jenis Kelamin"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    @IBAction func pilihProvinsiPressed(sender: UIButton) {
        isPickingProvinsi = true
        
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = CDProvince.getProvincePickerItems()
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.selectedProvinsiID = PickerViewController.RevealHiddenString(string)
            self.lblKabKota.text = "Pilih Kota/Kabupaten"
        }
        p?.title = "Provinsi"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    @IBAction func pilihKabKotaPressed(sender: UIButton) {
        if (selectedProvinsiID == "") {
            Constant.showDialog("Warning", message: "Pilih provinsi terlebih dahulu")
        } else {
            isPickingKabKota = true
            
            let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
            //p?.items = []
            p?.items = CDRegion.getRegionPickerItems(selectedProvinsiID)
            p?.pickerDelegate = self
            p?.selectBlock = { string in
                self.selectedKabKotaID = PickerViewController.RevealHiddenString(string)
            }
            p?.title = "Kota/Kabupaten"
            self.view.endEditing(true)
            self.navigationController?.pushViewController(p!, animated: true)
        }
    }
    
    // MARK: - UIAlertView Delegate Functions
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 0) { // "No"
            // Hide loading
            self.hideLoading()
        } else if (buttonIndex == 1) { // "Yes"
            if (alertView.title == "Instagram Logout") {
                request(APISocial.PostInstagramData(id: "", username: "", token: "")).responseJSON { req, resp, res, err in
                    if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Logout Instagram")) {
                        let json = JSON(res!)
                        let data = json["_data"].bool
                        
                        // Save in core data
                        let userOther : CDUserOther = CDUserOther.getOne()!
                        userOther.instagramID = nil
                        userOther.instagramUsername = nil
                        userOther.instagramAccessToken = nil
                        UIApplication.appDelegate.saveContext()
                        
                        // Adjust instagram button
                        self.lblLoginInstagram.text = "LOGIN INSTAGRAM"
                        self.isLoggedInInstagram = false
                    }
                    // Hide loading
                    self.hideLoading()
                }
            } else if (alertView.title == "Facebook Logout") {
                request(APISocial.PostFacebookData(id: "", username: "", token: "")).responseJSON { req, resp, res, err in
                    if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Logout Facebook")) {
                        let json = JSON(res!)
                        let data = json["_data"].bool
                        
                        // End session
                        User.LogoutFacebook()
                        
                        // Save in core data
                        let userOther : CDUserOther = CDUserOther.getOne()!
                        userOther.fbID = nil
                        userOther.fbUsername = nil
                        userOther.fbAccessToken = nil
                        UIApplication.appDelegate.saveContext()
                        
                        // Adjust fb button
                        self.lblLoginFacebook.text = "LOGIN FACEBOOK"
                        self.isLoggedInFacebook = false
                    }
                    // Hide loading
                    self.hideLoading()
                }
            } else if (alertView.title == "Twitter Logout") {
                request(APISocial.PostTwitterData(id: "", username: "", token: "", secret: "")).responseJSON { req, resp, res, err in
                    if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Logout Twitter")) {
                        let json = JSON(res!)
                        let data = json["_data"].bool
                        
                        // End session
                        User.LogoutTwitter()
                        
                        // Save in core data
                        let userOther : CDUserOther = CDUserOther.getOne()!
                        userOther.twitterID = nil
                        userOther.twitterUsername = nil
                        userOther.twitterAccessToken = nil
                        userOther.twitterTokenSecret = nil
                        UIApplication.appDelegate.saveContext()
                        
                        // Adjust twitter button
                        self.lblLoginTwitter.text = "LOGIN TWITTER"
                        self.isLoggedInTwitter = false
                    }
                    // Hide loading
                    self.hideLoading()
                }
            } else if (alertView.title == "Path Logout") {
                request(APISocial.PostPathData(id: "", username: "", token: "")).responseJSON { req, resp, res, err in
                    if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Logout Path")) {
                        let json = JSON(res!)
                        let data = json["_data"].bool
                        
                        // Save in core data
                        let userOther : CDUserOther = CDUserOther.getOne()!
                        userOther.pathID = nil
                        userOther.pathUsername = nil
                        userOther.pathAccessToken = nil
                        UIApplication.appDelegate.saveContext()
                        
                        // Adjust path button
                        self.lblLoginPath.text = "LOGIN PATH"
                        self.isLoggedInPath = false
                    }
                    // Hide loading
                    self.hideLoading()
                }
            }
        }
    }
    
    // MARK: - Phone Verification Delegate Functions
    
    func phoneVerified(newPhone: String) {
        // Change label
        self.lblNoHP.text = newPhone
        
        // Update core data
        var userProfile = CDUserProfile.getOne()!
        userProfile.phone = newPhone
        let m = UIApplication.appDelegate.managedObjectContext
        var err : NSError?
        if ((m?.save(&err))! == false) {
            println("Update phone in core data failed")
        } else {
            println("Update phone in core data success")
        }
    }
    
    // MARK: - Textview Delegate Functions
    
    func textViewDidBeginEditing(textView: UITextView) {
        if (textView.textColor == UIColor.lightGrayColor()) {
            textView.text = ""
            textView.textColor = Theme.GrayDark
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        let fieldTentangShopHeight = fieldTentangShop.frame.size.height
        var sizeThatShouldFitTheContent = fieldTentangShop.sizeThatFits(fieldTentangShop.frame.size)
        //println("sizeThatShouldFitTheContent.height = \(sizeThatShouldFitTheContent.height)")
        
        // Tambahkan tinggi scrollview content sesuai dengan penambahan tinggi textview
        contentViewHeightConstraint.constant = contentViewHeightConstraint.constant + sizeThatShouldFitTheContent.height - fieldTentangShopHeight
        
        // Update tinggi textview
        fieldTentangShopHeightConstraint.constant = sizeThatShouldFitTheContent.height
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if (textView.text.isEmpty) {
            textView.text = FldTentangShopPlaceholder
            textView.textColor = UIColor.lightGrayColor()
        }
    }
    
    @IBAction func JneRegulerPressed(sender: UIButton) {
        jneSelected = !jneSelected
        if (jneSelected) {
            lblJneCheckbox.text = "";
            lblJneCheckbox.font = AppFont.Prelo2.getFont(19)!
            lblJneCheckbox.textColor = Theme.ThemeOrange
        } else {
            lblJneCheckbox.text = "";
            lblJneCheckbox.font = AppFont.PreloAwesome.getFont(24)!
            lblJneCheckbox.textColor = Theme.GrayLight
        }
    }
    
    @IBAction func TikiRegulerPressed(sender: UIButton) {
        tikiSelected = !tikiSelected
        if (tikiSelected) {
            lblTikiCheckbox.text = "";
            lblTikiCheckbox.font = AppFont.Prelo2.getFont(19)!
            lblTikiCheckbox.textColor = Theme.ThemeOrange
        } else {
            lblTikiCheckbox.text = "";
            lblTikiCheckbox.font = AppFont.PreloAwesome.getFont(24)!
            lblTikiCheckbox.textColor = Theme.GrayLight
        }
    }
    
    func fieldsVerified() -> Bool {
        if (fieldNama.text == "") {
            Constant.showDialog("Warning", message: "Nama harus diisi")
            return false
        }
        if (lblProvinsi.text == "Pilih Provinsi") {
            Constant.showDialog("Warning", message: "Provinsi harus diisi")
            return false
        }
        if (lblKabKota.text == "Pilih Kota/Kabupaten") {
            Constant.showDialog("Warning", message: "Kota/Kabupaten harus diisi")
            return false
        }
        if (!jneSelected && !tikiSelected) {
            Constant.showDialog("Warning", message: "Pilihan Kurir harus diisi")
            return false
        }
        return true
    }
    
    @IBAction func simpanDataPressed(sender: UIButton) {
        if (fieldsVerified()) {
            btnSimpanData.enabled = false
            loadingPanel.hidden = false
            loading.startAnimating()
            
            let shipping : String = (jneSelected ? JNE_REGULAR_ID : "") + (tikiSelected ? (jneSelected ? "," : "") + TIKI_REGULAR_ID : "")
            let tentangShop : String = (fieldTentangShop.text != FldTentangShopPlaceholder) ? fieldTentangShop.text : ""
            
            if (!self.isUserPictUpdated) {
                request(APIUser.SetProfile(fullname: fieldNama.text, address: fieldAlamat.text, province: selectedProvinsiID, region: selectedKabKotaID, postalCode: fieldKodePos.text, description: tentangShop, shipping: shipping)).responseJSON { req, resp, res, err in
                    if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Edit Profil")) {
                        let json = JSON(res!)
                        self.simpanDataSucceed(json)
                    } else {
                        self.btnSimpanData.enabled = true
                    }
                }
            } else {
                var url = "\(AppTools.PreloBaseUrl)/api/me/profile"
                var param = [
                    "fullname":fieldNama.text,
                    "address":fieldAlamat.text,
                    "province":selectedProvinsiID,
                    "region":selectedKabKotaID,
                    "postal_code":fieldKodePos.text,
                    "description":tentangShop,
                    "shipping":shipping
                ]
                var images : [UIImage] = []
                images.append(imgUser.image!)
                
                let userAgent : String? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.UserAgent) as? String
                
                AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, andUserAgent: userAgent!, to: url, success: { op, res in
                    println("Edit profile res = \(res)")
                    let json = JSON(res)
                    self.simpanDataSucceed(json)
                }, failure: { op, err in
                    println(err) // failed
                    Constant.showDialog("Edit Profil", message: "Gagal mengupload data")//:err.description)
                    self.btnSimpanData.enabled = true
                    self.loadingPanel.hidden = true
                    self.loading.stopAnimating()
                })
            }
        }
    }
    
    func simpanDataSucceed(json : JSON) {
        println("json = \(json)")
        let data = json["_data"]
        let profile : UserProfile = UserProfile.instance(data)!
        let m = UIApplication.appDelegate.managedObjectContext
        
        // Fetch and edit data
        let user : CDUser = CDUser.getOne()!
        user.fullname = profile.fullname
        
        let userProfile : CDUserProfile = CDUserProfile.getOne()!
        userProfile.address = profile.address
        userProfile.desc = profile.desc
        userProfile.gender = profile.gender
        userProfile.phone = profile.phone
        if (profile.profPictURL != nil) {
            userProfile.pict = "\(profile.profPictURL!)"
        }
        userProfile.postalCode = profile.postalCode
        userProfile.regionID = profile.regionId!
        userProfile.provinceID = profile.provinceId!
        user.profiles = userProfile
        
        // Save data
        var saveErr : NSError? = nil
        if (!m!.save(&saveErr)) {
            Constant.showDialog("Edit Profil", message: "Gagal menyimpan data")
            self.btnSimpanData.enabled = true
            self.loadingPanel.hidden = true
            self.loading.stopAnimating()
        } else {
            println("Data saved")
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
}