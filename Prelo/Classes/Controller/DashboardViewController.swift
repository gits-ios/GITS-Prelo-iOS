//
//  DashboardViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/28/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import MessageUI
import Alamofire

// MARK: - Class

class DashboardViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, PickerViewDelegate {

    @IBOutlet var tableView : UITableView?
    @IBOutlet var captionName : UILabel?
    @IBOutlet var imgCover : UIImageView?
    
    @IBOutlet var vwTopMenu: UIView!
    @IBOutlet var ivLove  : UIImageView?
    @IBOutlet var ivRequest: UIImageView?
    @IBOutlet weak var ivVoucher: UIImageView?
    
    let VwTopMenuHeightLoggedOut : CGFloat = 96
    
    @IBOutlet weak var vwHeaderLoggedIn: UIView!
    @IBOutlet weak var vwHeaderLoggedOut: UIView!
    
    var menus : Array<[String : String]>?
    
    var contactUs : UIViewController?
    
    var feedback: FeedbackPopup?
    
    @IBOutlet weak var btnEdit: UIButton!
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set button
        let insetBtn = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        
        btnEdit.setImage(UIImage(named: "ic_edit_white"), for: .normal)
        btnEdit.imageView?.contentMode = .scaleAspectFit
        btnEdit.imageEdgeInsets = insetBtn
        
        // regiter cell
        
        tableView?.register(BottomCell.self, forCellReuseIdentifier: "BottomCell")
        
        let c = CDUser.getOne()
        captionName?.text = c?.username
        
        if let i = UIImage(named: "ic_lovelist") {
            ivLove?.tintColor = Theme.PrimaryColor
            ivLove?.image = i.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        }
        
        if let i2 = UIImage(named: "ic_tshirt") {
            ivRequest?.tintColor = Theme.PrimaryColor
            ivRequest?.image = i2.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        }
    
        if let i3 = UIImage(named: "ic_belanjaan_saya") {
            ivVoucher?.tintColor = Theme.PrimaryColor
            ivVoucher?.image = i3.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        }

        //self.setupNormalOptions()
        self.setupTitle()

        if (User.IsLoggedIn) {
            vwHeaderLoggedIn.isHidden = false
            vwHeaderLoggedOut.isHidden = true
            menus = [
                [
                    "type":"iconic",
                    "title":"Request",
                    "iconimg":"ic_request",
                ],
                [
                    "type":"iconic",
                    "title":"Tarik Uang",
                    "iconimg":"ic_tarik_uang",
                ],
                [
                    "type":"iconic",
                    "title":"Referral Bonus",
                    "iconimg":"ic_voucher"
                ],
                [
                    "type":"iconic",
                    "title":"Achievement",
                    "iconimg":"ic_achievement"
                ],
                [
                    "type":"iconic",
                    "title":"Bantuan",
                    "iconimg":"ic_faq"
                ],
                [
                    "type":"text-separator",
                    "title":"Feedback",
                ],
                [
                    "type":"text",
                    "title":"About",
                    "iconimg":"ic_about" // not uses
                ],
                [
                    "type":"blank"
                ]
            ]
        } else {
            vwHeaderLoggedIn.isHidden = true
            vwHeaderLoggedOut.isHidden = false
            let vwTopMenuFrame = vwTopMenu.frame
            vwTopMenu.frame = CGRect(x: vwTopMenuFrame.origin.x, y: vwTopMenuFrame.origin.y, width: vwTopMenuFrame.width, height: VwTopMenuHeightLoggedOut)
            menus = [
                [
                    "type":"iconic",
                    "title":"Referral Bonus",
                    "iconimg":"ic_voucher"
                ],
                [
                    "type":"iconic",
                    "title":"Bantuan",
                    "iconimg":"ic_faq"
                ],
                [
                    "type":"text-separator",
                    "title":"About",
                    "iconimg":"ic_about" // not use
                ]

            ]
        }
        
        
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.tableFooterView = UIView()
        
        tableView?.contentInset = UIEdgeInsetsMake(0, 0, 40, 0)
        
        
        imgCover?.layer.cornerRadius = (imgCover?.frame.size.width)!/2
        imgCover?.layer.masksToBounds = true
        
        imgCover?.layer.borderColor = Theme.GrayLight.cgColor
        imgCover?.layer.borderWidth = 3
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (User.IsLoggedIn) {
            // Mixpanel
//            Mixpanel.trackPageVisit(PageName.DashboardLoggedIn)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.DashboardLoggedIn)
        } else {
            // Mixpanel
//            Mixpanel.trackPageVisit(PageName.DashboardLoggedOut)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.DashboardLoggedOut)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        imgCover?.image = UIImage(named: "placeholder-circle.png") //UIImage(named: "ic_user_2.png")
        let uProf = CDUserProfile.getOne()
        if (uProf != nil) {
            let url = URL(string: uProf!.pict)
            if (url != nil) {
                imgCover?.afSetImage(withURL: url!, withFilter: .circle)
            }
        }
        
        // Redirect if any
        let redirectFromHome : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.RedirectFromHome) as! String?
        if (redirectFromHome != nil) {
            if (redirectFromHome == PageName.MyOrders) {
                let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
                self.previousController?.navigationController?.pushViewController(myPurchaseVC, animated: true)
            } else if (redirectFromHome == PageName.UnpaidTransaction) {
                // deprecated
                /*
                let paymentConfirmationVC = Bundle.main.loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil)?.first as! PaymentConfirmationViewController
                self.previousController!.navigationController?.pushViewController(paymentConfirmationVC, animated: true)
                */
            }
            UserDefaults.standard.removeObject(forKey: UserDefaultsKey.RedirectFromHome)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view delegate functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (menus?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let m : [String : String] = (menus?.objectAtCircleIndex((indexPath as NSIndexPath).row))!
        
        if m["type"] == "iconic" {
            let cell : DashboardCell = tableView.dequeueReusableCell(withIdentifier: "cell") as! DashboardCell
            
            // clean
            if (cell.viewWithTag(888) != nil) {
                cell.viewWithTag(888)?.removeFromSuperview()
            }
            
            if let isPreloAwesome = m["PreloAwesome"] { // Icon is from font
                if (isPreloAwesome == "1") {
                    cell.captionIcon?.font = AppFont.preloAwesome.getFont(24)!
                } else {
                    cell.captionIcon?.font = AppFont.prelo2.getFont(24)!
                }
                cell.captionIcon?.text = m["icon"]
            } else { // Icon is from image
                cell.captionIcon?.text = ""
                let img = UIImage(named: m["iconimg"]!)
                let iconImg = UIImageView(image: img)
                iconImg.tintColor = Theme.PrimaryColorDark
                iconImg.frame = CGRect(x: 8, y: 10, width: 26, height: 26)
                iconImg.tag = 888
                cell.addSubview(iconImg)
            }
            
            cell.captionTitle?.text = m["title"]
            cell.selectionStyle = .none
            return cell
            
        } else if m["type"] == "text" || m["type"] == "text-separator" {
            let cell: BottomCell = tableView.dequeueReusableCell(withIdentifier: "BottomCell") as! BottomCell
            
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
            cell.textLabel?.textColor = UIColor(hex: "555555")
            
            cell.textLabel!.text = m["title"]
            cell.selectionStyle = .none
            
            if m["type"] == "text-separator" {
                let inView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.width, height: 1), backgroundColor: UIColor(hex: "AAAAAA"))
            
                cell.contentView.addSubview(inView)
            } else {
                
                cell.contentView.removeAllSubviews()
            }
            return cell

        } else {
            let cell: BottomCell = tableView.dequeueReusableCell(withIdentifier: "BottomCell") as! BottomCell
            cell.textLabel!.text = ""
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (User.IsLoggedIn) {
            if ((indexPath as NSIndexPath).row == 0) { // Request barang
                self.launchRequestBarang()
            } else if ((indexPath as NSIndexPath).row == 1) { // Tarik uang
                self.launchTarikUang()
            } else if ((indexPath as NSIndexPath).row == 2) { // Referral bonus
                self.launchFreeVoucher()
            } else if ((indexPath as NSIndexPath).row == 3) { // Achievement
                self.launchAchievement()
            } else if ((indexPath as NSIndexPath).row == 4) { // Bantuan
                self.launchFAQ()
            } else if ((indexPath as NSIndexPath).row == 5) { // Feedback
                self.launchRateUs()
            } else if ((indexPath as NSIndexPath).row == 6) { // About
                self.launchAbout()
            } else if (AppTools.isDev) { // row 7
                self.lauchTestingFeature()
            }
        } else {
            if ((indexPath as NSIndexPath).row == 0) { // Referral bonus
                self.launchFreeVoucher()
            } else if ((indexPath as NSIndexPath).row == 1) { // Bantuan
                self.launchFAQ()
            } else if ((indexPath as NSIndexPath).row == 2) { // About
                self.launchAbout()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let m : [String : String] = (menus?.objectAtCircleIndex((indexPath as NSIndexPath).row))!
        
        if m["title"] == "Feedback" {
            return 45 + 1 // separator
            
        } else {
            return 45
            
        }
    }
    
    // MARK: - Pickervc functions
    
    func pickerDidSelect(_ item: String) {
        if (PickerViewController.HideHiddenString(item) == "Request Barang") {
            let webVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
            var url = "https://prelo.co.id/request-barang?ref=preloapp"
            if let username = CDUser.getOne()?.username {
                url += "&username=\(username)"
            }
            webVC.url = url
            webVC.titleString = "Request Barang"
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([webVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        } else if (PickerViewController.HideHiddenString(item) == "Request Packaging") {
            let webVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
            var url = "https://prelo.co.id/request-packaging?ref=preloapp"
            if let username = CDUser.getOne()?.username {
                url += "&username=\(username)"
            }
            webVC.url = url
            webVC.titleString = "Request Packaging"
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([webVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        }
    }
    
    // MARK: - IBActions

    @IBAction func vwHeaderPressed(_ sender: AnyObject) {
        if (User.IsLoggedIn) {
            self.launchMyPage()
        } else {
            LoginViewController.Show(self.previousController!, userRelatedDelegate: self.previousController as? UserRelatedDelegate, animated: true)
        }
    }
    
    @IBAction func editProfilePressed(_ sender: UIButton) {
//        let userProfileVC = Bundle.main.loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil)?.first as! UserProfileViewController
//        self.previousController!.navigationController?.pushViewController(userProfileVC, animated: true)
        
        let userProfileVC2 = Bundle.main.loadNibNamed(Tags.XibNameUserProfile2, owner: nil, options: nil)?.first as! UserProfileViewController2
        self.navigationController?.pushViewController(userProfileVC2, animated: true)
    }
    
    @IBAction func topMenu1Pressed(_ sender: AnyObject) {
        self.launchMyLovelist()
    }
    
    @IBAction func topMenu2Pressed(_ sender: AnyObject) {
        self.launchMyProducts()
    }
    
    @IBAction func topMenu3Pressed(_ sender: AnyObject) {
        self.launchMyPurchases()
    }
    
    // MARK: - Navigation functions
    
    func launchTarikUang() {
        let balanceMutationVC = Bundle.main.loadNibNamed(Tags.XibNameBalanceMutation, owner: nil, options: nil)?.first as! BalanceMutationViewController
        self.previousController?.navigationController?.pushViewController(balanceMutationVC, animated: true)
    }
    
    func launchMyPage() {
        if let me = CDUser.getOne() {
            if (!AppTools.isNewShop) {
                let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                l.currentMode = .shop
                l.shopName = me.username
                l.shopId = me.id
                l.previousScreen = PageName.DashboardLoggedIn
                self.navigationController?.pushViewController(l, animated: true)
            } else {
                let storePageTabBarVC = Bundle.main.loadNibNamed(Tags.XibNameStorePage, owner: nil, options: nil)?.first as! StorePageTabBarViewController
                storePageTabBarVC.shopId = me.id
                storePageTabBarVC.previousScreen = PageName.DashboardLoggedIn
                self.navigationController?.pushViewController(storePageTabBarVC, animated: true)
            }
        }
    }
    
    func launchMyLovelist() {
        let myLovelistVC = Bundle.main.loadNibNamed(Tags.XibNameMyLovelist, owner: nil, options: nil)?.first as! MyLovelistViewController
        self.previousController?.navigationController?.pushViewController(myLovelistVC, animated: true)
    }
    
    func launchFreeVoucher() {
        /*
        let referralPageVC = Bundle.main.loadNibNamed(Tags.XibNameReferralPage, owner: nil, options: nil)?.first as! ReferralPageViewController
        referralPageVC.previousScreen = PageName.DashboardLoggedIn
        self.previousController!.navigationController?.pushViewController(referralPageVC, animated: true)
        */
        
        let shareReferralVC = Bundle.main.loadNibNamed(Tags.XibNameShareReferral, owner: nil, options: nil)?.first as! ShareReferralViewController
        self.navigationController?.pushViewController(shareReferralVC, animated: true)
    }
    
    func launchRequestBarang() {
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as! PickerViewController
        p.items = ["Request Barang", "Request Packaging"]
        p.pickerDelegate = self
        p.title = "Request"
        self.navigationController?.pushViewController(p, animated: true)
    }
    
    func launchMyProducts() {
        let m = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdMyProducts) as! MyProductViewController
        m.shouldSkipBack = false
        self.previousController?.navigationController?.pushViewController(m, animated: true)
    }
    
    func launchMyPurchases() {
        let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
        self.previousController?.navigationController?.pushViewController(myPurchaseVC, animated: true)
        
//        let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameProductCompare, owner: nil, options: nil)?.first as! ProductCompareViewController
//        self.previousController?.navigationController?.pushViewController(myPurchaseVC, animated: true)
    }
    
    func launchContactPrelo() {
        let c = (self.storyboard?.instantiateViewController(withIdentifier: "contactus"))!
        contactUs = c
        if let v = c.view, let p = self.previousController?.navigationController?.view
        {
            v.alpha = 0
            v.frame = p.bounds
            self.previousController?.navigationController?.view.addSubview(v)
            
            v.alpha = 0
            UIView.animate(withDuration: 0.2, animations: {
                v.alpha = 1
            })
        }
    }
    
    func launchAchievement() {
        let AchievementVC = Bundle.main.loadNibNamed(Tags.XibNameAchievement, owner: nil, options: nil)?.first as! AchievementViewController
        AchievementVC.previousScreen = PageName.DashboardLoggedIn
        self.navigationController?.pushViewController(AchievementVC, animated: true)
    }

    func launchRateUs() {
        self.setupPopUp()
        self.feedback?.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.feedback?.setupPopUp()
            self.feedback?.displayPopUp(.rate)
        })
    }
    
    func rateApp(appId: String, completion: @escaping ((_ success: Bool)->())) {
        guard let url = URL(string : "itms-apps://itunes.apple.com/app/" + appId) else {
            completion(false)
            return
        }
        guard #available(iOS 10, *) else {
            completion(UIApplication.shared.openURL(url))
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }
    
    func lauchTestingFeature() {
        // new shop page -- OKE
//        let storePageTabBarVC = Bundle.main.loadNibNamed(Tags.XibNameStorePage, owner: nil, options: nil)?.first as! StorePageTabBarViewController
//        storePageTabBarVC.shopId = CDUser.getOne()?.id
//        self.navigationController?.pushViewController(storePageTabBarVC, animated: true)

        // address book -- OKE
//        let addressBookVC = Bundle.main.loadNibNamed(Tags.XibNameAddressBook, owner: nil, options: nil)?.first as! AddressBookViewController
//        self.navigationController?.pushViewController(addressBookVC, animated: true)
        
        // edit profile - baru -- OKE
//        let userProfileVC2 = Bundle.main.loadNibNamed(Tags.XibNameUserProfile2, owner: nil, options: nil)?.first as! UserProfileViewController2
//        self.navigationController?.pushViewController(userProfileVC2, animated: true)
        
        // prelo message -- OKE
//        let preloMessageVC = Bundle.main.loadNibNamed(Tags.XibNamePreloMessage, owner: nil, options: nil)?.first as! PreloMessageViewController
//        self.navigationController?.pushViewController(preloMessageVC, animated: true)
        
        // share profile -- OKE
//        let shareProfileVC = Bundle.main.loadNibNamed(Tags.XibNameShareProfile, owner: nil, options: nil)?.first as! ShareProfileViewController
//        self.navigationController?.pushViewController(shareProfileVC, animated: true)
        
        // share referral - baru -- OKE
//        let shareReferralVC = Bundle.main.loadNibNamed(Tags.XibNameShareReferral, owner: nil, options: nil)?.first as! ShareReferralViewController
//        self.navigationController?.pushViewController(shareReferralVC, animated: true)

        // google map -- OKE
//        let googleMapVC = Bundle.main.loadNibNamed(Tags.XibNameGoogleMap, owner: nil, options: nil)?.first as! GoogleMapViewController
//        googleMapVC.blockDone = { result in
//            print(result)
//        }
//        self.navigationController?.pushViewController(googleMapVC, animated: true)
        
        // checkout v2 -- OKE
//        let checkout2ShipVC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2Ship, owner: nil, options: nil)?.first as! Checkout2ShipViewController
//        checkout2ShipVC.previousController = self
//        checkout2ShipVC.previousScreen = PageName.DashboardLoggedIn
//        self.navigationController?.pushViewController(checkout2ShipVC, animated: true)
        
        // checkout v2 - single page -- OKE
//        let checkout2VC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2, owner: nil, options: nil)?.first as! Checkout2ViewController
//        checkout2VC.previousController = self
//        checkout2VC.previousScreen = PageName.DashboardLoggedIn
//        self.navigationController?.pushViewController(checkout2VC, animated: true)
    }
    
    func launchFAQ() {
        let helpVC = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
        helpVC.url = "https://prelo.co.id/faq?ref=preloapp"
        helpVC.titleString = "Bantuan"
        helpVC.contactPreloMode = true
        let baseNavC = BaseNavigationController()
        baseNavC.setViewControllers([helpVC], animated: false)
        self.present(baseNavC, animated: true, completion: nil)
    }
    
    func launchAbout() {
        let a = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdAbout) as! AboutViewController
        a.userRelatedDelegate = self.previousController as? UserRelatedDelegate
        a.isShowLogout = User.IsLoggedIn
        a.previousScreen = PageName.DashboardLoggedIn
        self.previousController?.navigationController?.pushViewController(a, animated: true)
    }
    
    // MARK: - Mail compose delegate functions
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if (result == MFMailComposeResult.sent) {
            Constant.showDialog("Request Barang", message: "E-mail terkirim")
        } else if (result == MFMailComposeResult.failed) {
            Constant.showDialog("Request Barang", message: "E-mail gagal dikirim")
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Setup popup
    func setupPopUp() {
        // setup popup
        if (self.feedback == nil) {
            self.feedback = Bundle.main.loadNibNamed("FeedbackPopup", owner: nil, options: nil)?.first as? FeedbackPopup
            self.feedback?.frame = self.view.frame
            self.feedback?.tag = 100
            self.feedback?.isHidden = true
            self.feedback?.backgroundColor = UIColor.clear
            self.view.addSubview(self.feedback!)
            
            self.feedback?.initPopUp()
            
            self.feedback?.disposePopUp = {
                self.feedback?.isHidden = true
                self.feedback = nil
                //print("Start remove sibview")
                if let viewWithTag = self.view.viewWithTag(100) {
                    viewWithTag.removeFromSuperview()
                } else {
                    //print("No!")
                }
            }
            
            self.feedback?.sendMail = {
                let my_device = UserDefaults().value(forKey: UserDefaultsKey.UserAgent)
                //        //print("this is my_device")
                //        //print(my_device)
                
                //        Constant.showDialog("Device Info", message: String(describing: my_device))
                
                let composer = MFMailComposeViewController()
                if (MFMailComposeViewController.canSendMail()) {
                    composer.mailComposeDelegate = self
                    composer.setToRecipients(["contact@prelo.co.id"])
                    
                    // adding title and message email
                    composer.setSubject("Feedback")
                    
                    var msg = ""
                    let user = CDUser.getOne()
                    let username = user?.username
                    let no_hp = user?.profiles.phone
                    
                    msg += "Love: " + (self.feedback?.rate)!.description + "\n"
                    msg += "Feedback / Masukan: \n\n" + "\n---\n"
                    
                    
                    if (user != nil) {
                        msg += "Username: " + username! + "\n"
                        msg += "No. HP: " + no_hp! + "\n"
                    }
                    
                    msg += "Versi App: " + (CDVersion.getOne()?.appVersion)! + "\n"
                    msg += "User Agent: " + String(describing: my_device)
                    
                    composer.setMessageBody(msg, isHTML: false)
                    
                    self.present(composer, animated: true, completion: nil)
                } else {
                    Constant.showDialog("No Active E-mail", message: "Untuk dapat menghubungi Prelo via e-mail, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
                }
                
            }
            
            self.feedback?.openStore = {
                /** URL APP STORE PRELO
                 https://itunes.apple.com/id/app/prelo-jual-beli-barang-bekas/id1027248488?mt=8
                 **/
                
                self.rateApp(appId: "id1027248488") { success in
                    //print("RateApp \(success)")
                }
            }
        }

    }
}

// MARK: - Class

class DashboardCell : UITableViewCell {
    @IBOutlet var captionTitle : UILabel?
    @IBOutlet var captionIcon : UILabel?
}

class BottomCell: UITableViewCell { // rate us, about
    
}

// MARK: - Pop up Feedback
enum PopUpRateMode {
    case rate
    case openStore
    case sendMail
}

class FeedbackPopup: UIView, FloatRatingViewDelegate {
    @IBOutlet weak var vwBackgroundOverlay: UIView!
    @IBOutlet weak var vwOverlayPopUp: UIView!
    @IBOutlet weak var vwLove: UIView!
    @IBOutlet weak var vwPopUp: UIView!
    @IBOutlet weak var vwPopUpStore: UIView!
    @IBOutlet weak var vwPopUpMail: UIView!
    @IBOutlet weak var consCenteryPopUp: NSLayoutConstraint!
    @IBOutlet weak var consCenteryPopUpStore: NSLayoutConstraint!
    @IBOutlet weak var consCenteryPopUpMail: NSLayoutConstraint!
    
    var popUpMode : PopUpRateMode!
    
    var floatRatingView: FloatRatingView!
    var rate : Float = 0
    
    var disposePopUp : ()->() = {}
    var sendMail : ()->() = {}
    var openStore : ()->() = {}
    
    func setupPopUp() {
        // Love floatable
        self.floatRatingView = FloatRatingView(frame: CGRect(x: 27, y: 5, width: 214, height: 40)) // 268 50
        self.floatRatingView.emptyImage = UIImage(named: "ic_love_96px_trp.png")?.withRenderingMode(.alwaysTemplate)
        self.floatRatingView.fullImage = UIImage(named: "ic_love_96px.png")?.withRenderingMode(.alwaysTemplate)
        // Optional params
        self.floatRatingView.delegate = self
        self.floatRatingView.contentMode = UIViewContentMode.scaleAspectFit
        self.floatRatingView.maxRating = 5
        self.floatRatingView.minRating = 0
        self.floatRatingView.rating = rate
        self.floatRatingView.editable = true
        self.floatRatingView.halfRatings = false
        self.floatRatingView.floatRatings = false
        self.floatRatingView.tintColor = Theme.ThemeRed
        
        self.vwLove.addSubview(self.floatRatingView )
    }
    
    func initPopUp() {
        // Transparent panel
        self.vwBackgroundOverlay.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        
        self.vwBackgroundOverlay.isHidden = false
        self.vwOverlayPopUp.isHidden = false
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        self.consCenteryPopUpStore.constant = screenHeight
        self.consCenteryPopUpMail.constant = screenHeight
    }
    
    func displayPopUp(_ type: PopUpRateMode) {
        self.popUpMode = type
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            
            switch(type) {
            case .rate:
                var curView = self.vwPopUp.frame
                curView.origin.y = (screenHeight - self.vwPopUp.frame.height) / 2
                self.vwPopUp.frame = curView
            case .openStore:
                var curView = self.vwPopUpStore.frame
                curView.origin.y = (screenHeight - self.vwPopUpStore.frame.height) / 2
                self.vwPopUpStore.frame = curView
            case .sendMail:
                var curView = self.vwPopUpMail.frame
                curView.origin.y = (screenHeight - self.vwPopUpMail.frame.height) / 2
                self.vwPopUpMail.frame = curView
            }
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        switch(type) {
        case .rate:
            self.consCenteryPopUp.constant = 0
        case .openStore:
            self.consCenteryPopUpStore.constant = 0
        case .sendMail:
            self.consCenteryPopUpMail.constant = 0
        }
    }
    
    func unDisplayPopUp() {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = 0
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            
            var curView = self.vwPopUp.frame
            curView.origin.y = screenHeight + (screenHeight - self.vwPopUp.frame.height) / 2
            self.vwPopUp.frame = curView
            
            var cur2View = self.vwPopUpStore.frame
            cur2View.origin.y = screenHeight + (screenHeight - self.vwPopUpStore.frame.height) / 2
            self.vwPopUpStore.frame = cur2View
            
            var cur3View = self.vwPopUpMail.frame
            cur3View.origin.y = screenHeight + (screenHeight - self.vwPopUpMail.frame.height) / 2
            self.vwPopUpMail.frame = cur3View

        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = screenHeight
        self.consCenteryPopUpStore.constant = screenHeight
        self.consCenteryPopUpMail.constant = screenHeight
    }
    
    @IBAction func btnSendPressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        let appVersion = CDVersion.getOne()?.appVersion
        
        let deadline = DispatchTime.now() + 0.3
        
        let _ = request(APIUser.rateApp(appVersion: appVersion!, rate: Int(self.rate), review: "")).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Rate App")) {
                //print("rated")
                
                // Prelo Analytic - Rate
                self.sentPreloAnalyticRate(false)
                
                // Check if app installed version > server version
                if let installedVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                    
                    // installed version > server version
                    if (installedVer.compare(appVersion!, options: .numeric, range: nil, locale: nil) == .orderedDescending) {
                        
                        if (Int(self.rate) >= 4) {
                            DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                                // rate to store
                                self.displayPopUp(.openStore)
                            })
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                                // send email
                                self.displayPopUp(.sendMail)
                            })
                        }
                        
                    } else {
                        
                        if (Int(self.rate) >= 4) {
                            self.vwOverlayPopUp.isHidden = true
                            self.vwBackgroundOverlay.isHidden = true
                            self.openStore()
                            self.disposePopUp()
                        } else {
                            self.vwOverlayPopUp.isHidden = true
                            self.vwBackgroundOverlay.isHidden = true
                            self.sendMail()
                            self.disposePopUp()
                        }
                    }
                    
                } else {
                    
                    if (Int(self.rate) >= 4) {
                        DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                            // rate to store
                            self.displayPopUp(.openStore)
                        })
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                            // send email
                            self.displayPopUp(.sendMail)
                        })
                    }
                    
                }
                
            } else {
                
                DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                    // re rate
                    self.displayPopUp(.rate)
                })
                
            }
        }
    }
    
    @IBAction func btnOpenStorePressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.openStore()
            self.disposePopUp()
        })
    }
    
    @IBAction func btnSendMailPressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.sendMail()
            self.disposePopUp()
        })
    }
    
    @IBAction func btnTidakPressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        // Prelo Analytic - Rate
        if self.popUpMode == .rate {
            self.sentPreloAnalyticRate(true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            self.disposePopUp()
        })
    }
    
    // Prelo Analytic - Rate
    func sentPreloAnalyticRate(_ isCancelled: Bool) {
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            "Rating" : Int(self.rate),
            "Cancelled" : isCancelled
        ] as [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.Rate, data: pdata, previousScreen: PageName.Home, loginMethod: loginMethod)
    }
    
    // MARK: - FloatRatingViewDelegate
    
    func floatRatingView(_ ratingView: FloatRatingView, isUpdating rating:Float) {
        self.rate = self.floatRatingView.rating
    }
    
    func floatRatingView(_ ratingView: FloatRatingView, didUpdate rating: Float) {
        self.rate = self.floatRatingView.rating
    }
}
