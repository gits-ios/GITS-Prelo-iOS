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
    
    static func saveShippings(json : JSON, m : NSManagedObjectContext) -> Bool {
        for i in 0 ..< json.count {
            let shipJson = json[i]
            for j in 0 ..< shipJson["shipping_packages"].count {
                let packJson = shipJson["shipping_packages"][j]
                let r = NSEntityDescription.insertNewObjectForEntityForName("CDShipping", inManagedObjectContext: m) as! CDShipping
                r.id = shipJson["_id"].string!
                r.name = shipJson["name"].string!
                r.packageId = packJson["_id"].string!
                r.packageName = packJson["name"].string!
            }
        }
        if (m.saveSave() == false) {
            print("saveShippings failed")
            return false
        } else {
            print("saveShippings success")
            return true
        }
    }
    
    static func newOne(id : String, name : String, packageId : String, packageName : String) -> CDShipping? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObjectForEntityForName("CDShipping", inManagedObjectContext: m) as! CDShipping
        r.id = id
        r.name = name
        r.packageId = packageId
        r.packageName = packageName
        if (m.saveSave() == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll(m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDShipping")
        fetchRequest.includesPropertyValues = false
        
        guard let results = m.tryExecuteFetchRequest(fetchRequest) else {
            print("deleteAll CDShipping failed")
            return false
        }
        for result in results {
            m.deleteObject(result)
        }
        if (m.saveSave() == false) {
            print("deleteAll CDShipping failed")
            return false
        } else {
            print("deleteAll CDShipping success")
            return true
        }
    }
    
    static func getShippingCount() -> Int {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchReq = NSFetchRequest(entityName: "CDShipping")
        guard let r = m.tryExecuteFetchRequest(fetchReq) else {
            return 0
        }
        return r.count
    }
    
    static func getShippingCompleteNameWithId(id : String) -> String? {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "packageId like[c] %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDShipping")
        fetchReq.predicate = predicate
        guard let r = m.tryExecuteFetchRequest(fetchReq) else {
            return nil
        }
        let s = r.first as! CDShipping
        return "\(s.name) \(s.packageName)"
    }
}