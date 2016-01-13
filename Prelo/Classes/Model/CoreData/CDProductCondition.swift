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
    
    static func saveProductConditions(json : JSON) {
        let m = UIApplication.appDelegate.managedObjectContext
        for (var i = 0; i < json.count; i++) {
            let condJson = json[i]
            self.newOne(condJson["_id"].string!, name: condJson["name"].string!, detail: condJson["description"].string!, order: condJson["order"].number!)
        }
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
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CDProductCondition")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m?.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m?.deleteObject(result)
            }
            
            var error : NSError?
            if (m?.save(&error) != nil) {
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
}