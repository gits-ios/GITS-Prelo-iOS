//
//  KumangTabBarViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class KumangTabBarViewController: BaseViewController, UserRelatedDelegate, MenuPopUpDelegate, LoadAppDataDelegate {
    
    var numberOfControllers : Int = 0
    
    @IBOutlet var sectionContent : UIView?
    @IBOutlet var sectionBar : UIView?
    @IBOutlet var segmentBar : UISegmentedControl?
    @IBOutlet var btnAdd : UIView?
    
    @IBOutlet var btnDashboard : UIButton!
    @IBOutlet var btnBrowse : UIButton!
    
    @IBOutlet var consMarginBottomBar : NSLayoutConstraint!
    
    var loadAppDataAlert : UIAlertView?
    var loadAppDataProgressView : UIProgressView?
    
    var menuPopUp : MenuPopUp?
    
    var changeToBrowseCount = 0
    
    var _controllerDashboard : BaseViewController?
    @IBOutlet var controllerDashboard : BaseViewController?
    {
        get {
            return _controllerDashboard
        }
        set(newController) {
            _controllerDashboard = newController
            _controllerDashboard?.userRelatedDelegate = self
        }
    }
    var _controllerDashboard2 : BaseViewController?
    var controllerDashboard2 : BaseViewController?
        {
        get {
            return _controllerDashboard2
        }
        set(newController) {
            _controllerDashboard2 = newController
            _controllerDashboard2?.userRelatedDelegate = self
        }
    }
    @IBOutlet var controllerBrowse : UIViewController?
    @IBOutlet var controllerLogin : LoginViewController?
    @IBOutlet var controllerContactPrelo : BaseViewController?
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        let v = UIView()
        v.frame = CGRectMake(0, 0, 10, 10)
        v.backgroundColor = UIColor.clearColor()
        self.navigationItem.titleView = v
        
        self.updateLoginButton()
        
        //self.setupNormalOptions()
        self.setupTitle()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(KumangTabBarViewController.pushNew(_:)), name: NotificationName.PushNew, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(KumangTabBarViewController.hideBottomBar), name: "hideBottomBar", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(KumangTabBarViewController.showBottomBar), name: "showBottomBar", object: nil)

        // Do any additional setup after loading the view.
        btnAdd?.layer.cornerRadius = (btnAdd?.frame.size.width)!/2
        btnAdd?.layer.shadowColor = UIColor.blackColor().CGColor
        btnAdd?.layer.shadowOffset = CGSize(width: 0, height: 5)
        btnAdd?.layer.shadowOpacity = 0.3
        
        let lc : ListCategoryViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdBrowse) as! ListCategoryViewController
        lc.previousController = self
        controllerBrowse = lc
        changeToController(controllerBrowse!)
        
        controllerDashboard = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdDashboard) as? BaseViewController
        controllerDashboard?.previousController = self
        controllerDashboard2 = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdDashboard) as? BaseViewController//Dashboard2ViewController(nibName:Tags.XibNameDashboard2, bundle: nil)
        controllerDashboard2?.previousController = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(KumangTabBarViewController.updateLoginButton), name: "userLoggedIn", object: nil)
    }
    
    func updateLoginButton()
    {
        if (User.IsLoggedIn)
        {
            btnDashboard.setTitle("AKUN SAYA", forState: UIControlState.Normal)
        } else
        {
            btnDashboard.setTitle("LOGIN", forState: UIControlState.Normal)
        }
    }
    
    func hideBottomBar()
    {
        consMarginBottomBar.constant = -76
        UIView.animateWithDuration(0.2, animations: {
            self.sectionBar?.layoutIfNeeded()
            self.btnAdd?.layoutIfNeeded()
        })
    }
    
    func showBottomBar()
    {
        consMarginBottomBar.constant = 0
        UIView.animateWithDuration(0.2, animations: {
            self.sectionBar?.layoutIfNeeded()
            self.btnAdd?.layoutIfNeeded()
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().postNotificationName("changeStatusBarColor", object: Theme.PrimaryColor)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        showBottomBar()
        self.setupNormalOptions()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
    }
    
    var isAlreadyGetCategory : Bool = false
    var userDidLoggedIn : Bool?
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (menuPopUp == nil) {
            menuPopUp = NSBundle.mainBundle().loadNibNamed("MenuPopUp", owner: nil, options: nil).first as? MenuPopUp
            menuPopUp?.menuDelegate = self
            menuPopUp?.setupView(self.navigationController!)
        }
        
        // Show tour and/or loadAppData pop up
        if (!NSUserDefaults.isTourDone() && !isAlreadyGetCategory && !User.IsLoggedIn) { // Jika akan memanggil tour
            self.performSegueWithIdentifier("segTour", sender: self)
            NSUserDefaults.setTourDone(true)
        } else {
            if (userDidLoggedIn == false && User.IsLoggedIn) { // Jika user baru saja log in
                (self.controllerBrowse as? ListCategoryViewController)?.grandRefresh()
            } else if (!isAlreadyGetCategory) { // Jika tidak memanggil tour saat membuka app, atau jika tour baru saja selesai
                (self.controllerBrowse as? ListCategoryViewController)?.getCategory()
                isAlreadyGetCategory = true
                
                // Set self as LoadAppDataDelegate
                UIApplication.appDelegate.loadAppDataDelegate = self
                
                // Check if app is currently loading app data
                let appDataSaved : Bool? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.AppDataSaved) as? Bool
                if (appDataSaved == nil) { // Proses pengecekan di AppDelegate bahkan belum berjalan, tunggu pengecekan selesai
                    // Tampilkan pop up untuk loading
                    self.loadAppDataAlert = UIAlertView()
                    self.loadAppDataAlert!.title = "Checking App Data..."
                    self.loadAppDataAlert!.message = "Harap untuk tidak menutup aplikasi selama proses berjalan"
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadAppDataAlert!.show()
                    })
                } else if (appDataSaved == false) { // App data belum selesai diload
                    // Tampilkan pop up untuk loading
                    self.loadAppDataAlert = UIAlertView()
                    self.loadAppDataProgressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Bar)
                    self.loadAppDataProgressView!.progress = UIApplication.appDelegate.loadAppDataProgress
                    self.loadAppDataProgressView!.backgroundColor = Theme.GrayLight
                    self.loadAppDataProgressView!.progressTintColor = Theme.ThemeOrange
                    self.loadAppDataAlert!.setValue(self.loadAppDataProgressView!, forKey: "accessoryView")
                    self.loadAppDataAlert!.title = "Loading App Data..."
                    self.loadAppDataAlert!.message = "Harap untuk tidak menutup aplikasi selama proses berjalan"
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadAppDataAlert!.show()
                    })
                }
            }
        }
        userDidLoggedIn = User.IsLoggedIn
    }
    
    func updateProgress(progress: Float) {
        if (loadAppDataAlert != nil) {
            if (loadAppDataAlert!.title == "Checking App Data...") {
                // Hilangkan pop up ini dan jika (NSUserDefaultl AppDataSaved = false) kemudian munculkan pop up dengan progressView
                loadAppDataAlert!.dismissWithClickedButtonIndex(-1, animated: true)
                let appDataSaved = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.AppDataSaved) as? Bool
                if (appDataSaved == false) {
                    self.loadAppDataAlert = UIAlertView()
                    self.loadAppDataProgressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Bar)
                    self.loadAppDataProgressView!.progress = UIApplication.appDelegate.loadAppDataProgress
                    self.loadAppDataProgressView!.backgroundColor = Theme.GrayLight
                    self.loadAppDataProgressView!.progressTintColor = Theme.ThemeOrange
                    self.loadAppDataAlert!.setValue(self.loadAppDataProgressView!, forKey: "accessoryView")
                    self.loadAppDataAlert!.title = "Loading App Data..."
                    self.loadAppDataAlert!.message = "Harap untuk tidak menutup aplikasi selama proses berjalan"
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadAppDataAlert!.show()
                    })
                }
            } else if (loadAppDataAlert!.title == "Loading App Data...") {
                // Update progressView, jika sudah full (cek NSUSerDefault AppDataSaved) maka hilangkan pop up ini dan munculkan pop up berhasil/gagal
                if (loadAppDataProgressView != nil) {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadAppDataProgressView!.setProgress(UIApplication.appDelegate.loadAppDataProgress, animated: true)
                    })
                }
                let appDataSaved = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.AppDataSaved) as? Bool
                if (appDataSaved == true) {
                    loadAppDataAlert!.dismissWithClickedButtonIndex(-1, animated: true)
                    if (UIApplication.appDelegate.isLoadAppDataSuccess) {
                        dispatch_async(dispatch_get_main_queue(), {
                            let a = UIAlertView()
                            a.title = "Load App Data"
                            a.message = "Load App Data berhasil"
                            a.addButtonWithTitle("OK")
                            a.show()
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            let a = UIAlertView()
                            a.title = "Load App Data"
                            a.message = "Oops, terjadi kesalahan saat Load App Data"
                            a.addButtonWithTitle("OK")
                            a.show()
                        })
                    }
                }
            }
        }
    }
    
    func pushNew(sender : AnyObject)
    {
        let n : NSNotification = sender as! NSNotification
        let d:ProductDetailViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
        let nav = UINavigationController(rootViewController: d)
        nav.navigationBar.translucent = false
        nav.navigationBar.barTintColor = Theme.navBarColor
        nav.navigationBar.tintColor = UIColor.whiteColor()
        d.product = n.object as? Product
        self.navigationController?.pushViewController(d, animated: true)
    }
    
    var oldController : UIViewController?
    func changeToController(newController : UIViewController)
    {
        print("class name = \(newController.dynamicType)")
        if ("\(newController.dynamicType)" == "ListCategoryViewController") { // Browse
            btnDashboard.titleLabel?.font = UIFont.systemFontOfSize(13)
            btnDashboard.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
            btnBrowse.titleLabel?.font = UIFont.boldSystemFontOfSize(13)
            btnBrowse.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
        } else if ("\(newController.dynamicType)" == "DashboardViewController") { // Login/Dashboard
            btnDashboard.titleLabel?.font = UIFont.boldSystemFontOfSize(13)
            btnDashboard.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
            btnBrowse.titleLabel?.font = UIFont.systemFontOfSize(13)
            btnBrowse.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        }
        
        if let o = oldController
        {
            o.removeFromParentViewController()
        }
        
        let oldView = sectionContent?.viewWithTag(1)
        oldView?.removeFromSuperview()
        
        let v : UIViewController? = newController
        v?.view.tag = 1
        v?.view.translatesAutoresizingMaskIntoConstraints = false
        
        sectionContent?.addSubview((v?.view)!)
        let horizontalConstraint = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[v1]-0-|", options: .AlignAllTop, metrics: nil, views: ["v1": v!.view])
        let verticalConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[v1]-0-|", options: .AlignAllTop, metrics: nil, views: ["v1": v!.view])
        
        sectionContent?.addConstraints(horizontalConstraint)
        sectionContent?.addConstraints(verticalConstraint)
        
        oldController = v
        self.addChildViewController(oldController!)
    }
    
    @IBAction func switchController(sender: AnyObject) {
        let btn : AppButton = sender as! AppButton
        if (btn.stringTag == Tags.Browse) {
            self.setupNormalOptions() // Agar notification terupdate
            changeToController(controllerBrowse!)
            
            if (changeToBrowseCount == 0) {
                changeToBrowseCount = 1
                sectionContent?.hidden = true
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(KumangTabBarViewController.delayBrowseSwitch), userInfo: nil, repeats: false)
            }
            
        } else {
            if (User.IsLoggedIn) {
                print("To Dashboard")
                controllerDashboard?.previousController = self
                self.setupNormalOptions() // Agar notification terupdate
                changeToController(controllerDashboard!)
            } else {
                print("To Dashboard2")
                controllerDashboard2?.previousController = self
                changeToController(controllerDashboard2!)
            }
        }
    }
    
    @IBAction func launchMenu()
    {
//        let i = PreloShareItem()
//        PreloShareController.Share(i, inView: (self.navigationController?.view)!)
        
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        add.screenBeforeAddProduct = PageName.Home
        self.navigationController?.pushViewController(add, animated: true)
    }
    
    func delayBrowseSwitch()
    {
        sectionContent?.hidden = false
        changeToController(controllerBrowse!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func userLoggedIn() {
        btnDashboard.setTitle("AKUN SAYA", forState: UIControlState.Normal)
        let d : BaseViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdDashboard) as! BaseViewController
        d.previousController = self
        changeToController(d)
        controllerDashboard = d
    }
    
    func userLoggedOut() {
        btnDashboard.setTitle("LOGIN", forState: UIControlState.Normal)
//        let d : BaseViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdLogin) as! BaseViewController
        changeToController(controllerBrowse!)
//        controllerDashboard = d
    }
    
    func userCancelLogin() {
        btnDashboard.setTitle("LOGIN", forState: UIControlState.Normal)
        changeToController(controllerBrowse!)
    }
    
    func menuSelected(option: MenuOption) {
        let i = PreloShareItem()
        PreloShareController.Share(i, inView: self.view)
        
//        menuPopUp?.hide()
//        
//        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProductImage) as! AddProductImageSourceViewController
//        self.navigationController?.pushViewController(add, animated: true)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "segTour") {
            let t = (segue.destinationViewController as? UINavigationController)?.viewControllers.first as! TourViewController
            t.parent = sender as? BaseViewController
        }
    }

}
