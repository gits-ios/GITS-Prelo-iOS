//
//  CDRegion.swift
//  Prelo
//
//  Created by Fransiska on 9/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDRegion)
class CDRegion : NSManagedObject {
    
    @NSManaged var id : String
    @NSManaged var name : String
    @NSManaged var province : CDProvince
    
    static func newOne(id : String, name : String, province : CDProvince) -> CDRegion? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObjectForEntityForName("CDRegion", inManagedObjectContext: m!) as! CDRegion
        r.id = id
        r.name = name
        r.province = province
        var err : NSError?
        if ((m?.save(&err))! == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CDRegion")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m?.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m?.deleteObject(result)
            }
            
            var error : NSError?
            if (m?.save(&error) != nil) {
                println("deleteAll CDRegion success")
            } else if let error = error {
                println("deleteAll CDRegion failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            println("deleteAll CDRegion failed with fetch error : \(error)")
            return false
        }
        return true
    }
    
    static func getRegionPickerItems(provID : String) -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var regions = [CDRegion]()
        
        var err : NSError?
        let fetchReq = NSFetchRequest(entityName: "CDRegion")
        regions = (m?.executeFetchRequest(fetchReq, error: &err) as? [CDRegion])!
        
        var arr : [String] = []
        for region in regions {
            if (region.province.id == provID) {
                arr.append(region.name + PickerViewController.TAG_START_HIDDEN + region.id + PickerViewController.TAG_END_HIDDEN)
            }
        }
        return arr
    }
    
    static func getRegionNameWithID(id : String) -> String? {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "id like[c] %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDRegion")
        fetchReq.predicate = predicate
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err)
        if (err != nil || r?.count == 0) {
            return nil
        } else {
            return (r!.first as! CDRegion).name
        }
    }
}