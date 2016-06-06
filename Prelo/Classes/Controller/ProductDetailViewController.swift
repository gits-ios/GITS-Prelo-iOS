//
//  ProductDetailViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/13/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CoreData
//import FMMosaicLayout
//import ZSWTappableLabel
import MessageUI
import Social

protocol ProductCellDelegate
{
    func cellTappedCategory(categoryName : String, categoryID : String)
    func cellTappedBrand(brandId : String, brandName : String)
}

class ProductDetailViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, ProductCellDelegate, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, UserRelatedDelegate
{
    
    var product : Product?
    var detail : ProductDetail?
    
    var alreadyInCart : Bool = false
    
    @IBOutlet var tableView : UITableView?
    @IBOutlet var btnAddDiscussion : UIButton?
    @IBOutlet var btnBuy : UIButton!
    @IBOutlet var btnTawar : BorderedButton!
    @IBOutlet var btnUp: BorderedButton!
    @IBOutlet var btnSold: UIButton!
    @IBOutlet var btnEdit : UIButton!
    @IBOutlet var vwCoachmark: UIView!
    @IBOutlet var vwCoachmarkReserve: UIView!
    
    @IBOutlet weak var konfirmasiBayarBtnSet: UIView!
    @IBOutlet weak var tpDetailBtnSet: UIView!
    
    @IBOutlet weak var reservationBtnSet: UIView!
    @IBOutlet weak var btnReservation: BorderedButton!
    
    var pDetailCover : ProductDetailCover?
    
    var cellTitle : ProductCellTitle?
    var cellSeller : ProductCellSeller?
    var cellDesc : ProductCellDescription?
    
    @IBOutlet var loadingPanel: UIView!
    
    var activated = true
    
    let ProductStatusActive = 1
    let ProductStatusReserved = 7
    
    var mgInstagram : MGInstagram?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = UIImage(named: "ic_chat")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        self.btnAddDiscussion?.addTarget(self, action: #selector(ProductDetailViewController.segAddComment(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        btnBuy.hidden = true
        btnTawar.hidden = true
        
        btnAddDiscussion?.layer.cornerRadius = 4
        btnAddDiscussion?.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnAddDiscussion?.layer.borderWidth = 1
        
        let btnClose = self.createButtonWithIcon(AppFont.Prelo2, icon: "")
        btnClose.addTarget(self, action: #selector(ProductDetailViewController.dismiss(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        tableView?.contentInset = UIEdgeInsetsMake(0, 0, 44, 0)
        
        let btnOption = self.createButtonWithIcon(AppFont.Prelo2, icon: "")
        btnOption.addTarget(self, action: #selector(ProductDetailViewController.option), forControlEvents: UIControlEvents.TouchUpInside)
        self.navigationItem.rightBarButtonItem = btnOption.toBarButton()
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        if (detail == nil) {
            getDetail()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.title = product?.name
        
        if (self.detail) != nil
        {
            if (CartProduct.isExist((detail?.productID)!, email : User.EmailOrEmptyString)) {
                alreadyInCart = true
            } else {
                alreadyInCart = false
            }
        }
        
        if (self.navigationController != nil) {
            if ((self.navigationController?.navigationBarHidden)! == true)
            {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }
        }
        
        if (UIApplication.sharedApplication().statusBarHidden)
        {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
        }
        
        let p = [
            "Product" : ((product != nil) ? (product!.name) : ""),
            "Product ID" : ((product != nil) ? (product!.id) : ""),
            "Category 1" : ((detail != nil && detail?.categoryBreadcrumbs.count > 1) ? (detail!.categoryBreadcrumbs[1]["name"].string!) : ""),
            "Category 2" : ((detail != nil && detail?.categoryBreadcrumbs.count > 2) ? (detail!.categoryBreadcrumbs[2]["name"].string!) : ""),
            "Category 3" : ((detail != nil && detail?.categoryBreadcrumbs.count > 3) ? (detail!.categoryBreadcrumbs[3]["name"].string!) : ""),
            "Seller" : ((detail != nil) ? (detail!.theirName) : "")
        ]
        if (detail != nil && detail!.isMyProduct == true) {
            // Mixpanel
            Mixpanel.trackPageVisit(PageName.ProductDetailMine, otherParam: p)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.ProductDetailMine)
        } else {
            // Mixpanel
            Mixpanel.trackPageVisit(PageName.ProductDetail, otherParam: p)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.ProductDetail)
        }
        
        // Remove redirect alert if any
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let redirAlert = appDelegate.redirAlert {
            redirAlert.dismissWithClickedButtonIndex(-1, animated: true)
        }
    }
    
    func option()
    {
        let a = UIActionSheet(title: "Option", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: "Cancel")
        a.addButtonWithTitle("Report")
        a.showInView(self.view)
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == 1)
        {
            guard let pDetail = detail else {
                return
            }
            var username = "Your beloved user"
            if let u = CDUser.getOne() {
                username = u.username
            }
            
            // report
            let msgBody = "Dear Prelo,<br/><br/>Saya ingin melaporkan barang \(pDetail.name) dari penjual \(pDetail.theirName)<br/><br/>Alasan pelaporan: <br/><br/>Terima kasih Prelo <3<br/><br/>--<br/>\(username)<br/>Sent from Prelo iOS"
            
            let m = MFMailComposeViewController()
            if (MFMailComposeViewController.canSendMail()) {
                m.setToRecipients(["contact@prelo.id"])
                m.setSubject("Laporan Baru untuk Barang " + (detail?.name)!)
                m.setMessageBody(msgBody, isHTML: true)
                m.mailComposeDelegate = self
                self.presentViewController(m, animated: true, completion: nil)
            } else {
                Constant.showDialog("No Active E-mail", message: "Untuk dapat mengirim Report, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
            }
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func getDetail()
    {
        self.showLoading()
        // API Migrasi
        request(APIProduct.Detail(productId: (product?.json)!["_id"].string!, forEdit: 0))
            .responseJSON {resp in
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Detail Barang"))
                {
                    self.detail = ProductDetail.instance(JSON(resp.result.value!))
                    self.activated = (self.detail?.isActive)!
                    self.adjustButtonIfBoughtOrDeleted()
                    print(self.detail?.json)
                    self.tableView?.dataSource = self
                    self.tableView?.delegate = self
                    self.tableView?.hidden = false
                    self.tableView?.reloadData()
                    self.setupView()
                } else {
                    
                }
                self.hideLoading()
        }
    }
    
    func adjustButtonIfBoughtOrDeleted()
    {
        if (self.detail?.status == 3 || self.detail?.status == 4) { // If product is sold or deleted
            self.btnTawar.borderColor = Theme.GrayLight
            self.btnTawar.titleLabel?.textColor = Theme.GrayLight
            self.btnTawar.userInteractionEnabled = false
            
            self.disableButton(self.btnBuy)
            self.disableMyProductBtnSet()
            
            if (self.detail?.status == 4) {
                if (self.detail?.boughtByMe == true) {
                    self.btnTawar.hidden = true
                    self.btnBuy.hidden = true
                    if (self.detail?.transactionProgress == 1 || self.detail?.transactionProgress == 2) {
                        // Tampilkan button konfirmasi bayar
                        self.konfirmasiBayarBtnSet.hidden = false
                    } else if (self.detail?.transactionProgress > 2) {
                        // Tampilkan button transaction product detail
                        self.tpDetailBtnSet.hidden = false
                    }
                }
            }
        }
    }
    
    func disableMyProductBtnSet() {
        self.disableButton(self.btnUp)
        self.disableButton(self.btnSold)
        self.disableButton(self.btnEdit)
    }
    
    func disableButton(btn : UIButton) {
        btn.setBackgroundImage(nil, forState: .Normal)
        btn.backgroundColor = nil
        btn.setTitleColor(Theme.GrayLight)
        btn.layer.borderColor = Theme.GrayLight.CGColor
        btn.layer.borderWidth = 1
        btn.layer.cornerRadius = 1
        btn.layer.masksToBounds = true
        btn.userInteractionEnabled = false
    }
    
    func setupView()
    {
        if (self.detail == nil)
        {
            return
        }
        pDetailCover = ProductDetailCover.instance((detail?.displayPicturers)!, status: (detail?.status)!, topBannerText: (detail?.rejectionText))
        pDetailCover?.parent = self
        pDetailCover?.largeImageURLS = (detail?.originalPicturers)!
        if let labels = detail?.imageLabels
        {
            pDetailCover?.labels = labels
        }
        pDetailCover?.height = UIScreen.mainScreen().bounds.size.width * 340 / 480
        tableView?.tableHeaderView = pDetailCover
        
        if (detail?.json["_data"]["price"].int?.asPrice) != nil
        {
//            captionPrice.text = price
        } else {
//            captionPrice.text = Int(0).asPrice
        }
        
        if (CartProduct.isExist((detail?.productID)!, email : User.EmailOrEmptyString)) {
            alreadyInCart = true
        }
        
//        let freeOngkir = (detail?.json["_data"]["is_free_ongkir"].bool)!
        let freeOngkir = false
        if (freeOngkir)
        {
//            captionFreeOngkir.text = "FREE ONGKIR"
        } else
        {
//            captionFreeOngkir.text = "+ ONGKIR"
        }
        
        if let arr = detail?.json["_data"]["category_breadcrumbs"].array
        {
            if let id = detail?.productID
            {
                if let catName = arr.last?["name"].string
                {
                    if let price = detail?.json["_data"]["price"].int
                    {
                        ACTRemarketingReporter.reportWithConversionID("953474992", customParameters: ["dynx_itemid":id, "dynx_pagetype":catName, "dynx_totalvalue":price])
                    }
                }
            }
        }
        
        // Button arrangement
        if (detail!.isGarageSale) {
            reservationBtnSet.hidden = false
            if (detail!.status == 1) { // Product is available
                self.setBtnReservationToEnabled()
            } else if (detail!.status == 7) { // Product is reserved
                if (detail!.boughtByMe) {
                    self.setBtnReservationToCancel()
                } else {
                    self.setBtnReservationToDisabled()
                }
            }
        } else {
            reservationBtnSet.hidden = true
            
            if ((detail?.isMyProduct)! == true)
            {
//            if let b : UIButton = self.view.viewWithTag(12) as? UIButton
//            {
//                b.hidden = false
//                b.titleLabel?.font = AppFont.PreloAwesome.getFont(15)
//                b.setTitle(" EDIT", forState: UIControlState.Normal)
//            }
                self.btnBuy.hidden = true
                self.btnTawar.hidden = true
                btnEdit.hidden = false
                btnUp.hidden = false
                btnSold.hidden = false
                btnSold.superview?.hidden = false
            }
            else
            {
                btnBuy.hidden = false
                btnTawar.hidden = false
            }
            
            self.btnTawar.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
            self.btnTawar.addTarget(self, action: #selector(ProductDetailViewController.tawar(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        }
        
        // Coachmark
        if (detail!.isGarageSale) {
            let coachmarkReserveDone : Bool? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.CoachmarkReserveDone) as! Bool?
            if (coachmarkReserveDone != true) {
                NSUserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.CoachmarkReserveDone)
                vwCoachmarkReserve.backgroundColor = UIColor.colorWithColor(UIColor.blackColor(), alpha: 0.7)
                vwCoachmarkReserve.hidden = false
            }
        } else {
            let coachmarkDone : Bool? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.CoachmarkProductDetailDone) as! Bool?
            if (coachmarkDone != true) {
                NSUserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.CoachmarkProductDetailDone)
                vwCoachmark.backgroundColor = UIColor.colorWithColor(UIColor.blackColor(), alpha: 0.7)
                vwCoachmark.hidden = false
            }
        }
    }

    @IBAction func dismiss(sender: AnyObject)
    {
        dismissViewControllerAnimated(YES, completion: nil)
    }
    
    // MARK: - Instagram
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerDidEndPreview(controller: UIDocumentInteractionController) {
        print("DidEndPreview")
    }
    
    // MARK: - Facebook
    
    func postShareCommissionFacebook() {
        request(Products.ShareCommission(pId: (self.detail?.productID)!, instagram: "0", path: "0", facebook: "1", twitter: "0")).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Share Facebook")) {
                self.cellTitle?.sharedViaFacebook()
                self.detail?.setSharedViaFacebook()
            }
            self.hideLoading()
        }
    }
    
    // MARK: - Twitter
    func postShareCommissionTwitter() {
        request(Products.ShareCommission(pId: (self.detail?.productID)!, instagram: "0", path: "0", facebook: "0", twitter: "1")).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Share Twitter")) {
                self.cellTitle?.sharedViaTwitter()
                self.detail?.setSharedViaTwitter()
            }
            self.hideLoading()
        }
    }
    
    // MARK: - Tableview
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 3
        } else {
            return 0+(detail?.discussions?.count)!
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 1+(((detail?.discussions?.count)! == 0) ? 0 : 1)
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                if (cellTitle == nil) {
                    cellTitle = tableView.dequeueReusableCellWithIdentifier("cell_title") as? ProductCellTitle
                }
                cellTitle?.parent = self
                cellTitle?.product = self.product
                cellTitle?.adapt(detail)
                
                // Share socmed
                var textToShare = ""
                if let dtl = detail {
                    textToShare = "Temukan barang bekas berkualitas-ku, \(dtl.name) di Prelo hanya dengan harga \(dtl.price). Nikmati mudahnya jual-beli barang bekas berkualitas dengan aman dari ponselmu. Download aplikasinya sekarang juga di http://prelo.co.id #PreloID"
                }
                cellTitle?.shareInstagram = {
                    self.showLoading()
                    if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "instagram://app")!)) {
                        UIPasteboard.generalPasteboard().string = textToShare
                        Constant.showDialog("Text sudah disalin ke clipboard", message: "Silakan paste sebagai deskripsi post Instagram kamu")
                        self.mgInstagram = MGInstagram()
                        if let imgUrl = self.detail?.productImage {
                            let imgData = NSData(contentsOfURL: imgUrl)
                            let img = UIImage(data: imgData!)
                            self.mgInstagram?.postImage(img, withCaption: textToShare, inView: self.view, delegate: self)
                            request(Products.ShareCommission(pId: (self.detail?.productID)!, instagram: "1", path: "0", facebook: "0", twitter: "0")).responseJSON { resp in
                                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Share Instagram")) {
                                    self.cellTitle?.sharedViaInstagram()
                                    self.detail?.setSharedViaInstagram()
                                }
                                self.hideLoading()
                            }
                        } else {
                            self.hideLoading()
                        }
                    } else {
                        Constant.showDialog("No Instagram app", message: "Silakan install Instagram dari app store terlebih dahulu")
                        self.hideLoading()
                    }
                }
                cellTitle?.shareFacebook = {
                    self.showLoading()
                    
                    if (FBSDKAccessToken.currentAccessToken() != nil && FBSDKAccessToken.currentAccessToken().permissions.contains("publish_actions")) {
                        self.postShareCommissionFacebook()
                    } else {
                        let p = ["sender" : self]
                        LoginViewController.LoginWithFacebook(p, onFinish: { result in
                            // Handle Profile Photo URL String
                            let userId = result["id"] as? String
                            let name = result["name"] as? String
                            let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                            
                            print("result = \(result)")
                            print("accessToken = \(accessToken)")
                            
                            // userId & name is required
                            if (userId != nil && name != nil) {
                                // API Migrasi
                                request(APISocial.PostFacebookData(id: userId!, username: name!, token: accessToken)).responseJSON { resp in
                                    if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Login Facebook")) {
                                        
                                        // Save in core data
                                        if let userOther : CDUserOther = CDUserOther.getOne() {
                                            userOther.fbID = userId
                                            userOther.fbUsername = name
                                            userOther.fbAccessToken = accessToken
                                            UIApplication.appDelegate.saveContext()
                                        }
                                        
                                        self.postShareCommissionFacebook()
                                    } else {
                                        LoginViewController.LoginFacebookCancelled(self, reason: "Terdapat kesalahan saat menyimpan data Facebook")
                                    }
                                }
                            } else {
                                LoginViewController.LoginFacebookCancelled(self, reason: "Terdapat kesalahan data saat login Facebook")
                            }
                        })
                    }
                }
                cellTitle?.shareTwitter = {
                    self.showLoading()
                    
                    if (User.IsLoggedInTwitter) {
                        self.postShareCommissionTwitter()
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
                            
                            request(APISocial.PostTwitterData(id: twId, username: twUsername, token: twToken, secret: twSecret)).responseJSON { resp in
                                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Login Twitter")) {
                                    
                                    // Save in core data
                                    if let userOther : CDUserOther = CDUserOther.getOne() {
                                        userOther.twitterID = twId
                                        userOther.twitterUsername = twUsername
                                        userOther.twitterAccessToken = twToken
                                        userOther.twitterTokenSecret = twSecret
                                        UIApplication.appDelegate.saveContext()
                                    }
                                    
                                    self.postShareCommissionTwitter()
                                } else {
                                    LoginViewController.LoginTwitterCancelled(self, reason: "Terdapat kesalahan saat menyimpan data Twitter")
                                }
                            }
                        })
                    }
                }
                return cellTitle!
            } else if (indexPath.row == 1) {
                if (cellSeller == nil) {
                    cellSeller = tableView.dequeueReusableCellWithIdentifier("cell_seller") as? ProductCellSeller
                }
                cellSeller?.adapt(detail)
                return cellSeller!
            } else {
                if (cellDesc == nil) {
                    cellDesc = tableView.dequeueReusableCellWithIdentifier("cell_desc") as? ProductCellDescription
                    cellDesc?.cellDelegate = self
                }
                cellDesc?.adapt(detail)
                return cellDesc!
            }
        } else {
            let cell : ProductCellDiscussion = (tableView.dequeueReusableCellWithIdentifier("cell_disc_1") as? ProductCellDiscussion)!
            cell.adapt(detail?.discussions?.objectAtCircleIndex(indexPath.row-3))
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (section == 0) {
            return nil
        } else {
            let l = UILabel()
            l.numberOfLines = 1
            l.textColor = UIColor.lightGrayColor()
            l.backgroundColor = UIColor.clearColor()
            l.text = "KOMENTAR"
            l.font = UIFont.boldSystemFontOfSize(14)
            l.sizeToFit()
            let v = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 40))
            v.backgroundColor = UIColor.whiteColor()
            v.addSubview(l)
            l.x = 8
            l.y = (40-l.height)/2
            return v
        }
        
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == 0) {
            return 0
        } else {
            return 40
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                return ProductCellTitle.heightFor(detail)
            } else if (indexPath.row == 1) {
                return ProductCellSeller.heightFor(detail?.json)
            } else {
                return ProductCellDescription.heightFor(detail)
            }
        } else {
            return ProductCellDiscussion.heightFor(detail?.discussions?.objectAtCircleIndex(indexPath.row-3))
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == 1)
        {
            let d = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
            d.storeMode = true
            if let name = detail?.json["_data"]["seller"]["username"].string
            {
                d.storeName = name
            }
            
            if let name = detail?.json["_data"]["seller"]["_id"].string
            {
                d.storeId = name
            }
            
            if let name = detail?.json["_data"]["seller"]["pict"].string
            {
                d.storePictPath = name
            }
            
            self.navigationController?.pushViewController(d, animated: true)
        }
    }
    
    func cellTappedCategory(categoryName: String, categoryID: String) {
        let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        l.standalone = true
        l.standaloneCategoryName = categoryName
        l.standaloneCategoryID = categoryID
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    func cellTappedBrand(brandId: String, brandName: String) {
        let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        l.searchMode = true
        l.searchBrand = true
        l.searchBrandId = brandId
        l.searchKey = brandName
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    @IBAction func addToCart(sender: UIButton) {
        if (alreadyInCart) {
            self.performSegueWithIdentifier("segCart", sender: nil)
            return
        }
        
        if (CartProduct.newOne((detail?.productID)!, email : User.EmailOrEmptyString, name : (detail?.name)!) == nil) {
            Constant.showDialog("Failed", message: "Gagal Menyimpan")
        } else {
            setupView()
            self.performSegueWithIdentifier("segCart", sender: nil)
        }
    }
    
    @IBAction func upPressed(sender: AnyObject) {
        self.showLoading()
        if let productId = detail?.productID {
            request(APIProduct.Push(productId: productId)).responseJSON { resp in
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Up Barang")) {
                    let json = JSON(resp.result.value!)
                    let isSuccess = json["_data"]["result"].boolValue
                    let message = json["_data"]["message"].stringValue
                    if (isSuccess) {
                        Constant.showDialog("Success", message: message)
                    } else {
                        Constant.showDialog("Failed", message: message)
                    }
                }
                self.hideLoading()
            }
        }
    }
    
    @IBAction func soldPressed(sender: AnyObject) {
        let alert : UIAlertController = UIAlertController(title: "Mark As Sold", message: "Apakah barang ini sudah terjual di tempat lain? (Aksi ini tidak bisa dibatalkan)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Tidak", style: .Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Ya", style: .Default, handler: { action in
            self.showLoading()
            if let productId = self.detail?.productID {
                request(APIProduct.MarkAsSold(productId: productId)).responseJSON { resp in
                    if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Mark As Sold")) {
                        let json = JSON(resp.result.value!)
                        let isSuccess = json["_data"].boolValue
                        if (isSuccess) {
                            self.disableMyProductBtnSet()
                            self.pDetailCover?.addSoldBanner()
                            Constant.showDialog("Success", message: "Barang telah ditandai sebagai barang terjual")
                        } else {
                            Constant.showDialog("Failed", message: "Oops, terdapat kesalahan")
                        }
                    }
                    self.hideLoading()
                }
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func editPressed(sender: AnyObject) {
        self.showLoading()
        let a = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        a.editMode = true
        a.editDoneBlock = {
            self.tableView?.hidden = true
            self.getDetail()
        }
        // API Migrasi
        request(APIProduct.Detail(productId: detail!.productID, forEdit: 1)).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Detail Barang")) {
                a.editProduct = ProductDetail.instance(JSON(resp.result.value!))
                self.hideLoading()
                self.navigationController?.pushViewController(a, animated: true)
            }
        }
    }
    
    @IBAction func tawar(sender : UIView)
    {
        if let d = self.detail
        {
            let t = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdTawar) as! TawarViewController
            t.tawarItem = d
            t.loadInboxFirst = true
            t.prodId = d.productID
            self.navigationController?.pushViewController(t, animated: true)
        }
    }
    
    var loginComment = false
    @IBAction func segAddComment(sender : UIView?)
    {
        if (User.IsLoggedIn == false)
        {
            loginComment = true
            LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
        } else
        {
            self.performSegueWithIdentifier("segAddComment", sender: nil)
        }
    }
    
    func userCancelLogin() {
        
    }
    
    func userLoggedIn() {
        if (loginComment)
        {
            self.performSegueWithIdentifier("segAddComment", sender: nil)
        }
    }
    
    func userLoggedOut() {
        
    }
    
    // MARK: - Coachmark
    
    @IBAction func coachmarkTapped(sender: AnyObject) {
        self.vwCoachmark.hidden = true
        self.vwCoachmarkReserve.hidden = true
    }
    
    // MARK: - Reservation
    
    @IBAction func btnReservationPressed(sender: AnyObject) {
        if (detail != nil) {
            if (detail!.status == ProductStatusActive) { // Product is available
                // Reserve product
                self.setBtnReservationToLoading()
                // API Migrasi
                request(APIGarageSale.CreateReservation(productId: detail!.productID)).responseJSON {resp in
                    if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Create Reservation")) {
                        let json = JSON(resp.result.value!)
                        let data = json["_data"]
                        if let tpId = data["transaction_product_id"].string {
                            self.detail!.setStatus(self.ProductStatusReserved)
                            self.detail!.setBoughtByMe(true)
                            self.pDetailCover?.updateStatus(self.ProductStatusReserved)
                            self.setBtnReservationToCancel()
                            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            let transactionDetailVC : TransactionDetailViewController = (mainStoryboard.instantiateViewControllerWithIdentifier("TransactionDetail") as? TransactionDetailViewController)!
                            transactionDetailVC.trxProductId = tpId
                            transactionDetailVC.isSeller = false
                            self.navigationController?.pushViewController(transactionDetailVC, animated: true)
                        }
                    } else {
                        self.setBtnReservationToEnabled()
                        if (resp.result.value != nil) {
                            if let msg = JSON(resp.result.value!)["_message"].string {
                                if (msg == "server error: Produk sudah dipesan") {
                                    self.detail!.setStatus(self.ProductStatusReserved)
                                    self.detail!.setBoughtByMe(false)
                                    self.pDetailCover?.updateStatus(self.ProductStatusReserved)
                                    self.setBtnReservationToDisabled()
                                }
                            }
                        }
                    }
                }
            } else if (detail!.status == ProductStatusReserved) { // Product is reserved
                if (detail!.boughtByMe) {
                    // Cancel reservation
                    self.setBtnReservationToLoading()
                    // API Migrasi
                    request(APIGarageSale.CancelReservation(productId: detail!.productID)).responseJSON {resp in
                        if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Cancel Reservation")) {
                            let json = JSON(resp.result.value!)
                            if let success = json["_data"].bool {
                                if (success) {
                                    self.detail!.setStatus(self.ProductStatusActive)
                                    self.detail!.setBoughtByMe(false)
                                    self.pDetailCover?.updateStatus(self.ProductStatusActive)
                                    self.setBtnReservationToEnabled()
                                    Constant.showDialog("Cancellation Success", message: "Reservasi barang ini telah kamu batalkan")
                                } else {
                                    self.setBtnReservationToCancel()
                                    Constant.showDialog("Cancel Reservation", message: "Terdapat kesalahan saat melakukan pembatalan reservasi, silahkan coba kembali")
                                }
                            } else {
                                self.setBtnReservationToCancel()
                                Constant.showDialog("Cancel Reservation", message: "Terdapat kesalahan saat melakukan pembatalan reservasi, silahkan coba kembali")
                            }
                        } else {
                            self.setBtnReservationToCancel()
                        }
                    }
                }
            }
        }
    }
    
    func setBtnReservationToLoading() {
        btnReservation.cornerRadius = 0
        btnReservation.borderWidth = 0
        btnReservation.borderColor = UIColor.clearColor()
        btnReservation.backgroundColor = Theme.ThemeOrangeDark
        btnReservation.setTitle("LOADING...", forState: .Normal)
        btnReservation.userInteractionEnabled = false
    }
    
    func setBtnReservationToEnabled() {
        btnReservation.cornerRadius = 0
        btnReservation.borderWidth = 0
        btnReservation.borderColor = UIColor.clearColor()
        btnReservation.backgroundColor = Theme.ThemeOrange
        btnReservation.setTitle(" RESERVE", forState: .Normal)
        btnReservation.userInteractionEnabled = true
    }
    
    func setBtnReservationToCancel() {
        btnReservation.cornerRadius = 2.0
        btnReservation.borderWidth = 1.0
        btnReservation.borderColor = UIColor.whiteColor()
        btnReservation.backgroundColor = UIColor.clearColor()
        btnReservation.setTitle(" CANCEL RESERVATION", forState: .Normal)
        btnReservation.userInteractionEnabled = true
    }
    
    func setBtnReservationToDisabled() {
        btnReservation.cornerRadius = 0
        btnReservation.borderWidth = 0
        btnReservation.borderColor = UIColor.clearColor()
        btnReservation.backgroundColor = Theme.GrayLight
        btnReservation.setTitle(" RESERVE", forState: .Normal)
        btnReservation.userInteractionEnabled = false
    }
    
    // MARK: - If product is bought
    
    @IBAction func toPaymentConfirm(sender: AnyObject) {
        let paymentConfirmationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil).first as! PaymentConfirmationViewController
        self.navigationController?.pushViewController(paymentConfirmationVC, animated: true)
    }
    
    @IBAction func toTransactionProductDetail(sender: AnyObject) {
        let myPurchaseVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchase, owner: nil, options: nil).first as! MyPurchaseViewController
        self.navigationController?.pushViewController(myPurchaseVC, animated: true)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "segAddComment")
        {
            let c = segue.destinationViewController as! ProductCommentsController
            c.pDetail = self.detail
        } else
        {
            let c = segue.destinationViewController as! BaseViewController
            c.previousController = self
        }
    }
    
    // MARK: - Other functions

    func showLoading() {
        self.loadingPanel.hidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.hidden = true
    }
}

// MARK: - Class

class ProductCellTitle : UITableViewCell, UserRelatedDelegate
{
    @IBOutlet var captionTitle : UILabel?
    @IBOutlet var captionOldPrice : UILabel?
    @IBOutlet var captionPrice : UILabel?
    @IBOutlet var captionCountLove : UILabel?
    @IBOutlet var captionCountComment : UILabel?
    @IBOutlet var captionTotalViews: UILabel!
    
    @IBOutlet var sectionLove : UIView?
    @IBOutlet var sectionComment : UIView?
    @IBOutlet var sectionBrandReview : UIView?
    
    @IBOutlet var btnShare : UIButton?
    
    @IBOutlet var conWidthOngkir : NSLayoutConstraint!
    @IBOutlet var conMarginOngkir : NSLayoutConstraint!
    
    @IBOutlet var lblShareSocmed: UILabel!
    @IBOutlet var consHeightLblShareSocmed: NSLayoutConstraint!
    
    @IBOutlet var socmedBtnSet: UIView!
    @IBOutlet var lblsBtnInstagram: [UILabel]!
    @IBOutlet var btnInstagram: BorderedButton!
    @IBOutlet var lblsBtnFacebook: [UILabel]!
    @IBOutlet var btnFacebook: BorderedButton!
    @IBOutlet var lblsBtnTwitter: [UILabel]!
    @IBOutlet var btnTwitter: BorderedButton!
    @IBOutlet var consWidthSocmedBtns: [NSLayoutConstraint]!
    var shareInstagram : () -> () = {}
    var shareFacebook : () -> () = {}
    var shareTwitter : () -> () = {}
    var productProfit : Int = 90
    
    var parent : UIViewController?
    
    var product : Product?
    var detail : ProductDetail?
    
    static func heightFor(obj : ProductDetail?)->CGFloat
    {
        if (obj == nil) {
            return 110
        }
        var product = (obj?.json)!["_data"]
        
        let name = product["name"].string!
        let s = name.boundsWithFontSize(UIFont.boldSystemFontOfSize(16.5), width: UIScreen.mainScreen().bounds.size.width-74.0)
        
        var reviewHeight : CGFloat = 32.0
        if let brand_under_review = product["brand_under_review"].bool
        {
            if (brand_under_review == false)
            {
                reviewHeight = 0.0
            }
        }
        
        var lblShareHeight : CGFloat = 0
        if (obj!.isMyProduct) {
            lblShareHeight = 22
        }
        
        return CGFloat(99.0) + s.height + reviewHeight + lblShareHeight
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        btnShare?.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnShare?.layer.borderWidth = 1
        
        btnShare?.addTarget(self, action: #selector(ProductCellTitle.share), forControlEvents: UIControlEvents.TouchUpInside)
        
        sectionLove?.layer.borderColor = UIColor.lightGrayColor().CGColor
        sectionLove?.layer.borderWidth = 1
        sectionLove?.layer.cornerRadius = 2
        sectionLove?.layer.masksToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ProductCellTitle.love))
        sectionLove?.addGestureRecognizer(tap)
        
        sectionComment?.layer.borderColor = UIColor.lightGrayColor().CGColor
        sectionComment?.layer.borderWidth = 1
        sectionComment?.layer.cornerRadius = 2
        sectionComment?.layer.masksToBounds = true
        
        let tapcomment = UITapGestureRecognizer(target: self, action: #selector(ProductCellTitle.comment))
        sectionComment?.addGestureRecognizer(tapcomment)
        
        let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width
        for i in 0...consWidthSocmedBtns.count - 1 {
            consWidthSocmedBtns[i].constant = (screenWidth - 32) / 3
        }
    }
    
    func userLoggedIn() {
        // TODO: handle tombol socmed
        if (loving == true)
        {
            callApiLove()
            loving = false
        } else
        {
            self.parent?.performSegueWithIdentifier("segAddComment", sender: nil)
        }
    }
    
    func userCancelLogin() {
        
    }
    
    func userLoggedOut() {
        
    }
    
    func comment()
    {
        if (User.IsLoggedIn == false)
        {
            LoginViewController.Show(self.parent!, userRelatedDelegate: self, animated: true)
        } else
        {
            self.parent?.performSegueWithIdentifier("segAddComment", sender: nil)
        }
    }
    
    var isLoved = false
    var loving = false
    var loveCount = 0
    func love()
    {
        if (User.IsLoggedIn == false)
        {
            loving = true
            LoginViewController.Show(self.parent!, userRelatedDelegate: self, animated: true)
        } else {
            callApiLove()
        }
    }
    
    func callApiLove()
    {
        // Mixpanel
        let pt = [
            "Product Name" : ((product != nil) ? (product!.name) : ""),
            "Category 1" : ((detail != nil && detail?.categoryBreadcrumbs.count > 1) ? (detail!.categoryBreadcrumbs[1]["name"].string!) : ""),
            "Category 2" : ((detail != nil && detail?.categoryBreadcrumbs.count > 2) ? (detail!.categoryBreadcrumbs[2]["name"].string!) : ""),
            "Category 3" : ((detail != nil && detail?.categoryBreadcrumbs.count > 3) ? (detail!.categoryBreadcrumbs[3]["name"].string!) : ""),
            "Seller Name" : ((detail != nil) ? (detail!.theirName) : "")
        ]
        Mixpanel.trackEvent(MixpanelEvent.ToggledLikeProduct, properties: pt)
        
        if (isLoved)
        {
            callApiUnlove()
            return
        }
        isLoved = true
        loveCount+=1
        setupLoveView()
        // API Migrasi
        request(APIProduct.Love(productID: (detail?.productID)!)).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Love Product"))
            {
                if let s = self.captionCountLove?.text
                {
                    let ns = s as NSString
                    self.captionCountLove?.text = String(ns.integerValue + 1)
                }
            } else
            {
                self.isLoved = false
                self.setupLoveView()
            }
        }
    }
    
    func callApiUnlove()
    {
        isLoved = false
        loveCount-=1
        setupLoveView()
        // API Migrasi
        request(APIProduct.Unlove(productID: (detail?.productID)!)).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Unlove Product"))
            {
                if let s = self.captionCountLove?.text
                {
                    let ns = s as NSString
                    self.captionCountLove?.text = String(ns.integerValue - 1)
                }
            } else
            {
                self.isLoved = true
                self.setupLoveView()
            }
        }
    }
    
    func adapt(obj : ProductDetail?)
    {
        if (obj == nil) {
            return
        }
        
        var product = (obj?.json)!["_data"]
        if (detail == nil)
        {
            detail = obj
            isLoved = (product["love"].bool)!
            loveCount = product["num_lovelist"].int!
        }
        
        if let free_ongkir = product["free_ongkir"].int
        {
            if (free_ongkir == 0)
            {
                conWidthOngkir.constant = 0
//                conMarginOngkir.constant = 0
            }
        } else
        {
            conWidthOngkir.constant = 0
//            conMarginOngkir.constant = 0
        }
        
        captionTitle?.text = obj?.name
        if let tViews = obj?.totalViews {
            if (tViews < 1000) {
                captionTotalViews.text = " \(tViews)"
            } else if (tViews < 10000) {
                captionTotalViews.text = " \((tViews / 1000)),\((tViews % 1000) / 10)K"
            } else {
                captionTotalViews.text = " \((tViews / 1000))K+"
            }
        }
        if let oldPrice = product["price_original"].int?.asPrice
        {
            captionOldPrice?.text = oldPrice
        } else
        {
            captionOldPrice?.text = ""
        }
        
        if let price = product["price"].int?.asPrice
        {
            captionPrice?.text = price
        } else
        {
            captionPrice?.text = ""
        }
        
        if (isLoved)
        {
            setupLoveView()
        }
        captionCountLove?.text = String(loveCount)
        captionCountComment?.text = obj?.discussionCountText
        
        if let brand_under_review = product["brand_under_review"].bool
        {
            if (brand_under_review == false)
            {
                sectionBrandReview?.hidden = true
            }
        }
        
        // Socmed buttons
        if (detail!.isMyProduct) {
            self.consHeightLblShareSocmed.constant = 22
            
            self.sectionLove?.hidden = true
            self.sectionComment?.hidden = true
            self.btnShare?.hidden = true
            self.socmedBtnSet.hidden = false
            
            self.productProfit = 90
            self.setShareText()
            if (detail!.sharedViaInstagram) {
                self.sharedViaInstagram()
            }
            if (detail!.sharedViaFacebook) {
                self.sharedViaFacebook()
            }
            if (detail!.sharedViaTwitter) {
                self.sharedViaTwitter()
            }
        } else {
            self.consHeightLblShareSocmed.constant = 0
        }
    }
    
    func setShareText() {
        let txt = "Share utk keuntungan lebih, keuntungan sekarang: \(productProfit)%"
        let attTxt = NSMutableAttributedString(string: txt)
        attTxt.addAttributes([NSForegroundColorAttributeName: Theme.PrimaryColor], range: (txt as NSString).rangeOfString("\(productProfit)%"))
        self.lblShareSocmed.attributedText = attTxt
    }
    
    func sharedViaInstagram() {
        btnInstagram.borderColor = Theme.PrimaryColor
        btnInstagram.userInteractionEnabled = false
        for i in 0...lblsBtnInstagram.count - 1 {
            lblsBtnInstagram[i].textColor = Theme.PrimaryColor
        }
        productProfit += 3
        
        self.setShareText()
    }
    
    func sharedViaFacebook() {
        btnFacebook.borderColor = Theme.PrimaryColor
        btnFacebook.userInteractionEnabled = false
        for i in 0...lblsBtnFacebook.count - 1 {
            lblsBtnFacebook[i].textColor = Theme.PrimaryColor
        }
        productProfit += 4
        
        self.setShareText()
    }
    
    func sharedViaTwitter() {
        btnTwitter.borderColor = Theme.PrimaryColor
        btnTwitter.userInteractionEnabled = false
        for i in 0...lblsBtnTwitter.count - 1 {
            lblsBtnTwitter[i].textColor = Theme.PrimaryColor
        }
        productProfit += 3
        
        self.setShareText()
    }
    
    func setupLoveView()
    {
        if (isLoved == true)
        {
            sectionLove?.backgroundColor = Theme.PrimaryColor
            for v in (sectionLove?.subviews)!
            {
                if (v.isKindOfClass(UILabel.classForCoder()))
                {
                    let l = v as! UILabel
                    l.textColor = UIColor.whiteColor()
                } else
                {
                    v.backgroundColor = UIColor.whiteColor()
                }
            }
        } else
        {
            sectionLove?.backgroundColor = UIColor.whiteColor()
            for v in (sectionLove?.subviews)!
            {
                if (v.isKindOfClass(UILabel.classForCoder()))
                {
                    let l = v as! UILabel
                    l.textColor = UIColor(hexString: "#858585")
                } else
                {
                    v.backgroundColor = UIColor(hexString: "#858585")
                }
            }
        }
    }
    
    func share()
    {
        var item = PreloShareItem()
        let s = detail?.displayPicturers.first
        item.url = NSURL(string: s!)
        item.text = (detail?.name)!
        item.permalink  = (detail?.permalink)
        item.price = (detail?.price)
        
        PreloShareController.Share(item, inView: (parent?.navigationController?.view)!, detail : self.detail)
    }
    
    // Socmed functions
    @IBAction func btnInstagramPressed(sender: AnyObject) {
        self.shareInstagram()
    }
    
    @IBAction func btnFacebookPressed(sender: AnyObject) {
        self.shareFacebook()
    }
    
    @IBAction func btnTwitterPressed(sender: AnyObject) {
        self.shareTwitter()
    }
}

class ProductCellSeller : UITableViewCell
{
    @IBOutlet var captionSellerName : UILabel?
    @IBOutlet var captionSellerRating : UILabel?
    @IBOutlet var captionLastSeen: UILabel!
    @IBOutlet var ivSellerAvatar : UIImageView?
    
    static func heightFor(obj : JSON?)->CGFloat
    {
        return 86
    }
    
    func adapt(obj : ProductDetail?)
    {
        if (obj == nil) {
            return
        }
        var product = (obj?.json)!["_data"]
        
        captionSellerName?.text = product["seller"]["username"].stringValue
        let average_star = product["seller"]["average_star"].floatValue
        var stars = ""
        for x in 0...4
        {
            if (Float(x) <= average_star - 0.5)
            {
                stars = stars+""
            } else
            {
                stars = stars+""
            }
        }
        captionSellerRating?.text = stars
        let lastSeenSeller = obj!.lastSeenSeller
        if (lastSeenSeller != "") {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let lastSeenDate = formatter.dateFromString(lastSeenSeller) {
                captionLastSeen.text = "Terakhir aktif: \(lastSeenDate.relativeDescription)"
            }
        }

        ivSellerAvatar?.setImageWithUrl((obj?.shopAvatarURL)!, placeHolderImage: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ivSellerAvatar?.layer.cornerRadius = (ivSellerAvatar?.frame.size.width)!/2
        ivSellerAvatar?.layer.masksToBounds = true
    }
}

class ProductCellDescription : UITableViewCell, ZSWTappableLabelTapDelegate
{
    @IBOutlet var captionDesc : UILabel?
    @IBOutlet var captionDate : UILabel?
    @IBOutlet var captionSize : UILabel?
    @IBOutlet var captionCondition : UILabel?
    @IBOutlet var captionFrom : UILabel?
    @IBOutlet var captionConditionDesc : UILabel?
    @IBOutlet var captionAlasanJual : UILabel?
    
    @IBOutlet var captionMerk : ZSWTappableLabel?
    @IBOutlet var captionCategory : ZSWTappableLabel?
    
    var cellDelegate : ProductCellDelegate?
    
    override func awakeFromNib() {
        captionCategory?.tapDelegate = self
        captionMerk?.tapDelegate = self
    }
    
    static func heightFor(obj : ProductDetail?)->CGFloat
    {
        if (obj == nil) {
            return 202
        }
        var product = (obj?.json)!["_data"]
        
        let cons = CGSize(width: UIScreen.mainScreen().bounds.size.width-16, height: 0)
        let font = UIFont.systemFontOfSize(14)
        let desc = product["description"].string!
        var desc2 : NSString = NSString(string: desc)
        
        var desc3 = ""
        if let ss = obj?.specialStory
        {
            if (ss != "")
            {
                desc3 = "\"" + ss + "\"\n\n"
            }
        }
        
        desc2 = desc3 + (desc2 as String)
        
        let size = desc2.boundingRectWithSize(cons, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil)
        
        let s = "Jaminan 100% uang kembali jika pesananmu tidak sampai".boundsWithFontSize(UIFont.systemFontOfSize(12), width: UIScreen.mainScreen().bounds.size.width-66)
        
        let arr = product["category_breadcrumbs"].array!
        var categoryString : String = ""
        if (arr.count > 0) {
            for i in 0...arr.count-1
            {
                let d = arr[i]
                let name = d["name"].string!
                categoryString += name
                if (i != arr.count-1) {
                    categoryString += " > "
                }
            }
        }
        
        let cs = categoryString.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.size.width-101)
        
        var cs2 = (obj?.defectDescription)!
        if (cs2 == "")
        {
            cs2 = "-"
        }
        let cs2Size = cs2.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.size.width-136)
        
//        var al = (obj?.sellReason)!
        var sellReason = (obj?.sellReason)!
        if (sellReason == "")
        {
            sellReason = "-"
        }
        let alSize = sellReason.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.size.width-100)
        
        return 163+size.height+s.height+cs.height+8+8+cs2Size.height+8+alSize.height
    }
    
    func adapt(obj : ProductDetail?)
    {
        if (obj == nil) {
            return
        }
        var product = (obj?.json)!["_data"]
        
        var desc = ""
        if let ss = obj?.specialStory
        {
            if (ss != "")
            {
                desc = "\"" + ss + "\"\n\n"
            }
        }
        
        captionDesc?.text = desc + product["description"].string!
        captionDate?.text = product["time"].string!
        captionCondition?.text = product["condition"].string!
        if let region = product["seller_region"]["name"].string
        {
            captionFrom?.text = region
        } else {
            captionFrom?.text = "Unknown"
        }
        if let merk = product["brand"].string
        {
            let p = [
                "brand_id":product["brand_id"].stringValue,
                "brand":product["brand"].stringValue,
                "range":NSStringFromRange(NSMakeRange(0, merk.length)),
                ZSWTappableLabelTappableRegionAttributeName: Int(true),
                ZSWTappableLabelHighlightedBackgroundAttributeName : UIColor.darkGrayColor(),
                ZSWTappableLabelHighlightedForegroundAttributeName : UIColor.whiteColor(),
                NSForegroundColorAttributeName : Theme.PrimaryColorDark
            ]
            captionMerk?.attributedText = NSAttributedString(string: merk, attributes: p)
        } else {
            captionMerk?.text = "Unknown"
        }
        
        let regionid = product["seller"]["region_id"].stringValue
        if let name = CDRegion.getRegionNameWithID(regionid)
        {
            captionFrom?.text = name
        }
        
        var s = obj!.size
        if (s == "")
        {
            s = "-"
        }
        captionSize?.text = s;
        
        let arr = product["category_breadcrumbs"].array!
        var categoryString : String = ""
        var param : Array<[String : AnyObject]> = []
        if (arr.count > 0) {
            for i in 0...arr.count-1
            {
                let d = arr[i]
                let name = d["name"].string!
                let p = [
                    "category_name":name,
                    "category_id":d["_id"].string!,
                    "range":NSStringFromRange(NSMakeRange(categoryString.length, name.length)),
                    ZSWTappableLabelTappableRegionAttributeName: Int(true),
                    ZSWTappableLabelHighlightedBackgroundAttributeName : UIColor.darkGrayColor(),
                    ZSWTappableLabelHighlightedForegroundAttributeName : UIColor.whiteColor(),
                    NSForegroundColorAttributeName : Theme.PrimaryColorDark
                ]
                param.append(p)
                
                categoryString += name
                if (i != arr.count-1) {
                    categoryString += " > "
                }
            }
        }
        
        let attString : NSMutableAttributedString = NSMutableAttributedString(string: categoryString)
        for p in param
        {
            let r = NSRangeFromString(p["range"] as! String)
            attString.addAttributes(p, range: r)
        }
        
        captionCategory?.attributedText = attString
        
        var sellReason = (obj?.sellReason)!
        if (sellReason == "")
        {
            sellReason = "-"
        }
        
        captionAlasanJual?.numberOfLines = 0
        captionAlasanJual?.text = sellReason
        
        var defect = (obj?.defectDescription)!
        if (defect == "")
        {
            defect = "-"
        }
        captionConditionDesc?.text = defect
    }
    
    func tappableLabel(tappableLabel: ZSWTappableLabel!, tappedAtIndex idx: Int, withAttributes attributes: [NSObject : AnyObject]!) {
        //print(attributes)
        
        if (cellDelegate != nil) {
            if let brandName = attributes["brand"] as? String { // Brand clicked
                let brandId = attributes["brand_id"] as! String
                cellDelegate!.cellTappedBrand(brandId, brandName: brandName)
            } else {
                let name = attributes["category_name"] as! String
                let id = attributes["category_id"] as! String
                cellDelegate!.cellTappedCategory(name, categoryID: id)
            }
        }
        
    }
}

class ProductCellDiscussion : UITableViewCell
{
    @IBOutlet var captionMessage : UILabel?
    @IBOutlet var captionDate : UILabel?
    @IBOutlet var captionName : UILabel?
    @IBOutlet var ivCover : UIImageView?
    
    static func heightFor(obj : ProductDiscussion?)->CGFloat
    {
        if (obj == nil) {
            return 64
        }
        _ = (obj?.json)!
        
        let s = obj?.message.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.size.width-72)
        let h = 47+(s?.height)!
        return h
    }
    
    func adapt(obj : ProductDiscussion?)
    {
        if (obj == nil) {
            return
        }
        var json = (obj?.json)!
        
        captionDate?.text = json["time"].string!
        captionMessage?.text = obj?.message
        captionName?.text = json["sender_username"].string!
        ivCover?.setImageWithUrl((obj?.posterImageURL)!, placeHolderImage: nil)
    }
}
