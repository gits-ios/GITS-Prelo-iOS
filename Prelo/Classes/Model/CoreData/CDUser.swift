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

}
