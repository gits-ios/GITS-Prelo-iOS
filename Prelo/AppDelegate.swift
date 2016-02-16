//
//  AppDelegate.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics
import TwitterKit
import Bolts
import FBSDKCoreKit

//import AdobeCreativeSDKCore

protocol LoadAppDataDelegate {
    func updateProgress(progress : Float)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static let StatusBarTapNotificationName = "statusbartapped"
    
    var messagePool : MessagePool!
    
    var preloNotifListener : PreloNotificationListener!
    
    var loadAppDataProgress : Float = 0
    var isLoadAppDataSuccess : Bool = true
    
    var loadAppDataDelegate : LoadAppDataDelegate?

    // MARK: - Application delegate functions
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        preloNotifListener = PreloNotificationListener()
        
        messagePool = MessagePool()
        messagePool.start()
        
        Fabric.with([Crashlytics.self(), Twitter.self()])
        
        if (AppTools.IsPreloProduction) {
            Mixpanel.sharedInstanceWithToken("1f07daa901e779dd504e21daca2a88df")
        } else {
            Mixpanel.sharedInstanceWithToken("5128cc503a07747a39945badf5aa4b3b")
        }
        
        
        if let c = CDUser.getOne()
        {
            Mixpanel.sharedInstance().identify(c.id)
            //Mixpanel.sharedInstance().people.set(["$first_name":c.fullname!, "$name":c.email, "user_id":c.id])
            
            // Set crashlytics user information
            Crashlytics.sharedInstance().setUserIdentifier((c.profiles.phone != nil) ? c.profiles.phone! : "undefined")
            Crashlytics.sharedInstance().setUserEmail(c.email)
            Crashlytics.sharedInstance().setUserName(c.fullname!)
        }/* else {
            Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
            Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
        }*/
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.SplashScreen)
        
        // Configure GAI options.
        var gai = GAI.sharedInstance()
        gai.trackerWithTrackingId("UA-68727101-3")
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.logger.logLevel = GAILogLevel.Verbose  // remove before app release
        
        // Google Analytics
        GAI.trackPageVisit(PageName.SplashScreen)
        
        /* AVIARY IS DISABLED
        AdobeUXAuthManager.sharedManager().setAuthenticationParametersWithClientID("79e1f842bbe948b49f7cce12d30d547e", clientSecret: "63bcf116-40d9-4a09-944b-af0401b1a350", enableSignUp: false)
        */
        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
//            
//        })
        
        self.versionCheck()
        
        // Enable Google AdWords automated usage reporting
        ACTAutomatedUsageTracker.enableAutomatedUsageReportingWithConversionID("953474992")
        ACTConversionReporter.reportWithConversionID("953474992", label: "sV6mCNOS0WIQsL_TxgM", value: "10000.00", isRepeatable: false)
        
        //return true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userLoggedIn", name: "userLoggedIn", object: nil)
        
        // Default deviceRegId so it's not nil
        NSUserDefaults.standardUserDefaults().setObject("", forKey: "deviceregid")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Register push notification
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1)
        {
            let setting = UIUserNotificationSettings(forTypes: (UIUserNotificationType.Badge|UIUserNotificationType.Sound|UIUserNotificationType.Alert), categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(setting)
        } else
        {
            let types = (UIRemoteNotificationType.Badge|UIRemoteNotificationType.Sound|UIRemoteNotificationType.Alert)
            UIApplication.sharedApplication().registerForRemoteNotificationTypes(types)
        }
        
        // Handling push notification
        if (launchOptions != nil) {
            if let remoteNotif = launchOptions![UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
                if let remoteNotifAps = remoteNotif["aps"] as? NSDictionary {
                    //Constant.showDialog("Push Notification", message: "remoteNotifAps = \(remoteNotifAps)")
                    let tipe : String? = remoteNotifAps["tipe"] as! String?
                    let targetId : String? = remoteNotifAps["target_id"] as! String?
                    //Constant.showDialog("tipe", message: "\(tipe)")
                    if (tipe?.lowercaseString == "notification") {
                        //self.redirectNotification() // Sementara pake NSUserDefaults dulu, karna dipanggil setelah selesai load notif, kalo notif udah pake paging baru pake ini
                        NSUserDefaults.standardUserDefaults().setObject("notification", forKey: "apnsredirect")
                        NSUserDefaults.standardUserDefaults().synchronize()
                    } else if (tipe?.lowercaseString == "inbox") {
                        self.redirectInbox(targetId)
                    }
                }
            }
        }
        
        // Handling facebook deferred deep linking
        // Kepanggil hanya jika app baru saja dibuka, jika dibuka ketika sedang dalam background mode maka tidak terpanggil
        if let launchURL = launchOptions?[UIApplicationLaunchOptionsURLKey] as? NSURL {
            //Constant.showDialog("Deeplink", message: "launchURL = \(launchURL)")
            if (launchURL.host == "product") {
                if let productId = launchURL.path?.substringFromIndex(1) {
                    self.redirectProduct(productId)
                }
            } else if (launchURL.host == "confirm") {
                if let confirmId = launchURL.path?.substringFromIndex(1) {
                    self.redirectConfirmPayment(confirmId)
                }
            } else if (launchURL.host == "user") {
                if let userId = launchURL.path?.substringFromIndex(1) {
                    self.redirectShopPage(userId)
                }
            } else if (launchURL.host == "inbox") {
                if let inboxId = launchURL.path?.substringFromIndex(1) {
                    self.redirectInbox(inboxId)
                }
            }

            FBSDKAppLinkUtility.fetchDeferredAppLink({(url : NSURL!, error : NSError!) -> Void in
                if (error != nil) { // Process error
                    println("Received error while fetching deferred app link \(error)")
                }
                if (url != nil) {
                    UIApplication.sharedApplication().openURL(url)
                }
            })
        }
        
        // Deeplink handling using Branch
        let branch : Branch = Branch.getInstance()
        branch.initSessionWithLaunchOptions(launchOptions, andRegisterDeepLinkHandler: { params, error in
            // Route the user based on what's in params
            let sessionParams = Branch.getInstance().getLatestReferringParams()
            let firstParams = Branch.getInstance().getFirstReferringParams()
            println("launch sessionParams = \(sessionParams)")
            println("launch firstParams = \(firstParams)")
            
            let params = JSON(sessionParams)
            let tipe : String? = params["tipe"].string
            let targetId : String? = params["target_id"].string
            if (tipe != nil && targetId != nil) {
                if (tipe! == "product") { // deeplinkProduct
                    self.redirectProduct(targetId!)
                } else if (tipe! == "user") { // deeplinkShopPage
                    self.redirectShopPage(targetId!)
                } else if (tipe! == "inbox") { // deeplinkInbox
                    self.redirectInbox(targetId!)
                } else if (tipe! == "confirm") { // deeplinkConfirmPayment
                    self.redirectConfirmPayment(targetId!)
                }
            }
        })
        
        // Set User-Agent for every HTTP request
        let webViewDummy = UIWebView()
        let userAgent = webViewDummy.stringByEvaluatingJavaScriptFromString("navigator.userAgent")
        NSUserDefaults.setObjectAndSync(userAgent, forKey: UserDefaultsKey.UserAgent)
        
        // Override point for customization after application launch
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject?) -> Bool {
            // Kepanggil hanya jika app dibuka ketika sedang dalam background mode, jika app baru saja dibuka maka tidak terpanggil
            //Constant.showDialog("Deeplink", message: "url = \(url)")
            
            if (!Branch.getInstance().handleDeepLink(url)) {
                // Handle deeplink from Facebook
                if (url.host == "product") {
                    if let productId = url.path?.substringFromIndex(1) {
                        self.redirectProduct(productId)
                    }
                } else if (url.host == "confirm") {
                    if let confirmId = url.path?.substringFromIndex(1) {
                        self.redirectConfirmPayment(confirmId)
                    }
                } else if (url.host == "user") {
                    if let userId = url.path?.substringFromIndex(1) {
                        self.redirectShopPage(userId)
                    }
                } else if (url.host == "inbox") {
                    if let inboxId = url.path?.substringFromIndex(1) {
                        self.redirectInbox(inboxId)
                    }
                }
                return FBSDKApplicationDelegate.sharedInstance().application(
                    application,
                    openURL: url,
                    sourceApplication: sourceApplication,
                    annotation: annotation)
            }
            
            return true
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]!) -> Void) -> Bool {
        // Pass the url to the handle deep link call
        Branch.getInstance().continueUserActivity(userActivity)
        
        return true
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        println("Action : \(identifier)")
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        println("deviceToken = \(deviceToken)")
        
        var characterSet: NSCharacterSet = NSCharacterSet(charactersInString: "<>")
        
        var deviceRegId: String = (deviceToken.description as NSString)
            .stringByTrimmingCharactersInSet(characterSet)
            .stringByReplacingOccurrencesOfString(" ", withString: "") as String
        
        println("deviceRegId = \(deviceRegId)")
        
        NSUserDefaults.standardUserDefaults().setObject(deviceRegId, forKey: "deviceregid")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Set deviceRegId for push notif if user is logged in
        if (User.IsLoggedIn) {
            LoginViewController.SendDeviceRegId(onFinish: nil)
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println("ERROR : \(error)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        println("userInfo = \(userInfo)")
        
        if (application.applicationState == UIApplicationState.Active) {
            println("App were active when receiving remote notification")
        } else {
            println("App weren't active when receiving remote notification")
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Redirect functions
    
    func redirectProduct(productId : String) {
        request(Products.Detail(productId: productId)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Deeplink Product")) {
                let json = JSON(res!)
                let data = json["_data"]
                let p = Product.instance(data)
                
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let productDetailVC = mainStoryboard.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                productDetailVC.product = p!
                let rootViewController = self.window!.rootViewController?.childViewControllers[0] as! UINavigationController
                rootViewController.pushViewController(productDetailVC, animated: true)
            }
        }
    }
    
    func redirectConfirmPayment(transactionId : String) {
        request(APITransaction2.TransactionDetail(tId: transactionId)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Deeplink Confirm Payment")) {
                let json = JSON(res!)
                let data = json["_data"]
                let progress = data["progress"].intValue
                if (progress == 2) { // Pembayaran pending
                    let paymentConfirmationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil).first as! PaymentConfirmationViewController
                    let rootViewController = self.window!.rootViewController?.childViewControllers[0] as! UINavigationController
                    rootViewController.pushViewController(paymentConfirmationVC, animated: true)
                    Constant.showDialog("", message: "Pembayaran sedang diproses Prelo, mohon ditunggu")
                } else {
                    let products = data["products"]
                    var imgs : [NSURL] = []
                    for (var i = 0; i < products.count; i++) {
                        if let c : UserCheckoutProduct = UserCheckoutProduct.instanceCheckoutProduct(products[i]) {
                            imgs.append(c.productImageURL!)
                        }
                    }
                    
                    let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let orderConfirmVC : OrderConfirmViewController = (mainStoryboard.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdOrderConfirm) as? OrderConfirmViewController)!
                    orderConfirmVC.transactionId = transactionId
                    orderConfirmVC.orderID = data["order_id"].stringValue
                    orderConfirmVC.total = data["total_price"].intValue
                    orderConfirmVC.images = imgs
                    orderConfirmVC.fromCheckout = false
                    let rootViewController = self.window!.rootViewController?.childViewControllers[0] as! UINavigationController
                    rootViewController.pushViewController(orderConfirmVC, animated: true)
                }
            }
        }
    }
    
    func redirectShopPage(userId : String) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let shopPage = mainStoryboard.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        shopPage.storeMode = true
        shopPage.storeId = userId
        let rootViewController = self.window!.rootViewController?.childViewControllers[0] as! UINavigationController
        rootViewController.pushViewController(shopPage, animated: true)
    }
    
    func redirectInbox(inboxId : String?) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController = self.window!.rootViewController?.childViewControllers[0] as! UINavigationController
        if (inboxId != nil) {
            request(APIInbox.GetInboxMessage(inboxId: inboxId!)).responseJSON { req, resp, res, err in
                if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Deeplink Inbox")) {
                    let json = JSON(res!)
                    let data = json["_data"]
                    let inbox = Inbox(jsn: data)
                    
                    let tawarVC = mainStoryboard.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdTawar) as! TawarViewController
                    tawarVC.tawarItem = inbox
                    rootViewController.pushViewController(tawarVC, animated: true)
                }
            }
        } else {
            let inboxVC = mainStoryboard.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdInbox) as! InboxViewController
            rootViewController.pushViewController(inboxVC, animated: true)
        }
    }
    
    func redirectNotification() {
        let notifPageVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameNotificationPageTabbed, owner: nil, options: nil).first as! NotificationPageTabbedViewController
        let rootViewController = self.window!.rootViewController?.childViewControllers[0] as! UINavigationController
        rootViewController.pushViewController(notifPageVC, animated: true)
    }
    
    // MARK: - Version check
    
    func versionCheck() {
        request(APIApp.Version(appType: "ios")).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Version Check")) {
                let json = JSON(res!)
                let data = json["_data"]
                // Jika versi metadata baru, load dan save kembali di coredata
                let ver : CDVersion? = CDVersion.getOne()
                var isUpdate : Bool = false
                var isUpdateVers : [String] = []
                if (ver?.brandsVersion == data["metadata_versions"]["brands"].number! && CDBrand.getBrandCount() > 0) {
                    isUpdateVers.append("0")
                } else {
                    isUpdateVers.append("1")
                    isUpdate = true
                }
                if (ver?.categoriesVersion == data["metadata_versions"]["categories"].number! && CDCategory.getCategoryCount() > 0) {
                    isUpdateVers.append("0")
                } else {
                    isUpdateVers.append("1")
                    isUpdate = true
                }
                if (ver?.categorySizesVersion == data["metadata_versions"]["category_sizes"].number! && CDCategorySize.getCategorySizeCount() > 0) {
                    isUpdateVers.append("0")
                } else {
                    isUpdateVers.append("1")
                    isUpdate = true
                }
                if (ver?.shippingsVersion == data["metadata_versions"]["shippings"].number! && CDShipping.getShippingCount() > 0) {
                    isUpdateVers.append("0")
                } else {
                    isUpdateVers.append("1")
                    isUpdate = true
                }
                if (ver?.productConditionsVersion == data["metadata_versions"]["product_conditions"].number! && CDProductCondition.getProductConditionCount() > 0) {
                    isUpdateVers.append("0")
                } else {
                    isUpdateVers.append("1")
                    isUpdate = true
                }
                if (ver?.provincesRegionsVersion == data["metadata_versions"]["provinces_regions"].number! && CDProvince.getProvinceCount() > 0) {
                    isUpdateVers.append("0")
                } else {
                    isUpdateVers.append("1")
                    isUpdate = true
                }
                
                // Update jika ada version yg berbeda
                if (isUpdate) {
                    // Set appdatasaved to false so the app is blocked at KumangTabBarVC
                    NSUserDefaults.setObjectAndSync(false, forKey: UserDefaultsKey.AppDataSaved)
                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                    
                    self.updateMetadata(isUpdateVers[0], updateCategories: isUpdateVers[1], updateCategorySizes: isUpdateVers[2], updateShippings: isUpdateVers[3], updateProductConditions: isUpdateVers[4], updateProvincesRegions: isUpdateVers[5])
                } else {
                    println("Same metadata version")
                    
                    // Set categorysaved to true so CategoryPreferencesVC can be executed
                    NSUserDefaults.standardUserDefaults().setObject(true, forKey: UserDefaultsKey.CategorySaved)
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    // Set appdatasaved to true so the app is not blocked
                    NSUserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.AppDataSaved)
                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                }
                
                CDVersion.saveVersions(data)
            }
        }
    }
    
    func updateMetadata(updateBrands : String, updateCategories : String, updateCategorySizes : String, updateShippings : String, updateProductConditions : String, updateProvincesRegions : String)
    {
        request(APIApp.Metadata(brands: updateBrands, categories: updateCategories, categorySizes: updateCategorySizes, shippings: updateShippings, productConditions: updateProductConditions, provincesRegions: updateProvincesRegions)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Metadata Update")) {
                let metaJson = JSON(res!)
                let metadata = metaJson["_data"]
                
                var progressPortionLeft : Float = 0.97
                let progressPortion : Float = 0.05
                
                var queue : NSOperationQueue = NSOperationQueue.new()
                
                let opFinish : NSOperation = NSBlockOperation(block: {
                    // Set appdatasaved to true so the app is no longer blocked
                    NSUserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.AppDataSaved)
                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                })
                
                var opCategories : NSOperation?
                
                if (updateCategories == "1") {
                    opCategories = NSBlockOperation(block: {
                        if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                            var moc = NSManagedObjectContext()
                            moc.persistentStoreCoordinator = psc
                            
                            // Update categories
                            println("Updating categories..")
                            if (CDCategory.deleteAll(moc)) {
                                if (CDCategory.saveCategories(metadata["categories"], m: moc)) {
                                    self.increaseLoadAppDataProgressBy(progressPortion)
                                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                                    progressPortionLeft -= progressPortion
                                } else {
                                    self.isLoadAppDataSuccess = false
                                }
                            }
                        }
                    })
                    queue.addOperation(opCategories!)
                    opFinish.addDependency(opCategories!)
                } else {
                    self.increaseLoadAppDataProgressBy(progressPortion)
                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                    progressPortionLeft -= progressPortion
                }
                
                if (updateCategorySizes == "1") {
                    let opCategorySizes : NSOperation = NSBlockOperation(block: {
                        if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                            var moc = NSManagedObjectContext()
                            moc.persistentStoreCoordinator = psc
                            
                            // Update category sizes
                            println("Updating category sizes..")
                            if (CDCategorySize.deleteAll(moc)) {
                                if (CDCategorySize.saveCategorySizes(metadata["category_sizes"], m: moc)) {
                                    // opCategorySizes dibuat menunggu opCategories beres, terus ngeset CategorySaved dilakukan di bloknya opCategorySizes.. kenapa? karena entah kenapa kalo CategorySaved  ditaro di bloknya opCategories, ada kejadian dimana CategorySaved udah true tapi belum kesave beneran di core data waktu diakses oleh CategoryPreferencesVC.. nah kalo ditaro di bloknya opCategorySizes yang nunggu opCategories, diharapkan udah kesave beneran
                                    // Set categorysaved to true so CategoryPreferencesVC can be executed
                                    NSUserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.CategorySaved)
                                    
                                    self.increaseLoadAppDataProgressBy(progressPortion)
                                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                                    progressPortionLeft -= progressPortion
                                } else {
                                    self.isLoadAppDataSuccess = false
                                }
                            }
                        }
                    })
                    queue.addOperation(opCategorySizes)
                    opFinish.addDependency(opCategorySizes)
                    if (opCategories != nil) {
                        opCategorySizes.addDependency(opCategories!)
                    }
                } else {
                    self.increaseLoadAppDataProgressBy(progressPortion)
                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                    progressPortionLeft -= progressPortion
                }
                
                if (updateShippings == "1") {
                    let opShippings : NSOperation = NSBlockOperation(block: {
                        if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                            var moc = NSManagedObjectContext()
                            moc.persistentStoreCoordinator = psc
                            
                            // Update shippings
                            println("Updating shippings..")
                            if (CDShipping.deleteAll(moc)) {
                                if (CDShipping.saveShippings(metadata["shippings"], m: moc)) {
                                    self.increaseLoadAppDataProgressBy(progressPortion)
                                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                                    progressPortionLeft -= progressPortion
                                } else {
                                    self.isLoadAppDataSuccess = false
                                }
                            }
                        }
                    })
                    queue.addOperation(opShippings)
                    opFinish.addDependency(opShippings)
                } else {
                    self.increaseLoadAppDataProgressBy(progressPortion)
                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                    progressPortionLeft -= progressPortion
                }
                
                if (updateProductConditions == "1") {
                    let opProductConditions : NSOperation = NSBlockOperation(block: {
                        if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                            var moc = NSManagedObjectContext()
                            moc.persistentStoreCoordinator = psc
                            
                            // Update product conditions
                            println("Updating product conditions..")
                            if (CDProductCondition.deleteAll(moc)) {
                                if (CDProductCondition.saveProductConditions(metadata["product_conditions"], m: moc)) {
                                    self.increaseLoadAppDataProgressBy(progressPortion)
                                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                                    progressPortionLeft -= progressPortion
                                } else {
                                    self.isLoadAppDataSuccess = false
                                }
                            }
                        }
                    })
                    queue.addOperation(opProductConditions)
                    opFinish.addDependency(opProductConditions)
                } else {
                    self.increaseLoadAppDataProgressBy(progressPortion)
                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                    progressPortionLeft -= progressPortion
                }
                
                if (updateProvincesRegions == "1") {
                    let opProvincesRegions : NSOperation = NSBlockOperation(block: {
                        if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                            var moc = NSManagedObjectContext()
                            moc.persistentStoreCoordinator = psc
                            
                            // Update provinces regions
                            println("Updating provinces regions..")
                            if (CDProvince.deleteAll(moc) && CDRegion.deleteAll(moc)) {
                                if (CDProvince.saveProvinceRegions(metadata["provinces_regions"], m: moc)) {
                                    self.increaseLoadAppDataProgressBy(progressPortion)
                                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                                    progressPortionLeft -= progressPortion
                                } else {
                                    self.isLoadAppDataSuccess = false
                                }
                            }
                        }
                    })
                    queue.addOperation(opProvincesRegions)
                    opFinish.addDependency(opProvincesRegions)
                } else {
                    self.increaseLoadAppDataProgressBy(progressPortion)
                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                    progressPortionLeft -= progressPortion
                }
                
                if (updateBrands == "1") {
                    let opBrands : NSOperation = NSBlockOperation(block: {
                        if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                            var moc = NSManagedObjectContext()
                            moc.persistentStoreCoordinator = psc
                            
                            // Update brands
                            println("Updating brands..")
                            if (CDBrand.deleteAll(moc)) {
                                if (CDBrand.saveBrands(metadata["brands"], m: moc, pView: nil, p : progressPortionLeft)) {
                                } else {
                                    self.isLoadAppDataSuccess = false
                                }
                            }
                        }
                    })
                    queue.addOperation(opBrands)
                    opFinish.addDependency(opBrands)
                } else {
                    self.increaseLoadAppDataProgressBy(progressPortionLeft)
                    self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
                }

                queue.addOperation(opFinish)
                
            } else {
                // Set appdatasaved to true so the app is no longer blocked
                NSUserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.AppDataSaved)
                self.loadAppDataDelegate?.updateProgress(self.loadAppDataProgress)
            }
        }
    }
    
    func increaseLoadAppDataProgressBy(progress: Float) {
        self.loadAppDataProgress += progress
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "id.gits.Prelo" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Prelo", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Prelo.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        let opt = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
        
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: opt, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
    // MARK: - User related delegate functions
    
    func userLoggedIn()
    {
        messagePool.start()
    }
    
    // MARK: - Other functions
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        let t : UITouch = event.allTouches()?.first as! UITouch
        let loc = t.locationInView(self.window)
        let f = UIApplication.sharedApplication().statusBarFrame
        let b = CGRectContainsPoint(f, loc)
        if (b) {
            NSNotificationCenter.defaultCenter().postNotificationName(AppDelegate.StatusBarTapNotificationName, object: nil)
        }
    }
}
