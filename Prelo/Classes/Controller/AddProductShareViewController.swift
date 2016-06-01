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

class AddProductShareViewController: BaseViewController, PathLoginDelegate, InstagramLoginDelegate, UIDocumentInteractionControllerDelegate {
    
    var sendProductParam : [String : String!] = [:]
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
    
    var chargePercent : Double = 10
    var basePrice = 925000
    
    var productID = ""
    var me = CDUser.getOne()
    
    var productImg : String?
    var productImgImage : UIImage?
    var productName : String!
    var permalink : String!
    var linkToShare = AppTools.PreloBaseUrl
    var textToShare1 = ""
    var textToShare2 = ""
    
    var mgInstagram : MGInstagram?
    
    var pathSender : AddProductShareButton?
    
    func updateButtons(sender : AddProductShareButton) {
        let tag = sender.tag
        let arr = arrayRows[tag]
        let c = sender.active ? sender.normalColor : sender.selectedColor
        sender.active = !sender.active
        pathSender = sender
        
        // Update buttons
        for b in arr {
            b.setTitleColor(c, forState: UIControlState.Normal)
            b.active = sender.active
            
            if (b.titleLabel?.text == "") { // unchek, check it!
                b.setTitle("", forState: UIControlState.Normal)
            } else if (b.titleLabel?.text == "") { // checked, uncheck it
                b.setTitle("", forState: UIControlState.Normal)
            }
        }
        
        // Update percentage
        let p = self.percentages[tag]
        self.chargePercent = self.chargePercent + (p * (sender.active ? -1 : 1))
        self.adaptCharge()
    }
    
    @IBAction func setSelectShare(sender : AddProductShareButton)
    {
        btnSend.setTitle("Loading..", forState: UIControlState.Disabled)
        let tag = sender.tag
        
        if (!sender.active) { // Akan mengaktifkan tombol share
            if (tag == 0) { // Instagram
                if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "instagram://app")!)) {
                    UIPasteboard.generalPasteboard().string = self.textToShare1
                    Constant.showDialog("Text sudah disalin ke clipboard", message: "Silakan paste sebagai deskripsi post Instagram kamu")
                    mgInstagram = MGInstagram()
                    if let img = productImgImage {
                        mgInstagram?.postImage(img, withCaption: self.textToShare1, inView: self.view, delegate: self)
                        self.updateButtons(sender)
                    } else {
                        Constant.showDialog("Instagram Share", message: "Oops, terdapat kesalahan saat pemrosesan")
                    }
                } else {
                    Constant.showDialog("No Instagram app", message: "Silakan install Instagram dari app store terlebih dahulu")
                }
            } else if (tag == 2) { // Facebook
                if (SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook)) {
                    let composer = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                    if let url = NSURL(string:self.linkToShare) {
                        composer.addURL(url)
                    }
                    let pimg = self.productImg == nil ? "" : self.productImg!
                    if let imgUrl = NSURL(string: pimg) {
                        if let imgData = NSData(contentsOfURL: imgUrl) {
                            if let img = UIImage(data: imgData) {
                                composer.addImage(img)
                            }
                        }
                    }
                    composer.setInitialText("Temukan barang bekas berkualitas-ku, download aplikasinya sekarang juga di http://prelo.co.id #PreloID")
                    composer.completionHandler = { result -> Void in
                        let getResult = result as SLComposeViewControllerResult
                        switch(getResult.rawValue) {
                        case SLComposeViewControllerResult.Cancelled.rawValue:
                            print("Cancelled")
                        case SLComposeViewControllerResult.Done.rawValue:
                            print("Done")
                            self.updateButtons(sender)
                        default:
                            print("Error")
                        }
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                    self.presentViewController(composer, animated: true, completion: nil)
                } else {
                    Constant.showDialog("Anda belum login", message: "Silakan login Facebook dari menu Settings")
                }
            } else if (tag == 3) { // Twitter
                if (SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter)) {
                    let composer = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                    if let url = NSURL(string:self.linkToShare) {
                        composer.addURL(url)
                    }
                    let pimg = self.productImg == nil ? "" : self.productImg!
                    if let imgUrl = NSURL(string: pimg) {
                        if let imgData = NSData(contentsOfURL: imgUrl) {
                            if let img = UIImage(data: imgData) {
                                composer.addImage(img)
                            }
                        }
                    }
                    composer.setInitialText(self.textToShare2)
                    composer.completionHandler = { result -> Void in
                        let getResult = result as SLComposeViewControllerResult
                        switch(getResult.rawValue) {
                        case SLComposeViewControllerResult.Cancelled.rawValue:
                            print("Cancelled")
                        case SLComposeViewControllerResult.Done.rawValue:
                            print("Done")
                            self.updateButtons(sender)
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
        } else { // Akan menonaktifkan tombol share
            self.updateButtons(sender)
        }
    }
    
    func instagramLoginFailed() {
        
    }
    
    func instagramLoginSuccess(token: String, id: String, name: String) {
        
    }
    
    func instagramLoginSuccess(token: String) {
        // API Migrasi
        request(APISocial.StoreInstagramToken(token: token)).responseJSON {resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Store Instagram Token")) {
                
            } else {
                self.select(self.pathSender!)
            }
        }
    }
    
    func loginTwitter() {
        Twitter.sharedInstance().logInWithCompletion { session, error in
            if (session != nil) {
                let twId = session!.userID
                let twUsername = session!.userName
                let twToken = session!.authToken
                let twSecret = session!.authTokenSecret
                
                // API Migrasi
        request(APISocial.PostTwitterData(id: twId, username: twUsername, token: twToken, secret: twSecret)).responseJSON {resp in
                    if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Post Twitter Data")) {
                        let json = JSON(resp.result.value!)
                        let data = json["_data"].bool
                        if (data != nil && data == true) { // Berhasil
                            // Save in core data
                            let userOther : CDUserOther = CDUserOther.getOne()!
                            userOther.twitterID = twId
                            userOther.twitterUsername = twUsername
                            userOther.twitterAccessToken = twToken
                            userOther.twitterTokenSecret = twSecret
                            UIApplication.appDelegate.saveContext()
                            
                            // Save in NSUserDefaults
                            NSUserDefaults.standardUserDefaults().setObject(twToken, forKey: "twittertoken")
                            NSUserDefaults.standardUserDefaults().synchronize()
                        }
                    }
                }
            } else {
                self.hideLoading()
            }
        }
    }
    
    func loginFacebook() {
        // Log in and get permission from facebook
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logInWithReadPermissions(["public_profile", "email"], handler: {(result : FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
            if (error != nil) { // Process error
                print("Process error")
                User.LogoutFacebook()
            } else if result.isCancelled { // User cancellation
                print("User cancel")
                User.LogoutFacebook()
            } else { // Success
                if result.grantedPermissions.contains("email") && result.grantedPermissions.contains("public_profile") {
                    // Do work
                    self.fbLogin()
                } else {
                    // Handle not getting permission
                }
            }
        })
    }
    
    func fbLogin()
    {
        // Show loading
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email, name"], tokenString: FBSDKAccessToken.currentAccessToken().tokenString, version: nil, HTTPMethod: "GET")
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                
                if ((error) != nil) {
                    // Handle error
                    print("Error fetching facebook profile")
                } else {
                    // Handle Profile Photo URL String
                    let userId =  result["id"] as! String
                    let name = result["name"] as! String
                    let email = result["email"] as! String
                    //let profilePictureUrl = "https://graph.facebook.com/\(userId)/picture?type=large" // FIXME: harusnya dipasang di profile kan?
                    let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                    
                    // API Migrasi
        request(APIAuth.LoginFacebook(email: email, fullname: name, fbId: userId, fbUsername: name, fbAccessToken: accessToken)).responseJSON {resp in
                        if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Login Facebook")) {
                            self.me?.others.fbAccessToken = accessToken
                            UIApplication.appDelegate.saveContext()
                        }
                    }
                }
            })
        }
    }

    
    func pathLoginSuccess(userData : JSON, token : String) {
        let pathId = userData["id"].string!
        let pathName = userData["name"].string!
        let email = userData["email"].string!
        //let profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        
        // API Migrasi
        request(APIAuth.LoginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON {resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Login Path")) {
                NSUserDefaults.standardUserDefaults().setObject(token, forKey: "pathtoken")
                NSUserDefaults.standardUserDefaults().synchronize()
            } else {
                self.setSelectShare(self.pathSender!)
            }
        }
    }
    
    func hideLoading() {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Share"

        // Do any additional setup after loading the view.
        
        if (arrayRows.count == 0)
        {
            arrayRows.append(arrayRow1)
            arrayRows.append(arrayRow2)
            arrayRows.append(arrayRow3)
            arrayRows.append(arrayRow4)
        }
        
        adaptCharge()
        
        self.title = "Kesempatan Terbatas"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        //Mixpanel.trackPageVisit(PageName.ShareAddedProduct)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ShareAddedProduct)
    }
    
    var first = true
    
    var shouldSkipBack = true
    
    override func viewDidAppear(animated: Bool) {
        if first && shouldSkipBack
        {
            first = false
            super.viewDidAppear(animated)
            var m = self.navigationController?.viewControllers
            m?.removeAtIndex((m?.count)!-2)
            self.navigationController?.viewControllers = m!
        }
        
        self.linkToShare = "\(AppTools.PreloBaseUrl)/p/\(self.permalink)"
        self.textToShare1 = "Temukan barang bekas berkualitas-ku, \(self.productName) di Prelo hanya dengan harga \(self.basePrice.asPrice). Nikmati mudahnya jual-beli barang bekas berkualitas dengan aman dari ponselmu. Download aplikasinya sekarang juga di http://prelo.co.id #PreloID"
        self.textToShare2 = "Dapatkan barang bekas berkualitas-ku, \(self.productName) seharga \(self.basePrice.asPrice) #PreloID"
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
        attString.addAttributes([NSForegroundColorAttributeName:UIColor.redColor()], range: AppToolsObjC.rangeOf(chargePercent.roundString+"%", inside: string))
        attString.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColorLight], range: AppToolsObjC.rangeOf("FREE", inside: string))
        captionCharge.attributedText = attString
        captionPrice.text = (basePrice - Int(charge)).asPrice
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sendProduct(instagram : String = "0", facebook : String = "0", twitter : String = "0")
    {
        self.sendProductParam["instagram"] = instagram
        self.sendProductParam["facebook"] = facebook
        self.sendProductParam["twitter"] = twitter
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            AppDelegate.Instance.produkUploader.addToQueue(ProdukUploader.ProdukLokal(produkParam: self.sendProductParam, produkImages: self.sendProductImages))
            dispatch_async(dispatch_get_main_queue(), {
                let b = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdMyProducts)
                self.navigationController?.pushViewController(b!, animated: true)
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
//        request(Products.ShareCommission(pId: productID, instagram: i, path: p, facebook: f, twitter: t)).responseJSON {resp in
//            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Share Commission")) {
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
        btnSend.enabled = false
        
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
