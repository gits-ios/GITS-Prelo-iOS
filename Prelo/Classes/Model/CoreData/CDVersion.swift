//
//  CDVersion.swift
//  Prelo
//
//  Created by Fransiska on 9/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDVersion)
class CDVersion: NSManagedObject {

    @NSManaged var appVersion: String
    @NSManaged var metadataVersion: String
    
    static func getOne() -> CDVersion? {
        let fetchReq = NSFetchRequest(entityName : "CDVersion")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err)
        if (err != nil || r?.count == 0) {
            return nil
        } else {
            return r?.first as? CDVersion
        }
    }
    
    static func saveVersion(json : JSON) {
        println(json)
        let m = UIApplication.appDelegate.managedObjectContext
        let ver : CDVersion? = self.getOne()
        if (ver != nil) {
            // Update
            ver?.appVersion = json["version"].string!
//            ver?.metadataVersion = json["metadata_version"].string!
        } else {
            // Make new
            let newVer = NSEntityDescription.insertNewObjectForEntityForName("CDVersion", inManagedObjectContext: m!) as! CDVersion
            newVer.appVersion = json["version"].string!
//            newVer.metadataVersion = json["metadata_version"].string!
        }
        
        var err : NSError?
        if ((m?.save(&err))! == false) {
            println("saveVersion failed")
        } else {
            println("saveVersion success")
        }
    }
}
