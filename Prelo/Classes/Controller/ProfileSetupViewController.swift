//
//  ProfileSetupViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/1/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

class ProfileSetupViewController : BaseViewController, PickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
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
    
    var previousControllerName : String?
    
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
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 16)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton*/
        
        // Tombol apply
        let applyButton = UIBarButtonItem(title: "", style:UIBarButtonItemStyle.Done, target:self, action: "applyPressed:")
        applyButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 16)!], forState: UIControlState.Normal)
        self.navigationItem.rightBarButtonItem = applyButton
    }
    
    func backPressed(sender: UIBarButtonItem) {
        if (self.previousControllerName == "Register") {
            if let d = self.userRelatedDelegate
            {
                d.userLoggedIn!()
            }
            self.dismissViewControllerAnimated(true, completion: nil)
        } else if (self.previousControllerName == "Dashboard") {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func hideGroups() {
        /* Digunakan setelah FGD 4 Sept
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
        */
        
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
        self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, deltaHeight, 0)
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
        // Akses galeri
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
            imagePicker.allowsEditing = true
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        btnUserImage.setImage(image, forState: UIControlState.Normal)
        self.dismissViewControllerAnimated(true, completion: nil)
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
        p?.items = []
        p?.pickerDelegate = self
        p?.prepDataBlock = { picker in
            picker.startLoading()
            
            request(References.ProvinceList)
                .responseJSON{ _, _, res, err in
                    if (err != nil) {
                        picker.dismiss()
                    } else {
                        let json = JSON(res!)["_data"].array
                        var r : Array<String> = []
                        let c = json?.count
                        if (c! == 0) {
                            picker.dismiss()
                        } else {
                            for i in 0...c!-1
                            {
                                let j = json?[i]
                                let n = (j?["name"].string)! + PickerViewController.TAG_START_HIDDEN + (j?["_id"].string)! + PickerViewController.TAG_END_HIDDEN
                                r.append(n)
                            }
                            picker.items = r
                            picker.tableView.reloadData()
                            picker.doneLoading()
                        }
                    }
            }
            
            // On select block
            picker.selectBlock = { string in
                self.selectedProvinsiID = PickerViewController.RevealHiddenString(string)
            }
        }
        p?.title = "Provinsi"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    @IBAction func kabKotaPressed(sender: AnyObject) {
        isPickingKabKota = true
        
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = []
        p?.pickerDelegate = self
        p?.prepDataBlock = { picker in
            picker.startLoading()
            
            request(References.CityList(provinceId: self.selectedProvinsiID))
                .responseJSON{ _, _, res, err in
                    if (err != nil) {
                        picker.dismiss()
                    } else {
                        let json = JSON(res!)["_data"].array
                        var r : Array<String> = []
                        let c = json?.count
                        if (c! == 0) {
                            picker.dismiss()
                        } else {
                            for i in 0...c!-1
                            {
                                let j = json?[i]
                                let n = (j?["name"].string)! + PickerViewController.TAG_START_HIDDEN + (j?["_id"].string)! + PickerViewController.TAG_END_HIDDEN
                                r.append(n)
                            }
                            picker.items = r
                            picker.tableView.reloadData()
                            picker.doneLoading()
                        }
                    }
            }
            
            // On select block
            picker.selectBlock = { string in
                self.selectedKabKotaID = PickerViewController.RevealHiddenString(string)
            }
        }
        p?.title = "Kota/Kabupaten"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
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
            
            let jenisKelamin = lblJenisKelamin?.text
            let nomorHP = fieldNoHP?.text
            let shipping : String = (jneSelected ? JNE_REGULAR_ID : "") + (tikiSelected ? (jneSelected ? "," : "") + TIKI_REGULAR_ID : "")
            request(APIUser.SetProfile(fullname: "Dummy setup fullname", phone: nomorHP!, address: "Dummy setup address", region: selectedKabKotaID, postalCode: "Dummy setup postal code", shopName: "Dummy setup shop name", Description: "Dummy setup description", Shipping: shipping)).responseJSON { _, _, res, err in
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
                        
                        // Fetch and edit data
                        let user : CDUser = CDUser.getOne()!
                        
                        let userProfile : CDUserProfile = CDUserProfile.getOne()!
                        userProfile.regionID = self.selectedKabKotaID
                        userProfile.provinceID = self.selectedProvinsiID
                        user.profiles = userProfile
                        
                        // Save data
                        var saveErr : NSError? = nil
                        if (!m!.save(&saveErr)) {
                            println("Error while saving data")
                        } else {
                            println("Data saved")
                            //self.btnSimpanData.enabled = true
                            if (self.previousControllerName == "Register") {
                                if let d = self.userRelatedDelegate
                                {
                                    d.userLoggedIn!()
                                }
                                self.dismissViewControllerAnimated(true, completion: nil)
                            } else if (self.previousControllerName == "Dashboard") {
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        }
                    }
                }
            }
        }
    }
}