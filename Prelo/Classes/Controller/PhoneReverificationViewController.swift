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
        
        setNavBarButtons()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Mixpanel.trackPageVisit("Change Phone")
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
    
    func setNavBarButtons() {
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: " Nomor Handphone", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
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
            request(APIUser.ResendVerificationSms(phone: self.fieldNoHP.text)).responseJSON {req, _, res, err in
                
                println("Resend verification sms req = \(req)")
                if (err != nil) {
                    Constant.showDialog("Warning", message: "Resend sms error")//: \(err?.description)")
                } else {
                    let json = JSON(res!)
                    let data : Bool? = json["_data"].bool
                    if (data == nil || data == false) { // Gagal
                        Constant.showDialog("Warning", message: "Resend sms error")
                    } else { // Berhasil
                        println("data = \(data)")
                        
                        let phoneVerificationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil).first as! PhoneVerificationViewController
                        phoneVerificationVC.isReverification = true
                        phoneVerificationVC.reverificationNoHP = self.fieldNoHP.text
                        phoneVerificationVC.isShowBackBtn = true
                        phoneVerificationVC.delegate = self.prevVC
                        self.navigationController?.pushViewController(phoneVerificationVC, animated: true)
                    }
                }
            }
        }
    }
    
}
