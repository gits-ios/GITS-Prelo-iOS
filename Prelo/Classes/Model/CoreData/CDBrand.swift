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
    @NSManaged var categoryIds : Data
    
    static func saveBrands(_ json : JSON, m : NSManagedObjectContext, pView : UIProgressView?, p : Float?) -> Bool {
        // Kalo (p != nil) artinya ada progress view yang dihandle
        // Kalo (p == nil) artinya tidak ada progress view yang dihandle
        // Kalo (pView != nil) artinya progress view dihandle fungsi ini
        // Kalo (pView == nil) artinya progress view dihandle appdelegate
        let brandCount : Int = json.count
        if (brandCount > 0) {
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
                let r = NSEntityDescription.insertNewObject(forEntityName: "CDBrand", into: m) as! CDBrand
                r.id = brandJson["_id"].string!
                r.name = brandJson["name"].string!
                r.v = brandJson["__v"].number!
                r.categoryIds = NSKeyedArchiver.archivedData(withRootObject: catIds)
                if (isUpdateProgressView) {
                    if (pView != nil) {
                        DispatchQueue.main.async(execute: {
                            pView!.setProgress(pView!.progress + progressPerBrand!, animated: true)
                        })
                    } else {
                        /* TO BE DELETED, untuk load app data cara lama
                        UIApplication.appDelegate.increaseLoadAppDataProgressBy(progressPerBrand!)
                        UIApplication.appDelegate.loadAppDataDelegate?.updateProgress(UIApplication.appDelegate.loadAppDataProgress)
                         */
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
        print("saveBrands failed, no brand at all")
        return false
    }
    
    static func newOne(_ id : String, name : String, v : NSNumber, categoryIds: Data) -> CDBrand? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObject(forEntityName: "CDBrand", into: m) as! CDBrand
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
    
    static func deleteAll(_ m : NSManagedObjectContext) -> Bool {
        let fetchRequest : NSFetchRequest<CDBrand> = CDBrand.fetchRequest()
        fetchRequest.includesPropertyValues = false
        
        do {
            let r = try m.fetch(fetchRequest) as? [NSManagedObject]
            if let results = r
            {
                for result in results {
                    m.delete(result)
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
        let fetchReq : NSFetchRequest<CDBrand> = CDBrand.fetchRequest()
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq);
            return r.count
        } catch {
            return 0
        }
    }
    
    static func getBrandNameWithID(_ id : String) -> String? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq : NSFetchRequest<CDBrand> = CDBrand.fetchRequest()
        fetchReq.predicate = predicate
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDBrand).name
        } catch {
            return nil
        }
    }
    
    static func getBrandPickerItems() -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var brands = [CDBrand]()
        
        let fetchReq : NSFetchRequest<CDBrand> = CDBrand.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        
        var arr : [String] = []
        
        do {
            brands = try (m.fetch(fetchReq) as? [CDBrand])!
            
            for brand in brands {
                arr.append(brand.name + PickerViewController.TAG_START_HIDDEN + brand.id + PickerViewController.TAG_END_HIDDEN)
            }
        } catch {
            
        }
        return arr
    }
}
