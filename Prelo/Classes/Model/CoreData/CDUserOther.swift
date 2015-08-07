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
    @NSManaged var fbAccessToken: String
    @NSManaged var fbID: String
    @NSManaged var fbUsername: String
    @NSManaged var instagramAccessToken: String
    @NSManaged var instagramID: String
    @NSManaged var instagramUsername: String
    @NSManaged var isActiveSeller: NSNumber
    @NSManaged var lastLogin: String
    @NSManaged var phoneCode: String
    @NSManaged var phoneVerified: NSNumber
    @NSManaged var registerTime: String
    @NSManaged var seller: NSNumber
    @NSManaged var shopName: String
    @NSManaged var shopPermalink: String
    @NSManaged var simplePermalink: String
    @NSManaged var twitterAccessToken: String
    @NSManaged var twitterID: String
    @NSManaged var twitterTokenSecret: String
    @NSManaged var shippingIDs: NSData

}
