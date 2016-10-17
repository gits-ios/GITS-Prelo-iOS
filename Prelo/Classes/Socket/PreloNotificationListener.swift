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
    func showNewNotifCount(_ count : Int)
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
        let _ = request(APINotification.getUnreadNotifCount).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Unread Count")) {
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
        if let del = UIApplication.shared.delegate as? AppDelegate {
        self.socket = del.messagePool?.socket
        } else
        {
            let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
            Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"PreloNotificationListener"])
        }
    }
        
    func handleNotification() {
        self.getTotalUnreadNotifCount()
    }
    
    func setNewNotifCount(_ count : Int) {
        newNotifCount = count
        delegate?.showNewNotifCount(newNotifCount)
    }
}
