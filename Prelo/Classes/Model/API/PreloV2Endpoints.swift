//
//  PreloV2Endpoints.swift
//  Prelo
//
//  Created by Djuned on 4/26/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire

var preloHostV2 : String {
    get {
        return "\(AppTools.PreloBaseUrl)/api/v2/"
    }
}

class PreloV2Endpoints: NSObject {
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
                        Constant.showDialog(reqAlias, message: "Server Prelo sedang lelah, silahkan coba beberapa saat lagi")
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
    func defaultV2URLRequest() -> URLRequest {
        var urlRequest = URLRequest(url: self.url!)
        
        // Set token
        if let token = User.Token {
            urlRequest.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
            print("User token = \(token)")
        }
        
        // Set user agent
        if let userAgent = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String {
            urlRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        
        // Set crashlytics custom key
        Crashlytics.sharedInstance().setObjectValue(urlRequest, forKey: "last_req_url")
        
        return urlRequest
    }
}

enum APICartV2 : URLRequestConvertible {
    case refresh(cart : String, address : String, voucher : String?)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "cart/"
        let url = URL(string: preloHostV2)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultV2URLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .refresh(_, _, _) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .refresh(_, _, _) : return ""
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .refresh(let cart, let address, let voucher) :
            p = [
                "cart_products":cart,
                "shipping_address":address,
                "voucher_serial":(voucher == nil) ? "" : voucher!,
                "platform_sent_from" : "ios"
            ]
        }
        return p
    }
}
