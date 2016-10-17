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
    @NSManaged var typeSizes : Data
    
    static func saveCategorySizes(_ json : JSON, m : NSManagedObjectContext) -> Bool {
        for i in 0 ..< json.count {
            let catJson = json[i]
            for j in 0 ..< catJson["size_types"].count {
                let typeJson = catJson["size_types"][j]
                var sizes : [String] = []
                for k in 0 ..< typeJson["sizes"].count {
                    sizes.append(typeJson["sizes"][k].string!)
                }
                let r = NSEntityDescription.insertNewObject(forEntityName: "CDCategorySize", into: m) as! CDCategorySize
                r.id = catJson["_id"].string!
                r.name = catJson["name"].string!
                r.v = catJson["__v"].number!
                r.typeOrder = typeJson["order"].number!
                r.typeName = typeJson["name"].string!
                r.typeSizes = NSKeyedArchiver.archivedData(withRootObject: sizes)
            }
        }
        
        if (m.saveSave() == false) {
            print("saveCategorySizes failed")
            return false
        }
        print("saveCategorySizes success")
        return true
    }
    
    static func newOne(_ id : String, name : String, v : NSNumber, typeOrder : NSNumber, typeName : String, typeSizes : Data) -> CDCategorySize? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObject(forEntityName: "CDCategorySize", into: m) as! CDCategorySize
        r.id = id
        r.name = name
        r.v = v
        r.typeOrder = typeOrder
        r.typeName = typeName
        r.typeSizes = typeSizes
        
        if (m.saveSave() == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll(_ m : NSManagedObjectContext) -> Bool {
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDCategorySize")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.fetch(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.delete(result)
                }
                
                if (m.saveSave() == true) {
                    print("deleteAll CDCategorySize success")
                } else {
                    print("deleteAll CDCategorySize failed")
                    return false
                }
            }
        } catch {
            return false
        }
        return true
    }
    
    static func getCategorySizeCount() -> Int {
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDCategorySize")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq);
            return r.count
        } catch {
            return 0
        }
    }
}
