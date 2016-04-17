//
//  CDShipping.swift
//  Prelo
//
//  Created by Fransiska on 10/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDShipping)
class CDShipping: NSManagedObject {
    
    @NSManaged var id : String
    @NSManaged var name : String
    @NSManaged var packageId : String
    @NSManaged var packageName : String
    
    static func saveShippings(json : JSON, m : NSManagedObjectContext) -> Bool{
        for (var i = 0; i < json.count; i++) {
            let shipJson = json[i]
            for (var j = 0; j < shipJson["shipping_packages"].count; j++) {
                let packJson = shipJson["shipping_packages"][j]
                let r = NSEntityDescription.insertNewObjectForEntityForName("CDShipping", inManagedObjectContext: m) as! CDShipping
                r.id = shipJson["_id"].string!
                r.name = shipJson["name"].string!
                r.packageId = packJson["_id"].string!
                r.packageName = packJson["name"].string!
            }
        }
        var err : NSError?
        if (m.save(&err) == false) {
            print("saveShippings failed")
            return false
        }
        print("saveShippings success")
        return true
    }
    
    static func newOne(id : String, name : String, packageId : String, packageName : String) -> CDShipping? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObjectForEntityForName("CDShipping", inManagedObjectContext: m!) as! CDShipping
        r.id = id
        r.name = name
        r.packageId = packageId
        r.packageName = packageName
        var err : NSError?
        if (m?.saveSave() == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll(m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDShipping")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m.deleteObject(result)
            }
            
            var error : NSError?
            if (m.save(&error) == true) {
                print("deleteAll CDShipping success")
            } else if let error = error {
                print("deleteAll CDShipping failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            print("deleteAll CDShipping failed with fetch error : \(error)")
            return false
        }
        return true
    }
    
    static func getShippingCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDShipping")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err);
        if (err != nil || r == nil) {
            return 0
        } else {
            return r!.count
        }
    }
    
    static func getShippingCompleteNameWithId(id : String) -> String? {
        let predicate = NSPredicate(format: "packageId like[c] %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDShipping")
        fetchReq.predicate = predicate
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err)
        if (err != nil || r?.count == 0) {
            return nil
        } else {
            let s = r!.first as! CDShipping
            return "\(s.name) \(s.packageName)"
        }
    }
}