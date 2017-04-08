//
//  RefundRequestViewController.swift
//  Prelo
//
//  Created by PreloBook on 12/15/16.
//  Copyright © 2016 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class

enum RefundType {
    case KW
    case Cacat
    case SalahBarang
    
    var value : String {
        switch self {
        case .KW : return "0"
        case .Cacat : return "1"
        case .SalahBarang : return "2"
        }
    }
}

class RefundRequestViewController: BaseViewController, UITextViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet var lblRadioKW: UILabel!
    @IBOutlet var lblRadioCacat: UILabel!
    @IBOutlet var lblRadioSalahBarang: UILabel!
    @IBOutlet var txtvwAlasan: UITextView!
    @IBOutlet var loadingPanel: UIView!
    
    var refundType : RefundType?
    let placeholder = "Tulis detail alasan refund kamu"
    
    // Predefined value
    var tpId : String = ""
    
    // Prelo Analytic - Request Refund
    var pId : String = ""
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        self.title = "Pengajuan Refund"
        
        // Textview setup
        self.txtvwAlasan.layer.borderWidth = 1
        self.txtvwAlasan.layer.borderColor = UIColor.lightGray.cgColor
        self.txtvwAlasan.delegate = self
        
        // Loading setup
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.hideLoading()
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
    
    @IBAction func btnKWPressed(_ sender: UIButton) {
        self.refundType = .KW
        self.lblRadioKW.text = ""
        self.lblRadioKW.textColor = Theme.ThemeOrange
        self.lblRadioCacat.text = ""
        self.lblRadioCacat.textColor = UIColor.lightGray
        self.lblRadioSalahBarang.text = ""
        self.lblRadioSalahBarang.textColor = UIColor.lightGray
    }
    
    @IBAction func btnCacatPressed(_ sender: UIButton) {
        self.refundType = .Cacat
        self.lblRadioKW.text = ""
        self.lblRadioKW.textColor = UIColor.lightGray
        self.lblRadioCacat.text = ""
        self.lblRadioCacat.textColor = Theme.ThemeOrange
        self.lblRadioSalahBarang.text = ""
        self.lblRadioSalahBarang.textColor = UIColor.lightGray
    }
    
    @IBAction func btnSalahBarangPressed(_ sender: UIButton) {
        self.refundType = .SalahBarang
        self.lblRadioKW.text = ""
        self.lblRadioKW.textColor = UIColor.lightGray
        self.lblRadioCacat.text = ""
        self.lblRadioCacat.textColor = UIColor.lightGray
        self.lblRadioSalahBarang.text = ""
        self.lblRadioSalahBarang.textColor = Theme.ThemeOrange
    }
    
    @IBAction func btnSubmitPressed(_ sender: UIButton) {
        if (refundType == nil) {
            Constant.showDialog("Perhatian", message: "Pilih salah satu alasan pengajuan refund")
            return
        }
        if (txtvwAlasan.text == placeholder || txtvwAlasan.text == "") {
            Constant.showDialog("Perhatian", message: "Detail alasan pengajuan harus diisi")
            return
        }
        
        self.showLoading()
        _ = request(APITransactionProduct.refundRequest(tpId: self.tpId, reason: self.refundType!.value, reasonNote: self.txtvwAlasan.text)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Pengajuan Refund")) {
                let json = JSON(resp.result.value!)
                let isSuccess = json["_data"].boolValue
                if (isSuccess) {
                    
                    // Prelo Analytic - Request Refund
                    let loginMethod = User.LoginMethod ?? ""
                    let pdata = [
                        "Product ID" : self.pId
                    ]
                    AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.RequestRefund, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
                    
                    Constant.showDialog("Pengajuan Refund", message: "Pengajuan refund berhasil dilakukan")
                    _ = self.navigationController?.popViewController(animated: true)
                    return
                }
            }
            Constant.showDialog("Pengajuan Refund", message: "Oops, terdapat kesalahan saat melakukan pengajuan refund, silahkan coba beberapa saat lagi")
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
