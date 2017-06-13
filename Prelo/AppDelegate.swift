//
//  AppDelegate.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics
import TwitterKit
import Bolts
import FBSDKCoreKit
import Alamofire
import AVFoundation
import AlamofireImage

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
    let RedirLove = "lovers"
    let RedirAchievement = "achievement"
    let RedirReferral = "referral"
    let RedirPreloMessage = "prelo_message"
    
    var redirAlert : SCLAlertView?
    var alertViewResponder : SCLAlertViewResponder?
    var RedirWaitAmount : Int = 10000000
    
    var produkUploader : ProdukUploader!
    
    var isTakingScreenshot = false // for use when take screenshot (dialog show)
    
    static var Instance : AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    // Uninstall.io (disabled)
    /*// TODO: isi apptoken dan appsecret
    let UninstallIOAppToken = ""
    let UninstallIOAppSecret = ""*/

    // MARK: - Application delegate functions
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // alamofire-image fixer
        DataRequest.addAcceptableImageContentTypes(["image/jpg","binary/octet-stream"])
        
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
        _ = gai?.tracker(withTrackingId: "UA-68727101-3")
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
        
        if AppTools.isDev {
            AppsFlyerTracker.shared().isDebug = true
        }
        
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
                if let _tipe = remoteNotif.object(forKey: "tipe") as? String {
                    var tipe = _tipe
                    var targetId : String = ""
                    if let tId = remoteNotif.object(forKey: "target_id") as? String {
                        targetId = tId
                    }
                    if let _ = remoteNotif.object(forKey: "is_prelo_message") as? Bool {
                        tipe = self.RedirPreloMessage
                    }
                    //Constant.showDialog(tipe, message: targetId)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        self.deeplinkRedirect(tipe, targetId: targetId)
                    })
                    
                    // Prelo Analytic - Click Push Notification
                    if let _ = remoteNotif.object(forKey: "attachment-url") as? String {
                        sendPushNotifAnalytic(true, isBackgroundMode: true, targetId: targetId, tipe: tipe)
                    } else {
                        sendPushNotifAnalytic(false, isBackgroundMode: true, targetId: targetId, tipe: tipe)
                    }
                }
                
//                Constant.showDialog("APNS", message: remoteNotif.description )
            }
        }
        
        // Handling facebook deferred deep linking
        // Kepanggil hanya jika app baru saja dibuka, jika dibuka ketika sedang dalam background mode maka tidak terpanggil
        if let launchURL = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL {
            if let tipe = launchURL.host {
                var targetId : String?
                targetId = launchURL.path.substringFromIndex(1)
                
                let param : [URLQueryItem] = []
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    // prelo:// http:// https://
                    if (launchURL.absoluteString.contains("prelo://") || launchURL.absoluteString.contains("http://") || launchURL.absoluteString.contains("https://")) {
                        self.handleUniversalLink(launchURL.absoluteURL, path: launchURL.path, param: param)
                    } else {
                        // fb ?
                        self.deeplinkRedirect(tipe, targetId: targetId)
                    }
                })
            }

            // FIXME: Swift 3
//            FBSDKAppLinkUtility.fetchDeferredAppLink({(url : URL!, error : NSError!) -> Void in
//                if (error != nil) { // Process error
//                    //print("Received error while fetching deferred app link \(error)")
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
            //let firstParams = Branch.getInstance().getFirstReferringParams()
            //print("launch sessionParams = \(sessionParams)")
            //print("launch firstParams = \(firstParams)")
            
            let params = JSON((sessionParams ?? [:]))
            if let tipe = params["tipe"].string {
                var targetId : String?
                if let tId = params["target_id"].string {
                    targetId = tId
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.deeplinkRedirect(tipe, targetId: targetId)
                })
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        self.handleUniversalLink(url, path: components.path, param: param)
                    })
                }
            }
        }
        
        // Set User-Agent for every HTTP request
        let webViewDummy = UIWebView()
        let userAgent = webViewDummy.stringByEvaluatingJavaScript(from: "navigator.userAgent")
        UserDefaults.setObjectAndSync(userAgent as AnyObject?, forKey: UserDefaultsKey.UserAgent)
        
        // Remove app badge if any
        //UIApplication.shared.applicationIconBadgeNumber = 0
        
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
        
        // deeplinking prelo://
        if url.absoluteString.contains("prelo://"), let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            var param : [URLQueryItem] = []
            if let items = components.queryItems {
                param = items
            }
            if let del = UIApplication.shared.delegate as? AppDelegate {
                del.handleUniversalLink(url, path: components.path, param: param)
                
                return true
            }
            return false
            
        // deeplinking fb860723977338277:// (FACEBOOK)
        } else if url.absoluteString.contains("fb860723977338277://") {
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
        //print("Action : \(identifier)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //print("deviceToken = \(deviceToken)")
        
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
        
        //print("deviceRegId = \(deviceRegId)")
        
        UserDefaults.standard.set(deviceRegId, forKey: "deviceregid")
        UserDefaults.standard.synchronize()
        
        // Set deviceRegId for push notif if user is logged in
        if (User.IsLoggedIn) {
            LoginViewController.SendDeviceRegId()
        } else {
            // API Migrasi
            let _ = request(APIVisitors.updateVisitor(deviceRegId: deviceRegId)).responseJSON {resp in
                if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Update Visitor")) {
                    //print("Visitor updated with deviceRegId: \(deviceRegId)")
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        //print("ERROR : \(error)")
        
        // MoEngage
        MoEngage.sharedInstance().didFailToRegisterForPush()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        //print("userInfo = \(userInfo)")
        
        // MoEngage
        MoEngage.sharedInstance().didReceieveNotificationinApplication(application, withInfo: userInfo)
        
        // Uninstall.io (disabled)
        //NotifyManager.sharedManager().processRemoteNotification(userInfo)
        
        // APNS handle
        var title = ""
        var body = ""
        
        var alert = ""
        
        var tipe = ""
        var targetId = ""
        
        var imgUrl = ""
        
        if let remoteNotifAps = userInfo["aps"] as? NSDictionary {
            if let remoteNotifAlert = remoteNotifAps["alert"] as? NSDictionary {
                if let _title = remoteNotifAlert.object(forKey: "title") as? String {
                    title = _title
                }
                if let _body = remoteNotifAlert.object(forKey: "body") as? String {
                    body = _body
                }
            } else {
                if let remoteNotifAlert = remoteNotifAps["alert"] as? String {
                    alert = remoteNotifAlert
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
        
        if let _ = userInfo["is_prelo_message"] as? Bool {
            tipe = self.RedirPreloMessage
        }
        
        // image
        if let img = userInfo["attachment-url"] as? String {
            imgUrl = img
        }
        
        // check current view
        var isDoing = true
        var rootViewController : UINavigationController?
        if let childVCs = self.window!.rootViewController?.childViewControllers {
            if (childVCs.count > 0) {
                if let rootVC = childVCs[0] as? UINavigationController {
                    rootViewController = rootVC
                }
            }
        }
        
        if tipe.lowercased() == self.RedirInbox && rootViewController?.childViewControllers.last is TawarViewController {
            //do something if it's an instance of that class
            
            if let tawarVC = rootViewController?.childViewControllers.last as? TawarViewController {
                if tawarVC.tawarItem.threadId == targetId {
                    isDoing = false
                }
            }
        } else if tipe.lowercased() == self.RedirPreloMessage && rootViewController?.childViewControllers.last is PreloMessageViewController {
            //do something if it's an instance of that class
            
            isDoing = false
        }
        
        if (application.applicationState == UIApplicationState.active) { // active mode
            //print("App were active when receiving remote notification")
            
//            Constant.showDialog("APNS", message: userInfo.description)
            
            let tipeLowercase = tipe.lowercased()
            var imageName = "banner_"
            /*if (tipeLowercase == self.RedirProduct || tipeLowercase == self.RedirUser || tipeLowercase == self.RedirInbox || tipeLowercase == self.RedirNotif) {
                // notif
                imageName += "notif"
            } else*/ if (tipeLowercase == self.RedirComment) {
                // comment
                imageName += "comment"
            } else if (tipeLowercase == self.RedirConfirm || tipeLowercase == self.RedirTrxBuyer || tipeLowercase == self.RedirTrxSeller || tipeLowercase == self.RedirTrxPBuyer || tipeLowercase == self.RedirTrxPSeller) {
                // harga
                imageName += "harga"
            } else if (tipeLowercase == self.RedirCategory) {
                // exclamation
                imageName += "exclamation"
            } else if (tipeLowercase == self.RedirLove) {
                // love
                imageName += "love"
            } else if (tipeLowercase == self.RedirAchievement) {
                // achievement
                imageName += "achievement"
            } else {
                // notif
                imageName += "notif"
            }
            imageName += ".png"
            
            let imageBanner = UIImage(named: imageName)
            
            /*
            if imgUrl != "" {
                if let data = NSData(contentsOf: URL(string: imgUrl)!) {
                    if let imageUrl = UIImage(data: data as Data) {
                        
                        imageBanner = imageUrl
                    }
                }
            }
             */
            
            if ((title != "" || alert != "") && isDoing) {
                // banner
                let banner = Banner(title: title != "" ? title : alert, subtitle: body != "" ? body : nil, image: imageBanner, backgroundColor: Theme.PrimaryColor, didTapBlock: {
                    //if isDoing {
                        self.deeplinkRedirect(tipe, targetId: targetId)
                    //}
                    
                    // Prelo Analytic - Click Push Notification
                    if imgUrl != "" {
                        self.sendPushNotifAnalytic(true, isBackgroundMode: false, targetId: targetId, tipe: tipe)
                    } else {
                        self.sendPushNotifAnalytic(false, isBackgroundMode: false, targetId: targetId, tipe: tipe)
                    }
                })
                
                banner.dismissesOnTap = true
                
                AudioServicesPlaySystemSound(SystemSoundID(1000))
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
                banner.show(duration: 3.0)
            }
            
        } else { // background mode
            //print("App weren't active when receiving remote notification")
            
//            Constant.showDialog("APNS", message: userInfo.description)
            
            if isDoing {
                self.deeplinkRedirect(tipe, targetId: targetId)
            } else {
                // not tested
                if tipe.lowercased() == self.RedirInbox && rootViewController?.childViewControllers.last is TawarViewController {
                    //do something if it's an instance of that class
                    
                    if let tawarVC = rootViewController?.childViewControllers.last as? TawarViewController {
                        tawarVC.isScrollToBottom = true
                        tawarVC.getMessages()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            // decrease notif badge
                            let unreadNotifCount = self.preloNotifListener.newNotifCount - 1
                            self.preloNotifListener.setNewNotifCount(unreadNotifCount)
                        })
                    }
                } else if tipe.lowercased() == self.RedirPreloMessage && rootViewController?.childViewControllers.last is PreloMessageViewController {
                    //do something if it's an instance of that class
                    
                    if let preloMessageVC = rootViewController?.childViewControllers.last as? PreloMessageViewController {
                        preloMessageVC.getMessage()
                        
                        // decrease notif badge
                        // handled at prelo message vc
                    }
                }
            }
            
            // Prelo Analytic - Click Push Notification
            if imgUrl != "" {
                sendPushNotifAnalytic(true, isBackgroundMode: true, targetId: targetId, tipe: tipe)
            } else {
                sendPushNotifAnalytic(false, isBackgroundMode: true, targetId: targetId, tipe: tipe)
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        self.saveContext()
        
        // MoEngage
        MoEngage.sharedInstance().stop(application)
        
        /* // disable
        if produkUploader != nil {
            produkUploader.stop()
        }
         */
        
        // Uninstall.io (disabled)
        //NotifyManager.sharedManager().didLoseFocus()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        // Uninstall.io (disabled)
        //NotifyManager.sharedManager().startNotifyServicesWithAppID(UninstallIOAppToken, key: UninstallIOAppSecret)
        
        self.versionForceUpdateCheck()
        
        // Prelo Analytic - Open App
        AnalyticManager.sharedInstance.openApp()
        
        /* // disable
        if (User.Token != nil && CDUser.getOne() != nil) { // If user is logged in
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
                self.produkUploader.start()
            })
        }
         */
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        
        // Remove app badge if any
        // show badge
        //UIApplication.shared.applicationIconBadgeNumber = 0 //User.getNotifCount() as NSInteger
        
        // AppsFlyer
        // Track Installs, updates & sessions(app opens) (You must include this API to enable tracking)
        AppsFlyerTracker.shared().trackAppLaunch()
        
        // MoEngage
        MoEngage.sharedInstance().applicationBecameActiveinApplication(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        
        // MoEngage
        MoEngage.sharedInstance().applicationTerminated(application)
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
//        Constant.showDialog("FIrst INIT", message: "firts INIT")
        
        self.versionForceUpdateCheck()
        
        // Prelo Analytic - Open App
        AnalyticManager.sharedInstance.openApp()
        
        // Prelo Analytic - Update User
        AnalyticManager.sharedInstance.updateUser(isNeedPayload: true)
        
        let mainQueue = OperationQueue.main
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot,
                                                                object: nil,
                                                                queue: mainQueue) { notification in
                                                                    // executes after screenshot
                                                                    
                                                                    if !self.isTakingScreenshot {
                                                                        
                                                                        self.isTakingScreenshot = true
                                                                        self.showAlert()
                                                                        
                                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                                                            
                                                                            self.hideRedirAlertWithDelay(0.0, completion: nil)
                                                                            self.takeScreenshot()
                                                                            
                                                                        })
                                                                    }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Uninstall.io (disabled)
        //NotifyManager.sharedManager().startNotifyServicesWithAppID(UninstallIOAppToken, key: UninstallIOAppSecret)
    }
    
    // MARK: - Redirection functions
    
    func handleUniversalLink(_ url : URL, path : String, param : [URLQueryItem]) {
        self.showRedirAlert()
        
        if (url.absoluteString.lowercased().contains("prelo://")) { // prelo://
            let urlString = url.absoluteString.lowercased().replace("prelo:/", template: "")
            var parameter = path
            
            if parameter != "" && parameter.characterAtIndex(0) == "/" {
                parameter.remove(at: parameter.startIndex)
            }
            
            // #1 User
            if (urlString.contains("/user")) {
                if parameter != "" {
                    self.redirectShopPage(parameter) // user id
                } else {
                    self.showFailedRedirAlert()
                }
                
                /*
                let _ = request(APIUser.testUser(username: path.replace("/", template: ""))).responseJSON { resp in
                    if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Data Shop Pengguna")) {
                        let json = JSON(resp.result.value!)["_data"]
                        if let userId = json["_id"].string {
                            self.redirectShopPage(userId)
                        } else {
                            self.showFailedRedirAlert()
                        }
                    } else {
                        self.showFailedRedirAlert()
                    }
                }
                 */
            
            // #2 Category
            } else if (urlString.contains("/category")) {
                if parameter != "" {
                    if parameter.contains("/") {
                        let separators = NSCharacterSet(charactersIn: "/")
                        // Split based on characters.
                        let params = parameter.components(separatedBy: separators as CharacterSet)
                        
                        if params.count >= 2 && params[1] != "" {
                            self.redirectSubCategorySegment(params[0], segment: params[1])
                        } else {
                            self.redirectCategory(params[0])
                        }
                    } else {
                        self.redirectCategory(parameter) // user id
                    }
                } else {
                    self.showFailedRedirAlert()
                }
                
                /*
                let _ = request(APIReference.getCategoryByPermalink(permalink: path.replace("/", template: ""))).responseJSON { resp in
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
                 */
                
            // #3 Chat
            } else if (urlString.contains("/chat")) {
                if parameter != "" {
                    self.redirectInbox(parameter)
                } else {
                    self.showFailedRedirAlert()
                }
            
            // #4 Product Detail
            } else if (urlString.contains("/product")) {
                if parameter != "" {
                    self.redirectProduct(parameter)
                } else {
                    self.showFailedRedirAlert()
                }
            
            // #5 Order
            } else if (urlString.contains("/order")) {
                if parameter != "" {
                    if (urlString.contains("/buyer")) {
                        self.redirectTransaction(parameter, trxProductId: nil, isSeller: false)
                    } else if (urlString.contains("/seller")) {
                        self.redirectTransaction(parameter, trxProductId: nil, isSeller: true)
                    } else {
                        self.showFailedRedirAlert()
                    }
                } else {
                    self.showFailedRedirAlert()
                }
                
            // #6 Transaction
            } else if (urlString.contains("/transaction")) {// seller - buyer
                if parameter != "" {
                    self.redirectTransaction(nil, trxProductId: parameter, isSeller: false) // is seller not use, because trx product
                } else {
                    self.showFailedRedirAlert()
                }
                
            // #7 Cart
            } else if (urlString.contains("/cart")) {
                self.redirectCart()
            
            // #8 Referral
            } else if (urlString.contains("/referral")) {
                self.redirectReferral()
            
            // #9 Lovers
            } else if (urlString.contains("/lovers")) {
                if parameter != "" {
                    self.redirectLove(parameter)
                } else {
                    self.showFailedRedirAlert()
                }
                
            // #10 Achievement
            } else if (urlString.contains("/achievement")) {
                self.redirectAchievement()
            
            // #11 Confirm Payment
            } else if (urlString.contains("/confirm")) {
                if parameter != "" {
                    self.redirectConfirmPayment(parameter)
                } else {
                    self.showFailedRedirAlert()
                }
                
            // #12 My Products
            } else if (urlString.contains("/my-products")) {
                self.redirectMyProducts()
                
            // #13 Comment
            } else if (urlString.contains("/comment")) {
                if parameter != "" {
                    self.redirectComment(parameter)
                } else {
                    self.showFailedRedirAlert()
                }
                
            } else {
                self.showFailedRedirAlert()
                
            }
            
        } else if (url.absoluteString.contains("prelo.co.id") || url.absoluteString.contains("dev.prelo.id")) { // https://prelo.co.id/ / http://dev.prelo.id/
            if (path.contains(".html")) {
                let permalink = path.replace("/", template: "").replacingOccurrences(of: ".html", with: "")
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
            } else if (path.contains("/p/")) { // old
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
                    let permalink = splittedPath[1] //.replacingOccurrences(of: ".html", with: "")
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
                let _ = request(APIUser.testUser(username: path.replace("/", template: ""))).responseJSON { resp in
                    
                    if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Data Shop Pengguna")) {
                        
                        let json = JSON(resp.result.value!)["_data"]
                        if let userId = json["_id"].string {
                            self.redirectShopPage(userId)
                        } else {
                            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                                // Choose one method
                                UIApplication.shared.openURL(url) // Open in safari
                                //self.redirectWebview(url.absoluteString) // Open in prelo's webview
                            })
                        }
                    } else {
                        self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                            // Choose one method
                            UIApplication.shared.openURL(url) // Open in safari
                            //self.redirectWebview(url.absoluteString) // Open in prelo's webview
                        })
                    }
                }
            }
            
        } else if (url.absoluteString.contains("http://") || url.absoluteString.contains("https://")) { // other
            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                // Choose one method
                UIApplication.shared.openURL(url) // Open in safari
                //self.redirectWebview(url.absoluteString) // Open in prelo's webview
            })
        } else {
            self.showFailedRedirAlert()
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
        } else if (tipeLowercase == self.RedirLove) {
            if (targetId != nil && targetId != "") {
                self.showRedirAlert()
                self.redirectLove(targetId!)
            }
        } else if (tipeLowercase == self.RedirAchievement) {
            self.showRedirAlert()
            self.redirectAchievement()
        } else if (tipeLowercase == self.RedirReferral) {
            self.showRedirAlert()
            self.redirectReferral()
        } else if (tipeLowercase == self.RedirPreloMessage) {
            self.showRedirAlert()
            self.redirectPreloMessage()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            // decrease notif badge
            let unreadNotifCount = self.preloNotifListener.newNotifCount - 1
            self.preloNotifListener.setNewNotifCount(unreadNotifCount)
        })
    }
    
    func showAlert() {
        self.redirAlert = SCLAlertView(appearance: Constant.appearance)
        self.alertViewResponder = self.redirAlert!.showCustom("Take Screenshot", subTitle: "Harap tunggu beberapa saat", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    func showRedirAlert() {
//        redirAlert = UIAlertController(title: "Redirecting...", message: "Harap tunggu beberapa saat", preferredStyle: .alert)
//        UIApplication.shared.keyWindow?.rootViewController?.present(redirAlert!, animated: true, completion: nil)
        
        self.redirAlert = SCLAlertView(appearance: Constant.appearance)
        self.alertViewResponder = self.redirAlert!.showCustom("Redirecting...", subTitle: "Harap tunggu beberapa saat", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    func hideRedirAlertWithDelay(_ delay: Double, completion: (() -> Void)?) {
        let delayTime = delay * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delayTime)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
//            self.redirAlert?.dismiss(animated: true, completion: completion)
            self.alertViewResponder?.close()
            if (completion != nil) {
                self.alertViewResponder?.setDismissBlock(completion!)
            }
        })
    }
    
    func showFailedRedirAlert() {
//        redirAlert?.title = "Redirection Failed"
//        redirAlert?.message = "Terdapat kesalahan saat memproses data"
        
        alertViewResponder?.setTitle("Redirection Failed")
        alertViewResponder?.setSubTitle("Terdapat kesalahan saat memproses data")
        
        self.hideRedirAlertWithDelay(3.0, completion: nil)
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
                    
                    self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                        rootViewController!.pushViewController(productDetailVC, animated: true)
                    })
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
                    p.previousScreen = "Push Notification"
                    
                    self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                        rootViewController!.pushViewController(p, animated: true)
                    })
                    
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
        
        
        if (!AppTools.isNewShop) {
            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                rootViewController!.pushViewController(listItemVC, animated: true)
            })
            
        } else { // new shop
            let storePageTabBarVC = Bundle.main.loadNibNamed(Tags.XibNameStorePage, owner: nil, options: nil)?.first as! StorePageTabBarViewController
            storePageTabBarVC.shopId = userId
            
            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                rootViewController!.pushViewController(storePageTabBarVC, animated: true)
            })
        }
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
                    tawarVC.previousScreen = "Push Notification"
                    
                    self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                        rootViewController!.pushViewController(tawarVC, animated: true)
                    })
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
            
            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                rootViewController!.pushViewController(notifPageVC, animated: true)
            })
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
//                            self.redirAlert?.title = "Perhatian"
//                            self.redirAlert?.message = "Anda sudah melakukan konfirmasi bayar untuk transaksi ini"
                            self.alertViewResponder?.setTitle("Perhatian")
                            self.alertViewResponder?.setSubTitle("Anda sudah melakukan konfirmasi bayar untuk transaksi ini")
                            self.hideRedirAlertWithDelay(3.0, completion: nil)
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
                            orderConfirmVC.total = data["total_price"].int64Value
                            orderConfirmVC.images = imgs
                            orderConfirmVC.isFromCheckout = false
                            
                            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                                rootViewController!.pushViewController(orderConfirmVC, animated: true)
                            })
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
            
            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                rootViewController!.pushViewController(transactionDetailVC, animated: true)
            })
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
        
        self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
            rootViewController!.pushViewController(expProductsVC, animated: true)
        })
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
        
        self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
            rootViewController!.pushViewController(listItemVC, animated: true)
        })
    }
    
    func redirectSubCategorySegment(_ categoryId : String, segment : String) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let listItemVC = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        listItemVC.currentMode = .filter
        listItemVC.fltrCategId = categoryId
        listItemVC.fltrSortBy = "recent"
        listItemVC.fltrSegment = segment
        
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
        
        self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
            rootViewController!.pushViewController(listItemVC, animated: true)
        })
    }
    
    func redirectLove(_ productId : String) {
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
            let productLovelistVC = Bundle.main.loadNibNamed(Tags.XibNameProductLovelist, owner: nil, options: nil)?.first as! ProductLovelistViewController
            productLovelistVC.productId = productId
            
            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                rootViewController!.pushViewController(productLovelistVC, animated: true)
            })
        } else {
            self.showFailedRedirAlert()
        }
    }
    
    func redirectAchievement() {
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
            let AchievementVC = Bundle.main.loadNibNamed(Tags.XibNameAchievement, owner: nil, options: nil)?.first as! AchievementViewController
            AchievementVC.previousScreen = "Push Notification"
            
            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                rootViewController!.pushViewController(AchievementVC, animated: true)
            })
        } else {
            self.showFailedRedirAlert()
        }
    }
    
    func redirectReferral() {
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
            let referralPageVC = Bundle.main.loadNibNamed(Tags.XibNameReferralPage, owner: nil, options: nil)?.first as! ReferralPageViewController
            referralPageVC.previousScreen = "Push Notification"
            
            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                rootViewController!.pushViewController(referralPageVC, animated: true)
            })
        } else {
            self.showFailedRedirAlert()
        }
    }
    
    func redirectPreloMessage() {
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
            let preloMessageVC = Bundle.main.loadNibNamed(Tags.XibNamePreloMessage, owner: nil, options: nil)?.first as! PreloMessageViewController
            preloMessageVC.previousScreen = "Push Notification"
            
            self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
                rootViewController!.pushViewController(preloMessageVC, animated: true)
            })
        } else {
            self.showFailedRedirAlert()
        }
    }
    
    func redirectMyProducts() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let myProductVC = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdMyProducts) as! MyProductViewController
        myProductVC.shouldSkipBack = false
        
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
        
        self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
            rootViewController!.pushViewController(myProductVC, animated: true)
        })
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
        
        self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
            rootViewController!.pushViewController(webVC, animated: true)
        })
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
        
        self.hideRedirAlertWithDelay(1.0, completion: { () -> Void in
            rootViewController!.pushViewController(cartVC, animated: true)
        })
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
                //print("Portrait")
                
                
                //Do Rotation stuff here
                orientations = orientation
            }
        }
        else if (orientation == UIInterfaceOrientation.landscapeLeft || orientation == UIInterfaceOrientation.landscapeRight)
        {
            if(orientation != orientations) {
                //print("Landscape")
                
                Constant.showDialog("Device Orientation", message: "Halo Prelovers, Prelo menyarankan untuk menggunakan aplikasi Prelo dengan orientasi portrait atau tegak")
                
                //Do Rotation stuff here
                orientations = orientation
            }
        }
    }
    
    // MARK: - Analytics push notif
    func sendPushNotifAnalytic(_ isContainImage: Bool, isBackgroundMode: Bool, targetId: String, tipe: String) {
        // Prelo Analytic - Click Push Notification
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            "With Picture" : isContainImage,
//            "Is Background Mode" : isBackgroundMode,
//            "Target ID" : targetId,
//            "Type" : tipe
        ] as [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ClickPushNotification, data: pdata, previousScreen: "", loginMethod: loginMethod)
    }
    
    // MARK: - forceupdate checker
    func versionForceUpdateCheck() {
        // API Migrasi
        let _ = request(APIApp.version).responseJSON { resp in
            
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Version Check")) {
                let json = JSON(resp.result.value!)
                var data = json["_data"]
                
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
                            
                            Constant.forceUpdatePrompt()
                        }
                    }
                }
                
                // Check apps frequency
                if let frequency = data["ads_config"]["frequency"].int {
                    UserDefaults.standard.set(frequency + 1, forKey: UserDefaultsKey.AdsFrequency)
                    
                    UserDefaults.standard.synchronize()
                }
                
                // Check apps offset
                if let offset = data["ads_config"]["offset"].int {
                    UserDefaults.standard.set(offset, forKey: UserDefaultsKey.AdsOffset)
                    
                    UserDefaults.standard.synchronize()
                }
                
                // Check apps refresh time
                if let refreshTime = data["editors_page_refresh_time"].int {
                    UserDefaults.standard.set(refreshTime, forKey: UserDefaultsKey.RefreshTime)
                    
                    UserDefaults.standard.synchronize()
                }
                
                // change icon from server iOS 10.3.*
                if #available(iOS 10.3, *) {
                    if UIApplication.shared.supportsAlternateIcons {
                        // Check apps icon need update?
                        //let iconType = "ramadhan" // "default", "christmas", "ramadhan",
                        if let iconType = data["icon_launcher"].string {
                            if iconType == "default" && UIApplication.shared.alternateIconName != nil {
                                UIApplication.shared.setAlternateIconName(nil) { error in
                                    /*if let error = error {
                                        print(error.localizedDescription)
                                    } else {
                                        print("Success!")
                                    }*/
                                }
                            } else if UIApplication.shared.alternateIconName != iconType {
                                UIApplication.shared.setAlternateIconName(iconType) { error in
                                    /*if let error = error {
                                        print(error.localizedDescription)
                                    } else {
                                        print("Success!")
                                    }*/
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // screenshot
    func takeScreenshot() {
        CustomPhotoAlbum.sharedInstance.fetchLastPhoto(resizeTo: nil , imageCallback: {
            image in
            if let ss = image {
                let appearance = Constant.appearance
                //appearance.shouldAutoDismiss = false
                
                let alertView = SCLAlertView(appearance: appearance)
                
                let width = Constant.appearance.kWindowWidth - 24
                let frame = CGRect(x: 0, y: 0, width: width, height: width)
                
                let pView = UIImageView(frame: frame)
                pView.image = ss.resizeWithMaxWidthOrHeight(width * UIScreen.main.scale)
                pView.afInflate()
                pView.contentMode = .scaleAspectFit
                
                // Creat the subview
                let subview = UIView(frame: CGRect(x: 0, y: 0, width: width, height: width))
                subview.addSubview(pView)
                
                alertView.customSubview = subview
                
                alertView.addButton("Share", action: {
                    self.openShare(image: ss)
                })
                
                alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {
                    self.isTakingScreenshot = false
                }
                
                alertView.showCustom("Screenshot", subTitle: "", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
            } else {
                Constant.showDialog("Screenshot", message: "Pastikan untuk memberi akses aplikasi Prelo, dan coba untuk mengambil screenshot sekali lagi.")
                self.isTakingScreenshot = false
            }
        })
    }
    
    func openShare(image: UIImage) {
        // disable deeplink
        //let firstActivityItem = "Prelo"
        //let secondActivityItem : NSURL = NSURL(string: "https://prelo.co.id/")!
        
        // If you want to put an image
        // image (param)
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [image], applicationActivities: nil) // firstActivityItem, secondActivityItem,
        /*
         // This lines is for the popover you need to show in iPad
         activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)
         
         // This line remove the arrow of the popover to show in iPad
         activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.allZeros
         activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
         
         // Anything you want to exclude
         activityViewController.excludedActivityTypes = [
         UIActivityTypePostToWeibo,
         UIActivityTypePrint,
         UIActivityTypeAssignToContact,
         UIActivityTypeSaveToCameraRoll,
         UIActivityTypeAddToReadingList,
         UIActivityTypePostToFlickr,
         UIActivityTypePostToVimeo,
         UIActivityTypePostToTencentWeibo
         ]
         */
        
        //UIApplication.shared.keyWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
        
        activityViewController.completionWithItemsHandler = { activity, success, items, error in
            self.isTakingScreenshot = false
        }
        
        // https://stackoverflow.com/questions/26667009/get-top-most-uiviewcontroller
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            // topController should now be your topmost view controller
            topController.present(activityViewController, animated: true, completion: nil)
        }
    }
}
