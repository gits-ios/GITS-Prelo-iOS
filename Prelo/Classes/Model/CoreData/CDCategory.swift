//
//  CDCategory.swift
//  Prelo
//
//  Created by Fransiska on 10/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDCategory)
class CDCategory: NSManagedObject {
    
    @NSManaged var id : String
    @NSManaged var name : String
    @NSManaged var permalink : String
    @NSManaged var order : NSNumber
    @NSManaged var level : NSNumber
    @NSManaged var isParent : Bool
    @NSManaged var imageName : String
    @NSManaged var categorySizeId : String?
    @NSManaged var parent : CDCategory?
    @NSManaged var children : NSMutableSet
    
    static func saveCategories(json : JSON, m : NSManagedObjectContext) -> Bool {
        // Mulai dari category all, tidak perlu loop
        let allJson = json[0]
        let a = NSEntityDescription.insertNewObjectForEntityForName("CDCategory", inManagedObjectContext: m) as! CDCategory
        a.id = allJson["_id"].string!
        a.name = allJson["name"].string!
        a.permalink = allJson["permalink"].string!
        a.order = allJson["order"].number!
        a.level = allJson["level"].number!
        a.isParent = allJson["is_parent"].bool!
        a.imageName = allJson["image_name"].string!
        a.categorySizeId = nil
        a.parent = nil
        self.saveCategoryChildren(a, json: allJson["children"])
        
        if (m.saveSave() == false) {
            print("saveCategories failed")
            return false
        }
        print("saveCategories success")
        return true
    }
    
    static func saveCategoryChildren(parent : CDCategory, json : JSON) {
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0 ..< json.count {
            let childJson = json[i]
            let c = NSEntityDescription.insertNewObjectForEntityForName("CDCategory", inManagedObjectContext: m) as! CDCategory
            //print("a CDCategory created")
            c.id = childJson["_id"].string!
            c.name = childJson["name"].string!
            c.permalink = childJson["permalink"].string!
            c.order = childJson["order"].number!
            c.level = childJson["level"].number!
            c.isParent = childJson["is_parent"].bool!
            c.imageName = childJson["image_name"].string!
            c.categorySizeId = childJson["category_size_id"].string
            parent.children.addObject(c)
            self.saveCategoryChildren(c, json: childJson["children"])
        }
    }
    
    static func deleteAll(m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDCategory")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.executeFetchRequest(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.deleteObject(result)
                }
                
                
                if (m.saveSave() == true) {
                    print("deleteAll CDCategory success")
                } else {
                    print("deleteAll CDCategory failed with error")
                    return false
                }
            }
        } catch {
            return false
        }
        return true
    }
    
    static func getCategoryCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDCategory")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.executeFetchRequest(fetchReq);
            return r.count
        } catch {
            return 0
        }
    }
    
    static func getCategoriesInLevel(level : NSNumber) -> [CDCategory] {
        let predicate = NSPredicate(format: "level == %@", level)
        let fetchReq = NSFetchRequest(entityName: "CDCategory")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.executeFetchRequest(fetchReq)
            return r as! [CDCategory]
        } catch {
            return []
        }
    }
    
    static func getCategoryNameWithID(id : String) -> String? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDCategory")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.executeFetchRequest(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDCategory).name
        } catch {
            return nil
        }
    }
}