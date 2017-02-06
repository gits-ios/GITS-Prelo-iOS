//
//  AddressAddEdit.swift
//  Prelo
//
//  Created by Djuned on 2/6/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class

class AddressAddEditViewController: BaseViewController, PickerViewDelegate {
    // MARK: - Properties
    @IBOutlet weak var txtNamaAlamat: UITextField!
    @IBOutlet weak var txtNama: UITextField!
    @IBOutlet weak var txtTelepon: UITextField!
    @IBOutlet weak var lblProvinsi: UILabel!
    @IBOutlet weak var lblKotaKabupaten: UILabel!
    @IBOutlet weak var lblKecamatan: UILabel!
    @IBOutlet weak var txtAlamat: UITextField!
    @IBOutlet weak var txtKodePos: UITextField!
    @IBOutlet weak var btnAction: UIButton! // Edit / Tambah Alamat
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var editMode: Bool = false
    var addressId: String = ""
    
    var selectedProvinceId: String = ""
    var selectedRegionId: String = ""
    var selectedSubdistrictId: String = ""
    
    var kecamatanPickerItems : [String] = []
    var isPickingProvinsi : Bool = false
    var isPickingKabKota : Bool = false
    var isPickingKecamatan : Bool = false
    
    var isFirst: Bool = true
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
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
                
                getAddress(addressId)
                self.setupLocation(true)
            } else {
                self.title = "Tambah Alamat"
                self.btnAction.setTitle("TAMBAH ALAMAT", for: .normal)
                
                self.hideLoading()
                self.setupLocation(false)
            }
            isFirst = false
        }
    }
    
    func getAddress(_ addressId: String) {
        let fakeres = [
            "address_name":"coba-" + addressId,
            "recipient_name":"djuned",
            "address": "Jl kartini 44",
            "province_id": "533f81506d07364195779449", // jawa timur
            "region_id": "53a6e369490cd61d3a00001b", // kab kediri
            "subdistrict_id":"5758f2a1f8ec1c50289c78d5", // plemahan
            "subdistrict_name":"Plemahan",
            "phone": "087759035853",
            "postal_code": "64155",
            "is_main_address": addressId.int % 3 == 0
            ] as [String : Any]
        
        let json = JSON(fakeres)
        let address = AddressItem.instance(json)
        
        setupAddress(address!)
        
        self.hideLoading()

        // TODO: - load from API
    }
    
    func setupLocation(_ isActive: Bool) {
        if isActive {
            lblProvinsi.textColor = Theme.GrayDark
            lblKotaKabupaten.textColor = Theme.GrayDark
            lblKecamatan.textColor = Theme.GrayDark
        } else {
            lblProvinsi.textColor = Theme.GrayLight
            lblKotaKabupaten.textColor = Theme.GrayLight
            lblKecamatan.textColor = Theme.GrayLight
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
            self.lblKotaKabupaten.text = "Pilih Kota/Kabupaten"
            self.lblKecamatan.text = "Pilih Kecamatan"
            self.lblKotaKabupaten.textColor = Theme.GrayLight
            self.lblKecamatan.textColor = Theme.GrayLight
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
                self.lblKecamatan.text = "Pilih Kecamatan"
                self.lblKecamatan.textColor = Theme.GrayLight
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

    // submit --> add / edit
    @IBAction func btnActionPressed(_ sender: Any) {
        if validateField() {
            // execute
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
            lblProvinsi.textColor = Theme.GrayDark
            isPickingProvinsi = false
        } else if (isPickingKabKota) {
            lblKotaKabupaten?.text = PickerViewController.HideHiddenString(item)
            lblKotaKabupaten.textColor = Theme.GrayDark
            isPickingKabKota = false
            kecamatanPickerItems = []
        } else if (isPickingKecamatan) {
            lblKecamatan?.text = PickerViewController.HideHiddenString(item)
            lblKecamatan.textColor = Theme.GrayDark
            isPickingKecamatan = false
        }
    }
    
    func pickerCancelled() {
        isPickingProvinsi = false
        isPickingKabKota = false
        isPickingKecamatan = false
    }
}
