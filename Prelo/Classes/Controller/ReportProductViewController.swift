//
//  ReportProductViewController.swift
//  Prelo
//
//  Created by Djuned on 12/13/16.
//  Copyright © 2016 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - class

class ReportProductViewController: BaseViewController, UITextViewDelegate {
    
    // MARK: - properties
    
    @IBOutlet weak var lblRadioKW: UILabel!
    @IBOutlet weak var lblRadioKategoriSalah: UILabel!
    @IBOutlet weak var lblRadioBarangBerulang: UILabel!
    @IBOutlet weak var lblRadioTerindikasiPenipuan: UILabel!
    
    @IBOutlet weak var txtvwKW: UITextView!
    @IBOutlet weak var txtvwTerindikasiPenipuan: UITextView!
    
    @IBOutlet weak var consHeightKW: NSLayoutConstraint!
    @IBOutlet weak var consHeightKategoriSalah: NSLayoutConstraint!
    @IBOutlet weak var consHeightTerindikasiPenipuan: NSLayoutConstraint!
    
    @IBOutlet weak var txtvwKategoriTerpilih: UILabel!
    var categoryIdSelected : String = ""
    
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
        
        // style
        txtvwKW.layer.borderColor = UIColor.lightGray.cgColor
        txtvwKW.layer.borderWidth = 1.0
        
        txtvwTerindikasiPenipuan.layer.borderColor = UIColor.lightGray.cgColor
        txtvwTerindikasiPenipuan.layer.borderWidth = 1.0
        
        self.title = "Laporkan Barang"
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard) /*"dismissKeyboard"*/)
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - action
    
    //== KW
    @IBAction func btnKWPressed(_ sender: UIButton) {
        checklist = 0
        radioButton()
    }
    
    //== kategori salah
    @IBAction func btnKategoriSalahPressed(_ sender: UIButton) {
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
        checklist = 2
        radioButton()
    }
    
    //== terindikasi penipuan
    @IBAction func btnTerindikasiPenipuanPressed(_ sender: UIButton) {
        checklist = 3
        radioButton()
    }
    
    func radioButton() {
        // 0
        if checklist == 0 {
            self.lblRadioKW.text = ""
            self.lblRadioKW.textColor = Theme.ThemeOrange
            consHeightKW.constant = 72
        } else {
            self.lblRadioKW.text = ""
            self.lblRadioKW.textColor = UIColor.lightGray
            consHeightKW.constant = 0
        }
        
        // 1
        if checklist == 1 {
            self.lblRadioKategoriSalah.text = ""
            self.lblRadioKategoriSalah.textColor = Theme.ThemeOrange
            consHeightKategoriSalah.constant = 72
        } else {
            self.lblRadioKategoriSalah.text = ""
            self.lblRadioKategoriSalah.textColor = UIColor.lightGray
            consHeightKategoriSalah.constant = 0
        }
        
        // 2
        if checklist == 2 {
            self.lblRadioBarangBerulang.text = ""
            self.lblRadioBarangBerulang.textColor = Theme.ThemeOrange
        } else {
            self.lblRadioBarangBerulang.text = ""
            self.lblRadioBarangBerulang.textColor = UIColor.lightGray
        }
        
        // 3
        if checklist == 3 {
            self.lblRadioTerindikasiPenipuan.text = ""
            self.lblRadioTerindikasiPenipuan.textColor = Theme.ThemeOrange
            consHeightTerindikasiPenipuan.constant = 72
        } else {
            self.lblRadioTerindikasiPenipuan.text = ""
            self.lblRadioTerindikasiPenipuan.textColor = UIColor.lightGray
            consHeightTerindikasiPenipuan.constant = 0
        }

        dismissKeyboard()
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
//            print(txtvwKW.text)
        } else if checklist == 1 {
            report = ""
            category_id_sebenarnya = categoryIdSelected
//            print(txtvwKategoriTerpilih.text)
        } else if checklist == 2 {
            report = ""
            category_id_sebenarnya = ""
        } else if checklist == 3 {
            report = txtvwTerindikasiPenipuan.text == placeholder ? "" : txtvwTerindikasiPenipuan.text
            category_id_sebenarnya = ""
//            print(txtvwTerindikasiPenipuan.text)
        }
        
        if (checklist == 1 && category_id_sebenarnya == "") {
            Constant.showDialog("Perhatian", message: "Kategori wajib dipilih / diisi")
        } else if checklist == -1 {
            Constant.showDialog("Perhatian", message: "Alasan pelaporan wajib dipilih")
        } else if (checklist == 0 || checklist == 3) && report == "" {
            Constant.showDialog("Perhatian", message: "Alasan wajib diisi")
        } else {
            reportProduct(reportType: checklist, reasonText: report, categoryIdCorrection: category_id_sebenarnya)
            
            // notif
//            Constant.showDialog("Close", message: "Terima kasih, Prelo akan meninjau laporan kamu")
            
            // back to previos window
            if let r = self.root {
                _ = self.navigationController?.popToViewController(r, animated: true)
            }
        }
    }
    
    func reportProduct(reportType : Int, reasonText : String, categoryIdCorrection : String) {
        request(APIProduct.reportProduct(productId: (self.pDetail?.productID)!, sellerId: (self.pDetail?.theirId)!, reportType: reportType, reasonText: reasonText, categoryIdCorrection: categoryIdCorrection)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Laporkan Barang")) {
//                let json = JSON(resp.result.value!)
//                if (json["_data"].boolValue == true) {
                    Constant.showDialog("Barang Dilaporkan", message: "Terima kasih, Prelo akan meninjau laporan kamu")
//                }
                
                // Prelo Analytic - Report Product
                let loginMethod = User.LoginMethod ?? ""
                let reportingUsername = (CDUser.getOne()?.username)!
                let pdata = [
                    "Product ID" : (self.pDetail?.productID)!,
                    "Reported Username" : (self.pDetail?.theirName)!,
                    "Reporting Username" : reportingUsername,
                    "Reason" : reportType
                ] as [String : Any]
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ReportProduct, data: pdata, previousScreen: PageName.ProductDetail, loginMethod: loginMethod)
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
    
    // MARK: - close keyboard
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

}
