//
//  AddressAddEdit.swift
//  Prelo
//
//  Created by Djuned on 2/6/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class

class AddressAddEditViewController: BaseViewController, PickerViewDelegate, UITextFieldDelegate {
    // MARK: - Properties
    @IBOutlet weak var txtNamaAlamat: UITextField!
    @IBOutlet weak var txtNama: UITextField!
    @IBOutlet weak var txtTelepon: UITextField!
    @IBOutlet weak var lblProvinsi: UILabel!
    @IBOutlet weak var lblKotaKabupaten: UILabel!
    @IBOutlet weak var lblKecamatan: UILabel!
    @IBOutlet weak var txtAlamat: UITextField!
    @IBOutlet weak var txtKodePos: UITextField!
    @IBOutlet weak var lblLokasi: UILabel!
    @IBOutlet weak var btnAction: UIButton! // Edit / Tambah Alamat
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var editMode: Bool = false
    var address: AddressItem?
    
    var selectedProvinceId: String = ""
    var selectedRegionId: String = ""
    var selectedSubdistrictId: String = ""
    
    var kecamatanPickerItems : [String] = []
    var isPickingProvinsi : Bool = false
    var isPickingKabKota : Bool = false
    var isPickingKecamatan : Bool = false
    
    var isFirst: Bool = true
    
    var coordinate : String = "" // lat,long
    
    let coordinateText = "Pilih Lokasi (opsional)"
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.txtNamaAlamat.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Google Analytics
        if editMode {
            GAI.trackPageVisit(PageName.EditAddress)
        } else {
            GAI.trackPageVisit(PageName.AddAddress)
        }
        
        self.an_subscribeKeyboard(animations: { f, i , o in
            
            if (o)
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
            } else
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
            
        }, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirst {
            if editMode {
                self.title = "Edit Alamat"
                self.btnAction.setTitle("EDIT ALAMAT", for: .normal)
                
                getAddress()
                self.setupLocation(true)
            } else {
                self.title = "Tambah Alamat"
                self.btnAction.setTitle("TAMBAH ALAMAT", for: .normal)
                
                lblLokasi.text = coordinateText
                lblLokasi.textColor = Theme.PrimaryColorDark
                
                self.hideLoading()
                self.setupLocation(false)
            }
            isFirst = false
        }
    }
    
    func getAddress() {
        // load from API
        
        setupAddress(address!)
        
        self.hideLoading()
    }
    
    func setupLocation(_ isActive: Bool) {
        if isActive {
            lblProvinsi.textColor = UIColor.darkGray
            lblKotaKabupaten.textColor = UIColor.darkGray
            lblKecamatan.textColor = UIColor.darkGray
        } else {
            lblProvinsi.textColor = UIColor(hex: "C9C9CE")
            lblKotaKabupaten.textColor = UIColor(hex: "C9C9CE")
            lblKecamatan.textColor = UIColor(hex: "C9C9CE")
        }
    }
    
    func setupAddress(_ address: AddressItem) {
        let regionName = CDRegion.getRegionNameWithID(address.regionId)
        let provinceName = CDProvince.getProvinceNameWithID(address.provinceId)
        
        txtNamaAlamat.text = address.addressName
        txtNama.text = address.recipientName
        txtTelepon.text = address.phone
        lblProvinsi.text = provinceName!
        lblKotaKabupaten.text = regionName!
        lblKecamatan.text = address.subdisrictName
        txtAlamat.text = address.address
        txtKodePos.text = address.postalCode
        
        selectedProvinceId = address.provinceId
        selectedRegionId = address.regionId
        selectedSubdistrictId = address.subdisrictId
        
        if selectedSubdistrictId == "" {
            lblKecamatan.textColor = UIColor(hex: "C9C9CE")
        }
        
        //lblLokasi.textColor = Theme.PrimaryColorDark
        
        if address.coordinateAddress == "" || address.coordinate == "" {
            /*let text = "Pilih Lokasi (opsional)"
            
            let attString : NSMutableAttributedString = NSMutableAttributedString(string: text)
            
            attString.addAttributes([NSForegroundColorAttributeName:UIColor.init(hex: "C9C9CE")], range: (text as NSString).range(of: "(opsional)"))
            
            lblLokasi.attributedText = attString
 */
            lblLokasi.text = coordinateText
            lblLokasi.textColor = Theme.PrimaryColorDark
        } else {
            lblLokasi.text = "Koordinat alamat sudah dipilih" //address.coordinateAddress
            lblLokasi.textColor = UIColor.init(hex: "C9C9CE")
        }
    }
    
    func validateField() -> Bool {
        if !validateString(txtNamaAlamat.text!, label: "Nama Alamat") {
            return false
        }
        
        if !validateString(txtNama.text!, label: "Nama") {
            return false
        }
        
        if !validateString(txtTelepon.text!, label: "Telepon") {
            return false
        }
        
        if !validateString(selectedProvinceId, label: "Provinsi") {
            return false
        }
        
        if !validateString(selectedRegionId, label: "Kota/Kabupaten") {
            return false
        }
        if !validateString(selectedSubdistrictId, label: "Kecamatan") {
            return false
        }
        
        if !validateString(txtAlamat.text!, label: "Alamat") {
            return false
        }
        
        if !validateString(txtKodePos.text!, label: "Kode Pos") {
            return false
        }
        
        return true
    }
    
    func validateString(_ string: String, label: String) -> Bool {
        if (string == "") {
            Constant.showDialog("Perhatian", message: label + " wajib diisi")
            return false
        }
        return true
    }
    
    // MARK: - Button
    // provinsi
    @IBAction func btnPilihProvinsiPressed(_ sender: Any) {
        isPickingProvinsi = true
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = CDProvince.getProvincePickerItems()
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.selectedProvinceId = PickerViewController.RevealHiddenString(string)
            self.selectedRegionId = ""
            self.selectedSubdistrictId = ""
            self.lblKotaKabupaten.text = "Pilih Kota/Kabupaten"
            self.lblKecamatan.text = "Pilih Kecamatan"
            self.lblKotaKabupaten.textColor = UIColor(hex: "C9C9CE")
            self.lblKecamatan.textColor = UIColor(hex: "C9C9CE")
        }
        p?.title = "Provinsi"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    // kota kabupaten
    @IBAction func btnPilihKotaKabupatenPressed(_ sender: Any) {
        isPickingKabKota = true
        if (selectedProvinceId == "") {
            Constant.showDialog("Perhatian", message: "Pilih provinsi terlebih dahulu")
        } else {
            let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
            p?.items = CDRegion.getRegionPickerItems(selectedProvinceId)
            p?.pickerDelegate = self
            p?.selectBlock = { string in
                self.selectedRegionId = PickerViewController.RevealHiddenString(string)
                self.selectedSubdistrictId = ""
                self.lblKecamatan.text = "Pilih Kecamatan"
                self.lblKecamatan.textColor = UIColor(hex: "C9C9CE")
            }
            p?.title = "Kota/Kabupaten"
            self.view.endEditing(true)
            self.navigationController?.pushViewController(p!, animated: true)
        }
    }
    
    // kecamatan
    @IBAction func btnPilihKecamatan(_ sender: Any) {
        if (selectedRegionId == "") {
            Constant.showDialog("Perhatian", message: "Pilih kota/kabupaten terlebih dahulu")
        } else {
            if (kecamatanPickerItems.count <= 0) {
                self.showLoading()
                
                // Retrieve kecamatanPickerItems
                let _ = request(APIMisc.getSubdistrictsByRegionID(id: self.selectedRegionId)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Kecamatan")) {
                        let json = JSON(resp.result.value!)
                        let data = json["_data"].arrayValue
                        
                        if (data.count > 0) {
                            for i in 0...data.count - 1 {
                                self.kecamatanPickerItems.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)
                            }
                            
                            self.pickKecamatan()
                        } else {
                            Constant.showDialog("Oops", message: "Kecamatan tidak ditemukan")
                        }
                    }
                    self.hideLoading()
                }
            } else {
                self.pickKecamatan()
            }
        }
    }
    
    func pickKecamatan() {
        isPickingKecamatan = true
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = kecamatanPickerItems
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.selectedSubdistrictId = PickerViewController.RevealHiddenString(string)
            self.lblKecamatan.text = string.components(separatedBy: PickerViewController.TAG_START_HIDDEN)[0]
        }
        p?.title = "Kecamatan"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }

    @IBAction func btnPilihLokasiPressed(_ sender: Any) {
        
        let googleMapVC = Bundle.main.loadNibNamed(Tags.XibNameGoogleMap, owner: nil, options: nil)?.first as! GoogleMapViewController
        googleMapVC.blockDone = { result in
            print(result)
            
            self.coordinate = result["latitude"]! + "," + result["longitude"]!
            
            self.lblLokasi.text = result["address"]
            self.lblLokasi.textColor = Theme.PrimaryColorDark
        }
        self.navigationController?.pushViewController(googleMapVC, animated: true)
    }
    
    // submit --> add / edit
    @IBAction func btnActionPressed(_ sender: Any) {
        let coordinateAddress = (lblLokasi.text! != coordinateText ? lblLokasi.text! : "")
        
        if validateField() {
            // execute
            if editMode {
                let _ = request(APIMe.updateAddress(addressId: (address?.id)!, addressName: txtNamaAlamat.text!, recipientName: txtNama.text!, phone: txtTelepon.text!, provinceId: selectedProvinceId, provinceName: lblProvinsi.text!, regionId: selectedRegionId, regionName: lblKotaKabupaten.text!, subdistrictId: selectedSubdistrictId, subdistricName: lblKecamatan.text!, address: txtAlamat.text!, postalCode: txtKodePos.text!, isMainAddress: (address?.isMainAddress)!, coordinate: coordinate, coordinateAddress: coordinateAddress)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Edit Alamat")) {
                        Constant.showDialog("Edit Alamat", message: "Alamat berhasil diperbarui")
                        if (self.address?.isMainAddress)! {
                            self.setupProfile()
                        }
                        _ = self.navigationController?.popViewController(animated: true)
                    }
                }
                
            } else { // insert new
                let _ = request(APIMe.createAddress(addressName: txtNamaAlamat.text!, recipientName: txtNama.text!, phone: txtTelepon.text!, provinceId: selectedProvinceId, provinceName: lblProvinsi.text!, regionId: selectedRegionId, regionName: lblKotaKabupaten.text!, subdistrictId: selectedSubdistrictId, subdistricName: lblKecamatan.text!, address: txtAlamat.text!, postalCode: txtKodePos.text!, coordinate: coordinate, coordinateAddress: coordinateAddress)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Tambah Alamat")) {
                        Constant.showDialog("Tambah Alamat", message: "Alamat berhasil ditambahkan")
                        _ = self.navigationController?.popViewController(animated: true)
                    }
                }
                
            }
        }
    }
    
    // MARK: - Update user Profile
    func setupProfile() {
        let m = UIApplication.appDelegate.managedObjectContext
        
        if let userProfile = CDUserProfile.getOne() {
            userProfile.address = txtAlamat.text!
            userProfile.postalCode = txtKodePos.text!
            userProfile.regionID = selectedRegionId
            userProfile.provinceID = selectedProvinceId
            userProfile.subdistrictID = selectedSubdistrictId
            userProfile.subdistrictName = lblKecamatan.text!
            userProfile.addressName = txtNamaAlamat.text!
            userProfile.recipientName = txtNama.text!
            userProfile.coordinate = coordinate
            userProfile.coordinateAddress = (lblLokasi.text! != coordinateText ? lblLokasi.text! : "")
        }
        
        // Save data
        if (m.saveSave() == false) {
            //print("Failed")
        } else {
            //print("Data saved")
        }
    }
    
    // MARK: - Other
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    // MARK: - Picker Delegate
    func pickerDidSelect(_ item: String) {
        if (isPickingProvinsi) {
            lblProvinsi?.text = PickerViewController.HideHiddenString(item)
            lblProvinsi.textColor = UIColor.darkGray
            isPickingProvinsi = false
        } else if (isPickingKabKota) {
            lblKotaKabupaten?.text = PickerViewController.HideHiddenString(item)
            lblKotaKabupaten.textColor = UIColor.darkGray
            isPickingKabKota = false
            kecamatanPickerItems = []
        } else if (isPickingKecamatan) {
            lblKecamatan?.text = PickerViewController.HideHiddenString(item)
            lblKecamatan.textColor = UIColor.darkGray
            isPickingKecamatan = false
        }
    }
    
    func pickerCancelled() {
        isPickingProvinsi = false
        isPickingKabKota = false
        isPickingKecamatan = false
    }
    
    // MARK: - DELEGATE UITEXTFIELD
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.txtNamaAlamat {
            let currentCharacterCount = textField.text?.characters.count ?? 0
            if (range.length + range.location > currentCharacterCount){
                return false
            }
            let newLength = currentCharacterCount + string.characters.count - range.length
            return newLength <= 30
        } else {
            return true
        }
    }
}
