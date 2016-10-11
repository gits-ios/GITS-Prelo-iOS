//
//  PhoneReverificationViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/9/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class PhoneReverificationViewController : BaseViewController {
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var lblNoHP : UILabel!
    @IBOutlet weak var fieldNoHP : UITextField!
    @IBOutlet weak var btnVerifikasiNoHP : UIButton!
    
    var verifiedHP : String?
    
    var prevVC : UserProfileViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Nomor Handphone"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
        //Mixpanel.trackPageVisit(PageName.ChangePhone)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ChangePhone)
        
        self.an_subscribeKeyboard(
            animations: {r, t, o in
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
            }, completion: nil)
        
        print("verifiedHP = \(verifiedHP)")
        lblNoHP.text = verifiedHP
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    @IBAction func disableTextFields(_ sender : AnyObject)
    {
        fieldNoHP?.resignFirstResponder()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    @IBAction func verifikasiPressed(_ sender: AnyObject) {
        if (fieldNoHP.text == "") {
            Constant.showDialog("Warning", message: "Isi nomor HP baru untuk verifikasi")
        } else {
            // API Migrasi
        request(APIUser.resendVerificationSms(phone: self.fieldNoHP.text!)).responseJSON {resp in
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Kirim Ulang SMS")) {
                    let json = JSON(resp.result.value!)
                    _ = json["_data"].bool
                    
                    let phoneVerificationVC = Bundle.main.loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil).first as! PhoneVerificationViewController
                    phoneVerificationVC.isReverification = true
                    phoneVerificationVC.noHpToVerify = self.fieldNoHP.text == nil ? "" : self.fieldNoHP.text!
                    phoneVerificationVC.isShowBackBtn = true
                    phoneVerificationVC.delegate = self.prevVC
                    self.navigationController?.pushViewController(phoneVerificationVC, animated: true)
                }
            }
        }
    }
    
}
