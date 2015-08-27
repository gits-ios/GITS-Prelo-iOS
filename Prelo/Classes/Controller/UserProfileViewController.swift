//
//  UserProfileViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

class UserProfileViewController : BaseViewController, PickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var btnUserImage: UIButton!
    
    @IBOutlet weak var btnLoginInstagram: UIButton!
    @IBOutlet weak var btnLoginFacebook: UIButton!
    @IBOutlet weak var btnLoginTwitter: UIButton!
    @IBOutlet weak var btnLoginPath: UIButton!
    
    @IBOutlet weak var fieldNama: UITextField!
    @IBOutlet weak var fieldNoHp: UITextField!
    @IBOutlet weak var btnProvinsi: UIButton!
    @IBOutlet weak var btnKabKota: UIButton!
    
    @IBOutlet weak var fieldTentangShop: UITextView!
    @IBOutlet weak var fieldTentangShopHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var btnJneReguler: UIButton!
    @IBOutlet weak var btnTikiReguler: UIButton!
    @IBOutlet weak var btnSimpanData: UIButton!
    
    var jneSelected : Bool = false
    var tikiSelected : Bool = false
    let JNE_REGULAR_ID = "54087faabaede1be0b000001"
    let TIKI_REGULAR_ID = "5405c038ace83c4304ec0caf"
    
    var selectedProvinsiID = ""
    var selectedKabKotaID = ""
    var isPickingProvinsi : Bool = false
    var isPickingKabKota : Bool = false
    
    var previousControllerName : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Border untuk tombol login social media
        btnLoginInstagram.layer.borderWidth = 1
        btnLoginFacebook.layer.borderWidth = 1
        btnLoginTwitter.layer.borderWidth = 1
        btnLoginPath.layer.borderWidth = 1
        btnLoginInstagram.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnLoginFacebook.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnLoginTwitter.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnLoginPath.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        // Pengaturan tinggi field tentang shop
        let fieldTentangShopHeight = fieldTentangShop.frame.size.height
        var sizeThatShouldFitTheContent = fieldTentangShop.sizeThatFits(fieldTentangShop.frame.size)
        //println("sizeThatShouldFitTheContent.height = \(sizeThatShouldFitTheContent.height)")
        // Tambahkan tinggi scrollview content sesuai dengan penambahan tinggi textview
        contentViewHeightConstraint.constant = contentViewHeightConstraint.constant + sizeThatShouldFitTheContent.height - fieldTentangShopHeight
        // Update tinggi textview
        fieldTentangShopHeightConstraint.constant = sizeThatShouldFitTheContent.height
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // TODO: Update tinggi textview sembari mengisi
    
    func pickerDidSelect(item: String) {
        if (isPickingProvinsi) {
            btnProvinsi.titleLabel?.text = PickerViewController.HideHiddenString(item)
            isPickingProvinsi = false
        } else if (isPickingKabKota) {
            btnKabKota.titleLabel?.text = PickerViewController.HideHiddenString(item)
            isPickingKabKota = false
        }
    }
    
    @IBAction func userImagePressed(sender: UIButton) {
        // Akses kamera
        /*if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }*/
        
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
    
    @IBAction func JneRegulerPressed(sender: UIButton) {
        sender.selected = !sender.selected
        jneSelected = !jneSelected
    }
    
    @IBAction func TikiRegulerPressed(sender: UIButton) {
        sender.selected = !sender.selected
        tikiSelected = !tikiSelected
    }
    
    @IBAction func simpanDataPressed(sender: UIButton) {
        btnSimpanData.enabled = false
        
        var dataRep = UIImageJPEGRepresentation(btnUserImage.imageView!.image, 1)
        
        var shipping : String = (jneSelected ? JNE_REGULAR_ID : "") + (tikiSelected ? (jneSelected ? "," : "") + TIKI_REGULAR_ID : "")
        
        upload(APIUser.SetProfile(fullname: fieldNama.text, phone: fieldNoHp.text, address: "Alamat pengiriman dummy", region: selectedKabKotaID, postalCode: "Postal code dummy", shopName: "Shop name dummy", Description: fieldTentangShop.text, Shipping: shipping), multipartFormData: { form in
            
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
                            userProfile.phone = self.fieldNoHp.text
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
                                if (self.previousControllerName == "Register") {
                                    self.dismissViewControllerAnimated(true, completion: nil)
                                } else if (self.previousControllerName == "Dashboard") {
                                    self.navigationController?.popViewControllerAnimated(true)
                                }
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