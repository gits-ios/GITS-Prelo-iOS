//
//  ProdukUploader.swift
//  Prelo
//
//  Created by Rahadian Kumang on 25/5/16.
//  Copyright © 2016 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class ProdukUploader: NSObject {

    static let ProdukUploader_NOTIFICATION_UPLOAD_SUCCESS = "ProdukUploader_NOTIFICATION_UPLOAD_SUCCESS"
    static let ProdukUploader_NOTIFICATION_UPLOAD_FAILED = "ProdukUploader_NOTIFICATION_UPLOAD_FAILED"
    
    /*
     Notification Object is JSON Dictionary
    */
    static func AddObserverForUploadSuccess(_ observer : NSObject, selector : Selector)
    {
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: ProdukUploader_NOTIFICATION_UPLOAD_SUCCESS), object: nil)
    }
    
    static func RemoveObserverForUploadSuccess(_ observer : NSObject)
    {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: ProdukUploader_NOTIFICATION_UPLOAD_SUCCESS), object: nil)
    }
    
    /*
     Notification Object is NSError
    */
    static func AddObserverForUploadFailed(_ observer : NSObject, selector : Selector)
    {
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: ProdukUploader_NOTIFICATION_UPLOAD_FAILED), object: nil)
    }
    
    static func RemoveObserverForUploadFailed(_ observer : NSObject)
    {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: ProdukUploader_NOTIFICATION_UPLOAD_FAILED), object: nil)
    }
    
    let KEY_LIST_PRODUKLOKAL = "KEY_LIST_PRODUKLOKAL"
    
    struct ProdukLokal {
        
        static let KEY_PARAM = "param"
        static let KEY_IMAGES = "images"
        static let KEY_MIXPANEL_PARAM = "mixpanelParam"
        
        init(produkParam : [String : String?], produkImages : [AnyObject], mixpanelParam : [AnyHashable: Any])
        {
            self.param = produkParam
            self.images = produkImages
            self.mixpanelParam = mixpanelParam
        }
        
        init(produkParam : [String : String?], produkImages : [AnyObject], preloAnalyticParam : [AnyHashable: Any])
        {
            self.param = produkParam
            self.images = produkImages
            self.mixpanelParam = preloAnalyticParam
        }
        
        var param : [String : String?] = [:]
        var images : [AnyObject] = []
        var mixpanelParam : [AnyHashable: Any] = [:]
        
        var toDictionary : [String : AnyObject] {
            return ["param":param as AnyObject, "images":images as AnyObject, "mixpanelParam":mixpanelParam as AnyObject]
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
        case idle
        case failed
        case uploading
    }
    
    var currentStatus : ProdukUploaderStatus = .idle
    
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
    
    func start(_ onLoop : Bool = false)
    {
        let t = Date()
        if (!onLoop) // onLoop == false artinya fungsi start() dipanggil dari code lain, buka recursive
        {
            stop()
        }
        
        if let p = getQueue().first
        {
            // UPDATE to v2 -> http://dev.prelo.id/docs/#api-Product-addProductV2
            let url = "\(AppTools.PreloBaseUrl)/api/v2/product"
            let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
            
            currentStatus = .uploading
            //print("starting produk upload took \(Date().timeIntervalSince(t)) seconds")
            currentUploadManager = AppToolsObjC.sendMultipart2(p.param, images: p.images, withToken: User.Token!, andUserAgent: userAgent!, to:url, success: {op, res in
                
                //print("queue upload success :")
                //print((res ?? ""))
                self.currentRetryCount = 0
                
                /*
                // Mixpanel
                Mixpanel.trackEvent(MixpanelEvent.AddedProduct, properties: p.mixpanelParam)
                 */
                
                var queue = self.getQueue()
                if (queue.count > 1)
                {
                    queue.removeFirst()
                    self.saveQueue(queue)
                    //print("queue : move to next product!")
                    self.start(true)
                } else
                {
                    self.saveQueue([])
                    //print("Queue finished!")
                }
                
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: ProdukUploader.ProdukUploader_NOTIFICATION_UPLOAD_SUCCESS), object: [ res , p.mixpanelParam ])
                })
                
            }, failure: { op, err in
                //print((err ?? ""))
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
                        //print("queue : move to next product!")
                        self.start(true)
                    } else
                    {
                        self.saveQueue([])
                        //print("Queue finished!")
                    }
                    
                    self.currentRetryCount = 0
                    DispatchQueue.main.async(execute: {
                        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: ProdukUploader.ProdukUploader_NOTIFICATION_UPLOAD_FAILED), object: [ err as Any , p.mixpanelParam ])
                    })
                }
            })
        } else
        {
            //print("Queue is empty")
        }
    }
    
    func stop()
    {
        currentUploadManager?.operationQueue.cancelAllOperations()
    }
    
    func clearQueue()
    {
        stop()
        saveRawQueue(ProdukRawQueue(val: []))
    }
    
    func addToQueue(_ produk : ProdukLokal)
    {
        let t = Date()
        let rawQueue = getRawQueue()
        rawQueue.val.append(produk.toDictionary)
        saveRawQueue(rawQueue)
        
        //print("adding queue took \(Date().timeIntervalSince(t)) seconds")
        
        if (rawQueue.val.count >= 1)
        {
            DispatchQueue.main.async(execute: {
                self.start()
            })
        }
    }
    
    func getQueue() -> [ProdukLokal]
    {
        let t = Date()
        var queue : [ProdukLokal] = []
        let rawQueue = getRawQueue()
        for raw in rawQueue.val
        {
            if let param = raw[ProdukLokal.KEY_PARAM] as? [String : String?], let images = raw[ProdukLokal.KEY_IMAGES] as? [AnyObject], let mixpanelParam = raw[ProdukLokal.KEY_MIXPANEL_PARAM] as? [AnyHashable: Any]
            {
                let p = ProdukLokal(produkParam: param, produkImages: images, mixpanelParam: mixpanelParam)
                queue.append(p)
            }
        }
        
        //print("getting queue took \(Date().timeIntervalSince(t)) seconds")
        return queue
    }
    
    fileprivate func saveQueue(_ queue : [ProdukLokal])
    {
        let rawQueue = ProdukRawQueue(val: [])
        for p in queue
        {
            rawQueue.val.append(p.toDictionary)
        }
        
        saveRawQueue(rawQueue)
    }
    
    fileprivate func getRawQueue() -> ProdukRawQueue
    {
        var savedQueueRaw = ProdukRawQueue(val: [])
        if let data = UserDefaults.standard.object(forKey: KEY_LIST_PRODUKLOKAL) as? Data
        {
            if let dataToArray = NSKeyedUnarchiver.unarchiveObject(with: data) as? ProdukRawQueue
            {
                savedQueueRaw = dataToArray
            }
        }
        
        return savedQueueRaw
    }
    
    fileprivate func saveRawQueue(_ rawQueue : ProdukRawQueue)
    {
        let data = NSKeyedArchiver.archivedData(withRootObject: rawQueue)
        UserDefaults.standard.set(data, forKey: KEY_LIST_PRODUKLOKAL)
        UserDefaults.standard.synchronize()
    }
    
}

extension Thread
{
    static func sleepFor(_ second : TimeInterval, onWakeUp : @escaping () -> ())
    {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            Thread.sleep(forTimeInterval: second)
            DispatchQueue.main.async(execute: {
                onWakeUp()
            })
        }
    }
}

class ProdukRawQueue: NSObject, NSCoding
{
    var val: [[String : AnyObject]] = [] // Array of product
    var nsVal : NSMutableArray = NSMutableArray()
    
    init(val: [[String : AnyObject]])
    {
        self.val = val
    }
    
    // MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        nsVal = NSMutableArray()
        for p in val {
            //print("obj = \(p)")
            ////print("images : " + "\(p["images"])")
            ////print("param : " + "\(p["param"])")
            ////print("mixpanelParam : " + "\(p["mixpanelParam"])")
            nsVal.add(p as [String : AnyObject])
        }
        aCoder.encode(nsVal, forKey: "nsVal")
    }
    
    required init(coder aDecoder: NSCoder) {
        self.nsVal = aDecoder.decodeObject(forKey: "nsVal") as! NSMutableArray
        val = []
        val = nsVal.flatMap({ $0 as? [String : AnyObject] })
    }
}

