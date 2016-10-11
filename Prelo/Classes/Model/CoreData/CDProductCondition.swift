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
    
    static func saveProductConditionsFromArrayJson(_ arr: [JSON]) -> Bool {
        
        if (arr.count <= 0) {
            return true
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let n = NSEntityDescription.insertNewObject(forEntityName: "CDProductCondition", into: m) as! CDProductCondition
            let prodCond = arr[i]
            n.id = prodCond["_id"].stringValue
            n.name = prodCond["name"].stringValue
            n.detail = prodCond["description"].stringValue
            n.order = prodCond["order"].numberValue
        }
        
        if (m.saveSave() == false) {
            print("saveProductConditionsFromArrayJson failed")
            return false
        } else {
            print("saveProductConditionsFromArrayJson success")
            return true
        }
    }
    
    static func saveProductConditions(_ json : JSON, m : NSManagedObjectContext) -> Bool {
        for i in 0 ..< json.count {
            let condJson = json[i]
            let r = NSEntityDescription.insertNewObject(forEntityName: "CDProductCondition", into: m) as! CDProductCondition
            r.id = condJson["_id"].string!
            r.name = condJson["name"].string!
            r.detail = condJson["description"].string!
            r.order = condJson["order"].number!
        }
        if (m.saveSave() == false) {
            print("saveProductConditions failed")
            return false
        }
        print("saveProductConditions success")
        return true
    }
    
    static func getProductConditionWithID(_ id : String) -> CDProductCondition? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDProductCondition")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDProductCondition)
        } catch {
            return nil
        }
    }
    
    static func getProductConditionWithName(_ name : String) -> CDProductCondition? {
        let predicate = NSPredicate(format: "name == %@", name)
        let fetchReq = NSFetchRequest(entityName: "CDProductCondition")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDProductCondition)
        } catch {
            return nil
        }
    }
    
    static func newOne(_ id : String, name : String, detail : String, order : NSNumber) -> CDProductCondition? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObject(forEntityName: "CDProductCondition", into: m) as! CDProductCondition
        r.id = id
        r.name = name
        r.detail = detail
        r.order = order
        if (m.saveSave() == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll(_ m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDProductCondition")
        fetchRequest.includesPropertyValues = false
        
        do {
            let r = try m.fetch(fetchRequest) as? [NSManagedObject]
            if let results = r {
                for result in results {
                    m.delete(result)
                }
                
                if (m.saveSave() == true) {
                    print("deleteAll CDProductCondition success")
                }
            } else
            {
                
            }
        } catch {
            print("deleteAll CDProductCondition failed with fetch error : \(error)")
            return false
        }
        return true
    }
    
    static func getProductConditionCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDProductCondition")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq);
            return r.count
        } catch {
            return 0
        }
    }
    
    static func getProductConditionPickerItems() -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var productConditions = [CDProductCondition]()
        
        let fetchReq = NSFetchRequest(entityName: "CDProductCondition")
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        
        var arr : [String] = []
        
        do {
            productConditions = (try m.fetch(fetchReq) as? [CDProductCondition])!
            for productCondition in productConditions {
                arr.append(productCondition.name + PickerViewController.TAG_START_HIDDEN + productCondition.id + PickerViewController.TAG_END_HIDDEN)
            }
        } catch {
            
        }
        return arr
    }
    
    static func getProductConditionPickerDetailItems() -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var productConditions = [CDProductCondition]()
        
        let fetchReq = NSFetchRequest(entityName: "CDProductCondition")
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        
        var arr : [String] = []
        
        do {
            productConditions = (try m.fetch(fetchReq) as? [CDProductCondition])!
            for productCondition in productConditions {
                arr.append(productCondition.detail)
            }
        } catch {
            
        }
        
        return arr
    }
    
    static func getProductConditionNames() -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var productConditions = [CDProductCondition]()
        
        let fetchReq = NSFetchRequest(entityName: "CDProductCondition")
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        
        var arr : [String] = []
        
        do {
            productConditions = (try m.fetch(fetchReq) as? [CDProductCondition])!
            for productCondition in productConditions {
                arr.append(productCondition.name)
            }
        } catch {
            
        }
        return arr
    }
    
    static func getProductConditionIds() -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var productConditions = [CDProductCondition]()
        
        let fetchReq = NSFetchRequest(entityName: "CDProductCondition")
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        
        var arr : [String] = []
        
        do {
            productConditions = (try m.fetch(fetchReq) as? [CDProductCondition])!
            for productCondition in productConditions {
                arr.append(productCondition.id)
            }
        } catch {
            
        }
        return arr
    }
}
