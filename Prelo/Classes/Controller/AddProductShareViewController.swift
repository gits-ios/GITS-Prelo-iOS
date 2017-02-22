 //
//  AddProductShareViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import TwitterKit
import Social
import Crashlytics
import Alamofire

class AddProductShareViewController: BaseViewController, PathLoginDelegate, InstagramLoginDelegate, UIDocumentInteractionControllerDelegate {
    
    var sendProductParam : [String : String?] = [:]
    var sendProductImages : [AnyObject] = []
    var sendProductBeforeScreen = ""
    var sendProductKondisi = ""
    
    @IBOutlet var arrayRow1 : [AddProductShareButton] = []
    @IBOutlet var arrayRow2 : [AddProductShareButton] = []
    @IBOutlet var arrayRow3 : [AddProductShareButton] = []
    @IBOutlet var arrayRow4 : [AddProductShareButton] = []
    
    var percentages = [3.0, 0.0, 4.0, 3.0]
    
    var arrayRows : [[AddProductShareButton]] = []
    
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var captionCharge : UILabel!
    @IBOutlet var captionChargePercent : UILabel!
    @IBOutlet var btnSend : UIButton!
    
    @IBOutlet var loadingPanel: UIView!
    
    var chargePercent : Double = 10
    var basePrice = 925000
    
    var productID = ""
    var me = CDUser.getOne()
    
    var productImg : String?
    var productImgImage : UIImage?
    var productName : String = ""
    var permalink : String!
    var linkToShare = AppTools.PreloBaseUrl
    var textToShare = ""
    
    var mgInstagram : MGInstagram?
    
    var pathSender : AddProductShareButton?
    
    var localId : String = ""
    
    @IBOutlet weak var topBarWarning: UIView!
    @IBOutlet weak var consHeightTopBarWarning: NSLayoutConstraint!
    
    func updateButtons(_ sender : AddProductShareButton) {
        let tag = sender.tag
        let arr = arrayRows[tag]
        let c = sender.active ? sender.normalColor : sender.selectedColor
        sender.active = !sender.active
        pathSender = sender
        
        // Update buttons
        for b in arr {
            b.setTitleColor(c, for: UIControlState())
            b.active = sender.active
            
            if (b.titleLabel?.text == "") { // unchek, check it!
                b.setTitle("", for: UIControlState())
            } else if (b.titleLabel?.text == "") { // checked, uncheck it
                b.setTitle("", for: UIControlState())
            }
        }
        
        // Update percentage
        let p = self.percentages[tag]
        self.chargePercent = self.chargePercent + (p * (sender.active ? -1 : 1))
        self.adaptCharge()
    }
    
    @IBAction func setSelectShare(_ sender : AddProductShareButton)
    {
        btnSend.setTitle("Loading..", for: UIControlState.disabled)
        let tag = sender.tag
        
        if (!sender.active) { // Akan mengaktifkan tombol share
            if (tag == 0) { // Instagram
                if (UIApplication.shared.canOpenURL(URL(string: "instagram://app")!)) {
                    var hashtags = ""
                    if let categId = sendProductParam["category_id"] {
                        if let h = CDCategory.getCategoryHashtagsWithID(categId!) {
                            hashtags = " \(h)"
                        }
                    }
                    
                    if let img = self.productImgImage {
                        let instagramSharePreview : InstagramSharePreview = .fromNib()
                        instagramSharePreview.textToShare.text = "\(self.textToShare)\(hashtags)"
                        instagramSharePreview.textToShare.layoutIfNeeded()
                        instagramSharePreview.imgToShare.image = img
                        instagramSharePreview.copyAndShare = {
                            UIPasteboard.general.string = "\(self.textToShare)\(hashtags)"
                            Constant.showDialog("Text sudah disalin ke clipboard", message: "Silakan paste sebagai deskripsi post Instagram kamu")
                            self.mgInstagram = MGInstagram()
                            self.mgInstagram?.post(img, withCaption: self.textToShare, in: self.view, delegate: self)
                            self.updateButtons(sender)
                            instagramSharePreview.removeFromSuperview()
                        }
                        instagramSharePreview.frame = CGRect(x: 0, y: -64, width: AppTools.screenWidth, height: AppTools.screenHeight)
                        self.view.addSubview(instagramSharePreview)
                    } else {
                        Constant.showDialog("Instagram Share", message: "Oops, terdapat kesalahan saat pemrosesan")
                    }
                } else {
                    Constant.showDialog("No Instagram app", message: "Silakan install Instagram dari app store terlebih dahulu")
                }
            } else if (tag == 2) { // Facebook
                self.showLoading()
                
                if (FBSDKAccessToken.current() != nil && FBSDKAccessToken.current().permissions.contains("publish_actions")) {
                    self.updateButtons(sender)
                    self.hideLoading()
                } else {
                    let p = ["sender" : self]
                    LoginViewController.LoginWithFacebook(p, onFinish: { result in
                        // Handle Profile Photo URL String
                        let userId =  result["id"] as? String
                        let name = result["name"] as? String
                        let accessToken = FBSDKAccessToken.current().tokenString
                        
                        print("result = \(result)")
                        print("accessToken = \(accessToken)")
                        
                        // userId & name is required
                        if (userId != nil && name != nil) {
                            // API Migrasi
                            let _ = request(APISocmed.postFacebookData(id: userId!, username: name!, token: accessToken!)).responseJSON {resp in
                                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Facebook")) {
                                    
                                    // Save in core data
                                    let userOther : CDUserOther = CDUserOther.getOne()!
                                    userOther.fbID = userId
                                    userOther.fbUsername = name
                                    userOther.fbAccessToken = accessToken
                                    UIApplication.appDelegate.saveContext()
                                    
                                    self.updateButtons(sender)
                                    self.hideLoading()
                                } else {
                                    LoginViewController.LoginFacebookCancelled(self, reason: "Terdapat kesalahan saat menyimpan data Facebook")
                                }
                            }
                        } else {
                            LoginViewController.LoginFacebookCancelled(self, reason: "Terdapat kesalahan data saat login Facebook")
                        }
                    })
                }
            } else if (tag == 3) { // Twitter
                self.showLoading()
                
                if (User.IsLoggedInTwitter) {
                    self.updateButtons(sender)
                    self.hideLoading()
                } else {
                    let p = ["sender" : self]
                    LoginViewController.LoginWithTwitter(p, onFinish: { result in
                        guard let twId = result["twId"] as? String,
                            let twUsername = result["twUsername"] as? String,
                            let twToken = result["twToken"] as? String,
                            let twSecret = result["twSecret"] as? String else {
                                LoginViewController.LoginTwitterCancelled(self, reason: "Terdapat kesalahan saat memproses data Twitter")
                                return
                        }
                        
                        let _ = request(APISocmed.postTwitterData(id: twId, username: twUsername, token: twToken, secret: twSecret)).responseJSON { resp in
                            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Twitter")) {
                                
                                // Save in core data
                                if let userOther : CDUserOther = CDUserOther.getOne() {
                                    userOther.twitterID = twId
                                    userOther.twitterUsername = twUsername
                                    userOther.twitterAccessToken = twToken
                                    userOther.twitterTokenSecret = twSecret
                                    UIApplication.appDelegate.saveContext()
                                }
                                
                                self.updateButtons(sender)
                                self.hideLoading()
                            } else {
                                LoginViewController.LoginTwitterCancelled(self, reason: "Terdapat kesalahan saat menyimpan data Twitter")
                            }
                        }
                    })
                }
            }
        } else { // Akan menonaktifkan tombol share
            self.updateButtons(sender)
        }
    }
    
    func instagramLoginFailed() {
        
    }
    
    func instagramLoginSuccess(_ token: String, id: String, name: String) {
        
    }
    
    func instagramLoginSuccess(_ token: String) {
        // API Migrasi
        let _ = request(APISocmed.storeInstagramToken(token: token)).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Store Instagram Token")) {
                
            } else {
                self.select(self.pathSender!)
            }
        }
    }
    
    func pathLoginSuccess(_ userData : JSON, token : String) {
        let pathId = userData["id"].string!
        let pathName = userData["name"].string!
        let email = userData["email"].string!
        //let profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        
        // API Migrasi
        let _ = request(APIAuth.loginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Login Path")) {
                UserDefaults.standard.set(token, forKey: "pathtoken")
                UserDefaults.standard.synchronize()
            } else {
                self.setSelectShare(self.pathSender!)
            }
        }
    }
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Share"

        // Do any additional setup after loading the view.
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        if (arrayRows.count == 0)
        {
            arrayRows.append(arrayRow1)
            arrayRows.append(arrayRow2)
            arrayRows.append(arrayRow3)
            arrayRows.append(arrayRow4)
        }
        
        adaptCharge()
        
        self.title = "Kesempatan Terbatas"
//        setupTopBanner()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.ShareAddedProduct)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ShareAddedProduct)
    }
    
    // MARK: - Warning top bar twitter
    func setupTopBanner() {
        let tbText = "Terdapat kesalahan saat mengakses Twitter. Mohon pastikan:\n- Aplikasi Twitter terpasang di device kamu dan ter-login dengan akun yang sama dengan yang akan di-sync, atau\n- Kamu sudah login di menu Settings > Twitter menggunakan akun yang sama dengan yang akan di-sync, atau\n- Belum ada aplikasi Prelo terpasang di akun Twitter (bisa dilihat di web Twitter http://www.twitter.com, di bagian Settings, klik App). Jika sudah, silakan revoke access terlebih dahulu.\n\nSelain itu, pastikan e-mail akun Twitter sudah terverifikasi."
        
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        var topBannerHeight : CGFloat = 30.0
        let textRect = tbText.boundsWithFontSize(UIFont.systemFont(ofSize: 11), width: screenWidth - 16)
        topBannerHeight += textRect.height
        let topLabelMargin : CGFloat = 8.0
        let topBanner : UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: topBannerHeight), backgroundColor: Theme.ThemeOrange)
        let topLabel : UITextView = UITextView(frame: CGRect(x: topLabelMargin, y: 0, width: screenWidth - (topLabelMargin * 2), height: topBannerHeight))
        topLabel.textColor = UIColor.white
        topLabel.font = UIFont.systemFont(ofSize: 11)
//        topLabel.lineBreakMode = .byWordWrapping
//        topLabel.numberOfLines = 0
        topLabel.text = tbText
        topLabel.isEditable = false
        topLabel.isSelectable = true
        topLabel.backgroundColor = UIColor.clear
        topBanner.addSubview(topLabel)
        
        
        self.topBarWarning.addSubview(topBanner)
        self.consHeightTopBarWarning.constant = topBannerHeight
    }
    
    var first = true
    
    var shouldSkipBack = true
    
    override func viewDidAppear(_ animated: Bool) {
        if first && shouldSkipBack
        {
            first = false
            super.viewDidAppear(animated)
            var m = self.navigationController?.viewControllers
            m?.remove(at: (m?.count)!-2)
            self.navigationController?.viewControllers = m!
        }
        
        self.linkToShare = "\(AppTools.PreloBaseUrl)/p/\(self.permalink)"
        self.textToShare = "Temukan barang bekas berkualitas-ku, \(self.productName) di Prelo hanya dengan harga \(self.basePrice.asPrice). Nikmati mudahnya jual-beli barang bekas berkualitas dengan aman dari ponselmu. Download aplikasinya sekarang juga di http://prelo.co.id #PreloID"
    }
    
    func adaptCharge()
    {
        captionChargePercent.text = Double(100 - chargePercent).roundString + " %"
        if (captionChargePercent.text == "0 %")
        {
            captionChargePercent.text = "FREE!"
        }
        let charge = Double(basePrice) * chargePercent / 100
        var string = "Charge Prelo : " + Int(charge).asPrice + " (" + chargePercent.roundString + "%)"
        if (chargePercent == 0)
        {
            string = "Charge Prelo : FREE"
        }
        let attString = NSMutableAttributedString(string: string)
        attString.addAttributes([NSForegroundColorAttributeName:UIColor.red], range: AppToolsObjC.range(of: chargePercent.roundString+"%", inside: string))
        attString.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColorLight], range: AppToolsObjC.range(of: "FREE", inside: string))
        captionCharge.attributedText = attString
        captionPrice.text = (basePrice - Int(charge)).asPrice
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sendProduct(_ instagram : String = "0", facebook : String = "0", twitter : String = "0")
    {
        /*
        self.sendProductParam["instagram"] = instagram
        self.sendProductParam["facebook"] = facebook
        self.sendProductParam["twitter"] = twitter
        
        // Mixpanel
        var categ = ""
        if let categId = sendProductParam["category_id"] {
            if let categObj = CDCategory.getCategoryWithID(categId!) {
                categ = categObj.name
            }
        }
        var mixpImageCount = 0
        var mixpImgs : [UIImage?] = []
        for i in 0...self.sendProductImages.count - 1 {
            mixpImgs.append(self.sendProductImages[i] as? UIImage)
            if (mixpImgs[i] != nil) {
                mixpImageCount += 1
            }
        }
        var kondisiName = ""
        if let kondisi = CDProductCondition.getProductConditionWithID(sendProductKondisi) {
            kondisiName = kondisi.name
        }
        let weightInt : Int? = Int(sendProductParam["weight"]!!)
        let priceOriInt : Int? = Int(sendProductParam["price_original"]!!)
        let priceInt : Int? = Int(sendProductParam["price"]!!)
        let chargePercentInt : Int = Int(self.chargePercent)
        var fbUsername = "", twUsername = "", igUsername = ""
        if let uOther = CDUserOther.getOne() {
            fbUsername = uOther.fbUsername != nil ? uOther.fbUsername! : ""
            twUsername = uOther.twitterUsername != nil ? uOther.twitterUsername! : ""
            igUsername = uOther.instagramUsername != nil ? uOther.instagramUsername! : ""
        }
        let pt = [
            "Previous Screen" : self.sendProductBeforeScreen,
            "Name" : self.productName,
            "Category" : categ,
            "Number of Picture Uploaded" : mixpImageCount,
            "Is Main Picture Uploaded" : mixpImgs[0] != nil ? true : false,
            "Is Back Picture Uploaded" : mixpImgs[1] != nil ? true : false,
            "Is Label Picture Uploaded" : mixpImgs[2] != nil ? true : false,
            "Is Wear Picture Uploaded" : mixpImgs[3] != nil ? true : false,
            "Is Defect Picture Uploaded" : mixpImgs[4] != nil ? true : false,
            "Condition" : kondisiName,
            "Product Brand" : sendProductParam["brand_name"]!,
            "Is New Brand" : sendProductParam["proposed_brand"]! == "" ? false : true,
            "Is Free Ongkir" : sendProductParam["free_ongkir"]! == "0" ? false : true,
            "Weight" : weightInt != nil ? weightInt! : 0,
            "Price Original" : priceOriInt != nil ? priceOriInt! : 0,
            "Price" : priceInt != nil ? priceInt! : 0,
            "Commission Percentage" : chargePercentInt,
            "Commission Price" : priceInt != nil ? priceInt! * chargePercentInt / 100 : 0,
            "Is Facebook Shared" : facebook == "1" ? true : false,
            "Facebook Username" : fbUsername,
            "Is Twitter Shared" : twitter == "1" ? true : false,
            "Twitter Username" : twUsername,
            "Is Instagram Shared" : instagram == "1" ? true : false,
            "Instagram Username" : igUsername,
            "Time" : Date().isoFormatted,
            "platform_sent_from" : "ios"
        ] as [String : Any]
         */
        
        // Prelo Analytic - Share Product
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            "Product Name" : productName,
            "Commission Percentage" : Int(self.chargePercent),
            "Facebook" : (facebook != "0" ? true : false),
            "Twitter" : (twitter != "0" ? true : false),
            "Instagram" : (instagram != "0" ? true : false),
        ] as [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ShareProduct, data: pdata, previousScreen: self.sendProductBeforeScreen, loginMethod: loginMethod)
        
        // Add product to product uploader
        // DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
//            AppDelegate.Instance.produkUploader.addToQueue(ProdukUploader.ProdukLokal(produkParam: self.sendProductParam, produkImages: self.sendProductImages, mixpanelParam: pt as [AnyHashable: Any]))
            AppDelegate.Instance.produkUploader.addToQueue(ProdukUploader.ProdukLokal(produkParam: self.sendProductParam, produkImages: self.sendProductImages, preloAnalyticParam: pdata as [AnyHashable: Any]))
            DispatchQueue.main.async(execute: {
                if (AppDelegate.Instance.produkUploader.getQueue().count > 0) {
                    
                    // set state is uploading
                    CDDraftProduct.setUploading(self.localId, isUploading: true)
                    
                    let b = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdMyProducts)
                    self.navigationController?.pushViewController(b!, animated: true)
                } else {
                    Crashlytics.sharedInstance().recordCustomExceptionName("ProdukUploader", reason: "Empty Queue", frameArray: [])
                    Constant.showDialog("Warning", message: "Oops, terdapat kesalahan saat mengupload barang kamu.\nMohon coba upload foto utama dan foto merek terlebih dahulu, kemudian tambah foto melalui fitur edit.")
                    self.btnSend.isEnabled = true
                }
            })
        })
        return
        
//        let url = "\(AppTools.PreloBaseUrl)/api/product"
//        let userAgent : String? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.UserAgent) as? String
//        
//        AppToolsObjC.sendMultipart(self.sendProductParam, images: self.sendProductImages, withToken: User.Token!, andUserAgent: userAgent!, to:url, success: {op, res in
//            print(res)
//            
//            let json = JSON(res)
//            
//            //Mixpanel.sharedInstance().track("Adding Product", properties: ["success":"1"])
//            
//            // Mixpanel
//            let data = json["_data"]
//            
//            var mixpImageCount = 0
//            var mixpImgs : [UIImage?] = []
//            for i in 0...self.sendProductImages.count - 1 {
//                mixpImgs.append(self.sendProductImages[i] as? UIImage)
//                if (mixpImgs[i] != nil) {
//                    mixpImageCount += 1
//                }
//            }
//            let proposedBrand : String? = ((data["proposed_brand"] != nil) ? data["proposed_brand"].stringValue : nil)
//            let isFacebook = ((data["share_status"]["shared"]["FACEBOOK"].intValue == 0) ? false : true)
//            let isTwitter = ((data["share_status"]["shared"]["TWITTER"].intValue == 0) ? false : true)
//            let isInstagram = ((data["share_status"]["shared"]["INSTAGRAM"].intValue == 0) ? false : true)
//            let pt = [
//                "Previous Screen" : self.sendProductBeforeScreen,
//                "Name" : data["name"].stringValue,
//                "Category 1" : "",
//                "Category 2" : "",
//                "Category 3" : "",
//                "Number of Picture Uploaded" : mixpImageCount,
//                "Is Main Picture Uploaded" : ((mixpImgs[0] != nil) ? true : false),
//                "Is Back Picture Uploaded" : ((mixpImgs[1] != nil) ? true : false),
//                "Is Label Picture Uploaded" : ((mixpImgs[2] != nil) ? true : false),
//                "Is Wear Picture Uploaded" : ((mixpImgs[3] != nil) ? true : false),
//                "Is Defect Picture Uploaded" : ((mixpImgs[4] != nil) ? true : false),
//                "Condition" : self.sendProductKondisi,
//                "Brand" : ((proposedBrand != nil) ? proposedBrand! : data["brand_id"].stringValue),
//                "Is New Brand" : ((proposedBrand != nil) ? true : false),
//                "Is Free Ongkir" : ((data["free_ongkir"].intValue == 0) ? false : true),
//                "Weight" : data["weight"].intValue,
//                "Price Original" : data["price_original"].intValue,
//                "Price" : data["price"].intValue,
//                "Commission Percentage" : data["commission"].intValue,
//                "Commission Price" : data["price"].intValue * data["commission"].intValue / 100,
//                "Is Facebook Shared" : isFacebook,
//                "Facebook Username" : "",
//                "Is Twitter Shared" : isTwitter,
//                "Twitter Username" : "",
//                "Is Instagram Shared" : isInstagram,
//                "Instagram Username" : "",
//                "Time" : NSDate().isoFormatted
//            ]
//            Mixpanel.trackEvent(MixpanelEvent.AddedProduct, properties: pt as [NSObject : AnyObject])
//            
//            self.productID = (json["_data"]["_id"].string)!
////            self.sendShare()
//            
//            NSNotificationCenter.defaultCenter().postNotificationName("refreshHome", object: nil)
//            let b = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdMyProducts)
//            self.navigationController?.pushViewController(b!, animated: true)
//            
//            }, failure: { op, err in
//                //Mixpanel.sharedInstance().track("Adding Product", properties: ["success":"0"])
////                self.navigationItem.rightBarButtonItem = self.confirmButton.toBarButton()
//                self.btnSend.enabled = true
//                var msgContent = "Terdapat kesalahan saat upload barang, silahkan coba beberapa saat lagi"
//                if let msg = op.responseString {
//                    if let range1 = msg.rangeOfString("{\"_message\":\"") {
//                        //print(range1)
//                        let msg1 = msg.substringFromIndex(range1.endIndex)
//                        if let range2 = msg1.rangeOfString("\"}") {
//                            //print(range2)
//                            msgContent = msg1.substringToIndex(range2.startIndex)
//                        }
//                    }
//                }
//                UIAlertView.SimpleShow("Upload Barang", message: msgContent)
//        })
    }
    
//    func sendShare()
//    {
//        var i = "0", p = "0", f = "0", t = "0"
//        
//        for x in 0...3
//        {
//            let arr = arrayRows[x]
//            for b in arr
//            {
//                if (b.titleLabel?.text == "")
//                {
//                    if (x == 0)
//                    {
//                        i = "1"
//                    }
//                    
//                    if (x == 1)
//                    {
//                        p = "1"
//                    }
//                    
//                    if (x == 2)
//                    {
//                        f = "1"
//                    }
//                    
//                    if (x == 3)
//                    {
//                        t = "1"
//                    }
//                }
//            }
//        }
//        
//        let _ = request(APIProduct.ShareCommission(pId: productID, instagram: i, path: p, facebook: f, twitter: t)).responseJSON {resp in
//            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Share Commission")) {
//                NSNotificationCenter.defaultCenter().postNotificationName("refreshHome", object: nil)
//                let b = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdMyProducts)
//                self.navigationController?.pushViewController(b!, animated: true)
//            } else {
//                self.btnSend.enabled = true
//            }
//        }
//    }
    
    @IBAction func shareDone()
    {
        btnSend.isEnabled = false
        
        var i = "0", p = "0", f = "0", t = "0"
        
        for x in 0...3
        {
            let arr = arrayRows[x]
            for b in arr
            {
                if (b.titleLabel?.text == "")
                {
                    if (x == 0)
                    {
                        i = "1"
                    }
                    
                    if (x == 1)
                    {
                        p = "1"
                    }
                    
                    if (x == 2)
                    {
                        f = "1"
                    }
                    
                    if (x == 3)
                    {
                        t = "1"
                    }
                }
            }
        }
        
        sendProduct(i, facebook: f, twitter: t)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension Double
{
    var roundString : String
    {
        if (self - Double(Int(self)) == 0) {
            return String(Int(self))
        } else
        {
            return String(stringInterpolationSegment: self)
        }
    }
}
