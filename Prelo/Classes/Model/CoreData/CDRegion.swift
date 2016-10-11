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
    @NSManaged var provinceId : String
    @NSManaged var idRajaOngkir : String
    @NSManaged var postalCode : String
    
    static func saveRegionsFromArrayJson(_ arr: [JSON]) -> Bool {
        
        if (arr.count <= 0) {
            return true
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let n = NSEntityDescription.insertNewObject(forEntityName: "CDRegion", into: m) as! CDRegion
            let reg = arr[i]
            n.id = reg["_id"].stringValue
            n.name = reg["name"].stringValue
            n.provinceId = reg["province_id"].stringValue
            n.idRajaOngkir = reg["id_rajaongkir"].stringValue
            n.postalCode = reg["postal_code"].stringValue
        }
        
        if (m.saveSave() == false) {
            print("saveRegionsFromArrayJson failed")
            return false
        } else {
            print("saveRegionsFromArrayJson success")
            return true
        }
    }
    
    static func updateRegionsFromArrayJson(_ arr : [JSON]) -> Bool {
        var isSuccess = true
        
        if (arr.count <= 0) {
            return isSuccess
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let predicate = NSPredicate(format: "id == %@", arr[i]["_id"].stringValue)
            let fetchReq = NSFetchRequest(entityName: "CDRegion")
            fetchReq.predicate = predicate
            do {
                if let results = try m.fetch(fetchReq) as? [CDRegion] {
                    for result in results {
                        result.name = arr[i]["name"].stringValue
                        result.provinceId = arr[i]["province_id"].stringValue
                        result.idRajaOngkir = arr[i]["id_rajaongkir"].stringValue
                        result.postalCode = arr[i]["postal_code"].stringValue
                    }
                }
            } catch {
                isSuccess = false
            }
        }
        if (m.saveSave() == true) {
            print("updateRegionsFromArrayJson success")
        } else {
            isSuccess = false
            print("updateRegionsFromArrayJson failed")
        }
        return isSuccess
    }
    
    static func deleteRegionsFromArrayJson(_ arr : [JSON]) -> Bool {
        var isSuccess = true
        
        if (arr.count <= 0) {
            return isSuccess
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let predicate = NSPredicate(format: "id == %@", arr[i]["_id"].stringValue)
            let fetchReq = NSFetchRequest(entityName: "CDRegion")
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
            print("deleteRegionsFromArrayJson success")
        } else {
            isSuccess = false
            print("deleteRegionsFromArrayJson failed")
        }
        return isSuccess
    }
    
    static func newOne(_ id : String, name : String, province : CDProvince) -> CDRegion? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObject(forEntityName: "CDRegion", into: m) as! CDRegion
        r.id = id
        r.name = name
        //r.province = province
        if (m.saveSave() == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll(_ m : NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "CDRegion")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.fetch(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.delete(result)
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
    
    static func getRegionPickerItems(_ provID : String) -> [String] {
        let m = UIApplication.appDelegate.managedObjectContext
        var regions = [CDRegion]()
        
        let fetchReq = NSFetchRequest(entityName: "CDRegion")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        var arr : [String] = []
        
        do {
            regions = try (m.fetch(fetchReq) as? [CDRegion])!
            for region in regions {
                if (region.provinceId == provID) {
                    arr.append(region.name + PickerViewController.TAG_START_HIDDEN + region.id + PickerViewController.TAG_END_HIDDEN)
                }
            }
        } catch {
            
        }
        return arr
    }
    
    static func getRegionNameWithID(_ id : String) -> String? {
        let predicate = NSPredicate(format: "id like[c] %@", id)
        let fetchReq = NSFetchRequest(entityName: "CDRegion")
        fetchReq.predicate = predicate
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDRegion).name
        } catch {
            return nil
        }
    }
}
