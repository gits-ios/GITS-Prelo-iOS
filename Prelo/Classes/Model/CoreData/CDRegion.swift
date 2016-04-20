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
        
        guard let results = m.tryExecuteFetchRequest(fetchRequest) else {
            return false
        }
        for result in results {
            m.deleteObject(result)
        }
        if (m.saveSave() == false) {
            print("deleteAll CDRegion failed")
        } else {
            print("deleteAll CDRegion success")
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
        regions = (m.tryExecuteFetchRequest(fetchReq) as? [CDRegion])!
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
        guard let r = m.tryExecuteFetchRequest(fetchReq) else {
            return nil
        }
        return (r.first as! CDRegion).name
    }
}