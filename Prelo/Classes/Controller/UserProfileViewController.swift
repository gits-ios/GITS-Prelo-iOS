//
//  UserProfileViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

class UserProfileViewController : BaseViewController, PickerViewDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var scrollView : UIScrollView?
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var btnUserImage: UIButton!
    
    @IBOutlet weak var btnLoginInstagram: UIButton!
    @IBOutlet weak var btnLoginFacebook: UIButton!
    @IBOutlet weak var btnLoginTwitter: UIButton!
    @IBOutlet weak var btnLoginPath: UIButton!
    
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
    
    var jneSelected : Bool = false
    var tikiSelected : Bool = false
    let JNE_REGULAR_ID = "54087faabaede1be0b000001"
    let TIKI_REGULAR_ID = "5405c038ace83c4304ec0caf"
    
    var selectedProvinsiID = ""
    var selectedKabKotaID = ""
    var isPickingProvinsi : Bool = false
    var isPickingKabKota : Bool = false
    var isPickingJenKel : Bool = false
    
    var asset : ALAssetsLibrary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavBarButtons()
        initiateFields()
        
        // Border untuk tombol user image
        btnUserImage.layer.borderWidth = 1
        btnUserImage.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        // Border untuk tombol login social media
        btnLoginInstagram.layer.borderWidth = 1
        btnLoginFacebook.layer.borderWidth = 1
        btnLoginTwitter.layer.borderWidth = 1
        btnLoginPath.layer.borderWidth = 1
        btnLoginInstagram.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnLoginFacebook.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnLoginTwitter.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnLoginPath.layer.borderColor = UIColor.lightGrayColor().CGColor
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Mixpanel.sharedInstance().track("Setup Account")
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
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: " Edit Profil", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
        
        // Tombol apply
        let applyButton = UIBarButtonItem(title: "", style:UIBarButtonItemStyle.Done, target:self, action: "simpanDataPressed:")
        applyButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.rightBarButtonItem = applyButton
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
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
        
        // Set fields' default value
        fieldNama.text = user.fullname
        lblNoHP.text = userProfile.phone
        // TODO: ambil gender
        fieldAlamat.text = userProfile.address
        fieldKodePos.text = userProfile.postalCode
        fieldTentangShop.text = userProfile.desc
        self.textViewDidChange(self.fieldTentangShop)
        // TODO: ambil shipping options
        
        println("Req metadata")
        request(APIApp.Metadata).responseJSON { _, _, res, err in
            if let error = err {
                Constant.showDialog("Warning", message: error.description)
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                if (data == nil) { // Data kembalian kosong
                    let obj : [String : String] = res as! [String : String]
                    let message = obj["_message"]
                    Constant.showDialog("Warning", message: message!)
                } else { // Berhasil
                    println("Metadata loaded")
                    for (var i = 0; i < data["provinces_regions"].count; i++) {
                        let province = data["provinces_regions"][i]
                        let provID = province["_id"].string
                        if (provID == userProfile.provinceID) {
                            self.lblProvinsi.text = province["name"].string
                            for (var j = 0; j < province["regions"].count; j++) {
                                let region = province["regions"][j]
                                let regionID = region["_id"].string
                                if (regionID == userProfile.regionID) {
                                    self.lblKabKota.text = region["name"].string
                                    break
                                }
                            }
                            break
                        }
                    }
                }
            }
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
    
    @IBAction func userImagePressed(sender: UIButton) {
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
    
    @IBAction func uploadFotoPressed(sender: UIButton) {
        // TODO : upload foto saja
    }
    
    @IBAction func loginInstagramPressed(sender: UIButton) {
        // TODO : login instagram
    }
    
    @IBAction func loginFacebookPressed(sender: UIButton) {
        // TODO : login facebook
    }
    
    @IBAction func loginTwitterPressed(sender: UIButton) {
        // TODO : login twitter
    }
    
    @IBAction func loginPathPressed(sender: UIButton) {
        // TODO : login path
    }
    
    @IBAction func nomorHpPressed(sender: AnyObject) {
        let phoneReverificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneReverification, owner: nil, options: nil).first as! PhoneReverificationViewController
        phoneReverificationVC.verifiedHP = lblNoHP.text
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
    
    @IBAction func pilihKabKotaPressed(sender: UIButton) {
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
    
    func textViewDidChange(textView: UITextView) {
        let fieldTentangShopHeight = fieldTentangShop.frame.size.height
        var sizeThatShouldFitTheContent = fieldTentangShop.sizeThatFits(fieldTentangShop.frame.size)
        //println("sizeThatShouldFitTheContent.height = \(sizeThatShouldFitTheContent.height)")
        
        // Tambahkan tinggi scrollview content sesuai dengan penambahan tinggi textview
        contentViewHeightConstraint.constant = contentViewHeightConstraint.constant + sizeThatShouldFitTheContent.height - fieldTentangShopHeight
        
        // Update tinggi textview
        fieldTentangShopHeightConstraint.constant = sizeThatShouldFitTheContent.height
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
            Constant.showDialog("Warning", message: "Shipping Options harus diisi")
            return false
        }
        return true
    }
    
    @IBAction func simpanDataPressed(sender: UIButton) {
        if (fieldsVerified()) {
            btnSimpanData.enabled = false
            
            var dataRep = UIImageJPEGRepresentation(btnUserImage.imageView!.image, 1)
            
            var shipping : String = (jneSelected ? JNE_REGULAR_ID : "") + (tikiSelected ? (jneSelected ? "," : "") + TIKI_REGULAR_ID : "")
            
            upload(APIUser.SetProfile(fullname: fieldNama.text, phone: lblNoHP.text!, address: "Alamat pengiriman dummy", region: selectedKabKotaID, postalCode: "Postal code dummy", shopName: "Shop name dummy", Description: fieldTentangShop.text, Shipping: shipping), multipartFormData: { form in
                
                form.appendBodyPart(data : dataRep, name:"userID", mimeType:"image/jpg") // TODO: nama sesuai dengan userID yang didapat setelah register
                
                }, encodingCompletion: { result in
                    switch result
                    {
                    case .Success(let x, _, _):
                        x.responseJSON{_, _, res, err in
                            
                            if let error = err
                            {
                                // error, gagal
                                Constant.showDialog("Warning", message: error.description)
                                self.btnSimpanData.enabled = true
                            } else if let result : AnyObject = res
                            {
                                // sukses
                                let json = JSON(result)
                                println("json = \(json)")
                                let m = UIApplication.appDelegate.managedObjectContext
                                
                                // Fetch and edit data
                                let user : CDUser = CDUser.getOne()!
                                user.fullname = self.fieldNama.text
                                
                                let userProfile : CDUserProfile = CDUserProfile.getOne()!
                                userProfile.desc = self.fieldTentangShop.text
                                userProfile.phone = self.lblNoHP.text!
                                //userProfile.pict = dataRep
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
                                    self.navigationController?.popViewControllerAnimated(true)
                                }
                            }
                        }
                        
                    case .Failure(let err):
                        println(err) // failed
                        Constant.showDialog("Warning", message: err.description)
                        self.btnSimpanData.enabled = true
                    }
            })
        }
    }
    
}