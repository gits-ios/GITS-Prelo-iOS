//
//  PreloNotificationListener.swift
//  Prelo
//
//  Created by Fransiska on 10/8/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Crashlytics
import Alamofire

protocol PreloNotifListenerDelegate {
    func showNewNotifCount(_ count : Int)
    func refreshNotifPage()
    func showCartCount(_ count : Int)
    func refreshCartPage()
    func increaseCartCount(_ value : Int)
}

class PreloNotificationListener {
    
    var socket : SocketIOClient!
    
    var newNotifCount : Int = 0
    
    var cartCount : Int = 0
    
    var delegate : PreloNotifListenerDelegate?
    
    var willReconnect = false
    
    init() {
        if (User.IsLoggedIn) {
            self.getTotalUnreadNotifCount()
            self.getTotalUnpaidCount()
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
    
    func getTotalUnpaidCount() {
        let _ = request(APITransactionCheck.checkUnpaidTransaction).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Checkout - Unpaid Transaction")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if (data["user_has_unpaid_transaction"].boolValue == true) {
                    self.cartCount = data["n_transaction_unpaid"].intValue
                    
                    self.delegate?.showCartCount(self.cartCount)
                    self.delegate?.refreshCartPage()
                }
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
        self.getTotalUnpaidCount()
    }
    
    func setNewNotifCount(_ count : Int) {
        newNotifCount = count
        delegate?.showNewNotifCount(newNotifCount)
        
        User.storeNotif(newNotifCount + cartCount)
    }
    
    func setCartCount(_ count : Int) {
        cartCount = count
        delegate?.showCartCount(cartCount)
        
        User.storeNotif(newNotifCount + cartCount)
    }
    
    func increaseCartCount(_ value : Int) {
        cartCount += value
        delegate?.showCartCount(cartCount)
        
        User.storeNotif(newNotifCount + cartCount)
    }
}
