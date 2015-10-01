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
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err);
        if (err != nil || r?.count == 0) {
            return nil
        } else {
            return r?.first as? CDUserProfile
        }
    }
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CDUserProfile")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m?.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m?.deleteObject(result)
            }
            
            var error : NSError?
            if (m?.save(&error) != nil) {
                println("deleteAll CDUserProfile success")
            } else if let error = error {
                println("deleteAll CDUserProfile failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            println("deleteAll CDUserProfile failed with fetch error : \(error)")
            return false
        }
        return true
    }
}
