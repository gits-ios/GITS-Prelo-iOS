//
//  AnalyticManager.swift
//  Prelo
//
//  Created by Djuned on 2/20/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

class AnalyticManager: NSObject {
    static let sharedInstance = AnalyticManager()
    
    let devAnalyticURL = "http://dev.prelo.id"
    let prodAnalyticURL = "https://prelo.co.id"
    
    var isShowDialog = false
    
    var PreloAnalyticBaseUrl : String {
        return (AppTools.isDev ? devAnalyticURL : prodAnalyticURL)
    }
    
    // skeleton data -- copy it to your temporer data
    let skeletonData =  [
        "OS" : UIDevice.current.systemVersion,
        "App version" : CDVersion.getOne()!,
        "Device Model" : UIDevice.current.model,
        //"Previous Screen" : "", // override it
        //"Login Method" : "" // override it
    ] as [String : Any]
    
    // send record to Analytic Server
    func send(eventType : String, data : [String : Any], previousScreen : String, loginMethod : String) {
        var wrappedData = skeletonData
        
        // still skeleton
        wrappedData["Previous Screen"] = previousScreen
        wrappedData["Login Method"] = loginMethod
        
        wrappedData.update(other: data)
        
        let _ = request(APIAnalytic.event(eventType: eventType, data: wrappedData)).responseJSON {resp in
            if (PreloAnalyticEndpoints.validate(self.isShowDialog, dataResp: resp, reqAlias: "Analytics - " + eventType)) {
                print("Analytics - " + eventType + ", Sent!")
                if self.isShowDialog {
                    Constant.showDialog("Analytics - " + eventType, message: "Success")
                }
            }
        }
    }
    
    func updateUser() {
        let _ = request(APIAnalytic.user).responseJSON {resp in
            if (PreloAnalyticEndpoints.validate(self.isShowDialog, dataResp: resp, reqAlias: "Analytics - User")) {
                print("Analytics - User, Sent!")
                if self.isShowDialog {
                    Constant.showDialog("Analytics - User", message: "Success")
                }
            }
        }
    }
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}
