//
//  KumangTabBarViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/27/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Alamofire

// MARK: - Class

class KumangTabBarViewController: BaseViewController, UserRelatedDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var loadingPanel: UIView!
    @IBOutlet var sectionContent : UIView?
    @IBOutlet var sectionBar : UIView?
    @IBOutlet var btnAdd : UIView?
    @IBOutlet var btnDashboard : UIButton!
    @IBOutlet var btnBrowse : UIButton!
    @IBOutlet var consMarginBottomBar : NSLayoutConstraint!
    var oldController : UIViewController?
    var controllerBrowse : UIViewController?
    var _controllerDashboard : BaseViewController?
    var controllerDashboard : BaseViewController?
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
    
    // Data container
    var numberOfControllers : Int = 0
    var changeToBrowseCount = 0
    
    // Flags
    var isVersionChecked = false
    var isAlreadyGetCategory : Bool = false
    var userDidLoggedIn : Bool?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Loading panel
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        // Version check
        if (!isVersionChecked) {
            self.versionCheck()
        } else {
            self.versionChecked()
        }
        
        /*
        // Resume product upload
        if (User.Token != nil && CDUser.getOne() != nil) { // If user is logged in
//            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
                AppDelegate.Instance.produkUploader.start()
            })
        }
         */
        
        // Subdistrict check
        self.subdistrictProfileCheck()
        
        // Adjust navbar and title view
        self.navigationController?.navigationBar.tintColor = UIColor.white
        let v = UIView()
        v.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        v.backgroundColor = UIColor.clear
        self.navigationItem.titleView = v
        
        // Login button setup
        self.updateLoginButton()
        
        // Set left-corner title
        self.setupTitle()
        
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(KumangTabBarViewController.showProduct(_:)), name: NSNotification.Name(rawValue: NotificationName.ShowProduct), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KumangTabBarViewController.hideBottomBar), name: NSNotification.Name(rawValue: "hideBottomBar"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KumangTabBarViewController.showBottomBar), name: NSNotification.Name(rawValue: "showBottomBar"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KumangTabBarViewController.updateLoginButton), name: NSNotification.Name(rawValue: "userLoggedIn"), object: nil)

        // Sell button setup
        btnAdd?.layoutIfNeeded()
        btnAdd?.layer.cornerRadius = (btnAdd?.frame.size.width)!/2
        btnAdd?.layer.shadowColor = UIColor.black.cgColor
        btnAdd?.layer.shadowOffset = CGSize(width: 0, height: 5)
        btnAdd?.layer.shadowOpacity = 0.3
        
        // Init controllers
        let lc : ListCategoryViewController = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdBrowse) as! ListCategoryViewController
        lc.previousController = self
        controllerBrowse = lc
        controllerDashboard = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdDashboard) as? BaseViewController
        controllerDashboard?.previousController = self
        controllerDashboard2 = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdDashboard) as? BaseViewController
        controllerDashboard2?.previousController = self
        changeToController(controllerBrowse!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show bottom bar
        self.showBottomBar()
        
        // Setup navbar buttons
        self.setupNormalOptions()
        
        // Status bar color
        self.setStatusBarBackgroundColor(color: Theme.PrimaryColor)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show status bar
        self.showStatusBar()
        
        // Status bar color
        self.setStatusBarBackgroundColor(color: UIColor.clear)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show tour pop up, refresh home, and/or show pop up
        if (!UserDefaults.isTourDone() && !isAlreadyGetCategory && !User.IsLoggedIn) { // Jika akan memanggil tour
            self.performSegue(withIdentifier: "segTour", sender: self)
            UserDefaults.setTourDone(true)
        } else {
            let preloBaseUrlJustChanged : Bool? = UserDefaults.standard.object(forKey: UserDefaultsKey.PreloBaseUrlJustChanged) as! Bool?
            if ((AppTools.isDev && preloBaseUrlJustChanged == true) || (userDidLoggedIn == false && User.IsLoggedIn) || (userDidLoggedIn == true && !User.IsLoggedIn)) { // Jika user baru saja log in, baru saja log out, atau baru saja switch base url dalam dev mode
                UserDefaults.standard.set(false, forKey: UserDefaultsKey.PreloBaseUrlJustChanged)
                UserDefaults.standard.synchronize()
                (self.controllerBrowse as? ListCategoryViewController)?.grandRefresh()
                
                // Subdistrict check
                self.subdistrictProfileCheck()
            } else if (!isAlreadyGetCategory) { // Jika tidak memanggil tour saat membuka app, atau jika tour baru saja selesai
                (self.controllerBrowse as? ListCategoryViewController)?.getCategory()
            }
        }
        userDidLoggedIn = User.IsLoggedIn
    }
    
    // MARK: - View-related actions
    
    func subdistrictProfileCheck() {
        if (User.IsLoggedIn && CDUser.getOne() != nil && CDUserProfile.getOne() != nil && CDUserOther.getOne() != nil && (CDUserProfile.getOne()?.subdistrictID == nil || CDUserProfile.getOne()?.subdistrictID == "")) {
            let sdAlert = UIAlertController(title: "Perhatian", message: "Lengkapi kecamatan di profil kamu sekarang untuk ongkos kirim yang lebih akurat", preferredStyle: .alert)
            sdAlert.addAction(UIAlertAction(title: "Oke", style: .default, handler: { action in
                let userProfileVC = Bundle.main.loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil)?.first as! UserProfileViewController
                self.navigationController?.pushViewController(userProfileVC, animated: true)
            }))
            self.present(sdAlert, animated: true, completion: nil)
        }
    }
    
    func updateLoginButton() {
        if (User.IsLoggedIn) {
            btnDashboard.setTitle("MY ACCOUNT", for: UIControlState())
        } else {
            btnDashboard.setTitle("LOG IN", for: UIControlState())
        }
    }
    
    func hideBottomBar() {
        consMarginBottomBar.constant = -76
        UIView.animate(withDuration: 0.2, animations: {
            self.sectionBar?.layoutIfNeeded()
            self.btnAdd?.layoutIfNeeded()
        })
    }
    
    func showBottomBar() {
        consMarginBottomBar.constant = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.sectionBar?.layoutIfNeeded()
            self.btnAdd?.layoutIfNeeded()
        })
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    // MARK: - User related functions
    
    func userLoggedIn() {
        btnDashboard.setTitle("MY ACCOUNT", for: UIControlState())
        let d : BaseViewController = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdDashboard) as! BaseViewController
        d.previousController = self
        changeToController(d)
        controllerDashboard = d
    }
    
    func userLoggedOut() {
        btnDashboard.setTitle("LOG IN", for: UIControlState())
        changeToController(controllerBrowse!)
    }
    
    func userCancelLogin() {
        btnDashboard.setTitle("LOG IN", for: UIControlState())
        changeToController(controllerBrowse!)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "segTour") {
            let t = (segue.destination as? UINavigationController)?.viewControllers.first as! TourViewController
            t.parentVC = sender as? BaseViewController
        }
    }
    
    func showProduct(_ sender : Any) {
        let n : Foundation.Notification = sender as! Foundation.Notification
        let p = n.object as? Array<AnyObject> // for handle with previous page name - [Product, String]
        
        let d : ProductDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
        d.previousScreen = p?[1] as! String
        let nav = UINavigationController(rootViewController: d)
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.barTintColor = Theme.navBarColor
        nav.navigationBar.tintColor = UIColor.white
        if let pro = p?[0] as? Product {
            d.product = pro
        } else if let pro = n.object as? Product {
            d.product = pro
        }

        self.navigationController?.pushViewController(d, animated: true)
    }
    
    func delayBrowseSwitch() {
        sectionContent?.isHidden = false
        changeToController(controllerBrowse!)
    }
    
    func changeToController(_ newController : UIViewController) {
        print("class name = \(type(of: newController))")
        if ("\(type(of: newController))" == "ListCategoryViewController") { // Browse
            btnDashboard.titleLabel?.font = UIFont.systemFont(ofSize: 13)
            btnDashboard.setTitleColor(UIColor.lightGray, for: UIControlState())
            btnBrowse.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            btnBrowse.setTitleColor(Theme.GrayGranite, for: UIControlState())
        } else if ("\(type(of: newController))" == "DashboardViewController") { // Login/Dashboard
            btnDashboard.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            btnDashboard.setTitleColor(Theme.GrayGranite, for: UIControlState())
            btnBrowse.titleLabel?.font = UIFont.systemFont(ofSize: 13)
            btnBrowse.setTitleColor(UIColor.lightGray, for: UIControlState())
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
        let horizontalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v1]-0-|", options: .alignAllTop, metrics: nil, views: ["v1": v!.view])
        let verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v1]-0-|", options: .alignAllTop, metrics: nil, views: ["v1": v!.view])
        
        sectionContent?.addConstraints(horizontalConstraint)
        sectionContent?.addConstraints(verticalConstraint)
        
        oldController = v
        self.addChildViewController(oldController!)
    }
    
    @IBAction func switchController(_ sender: AnyObject) {
        let btn : AppButton = sender as! AppButton
        if (btn.stringTag == Tags.Browse) {
            if isAlreadyGetCategory == false {
                self.showLoading()
            }
            self.setupNormalOptions() // Agar notification terupdate
            changeToController(controllerBrowse!)
            
            if (changeToBrowseCount == 0) {
                changeToBrowseCount = 1
                sectionContent?.isHidden = true
                Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(KumangTabBarViewController.delayBrowseSwitch), userInfo: nil, repeats: false)
            }
            
        } else {
            self.hideLoading()
            
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
    
    @IBAction func launchMenu() {
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        add.screenBeforeAddProduct = PageName.Home
        self.navigationController?.pushViewController(add, animated: true)
    }
    
    // MARK: - Version check and load/update metadata
    
    func versionCheck() {
        // API Migrasi
        let _ = request(APIApp.version).responseJSON { resp in
            var isFirstInstall = false
            var isInitialMetadataSaveSuccess : Bool = true
            
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Version Check")) {
                let json = JSON(resp.result.value!)
                var data = json["_data"]
                
                let ver : CDVersion? = CDVersion.getOne()
                
                if (ver == nil) { // App is installed for the first time
                    isFirstInstall = true
                    
                    // MoEngage
                    MoEngage.sharedInstance().appStatus(INSTALL)
                    
                    // Save category for the first time, from local json file
                    if let metadataPath = Bundle.main.path(forResource: "InitialMetadata", ofType: "json") {
                        do {
                            let metadataData = try Data(contentsOf: URL(fileURLWithPath: metadataPath), options: NSData.ReadingOptions.mappedIfSafe)
                            let metadataJson = JSON(data: metadataData)
                            
                            data["metadata_versions"] = metadataJson["_data"]["metadata_versions"]
                            
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
                    if (ver!.categoriesVersion.intValue < updateVer["categories"].numberValue.intValue) {
                        self.updateMetaCategories(ver!, updateVer: updateVer)
                    } else if (ver!.productConditionsVersion.intValue < updateVer["product_conditions"].numberValue.intValue) {
                        self.updateMetaProductConditions(ver!, updateVer: updateVer)
                    } else if (ver!.provincesRegionsVersion.intValue < updateVer["province_regions"].numberValue.intValue) {
                        self.updateMetaProvinceRegions(ver!, updateVer: updateVer)
                    } else if (ver!.shippingsVersion.intValue < updateVer["shippings"].numberValue.intValue) {
                        self.updateMetaShippings()
                    } else {
                        // Version check is done
                        self.versionChecked()
                    }
                }
                
                // Check if app is just updated
                if let installedVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                    if let lastInstalledVer = CDVersion.getOne()?.appVersion {
                        if (installedVer.compare(lastInstalledVer, options: .numeric, range: nil, locale: nil) == .orderedDescending) {
                            // MoEngage
                            MoEngage.sharedInstance().appStatus(UPDATE)
                        }
                    }
                }
                
                // Save version to core data
                CDVersion.saveVersions(data)
                
                /*
                // Check if app need to be updated
                if let installedVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                    if let newVer = CDVersion.getOne()?.appVersion {
                        if (newVer.compare(installedVer, options: .numeric, range: nil, locale: nil) == .orderedDescending) {
                            UserDefaults.standard.set(newVer, forKey: UserDefaultsKey.UpdatePopUpVer)
                            
                            if let releaseNotes = data["release_notes"].array {
                                var notes = ""
                                for rn in releaseNotes {
                                    notes += rn.stringValue + "\n"
                                }
                                UserDefaults.standard.set(notes, forKey: UserDefaultsKey.UpdatePopUpNotes)
                            } else if let releaseNotes = data["release_notes"].string {
                                UserDefaults.standard.set(releaseNotes, forKey: UserDefaultsKey.UpdatePopUpNotes)
                            }
                            
                            if let isForceUpdate = data["is_force_update"].bool {
                                UserDefaults.standard.set(isForceUpdate, forKey: UserDefaultsKey.UpdatePopUpForced)
                            }
                            
                            UserDefaults.standard.synchronize()
                        }
                    }
                }
                 */
            }
            
            if (isFirstInstall) {
                if (isInitialMetadataSaveSuccess) {
                    //Constant.showDialog("Success", message: "Load App Data Success")
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
    
    func updateMetaCategories(_ ver : CDVersion, updateVer : JSON) {
        let _ = request(APIApp.metadataCategories(currentVer: ver.categoriesVersion.intValue)).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Update Metadata Categories")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if let deleteData = data["delete"].array {
                    _ = CDCategory.deleteCategoriesFromArrayJson(deleteData)
                }
                if let addData = data["add"].array {
                    _ = CDCategory.saveCategoriesFromArrayJson(addData)
                }
                if let updateData = data["update"].array {
                    _ = CDCategory.updateCategoriesFromArrayJson(updateData)
                }
            }
            
            // Continue updating metadata
            if (ver.productConditionsVersion.intValue < updateVer["product_conditions"].numberValue.intValue) {
                self.updateMetaProductConditions(ver, updateVer: updateVer)
            } else if (ver.provincesRegionsVersion.intValue < updateVer["province_regions"].numberValue.intValue) {
                self.updateMetaProvinceRegions(ver, updateVer: updateVer)
            } else if (ver.shippingsVersion.intValue < updateVer["shippings"].numberValue.intValue) {
                self.updateMetaShippings()
            } else {
                // Version check is done
                self.versionChecked()
            }
        }
    }
    
    func updateMetaProductConditions(_ ver : CDVersion, updateVer : JSON) {
        let _ = request(APIApp.metadataProductConditions).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Update Metadata Product Conditions")) {
                let json = JSON(resp.result.value!)
                if let arr = json["_data"].array {
                    if (CDProductCondition.deleteAll(UIApplication.appDelegate.managedObjectContext)) {
                        _ = CDProductCondition.saveProductConditionsFromArrayJson(arr)
                    }
                }
            }
            
            // Continue updating metadata
            if (ver.provincesRegionsVersion.intValue < updateVer["province_regions"].numberValue.intValue) {
                self.updateMetaProvinceRegions(ver, updateVer: updateVer)
            } else if (ver.shippingsVersion.intValue < updateVer["shippings"].numberValue.intValue) {
                self.updateMetaShippings()
            } else {
                // Version check is done
                self.versionChecked()
            }
        }
    }
    
    func updateMetaProvinceRegions(_ ver : CDVersion, updateVer : JSON) {
        let _ = request(APIApp.metadataProvincesRegions(currentVer: ver.provincesRegionsVersion.intValue)).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Update Metadata Province Regions")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if let deleteDataProv = data["provinces"]["delete"].array {
                    _ = CDProvince.deleteProvincesFromArrayJson(deleteDataProv)
                }
                if let addDataProv = data["provinces"]["add"].array {
                    _ = CDProvince.saveProvincesFromArrayJson(addDataProv)
                }
                if let updateDataProv = data["provinces"]["update"].array {
                    _ = CDProvince.updateProvincesFromArrayJson(updateDataProv)
                }
                if let deleteDataReg = data["regions"]["delete"].array {
                    _ = CDRegion.deleteRegionsFromArrayJson(deleteDataReg)
                }
                if let addDataReg = data["regions"]["add"].array {
                    _ = CDRegion.saveRegionsFromArrayJson(addDataReg)
                }
                if let updateDataReg = data["regions"]["update"].array {
                    _ = CDRegion.updateRegionsFromArrayJson(updateDataReg)
                }
            }
            
            // Continue updating metadata
            if (ver.shippingsVersion.intValue < updateVer["shippings"].numberValue.intValue) {
                self.updateMetaShippings()
            } else {
                // Version check is done
                self.versionChecked()
            }
        }
    }
    
    func updateMetaShippings() {
        let _ = request(APIApp.metadataShippings).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Update Metadata Shipping")) {
                let json = JSON(resp.result.value!)
                if let arr = json["_data"].array {
                    if (CDShipping.deleteAll(UIApplication.appDelegate.managedObjectContext)) {
                        _ = CDShipping.saveShippingsFromArrayJson(arr)
                    }
                }
            }
            
            // Version check is done
            self.versionChecked()
        }
    }
}
