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

class ChangeShopStatusViewController : BaseViewController{
    
    // shop tutup
    @IBOutlet weak var vwShopTutup: UIView!
    
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
    @IBOutlet weak var txtPengalamanBuruk: UITextField!
    @IBOutlet weak var txtLainnya: UITextField!
    
    
    @IBAction func btnTanggalMulaiPressed(_ sender: Any) {
        if (datePicker.isHidden){
            datePicker.isHidden = false
            consSelesaiTop.constant = 165
            
            datePicker2.isHidden = true
            consAlasanTop.constant = 5
            consPeringatanAlasanTop.constant = 5
            
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/YYYY"
            datePicker.isHidden = false
            lblTanggalMulai.text = formatter.string(from: datePicker.date)
        }
        else {
            datePicker.isHidden = true
            consSelesaiTop.constant = 0
        }
    }
    @IBAction func btnTanggalSelesaiPressed(_ sender: Any) {
        if (datePicker2.isHidden){
            datePicker2.minimumDate = datePicker.date
            
            datePicker.isHidden = true
            consSelesaiTop.constant = 0
            
            datePicker2.isHidden = false
            consAlasanTop.constant = 183
            consPeringatanAlasanTop.constant = 181
            
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/YYYY"
            datePicker2.isHidden = false
            lblTanggalSelesai.text = formatter.string(from: datePicker2.date)
        }
        else {
            datePicker2.isHidden = true
            consAlasanTop.constant = 5
            consPeringatanAlasanTop.constant = 5
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
        setupDropdownAlasan()
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
                    } else if (index == 6){
                        self.vwPengalamanBuruk.isHidden = true
                        self.vwLainnya.isHidden = false
                        self.consPeringatanNotifikasiTop.constant = -40
                    } else {
                        self.vwPengalamanBuruk.isHidden = true
                        self.vwLainnya.isHidden = true
                        self.consPeringatanNotifikasiTop.constant = -100
                    }
                } else {
                    self.isNeedSetup = true
                    self.selectedIndex = 7
                }
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        
        dropDown.cellHeight = 40
        
        dropDown.selectRow(at: self.selectedIndex)
        
        dropDown.direction = .bottom
    }
    
    @IBAction func btnTutupShop(_ sender: Any) {
        if(isValidateField()){
            // set api
            print("masuk sini")
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Status Shop"
        vwShopTutup.isHidden = true
        vwLainnya.isHidden = true
        consSelesaiTop.constant = 0
        consAlasanTop.constant = 5
        consPeringatanAlasanTop.constant = 5
        let currentDate: NSDate = NSDate()
        datePicker.minimumDate = currentDate as Date
        consPeringatanNotifikasiTop.constant = -100
    }
}
