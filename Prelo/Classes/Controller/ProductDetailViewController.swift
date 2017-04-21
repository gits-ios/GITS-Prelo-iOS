//
//  ProductDetailViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/13/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
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


protocol ProductCellDelegate: class
{
    func cellTappedCategory(_ categoryName : String, categoryID : String)
    func cellTappedBrand(_ brandId : String, brandName : String)
    
    func cellTappedComment()
}

class ProductDetailViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, ProductCellDelegate, /*UIActionSheetDelegate, UIAlertViewDelegate,*/ MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, UserRelatedDelegate, ISRewardedVideoDelegate {
    
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
    
    // up barang coin - diamond
    var isCoinUse = false
    
    var isNeedReload = false
    
    weak var delegate: MyProductDelegate?
    
    var thisScreen: String!
    
    // new popup paid push
    var newPopup: PaidPushPopup?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = product?.name
        
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
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        self.hideUpPopUp()
        self.vwUpBarangPopUp.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
        
        self.setNeedsStatusBarAppearanceUpdate()

        if (detail == nil || isNeedReload) {
            getDetail()
            
            isNeedReload = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        self.title = product?.name
        
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
//            UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.slide)
            
            UIApplication.shared.isStatusBarHidden = false
        }
        
//        let p = [
//            "Product" : ((product != nil) ? (product!.name) : ""),
//            "Product ID" : ((product != nil) ? (product!.id) : ""),
//            "Category 1" : ((detail != nil && detail?.categoryBreadcrumbs.count > 1) ? (detail!.categoryBreadcrumbs[1]["name"].string!) : ""),
//            "Category 2" : ((detail != nil && detail?.categoryBreadcrumbs.count > 2) ? (detail!.categoryBreadcrumbs[2]["name"].string!) : ""),
//            "Category 3" : ((detail != nil && detail?.categoryBreadcrumbs.count > 3) ? (detail!.categoryBreadcrumbs[3]["name"].string!) : ""),
//            "Seller" : ((detail != nil) ? (detail!.theirName) : "")
//        ]
        if (detail != nil && detail!.isMyProduct == true) {
            // Mixpanel
//            Mixpanel.trackPageVisit(PageName.ProductDetailMine, otherParam: p)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.ProductDetailMine)
            
            self.thisScreen = PageName.ProductDetailMine
        } else {
            // Mixpanel
//            Mixpanel.trackPageVisit(PageName.ProductDetail, otherParam: p)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.ProductDetail)
            
            self.thisScreen = PageName.ProductDetail
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return UIApplication.shared.isStatusBarHidden
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
                    
                    self.title = self.detail?.name
                    
                    self.activated = (self.detail?.isActive)!
                    print((self.detail?.json ?? ""))
                    
                    self.adjustButtonByStatus()
                    
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
                    
                    let userid = CDUser.getOne()?.id
                    let sellerid = self.detail?.theirId
                    
                    if User.IsLoggedIn && sellerid != userid {
                        self.setOptionButton()
                    } else {
                        // ads
                        IronSource.setRewardedVideoDelegate(self)
                        
                        let userID = UIDevice.current.identifierForVendor!.uuidString
                        IronSource.setUserId(userID)
                        
                        // init with prelo official appkey
                        IronSource.initWithAppKey("60b14515", adUnits:[IS_REWARDED_VIDEO])
                        
                        // check ads mediation integration
                        ISIntegrationHelper.validateIntegration()
                    }
                    
                    self.setupView()
                    
                    // Prelo Analytic - Visit Product Detail
                    self.sendVisitProductDetailAnalytic()
                } else {
                    
                }
                self.hideLoading()
        }
    }
    
    func adjustButtonByStatus() {
        if (self.detail?.status == 0 && !((self.detail?.isFakeApproveV2)!)) { // Inactive or under review
            self.disableButton(self.btnUp)
            self.disableButton(self.btnSold)
        } else if (self.detail?.status == 2 && !((self.detail?.isFakeApprove)!) && !((self.detail?.isFakeApproveV2)!)) { // Under review (bukan v2)
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
        pDetailCover = ProductDetailCover.instance((detail?.displayPicturers)!, status: (detail?.status)!, topBannerText: (detail?.rejectionText), isFakeApprove: (detail?.isFakeApprove)!, isFakeApproveV2: (detail?.isFakeApproveV2)!, width: UIScreen.main.bounds.size.width)
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
        pDetailCover?.height = UIScreen.main.bounds.size.width * 340 / 480 + (pDetailCover?.topBannerHeight)!
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
    
    // MARK: - option button (right top)
    func setOptionButton() {
        let btnOption = self.createButtonWithIcon(AppFont.prelo2, icon: "")
        
        btnOption.addTarget(self, action: #selector(ProductDetailViewController.option), for: UIControlEvents.touchUpInside)
        
        self.navigationItem.rightBarButtonItem = btnOption.toBarButton()
    }
    
    func option() {
        
        let userid = CDUser.getOne()?.id
        let sellerid = detail?.theirId
        
        let a = UIAlertController(title: "Opsi", message: nil, preferredStyle: .actionSheet)
        a.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        if sellerid != userid && User.IsLoggedIn == true {
            a.addAction(UIAlertAction(title: "Laporkan Barang", style: .default, handler: { action in
                self.gotoReport()
                a.dismiss(animated: true, completion: nil)
            }))
        }
        a.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { action in
            a.dismiss(animated: true, completion: nil)
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(a, animated: true, completion: nil)
    }
    
    func gotoReport() {
        let productReportVC = Bundle.main.loadNibNamed(Tags.XibNameProductReport, owner: nil, options: nil)?.first as! ReportProductViewController
        productReportVC.root = self
        productReportVC.pDetail = self.detail
        self.navigationController?.pushViewController(productReportVC, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
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
                    self.delegate?.setFromDraftOrNew(true)
                }
                // Prelo Analytic - Share for Commission - Facebook
                self.sendShareForCommissionAnalytic((self.detail?.productID)!, productName: (self.detail?.name)!, fb: 1, tw: 0, ig: 0, reason: "")
            } else {
                let json = JSON((resp.result.value ?? [:]))
                let reason = json["_message"].stringValue
                
                // Prelo Analytic - Share for Commission - Facebook
                self.sendShareForCommissionAnalytic((self.detail?.productID)!, productName: (self.detail?.name)!, fb: 1, tw: 0, ig: 0, reason: reason)
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
                    self.delegate?.setFromDraftOrNew(true)
                }
                // Prelo Analytic - Share for Commission - Twitter
                self.sendShareForCommissionAnalytic((self.detail?.productID)!, productName: (self.detail?.name)!, fb: 0, tw: 1, ig: 0, reason: "")
            } else {
                let json = JSON((resp.result.value ?? [:]))
                let reason = json["_message"].stringValue
                
                // Prelo Analytic - Share for Commission - Twitter
                self.sendShareForCommissionAnalytic((self.detail?.productID)!, productName: (self.detail?.name)!, fb: 0, tw: 1, ig: 0, reason: reason)
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
                cellTitle?.cellDelegate = self
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
                        if let imgUrl = self.detail?.productImage {
                            let imgData = try? Data(contentsOf: imgUrl as URL)
                            let img = UIImage(data: imgData!)
                            let instagramSharePreview : InstagramSharePreview = .fromNib()
                            instagramSharePreview.textToShare.text = "\(textToShare)\(hashtags)"
                            instagramSharePreview.textToShare.layoutIfNeeded()
                            instagramSharePreview.imgToShare.image = img
                            instagramSharePreview.beforeDismissPreview = {
                                self.hideLoading()
                            }
                            instagramSharePreview.copyAndShare = {
                                UIPasteboard.general.string = "\(textToShare)\(hashtags)"
                                Constant.showDialog("Data telah disalin ke clipboard", message: "Silakan paste sebagai deskripsi post Instagram kamu")
                                self.delegate?.setFromDraftOrNew(true)
                                self.mgInstagram = MGInstagram()
                                self.mgInstagram?.post(img, withCaption: textToShare, in: self.view, delegate: self)
                                let _ = request(APIProduct.shareCommission(pId: (self.detail?.productID)!, instagram: "1", path: "0", facebook: "0", twitter: "0")).responseJSON { resp in
                                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Share Instagram")) {
                                        self.cellTitle?.sharedViaInstagram()
                                        self.detail?.setSharedViaInstagram()
                                        
                                        // Prelo Analytic - Share for Commission - Instagram
                                        self.sendShareForCommissionAnalytic((self.detail?.productID)!, productName: (self.detail?.name)!, fb: 0, tw: 0, ig: 1, reason: "")
                                    } else {
                                        let json = JSON((resp.result.value ?? [:]))
                                        let reason = json["_message"].stringValue
                                        
                                        // Prelo Analytic - Share for Commission - Instagram
                                        self.sendShareForCommissionAnalytic((self.detail?.productID)!, productName: (self.detail?.name)!, fb: 0, tw: 0, ig: 1, reason: reason)
                                    }
                                    self.hideLoading()
                                    instagramSharePreview.removeFromSuperview()
                                }
                            }
                            instagramSharePreview.frame = CGRect(x: 0, y: -64, width: AppTools.screenWidth, height: AppTools.screenHeight)
                            self.view.addSubview(instagramSharePreview)
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
            
            let userId = CDUser.getOne()?.id
            let senderId = cell.senderId
            
            if userId != senderId && cell.isDeleted == false {
            
                cell.showReportAlert = { sender, commentId in
                    let alert = UIAlertController(title: nil, message: "Laporkan Komentar", preferredStyle: .actionSheet)
                    alert.popoverPresentationController?.sourceView = sender
                    alert.popoverPresentationController?.sourceRect = sender.bounds
                    alert.addAction(UIAlertAction(title: "Mengganggu / spam", style: .default, handler: { act in
                        self.reportComment(commentId: commentId, reportType: 0, reportedUsername: (cell.captionName?.text!)!)
                        alert.dismiss(animated: true, completion: nil)
                    }))
                    alert.addAction(UIAlertAction(title: "Tidak layak", style: .default, handler: { act in
                        self.reportComment(commentId: commentId, reportType: 1, reportedUsername: (cell.captionName?.text!)!)
                        alert.dismiss(animated: true, completion: nil)
                    }))
                    alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in
                        alert.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                }
                
            } else{
                cell.doHide()
            }
            cell.goToProfile = { userId in
                if (!AppTools.isNewShop) {
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                    vc.currentMode = .shop
                    vc.shopId = userId
                    vc.previousScreen = self.thisScreen
                    
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let storePageTabBarVC = Bundle.main.loadNibNamed(Tags.XibNameStorePage, owner: nil, options: nil)?.first as! StorePageTabBarViewController
                    storePageTabBarVC.shopId = userId
                    storePageTabBarVC.previousScreen = self.thisScreen
                    self.navigationController?.pushViewController(storePageTabBarVC, animated: true)
                }
            }
            return cell
        }
    }
    
    func reportComment(commentId : String, reportType : Int, reportedUsername : String) {
        self.showLoading()
        request(APIProduct.reportComment(productId: (self.product?.id)!, commentId: commentId, reportType: reportType)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Laporkan Komentar")) {
                let json = JSON(resp.result.value!)
                if (json["_data"].boolValue == true) {
                    Constant.showDialog("Komentar Dilaporkan", message: "Terima kasih, Prelo akan meninjau laporan kamu")
                }
                
                // Prelo Analytic - Report Comment
                let loginMethod = User.LoginMethod ?? ""
                let reportingUsername = (CDUser.getOne()?.username)!
                let pdata = [
                    "Product ID" : (self.product?.id)!,
                    "Reported Username" : reportedUsername,
                    "Reporter Username" : reportingUsername,
                    "Reason" : reportType,
                    "Comment ID" : commentId
                ] as [String : Any]
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ReportComment, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
            }
            self.hideLoading()
        }
    }
    
    // MARK: - table delegate
    
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
        if ((indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 1)
        {
            if (!AppTools.isNewShop) {
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
                
                d.previousScreen = thisScreen
                
                self.navigationController?.pushViewController(d, animated: true)
            } else {
                let storePageTabBarVC = Bundle.main.loadNibNamed(Tags.XibNameStorePage, owner: nil, options: nil)?.first as! StorePageTabBarViewController
                storePageTabBarVC.shopId = detail?.json["_data"]["seller"]["_id"].string
                storePageTabBarVC.previousScreen = thisScreen
                self.navigationController?.pushViewController(storePageTabBarVC, animated: true)
            }
        }
    }
    
    // MARK: - Product cell delegate
    
    func cellTappedCategory(_ categoryName: String, categoryID: String) {
        let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
//        l.currentMode = .standalone
//        l.standaloneCategoryName = categoryName
//        l.standaloneCategoryID = categoryID
        l.currentMode = .filter
        l.fltrSortBy = "recent"
        l.fltrCategId = categoryID
        l.previousScreen = thisScreen
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    func cellTappedBrand(_ brandId: String, brandName: String) {
        let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        l.currentMode = .filter
        l.fltrSortBy = "recent"
        l.fltrBrands = [brandName : brandId]
        l.previousScreen = thisScreen
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    func cellTappedComment() {
        isNeedReload = true
    }
    
    // MARK: - button
    
    @IBAction func addToCart(_ sender: UIButton) {
        if (alreadyInCart) {
//            self.performSegue(withIdentifier: "segCart", sender: nil)
            let cart = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdCart) as! CartViewController
            cart.previousController = self
            cart.previousScreen = thisScreen
            self.navigationController?.pushViewController(cart, animated: true)
            return
        }
        
        if (CartProduct.newOne((detail?.productID)!, email : User.EmailOrEmptyString, name : (detail?.name)!) == nil) {
            Constant.showDialog("Failed", message: "Gagal Menyimpan")
        } else {
            // FB Analytics - Add to Cart
            let fbPdata: [String : Any] = [
                FBSDKAppEventParameterNameContentType          : "product",
                FBSDKAppEventParameterNameContentID            : (detail?.productID)!,
                FBSDKAppEventParameterNameCurrency             : "IDR"
            ]
            FBSDKAppEvents.logEvent(FBSDKAppEventNameAddedToCart, valueToSum: Double((detail?.priceInt)!), parameters: fbPdata)
            
            setupView()
//            self.performSegue(withIdentifier: "segCart", sender: nil)
            let cart = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdCart) as! CartViewController
            cart.previousController = self
            cart.previousScreen = thisScreen
            self.navigationController?.pushViewController(cart, animated: true)
        }
    }
        
    @IBAction func soldPressed(_ sender: AnyObject) {
        /*
        let alert : UIAlertController = UIAlertController(title: "Mark As Sold", message: "Apakah barang ini sudah terjual? (Aksi ini tidak bisa dibatalkan)", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: nil))
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
                            
                            self.delegate?.setFromDraftOrNew(true)
                            
                            // Prelo Analytic - Mark As Sold
                            let loginMethod = User.LoginMethod ?? ""
                            let pdata = [
                                "Product ID": productId,
                                "Screen" : PageName.ProductDetailMine
                            ] as [String : Any]
                            AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.MarkAsSold, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
                        } else {
                            Constant.showDialog("Failed", message: "Oops, terdapat kesalahan")
                        }
                    }
                    self.hideLoading()
                }
            }
        }))
        self.present(alert, animated: true, completion: nil)
         */
        
        let alertView = SCLAlertView(appearance: Constant.appearance)
        alertView.addButton("Ya") {
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
                            
                            self.delegate?.setFromDraftOrNew(true)
                            
                            // Prelo Analytic - Mark As Sold
                            let loginMethod = User.LoginMethod ?? ""
                            let pdata = [
                                "Product ID": productId,
                                "Screen" : PageName.ProductDetailMine
                                ] as [String : Any]
                            AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.MarkAsSold, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
                        } else {
                            Constant.showDialog("Failed", message: "Oops, terdapat kesalahan")
                        }
                    }
                    self.hideLoading()
                }
            }
        }
        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
        alertView.showCustom("Mark As Sold", subTitle: "Apakah barang ini sudah terjual? (Aksi ini tidak bisa dibatalkan)", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    @IBAction func editPressed(_ sender: AnyObject) {
        self.showLoading()
        
        isNeedReload = true
        
        let a = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        a.editMode = true
        a.editDoneBlock = {
            self.tableView?.isHidden = true
            self.getDetail()
        }
        a.topBannerText = (detail?.rejectionText)
        
        a.delegate = self.delegate
        
        a.screenBeforeAddProduct = PageName.ProductDetailMine
        
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
            t.previousScreen = thisScreen
            t.isSellerNotActive = d.IsShopClosed
            t.phoneNumber = d.SellerPhone
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
            isNeedReload = true
            
            self.performSegue(withIdentifier: "segAddComment", sender: nil)
        }
    }
    
    func userCancelLogin() {
        
    }
    
    func userLoggedIn() {
        if (loginComment)
        {
            isNeedReload = true
            
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
            
            isNeedReload = true
            
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
                            transactionDetailVC.previousScreen = self.thisScreen
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
        
        isNeedReload = true
        
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
            c.previousScreen = thisScreen
        } else
        {
            let c = segue.destination as! BaseViewController
            c.previousController = self
            c.previousScreen = thisScreen
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
                    let coinAmount = json["_data"]["diamond_amount"].intValue
                    let coin = json["_data"]["my_total_diamonds"].intValue
                    
                    if (isSuccess) {
                        // Prelo Analytic - Up Product - Free
                        self.sendUpProductAnalytic(productId, type: "Free")
                        
                        self.showUpPopUp(withText: message, isShowUpOther: true, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                    } else {
                        //self.showUpPopUp(withText: message, isShowUpOther: false, isShowPaidUp: true, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                        
                        self.launchNewPopUp(withText: message, paidAmount: paidAmount, preloBalance: preloBalance, poinAmount: coinAmount, poin: coin)
                    }
                }
                self.hideLoading()
            }
        }
    }
    
    func showUpPopUp(withText: String, isShowUpOther: Bool, isShowPaidUp: Bool, paidAmount: Int, preloBalance: Int, coinAmount: Int, coin: Int) {
        self.vwUpBarangPopUp.isHidden = false
        if (isShowUpOther) {
            self.lblUpOther.isHidden = false
            self.delegate?.setFromDraftOrNew(true)
        } else {
            self.lblUpOther.isHidden = true
        }
        if (isShowPaidUp) {
            self.vwBtnSet1UpBarang.isHidden = false
            self.vwBtnSet2UpBarang.isHidden = true
            
            if coin >= coinAmount { // with coin / diamond
                self.lblUpBarang.text = withText + "\n\n" + "Atau kamu bisa UP sekarang menggunakan " + coinAmount.string + " Poin\n\n"  + "Poin kamu sekarang: " + coin.string
                
                isCoinUse = true
                
                self.lblUpBarang.boldSubstring(coinAmount.string + " Poin")
                self.lblUpBarang.boldSubstring(coin.string)
                
            } else { // with prelo balance
                self.lblUpBarang.text = withText + "\n\n" + "Atau kamu bisa UP sekarang dengan membayar " + paidAmount.asPrice + " (akan otomatis ditarik dari Prelo Balance)\n\n"  + "Prelo Balance kamu: " + preloBalance.asPrice
            
                isCoinUse = false
                
                self.lblUpBarang.boldSubstring(paidAmount.asPrice)
                self.lblUpBarang.boldSubstring(preloBalance.asPrice)
                
            }
            
            self.lblUpBarang.boldSubstring("sekarang")
        } else {
            self.vwBtnSet1UpBarang.isHidden = true
            self.vwBtnSet2UpBarang.isHidden = false
            self.lblUpBarang.text = withText
            
            self.lblUpBarang.boldSubstring(paidAmount.asPrice)
            self.lblUpBarang.boldSubstring(coinAmount.string + " Poin")
        }
        self.lblUpBarang.sizeToFit()
        self.consHeightUpBarang.constant = 120 + lblUpBarang.height
        self.vwUpBarangPopUpPanel.setNeedsLayout()
        self.lblUpBarang.boldSubstring(coinAmount.string + " Poin")
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
            
            
            if isCoinUse == true {
            
                let _ = request(APIProduct.paidPushWithCoin(productId: productId)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Up Barang")) {
                        let json = JSON(resp.result.value!)
                        let isSuccess = json["_data"]["result"].boolValue
                        let message = json["_data"]["message"].stringValue
                        let paidAmount = json["_data"]["paid_amount"].intValue
                        let preloBalance = json["_data"]["my_prelo_balance"].intValue
                        let coinAmount = json["_data"]["diamond_amount"].intValue
                        let coin = json["_data"]["my_total_diamonds"].intValue
                        
                        if (isSuccess) {
                            // Prelo Analytic - Up Product - Point
                            self.sendUpProductAnalytic(productId, type: "Point")
                            
                            self.showUpPopUp(withText: message + " (" + coinAmount.string + " Poin kamu telah otomatis ditarik)", isShowUpOther: true, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                        } else {
                            self.showUpPopUp(withText: message, isShowUpOther: false, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                        }
                    }
                    self.hideLoading()
                }
                
            } else {
                
                let _ = request(APIProduct.paidPush(productId: productId)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Up Barang")) {
                        let json = JSON(resp.result.value!)
                        let isSuccess = json["_data"]["result"].boolValue
                        let message = json["_data"]["message"].stringValue
                        let paidAmount = json["_data"]["paid_amount"].intValue
                        let preloBalance = json["_data"]["my_prelo_balance"].intValue
                        let coinAmount = json["_data"]["diamond_amount"].intValue
                        let coin = json["_data"]["my_total_diamonds"].intValue
                        
                        if (isSuccess) {
                            // Prelo Analytic - Up Product - Balance
                            self.sendUpProductAnalytic(productId, type: "Balance")
                            
                            self.showUpPopUp(withText: message + " (" + paidAmount.asPrice + " telah otomatis ditarik dari Prelo Balance)", isShowUpOther: true, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                        } else {
                            self.showUpPopUp(withText: message, isShowUpOther: false, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                        }
                    }
                    self.hideLoading()
                }
            }
        }
    }
    
    // MARK: - Setup popup
    
    func launchNewPopUp(withText: String, paidAmount: Int, preloBalance: Int, poinAmount: Int, poin: Int) {
        self.setupPopUp(withText: withText, paidAmount: paidAmount, preloBalance: preloBalance, poinAmount: poinAmount, poin: poin)
        self.newPopup?.isHidden = false
        
        let isAdsAvailable = IronSource.hasRewardedVideo()
        print(isAdsAvailable)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.newPopup?.setupPopUp(isAdsAvailable)
            self.newPopup?.displayPopUp()
        })
    }
    
    func setupPopUp(withText: String, paidAmount: Int, preloBalance: Int, poinAmount: Int, poin: Int) {
        // setup popup
        if (self.newPopup == nil) {
            self.newPopup = Bundle.main.loadNibNamed("PaidPushPopup", owner: nil, options: nil)?.first as? PaidPushPopup
            self.newPopup?.frame = UIScreen.main.bounds
            self.newPopup?.tag = 100
            self.newPopup?.isHidden = true
            self.newPopup?.backgroundColor = UIColor.clear
            self.view.addSubview(self.newPopup!)
            
            self.newPopup?.initPopUp(withText: withText, paidAmount: paidAmount, preloBalance: preloBalance, poinAmount: poinAmount, poin: poin)
            
            self.newPopup?.disposePopUp = {
                self.newPopup?.isHidden = true
                self.newPopup = nil
                print("Start remove sibview")
                if let viewWithTag = self.view.viewWithTag(100) {
                    viewWithTag.removeFromSuperview()
                } else {
                    print("No!")
                }
            }
            
            self.newPopup?.balanceUsed = {
                self.isCoinUse = false
                self.showLoading()
                if let productId = self.detail?.productID {
                    let _ = request(APIProduct.paidPush(productId: productId)).responseJSON { resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Up Barang")) {
                            let json = JSON(resp.result.value!)
                            let isSuccess = json["_data"]["result"].boolValue
                            let message = json["_data"]["message"].stringValue
                            let paidAmount = json["_data"]["paid_amount"].intValue
                            let preloBalance = json["_data"]["my_prelo_balance"].intValue
                            let coinAmount = json["_data"]["diamond_amount"].intValue
                            let coin = json["_data"]["my_total_diamonds"].intValue
                            
                            if (isSuccess) {
                                // Prelo Analytic - Up Product - Balance
                                self.sendUpProductAnalytic(productId, type: "Balance")
                                
                                self.showUpPopUp(withText: message + " (" + paidAmount.asPrice + " telah otomatis ditarik dari Prelo Balance)", isShowUpOther: true, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                            } else {
                                self.showUpPopUp(withText: message, isShowUpOther: false, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                            }
                        }
                        self.hideLoading()
                    }
                }
            }
            
            self.newPopup?.poinUsed = {
                self.isCoinUse = true
                self.showLoading()
                if let productId = self.detail?.productID {
                    let _ = request(APIProduct.paidPushWithCoin(productId: productId)).responseJSON { resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Up Barang")) {
                            let json = JSON(resp.result.value!)
                            let isSuccess = json["_data"]["result"].boolValue
                            let message = json["_data"]["message"].stringValue
                            let paidAmount = json["_data"]["paid_amount"].intValue
                            let preloBalance = json["_data"]["my_prelo_balance"].intValue
                            let coinAmount = json["_data"]["diamond_amount"].intValue
                            let coin = json["_data"]["my_total_diamonds"].intValue
                            
                            if (isSuccess) {
                                // Prelo Analytic - Up Product - Point
                                self.sendUpProductAnalytic(productId, type: "Point")
                                
                                self.showUpPopUp(withText: message + " (" + coinAmount.string + " Poin kamu telah otomatis ditarik)", isShowUpOther: true, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                            } else {
                                self.showUpPopUp(withText: message, isShowUpOther: false, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                            }
                        }
                        self.hideLoading()
                    }
                }
            }
            
            self.newPopup?.watchVideoAds = {
                // open ads
                IronSource.showRewardedVideo(with: self, placement: "Up_Product")
                
                //  goto delegate
            }
        }
        
    }
    
    // Prelo Analytic - Up Product
    func sendUpProductAnalytic(_ productId: String, type: String) {
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            "Product ID" : productId,
            "Type" : type
        ]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.UpProduct, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
    }
    
    // Prelo Analytic - Share for Commission
    func sendShareForCommissionAnalytic(_ productId: String, productName: String, fb: Int, tw: Int, ig: Int, reason: String) {
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            "Product Name" : productName,
            "Product ID" : productId,
            "Username" : (CDUser.getOne()?.username)!,
            "Facebook" : fb,
            "Twitter" : tw,
            "Instagram" : ig,
            "Reason" : reason
        ] as [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ShareForCommission, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
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
    
    // Prelo Analytic - Visit Product Detail
    func sendVisitProductDetailAnalytic() {
        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.PreloAnalytic",
                                            qos: .background,
                                            target: nil)
        backgroundQueue.async {
            print("Work on background queue")
            
            let loginMethod = User.LoginMethod ?? ""
            
            // category
            var cat : Array<String> = []
            var catId : Array<String> = []
            
            let cb = (self.detail?.categoryBreadcrumbs)!
            
            for i in 1...cb.count-1 {
                cat.append(cb[i]["name"].stringValue)
                catId.append(cb[i]["_id"].stringValue)
            }
            
            // brand
            let brand = [
                "ID" : (self.detail?.json["_data"]["brand_id"].stringValue)!,
                "Name" : (self.detail?.json["_data"]["brand"].stringValue)!,
                "Verified" : !((self.detail?.json["_data"]["brand_under_review"].boolValue)!)
            ] as [String : Any]
            
            // segment
            var seg : Array<String> = []
            if let arr = (self.detail?.json["_data"]["segments"].arrayValue) {
                for i in arr {
                    seg.append(i.stringValue)
                }
            }
            
            // keywords
            var key : Array<String> = []
            if let arr = (self.detail?.json["_data"]["keywords"].arrayValue) {
                for i in arr {
                    key.append(i.stringValue)
                }
            }
            
            let pdata = [
                "Product ID": (self.product?.id)!,
                "Seller ID" : (self.detail?.json["_data"]["seller"]["_id"].stringValue)!,
                "Brand" : brand,
                "Category Names" : cat,
                "Category IDs" : catId,
                "Segments" : seg,
                "Keywords" : key
            ] as [String : Any]
            
            AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.VisitProductDetail, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
            
        }
    }
    
    // MARK: - Ads delegate
    //MARK: ISRewardedVideoDelegate Functions
    /**
     Called after a rewarded video has changed its availability.
     
     @param available The new rewarded video availability. YES if available and ready to be shown, NO otherwise.
     */
    public func rewardedVideoHasChangedAvailability(_ available: Bool) {
    }
    
    /**
     Called after a rewarded video has finished playing.
     */
    public func rewardedVideoDidEnd() {
    }
    
    /**
     Called after a rewarded video has started playing.
     */
    public func rewardedVideoDidStart() {
    }
    
    /**
     Called after a rewarded video has been dismissed.
     */
    public func rewardedVideoDidClose() {
        //Constant.showDialog("Watch Video", message: "yey")
    }
    
    /**
     Called after a rewarded video has been opened.
     */
    public func rewardedVideoDidOpen() {
    }
    
    /**
     Called after a rewarded video has attempted to show but failed.
     
     @param error The reason for the error
     */
    public func rewardedVideoDidFailToShowWithError(_ error: Error!) {
        Constant.showDialog("Oops", message: "Terdapat kesalahan sewaktu memulai video")
        //let err = (error! as NSError)
        //Constant.showDialog("Oops", message: err.description)
    }
    
    /**
     Called after a rewarded video has been viewed completely and the user is eligible for reward.
     
     @param placementInfo An object that contains the placement's reward name and amount.
     */
    public func didReceiveReward(forPlacement placementInfo: ISPlacementInfo!) {
        self.showLoading()
        if let productId = detail?.productID {
            let _ = request(APIProduct.paidPushWithWatchVideo(productId: productId)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Up Barang")) {
                    let json = JSON(resp.result.value!)
                    let isSuccess = json["_data"]["result"].boolValue
                    let message = json["_data"]["message"].stringValue
                    let paidAmount = json["_data"]["paid_amount"].intValue
                    let preloBalance = json["_data"]["my_prelo_balance"].intValue
                    let coinAmount = json["_data"]["diamond_amount"].intValue
                    let coin = json["_data"]["my_total_diamonds"].intValue
                    
                    if (isSuccess) {
                        // Prelo Analytic - Up Product - Video
                        self.sendUpProductAnalytic(productId, type: "Video")
                        
                        self.showUpPopUp(withText: message, isShowUpOther: true, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                    } else {
                        self.showUpPopUp(withText: message, isShowUpOther: false, isShowPaidUp: false, paidAmount: paidAmount, preloBalance: preloBalance, coinAmount: coinAmount, coin: coin)
                    }
                }
                self.hideLoading()
            }
        }
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
    
    var parent : BaseViewController?
    
    var product : Product?
    var detail : ProductDetail?
    
    weak var cellDelegate : ProductCellDelegate?
    
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
            self.cellDelegate?.cellTappedComment()
            
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
        /*
        // Mixpanel
        let pt = [
            "Product Name" : ((product != nil) ? (product!.name) : ""),
            "Category 1" : ((detail != nil && detail?.categoryBreadcrumbs.count > 1) ? (detail!.categoryBreadcrumbs[1]["name"].string!) : ""),
            "Category 2" : ((detail != nil && detail?.categoryBreadcrumbs.count > 2) ? (detail!.categoryBreadcrumbs[2]["name"].string!) : ""),
            "Category 3" : ((detail != nil && detail?.categoryBreadcrumbs.count > 3) ? (detail!.categoryBreadcrumbs[3]["name"].string!) : ""),
            "Seller Name" : ((detail != nil) ? (detail!.theirName) : "")
        ]
        Mixpanel.trackEvent(MixpanelEvent.ToggledLikeProduct, properties: pt)
         */
        
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
                
                // Prelo Analytic - Love
                let loginMethod = User.LoginMethod ?? ""
                let pdata = [
                    "Product ID": ((self.product != nil) ? (self.product!.id) : ""),
                    "Seller ID" : ((self.product != nil) ? (self.product!.json["seller_id"].stringValue) : ""),
                    "Screen" : PageName.ProductDetail,
                    "Is Featured" : ((self.product != nil) ? (self.product!.isFeatured) : false)
                ] as [String : Any]
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.LoveProduct, data: pdata, previousScreen: self.parent!.previousScreen, loginMethod: loginMethod)
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
                
                // Prelo Analytic - UnLove
                let loginMethod = User.LoginMethod ?? ""
                let pdata = [
                    "Product Id": ((self.product != nil) ? (self.product!.id) : ""),
                    "Seller ID" : ((self.product != nil) ? (self.product!.json["seller_id"].stringValue) : ""),
                    "Screen" : PageName.ProductDetail,
                    "Is Featured" : ((self.product != nil) ? (self.product!.isFeatured) : false)
                ] as [String : Any]
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.UnloveProduct, data: pdata, previousScreen: self.parent!.previousScreen, loginMethod: loginMethod)
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

class ProductCellSeller : UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate
{
    @IBOutlet weak var captionSellerName : UILabel?
    @IBOutlet weak var captionSellerRating : UILabel?
    @IBOutlet weak var captionLastSeen: UILabel!
    @IBOutlet weak var ivSellerAvatar : UIImageView?
    @IBOutlet weak var collectionView: UIView! // parent of achievement
    @IBOutlet weak var badgeCollectionView: UICollectionView! // achievement
    @IBOutlet weak var consWidthCollectionView: NSLayoutConstraint!
    
    var badges : Array<URL>! = []
    
    // love floatable
    @IBOutlet var vwLove: UIView!
    var floatRatingView: FloatRatingView!
    
    static func heightFor(_ obj : JSON?)->CGFloat
    {
        return 86
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        ivSellerAvatar?.afCancelRequest()
    }
    
    func adapt(_ obj : ProductDetail?)
    {
        if (obj == nil) {
            return
        }
        var product = (obj?.json)!["_data"]
        
        captionSellerName?.text = product["seller"]["username"].stringValue
        let average_star = product["seller"]["average_star"].floatValue
//        var stars = ""
//        for x in 0...4
//        {
//            if (Float(x) <= average_star - 0.5)
//            {
//                stars = stars+""
//            } else
//            {
//                stars = stars+""
//            }
//        }
//        captionSellerRating?.text = stars
        
        // Love floatable
        self.floatRatingView = FloatRatingView(frame: CGRect(x: 0, y: 0, width: 90, height: 16))
        self.floatRatingView.emptyImage = UIImage(named: "ic_love_96px_trp.png")?.withRenderingMode(.alwaysTemplate)
        self.floatRatingView.fullImage = UIImage(named: "ic_love_96px.png")?.withRenderingMode(.alwaysTemplate)
        // Optional params
        //                self.floatRatingView.delegate = self
        self.floatRatingView.contentMode = UIViewContentMode.scaleAspectFit
        self.floatRatingView.maxRating = 5
        self.floatRatingView.minRating = 0
        self.floatRatingView.rating = average_star
        self.floatRatingView.editable = false
        self.floatRatingView.halfRatings = true
        self.floatRatingView.floatRatings = true
        self.floatRatingView.tintColor = Theme.ThemeRed
        
        self.vwLove.addSubview(self.floatRatingView )
        
        let lastSeenSeller = obj!.lastSeenSeller
        if (lastSeenSeller != "") {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let lastSeenDate = formatter.date(from: lastSeenSeller) {
                captionLastSeen.text = "Terakhir aktif: \(lastSeenDate.relativeDescription)"
            }
        }

        ivSellerAvatar?.afSetImage(withURL: (obj?.shopAvatarURL)!, withFilter: .circle)
        
        // reset
        badges = []
        consWidthCollectionView.constant = 0
        
        if let arr = product["seller"]["achievements"].array {
//            for i in arr {
//                let ach = AchievementItem.instance(i)
//                
//                self.badges.append((ach?.icon)!)
//            }
            
            if arr.count > 0 {
                let ach = AchievementItem.instance(arr[0])
                
                self.badges.append((ach?.icon)!)
                
                setupCollection()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ivSellerAvatar?.layoutIfNeeded()
        ivSellerAvatar?.layer.cornerRadius = (ivSellerAvatar?.frame.size.width)!/2
        ivSellerAvatar?.layer.masksToBounds = true
        
        ivSellerAvatar?.layer.borderColor = Theme.GrayLight.cgColor
        ivSellerAvatar?.layer.borderWidth = 2
    }
    
    func setupCollection() {
        
        let width = CGFloat(28) //21 * CGFloat(self.badges!.count) + 1
        
        // Set collection view
        self.badgeCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcProgressCell")
        self.badgeCollectionView.delegate = self
        self.badgeCollectionView.dataSource = self
        self.badgeCollectionView.backgroundView = UIView(frame: self.badgeCollectionView.bounds)
        self.badgeCollectionView.backgroundColor = UIColor.clear
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 28, height: 28)
//        layout.minimumInteritemSpacing = 1
//        layout.minimumLineSpacing = 1
        self.badgeCollectionView.collectionViewLayout = layout
        
        self.badgeCollectionView.isScrollEnabled = false
        self.consWidthCollectionView.constant = width
        
        self.collectionView.isHidden = false
    }
    
    // MARK: - CollectionView delegate functions
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.badges!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = self.badgeCollectionView.dequeueReusableCell(withReuseIdentifier: "collcProgressCell", for: indexPath)
        // Create icon view
        let vwIcon : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
        
//        vwIcon.layer.cornerRadius = vwIcon.frame.size.width/2
//        vwIcon.layer.masksToBounds = true
//        vwIcon.backgroundColor = UIColor.white
        
        let img = UIImageView(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
        img.layoutIfNeeded()
        img.layer.cornerRadius = (img.width ) / 2
        img.layer.masksToBounds = true
        img.afSetImage(withURL: badges[(indexPath as NSIndexPath).row], withFilter: .circleWithBadgePlaceHolder)
        
        vwIcon.addSubview(img)
        
        img.frame = vwIcon.bounds
        
        // Add view to cell
        cell.addSubview(vwIcon)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 28, height: 28)
    }
}

class ProductCellDescription : UITableViewCell, ZSWTappableLabelTapDelegate
{
    @IBOutlet weak var captionSpecialStory: UILabel!
    @IBOutlet weak var captionWeight : UILabel!
    @IBOutlet weak var captionCondition : UILabel!
    @IBOutlet weak var captionFrom : UILabel!
    @IBOutlet weak var captionAlasanJual : UILabel!
    @IBOutlet weak var captionMerk : ZSWTappableLabel?
    @IBOutlet weak var captionCategory : ZSWTappableLabel?
    @IBOutlet weak var captionDesc : UILabel!
    @IBOutlet weak var captionDate : UILabel!
    @IBOutlet weak var captionCacat: UILabel!
    @IBOutlet weak var captionUkuran: UILabel!
    
    @IBOutlet weak var consHeightWaktuJaminan: NSLayoutConstraint!
    
    @IBOutlet weak var consHeightUkuran: NSLayoutConstraint!
    @IBOutlet weak var consHeightCacat: NSLayoutConstraint!
    
    weak var cellDelegate : ProductCellDelegate?
    
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
        let desc2 : NSString = NSString(string: desc)
        
        var desc3 : NSString = NSString(string: "")
        if let ss = obj?.specialStory
        {
            if (ss != "")
            {
                desc3 = NSString(string: " " + ss)
            }
        }
        
        let size = desc3.boundingRect(with: cons, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil)
        
        let size2 = desc2.boundingRect(with: cons, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil)
        
        let string : String = "Waktu Jaminan Prelo. Belanja bergaransi dengan waktu jaminan hingga 3x24 jam setelah status barang \"Diterima\" jika barang terbukti KW, memiliki cacat yang tidak diinformasikan, atau berbeda dari yang dipesan."
        
        let s = string.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: UIScreen.main.bounds.size.width-66)
        
        let arr = product["category_breadcrumbs"].array!
        var categoryString : String = ""
        if (arr.count > 0) {
            for i in 0...arr.count-1
            {
                let d = arr[i]
                let name = d["name"].string!
                categoryString += name
                if (i != arr.count-1) {
                    categoryString += "  "
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
        
        // cacat
        let condition = product["condition"].string
        let cacat = product["defect_description"].string
        var defectSize = CGFloat(0)
        if cacat != nil && cacat != "" && condition == "Cukup ( < 70%)" {
            defectSize = 21
        }
        
        // ukuran
        let ukuran = product["size"].string
        var sizeSize = CGFloat(0)
        if ukuran != nil && ukuran != "" {
            sizeSize = 21
        }
        
        let control = CGFloat((desc2 == "" && desc3 == "") ? -40 : ((desc2 == "" || desc3 == "") ? -20 : 0))
//        let control = CGFloat((desc2 == "") ? -40 : ((desc3 == "") ? -20 : 0))
        
        return 163+size.height+size2.height+s.height+cs.height+8+8+cs2Size.height+8+alSize.height+defectSize+sizeSize+control
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
                desc = " " + ss
            }
        }
        
        let attrStr = NSMutableAttributedString(string: desc)
//        attrStr.addAttributes([NSForegroundColorAttributeName:Theme.GrayDark], range: NSMakeRange(0, desc.length))
        attrStr.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColor], range: (desc as NSString).range(of: ""))
        attrStr.addAttributes([NSFontAttributeName:UIFont(name: "preloAwesome", size: 17.0)!], range: (desc as NSString).range(of: ""))
        
        captionSpecialStory?.text = desc
        captionSpecialStory?.attributedText = attrStr
        
        
        captionDesc?.text = product["description"].string!
        captionDate?.text = product["time"].string!
        
        let condition = product["condition"].string
        captionCondition?.text = condition!
        
        let cacat = product["defect_description"].string
        if cacat != nil && cacat != "" && condition == "Cukup ( < 70%)" {
            captionCacat?.text = product["defect_description"].string!
            consHeightCacat.constant = 21
        } else {
            consHeightCacat.constant = 0
        }
        
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
        
        let w = obj!.weight
        if (w > 1000)
        {
            captionWeight?.text = (Float(w) / 1000.0).clean + " kg"
        } else {
            captionWeight?.text = w.description + " gram"
        }
        
        let ukuran = product["size"].string
        if ukuran != nil && ukuran != "" {
            captionUkuran?.text = ukuran
            consHeightUkuran.constant = 21
        } else {
            consHeightUkuran.constant = 0
        }
        
        let arr = product["category_breadcrumbs"].array!
        var categoryString : String = ""
        var param : Array<[String : Any]> = []
        if (arr.count > 0) {
            for i in 1...arr.count-1
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
                    categoryString += "  "
                }
            }
        }
        
        let mystr = categoryString
        let searchstr = ""
        let ranges: [NSRange]
        
        do {
            // Create the regular expression.
            let regex = try NSRegularExpression(pattern: searchstr, options: [])
            
            // Use the regular expression to get an array of NSTextCheckingResult.
            // Use map to extract the range from each result.
            ranges = regex.matches(in: mystr, options: [], range: NSMakeRange(0, mystr.characters.count)).map {$0.range}
        }
        catch {
            // There was a problem creating the regular expression
            ranges = []
        }
        
        print(ranges)  // prints [(0,3), (18,3), (27,3)]
        
        let attString : NSMutableAttributedString = NSMutableAttributedString(string: categoryString)
        for p in param
        {
            let r = NSRangeFromString(p["range"] as! String)
            attString.addAttributes(p, range: r)
            if ranges.count > 0 {
                for i in 0...ranges.count-1 {
                    attString.addAttributes([NSFontAttributeName:UIFont(name: "prelo2", size: 14.0)!], range: ranges[i])
                }
            }

        }
        
        captionCategory?.attributedText = attString
        
        var sellReason = (obj?.sellReason)!
        if (sellReason == "")
        {
            sellReason = "-"
        }
        
        captionAlasanJual?.numberOfLines = 0
        captionAlasanJual?.text = sellReason
        
        let string : String = "Waktu Jaminan Prelo. Belanja bergaransi dengan waktu jaminan hingga 3x24 jam setelah status barang \"Diterima\" jika barang terbukti KW, memiliki cacat yang tidak diinformasikan, atau berbeda dari yang dipesan."
        
        let s2 = string.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: UIScreen.main.bounds.size.width-66)
        
        self.consHeightWaktuJaminan.constant = s2.height
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
    @IBOutlet weak var lblReport: UIButton!
    
    var commentId : String = ""
    var senderId : String = ""
    var isDeleted : Bool = false
    
    var showReportAlert : (UIView, String) -> () = { _, _ in }
    var goToProfile : (String) -> () = { _ in }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        ivCover?.afCancelRequest()
    }
    
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
    
    func setupCover() {
        ivCover?.layoutIfNeeded()
        ivCover?.layer.cornerRadius = (ivCover?.frame.size.width)!/2
        ivCover?.layer.masksToBounds = true
        
        ivCover?.layer.borderColor = Theme.GrayLight.cgColor
        ivCover?.layer.borderWidth = 2
    }
    
    func adapt(_ obj : ProductDiscussion?)
    {
        if (obj == nil) {
            return
        }
        setupCover()
        
        var json = (obj?.json)!
        commentId = json["_id"].stringValue
        senderId = json["sender_id"].stringValue
        
        captionDate?.text = json["time"].string!
        captionMessage?.text = obj?.message
        if (obj!.isDeleted) {
            captionMessage?.font = UIFont.italicSystemFont(ofSize: 13)
            captionMessage?.textColor = UIColor.lightGray
            isDeleted = true
        } else {
            captionMessage?.font = UIFont.systemFont(ofSize: 13)
            captionMessage?.textColor = UIColor.darkGray
        }
        captionName?.text = json["sender_username"].string!
        ivCover?.afSetImage(withURL: (obj?.posterImageURL)!, withFilter: .circle)
        
        if (User.IsLoggedIn) {
            consWidthBtnReport.constant = 25
        } else {
            consWidthBtnReport.constant = 0
        }
    }
    
    func doHide() {
        consWidthBtnReport.constant = 0
    }
    
    @IBAction func btnReportPressed(_ sender: UIView) {
        self.showReportAlert(sender, commentId)
    }
    
    @IBAction func btnUsernamePressed(_ sender: AnyObject) {
        self.goToProfile(senderId)
    }
}

class PaidPushPopup: UIView {
    @IBOutlet weak var vwBackgroundOverlay: UIView!
    @IBOutlet weak var vwOverlayPopUp: UIView!
    @IBOutlet weak var vwPopUp: UIView!
    @IBOutlet weak var vwVideoUp: UIView! // hidden
    @IBOutlet weak var consCenteryPopUp: NSLayoutConstraint!
    @IBOutlet weak var consBottomSeparatorToVideo: NSLayoutConstraint! // 0 -> 67
    @IBOutlet weak var lbDescription: UILabel!
    @IBOutlet weak var lbBalanceUsed: UILabel!
    @IBOutlet weak var lbPoinUsed: UILabel!
    @IBOutlet weak var lbWatchVideo: UILabel!
    @IBOutlet weak var btnBalanceUsed: UIButton! // enable
    @IBOutlet weak var btnPoinUsed: UIButton! // enable
    @IBOutlet weak var btnWatchVideo: UIButton!
    @IBOutlet weak var imgBalanceUsed: TintedImageView!
    @IBOutlet weak var imgPoinUsed: TintedImageView!
    @IBOutlet weak var lbTitleBalanceUsed: UILabel!
    @IBOutlet weak var lbTitlePoinUsed: UILabel!
    @IBOutlet weak var lbTitleWatchVideo: UILabel!
    @IBOutlet weak var consHeightSeparatorToVideo: NSLayoutConstraint! // 0 -> 1
    
    let gray = UIColor(hexString: "#939393")
    
    var disposePopUp : ()->() = {}
    var balanceUsed : ()->() = {}
    var poinUsed : ()->() = {}
    var watchVideoAds : ()->() = {}
    
    func setupPopUp(_ isAdsLoaded: Bool) {
        if isAdsLoaded {
            self.vwVideoUp.isHidden = false
            self.consBottomSeparatorToVideo.constant = 67
            
            self.consHeightSeparatorToVideo.constant = 1
            
            self.lbTitleWatchVideo.textColor = Theme.PrimaryColorDark
            self.lbWatchVideo.textColor = gray
            
            self.btnWatchVideo.isEnabled = true
            //self.btnWatchVideo.backgroundColor = UIColor.clear
        } else {
            self.vwVideoUp.isHidden = true
            self.consBottomSeparatorToVideo.constant = 0
            
            self.consHeightSeparatorToVideo.constant = 0
            
            self.lbTitleWatchVideo.textColor = Theme.GrayLight
            self.lbWatchVideo.textColor = Theme.GrayLight
            
            self.btnWatchVideo.isEnabled = false
            //self.btnWatchVideo.backgroundColor = UIColor.lightGray.alpha(0.3)
        }
    }
    
    func initPopUp(withText: String, paidAmount: Int, preloBalance: Int, poinAmount: Int, poin: Int) {
        let path = UIBezierPath(roundedRect:vwPopUp.bounds,
                                byRoundingCorners:[.topRight, .topLeft],
                                cornerRadii: CGSize(width: 4, height:  4))
        
        let maskLayer = CAShapeLayer()
        
        maskLayer.path = path.cgPath
        vwPopUp.layer.mask = maskLayer
        
        // Transparent panel
        self.vwBackgroundOverlay.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        
        self.vwBackgroundOverlay.isHidden = false
        self.vwOverlayPopUp.isHidden = false
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        
        // setup content
        self.lbDescription.text = withText + "\n\n" + "Atau kamu bisa UP sekarang dengan cara:"
        
        self.lbPoinUsed.text = poinAmount.string + " poin akan berkurang untuk satu kali UP. Poin kamu sekarang " + poin.string
        self.lbPoinUsed.boldSubstring(poinAmount.string + " poin")
        self.lbPoinUsed.boldSubstring(poin.string)
        
        if (poinAmount <= poin) {
            self.btnPoinUsed.isEnabled = true
            //self.btnPoinUsed.backgroundColor = UIColor.clear
            
            self.lbTitlePoinUsed.textColor = Theme.PrimaryColorDark
            self.lbPoinUsed.textColor = gray
            
            self.imgPoinUsed.tint = false
            self.imgPoinUsed.tintColor = UIColor.clear
        } else {
            self.btnPoinUsed.isEnabled = false
            //self.btnPoinUsed.backgroundColor = UIColor.lightGray.alpha(0.3)
            
            self.lbTitlePoinUsed.textColor = Theme.GrayLight
            self.lbPoinUsed.textColor = Theme.GrayLight
            
            self.imgPoinUsed.tint = true
            self.imgPoinUsed.tintColor = Theme.GrayLight
        }
        
        self.lbBalanceUsed.text = paidAmount.asPrice + " akan ditarik dari Prelo Balance kamu untuk satu kali UP. Prelo Balance kamu " + preloBalance.asPrice
        self.lbBalanceUsed.boldSubstring(paidAmount.asPrice)
        self.lbBalanceUsed.boldSubstring(preloBalance.asPrice)
        
        if (paidAmount <= preloBalance) {
            self.btnBalanceUsed.isEnabled = true
            //self.btnBalanceUsed.backgroundColor = UIColor.clear
            
            self.lbTitleBalanceUsed.textColor = Theme.PrimaryColorDark
            self.lbBalanceUsed.textColor = gray
        
            self.imgBalanceUsed.tint = false
            self.imgBalanceUsed.tintColor = UIColor.clear
        } else {
            self.btnBalanceUsed.isEnabled = false
            //.btnBalanceUsed.backgroundColor = UIColor.lightGray.alpha(0.3)
        
            self.lbTitleBalanceUsed.textColor = Theme.GrayLight
            self.lbBalanceUsed.textColor = Theme.GrayLight
        
            self.imgBalanceUsed.tint = true
            self.imgBalanceUsed.tintColor = Theme.GrayLight
        }
    }
    
    func displayPopUp() {
        let screenSize = self.bounds
        let screenHeight = screenSize.height
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = (screenHeight - self.vwPopUp.frame.height) / 2 - 32
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = -32
    }
    
    func unDisplayPopUp() {
        let screenSize = self.bounds
        let screenHeight = screenSize.height
        
        // force to bottom first
        self.consCenteryPopUp.constant = 0
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = screenHeight + (screenHeight - self.vwPopUp.frame.height) / 2 - 32
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = screenHeight
    }
    
    @IBAction func btnBalancePressed(_ sender: Any) {
        self.unDisplayPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.balanceUsed()
            self.disposePopUp()
        })
    }
    
    @IBAction func btnPoinPressed(_ sender: Any) {
        self.unDisplayPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.poinUsed()
            self.disposePopUp()
        })
    }
    
    @IBAction func btnVideoPressed(_ sender: Any) {
        self.unDisplayPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.watchVideoAds()
            self.disposePopUp()
        })
    }
    
    @IBAction func btnTidakPressed(_ sender: Any) {
        self.unDisplayPopUp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.disposePopUp()
        })
    }
}
