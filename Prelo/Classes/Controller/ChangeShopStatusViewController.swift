//
//  ChangeShopStatusViewController.swift
//  Prelo
//
//  Created by Prelo on 7/3/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import UIKit
import DropDown
import Alamofire

class ChangeShopStatusViewController : BaseViewController{
    
    // shop tutup
    @IBOutlet weak var vwShopTutup: UIView!
    @IBOutlet weak var lblDateAndTime: UILabel!
    
    // shop buka
    @IBOutlet weak var vwShopBuka: UIView!
    @IBOutlet weak var vwPengalamanBuruk: UIView!
    @IBOutlet weak var vwLainnya: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePicker2: UIDatePicker!
    @IBOutlet weak var lblTanggalMulai: UILabel!
    @IBOutlet weak var lblTanggalSelesai: UILabel!
    @IBOutlet weak var consSelesaiTop: NSLayoutConstraint! //165
    @IBOutlet weak var consAlasanTop: NSLayoutConstraint! //183
    @IBOutlet weak var consPeringatanAlasanTop: NSLayoutConstraint! //181
    @IBOutlet weak var consPeringatanNotifikasiTop: NSLayoutConstraint!
    @IBOutlet weak var consButtonTopToTutup: NSLayoutConstraint!
    @IBOutlet weak var consButtonTop: NSLayoutConstraint!
    @IBOutlet weak var txtPengalamanBuruk: UITextField!
    @IBOutlet weak var txtLainnya: UITextField!
    @IBOutlet weak var btnOpenClose: UIButton!
    @IBOutlet weak var consVwShopHeight: NSLayoutConstraint!
    @IBOutlet weak var consVwShopOpenHeight: NSLayoutConstraint!
    
    
    @IBAction func btnTanggalMulaiPressed(_ sender: Any) {
        if (datePicker.isHidden){
            datePicker.isHidden = false
            consSelesaiTop.constant = 165
            consVwShopHeight.constant = 650
            
            datePicker2.isHidden = true
            consAlasanTop.constant = 5
            consPeringatanAlasanTop.constant = 5
            
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/YYYY"
            datePicker.isHidden = false
            lblTanggalMulai.text = formatter.string(from: datePicker.date)
            
            if(selectedIndex == 3){
                consVwShopOpenHeight.constant = 670
            } else if (selectedIndex == 6){
                consVwShopOpenHeight.constant = 625
            } else {
                consVwShopOpenHeight.constant = 566
            }

        }
        else {
            datePicker.isHidden = true
            consSelesaiTop.constant = 0
            
            consVwShopHeight.constant = 500
            
            if(selectedIndex == 3){
                consVwShopOpenHeight.constant = 510
            } else if (selectedIndex == 6){
                consVwShopOpenHeight.constant = 460
            } else {
                consVwShopOpenHeight.constant = 400
            }

        }
    }
    @IBAction func btnTanggalSelesaiPressed(_ sender: Any) {
        if (datePicker2.isHidden){
            datePicker2.minimumDate = datePicker.date
            
            datePicker.isHidden = true
            consSelesaiTop.constant = 0
            consVwShopHeight.constant = 650
            
            datePicker2.isHidden = false
            consAlasanTop.constant = 183
            consPeringatanAlasanTop.constant = 181
            
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/YYYY"
            datePicker2.isHidden = false
            lblTanggalSelesai.text = formatter.string(from: datePicker2.date)
            consVwShopHeight.constant = 700
            
            if(selectedIndex == 3){
                consVwShopOpenHeight.constant = 680
            } else if (selectedIndex == 6){
                consVwShopOpenHeight.constant = 635
            } else {
                consVwShopOpenHeight.constant = 576
            }

        }
        else {
            datePicker2.isHidden = true
            consAlasanTop.constant = 5
            consPeringatanAlasanTop.constant = 5
            
            consVwShopHeight.constant = 500
            
            if(selectedIndex == 3){
                consVwShopOpenHeight.constant = 510
            } else if (selectedIndex == 6){
                consVwShopOpenHeight.constant = 460
            } else {
                consVwShopOpenHeight.constant = 400
            }
        }
    }
    
    @IBAction func datePickerValueChanged(_ sender: Any) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/YYYY"
        datePicker.isHidden = false
        lblTanggalMulai.text = formatter.string(from: datePicker.date)
        if(lblTanggalSelesai.text != "DD/MM/YYYY"){
            switch datePicker.date.compare(dateSelesai) {
            case .orderedAscending     : break
            case .orderedDescending    :   datePicker2.minimumDate = datePicker.date
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/YYYY"
            datePicker2.isHidden = true
            lblTanggalSelesai.text = formatter.string(from: datePicker2.date)
            dateSelesai = datePicker2.date
            case .orderedSame          : break
            }
        }
    }
    var dateSelesai = Date()
    
    @IBAction func datePicker2ValueChanged(_ sender: Any) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/YYYY"
        datePicker2.isHidden = false
        lblTanggalSelesai.text = formatter.string(from: datePicker2.date)
        dateSelesai = datePicker2.date
    }
    
    // dropdown alasan
    let dropDown = DropDown()
    var selectedIndex = 0
    var isNeedSetup = false
    @IBOutlet weak var lblAlasan: UILabel!
    @IBOutlet weak var dropDownAlasan: UIButton!
    
    @IBAction func dropDownAlasanPressed(_ sender: Any) {
        dropDown.hide()
        dropDown.show()
        
    }
    func setupDropdownAlasan() {
        //dropDown = DropDown()
        
        // The list of items to display. Can be changed dynamically
        dropDown.dataSource = ["Alasan menutup toko","Sedang berada di luar kota", "Sakit", "Mendapatkan Pengalaman Buruk di Prelo", "Belum ada barang untuk dijual di Prelo", "Barang tidak pernah terjual di Prelo", "Lainnya"]
        lblAlasan.text = dropDown.dataSource[selectedIndex]
        
        // Action triggered on selection
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            if index != self.selectedIndex {
                if index < 7 {
                    self.isNeedSetup = false
                    self.selectedIndex = index
                    self.lblAlasan.text = self.dropDown.dataSource[self.selectedIndex]
                    print("ini index "+String(index))
                    if(index == 3){
                        self.vwPengalamanBuruk.isHidden = false
                        self.vwLainnya.isHidden = true
                        self.consPeringatanNotifikasiTop.constant = 0
                        if(self.datePicker.isHidden == false || self.datePicker2.isHidden == false){
                            self.consVwShopOpenHeight.constant = 680
                        } else {
                            self.consVwShopOpenHeight.constant = 510
                        }
                    } else if (index == 6){
                        self.vwPengalamanBuruk.isHidden = true
                        self.vwLainnya.isHidden = false
                        self.consPeringatanNotifikasiTop.constant = -40
                        if(self.datePicker.isHidden == false || self.datePicker2.isHidden == false){
                            self.consVwShopOpenHeight.constant = 635
                        } else {
                            self.consVwShopOpenHeight.constant = 460
                        }
                    } else {
                        self.vwPengalamanBuruk.isHidden = true
                        self.vwLainnya.isHidden = true
                        self.consPeringatanNotifikasiTop.constant = -100
                        if(self.datePicker.isHidden == false || self.datePicker2.isHidden == false){
                            self.consVwShopOpenHeight.constant = 576
                        } else {
                            self.consVwShopOpenHeight.constant = 400
                        }
                    }
                } else {
                    self.isNeedSetup = true
                    self.selectedIndex = 7
                    
                    if(self.datePicker.isHidden == false || self.datePicker.isHidden == false){
                        self.consVwShopHeight.constant = 620
                        self.consVwShopOpenHeight.constant = 580
                    } else {
                        self.consVwShopHeight.constant = 470
                        self.consVwShopOpenHeight.constant = 430
                    }
                }
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        
        dropDown.cellHeight = 40
        
        dropDown.selectRow(at: self.selectedIndex)
        
        dropDown.direction = .bottom
    }
    
    @IBAction func btnOpenCloseShop(_ sender: Any) {
        if(btnOpenClose.titleLabel?.text == "ATUR TUTUP SHOP"){
            if(isValidateField()){
                closeShop()
            }
        } else {
            openShop()
        }
    }
    
    func isValidateField() -> Bool{
        if(lblTanggalMulai.text == "DD/MM/YYYY"){
            Constant.showDialog("Perhatian", message: "Pilih tanggal mulai tutup")
            return false
        }
        if(lblTanggalSelesai.text == "DD/MM/YYYY"){
            Constant.showDialog("Perhatian", message: "Pilih tanggal berakhirnya tutup toko")
            return false
        }
        if(lblAlasan.text == "Alasan menutup toko"){
            Constant.showDialog("Perhatian", message: "Pilih alasan menutup toko")
            return false
        }
        if(vwPengalamanBuruk.isHidden == false){
            if(txtPengalamanBuruk.text == ""){
                Constant.showDialog("Perhatian", message: "Mohon sertakan pengalaman yang pernah kamu alami")
                return false
            }
        }
        if(vwLainnya.isHidden == false){
            if(txtLainnya.text == ""){
                Constant.showDialog("Perhatian", message: "Mohon sertakan alasan menutup toko")
                return false
            }
        }
        return true
    }
    
    func closeShop(){
        var date : String = ""
        var date2 : String = ""
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        date = formatter.string(from: datePicker.date)
        date2 = formatter.string(from: datePicker2.date)
        var alasanCustom : String? = nil
        if(selectedIndex==3){
            alasanCustom = txtPengalamanBuruk.text
        } else if(selectedIndex == 6){
            alasanCustom = txtLainnya.text
        }
        let _ = request(APIMe.closeUsersShop(start_date: "adfadf", end_date: "dfsadsf", reason: selectedIndex, custom_reason: alasanCustom)).responseJSON{resp in
            if(PreloEndpoints.validate(true, dataResp:resp, reqAlias:"Close Shop")){
                
            }
        }
    }
    
    func openShop(){
        let _ = request(APIMe.openUsersShop).responseJSON{resp in
            print("masuk sini kok")
            if(PreloEndpoints.validate(true, dataResp:resp, reqAlias:"Open Shop")){
                _ = self.navigationController?.popViewController(animated: true)
            }
        }

    }
    
    func getUsersShopData() {
        let _ = request(APIMe.getUsersShopData).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "User's Shop Data")) {
                if let x: AnyObject = resp.result.value as AnyObject? {
                    var json = JSON(x)
                    json = json["_data"]
                    if(json.isEmpty){
                        self.vwShopBuka.isHidden = false
                        self.vwShopTutup.isHidden = true
                        self.btnOpenClose.setTitle("ATUR TUTUP SHOP", for: .normal)
                        self.consButtonTop.isActive = true
                        self.consButtonTopToTutup.isActive = false
                    } else {
                        if(json["status"] == 1){
                            self.vwShopBuka.isHidden = false
                            self.vwShopTutup.isHidden = true
                            self.btnOpenClose.setTitle("ATUR TUTUP SHOP", for: .normal)
                            self.consButtonTop.isActive = true
                            self.consButtonTopToTutup.isActive = false
                            if(json["custom_reason"] != nil){
                                
                                let start_date = json["start_date"].string
                                var arrStart = start_date?.components(separatedBy: "T")
                                var arrLabelStart = arrStart?[0].components(separatedBy: "-")
                                var labelStart = (arrLabelStart?[2])!+"/"+(arrLabelStart?[1])!+"/"+(arrLabelStart?[0])!
                                
                                let end_date = json["end_date"].string
                                var arrEnd = end_date?.components(separatedBy: "T")
                                var arrLabelEnd = arrEnd?[0].components(separatedBy: "-")
                                var labelEnd = (arrLabelEnd?[2])!+"/"+(arrLabelEnd?[1])!+"/"+(arrLabelEnd?[0])!
                                
                                let inputFormatter = DateFormatter()
                                inputFormatter.dateFormat = "dd/MM/yyyy"
                                let showDateStart = inputFormatter.date(from: labelStart)
                                self.datePicker.date = showDateStart!
                                self.lblTanggalMulai.text = labelStart
                                
                                let showDateEnd = inputFormatter.date(from: labelEnd)
                                self.datePicker2.date = showDateEnd!
                                self.lblTanggalSelesai.text = labelEnd
                                
                                self.selectedIndex = json["reason"].int! + 1
                                self.lblAlasan.text = self.dropDown.dataSource[self.selectedIndex]
                                if(self.selectedIndex==3){
                                    self.txtPengalamanBuruk.text = json["custom_reason"].string!
                                    self.vwPengalamanBuruk.isHidden = false
                                    self.vwLainnya.isHidden = true
                                    self.consPeringatanNotifikasiTop.constant = 0
                                    if(self.datePicker.isHidden == false || self.datePicker2.isHidden == false){
                                        self.consVwShopOpenHeight.constant = 680
                                    } else {
                                        self.consVwShopOpenHeight.constant = 510
                                    }
                                } else if (self.selectedIndex==6){
                                    self.txtLainnya.text = json["custom_reason"].string!
                                    self.vwPengalamanBuruk.isHidden = true
                                    self.vwLainnya.isHidden = false
                                    self.consPeringatanNotifikasiTop.constant = -40
                                    if(self.datePicker.isHidden == false || self.datePicker2.isHidden == false){
                                        self.consVwShopOpenHeight.constant = 635
                                    } else {
                                        self.consVwShopOpenHeight.constant = 460
                                    }
                                }

                            }
                        } else {
                            self.vwShopBuka.isHidden = true
                            self.vwShopTutup.isHidden = false
                            self.btnOpenClose.setTitle("BUKA SHOP SEKARANG", for: .normal)
                            self.consButtonTopToTutup.constant = 0
                            self.consButtonTop.isActive = false
                            self.consButtonTopToTutup.isActive = true
                            let end_date = json["end_date"].string
                            var arrEnd = end_date?.components(separatedBy: "T")
                            var arrLabelEndDate = arrEnd?[0].components(separatedBy: "-")
                            var arrLabelEndTime = arrEnd?[1].components(separatedBy: ".")
                            var labelEndDate = (arrLabelEndDate?[2])!+"/"+(arrLabelEndDate?[1])!+"/"+(arrLabelEndDate?[0])!
                            
                            self.lblDateAndTime.text = labelEndDate + " " + (arrLabelEndTime?[0])!
                        }
                    }
                }
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
        
    }

    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChangeShopStatusViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Status Shop"
        initiateField()
        self.hideKeyboardWhenTappedAround()
        getUsersShopData()
        setupDropdownAlasan()
        
    }
    
    func initiateField(){
        vwShopTutup.isHidden = true
        vwLainnya.isHidden = true
        consSelesaiTop.constant = 0
        consAlasanTop.constant = 5
        consPeringatanAlasanTop.constant = 5
        let currentDate: NSDate = NSDate()
        datePicker.minimumDate = currentDate as Date
        self.consPeringatanNotifikasiTop.constant = -100
        consVwShopHeight.constant = 470
        consVwShopOpenHeight.constant = 400
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
}
