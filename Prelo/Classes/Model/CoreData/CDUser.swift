//
//  CDUser.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDUser)
class CDUser: NSManagedObject {

    @NSManaged var email: String
    @NSManaged var fullname: String
    @NSManaged var id: String
    @NSManaged var others: CDUserOther
    @NSManaged var profiles: CDUserProfile
    
    static func getOne() -> CDUser?
    {
        let fetchReq = NSFetchRequest(entityName: "CDUser")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err);
        if (err != nil || r?.count == 0) {
            return nil
        } else {
            return r?.first as? CDUser
        }
    }

    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CDUser")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m?.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m?.deleteObject(result)
            }
            
            var error : NSError?
            if (m?.save(&error) != nil) {
                println("deleteAll CDUser success")
            } else if let error = error {
                println("deleteAll CDUser failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            println("deleteAll CDUser failed with fetch error : \(error)")
            return false
        }
        return true
    }
}
