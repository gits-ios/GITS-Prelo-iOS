//
//  CDUserProfile.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDUserProfile)
class CDUserProfile: NSManagedObject {

    @NSManaged var address: String?
    @NSManaged var desc: String?
    @NSManaged var gender: String?
    @NSManaged var phone: String?
    @NSManaged var pict: String
    @NSManaged var postalCode: String?
    @NSManaged var regionID: String
    @NSManaged var provinceID: String

    static func getOne() -> CDUserProfile?
    {
        let fetchReq = NSFetchRequest(entityName: "CDUserProfile")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.executeFetchRequest(fetchReq);
            return r.count == 0 ? nil : r.first as? CDUserProfile
        } catch {
            return nil
        }
    }
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CDUserProfile")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.executeFetchRequest(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.deleteObject(result)
                }
                
                if (m.saveSave() != false) {
                    print("deleteAll CDUserProfile success")
                } else {
                    print("deleteAll CDUserProfile failed")
                    return false
                }
            }
        } catch {
            return false
        }
        return true
    }
}
