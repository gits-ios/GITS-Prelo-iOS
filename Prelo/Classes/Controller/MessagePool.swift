//
//  MessagePool.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/12/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Crashlytics

protocol MessagePoolDelegate
{
    func messageArrived(_ message : InboxMessage)
}

class MessagePool: NSObject
{
    fileprivate var delegates : [String : MessagePoolDelegate] = [:]
    
    func registerDelegate(_ threadId : String, d : MessagePoolDelegate)
    {
        if (delegates[threadId]) != nil
        {
            
        } else
        {
            delegates[threadId] = d
        }
    }
    
    func removeDelegate(_ threadId : String)
    {
        delegates.removeValue(forKey: threadId)
    }
    
    var socket : SocketIOClient!
    var started = false
    func start()
    {
        if (CDUser.getOne()?.id != nil)
        {
            let url = URL(string: AppTools.PreloBaseUrl)
            if (url == nil)
            {
                let error = NSError(domain: "Cannot create url", code: 0, userInfo: ["string" : AppTools.PreloBaseUrl])
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["string" : AppTools.PreloBaseUrl])
                return
            }
            socket = SocketIOClient(socketURL: url!)
            
            socket.on("connect", callback:{ data, ack in
                print("Socket connected, registering..")
                self.register()
            })
            
            socket.on("disconnect", callback:{ data, ack in
                print("Socket disconnected, reconnecting..")
                self.socket.reconnect()
            })
            
            socket.on("error", callback:{ data, ack in
                print(data)
                print(ack)
            })
            
            socket.on("reconnect", callback:{ data, ack in
                print("Socket reconnected")
            })
            
            socket.on("message", callback:{ data, ack in
                print(data)
                
                if let arr = data as? [[String: Any]] {
                    for d in arr {
                        if let inboxId : String = d["inbox_id"] as? String {
                            if let delegate = self.delegates[inboxId] {
                                let i = InboxMessage()
                                if let senderId = d["sender_id"] as? String {
                                    i.senderId = senderId
                                }
                                
                                if let o : NSNumber = d["message_type"] as? NSNumber {
                                    i.messageType = o.intValue
                                }
                                
                                if let m = d["message"] as? String {
                                    i.message = m
                                }
                                
                                
                                if let at = d["attachment_type"] as? String {
                                    i.attachmentType = at
                                }
                                
                                if let au = d["attachment_url"] as? String {
                                    i.attachmentURL = URL(string: au)!
                                }
                                
                                i.isMe = i.senderId == CDUser.getOne()?.id
                                i.time = ""
                                i.id = ""
                                delegate.messageArrived(i)
                            }
                        } else {
                            let error = NSError(domain: "No inbox_id", code: 0, userInfo: nil)
                            Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: d as [String : AnyObject])
                        }
                    }
                }
            })
            
            socket.on("clients", callback:{ data, ack in
                print(data)
            })
            
            
            
            if let del = UIApplication.shared.delegate as? AppDelegate
            {
                let notifListener = del.preloNotifListener
                socket.on("notification", callback: { data, ack in
                    if (!(notifListener?.willReconnect)!) {
                        print("Get notification from messagepool")
                        notifListener?.handleNotification()
                    }
                })
                if (notifListener?.willReconnect)! {
                    notifListener?.willReconnect = false
                }
            } else
            {
                let error = NSError(domain: "Failed to cast AppDelegate", code: 0, userInfo: nil)
                Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: ["from":"MessagePool"])
            }
            
            // FOR TESTING
            self.socket.onAny {print("Got socket event: \($0.event), with items: \($0.items)")}
            
            socket.connect()
        }
        
    }
    
    func register()
    {
        if let id = User.Id
        {
            socket.emit("register", id)
        } else
        {
            print("REGISTER SOCKET.IO FAILED BECAUSE USER IS NONE")
        }
    }
    
    func stop()
    {
        
        
    }
}
