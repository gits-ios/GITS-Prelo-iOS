//
//  CDBrand.swift
//  Prelo
//
//  Created by Fransiska on 10/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDBrand)
class CDBrand: NSManagedObject {
    
    @NSManaged var id : String
    @NSManaged var name : String
    @NSManaged var v : NSNumber
    @NSManaged var categoryIds : NSData
    
    static func saveBrands(json : JSON, m : NSManagedObjectContext, pView : UIProgressView?, p : Float?) -> Bool {
        // Kalo (p != nil) artinya ada progress view yang dihandle
        // Kalo (p == nil) artinya tidak ada progress view yang dihandle
        // Kalo (pView != nil) artinya progress view dihandle fungsi ini
        // Kalo (pView == nil) artinya progress view dihandle appdelegate
        let brandCount : Int = json.count
        var isUpdateProgressView : Bool = false
        var progressPerBrand : Float?
        if (p != nil) {
            isUpdateProgressView = true
            progressPerBrand = p! / Float(brandCount)
        }
        for i in 0 ..< brandCount
        {
            let brandJson = json[i]
            print(brandJson.rawString())
            var catIds : [String] = []
            let bcount = brandJson["category_ids"].arrayValue.count
            for j in 0 ..< bcount
            {
                catIds.append(brandJson["category_ids"][j].string!)
            }
            let r = NSEntityDescription.insertNewObjectForEntityForName("CDBrand", inManagedObjectContext: m) as! CDBrand
            r.id = brandJson["_id"].string!
            r.name = brandJson["name"].string!
            r.v = brandJson["__v"].number!
            r.categoryIds = NSKeyedArchiver.archivedDataWithRootObject(catIds)
            if (isUpdateProgressView) {
                if (pView != nil) {
                    dispatch_async(dispatch_get_main_queue(), {
                        pView!.setProgress(pView!.progress + progressPerBrand!, animated: true)
                    })
                } else {
                    UIApplication.appDelegate.increaseLoadAppDataProgressBy(progressPerBrand!)
                    UIApplication.appDelegate.loadAppDataDelegate?.updateProgress(UIApplication.appDelegate.loadAppDataProgress)
                }
            }
        }
        if (m.saveSave() == false) {
            print("saveBrands failed")
            return false
        }
        print("saveBrands success")
        return true
    }
    
    static func newOne(id : String, name : String, v : NSNumber, categoryIds: NSData) -> CDBrand? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObjectForEntityForName("CDBrand", inManagedObjectContext: m) as! CDBrand
        r.id = id
        r.name = name
        r.v = v
        r.categoryIds = categoryIds
        
        if (m.saveSave() == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll(m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDBrand")
        fetchRequest.includesPropertyValues = false
        
        do {
            let r = try m.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            if let results = r
            {
                for result in results {
                    m.deleteObject(result)
                }
                
                if (m.saveSave() == true) {
                    print("deleteAll CDBrand success")
                }
            }
        } catch {
            return false
        }
        return true
    }
    
    static func getBrandCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDBrand")
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.executeFetchRequest(fetchReq);
            return r.count
        } catch {
            return 0
        }
    }
    
    static func getBrandNameWithID(id : String) -> String? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDBrand")
        fetchReq.predicate = predicate
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.executeFetchRequest(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDBrand).name
        } catch {
            return nil
        }
    }
    
    static func getBrandPickerItems() -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var brands = [CDBrand]()
        
        let fetchReq = NSFetchRequest(entityName: "CDBrand")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        
        var arr : [String] = []
        
        do {
            brands = try (m.executeFetchRequest(fetchReq) as? [CDBrand])!
            
            for brand in brands {
                arr.append(brand.name + PickerViewController.TAG_START_HIDDEN + brand.id + PickerViewController.TAG_END_HIDDEN)
            }
        } catch {
            
        }
        return arr
    }
}