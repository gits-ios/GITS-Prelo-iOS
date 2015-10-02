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
    
    @IBOutlet weak var groupUploadFoto: UIView!
    @IBOutlet weak var btnUserImage: UIButton!
    
    @IBOutlet weak var groupFullname: UIView!
    @IBOutlet weak var fieldFullname: UITextField!
    
    @IBOutlet weak var consTopGroupJenKel: NSLayoutConstraint!
    @IBOutlet weak var lblJenisKelamin: UILabel!
    
    @IBOutlet weak var groupNoHP: UIView!
    @IBOutlet weak var fieldNoHP: UITextField!
    
    @IBOutlet weak var consTopGroupVerifikasiHP: NSLayoutConstraint!
    @IBOutlet weak var groupVerifikasiHP: UIView!
    @IBOutlet weak var fieldVerifikasiNoHP: UITextField!
    @IBOutlet weak var fieldKodeVerifikasi: UITextField!
    
    @IBOutlet weak var consTopGroupKota: NSLayoutConstraint!
    @IBOutlet weak var lblProvinsi: UILabel!
    @IBOutlet weak var lblKabKota: UILabel!
    
    @IBOutlet weak var lblJneCheckbox: UILabel!
    @IBOutlet weak var lblTikiCheckbox: UILabel!
    
    @IBOutlet weak var groupReferral: UIView!
    @IBOutlet weak var fieldKodeReferral: UITextField!
    
    @IBOutlet weak var consTopBtnApply: NSLayoutConstraint!
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        setNavBarButtons()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideGroups()
        
        // Border untuk tombol user image
        btnUserImage.layer.borderWidth = 1
        btnUserImage.layer.borderColor = UIColor.lightGrayColor().CGColor
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Mixpanel.sharedInstance().track("Setup Account")
        self.an_subscribeKeyboardWithAnimations(
            {r, t, o in
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, self.deltaHeight + r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, self.deltaHeight, 0)
                }
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func setNavBarButtons() {
        // Tombol back
        self.navigationItem.hidesBackButton = true
        /*let newBackButton = UIBarButtonItem(title: " Setup Akun", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton*/
        
        // Tombol apply
        let applyButton = UIBarButtonItem(title: "", style:UIBarButtonItemStyle.Done, target:self, action: "applyPressed:")
        applyButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.rightBarButtonItem = applyButton
    }
    
    func backPressed(sender: UIBarButtonItem) {
        if let d = self.userRelatedDelegate
        {
            d.userLoggedIn!()
        }
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func hideGroups() {
        groupUploadFoto.hidden = true
        groupFullname.hidden = true
        groupVerifikasiHP.hidden = true
        
        // Naikin group lainnya
        let separateHeight : CGFloat = 30
        consTopGroupJenKel.constant -= groupUploadFoto.frame.size.height + groupFullname.frame.size.height + separateHeight
        deltaHeight -= groupUploadFoto.frame.size.height + groupFullname.frame.size.height + separateHeight
        consTopGroupKota.constant -= groupVerifikasiHP.frame.size.height + separateHeight
        deltaHeight -= groupVerifikasiHP.frame.size.height + separateHeight
        
        // Sesuaikan tinggi scrollview content
        self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, deltaHeight, 0)
        
        /* Digunakan untuk FGD 4 Sept
        groupFullname.hidden = true
        groupNoHP.hidden = true
        //groupReferral.hidden = true

        // Naikin group lainnya
        let separateHeight : CGFloat = 30
        consTopGroupJenKel.constant -= groupFullname.frame.size.height
        deltaHeight -= groupFullname.frame.size.height
        consTopGroupVerifikasiHP.constant -= groupNoHP.frame.size.height
        consTopGroupKota.constant -= groupNoHP.frame.size.height
        deltaHeight -= groupNoHP.frame.size.height
        //consTopBtnApply.constant -= groupReferral.frame.size.height + separateHeight
        //deltaHeight -= groupReferral.frame.size.height + separateHeight
        
        // Sesuaikan tinggi scrollview content
        self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, deltaHeight, 0)*/
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
            isPickingJenKel = false
        } else if (isPickingProvinsi) {
            lblProvinsi?.text = PickerViewController.HideHiddenString(item)
            isPickingProvinsi = false
        } else if (isPickingKabKota) {
            lblKabKota?.text = PickerViewController.HideHiddenString(item)
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
            Constant.showDialog("Warning", message: "Shipping Options harus diisi")
            return false
        }
        return true
    }
    
    @IBAction func applyPressed(sender: AnyObject) {
        if (fieldsVerified()) {
            disableTextFields(NSNull)
            btnApply.enabled = false
            
            let userGender = (lblJenisKelamin?.text == "Pria") ? 0 : 1
            let userPhone = fieldNoHP?.text
            let userShipping : String = (jneSelected ? JNE_REGULAR_ID : "") + (tikiSelected ? (jneSelected ? "," : "") + TIKI_REGULAR_ID : "")
            let userReferral = fieldKodeReferral.text
            let userDeviceId = "dor" // FIXME
            
            // TODO: harusnya ini dipasang di phone verification karna kalau belum verification dianggap belum tuntas, jika exit app saat verification lalu buka app lagi harusnya belum kelogin
            User.StoreUser(self.userId, token: self.userToken, email: self.userEmail)
            if let d = self.userRelatedDelegate
            {
                d.userLoggedIn!()
            }
            if let c = CDUser.getOne()
            {
                Mixpanel.sharedInstance().identify(c.id)
                Mixpanel.sharedInstance().people.set(["$first_name":c.fullname!, "$name":c.email, "user_id":c.id])
            } else {
                Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
            }
            
            request(APIUser.SetupAccount(gender: userGender, phone: userPhone!, province: selectedProvinsiID, region: selectedKabKotaID, shipping: userShipping, referralCode: userReferral, deviceId: userDeviceId)).responseJSON { _, _, res, err in
                if let error = err {
                    Constant.showDialog("Warning", message: error.description)
                    self.btnApply.enabled = true
                } else {
                    let json = JSON(res!)
                    let data = json["_data"]
                    if (data == nil) { // Data kembalian kosong
                        let obj : [String : String] = res as! [String : String]
                        let message = obj["_message"]
                        Constant.showDialog("Warning", message: message!)
                        self.btnApply.enabled = true
                    } else { // Berhasil
                        println("Setup account succeed")
                        println("Setup account data = \(data)")
                        
                        let m = UIApplication.appDelegate.managedObjectContext
                        
                        // Save in core data
                        CDUser.deleteAll()
                        let user : CDUser = (NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser)
                        
                        CDUserProfile.deleteAll()
                        let userProfile : CDUserProfile = (NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile)
                        userProfile.regionID = self.selectedKabKotaID
                        userProfile.provinceID = self.selectedProvinsiID
                        userProfile.phone = userPhone!
                        userProfile.gender = self.lblJenisKelamin.text!
                        user.profiles = userProfile
                        // TODO: Simpan shipping, referral, deviceid di coredata
                        
                        // Save data
                        var saveErr : NSError? = nil
                        if (!m!.save(&saveErr)) {
                            println("Error while saving data")
                        } else {
                            println("Data saved")
                            //self.btnSimpanData.enabled = true

                            /* Digunakan jika setelah scene ini adalah scene phone verification
                            // TODO : Coba POST phone verification dulu sebelum pindah scene

                            let phoneVerificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil).first as! PhoneVerificationViewController
                            self.navigationController?.pushViewController(phoneVerificationVC, animated: true)
                            */
                            
                            // FOR TESTING (SKIP PHONE VERIFICATION)
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    }
                }
            }
        }
    }
}