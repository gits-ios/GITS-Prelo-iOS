//
//  CDCategorySize.swift
//  Prelo
//
//  Created by Fransiska on 10/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDCategorySize)
class CDCategorySize: NSManagedObject {
    
    @NSManaged var id : String
    @NSManaged var name : String
    @NSManaged var v : NSNumber
    @NSManaged var typeOrder : NSNumber
    @NSManaged var typeName : String
    @NSManaged var typeSizes : NSData
    
    static func saveCategorySizes(json : JSON, m : NSManagedObjectContext) -> Bool {
        for (var i = 0; i < json.count; i++) {
            let catJson = json[i]
            for (var j = 0; j < catJson["size_types"].count; j++) {
                let typeJson = catJson["size_types"][j]
                var sizes : [String] = []
                for (var k = 0; k < typeJson["sizes"].count; k++) {
                    sizes.append(typeJson["sizes"][k].string!)
                }
                let r = NSEntityDescription.insertNewObjectForEntityForName("CDCategorySize", inManagedObjectContext: m) as! CDCategorySize
                r.id = catJson["_id"].string!
                r.name = catJson["name"].string!
                r.v = catJson["__v"].number!
                r.typeOrder = typeJson["order"].number!
                r.typeName = typeJson["name"].string!
                r.typeSizes = NSKeyedArchiver.archivedDataWithRootObject(sizes)
            }
        }
        var err : NSError?
        if (m.save(&err) == false) {
            println("saveCategorySizes failed")
            return false
        }
        println("saveCategorySizes success")
        return true
    }
    
    static func newOne(id : String, name : String, v : NSNumber, typeOrder : NSNumber, typeName : String, typeSizes : NSData) -> CDCategorySize? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObjectForEntityForName("CDCategorySize", inManagedObjectContext: m!) as! CDCategorySize
        r.id = id
        r.name = name
        r.v = v
        r.typeOrder = typeOrder
        r.typeName = typeName
        r.typeSizes = typeSizes
        var err : NSError?
        if ((m?.save(&err))! == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll(m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDCategorySize")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m.deleteObject(result)
            }
            
            var error : NSError?
            if (m.save(&error) == true) {
                println("deleteAll CDCategorySize success")
            } else if let error = error {
                println("deleteAll CDCategorySize failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            println("deleteAll CDCategorySize failed with fetch error : \(error)")
            return false
        }
        return true
    }
    
    static func getCategorySizeCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDCategorySize")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err);
        if (err != nil || r == nil) {
            return 0
        } else {
            return r!.count
        }
    }
}