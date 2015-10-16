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

class PreloNotificationListener : PreloSocketDelegate
{
    
    let socket = SocketIOClient(socketURL: "dev.prelo.id")
    
    var newNotifCount : Int = 0
    
    var delegate : PreloNotifListenerDelegate?
    
    var willReconnect = false
    
    init() {
        // Init notif count
        NotificationPageViewController.refreshNotifications()
        
        // todo add delegate to Main Socket Class
        // PreloSocket.sharedInstance().registerDelegate(self, event:"eventName")
    }
    
    func socketReceiveSomething(data: NSArray?, ack: AckEmitter?) {
        self.handleNotification(JSON(data!)[0])
    }
    
    func setupSocket() {
        if ((!self.socket.connected || willReconnect) && !self.socket.connecting) {
            self.socket.on("connect") {data, ack in
                println("Socket is connected")
                
                // Register
                var userId = User.Id!
                self.socket.emit("register", userId)
            }
            
            // Listening for notification
            self.socket.on("notification") {data, ack in
                if (!self.willReconnect) {
                    println("You've got a notification: \(data)")
                    self.handleNotification(JSON(data!)[0])
                }
            }
            
            // FOR TESTING
            //self.socket.onAny {println("Got socket event: \($0.event), with items: \($0.items)")}
            
            if (willReconnect) {
                self.willReconnect = false
                self.socket.reconnect()
            } else {
                self.socket.connect()
            }
        }
    }
        
    func handleNotification(json : JSON) {
        // Add new notif to core data
        for (i : String, itemNotifs : JSON) in json {
            //println("itemNotifs = \(itemNotifs)")
            //println("itemNotifs.count = \(itemNotifs.count)")
            for (j : String, n : JSON) in itemNotifs {
                var notifType : String = ""
                if (i == "tp_notif") { // Transaksi
                    notifType = NotificationType.Transaksi
                } else if (i == "inbox") { // Inbox FIXME: keyword "inbox" belum fix
                    notifType = NotificationType.Inbox
                } else if (i == "activity") { // Aktivitas
                    notifType = NotificationType.Aktivitas
                }
                CDNotification.newOne(notifType, opened : n["opened"].bool!, read : n["read"].bool!, message: n["text"].string!, ownerId: n["owner_id"].string!, name: n["name"].string!, type: n["type"].int!, objectName: n["object_name"].string!, objectId: n["object_id"].string!, time: n["time"].string!, leftImage: n["left_image"].string!, rightImage: n["right_image"].string)
                newNotifCount++
            }
        }
        println("newNotifCount = \(newNotifCount)")
        delegate?.showNewNotifCount(newNotifCount)
        delegate?.refreshNotifPage()
    }
    
    func setNewNotifCount(count : Int) {
        newNotifCount = count
        delegate?.showNewNotifCount(newNotifCount)
    }
}