//
//  KumangTabBarViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class KumangTabBarViewController: BaseViewController, UserRelatedDelegate, MenuPopUpDelegate {
    
    @IBOutlet var loadingPanel: UIView!
    
    var numberOfControllers : Int = 0
    
    @IBOutlet var sectionContent : UIView?
    @IBOutlet var sectionBar : UIView?
    @IBOutlet var segmentBar : UISegmentedControl?
    @IBOutlet var btnAdd : UIView?
    
    @IBOutlet var btnDashboard : UIButton!
    @IBOutlet var btnBrowse : UIButton!
    
    @IBOutlet var consMarginBottomBar : NSLayoutConstraint!
    
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
    
    var isVersionChecked = false
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        
        if (!isVersionChecked) {
            self.versionCheck()
        }
        
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
            btnDashboard.setTitle("MY ACCOUNT", forState: UIControlState.Normal)
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
        
        // Show tour pop up
        if (!NSUserDefaults.isTourDone() && !isAlreadyGetCategory && !User.IsLoggedIn) { // Jika akan memanggil tour
            self.performSegueWithIdentifier("segTour", sender: self)
            NSUserDefaults.setTourDone(true)
        } else {
            if (AppTools.isDev || (userDidLoggedIn == false && User.IsLoggedIn)) { // Jika user baru saja log in, atau dalam dev mode
                (self.controllerBrowse as? ListCategoryViewController)?.grandRefresh()
            } else if (!isAlreadyGetCategory) { // Jika tidak memanggil tour saat membuka app, atau jika tour baru saja selesai
                (self.controllerBrowse as? ListCategoryViewController)?.getCategory()
            }
        }
        userDidLoggedIn = User.IsLoggedIn
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
        btnDashboard.setTitle("MY ACCOUNT", forState: UIControlState.Normal)
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
    
    func hideLoading() {
        self.loadingPanel.hidden = true
    }
    
    func showLoading() {
        self.loadingPanel.hidden = false
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
    
    // MARK: - Version check and load/update metadata
    
    func versionCheck() {
        // API Migrasi
        request(APIApp.Version).responseJSON { resp in
            var isFirstInstall = false
            var isInitialMetadataSaveSuccess : Bool = true
            
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Version Check")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                let ver : CDVersion? = CDVersion.getOne()
                
                if (ver == nil) { // App is installed for the first time
                    isFirstInstall = true
                    
                    // MoEngage
                    MoEngage.sharedInstance().appStatus(INSTALL)
                    
                    // Save category for the first time, from local json file
                    if let metadataPath = NSBundle.mainBundle().pathForResource("InitialMetadata", ofType: "json") {
                        do {
                            let metadataData = try NSData(contentsOfURL: NSURL(fileURLWithPath: metadataPath), options: NSDataReadingOptions.DataReadingMappedIfSafe)
                            let metadataJson = JSON(data: metadataData)
                            
                            // Save categories
                            if let categArr = metadataJson["_data"]["categories"].array {
                                //print("categArr = \(categArr)")
                                if (!CDCategory.saveCategoriesFromArrayJson(categArr)) {
                                    isInitialMetadataSaveSuccess = false
                                }
                            } else {
                                isInitialMetadataSaveSuccess = false
                            }
                            
                            // Save product conditions
                            if let prodCondArr = metadataJson["_data"]["product_conditions"].array {
                                //print("prodCondArr = \(prodCondArr)")
                                if (!CDProductCondition.saveProductConditionsFromArrayJson(prodCondArr)) {
                                    isInitialMetadataSaveSuccess = false
                                }
                            } else {
                                isInitialMetadataSaveSuccess = false
                            }
                            
                            // Save provinces
                            if let provArr = metadataJson["_data"]["provinces"].array {
                                print("provArr = \(provArr)")
                                if (!CDProvince.saveProvincesFromArrayJson(provArr)) {
                                    isInitialMetadataSaveSuccess = false
                                }
                            } else {
                                isInitialMetadataSaveSuccess = false
                            }
                            
                            // Save regions
                            if let regArr = metadataJson["_data"]["regions"].array {
                                print("regArr = \(regArr)")
                                if (!CDRegion.saveRegionsFromArrayJson(regArr)) {
                                    isInitialMetadataSaveSuccess = false
                                }
                            } else {
                                isInitialMetadataSaveSuccess = false
                            }
                            
                            // Save shippings
                            if let shipArr = metadataJson["_data"]["shippings"].array {
                                print("shipArr = \(shipArr)")
                                if (!CDShipping.saveShippingsFromArrayJson(shipArr)) {
                                    isInitialMetadataSaveSuccess = false
                                }
                            } else {
                                isInitialMetadataSaveSuccess = false
                            }
                        } catch {
                            isInitialMetadataSaveSuccess = false
                        }
                    } else {
                        isInitialMetadataSaveSuccess = false
                    }
                } else { // App is updated from older version
                    // Jika versi metadata baru, load dan save kembali di coredata
                    // Karena ada proses request bersifat paralel dan managed object context beresiko jika diakses berbarengan, proses update ini harus dilakukan secara bergantian, jadi dipilih mana yg dilakukan duluan dari ke-4 jenis metadata, jika satu metadata telah selesai diupdate, baru dilanjutkan yg lainnya
                    // Urutannya: Categories - ProductConditions - ProvinceRegions - Shippings
                    let updateVer = data["metadata_versions"]
                    if (ver!.categoriesVersion.integerValue < updateVer["categories"].numberValue.integerValue) {
                        self.updateMetaCategories(ver!, updateVer: updateVer)
                    } else if (ver!.productConditionsVersion.integerValue < updateVer["product_conditions"].numberValue.integerValue) {
                        self.updateMetaProductConditions(ver!, updateVer: updateVer)
                    } else if (ver!.provincesRegionsVersion.integerValue < updateVer["province_regions"].numberValue.integerValue) {
                        self.updateMetaProvinceRegions(ver!, updateVer: updateVer)
                    } else if (ver!.shippingsVersion.integerValue < updateVer["shippings"].numberValue.integerValue) {
                        self.updateMetaShippings()
                    } else {
                        // Version check is done
                        self.versionChecked()
                    }
                }
                
                // Check if app is just updated
                if let installedVer = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String {
                    if let lastInstalledVer = CDVersion.getOne()?.appVersion {
                        if (installedVer.compare(lastInstalledVer, options: .NumericSearch, range: nil, locale: nil) == .OrderedDescending) {
                            // MoEngage
                            MoEngage.sharedInstance().appStatus(UPDATE)
                        }
                    }
                }
                
                // Save version to core data
                CDVersion.saveVersions(data)
                
                // Check if app need to be updated
                if let installedVer = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String {
                    if let newVer = CDVersion.getOne()?.appVersion {
                        if (newVer.compare(installedVer, options: .NumericSearch, range: nil, locale: nil) == .OrderedDescending) {
                            let alert : UIAlertController = UIAlertController(title: "New Version Available", message: "Prelo \(newVer) is available on App Store", preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "Update", style: .Default, handler: { action in
                                UIApplication.sharedApplication().openURL(NSURL(string: "itms-apps://itunes.apple.com/id/app/prelo/id1027248488")!)
                            }))
                            if let isForceUpdate = data["is_force_update"].bool {
                                if (!isForceUpdate) {
                                    alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
                                }
                            } else {
                                alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
                            }
                            self.presentViewController(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
            
            if (isFirstInstall) {
                if (isInitialMetadataSaveSuccess) {
                    Constant.showDialog("Success", message: "Load App Data Success")
                } else {
                    Constant.showDialog("Load App Data Failed", message: "Oops, terdapat kesalahan saat memproses data. Prelo mungkin akan tidak berjalan dengan baik. Untuk memperbaiki, silahkan ke menu About > Reload App Data")
                }
                
                // Di titik ini, version check telah selesai jika first install, yaitu yg dilakukan adalah save metadata for the first time, kalo update from older version, belum tentu udah selesai
                self.versionChecked()
            }
        }
    }
    
    func versionChecked() {
        self.isVersionChecked = true
        
        if (self.isAlreadyGetCategory) { // Only hide loading if category is already loaded and version already checked
            self.hideLoading()
        }
    }
    
    func updateMetaCategories(ver : CDVersion, updateVer : JSON) {
        request(APIApp.MetadataCategories(currentVer: ver.categoriesVersion.integerValue)).responseJSON { resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Update Metadata Categories")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if let deleteData = data["delete"].array {
                    CDCategory.deleteCategoriesFromArrayJson(deleteData)
                }
                if let addData = data["add"].array {
                    CDCategory.saveCategoriesFromArrayJson(addData)
                }
                if let updateData = data["update"].array {
                    CDCategory.updateCategoriesFromArrayJson(updateData)
                }
            }
            
            // Continue updating metadata
            if (ver.productConditionsVersion.integerValue < updateVer["product_conditions"].numberValue.integerValue) {
                self.updateMetaProductConditions(ver, updateVer: updateVer)
            } else if (ver.provincesRegionsVersion.integerValue < updateVer["province_regions"].numberValue.integerValue) {
                self.updateMetaProvinceRegions(ver, updateVer: updateVer)
            } else if (ver.shippingsVersion.integerValue < updateVer["shippings"].numberValue.integerValue) {
                self.updateMetaShippings()
            } else {
                // Version check is done
                self.versionChecked()
            }
        }
    }
    
    func updateMetaProductConditions(ver : CDVersion, updateVer : JSON) {
        request(APIApp.MetadataProductConditions).responseJSON { resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Update Metadata Product Conditions")) {
                let json = JSON(resp.result.value!)
                if let arr = json["_data"].array {
                    if (CDProductCondition.deleteAll(UIApplication.appDelegate.managedObjectContext)) {
                        CDProductCondition.saveProductConditionsFromArrayJson(arr)
                    }
                }
            }
            
            // Continue updating metadata
            if (ver.provincesRegionsVersion.integerValue < updateVer["province_regions"].numberValue.integerValue) {
                self.updateMetaProvinceRegions(ver, updateVer: updateVer)
            } else if (ver.shippingsVersion.integerValue < updateVer["shippings"].numberValue.integerValue) {
                self.updateMetaShippings()
            } else {
                // Version check is done
                self.versionChecked()
            }
        }
    }
    
    func updateMetaProvinceRegions(ver : CDVersion, updateVer : JSON) {
        request(APIApp.MetadataProvincesRegions(currentVer: ver.provincesRegionsVersion.integerValue)).responseJSON { resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Update Metadata Province Regions")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if let deleteDataProv = data["provinces"]["delete"].array {
                    CDProvince.deleteProvincesFromArrayJson(deleteDataProv)
                }
                if let addDataProv = data["provinces"]["add"].array {
                    CDProvince.saveProvincesFromArrayJson(addDataProv)
                }
                if let updateDataProv = data["provinces"]["update"].array {
                    CDProvince.updateProvincesFromArrayJson(updateDataProv)
                }
                if let deleteDataReg = data["regions"]["delete"].array {
                    CDRegion.deleteRegionsFromArrayJson(deleteDataReg)
                }
                if let addDataReg = data["regions"]["add"].array {
                    CDRegion.saveRegionsFromArrayJson(addDataReg)
                }
                if let updateDataReg = data["regions"]["update"].array {
                    CDRegion.updateRegionsFromArrayJson(updateDataReg)
                }
            }
            
            // Continue updating metadata
            if (ver.shippingsVersion.integerValue < updateVer["shippings"].numberValue.integerValue) {
                self.updateMetaShippings()
            } else {
                // Version check is done
                self.versionChecked()
            }
        }
    }
    
    func updateMetaShippings() {
        request(APIApp.MetadataShippings).responseJSON { resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Update Metadata Shipping")) {
                let json = JSON(resp.result.value!)
                if let arr = json["_data"].array {
                    if (CDShipping.deleteAll(UIApplication.appDelegate.managedObjectContext)) {
                        CDShipping.saveShippingsFromArrayJson(arr)
                    }
                }
            }
            
            // Version check is done
            self.versionChecked()
        }
    }
}
