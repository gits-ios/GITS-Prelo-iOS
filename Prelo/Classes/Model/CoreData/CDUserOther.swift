//
//  CDUserOther.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/6/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDUserOther)
class CDUserOther: NSManagedObject {

    @NSManaged var emailVerified: NSNumber
    @NSManaged var fbAccessToken: String?
    @NSManaged var fbID: String?
    @NSManaged var fbUsername: String?
    @NSManaged var instagramAccessToken: String?
    @NSManaged var instagramID: String?
    @NSManaged var instagramUsername: String?
    @NSManaged var isActiveSeller: NSNumber
    @NSManaged var lastLogin: String
    @NSManaged var phoneCode: String
    @NSManaged var phoneVerified: Bool
    @NSManaged var registerTime: String?
    @NSManaged var seller: NSNumber
    @NSManaged var shopName: String
    @NSManaged var shopPermalink: String
    @NSManaged var simplePermalink: String
    @NSManaged var twitterAccessToken: String?
    @NSManaged var twitterID: String?
    @NSManaged var twitterUsername: String?
    @NSManaged var twitterTokenSecret: String?
    @NSManaged var pathID: String?
    @NSManaged var pathUsername: String?
    @NSManaged var pathAccessToken: String?
    @NSManaged var shippingIDs: Data

    static func getOne() -> CDUserOther? {
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDUserOther")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : r.first as? CDUserOther
        } catch {
            return nil
        }
    }
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDUserOther")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.fetch(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.delete(result)
                }
                
                if (m.saveSave() != false) {
                    //print("deleteAll CDUserOther success")
                } else {
                    //print("deleteAll CDUserOther failed")
                    return false
                }
            }
        } catch {
            return false
        }
        
        return true
    }
}
