//
//  CDProvince.swift
//  Prelo
//
//  Created by Fransiska on 9/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDProvince)
class CDProvince : NSManagedObject {
    
    @NSManaged var id : String
    @NSManaged var name : String
    @NSManaged var regions : NSMutableSet
    
    static func saveProvinceRegions(json : JSON, m : NSManagedObjectContext) -> Bool {
        for i in 0 ..< json.count {
            let provJson = json[i]
            let p = NSEntityDescription.insertNewObjectForEntityForName("CDProvince", inManagedObjectContext: m) as! CDProvince
            p.id = provJson["_id"].string!
            p.name = provJson["name"].string!
            //print("Province \(p.name) added")
            for j in 0 ..< provJson["regions"].count {
                let regJson = provJson["regions"][j]
                let r = NSEntityDescription.insertNewObjectForEntityForName("CDRegion", inManagedObjectContext: m) as! CDRegion
                r.id = regJson["_id"].string!
                r.name = regJson["name"].string!
                r.province = p
                p.regions.addObject(r)
                //print("Region: \(r.name) added to province: \(p.name)")
            }
        }
        
        if (m.saveSave() == false) {
            print("saveProvinceRegions failed")
            return false
        }
        print("saveProvinceRegions success")
        return true
    }
    
    static func deleteAll(m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDProvince")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.executeFetchRequest(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.deleteObject(result)
                }
                
                if (m.saveSave() == true) {
                    print("deleteAll CDProvince success")
                } else {
                    print("deleteAll CDProvince failed")
                    return false
                }
            }
        } catch {
            return false
        }
        
        
        return true
    }
    
    static func getProvincePickerItems() -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var provinces = [CDProvince]()
        
        let fetchReq = NSFetchRequest(entityName: "CDProvince")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        var arr : [String] = []
        
        do {
            provinces = try (m.executeFetchRequest(fetchReq) as? [CDProvince])!
            for province in provinces {
                arr.append(province.name + PickerViewController.TAG_START_HIDDEN + province.id + PickerViewController.TAG_END_HIDDEN)
            }
        } catch {
            
        }
        return arr
    }
    
    static func getProvinceNameWithID(id : String) -> String? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDProvince")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.executeFetchRequest(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDProvince).name
        } catch {
            return nil
        }
    }
    
    static func getProvinceCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDProvince")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.executeFetchRequest(fetchReq)
            return r.count
        } catch {
            return 0
        }
    }
}
