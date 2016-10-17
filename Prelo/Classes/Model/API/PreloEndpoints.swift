//
//  PreloEndpoints.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/23/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire

var preloHost : String {
    get {
        return "\(AppTools.PreloBaseUrl)/api/"
    }
}

class PreloEndpoints: NSObject {
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
    func defaultURLRequest() -> URLRequest {
        var urlRequest = URLRequest(url: self.url!)
        
        // Set token
        if let token = User.Token {
            urlRequest.setValue("Token ", forHTTPHeaderField: "Authorization")
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

enum APIApp : URLRequestConvertible {
    case version
    case metadata(brands : String, categories : String, categorySizes : String, shippings : String, productConditions : String, provincesRegions : String)
    case metadataCategories(currentVer : Int)
    case metadataProductConditions
    case metadataProvincesRegions(currentVer : Int)
    case metadataShippings
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "app/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .version : return .get
        case .metadata(_, _, _, _, _, _) : return .get
        case .metadataCategories(_) : return .get
        case .metadataProductConditions : return .get
        case .metadataProvincesRegions(_) : return .get
        case .metadataShippings : return .get
        }
    }
    
    var path : String {
        switch self {
        case .version : return "version"
        case .metadata(_, _, _, _, _, _) : return "metadata"
        case .metadataCategories(_) : return "metadata/categories"
        case .metadataProductConditions : return "metadata/product_condition"
        case .metadataProvincesRegions(_) : return "metadata/provinces_regions"
        case .metadataShippings : return "metadata/shippings"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .version :
            p = [
                "app_type" : "ios"
            ]
        case .metadata(let brands, let categories, let categorySizes, let shippings, let productConditions, let provincesRegions) :
            p = [
                "brands" : brands,
                "categories" : categories,
                "cateogry_sizes" : categorySizes,
                "shippings" : shippings,
                "product_conditions" : productConditions,
                "provinces_regions" : provincesRegions
            ]
        case .metadataCategories(let currentVer) :
            p = [
                "current_version" : currentVer
            ]
        case .metadataProvincesRegions(let currentVer) :
            p = [
                "current_version" : currentVer
            ]
        default : break
        }
        return p
    }
}

enum APIAuth : URLRequestConvertible {
    case register(username : String, fullname : String, email : String, password : String)
    case login(email : String, password : String)
    case loginFacebook(email : String, fullname : String, fbId : String, fbUsername : String, fbAccessToken : String)
    case loginPath(email : String, fullname : String, pathId : String, pathAccessToken : String)
    case loginTwitter(email : String, fullname : String, username : String, id : String, accessToken : String, tokenSecret : String)
    case logout
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "auth/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .register(_, _, _, _) : return .post
        case .login(_, _) : return .post
        case .loginFacebook(_, _, _, _, _) : return .post
        case .loginPath(_, _, _, _) : return .post
        case .loginTwitter(_, _, _, _, _, _) : return .post
        case .logout : return .post
        }
    }
    
    var path : String {
        switch self {
        case .register(_, _, _, _) : return "register"
        case .login(_, _) : return "login"
        case .loginFacebook(_, _, _, _, _) : return "login/facebook"
        case .loginPath(_, _, _, _) : return "login/path"
        case .loginTwitter(_, _, _, _, _, _) : return "login/twitter"
        case .logout : return "logout"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .register(let username, let fullname, let email, let password) :
            p = [
                "username" : username,
                "fullname" : fullname,
                "email" : email,
                "password" : password,
                "device_id" : UIDevice.current.identifierForVendor!.uuidString,
                "fa_id" : UIDevice.current.identifierForVendor!.uuidString
            ]
        case .login(let usernameOrEmail, let password) :
            p = [
                "username_or_email" : usernameOrEmail,
                "password" : password
            ]
        case .loginFacebook(let email, let fullname, let fbId, let fbUsername, let fbAccessToken) :
            p = [
                "email" : email,
                "fullname" : fullname,
                "fb_id" : fbId,
                "fb_username" : fbUsername,
                "fb_access_token" : fbAccessToken
            ]
        case .loginPath(let email, let fullname, let pathId, let pathAccessToken) :
            p = [
                "email" : email,
                "fullname" : fullname,
                "path_id" : pathId,
                "path_access_token" : pathAccessToken
            ]
        case .loginTwitter(let email, let fullname, let username, let id, let accessToken, let tokenSecret) :
            p = [
                "email" : email,
                "fullname" : fullname,
                "twitter_username" : username,
                "twitter_id" : id,
                "twitter_access_token" : accessToken,
                "twitter_token_secret" : tokenSecret
            ]
        default : break
        }
        return p
    }
}

enum APICart : URLRequestConvertible {
    case refresh(cart : String, address : String, voucher : String?)
    case checkout(cart : String, address : String, voucher : String?, payment : String, usedPreloBalance : Int, usedReferralBonus : Int, kodeTransfer : Int, ccOrderId : String)
    case generateVeritransUrl(cart : String, address : String, voucher : String?, payment : String, usedPreloBalance : Int, usedReferralBonus : Int, kodeTransfer : Int)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "cart/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .refresh(_, _, _) : return .post
        case .checkout(_, _, _, _, _, _, _, _) : return .post
        case .generateVeritransUrl(_, _, _, _, _, _, _) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .refresh(_, _, _) : return ""
        case .checkout(_, _, _, _, _, _, _, _) : return "checkout"
        case .generateVeritransUrl(_, _, _, _, _, _, _) : return "generate_veritrans_url"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .refresh(let cart, let address, let voucher) :
            p = [
                "cart_products":cart,
                "shipping_address":address,
                "voucher_serial":(voucher == nil) ? "" : voucher!
            ]
        case .checkout(let cart, let address, let voucher, let payment, let usedBalance, let usedBonus, let kodeTransfer, let ccOrderId) :
            p = [
                "cart_products":cart,
                "shipping_address":address,
                "banktransfer_digit":NSNumber(value: 1 as Int),
                "voucher_serial":(voucher == nil) ? "" : voucher!,
                "payment_method":payment
                ] as [String : Any]
            if usedBalance != 0 {
                p["prelobalance_used"] = NSNumber(value: usedBalance as Int)
            }
            if kodeTransfer != 0 {
                p["banktransfer_digit"] = NSNumber(value: kodeTransfer as Int)
            }
            if usedBonus != 0 {
                p["bonus_used"] = NSNumber(value: usedBonus as Int)
            }
            if ccOrderId != "" {
                p["order_id"] = ccOrderId
            }
        case .generateVeritransUrl(let cart, let address, let voucher, let payment, let usedBalance, let usedBonus, let kodeTransfer) :
            p = [
                "cart_products":cart,
                "shipping_address":address,
                "banktransfer_digit":NSNumber(value: 1 as Int),
                "voucher_serial":(voucher == nil) ? "" : voucher!,
                "payment_method":payment
                ] as [String : Any]
            if usedBalance != 0 {
                p["prelobalance_used"] = NSNumber(value: usedBalance as Int)
            }
            if kodeTransfer != 0 {
                p["banktransfer_digit"] = NSNumber(value: kodeTransfer as Int)
            }
            if usedBonus != 0 {
                p["bonus_used"] = NSNumber(value: usedBonus as Int)
            }
        }
        return p
    }
}

enum APIDemo : URLRequestConvertible {
    case homeCategories
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "demo/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .homeCategories : return .get
        }
    }
    
    var path : String {
        switch self {
        case .homeCategories : return "reference/categories/home"
        }
    }
    
    var param : [String : Any] {
        switch self {
        case .homeCategories : return [:]
        }
    }
}

enum APIGarageSale : URLRequestConvertible {
    case createReservation(productId : String)
    case cancelReservation(productId : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "garagesale/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .createReservation(_) : return .post
        case .cancelReservation(_) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .createReservation(_) : return "newreservation"
        case .cancelReservation(_) : return "cancelreservation"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .createReservation(let productId) :
            p = [
                "product_id" : productId
            ]
        case .cancelReservation(let productId) :
            p = [
                "product_id" : productId
            ]
        }
        return p
    }
}

enum APIInbox : URLRequestConvertible {
    case getInboxes
    case getInboxByProductID(productId : String)
    case getInboxByProductIDSeller(productId : String, buyerId : String)
    case getInboxMessage (inboxId : String)
    case startNewOne (productId : String, type : Int, message : String)
    case startNewOneBySeller (productId : String, type : Int, message : String, toId : String)
    case sendTo (inboxId : String, type : Int, message : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "inbox/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .getInboxByProductID(_) : return .get
        case .getInboxByProductIDSeller(_, _) : return .get
        case .getInboxes : return .get
        case .getInboxMessage(_) : return .get
        case .startNewOne (_, _, _) : return .post
        case .startNewOneBySeller (_, _, _, _) : return .post
        case .sendTo (_, _, _) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .getInboxByProductID(let prodId) : return ("product/" + prodId)
        case .getInboxByProductIDSeller(let prodId, _) : return ("product/buyer/" + prodId)
        case .getInboxMessage(let inboxId) : return inboxId
        case .sendTo (let inboxId, _, _) : return inboxId
        default : return ""
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .getInboxByProductIDSeller(_, let buyerId) :
            p = [
                "buyer_id" : buyerId
            ]
        case .startNewOne(let prodId, let type, let m) :
            p = [
                "product_id" : prodId,
                "message_type" : String(type),
                "message" : m
            ]
        case .startNewOneBySeller(let prodId, let type, let m, let toId) :
            p = [
                "product_id" : prodId,
                "message_type" : String(type),
                "message" : m,
                "to" : toId
            ]
        case .sendTo (_, let type, let message) :
            p = [
                "message_type" : type,
                "message" : message
            ]
        default : break
        }
        return p
    }
}

enum APIMe : URLRequestConvertible {
    case login(email : String, password : String)
    case register(fullname : String, email : String, password : String)
    case logout
    case me
    case orderList(status : String)
    case myProductSell
    case myLovelist
    case setupAccount(username : String, email: String, gender : Int, phone : String, province : String, region : String, subdistrict : String, shipping : String, referralCode : String, deviceId : String, deviceRegId : String)
    case setProfile(fullname : String, address : String, province : String, region : String, subdistrict : String, postalCode : String, description : String, shipping : String)
    case resendVerificationSms(phone : String)
    case verifyPhone(phone : String, phoneCode : String)
    case referralData
    case setReferral(referralCode : String, deviceId : String)
    case setDeviceRegId(deviceRegId : String)
    case setUserPreferencedCategories(categ1 : String, categ2 : String, categ3 : String)
    case checkPassword
    case resendVerificationEmail
    case getBalanceMutations(current : Int, limit : Int)
    case setUserUUID
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "me/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .login(_, _):return .post
        case .register(_, _, _): return .post
        case .logout:return .post
        case .me:return .get
        case .orderList(_):return .get
        case .myProductSell:return .get
        case .myLovelist : return .get
        case .setupAccount(_, _, _, _, _, _, _, _, _, _, _) : return .post
        case .setProfile(_, _, _, _, _, _, _, _) : return .post
        case .resendVerificationSms(_) : return .post
        case .verifyPhone(_, _) : return .post
        case .referralData : return .get
        case .setReferral(_, _) : return .post
        case .setDeviceRegId(_) : return .post
        case .setUserPreferencedCategories(_, _, _) : return .post
        case .checkPassword : return .get
        case .resendVerificationEmail : return .post
        case .getBalanceMutations(_, _) : return .get
        case .setUserUUID : return .post
        }
    }
    
    var path : String {
        switch self {
        case .login(_, _):return "login"
        case .register(_, _, _): return "register"
        case .logout:return "logout"
        case .me : return "profile"
        case .orderList(_):return "buy_list"
        case .myProductSell:return "products"
        case .myLovelist : return "lovelist"
        case .setupAccount(_, _, _, _, _, _, _, _, _, _, _) : return "setup"
        case .setProfile(_, _, _, _, _, _, _, _) : return "profile"
        case .resendVerificationSms(_) : return "verify/resend_phone"
        case .verifyPhone(_, _) : return "verify/phone"
        case .referralData : return "referral_bonus"
        case .setReferral(_, _) : return "referral"
        case .setDeviceRegId(_) : return "set_device_registration_id"
        case .setUserPreferencedCategories(_, _, _) : return "category_preference"
        case .checkPassword : return "checkpassword"
        case .resendVerificationEmail : return "verify/resend_email"
        case .getBalanceMutations(_, _) : return "getprelobalances"
        case .setUserUUID : return "setgafaid"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .login(let email, let password):
            p = [
                "email":email,
                "password":password
            ]
        case .register(let fullname, let email, let password):
            p = [
                "fullname":fullname,
                "email":email,
                "password":password
            ]
        case .orderList(let status):
            p = [
                "status":status
            ]
        case .setupAccount(let username, let email, let gender, let phone, let province, let region, let subdistrict, let shipping, let referralCode, let deviceId, let deviceRegId):
            p = [
                "username":username,
                "email":email,
                "phone":phone,
                "province":province,
                "region":region,
                "subdistrict":subdistrict,
                "shipping":shipping,
                "referral_code":referralCode,
                "device_id":deviceId,
                "device_registration_id":deviceRegId,
                "device_type":"APNS"
            ]
            if (gender == 0 || gender == 1) {
                p["gender"] = gender
            }
        case .setProfile(let fullname, let address, let province, let region, let subdistrict, let postalCode, let description, let shipping):
            p = [
                "fullname":fullname,
                "address":address,
                "province":province,
                "region":region,
                "subdistrict":subdistrict,
                "postal_code":postalCode,
                "description":description,
                "shipping":shipping
            ]
        case .resendVerificationSms(let phone) :
            p = [
                "phone" : phone
            ]
        case .verifyPhone(let phone, let phoneCode) :
            p = [
                "phone" : phone,
                "phone_code" : phoneCode
            ]
        case .setReferral(let referralCode, let deviceId) :
            p = [
                "referral_code" : referralCode,
                "device_id" : deviceId
            ]
        case .setDeviceRegId(let deviceRegId) :
            p = [
                "registered_device_id" : deviceRegId,
                "device_type" : "APNS"
            ]
        case .setUserPreferencedCategories(let categ1, let categ2, let categ3) :
            p = [
                "category1" : categ1,
                "category2" : categ2,
                "category3" : categ3
            ]
        case .getBalanceMutations(let current, let limit) :
            p = [
                "current" : current,
                "limit" : limit
            ]
        case .setUserUUID :
            p = [
                "fa_id" : UIDevice.current.identifierForVendor!.uuidString
            ]
        default : break
        }
        return p
    }
}

enum APIMisc : URLRequestConvertible {
    case getSubdistrictsByRegionID(id : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = ""
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .getSubdistrictsByRegionID(_) : return .get
        }
    }
    
    var path : String {
        switch self {
        case .getSubdistrictsByRegionID(let id) : return "subdistricts/region/\(id)"
        }
    }
    
    var param : [String : Any] {
        let p : [String : Any] = [:]
        switch self {
        default : break
        }
        return p
    }
}

enum APINotification : URLRequestConvertible {
    case getNotifs(tab : String, page : Int)
    case getNotifsSell(page : Int, name : String)
    case getNotifsBuy(page : Int, name : String)
    case getUnreadNotifCount
    case readNotif(tab : String, id : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "notification/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .getNotifs(_, _) : return .get
        case .getNotifsSell(_, _) : return .get
        case .getNotifsBuy(_, _) : return .get
        case .getUnreadNotifCount : return .get
        case .readNotif(_, _) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .getNotifs(let tab, let page) : return "new/\(tab)/\(page)"
        case .getNotifsSell(let page, _) : return "new/transaction/\(page)"
        case .getNotifsBuy(let page, _) : return "new/transaction/\(page)"
        case .getUnreadNotifCount : return "new/count"
        case .readNotif(let tab, _) : return "new/\(tab)/read"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .getNotifsSell(_, let name) :
            p = [
                "type" : NSNumber(value: 1 as Int),
                "name" : name
            ]
        case .getNotifsBuy(_, let name) :
            p = [
                "type" : NSNumber(value: 2 as Int),
                "name" : name
            ]
        case .readNotif(_, let id) :
            p = [
                "object_id" : id
            ]
        default : break
        }
        return p
    }
}

enum APIProduct : URLRequestConvertible {
    case listByCategory(categoryId : String, location : String, sort : String, current : Int, limit : Int, priceMin : Int, priceMax : Int)
    case detail(productId : String, forEdit : Int)
    case add(name : String, desc : String, price : String, weight : String, category : String)
    case love(productID : String)
    case unlove(productID : String)
    case getComment(productID : String)
    case postComment(productID : String, message : String, mentions : String)
    case myProduct(current : Int, limit : Int, name : String)
    case push(productId : String)
    case markAsSold(productId : String, soldTo : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "product/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .listByCategory(_, _, _, _, _, _, _): return .get
        case .detail(_, _) : return .get
        case .add(_, _, _, _, _) : return .post
        case .love(_):return .post
        case .unlove(_):return .post
        case .postComment(_, _, _) : return .post
        case .getComment(_) :return .get
        case .myProduct(_, _, _) : return .get
        case .push(_) : return .post
        case .markAsSold(_, _) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .listByCategory(_, _, _, _, _, _, _) : return ""
        case .detail(let prodId, _): return prodId
        case .add(_, _, _, _, _) : return ""
        case .love(let prodId) : return prodId + "/love"
        case .unlove(let prodId) : return prodId + "/unlove"
        case .postComment(let pId, _, _) : return pId + "/comments"
        case .getComment(let pId) : return pId + "/comments"
        case .myProduct(_, _, _) : return ""
        case .push(let pId) : return "push/\(pId)"
        case .markAsSold(let pId, _) : return "sold/\(pId)"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .listByCategory(let catId, let location, let sort, let current, let limit, let priceMin, let priceMax):
            p = [
                "category" : catId,
                "location" : location,
                "sort" : sort,
                "current" : current,
                "limit" : limit,
                "price_min" : priceMin,
                "price_max" : priceMax,
                "prelo" : "true"
            ]
        case .detail(_, let forEdit):
            p = [
                "inedit" : forEdit
            ]
        case .add(let name, let desc, let price, let weight, let category):
            p = [
                "name":name,
                "category":category,
                "price":price,
                "weight":weight,
                "description":desc
            ]
        case .love(let pId) :
            p = [
                "product_id" : pId
            ]
        case .unlove(let pId) :
            p = [
                "product_id" : pId
            ]
        case .postComment(let pId, let m, let mentions) :
            p = [
                "product_id" : pId,
                "comment" : m,
                "mentions" : mentions
            ]
        case .myProduct(let c, let l, let n) :
            p = [
                "current" : c,
                "limit" : l,
                "name" : n
            ]
        case .markAsSold(_, let soldTo) :
            p = [
                "sold_from" : "ios",
                "sold_to" : soldTo
            ]
        default : break
        }
        return p
    }
}

enum APIReference : URLRequestConvertible {
    case categoryList
    case provinceList
    case cityList(provinceId : String)
    case brandAndSizeByCategory(category : String)
    case homeCategories
    case formattedSizesByCategory(category : String)
    case getCategoryByPermalink(permalink : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "reference/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .categoryList:return .get
        case .provinceList:return .get
        case .cityList(_):return .get
        case .brandAndSizeByCategory(_) : return .get
        case .homeCategories : return .get
        case .formattedSizesByCategory(_) : return .get
        case .getCategoryByPermalink(_) : return .get
        }
    }
    
    var path : String {
        switch self {
        case .categoryList : return "categories"
        case .provinceList : return "provinces"
        case .cityList(_) : return "cities"
        case .brandAndSizeByCategory(_) : return "brands_sizes"
        case .homeCategories : return "categories/home"
        case .formattedSizesByCategory(_) : return "formatted_sizes"
        case .getCategoryByPermalink(_) : return "category/by_permalink"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .categoryList :
            p = [
                "prelo":"true"
            ]
        case .provinceList :
            p = [
                "prelo" : "true"
            ]
        case .cityList(let pId) :
            p = [
                "province" : pId,
                "prelo" : "true"
            ]
        case .brandAndSizeByCategory(let catId) :
            p = [
                "category_id" : catId
            ]
        case .formattedSizesByCategory(let catId) :
            p = [
                "category_id" : catId
            ]
        case .getCategoryByPermalink(let permalink) :
            p = [
                "permalink" : permalink
            ]
        default : break
        }
        return p
    }
}

enum APISearch : URLRequestConvertible {
    case user(keyword : String)
    case find(keyword : String, categoryId : String, brandId : String, condition : String, current : Int, limit : Int, priceMin : Int, priceMax : Int)
    case productByCategory(categoryId : String, sort : String, current : Int, limit : Int, priceMin : Int, priceMax : Int, segment: String, lastTimeUuid : String)
    case getTopSearch(limit : String)
    case insertTopSearch(search : String)
    case brands(name : String, current : Int, limit : Int)
    case productByFilter(name : String, categoryId : String, brandIds : String, productConditionIds : String, segment : String, priceMin : NSNumber, priceMax : NSNumber, isFreeOngkir : String, sizes : String, sortBy : String, current : NSNumber, limit : NSNumber, lastTimeUuid : String)
    case autocomplete(key : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "search/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .user(_) : return .get
        case .productByCategory(_, _, _, _, _, _, _, _): return .get
        case .getTopSearch(_): return .get
        case .find(_, _, _, _, _, _, _, _) : return .get
        case .insertTopSearch(_): return .post
        case .brands(_, _, _) : return .get
        case .productByFilter(_, _, _, _, _, _, _, _, _, _, _, _, _) : return .get
        case .autocomplete(_) : return .get
        }
    }
    
    var path : String {
        switch self {
        case .user(_) : return "users"
        case .productByCategory(_, _, _, _, _, _, _, _) : return "products"
        case .getTopSearch(_) : return "top"
        case .find(_, _, _, _, _, _, _, _) : return "products"
        case .insertTopSearch(_) :return "top"
        case .brands(_, _, _) : return "brands"
        case .productByFilter(_, _, _, _, _, _, _, _, _, _, _, _, _) : return "products"
        case .autocomplete(_) : return "autocomplete"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self
        {
        case .user(let key) :
            p = [
                "name" : key
            ]
        case .productByCategory(let catId, let sort, let current, let limit, let priceMin, let priceMax, let segment, let lastTimeUuid):
            p = [
                "category_id":catId,
                "sort":sort,
                "current":current,
                "limit":limit,
                "price_min":priceMin,
                "price_max":priceMax,
                "prelo":"true",
                "segment":segment,
                "last_time_uuid" : lastTimeUuid
            ]
        case .getTopSearch(let limit) :
            p = [
                "limit" : limit
            ]
        case .find(let key, let catId, let brandId, let condition, let current, let limit, let priceMin, let priceMax):
            p = [
                "name" : key,
                "category_id" : catId,
                "brand_id" : brandId,
                "product_condition_id" : condition,
                "current" : current,
                "limit" : limit,
                "price_min" : priceMin,
                "price_max" : priceMax,
                "prelo" : "true"
            ]
        case .insertTopSearch(let s):
            p = [
                "name" : s
            ]
        case .brands(let name, let current, let limit):
            p = [
                "name" : name,
                "current" : current,
                "limit" : limit
            ]
        case .productByFilter(let name, let categoryId, let brandIds, let productConditionIds, let segment, let priceMin, let priceMax, let isFreeOngkir, let sizes, let sortBy, let current, let limit, let lastTimeUuid):
            p = [
                "name" : name,
                "category_id" : categoryId,
                "brand_ids" : brandIds,
                "product_condition_ids" : productConditionIds,
                "segment" : segment,
                "price_min" : priceMin,
                "price_max" : priceMax,
                "is_free_ongkir" : isFreeOngkir,
                "sizes" : sizes,
                "sort_by" : sortBy,
                "current" : current,
                "limit" : limit,
                "last_time_uuid" : lastTimeUuid
            ]
        case .autocomplete(let key) :
            p = [
                "name": key
            ]
        }
        return p
    }
}

enum APISocmed : URLRequestConvertible {
    case storeInstagramToken(token : String)
    case postInstagramData(id : String, username : String, token : String)
    case postFacebookData(id : String, username : String, token : String)
    case postPathData(id : String, username : String, token : String)
    case postTwitterData(id : String, username : String, token : String, secret : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "socmed/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        default : return .post
        }
    }
    
    var path : String {
        switch self {
        case .storeInstagramToken(_) : return "instagram"
        case .postInstagramData(_, _, _) : return "instagram"
        case .postFacebookData(_, _, _) : return "facebook"
        case .postPathData(_, _, _) : return "path"
        case .postTwitterData(_, _, _, _) : return "twitter"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .storeInstagramToken(let appType) :
            p = [
                "access_token" : appType
            ]
        case .postInstagramData(let id, let username, let token) :
            p = [
                "instagram_id" : id,
                "instagram_username" : username,
                "access_token" : token
            ]
        case .postFacebookData(let id, let username, let token) :
            p = [
                "fb_id" : id,
                "fb_username" : username,
                "access_token" : token
            ]
        case .postPathData(let id, let username, let token) :
            p = [
                "path_id" : id,
                "path_username" : username,
                "access_token" : token
            ]
        case .postTwitterData(let id, let username, let token, let secret) :
            p = [
                "twitter_id" : id,
                "twitter_username" : username,
                "access_token" : token,
                "token_secret" : secret
            ]
        }
        return p
    }
}

enum APITransaction : URLRequestConvertible {
    case transactionDetail(tId : String)
    case confirmPayment(bankFrom : String, bankTo : String, name : String, nominal : Int, orderId : String, timePaid : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "transaction/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .transactionDetail(_) : return .get
        case .confirmPayment(_, _, _, _, _, _) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .transactionDetail(let tId) : return "\(tId)"
        case  .confirmPayment(_, _, _, _, let orderId, _) : return orderId + "/payment"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case  .confirmPayment(let bankFrom, let bankTo, let nama, let nominal, _, let timePaid) :
            p = [
                "target_bank":bankTo,
                "source_bank":bankFrom,
                "name":nama,
                "nominal":nominal,
                "time_paid":timePaid
            ]
        default : break
        }
        return p
    }
}

enum APITransactionAnggi : URLRequestConvertible {
    case getSellerTransaction(id : String)
    case getBuyerTransaction(id : String)
    case getTransactionProduct(id : String)
    case delayShipping(arrTpId : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = ""
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .getSellerTransaction(_) : return .get
        case .getBuyerTransaction(_) : return .get
        case .getTransactionProduct(_) : return .get
        case .delayShipping(_) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .getSellerTransaction(let id) : return "transaction/seller/\(id)"
        case .getBuyerTransaction(let id) : return "transaction/\(id)"
        case .getTransactionProduct(let id) : return "transaction_product/\(id)"
        case .delayShipping(_) : return "transaction/delay/shipping"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .delayShipping(let arrTpId) :
            p = [
                "arr_tp_id" : arrTpId
            ]
        default : break
        }
        return p
    }
}

enum APITransactionCheck : URLRequestConvertible {
    case checkUnpaidTransaction
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "transaction_check/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .checkUnpaidTransaction : return .get
        }
    }
    
    var path : String {
        switch self {
        default : return ""
        }
    }
    
    var param : [String : Any] {
        let p : [String : Any] = [:]
        switch self {
        default : break
        }
        return p
    }
}

enum APITransactionProduct : URLRequestConvertible
{
    case purchases(status : String, current : String, limit : String)
    case sells(status : String, current : String, limit : String)
    case transactionDetail(id : String)
    case confirmShipping(tpId : String, resiNum : String)
    case checkoutList(current : String, limit : String)
    case rejectTransaction(tpId : String, reason : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "transaction_product/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .purchases(_, _, _) : return .get
        case .sells(_, _, _) : return .get
        case .transactionDetail(_) : return .get
        case .confirmShipping(_, _) : return .post
        case .checkoutList(_, _) : return .get
        case .rejectTransaction(_, _) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .purchases(_, _, _) : return "buys"
        case .sells(_, _, _) : return "sells"
        case .transactionDetail(let id) : return id
        case .confirmShipping(let tpId, _) : return "\(tpId)/sent"
        case .checkoutList(_, _) : return "checkouts"
        case .rejectTransaction(let tpId, _) : return "\(tpId)/reject"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .purchases(let status, let current, let limit) :
            p = [
                "status" : status,
                "current" : current,
                "limit" : limit
            ]
        case .sells(let status, let current, let limit) :
            p = [
                "status" : status,
                "current" : current,
                "limit" : limit
            ]
        case .confirmShipping(_, let resiNum) :
            p = [
                "resi_number" : resiNum
            ]
        case .checkoutList(let current, let limit) :
            p = [
                "current" : current,
                "limit" : limit
            ]
        case .rejectTransaction(_, let reason) :
            p = [
                "reason" : reason
            ]
        default : break
        }
        return p
    }
}

enum APIUser : URLRequestConvertible {
    case getShopPage(id : String, current : Int, limit : Int)
    case getSellerReviews(id : String)

    public func asURLRequest() throws -> URLRequest {
        let basePath = "user/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .getShopPage(_, _, _) : return .get
        case .getSellerReviews(_) : return .get
        }
    }
    
    var path : String {
        switch self {
        case .getShopPage(let id, _, _) : return id
        case .getSellerReviews(let id) : return "\(id)/review"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .getShopPage(_, let current, let limit) :
            p = [
                "current" : NSNumber(value: current as Int),
                "limit" : NSNumber(value: limit as Int)
            ]
        default : break
        }
        return p
    }
}

enum APIVisitors : URLRequestConvertible {
    case updateVisitor(deviceRegId : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "visitors/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .updateVisitor(_) : return .post
        }
    }
    
    var path : String {
        switch self {
        case .updateVisitor(_) : return "update"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .updateVisitor(let deviceRegId) :
            p = [
                "device_type" : "APNS",
                "device_registration_id" : deviceRegId
            ]
        }
        return p
    }
}

enum APIWallet : URLRequestConvertible {
    case getBalance
    case withdraw(amount : String, targetBank : String, norek : String, namarek : String, password : String)
    
    public func asURLRequest() throws -> URLRequest {
        let basePath = "wallet/"
        let url = URL(string: preloHost)!.appendingPathComponent(basePath).appendingPathComponent(path)
        var urlRequest = URLRequest(url: url).defaultURLRequest()
        urlRequest.httpMethod = method.rawValue
        let encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: PreloEndpoints.ProcessParam(param))
        return encodedURLRequest
    }
    
    var method : HTTPMethod {
        switch self {
        case .withdraw(_, _, _, _, _) : return .post
        case .getBalance : return .get
        }
    }
    
    var path : String {
        switch self {
        case .withdraw(_, _, _, _, _) : return "withdraw"
        case .getBalance : return "balance"
        }
    }
    
    var param : [String : Any] {
        var p : [String : Any] = [:]
        switch self {
        case .withdraw(let amount, let namaBank, let norek, let namarek, let password) :
            p = [
                "amount" : amount,
                "target_bank" : namaBank,
                "nomor_rekening" : norek,
                "name" : namarek,
                "password" : password
            ]
        default : break
        }
        return p
    }
}

/*


enum Products : URLRequestConvertible
{
    static let basePath = "product/"
    
    case myProducts(current : Int, limit : Int)
    case listByCategory(categoryId : String, location : String, sort : String, current : Int, limit : Int, priceMin : Int, priceMax : Int)
    case detail(productId : String)
    case add(name : String, desc : String, price : String, weight : String, category : String)
    case love(productID : String)
    case unlove(productID : String)
    case getComment(productID : String)
    case postComment(productID : String, message : String, mentions : String)
    case shareCommission(pId : String, instagram : String, path : String, facebook : String, twitter : String)
    case postReview(productID : String, comment : String, star : Int)
    case activate(productID : String)
    case deactivate(productID : String)
    case delete(productID : String)
    case getAllFeaturedProducts(categoryId : String)
    case getIdByPermalink(permalink : String)
    case getExpiringProducts
    case setSoldExpiringProduct(productId : String)
    case setUnsoldExpiringProduct(productId : String)
    case finishExpiringProducts
    
    var method : Method
    {
        switch self
        {
        case .myProducts(_, _) : return .get
        case .listByCategory(_, _, _, _, _, _, _): return .get
        case .detail(_): return .get
        case .add(_, _, _, _, _) : return .post
        case .love(_):return .post
        case .unlove(_):return .post
        case .postComment(_, _, _) : return .post
        case .getComment(_) :return .get
        case .shareCommission(_, _, _, _, _) : return .post
        case .postReview(_, _, _) : return .post
        case .activate(_) : return .post
        case .deactivate(_) : return .post
        case .delete(_) : return .post
        case .getAllFeaturedProducts(_) : return .get
        case .getIdByPermalink(_) : return .get
        case .getExpiringProducts : return .get
        case .setSoldExpiringProduct(_) : return .post
        case .setUnsoldExpiringProduct(_) : return .post
        case .finishExpiringProducts : return .post
        }
    }
    
    var path : String
    {
        switch self
        {
        case .myProducts(_, _) : return ""
        case .listByCategory(_, _, _, _, _, _, _): return ""
        case .detail(let prodId): return prodId
        case .add(_, _, _, _, _) : return ""
        case .love(let prodId):return prodId + "/love"
        case .unlove(let prodId):return prodId + "/unlove"
        case .postComment(let pId, _, _):return pId + "/comments"
        case .getComment(let pId) :return pId + "/comments"
        case .shareCommission(let pId, _, _, _, _) : return pId + "/shares_commission"
        case .postReview(let pId, _, _) : return pId + "/review"
        case .activate(let pId) : return pId + "/activate"
        case .deactivate(let pId) : return pId + "/deactivate"
        case .delete(let pId) : return pId + "/delete"
        case .getAllFeaturedProducts(let cId) : return "editorspick/\(cId)"
        case .getIdByPermalink(let permalink) : return "to_id/" + permalink
        case .getExpiringProducts : return "expiring"
        case .setSoldExpiringProduct(let productId) : return "expiring/\(productId)/sold"
        case .setUnsoldExpiringProduct(let productId) : return "expiring/\(productId)/undo_sold"
        case .finishExpiringProducts : return "expiring/finish"
        }
    }
    
    var param : [String: AnyObject]?
    {
        switch self
        {
        case .myProducts(let current, let limit) :
            let p = [
                "current" : current,
                "limit" : limit
            ]
            return p as [String : AnyObject]?
        case .listByCategory(let catId, let location, let sort, let current, let limit, let priceMin, let priceMax):
            return [
                "category":catId,
                "location":location,
                "sort":sort,
                "current":current,
                "limit":limit,
                "price_min":priceMin,
                "price_max":priceMax,
                "prelo":"true"
            ]
        case .detail(_): return ["prelo":"true"]
        case .add(let name, let desc, let price, let weight, let category):
            return [
                "name":name,
                "category":category,
                "price":price,
                "weight":weight,
                "description":desc
            ]
        case .love(let pId):return ["product_id":pId]
        case .unlove(let pId):return ["product_id":pId]
        case .postComment(let pId, let m, let mentions):return ["product_id":pId, "comment":m, "mentions":mentions]
        case .getComment(_) : return [:]
        case .shareCommission(_, let i, let p, let f, let t) : return ["instagram":i, "facebook":f, "path":p, "twitter":t]
        case .postReview(_, let comment, let star) :
            return [
                "comment" : comment,
                "star" : star
            ]
        default : return [:]
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(Products.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        
        let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        return r
    }
}
*/
