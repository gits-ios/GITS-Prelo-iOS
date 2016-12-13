//
//  ReportProductViewController.swift
//  Prelo
//
//  Created by Djuned on 12/13/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - class

class ReportProductViewController: BaseViewController, UITextViewDelegate {
    
    // MARK: - properties
    
    @IBOutlet weak var lblCheckboxKW: UILabel!
    @IBOutlet weak var lblCheckboxKategoriSalah: UILabel!
    @IBOutlet weak var lblCheckboxBarangBerulang: UILabel!
    @IBOutlet weak var lblCheckboxTerindikasiPenipuan: UILabel!
    
    @IBOutlet weak var txtvwKW: UITextView!
    @IBOutlet weak var txtvwTerindikasiPenipuan: UITextView!
    
    @IBOutlet weak var consHeightKW: NSLayoutConstraint!
    @IBOutlet weak var consHeightKategoriSalah: NSLayoutConstraint!
    @IBOutlet weak var consHeightTerindikasiPenipuan: NSLayoutConstraint!
    
    @IBOutlet weak var txtvwKategoriTerpilih: UILabel!
    var categoryIdSelected : String = ""
    
    // default - all false      KW     KS     BB     TP
//    var checklist : [Bool] = [ false, false, false, false ]
    var checklist : Int = -1
    
    let placeholder = "Alasan"
    
    var root : UIViewController? // For returning to page before product report
    var sellerId : String? // for report product from seller x
    
    var pDetail : ProductDetail?
    
    // MARK: - init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtvwKW.delegate = self
        txtvwTerindikasiPenipuan.delegate = self
        
        
        self.title = "Laporkan Barang"
    }
    
    // MARK: - action
    
    //== KW
    @IBAction func btnKWPressed(_ sender: UIButton) {
//        checklist[0] = checklist[0] == false ? true : false
//        lblCheckboxKW.isHidden = !checklist[0]
//        if checklist[0] == true {
//            consHeightKW.constant = 72
//        } else {
//            consHeightKW.constant = 0
//        }
        
        checklist = 0
        radioButton()
    }
    
    //== kategori salah
    @IBAction func btnKategoriSalahPressed(_ sender: UIButton) {
//        checklist[1] = checklist[1] == false ? true : false
//        lblCheckboxKategoriSalah.isHidden = !checklist[1]
//        if checklist[1] == true {
//            consHeightKategoriSalah.constant = 72
//        } else {
//            consHeightKategoriSalah.constant = 0
//        }
        
        checklist = 1
        radioButton()
    }
    
    @IBAction func btnPilihKategoriPressed(_ sender: UIButton) {
        let mainStoryBoard : UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
        let p = mainStoryBoard.instantiateViewController(withIdentifier: Tags.StoryBoardIdCategoryPicker) as! CategoryPickerViewController
        p.blockDone = { data in
            let children = JSON(data["child"]!)
            
            if let id = children["_id"].string
            {
                self.categoryIdSelected = id
            }
            
            if let name = children["name"].string
            {
                self.txtvwKategoriTerpilih.text = name
            }
            
        }
        p.root = self
        self.navigationController?.pushViewController(p, animated: true)
        

    }
    
    //== barang berulang
    @IBAction func btnBarangBerulangPressed(_ sender: UIButton) {
//        checklist[2] = checklist[2] == false ? true : false
//        lblCheckboxBarangBerulang.isHidden = !checklist[2]
        
        checklist = 2
        radioButton()
    }
    
    //== terindikasi penipuan
    @IBAction func btnTerindikasiPenipuanPressed(_ sender: UIButton) {
//        checklist[3] = checklist[3] == false ? true : false
//        lblCheckboxTerindikasiPenipuan.isHidden = !checklist[3]
//        if checklist[3] == true {
//            consHeightTerindikasiPenipuan.constant = 72
//        } else {
//            consHeightTerindikasiPenipuan.constant = 0
//        }
        
        checklist = 3
        radioButton()
    }
    
    func radioButton() {
        // 0
        lblCheckboxKW.isHidden = checklist == 0 ? false : true
        if checklist == 0 {
            consHeightKW.constant = 72
        } else {
            consHeightKW.constant = 0
        }
        // 1
        lblCheckboxKategoriSalah.isHidden = checklist == 1 ? false : true
        if checklist == 1 {
            consHeightKategoriSalah.constant = 72
        } else {
            consHeightKategoriSalah.constant = 0
        }
        // 2
        lblCheckboxBarangBerulang.isHidden = checklist == 2 ? false : true
        // 3
        lblCheckboxTerindikasiPenipuan.isHidden = checklist == 3 ? false : true
        if checklist == 3 {
            consHeightTerindikasiPenipuan.constant = 72
        } else {
            consHeightTerindikasiPenipuan.constant = 0
        }

    }
    
    //== laporkan
    @IBAction func btnLaporkanPressed(_ sender: UIButton) {
        // post to api
        var report = ""
        var category_id_sebenarnya = ""
        print(checklist)
        if checklist == 0 {
            report = txtvwKW.text == placeholder ? "" : txtvwKW.text
            category_id_sebenarnya = ""
            print(txtvwKW.text)
        } else if checklist == 1 {
            report = ""
            category_id_sebenarnya = categoryIdSelected
            print(txtvwKategoriTerpilih.text)
        } else if checklist == 2 {
            report = ""
            category_id_sebenarnya = ""
        } else if checklist == 3 {
            report = txtvwTerindikasiPenipuan.text == placeholder ? "" : txtvwTerindikasiPenipuan.text
            category_id_sebenarnya = ""
            print(txtvwTerindikasiPenipuan.text)
        }
        
        if (checklist == 1 && category_id_sebenarnya == "") {
            Constant.showDialog("Perhatian", message: "Kategori wajib diisi")
        } else if checklist == -1 {
            Constant.showDialog("Perhatian", message: "Alasan wajib dipilih")
        } else {
            reportProduct(reportType: checklist, reasonText: report, categoryIdCorrection: category_id_sebenarnya)
            
            // back to previos window
            if let r = self.root {
                self.navigationController?.popToViewController(r, animated: true)
            }
        }
    }
    
    func reportProduct(reportType : Int, reasonText : String, categoryIdCorrection : String) {
        request(APIProduct.reportProduct(productId: (self.pDetail?.productID)!, sellerId: (self.pDetail?.theirId)!, reportType: reportType, reasonText: reasonText, categoryIdCorrection: categoryIdCorrection)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Laporkan Barang")) {
                let json = JSON(resp.result.value!)
                if (json["_data"].boolValue == true) {
                    Constant.showDialog("Barang Dilaporkan", message: "Terima kasih, Prelo akan meninjau laporan kamu")
                }
            }
        }
    }
    
    // MARK: - UI textview delegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholder {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = placeholder
            textView.textColor = UIColor.lightGray
        }
    }

}
