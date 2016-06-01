//
//  PreloNotificationListener.swift
//  Prelo
//
//  Created by Fransiska on 10/8/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import Crashlytics

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
        // API Migrasi
        request(APINotifAnggi.GetUnreadNotifCount).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Notifikasi - Unread Count")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                self.newNotifCount = data["total"].intValue
                
                print("newNotifCount = \(self.newNotifCount)")
                self.delegate?.showNewNotifCount(self.newNotifCount)
                self.delegate?.refreshNotifPage()
            }
        }
    }
    
    func setupSocket() {
        if let del = UIApplication.sharedApplication().delegate as? AppDelegate {
        self.socket = del.messagePool?.socket
        } else
        {
            let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
            Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"PreloNotificationListener"])
        }
    }
        
    func handleNotification(json : JSON) {
        self.getTotalUnreadNotifCount()
    }
    
    func setNewNotifCount(count : Int) {
        newNotifCount = count
        delegate?.showNewNotifCount(newNotifCount)
    }
}