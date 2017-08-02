//
//  RekeningAddViewController.swift
//  Prelo
//
//  Created by Prelo (Chyntia) on 6/12/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class

class RekeningAddViewController: BaseViewController, PickerViewDelegate, UITextFieldDelegate {
    // MARK: - Properties
    
    @IBOutlet weak var pilihBank: UILabel!
    @IBOutlet weak var txtRekening: UITextField!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtCabang: UITextField!
    @IBOutlet weak var btnAction: UIButton!
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var editMode: Bool = false
    var rekening: RekeningItem?

    var isFirst: Bool = true
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
                self.title = "Edit Rekening"
                self.btnAction.setTitle("EDIT REKENING", for: .normal)
                
                getRekening()
            } else {
                
                self.title = "Tambah Rekening"
                self.btnAction.setTitle("TAMBAH REKENING", for: .normal)
                
            }
            isFirst = false
        }
        
        
    }
    
    func getRekening(){
        pilihBank.text = rekening?.target_bank
        txtRekening.text = rekening?.account_number
        txtName.text = rekening?.name
        txtCabang.text = rekening?.branch
    }
    
    func isValidateField() -> Bool{
        if !validateString(pilihBank.text!, label: "Bank"){
            return false
        }
        if !validateString(txtRekening.text!, label: "Nomor Rekening"){
            return false
        }
        if !validateString(txtName.text!, label: "Nama"){
            return false
        }
        if !validateString(txtCabang.text!, label: "Cabang"){
            return false
        }
        return true
    }
    
    func validateString(_ string: String, label: String) -> Bool {
        if (string == "") {
            Constant.showDialog("Perhatian", message: label + " wajib diisi")
            return false
        }
        if (string == "Pilih Bank") {
            Constant.showDialog("Perhatian", message: label + " wajib diisi")
            return false
        }
        return true
    }
    
    // submit --> add / edit
    @IBAction func btnActionPressed(_ sender: Any) {
        if(isValidateField()){
            if editMode { //edit
                let _ = request(APIMe.editBankAccount(doc_id: (rekening?.id)!, target_bank: self.pilihBank.text!, account_number: self.txtRekening.text!, name: self.txtName.text!, branch: self.txtCabang.text!, is_default: (rekening?.isDefaultBankAccount)!)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Edit Rekening")) {
                        Constant.showDialog("Edit Rekening", message: "Rekening berhasil diperbarui")
                        _ = self.navigationController?.popViewController(animated: true)
                    }
                }
            } else { //new
                let _ = request(APIMe.addBankAccount(target_bank: self.pilihBank.text!, account_number: self.txtRekening.text!, name: self.txtName.text!, branch: self.txtCabang.text!)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Tambah Rekening")) {
                    Constant.showDialog("Tambah Rekening", message: "Rekening berhasil ditambahkan")
                    _ = self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    var item=""
    var bankPickerItems : [String] = []
    
    @IBAction func pilihBankPressed(_ sender: Any) {
        // Retrieve bankPickerItems
        bankPickerItems = []
        let _ = request(APIReference.getAllBank()).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Bank")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"].arrayValue
                if (data.count > 0) {
                    for i in 0...data.count - 1 {
                        self.bankPickerItems.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)
                    }
                    
                    self.pickBank()
                }
            }
        }
    }
    
    func pickBank(){
        
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.bankMode = true
        p?.items = self.bankPickerItems
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.item = PickerViewController.RevealHiddenString(string)
        }
        p?.showSearch = true
        p?.title = "Bank"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    
    func pickerDidSelect(_ item: String) {
        self.pilihBank.text = PickerViewController.HideHiddenString(item)
        self.pilihBank.textColor = UIColor(hex: "000000")
        
    }
    
    // MARK: - Other
//    func showLoading() {
//        self.loadingPanel.isHidden = false
//    }
//    
//    func hideLoading() {
//        self.loadingPanel.isHidden = true
//    }
    
    
}
