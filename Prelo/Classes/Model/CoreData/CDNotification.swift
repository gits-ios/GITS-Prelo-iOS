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
    
    static func newOne(_ notifType : String, ids : String, opened : Bool, read : Bool, message : String, ownerId : String, name : String, type : NSNumber, objectName : String, objectId : String, time : String, leftImage : String, rightImage : String?, weight : NSNumber, names : String) -> CDNotification? {
        let m = UIApplication.appDelegate.managedObjectContext
        let r = NSEntityDescription.insertNewObject(forEntityName: "CDNotification", into: m) as! CDNotification
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
        
        if (m.saveSave() == false) {
            return nil
        } else {
            return r
        }
    }
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CDNotification")
        fetchRequest.includesPropertyValues = false
        
        do {
            let r = try m.fetch(fetchRequest) as? [NSManagedObject]
            if let results = r
            {
                for result in results {
                    m.delete(result)
                }
                
                if (m.saveSave() != false) {
                    print("deleteAll CDNotification success")
                }
            }
        } catch
        {
            return false
        }
        
        return true
    }
    
    static func getAll() -> [CDNotification]? {
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq) as? [CDNotification]
            return r
        } catch {
            return nil
        }
    }
    
    static func getNotifCount() -> Int {
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq);
            return r.count
        } catch {
            return 0
        }
    }
    
    static func getNewNotifCount() -> Int {
        let predicate = NSPredicate(format: "read == %@", NSNumber(value: false as Bool)) // Ada perubahan bahwa angka notif sekarang adalah berdasarkan read, bukan opened, jadi "opened == %@" diubah jadi "read == %@"
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count
        } catch {
            return 0
        }
    }
    
    static func getNotifInSection(_ section : String) -> [CDNotification] {
        let predicate = NSPredicate(format: "notifType == %@", section)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq) as? [CDNotification]
            return r == nil ? [] : r!
        } catch {
            return []
        }
    }
    
    static func getUnreadNotifCountInSection(_ section : String) -> Int {
        let predicate = NSPredicate(format: "notifType == %@ AND read == false", section)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count
        } catch {
            return 0
        }
        
    }
    
    static func getNotifCountInSection(_ section : String) -> Int {
        let predicate = NSPredicate(format: "notifType == %@", section)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count
        } catch {
            return 0
        }
    }
    
    static func setAllNotifToOpened() {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        
        do {
            let r = try m.fetch(fetchReq) as? [CDNotification]
            if (r != nil) {
                for i in 0 ..< r!.count {
                    r![i].opened = true
                }
            }
            if (m.saveSave() == false) {
                print("setAllNotifToOpened failed")
            } else {
                print("setAllNotifToOpened success")
            }
        } catch {
            
        }
    }
    
    // Mengembalikan jumlah notif inbox + aktivitas yang not opened
    static func setAllNotifTransactionToOpened() -> Int? {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "notifType like[c] %@", NotificationType.Transaksi)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.includesPropertyValues = false
        fetchReq.predicate = predicate
        do {
            let r = try m.fetch(fetchReq) as? [CDNotification]
            if (r != nil) {
                for i in 0 ..< r!.count {
                    r![i].opened = true
                }
                
                if (m.saveSave() == false) {
                    print("setAllNotifTransactionToOpened failed")
                    return nil
                } else {
                    print("setAllNotifTransactionToOpened success")
                    
                    // Hitung notif inbox + aktivitas yang not opened
                    let predicate2 = NSPredicate(format: "(notifType like[c] %@ OR notifType like[c] %@) AND opened == false", NotificationType.Inbox, NotificationType.Aktivitas)
                    let fetchReq2 = NSFetchRequest(entityName: "CDNotification")
                    fetchReq2.includesPropertyValues = false
                    fetchReq2.predicate = predicate2
                    let r2 = try m.fetch(fetchReq2) as? [CDNotification]
                    if (r2 != nil) {
                        return r2!.count
                    } else {
                        return nil
                    }
                }
            } else {
                print("setAllNotifTransactionToOpened failed")
                return nil
            }
        } catch {
            return nil
        }
    }
    
    // Mengembalikan jumlah notif transaksi + aktivitas yang not opened
    static func setAllNotifInboxToOpened() -> Int? {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "notifType like[c] %@", NotificationType.Inbox)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.includesPropertyValues = false
        fetchReq.predicate = predicate
        
        do {
            let r = try m.fetch(fetchReq) as? [CDNotification]
            if (r != nil) {
                for i in 0 ..< r!.count {
                    r![i].opened = true
                }
                
                if (m.saveSave() == false) {
                    print("setAllNotifInboxToOpened failed")
                    return nil
                } else {
                    print("setAllNotifInboxToOpened success")
                    
                    // Hitung notif transaksi + aktivitas yang not opened
                    let predicate2 = NSPredicate(format: "(notifType like[c] %@ OR notifType like[c] %@) AND opened == false", NotificationType.Transaksi, NotificationType.Aktivitas)
                    let fetchReq2 = NSFetchRequest(entityName: "CDNotification")
                    fetchReq2.includesPropertyValues = false
                    fetchReq2.predicate = predicate2
                    let r2 = try m.fetch(fetchReq2) as? [CDNotification]
                    if (r2 != nil) {
                        return r2!.count
                    } else {
                        return nil
                    }
                }
            } else {
                print("setAllNotifInboxToOpened failed")
                return nil
            }
        } catch {
            return nil
        }
    }
    
    // Mengembalikan jumlah notif transaksi + inbox yang not opened
    static func setAllNotifActivityToOpened() -> Int? {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "notifType like[c] %@", NotificationType.Aktivitas)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.includesPropertyValues = false
        fetchReq.predicate = predicate
        
        do {
            let r = try m.fetch(fetchReq) as? [CDNotification]
            if (r != nil) {
                for i in 0 ..< r!.count {
                    r![i].opened = true
                }
                
                if (m.saveSave() == false) {
                    print("setAllNotifActivityToOpened failed")
                    return nil
                } else {
                    print("setAllNotifActivityToOpened success")
                    
                    // Hitung notif transaksi + inbox yang not opened
                    let predicate2 = NSPredicate(format: "(notifType like[c] %@ OR notifType like[c] %@) AND opened == false", NotificationType.Transaksi, NotificationType.Inbox)
                    let fetchReq2 = NSFetchRequest(entityName: "CDNotification")
                    fetchReq2.includesPropertyValues = false
                    fetchReq2.predicate = predicate2
                    let r2 = try m.fetch(fetchReq2) as? [CDNotification]
                    if (r2 != nil) {
                        return r2!.count
                    } else {
                        return nil
                    }
                }
            } else {
                print("setAllNotifActivityToOpened failed")
                return nil
            }
        } catch {
            return nil
        }
    }
    
    // Mengembalikan jumlah notif transaction yang not read
    static func setReadNotifTransactionAndGetUnreadCount(_ ids : String) -> Int? {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "ids like[c] %@", ids)
        let fetchRequest = NSFetchRequest(entityName: "CDNotification")
        fetchRequest.includesPropertyValues = false
        fetchRequest.predicate = predicate
        
        do {
            let r = try m.fetch(fetchRequest) as? [CDNotification]
            if let results = r {
                let result = results[0]
                // Ubah jadi read
                result.read = true
                
                if (m.saveSave() == false) {
                    print("setReadNotifTransactionAndGetUnreadCount failed")
                    return nil
                } else {
                    print("setReadNotifTransactionAndGetUnreadCount success")
                    
                    // Hitung notif transaction yang not read
                    let predicate2 = NSPredicate(format: "notifType like[c] %@ AND read == false", NotificationType.Transaksi)
                    let fetchReq2 = NSFetchRequest(entityName: "CDNotification")
                    fetchReq2.includesPropertyValues = false
                    fetchReq2.predicate = predicate2
                    let results2 = try m.fetch(fetchReq2) as? [CDNotification]
                    if (results2 != nil) {
                        return results2!.count
                    } else {
                        return nil
                    }
                }
            } else {
                print("setReadNotifTransactionAndGetUnreadCount failed")
                return nil
            }
        } catch {
            return nil
        }
    }
    
    // Mengembalikan jumlah notif inbox yang not read
    static func setReadNotifInboxAndGetUnreadCount(_ ids : String) -> Int? {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "ids like[c] %@", ids)
        let fetchRequest = NSFetchRequest(entityName: "CDNotification")
        fetchRequest.includesPropertyValues = false
        fetchRequest.predicate = predicate
        
        do {
            let r = try m.fetch(fetchRequest) as? [CDNotification]
            if let results = r {
                let result = results[0]
                // Ubah jadi read
                result.read = true
                
                if (m.saveSave() == false) {
                    print("setReadNotifInboxAndGetUnreadCount failed")
                    return nil
                } else {
                    print("setReadNotifInboxAndGetUnreadCount success")
                    
                    // Hitung notif inbox yang not read
                    let predicate2 = NSPredicate(format: "notifType like[c] %@ AND read == false", NotificationType.Inbox)
                    let fetchReq2 = NSFetchRequest(entityName: "CDNotification")
                    fetchReq2.includesPropertyValues = false
                    fetchReq2.predicate = predicate2
                    let results2 = try m.fetch(fetchReq2) as? [CDNotification]
                    if (results2 != nil) {
                        return results2!.count
                    } else {
                        return nil
                    }
                }
            } else {
                print("setReadNotifInboxAndGetUnreadCount failed")
                return nil
            }
        } catch {
            return nil
        }
    }
    
    // Mengembalikan jumlah notif aktivitas yang not read
    static func setReadNotifActivityAndGetUnreadCount(_ ids : String) -> Int? {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "ids like[c] %@", ids)
        let fetchRequest = NSFetchRequest(entityName: "CDNotification")
        fetchRequest.includesPropertyValues = false
        fetchRequest.predicate = predicate
        
        do {
            let r = try m.fetch(fetchRequest) as? [CDNotification]
            if let results = r {
                let result = results[0]
                // Ubah jadi read
                result.read = true
                
                if (m.saveSave() == false) {
                    print("setReadNotifActivityAndGetUnreadCount failed")
                    return nil
                } else {
                    print("setReadNotifActivityAndGetUnreadCount success")
                    
                    // Hitung notif aktivitas yang not read
                    let predicate2 = NSPredicate(format: "notifType like[c] %@ AND read == false", NotificationType.Aktivitas)
                    let fetchReq2 = NSFetchRequest(entityName: "CDNotification")
                    fetchReq2.includesPropertyValues = false
                    fetchReq2.predicate = predicate2
                    let results2 = try m.fetch(fetchReq2) as? [CDNotification]
                    if (results2 != nil) {
                        return results2!.count
                    } else {
                        return nil
                    }
                }
            } else {
                print("setReadNotifActivityAndGetUnreadCount failed")
                return nil
            }
        } catch {
            return nil
        }
    }
    
    static func setReadNotifWithIds(_ ids : String) {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "ids like[c] %@", ids)
        let fetchRequest = NSFetchRequest(entityName: "CDNotification")
        fetchRequest.includesPropertyValues = false
        fetchRequest.predicate = predicate
        
        do {
            let r = try m.fetch(fetchRequest) as? [CDNotification]
            if let results = r {
                let result = results[0]
                // Ubah jadi read
                result.read = true
                
                if (m.saveSave() == false) {
                    print("setReadNotifActivity failed")
                } else {
                    print("setReadNotifActivity success")
                }
            }
        } catch {
            
        }
    }
    
    static func deleteNotifWithIds(_ ids : String) {
        let m = UIApplication.appDelegate.managedObjectContext
        let predicate = NSPredicate(format: "ids like[c] %@", ids)
        let fetchRequest = NSFetchRequest(entityName: "CDNotification")
        fetchRequest.includesPropertyValues = false
        fetchRequest.predicate = predicate
        
        do {
            let r = try m.fetch(fetchRequest) as? [NSManagedObject]
            if let results = r {
                for result in results {
                    m.delete(result)
                }
                
                if (m.saveSave() != false) {
                    print("Notification with ids:\(ids) deleted")
                }
            }
        } catch {
            
        }
    }
    
    static func getNotifWithObjectId(_ objectId : String, andType type : NSNumber) -> CDNotification? {
        let predicate = NSPredicate(format: "objectId like[c] %@ AND type == %@", objectId, type)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.first as? CDNotification
        } catch {
            return nil
        }
    }
    
    static func getNotifWithObjectId(_ objectId : String) -> CDNotification? {
        let predicate = NSPredicate(format: "objectId like[c] %@", objectId)
        let fetchReq = NSFetchRequest(entityName: "CDNotification")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.first as? CDNotification
        } catch {
            return nil
        }
    }
}
