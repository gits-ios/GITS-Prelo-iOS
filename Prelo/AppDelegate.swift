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

//import AdobeCreativeSDKCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static let StatusBarTapNotificationName = "statusbartapped"
    
    var messagePool : MessagePool!
    
    var preloNotifListener : PreloNotificationListener!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
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
            Crashlytics.sharedInstance().setUserIdentifier(c.profiles.phone!)
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
        AdobeUXAuthManager.sharedManager().setAuthenticationParametersWithClientID("79e1f842bbe948b49f7cce12d30d547e", clientSecret: "63bcf116-40d9-4a09-944b-af0401b1a350", enableSignUp: false)
        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
//            
//        })
        
        preloNotifListener = PreloNotificationListener()
        
        self.versionCheck()
        
        ACTAutomatedUsageTracker.enableAutomatedUsageReportingWithConversionID("953474992")
        
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
                    let notifType : String? = remoteNotifAps["tipe"] as! String?
                    //Constant.showDialog("notifType", message: "\(notifType)")
                    if (notifType?.lowercaseString == "notification") {
                        NSUserDefaults.standardUserDefaults().setObject("notification", forKey: "apnsredirect")
                        NSUserDefaults.standardUserDefaults().synchronize()
                    } else if (notifType?.lowercaseString == "inbox") {
                        NSUserDefaults.standardUserDefaults().setObject("inbox", forKey: "apnsredirect")
                        NSUserDefaults.standardUserDefaults().synchronize()
                    }
                }
            }
        }
        
        // Override point for customization after application launch
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func userLoggedIn()
    {
        messagePool.start()
    }
    
    func versionCheck() {
        request(APIApp.Version(appType: "ios")).responseJSON
            {_, _, res, err in
                if (err != nil) { // Terdapat error
                    println("Error getting version: \(err!.description)")
                } else {
                    let json = JSON(res!)
                    let data = json["_data"]
                    if (data == nil) { // Data kembalian kosong
                        let obj : [String : String] = res as! [String : String]
                        let message = obj["_message"]
                        println("Empty version data, error: \(message)")
                    } else { // Berhasil
                        println("Version data: \(data)")
                        
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
                            self.updateMetadata(isUpdateVers[0], updateCategories: isUpdateVers[1], updateCategorySizes: isUpdateVers[2], updateShippings: isUpdateVers[3], updateProductConditions: isUpdateVers[4], updateProvincesRegions: isUpdateVers[5])
                        } else {
                            println("Same metadata version")
                            
                            // Set categorysaved to true so CategoryPreferencesVC can be executed
                            NSUserDefaults.standardUserDefaults().setObject(true, forKey: UserDefaultsKey.CategorySaved)
                            NSUserDefaults.standardUserDefaults().synchronize()
                        }
                        
                        CDVersion.saveVersions(data)
                    }
                }
        }
    }
    
    func updateMetadata(updateBrands : String, updateCategories : String, updateCategorySizes : String, updateShippings : String, updateProductConditions : String, updateProvincesRegions : String)
    {
        request(APIApp.Metadata(brands: updateBrands, categories: updateCategories, categorySizes: updateCategorySizes, shippings: updateShippings, productConditions: updateProductConditions, provincesRegions: updateProvincesRegions)).responseJSON
            {_, _, metaRes, metaErr in
                if (metaErr != nil) { // Terdapat error
                    println("Error getting metadata: \(metaErr!.description)")
                } else {
                    let metaJson = JSON(metaRes!)
                    let metadata = metaJson["_data"]
                    if (metadata == nil) { // Data kembalian kosong
                        println("Error getting metadata")
                    } else { // Berhasil
                        // Asynchronous update!!
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                            // Update categories
                            if (updateCategories == "1") {
                                println("Updating categories..")
                                if (CDCategory.deleteAll()) {
                                    CDCategory.saveCategories(metadata["categories"])
                                    // Set categorysaved to true so CategoryPreferencesVC can be executed
                                    NSUserDefaults.standardUserDefaults().setObject(true, forKey: UserDefaultsKey.CategorySaved)
                                    NSUserDefaults.standardUserDefaults().synchronize()
                                }
                            }
                            // Update brands
                            if (updateBrands == "1") {
                                println("Updating brands..")
                                if (CDBrand.deleteAll()) {
                                    CDBrand.saveBrands(metadata["brands"])
                                }
                            }
                            // Update category sizes
                            if (updateCategorySizes == "1") {
                                println("Updating category sizes..")
                                if (CDCategorySize.deleteAll()) {
                                    CDCategorySize.saveCategorySizes(metadata["category_sizes"])
                                }
                            }
                            // Update shippings
                            if (updateShippings == "1") {
                                println("Updating shippings..")
                                if (CDShipping.deleteAll()) {
                                    CDShipping.saveShippings(metadata["shippings"])
                                }
                            }
                            // Update product conditions
                            if (updateProductConditions == "1") {
                                println("Updating product conditions..")
                                if (CDProductCondition.deleteAll()) {
                                    CDProductCondition.saveProductConditions(metadata["product_conditions"])
                                }
                            }
                            // Update provinces regions
                            if (updateProvincesRegions == "1") {
                                println("Updating provinces regions..")
                                if (CDProvince.deleteAll() && CDRegion.deleteAll()) {
                                    CDProvince.saveProvinceRegions(metadata["provinces_regions"])
                                }
                            }
                        })
                    }
                }
        }
    }
    
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
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
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

    // MARK: - Facebook Function
    
    func application(application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject?) -> Bool {
            return FBSDKApplicationDelegate.sharedInstance().application(
                application,
                openURL: url,
                sourceApplication: sourceApplication,
                annotation: annotation)
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
}

