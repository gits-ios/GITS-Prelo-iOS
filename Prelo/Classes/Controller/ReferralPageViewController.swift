//
//  ReferralPageViewController.swift
//  Prelo
//
//  Created by Fransiska on 10/28/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import Social
import MessageUI

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
    @IBOutlet weak var btnMore: UIButton!
    
    @IBOutlet weak var fieldKodeReferral: UITextField!
    @IBOutlet weak var vwSubmit: UIView!
    @IBOutlet weak var btnSubmit: UIButton!
    
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var mgInstagram : MGInstagram?
    
    var saldo : Int = 0
    
    let MAX_BONUS_TIMES : Float = 10
    let BONUS_AMOUNT : Int = 25000
    
    var shareImage : UIImage = UIImage(named:"raisa.jpg")!
    var shareText : String = ""
    
    // MARK: - Init
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = false
        loading.startAnimating()
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.Referral)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Referral)
        
        var isEmailVerified : Bool = false
        // API Migrasi
        request(APIUser.Me).responseJSON {resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Referral Page - Get Profile")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                isEmailVerified = data["others"]["is_email_verified"].boolValue
                // TODO: Apakah isEmailVerified di core data perlu diupdate? sepertinya tidak..
                
                if (!isEmailVerified) {
                    // Tampilkan pop up untuk verifikasi email
                    let a = UIAlertView()
                    a.title = "Prelo Bonus"
                    a.message = "Mohon verifikasi e-mail kamu untuk mendapatkan voucher gratis dari Prelo"
                    a.addButtonWithTitle("Batal")
                    a.addButtonWithTitle("Kirim E-mail Konfirmasi")
                    a.delegate = self
                    a.show()
                } else {
                    self.getReferralData()
                }
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
            btnSms.userInteractionEnabled = true
        } else {
            imgSms.alpha = 0.3
            btnSms.userInteractionEnabled = false
        }
        // Email
        if (MFMailComposeViewController.canSendMail()) {
            imgEmail.alpha = 1
            btnEmail.userInteractionEnabled = true
        } else {
            imgEmail.alpha = 0.3
            btnEmail.userInteractionEnabled = false
        }
        // More
        imgMore.alpha = 0.3
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        self.title = "Prelo Bonus"
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
    
    func getReferralData() {
        // API Migrasi
        request(APIUser.ReferralData).responseJSON {req, resp, res, err in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Prelo Bonus")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
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
                
                // Set shareText
                self.shareText = "Download aplikasi Prelo dan dapatkan bonus Rp 25.000 dengan mengisikan referral: \(self.lblKodeReferral.text!)"
                
                self.loadingPanel.hidden = true
                self.loading.stopAnimating()
            } else {
                self.navigationController?.popViewControllerAnimated(true)
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
    
    // MARK: - MFMessage Delegate Functions
    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - MFMail Delegate Functions
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Path
    
    func loginPath()
    {
        let pathLoginVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePathLogin, owner: nil, options: nil).first as! PathLoginViewController
        pathLoginVC.delegate = self
        pathLoginVC.standAlone = true
        let n = UINavigationController(rootViewController: pathLoginVC)
        self.presentViewController(n, animated: true, completion: nil)
    }
    
    func hideLoading() {
        // Hilangkan loading
        loadingPanel.hidden = true
        loading.stopAnimating()
    }
    
    func pathLoginSuccess(userData: JSON, token: String) {
        registerPathToken(userData, token : token)
        postToPath(shareImage, token: token)
    }
    
    func registerPathToken(userData : JSON, token : String) {
        let pathId = userData["id"].string!
        let pathName = userData["name"].string!
        let email = userData["email"].string!
        if (userData["photo"] != nil) {
            let profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        }
        
        self.mixpanelSharedReferral("Path", username: pathName)
        
        /* FIXME: Sementara dijadiin komentar, login path harusnya dimatiin karna di edit profile udah ga ada
        // API Migrasi
        request(APIAuth.LoginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON {req, resp, res, err in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Login Path")) {
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
    
    func postToPath(image : UIImage, token : String) {
        let param = [
            "caption": shareText
        ]
        let data = NSJSONSerialization.dataWithJSONObject(param, options: nil, error: nil)
        let jsonString = NSString(data: data!, encoding: NSUTF8StringEncoding)
        let a = UIAlertView(title: "Path", message: "Posting to path", delegate: nil, cancelButtonTitle: nil)
        a.show()
        AppToolsObjC.PATHPostPhoto(image, param: ["private": true, "caption": shareText], token: token, success: {_, _ in
            a.dismissWithClickedButtonIndex(0, animated: true)
        }, failure: nil)
    }
    
    // MARK: - Instagram
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerDidEndPreview(controller: UIDocumentInteractionController) {
        print("DidEndPreview")
    }
    
    // MARK: - IBActions
    
    @IBAction func instagramPressed(sender: AnyObject) {
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "instagram://app")!)) {
            mgInstagram = MGInstagram()
            mgInstagram?.postImage(shareImage, withCaption: shareText, inView: self.view, delegate: self)
            self.mixpanelSharedReferral("Instagram", username: "")
        } else {
            Constant.showDialog("No Instagram app", message: "Silakan install Instagram dari app store terlebih dahulu")
        }
    }
    
    @IBAction func facebookPressed(sender: AnyObject) {
        if (SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook)) {
            let url = NSURL(string:AppTools.PreloBaseUrl)
            let composer = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            composer.addURL(url!)
            composer.addImage(shareImage)
            composer.setInitialText(shareText)
            composer.completionHandler = { result -> Void in
                var getResult = result as SLComposeViewControllerResult
                switch(getResult.rawValue) {
                case SLComposeViewControllerResult.Cancelled.rawValue:
                    print("Cancelled")
                case SLComposeViewControllerResult.Done.rawValue:
                    print("Done")
                    self.mixpanelSharedReferral("Facebook", username: "")
                default:
                    print("Error")
                }
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            self.presentViewController(composer, animated: true, completion: nil)
        } else {
            Constant.showDialog("Anda belum login", message: "Silakan login Facebook dari menu Settings")
        }
    }
    
    @IBAction func twitterPressed(sender: AnyObject) {
        if (SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter)) {
            let url = NSURL(string:AppTools.PreloBaseUrl)
            let composer = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            composer.addURL(url!)
            composer.addImage(shareImage)
            composer.setInitialText(shareText)
            composer.completionHandler = { result -> Void in
                var getResult = result as SLComposeViewControllerResult
                switch(getResult.rawValue) {
                case SLComposeViewControllerResult.Cancelled.rawValue:
                    print("Cancelled")
                case SLComposeViewControllerResult.Done.rawValue:
                    print("Done")
                    self.mixpanelSharedReferral("Twitter", username: "")
                default:
                    print("Error")
                }
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            self.presentViewController(composer, animated: true, completion: nil)
        } else {
            Constant.showDialog("Anda belum login", message: "Silakan login Twitter dari menu Settings")
        }
    }
    
    @IBAction func pathPressed(sender: AnyObject) {
        if (CDUser.pathTokenAvailable()) {
            postToPath(shareImage, token: NSUserDefaults.standardUserDefaults().stringForKey("pathtoken")!)
            if let o = CDUserOther.getOne() {
                self.mixpanelSharedReferral("Path", username: (o.pathUsername != nil) ? o.pathUsername! : "")
            }
        } else {
            loginPath()
        }
    }
    
    @IBAction func whatsappPressed(sender: AnyObject) {
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "whatsapp://app")!)) {
            let url = NSURL(string : "whatsapp://send?text=" + shareText.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
            UIApplication.sharedApplication().openURL(url!)
            self.mixpanelSharedReferral("Whatsapp", username: "")
        } else {
            Constant.showDialog("No Whatsapp", message: "Silakan install Whatsapp dari app store terlebih dahulu")
        }
    }
    
    @IBAction func linePressed(sender: AnyObject) {
        if (Line.isLineInstalled()) {
            Line.shareText(shareText)
            self.mixpanelSharedReferral("Line", username: "")
        } else {
            Constant.showDialog("No Line app", message: "Silakan install Line dari app store terlebih dahulu")
        }
    }
    
    @IBAction func smsPressed(sender: AnyObject) {
        let composer = MFMessageComposeViewController()
        composer.body = shareText
        composer.messageComposeDelegate = self
        
        self.presentViewController(composer, animated: true, completion: nil)
        
        self.mixpanelSharedReferral("SMS", username: "")
    }
    
    @IBAction func emailPressed(sender: AnyObject) {
        let composer = MFMailComposeViewController()
        if (MFMailComposeViewController.canSendMail()) {
            composer.setMessageBody(shareText, isHTML: false)
            composer.mailComposeDelegate = self
            
            self.presentViewController(composer, animated: true, completion: nil)
            
            self.mixpanelSharedReferral("Email", username: "")
        } else {
            Constant.showDialog("No Active E-mail", message: "Untuk dapat membagi kode referral melalui e-mail, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
        }
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
            self.showLoading()
            let deviceId = UIDevice.currentDevice().identifierForVendor!.UUIDString
            // API Migrasi
        request(APIUser.SetReferral(referralCode: self.fieldKodeReferral.text, deviceId: deviceId)).responseJSON {resp in
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Submit Prelo Bonus")) {
                    let json = JSON(resp.result.value!)
                    let isSuccess = json["_data"].bool!
                    if (isSuccess) { // Berhasil
                        Constant.showDialog("Success", message: "Kode referral berhasil ditambahkan")
                        
                        // Refresh saldo
                        self.saldo += self.BONUS_AMOUNT
                        self.lblSaldo.text = "\(self.saldo.asPrice)"
                        
                        // Sembunyikan field
                        self.vwSubmit.hidden = true
                        
                        // Mixpanel
                        let p = [
                            "Referral Code Used" : self.fieldKodeReferral.text
                        ]
                        Mixpanel.sharedInstance().registerSuperProperties(p)
                        Mixpanel.sharedInstance().people.setOnce(p)
                        let pt = [
                            "Activation Screen" : "Voucher"
                        ]
                        Mixpanel.trackEvent(MixpanelEvent.ReferralUsed, properties: pt)
                    }
                }
                self.hideLoading()
            }
        }
    }
    
    // MARK: - Mixpanel
    
    func mixpanelSharedReferral(socmed : String, username : String) {
        let pt = [
            "Socmed" : socmed,
            "Socmed Username" : username
        ]
        Mixpanel.trackEvent(MixpanelEvent.SharedReferral, properties: pt)
    }
    
    // MARK: - UIAlertView Delegate Functions
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        switch buttonIndex {
        case 0: // Batal
            self.navigationController?.popViewControllerAnimated(true)
            break
        case 1: // Kirim Email Konfirmasi
            if let email = CDUser.getOne()?.email {
                alertView.dismissWithClickedButtonIndex(-1, animated: true)
                // Tampilkan pop up untuk loading
                let a = UIAlertView()
                a.title = "Prelo Bonus"
                a.message = "Mengirim e-mail..."
                a.show()
                // API Migrasi
        request(APIUser.ResendVerificationEmail).responseJSON {resp in
                    if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Prelo Bonus")) {
                        a.dismissWithClickedButtonIndex(-1, animated: true)
                        Constant.showDialog("Prelo Bonus", message: "E-mail konfirmasi telah terkirim ke \(email)")
                    }
                    self.navigationController?.popViewControllerAnimated(true)
                }
            } else {
                Constant.showDialog("Prelo Bonus", message: "Oops, terdapat masalah saat mencari e-mail kamu")
                self.navigationController?.popViewControllerAnimated(true)
            }
            break
        default:
            break
        }
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        // Tampilkan loading
        loadingPanel.hidden = false
        loading.startAnimating()
    }
}