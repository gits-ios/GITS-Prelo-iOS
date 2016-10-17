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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


struct PreloShareItem
{
    var image : UIImage?
    var text : String?
    var url : URL?
    var permalink : String?
    var price : String?
}

struct PreloShareAgent
{
    var title : String = ""
    var icon : String = ""
    var font : UIFont = AppFont.prelo2.getFont!
    var background : UIColor = UIColor.white
    var availibility : Bool = false
}

class PreloShareController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIDocumentInteractionControllerDelegate, UIGestureRecognizerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, PathLoginDelegate
{

    static var sharer : PreloShareController = PreloShareController()
    
    static func Share(_ item : PreloShareItem, inView:UIView)
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
    
    static func Share(_ item : PreloShareItem, inView : UIView, detail : ProductDetail?)
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
        //Mixpanel.trackPageVisit(PageName.ProductDetailShare, otherParam: p)
        
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
    
    override func viewDidAppear(_ animated: Bool) {
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
        
//        let url = NSURL(string : "")
//        let x = UIApplication.sharedApplication().canOpenURL(NSURL(string:"")!)
        agents.append(PreloShareAgent(title: "Instagram", icon: "", font: AppFont.prelo2.getFont!, background: UIColor.brown, availibility: UIApplication.shared.canOpenURL(URL(string:"instagram://app")!)))
        agents.append(PreloShareAgent(title: "Facebook", icon: "", font: AppFont.prelo2.getFont!, background: UIColor(hexString: "#3b5998"), availibility: UIApplication.shared.canOpenURL(URL(string:"fb://")!)))
        agents.append(PreloShareAgent(title: "Twitter", icon: "", font: AppFont.prelo2.getFont!, background: UIColor(hexString: "#00aced"), availibility: UIApplication.shared.canOpenURL(URL(string:"twitter://timeline")!)))
        agents.append(PreloShareAgent(title: "Path", icon: "", font: AppFont.prelo2.getFont!, background: UIColor(hexString: "#cb2027"), availibility: true))
        agents.append(PreloShareAgent(title: "Whatsapp", icon: "", font: AppFont.prelo2.getFont!, background: UIColor(hexString: "#4dc247"), availibility: UIApplication.shared.canOpenURL(URL(string:"whatsapp://app")!)))
        agents.append(PreloShareAgent(title: "Line", icon: "", font: AppFont.prelo2.getFont!, background: UIColor(hexString: "#4dc247"), availibility: Line.isLineInstalled()))
        agents.append(PreloShareAgent(title: "Salin", icon: "", font: AppFont.preloAwesome.getFont!, background: UIColor.darkGray, availibility: UIApplication.shared.canOpenURL(URL(string:"instagram://app")!)))
        agents.append(PreloShareAgent(title: "SMS", icon: "", font: AppFont.preloAwesome.getFont!, background: UIColor.darkGray, availibility: MFMessageComposeViewController.canSendText()))
        agents.append(PreloShareAgent(title: "E-mail", icon: "", font: AppFont.preloAwesome.getFont!, background: UIColor.darkGray, availibility: MFMailComposeViewController.canSendMail()))
        
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
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
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
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.view.backgroundColor = UIColor(white: 0.5, alpha: 0)
            self.gridView.layoutIfNeeded()
            }, completion: {s in
                if (s)
                {
                    self.view.removeFromSuperview()
                }
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return agents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let s = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ShareCell
        
        let a = agents[(indexPath as NSIndexPath).item]
        
        if (a.availibility == false)
        {
            s.sectionIcon.backgroundColor = UIColor.lightGray
        } else {
            s.sectionIcon.backgroundColor = a.background
        }
        
        s.captionIcon.font = a.font
        s.captionIcon.text = a.icon
        s.captionTitle.text = a.title
        
        return s
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (UIScreen.main.bounds.width/3)-4, height: 84)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let a = agents[(indexPath as NSIndexPath).item]
        
        if (a.availibility == false)
        {
            return
        }
        
        print(item?.url)
        print(item?.text)
        
        let _ = request(Method.GET, (item?.url?.absoluteString)!).validate().response{ req, res, data, error in
            if let imgData = data
            {
                let i = UIImage(data: imgData)
                self.share(a, img: i!)
            }
        }
    }
    
    func loginPath()
    {
        let pathLoginVC = Bundle.main.loadNibNamed(Tags.XibNamePathLogin, owner: nil, options: nil)?.first as! PathLoginViewController
        pathLoginVC.delegate = self
        pathLoginVC.standAlone = true
        let n = UINavigationController(rootViewController: pathLoginVC)
        self.present(n, animated: true, completion: nil)
    }
    
    func pathLoginSuccess(_ userData: JSON, token: String) {
        registerPathToken(userData, token : token)
        postToPath(pathImage!, token: token)
    }
    
    func postToPath(_ image : UIImage, token : String)
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
        AppToolsObjC.pathPostPhoto(image, param: ["private":true, "caption":(item?.text)!], token: token, success: {_, _ in
            a.dismiss(withClickedButtonIndex: 0, animated: true)
            self.hide()
            }, failure: nil)
    }
    
    func hideLoading() {
        
    }
    
    func registerPathToken(_ userData : JSON, token : String)
    {
//        let pathId = userData["id"].string!
        let pathName = userData["name"].string!
//        let email = userData["email"].string!
        //let profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        
        self.mixpanelSharedProduct("Path", username: pathName)
        
        /* FIXME: Sementara dijadiin komentar, soalnya kalo user lagi ga login terus share product via path, harusnya ga usah APIAuth.LoginPath ga sih
        // API Migrasi
        let _ = request(APIAuth.LoginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON {req, resp, res, err in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Path")) {
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
    func share(_ a : PreloShareAgent, img : UIImage)
    {
        var image = img
        image = image.putPreloWatermark(withUsername: "@" + (detail?.json["_data"]["seller"]["username"].stringValue)!)!
        
        if (a.title.lowercased() == "instagram")
        {
            UIPasteboard.general.string = "Temukan barang bekas berkualitas, \(item!.text!) di Prelo hanya dengan harga \(item!.price!). Nikmati mudahnya jual-beli barang bekas berkualitas dengan aman dari ponselmu. Download aplikasinya sekarang juga di http://prelo.co.id #PreloID"
            Constant.showDialog("Text sudah disalin ke clipboard", message: "Silakan paste sebagai deskripsi post Instagram kamu")
            mgInstagram = MGInstagram()
            mgInstagram?.post(image, withCaption: self.textToShare1, in: self.view, delegate: self)
            self.mixpanelSharedProduct("Instagram", username: "")
        }
        
        if (a.title.lowercased() == "path")
        {
            pathImage = image
            if (CDUser.pathTokenAvailable())
            {
                postToPath(image, token: UserDefaults.standard.string(forKey: "pathtoken")!)
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
        
        if (a.title.lowercased() == "whatsapp")
        {
            var message = ""
            var name = ""
            if let n = item!.text
            {
                name = n.replacingOccurrences(of: " ", with: "-")
            }
            message = "Temukan barang bekas berkualitas, \(name) hanya dengan harga \(item!.price!). Jangan sampai kehabisan, beli sekarang juga di Prelo! \(item!.permalink!)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
            
            let url = URL(string : "whatsapp://send?text="+message)
            UIApplication.shared.openURL(url!)
            self.mixpanelSharedProduct("Whatsapp", username: "")
        }
        
        if (a.title.lowercased() == "salin")
        {
            var name = ""
            if let n = item!.text
            {
                name = n.replacingOccurrences(of: " ", with: "-")
            }
            name = "Temukan barang bekas berkualitas, \(name) hanya dengan harga \(item!.price!). Jangan sampai kehabisan, beli sekarang juga di Prelo! \(item!.permalink!)"
            UIPasteboard.general.string = name
            UIAlertView.SimpleShow("", message: "Sukses disalin")
            
            self.mixpanelSharedProduct("Copy Info", username: "")
        }
        
        if (a.title.lowercased() == "sms")
        {
            var message = item!.text!
            var name = ""
            if let n = item!.text
            {
                name = n.replacingOccurrences(of: " ", with: "-")
            }
            message = "Temukan barang bekas berkualitas, \(name) hanya dengan harga \(item!.price!). Jangan sampai kehabisan, beli sekarang juga di Prelo! \(item!.permalink!)"
            let composer = MFMessageComposeViewController()
            composer.body = message
            composer.messageComposeDelegate = self
            
            self.present(composer, animated: true, completion: nil)
            
            self.mixpanelSharedProduct("SMS", username: "")
        }
        
        if (a.title.lowercased() == "e-mail")
        {
            var message = item!.text!
            var name = ""
            if let n = item!.text
            {
                name = n.replacingOccurrences(of: " ", with: "-")
            }
            message = "Hai!\n\nKamu bisa dapatkan barang bekas berkualitas, \(name) hanya dengan harga \(item!.price!).\nInfo selengkapnya mengenai kondisi barang bisa kamu cari tahu di \(item!.permalink!).\nNikmati mudahnya jual-beli barang bekas berkualitas dengan aman di Prelo. Dapatkan juga beragam keuntungan dengan aplikasi Prelo di ponsel kamu.\nDownload Prelo sekarang di http://prelo.co.id\nCheers!"
            let composer = MFMailComposeViewController()
            if (MFMailComposeViewController.canSendMail()) {
                composer.setMessageBody(message, isHTML: false)
                composer.mailComposeDelegate = self
                
                self.present(composer, animated: true, completion: nil)
                
                self.mixpanelSharedProduct("Email", username: "")
            } else {
                Constant.showDialog("No Active E-mail", message: "Untuk dapat membagi barang melalui e-mail, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
            }
        }
        
        if (a.title.lowercased() == "line")
        {
            var message = item!.text!
            var name = ""
            if let n = item!.text
            {
                name = n.replacingOccurrences(of: " ", with: "-")
            }
            message = "Temukan barang bekas berkualitas, \(name) hanya dengan harga \(item!.price!). Jangan sampai kehabisan, beli sekarang juga di Prelo! \(item!.permalink!)"
            Line.shareText(message)
            self.mixpanelSharedProduct("Line", username: "")
        }
        
        if (a.title.lowercased() == "facebook" || a.title.lowercased() == "twitter")
        {
            let type = a.title.lowercased() == "facebook" ? SLServiceTypeFacebook : SLServiceTypeTwitter
            
            if (SLComposeViewController.isAvailable(forServiceType: type))
            {
                let url = URL(string:"\(item!.permalink!)")
                let composer = SLComposeViewController(forServiceType: type)
                composer?.add(url!)
                composer?.add(image)
                if (type == SLServiceTypeFacebook) {
                    composer?.setInitialText("Dapatkan barang bekas berkualitas, \(item!.text!) seharga Rp\(item!.price!) #PreloID")
                } else if (type == SLServiceTypeTwitter) {
                    composer?.setInitialText("Dapatkan barang bekas berkualitas, \(item!.text!) seharga Rp\(item!.price!) #PreloID")
                }
                composer?.completionHandler = { result -> Void in
                    let getResult = result as SLComposeViewControllerResult
                    switch(getResult.rawValue) {
                    case SLComposeViewControllerResult.cancelled.rawValue:
                        print("Cancelled")
                    case SLComposeViewControllerResult.done.rawValue:
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
                self.present(composer!, animated: true, completion: nil)
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
    
    func mixpanelSharedProduct(_ socmed : String, username : String) {
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
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UICollectionView.classForCoder()) || touch.view!.tag == 1)
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
        sectionIcon.superview?.backgroundColor = UIColor.clear
    }
}
