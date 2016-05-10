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
        let r = NSEntityDescription.insertNewObjectForEntityForName("CDRegion", inManagedObjectContext: m) as! CDRegion
        r.id = id
        r.name = name
        r.province = province
        if (m.saveSave() == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll(m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDRegion")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.executeFetchRequest(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.deleteObject(result)
                }
                
                if (m.saveSave() == true) {
                    print("deleteAll CDRegion success")
                }
            }
        } catch {
            return false
        }
        return true
    }
    
    static func getRegionPickerItems(provID : String) -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var regions = [CDRegion]()
        
        let fetchReq = NSFetchRequest(entityName: "CDRegion")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        var arr : [String] = []
        
        do {
            regions = try (m.executeFetchRequest(fetchReq) as? [CDRegion])!
            for region in regions {
                if (region.province.id == provID) {
                    arr.append(region.name + PickerViewController.TAG_START_HIDDEN + region.id + PickerViewController.TAG_END_HIDDEN)
                }
            }
        } catch {
            
        }
        return arr
    }
    
    static func getRegionNameWithID(id : String) -> String? {
        let predicate = NSPredicate(format: "id like[c] %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDRegion")
        fetchReq.predicate = predicate
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.executeFetchRequest(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDRegion).name
        } catch {
            return nil
        }
    }
}