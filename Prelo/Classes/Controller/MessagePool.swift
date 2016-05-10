//
//  MessagePool.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/12/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

protocol MessagePoolDelegate
{
    func messageArrived(message : InboxMessage)
}

class MessagePool: NSObject
{
    private var delegates : [String : MessagePoolDelegate] = [:]
    
    func registerDelegate(threadId : String, d : MessagePoolDelegate)
    {
        if (delegates[threadId]) != nil
        {
            
        } else
        {
            delegates[threadId] = d
        }
    }
    
    func removeDelegate(threadId : String)
    {
        delegates.removeValueForKey(threadId)
    }
    
    var socket : SocketIOClient!
    var started = false
    func start()
    {
        if (CDUser.getOne()?.id != nil)
        {
            socket = SocketIOClient(socketURL: NSURL(string: AppTools.PreloBaseUrl)!)
            
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
                
                for d in data
                {
                    let inboxId : String = d["inbox_id"] as! String
                    if let delegate = self.delegates[inboxId]
                    {
                        let i = InboxMessage()
                        i.senderId = d["sender_id"] as! String
                        let o : NSNumber = d["message_type"] as! NSNumber
                        i.messageType = o.integerValue
                        i.message = d["message"] as! String
                        i.isMe = i.senderId == CDUser.getOne()?.id
                        i.time = ""
                        i.id = ""
                        delegate.messageArrived(i)
                    }
                }
            })
            
            socket.on("clients", callback:{ data, ack in
                print(data)
            })
            
            let del = UIApplication.sharedApplication().delegate as! AppDelegate
            let notifListener = del.preloNotifListener
            socket.on("notification", callback: { data, ack in
                if (!notifListener.willReconnect) {
                    print("Get notification from messagepool")
                    notifListener.handleNotification(JSON(data)[0])
                }
            })
            if (notifListener.willReconnect) {
                notifListener.willReconnect = false
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
