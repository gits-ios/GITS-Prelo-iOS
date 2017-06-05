//
//  CDVersion.swift
//  Prelo
//
//  Created by Fransiska on 9/11/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDVersion)
class CDVersion: NSManagedObject {

    @NSManaged var appVersion: String
    @NSManaged var brandsVersion : NSNumber
    @NSManaged var categoriesVersion : NSNumber
    @NSManaged var categorySizesVersion : NSNumber
    @NSManaged var shippingsVersion : NSNumber
    @NSManaged var productConditionsVersion : NSNumber
    @NSManaged var provincesRegionsVersion : NSNumber
    
    static func getOne() -> CDVersion? {
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName : "CDVersion")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : r.first as? CDVersion
        } catch {
            return nil
        }
    }
    
    static func saveVersions(_ json : JSON) {
        let m = UIApplication.appDelegate.managedObjectContext
        let ver : CDVersion? = self.getOne()
        if (ver != nil) {
            // Update
            ver?.appVersion = json["version"].string!
            ver?.brandsVersion = json["metadata_versions"]["brands"].number!
            ver?.categoriesVersion = json["metadata_versions"]["categories"].number!
            ver?.categorySizesVersion = json["metadata_versions"]["category_sizes"].number!
            ver?.shippingsVersion = json["metadata_versions"]["shippings"].number!
            ver?.productConditionsVersion = json["metadata_versions"]["product_conditions"].number!
            ver?.provincesRegionsVersion = json["metadata_versions"]["provinces_regions"].number!
        } else {
            // Make new
            let newVer = NSEntityDescription.insertNewObject(forEntityName: "CDVersion", into: m) as! CDVersion
            newVer.appVersion = json["version"].string!
            newVer.appVersion = json["version"].string!
            newVer.brandsVersion = json["metadata_versions"]["brands"].number!
            newVer.categoriesVersion = json["metadata_versions"]["categories"].number!
            newVer.categorySizesVersion = json["metadata_versions"]["category_sizes"].number!
            newVer.shippingsVersion = json["metadata_versions"]["shippings"].number!
            newVer.productConditionsVersion = json["metadata_versions"]["product_conditions"].number!
            newVer.provincesRegionsVersion = json["metadata_versions"]["provinces_regions"].number!
        }
        
        if (m.saveSave() == false) {
            //print("saveVersion failed")
        } else {
            //print("saveVersion success")
        }
    }
}
