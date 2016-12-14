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
import Alamofire

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


protocol ProductCellDelegate
{
    func cellTappedCategory(_ categoryName : String, categoryID : String)
    func cellTappedBrand(_ brandId : String, brandName : String)
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
    @IBOutlet var vwCoachmarkMine: UIView!
    @IBOutlet var vwCoachmarkReserve: UIView!
    
    @IBOutlet var vwAddComment: UIView!
    @IBOutlet var consHeightLblNoComment: NSLayoutConstraint!
    
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
    
    // Up barang pop up
    @IBOutlet var vwUpBarangPopUp: UIView!
    @IBOutlet var vwUpBarangPopUpPanel: UIView!
    @IBOutlet var lblUpBarang: UILabel!
    @IBOutlet var vwBtnSet1UpBarang: UIView!
    @IBOutlet var vwBtnSet2UpBarang: UIView!
    @IBOutlet var lblUpOther: UILabel!
    @IBOutlet var consHeightUpBarang: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide add comment view first
        self.vwAddComment.isHidden = true
        
        _ = UIImage(named: "ic_chat")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        
        self.btnAddDiscussion?.addTarget(self, action: #selector(ProductDetailViewController.segAddComment(_:)), for: UIControlEvents.touchUpInside)
        
        btnBuy.isHidden = true
        btnTawar.isHidden = true
        
        btnAddDiscussion?.layer.cornerRadius = 4
        btnAddDiscussion?.layer.borderColor = UIColor.lightGray.cgColor
        btnAddDiscussion?.layer.borderWidth = 1
        
        let btnClose = self.createButtonWithIcon(AppFont.prelo2, icon: "")
        btnClose.addTarget(self, action: #selector(ProductDetailViewController.dismiss(_:)), for: UIControlEvents.touchUpInside)
        
        tableView?.contentInset = UIEdgeInsetsMake(0, 0, 44, 0)
        
        let btnOption = self.createButtonWithIcon(AppFont.prelo2, icon: "")
        btnOption.addTarget(self, action: #selector(ProductDetailViewController.option), for: UIControlEvents.touchUpInside)
        self.navigationItem.rightBarButtonItem = btnOption.toBarButton()
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        self.hideUpPopUp()
        self.vwUpBarangPopUp.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
        if (detail == nil) {
            getDetail()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
            if ((self.navigationController?.isNavigationBarHidden)! == true)
            {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }
        }
        
        if (UIApplication.shared.isStatusBarHidden)
        {
            UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.slide)
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
    }
    
    func option()
    {
        let a = UIActionSheet(title: "Option", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: "Cancel")
        a.addButton(withTitle: "Report")
        a.show(in: self.view)
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == 1)
        {
            guard let pDetail = detail else {
                return
            }
//            var username = "Your beloved user"
//            if let u = CDUser.getOne() {
//                username = u.username
//            }
//            
//            // report
//            let msgBody = "Dear Prelo,<br/><br/>Saya ingin melaporkan barang \(pDetail.name) dari penjual \(pDetail.theirName)<br/><br/>Alasan pelaporan: <br/><br/>Terima kasih Prelo <3<br/><br/>--<br/>\(username)<br/>Sent from Prelo iOS"
//            
//            let m = MFMailComposeViewController()
//            if (MFMailComposeViewController.canSendMail()) {
//                m.setToRecipients(["contact@prelo.id"])
//                m.setSubject("Laporan Baru untuk Barang " + (detail?.name)!)
//                m.setMessageBody(msgBody, isHTML: true)
//                m.mailComposeDelegate = self
//                self.present(m, animated: true, completion: nil)
//            } else {
//                Constant.showDialog("No Active E-mail", message: "Untuk dapat mengirim Report, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
//            }
            
            
            
            
            let productReportVC = Bundle.main.loadNibNamed(Tags.XibNameProductReport, owner: nil, options: nil)?.first as! ReportProductViewController
            
            productReportVC.root = self

            productReportVC.pDetail = self.detail
            self.navigationController?.pushViewController(productReportVC, animated: true)
            
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func getDetail()
    {
        self.showLoading()
        // API Migrasi
        let _ = request(APIProduct.detail(productId: (product?.json)!["_id"].string!, forEdit: 0))
            .responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Barang"))
                {
                    self.detail = ProductDetail.instance(JSON(resp.result.value!))
                    self.activated = (self.detail?.isActive)!
                    self.adjustButtonByStatus()
                    print(self.detail?.json)
                    
                    // Setup add comment view
                    self.vwAddComment.isHidden = false
                    if (self.detail?.discussions?.count > 0) {
                        self.consHeightLblNoComment.constant = 0
                    } else {
                        self.consHeightLblNoComment.constant = 16
                    }
                    
                    // Setup table
                    self.tableView?.dataSource = self
                    self.tableView?.delegate = self
                    self.tableView?.isHidden = false
                    self.tableView?.reloadData()
                    
                    self.setupView()
                } else {
                    
                }
                self.hideLoading()
        }
    }
    
    func adjustButtonByStatus() {
        if (self.detail?.status == 0 || self.detail?.status == 2) { // Inactive or under review
            self.disableButton(self.btnUp)
            self.disableButton(self.btnSold)
        } else if (self.detail?.status == 3 || self.detail?.status == 4) { // sold or deleted
            self.disableButton(self.btnTawar)
            self.btnTawar.borderColor = Theme.GrayLight
            
            self.disableButton(self.btnBuy)
            self.disableMyProductBtnSet()
            
            if (self.detail?.status == 4) {
                if (self.detail?.boughtByMe == true) {
                    self.btnTawar.isHidden = true
                    self.btnBuy.isHidden = true
                    if (self.detail?.transactionProgress == 1 || self.detail?.transactionProgress == 2) {
                        // Tampilkan button konfirmasi bayar
                        self.konfirmasiBayarBtnSet.isHidden = false
                    } else if (self.detail?.transactionProgress > 2) {
                        // Tampilkan button transaction product detail
                        self.tpDetailBtnSet.isHidden = false
                    }
                }
            }
        }
        
        // Disable pet buying
        if (self.detail?.categoryID == "57d8da9dce731801ed540fa4") { // Pet category ID
            self.disableButton(self.btnBuy)
        }
    }
    
    func disableMyProductBtnSet() {
        self.disableButton(self.btnUp)
        self.disableButton(self.btnSold)
        self.disableButton(self.btnEdit)
    }
    
    func disableButton(_ btn : UIButton) {
        btn.isUserInteractionEnabled = false
        
        if (btn.titleLabel?.text == nil || btn.titleLabel?.text == "") { // Button with uiimage icon
            btn.backgroundColor = UIColor.colorWithColor(UIColor.darkGray, alpha: 0.5)
            return
        }
        
        // Button with uilabel icon
        btn.setBackgroundImage(nil, for: UIControlState())
        btn.backgroundColor = nil
        btn.setTitleColor(Theme.GrayLight)
        btn.layer.borderColor = Theme.GrayLight.cgColor
        btn.layer.borderWidth = 1
        btn.layer.cornerRadius = 1
        btn.layer.masksToBounds = true
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
        if let isFeatured = self.product?.isFeatured , isFeatured {
            pDetailCover?.isFeaturedProduct = isFeatured
            pDetailCover?.setupBanner()
        }
        if let labels = detail?.imageLabels
        {
            pDetailCover?.labels = labels
        }
        pDetailCover?.height = UIScreen.main.bounds.size.width * 340 / 480
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
                        ACTRemarketingReporter.report(withConversionID: "953474992", customParameters: ["dynx_itemid":id, "dynx_pagetype":catName, "dynx_totalvalue":price])
                    }
                }
            }
        }
        
        // Button arrangement
        if (detail!.isGarageSale) {
            reservationBtnSet.isHidden = false
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
            reservationBtnSet.isHidden = true
            
            if ((detail?.isMyProduct)! == true)
            {
//            if let b : UIButton = self.view.viewWithTag(12) as? UIButton
//            {
//                b.hidden = false
//                b.titleLabel?.font = AppFont.PreloAwesome.getFont(15)
//                b.setTitle(" EDIT", forState: UIControlState.Normal)
//            }
                self.btnBuy.isHidden = true
                self.btnTawar.isHidden = true
                btnEdit.isHidden = false
                btnUp.isHidden = false
                btnSold.isHidden = false
                btnSold.superview?.isHidden = false
            }
            else
            {
                btnBuy.isHidden = false
                btnTawar.isHidden = false
            }
            
            self.btnTawar.removeTarget(nil, action: nil, for: .allEvents)
            self.btnTawar.addTarget(self, action: #selector(ProductDetailViewController.tawar(_:)), for: UIControlEvents.touchUpInside)
        }
        
        // Coachmark
        if (detail!.isGarageSale) {
            let coachmarkReserveDone : Bool? = UserDefaults.standard.object(forKey: UserDefaultsKey.CoachmarkReserveDone) as! Bool?
            if (coachmarkReserveDone != true) {
                UserDefaults.setObjectAndSync(true as AnyObject?, forKey: UserDefaultsKey.CoachmarkReserveDone)
                vwCoachmarkReserve.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.7)
                vwCoachmarkReserve.isHidden = false
            }
        } else {
            if (detail!.isMyProduct) {
                let coachmarkMineDone : Bool? = UserDefaults.standard.object(forKey: UserDefaultsKey.CoachmarkProductDetailMineDone) as! Bool?
                if (coachmarkMineDone != true) {
                    UserDefaults.setObjectAndSync(true as AnyObject?, forKey: UserDefaultsKey.CoachmarkProductDetailMineDone)
                    vwCoachmarkMine.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.7)
                    vwCoachmarkMine.isHidden = false
                }
            } else {
                let coachmarkDone : Bool? = UserDefaults.standard.object(forKey: UserDefaultsKey.CoachmarkProductDetailDone) as! Bool?
                if (coachmarkDone != true) {
                    UserDefaults.setObjectAndSync(true as AnyObject?, forKey: UserDefaultsKey.CoachmarkProductDetailDone)
                    vwCoachmark.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.7)
                    vwCoachmark.isHidden = false
                }
            }
        }
    }

    @IBAction func dismiss(_ sender: AnyObject)
    {
        self.dismiss(animated: YES, completion: nil)
    }
    
    // MARK: - Instagram
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        print("DidEndPreview")
    }
    
    // MARK: - Facebook
    
    func postShareCommissionFacebook() {
        let _ = request(APIProduct.shareCommission(pId: (self.detail?.productID)!, instagram: "0", path: "0", facebook: "1", twitter: "0")).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Share Facebook")) {
                self.cellTitle?.sharedViaFacebook()
                self.detail?.setSharedViaFacebook()
                if let fbUsername = CDUserOther.getOne()?.fbUsername {
                    Constant.showDialog("Share to Facebook", message: "Barang berhasil di-share di akun Facebook \(fbUsername)")
                }
            }
            self.hideLoading()
        }
    }
    
    // MARK: - Twitter
    func postShareCommissionTwitter() {
        let _ = request(APIProduct.shareCommission(pId: (self.detail?.productID)!, instagram: "0", path: "0", facebook: "0", twitter: "1")).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Share Twitter")) {
                self.cellTitle?.sharedViaTwitter()
                self.detail?.setSharedViaTwitter()
                if let twUsername = CDUserOther.getOne()?.twitterUsername {
                    Constant.showDialog("Share to Twitter", message: "Barang berhasil di-share di akun Twitter \(twUsername)")
                }
            }
            self.hideLoading()
        }
    }
    
    // MARK: - Tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 3
        } else {
            return 0+(detail?.discussions?.count)!
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1+(((detail?.discussions?.count)! == 0) ? 0 : 1)
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath as NSIndexPath).section == 0) {
            if ((indexPath as NSIndexPath).row == 0) {
                if (cellTitle == nil) {
                    cellTitle = tableView.dequeueReusableCell(withIdentifier: "cell_title") as? ProductCellTitle
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
                    if (UIApplication.shared.canOpenURL(URL(string: "instagram://app")!)) {
                        var hashtags = ""
                        if let dtl = self.detail {
                            if let h = CDCategory.getCategoryHashtagsWithID(dtl.categoryID) {
                                hashtags = " \(h)"
                            }
                        }
                        UIPasteboard.general.string = "\(textToShare)\(hashtags)"
                        Constant.showDialog("Text sudah disalin ke clipboard", message: "Silakan paste sebagai deskripsi post Instagram kamu")
                        self.mgInstagram = MGInstagram()
                        if let imgUrl = self.detail?.productImage {
                            let imgData = try? Data(contentsOf: imgUrl as URL)
                            let img = UIImage(data: imgData!)
                            self.mgInstagram?.post(img, withCaption: textToShare, in: self.view, delegate: self)
                            let _ = request(APIProduct.shareCommission(pId: (self.detail?.productID)!, instagram: "1", path: "0", facebook: "0", twitter: "0")).responseJSON { resp in
                                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Share Instagram")) {
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
                    
                    if (FBSDKAccessToken.current() != nil && FBSDKAccessToken.current().permissions.contains("publish_actions")) {
                        self.postShareCommissionFacebook()
                    } else {
                        let p = ["sender" : self]
                        LoginViewController.LoginWithFacebook(p, onFinish: { result in
                            // Handle Profile Photo URL String
                            let userId = result["id"] as? String
                            let name = result["name"] as? String
                            let accessToken = FBSDKAccessToken.current().tokenString
                            
                            print("result = \(result)")
                            print("accessToken = \(accessToken)")
                            
                            // userId & name is required
                            if (userId != nil && name != nil) {
                                // API Migrasi
                                let _ = request(APISocmed.postFacebookData(id: userId!, username: name!, token: accessToken!)).responseJSON { resp in
                                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Facebook")) {
                                        
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
                                    
                                    self.postShareCommissionTwitter()
                                } else {
                                    LoginViewController.LoginTwitterCancelled(self, reason: "Terdapat kesalahan saat menyimpan data Twitter")
                                }
                            }
                        })
                    }
                }
                return cellTitle!
            } else if ((indexPath as NSIndexPath).row == 1) {
                if (cellSeller == nil) {
                    cellSeller = tableView.dequeueReusableCell(withIdentifier: "cell_seller") as? ProductCellSeller
                }
                cellSeller?.adapt(detail)
                return cellSeller!
            } else {
                if (cellDesc == nil) {
                    cellDesc = tableView.dequeueReusableCell(withIdentifier: "cell_desc") as? ProductCellDescription
                    cellDesc?.cellDelegate = self
                }
                cellDesc?.adapt(detail)
                return cellDesc!
            }
        } else {
            let cell : ProductCellDiscussion = (tableView.dequeueReusableCell(withIdentifier: "cell_disc_1") as? ProductCellDiscussion)!
            cell.adapt(detail?.discussions?.objectAtCircleIndex((indexPath as NSIndexPath).row-3))
            cell.showReportAlert = { sender, commentId in
                let alert = UIAlertController(title: "Laporkan Komentar", message: "", preferredStyle: .actionSheet)
                alert.popoverPresentationController?.sourceView = sender
                alert.popoverPresentationController?.sourceRect = sender.bounds
                alert.addAction(UIAlertAction(title: "Komentar ini mengganggu/spam", style: .default, handler: { act in
                    self.reportComment(commentId: commentId, reportType: 0)
                    alert.dismiss(animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Komentar ini tidak layak", style: .default, handler: { act in
                    self.reportComment(commentId: commentId, reportType: 1)
                    alert.dismiss(animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Batal", style: .default, handler: { act in
                    alert.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
            cell.goToProfile = { userId in
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                vc.currentMode = .shop
                vc.shopId = userId
                
                self.navigationController?.pushViewController(vc, animated: true)
            }
            return cell
        }
    }
    
    func reportComment(commentId : String, reportType : Int) {
        self.showLoading()
        request(APIProduct.reportComment(productId: (self.product?.id)!, commentId: commentId, reportType: reportType)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Laporkan Komentar")) {
                let json = JSON(resp.result.value!)
                if (json["_data"].boolValue == true) {
                    Constant.showDialog("Komentar Dilaporkan", message: "Terima kasih, Prelo akan meninjau laporan kamu")
                }
            }
            self.hideLoading()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (section == 0) {
            return nil
        } else {
            let l = UILabel()
            l.numberOfLines = 1
            l.textColor = UIColor.lightGray
            l.backgroundColor = UIColor.clear
            l.text = "KOMENTAR"
            l.font = UIFont.boldSystemFont(ofSize: 14)
            l.sizeToFit()
            let v = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 40))
            v.backgroundColor = UIColor.white
            v.addSubview(l)
            l.x = 8
            l.y = (40-l.height)/2
            return v
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == 0) {
            return 0
        } else {
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ((indexPath as NSIndexPath).section == 0) {
            if ((indexPath as NSIndexPath).row == 0) {
                return ProductCellTitle.heightFor(detail)
            } else if ((indexPath as NSIndexPath).row == 1) {
                return ProductCellSeller.heightFor(detail?.json)
            } else {
                return ProductCellDescription.heightFor(detail)
            }
        } else {
            return ProductCellDiscussion.heightFor(detail?.discussions?.objectAtCircleIndex((indexPath as NSIndexPath).row-3))
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ((indexPath as NSIndexPath).row == 1)
        {
            let d = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            d.currentMode = .shop
            if let name = detail?.json["_data"]["seller"]["username"].string
            {
                d.shopName = name
            }
            
            if let name = detail?.json["_data"]["seller"]["_id"].string
            {
                d.shopId = name
            }
            
            self.navigationController?.pushViewController(d, animated: true)
        }
    }
    
    func cellTappedCategory(_ categoryName: String, categoryID: String) {
        let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        l.currentMode = .standalone
        l.standaloneCategoryName = categoryName
        l.standaloneCategoryID = categoryID
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    func cellTappedBrand(_ brandId: String, brandName: String) {
        let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        l.currentMode = .filter
        l.fltrSortBy = "recent"
        l.fltrBrands = [brandName : brandId]
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    @IBAction func addToCart(_ sender: UIButton) {
        if (alreadyInCart) {
            self.performSegue(withIdentifier: "segCart", sender: nil)
            return
        }
        
        if (CartProduct.newOne((detail?.productID)!, email : User.EmailOrEmptyString, name : (detail?.name)!) == nil) {
            Constant.showDialog("Failed", message: "Gagal Menyimpan")
        } else {
            setupView()
            self.performSegue(withIdentifier: "segCart", sender: nil)
        }
    }
        
    @IBAction func soldPressed(_ sender: AnyObject) {
        let alert : UIAlertController = UIAlertController(title: "Mark As Sold", message: "Apakah barang ini sudah terjual? (Aksi ini tidak bisa dibatalkan)", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Tidak", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Ya", style: .default, handler: { action in
            self.showLoading()
            if let productId = self.detail?.productID {
                let _ = request(APIProduct.markAsSold(productId: productId, soldTo: "")).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Mark As Sold")) {
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
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func editPressed(_ sender: AnyObject) {
        self.showLoading()
        let a = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        a.editMode = true
        a.editDoneBlock = {
            self.tableView?.isHidden = true
            self.getDetail()
        }
        // API Migrasi
        let _ = request(APIProduct.detail(productId: detail!.productID, forEdit: 1)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Barang")) {
                a.editProduct = ProductDetail.instance(JSON(resp.result.value!))
                self.hideLoading()
                self.navigationController?.pushViewController(a, animated: true)
            }
        }
    }
    
    @IBAction func tawar(_ sender : UIView)
    {
        if let d = self.detail
        {
            let t = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdTawar) as! TawarViewController
            t.tawarItem = d
            t.loadInboxFirst = true
            t.prodId = d.productID
            self.navigationController?.pushViewController(t, animated: true)
        }
    }
    
    var loginComment = false
    @IBAction func segAddComment(_ sender : UIView?)
    {
        if (User.IsLoggedIn == false)
        {
            loginComment = true
            LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
        } else
        {
            self.performSegue(withIdentifier: "segAddComment", sender: nil)
        }
    }
    
    func userCancelLogin() {
        
    }
    
    func userLoggedIn() {
        if (loginComment)
        {
            self.performSegue(withIdentifier: "segAddComment", sender: nil)
        }
    }
    
    func userLoggedOut() {
        
    }
    
    // MARK: - Coachmark
    
    @IBAction func coachmarkTapped(_ sender: AnyObject) {
        self.vwCoachmark.isHidden = true
        self.vwCoachmarkMine.isHidden = true
        self.vwCoachmarkReserve.isHidden = true
    }
    
    // MARK: - Reservation
    
    @IBAction func btnReservationPressed(_ sender: AnyObject) {
        if (detail != nil) {
            if (detail!.status == ProductStatusActive) { // Product is available
                // Reserve product
                self.setBtnReservationToLoading()
                // API Migrasi
                let _ = request(APIGarageSale.createReservation(productId: detail!.productID)).responseJSON {resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Create Reservation")) {
                        let json = JSON(resp.result.value!)
                        let data = json["_data"]
                        if let tpId = data["transaction_product_id"].string {
                            self.detail!.setStatus(self.ProductStatusReserved)
                            self.detail!.setBoughtByMe(true)
                            self.pDetailCover?.updateStatus(self.ProductStatusReserved)
                            self.setBtnReservationToCancel()
                            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            let transactionDetailVC : TransactionDetailViewController = (mainStoryboard.instantiateViewController(withIdentifier: "TransactionDetail") as? TransactionDetailViewController)!
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
                    let _ = request(APIGarageSale.cancelReservation(productId: detail!.productID)).responseJSON {resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Cancel Reservation")) {
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
        btnReservation.borderColor = UIColor.clear
        btnReservation.backgroundColor = Theme.ThemeOrangeDark
        btnReservation.setTitle("LOADING...", for: UIControlState())
        btnReservation.isUserInteractionEnabled = false
    }
    
    func setBtnReservationToEnabled() {
        btnReservation.cornerRadius = 0
        btnReservation.borderWidth = 0
        btnReservation.borderColor = UIColor.clear
        btnReservation.backgroundColor = Theme.ThemeOrange
        btnReservation.setTitle(" RESERVE", for: UIControlState())
        btnReservation.isUserInteractionEnabled = true
    }
    
    func setBtnReservationToCancel() {
        btnReservation.cornerRadius = 2.0
        btnReservation.borderWidth = 1.0
        btnReservation.borderColor = UIColor.white
        btnReservation.backgroundColor = UIColor.clear
        btnReservation.setTitle(" CANCEL RESERVATION", for: UIControlState())
        btnReservation.isUserInteractionEnabled = true
    }
    
    func setBtnReservationToDisabled() {
        btnReservation.cornerRadius = 0
        btnReservation.borderWidth = 0
        btnReservation.borderColor = UIColor.clear
        btnReservation.backgroundColor = Theme.GrayLight
        btnReservation.setTitle(" RESERVE", for: UIControlState())
        btnReservation.isUserInteractionEnabled = false
    }
    
    // MARK: - If product is bought
    
    @IBAction func toPaymentConfirm(_ sender: AnyObject) {
        let paymentConfirmationVC = Bundle.main.loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil)?.first as! PaymentConfirmationViewController
        self.navigationController?.pushViewController(paymentConfirmationVC, animated: true)
    }
    
    @IBAction func toTransactionProductDetail(_ sender: AnyObject) {
        let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
        self.navigationController?.pushViewController(myPurchaseVC, animated: true)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "segAddComment")
        {
            let c = segue.destination as! ProductCommentsController
            c.pDetail = self.detail
        } else
        {
            let c = segue.destination as! BaseViewController
            c.previousController = self
        }
    }
    
    // MARK: - Up barang
    
    @IBAction func upPressed(_ sender: AnyObject) {
        self.showLoading()
        if let productId = detail?.productID {
            let _ = request(APIProduct.push(productId: productId)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Up Barang")) {
                    let json = JSON(resp.result.value!)
                    let isSuccess = json["_data"]["result"].boolValue
                    let message = json["_data"]["message"].stringValue
                    let paidAmount = json["_data"]["paid_amount"].intValue
                    let preloBalance = json["_data"]["my_prelo_balance"].intValue
                    if (isSuccess) {
                        self.showUpPopUp(withText: message, isShowUpOther: true, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance)
                    } else {
                        self.showUpPopUp(withText: message, isShowUpOther: false, isShowPaidUp: true, paidAmount: paidAmount, preloBalance: preloBalance)
                    }
                }
                self.hideLoading()
            }
        }
    }
    
    func showUpPopUp(withText : String, isShowUpOther : Bool, isShowPaidUp : Bool, paidAmount : Int, preloBalance: Int) {
        self.vwUpBarangPopUp.isHidden = false
        if (isShowUpOther) {
            self.lblUpOther.isHidden = false
        } else {
            self.lblUpOther.isHidden = true
        }
        if (isShowPaidUp) {
            self.vwBtnSet1UpBarang.isHidden = false
            self.vwBtnSet2UpBarang.isHidden = true
            self.lblUpBarang.text = withText + "\n\n" + "Atau kamu bisa UP sekarang dengan membayar " + paidAmount.asPrice + " (akan otomatis ditarik dari Prelo Balance)\n"  + "Prelo Balance kamu: " + preloBalance.asPrice
            self.lblUpBarang.boldSubstring("sekarang")
            self.lblUpBarang.boldSubstring(paidAmount.asPrice)
            self.lblUpBarang.boldSubstring(preloBalance.asPrice)
        } else {
            self.vwBtnSet1UpBarang.isHidden = true
            self.vwBtnSet2UpBarang.isHidden = false
            self.lblUpBarang.text = withText
        }
        self.lblUpBarang.sizeToFit()
        self.consHeightUpBarang.constant = 120 + lblUpBarang.height
        self.vwUpBarangPopUpPanel.setNeedsLayout()
    }
    
    func hideUpPopUp() {
        self.vwUpBarangPopUp.isHidden = true
    }
    
    @IBAction func btnUPOtherPressed(_ sender: AnyObject) {
        let m = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdMyProducts) as! MyProductViewController
        m.shouldSkipBack = false
        self.navigationController?.pushViewController(m, animated: true)
    }
    
    @IBAction func btnUpBarangOKPressed(_ sender: AnyObject) {
        self.hideUpPopUp()
    }
    
    @IBAction func btnUpBarangUpPressed(_ sender: AnyObject) {
        self.hideUpPopUp()
        self.showLoading()
        if let productId = detail?.productID {
            let _ = request(APIProduct.paidPush(productId: productId)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Up Barang")) {
                    let json = JSON(resp.result.value!)
                    let isSuccess = json["_data"]["result"].boolValue
                    let message = json["_data"]["message"].stringValue
                    let paidAmount = json["_data"]["paid_amount"].intValue
                    let preloBalance = json["_data"]["my_prelo_balance"].intValue
                    if (isSuccess) {
                        self.showUpPopUp(withText: message, isShowUpOther: true, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance)
                    } else {
                        self.showUpPopUp(withText: message, isShowUpOther: false, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance)
                    }
                }
                self.hideLoading()
            }
        }
    }
    
    @IBAction func btnUpBarangBatalPressed(_ sender: AnyObject) {
        self.hideUpPopUp()
    }
    
    // MARK: - Other functions

    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
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
    
    static func heightFor(_ obj : ProductDetail?)->CGFloat
    {
        if (obj == nil) {
            return 110
        }
        var product = (obj?.json)!["_data"]
        
        let name = product["name"].string!
        let s = name.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 16.5), width: UIScreen.main.bounds.size.width-74.0)
        
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
        
        btnShare?.layer.borderColor = UIColor.lightGray.cgColor
        btnShare?.layer.borderWidth = 1
        
        btnShare?.addTarget(self, action: #selector(ProductCellTitle.share), for: UIControlEvents.touchUpInside)
        
        sectionLove?.layer.borderColor = UIColor.lightGray.cgColor
        sectionLove?.layer.borderWidth = 1
        sectionLove?.layer.cornerRadius = 2
        sectionLove?.layer.masksToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ProductCellTitle.love))
        sectionLove?.addGestureRecognizer(tap)
        
        sectionComment?.layer.borderColor = UIColor.lightGray.cgColor
        sectionComment?.layer.borderWidth = 1
        sectionComment?.layer.cornerRadius = 2
        sectionComment?.layer.masksToBounds = true
        
        let tapcomment = UITapGestureRecognizer(target: self, action: #selector(ProductCellTitle.comment))
        sectionComment?.addGestureRecognizer(tapcomment)
        
        let screenWidth: CGFloat = UIScreen.main.bounds.width
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
            self.parent?.performSegue(withIdentifier: "segAddComment", sender: nil)
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
            self.parent?.performSegue(withIdentifier: "segAddComment", sender: nil)
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
        let _ = request(APIProduct.love(productID: (detail?.productID)!)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Love Product"))
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
        let _ = request(APIProduct.unlove(productID: (detail?.productID)!)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Unlove Product"))
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
    
    func adapt(_ obj : ProductDetail?)
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
            } else
            {
                conWidthOngkir.constant = 104
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
                sectionBrandReview?.isHidden = true
            }
        }
        
        // Socmed buttons
        if (detail!.isMyProduct) {
            self.consHeightLblShareSocmed.constant = 22
            
            self.sectionLove?.isHidden = true
            self.sectionComment?.isHidden = true
            self.btnShare?.isHidden = true
            self.socmedBtnSet.isHidden = false
            
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
        attTxt.addAttributes([NSForegroundColorAttributeName: Theme.PrimaryColor], range: (txt as NSString).range(of: "\(productProfit)%"))
        self.lblShareSocmed.attributedText = attTxt
    }
    
    func sharedViaInstagram() {
        btnInstagram.borderColor = Theme.PrimaryColor
        btnInstagram.isUserInteractionEnabled = false
        for i in 0...lblsBtnInstagram.count - 1 {
            lblsBtnInstagram[i].textColor = Theme.PrimaryColor
        }
        productProfit += 3
        
        self.setShareText()
    }
    
    func sharedViaFacebook() {
        btnFacebook.borderColor = Theme.PrimaryColor
        btnFacebook.isUserInteractionEnabled = false
        for i in 0...lblsBtnFacebook.count - 1 {
            lblsBtnFacebook[i].textColor = Theme.PrimaryColor
        }
        productProfit += 4
        
        self.setShareText()
    }
    
    func sharedViaTwitter() {
        btnTwitter.borderColor = Theme.PrimaryColor
        btnTwitter.isUserInteractionEnabled = false
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
                if (v.isKind(of: UILabel.classForCoder()))
                {
                    let l = v as! UILabel
                    l.textColor = UIColor.white
                } else
                {
                    v.backgroundColor = UIColor.white
                }
            }
        } else
        {
            sectionLove?.backgroundColor = UIColor.white
            for v in (sectionLove?.subviews)!
            {
                if (v.isKind(of: UILabel.classForCoder()))
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
        item.url = URL(string: s!)
        item.text = (detail?.name)!
        item.permalink  = (detail?.permalink)
        item.price = (detail?.price)
        
        PreloShareController.Share(item, inView: (parent?.navigationController?.view)!, detail : self.detail)
    }
    
    // Socmed functions
    @IBAction func btnInstagramPressed(_ sender: AnyObject) {
        self.shareInstagram()
    }
    
    @IBAction func btnFacebookPressed(_ sender: AnyObject) {
        self.shareFacebook()
    }
    
    @IBAction func btnTwitterPressed(_ sender: AnyObject) {
        self.shareTwitter()
    }
}

class ProductCellSeller : UITableViewCell
{
    @IBOutlet var captionSellerName : UILabel?
    @IBOutlet var captionSellerRating : UILabel?
    @IBOutlet var captionLastSeen: UILabel!
    @IBOutlet var ivSellerAvatar : UIImageView?
    
    static func heightFor(_ obj : JSON?)->CGFloat
    {
        return 86
    }
    
    func adapt(_ obj : ProductDetail?)
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
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let lastSeenDate = formatter.date(from: lastSeenSeller) {
                captionLastSeen.text = "Terakhir aktif: \(lastSeenDate.relativeDescription)"
            }
        }

        ivSellerAvatar?.afSetImage(withURL: (obj?.shopAvatarURL)!)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ivSellerAvatar?.layoutIfNeeded()
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
    
    static func heightFor(_ obj : ProductDetail?)->CGFloat
    {
        if (obj == nil) {
            return 202
        }
        var product = (obj?.json)!["_data"]
        
        let cons = CGSize(width: UIScreen.main.bounds.size.width-16, height: 0)
        let font = UIFont.systemFont(ofSize: 14)
        let desc = product["description"].string!
        var desc2 : NSString = NSString(string: desc)
        
        var desc3 : NSString = NSString(string: "")
        if let ss = obj?.specialStory
        {
            if (ss != "")
            {
                desc3 = NSString(string: "\"" + ss + "\"\n\n")
            }
        }
        
        desc2 = desc3.appending(desc2 as String) as NSString
        
        let size = desc2.boundingRect(with: cons, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil)
        
        let s = "Jaminan 100% uang kembali jika pesananmu tidak sampai".boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: UIScreen.main.bounds.size.width-66)
        
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
        
        let cs = categoryString.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width-101)
        
        var cs2 = (obj?.defectDescription)!
        if (cs2 == "")
        {
            cs2 = "-"
        }
        let cs2Size = cs2.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width-136)
        
//        var al = (obj?.sellReason)!
        var sellReason = (obj?.sellReason)!
        if (sellReason == "")
        {
            sellReason = "-"
        }
        let alSize = sellReason.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width-100)
        
        return 163+size.height+s.height+cs.height+8+8+cs2Size.height+8+alSize.height
    }
    
    func adapt(_ obj : ProductDetail?)
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
                ZSWTappableLabelHighlightedBackgroundAttributeName : UIColor.darkGray,
                ZSWTappableLabelHighlightedForegroundAttributeName : UIColor.white,
                NSForegroundColorAttributeName : Theme.PrimaryColorDark
            ] as [String : Any]
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
        var param : Array<[String : Any]> = []
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
                    ZSWTappableLabelHighlightedBackgroundAttributeName : UIColor.darkGray,
                    ZSWTappableLabelHighlightedForegroundAttributeName : UIColor.white,
                    NSForegroundColorAttributeName : Theme.PrimaryColorDark
                ] as [String : Any]
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
    
    func tappableLabel(_ tappableLabel: ZSWTappableLabel!, tappedAt idx: Int, withAttributes attributes: [AnyHashable: Any]!) {
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
    @IBOutlet var consWidthBtnReport: NSLayoutConstraint!
    
    var commentId : String = ""
    var senderId : String = ""
    
    var showReportAlert : (UIView, String) -> () = { _, _ in }
    var goToProfile : (String) -> () = { _ in }
    
    static func heightFor(_ obj : ProductDiscussion?)->CGFloat
    {
        if (obj == nil) {
            return 64
        }
        _ = (obj?.json)!
        
        let s = obj?.message.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width-72)
        let h = 47+(s?.height)!
        return h
    }
    
    func adapt(_ obj : ProductDiscussion?)
    {
        if (obj == nil) {
            return
        }
        var json = (obj?.json)!
        commentId = json["_id"].stringValue
        senderId = json["sender_id"].stringValue
        
        captionDate?.text = json["time"].string!
        captionMessage?.text = obj?.message
        if (obj!.isDeleted) {
            captionMessage?.font = UIFont.italicSystemFont(ofSize: 13)
            captionMessage?.textColor = UIColor.lightGray
        } else {
            captionMessage?.font = UIFont.systemFont(ofSize: 13)
            captionMessage?.textColor = UIColor.darkGray
        }
        captionName?.text = json["sender_username"].string!
        ivCover?.afSetImage(withURL: (obj?.posterImageURL)!)
        
        if (User.IsLoggedIn) {
            consWidthBtnReport.constant = 25
        } else {
            consWidthBtnReport.constant = 0
        }
    }
    
    @IBAction func btnReportPressed(_ sender: UIView) {
        self.showReportAlert(sender, commentId)
    }
    
    @IBAction func btnUsernamePressed(_ sender: AnyObject) {
        self.goToProfile(senderId)
    }
}
