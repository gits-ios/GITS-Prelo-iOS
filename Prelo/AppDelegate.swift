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
import Alamofire

//import AdobeCreativeSDKCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static let StatusBarTapNotificationName = "statusbartapped"
    
    var messagePool : MessagePool?
    
    var preloNotifListener : PreloNotificationListener!
    
    let RedirProduct = "product"
    let RedirComment = "comment"
    let RedirUser = "user"
    let RedirInbox = "inbox"
    let RedirNotif = "notification"
    let RedirConfirm = "confirm"
    let RedirTrxBuyer = "transaction_buyer"
    let RedirTrxSeller = "transaction_seller"
    let RedirTrxPBuyer = "transaction_product_buyer"
    let RedirTrxPSeller = "transaction_product_seller"
    let RedirCategory = "category"
    
    var redirAlert : UIAlertView?
    var RedirWaitAmount : Int = 10000000
    
    var produkUploader : ProdukUploader!
    
    static var Instance : AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    // Uninstall.io (disabled)
    /*// TODO: isi apptoken dan appsecret
    let UninstallIOAppToken = ""
    let UninstallIOAppSecret = ""*/

    // MARK: - Application delegate functions
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        produkUploader = ProdukUploader()
        
        preloNotifListener = PreloNotificationListener()
        
        messagePool = MessagePool()
        messagePool?.start()
        
        if (messagePool == nil)
        {
            let error = NSError(domain: "Failed to create MessagePool", code: 0, userInfo: nil)
            Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: nil)
        }
        
        Fabric.with([Crashlytics.self(), Twitter.self()])
        
        if (AppTools.IsPreloProduction) {
            Mixpanel.sharedInstance(withToken: "6503102e2f63cae565ac95dbe489c154")
        } else {
            Mixpanel.sharedInstance(withToken: "5128cc503a07747a39945badf5aa4b3b")
        }
        
        if (User.IsLoggedIn) {
            if let c = CDUser.getOne()
            {
                Mixpanel.sharedInstance().identify(c.id)
                //Mixpanel.sharedInstance().people.set(["$first_name":c.fullname!, "$name":c.email, "user_id":c.id])
                
                // Set crashlytics user information
                Crashlytics.sharedInstance().setUserIdentifier((c.profiles.phone != nil) ? c.profiles.phone! : "undefined")
                Crashlytics.sharedInstance().setUserEmail(c.email)
                Crashlytics.sharedInstance().setUserName(c.fullname)
                
                // MoEngage
                MoEngage.sharedInstance().setUserAttribute(c.id, forKey: "user_id")
                MoEngage.sharedInstance().setUserAttribute(c.username, forKey: "username")
                MoEngage.sharedInstance().setUserAttribute(c.fullname, forKey: "user_fullname")
                MoEngage.sharedInstance().setUserAttribute(c.email, forKey: "user_email")
                MoEngage.sharedInstance().setUserAttribute((c.profiles.phone != nil) ? c.profiles.phone! : "undefined", forKey: "phone")
            }/* else {
                Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
            }*/
            
            // Send uuid to server
            let _ = request(APIMe.setUserUUID)
        }
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.SplashScreen)
        
        // Configure GAI options.
        let gai = GAI.sharedInstance()
        gai?.tracker(withTrackingId: "UA-68727101-3")
        gai?.trackUncaughtExceptions = true  // report uncaught exceptions
        gai?.logger.logLevel = GAILogLevel.verbose  // remove before app release
        gai?.defaultTracker.allowIDFACollection = true // Enable IDFA collection
        
        // Google Analytics
        GAI.trackPageVisit(PageName.SplashScreen)
        
        /* AVIARY IS DISABLED
        AdobeUXAuthManager.sharedManager().setAuthenticationParametersWithClientID("79e1f842bbe948b49f7cce12d30d547e", clientSecret: "63bcf116-40d9-4a09-944b-af0401b1a350", enableSignUp: false)
        */
        
        // Enable Google AdWords automated usage reporting
        ACTAutomatedUsageTracker.enableAutomatedUsageReporting(withConversionID: "953474992")
        ACTConversionReporter.report(withConversionID: "953474992", label: "sV6mCNOS0WIQsL_TxgM", value: "10000.00", isRepeatable: false)
        
        // AppsFlyer Tracker
        AppsFlyerTracker.shared().appsFlyerDevKey = "JdjGSJmNJwd46zDPxZf9J"
        AppsFlyerTracker.shared().appleAppID = "1027248488"
        
        // MoEngage
        MoEngage.sharedInstance().initialize(withApiKey: "N4VL0T0CGHRODQUOGRKZVWFH", in: application, withLaunchOptions: launchOptions)
        
        // Uninstall.io (disabled)
        /*NotifyManager.sharedManager().processLaunchOptions(launchOptions)
        NotifyManager.sharedManager().startNotifyServicesWithAppID(UninstallIOAppToken, key: UninstallIOAppSecret)
        var isUninstallIOIdentified = true
        if let io = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.UninstallIOIdentified) as? Bool {
            if (io == false) {
                isUninstallIOIdentified = false
            }
        } else {
            isUninstallIOIdentified = false
        }
        if (!isUninstallIOIdentified) {
            if (User.IsLoggedIn) {
                if let u = CDUser.getOne() {
                    let p = [
                        "username" : u.username,
                        "fullname" : (u.fullname != nil) ? u.fullname! : "",
                        "email" : u.email,
                        "phone" : (u.profiles.phone != nil) ? u.profiles.phone! : ""
                    ]
                    NotifyManager.sharedManager().identify(u.id, traits: p)
                    NSUserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.UninstallIOIdentified)
                }
            }
        }*/
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.userLoggedIn), name: NSNotification.Name(rawValue: "userLoggedIn"), object: nil)
        
        // Default deviceRegId so it's not nil
        UserDefaults.standard.set("", forKey: "deviceregid")
        UserDefaults.standard.synchronize()
        
        // Register push notification
        let settings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        UIApplication.shared.registerForRemoteNotifications()
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // Handling push notification from APNS
        // Kepanggil hanya jika app baru saja dibuka, jika dibuka ketika sedang dalam background mode maka tidak terpanggil
        if (launchOptions != nil) {
            if let remoteNotif = launchOptions![UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary {
                if let remoteNotifAps = remoteNotif["aps"] as? NSDictionary {
                    //Constant.showDialog("Push Notification", message: "remoteNotifAps = \(remoteNotifAps)")
                    if let tipe = remoteNotifAps.object(forKey: "tipe") as? String {
                        var targetId : String?
                        if let tId = remoteNotifAps.object(forKey: "target_id") as? String {
                            targetId = tId
                        }
                        self.deeplinkRedirect(tipe, targetId: targetId)
                    }
                }
            }
        }
        
        /**
         * HOTLINE
         * 1
         **/
        /*
        let config = HotlineConfig.init(appID: "aa37ac74-0ad1-4450-856e-136e59a810c9", andAppKey: "d66d7946-557f-44ef-96c1-9f27585a94fc")
        Hotline.sharedInstance().initWith(config)
        
        /* Enable remote notifications */
//        let settings = UIUserNotificationSettings(forTypes: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        UIApplication.shared.registerForRemoteNotifications()
        
        
        if Hotline.sharedInstance().isHotlineNotification(launchOptions){
            Hotline.sharedInstance().handleRemoteNotification(launchOptions, andAppstate: application.applicationState)
        }
        
        // re init for upgrade app version
        self.setupHotline()
         */
        
        // Handling facebook deferred deep linking
        // Kepanggil hanya jika app baru saja dibuka, jika dibuka ketika sedang dalam background mode maka tidak terpanggil
        if let launchURL = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL {
            if let tipe = launchURL.host {
                var targetId : String?
                targetId = launchURL.path.substringFromIndex(1)
                self.deeplinkRedirect(tipe, targetId: targetId)
            }

            // FIXME: Swift 3
//            FBSDKAppLinkUtility.fetchDeferredAppLink({(url : URL!, error : NSError!) -> Void in
//                if (error != nil) { // Process error
//                    print("Received error while fetching deferred app link \(error)")
//                }
//                if (url != nil) {
//                    UIApplication.shared.openURL(url)
//                }
//            })
        }
        
        // Deeplink handling using Branch
        let branch : Branch = Branch.getInstance()
        branch.accountForFacebookSDKPreventingAppLaunch()
        branch.initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: { params, error in
            // Route the user based on what's in params
            let sessionParams = Branch.getInstance().getLatestReferringParams()
            let firstParams = Branch.getInstance().getFirstReferringParams()
            print("launch sessionParams = \(sessionParams)")
            print("launch firstParams = \(firstParams)")
            
            let params = JSON(sessionParams)
            if let tipe = params["tipe"].string {
                var targetId : String?
                if let tId = params["target_id"].string {
                    targetId = tId
                }
                self.deeplinkRedirect(tipe, targetId: targetId)
            }
        })
        
        // Deeplink handling for universal link
        if let activityDict = launchOptions?[UIApplicationLaunchOptionsKey.userActivityDictionary] as? [AnyHashable: Any], let activity = activityDict["UIApplicationLaunchOptionsUserActivityKey"] as? NSUserActivity {
            if (activity.activityType == NSUserActivityTypeBrowsingWeb) {
                if let url = activity.webpageURL, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                    var param : [URLQueryItem] = []
                    if let items = components.queryItems {
                        param = items
                    }
                    self.handleUniversalLink(url, path: components.path, param: param)
                }
            }
        }
        
        // Set User-Agent for every HTTP request
        let webViewDummy = UIWebView()
        let userAgent = webViewDummy.stringByEvaluatingJavaScript(from: "navigator.userAgent")
        UserDefaults.setObjectAndSync(userAgent as AnyObject?, forKey: UserDefaultsKey.UserAgent)
        
        // Remove app badge if any
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Set status bar color
        self.setStatusBarBackgroundColor(color: UIColor.clear)
        
        // Override point for customization after application launch
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(_ application: UIApplication,
        open url: URL,
        sourceApplication: String?,
        annotation: Any) -> Bool {
            // Kepanggil hanya jika app dibuka ketika sedang dalam background mode, jika app baru saja dibuka maka tidak terpanggil
            //Constant.showDialog("Deeplink", message: "url = \(url)")
            
            if (!Branch.getInstance().handleDeepLink(url)) {
                // Handle deeplink from Facebook
                if let tipe = url.host {
                    var targetId : String?
                    if (url.path.length > 1) {
                        targetId = url.path.substringFromIndex(1)
                    }
                    self.deeplinkRedirect(tipe, targetId: targetId)
                }
                
                return FBSDKApplicationDelegate.sharedInstance().application(
                    application,
                    open: url,
                    sourceApplication: sourceApplication,
                    annotation: annotation)
            }
            
            return true
    }
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return userActivityType == NSUserActivityTypeBrowsingWeb
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        
        if (userActivity.activityType == NSUserActivityTypeBrowsingWeb) {
            if let url = userActivity.webpageURL, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                var param : [URLQueryItem] = []
                if let items = components.queryItems {
                    param = items
                }
                self.handleUniversalLink(url, path: components.path, param: param)
                return true
            }
        }

        Branch.getInstance().continue(userActivity)
        
        return true
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
        
        // MoEngage
        MoEngage.sharedInstance().didRegister(for: notificationSettings)
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        print("Action : \(identifier)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("deviceToken = \(deviceToken)")
        
        // Mixpanel push notification setup
        Mixpanel.sharedInstance().people.addPushDeviceToken(deviceToken)
        
        // Appsflyer uninstall tracking
        AppsFlyerTracker.shared().registerUninstall(deviceToken)
        if (AppTools.isDev) {
            AppsFlyerTracker.shared().useUninstallSandbox = true
        }
        
        // Uninstall.io (disabled)
        //NotifyManager.sharedManager().registerForPushNotificationUsingDeviceToken(deviceToken)
        
        var deviceRegId : String = ""
        for i in 0..<deviceToken.count {
            deviceRegId += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
//        let deviceRegId = String(format: "%@", deviceToken as CVarArg)
//            .trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
//            .replacingOccurrences(of: " ", with: "")
        
        print("deviceRegId = \(deviceRegId)")
        
        UserDefaults.standard.set(deviceRegId, forKey: "deviceregid")
        UserDefaults.standard.synchronize()
        
        // Set deviceRegId for push notif if user is logged in
        if (User.IsLoggedIn) {
            LoginViewController.SendDeviceRegId()
        } else {
            // API Migrasi
            let _ = request(APIVisitors.updateVisitor(deviceRegId: deviceRegId)).responseJSON {resp in
                if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Update Visitor")) {
                    print("Visitor updated with deviceRegId: \(deviceRegId)")
                }
            }
        }
        
        /**
         * HOTLINE
         * 3
         **/
//        Hotline.sharedInstance().updateDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("ERROR : \(error)")
        
        // MoEngage
        MoEngage.sharedInstance().didFailToRegisterForPush()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("userInfo = \(userInfo)")
        
        // MoEngage
        MoEngage.sharedInstance().didReceieveNotificationinApplication(application, withInfo: userInfo)
        
        // Uninstall.io (disabled)
        //NotifyManager.sharedManager().processRemoteNotification(userInfo)
        
        if (application.applicationState == UIApplicationState.active) {
            print("App were active when receiving remote notification")
            
//            Constant.showDialog("APNS", message: userInfo.description)
            
            var title = ""
            var body = ""
            
            var tipe = ""
            var targetId = ""
            
            if let remoteNotifAps = userInfo["aps"] as? NSDictionary {
                if let remoteNotifAlert = remoteNotifAps["alert"] as? NSDictionary {
                    if let _title = remoteNotifAlert.object(forKey: "title") as? String {
                        title = _title
                    }
                    if let _body = remoteNotifAlert.object(forKey: "body") as? String {
                        body = _body
                    }
                }
            }
            
            // deeplink
            if let t = userInfo["tipe"] as? String {
                tipe = t
            }
            if let tId = userInfo["target_id"] as? String {
                targetId = tId
            }
            
            // banner
            let banner = Banner(title: title, subtitle: body, image: nil, backgroundColor: Theme.PrimaryColor, didTapBlock: {
//                Constant.showDialog("APNS", message: "coba")
                self.deeplinkRedirect(tipe, targetId: targetId)
            })
            
            banner.dismissesOnTap = true
            
            banner.show(duration: 3.0)
        } else {
            print("App weren't active when receiving remote notification")
        }
        
        /**
         * HOTLINE
         * 4
         **/
        /*
        if Hotline.sharedInstance().isHotlineNotification(userInfo){
            Hotline.sharedInstance().handleRemoteNotification(userInfo, andAppstate: application.applicationState)
        }
         */
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        // MoEngage
        MoEngage.sharedInstance().stop(application)
        
//        produkUploader.stop()
        
        // Uninstall.io (disabled)
        //NotifyManager.sharedManager().didLoseFocus()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        // Uninstall.io (disabled)
        //NotifyManager.sharedManager().startNotifyServicesWithAppID(UninstallIOAppToken, key: UninstallIOAppSecret)
        
//        produkUploader.start()
        
        // init hotline for chat
        // re init for upgrade app version
//        self.setupHotline()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        
        // Remove app badge if any
        // show badge
        UIApplication.shared.applicationIconBadgeNumber = User.getNotifCount() as NSInteger
        
        // AppsFlyer
        // Track Installs, updates & sessions(app opens) (You must include this API to enable tracking)
        AppsFlyerTracker.shared().trackAppLaunch()
        
        // MoEngage
        MoEngage.sharedInstance().applicationBecameActiveinApplication(application)
        
        /**
         * HOTLINE
         * 2
         **/
        /*
        let unreadCount : NSInteger = Hotline.sharedInstance().unreadCount()
        UIApplication.shared.applicationIconBadgeNumber = (User.getNotifCount() as NSInteger + unreadCount)
        */
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        
        // MoEngage
        MoEngage.sharedInstance().applicationTerminated(application)
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Uninstall.io (disabled)
        //NotifyManager.sharedManager().startNotifyServicesWithAppID(UninstallIOAppToken, key: UninstallIOAppSecret)
    }
    
    // MARK: - Redirection functions
    
    func handleUniversalLink(_ url : URL, path : String, param : [URLQueryItem]) {
        self.showRedirAlert()
        if (path.contains("/p/")) {
            let splittedPath = path.characters.split{$0 == "/"}.map(String.init)
            if (splittedPath.count > 1) {
                let permalink = splittedPath[1].replacingOccurrences(of: ".html", with: "")
                let _ = request(APIProduct.getIdByPermalink(permalink: permalink)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Produk")) {
                        let json = JSON(resp.result.value!)
                        let pId = json["_data"].stringValue
                        if (pId != "") {
                            self.redirectProduct(pId)
                        } else {
                            self.showFailedRedirAlert()
                        }
                    } else {
                        self.showFailedRedirAlert()
                    }
                }
            } else {
                self.showFailedRedirAlert()
            }
        } else if (path.contains("/reminder-ketersediaan-barang") || path.contains("/barang-expiring")) {
            /* GET PARAM EXAMPLE
            var token = ""
            if (param.count > 0) {
                for i in 0...param.count - 1 {
                    if (param[i].name.lowercaseString == "token") {
                        if let v = param[i].value {
                            token = v
                        }
                    }
                }
            }*/
            self.redirectExpiringProducts()
        } else if (path.contains("/c/") || path.contains("/bekas/")) {
            let splittedPath = path.characters.split{$0 == "/"}.map(String.init)
            if (splittedPath.count > 1) {
                let permalink = splittedPath[1].replacingOccurrences(of: ".html", with: "")
                let _ = request(APIReference.getCategoryByPermalink(permalink: permalink)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Get Category ID")) {
                        let json = JSON(resp.result.value!)
                        let cId = json["_data"].stringValue
                        if (cId != "") {
                            self.redirectCategory(cId)
                        } else {
                            self.showFailedRedirAlert()
                        }
                    } else {
                        self.showFailedRedirAlert()
                    }
                }
            } else {
                self.showFailedRedirAlert()
            }
        } else if (path.contains("/checkout")) {
            self.redirectCart()
        } else {
            self.hideRedirAlertWithDelay(1.0)
            // Choose one method
            UIApplication.shared.openURL(url) // Open in safari
            //self.redirectWebview(url.absoluteString) // Open in prelo's webview
        }
    }
    
    func deeplinkRedirect(_ tipe : String, targetId : String?) {
        //Constant.showDialog("tipe", message: "\(tipe)")
        let tipeLowercase = tipe.lowercased()
        if (tipeLowercase == self.RedirProduct) {
            if (targetId != nil && targetId! != "") {
                self.showRedirAlert()
                self.redirectProduct(targetId!)
            }
        } else if (tipeLowercase == self.RedirComment) {
            if (User.IsLoggedIn && targetId != nil && targetId! != "") {
                self.showRedirAlert()
                self.redirectComment(targetId!)
            }
        } else if (tipeLowercase == self.RedirUser) {
            if (targetId != nil && targetId! != "") {
                self.showRedirAlert()
                self.redirectShopPage(targetId!)
            }
        } else if (tipeLowercase == self.RedirInbox) {
            if (User.IsLoggedIn && targetId != nil && targetId! != "") {
                self.showRedirAlert()
                self.redirectInbox(targetId)
            }
        } else if (tipeLowercase == self.RedirNotif) {
            if (User.IsLoggedIn) {
                self.showRedirAlert()
                self.redirectNotification()
            }
        } else if (tipeLowercase == self.RedirConfirm) {
            if (User.IsLoggedIn && targetId != nil && targetId! != "") {
                self.showRedirAlert()
                self.redirectConfirmPayment(targetId!)
            }
        } else if (tipeLowercase == self.RedirTrxBuyer) {
            if (User.IsLoggedIn && targetId != nil && targetId! != "") {
                self.showRedirAlert()
                self.redirectTransaction(targetId!, trxProductId: nil, isSeller: false)
            }
        } else if (tipeLowercase == self.RedirTrxSeller) {
            if (User.IsLoggedIn && targetId != nil && targetId! != "") {
                self.showRedirAlert()
                self.redirectTransaction(targetId!, trxProductId: nil, isSeller: true)
            }
        } else if (tipeLowercase == self.RedirTrxPBuyer) {
            if (User.IsLoggedIn && targetId != nil && targetId! != "") {
                self.showRedirAlert()
                self.redirectTransaction(nil, trxProductId: targetId!, isSeller: false)
            }
        } else if (tipeLowercase == self.RedirTrxPSeller) {
            if (User.IsLoggedIn && targetId != nil && targetId! != "") {
                self.showRedirAlert()
                self.redirectTransaction(nil, trxProductId: targetId!, isSeller: true)
            }
        } else if (tipeLowercase == self.RedirCategory) {
            if (targetId != nil && targetId != "") {
                self.showRedirAlert()
                self.redirectCategory(targetId!)
            }
        }
    }
    
    func showRedirAlert() {
        redirAlert = UIAlertView()
        redirAlert!.title = "Redirecting..."
        redirAlert!.message = "Harap tunggu beberapa saat"
        redirAlert!.show()
    }
    
    func hideRedirAlertWithDelay(_ delay: Double) {
        let delayTime = delay * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delayTime)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            self.redirAlert?.dismiss(withClickedButtonIndex: -1, animated: true)
        })
    }
    
    func showFailedRedirAlert() {
        redirAlert?.title = "Redirection Failed"
        redirAlert?.message = "Terdapat kesalahan saat memproses data"
        self.hideRedirAlertWithDelay(3.0)
    }
    
    func redirectProduct(_ productId : String) {
        let _ = request(APIProduct.detail(productId: productId, forEdit: 0)).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Deeplink Product")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                let p = Product.instance(data)
                
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                var rootViewController : UINavigationController?
                
                // Tunggu sampai UINavigationController terbentuk
                var wait = true
                var waitCount = self.RedirWaitAmount
                while (wait) {
                    if let childVCs = self.window!.rootViewController?.childViewControllers {
                        if (childVCs.count > 0) {
                            if let rootVC = childVCs[0] as? UINavigationController {
                                rootViewController = rootVC
                            }
                            wait = false
                        }
                    }
                    waitCount -= 1
                    if (waitCount <= 0) { // Jaga2 jika terlalu lama menunggu
                        wait = false
                    }
                }
                
                // Redirect setelah selesai menunggu
                if (rootViewController != nil) {
                    let productDetailVC = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                    productDetailVC.product = p!
                    rootViewController!.pushViewController(productDetailVC, animated: true)
                } else {
                    self.showFailedRedirAlert()
                }
            } else {
                self.showFailedRedirAlert()
            }
        }
    }
    
    func redirectComment(_ productId : String) {
        let _ = request(APIProduct.detail(productId: productId, forEdit: 0)).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Deeplink Product Comment")) {
                let json = JSON(resp.result.value!)
                let pDetail = ProductDetail.instance(json)
                
                var rootViewController : UINavigationController?
                
                // Tunggu sampai UINavigationController terbentuk
                var wait = true
                var waitCount = self.RedirWaitAmount
                while (wait) {
                    if let childVCs = self.window!.rootViewController?.childViewControllers {
                        if (childVCs.count > 0) {
                            if let rootVC = childVCs[0] as? UINavigationController {
                                rootViewController = rootVC
                            }
                            wait = false
                        }
                    }
                    waitCount -= 1
                    if (waitCount <= 0) { // Jaga2 jika terlalu lama menunggu
                        wait = false
                    }
                }
                
                // Redirect setelah selesai menunggu
                if (rootViewController != nil) {
                    let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdProductComments) as! ProductCommentsController
                    p.pDetail = pDetail
                    rootViewController!.pushViewController(p, animated: true)
                } else {
                    self.showFailedRedirAlert()
                }
            } else {
                self.showFailedRedirAlert()
            }
        }
    }
    
    func redirectShopPage(_ userId : String) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let listItemVC = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        listItemVC.currentMode = .shop
        listItemVC.shopId = userId

        var rootViewController : UINavigationController?
        if let rVC = self.window?.rootViewController {
            if (rVC.childViewControllers.count > 0) {
                if let chld = rVC.childViewControllers[0] as? UINavigationController {
                    rootViewController = chld
                }
            }
        }
        if (rootViewController == nil) {
            // Set root view controller
            rootViewController = UINavigationController()
            rootViewController?.navigationBar.barTintColor = Theme.PrimaryColor
            rootViewController?.navigationBar.tintColor = UIColor.white
            rootViewController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
            self.window?.rootViewController = rootViewController
            let noBtn = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            listItemVC.navigationItem.leftBarButtonItem = noBtn
        }
        rootViewController!.pushViewController(listItemVC, animated: true)
    }
    
    func redirectInbox(_ inboxId : String?) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var rootViewController : UINavigationController?
        
        // Tunggu sampai UINavigationController terbentuk
        var wait = true
        var waitCount = self.RedirWaitAmount
        while (wait) {
            if let childVCs = self.window!.rootViewController?.childViewControllers {
                if (childVCs.count > 0) {
                    if let rootVC = childVCs[0] as? UINavigationController {
                        rootViewController = rootVC
                    }
                    wait = false
                }
            }
            waitCount -= 1
            if (waitCount <= 0) { // Jaga2 jika terlalu lama menunggu
                wait = false
            }
        }
        
        // Redirect setelah selesai menunggu
        if (rootViewController != nil) {
            // API Migrasi
            let _ = request(APIInbox.getInboxMessage(inboxId: inboxId!)).responseJSON {resp in
                if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Deeplink Inbox")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    let inbox = Inbox(jsn: data)
                    
                    let tawarVC = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdTawar) as! TawarViewController
                    tawarVC.tawarItem = inbox
                    rootViewController!.pushViewController(tawarVC, animated: true)
                } else {
                    self.showFailedRedirAlert()
                }
            }
        } else {
            self.showFailedRedirAlert()
        }
    }
    
    func redirectNotification() {
        // Tunggu sampai UINavigationController terbentuk
        var rootViewController : UINavigationController?
        
        var wait = true
        var waitCount = self.RedirWaitAmount
        while (wait) {
            if let childVCs = self.window!.rootViewController?.childViewControllers {
                if (childVCs.count > 0) {
                    if let rootVC = childVCs[0] as? UINavigationController {
                        rootViewController = rootVC
                    }
                    wait = false
                }
            }
            waitCount -= 1
            if (waitCount <= 0) { // Jaga2 jika terlalu lama menunggu
                wait = false
            }
        }
        
        // Redirect setelah selesai menunggu
        if (rootViewController != nil) {
            let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
            rootViewController!.pushViewController(notifPageVC, animated: true)
        } else {
            self.showFailedRedirAlert()
        }
    }
    
    func redirectConfirmPayment(_ transactionId : String) {
        if (transactionId != "") {
            // API Migrasi
            let _ = request(APITransaction.transactionDetail(tId: transactionId)).responseJSON {resp in
                if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Deeplink Confirm Payment")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    let progress = data["progress"].intValue
                    
                    var rootViewController : UINavigationController?
                    
                    // Tunggu sampai UINavigationController terbentuk
                    var wait = true
                    var waitCount = self.RedirWaitAmount
                    while (wait) {
                        if let childVCs = self.window!.rootViewController?.childViewControllers {
                            if (childVCs.count > 0) {
                                if let rootVC = childVCs[0] as? UINavigationController {
                                    rootViewController = rootVC
                                }
                                wait = false
                            }
                        }
                        waitCount -= 1
                        if (waitCount <= 0) { // Jaga2 jika terlalu lama menunggu
                            wait = false
                        }
                    }
                    
                    // Redirect setelah selesai menunggu
                    if (rootViewController != nil) {
                        if (progress != 1) { // Sudah pernah melakukan konfirmasi bayar
                            self.redirAlert?.title = "Perhatian"
                            self.redirAlert?.message = "Anda sudah melakukan konfirmasi bayar untuk transaksi ini"
                            self.hideRedirAlertWithDelay(3.0)
                        } else {
                            let products = data["products"]
                            var imgs : [URL] = []
                            for i in 0 ..< products.count {
                                if let c : UserCheckoutProduct = UserCheckoutProduct.instanceCheckoutProduct(products[i]) {
                                    imgs.append(c.productImageURL!)
                                }
                            }
                            
                            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            let orderConfirmVC : OrderConfirmViewController = (mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdOrderConfirm) as? OrderConfirmViewController)!
                            orderConfirmVC.transactionId = transactionId
                            orderConfirmVC.orderID = data["order_id"].stringValue
                            orderConfirmVC.total = data["total_price"].intValue
                            orderConfirmVC.images = imgs
                            orderConfirmVC.isFromCheckout = false
                            rootViewController!.pushViewController(orderConfirmVC, animated: true)
                        }
                    } else {
                        self.showFailedRedirAlert()
                    }
                } else {
                    self.showFailedRedirAlert()
                }
            }
        }
    }
    
    func redirectTransaction(_ trxId : String?, trxProductId : String?, isSeller : Bool) {
        // Tunggu sampai UINavigationController terbentuk
        var rootViewController : UINavigationController?
        
        var wait = true
        var waitCount = self.RedirWaitAmount
        while (wait) {
            if let childVCs = self.window!.rootViewController?.childViewControllers {
                if (childVCs.count > 0) {
                    if let rootVC = childVCs[0] as? UINavigationController {
                        rootViewController = rootVC
                    }
                    wait = false
                }
            }
            waitCount -= 1
            if (waitCount <= 0) { // Jaga2 jika terlalu lama menunggu
                wait = false
            }
        }
        
        // Redirect setelah selesai menunggu
        if (rootViewController != nil) {
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let transactionDetailVC : TransactionDetailViewController = (mainStoryboard.instantiateViewController(withIdentifier: "TransactionDetail") as? TransactionDetailViewController)!
            transactionDetailVC.trxId = trxId
            transactionDetailVC.trxProductId = trxProductId
            transactionDetailVC.isSeller = isSeller
            rootViewController!.pushViewController(transactionDetailVC, animated: true)
        } else {
            self.showFailedRedirAlert()
        }
    }
    
    func redirectExpiringProducts() {
        let expProductsVC = Bundle.main.loadNibNamed(Tags.XibNameExpiringProducts, owner: nil, options: nil)?.first as! ExpiringProductsViewController
        
        var rootViewController : UINavigationController?
        if let rVC = self.window?.rootViewController {
            if (rVC.childViewControllers.count > 0) {
                if let chld = rVC.childViewControllers[0] as? UINavigationController {
                    rootViewController = chld
                }
            }
        }
        if (rootViewController == nil) {
            // Set root view controller
            rootViewController = UINavigationController()
            rootViewController?.navigationBar.barTintColor = Theme.PrimaryColor
            rootViewController?.navigationBar.tintColor = UIColor.white
            rootViewController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
            self.window?.rootViewController = rootViewController
            let noBtn = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            expProductsVC.navigationItem.leftBarButtonItem = noBtn
        }
        rootViewController!.pushViewController(expProductsVC, animated: true)
    }
    
    func redirectCategory(_ categoryId : String) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let listItemVC = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        listItemVC.currentMode = .filter
        listItemVC.fltrCategId = categoryId
        listItemVC.fltrSortBy = "recent"
        
        var rootViewController : UINavigationController?
        if let rVC = self.window?.rootViewController {
            if (rVC.childViewControllers.count > 0) {
                if let chld = rVC.childViewControllers[0] as? UINavigationController {
                    rootViewController = chld
                }
            }
        }
        if (rootViewController == nil) {
            // Set root view controller
            rootViewController = UINavigationController()
            rootViewController?.navigationBar.barTintColor = Theme.PrimaryColor
            rootViewController?.navigationBar.tintColor = UIColor.white
            rootViewController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
            self.window?.rootViewController = rootViewController
            let noBtn = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            listItemVC.navigationItem.leftBarButtonItem = noBtn
        }
        rootViewController!.pushViewController(listItemVC, animated: true)
    }
    
    func redirectWebview(_ url : String) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let webVC = mainStoryboard.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
        webVC.url = url
        webVC.titleString = "Prelo"
        var rootViewController : UINavigationController?
        if let rVC = self.window?.rootViewController {
            if (rVC.childViewControllers.count > 0) {
                if let chld = rVC.childViewControllers[0] as? UINavigationController {
                    rootViewController = chld
                }
            }
        }
        if (rootViewController == nil) {
            // Set root view controller
            rootViewController = UINavigationController()
            rootViewController?.navigationBar.barTintColor = Theme.PrimaryColor
            rootViewController?.navigationBar.tintColor = UIColor.white
            rootViewController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
            self.window?.rootViewController = rootViewController
            let noBtn = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            webVC.navigationItem.leftBarButtonItem = noBtn
        }
        rootViewController!.pushViewController(webVC, animated: true)
    }
    
    func redirectCart() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let cartVC = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdCart) as! CartViewController
        
        var rootViewController : UINavigationController?
        if let rVC = self.window?.rootViewController {
            if (rVC.childViewControllers.count > 0) {
                if let chld = rVC.childViewControllers[0] as? UINavigationController {
                    rootViewController = chld
                }
            }
        }
        if (rootViewController == nil) {
            // Set root view controller
            rootViewController = UINavigationController()
            rootViewController?.navigationBar.barTintColor = Theme.PrimaryColor
            rootViewController?.navigationBar.tintColor = UIColor.white
            rootViewController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
            self.window?.rootViewController = rootViewController
       }
        rootViewController!.pushViewController(cartVC, animated: true)
    }
    
    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "id.gits.Prelo" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as URL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Prelo", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        
        // migration
        let option = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: option)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()


    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    // MARK: - User related delegate functions
    
    func userLoggedIn()
    {
        messagePool?.start()
    }
    
    // MARK: - Other functions
    
    func setStatusBarBackgroundColor(color: UIColor) {
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        statusBar.backgroundColor = color
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let t = event?.allTouches?.first
        {
            let loc = t.location(in: self.window)
            let f = UIApplication.shared.statusBarFrame
            let b = f.contains(loc)
            if (b) {
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: AppDelegate.StatusBarTapNotificationName), object: nil)
            }
        }
    }
    
//    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent?) {
//        super.touchesBegan(touches, withEvent: event)
//        
//    }
    
    // MARK: - orintation screen
    
    var orientations:UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
    
    func application(_ application: UIApplication, didChangeStatusBarOrientation oldStatusBarOrientation: UIInterfaceOrientation) {
        adjustViewsForOrientation(orientation: UIApplication.shared.statusBarOrientation)
    }
    
    func adjustViewsForOrientation(orientation: UIInterfaceOrientation) {
        if (orientation == UIInterfaceOrientation.portrait || orientation == UIInterfaceOrientation.portraitUpsideDown)
        {
            if(orientation != orientations) {
                print("Portrait")
                
                
                //Do Rotation stuff here
                orientations = orientation
            }
        }
        else if (orientation == UIInterfaceOrientation.landscapeLeft || orientation == UIInterfaceOrientation.landscapeRight)
        {
            if(orientation != orientations) {
                print("Landscape")
                
                Constant.showDialog("Device Orientation", message: "Halo Prelovers, Prelo menyarankan untuk menggunakan aplikasi Prelo dengan orientasi portrait atau tegak")
                
                //Do Rotation stuff here
                orientations = orientation
            }
        }
    }
    
    // MARK: - Hotline
    func setupHotline() {
        /*
         * Following three methods are to identify a user.
         * These user properties will be viewable on the Hotline web dashboard.
         * The externalID (identifier) set will also be used to identify the specific user for any APIs
         * targeting a user or list of users in pro-active messaging or marketing
         */
        
        // Create a user object
        let user = HotlineUser.sharedInstance();
        
        // To set an identifiable name for the user
//        user?.name = CDUser.getOne()?.fullname
        user?.name = CDUser.getOne()?.username
        
        //To set user's email id
        user?.email = CDUser.getOne()?.email
        
        //To set user's phone number
        //        user?.phoneCountryCode="62"; // indonesia
        user?.phoneNumber = CDUser.getOne()?.profiles.phone
        
        
        
        //To set user's identifier (external id to map the user to a user in your system. Setting an external ID is COMPULSARY for many of Hotline’s APIs
        user?.externalID = UIDevice.current.identifierForVendor!.uuidString
        
        
        // FINALLY, REMEMBER TO SEND THE USER INFORMATION SET TO HOTLINE SERVERS
        Hotline.sharedInstance().update(user)
        
        /* Custom properties & Segmentation - You can add any number of custom properties. An example is given below.
         These properties give context for your conversation with the user and also serve as segmentation criteria for your marketing messages
         */
        
        //        //You can set custom user properties for a particular user
        //        Hotline.sharedInstance().updateUserPropertyforKey("customerType", withValue: "Premium")
        
        let city = CDUser.getOne()?.profiles.subdistrictName
        
        //You can set user demographic information
        Hotline.sharedInstance().updateUserPropertyforKey("city", withValue: city)
        
        //You can segment based on where the user is in their journey of using your app
        Hotline.sharedInstance().updateUserPropertyforKey("loggedIn", withValue: User.IsLoggedIn.description)
        
        //        //You can capture a state of the user that includes what the user has done in your app
        //        Hotline.sharedInstance().updateUserPropertyforKey("transactionCount", withValue: "3")
        
        
        /* If you want to indicate to the user that he has unread messages in his inbox, you can retrieve the unread count to display. */
        //returns an int indicating the of number of unread messages for the user
//        Hotline.sharedInstance().unreadCount()
        
        
        //        /*
        //         Managing Badge number for unread messages - Manual
        //         */
        //        Hotline.sharedInstance().initWithConfig(config)
        //        print("Unread messages count \(Hotline.sharedInstance().unreadCount()) .")
        //
        //
        //        Hotline.sharedInstance().unreadCountWithCompletion { (count:Int) -> Void in
        //            print("Unread count (Async) :\(count)")
        //        }
        
    }
}
