//
//  CDProvince.swift
//  Prelo
//
//  Created by Fransiska on 9/11/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDProvince)
class CDProvince : NSManagedObject {
    
    @NSManaged var id : String
    @NSManaged var name : String
    @NSManaged var regions : NSMutableSet

    static func saveProvincesFromArrayJson(_ arr: [JSON]) -> Bool {
        
        if (arr.count <= 0) {
            return true
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let n = NSEntityDescription.insertNewObject(forEntityName: "CDProvince", into: m) as! CDProvince
            let prov = arr[i]
            n.id = prov["_id"].stringValue
            n.name = prov["name"].stringValue
            n.regions = NSMutableSet()
        }
        
        if (m.saveSave() == false) {
            //print("saveProvincesFromArrayJson failed")
            return false
        } else {
            //print("saveProvincesFromArrayJson success")
            return true
        }
    }

    static func updateProvincesFromArrayJson(_ arr: [JSON]) -> Bool {
        var isSuccess = true
        
        if (arr.count <= 0) {
            return isSuccess
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let predicate = NSPredicate(format: "id == %@", arr[i]["_id"].stringValue)
            let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDProvince")
            fetchReq.predicate = predicate
            do {
                if let results = try m.fetch(fetchReq) as? [CDProvince] {
                    for result in results {
                        result.name = arr[i]["name"].stringValue
                    }
                }
            } catch {
                isSuccess = false
            }
        }
        if (m.saveSave() == true) {
            //print("updateProvincesFromArrayJson success")
        } else {
            isSuccess = false
            //print("updateProvincesFromArrayJson failed")
        }
        return isSuccess
    }

    static func deleteProvincesFromArrayJson(_ arr: [JSON]) -> Bool {
        var isSuccess = true
        
        if (arr.count <= 0) {
            return isSuccess
        }
        
        let m = UIApplication.appDelegate.managedObjectContext
        for i in 0...arr.count - 1 {
            let predicate = NSPredicate(format: "id == %@", arr[i]["_id"].stringValue)
            let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDProvince")
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
            //print("deleteProvincesFromArrayJson success")
        } else {
            isSuccess = false
            //print("deleteProvincesFromArrayJson failed")
        }
        return isSuccess
    }

    static func saveProvinceRegions(_ json : JSON, m : NSManagedObjectContext) -> Bool {
        for i in 0 ..< json.count {
            let provJson = json[i]
            let p = NSEntityDescription.insertNewObject(forEntityName: "CDProvince", into: m) as! CDProvince
            p.id = provJson["_id"].string!
            p.name = provJson["name"].string!
            ////print("Province \(p.name) added")
            for j in 0 ..< provJson["regions"].count {
                let regJson = provJson["regions"][j]
                let r = NSEntityDescription.insertNewObject(forEntityName: "CDRegion", into: m) as! CDRegion
                r.id = regJson["_id"].stringValue
                r.name = regJson["name"].stringValue
                r.provinceId = provJson["_id"].stringValue
                r.idRajaOngkir = regJson["id_rajaongkir"].stringValue
                r.postalCode = regJson["postal_code"].stringValue
                p.regions.add(r)
                ////print("Region: \(r.name) added to province: \(p.name)")
            }
        }
        
        if (m.saveSave() == false) {
            //print("saveProvinceRegions failed")
            return false
        }
        //print("saveProvinceRegions success")
        return true
    }

    static func deleteAll(_ m : NSManagedObjectContext) -> Bool {
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDProvince")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.fetch(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.delete(result)
                }
                
                if (m.saveSave() == true) {
                    //print("deleteAll CDProvince success")
                } else {
                    //print("deleteAll CDProvince failed")
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
        
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDProvince")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchReq.sortDescriptors = sortDescriptors
        var arr : [String] = []
        
        do {
            provinces = try (m.fetch(fetchReq) as? [CDProvince])!
            for province in provinces {
                arr.append(province.name + PickerViewController.TAG_START_HIDDEN + province.id + PickerViewController.TAG_END_HIDDEN)
            }
        } catch {
            
        }
        return arr
    }
    
    static func getProvinceNameWithID(_ id : String) -> String? {
        let predicate = NSPredicate(format: "id == %@", id)
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDProvince")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : (r.first as! CDProvince).name
        } catch {
            return nil
        }
    }

    static func getProvinceCount() -> Int {
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDProvince")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count
        } catch {
            return 0
        }
    }
}
