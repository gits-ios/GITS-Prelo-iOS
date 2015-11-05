//
//  CDUserOther.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDUserOther)
class CDUserOther: NSManagedObject {

    @NSManaged var emailVerified: NSNumber
    @NSManaged var fbAccessToken: String?
    @NSManaged var fbID: String?
    @NSManaged var fbUsername: String?
    @NSManaged var instagramAccessToken: String
    @NSManaged var instagramID: String
    @NSManaged var instagramUsername: String
    @NSManaged var isActiveSeller: NSNumber
    @NSManaged var lastLogin: String
    @NSManaged var phoneCode: String
    @NSManaged var phoneVerified: Bool
    @NSManaged var registerTime: String
    @NSManaged var seller: NSNumber
    @NSManaged var shopName: String
    @NSManaged var shopPermalink: String
    @NSManaged var simplePermalink: String
    @NSManaged var twitterAccessToken: String
    @NSManaged var twitterID: String
    @NSManaged var twitterTokenSecret: String
    @NSManaged var pathID: String?
    @NSManaged var pathUsername: String?
    @NSManaged var pathAccessToken: String?
    @NSManaged var shippingIDs: NSData

    static func getOne() -> CDUserOther? {
        let fetchReq = NSFetchRequest(entityName: "CDUserOther")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err)
        if (err != nil || r?.count == 0) {
            return nil
        } else {
            return r?.first as? CDUserOther
        }
    }
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CDUserOther")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m?.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m?.deleteObject(result)
            }
            
            var error : NSError?
            if (m?.save(&error) != nil) {
                println("deleteAll CDUserOther success")
            } else if let error = error {
                println("deleteAll CDUserOther failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            println("deleteAll CDUserOther failed with fetch error : \(error)")
            return false
        }
        return true
    }
}
