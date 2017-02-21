//
//  PreloAnalyticEndpoints.swift
//  Prelo
//
//  Created by Djuned on 2/20/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire

var preloAnalyticHost : String {
get {
    return "\(AnalyticManager.sharedInstance.PreloAnalyticBaseUrl)/api/"
}
}

class PreloAnalyticEndpoints: NSObject {
    class func ProcessParam(_ oldParam : [String : Any]) -> [String : Any] {
        // Set crashlytics custom keys
        Crashlytics.sharedInstance().setObjectValue(oldParam, forKey: "last_req_param")
        
        return oldParam
    }
    
    static func validate(_ showErrorDialog : Bool, dataResp : DataResponse<Any>, reqAlias : String) -> Bool {
        let req = dataResp.request!
        let resp = dataResp.response
        let res = dataResp.result.value
        let err = dataResp.result.error
        
        // Set crashlytics custom keys
        Crashlytics.sharedInstance().setObjectValue(reqAlias, forKey: "last_req_alias")
        Crashlytics.sharedInstance().setObjectValue(res, forKey: "last_api_result")
        if let resJson = (res as? JSON) {
            Crashlytics.sharedInstance().setObjectValue(resJson.stringValue, forKey: "last_api_result_string")
        }
        
        print("\(reqAlias) req = \(req)")
        
        if let response = resp {
            if (response.statusCode != 200) {
                if (res != nil) {
                    if let msg = JSON(res!)["_message"].string {
                        if (showErrorDialog) {
                            Constant.showDialog(reqAlias, message: msg)
                        }
                        print("\(reqAlias) _message = \(msg)")
                        
                        if (msg.lowercased() == "user belum login") {
                            User.Logout()
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            if let childVCs = appDelegate.window?.rootViewController?.childViewControllers {
                                let rootVC = childVCs[0]
                                let uiNavigationController : UINavigationController? = rootVC as? UINavigationController
                                //let kumangTabBarVC : KumangTabBarViewController? = childVCs[0].viewControllers![0] as? KumangTabBarViewController
                                let kumangTabBarVC : KumangTabBarViewController? = (childVCs[0] as? UINavigationController)?.viewControllers[0] as? KumangTabBarViewController
                                if (uiNavigationController != nil && kumangTabBarVC != nil) {
                                    uiNavigationController!.popToRootViewController(animated: true)
                                    LoginViewController.Show(rootVC, userRelatedDelegate: kumangTabBarVC, animated: true)
                                }
                            }
                        }
                    }
                } else if (res == nil && showErrorDialog) {
                    if (response.statusCode > 500) {
                        Constant.showDialog(reqAlias, message: "Server Analytic Prelo sedang lelah, silahkan coba beberapa saat lagi")
                    } else {
                        Constant.showDialog(reqAlias, message: "Oops, silahkan coba beberapa saat lagi")
                    }
                }
                return false
            }
        }
        
        if (res == nil) {
            if (showErrorDialog) {
                Constant.showDialog(reqAlias, message: "Oops, tidak ada respon, silahkan coba beberapa saat lagi")
            }
            return false
        }
        
        if let error = err {
            if (showErrorDialog) {
                Constant.showDialog(reqAlias, message: "Oops, terdapat kesalahan, silahkan coba beberapa saat lagi")
            }
            print("\(reqAlias) err = \(error.localizedDescription)")
            return false
        } else {
            let json = JSON(res!)
            let data = json["_data"]
            print("\(reqAlias) _data = \(data)")
            return true
        }
    }
}

extension URLRequest {
    func defaultAnalyticURLRequest() -> URLRequest {
        var urlRequest = URLRequest(url: self.url!)
        
        // Set token
        urlRequest.setValue("Token \(AnalyticManager.sharedInstance.token)", forHTTPHeaderField: "Authorization")
        
        // Set user agent
        if let userAgent = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String {
            urlRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        
        // ERR
//        // json
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set crashlytics custom key
        Crashlytics.sharedInstance().setObjectValue(urlRequest, forKey: "last_req_url")
        
        return urlRequest
    }
}

enum APIAnalytic : URLRequestConvertible {
    case event(eventType: String, data: [String : Any])
    case user
    
    public func asURLRequest() throws -> URLRequest {
        //convert the JSON to a raw String
        let prettyJSONstring = JSON(param).rawString()
        let JSONstring = prettyJSONstring!.replace("\n", template: "")
        
        let basePath = "analytics/"
        let url = URL(string: preloAnalyticHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultAnalyticURLRequest()
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = ("payload = " + JSONstring).data(using: String.Encoding.ascii, allowLossyConversion: true)
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: nil)
//        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloAnalyticEndpoints.ProcessParam(param))
        
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .event(_, _) : return .post
        case .user : return .post
        }
    }
    
    var path : String {
        switch self {
        case .event(_, _) : return "event"
        case .user : return "user"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .event(let eventType, let data) :
            p = [
                "user_id" : (User.IsLoggedIn ? User.Id! : ""),
                "fa_id" : UIDevice.current.identifierForVendor!.uuidString,
                "device_id" : UIDevice.current.identifierForVendor!.uuidString,
                "event_type" : eventType,
                "data" : data
            ]
        case .user :
            let _user = CDUser.getOne()
            let regionName = CDRegion.getRegionNameWithID((_user?.profiles.regionID)!) ?? ""
            let deviceToken = (User.IsLoggedIn && UserDefaults.standard.string(forKey: "deviceregid") != nil ? UserDefaults.standard.string(forKey: "deviceregid")! : "")
            let d : [String : [String : Any]] =  [
                "device_model" : [
                    "append" : UIDevice.current.model + " - " + UIDevice.current.systemName + " (" + UIDevice.current.systemVersion + ")"
                ],
                "apns_id" : [
                    "append" : deviceToken
                ],
                "region" : [
                    "update" : regionName
                ]
            ]
            p = [
                "user_id" : (User.IsLoggedIn ? User.Id! : ""),
                "fa_id" : UIDevice.current.identifierForVendor!.uuidString,
                "device_id" : UIDevice.current.identifierForVendor!.uuidString,
                "username" : (User.IsLoggedIn ? (_user?.username)! : ""),
                "data" : d
            ]
        }
        print(p.debugDescription)
//        print(p.description)
        return p
    }
}
