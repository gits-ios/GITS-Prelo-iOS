//
//  ReferralPageViewController.swift
//  Prelo
//
//  Created by Fransiska on 10/28/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class ReferralPageViewController: BaseViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lblSaldo: UILabel!
    @IBOutlet weak var progressBonus: UIProgressView!
    @IBOutlet weak var lblKodeReferral: UILabel!
    @IBOutlet weak var fieldKodeReferral: UITextField!
    @IBOutlet weak var vwSubmit: UIView!
    @IBOutlet weak var btnSubmit: UIButton!
    
    var saldo : Int = 0
    
    let MAX_BONUS_TIMES : Float = 10
    let BONUS_AMOUNT : Int = 25000
    
    // MARK: - Init
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.sharedInstance().track("Referral Page")
        
        self.getReferralData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: " Kode Referral", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboardWithAnimations(
            {r, t, o in
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func getReferralData() {
        request(APIUser.ReferralData).responseJSON {req, _, res, err in
            println("Referral data req = \(req)")
            if (err != nil) { // Terdapat error
                Constant.showDialog("Warning", message: "Error getting referral data: \(err!.description)")
                self.navigationController?.popViewControllerAnimated(true)
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                if (data == nil) { // Terdapat error
                    let obj : [String : String] = res as! [String : String]
                    let message = obj["_message"]!
                    Constant.showDialog("Warning", message: "Error getting referral data, message: \(message)")
                    self.navigationController?.popViewControllerAnimated(true)
                } else { // Berhasil
                    println("Referral data : \(data)")
                    
                    self.saldo = data["bonus"].int!
                    self.lblSaldo.text = "\(self.saldo.asPrice)"
                    self.lblKodeReferral.text = data["referral"]["my_referral_code"].string!
                    
                    // Set progress bar
                    let progress : Float = data["referral"]["total_referred"].float! / self.MAX_BONUS_TIMES
                    self.progressBonus.setProgress(progress, animated: true)
                    
                    // Jika sudah pernah memasukkan referral, sembunyikan field
                    if (data["referral"]["referral_code_used"] != nil) {
                        self.vwSubmit.hidden = true
                    }
                }
            }
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UIButton.classForCoder()) || touch.view.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func instagramPressed(sender: AnyObject) {
        UIAlertView.SimpleShow("Coming Soon :)", message: "")
    }
    
    @IBAction func facebookPressed(sender: AnyObject) {
        UIAlertView.SimpleShow("Coming Soon :)", message: "")
    }
    
    @IBAction func twitterPressed(sender: AnyObject) {
        UIAlertView.SimpleShow("Coming Soon :)", message: "")
    }
    
    @IBAction func pathPressed(sender: AnyObject) {
        UIAlertView.SimpleShow("Coming Soon :)", message: "")
    }
    
    @IBAction func whatsappPressed(sender: AnyObject) {
        UIAlertView.SimpleShow("Coming Soon :)", message: "")
    }
    
    @IBAction func linePressed(sender: AnyObject) {
        UIAlertView.SimpleShow("Coming Soon :)", message: "")
    }
    
    @IBAction func smsPressed(sender: AnyObject) {
        UIAlertView.SimpleShow("Coming Soon :)", message: "")
    }
    
    @IBAction func emailPressed(sender: AnyObject) {
        UIAlertView.SimpleShow("Coming Soon :)", message: "")
    }
    
    @IBAction func morePressed(sender: AnyObject) {
        UIAlertView.SimpleShow("Coming Soon :)", message: "")
    }
    
    @IBAction func disableTextFields(sender : AnyObject)
    {
        fieldKodeReferral.resignFirstResponder()
    }
    
    @IBAction func submitPressed(sender: AnyObject) {
        if (self.fieldKodeReferral.text.isEmpty) {
            Constant.showDialog("Warning", message: "Isi kode referral terlebih dahulu")
        } else {
            let deviceId = ""
            request(APIUser.SetReferral(referralCode: self.fieldKodeReferral.text, deviceId: deviceId)).responseJSON {req, _, res, err in
                println("Set referral req = \(req)")
                if (err != nil) { // Terdapat error
                    Constant.showDialog("Warning", message: "Error setting referral: \(err!.description)")
                } else {
                    let json = JSON(res!)
                    if (json["_data"] == nil) {
                        let obj : [String : String] = res as! [String : String]
                        let message = obj["_message"]!
                        Constant.showDialog("Warning", message: "Error setting referral, message: \(message)")
                    } else {
                        let isSuccess = json["_data"].bool!
                        if (isSuccess) { // Berhasil
                            Constant.showDialog("Success", message: "Kode referral berhasil ditambahkan")
                            
                            // Refresh saldo
                            self.saldo += self.BONUS_AMOUNT
                            self.lblSaldo.text = "\(self.saldo.asPrice)"
                            
                            // Sembunyikan field
                            self.vwSubmit.hidden = true
                        } else { // Gagal
                            Constant.showDialog("Warning", message: "Error setting referral")
                        }
                    }
                }
            }
        }
    }
}