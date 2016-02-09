//
//  CDProductCondition.swift
//  Prelo
//
//  Created by Fransiska on 10/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDProductCondition)
class CDProductCondition: NSManagedObject {
    
    @NSManaged var id : String
    @NSManaged var name : String
    @NSManaged var detail : String
    @NSManaged var order : NSNumber
    
    static func saveProductConditions(json : JSON, m : NSManagedObjectContext) -> Bool {
        for (var i = 0; i < json.count; i++) {
            let condJson = json[i]
            let r = NSEntityDescription.insertNewObjectForEntityForName("CDProductCondition", inManagedObjectContext: m) as! CDProductCondition
            r.id = condJson["_id"].string!
            r.name = condJson["name"].string!
            r.detail = condJson["description"].string!
            r.order = condJson["order"].number!
        }
        var err : NSError?
        if (m.save(&err) == false) {
            println("saveProductConditions failed")
            return false
        }
        println("saveProductConditions success")
        return true
    }
    
    static func newOne(id : String, name : String, detail : String, order : NSNumber) -> CDProductCondition? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObjectForEntityForName("CDProductCondition", inManagedObjectContext: m!) as! CDProductCondition
        r.id = id
        r.name = name
        r.detail = detail
        r.order = order
        var err : NSError?
        if ((m?.save(&err))! == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll(m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDProductCondition")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m.deleteObject(result)
            }
            
            var error : NSError?
            if (m.save(&error) == true) {
                println("deleteAll CDProductCondition success")
            } else if let error = error {
                println("deleteAll CDProductCondition failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            println("deleteAll CDProductCondition failed with fetch error : \(error)")
            return false
        }
        return true
    }
    
    static func getProductConditionCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDProductCondition")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err);
        if (err != nil || r == nil) {
            return 0
        } else {
            return r!.count
        }
    }
    
    static func getProductConditionPickerItems() -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var productConditions = [CDProductCondition]()
        
        var err : NSError?
        let fetchReq = NSFetchRequest(entityName: "CDProductCondition")
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        productConditions = (m?.executeFetchRequest(fetchReq, error: &err) as? [CDProductCondition])!
        
        var arr : [String] = []
        for productCondition in productConditions {
            arr.append(productCondition.name + PickerViewController.TAG_START_HIDDEN + productCondition.id + PickerViewController.TAG_END_HIDDEN)
        }
        return arr
    }
    
    static func getProductConditionPickerDetailItems() -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var productConditions = [CDProductCondition]()
        
        var err : NSError?
        let fetchReq = NSFetchRequest(entityName: "CDProductCondition")
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        productConditions = (m?.executeFetchRequest(fetchReq, error: &err) as? [CDProductCondition])!
        
        var arr : [String] = []
        for productCondition in productConditions {
            arr.append(productCondition.detail)
        }
        return arr
    }
}