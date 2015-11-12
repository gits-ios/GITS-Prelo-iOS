//
//  DashboardViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/28/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class DashboardViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView : UITableView?
    @IBOutlet var captionName : UILabel?
    @IBOutlet var imgCover : UIImageView?
    
    @IBOutlet var ivBag  : UIImageView?
    @IBOutlet var ivShirt  : UIImageView?
    @IBOutlet var ivLove  : UIImageView?
    
    var menus : Array<[String : String]>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let c = CDUser.getOne()
        captionName?.text = c?.fullname
        
        let i = UIImage(named: "ic_bag")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        ivBag?.tintColor = Theme.PrimaryColorDark
        ivBag?.image = i
        
        let i2 = UIImage(named: "ic_shirt")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        ivShirt?.tintColor = Theme.PrimaryColorDark
        ivShirt?.image = i2
        
        let i3 = UIImage(named: "ic_love")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        ivLove?.tintColor = Theme.PrimaryColorDark
        ivLove?.image = i3
        
        //self.setupNormalOptions()
        self.setupTitle()

        menus = [
            [
                "title":"Inbox",
                "icon":"",
                "PreloAwesome":"1"
            ],
            [
                "title":"Konfirmasi Bayar",
                "icon":"",
                "PreloAwesome":"0"
            ],
            [
                "title":"Tarik Uang",
                "icon":"",
                "PreloAwesome":"0"
            ],
            [
                "title":"Voucher Gratis",
                "icon":"",
                "PreloAwesome":"0"
            ],
            [
                "title":"Hubungi Prelo",
                "icon":"",
                "PreloAwesome":"0"
            ],
            [
                "title":"About",
                "icon":"",
                "PreloAwesome":"1"
            ]/*,
            [
                "title":"Tutorial",
                "icon":"",
                "PreloAwesome":"1"
            ]*/
        ]
        
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.tableFooterView = UIView()
        
        tableView?.contentInset = UIEdgeInsetsMake(0, 0, 40, 0)
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.sharedInstance().track("Dashboard Logged In")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        imgCover?.image = nil
        let uProf = CDUserProfile.getOne()
        let url = NSURL(string: uProf!.pict)
        if (url != nil) {
            imgCover?.setImageWithUrl(url!, placeHolderImage: nil)
            imgCover?.layer.cornerRadius = (imgCover?.frame.size.width)!/2
            imgCover?.layer.masksToBounds = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (menus?.count)!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : DashboardCell = tableView.dequeueReusableCellWithIdentifier("cell") as! DashboardCell
        let m : [String : String] = (menus?.objectAtCircleIndex(indexPath.row))!
        
        if (m["PreloAwesome"] == "1") {
            cell.captionIcon?.font = AppFont.PreloAwesome.getFont(24)!
        } else {
            cell.captionIcon?.font = AppFont.Prelo2.getFont(24)!
        }
        
        cell.captionIcon?.text = m["icon"]
        cell.captionTitle?.text = m["title"]
        
        return cell
    }
    
    var contactUs : UIViewController?
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if (indexPath.row == 0) // Inbox
        {
            let i = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdInbox) as! InboxViewController
            self.previousController?.navigationController?.pushViewController(i, animated: true)
        }
        
        if (indexPath.row == 1) { // Konfirmasi Bayar
            let paymentConfirmationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil).first as! PaymentConfirmationViewController
            self.previousController!.navigationController?.pushViewController(paymentConfirmationVC, animated: true)
        }
        
        if (indexPath.row == 2) // Dompet
        {
            let t = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdTarikTunai) as! TarikTunaiController
            self.previousController?.navigationController?.pushViewController(t, animated: true)
        }
        
        if (indexPath.row == 3) // Voucher Gratis
        {
            let referralPageVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameReferralPage, owner: nil, options: nil).first as! ReferralPageViewController
            self.previousController!.navigationController?.pushViewController(referralPageVC, animated: true)
        }
        
        if (indexPath.row == 4) // Hubungi Prelo
        {
            let c = self.storyboard?.instantiateViewControllerWithIdentifier("contactus") as! UIViewController
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
        
        if (indexPath.row == 5) // About
        {
            let a = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdAbout) as! AboutViewController
            a.userRelatedDelegate = self.previousController as? UserRelatedDelegate
            a.isShowLogout = true
            self.previousController?.navigationController?.pushViewController(a, animated: true)
        }
        
        if (indexPath.row == 6) // Tutorial
        {
            self.previousController?.performSegueWithIdentifier("segTour", sender: self)
        }
    }
    
    @IBAction func launchMyPage()
    {
        if let me = CDUser.getOne()
        {
            let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
            l.storeMode = true
            if let fullname = me.fullname
            {
                l.storeName = fullname
            }
            l.storeId = me.id
            self.navigationController?.pushViewController(l, animated: true)
        }
        
    }
    
    @IBAction func launchMyLovelist()
    {
        let myLovelistVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyLovelist, owner: nil, options: nil).first as! MyLovelistViewController
        self.previousController?.navigationController?.pushViewController(myLovelistVC, animated: true)
    }
    
    @IBAction func launchMyProducts()
    {
        let m = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdMyProducts) as! MyProductViewController
        m.shouldSkipBack = false
        self.previousController?.navigationController?.pushViewController(m, animated: true)
    }
    
    @IBAction func launchMyPurchases() {
        let myPurchaseVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchase, owner: nil, options: nil).first as! MyPurchaseViewController
        self.previousController?.navigationController?.pushViewController(myPurchaseVC, animated: true)
    }

    @IBAction func editProfilePressed(sender: UIButton) {
        let userProfileVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil).first as! UserProfileViewController
//        userProfileVC.previousControllerName = "Dashboard"
        self.previousController!.navigationController?.pushViewController(userProfileVC, animated: true)
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

class DashboardCell : UITableViewCell
{
    @IBOutlet var captionTitle : UILabel?
    @IBOutlet var captionIcon : UILabel?
}
