//
//  ProfileSetupViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/1/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

class ProfileSetupViewController : BaseViewController, PickerViewDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var consHeightContentView: NSLayoutConstraint!
    
    @IBOutlet weak var lblHeaderAlert: UILabel!
    
    // Groups index:
    // 0 : Group Upload Foto
    // 1 : Group Fullname
    // 2 : Group Email
    // 3 : Group Jenis Kelamin
    // 4 : Group No HP
    // 5 : Group Verifikasi HP
    // 6 : Group Kota
    // 7 : Group Shipping Options
    // 8 : Group Referal
    // 9 : Group Apply
    @IBOutlet weak var groupUploadFoto: UIView!
    @IBOutlet weak var groupFullname: UIView!
    @IBOutlet weak var groupEmail: UIView!
    @IBOutlet weak var groupJenisKelamin: UIView!
    @IBOutlet weak var groupNoHp: UIView!
    @IBOutlet weak var groupVerifikasiHp: UIView!
    @IBOutlet weak var groupKota: UIView!
    @IBOutlet weak var groupShippingOptions: UIView!
    @IBOutlet weak var groupReferral: UIView!
    @IBOutlet weak var groupApply: UIView!
    var groups: [UIView] = []
    
    @IBOutlet weak var consTopUploadFoto: NSLayoutConstraint!
    @IBOutlet weak var consTopFullname: NSLayoutConstraint!
    @IBOutlet weak var consTopEmail: NSLayoutConstraint!
    @IBOutlet weak var consTopJenisKelamin: NSLayoutConstraint!
    @IBOutlet weak var consTopNoHp: NSLayoutConstraint!
    @IBOutlet weak var consTopVerifikasiHp: NSLayoutConstraint!
    @IBOutlet weak var consTopKota: NSLayoutConstraint!
    @IBOutlet weak var consTopShippingOptions: NSLayoutConstraint!
    @IBOutlet weak var consTopReferral: NSLayoutConstraint!
    @IBOutlet weak var consTopApply: NSLayoutConstraint!
    var consTopGroups: [NSLayoutConstraint] = []
    
    @IBOutlet weak var btnUserImage: UIButton!
    
    @IBOutlet weak var lblFullname: UILabel!
    @IBOutlet weak var fieldFullname: UITextField!
    
    @IBOutlet weak var fieldEmail: UITextField!
    
    @IBOutlet weak var lblJenisKelamin: UILabel!
    
    @IBOutlet weak var fieldNoHP: UITextField!
    
    @IBOutlet weak var fieldVerifikasiNoHP: UITextField!
    @IBOutlet weak var fieldKodeVerifikasi: UITextField!
    
    @IBOutlet weak var lblProvinsi: UILabel!
    @IBOutlet weak var lblKabKota: UILabel!
    
    @IBOutlet weak var lblJneCheckbox: UILabel!
    @IBOutlet weak var lblTikiCheckbox: UILabel!
    
    @IBOutlet weak var fieldKodeReferral: UITextField!
    
    @IBOutlet weak var btnApply: UIButton!
    
    var jneSelected : Bool = false
    var tikiSelected : Bool = false
    let JNE_REGULAR_ID = "54087faabaede1be0b000001"
    let TIKI_REGULAR_ID = "5405c038ace83c4304ec0caf"
    
    var selectedProvinsiID = ""
    var selectedKabKotaID = ""
    var isPickingProvinsi : Bool = false
    var isPickingKabKota : Bool = false
    var isPickingJenKel : Bool = false
    
    var deltaHeight : CGFloat = 0
    
    var asset : ALAssetsLibrary?
    
    // Variable from previous scene
    var userId : String = ""
    var userToken : String = ""
    var userEmail : String = ""
    var isSocmedAccount : Bool!
    var loginMethod : String = "" // [Basic | Facebook | Twitter]
    var screenBeforeLogin : String = ""
    var isMixpanelPageVisitSent : Bool = false
    var isFromRegister : Bool!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        setupContent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Setelan Akun"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
        if (!self.isMixpanelPageVisitSent) {
            Mixpanel.trackPageVisit(PageName.SetupAccount)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.SetupAccount)
            
            // Di sini akan dikirim mixpanel event register, hanya jika user baru saja melakukan register 
            // Pengecekan apakah baru register ada 2 lapis
            // Pertama: dicek apakah CDUser tidak nil, karena kalau login dan masuk ke ProfileSetupVC, seharusnya CDUser masih kosong, sedangkan kalau setelah register seharusnya CDUser terisi
            // Kedua: apakah registerTime terjadi kurang dari 1 menit yang lalu (karna profile setup pasti dipanggil setelah register berhasil)
            // Pengecekan kedua dilakukan karena pengecekan pertama terkadang bocor
            if let c = CDUser.getOne() {
                var minutesSinceReg = 0
                if let o = CDUserOther.getOne() {
                    if let regTime = o.registerTime {
                        minutesSinceReg = NSDate().minutesFromIsoFormatted(regTime)
                    }
                }
                if (minutesSinceReg <= 1) {
                    let sp = [
                        "Email" : c.email,
                        "Username" : c.username,
                        "Fullname" : c.fullname!,
                        "Login Method" : self.loginMethod
                    ]
                    Mixpanel.sharedInstance().registerSuperProperties(sp)
                    let spo = [
                        "Register Time" : NSDate().isoFormatted,
                        "Register Method" : self.loginMethod
                    ]
                    Mixpanel.sharedInstance().registerSuperPropertiesOnce(spo)
                    Mixpanel.sharedInstance().identify(c.id)
                    let p = [
                        "$email" : c.email,
                        "$username" : c.username,
                        "$name" : c.fullname!
                    ]
                    Mixpanel.sharedInstance().people.set(p)
                    let po = [
                        "$created" : NSDate().isoFormatted,
                        "Register Method" : self.loginMethod
                    ]
                    Mixpanel.sharedInstance().people.setOnce(po)
                    let pr = [
                        "Previous Screen" : self.screenBeforeLogin
                    ]
                    Mixpanel.trackEvent(MixpanelEvent.Register, properties: pr)
                }
            }
            
            self.isMixpanelPageVisitSent = true
        }
        
        // Keyboard animation handling
        self.an_subscribeKeyboardWithAnimations(
            {r, t, o in
                if (o) {
                    self.consHeightContentView.constant += r.height
                } else {
                    self.consHeightContentView.constant -= r.height
                }
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    override func backPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setupContent() {
        // Set header alert
        if (!isFromRegister) {
            self.lblHeaderAlert.text = "Kamu perlu menyelesaikan Setelan Akun"
        }
        
        // Set groups and top constraints manually
        groups.append(self.groupUploadFoto)
        groups.append(self.groupFullname)
        groups.append(self.groupEmail)
        groups.append(self.groupJenisKelamin)
        groups.append(self.groupNoHp)
        groups.append(self.groupVerifikasiHp)
        groups.append(self.groupKota)
        groups.append(self.groupShippingOptions)
        groups.append(self.groupReferral)
        groups.append(self.groupApply)
        consTopGroups.append(self.consTopUploadFoto)
        consTopGroups.append(self.consTopFullname)
        consTopGroups.append(self.consTopEmail)
        consTopGroups.append(self.consTopJenisKelamin)
        consTopGroups.append(self.consTopNoHp)
        consTopGroups.append(self.consTopVerifikasiHp)
        consTopGroups.append(self.consTopKota)
        consTopGroups.append(self.consTopShippingOptions)
        consTopGroups.append(self.consTopReferral)
        consTopGroups.append(self.consTopApply)
        
        // Arrange groups
        var p : [Bool]!
        if (self.isSocmedAccount == true) {
            p = [false, true, (self.userEmail == ""), true, true, false, true, true, false, true]
        } else {
            p = [false, false, (self.userEmail == ""), true, true, false, true, true, false, true]
        }
        arrangeGroups(p)
        
        // If user uses socmed account, change fullname field to username field
        if (self.isSocmedAccount == true) {
            lblFullname.text = "Username"
            fieldFullname.placeholder = "Username"
        }
        
        // Border untuk tombol user image
        btnUserImage.layer.borderWidth = 1
        btnUserImage.layer.borderColor = UIColor.lightGrayColor().CGColor
    }
    
    func arrangeGroups(isShowGroups : [Bool]) {
        let narrowSpace : CGFloat = 15
        let wideSpace : CGFloat = 25
        var deltaX : CGFloat = 0
        for (var i = 0; i < isShowGroups.count; i++) { // asumsi i = 0-9
            let isShowGroup : Bool = isShowGroups[i]
            if isShowGroup {
                groups[i].hidden = false
                // Manual narrow/wide space
                if (i == 0 || i == 2 || (i == 3 && !groups[1].hidden) || i == 4) { // Narrow space before group
                    deltaX += narrowSpace
                } else { // Wide space before group
                    deltaX += wideSpace
                }
                consTopGroups[i].constant = deltaX
                deltaX += groups[i].frame.size.height
            } else {
                groups[i].hidden = true
            }
        }
        // Set content view height
        consHeightContentView.constant = deltaX + narrowSpace
    }
    
    @IBAction func disableTextFields(sender : AnyObject)
    {
        fieldFullname?.resignFirstResponder()
        fieldNoHP?.resignFirstResponder()
        fieldVerifikasiNoHP?.resignFirstResponder()
        fieldKodeVerifikasi?.resignFirstResponder()
        fieldKodeReferral?.resignFirstResponder()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UIButton.classForCoder()) || touch.view.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    func pickerDidSelect(item: String) {
        if (isPickingJenKel) {
            lblJenisKelamin?.text = PickerViewController.HideHiddenString(item)
            lblJenisKelamin.textColor = Theme.GrayDark
            isPickingJenKel = false
        } else if (isPickingProvinsi) {
            lblProvinsi?.text = PickerViewController.HideHiddenString(item)
            lblProvinsi.textColor = Theme.GrayDark
            isPickingProvinsi = false
        } else if (isPickingKabKota) {
            lblKabKota?.text = PickerViewController.HideHiddenString(item)
            lblKabKota.textColor = Theme.GrayDark
            isPickingKabKota = false
        }
    }
    
    @IBAction func userImagePressed(sender: AnyObject) {
        ImagePickerViewController.ShowFrom(self, maxSelect: 1, doneBlock:
            { imgs in
                if (imgs.count > 0) {
                    self.btnUserImage.setImage(ImageSourceCell.defaultImage, forState: UIControlState.Normal)
                    
                    let img : APImage = imgs[0]
                    
                    if ((img.image) != nil)
                    {
                        self.btnUserImage.setImage(img.image, forState: UIControlState.Normal)
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
                                        self.btnUserImage.setImage(i, forState: UIControlState.Normal)
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
    
    @IBAction func uploadFotoPressed(sender: AnyObject) {
        if (btnUserImage.imageView?.image == nil) {
            Constant.showDialog("Warning", message: "Pilih foto terlebih dahulu")
        } else {
            Constant.showDialog("Success", message: "Upload foto berhasil")
        }
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
    
    @IBAction func verifikasiNoHPPressed(sender: AnyObject) {
        if (fieldVerifikasiNoHP.text == "") {
            Constant.showDialog("Warning", message: "Isi no HP terlebih dahulu")
        } else {
            Constant.showDialog("Success", message: "Verifikasi no HP berhasil")
            fieldKodeVerifikasi.text = "123456"
        }
    }
    
    @IBAction func provinsiPressed(sender: AnyObject) {
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
    
    @IBAction func kabKotaPressed(sender: AnyObject) {
        if (selectedProvinsiID == "") {
            Constant.showDialog("Warning", message: "Pilih provinsi terlebih dahulu")
        } else {
            isPickingKabKota = true
            
            let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
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
    
    @IBAction func jneRegulerPressed(sender: UIButton) {
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
    
    @IBAction func tikiRegulerPressed(sender: UIButton) {
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
        if (isSocmedAccount == true) { // fieldFullname menjadi fieldUsername
            if (fieldFullname.text == "") {
                Constant.showDialog("Warning", message: "Username harus diisi")
                return false
            } else {
                let usernameRegex = "^[a-zA-Z0-9_]{4,15}$"
                if (fieldFullname.text.match(usernameRegex) == false) {
                    Constant.showDialog("Warning", message: "Username harus sepanjang 4-15 karakter (a-z, A-Z, 0-9, _)")
                    return false
                }
            }
        }
        if (self.userEmail == "" && fieldEmail.text == "") {
            Constant.showDialog("Warning", message: "E-mail harus diisi")
        }
        if (fieldNoHP.text == "") {
            Constant.showDialog("Warning", message: "Nomor HP harus diisi")
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
    
    @IBAction func applyPressed(sender: AnyObject) {
        if (fieldsVerified()) {
            disableTextFields(NSNull)
            btnApply.enabled = false
            
            var username = ""
            if (self.isSocmedAccount == true) {
                username = (fieldFullname?.text)!
            }
            var email = ""
            if (self.userEmail == "") {
                email = fieldEmail.text
            }
            let userFullname = fieldFullname?.text
            let userGender = (lblJenisKelamin?.text == "Pria") ? 0 : 1
            let userPhone = fieldNoHP?.text
            let userShipping : String = (jneSelected ? JNE_REGULAR_ID : "") + (tikiSelected ? (jneSelected ? "," : "") + TIKI_REGULAR_ID : "")
            let userReferral = fieldKodeReferral.text
            let userDeviceId = UIDevice.currentDevice().identifierForVendor!.UUIDString
            
            // Get device token
            let deviceToken = NSUserDefaults.standardUserDefaults().stringForKey("deviceregid")!
            //println("deviceToken = \(deviceToken)")
            
            // Token belum disimpan pake User.StoreUser karna di titik ini user belum dianggap login
            // Set token first, because APIUser.SetupAccount & APIUser.SetUserPreferencedCategories need token
            User.SetToken(self.userToken)
            
            request(APIUser.SetupAccount(username: username, email: email,gender: userGender, phone: userPhone!, province: selectedProvinsiID, region: selectedKabKotaID, shipping: userShipping, referralCode: userReferral, deviceId: userDeviceId, deviceRegId: deviceToken)).responseJSON { req, resp, res, err in
                
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Setelan Akun")) {
                    let json = JSON(res!)
                    let data = json["_data"]
                    
                    // Set user's preferenced categories by current stored categories
                    // Dilakukan di sini (bukan di register atau phone verification) karna register dibedakan antara normal dan via socmed, dan phone verification dilakukan bisa berkali2 saat edit profile
                    request(APIUser.SetUserPreferencedCategories(categ1: NSUserDefaults.categoryPref1(), categ2: NSUserDefaults.categoryPref2(), categ3: NSUserDefaults.categoryPref3())).responseJSON { req, resp, res, err in
                        if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Set User Preferenced Categories")) {
                            let json = JSON(res!)
                            let isSuccess = json["_data"].bool!
                            if (isSuccess) { // Berhasil
                                println("Success setting user preferenced categories")
                            } else { // Gagal
                                println("Error setting user preferenced categories")
                            }
                        }
                        // Delete token because user is considered not logged in
                        User.SetToken(nil)
                    }
                    
                    let userProfileData = UserProfile.instance(data)
                    
                    // Mixpanel
                    let sp = [
                        "User ID" : userProfileData?.id,
                        "Username" : userProfileData?.username,
                        "Gender" : userProfileData?.gender,
                        "Province Input" : (userProfileData != nil) ? (CDProvince.getProvinceNameWithID(userProfileData!.provinceId)!) : "",
                        "City Input" : (userProfileData != nil) ? (CDRegion.getRegionNameWithID(userProfileData!.regionId)!) : "",
                        "Referral Code Used" : userReferral
                    ]
                    Mixpanel.sharedInstance().registerSuperProperties(sp)
                    Mixpanel.sharedInstance().identify(userProfileData?.id)
                    let p = [
                        "User ID" : userProfileData?.id,
                        "$username" : userProfileData?.username,
                        "Gender" : userProfileData?.gender,
                        "Province Input" : (userProfileData != nil) ? (CDProvince.getProvinceNameWithID(userProfileData!.provinceId)!) : "",
                        "City Input" : (userProfileData != nil) ? (CDRegion.getRegionNameWithID(userProfileData!.regionId)!) : "",
                        "Referral Code Used" : userReferral
                    ]
                    Mixpanel.sharedInstance().people.set(p)
                    var shippingArr : [String] = []
                    var shippingArrName : [String] = []
                    for (var i = 0; i < data["shipping_preferences_ids"].count; i++) {
                        let s : String = data["shipping_preferences_ids"][i].string!
                        shippingArr.append(s)
                        if let sName = CDShipping.getShippingCompleteNameWithId(s) {
                            shippingArrName.append(sName)
                        }
                    }
                    var pt = [String : AnyObject]()
                    pt["Shipping Options"] = shippingArrName
                    pt["Phone"] = userProfileData?.phone
                    Mixpanel.trackEvent(MixpanelEvent.SetupAccount, properties: pt as [NSObject : AnyObject])
                    let pt2 = [
                        "Activation Screen" : "Setup Account"
                    ]
                    Mixpanel.trackEvent(MixpanelEvent.ReferralUsed, properties: pt2)
                    
                    let phoneVerificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil).first as! PhoneVerificationViewController
                    phoneVerificationVC.userRelatedDelegate = self.userRelatedDelegate
                    phoneVerificationVC.userId = self.userId
                    phoneVerificationVC.userToken = self.userToken
                    phoneVerificationVC.userEmail = (userProfileData != nil) ? userProfileData!.email : "" // Tidak menggunakan 'self.userEmail' karena mungkin kosong dan baru diset di halaman ini
                    phoneVerificationVC.isShowBackBtn = false
                    phoneVerificationVC.loginMethod = self.loginMethod
                    phoneVerificationVC.noHpToVerify = userPhone!
                    phoneVerificationVC.userProfileData = userProfileData
                    self.navigationController?.pushViewController(phoneVerificationVC, animated: true)
                } else {
                    self.btnApply.enabled = true
                }
            }
        }
    }
}