//
//  DashboardViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/28/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import MessageUI

// MARK: - Class

class DashboardViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate {

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
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let c = CDUser.getOne()
        captionName?.text = c?.username
        
        if let i = UIImage(named: "ic_lovelist") {
            ivLove?.tintColor = Theme.PrimaryColor
            ivLove?.image = i.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        }
        
        if let i2 = UIImage(named: "ic_tshirt") {
            ivRequest?.tintColor = Theme.PrimaryColor
            ivRequest?.image = i2.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        }
    
        if let i3 = UIImage(named: "ic_belanjaan_saya") {
            ivVoucher?.tintColor = Theme.PrimaryColor
            ivVoucher?.image = i3.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        }

        //self.setupNormalOptions()
        self.setupTitle()

        if (User.IsLoggedIn) {
            vwHeaderLoggedIn.hidden = false
            vwHeaderLoggedOut.hidden = true
            menus = [
                [
                    "title":"Request Barang",
                    "iconimg":"ic_request",
                ],
                [
                    "title":"Tarik Uang",
                    "iconimg":"ic_tarik_uang",
                ],
                [
                    "title":"Referral Bonus",
                    "iconimg":"ic_voucher"
                ],
                [
                    "title":"Bantuan",
                    "iconimg":"ic_faq"
                ],
                [
                    "title":"About",
                    "iconimg":"ic_about"
                ]
            ]
        } else {
            vwHeaderLoggedIn.hidden = true
            vwHeaderLoggedOut.hidden = false
            let vwTopMenuFrame = vwTopMenu.frame
            vwTopMenu.frame = CGRectMake(vwTopMenuFrame.origin.x, vwTopMenuFrame.origin.y, vwTopMenuFrame.width, VwTopMenuHeightLoggedOut)
            menus = [
                [
                    "title":"Referral Bonus",
                    "iconimg":"ic_voucher"
                ],
                [
                    "title":"Bantuan",
                    "iconimg":"ic_faq"
                ],
                [
                    "title":"About",
                    "iconimg":"ic_about"
                ]
            ]
        }
        
        
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.tableFooterView = UIView()
        
        tableView?.contentInset = UIEdgeInsetsMake(0, 0, 40, 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (User.IsLoggedIn) {
            // Mixpanel
            //Mixpanel.trackPageVisit(PageName.DashboardLoggedIn)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.DashboardLoggedIn)
        } else {
            // Mixpanel
            //Mixpanel.trackPageVisit(PageName.DashboardLoggedOut)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.DashboardLoggedOut)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        imgCover?.image = UIImage(named: "ic_user_2.png")
        let uProf = CDUserProfile.getOne()
        if (uProf != nil) {
            let url = NSURL(string: uProf!.pict)
            if (url != nil) {
                imgCover?.setImageWithUrl(url!, placeHolderImage: nil)
                imgCover?.layer.cornerRadius = (imgCover?.frame.size.width)!/2
                imgCover?.layer.masksToBounds = true
            }
        }
        
        // Redirect if any
        let redirectFromHome : String? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.RedirectFromHome) as! String?
        if (redirectFromHome != nil) {
            if (redirectFromHome == PageName.MyOrders) {
                let myPurchaseVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchase, owner: nil, options: nil).first as! MyPurchaseViewController
                self.previousController?.navigationController?.pushViewController(myPurchaseVC, animated: true)
            } else if (redirectFromHome == PageName.UnpaidTransaction) {
                let paymentConfirmationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil).first as! PaymentConfirmationViewController
                self.previousController!.navigationController?.pushViewController(paymentConfirmationVC, animated: true)
            }
            NSUserDefaults.standardUserDefaults().removeObjectForKey(UserDefaultsKey.RedirectFromHome)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view delegate functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (menus?.count)!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : DashboardCell = tableView.dequeueReusableCellWithIdentifier("cell") as! DashboardCell
        let m : [String : String] = (menus?.objectAtCircleIndex(indexPath.row))!
        
        if let isPreloAwesome = m["PreloAwesome"] { // Icon is from font
            if (isPreloAwesome == "1") {
                cell.captionIcon?.font = AppFont.PreloAwesome.getFont(24)!
            } else {
                cell.captionIcon?.font = AppFont.Prelo2.getFont(24)!
            }
            cell.captionIcon?.text = m["icon"]
        } else { // Icon is from image
            cell.captionIcon?.text = ""
            let img = UIImage(named: m["iconimg"]!)
            let iconImg = UIImageView(image: img)
            iconImg.tintColor = Theme.PrimaryColorDark
            iconImg.frame = CGRect(x: 8, y: 10, width: 26, height: 26)
            cell.addSubview(iconImg)
        }
        
        cell.captionTitle?.text = m["title"]
        cell.selectionStyle = .None
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if (User.IsLoggedIn) {
            if (indexPath.row == 0) { // Request barang
                self.launchRequestBarang()
            } else if (indexPath.row == 1) { // Tarik uang
                self.launchTarikUang()
            } else if (indexPath.row == 2) { // Referral bonus
                self.launchFreeVoucher()
            } else if (indexPath.row == 3) { // Bantuan
                self.launchFAQ()
            } else if (indexPath.row == 4) { // About
                self.launchAbout()
            }
        } else {
            if (indexPath.row == 0) { // Referral bonus
                self.launchFreeVoucher()
            } else if (indexPath.row == 1) { // Bantuan
                self.launchFAQ()
            } else if (indexPath.row == 2) { // About
                self.launchAbout()
            }
        }
    }
    
    // MARK: - IBActions

    @IBAction func vwHeaderPressed(sender: AnyObject) {
        if (User.IsLoggedIn) {
            self.launchMyPage()
        } else {
            LoginViewController.Show(self.previousController!, userRelatedDelegate: self.previousController as? UserRelatedDelegate, animated: true)
        }
    }
    
    @IBAction func editProfilePressed(sender: UIButton) {
        let userProfileVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil).first as! UserProfileViewController
        self.previousController!.navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    @IBAction func topMenu1Pressed(sender: AnyObject) {
        self.launchMyLovelist()
    }
    
    @IBAction func topMenu2Pressed(sender: AnyObject) {
        self.launchMyProducts()
    }
    
    @IBAction func topMenu3Pressed(sender: AnyObject) {
        self.launchMyPurchases()
    }
    
    // MARK: - Navigation functions
    
    func launchTarikUang() {
        let balanceMutationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameBalanceMutation, owner: nil, options: nil).first as! BalanceMutationViewController
        self.previousController?.navigationController?.pushViewController(balanceMutationVC, animated: true)
    }
    
    func launchMyPage() {
        if let me = CDUser.getOne() {
            let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
            l.currentMode = .Shop
            l.shopName = me.username
            l.shopId = me.id
            self.navigationController?.pushViewController(l, animated: true)
        }
        
    }
    
    func launchMyLovelist() {
        let myLovelistVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyLovelist, owner: nil, options: nil).first as! MyLovelistViewController
        self.previousController?.navigationController?.pushViewController(myLovelistVC, animated: true)
    }
    
    func launchFreeVoucher() {
        let referralPageVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameReferralPage, owner: nil, options: nil).first as! ReferralPageViewController
        self.previousController!.navigationController?.pushViewController(referralPageVC, animated: true)
    }
    
    func launchRequestBarang() {
        var username = "Your beloved user"
        if let u = CDUser.getOne() {
            username = u.username
        }
        let msgBody = "Dear Prelo,<br/><br/>Saya sedang mencari barang bekas berkualitas ini:<br/><br/><br/>Jika ada pengguna di Prelo yang menjual barang tersebut, harap memberitahu saya melalui e-mail.<br/><br/>Terima kasih Prelo <3<br/><br/>--<br/>\(username)<br/>Sent from Prelo iOS"
        
        let m = MFMailComposeViewController()
        if (MFMailComposeViewController.canSendMail()) {
            m.setToRecipients(["contact@prelo.id"])
            m.setSubject("Request Barang")
            m.setMessageBody(msgBody, isHTML: true)
            m.mailComposeDelegate = self
            self.presentViewController(m, animated: true, completion: nil)
        } else {
            Constant.showDialog("No Active E-mail", message: "Untuk dapat mengirim Request Barang, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
        }
    }
    
    func launchMyProducts() {
        let m = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdMyProducts) as! MyProductViewController
        m.shouldSkipBack = false
        self.previousController?.navigationController?.pushViewController(m, animated: true)
    }
    
    func launchMyPurchases() {
        let myPurchaseVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchase, owner: nil, options: nil).first as! MyPurchaseViewController
        self.previousController?.navigationController?.pushViewController(myPurchaseVC, animated: true)
    }
    
    func launchContactPrelo() {
        let c = (self.storyboard?.instantiateViewControllerWithIdentifier("contactus"))!
        contactUs = c
        if let v = c.view, let p = self.previousController?.navigationController?.view
        {
            v.alpha = 0
            v.frame = p.bounds
            self.previousController?.navigationController?.view.addSubview(v)
            
            v.alpha = 0
            UIView.animateWithDuration(0.2, animations: {
                v.alpha = 1
            })
        }
    }
    
    func launchFAQ() {
        let helpVC = self.storyboard?.instantiateViewControllerWithIdentifier("preloweb") as! PreloWebViewController
        helpVC.url = "https://prelo.co.id/faq?ref=preloapp"
        helpVC.titleString = "Bantuan"
        helpVC.contactPreloMode = true
        let baseNavC = BaseNavigationController()
        baseNavC.setViewControllers([helpVC], animated: false)
        self.presentViewController(baseNavC, animated: true, completion: nil)
    }
    
    func launchAbout() {
        let a = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdAbout) as! AboutViewController
        a.userRelatedDelegate = self.previousController as? UserRelatedDelegate
        a.isShowLogout = User.IsLoggedIn
        self.previousController?.navigationController?.pushViewController(a, animated: true)
    }
    
    // MARK: - Mail compose delegate functions
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        if (result == MFMailComposeResultSent) {
            Constant.showDialog("Request Barang", message: "E-mail terkirim")
        } else if (result == MFMailComposeResultFailed) {
            Constant.showDialog("Request Barang", message: "E-mail gagal dikirim")
        }
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - Class

class DashboardCell : UITableViewCell {
    @IBOutlet var captionTitle : UILabel?
    @IBOutlet var captionIcon : UILabel?
}
