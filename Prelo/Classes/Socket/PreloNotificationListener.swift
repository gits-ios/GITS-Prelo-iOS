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

class PreloNotificationListener {
    
    var socket : SocketIOClient!
    
    var newNotifCount : Int = 0
    
    var delegate : PreloNotifListenerDelegate?
    
    var willReconnect = false
    
    init() {
        if (User.IsLoggedIn) {
            self.getTotalUnreadNotifCount()
        }
    }
    
    func getTotalUnreadNotifCount() {
        request(APINotifAnggi.GetUnreadNotifCount).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi - Unread Count")) {
                let json = JSON(res!)
                let data = json["_data"]
                
                self.newNotifCount = data["total"].intValue
                
                println("newNotifCount = \(self.newNotifCount)")
                self.delegate?.showNewNotifCount(self.newNotifCount)
                self.delegate?.refreshNotifPage()
            }
        }
    }
    
    func setupSocket() {
        let del = UIApplication.sharedApplication().delegate as! AppDelegate
        self.socket = del.messagePool.socket
    }
        
    func handleNotification(json : JSON) {
        self.getTotalUnreadNotifCount()
    }
    
    func setNewNotifCount(count : Int) {
        newNotifCount = count
        delegate?.showNewNotifCount(newNotifCount)
    }
}