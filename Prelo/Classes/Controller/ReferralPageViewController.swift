//
//  ReferralPageViewController.swift
//  Prelo
//
//  Created by Fransiska on 10/28/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Social
import MessageUI
import Alamofire

class ReferralPageViewController: BaseViewController, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, PathLoginDelegate, UIDocumentInteractionControllerDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var lblSaldo: UILabel!
    @IBOutlet weak var progressBonus: UIProgressView!
    @IBOutlet weak var lblKodeReferral: UILabel!
    
    @IBOutlet weak var imgInstagram: UIImageView!
    @IBOutlet weak var imgFacebook: UIImageView!
    @IBOutlet weak var imgTwitter: UIImageView!
    @IBOutlet weak var imgPath: UIImageView!
    @IBOutlet weak var imgWhatsApp: UIImageView!
    @IBOutlet weak var imgLine: UIImageView!
    @IBOutlet weak var imgSms: UIImageView!
    @IBOutlet weak var imgEmail: UIImageView!
    @IBOutlet weak var imgMore: UIImageView!
    
    @IBOutlet weak var btnInstagram: UIButton!
    @IBOutlet weak var btnFacebook: UIButton!
    @IBOutlet weak var btnTwitter: UIButton!
    @IBOutlet weak var btnPath: UIButton!
    @IBOutlet weak var btnWhatsApp: UIButton!
    @IBOutlet weak var btnLine: UIButton!
    @IBOutlet weak var btnSms: UIButton!
    @IBOutlet weak var btnEmail: UIButton!
    @IBOutlet weak var btnCopy: UIButton!
    
    @IBOutlet weak var fieldKodeReferral: UITextField!
    @IBOutlet weak var vwSubmit: UIView!
    @IBOutlet weak var btnSubmit: UIButton!
    
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var mgInstagram : MGInstagram?
    
    var saldo : Int = 0
    
    let BONUS_AMOUNT : Int = 25000
    
    var shareImage : UIImage = UIImage(named:"raisa.jpg")!
    var shareText : String = ""
    
    // MARK: - Init
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        loadingPanel.isHidden = false
        loading.startAnimating()
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.Referral)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Referral)
        
        var isEmailVerified : Bool = false
        // API Migrasi
        let _ = request(APIMe.me).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Referral Page - Get Profile")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                isEmailVerified = data["others"]["is_email_verified"].boolValue
                // TODO: Apakah isEmailVerified di core data perlu diupdate? sepertinya tidak..
                
                if (!isEmailVerified) {
                    // Tampilkan pop up untuk verifikasi email
                    let a = UIAlertView()
                    a.title = "Referral Bonus"
                    a.message = "Mohon verifikasi e-mail kamu untuk mendapatkan referral bonus dari Prelo"
                    a.addButton(withTitle: "Batal")
                    a.addButton(withTitle: "Kirim E-mail Konfirmasi")
                    a.cancelButtonIndex = 0
                    a.delegate = self
                    a.show()
                } else {
                    self.getReferralData()
                }
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
        
        // Atur opacity tombol
        // Instagram
        imgInstagram.alpha = 1
        // Facebook
        imgFacebook.alpha = 1
        // Twitter
        imgTwitter.alpha = 1
        // Path
        imgPath.alpha = 1
        // Whatsapp
        imgWhatsApp.alpha = 1
        // Line
        imgLine.alpha = 1
        // SMS
        if (MFMessageComposeViewController.canSendText()) {
            imgSms.alpha = 1
            btnSms.isUserInteractionEnabled = true
        } else {
            imgSms.alpha = 0.3
            btnSms.isUserInteractionEnabled = false
        }
        // Email
        if (MFMailComposeViewController.canSendMail()) {
            imgEmail.alpha = 1
            btnEmail.isUserInteractionEnabled = true
        } else {
            imgEmail.alpha = 0.3
            btnEmail.isUserInteractionEnabled = false
        }
        // More
        imgMore.alpha = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        self.title = "Referral Bonus"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboard(
            animations: {r, t, o in
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                }
            }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func getReferralData() {
        // API Migrasi
        let _ = request(APIMe.referralData).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Referral Bonus")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                self.saldo = data["bonus"].intValue
                self.lblSaldo.text = "\(self.saldo.asPrice)"
                self.lblKodeReferral.text = data["referral"]["my_referral_code"].stringValue
                
                // Set progress bar
                let progress : Float = data["referral"]["total_referral_amount"].floatValue / data["referral"]["max_referral_amount"].floatValue
                self.progressBonus.setProgress(progress, animated: true)
                
                // Jika sudah pernah memasukkan referral, sembunyikan field
                if (data["referral"]["referral_code_used"] != nil) {
                    self.vwSubmit.isHidden = true
                }
                
                // Set shareText
                self.shareText = "Download aplikasi Prelo dan dapatkan bonus Rp25.000 dengan mengisikan referral: \(self.lblKodeReferral.text!)"
                
                self.loadingPanel.isHidden = true
                self.loading.stopAnimating()
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - MFMessage Delegate Functions
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - MFMail Delegate Functions
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Path
    
    func loginPath()
    {
        let pathLoginVC = Bundle.main.loadNibNamed(Tags.XibNamePathLogin, owner: nil, options: nil)?.first as! PathLoginViewController
        pathLoginVC.delegate = self
        pathLoginVC.standAlone = true
        let n = UINavigationController(rootViewController: pathLoginVC)
        self.present(n, animated: true, completion: nil)
    }
    
    func hideLoading() {
        // Hilangkan loading
        loadingPanel.isHidden = true
        loading.stopAnimating()
    }
    
    func pathLoginSuccess(_ userData: JSON, token: String) {
        registerPathToken(userData, token : token)
        postToPath(shareImage, token: token)
    }
    
    func registerPathToken(_ userData : JSON, token : String) {
        let pathName = userData["name"].string!
        
        self.mixpanelSharedReferral("Path", username: pathName)
        
        /*FIXME: Sementara dijadiin komentar, login path harusnya dimatiin karna di edit profile udah ga ada
        let pathId = userData["id"].string!
         
        let email = userData["email"].string!
        if (userData["photo"] != nil) {
            let profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        }
        // API Migrasi
        let _ = request(APIAuth.LoginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON {req, resp, res, err in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Path")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                // Save in core data
                let m = UIApplication.appDelegate.managedObjectContext
                var user : CDUser = CDUser.getOne()!
                user.id = data["_id"].string!
                user.username = data["username"].string!
                user.email = data["email"].string!
                user.fullname = data["fullname"].string!
                
                var p : CDUserProfile = CDUserProfile.getOne()!
                let pr = data["profile"]
                p.pict = pr["pict"].string!
                
                var o : CDUserOther = CDUserOther.getOne()!
                o.pathID = pathId
                o.pathUsername = pathName
                o.pathAccessToken = token
                
                user.profiles = p
                user.others = o
                UIApplication.appDelegate.saveContext()
                
                // Save in NSUserDefaults
                NSUserDefaults.standardUserDefaults().setObject(token, forKey: "pathtoken")
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }*/
    }
    
    func postToPath(_ image : UIImage, token : String) {
//        let param = [
//            "caption": shareText
//        ]
//        let data = NSJSONSerialization.dataWithJSONObject(param, options: nil)
//        let jsonString = NSString(data: data!, encoding: NSUTF8StringEncoding)
        let a = UIAlertView(title: "Path", message: "Posting to path", delegate: nil, cancelButtonTitle: nil)
        a.show()
        AppToolsObjC.pathPostPhoto(image, param: ["private": true, "caption": shareText], token: token, success: {_, _ in
            a.dismiss(withClickedButtonIndex: 0, animated: true)
        }, failure: nil)
    }
    
    // MARK: - Instagram
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        print("DidEndPreview")
    }
    
    // MARK: - IBActions
    
    @IBAction func instagramPressed(_ sender: AnyObject) {
        if (UIApplication.shared.canOpenURL(URL(string: "instagram://app")!)) {
            mgInstagram = MGInstagram()
            mgInstagram?.post(shareImage, withCaption: shareText, in: self.view, delegate: self)
            self.mixpanelSharedReferral("Instagram", username: "")
        } else {
            Constant.showDialog("No Instagram app", message: "Silakan install Instagram dari app store terlebih dahulu")
        }
    }
    
    @IBAction func facebookPressed(_ sender: AnyObject) {
        if (SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)) {
            let url = URL(string:AppTools.PreloBaseUrl)
            let composer = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            composer?.add(url!)
            composer?.add(shareImage)
            composer?.setInitialText(shareText)
            composer?.completionHandler = { result -> Void in
                let getResult = result as SLComposeViewControllerResult
                switch(getResult.rawValue) {
                case SLComposeViewControllerResult.cancelled.rawValue:
                    print("Cancelled")
                case SLComposeViewControllerResult.done.rawValue:
                    print("Done")
                    self.mixpanelSharedReferral("Facebook", username: "")
                default:
                    print("Error")
                }
                self.dismiss(animated: true, completion: nil)
            }
            self.present(composer!, animated: true, completion: nil)
        } else {
            Constant.showDialog("Anda belum login", message: "Silakan login Facebook dari menu Settings")
        }
    }
    
    @IBAction func twitterPressed(_ sender: AnyObject) {
        if (SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter)) {
            let url = URL(string:AppTools.PreloBaseUrl)
            let composer = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            composer?.add(url!)
            composer?.add(shareImage)
            composer?.setInitialText(shareText)
            composer?.completionHandler = { result -> Void in
                let getResult = result as SLComposeViewControllerResult
                switch(getResult.rawValue) {
                case SLComposeViewControllerResult.cancelled.rawValue:
                    print("Cancelled")
                case SLComposeViewControllerResult.done.rawValue:
                    print("Done")
                    self.mixpanelSharedReferral("Twitter", username: "")
                default:
                    print("Error")
                }
                self.dismiss(animated: true, completion: nil)
            }
            self.present(composer!, animated: true, completion: nil)
        } else {
            Constant.showDialog("Anda belum login", message: "Silakan login Twitter dari menu Settings")
        }
    }
    
    @IBAction func pathPressed(_ sender: AnyObject) {
        if (CDUser.pathTokenAvailable()) {
            postToPath(shareImage, token: UserDefaults.standard.string(forKey: "pathtoken")!)
            if let o = CDUserOther.getOne() {
                self.mixpanelSharedReferral("Path", username: (o.pathUsername != nil) ? o.pathUsername! : "")
            }
        } else {
            loginPath()
        }
    }
    
    @IBAction func whatsappPressed(_ sender: AnyObject) {
        if (UIApplication.shared.canOpenURL(URL(string: "whatsapp://app")!)) {
            let url = URL(string : "whatsapp://send?text=" + shareText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!)
            UIApplication.shared.openURL(url!)
            self.mixpanelSharedReferral("Whatsapp", username: "")
        } else {
            Constant.showDialog("No Whatsapp", message: "Silakan install Whatsapp dari app store terlebih dahulu")
        }
    }
    
    @IBAction func linePressed(_ sender: AnyObject) {
        if (Line.isLineInstalled()) {
            Line.shareText(shareText)
            self.mixpanelSharedReferral("Line", username: "")
        } else {
            Constant.showDialog("No Line app", message: "Silakan install Line dari app store terlebih dahulu")
        }
    }
    
    @IBAction func smsPressed(_ sender: AnyObject) {
        let composer = MFMessageComposeViewController()
        composer.body = shareText
        composer.messageComposeDelegate = self
        
        self.present(composer, animated: true, completion: nil)
        
        self.mixpanelSharedReferral("SMS", username: "")
    }
    
    @IBAction func emailPressed(_ sender: AnyObject) {
        let composer = MFMailComposeViewController()
        if (MFMailComposeViewController.canSendMail()) {
            composer.setMessageBody(shareText, isHTML: false)
            composer.mailComposeDelegate = self
            
            self.present(composer, animated: true, completion: nil)
            
            self.mixpanelSharedReferral("Email", username: "")
        } else {
            Constant.showDialog("No Active E-mail", message: "Untuk dapat membagi kode referral melalui e-mail, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
        }
    }
    
    @IBAction func copyPressed(_ sender: AnyObject) {
        UIPasteboard.general.string = shareText
        Constant.showDialog("Copied", message: "Teks telah disalin")
    }
    
    @IBAction func disableTextFields(_ sender : AnyObject)
    {
        fieldKodeReferral.resignFirstResponder()
    }
    
    @IBAction func submitPressed(_ sender: AnyObject) {
        guard self.fieldKodeReferral.text != nil else
        {
            Constant.showDialog("Warning", message: "Isi kode referral terlebih dahulu")
            return
        }
        
        if (self.fieldKodeReferral.text!.isEmpty) {
            Constant.showDialog("Warning", message: "Isi kode referral terlebih dahulu")
        } else {
            self.showLoading()
            let deviceId = UIDevice.current.identifierForVendor!.uuidString
            // API Migrasi
            let _ = request(APIMe.setReferral(referralCode: self.fieldKodeReferral.text!, deviceId: deviceId)).responseJSON {resp in
                let json = JSON(resp.result.value!)
                
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Submit Referral Bonus")) {
                    let isSuccess = json["_data"].bool!
                    if (isSuccess) { // Berhasil
                        Constant.showDialog("Success", message: "Kode referral berhasil ditambahkan")
                        
                        // Refresh saldo
                        self.saldo += self.BONUS_AMOUNT
                        self.lblSaldo.text = "\(self.saldo.asPrice)"
                        
                        // Sembunyikan field
                        self.vwSubmit.isHidden = true
                        
                        /*
                        // Mixpanel
                        let p = [
                            "Referral Code Used" : self.fieldKodeReferral.text!
                        ]
                        Mixpanel.sharedInstance().registerSuperProperties(p)
                        Mixpanel.sharedInstance().people.setOnce(p)
                        let pt = [
                            "Activation Screen" : "Voucher"
                        ]
                        Mixpanel.trackEvent(MixpanelEvent.ReferralUsed, properties: pt)
                         */
                        
                        // Prelo Analytics - Redeem Referral Code
                        self.sendRedeemReferralCodeAnalytic(self.fieldKodeReferral.text!, isSuccess: true, reason: "")
                        
                    } else {
                        let reason = json["_message"].string!
                        
                        // Prelo Analytics - Redeem Referral Code
                        self.sendRedeemReferralCodeAnalytic(self.fieldKodeReferral.text!, isSuccess: false, reason: reason)
                    }
                } else {
                    let reason = json["_message"].string!
                    
                    // Prelo Analytics - Redeem Referral Code
                    self.sendRedeemReferralCodeAnalytic(self.fieldKodeReferral.text!, isSuccess: false, reason: reason)
                }
                self.hideLoading()
            }
        }
    }
    
    // MARK: - Mixpanel
    
    func mixpanelSharedReferral(_ socmed : String, username : String) {
        /*
        let pt = [
            "Socmed" : socmed,
            "Socmed Username" : username
        ]
        Mixpanel.trackEvent(MixpanelEvent.SharedReferral, properties: pt)
         */
        
        // Prelo Analytic - Share Referral Code
        sendShareReferralCodeAnalytic(socmed, username: username)
    }
    
    // Prelo Analytics - Redeem Referral Code
    func sendRedeemReferralCodeAnalytic(_ referralCode: String, isSuccess: Bool, reason: String) {
        let loginMethod = User.LoginMethod ?? ""
        var pdata = [
            "Referral Code Used" : referralCode,
            "Success" : isSuccess
        ] as [String : Any]
        
        if !isSuccess && reason != "" {
            pdata["Failed Reason"] = reason
        }
        
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.RedeemReferralCode, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
    }
    
    // Prelo Analytics - Share Referral Code
    func sendShareReferralCodeAnalytic(_ socmed: String, username: String) {
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            "Socmed" : socmed,
            "Socmed Username" : username
        ] as [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.RedeemReferralCode, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
    }
    
    // MARK: - UIAlertView Delegate Functions
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        switch buttonIndex {
        case 0: // Batal
            _ = self.navigationController?.popViewController(animated: true)
            break
        case 1: // Kirim Email Konfirmasi
            if let email = CDUser.getOne()?.email {
                alertView.dismiss(withClickedButtonIndex: -1, animated: true)
                // Tampilkan pop up untuk loading
                let a = UIAlertView()
                a.title = "Referral Bonus"
                a.message = "Mengirim e-mail..."
                a.show()
                // API Migrasi
        let _ = request(APIMe.resendVerificationEmail).responseJSON {resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Referral Bonus")) {
                        a.dismiss(withClickedButtonIndex: -1, animated: true)
                        Constant.showDialog("Referral Bonus", message: "E-mail konfirmasi telah terkirim ke \(email)")
                    }
                    _ = self.navigationController?.popViewController(animated: true)
                }
            } else {
                Constant.showDialog("Referral Bonus", message: "Oops, terdapat masalah saat mencari e-mail kamu")
                _ = self.navigationController?.popViewController(animated: true)
            }
            break
        default:
            break
        }
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        // Tampilkan loading
        loadingPanel.isHidden = false
        loading.startAnimating()
    }
}
