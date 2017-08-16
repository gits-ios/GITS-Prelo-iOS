//
//  AboutViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/27/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import CoreData
import Crashlytics
import Alamofire

class AboutViewController: BaseViewController/*, UIAlertViewDelegate*/ {

    @IBOutlet var btnLogout : BorderedButton!
    @IBOutlet var btnClear : BorderedButton!
    @IBOutlet var btnClear2 : BorderedButton!
    @IBOutlet weak var lblVersion: UILabel!
    @IBOutlet weak var btnUrlPrelo: UIButton!
    @IBOutlet var consHeightVwPreloTeam: NSLayoutConstraint! // Unused
    
    var isShowLogout : Bool = true
    
    var easterEggAlert : UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (!isShowLogout) {
            self.btnLogout.isHidden = true
            self.btnClear.isHidden = true
            self.btnClear2.isHidden = false
        }
        
        self.title = PageName.About
        
        self.lblVersion.text = "-"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                self.lblVersion.text = "Version " + version + " Build " + build
            }
        }
        
        if (AppTools.isDev) {
            let attr = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue, NSForegroundColorAttributeName: UIColor.white] as [String : Any]
            if (AppTools.IsPreloProduction) {
                let attrString = NSAttributedString(string: "switch to dev", attributes: attr)
                self.btnUrlPrelo.setAttributedTitle(attrString, for: UIControlState())
            } else {
                let attrString = NSAttributedString(string: "switch to production", attributes: attr)
                self.btnUrlPrelo.setAttributedTitle(attrString, for: UIControlState())
            }
            
            // developer toggle
            self.setDevButton()
        }
        
        // Remove 1px line at the bottom of navbar
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.About)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.About)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openPreloSite(_ sender: AnyObject) {
        if (AppTools.isDev) {
            self.logout()
            if (AppTools.IsPreloProduction) {
                // switch to dev
                AppTools.switchToDev(true)
                AnalyticManager.switchToDev(true)
            } else {
                // switch to production
                AppTools.switchToDev(false)
                AnalyticManager.switchToDev(false)
            }
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.PreloBaseUrlJustChanged)
            UserDefaults.standard.synchronize()
        } else {
            UIApplication.shared.openURL(URL(string: AppTools.PreloBaseUrl)!)
        }
    }
    
    @IBAction func reloadAppData(_ sender: AnyObject) {
        /*
        // Tampilkan pop up untuk prompt
        let a = UIAlertView()
        a.message = "Reload App Data membutuhkan waktu beberapa saat. Lanjutkan?"
        a.addButton(withTitle: "Batal")
        a.addButton(withTitle: "Reload App Data")
        a.cancelButtonIndex = 0
        a.delegate = self
        a.show()
         */
        
        let alertView = SCLAlertView(appearance: Constant.appearance)
        alertView.addButton("Reload App Data") {
            self.reloadingAppData()
        }
        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
        alertView.showCustom("Reload App Data", subTitle: "Reload App Data membutuhkan waktu beberapa saat. Lanjutkan?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    @IBAction func clearCache() {
        toClearCache(isButton: true)
        
        Constant.showDialog("Clear Cache", message: "Clear Cache telah berhasil")
        self.enableBtnClearCache()
    }
    
    func toClearCache(isButton : Bool) {
        // Get cart products
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = delegate.preloNotifListener
        
        if AppTools.isNewCart { // v2
            let cartSize = CartManager.sharedInstance.getSize()
            notifListener?.increaseCartCount(-cartSize)
        } else { // v1
            let cartProducts = CartProduct.getAll(User.EmailOrEmptyString)
            notifListener?.increaseCartCount(-cartProducts.count)
        }
        
        disableBtnClearCache()
        //UIImageView.sharedImageCache().clearAll()
        
        CartProduct.deleteAll() // v1
        CartManager.sharedInstance.deleteAll() // v2
        
        // disabled
        /*
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let p = AppToolsObjC.jsonString(from: c)
        var pID = ""
        var rID = ""
        if let u = CDUser.getOne()
        {
            pID = u.profiles.provinceID
            rID = u.profiles.regionID
        }
        let a = "{\"address\": \"alamat\", \"province_id\": \"" + pID + "\", \"region_id\": \"" + rID + "\", \"postal_code\": \"\"}"
        let _ = request(APICart.refresh(cart: p!, address: a, voucher: nil)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Clear Cache")) {
                self.enableBtnClearCache()
                
                if isButton {
                    Constant.showDialog("Clear Cache", message: "Clear Cache telah berhasil")
                }
            } else {
                self.enableBtnClearCache()
            }
        }
         */
        
        _ = CDDraftProduct.deleteAll()
        
        // reset localid
        User.SetCartLocalId("")
    }
    
    @IBAction func logout()
    {
        // Clear Cache --> for handling login another account
//        toClearCache(isButton: false)
        
        // Remove deviceRegId so the device won't receive push notification
        LoginViewController.SendDeviceRegId()
        
        // Tell server
        // API Migrasi
        let _ = request(APIAuth.logout).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Logout")) {
                //print("Logout API success")
            }
        }
        
        /*
        // Mixpanel event
        let p = ["User ID" : ((User.Id != nil) ? User.Id! : "")]
        Mixpanel.trackEvent(MixpanelEvent.Logout, properties: p)
         */
        
        // Prelo Analytic - Logout
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            "Username" : CDUser.getOne()?.username ?? ""
        ] as [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.Logout, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
        
        // Clear local data
        User.Logout()
        
        _ = CDDraftProduct.deleteAll()
        
        //cart
        CartProduct.deleteAll() // v1
        CartManager.sharedInstance.deleteAll() // v2
        
        // Tell delegate class if any
        if let d = self.userRelatedDelegate
        {
            d.userLoggedOut!()
        }
        
        if let del = UIApplication.shared.delegate as? AppDelegate
        {
            del.messagePool?.stop()
        } else
        {
            let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
            Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"logout"])
        }
        
        // Disconnect socket
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = delegate.preloNotifListener
        
        // Set top bar notif number to 0
        if (notifListener?.newNotifCount != 0) {
            notifListener?.setNewNotifCount(0)
        }
        
        if (notifListener?.cartCount != 0) {
            notifListener?.setCartCount(0)
        }
        
        if (GIDSignIn.sharedInstance().hasAuthInKeychain()) {
            GIDSignIn.sharedInstance().signOut()
            print("masukSignOut")
        }
        
        /*
        // Reset mixpanel
        Mixpanel.sharedInstance().reset()
        let uuid = UIDevice.current.identifierForVendor!.uuidString
        Mixpanel.sharedInstance().identify(uuid)
         */
        
        // MoEngage reset
        MoEngage.sharedInstance().resetUser()
        
        AppDelegate.Instance.produkUploader.stop()
        AppDelegate.Instance.produkUploader.clearQueue()
        
        // Back to previous page
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UIAlertView delegate function
    
//    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
//        switch buttonIndex {
//        case 0: // Batal
//            alertView.dismiss(withClickedButtonIndex: -1, animated: true)
//            break
//        case 1: // Reload App Data
//            alertView.dismiss(withClickedButtonIndex: -1, animated: true)
//            // Tampilkan pop up untuk loading
//            reloadingAppData()
//            break
//        default:
//            break
//        }
//    }
    
    // MARK: - Other functions
    
    func enableBtnClearCache() {
        self.btnClear.setTitle("CLEAR CACHE", for: UIControlState())
        self.btnClear.isUserInteractionEnabled = true
        self.btnClear2.setTitle("CLEAR CACHE", for: UIControlState())
        self.btnClear2.isUserInteractionEnabled = true
    }
    
    func disableBtnClearCache() {
        btnClear.setTitle("Loading...", for: UIControlState())
        btnClear.isUserInteractionEnabled = false
        btnClear2.setTitle("Loading...", for: UIControlState())
        btnClear2.isUserInteractionEnabled = false
    }
    
    // for testing only
    func printCoreDataCount() {
        print("Category = \(CDCategory.getCategoryCount())")
        print("Brand = \(CDBrand.getBrandCount())")
        print("CategorySize = \(CDCategorySize.getCategorySizeCount())")
        print("Shipping = \(CDShipping.getShippingCount())")
        print("ProductCondition = \(CDProductCondition.getProductConditionCount())")
        print("Province = \(CDProvince.getProvinceCount())")
    }
    
    func reloadingAppData() {
        // Tampilkan pop up untuk loading
        //let a = UIAlertView()
        let pView : UIProgressView = UIProgressView(progressViewStyle: UIProgressViewStyle.bar)
        pView.progress = 0
        pView.backgroundColor = Theme.GrayLight
        pView.progressTintColor = Theme.ThemeOrange
//        a.setValue(pView, forKey: "accessoryView")
//        a.title = "Reloading App Data..."
//        a.message = "Harap untuk tidak menutup aplikasi selama proses berjalan"
//        a.show()
        
        let alertView = SCLAlertView(appearance: Constant.appearance)
        let subtitle = UILabel()
        
        subtitle.text = "Harap untuk tidak menutup aplikasi selama proses berjalan"
        subtitle.font = Constant.appearance.kTextFont
        subtitle.textColor = alertView.labelTitle.textColor
        subtitle.numberOfLines = 0
        subtitle.textAlignment = .center
        
        let width = Constant.appearance.kWindowWidth - 24
        let frame = subtitle.text!.boundsWithFontSize(Constant.appearance.kTextFont, width: width)
        
        subtitle.frame = frame
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0, y: 0, width: width, height: frame.height + 18))
        subview.addSubview(subtitle)
        subview.addSubview(pView)
        
        subtitle.width = subview.bounds.width
        
        pView.frame = CGRect(x: 0, y: frame.height + 16, width: width, height: 2)
        
        alertView.customSubview = subview
        
        let alertViewResponder: SCLAlertViewResponder = alertView.showCustom("Reloading App Data...", subTitle: "", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)

        // API Migrasi
        let _ = request(APIApp.metadata(brands: "0", categories: "1", categorySizes: "0", shippings: "1", productConditions: "1", provincesRegions: "1")).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Reload App Data")) {
                let metaJson = JSON(resp.result.value!)
                let metadata = metaJson["_data"]
                
                var isSuccess : Bool = true
                let queue : OperationQueue = OperationQueue()
                
                let opCategories : Operation = BlockOperation(block: {
                    let psc = UIApplication.appDelegate.persistentStoreCoordinator
                    let moc = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
                    moc.persistentStoreCoordinator = psc
                    
                    // Update categories
                    //print("Updating categories..")
                    if (CDCategory.deleteAll(moc)) {
                        if (CDCategory.saveCategories(metadata["categories"], m: moc)) {
                            DispatchQueue.main.async(execute: {
                                pView.setProgress(pView.progress + 0.25, animated: true)
                            })
                        } else {
                            isSuccess = false
                        }
                    }
                })
                queue.addOperation(opCategories)
                
                
                let opShippings : Operation = BlockOperation(block: {
                    let psc = UIApplication.appDelegate.persistentStoreCoordinator
                    let moc = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
                    moc.persistentStoreCoordinator = psc
                    
                    // Update shippings
                    //print("Updating shippings..")
                    if (CDShipping.deleteAll(moc)) {
                        if (CDShipping.saveShippings(metadata["shippings"], m: moc)) {
                            DispatchQueue.main.async(execute: {
                                pView.setProgress(pView.progress + 0.25, animated: true)
                            })
                        } else {
                            isSuccess = false
                        }
                    }
                })
                queue.addOperation(opShippings)
                
                let opProductConditions : Operation = BlockOperation(block: {
                    let psc = UIApplication.appDelegate.persistentStoreCoordinator
                    let moc = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
                    moc.persistentStoreCoordinator = psc
                    
                    // Update product conditions
                    //print("Updating product conditions..")
                    if (CDProductCondition.deleteAll(moc)) {
                        if (CDProductCondition.saveProductConditions(metadata["product_conditions"], m: moc)) {
                            DispatchQueue.main.async(execute: {
                                pView.setProgress(pView.progress + 0.25, animated: true)
                            })
                        } else {
                            isSuccess = false
                        }
                    }
                })
                queue.addOperation(opProductConditions)
                
                let opProvincesRegions : Operation = BlockOperation(block: {
                    let psc = UIApplication.appDelegate.persistentStoreCoordinator
                    let moc = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
                    moc.persistentStoreCoordinator = psc
                    
                    // Update provinces regions
                    //print("Updating provinces regions..")
                    if (CDProvince.deleteAll(moc) && CDRegion.deleteAll(moc)) {
                        if (CDProvince.saveProvinceRegions(metadata["provinces_regions"], m: moc)) {
                            DispatchQueue.main.async(execute: {
                                pView.setProgress(pView.progress + 0.25, animated: true)
                            })
                        } else {
                            isSuccess = false
                        }
                    }
                })
                queue.addOperation(opProvincesRegions)
                
                let opFinish : Operation = BlockOperation(block: {
//                    a.dismiss(withClickedButtonIndex: -1, animated: true)
                    if (isSuccess) {
                        DispatchQueue.main.async(execute: {
                            alertViewResponder.close()
                            
                            Constant.showDialog("Reload App Data", message: "Reload App Data berhasil")
                        })
                    } else {
                        DispatchQueue.main.async(execute: {
                            alertViewResponder.close()
                            
                            Constant.showDialog("Reload App Data", message: "Oops, terjadi kesalahan saat Reload App Data")
                        })
                    }
                })
                opFinish.addDependency(opCategories)
                opFinish.addDependency(opShippings)
                opFinish.addDependency(opProductConditions)
                opFinish.addDependency(opProvincesRegions)
                queue.addOperation(opFinish)
            } else {
//                a.dismiss(withClickedButtonIndex: -1, animated: true)
                alertViewResponder.close()
            }
        }
    }

    @IBAction func easterEggPressed(_ sender: UIButton) {
        easterEggAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        easterEggAlert?.popoverPresentationController?.sourceView = sender
        easterEggAlert?.popoverPresentationController?.sourceRect = sender.bounds
        
        var str = ""
        let tag = sender.tag
        switch tag {
        case 1 : // Algo
            str = "Kucing paling takut sama siapa?"
            break
        case 2 : // Ope
            str = "Kanadin Kanadin"
            break
        case 3 : // Nadin
            str = "Terima kasih semuanya selamat duduk"
            break
        case 4 : // Anggi
            str = "Tektoknya harus balance"
            break
        case 5 : // Nanda
            str = "Mha hart mah sole"
            break
        case 6 : // K PW
            str = "Nyam nyam poy"
            break
        case 7 : // Riri
            str = "Aku.. gajadi deh"
            break
        case 8 : // Yossy
            str = "Okii"
            break
        case 9 : // Rico
            str = "Tonenonet Eghp eghp.. nenonet eghp eghp"
            break
        case 10 : // Rido
            str = "Gua punya satu pertanyaan"
            break
        case 11 : // K Set
            str = "Seerius?"
            break
        case 12 : // Andew
            str = "Yang yaaaaang"
            break
        case 13 : // Dea
            str = "Atukepiilinibiiza"
            break
        default: break
        }
        
        if (AppTools.isIPad) {
            easterEggAlert?.title = str
        } else {
            let attrStr = NSAttributedString(string: str, attributes: [NSForegroundColorAttributeName : Theme.PrimaryColor, NSFontAttributeName : UIFont.systemFont(ofSize: 14)])
            easterEggAlert?.setValue(attrStr, forKey: "attributedTitle")
            easterEggAlert?.addAction(UIAlertAction(title: "Close", style: .default, handler: { act in
                self.dismissEasterEgg()
            }))
        }
        
        self.present(easterEggAlert!, animated: true, completion: {
            let easterGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissEasterEgg))
            self.easterEggAlert!.view.superview?.isUserInteractionEnabled = true
            self.easterEggAlert!.view.superview?.addGestureRecognizer(easterGestureRecognizer)
        })
    }
    
    func dismissEasterEgg() {
        easterEggAlert?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Developer toggle
    func setDevButton() {
        let btnSetting = self.createButtonWithIcon(UIImage(named: "ic_dev")!)
        
        btnSetting.addTarget(self, action: #selector(AboutViewController.developerMode), for: UIControlEvents.touchUpInside)
        
        self.navigationItem.rightBarButtonItem = btnSetting.toBarButton()
    }
    
    func developerMode() {
        let alertView = SCLAlertView(appearance: Constant.appearance)
        
        let lblNewShop = UILabel()
        
        lblNewShop.text = "Shop Baru?"
        lblNewShop.font = Constant.appearance.kTextFont
        lblNewShop.textColor = alertView.labelTitle.textColor
        lblNewShop.numberOfLines = 1
        lblNewShop.textAlignment = .left
        
        let width = Constant.appearance.kWindowWidth - 24
        
        let tglNewShop = UISwitch()
        
        tglNewShop.isOn = AppTools.isNewShop
        tglNewShop.addTarget(self, action: #selector(self.newShopToggle(sender:)), for: UIControlEvents.valueChanged)
        
        tglNewShop.frame = CGRect(x: width - tglNewShop.width, y: 0, width: tglNewShop.width, height: tglNewShop.height)
        
        lblNewShop.frame = CGRect(x: 0, y: 0, width: width - tglNewShop.width - 8, height: tglNewShop.height)
        
        let lblNewCart = UILabel()
        
        lblNewCart.text = "Cart V2?"
        lblNewCart.font = Constant.appearance.kTextFont
        lblNewCart.textColor = alertView.labelTitle.textColor
        lblNewCart.numberOfLines = 1
        lblNewCart.textAlignment = .left
        
        let tglNewCart = UISwitch()
        
        tglNewCart.isOn = AppTools.isNewCart
        tglNewCart.addTarget(self, action: #selector(self.newCartToggle(sender:)), for: UIControlEvents.valueChanged)
        
        tglNewCart.frame = CGRect(x: width - tglNewCart.width, y: tglNewShop.height + 8, width: tglNewCart.width, height: tglNewCart.height)
        
        lblNewCart.frame = CGRect(x: 0, y: tglNewShop.height + 8, width: width - tglNewCart.width - 8, height: tglNewCart.height)
        
        let lblSigCart = UILabel()
        
        lblSigCart.text = "Cart 1 page?"
        lblSigCart.font = Constant.appearance.kTextFont
        lblSigCart.textColor = alertView.labelTitle.textColor
        lblSigCart.numberOfLines = 1
        lblSigCart.textAlignment = .left
        
        let tglSigCart = UISwitch()
        
        tglSigCart.isOn = AppTools.isSingleCart
        tglSigCart.addTarget(self, action: #selector(self.sigCartToggle(sender:)), for: UIControlEvents.valueChanged)
        
        tglSigCart.frame = CGRect(x: width - tglSigCart.width, y: tglNewShop.height + 8 + tglNewCart.height + 8, width: tglSigCart.width, height: tglNewCart.height)
        
        lblSigCart.frame = CGRect(x: 0, y: tglNewShop.height + 8 + tglNewCart.height + 8, width: width - tglSigCart.width - 8, height: tglSigCart.height)
        
        let lblRent = UILabel()
        
        lblRent.text = "Add Product Rent?"
        lblRent.font = Constant.appearance.kTextFont
        lblRent.textColor = alertView.labelTitle.textColor
        lblRent.numberOfLines = 1
        lblRent.textAlignment = .left
        
        let tglRent = UISwitch()
        
        tglRent.isOn = AppTools.isRent
        tglRent.addTarget(self, action: #selector(self.rentToggle(sender:)), for: UIControlEvents.valueChanged)
        
        tglRent.frame = CGRect(x: width - tglRent.width, y: tglNewShop.height + 8 + tglNewCart.height + 8 + tglSigCart.height + 8, width: tglRent.width, height: tglRent.height)
        
        lblRent.frame = CGRect(x: 0, y: tglNewShop.height + 8 + tglNewCart.height + 8 + tglSigCart.height + 8, width: width - tglRent.width - 8, height: tglRent.height)
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0, y: 0, width: width, height: tglNewShop.height + 8 + tglNewCart.height + 8 + tglSigCart.height + 8 + tglRent.height))
        subview.addSubview(lblNewShop)
        subview.addSubview(tglNewShop)
        subview.addSubview(lblNewCart)
        subview.addSubview(tglNewCart)
        subview.addSubview(lblSigCart)
        subview.addSubview(tglSigCart)
        subview.addSubview(lblRent)
        subview.addSubview(tglRent)
        
        alertView.customSubview = subview
        
        alertView.addButton("Oke") {}
        
        alertView.showCustom("Developer Mode Tools", subTitle: "", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    func newShopToggle(sender: UISwitch) {
        AppTools.switchToNewShop(sender.isOn)
    }
    
    func newCartToggle(sender: UISwitch) {
        AppTools.switchToNewCart(sender.isOn)
    }
    
    func sigCartToggle(sender: UISwitch) {
        AppTools.switchToSingleCart(sender.isOn)
    }
    
    func rentToggle(sender: UISwitch) {
        AppTools.switchToRent(sender.isOn)
    }
}
