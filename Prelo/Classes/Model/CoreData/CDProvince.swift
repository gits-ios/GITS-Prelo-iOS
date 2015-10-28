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
    
    static func saveProvinceRegions(json : JSON) {
        let m = UIApplication.appDelegate.managedObjectContext
        for (var i = 0; i < json.count; i++) {
            let provJson = json[i]
            let p = NSEntityDescription.insertNewObjectForEntityForName("CDProvince", inManagedObjectContext: m!) as! CDProvince
            p.id = provJson["_id"].string!
            p.name = provJson["name"].string!
            for (var j = 0; j < provJson["regions"].count; j++) {
                let regJson = provJson["regions"][j]
                let r : CDRegion = CDRegion.newOne(regJson["_id"].string!, name: regJson["name"].string!, province: p)!
                p.regions.addObject(r)
                println("Region: \(r.name) added to province: \(p.name)")
            }
        }
        
        var err : NSError?
        if ((m?.save(&err))! == false) {
            println("saveProvinceRegions failed")
        } else {
            println("saveProvinceRegions success")
        }
    }
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CDProvince")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m?.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m?.deleteObject(result)
            }
            
            var error : NSError?
            if (m?.save(&error) != nil) {
                println("deleteAll CDProvince success")
            } else if let error = error {
                println("deleteAll CDProvince failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            println("deleteAll CDProvince failed with fetch error : \(error)")
            return false
        }
        return true
    }
    
    static func getProvincePickerItems() -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var provinces = [CDProvince]()
        
        var err : NSError?
        let fetchReq = NSFetchRequest(entityName: "CDProvince")
        provinces = (m?.executeFetchRequest(fetchReq, error: &err) as? [CDProvince])!
        
        var arr : [String] = []
        for province in provinces {
            arr.append(province.name + PickerViewController.TAG_START_HIDDEN + province.id + PickerViewController.TAG_END_HIDDEN)
        }
        return arr
    }
    
    static func getProvinceNameWithID(id : String) -> String? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDProvince")
        fetchReq.predicate = predicate
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err)
        if (err != nil || r?.count == 0) {
            return nil
        } else {
            return (r!.first as! CDProvince).name
        }
    }
    
    static func getProvinceCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDProvince")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err);
        if (err != nil || r == nil) {
            return 0
        } else {
            return r!.count
        }
    }
}
