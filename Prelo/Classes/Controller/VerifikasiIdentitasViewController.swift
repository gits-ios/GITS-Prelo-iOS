//
//  VerifikasiIdentitasViewController.swift
//  Prelo
//
//  Created by Prelo on 6/19/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire
import DropDown

class VerifikasiIdentitasViewController: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, VerifikasiImagePreviewDelegate {
    func imageFullScreenDidReplace(_ controller: VerifikasiImagePreview, image: APImage, isCamera: Bool, name: String) {
        print("masuk sini ga?")
        if let i = image.image
        {
            if(isKartuKeluargaClicked){
                self.imgKartuKeluarga.image = i
            } else if (isKartuIdentitasClicked){
                self.imgKartuIdentitas.image = i
            } else if (isInstitusiImageClicked){
                self.imgInstitusiImage.image = i
            }
        } else {
            //Constant.showBadgeDialog("Perhatian", message: "Terjadi kesalahan saat memuat gambar", badge: "warning", view: self, isBack: false)
            Constant.showDialog("Perhatian", message: "Terjadi kesalahan saat memuat gambar")
        }
        
    }

    func imageFullScreenDidDelete(_ controller: VerifikasiImagePreview) {
        self.imgKartuIdentitas.image = nil
    }


    // yang mana yang dipilih
    var isKartuIdentitasClicked: Bool = false
    var isKartuKeluargaClicked: Bool = false
    var isInstitusiImageClicked: Bool = false
    
    // kartu identitas
    @IBOutlet weak var btnKartuIdentitas: UIButton!
    @IBOutlet weak var imgKartuIdentitas: UIImageView!
    var isKartuIdentitasPictUpdated: Bool = false
    
    // kartu keluarga
    @IBOutlet weak var btnKartuKeluarga: UIButton!
    @IBOutlet weak var imgKartuKeluarga: UIImageView!
    var isKartuKeluargaPictUpdated: Bool = false
    
    // institusi
    @IBOutlet weak var btnInstitusiImage: UIButton!
    @IBOutlet weak var imgInstitusiImage: UIImageView!
    var isInstitusiImagePictUpdated: Bool = false
    
    let dropDown = DropDown()
    var selectedIndex = 0
    var isNeedSetup = false
    @IBOutlet weak var lblInstansi: UILabel!
    @IBOutlet weak var txtInstitusi: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDropdownInstitusi()
        getUserRentData()
    }
    
    
    @IBOutlet weak var dropDownInstitusi: UIButton!
    @IBAction func dropDownInstitusiPressed(_ sender: Any) {
        setupDropdownInstitusi()
        dropDown.hide()
        dropDown.show()
        
    }
    
    @IBAction func pilihKartuIdentitasPressed(_ sender: UIButton) {
        self.isKartuIdentitasClicked = true
        isKartuKeluargaClicked = false
        isInstitusiImageClicked = false
        if(imgKartuIdentitas.image == nil){
            imagePicker()
        } else {
            let verifikasiImagePreviewVC = Bundle.main.loadNibNamed(Tags.XibNameVerifikasiImagePreview, owner: nil, options: nil)?.first as! VerifikasiImagePreview
            verifikasiImagePreviewVC.index = 1
            let ap = APImage()
            ap.image = imgKartuIdentitas.image
            verifikasiImagePreviewVC.apImage = ap
            verifikasiImagePreviewVC.fullScreenDelegate = self
            self.navigationController?.pushViewController(verifikasiImagePreviewVC, animated: true)
        }
    }
    
    @IBAction func pilihKartuKeluargaPressed(_ sender: UIButton) {
        isKartuIdentitasClicked = false
        isKartuKeluargaClicked = true
        isInstitusiImageClicked = false
        if(imgKartuKeluarga.image == nil){
            imagePicker()
        } else {
            let verifikasiImagePreviewVC = Bundle.main.loadNibNamed(Tags.XibNameVerifikasiImagePreview, owner: nil, options: nil)?.first as! VerifikasiImagePreview
            verifikasiImagePreviewVC.index = 1
            let ap = APImage()
            ap.image = imgKartuKeluarga.image
            verifikasiImagePreviewVC.apImage = ap
            verifikasiImagePreviewVC.fullScreenDelegate = self
            self.navigationController?.pushViewController(verifikasiImagePreviewVC, animated: true)
        }
    }
    
    @IBAction func pilihInstitusiImagePressed(_ sender: UIButton) {
        isKartuIdentitasClicked = false
        isKartuKeluargaClicked = false
        isInstitusiImageClicked = true
        if(imgInstitusiImage.image == nil){
            imagePicker()
        } else {
            let verifikasiImagePreviewVC = Bundle.main.loadNibNamed(Tags.XibNameVerifikasiImagePreview, owner: nil, options: nil)?.first as! VerifikasiImagePreview
            verifikasiImagePreviewVC.index = 1
            let ap = APImage()
            ap.image = imgInstitusiImage.image
            verifikasiImagePreviewVC.apImage = ap
            verifikasiImagePreviewVC.fullScreenDelegate = self
            self.navigationController?.pushViewController(verifikasiImagePreviewVC, animated: true)
        }
    }
    
    func imagePicker(){
        let i = UIImagePickerController()
        i.sourceType = .photoLibrary
        i.delegate = self
        
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            let a = UIAlertController(title: "Ambil gambar dari:", message: nil, preferredStyle: .actionSheet)
            a.popoverPresentationController?.sourceView = self.btnKartuIdentitas
            a.popoverPresentationController?.sourceRect = self.btnKartuIdentitas.bounds
            a.addAction(UIAlertAction(title: "Kamera", style: .default, handler: { act in
                i.sourceType = .camera
                self.present(i, animated: true, completion: nil)
            }))
            a.addAction(UIAlertAction(title: "Album", style: .default, handler: { act in
                self.present(i, animated: true, completion: nil)
            }))
            a.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in }))
            self.present(a, animated: true, completion: nil)
        } else {
            self.present(i, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if (isKartuIdentitasClicked){
            if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.imgKartuIdentitas.image = img
                self.isKartuIdentitasPictUpdated = true
            }
        } else if(isKartuKeluargaClicked){
            if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.imgKartuKeluarga.image = img
                self.isKartuKeluargaPictUpdated = true
            }
        } else if(isInstitusiImageClicked){
            if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.imgInstitusiImage.image = img
                self.isInstitusiImagePictUpdated = true
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func setupDropdownInstitusi() {
        //dropDown = DropDown()
        
        // The list of items to display. Can be changed dynamically                        
        dropDown.dataSource = ["Pilih Institusi","Sekolah/Kuliah", "Kantor", "Kantor kelurahan/kecamatan sesuai KTP/KK"]
        lblInstansi.text = dropDown.dataSource[selectedIndex]
        
        // Action triggered on selection
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            if index != self.selectedIndex {
                if index < 4 {
                    self.isNeedSetup = false
                    self.selectedIndex = index
                    self.lblInstansi.text = self.dropDown.dataSource[self.selectedIndex]
                } else {
                    self.isNeedSetup = true
                    self.selectedIndex = 4
                }
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        
        dropDown.cellHeight = 40
        
        dropDown.selectRow(at: self.selectedIndex)
        
        dropDown.direction = .bottom
    }
    
    func isValidateField() -> Bool{
        if(imgKartuIdentitas.image == nil){
            Constant.showDialog("Perhatian", message: "Sertakan foto kartu identitas yang masih berlaku")
            return false
        }
        if(imgKartuKeluarga.image == nil){
            Constant.showDialog("Perhatian", message: "Sertakan foto kartu keluarga yang masih berlaku")
            return false
        }
        if(txtInstitusi.text == ""){
            Constant.showDialog("Perhatian", message: "Masukkan nama institusi yang kamu pilih")
            return false
        }
        if(imgInstitusiImage.image == nil){
            Constant.showDialog("Perhatian", message: "Sertakan foto kamu di depan institusi yang kamu pilih")
            return false
        }
        return true
    }
    
    @IBAction func ajukanVerifikasiPressed(_ sender: Any) {
        if(isValidateField()){
            setUserRentData()
        }
    }
    func getUserRentData(){
        let _ = request(APIMe.getUserRentData).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Rent Data")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if let arr = data.array {
                    
                } else {
                    print("masuk ga ada data")
                }
            }
        }
    }
    var images : [AnyObject] = [NSNull(), NSNull(), NSNull()]
    func setUserRentData(){
        let url = "\(AppTools.PreloBaseUrl)/api/me/set_rent_data"
        let param = [
            "institution_type":selectedIndex - 1,
            "institution_name":txtInstitusi.text == nil ? "" : txtInstitusi.text!
            
        ] as [String : Any]
        images[0] = imgKartuIdentitas.image!
        images[1] = imgKartuKeluarga.image!
        images[2] = imgInstitusiImage.image!
        print("ini namanya")
        print(images[0].description())
        print(images[1].description())
        print(images[2].description())
        
        let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
        
        AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, andUserAgent: userAgent!, to: url, success: { op, res in
            print("Edit verifikasi res = \(res)")
            print("berhasil")
            Constant.showDialog("Edit Verifikasi", message: "Berhasil")
            self.navigationController?.popViewController(animated: true)
        }, failure: { op, err in
            //print((err ?? "")) // failed
            Constant.showDialog("Edit Verifikasi", message: "Gagal mengupload data")//:err.description)
        })
        
//        let _ = request(APIMe.setUserRentData(institution_type: selectedIndex, institution_name: self.txtInstitusi.text!, image1: self.imgKartuIdentitas.image!, image2: self.imgKartuKeluarga.image!, image3: self.imgInstitusiImage.image!)).responseJSON{resp in
//            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Rent Data")) {
//                let json = JSON(resp.result.value!)
//                let data = json["_data"]
//                if let arr = data.array {
//                    
//                } else {
//                    print("masuk ga ada data")
//                }
//            }
//        }

    }
}
