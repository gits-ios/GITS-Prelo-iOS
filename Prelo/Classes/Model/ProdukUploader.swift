//
//  ProdukUploader.swift
//  Prelo
//
//  Created by Rahadian Kumang on 25/5/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import UIKit

class ProdukUploader: NSObject {

    static let ProdukUploader_NOTIFICATION_UPLOAD_SUCCESS = "ProdukUploader_NOTIFICATION_UPLOAD_SUCCESS"
    static let ProdukUploader_NOTIFICATION_UPLOAD_FAILED = "ProdukUploader_NOTIFICATION_UPLOAD_FAILED"
    
    /*
     Notification Object is JSON Dictionary
    */
    static func AddObserverForUploadSuccess(observer : NSObject, selector : Selector)
    {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: selector, name: ProdukUploader_NOTIFICATION_UPLOAD_SUCCESS, object: nil)
    }
    
    static func RemoveObserverForUploadSuccess(observer : NSObject)
    {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: ProdukUploader_NOTIFICATION_UPLOAD_SUCCESS, object: nil)
    }
    
    /*
     Notification Object is NSError
    */
    static func AddObserverForUploadFailed(observer : NSObject, selector : Selector)
    {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: selector, name: ProdukUploader_NOTIFICATION_UPLOAD_FAILED, object: nil)
    }
    
    static func RemoveObserverForUploadFailed(observer : NSObject)
    {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: ProdukUploader_NOTIFICATION_UPLOAD_FAILED, object: nil)
    }
    
    let KEY_LIST_PRODUKLOKAL = "KEY_LIST_PRODUKLOKAL"
    
    struct ProdukLokal {
        
        static let KEY_PARAM = "param"
        static let KEY_IMAGES = "images"
        static let KEY_MIXPANEL_PARAM = "mixpanelParam"
        
        init(produkParam : [String : String!], produkImages : [AnyObject], mixpanelParam : [NSObject : AnyObject])
        {
            self.param = produkParam
            self.images = produkImages
            self.mixpanelParam = mixpanelParam
        }
        
        var param : [String : String!] = [:]
        var images : [AnyObject] = []
        var mixpanelParam : [NSObject : AnyObject] = [:]
        
        var toDictionary : [String : AnyObject] {
            return ["param":param, "images":images, "mixpanelParam":mixpanelParam]
        }
        
        var toProduct : Product?
            {
            let json = JSON(self.param)
            let p = Product.instance(json)
            p?.isLokal = true
            p?.placeHolderImage = images.first as? UIImage
            return p
        }
    }
    
    var autoRetry = true
    var maxRetry = 10
    var currentRetryCount = 0
    
    enum ProdukUploaderStatus {
        case Idle
        case Failed
        case Uploading
    }
    
    var currentStatus : ProdukUploaderStatus = .Idle
    
    var currentlyUploading : ProdukLokal?
    {
        let queue = getQueue()
        if (queue.count == 0)
        {
            return nil
        }
        return queue.first
    }
    
    var currentUploadManager : AFHTTPRequestOperationManager?
    
    func start(onLoop : Bool = false)
    {
        let t = NSDate()
        if (!onLoop) // onLoop == false artinya fungsi start() dipanggil dari code lain, buka recursive
        {
            stop()
        }
        
        if let p = getQueue().first
        {
            let url = "\(AppTools.PreloBaseUrl)/api/product"
            let userAgent : String? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.UserAgent) as? String
            
            currentStatus = .Uploading
            print("starting produk upload took \(NSDate().timeIntervalSinceDate(t)) seconds")
            currentUploadManager = AppToolsObjC.sendMultipart2(p.param, images: p.images, withToken: User.Token!, andUserAgent: userAgent!, to:url, success: {op, res in
                
                print("queue upload success :")
                print(res)
                self.currentRetryCount = 0
                
                // Mixpanel
                Mixpanel.trackEvent(MixpanelEvent.AddedProduct, properties: p.mixpanelParam)
                
                var queue = self.getQueue()
                if (queue.count > 1)
                {
                    queue.removeFirst()
                    self.saveQueue(queue)
                    print("queue : move to next product!")
                    self.start(true)
                } else
                {
                    self.saveQueue([])
                    print("Queue finished!")
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    NSNotificationCenter.defaultCenter().postNotificationName(ProdukUploader.ProdukUploader_NOTIFICATION_UPLOAD_SUCCESS, object: res)
                })
                
            }, failure: { op, err in
                print(err)
                if (self.autoRetry && self.currentRetryCount < self.maxRetry)
                {
                    self.currentRetryCount = self.currentRetryCount + 1
                    self.start(true)
                } else
                {
                    var queue = self.getQueue()
                    if (queue.count > 1)
                    {
                        queue.removeFirst()
                        self.saveQueue(queue)
                        print("queue : move to next product!")
                        self.start(true)
                    } else
                    {
                        self.saveQueue([])
                        print("Queue finished!")
                    }
                    
                    self.currentRetryCount = 0
                    dispatch_async(dispatch_get_main_queue(), {
                        NSNotificationCenter.defaultCenter().postNotificationName(ProdukUploader.ProdukUploader_NOTIFICATION_UPLOAD_FAILED, object: err)
                    })
                }
            })
        } else
        {
            print("Queue is empty")
        }
    }
    
    func stop()
    {
        currentUploadManager?.operationQueue.cancelAllOperations()
    }
    
    func clearQueue()
    {
        stop()
        saveRawQueue([])
    }
    
    func addToQueue(produk : ProdukLokal)
    {
        let t = NSDate()
        var rawQueue = getRawQueue()
        rawQueue.append(produk.toDictionary)
        saveRawQueue(rawQueue)
        
        print("adding queue took \(NSDate().timeIntervalSinceDate(t)) seconds")
        
        if (rawQueue.count >= 1)
        {
            dispatch_async(dispatch_get_main_queue(), {
                self.start()
            })
        }
    }
    
    func getQueue() -> [ProdukLokal]
    {
        let t = NSDate()
        var queue : [ProdukLokal] = []
        let rawQueue = getRawQueue()
        for raw in rawQueue
        {
            if let param = raw[ProdukLokal.KEY_PARAM] as? [String : String!], images = raw[ProdukLokal.KEY_IMAGES] as? [AnyObject], mixpanelParam = raw[ProdukLokal.KEY_MIXPANEL_PARAM] as? [NSObject : AnyObject]
            {
                let p = ProdukLokal(produkParam: param, produkImages: images, mixpanelParam: mixpanelParam)
                queue.append(p)
            }
        }
        
        print("getting queue took \(NSDate().timeIntervalSinceDate(t)) seconds")
        return queue
    }
    
    private func saveQueue(queue : [ProdukLokal])
    {
        var rawQueue : [[String : AnyObject]] = []
        for p in queue
        {
            rawQueue.append(p.toDictionary)
        }
        
        saveRawQueue(rawQueue)
    }
    
    private func getRawQueue() -> [[String : AnyObject]]
    {
        var savedQueueRaw : [[String : AnyObject]] = []
        if let data = NSUserDefaults.standardUserDefaults().objectForKey(KEY_LIST_PRODUKLOKAL) as? NSData
        {
            if let dataToArray = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [[String:AnyObject]]
            {
                savedQueueRaw = dataToArray
            }
        }
        
        return savedQueueRaw
    }
    
    private func saveRawQueue(rawQueue : [[String : AnyObject]])
    {
        let data = NSKeyedArchiver.archivedDataWithRootObject(rawQueue)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: KEY_LIST_PRODUKLOKAL)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}

extension NSThread
{
    static func sleepFor(second : NSTimeInterval, onWakeUp : () -> ())
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            NSThread.sleepForTimeInterval(second)
            dispatch_async(dispatch_get_main_queue(), {
                onWakeUp()
            })
        })
    }
}
