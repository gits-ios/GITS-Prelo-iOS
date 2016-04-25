//
//  PreloShareController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Social
import MessageUI

struct PreloShareItem
{
    var image : UIImage?
    var text : String?
    var url : NSURL?
    var permalink : String?
    var price : String?
}

struct PreloShareAgent
{
    var title : String = ""
    var icon : String = ""
    var font : UIFont = AppFont.Prelo2.getFont!
    var background : UIColor = UIColor.whiteColor()
    var availibility : Bool = false
}

class PreloShareController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIDocumentInteractionControllerDelegate, UIGestureRecognizerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, PathLoginDelegate
{

    static var sharer : PreloShareController = PreloShareController()
    
    static func Share(item : PreloShareItem, inView:UIView)
    {
        let s = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPreloShare) as! PreloShareController
        s.item = item
        
//        if let i = item.image
//        {
//            s.item?.image = i.putPreloWatermarkWithUsername("")
//        }
        
        s.parentView = inView
        
        sharer = s
        
        sharer.show()
    }
    
    static func Share(item : PreloShareItem, inView : UIView, detail : ProductDetail?)
    {
        let s = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPreloShare) as! PreloShareController
        s.item = item
        
//        if let i = item.image
//        {
//            s.item?.image = i.putPreloWatermarkWithUsername("")
//        }
        
        s.parentView = inView
        s.detail = detail
        
        sharer = s
        
        // Mixpanel
        let p = [
            "Product" : ((detail != nil) ? (detail!.name) : ""),
            "Product ID" : ((detail != nil) ? (detail!.productID) : ""),
            "Category 1" : ((detail != nil && detail?.categoryBreadcrumbs.count > 1) ? (detail!.categoryBreadcrumbs[1]["name"].string!) : ""),
            "Category 2" : ((detail != nil && detail?.categoryBreadcrumbs.count > 2) ? (detail!.categoryBreadcrumbs[2]["name"].string!) : ""),
            "Category 3" : ((detail != nil && detail?.categoryBreadcrumbs.count > 3) ? (detail!.categoryBreadcrumbs[3]["name"].string!) : ""),
            "Seller" : ((detail != nil) ? (detail!.theirName) : "")
        ]
        Mixpanel.trackPageVisit(PageName.ProductDetailShare, otherParam: p)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ProductDetailShare)
        
        sharer.show()
    }
    
    var item : PreloShareItem?
    var parentView : UIView?
    var product : Product?
    var detail : ProductDetail?
    
    @IBOutlet var conGridViewBottomMargin : NSLayoutConstraint!
    @IBOutlet var gridView : UICollectionView!
    
    var agents : Array<PreloShareAgent> = []
    
    var linkToShare = ""
    var textToShare1 = ""
    var textToShare2 = ""
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //FIXME: Sepertinya fungsi ini ga kepanggil, jangan taruh logic di sini
        
        self.linkToShare = "\(item!.permalink!)"
        self.textToShare1 = "Temukan barang bekas berkualitas, \(item!.text!) di Prelo hanya dengan harga \(item!.price!). Nikmati mudahnya jual-beli barang bekas berkualitas dengan aman dari ponselmu. Download aplikasinya sekarang juga di http://prelo.co.id #PreloID"
        self.textToShare2 = "Dapatkan barang bekas berkualitas, \(item!.text!) seharga \(item!.price!) #PreloID"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (CDUser.pathTokenAvailable())
        {
            
        }
        
        let url = NSURL(string : "")
        let x = UIApplication.sharedApplication().canOpenURL(NSURL(string:"")!)
        agents.append(PreloShareAgent(title: "Instagram", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor.brownColor(), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"instagram://app")!)))
        agents.append(PreloShareAgent(title: "Facebook", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor(hexString: "#3b5998"), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"fb://")!)))
        agents.append(PreloShareAgent(title: "Twitter", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor(hexString: "#00aced"), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"twitter://timeline")!)))
        agents.append(PreloShareAgent(title: "Path", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor(hexString: "#cb2027"), availibility: true))
        agents.append(PreloShareAgent(title: "Whatsapp", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor(hexString: "#4dc247"), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"whatsapp://app")!)))
        agents.append(PreloShareAgent(title: "Line", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor(hexString: "#4dc247"), availibility: Line.isLineInstalled()))
        agents.append(PreloShareAgent(title: "Salin", icon: "", font: AppFont.PreloAwesome.getFont!, background: UIColor.darkGrayColor(), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"instagram://app")!)))
        agents.append(PreloShareAgent(title: "SMS", icon: "", font: AppFont.PreloAwesome.getFont!, background: UIColor.darkGrayColor(), availibility: MFMessageComposeViewController.canSendText()))
        agents.append(PreloShareAgent(title: "E-mail", icon: "", font: AppFont.PreloAwesome.getFont!, background: UIColor.darkGrayColor(), availibility: MFMailComposeViewController.canSendMail()))
        
        // Do any additional setup after loading the view.
        conGridViewBottomMargin.constant = -gridView.height
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func show()
    {
        self.view.alpha = 1
        self.view.backgroundColor = UIColor(white: 0.5, alpha: 0)
        self.view.frame = (parentView?.bounds)!
        
        parentView?.addSubview(self.view)
        
        self.conGridViewBottomMargin.constant = 0
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.view.backgroundColor = UIColor(white: 0.5, alpha: 0.8)
            self.gridView.layoutIfNeeded()
            }, completion: {s in
                self.gridView.dataSource = self
                self.gridView.delegate = self
        })
    }
    
    @IBAction func hide()
    {
        conGridViewBottomMargin.constant = -gridView.height
        self.gridView.dataSource = nil
        self.gridView.delegate = nil
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.view.backgroundColor = UIColor(white: 0.5, alpha: 0)
            self.gridView.layoutIfNeeded()
            }, completion: {s in
                if (s)
                {
                    self.view.removeFromSuperview()
                }
        })
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return agents.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let s = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ShareCell
        
        let a = agents[indexPath.item]
        
        if (a.availibility == false)
        {
            s.sectionIcon.backgroundColor = UIColor.lightGrayColor()
        } else {
            s.sectionIcon.backgroundColor = a.background
        }
        
        s.captionIcon.font = a.font
        s.captionIcon.text = a.icon
        s.captionTitle.text = a.title
        
        return s
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake((UIScreen.mainScreen().bounds.width/3)-4, 84)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let a = agents[indexPath.item]
        
        if (a.availibility == false)
        {
            return
        }
        
        print(item?.url)
        print(item?.text)
        
        request(Method.GET, (item?.url?.absoluteString)!).validate().response{ req, res, data, error in
            if let imgData = data
            {
                let i = UIImage(data: imgData)
                self.share(a, image: i!)
            }
        }
    }
    
    func loginPath()
    {
        let pathLoginVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePathLogin, owner: nil, options: nil).first as! PathLoginViewController
        pathLoginVC.delegate = self
        pathLoginVC.standAlone = true
        let n = UINavigationController(rootViewController: pathLoginVC)
        self.presentViewController(n, animated: true, completion: nil)
    }
    
    func pathLoginSuccess(userData: JSON, token: String) {
        registerPathToken(userData, token : token)
        postToPath(pathImage!, token: token)
    }
    
    func postToPath(image : UIImage, token : String)
    {
//        let param = [
//            "caption":(item?.text)!
//        ]
        
//        do {
//            let data = try NSJSONSerialization.dataWithJSONObject(param, options: NSJSONWritingOptions.init(rawValue: 0))
//            let jsonString = NSString(data: data, encoding: NSUTF8StringEncoding)
//        } catch {
//        
//        }
        let a = UIAlertView(title: "Path", message: "Posting to path", delegate: nil, cancelButtonTitle: nil)
        a.show()
        AppToolsObjC.PATHPostPhoto(image, param: ["private":true, "caption":(item?.text)!], token: token, success: {_, _ in
            a.dismissWithClickedButtonIndex(0, animated: true)
            self.hide()
            }, failure: nil)
    }
    
    func hideLoading() {
        
    }
    
    func registerPathToken(userData : JSON, token : String)
    {
        let pathId = userData["id"].string!
        let pathName = userData["name"].string!
        let email = userData["email"].string!
        //let profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        
        self.mixpanelSharedProduct("Path", username: pathName)
        
        /* FIXME: Sementara dijadiin komentar, soalnya kalo user lagi ga login terus share product via path, harusnya ga usah APIAuth.LoginPath ga sih
        // API Migrasi
        request(APIAuth.LoginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON {req, resp, res, err in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Login Path")) {
                print("Path login req = \(req)")
                
                if (err != nil) { // Terdapat error
                    
                } else {
                    NSUserDefaults.standardUserDefaults().setObject(token, forKey: "pathtoken")
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
            }
        }*/
    }
    
    var mgInstagram : MGInstagram?
    var pathImage : UIImage?
    func share(a : PreloShareAgent, var image : UIImage)
    {
        image = image.putPreloWatermarkWithUsername("@" + (detail?.json["_data"]["seller"]["username"].stringValue)!)!
        
        if (a.title.lowercaseString == "instagram")
        {
            UIPasteboard.generalPasteboard().string = "Temukan barang bekas berkualitas, \(item!.text!) di Prelo hanya dengan harga \(item!.price!). Nikmati mudahnya jual-beli barang bekas berkualitas dengan aman dari ponselmu. Download aplikasinya sekarang juga di http://prelo.co.id #PreloID"
            Constant.showDialog("Text sudah disalin ke clipboard", message: "Silakan paste sebagai deskripsi post Instagram kamu")
            mgInstagram = MGInstagram()
            mgInstagram?.postImage(image, withCaption: self.textToShare1, inView: self.view, delegate: self)
            self.mixpanelSharedProduct("Instagram", username: "")
        }
        
        if (a.title.lowercaseString == "path")
        {
            pathImage = image
            if (CDUser.pathTokenAvailable())
            {
                postToPath(image, token: NSUserDefaults.standardUserDefaults().stringForKey("pathtoken")!)
                if let o = CDUserOther.getOne() {
                    self.mixpanelSharedProduct("Path", username: (o.pathUsername != nil) ? o.pathUsername! : "")
                } else {
                    self.mixpanelSharedProduct("Path", username: "")
                }
            } else
            {
                loginPath()
            }
            
        }
        
        if (a.title.lowercaseString == "whatsapp")
        {
            var message = ""
            var name = ""
            if let n = item!.text
            {
                name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
            }
            message = "Temukan barang bekas berkualitas, \(name) hanya dengan harga \(item!.price!). Jangan sampai kehabisan, beli sekarang juga di Prelo! \(item!.permalink!)".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!

            let url = NSURL(string : "whatsapp://send?text="+message)
            UIApplication.sharedApplication().openURL(url!)
            self.mixpanelSharedProduct("Whatsapp", username: "")
        }
        
        if (a.title.lowercaseString == "salin")
        {
            var name = ""
            if let n = item!.text
            {
                name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
            }
            name = "Temukan barang bekas berkualitas, \(name) hanya dengan harga \(item!.price!). Jangan sampai kehabisan, beli sekarang juga di Prelo! \(item!.permalink!)"
            UIPasteboard.generalPasteboard().string = name
            UIAlertView.SimpleShow("", message: "Sukses di salin")
            
            self.mixpanelSharedProduct("Copy Info", username: "")
        }
        
        if (a.title.lowercaseString == "sms")
        {
            var message = item!.text!
            var name = ""
            if let n = item!.text
            {
                name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
            }
            message = "Temukan barang bekas berkualitas, \(name) hanya dengan harga \(item!.price!). Jangan sampai kehabisan, beli sekarang juga di Prelo! \(item!.permalink!)"
            let composer = MFMessageComposeViewController()
            composer.body = message
            composer.messageComposeDelegate = self
            
            self.presentViewController(composer, animated: true, completion: nil)
            
            self.mixpanelSharedProduct("SMS", username: "")
        }
        
        if (a.title.lowercaseString == "e-mail")
        {
            var message = item!.text!
            var name = ""
            if let n = item!.text
            {
                name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
            }
            message = "Hai!\n\nKamu bisa dapatkan barang bekas berkualitas, \(name) hanya dengan harga \(item!.price!).\nInfo selengkapnya mengenai kondisi barang bisa kamu cari tahu di \(item!.permalink!).\nNikmati mudahnya jual-beli barang bekas berkualitas dengan aman di Prelo. Dapatkan juga beragam keuntungan dengan aplikasi Prelo di ponsel kamu.\nDownload Prelo sekarang di http://prelo.co.id\nCheers!"
            let composer = MFMailComposeViewController()
            if (MFMailComposeViewController.canSendMail()) {
                composer.setMessageBody(message, isHTML: false)
                composer.mailComposeDelegate = self
                
                self.presentViewController(composer, animated: true, completion: nil)
                
                self.mixpanelSharedProduct("Email", username: "")
            } else {
                Constant.showDialog("No Active E-mail", message: "Untuk dapat membagi barang melalui e-mail, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
            }
        }
        
        if (a.title.lowercaseString == "line")
        {
            var message = item!.text!
            var name = ""
            if let n = item!.text
            {
                name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
            }
            message = "Temukan barang bekas berkualitas, \(name) hanya dengan harga \(item!.price!). Jangan sampai kehabisan, beli sekarang juga di Prelo! \(item!.permalink!)"
            Line.shareText(message)
            self.mixpanelSharedProduct("Line", username: "")
        }
        
        if (a.title.lowercaseString == "facebook" || a.title.lowercaseString == "twitter")
        {
            let type = a.title.lowercaseString == "facebook" ? SLServiceTypeFacebook : SLServiceTypeTwitter
            
            if (SLComposeViewController.isAvailableForServiceType(type))
            {
                let url = NSURL(string:"\(item!.permalink!)")
                let composer = SLComposeViewController(forServiceType: type)
                composer.addURL(url!)
                composer.addImage(image)
                if (type == SLServiceTypeFacebook) {
                    composer.setInitialText("Dapatkan barang bekas berkualitas, \(item!.text!) seharga Rp\(item!.price!) #PreloID")
                } else if (type == SLServiceTypeTwitter) {
                    composer.setInitialText("Dapatkan barang bekas berkualitas, \(item!.text!) seharga Rp\(item!.price!) #PreloID")
                }
                composer.completionHandler = { result -> Void in
                    var getResult = result as SLComposeViewControllerResult
                    switch(getResult.rawValue) {
                    case SLComposeViewControllerResult.Cancelled.rawValue:
                        print("Cancelled")
                    case SLComposeViewControllerResult.Done.rawValue:
                        print("Done")
                        if (type == SLServiceTypeFacebook) {
                            self.mixpanelSharedProduct("Facebook", username: "")
                        } else if (type == SLServiceTypeTwitter) {
                            self.mixpanelSharedProduct("Twitter", username: "")
                        }
                    default:
                        print("Error")
                    }
                }
                self.presentViewController(composer, animated: true, completion: nil)
            } else
            {
                UIAlertView.SimpleShow(a.title, message: "Silakan login "+a.title+" dari Settings")
            }
        }
        
        /* TO BE DELETED, dilakukan di masing2 if closure
        // Mixpanel
        var socmedName = a.title.capitalizedString
        if (socmedName == "Sms") {
            socmedName = "SMS"
        } else if (socmedName == "Salin") {
            socmedName = "Copy Info"
        }
        let pt = [
            "Socmed" : socmedName,
            "Socmed Username" : "", // FIXME: cuma fb ama twitter keknya yg dapet username
            "Product Name" : ((detail != nil) ? (detail!.name) : ""),
            "Category 1" : ((detail != nil && detail?.categoryBreadcrumbs.count > 1) ? (detail!.categoryBreadcrumbs[1]["name"].string!) : ""),
            "Category 2" : ((detail != nil && detail?.categoryBreadcrumbs.count > 2) ? (detail!.categoryBreadcrumbs[2]["name"].string!) : ""),
            "Category 3" : ((detail != nil && detail?.categoryBreadcrumbs.count > 3) ? (detail!.categoryBreadcrumbs[3]["name"].string!) : "")
        ]
        Mixpanel.trackEvent(MixpanelEvent.SharedProduct, properties: pt)*/
    }
    
    func mixpanelSharedProduct(socmed : String, username : String) {
        let pt = [
            "Socmed" : socmed,
            "Socmed Username" : username,
            "Product Name" : ((detail != nil) ? (detail!.name) : ""),
            "Category 1" : ((detail != nil && detail?.categoryBreadcrumbs.count > 1) ? (detail!.categoryBreadcrumbs[1]["name"].string!) : ""),
            "Category 2" : ((detail != nil && detail?.categoryBreadcrumbs.count > 2) ? (detail!.categoryBreadcrumbs[2]["name"].string!) : ""),
            "Category 3" : ((detail != nil && detail?.categoryBreadcrumbs.count > 3) ? (detail!.categoryBreadcrumbs[3]["name"].string!) : "")
        ]
        Mixpanel.trackEvent(MixpanelEvent.SharedProduct, properties: pt)
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKindOfClass(UICollectionView.classForCoder()) || touch.view!.tag == 1)
        {
            return false
        }
        
        return true
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

class ShareCell : UICollectionViewCell
{
    
    @IBOutlet var captionTitle : UILabel!
    @IBOutlet var captionIcon : UILabel!
    @IBOutlet var sectionIcon : UIView!
    
    override func awakeFromNib() {
        sectionIcon.layer.cornerRadius = sectionIcon.width/2
        sectionIcon.layer.masksToBounds = true
        sectionIcon.superview?.backgroundColor = UIColor.clearColor()
    }
}
