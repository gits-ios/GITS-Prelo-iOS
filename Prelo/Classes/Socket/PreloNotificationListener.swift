//
//  PreloNotificationListener.swift
//  Prelo
//
//  Created by Fransiska on 10/8/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

protocol PreloNotifListenerDelegate {
    func showNotifCount(count : Int)
}

class PreloNotificationListener {
    
    let socket = SocketIOClient(socketURL: "dev.prelo.id")
    
    var newNotifCount : Int = 0
    
    var delegate : PreloNotifListenerDelegate?
    
    init() {
        // Init notif count
        newNotifCount = 0
    }
    
    func setupSocket() {
        if (User.IsLoggedIn) {
            if (!self.socket.connected && !self.socket.connecting) {
                self.socket.on("connect") {data, ack in
                    println("Socket is connected")
                    
                    // Register
                    var userId = User.Id!
                    self.socket.emit("register", userId)
                }
                
                // Listening for notification
                self.socket.on("notification") {data, ack in
                    println("You've got a notification: \(data)")
                    self.handleNotification(JSON(data!)[0])
                }
                
                // FOR TESTING
                //self.socket.onAny {println("Got socket event: \($0.event), with items: \($0.items)")}
            }
        }
    }
    
    func connectSocket() {
        self.socket.connect()
    }
    
    func disconnectSocket() {
        // TODO: dipanggil setiap kali user logout
    }
    
    func handleNotification(json : JSON) {
        for (i : String, itemNotifs : JSON) in json {
            println("itemNotif = \(itemNotifs)")
            println("count = \(itemNotifs.count)")
            for (j : String, itemNotif : JSON) in itemNotifs {
                newNotifCount++
            }
        }
        println("newNotifCount = \(newNotifCount)")
        delegate?.showNotifCount(newNotifCount)
    }
}