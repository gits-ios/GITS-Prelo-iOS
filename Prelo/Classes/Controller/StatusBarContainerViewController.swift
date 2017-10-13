//
//  StatusBarContainerViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/24/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import CoreData
import Crashlytics
import Alamofire

class StatusBarContainerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        reloadingAppData()
    }
    
    func reloadingAppData() {
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
                        if !(CDCategory.saveCategories(metadata["categories"], m: moc)) {
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
                        if !(CDShipping.saveShippings(metadata["shippings"], m: moc)) {
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
                        if !(CDProductCondition.saveProductConditions(metadata["product_conditions"], m: moc)) {
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
                        if !(CDProvince.saveProvinceRegions(metadata["provinces_regions"], m: moc)) {
                            isSuccess = false
                        }
                    }
                })
                queue.addOperation(opProvincesRegions)
                
                let opFinish : Operation = BlockOperation(block: {
                    //                    a.dismiss(withClickedButtonIndex: -1, animated: true)
                    if (isSuccess) {
                        DispatchQueue.main.async(execute: {
                            NotificationCenter.default.addObserver(self, selector: #selector(StatusBarContainerViewController.changeStatusBarColor(_:)), name: NSNotification.Name(rawValue: "changeStatusBarColor"), object: nil)
                        })
                    } else {
                        DispatchQueue.main.async(execute: {
                            NotificationCenter.default.addObserver(self, selector: #selector(StatusBarContainerViewController.changeStatusBarColor(_:)), name: NSNotification.Name(rawValue: "changeStatusBarColor"), object: nil)
                        })
                    }
                })
                opFinish.addDependency(opCategories)
                opFinish.addDependency(opShippings)
                opFinish.addDependency(opProductConditions)
                opFinish.addDependency(opProvincesRegions)
                queue.addOperation(opFinish)
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(StatusBarContainerViewController.changeStatusBarColor(_:)), name: NSNotification.Name(rawValue: "changeStatusBarColor"), object: nil)
            }
        }
    }
    
    func changeStatusBarColor(_ notif : Foundation.Notification) {
        if let c = notif.object as? UIColor {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.backgroundColor = c
            })
        }
    }
}
