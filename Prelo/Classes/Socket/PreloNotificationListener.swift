//
//  PreloNotificationListener.swift
//  Prelo
//
//  Created by Fransiska on 10/8/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

protocol PreloNotifListenerDelegate {
    func showNewNotifCount(count : Int)
    func refreshNotifPage()
}

protocol PreloSocketDelegate
{
    func socketReceiveSomething(data : NSArray?, ack : AckEmitter?)
}

class PreloNotificationListener //: PreloSocketDelegate
{
    
    var socket : SocketIOClient! // = SocketIOClient(socketURL: AppTools.PreloBaseUrl)
    
    var newNotifCount : Int = 0
    
    var delegate : PreloNotifListenerDelegate?
    
    var willReconnect = false
    
    init() {
        // Init notif count
        NotificationPageViewController.refreshNotifications()
        
        /* Belum dipake, mungkin ga akan dipake
        // Add delegate to Main Socket Class
        //let del = UIApplication.sharedApplication().delegate as! AppDelegate
        //del.messagePool.registerDelegate(self, event:"eventName")
        */
    }
    
    /* Belum dipake, mungkin ga akan dipake
    func socketReceiveSomething(data: NSArray?, ack: AckEmitter?) {
        self.handleNotification(JSON(data!)[0])
    }
    */
    
    func setupSocket() {
        let del = UIApplication.sharedApplication().delegate as! AppDelegate
        self.socket = del.messagePool.socket
        
        /* Dimatiin abis gabungin ke messagepool
        if ((!self.socket.connected || willReconnect) && !self.socket.connecting) {
            self.socket.on("connect") {data, ack in
                println("Socket is connected")
                
                /* Dimatiin abis gabungin ke messagepool
                // Register
                // Harusnya ini cuma dipanggil kalo user logged in, tapi sering crash gara2 kepanggil waktu logged out, jadi kasih if aja
                if (User.IsLoggedIn) {
                    var userId = User.Id!
                    self.socket.emit("register", userId)
                }
                */
            }
            
            // Listening for notification
            self.socket.on("notification") {data, ack in
                /* Dimatiin abis ganbungin ke messagepool
                if (!self.willReconnect) {
                    println("You've got a notification: \(data)")
                    self.handleNotification(JSON(data!)[0])
                }
                */
            }
            
            // FOR TESTING
            //self.socket.onAny {println("Got socket event: \($0.event), with items: \($0.items)")}
            
            if (willReconnect) {
                self.willReconnect = false
                self.socket.reconnect()
            } else {
                self.socket.connect()
            }
        }*/
    }
        
    func handleNotification(json : JSON) {
        let m = UIApplication.appDelegate.managedObjectContext
        
        // Add new notif to core data
        for (i : String, itemNotifs : JSON) in json {
            //println("itemNotifs = \(itemNotifs)")
            //println("itemNotifs.count = \(itemNotifs.count)")
            for (j : String, n : JSON) in itemNotifs {
                var newN : CDNotification?
                // First, check if there's already a same notif to be merged
                // Same notif: transaksi with same objectId OR inbox/aktivitas with same objectId and type
                var sameNotif : CDNotification?
                if (i == "tp_notif") { // Notif transaksi
                    sameNotif = CDNotification.getNotifWithObjectId(n["object_id"].string!)
                } else { // Notif inbox/aktivitas
                    sameNotif =  CDNotification.getNotifWithObjectId(n["object_id"].string!, andType: n["type"].number!)
                }
                if (sameNotif != nil) { // Udah ada yg sama
                    // Hapus yang lama di core data
                    CDNotification.deleteNotifWithIds(sameNotif!.ids)
                }
                // Simpan yang baru
                var notifType : String = ""
                if (i == "tp_notif") { // Transaksi
                    notifType = NotificationType.Transaksi
                } else if (i == "inbox") { // Inbox FIXME: keyword "inbox" belum fix
                    notifType = NotificationType.Inbox
                } else if (i == "activity") { // Aktivitas
                    notifType = NotificationType.Aktivitas
                }
                newN = CDNotification.newOne(notifType, ids : n["_id"].string!, opened : n["opened"].bool!, read : n["read"].bool!, message: n["text"].string!, ownerId: n["owner_id"].string!, name: n["name"].string!, type: n["type"].int!, objectName: n["object_name"].string!, objectId: n["object_id"].string!, time: n["time"].string!, leftImage: n["left_image"].string!, rightImage: n["right_image"].string, weight: NSNumber(integer: 1), names: n["name"].string!)
                
                /* TO BE DELETED, merged version, hiks T^T
                if (sameNotif != nil) { // Udah ada yg sama, merge dengan notif yg sama
                    // Sesuaikan ids, opened, message, name, time, leftImage, weight, names
                    // Simpan ids baru di var baru karna sameNotif.ids akan digunakan untuk menghapus objek di core data
                    let nId : String = n["_id"].string!
                    let newIds : String = "\(sameNotif!.ids);\(nId)"
                    if (sameNotif!.names.rangeOfString(n["name"].string!) == nil) {
                        let nName : String = n["name"].string!
                        sameNotif!.names = "\(sameNotif!.names);\(nName)"
                    }
                    let namesArr = split(sameNotif!.names) {$0 == ";"}
                    if (namesArr.count > 1) {
                        sameNotif!.message = sameNotif!.message.stringByReplacingOccurrencesOfString(sameNotif!.name, withString: n["name"].string! + " dan \(namesArr.count - 1) lainnya")
                        sameNotif!.name = n["name"].string! + " dan \(namesArr.count - 1) lainnya"
                    } else {
                        sameNotif!.message = n["text"].string!
                        sameNotif!.name = n["name"].string!
                    }
                    sameNotif!.opened = false
                    sameNotif!.read = false
                    sameNotif!.time = n["time"].string!
                    sameNotif!.leftImage = n["left_image"].string!
                    sameNotif!.weight = NSNumber(integer: sameNotif!.weight.integerValue + 1)
                    
                    // Simpan yang baru
                    newN = CDNotification.newOne(sameNotif!.notifType, ids: newIds, opened: sameNotif!.opened, read: sameNotif!.read, message: sameNotif!.message, ownerId: sameNotif!.ownerId, name: sameNotif!.name, type: sameNotif!.type, objectName: sameNotif!.objectName, objectId: sameNotif!.objectId, time: sameNotif!.time, leftImage: sameNotif!.leftImage, rightImage: sameNotif!.rightImage, weight: sameNotif!.weight, names: sameNotif!.names)
                    
                    // Hapus yang lama di core data
                    CDNotification.deleteNotifWithIds(sameNotif!.ids)
                } else { // Belum ada notif yg sama
                    var notifType : String = ""
                    if (i == "tp_notif") { // Transaksi
                        notifType = NotificationType.Transaksi
                    } else if (i == "inbox") { // Inbox FIXME: keyword "inbox" belum fix
                        notifType = NotificationType.Inbox
                    } else if (i == "activity") { // Aktivitas
                        notifType = NotificationType.Aktivitas
                    }
                    newN = CDNotification.newOne(notifType, ids : n["_id"].string!, opened : n["opened"].bool!, read : n["read"].bool!, message: n["text"].string!, ownerId: n["owner_id"].string!, name: n["name"].string!, type: n["type"].int!, objectName: n["object_name"].string!, objectId: n["object_id"].string!, time: n["time"].string!, leftImage: n["left_image"].string!, rightImage: n["right_image"].string, weight: NSNumber(integer: 1), names: n["name"].string!)
                }*/
                if (newN != nil) {
                    println("Successfully saved newN = \(newN)")
                    //newNotifCount++
                } else {
                    println("Failed to save newN")
                }
            }
        }
        newNotifCount = CDNotification.getNewNotifCount()
        println("newNotifCount = \(newNotifCount)")
        delegate?.showNewNotifCount(newNotifCount)
        delegate?.refreshNotifPage()
    }
    
    func setNewNotifCount(count : Int) {
        newNotifCount = count
        delegate?.showNewNotifCount(newNotifCount)
    }
}