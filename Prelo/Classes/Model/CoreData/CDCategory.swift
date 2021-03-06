//
//  CDCategory.swift
//  Prelo
//
//  Created by Fransiska on 10/27/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
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
    @NSManaged var parentId : String?
    @NSManaged var parent : CDCategory?
    @NSManaged var children : NSMutableSet
    @NSManaged var hashtags : String?
    
    static func saveCategoriesFromArrayJson(_ arr: [JSON]) -> Bool {
        
        if (arr.count <= 0) {
            return true
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let n = NSEntityDescription.insertNewObject(forEntityName: "CDCategory", into: m) as! CDCategory
            let categ = arr[i]
            n.id = categ["_id"].stringValue
            n.name = categ["name"].stringValue
            n.permalink = categ["permalink"].stringValue
            n.order = categ["order"].numberValue
            n.level = categ["level"].numberValue
            n.isParent = categ["is_parent"].boolValue
            n.imageName = categ["image_name"].stringValue
            n.categorySizeId = categ["category_size_id"].string
            n.parentId = categ["parent"].string
            if let h = categ["hashtags"].string {
                n.hashtags = h
            }
        }
        
        if (m.saveSave() == false) {
            //print("saveCategoriesFromArrayJson failed")
            return false
        } else {
            //print("saveCategoriesFromArrayJson success")
            return true
        }
    }
    
    static func updateCategoriesFromArrayJson(_ arr : [JSON]) -> Bool {
        var isSuccess = true
        
        if (arr.count <= 0) {
            return isSuccess
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let predicate = NSPredicate(format: "id == %@", arr[i]["_id"].stringValue)
            let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDCategory")
            fetchReq.predicate = predicate
            do {
                if let results = try m.fetch(fetchReq) as? [CDCategory] {
                    for result in results {
                        result.name = arr[i]["name"].stringValue
                        result.permalink = arr[i]["permalink"].stringValue
                        result.order = arr[i]["order"].numberValue
                        result.level = arr[i]["level"].numberValue
                        result.isParent = arr[i]["is_parent"].boolValue
                        result.imageName = arr[i]["image_name"].stringValue
                        result.categorySizeId = arr[i]["category_size_id"].string
                        result.parentId = arr[i]["parent"].string
                        if let h = arr[i]["hashtags"].string {
                            result.hashtags = h
                        }
                    }
                }
            } catch {
                isSuccess = false
            }
        }
        if (m.saveSave() == true) {
            //print("updateCategoriesFromArrayJson success")
        } else {
            isSuccess = false
            //print("updateCategoriesFromArrayJson failed")
        }
        return isSuccess
    }
    
    static func deleteCategoriesFromArrayJson(_ arr : [JSON]) -> Bool {
        var isSuccess = true
        
        if (arr.count <= 0) {
            return isSuccess
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let predicate = NSPredicate(format: "id == %@", arr[i]["_id"].stringValue)
            let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDCategory")
            fetchReq.predicate = predicate
            do {
                if let results = try m.fetch(fetchReq) as? [NSManagedObject] {
                    for result in results {
                        m.delete(result)
                    }
                }
            } catch {
                isSuccess = false
            }
        }
        
        if (m.saveSave() == true) {
            //print("deleteCategoriesFromArrayJson success")
        } else {
            isSuccess = false
            //print("deleteCategoriesFromArrayJson failed")
        }
        return isSuccess
    }
    
    static func saveCategories(_ json : JSON, m : NSManagedObjectContext) -> Bool {
        // Mulai dari category all, tidak perlu loop
        let allJson = json[0]
        let a = NSEntityDescription.insertNewObject(forEntityName: "CDCategory", into: m) as! CDCategory
        a.id = allJson["_id"].string!
        a.name = allJson["name"].string!
        a.permalink = allJson["permalink"].string!
        a.order = allJson["order"].number!
        a.level = allJson["level"].number!
        a.isParent = allJson["is_parent"].bool!
        a.imageName = allJson["image_name"].string!
        a.categorySizeId = nil
        a.parent = nil
        a.hashtags = nil
        self.saveCategoryChildren(a, json: allJson["children"])
        
        if (m.saveSave() == false) {
            //print("saveCategories failed")
            return false
        }
        //print("saveCategories success")
        return true
    }
    
    static func saveCategoryChildren(_ parent : CDCategory, json : JSON) {
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0 ..< json.count {
            let childJson = json[i]
            let c = NSEntityDescription.insertNewObject(forEntityName: "CDCategory", into: m) as! CDCategory
            ////print("a CDCategory created")
            c.id = childJson["_id"].string!
            c.name = childJson["name"].string!
            c.permalink = childJson["permalink"].string!
            c.order = childJson["order"].number!
            c.level = childJson["level"].number!
            c.isParent = childJson["is_parent"].bool!
            c.imageName = childJson["image_name"].string!
            c.categorySizeId = childJson["category_size_id"].string
            c.parentId = childJson["parent"].string
            if let h = childJson["hashtags"].string {
                c.hashtags = h
            }
            parent.children.add(c)
            self.saveCategoryChildren(c, json: childJson["children"])
        }
    }
    
    static func deleteAll(_ m : NSManagedObjectContext) -> Bool {
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDCategory")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.fetch(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.delete(result)
                }
                
                
                if (m.saveSave() == true) {
                    //print("deleteAll CDCategory success")
                } else {
                    //print("deleteAll CDCategory failed with error")
                    return false
                }
            }
        } catch {
            return false
        }
        return true
    }
    
    static func getCategoryCount() -> Int {
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDCategory")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq);
            return r.count
        } catch {
            return 0
        }
    }
    
    static func getCategoriesInLevel(_ level : NSNumber) -> [CDCategory] {
        let predicate = NSPredicate(format: "level == %@", level)
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDCategory")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r as! [CDCategory]
        } catch {
            return []
        }
    }
    
    static func getCategoryWithID(_ id : String) -> CDCategory? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDCategory")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDCategory)
        } catch {
            return nil
        }
    }
    
    static func getCategoryNameWithID(_ id : String) -> String? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDCategory")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDCategory).name
        } catch {
            return nil
        }
    }
    
    static func getCategoryHashtagsWithID(_ id : String) -> String? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDCategory")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDCategory).hashtags
        } catch {
            return nil
        }
    }
    
    static func getLv1CategIDFromID(_ id : String) -> String? {
        if var categ = CDCategory.getCategoryWithID(id) {
            if (categ.level.int32Value > 1) {
                var parentId : String? = nil
                for _ in 1..<categ.level.int32Value {
                    if (categ.parentId != nil) {
                        if let p = CDCategory.getCategoryWithID(categ.parentId!) {
                            categ = p
                            parentId = p.id
                        } else {
                            parentId = nil
                            break
                        }
                    }
                }
                return parentId
            }
        }
        return nil
    }
    
    static func getParent(_ id : String) -> CDCategory? {
        if let categ = CDCategory.getCategoryWithID(id) {
            
            //print(categ.description)
            
            if categ.parentId != nil && categ.parentId != "55de6d4e9ffd40362ae310a7", let parent = CDCategory.getCategoryWithID(categ.parentId!) {
                return parent
            }
            return nil
        }
        return nil
    }
}
