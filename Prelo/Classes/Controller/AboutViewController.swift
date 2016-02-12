//
//  AboutViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CoreData

class AboutViewController: BaseViewController, UIAlertViewDelegate {

    @IBOutlet var btnLogout : BorderedButton!
    @IBOutlet var btnClear : BorderedButton!
    @IBOutlet var btnClear2 : BorderedButton!
    @IBOutlet weak var lblVersion: UILabel!
    
    var isShowLogout : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (!isShowLogout) {
            self.btnLogout.hidden = true
            self.btnClear.hidden = true
            self.btnClear2.hidden = false
        }
        
        self.title = PageName.About
        
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            self.lblVersion.text = "Version " + version
        } else {
            self.lblVersion.text = "-"
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.About)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.About)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openPreloSite(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: AppTools.PreloBaseUrl)!)
    }
    
    @IBAction func reloadAppData(sender: AnyObject) {
        // Tampilkan pop up untuk prompt
        let a = UIAlertView()
        a.message = "Reload App Data membutuhkan waktu beberapa menit. Lanjutkan?"
        a.addButtonWithTitle("Batal")
        a.addButtonWithTitle("Reload App Data")
        a.delegate = self
        a.show()
    }
    
    @IBAction func clearCache()
    {
        UIImageView.sharedImageCache().clearAll()
        UIAlertView.SimpleShow("Perhatian", message: "Cache Cleared")
    }
    
    @IBAction func logout()
    {
        // Remove deviceRegId so the device won't receive push notification
        LoginViewController.SendDeviceRegId(onFinish: nil)
        
        // Clear local data
        User.Logout()
        
        // Tell delegate class if any
        if let d = self.userRelatedDelegate
        {
            d.userLoggedOut!()
        }
        
        // Tell server
        request(APIAuth.Logout).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Logout")) {
                println("Logout API success")
            }
        }
        
        let del = UIApplication.sharedApplication().delegate as! AppDelegate
        del.messagePool.stop()
        
        // Disconnect socket
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let notifListener = delegate.preloNotifListener
        /* Dimatiin abis gabungin ke messagepool
        notifListener.willReconnect = true // Pengganti disconnect
        */
        // Set top bar notif number to 0
        if (notifListener.newNotifCount != 0) {
            notifListener.setNewNotifCount(0)
        }
        
        // Reset mixpanel
        Mixpanel.sharedInstance().reset()
        let uuid = UIDevice.currentDevice().identifierForVendor!.UUIDString
        Mixpanel.sharedInstance().identify(uuid)
        
        // Back to previous page
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - UIAlertView delegate function
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        switch buttonIndex {
        case 0: // Batal
            alertView.dismissWithClickedButtonIndex(-1, animated: true)
            break
        case 1: // Reload App Data
            alertView.dismissWithClickedButtonIndex(-1, animated: true)
            // Tampilkan pop up untuk loading
            reloadingAppData()
            break
        default:
            break
        }
    }
    
    // MARK: - Other functions
    
    func printCoreDataCount() {
        println("Category = \(CDCategory.getCategoryCount())")
        println("Brand = \(CDBrand.getBrandCount())")
        println("CategorySize = \(CDCategorySize.getCategorySizeCount())")
        println("Shipping = \(CDShipping.getShippingCount())")
        println("ProductCondition = \(CDProductCondition.getProductConditionCount())")
        println("Province = \(CDProvince.getProvinceCount())")
    }
    
    func reloadingAppData() {
        // Set appdatasaved to false in case the reload is not finished (the app is closed before finish) and need to be repeated on next app launch
        NSUserDefaults.setObjectAndSync(false, forKey: UserDefaultsKey.AppDataSaved)
        
        // Tampilkan pop up untuk loading
        let a = UIAlertView()
        let pView : UIProgressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Bar)
        pView.progress = 0
        pView.backgroundColor = Theme.GrayLight
        pView.progressTintColor = Theme.ThemeOrage
        a.setValue(pView, forKey: "accessoryView")
        a.title = "Reloading App Data..."
        a.message = "Harap untuk tidak menutup aplikasi selama proses berjalan"
        a.show()

        request(APIApp.Metadata(brands: "1", categories: "1", categorySizes: "1", shippings: "1", productConditions: "1", provincesRegions: "1")).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Reload App Data")) {
                let metaJson = JSON(res!)
                let metadata = metaJson["_data"]
                
                var isSuccess : Bool = true
                var queue : NSOperationQueue = NSOperationQueue.new()
                
                let opCategories : NSOperation = NSBlockOperation(block: {
                    if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                        var moc = NSManagedObjectContext()
                        moc.persistentStoreCoordinator = psc
                        
                        // Update categories
                        println("Updating categories..")
                        if (CDCategory.deleteAll(moc)) {
                            if (CDCategory.saveCategories(metadata["categories"], m: moc)) {
                                dispatch_async(dispatch_get_main_queue(), {
                                    pView.setProgress(pView.progress + 0.05, animated: true)
                                })
                            } else {
                                isSuccess = false
                            }
                        }
                    }
                })
                queue.addOperation(opCategories)
                
                let opBrands : NSOperation = NSBlockOperation(block: {
                    if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                        var moc = NSManagedObjectContext()
                        moc.persistentStoreCoordinator = psc
                        
                        // Update brands
                        println("Updating brands..")
                        if (CDBrand.deleteAll(moc)) {
                            if (CDBrand.saveBrands(metadata["brands"], m: moc, pView : pView, p : 0.72)) {
                            } else {
                                isSuccess = false
                            }
                        }
                    }
                })
                queue.addOperation(opBrands)
                
                let opCategorySizes : NSOperation = NSBlockOperation(block: {
                    if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                        var moc = NSManagedObjectContext()
                        moc.persistentStoreCoordinator = psc
                        
                        // Update category sizes
                        println("Updating category sizes..")
                        if (CDCategorySize.deleteAll(moc)) {
                            if (CDCategorySize.saveCategorySizes(metadata["category_sizes"], m: moc)) {
                                dispatch_async(dispatch_get_main_queue(), {
                                    pView.setProgress(pView.progress + 0.05, animated: true)
                                })
                            } else {
                                isSuccess = false
                            }
                        }
                    }
                })
                queue.addOperation(opCategorySizes)
                
                let opShippings : NSOperation = NSBlockOperation(block: {
                    if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                        var moc = NSManagedObjectContext()
                        moc.persistentStoreCoordinator = psc
                    
                        // Update shippings
                        println("Updating shippings..")
                        if (CDShipping.deleteAll(moc)) {
                            if (CDShipping.saveShippings(metadata["shippings"], m: moc)) {
                                dispatch_async(dispatch_get_main_queue(), {
                                    pView.setProgress(pView.progress + 0.05, animated: true)
                                })
                            } else {
                                isSuccess = false
                            }
                        }
                    }
                })
                queue.addOperation(opShippings)
                
                let opProductConditions : NSOperation = NSBlockOperation(block: {
                    if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                        var moc = NSManagedObjectContext()
                        moc.persistentStoreCoordinator = psc
                        
                        // Update product conditions
                        println("Updating product conditions..")
                        if (CDProductCondition.deleteAll(moc)) {
                            if (CDProductCondition.saveProductConditions(metadata["product_conditions"], m: moc)) {
                                dispatch_async(dispatch_get_main_queue(), {
                                    pView.setProgress(pView.progress + 0.05, animated: true)
                                })
                            } else {
                                isSuccess = false
                            }
                        }
                    }
                })
                queue.addOperation(opProductConditions)
                
                let opProvincesRegions : NSOperation = NSBlockOperation(block: {
                    if let psc = UIApplication.appDelegate.persistentStoreCoordinator {
                        var moc = NSManagedObjectContext()
                        moc.persistentStoreCoordinator = psc
                        
                        // Update provinces regions
                        println("Updating provinces regions..")
                        if (CDProvince.deleteAll(moc) && CDRegion.deleteAll(moc)) {
                            if (CDProvince.saveProvinceRegions(metadata["provinces_regions"], m: moc)) {
                                dispatch_async(dispatch_get_main_queue(), {
                                    pView.setProgress(pView.progress + 0.05, animated: true)
                                })
                            } else {
                                isSuccess = false
                            }
                        }
                    }
                })
                queue.addOperation(opProvincesRegions)
                
                let opFinish : NSOperation = NSBlockOperation(block: {
                    a.dismissWithClickedButtonIndex(-1, animated: true)
                    if (isSuccess) {
                        dispatch_async(dispatch_get_main_queue(), {
                            Constant.showDialog("Reload App Data", message: "Reload App Data berhasil")
                        })
                        // Set appdatasaved to true
                        NSUserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.AppDataSaved)
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            Constant.showDialog("Reload App Data", message: "Oops, terjadi kesalahan saat Reload App Data")
                        })
                    }
                })
                opFinish.addDependency(opCategories)
                opFinish.addDependency(opBrands)
                opFinish.addDependency(opCategorySizes)
                opFinish.addDependency(opShippings)
                opFinish.addDependency(opProductConditions)
                opFinish.addDependency(opProvincesRegions)
                queue.addOperation(opFinish)
            } else {
                a.dismissWithClickedButtonIndex(-1, animated: true)
            }
        }
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
