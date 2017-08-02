//
//  PreloAnalyticEndpoints.swift
//  Prelo
//
//  Created by Djuned on 2/20/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire

var preloAnalyticHost : String {
get {
    return "\(AnalyticManager.PreloAnalyticBaseUrl)/api/"
}
}

class PreloAnalyticEndpoints: NSObject {
    class func ProcessParam(_ oldParam : [String : Any]) -> [String : Any] {
        // Set crashlytics custom keys
        Crashlytics.sharedInstance().setObjectValue(oldParam, forKey: "last_req_param")
        
        return oldParam
    }
    
    static func validate(_ showErrorDialog : Bool, dataResp : DataResponse<Any>, reqAlias : String) -> Bool {
        //let req = dataResp.request!
        let resp = dataResp.response
        let res = dataResp.result.value
        let err = dataResp.result.error
        
        // Set crashlytics custom keys
        Crashlytics.sharedInstance().setObjectValue(reqAlias, forKey: "last_req_alias")
        Crashlytics.sharedInstance().setObjectValue(res, forKey: "last_api_result")
        if let resJson = (res as? JSON) {
            Crashlytics.sharedInstance().setObjectValue(resJson.stringValue, forKey: "last_api_result_string")
        }
        
        //print("\(reqAlias) req = \(req)")
        
        if let response = resp {
            if (response.statusCode != 200) {
                if (res != nil) {
                    if let msg = JSON(res!)["_message"].string {
                        if (showErrorDialog) {
                            Constant.showDialog(reqAlias, message: msg)
                        }
                        //print("\(reqAlias) _message = \(msg)")
                        
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
        
        if let _ = err {
            if (showErrorDialog) {
                Constant.showDialog(reqAlias, message: "Oops, terdapat kesalahan, silahkan coba beberapa saat lagi")
            }
            //print("\(reqAlias) err = \(error.localizedDescription)")
            return false
        } else {
            //let json = JSON(res!)
            //let data = json["_data"]
            //print("\(reqAlias) _data = \(data)")
            return true
        }
    }
}

extension URLRequest {
    func defaultAnalyticURLRequest() -> URLRequest {
        var urlRequest = URLRequest(url: self.url!)
        
        // Set token
        urlRequest.setValue("Token \(AnalyticManager.PreloAnalyticToken)", forHTTPHeaderField: "Authorization")
        
        // Set user agent
        if let userAgent = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String {
            urlRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        
        // Set crashlytics custom key
        Crashlytics.sharedInstance().setObjectValue(urlRequest, forKey: "last_req_url")
        
        return urlRequest
    }
}

enum APIAnalytic : URLRequestConvertible {
    case eventWithUserId(eventType: String, data: [String : Any], userId: String)
    case event(eventType: String, data: [String : Any])
    case eventOpenApp
    case userRegister(registerMethod: String, metadata: JSON)
    case userInit(userProfileData: UserProfile)
    case userUpdate(phone: String)
    case user(isNeedPayload: Bool)
    
    public func asURLRequest() throws -> URLRequest {
        //convert the JSON to a raw String
//        let prettyJSONstring = JSON(param).rawString()
//        let JSONstring = prettyJSONstring!.replace("\n", template: "")
        
        let JSONString = AppToolsObjC.jsonString(from:param)
        
        let curparam : [String : Any] = [ "payload" : JSONString! ]
        
        let basePath = "analytics/"
        let url = URL(string: preloAnalyticHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultAnalyticURLRequest()
        urlRequest.httpMethod = method.rawValue
        
        // stringify (cara 2)
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloAnalyticEndpoints.ProcessParam(curparam))
        
        // stringify (cara 1) -- error untuk caracter tertentu -> + &
//        urlRequest.httpBody = ("payload=" + JSONstring).data(using: String.Encoding.ascii, allowLossyConversion: true)
//        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: nil)
        
        // original -- error beda representasi
//        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloAnalyticEndpoints.ProcessParam(param))
        
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        return .post
    }
    
    var path : String {
        switch self {
        case .eventWithUserId(_, _, _),
             .event(_, _),
             .eventOpenApp
                : return "event"
        case .userRegister(_, _),
             .userInit(_),
             .userUpdate(_),
             .user(_)
                : return "user"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .eventWithUserId(let eventType, let data, let userId):
            p = [
                "user_id" : userId,
                "fa_id" : AnalyticManager.faId,
                "device_id" : AnalyticManager.faId,
                "event_type" : eventType,
                "data" : data
            ]
        case .event(let eventType, let data):
            p = [
                "user_id" : (User.IsLoggedIn ? User.Id! : ""),
                "fa_id" : AnalyticManager.faId,
                "device_id" : AnalyticManager.faId,
                "event_type" : eventType,
                "data" : data
            ]
        case .eventOpenApp:
            p = [
                "user_id" : (User.IsLoggedIn ? User.Id! : ""),
                "fa_id" : AnalyticManager.faId,
                "device_id" : AnalyticManager.faId,
                "event_type" : PreloAnalyticEvent.OpenApp,
                "collapsible" : true
            ]
        case .userRegister(let registerMethod, let metadata):
            let d : [String : [String : Any]] =  [
                "device_model" : [
                    "append" : AnalyticManager.deviceModel
                ],
                "apns_id" : [
                    "append" : AnalyticManager.deviceToken
                ],
                "username" : [
                    "update" : metadata["username"].stringValue
                ],
                "name" : [
                    "append" : metadata["fullname"].stringValue
                ],
                "email" : [
                    "update" : metadata["email"].stringValue
                ],
                "register_method" : [
                    "update" : registerMethod
                ],
                "register_time" : [
                    "update" : AnalyticManager.sharedInstance.getCurrentTime()
                ]
            ]
            p = [
                "user_id" : metadata["_id"].stringValue,
                "fa_id" : AnalyticManager.faId,
                "device_id" : AnalyticManager.faId,
                "username" : metadata["username"].stringValue,
                "data" : d
            ]
        case .userInit(let userProfileData):
            let a : [String : Any] = [
                "province" : CDProvince.getProvinceNameWithID(userProfileData.provinceId)!,
                "region" : CDRegion.getRegionNameWithID(userProfileData.regionId)!,
                "subdistrict" : userProfileData.subdistrictName
            ]
            let d : [String : [String : Any]] =  [
                "device_model" : [
                    "append" : AnalyticManager.deviceModel
                ],
                "apns_id" : [
                    "append" : AnalyticManager.deviceToken
                ],
                "username" : [
                    "update" : userProfileData.username
                ],
                "name" : [
                    "append" : userProfileData.fullname
                ],
                "email" : [
                    "update" : userProfileData.email
                ],
                "gender" : [
                    "update" : userProfileData.gender
                ],
                "address" : a,
                "last_login" : [
                    "update" : AnalyticManager.sharedInstance.getCurrentTime()
                ]
            ]
            p = [
                "user_id" : userProfileData.id,
                "fa_id" : AnalyticManager.faId,
                "device_id" : AnalyticManager.faId,
                "username" : userProfileData.username,
                "data" : d
            ]
        case .userUpdate(let phone):
            let _user = CDUser.getOne()
            let d : [String : [String : Any]] =  [
                "device_model" : [
                    "append" : AnalyticManager.deviceModel
                ],
                "apns_id" : [
                    "append" : AnalyticManager.deviceToken
                ],
                "phone" : [
                    "update" : phone
                ],
                "last_login" : [
                    "update" : AnalyticManager.sharedInstance.getCurrentTime()
                ]
            ]
            p = [
                "user_id" : (User.Id != nil ? User.Id! : (_user?.id)!),
                "fa_id" : AnalyticManager.faId,
                "device_id" : AnalyticManager.faId,
                "username" : (_user?.username)!,
                "data" : d
            ]
        case .user(let isNeedPayload) :
            let _user = CDUser.getOne()
            var d : [String : [String : Any]] = [:]
            if (isNeedPayload) {
                let regionName = CDRegion.getRegionNameWithID((_user?.profiles.regionID)!) ?? ""
                let provinceName = CDProvince.getProvinceNameWithID((_user?.profiles.provinceID)!) ?? ""
                let a : [String : Any] = [
                    "province" : provinceName,
                    "region" : regionName,
                    "subdistrict" : (_user?.profiles.subdistrictName)!
                ]
                d =  [
                    "device_model" : [
                        "append" : AnalyticManager.deviceModel
                    ],
                    "apns_id" : [
                        "append" : AnalyticManager.deviceToken
                    ],
                    "username" : [
                        "update" : (_user?.username)!
                    ],
                    "name" : [
                        "append" : (_user?.fullname)!
                    ],
                    "email" : [
                        "update" : (_user?.email)!
                    ],
                    "gender" : [
                        "update" : (_user?.profiles.gender)!
                    ],
                    "phone" : [
                        "update" : (_user?.profiles.phone)!
                    ],
                    "address" : a,
                    "last_login" : [
                        "update" : AnalyticManager.sharedInstance.getCurrentTime()
                    ]
                ]
            } else {
                d =  [
                    "device_model" : [
                        "append" : AnalyticManager.deviceModel
                    ],
                    "apns_id" : [
                        "append" : AnalyticManager.deviceToken
                    ],
                    "last_login" : [
                        "update" : AnalyticManager.sharedInstance.getCurrentTime()
                    ]
                ]
            }
            p = [
                "user_id" : (User.Id != nil ? User.Id! : (_user?.id)!),
                "fa_id" : AnalyticManager.faId,
                "device_id" : AnalyticManager.faId,
                "username" : (_user?.username)!,
                "data" : d
            ]
        }
        //print(p.debugDescription)
        return p
    }
}
