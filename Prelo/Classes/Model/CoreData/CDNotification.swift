//
//  CDNotification.swift
//  Prelo
//
//  Created by Fransiska on 10/9/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDNotification)
class CDNotification : NSManagedObject {
    
    @NSManaged var notifType : String
    @NSManaged var ids : String
    @NSManaged var opened : Bool
    @NSManaged var read : Bool
    @NSManaged var message : String
    @NSManaged var ownerId : String
    @NSManaged var name : String
    @NSManaged var type : NSNumber
    @NSManaged var objectName : String
    @NSManaged var objectId : String
    @NSManaged var time : String
    @NSManaged var leftImage : String
    @NSManaged var rightImage : String?
    @NSManaged var weight : NSNumber
    @NSManaged var names : String
    
    static func newOne(notifType : String, ids : String, opened : Bool, read : Bool, message : String, ownerId : String, name : String, type : NSNumber, objectName : String, objectId : String, time : String, leftImage : String, rightImage : String?, weight : NSNumber, names : String) -> CDNotification? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObjectForEntityForName("CDNotification", inManagedObjectContext: m!) as! CDNotification
        r.notifType = notifType
        r.ids = ids
        r.opened = opened
        r.read = read
        r.message = message
        r.ownerId = ownerId
        r.name = name
        r.type = type
        r.objectName = objectName
        r.objectId = objectId
        r.time = time
        r.leftImage = leftImage
        r.rightImage = rightImage
        r.weight = weight
        r.names = names
        var err : NSError?
        if ((m?.save(&err))! == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CDNotification")
        fetchRequest.includesPropertyValues = false
        
        var error : NSError?
        if let results = m?.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m?.deleteObject(result)
            }
            
            var error : NSError?
            if (m?.save(&error) != nil) {
                println("deleteAll CDNotification success")
            } else if let error = error {
                println("deleteAll CDNotification failed with error : \(error.userInfo)")
                return false
            }
        } else if let error = error {
            println("deleteAll CDNotification failed with fetch error : \(error)")
            return false
        }
        return true
    }
    
    static func getAll() -> [CDNotification]? {
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err) as? [CDNotification]
        if (err != nil || r == nil) {
            return nil
        } else {
            return r!
        }
    }
    
    static func getNotifCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err);
        if (err != nil || r == nil) {
            return 0
        } else {
            return r!.count
        }
    }
    
    static func getNewNotifCount() -> Int {
        let predicate = NSPredicate(format: "opened == %@", NSNumber(bool: false))
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.predicate = predicate
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err)
        if (err != nil || r == nil) {
            return 0
        } else {
            return r!.count
        }
    }
    
    static func getNotifInSection(section : String) -> [CDNotification] {
        let predicate = NSPredicate(format: "notifType == %@", section)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.predicate = predicate
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err) as? [CDNotification]
        if (err != nil || r == nil) {
            return []
        } else {
            return r!
        }
    }
    
    static func getNotifCountInSection(section : String) -> Int {
        let predicate = NSPredicate(format: "notifType == %@", section)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.predicate = predicate
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err)
        if (err != nil || r == nil) {
            return 0
        } else {
            return r!.count
        }
    }
    
    static func setAllNotifToOpened() {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        var err : NSError?
        let r = m?.executeFetchRequest(fetchReq, error: &err) as? [CDNotification]
        if (r != nil) {
            for (var i = 0; i < r!.count; i++) {
                r![i].opened = true
            }
        }
        if ((m?.save(&err))! == false) {
            println("setAllNotifToOpened failed")
        } else {
            println("setAllNotifToOpened success")
        }
    }
    
    static func deleteNotifWithIds(ids : String) {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "ids like[c] %@", ids)
        let fetchRequest = NSFetchRequest(entityName: "CDNotification")
        fetchRequest.includesPropertyValues = false
        fetchRequest.predicate = predicate
        
        var error : NSError?
        if let results = m?.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                m?.deleteObject(result)
            }
            
            var error : NSError?
            if (m?.save(&error) != nil) {
                println("Notification with ids:\(ids) deleted")
            } else if let error = error {
                println("delete Notification failed with error : \(error.userInfo)")
            }
        } else if let error = error {
            println("delete Notification failed with fetch error : \(error)")
        }
    }
    
    static func getNotifWithObjectId(objectId : String, andType type : NSNumber) -> CDNotification? {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "objectId like[c] %@ AND type == %@", objectId, type)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.predicate = predicate
        
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err)
        if (err != nil || r?.count == 0) {
            return nil
        } else {
            return (r!.first as! CDNotification)
        }
    }
}