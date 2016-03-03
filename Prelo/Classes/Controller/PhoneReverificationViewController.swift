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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.ChangePhone)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ChangePhone)
        
        self.an_subscribeKeyboardWithAnimations(
            {r, t, o in
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
            }, completion: nil)
        
        println("verifiedHP = \(verifiedHP)")
        lblNoHP.text = verifiedHP
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    @IBAction func disableTextFields(sender : AnyObject)
    {
        fieldNoHP?.resignFirstResponder()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UIButton.classForCoder()) || touch.view.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    @IBAction func verifikasiPressed(sender: AnyObject) {
        if (fieldNoHP.text == "") {
            Constant.showDialog("Warning", message: "Isi nomor HP baru untuk verifikasi")
        } else {
            request(APIUser.ResendVerificationSms(phone: self.fieldNoHP.text)).responseJSON { req, resp, res, err in
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Kirim Ulang SMS")) {
                    let json = JSON(res!)
                    let data : Bool? = json["_data"].bool
                    
                    let phoneVerificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil).first as! PhoneVerificationViewController
                    phoneVerificationVC.isReverification = true
                    phoneVerificationVC.noHpToVerify = self.fieldNoHP.text
                    phoneVerificationVC.isShowBackBtn = true
                    phoneVerificationVC.delegate = self.prevVC
                    self.navigationController?.pushViewController(phoneVerificationVC, animated: true)
                }
            }
        }
    }
    
}
