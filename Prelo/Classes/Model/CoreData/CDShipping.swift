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
    
    static func saveShippingsFromArrayJson(_ arr: [JSON]) -> Bool {
        
        if (arr.count <= 0) {
            return true
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let n = NSEntityDescription.insertNewObject(forEntityName: "CDShipping", into: m) as! CDShipping
            let ship = arr[i]
            n.id = ship["_id"].stringValue
            n.name = ship["name"].stringValue
            n.packageId = ""
            n.packageName = ""
        }
        
        if (m.saveSave() == false) {
            print("saveShippingsFromArrayJson failed")
            return false
        } else {
            print("saveShippingsFromArrayJson success")
            return true
        }
    }
    
    static func getAll() -> [CDShipping] {
        let fetchReq = NSFetchRequest(entityName: "CDShipping")
        
        do {
            if let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq) as? [CDShipping] {
                return r
            }
            return []
        } catch {
            return []
        }
    }
    
    // Get shipping list where 'pos' is first object and 'tiki' is last object
    static func getPosBlaBlaBlaTiki() -> [CDShipping] {
        let fetchReq = NSFetchRequest(entityName: "CDShipping")
        
        do {
            if var r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq) as? [CDShipping] {
                for i in 0..<r.count {
                    if (r[i].name.lowercased() == "pos") {
                        r.moveObjectFromIndex(i, toIndex: 0)
                    }
                    if (r[i].name.lowercased() == "tiki") {
                        r.moveObjectFromIndex(i, toIndex: r.count - 1)
                    }
                }
                return r
            }
            return []
        } catch {
            return []
        }
    }
    
    static func saveShippings(_ json : JSON, m : NSManagedObjectContext) -> Bool {
        for i in 0 ..< json.count {
            let shipJson = json[i]
            let r = NSEntityDescription.insertNewObject(forEntityName: "CDShipping", into: m) as! CDShipping
            r.id = shipJson["_id"].stringValue
            r.name = shipJson["name"].stringValue
            r.packageId = ""
            r.packageName = ""
        }
        if (m.saveSave() == false) {
            print("saveShippings failed")
            return false
        } else {
            print("saveShippings success")
            return true
        }
    }
    
    static func newOne(_ id : String, name : String, packageId : String, packageName : String) -> CDShipping? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObject(forEntityName: "CDShipping", into: m) as! CDShipping
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
    
    static func deleteAll(_ m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDShipping")
        fetchRequest.includesPropertyValues = false
        
        guard let results = m.tryExecuteFetchRequest(fetchRequest) else {
            print("deleteAll CDShipping failed")
            return false
        }
        for result in results {
            m.delete(result)
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
    
    static func getShippingCompleteNameWithId(_ id : String) -> String? {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "id like[c] %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDShipping")
        fetchReq.predicate = predicate
        guard let r = m.tryExecuteFetchRequest(fetchReq) else {
            return nil
        }
        let s = r.first as! CDShipping
        return "\(s.name)"
    }
}
