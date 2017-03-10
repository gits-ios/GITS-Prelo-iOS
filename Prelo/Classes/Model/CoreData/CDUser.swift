//
//  CDUser.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/6/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDUser)
class CDUser: NSManagedObject {

    @NSManaged var email: String
    @NSManaged var fullname: String?
    @NSManaged var id: String
    @NSManaged var username: String
    @NSManaged var others: CDUserOther
    @NSManaged var profiles: CDUserProfile
    
    static func pathTokenAvailable() -> Bool
    {
        if UserDefaults.standard.string(forKey: "pathtoken") != nil
        {
            return true
        }
        
        return false
    }
    
    static func twitterTokenAvailable() -> Bool
    {
        if UserDefaults.standard.string(forKey: "twittertoken") != nil
        {
            return true
        }
        
        return false
    }
    
    static func getOne() -> CDUser?
    {
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDUser")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq);
            return r.count == 0 ? nil : r.first as? CDUser
        } catch {
            return nil
        }
    }

    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDUser")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.fetch(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.delete(result)
                }
                
                if (m.saveSave() != false) {
                    print("deleteAll CDUser success")
                } else {
                    print("deleteAll CDUser failed")
                    return false
                }
            }
        } catch {
            return false
        }
        return true
    }
}
