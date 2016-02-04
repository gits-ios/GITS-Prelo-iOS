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
        let brandCount : Int = json.count
        var isUpdateProgressView : Bool = false
        var progressPerBrand : Float?
        if (p != nil && pView != nil) {
            isUpdateProgressView = true
            progressPerBrand = p! / Float(brandCount)
        }
        for (var i = 0; i < brandCount; i++) {
            let brandJson = json[i]
            var catIds : [String] = []
            for (var j = 0; j < brandJson["category_ids"].count; j++) {
                catIds.append(brandJson["category_ids"][j].string!)
            }
            let r = NSEntityDescription.insertNewObjectForEntityForName("CDBrand", inManagedObjectContext: m) as! CDBrand
            r.id = brandJson["_id"].string!
            r.name = brandJson["name"].string!
            r.v = brandJson["__v"].number!
            r.categoryIds = NSKeyedArchiver.archivedDataWithRootObject(catIds)
            if (isUpdateProgressView) {
                dispatch_async(dispatch_get_main_queue(), {
                    pView!.setProgress(pView!.progress + progressPerBrand!, animated: true)
                })
            }
        }
        var err : NSError?
        if (m.save(&err) == false) {
            println("saveBrands failed")
            return false
        }
        println("saveBrands success")
        return true
    }
    
    static func newOne(id : String, name : String, v : NSNumber, categoryIds: NSData) -> CDBrand? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObjectForEntityForName("CDBrand", inManagedObjectContext: m!) as! CDBrand
        r.id = id
        r.name = name
        r.v = v
        r.categoryIds = categoryIds
        var err : NSError?
        if ((m?.save(&err))! == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll(m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDBrand")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m.deleteObject(result)
            }
            
            var error : NSError?
            if (m.save(&error) == true) {
                println("deleteAll CDBrand success")
            } else if let error = error {
                println("deleteAll CDBrand failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            println("deleteAll CDBrand failed with fetch error : \(error)")
            return false
        }
        return true
    }
    
    static func getBrandCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDBrand")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err);
        if (err != nil || r == nil) {
            return 0
        } else {
            return r!.count
        }
    }
    
    static func getBrandNameWithID(id : String) -> String? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDBrand")
        fetchReq.predicate = predicate
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err)
        if (err != nil || r?.count == 0) {
            return nil
        } else {
            return (r!.first as! CDBrand).name
        }
    }
}