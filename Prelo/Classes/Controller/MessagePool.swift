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
        if let d = delegates[threadId]
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
        if let id = CDUser.getOne()?.id
        {
            socket = SocketIOClient(socketURL: AppTools.PreloBaseUrlShort)
            
            socket.on("connect", callback:{ data, ack in
                println("connected, registering..")
                self.register()
            })
            
            socket.on("disconnect", callback:{ data, ack in
                
            })
            
            socket.on("error", callback:{ data, ack in
                
            })
            
            socket.on("reconnect", callback:{ data, ack in
                
            })
            
            socket.on("message", callback:{ data, ack in
                println(data)
                
                if let arr = data
                {
                    for d in arr
                    {
                        let inboxId : String = d["inbox_id"] as! String
                        if let delegate = self.delegates[inboxId]
                        {
                            let i = InboxMessage()
                            i.senderId = d["sender_id"] as! String
                            let o : NSString = d["message_type"] as! NSString
                            i.messageType = o.integerValue
                            i.message = d["message"] as! String
                            i.isMe = i.senderId == CDUser.getOne()?.id
                            i.time = ""
                            i.id = ""
                            delegate.messageArrived(i)
                        }
                    }
                }
                
            })
            
            socket.on("clients", callback:{ data, ack in
                println(data)
            })
            
            socket.connect()
        }
        
    }
    
    func register()
    {
        if let id = CDUser.getOne()?.id
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
