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
    
    static func saveCategories(json : JSON) {
        let m = UIApplication.appDelegate.managedObjectContext
        
        // Mulai dari category all, tidak perlu loop
        let allJson = json[0]
        let a = NSEntityDescription.insertNewObjectForEntityForName("CDCategory", inManagedObjectContext: m!) as! CDCategory
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
        
        var err : NSError?
        if ((m?.save(&err))! == false) {
            println("saveCategories failed")
        } else {
            println("saveCategories success")
        }
    }
    
    static func saveCategoryChildren(parent : CDCategory, json : JSON) {
        let m = UIApplication.appDelegate.managedObjectContext
        for (var i = 0; i < json.count; i++) {
            let childJson = json[i]
            let c = NSEntityDescription.insertNewObjectForEntityForName("CDCategory", inManagedObjectContext: m!) as! CDCategory
            //println("a CDCategory created")
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
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CDCategory")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m?.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m?.deleteObject(result)
            }
            
            var error : NSError?
            if (m?.save(&error) != nil) {
                println("deleteAll CDCategory success")
            } else if let error = error {
                println("deleteAll CDCategory failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            println("deleteAll CDCategory failed with fetch error : \(error)")
            return false
        }
        return true
    }
    
    static func getCategoryCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDCategory")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err);
        if (err != nil || r == nil) {
            return 0
        } else {
            return r!.count
        }
    }
    
    static func getCategoriesInLevel(level : NSNumber) -> [CDCategory] {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "level == %@", level)
        let fetchReq = NSFetchRequest(entityName: "CDCategory")
        fetchReq.predicate = predicate
        
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err)
        if (err != nil || r == nil || r?.count == 0) {
            return []
        } else {
            return (r as! [CDCategory])
        }
    }
}