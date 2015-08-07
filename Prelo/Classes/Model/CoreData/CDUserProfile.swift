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

    @NSManaged var address: String
    @NSManaged var desc: String
    @NSManaged var phone: String
    @NSManaged var pict: String
    @NSManaged var postalCode: String
    @NSManaged var regionID: String
    @NSManaged var provinceID: String

}
