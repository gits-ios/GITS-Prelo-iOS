//
//  ReportTransactionViewController.swift
//  Prelo
//
//  Created by Djuned on 3/29/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class

enum ReportTransactionType {
    case BelumTerimaBarang
    case ResiTidakValid
    case FotoResiTidakSesuai
    case Lainnya
    
    var value : String {
        switch self {
        case .BelumTerimaBarang : return "0"
        case .ResiTidakValid : return "1"
        case .FotoResiTidakSesuai : return "2"
        case .Lainnya : return "3"
        }
    }
}

class ReportTransactionViewController: BaseViewController, UITextViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var lblRadioBelumTerimaBarang: UILabel!
    @IBOutlet weak var lblRadioResiTidakValid: UILabel!
    @IBOutlet weak var lblRadioFotoResiTidakSesuai: UILabel!
    @IBOutlet weak var lblRadioLainnya: UILabel!
    @IBOutlet weak var txtvwAlasan: UITextView! // enable -> lainnya
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var consBottomBtnSubmit: NSLayoutConstraint!
    
    @IBOutlet weak var lblDetailSatu: UILabel!
    @IBOutlet weak var lblDetailDua: UILabel!
    
    var reportTransactionType : ReportTransactionType?
    let placeholder = "Tulis detail alasan lainnya"
    
    // Predefined value
    var tpId : String = ""
    var sellerId : String = ""
    var wjpTime : String = "6"
    
    // Prelo Analytic - Request Refund
    //var pId : String = ""
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        self.title = "Pelaporan Transaksi"
        
        // Textview setup
        self.txtvwAlasan.layer.borderWidth = 1
        self.txtvwAlasan.layer.borderColor = Theme.GrayLight.cgColor //UIColor.lightGray.cgColor
        self.txtvwAlasan.delegate = self
        
        // Loading setup
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.hideLoading()
        
        // setup teks
        self.lblDetailSatu.text = "Waktu Jaminan Prelo akan diperpanjang menjadi " + wjpTime + " hari"
        self.lblDetailSatu.boldSubstring("Waktu Jaminan Prelo")
        
        self.lblDetailDua.text = "Jika dalam " + wjpTime + " hari transaksi kamu berhasil tanpa masalah maka uang pembayaran kamu akan otomatis disalurkan ke penjual"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboard(animations: { r, t, o in
            if (o) {
                self.consBottomBtnSubmit.constant = r.height
            } else {
                self.consBottomBtnSubmit.constant = 0
            }
        }, completion: nil)
    }
    
    // MARK: - Textview functions
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView.text == placeholder) {
            textView.text = ""
            textView.textColor = UIColor.darkGray
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView.text == "") {
            textView.text = placeholder
            textView.textColor = UIColor.lightGray
        }
    }
    
    // MARK: - Actions
    
    @IBAction func disableTextView(_ sender: Any) {
        self.txtvwAlasan.resignFirstResponder()
    }
    
    @IBAction func btnBelumTerimaBarangPressed(_ sender: UIButton) {
        self.reportTransactionType = .BelumTerimaBarang
        self.lblRadioBelumTerimaBarang.text = ""
        self.lblRadioBelumTerimaBarang.textColor = Theme.ThemeOrange
        self.lblRadioResiTidakValid.text = ""
        self.lblRadioResiTidakValid.textColor = UIColor.lightGray
        self.lblRadioFotoResiTidakSesuai.text = ""
        self.lblRadioFotoResiTidakSesuai.textColor = UIColor.lightGray
        self.lblRadioLainnya.text = ""
        self.lblRadioLainnya.textColor = UIColor.lightGray
        
        self.txtvwAlasan.isEditable = false
        self.txtvwAlasan.isSelectable = false
        self.txtvwAlasan.layer.borderColor = Theme.GrayLight.cgColor
        self.txtvwAlasan.text = placeholder
        self.txtvwAlasan.textColor = UIColor.lightGray
        self.txtvwAlasan.resignFirstResponder()
    }
    
    @IBAction func btnResiTidakValidPressed(_ sender: UIButton) {
        self.reportTransactionType = .ResiTidakValid
        self.lblRadioBelumTerimaBarang.text = ""
        self.lblRadioBelumTerimaBarang.textColor = UIColor.lightGray
        self.lblRadioResiTidakValid.text = ""
        self.lblRadioResiTidakValid.textColor = Theme.ThemeOrange
        self.lblRadioFotoResiTidakSesuai.text = ""
        self.lblRadioFotoResiTidakSesuai.textColor = UIColor.lightGray
        self.lblRadioLainnya.text = ""
        self.lblRadioLainnya.textColor = UIColor.lightGray
        
        self.txtvwAlasan.isEditable = false
        self.txtvwAlasan.isSelectable = false
        self.txtvwAlasan.layer.borderColor = Theme.GrayLight.cgColor
        self.txtvwAlasan.text = placeholder
        self.txtvwAlasan.textColor = UIColor.lightGray
        self.txtvwAlasan.resignFirstResponder()
    }
    
    @IBAction func btnFotoResiTidakSesuaiPressed(_ sender: UIButton) {
        self.reportTransactionType = .FotoResiTidakSesuai
        self.lblRadioBelumTerimaBarang.text = ""
        self.lblRadioBelumTerimaBarang.textColor = UIColor.lightGray
        self.lblRadioResiTidakValid.text = ""
        self.lblRadioResiTidakValid.textColor = UIColor.lightGray
        self.lblRadioFotoResiTidakSesuai.text = ""
        self.lblRadioFotoResiTidakSesuai.textColor = Theme.ThemeOrange
        self.lblRadioLainnya.text = ""
        self.lblRadioLainnya.textColor = UIColor.lightGray
        
        self.txtvwAlasan.isEditable = false
        self.txtvwAlasan.isSelectable = false
        self.txtvwAlasan.layer.borderColor = Theme.GrayLight.cgColor
        self.txtvwAlasan.text = placeholder
        self.txtvwAlasan.textColor = UIColor.lightGray
        self.txtvwAlasan.resignFirstResponder()
    }
    
    @IBAction func btnLainnyaPressed(_ sender: UIButton) {
        self.reportTransactionType = .Lainnya
        self.lblRadioBelumTerimaBarang.text = ""
        self.lblRadioBelumTerimaBarang.textColor = UIColor.lightGray
        self.lblRadioResiTidakValid.text = ""
        self.lblRadioResiTidakValid.textColor = UIColor.lightGray
        self.lblRadioFotoResiTidakSesuai.text = ""
        self.lblRadioFotoResiTidakSesuai.textColor = UIColor.lightGray
        self.lblRadioLainnya.text = ""
        self.lblRadioLainnya.textColor = Theme.ThemeOrange
        
        self.txtvwAlasan.isEditable = true
        self.txtvwAlasan.isSelectable = true
        self.txtvwAlasan.layer.borderColor = Theme.GrayDark.cgColor
        self.txtvwAlasan.becomeFirstResponder()
    }
    
    @IBAction func btnSubmitPressed(_ sender: UIButton) {
        if (reportTransactionType == nil) {
            Constant.showDialog("Perhatian", message: "Pilih salah satu alasan pelaporan transaksi")
            return
        }
        if (reportTransactionType == .Lainnya && (txtvwAlasan.text == placeholder || txtvwAlasan.text == "")) {
            Constant.showDialog("Perhatian", message: "Detail alasan lainnya harus diisi")
            return
        }
        
        self.txtvwAlasan.resignFirstResponder()
        
        self.showLoading()
        _ = request(APITransactionProduct.reportTransaction(tpId: self.tpId, reason: self.reportTransactionType!.value, reasonNote: self.txtvwAlasan.text, sellerId: self.sellerId)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Pelaporan Transaksi")) {
                //let json = JSON(resp.result.value!)
                //let isSuccess = json["_data"].boolValue
                //if (isSuccess) {
                    
                    /*
                    // Prelo Analytic - Request Refund
                    let loginMethod = User.LoginMethod ?? ""
                    let pdata = [
                        "Product ID" : self.pId
                    ]
                    AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.RequestRefund, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
                    */
                    
                    Constant.showDialog("Pelaporan Transaksi", message: "Pelaporan transaksi berhasil dilakukan")
                    _ = self.navigationController?.popViewController(animated: true)
                    return
                //}
            }
            Constant.showDialog("Pelaporan Transaksi", message: "Oops, terdapat kesalahan saat melakukan pelaporan transaksi, silahkan coba beberapa saat lagi")
            self.hideLoading()
        }
         
    }
    
    // MARK: - Other functions
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
}
