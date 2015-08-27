//
//  UserProfileViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class UserProfileViewController : BaseViewController, PickerViewDelegate {
    
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userImage: UIButton!
    
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
    
    var selectedProvinsiID = ""
    var selectedKabKotaID = ""
    var isPickingProvinsi : Bool = false
    var isPickingKabKota : Bool = false
    
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
        println("sizeThatShouldFitTheContent.height = \(sizeThatShouldFitTheContent.height)")
        // Tambahkan tinggi scrollview content sesuai dengan penambahan tinggi textview
        contentViewHeightConstraint.constant = contentViewHeightConstraint.constant + sizeThatShouldFitTheContent.height - fieldTentangShopHeight
        // Update tinggi textview
        fieldTentangShopHeightConstraint.constant = sizeThatShouldFitTheContent.height
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
    }
    
    @IBAction func uploadFotoPressed(sender: UIButton) {
    }
    
    @IBAction func loginInstagramPressed(sender: UIButton) {
    }
    
    @IBAction func loginFacebookPressed(sender: UIButton) {
    }
    
    @IBAction func loginTwitterPressed(sender: UIButton) {
    }
    
    @IBAction func loginPathPressed(sender: UIButton) {
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
                self.btnKabKota.titleLabel?.text = PickerViewController.RevealHiddenString(string)
            }
        }
        p?.title = "Provinsi"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    @IBAction func JneRegulerPressed(sender: UIButton) {
    }
    
    @IBAction func TikiRegulerPressed(sender: UIButton) {
    }
    
    @IBAction func simpanDataPressed(sender: UIButton) {
        var dataRep = UIImageJPEGRepresentation(userImage.imageView!.image, 1)
        
        upload(APIUser.SetupAccount(province: btnProvinsi.titleLabel!.text!, region: btnKabKota.titleLabel!.text!, phone: fieldNoHp.text, phoneCode: "99999", shippingPackages: "JNE", referral: "TEUNYAHO"), multipartFormData: { form in
            
            form.appendBodyPart(data : dataRep, name:"userID", mimeType:"image/jpg") // TODO: nama sesuai dengan userID yang didapat setelah register
            
            }, encodingCompletion: { result in
                switch result
                {
                case .Success(let x, _, _):
                    x.responseJSON{_, _, res, err in
                        
                        if let error = err
                        {
                            // error, gagal
                        } else if let result : AnyObject = res
                        {
                            // sukses
                            let json = JSON(result)
                        }
                    }
                case .Failure(let err):
                    println(err) // failed
                }
        })
    }
    
}