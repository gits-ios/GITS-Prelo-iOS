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
    
    let token = "ZldVDK0Xca1v_osoTSiCdCngZ_r7iR1ZW6fpC3BscfCuHOYUYjLrlw"
    
    let devAnalyticURL = "http://analytics.dev.prelo.id"
    let prodAnalyticURL = "https://analytics.prelo.co.id"
    
    var isShowDialog = true
    
    var PreloAnalyticBaseUrl : String {
        return (AppTools.isDev ? devAnalyticURL : prodAnalyticURL)
    }
    
    // skeleton data -- copy it to your temporer data
    let skeletonData =  [
        "OS" : UIDevice.current.systemVersion,
        "App version" : CDVersion.getOne()!.appVersion,
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
 
        /*
        let userAgent = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String ?? ""
        
        let headers = [
            "Authorization": "Token \(self.token)",
            "User-Agent": userAgent
        ]
        
        let p = [
            "user_id" : (User.IsLoggedIn ? User.Id! : ""),
            "fa_id" : UIDevice.current.identifierForVendor!.uuidString,
            "device_id" : UIDevice.current.identifierForVendor!.uuidString,
            "event_type" : eventType,
            "data" : wrappedData
        ] as [String : Any]
        
        // create a custom session configuration
        let configuration = URLSessionConfiguration.default
        // add the headers
        configuration.httpAdditionalHeaders = headers
        
        // create a session manager with the configuration
        let sessionManager = Alamofire.SessionManager(configuration: configuration)
        
        // make calls with the session manager
        sessionManager.request("\(self.PreloAnalyticBaseUrl)/api/analytics/event", method: .post, parameters: p, encoding: JSONEncoding.default)
            .responseJSON { response in
                print(response)
                //to get status code
                if let status = response.response?.statusCode {
                    switch(status){
                    case 201:
                        print("example success")
                    default:
                        print("error with response status: \(status)")
                    }
                }
                //to get JSON return value
                if let result = response.result.value {
                    let JSON = result as! NSDictionary
                    print(JSON)
                }
                
        }
         */
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
    
    /*
    // helper
    func dictToJSON(dict:[String: AnyObject]) -> AnyObject {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        let decoded = try! JSONSerialization.jsonObject(with: jsonData, options: [])
        return decoded as AnyObject
    }
    
    func arrayToJSON(array:[String]) -> AnyObject {
        let jsonData = try! JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
        let decoded = try! JSONSerialization.jsonObject(with: jsonData, options: [])
        return decoded as AnyObject
    }
     */
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}
