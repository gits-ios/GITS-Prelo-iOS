//
//  NotificationService.swift
//  PushNotif
//
//  Created by Djuned on 1/24/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UserNotifications
import UIKit

final class NotificationService: UNNotificationServiceExtension {
    
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    
    override internal func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void){
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        func failEarly() {
            contentHandler(request.content)
        }
        
        guard let content = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            return failEarly()
        }
        
        guard let attachmentURL = content.userInfo["attachment-url"] as? String else {
            return failEarly()
        }
        
        guard let imageData = NSData(contentsOf:NSURL(string: attachmentURL)! as URL) else { return failEarly() }
        
        let imageName = "prelo-image-notif" + UNNotificationAttachment.contentTypeForImageData(imageData: imageData)
        
        guard let attachment = UNNotificationAttachment.create(imageFileIdentifier: imageName, data: imageData, options: nil) else { return failEarly() }
        
        content.attachments = [attachment]
        contentHandler(content.copy() as! UNNotificationContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}

extension UNNotificationAttachment {
    static func contentTypeForImageData(imageData: NSData) -> String {
        var c = [UInt32](repeating: 0, count: 1)
        imageData.getBytes(&c, length: 1)
        
        switch (c[0]) {
        case 0xFF:
            return ".jpg"
        case 0x89:
            return ".png"
        case 0x47:
            return ".gif"
        case 0x49, 0x4D:
            return ".tiff"
        default:
            return ".tmp"
        }
    }
    
    
    /// Save the image to disk
    static func create(imageFileIdentifier: String, data: NSData, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: tmpSubFolderURL!, withIntermediateDirectories: true, attributes: nil)
            let fileURL = tmpSubFolderURL?.appendingPathComponent(imageFileIdentifier)
            try data.write(to: fileURL!, options: [])
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL!, options: options)
            return imageAttachment
        } catch let error {
            print("error \(error)")
        }
        
        return nil
    }
}
