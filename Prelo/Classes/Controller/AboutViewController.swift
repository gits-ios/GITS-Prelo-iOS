//
//  AboutViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CoreData
import Crashlytics

class AboutViewController: BaseViewController, UIAlertViewDelegate {

    @IBOutlet var btnLogout : BorderedButton!
    @IBOutlet var btnClear : BorderedButton!
    @IBOutlet var btnClear2 : BorderedButton!
    @IBOutlet weak var lblVersion: UILabel!
    @IBOutlet weak var btnUrlPrelo: UIButton!
    
    var isShowLogout : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (!isShowLogout) {
            self.btnLogout.hidden = true
            self.btnClear.hidden = true
            self.btnClear2.hidden = false
        }
        
        self.title = PageName.About
        
        self.lblVersion.text = "-"
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
                self.lblVersion.text = "Version " + version + " Build " + build
            }
        }
        
        if (AppTools.isDev) {
            let attr = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue, NSForegroundColorAttributeName: UIColor.whiteColor()]
            if (AppTools.IsPreloProduction) {
                let attrString = NSAttributedString(string: "switch to dev", attributes: attr)
                self.btnUrlPrelo.setAttributedTitle(attrString, forState: .Normal)
            } else {
                let attrString = NSAttributedString(string: "switch to production", attributes: attr)
                self.btnUrlPrelo.setAttributedTitle(attrString, forState: .Normal)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        //Mixpanel.trackPageVisit(PageName.About)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.About)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openPreloSite(sender: AnyObject) {
        if (AppTools.isDev) {
            self.logout()
            if (AppTools.IsPreloProduction) {
                // switch to dev
                AppTools.PreloBaseUrl = "http://dev.prelo.id"
            } else {
                // switch to production
                AppTools.PreloBaseUrl = "https://prelo.co.id"
            }
        } else {
            UIApplication.sharedApplication().openURL(NSURL(string: AppTools.PreloBaseUrl)!)
        }
    }
    
    @IBAction func reloadAppData(sender: AnyObject) {
        // Tampilkan pop up untuk prompt
        let a = UIAlertView()
        a.message = "Reload App Data membutuhkan waktu beberapa saat. Lanjutkan?"
        a.addButtonWithTitle("Batal")
        a.addButtonWithTitle("Reload App Data")
        a.delegate = self
        a.show()
    }
    
    @IBAction func clearCache()
    {
        disableBtnClearCache()
        //UIImageView.sharedImageCache().clearAll()
        
        CartProduct.deleteAll()
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let p = AppToolsObjC.jsonStringFrom(c)
        var pID = ""
        var rID = ""
        if let u = CDUser.getOne()
        {
            pID = u.profiles.provinceID
            rID = u.profiles.regionID
        }
        let a = "{\"address\": \"alamat\", \"province_id\": \"" + pID + "\", \"region_id\": \"" + rID + "\", \"postal_code\": \"\"}"
        request(APICart.Refresh(cart: p, address: a, voucher: nil)).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Clear Cache")) {
                self.enableBtnClearCache()
                
                UIAlertView.SimpleShow("Clear Cache", message: "Clear Cache telah berhasil")
            } else {
                self.enableBtnClearCache()
            }
        }
    }
    
    @IBAction func logout()
    {
        // Remove deviceRegId so the device won't receive push notification
        LoginViewController.SendDeviceRegId()
        
        // Tell server
        // API Migrasi
        request(APIAuth.Logout).responseJSON {resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Logout")) {
                print("Logout API success")
            }
        }
        
        // Clear local data
        User.Logout()
        
        // Tell delegate class if any
        if let d = self.userRelatedDelegate
        {
            d.userLoggedOut!()
        }
        
        if let del = UIApplication.sharedApplication().delegate as? AppDelegate
        {
            del.messagePool?.stop()
        } else
        {
            let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
            Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"logout"])
        }
        
        // Disconnect socket
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let notifListener = delegate.preloNotifListener
        
        // Set top bar notif number to 0
        if (notifListener.newNotifCount != 0) {
            notifListener.setNewNotifCount(0)
        }
        
        // Reset mixpanel
        Mixpanel.sharedInstance().reset()
        let uuid = UIDevice.currentDevice().identifierForVendor!.UUIDString
        Mixpanel.sharedInstance().identify(uuid)
        
        // MoEngage reset
        MoEngage.sharedInstance().resetUser()
        
        AppDelegate.Instance.produkUploader.stop()
        AppDelegate.Instance.produkUploader.clearQueue()
        
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
    
    func enableBtnClearCache() {
        self.btnClear.setTitle("CLEAR CACHE", forState: .Normal)
        self.btnClear.userInteractionEnabled = true
        self.btnClear2.setTitle("CLEAR CACHE", forState: .Normal)
        self.btnClear2.userInteractionEnabled = true
    }
    
    func disableBtnClearCache() {
        btnClear.setTitle("Loading...", forState: .Normal)
        btnClear.userInteractionEnabled = false
        btnClear2.setTitle("Loading...", forState: .Normal)
        btnClear2.userInteractionEnabled = false
    }
    
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
        let a = UIAlertView()
        let pView : UIProgressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Bar)
        pView.progress = 0
        pView.backgroundColor = Theme.GrayLight
        pView.progressTintColor = Theme.ThemeOrange
        a.setValue(pView, forKey: "accessoryView")
        a.title = "Reloading App Data..."
        a.message = "Harap untuk tidak menutup aplikasi selama proses berjalan"
        a.show()

        // API Migrasi
        request(APIApp.Metadata(brands: "0", categories: "1", categorySizes: "0", shippings: "1", productConditions: "1", provincesRegions: "1")).responseJSON {resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Reload App Data")) {
                let metaJson = JSON(resp.result.value!)
                let metadata = metaJson["_data"]
                
                var isSuccess : Bool = true
                let queue : NSOperationQueue = NSOperationQueue()
                
                let opCategories : NSOperation = NSBlockOperation(block: {
                    let psc = UIApplication.appDelegate.persistentStoreCoordinator
                    let moc = NSManagedObjectContext()
                    moc.persistentStoreCoordinator = psc
                    
                    // Update categories
                    print("Updating categories..")
                    if (CDCategory.deleteAll(moc)) {
                        if (CDCategory.saveCategories(metadata["categories"], m: moc)) {
                            dispatch_async(dispatch_get_main_queue(), {
                                pView.setProgress(pView.progress + 0.25, animated: true)
                            })
                        } else {
                            isSuccess = false
                        }
                    }
                })
                queue.addOperation(opCategories)
                
                
                let opShippings : NSOperation = NSBlockOperation(block: {
                    let psc = UIApplication.appDelegate.persistentStoreCoordinator
                    let moc = NSManagedObjectContext()
                    moc.persistentStoreCoordinator = psc
                    
                    // Update shippings
                    print("Updating shippings..")
                    if (CDShipping.deleteAll(moc)) {
                        if (CDShipping.saveShippings(metadata["shippings"], m: moc)) {
                            dispatch_async(dispatch_get_main_queue(), {
                                pView.setProgress(pView.progress + 0.25, animated: true)
                            })
                        } else {
                            isSuccess = false
                        }
                    }
                })
                queue.addOperation(opShippings)
                
                let opProductConditions : NSOperation = NSBlockOperation(block: {
                    let psc = UIApplication.appDelegate.persistentStoreCoordinator
                    let moc = NSManagedObjectContext()
                    moc.persistentStoreCoordinator = psc
                    
                    // Update product conditions
                    print("Updating product conditions..")
                    if (CDProductCondition.deleteAll(moc)) {
                        if (CDProductCondition.saveProductConditions(metadata["product_conditions"], m: moc)) {
                            dispatch_async(dispatch_get_main_queue(), {
                                pView.setProgress(pView.progress + 0.25, animated: true)
                            })
                        } else {
                            isSuccess = false
                        }
                    }
                })
                queue.addOperation(opProductConditions)
                
                let opProvincesRegions : NSOperation = NSBlockOperation(block: {
                    let psc = UIApplication.appDelegate.persistentStoreCoordinator
                    let moc = NSManagedObjectContext()
                    moc.persistentStoreCoordinator = psc
                    
                    // Update provinces regions
                    print("Updating provinces regions..")
                    if (CDProvince.deleteAll(moc) && CDRegion.deleteAll(moc)) {
                        if (CDProvince.saveProvinceRegions(metadata["provinces_regions"], m: moc)) {
                            dispatch_async(dispatch_get_main_queue(), {
                                pView.setProgress(pView.progress + 0.25, animated: true)
                            })
                        } else {
                            isSuccess = false
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
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
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
