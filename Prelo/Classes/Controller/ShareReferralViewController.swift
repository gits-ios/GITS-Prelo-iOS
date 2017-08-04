//
//  ShareReferralViewController.swift
//  Prelo
//
//  Created by Djuned on 7/5/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Social
import MessageUI
import Alamofire

//---------------------
// -> Referral Page VC
// -> Share Profile VC
//---------------------

// MARK: - Class
class ShareReferralViewController: BaseViewController, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, PathLoginDelegate, UIDocumentInteractionControllerDelegate {
    // MARK: - Properties
    @IBOutlet weak var vwCoverScrollView: UIView!
    @IBOutlet weak var coverScrollView: UIScrollView! // define image of cover(s) here -> UIImageView (pagination)
    @IBOutlet weak var imgAvatar: UIImageView! // user
    @IBOutlet weak var mediaCollectionView: UICollectionView! // twitter, fb, etc
    @IBOutlet weak var otherCollectionView: UICollectionView! // sms, mail, copy
    @IBOutlet weak var btnPrev: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var lbSeller: UILabel!
    @IBOutlet weak var lbReferral: UILabel!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var imgPrelo: TintedImageView!
    
    //var images: [String] = []
    var types: shareType = .referral
    var images: [bgShare] = []
    var currentPage = 0
    var medias: [mediaType] = []
    var others: [mediaType] = []
    
    var shareImage: UIImage!
    var shareText: String!
    var myReferralCode: String!
    var myUsername: String!
    
    var mgInstagram : MGInstagram?
    
    // Referral ONLY
    @IBOutlet weak var lbSaldo: UILabel!
    @IBOutlet weak var progressSaldo: UIProgressView!
    @IBOutlet weak var lbKodeReferral: UILabel!
    
    @IBOutlet weak var vwSubmit: UIView! // hidden
    @IBOutlet weak var consHeightVwSubmit: NSLayoutConstraint! // 70 -> 0
    @IBOutlet weak var txKodeReferralInput: UITextField!
    
    var saldo: Int64 = 0
    
    let BONUS_AMOUNT : Int64 = 25000
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        // setup scorll-view
        self.coverScrollView?.isPagingEnabled = true
        self.coverScrollView?.backgroundColor = UIColor.clear
        self.coverScrollView?.delegate = self
        
        self.title = "Referral Bonus"
        
        // setup preview
        let user = CDUser.getOne()
        self.myUsername = user?.username
        let uProf = user?.profiles
        if (uProf != nil) {
            let url = URL(string: uProf!.pict)
            if (url != nil) {
                self.imgAvatar?.afSetImage(withURL: url!, withFilter: .circle)
            }
        }
        
        // setup referral
        //self.getReferralData()
        
        self.lbSeller.text = CDUser.getOne()?.username
        if AppTools.isIPad {
            self.lbSeller.font = UIFont.systemFont(ofSize: 28)
        } else {
            self.lbSeller.font = UIFont.systemFont(ofSize: 14)
        }
        
        //self.lbReferral.text = "gunakan kode referral xxx\nuntuk mendapatkan potongan Rp25.000"
        self.lbReferral.backgroundColor = UIColor.colorWithColor(Theme.PrimaryColor, alpha: 0.7)
        if AppTools.isIPad {
            self.lbReferral.font = UIFont.systemFont(ofSize: 20)
        } else {
            self.lbReferral.font = UIFont.systemFont(ofSize: 10)
        }
        
        // setup prelo
        self.imgPrelo.tint = true
        self.imgPrelo.tintColor = Theme.PrimaryColor
        if AppTools.isIPad {
            self.imgPrelo.image = UIImage(named: "ic_prelo_balance")
        } else {
            self.imgPrelo.image = UIImage(named: "ic_prelo_balance@2x_128.png")
        }
        
        // setup media
        self.medias = [
            .facebook, .twitter, .instagram, .path, .whatsapp, .line
        ]
        
        self.others = [
            .copyText, .email, .sms
        ]
        
        self.setupMediaCollection()
        self.setupOtherCollection()
        
        self.mediaCollectionView.reloadData()
        self.otherCollectionView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // setup avatar
        self.imgAvatar?.layer.cornerRadius = (self.imgAvatar?.frame.size.width)!/2
        self.imgAvatar?.layer.masksToBounds = true
        
        // setup prev-next
        self.btnPrev.layer.cornerRadius = (self.btnPrev.frame.size.width)/2
        self.btnPrev.layer.masksToBounds = true
        
        self.btnNext.layer.cornerRadius = (self.btnNext.frame.size.width)/2
        self.btnNext.layer.masksToBounds = true
        
        if self.types == .referral {
            self.btnPrev.isHidden = true
            self.btnNext.isHidden = true
        }
        
        // setup UI
        self.getCover()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Google Analytics
        // TODO: - Google Analytics
        //GAI.trackPageVisit(PageName.Referral)
        
        var isEmailVerified : Bool = false
        // API Migrasi
        let _ = request(APIMe.me).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Referral Page - Get Profile")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                isEmailVerified = data["others"]["is_email_verified"].boolValue
                
                if (!isEmailVerified) {
                    var alertViewResponder: SCLAlertViewResponder!
                    
                    let alertView = SCLAlertView(appearance: Constant.appearance)
                    alertView.addButton("Kirim E-mail Konfirmasi") {
                        if let email = CDUser.getOne()?.email {
                            alertViewResponder.close()
                            
                            var alertViewResponder2: SCLAlertViewResponder!
                            
                            let alertView2 = SCLAlertView(appearance: Constant.appearance)
                            alertViewResponder2 = alertView2.showCustom("Referral Bonus", subTitle: "Mengirim e-mail...", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                            
                            // API Migrasi
                            let _ = request(APIMe.resendVerificationEmail).responseJSON {resp in
                                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Referral Bonus")) {
                                    alertViewResponder2.close()
                                    Constant.showDialog("Referral Bonus", message: "E-mail konfirmasi telah terkirim ke \(email)")
                                }
                                _ = self.navigationController?.popViewController(animated: true)
                            }
                        } else {
                            Constant.showDialog("Referral Bonus", message: "Oops, terdapat masalah saat mencari e-mail kamu")
                            _ = self.navigationController?.popViewController(animated: true)
                        }
                    }
                    alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {
                        _ = self.navigationController?.popViewController(animated: true)
                    }
                    alertViewResponder = alertView.showCustom("Referral Bonus", subTitle: "Mohon verifikasi e-mail kamu untuk mendapatkan referral bonus dari Prelo", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                } else {
                    self.getReferralData()
                }
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func getCover() {
        /*self.images = [
         "https://trello-attachments.s3.amazonaws.com/5599f3283609769544ed1891/58e76d618d917f372f7a28d2/06c075031e8e53c90f23f95f5d59d9dd/image_only_-_hobby.png",
         "https://trello-attachments.s3.amazonaws.com/5599f3283609769544ed1891/58e76d618d917f372f7a28d2/d8f30edf8c535b391fca2c943a134ed5/image_only_-_gadget.png",
         "https://trello-attachments.s3.amazonaws.com/5599f3283609769544ed1891/58e76d618d917f372f7a28d2/33e5fe5332147cb06f9790bc745029e7/image_only_-_fashion.png",
         "https://trello-attachments.s3.amazonaws.com/5599f3283609769544ed1891/58e76d618d917f372f7a28d2/3b5bac850eda1f04ebed34226b7f0655/image_only_-_book.png",
         "https://trello-attachments.s3.amazonaws.com/5599f3283609769544ed1891/58e76d618d917f372f7a28d2/0284fb39102e7d99300070bb4aa10613/image_only_-_beauty.png"
         ]*/
        
        self.images = self.types.bg
        
        self.setupCover()
    }
    
    func setupCover() {
        var x : CGFloat = 0
        for i in 0...self.images.count - 1
        {
            let s = UIScrollView(frame : (self.coverScrollView?.bounds)!)
            let iv = UIImageView(frame : s.bounds)
            //iv.afSetImage(withURL: URL(string: self.images[i])!, withFilter: .fitWithoutPlaceHolder)
            iv.image = self.images[i].imageIcon
            iv.afInflate()
            iv.tag = 1
            s.addSubview(iv)
            s.x = x
            self.coverScrollView?.addSubview(s)
            
            s.delegate = self
            
            x += s.width
        }
        
        //self.hideLoading()
    }
    
    func setupMediaCollection() {
        let width = 68 * CGFloat(self.medias.count)
        let sWidth = UIScreen.main.bounds.width - 16
        let lrWidth = (sWidth - width) > 0 ? (sWidth - width) / 2.0 : 4.0
        
        // Set collection view
        self.mediaCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcProgressCell")
        self.mediaCollectionView.delegate = self
        self.mediaCollectionView.dataSource = self
        self.mediaCollectionView.backgroundView = UIView(frame: self.mediaCollectionView.bounds)
        self.mediaCollectionView.backgroundColor = UIColor.clear
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 4, left: lrWidth, bottom: 4, right: lrWidth)
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.scrollDirection = .horizontal
        self.mediaCollectionView.collectionViewLayout = layout
        
        self.mediaCollectionView.isScrollEnabled = true
        self.mediaCollectionView.isPagingEnabled = false
        self.mediaCollectionView.isDirectionalLockEnabled = true
    }
    
    func setupOtherCollection() {
        let width = 68 * CGFloat(self.medias.count) // others
        let sWidth = UIScreen.main.bounds.width - 16
        let lrWidth = (sWidth - width) > 0 ? (sWidth - width) / 2.0 : 4.0
        
        // Set collection view
        self.otherCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcProgressCell")
        self.otherCollectionView.delegate = self
        self.otherCollectionView.dataSource = self
        self.otherCollectionView.backgroundView = UIView(frame: self.otherCollectionView.bounds)
        self.otherCollectionView.backgroundColor = UIColor.clear
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 4, left: lrWidth, bottom: 4, right: lrWidth)
        layout.itemSize = CGSize(width: 60, height: 84)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.scrollDirection = .horizontal
        self.otherCollectionView.collectionViewLayout = layout
        
        self.otherCollectionView.isScrollEnabled = true
        self.otherCollectionView.isPagingEnabled = false
        self.otherCollectionView.isDirectionalLockEnabled = true
    }
    
    func getReferralData() {
        self.showLoading()
        // API Migrasi
        let _ = request(APIMe.referralData).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Referral Bonus")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                self.myReferralCode = data["referral"]["my_referral_code"].stringValue
                
                self.saldo = data["bonus"].int64Value
                self.lbSaldo.text = self.saldo.asPrice
                self.lbKodeReferral.text = self.myReferralCode
                
                // Set progress bar
                let progress : Float = data["referral"]["total_referral_amount"].floatValue / data["referral"]["max_referral_amount"].floatValue
                self.progressSaldo.setProgress(progress, animated: true)
                
                // Set shareText
                let shareText = "Gunakan kode referral saya: " + self.myReferralCode + " untuk potongan Rp25.000\nuntuk transaksi pertama kamu di Prelo!"
                self.lbReferral.text = shareText
                
                // Jika sudah pernah memasukkan referral, sembunyikan field
                if (data["referral"]["referral_code_used"] != nil) {
                    self.vwSubmit.isHidden = true
                    self.consHeightVwSubmit.constant = 0
                }
                
                self.hideLoading()
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func setupShareContent(_ mediaType: mediaType) {
        self.showLoading()
        self.shareText = "Download aplikasi Prelo dan dapatkan bonus Rp25.000 dengan mengisikan referral: " + self.myReferralCode
        
        // API Migrasi
        let _ = request(APIMe.referralProfile).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Share Profile Shop")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                print(data)
                // Production Only
                
                if let imageUrl = data["url"].string {
                    request(imageUrl, method: .get).responseImage { response in
                        DispatchQueue.main.async(execute: {
                            if let image = response.result.value {
                                self.shareImage = image
                            } else {
                                self.shareImage = self.coverScreenshot()
                            }
                            self.execute(mediaType)
                            self.hideLoading()
                        })
                    }
                } else {
                    self.shareImage = self.coverScreenshot()
                    self.execute(mediaType)
                }
            }
        }
    }
    
    func execute(_ mediaType: mediaType) {
        if !AppTools.IsPreloProduction {
            self.showCoverScreenshot()
        }
        
        switch mediaType {
        case .facebook:
            print("fb kena")
            self.facebookPressed()
        case .twitter:
            print("tw kena")
            self.twitterPressed()
        case .instagram:
            print("ig kena")
            self.instagramPressed()
        case .path:
            print("path kena")
            self.pathPressed()
        case .whatsapp:
            print("wa kena")
            self.whatsappPressed()
        case .line:
            print("line kena")
            self.linePressed()
        case .copyText:
            print("copy text kena")
            self.copyPressed()
        case .email:
            print("email kena")
            self.emailPressed()
        case .sms:
            print("sms kena")
            self.smsPressed()
        }
    }
    
    func coverScreenshot() -> UIImage {
        if let result = self.vwCoverScrollView.snapshot(of: self.vwCoverScrollView.frame) {
            return result
        }
        return UIImage()
    }
    
    func showCoverScreenshot() {
        guard let ss = self.shareImage else {
            return
        }
        
        let appearance = Constant.appearance
        //appearance.shouldAutoDismiss = false
        
        let alertView = SCLAlertView(appearance: appearance)
        
        let width = Constant.appearance.kWindowWidth - 24
        let frame = CGRect(x: 0, y: 0, width: width, height: width)
        
        let pView = UIImageView(frame: frame)
        pView.image = ss.resizeWithMaxWidthOrHeight(width * UIScreen.main.scale)
        pView.afInflate()
        pView.contentMode = .scaleAspectFit
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0, y: 0, width: width, height: width))
        subview.addSubview(pView)
        
        alertView.customSubview = subview
        
        alertView.addButton("Oke", action: {})
        
        alertView.showCustom("Screenshot", subTitle: "", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    // MARK: - ScrollView delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == self.coverScrollView)
        {
            var p : CGFloat = 0
            if (scrollView.bounds.width > 0) {
                p = scrollView.contentOffset.x / scrollView.bounds.width
            }
            if (currentPage != Int(p + 0.5))
            {
                currentPage = Int(p + 0.5)
            }
        }
    }
    
    // MARK: - CollectionView delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.mediaCollectionView {
            return self.medias.count
        } else if collectionView == self.otherCollectionView {
            return self.others.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = self.mediaCollectionView.dequeueReusableCell(withReuseIdentifier: "collcProgressCell", for: indexPath)
        if collectionView == self.mediaCollectionView {
            cell.viewWithTag(999)?.removeFromSuperview()
            
            // Create icon view
            let vwIcon : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            vwIcon.tag = 999
            
            let img = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            img.layoutIfNeeded()
            img.layer.cornerRadius = (img.width) / 2
            img.layer.masksToBounds = true
            img.image = UIImage(named: self.medias[(indexPath as IndexPath).item].imageName)
            
            vwIcon.addSubview(img)
            
            // Add view to cell
            cell.addSubview(vwIcon)
        } else if collectionView == self.otherCollectionView {
            cell.viewWithTag(999)?.removeFromSuperview()
            
            // Create icon view
            let vwIcon : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            vwIcon.tag = 999
            
            let img = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            img.layoutIfNeeded()
            img.layer.cornerRadius = (img.width) / 2
            img.layer.masksToBounds = true
            img.image = UIImage(named: self.others[(indexPath as IndexPath).item].imageName)
            
            let txt = UILabel(frame: CGRect(x: 0, y: 64, width: 60, height: 20))
            txt.text = self.others[(indexPath as IndexPath).item].socmedName
            txt.adjustsFontSizeToFitWidth = true
            txt.font = UIFont.systemFont(ofSize: 12.0)
            txt.textColor = UIColor.darkGray
            txt.textAlignment = .center
            
            vwIcon.addSubview(img)
            vwIcon.addSubview(txt)
            
            // Add view to cell
            cell.addSubview(vwIcon)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        if collectionView == self.mediaCollectionView {
            return CGSize(width: 60, height: 60)
        } else if collectionView == self.otherCollectionView {
            return CGSize(width: 60, height: 84)
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.mediaCollectionView {
            self.mediaPressed(self.medias[(indexPath as IndexPath).item])
        } else if collectionView == self.otherCollectionView {
            self.mediaPressed(self.others[(indexPath as IndexPath).item])
        }
    }
    
    func scrollSubVC(_ index: Int) {
        self.coverScrollView.setContentOffset(CGPoint(x: CGFloat(CGFloat(index) * self.coverScrollView.bounds.width), y: CGFloat(0)), animated: true)
    }
    
    // MARK: - button
    @IBAction func btnPrevPressed(_ sender: Any) {
        self.scrollSubVC((self.images.count+currentPage-1) % self.images.count)
    }
    
    @IBAction func btnNextPressed(_ sender: Any) {
        self.scrollSubVC((self.images.count+currentPage+1) % self.images.count)
    }
    
    @IBAction func btnSubmitPressed(_ sender: Any) {
        guard self.txKodeReferralInput.text != nil else
        {
            Constant.showDialog("Warning", message: "Isi kode referral terlebih dahulu")
            return
        }
        
        if (self.txKodeReferralInput.text!.isEmpty) {
            Constant.showDialog("Warning", message: "Isi kode referral terlebih dahulu")
        } else {
            self.showLoading()
            let deviceId = UIDevice.current.identifierForVendor!.uuidString
            // API Migrasi
            let _ = request(APIMe.setReferral(referralCode: self.txKodeReferralInput.text!, deviceId: deviceId)).responseJSON {resp in
                let json = JSON(resp.result.value!)
                
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Submit Referral Bonus")) {
                    let isSuccess = json["_data"].bool!
                    if (isSuccess) { // Berhasil
                        Constant.showDialog("Success", message: "Kode referral berhasil ditambahkan")
                        
                        // Refresh saldo
                        self.saldo += self.BONUS_AMOUNT
                        self.lbSaldo.text = "\(self.saldo.asPrice)"
                        
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
                        self.sendRedeemReferralCodeAnalytic(self.txKodeReferralInput.text!, isSuccess: true, reason: "")
                        
                    } else {
                        let reason = json["_message"].string!
                        
                        // Prelo Analytics - Redeem Referral Code
                        self.sendRedeemReferralCodeAnalytic(self.txKodeReferralInput.text!, isSuccess: false, reason: reason)
                    }
                } else {
                    let reason = json["_message"].string!
                    
                    // Prelo Analytics - Redeem Referral Code
                    self.sendRedeemReferralCodeAnalytic(self.txKodeReferralInput.text!, isSuccess: false, reason: reason)
                }
                self.hideLoading()
            }
        }
    }
    
    // MARK: - action
    func mediaPressed(_ mediaType: mediaType) {
        //        Constant.showDialog(mediaType.socmedName, message: "Clicked")
        
        self.setupShareContent(mediaType)
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
    func loginPath() {
        let pathLoginVC = Bundle.main.loadNibNamed(Tags.XibNamePathLogin, owner: nil, options: nil)?.first as! PathLoginViewController
        pathLoginVC.delegate = self
        pathLoginVC.standAlone = true
        let n = UINavigationController(rootViewController: pathLoginVC)
        self.present(n, animated: true, completion: nil)
    }
    
    func pathLoginSuccess(_ userData: JSON, token: String) {
        registerPathToken(userData, token : token)
        postToPath(shareImage, token: token)
    }
    
    func registerPathToken(_ userData : JSON, token : String) {
        let pathName = userData["name"].string!
        
        self.sendShareReferralCodeAnalytic("Path", username: pathName)
    }
    
    func postToPath(_ image : UIImage, token : String) {
        let alertView = SCLAlertView(appearance: Constant.appearance)
        let alertViewResponder: SCLAlertViewResponder = alertView.showCustom("Path", subTitle: "Posting to path", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
        
        AppToolsObjC.pathPostPhoto(image, param: ["private": true, "caption": shareText], token: token, success: {_, _ in
            alertViewResponder.close()
        }, failure: nil)
    }
    
    // MARK: - Instagram
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        print("DidEndPreview")
    }
    
    // MARK: - Socmed Actions
    func instagramPressed() {
        if (UIApplication.shared.canOpenURL(URL(string: "instagram://app")!)) {
            mgInstagram = MGInstagram()
            mgInstagram?.post(shareImage, withCaption: shareText, in: self.view, delegate: self)
            
            self.sendShareReferralCodeAnalytic("Instagram", username: "")
        } else {
            Constant.showDialog("No Instagram app", message: "Silakan install Instagram dari app store terlebih dahulu")
        }
    }
    
    func facebookPressed() {
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
                    
                    self.sendShareReferralCodeAnalytic("Facebook", username: "")
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
    
    func twitterPressed() {
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
                    
                    self.sendShareReferralCodeAnalytic("Twitter", username: "")
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
    
    func pathPressed() {
        if (CDUser.pathTokenAvailable()) {
            postToPath(shareImage, token: UserDefaults.standard.string(forKey: "pathtoken")!)
            
            if let o = CDUserOther.getOne() {
                self.sendShareReferralCodeAnalytic("Path", username: (o.pathUsername != nil) ? o.pathUsername! : "")
            }
        } else {
            loginPath()
        }
    }
    
    func whatsappPressed() {
        if (UIApplication.shared.canOpenURL(URL(string: "whatsapp://app")!)) {
            let url = URL(string : "whatsapp://send?text=" + shareText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!)
            UIApplication.shared.openURL(url!)
            
            self.sendShareReferralCodeAnalytic("Whatsapp", username: "")
        } else {
            Constant.showDialog("No Whatsapp", message: "Silakan install Whatsapp dari app store terlebih dahulu")
        }
    }
    
    func linePressed() {
        if (Line.isLineInstalled()) {
            Line.shareText(shareText)
            
            self.sendShareReferralCodeAnalytic("Line", username: "")
        } else {
            Constant.showDialog("No Line app", message: "Silakan install Line dari app store terlebih dahulu")
        }
    }
    
    func smsPressed() {
        let composer = MFMessageComposeViewController()
        if (MFMessageComposeViewController.canSendText()) {
            composer.body = shareText
            composer.messageComposeDelegate = self
            self.present(composer, animated: true, completion: nil)
            
            self.sendShareReferralCodeAnalytic("SMS", username: "")
        }
    }
    
    func emailPressed() {
        let composer = MFMailComposeViewController()
        if (MFMailComposeViewController.canSendMail()) {
            composer.setMessageBody(shareText, isHTML: false)
            composer.mailComposeDelegate = self
            self.present(composer, animated: true, completion: nil)
            
            self.sendShareReferralCodeAnalytic("Email", username: "")
        } else {
            Constant.showDialog("No Active E-mail", message: "Untuk dapat membagi kode referral melalui e-mail, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
        }
    }
    
    func copyPressed() {
        UIPasteboard.general.string = shareText
        Constant.showDialog("Copied", message: "Teks telah disalin")
    }
    
    // MARK: - Analytics
    
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
    
    // MARK: - Other
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
}
