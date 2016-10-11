//
//  PreloEndpoints.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/23/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Crashlytics

var prelloHost : String {
    get {
        return "\(AppTools.PreloBaseUrl)/api/"
    }
}

class PreloEndpoints: NSObject {
   
    class func ProcessParam(_ oldParam : [String : AnyObject]) -> [String : AnyObject]
    {
        // Set crashlytics custom keys
        Crashlytics.sharedInstance().setObjectValue(oldParam, forKey: "last_req_param")
        
        
        return oldParam
    }
    
}

extension NSMutableURLRequest
{
    class func defaultURLRequest(_ url : URL) -> NSMutableURLRequest
    {
        let r = NSMutableURLRequest(url: url)
        
        if (User.Token != nil) {
            let t = User.Token!
            r.setValue("Token " + t, forHTTPHeaderField: "Authorization")
            print("User token = \(t)")   
        }
        let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
        if (userAgent != nil) {
            //print("User-Agent = \(userAgent)")
            r.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        
        // Set crashlytics custom keys
        Crashlytics.sharedInstance().setObjectValue(url, forKey: "last_req_url")
        
        return r
    }
}

enum APIApp : URLRequestConvertible
{
    static let basePath = "app/"
    
    case version
    case metadata(brands : String, categories : String, categorySizes : String, shippings : String, productConditions : String, provincesRegions : String)
    case metadataCategories(currentVer : Int)
    case metadataProductConditions
    case metadataProvincesRegions(currentVer : Int)
    case metadataShippings
    
    var method : Method
    {
        switch self
        {
        case .version : return .GET
        case .metadata(_, _, _, _, _, _) : return .GET
        case .metadataCategories(_) : return .GET
        case .metadataProductConditions : return .GET
        case .metadataProvincesRegions(_) : return .GET
        case .metadataShippings : return .GET
        }
    }
    
    var path : String
    {
        switch self
        {
        case .version : return "version"
        case .metadata(_, _, _, _, _, _) : return "metadata"
        case .metadataCategories(_) : return "metadata/categories"
        case .metadataProductConditions : return "metadata/product_condition"
        case .metadataProvincesRegions(_) : return "metadata/provinces_regions"
        case .metadataShippings : return "metadata/shippings"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .version :
            let p = [
                "app_type" : "ios"
            ]
            return p as [String : AnyObject]?
        case .metadata(let brands, let categories, let categorySizes, let shippings, let productConditions, let provincesRegions) :
            let p = [
                "brands" : brands,
                "categories" : categories,
                "cateogry_sizes" : categorySizes,
                "shippings" : shippings,
                "product_conditions" : productConditions,
                "provinces_regions" : provincesRegions
            ]
            return p as [String : AnyObject]?
        case .metadataCategories(let currentVer) :
            let p = [
                "current_version" : currentVer
            ]
            return p as [String : AnyObject]?
        case .metadataProductConditions :
            return [:]
        case .metadataProvincesRegions(let currentVer) :
            let p = [
                "current_version" : currentVer
            ]
            return p as [String : AnyObject]?
        case .metadataShippings :
            return [:]
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIApp.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APISocial : URLRequestConvertible
{
    static let basePath = "socmed/"
    
    case storeInstagramToken(token : String)
    case postInstagramData(id : String, username : String, token : String)
    case postFacebookData(id : String, username : String, token : String)
    case postPathData(id : String, username : String, token : String)
    case postTwitterData(id : String, username : String, token : String, secret : String)
    
    var method : Method
        {
            switch self
            {
            default : return .POST
            }
    }
    
    var path : String
        {
            switch self
            {
            case .storeInstagramToken(_) : return "instagram"
            case .postInstagramData(_, _, _) : return "instagram"
            case .postFacebookData(_, _, _) : return "facebook"
            case .postPathData(_, _, _) : return "path"
            case .postTwitterData(_, _, _, _) : return "twitter"
            }
    }
    
    var param : [String : AnyObject]?
        {
            switch self
            {
            case .storeInstagramToken(let appType) :
                let p = [
                    "access_token" : appType
                ]
                return p as [String : AnyObject]?
            case .postInstagramData(let id, let username, let token) :
                let p = [
                    "instagram_id" : id,
                    "instagram_username" : username,
                    "access_token" : token
                ]
                return p as [String : AnyObject]?
            case .postFacebookData(let id, let username, let token) :
                let p = [
                    "fb_id" : id,
                    "fb_username" : username,
                    "access_token" : token
                ]
                return p as [String : AnyObject]?
            case .postPathData(let id, let username, let token) :
                let p = [
                    "path_id" : id,
                    "path_username" : username,
                    "access_token" : token
                ]
                return p as [String : AnyObject]?
            case .postTwitterData(let id, let username, let token, let secret) :
                let p = [
                    "twitter_id" : id,
                    "twitter_username" : username,
                    "access_token" : token,
                    "token_secret" : secret
                ]
                return p as [String : AnyObject]?
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = URL(string: prelloHost)?.appendingPathComponent(APISocial.basePath).appendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.httpMethod = method.rawValue
            
            print("\(req.allHTTPHeaderFields)")
            
            let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            
            return r
    }
}

enum APIWallet : URLRequestConvertible
{
    static let basePath = "wallet/"
    
    case getBalance
    case withdraw(amount : String, targetBank : String, norek : String, namarek : String, password : String)
    
    var method : Method
        {
            switch self
            {
            case .withdraw(_, _, _, _, _) : return .POST
            case .getBalance : return .GET
            }
    }
    
    var path : String
        {
            switch self
            {
            case .withdraw(_, _, _, _, _) : return "withdraw"
            case .getBalance : return "balance"
            }
    }
    
    var param : [String : AnyObject]?
        {
            switch self
            {
            case .withdraw(let amount, let namaBank, let norek, let namarek, let password) : return ["amount" : amount as AnyObject, "target_bank":namaBank as AnyObject, "nomor_rekening":norek as AnyObject, "name":namarek as AnyObject, "password":password as AnyObject]
            case .getBalance : return [:]
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIWallet.basePath).appendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.httpMethod = method.rawValue
            
            print("\(req.allHTTPHeaderFields)")
            
            let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            
            return r
    }
}

enum APINotif : URLRequestConvertible
{
    static let basePath = "notification/"
    
    case getNotifs
    case openNotifs
    case readNotif(notifId : String)
    case readMultiNotif(objectId : String, type : String)
    
    var method : Method
    {
        switch self
        {
        case .getNotifs : return .GET
        case .openNotifs : return .POST
        case .readNotif(_) : return .POST
        case .readMultiNotif(_, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .getNotifs : return ""
        case .openNotifs : return "open"
        case .readNotif(let notifId) : return "\(notifId)/read"
        case .readMultiNotif(_, _) : return "read_multiple"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .getNotifs :
            return [:]
        case .openNotifs :
            return [:]
        case .readNotif(_) :
            return [:]
        case .readMultiNotif(let objectId, let type) :
            let p = [
                "object_id" : objectId,
                "type" : type
            ]
            return p as [String : AnyObject]?
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APINotif.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APINotifAnggi : URLRequestConvertible
{
    static let basePath = "notification/"
    
    case getNotifs(tab : String, page : Int)
    case getNotifsSell(page : Int, name : String)
    case getNotifsBuy(page : Int, name : String)
    case getUnreadNotifCount
    case readNotif(tab : String, id : String)
    
    var method : Method
    {
        switch self
        {
        case .getNotifs(_, _) : return .GET
        case .getNotifsSell(_, _) : return .GET
        case .getNotifsBuy(_, _) : return .GET
        case .getUnreadNotifCount : return .GET
        case .readNotif(_, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .getNotifs(let tab, let page) : return "new/\(tab)/\(page)"
        case .getNotifsSell(let page, _) : return "new/transaction/\(page)"
        case .getNotifsBuy(let page, _) : return "new/transaction/\(page)"
        case .getUnreadNotifCount : return "new/count"
        case .readNotif(let tab, _) : return "new/\(tab)/read"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .getNotifs(_, _) :
            return [:]
        case .getNotifsSell(_, let name) :
            return [
                "type" : NSNumber(value: 1 as Int),
                "name" : name as AnyObject
            ]
        case .getNotifsBuy(_, let name) :
            return [
                "type" : NSNumber(value: 2 as Int),
                "name" : name as AnyObject
            ]
        case .getUnreadNotifCount :
            return [:]
        case .readNotif(_, let id) :
            let p = [
                "object_id" : id
            ]
            return p as [String : AnyObject]?
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APINotifAnggi.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APIInbox : URLRequestConvertible
{
    static let basePath = "inbox/"
    
    case getInboxes
    case getInboxByProductID(productId : String)
    case getInboxByProductIDSeller(productId : String, buyerId : String)
    case getInboxMessage (inboxId : String)
    case startNewOne (productId : String, type : Int, message : String)
    case startNewOneBySeller (productId : String, type : Int, message : String, toId : String)
    case sendTo (inboxId : String, type : Int, message : String)
    
    var method : Method
        {
            switch self
            {
            case .getInboxByProductID(_) : return .GET
            case .getInboxByProductIDSeller(_, _) : return .GET
            case .getInboxes : return .GET
            case .getInboxMessage(_) : return .GET
            case .startNewOne (_, _, _) : return .POST
            case .startNewOneBySeller (_, _, _, _) : return .POST
            case .sendTo (_, _, _) : return .POST
            }
    }
    
    var path : String
        {
            switch self
            {
            case .getInboxByProductID(let prodId) : return "product/"+prodId
            case .getInboxByProductIDSeller(let prodId, _) : return "product/buyer/"+prodId
            case .getInboxes : return ""
            case .getInboxMessage(let inboxId) : return inboxId
            case .sendTo (let inboxId, _, _) : return inboxId
            case .startNewOne(_, _, _) : return ""
            case .startNewOneBySeller(_, _, _, _) : return ""
            }
    }
    
    var param : [String : AnyObject]?
        {
            switch self
            {
            case .getInboxByProductID(_) : return [:]
            case .getInboxByProductIDSeller(_, let buyerId) : return ["buyer_id":buyerId as AnyObject]
            case .getInboxes : return [:]
            case .getInboxMessage(_) : return [:]
            case .startNewOne(let prodId, let type, let m) :
                return ["product_id":prodId as AnyObject, "message_type":String(type) as AnyObject, "message":m as AnyObject]
            case .startNewOneBySeller(let prodId, let type, let m, let toId) :
                return ["product_id":prodId as AnyObject, "message_type":String(type) as AnyObject, "message":m as AnyObject, "to":toId as AnyObject]
            case .sendTo (_, let type, let message) : return ["message_type":type as AnyObject, "message":message as AnyObject]
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIInbox.basePath).appendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.httpMethod = method.rawValue
            
            print("\(req.allHTTPHeaderFields)")
            
            let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            
            return r
    }
}

enum APITransactionCheck : URLRequestConvertible
{
    static let basePath = "transaction_check"
    
    case checkUnpaidTransaction
    
    var method : Method
    {
        switch self
        {
        case .checkUnpaidTransaction : return .GET
        }
    }
    
    var path : String
    {
        switch self
        {
        case .checkUnpaidTransaction : return ""
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .checkUnpaidTransaction : return [:]
        }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = URL(string: prelloHost)?.appendingPathComponent(APITransactionCheck.basePath).appendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.httpMethod = method.rawValue
            
            print("\(req.allHTTPHeaderFields)")
            
            let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            
            return r
    }
}

enum APITransaction : URLRequestConvertible
{
    static let basePath = "transaction_product/"
    
    case purchases(status : String, current : String, limit : String)
    case sells(status : String, current : String, limit : String)
    case transactionDetail(id : String)
    case confirmShipping(tpId : String, resiNum : String)
    case checkoutList(current : String, limit : String)
    case rejectTransaction(tpId : String, reason : String)
    
    var method : Method
    {
        switch self
        {
        case .purchases(_, _, _) : return .GET
        case .sells(_, _, _) : return .GET
        case .transactionDetail(_) : return .GET
        case .confirmShipping(_, _) : return .POST
        case .checkoutList(_, _) : return .GET
        case .rejectTransaction(_, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .purchases(_, _, _) : return "buys"
        case .sells(_, _, _) : return "sells"
        case .transactionDetail(let id) : return id
        case .confirmShipping(let tpId, _) : return "\(tpId)/sent"
        case .checkoutList(_, _) : return "checkouts"
        case .rejectTransaction(let tpId, _) : return "\(tpId)/reject"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .purchases(let status, let current, let limit) :
            let p = [
                "status" : status,
                "current" : current,
                "limit" : limit
            ]
            return p as [String : AnyObject]?
        case .sells(let status, let current, let limit) :
            let p = [
                "status" : status,
                "current" : current,
                "limit" : limit
            ]
            return p as [String : AnyObject]?
        case .transactionDetail(_) :
            return [:]
        case .confirmShipping(_, let resiNum) :
            let p = [
                "resi_number" : resiNum
            ]
            return p as [String : AnyObject]?
        case .checkoutList(let current, let limit) :
            let p = [
                "current" : current,
                "limit" : limit
            ]
            return p as [String : AnyObject]?
        case .rejectTransaction(_, let reason) :
            let p = [
                "reason" : reason
            ]
            return p as [String : AnyObject]?
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APITransaction.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APITransaction2 : URLRequestConvertible
{
    static let basePath = "transaction/"
    
    case transactionDetail(tId : String)
    case confirmPayment(bankFrom : String, bankTo : String, name : String, nominal : Int, orderId : String, timePaid : String)

    var method : Method {
        switch self
        {
        case .transactionDetail(_) : return .GET
        case .confirmPayment(_, _, _, _, _, _) : return .POST
        }
    }
    
    var path : String {
        switch self
        {
        case .transactionDetail(let tId) : return "\(tId)"
        case  .confirmPayment(_, _, _, _, let orderId, _) : return orderId + "/payment"
        }
    }
    
    var param : [String : AnyObject] {
        switch self
        {
        case .transactionDetail(_) :
            return [:]
        case  .confirmPayment(let bankFrom, let bankTo, let nama, let nominal, _, let timePaid) :
            return [
                "target_bank":bankTo as AnyObject,
                "source_bank":bankFrom as AnyObject,
                "name":nama as AnyObject,
                "nominal":nominal as AnyObject,
                "time_paid":timePaid as AnyObject
            ]
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APITransaction2.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
            
        print("\(req.allHTTPHeaderFields)")
            
        let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param)).0
            
        return r
    }
}

enum APITransactionAnggi : URLRequestConvertible
{
    static let basePath = ""
    
    case getSellerTransaction(id : String)
    case getBuyerTransaction(id : String)
    case getTransactionProduct(id : String)
    case delayShipping(arrTpId : String)
    
    var method : Method
    {
        switch self
        {
        case .getSellerTransaction(_) : return .GET
        case .getBuyerTransaction(_) : return .GET
        case .getTransactionProduct(_) : return .GET
        case .delayShipping(_) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .getSellerTransaction(let id) : return "transaction/seller/\(id)"
        case .getBuyerTransaction(let id) : return "transaction/\(id)"
        case .getTransactionProduct(let id) : return "transaction_product/\(id)"
        case .delayShipping(_) : return "transaction/delay/shipping"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .getSellerTransaction(_) : return [:]
        case .getBuyerTransaction(_) : return [:]
        case .getTransactionProduct(_) : return [:]
        case .delayShipping(let arrTpId) :
            let p = [
                "arr_tp_id" : arrTpId
            ]
            return p as [String : AnyObject]?
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APITransactionAnggi.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APICart : URLRequestConvertible
{
    static let basePath = "cart/"
    
    case refresh(cart : String, address : String, voucher : String?)
    case checkout(cart : String, address : String, voucher : String?, payment : String, usedPreloBalance : Int, usedReferralBonus : Int, kodeTransfer : Int, ccOrderId : String)
    case generateVeritransUrl(cart : String, address : String, voucher : String?, payment : String, usedPreloBalance : Int, usedReferralBonus : Int, kodeTransfer : Int)
    
    var method : Method
    {
        switch self
        {
        case .refresh(_, _, _) : return .POST
        case .checkout(_, _, _, _, _, _, _, _) : return .POST
        case .generateVeritransUrl(_, _, _, _, _, _, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .refresh(_, _, _) : return ""
        case .checkout(_, _, _, _, _, _, _, _) : return "checkout"
        case .generateVeritransUrl(_, _, _, _, _, _, _) : return "generate_veritrans_url"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .refresh(let cart, let address, let voucher) :
                let p = [
                    "cart_products":cart,
                    "shipping_address":address,
                    "voucher_serial":(voucher == nil) ? "" : voucher!
                ]
                return p as [String : AnyObject]?
        case .checkout(let cart, let address, let voucher, let payment, let usedBalance, let usedBonus, let kodeTransfer, let ccOrderId) :
            var p = [
                "cart_products":cart,
                "shipping_address":address,
                "banktransfer_digit":NSNumber(value: 1 as Int),
                "voucher_serial":(voucher == nil) ? "" : voucher!,
                "payment_method":payment
            ] as [String : Any]
            if usedBalance != 0
            {
                p["prelobalance_used"] = NSNumber(value: usedBalance as Int)
            }
            
            if kodeTransfer != 0
            {
                p["banktransfer_digit"] = NSNumber(value: kodeTransfer as Int)
            }
            
            if usedBonus != 0 {
                p["bonus_used"] = NSNumber(value: usedBonus as Int)
            }
            
            if ccOrderId != "" {
                p["order_id"] = ccOrderId
            }
            
            return p as [String : AnyObject]?
        case .generateVeritransUrl(let cart, let address, let voucher, let payment, let usedBalance, let usedBonus, let kodeTransfer) :
            var p = [
                "cart_products":cart,
                "shipping_address":address,
                "banktransfer_digit":NSNumber(value: 1 as Int),
                "voucher_serial":(voucher == nil) ? "" : voucher!,
                "payment_method":payment
            ] as [String : Any]
            if usedBalance != 0
            {
                p["prelobalance_used"] = NSNumber(value: usedBalance as Int)
            }
            
            if kodeTransfer != 0
            {
                p["banktransfer_digit"] = NSNumber(value: kodeTransfer as Int)
            }
            
            if usedBonus != 0 {
                p["bonus_used"] = NSNumber(value: usedBonus as Int)
            }
            
            return p as [String : AnyObject]?
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
//        switch self
//        {
//            case .Refresh(_, _, _) :
//                let url = NSBundle.mainBundle().URLForResource("dummyCart", withExtension: ".json")
//                let req = NSMutableURLRequest.defaultURLRequest(url!)
//                return req
//            default :
//                print("")
//            
//        }
        
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APICart.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APIAuth : URLRequestConvertible
{
    static let basePath = "auth/"
    
    case register(username : String, fullname : String, email : String, password : String)
    case login(email : String, password : String)
    case loginFacebook(email : String, fullname : String, fbId : String, fbUsername : String, fbAccessToken : String)
    case loginPath(email : String, fullname : String, pathId : String, pathAccessToken : String)
    case loginTwitter(email : String, fullname : String, username : String, id : String, accessToken : String, tokenSecret : String)
    case logout
    
    var method : Method
        {
            switch self
            {
            case .register(_, _, _, _) : return .POST
            case .login(_, _) : return .POST
            case .loginFacebook(_, _, _, _, _) : return .POST
            case .loginPath(_, _, _, _) : return .POST
            case .loginTwitter(_, _, _, _, _, _) : return .POST
            case .logout : return .POST
            }
    }
    
    var path : String
        {
            switch self
            {
            case .register(_, _, _, _) : return "register"
            case .login(_, _) : return "login"
            case .loginFacebook(_, _, _, _, _) : return "login/facebook"
            case .loginPath(_, _, _, _) : return "login/path"
            case .loginTwitter(_, _, _, _, _, _) : return "login/twitter"
            case .logout : return "logout"
            }
    }
    
    var param : [String : AnyObject]?
        {
            switch self
            {
            case .register(let username, let fullname, let email, let password) :
                let p = [
                    "username" : username,
                    "fullname" : fullname,
                    "email" : email,
                    "password" : password,
                    "device_id" : UIDevice.current.identifierForVendor!.uuidString,
                    "fa_id" : UIDevice.current.identifierForVendor!.uuidString
                ]
                return p as [String : AnyObject]?
            case .login(let usernameOrEmail, let password) :
                let p = [
                    "username_or_email" : usernameOrEmail,
                    "password" : password
                ]
                return p as [String : AnyObject]?
            case .loginFacebook(let email, let fullname, let fbId, let fbUsername, let fbAccessToken) :
                let p = [
                    "email" : email,
                    "fullname" : fullname,
                    "fb_id" : fbId,
                    "fb_username" : fbUsername,
                    "fb_access_token" : fbAccessToken
                ]
                return p as [String : AnyObject]?
            case .loginPath(let email, let fullname, let pathId, let pathAccessToken) :
                let p = [
                    "email" : email,
                    "fullname" : fullname,
                    "path_id" : pathId,
                    "path_access_token" : pathAccessToken
                ]
                return p as [String : AnyObject]?
            case .loginTwitter(let email, let fullname, let username, let id, let accessToken, let tokenSecret) :
                let p = [
                    "email" : email,
                    "fullname" : fullname,
                    "twitter_username" : username,
                    "twitter_id" : id,
                    "twitter_access_token" : accessToken,
                    "twitter_token_secret" : tokenSecret
                ]
                return p as [String : AnyObject]?
            case .logout :
                return [:]
            }
    }
    
    var URLRequest : NSMutableURLRequest {
        
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIAuth.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        
        // Selain logout jangan pake token
        switch self {
        case .logout : break
        default :
            req.setValue("", forHTTPHeaderField: "Authorization")
        }
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APIVisitor : URLRequestConvertible {
    static let basePath = "visitors/"
    
    case updateVisitor(deviceRegId : String)
    
    var method : Method {
        switch self {
        case .updateVisitor(_) : return .POST
        }
    }
    
    var path : String {
        switch self {
        case .updateVisitor(_) : return "update"
        }
    }
    
    var param : [String : AnyObject]? {
        switch self {
        case .updateVisitor(let deviceRegId) :
            let p = [
                "device_type" : "APNS",
                "device_registration_id" : deviceRegId
            ]
            return p as [String : AnyObject]?
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIVisitor.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        return ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum APIUser : URLRequestConvertible
{
    static let basePath = "me/"
    
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
    
    var method : Method
    {
        switch self
        {
        case .login(_, _):return .POST
        case .register(_, _, _): return .POST
        case .logout:return .POST
        case .me:return .GET
        case .orderList(_):return .GET
        case .myProductSell:return .GET
        case .myLovelist : return .GET
        case .setupAccount(_, _, _, _, _, _, _, _, _, _, _) : return .POST
        case .setProfile(_, _, _, _, _, _, _, _) : return .POST
        case .resendVerificationSms(_) : return .POST
        case .verifyPhone(_, _) : return .POST
        case .referralData : return .GET
        case .setReferral(_, _) : return .POST
        case .setDeviceRegId(_) : return .POST
        case .setUserPreferencedCategories(_, _, _) : return .POST
        case .checkPassword : return .GET
        case .resendVerificationEmail : return .POST
        case .getBalanceMutations(_, _) : return .GET
        case .setUserUUID : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
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
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .login(let email, let password):
            return [
                "email":email as AnyObject,
                "password":password as AnyObject
            ]
        case .register(let fullname, let email, let password):
            return [
                "fullname":fullname as AnyObject,
                "email":email as AnyObject,
                "password":password as AnyObject
            ]
        case .logout:return [:]
        case .me : return [:]
        case .orderList(let status):
            return [
                "status":status as AnyObject
            ]
        case .myProductSell:return [:]
        case .myLovelist : return [:]
        case .setupAccount(let username, let email, let gender, let phone, let province, let region, let subdistrict, let shipping, let referralCode, let deviceId, let deviceRegId):
            var p : [String : AnyObject] = [
                "username":username as AnyObject,
                "email":email as AnyObject,
                "phone":phone as AnyObject,
                "province":province as AnyObject,
                "region":region as AnyObject,
                "subdistrict":subdistrict as AnyObject,
                "shipping":shipping as AnyObject,
                "referral_code":referralCode,
                "device_id":deviceId,
                "device_registration_id":deviceRegId,
                "device_type":"APNS"
            ]
            if (gender == 0 || gender == 1) {
                p["gender"] = gender as AnyObject?
            }
            return p
        case .setProfile(let fullname, let address, let province, let region, let subdistrict, let postalCode, let description, let shipping):
            return [
                "fullname":fullname as AnyObject,
                "address":address as AnyObject,
                "province":province as AnyObject,
                "region":region as AnyObject,
                "subdistrict":subdistrict as AnyObject,
                "postal_code":postalCode as AnyObject,
                "description":description as AnyObject,
                "shipping":shipping
            ]
        case .resendVerificationSms(let phone) :
            return [
                "phone" : phone as AnyObject
            ]
        case .verifyPhone(let phone, let phoneCode) :
            return [
                "phone" : phone as AnyObject,
                "phone_code" : phoneCode as AnyObject
            ]
        case .referralData :
            return [:]
        case .setReferral(let referralCode, let deviceId) :
            let p = [
                "referral_code" : referralCode,
                "device_id" : deviceId
            ]
            return p as [String : AnyObject]?
        case .setDeviceRegId(let deviceRegId) :
            let p = [
                "registered_device_id" : deviceRegId,
                "device_type" : "APNS"
            ]
            return p as [String : AnyObject]?
        case .setUserPreferencedCategories(let categ1, let categ2, let categ3) :
            let p = [
                "category1" : categ1,
                "category2" : categ2,
                "category3" : categ3
            ]
            return p as [String : AnyObject]?
        case .checkPassword :
            return [:]
        case .resendVerificationEmail :
            return [:]
        case .getBalanceMutations(let current, let limit) :
            let p = [
                "current" : current,
                "limit" : limit
            ]
            return p as [String : AnyObject]?
        case .setUserUUID :
            let p = [
                "fa_id" : UIDevice.current.identifierForVendor!.uuidString
            ]
            return p as [String : AnyObject]?
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIUser.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        return ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

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
        case .myProducts(_, _) : return .GET
        case .listByCategory(_, _, _, _, _, _, _): return .GET
        case .detail(_): return .GET
        case .add(_, _, _, _, _) : return .POST
        case .love(_):return .POST
        case .unlove(_):return .POST
        case .postComment(_, _, _) : return .POST
        case .getComment(_) :return .GET
        case .shareCommission(_, _, _, _, _) : return .POST
        case .postReview(_, _, _) : return .POST
        case .activate(_) : return .POST
        case .deactivate(_) : return .POST
        case .delete(_) : return .POST
        case .getAllFeaturedProducts(_) : return .GET
        case .getIdByPermalink(_) : return .GET
        case .getExpiringProducts : return .GET
        case .setSoldExpiringProduct(_) : return .POST
        case .setUnsoldExpiringProduct(_) : return .POST
        case .finishExpiringProducts : return .POST
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
                "category":catId as AnyObject,
                "location":location as AnyObject,
                "sort":sort as AnyObject,
                "current":current as AnyObject,
                "limit":limit as AnyObject,
                "price_min":priceMin as AnyObject,
                "price_max":priceMax as AnyObject,
                "prelo":"true"
            ]
        case .detail(_): return ["prelo":"true" as AnyObject]
        case .add(let name, let desc, let price, let weight, let category):
            return [
                "name":name as AnyObject,
                "category":category as AnyObject,
                "price":price as AnyObject,
                "weight":weight as AnyObject,
                "description":desc as AnyObject
            ]
        case .love(let pId):return ["product_id":pId as AnyObject]
        case .unlove(let pId):return ["product_id":pId as AnyObject]
        case .postComment(let pId, let m, let mentions):return ["product_id":pId as AnyObject, "comment":m as AnyObject, "mentions":mentions as AnyObject]
        case .getComment(_) : return [:]
        case .shareCommission(_, let i, let p, let f, let t) : return ["instagram":i as AnyObject, "facebook":f as AnyObject, "path":p as AnyObject, "twitter":t as AnyObject]
        case .postReview(_, let comment, let star) :
            return [
                "comment" : comment as AnyObject,
                "star" : star as AnyObject
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

enum APIProduct : URLRequestConvertible
{
    static let basePath = "product/"
    
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
    
    var method : Method
        {
            switch self
            {
            case .listByCategory(_, _, _, _, _, _, _): return .GET
            case .detail(_, _): return .GET
            case .add(_, _, _, _, _) : return .POST
            case .love(_):return .POST
            case .unlove(_):return .POST
            case .postComment(_, _, _) : return .POST
            case .getComment(_) :return .GET
            case .myProduct(_, _, _): return .GET
            case .push(_) : return .POST
            case .markAsSold(_, _) : return .POST
            }
    }
    
    var path : String
        {
            switch self
            {
            case .listByCategory(_, _, _, _, _, _, _): return ""
            case .detail(let prodId, _): return prodId
            case .add(_, _, _, _, _) : return ""
            case .love(let prodId):return prodId + "/love"
            case .unlove(let prodId):return prodId + "/unlove"
            case .postComment(let pId, _, _):return pId + "/comments"
            case .getComment(let pId) :return pId + "/comments"
            case .myProduct(_, _, _): return ""
            case .push(let pId) : return "push/\(pId)"
            case .markAsSold(let pId, _) : return "sold/\(pId)"
            }
    }
    
    var param : [String: AnyObject]?
        {
            switch self
            {
            case .listByCategory(let catId, let location, let sort, let current, let limit, let priceMin, let priceMax):
                return [
                    "category":catId as AnyObject,
                    "location":location as AnyObject,
                    "sort":sort as AnyObject,
                    "current":current as AnyObject,
                    "limit":limit as AnyObject,
                    "price_min":priceMin as AnyObject,
                    "price_max":priceMax as AnyObject,
                    "prelo":"true"
                ]
            case .detail(_, let forEdit): return ["inedit": forEdit as AnyObject]
            case .add(let name, let desc, let price, let weight, let category):
                return [
                    "name":name as AnyObject,
                    "category":category as AnyObject,
                    "price":price as AnyObject,
                    "weight":weight as AnyObject,
                    "description":desc as AnyObject
                ]
            case .love(let pId):return ["product_id":pId as AnyObject]
            case .unlove(let pId):return ["product_id":pId as AnyObject]
            case .postComment(let pId, let m, let mentions):return ["product_id":pId as AnyObject, "comment":m as AnyObject, "mentions":mentions as AnyObject]
            case .getComment(_) :return [:]
            case .myProduct(let c, let l, let n): return ["current":c as AnyObject, "limit":l as AnyObject, "name":n as AnyObject]
            case .push(_) : return [:]
            case .markAsSold(_, let soldTo) : return ["sold_from":"ios" as AnyObject, "sold_to":soldTo as AnyObject]
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIProduct.basePath).appendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.httpMethod = method.rawValue
            
            let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            return r
    }
}

enum APISearch : URLRequestConvertible
{
    static let basePath = "search/"
    
    case user(keyword : String)
    case find(keyword : String, categoryId : String, brandId : String, condition : String, current : Int, limit : Int, priceMin : Int, priceMax : Int)
    case productByCategory(categoryId : String, sort : String, current : Int, limit : Int, priceMin : Int, priceMax : Int, segment: String, lastTimeUuid : String)
    case getTopSearch(limit : String)
    case insertTopSearch(search : String)
    case brands(name : String, current : Int, limit : Int)
    case productByFilter(name : String, categoryId : String, brandIds : String, productConditionIds : String, segment : String, priceMin : NSNumber, priceMax : NSNumber, isFreeOngkir : String, sizes : String, sortBy : String, current : NSNumber, limit : NSNumber, lastTimeUuid : String)
    case autocomplete(key : String)
    
    var method : Method
        {
            switch self
            {
            case .user(_) : return .GET
            case .productByCategory(_, _, _, _, _, _, _, _): return .GET
            case .getTopSearch(_): return .GET
            case .find(_, _, _, _, _, _, _, _) : return .GET
            case .insertTopSearch(_): return .POST
            case .brands(_, _, _) : return .GET
            case .productByFilter(_, _, _, _, _, _, _, _, _, _, _, _, _) : return .GET
            case .autocomplete(_) : return .GET
            }
    }
    
    var path : String
        {
            switch self
            {
            case .user(_) : return "users"
            case .productByCategory(_, _, _, _, _, _, _, _): return "products"
            case .getTopSearch(_): return "top"
            case .find(_, _, _, _, _, _, _, _) : return "products"
            case .insertTopSearch(_):return "top"
            case .brands(_, _, _) : return "brands"
            case .productByFilter(_, _, _, _, _, _, _, _, _, _, _, _, _) : return "products"
            case .autocomplete(_) : return "autocomplete"
            }
    }
    
    var param : [String: AnyObject]?
        {
            switch self
            {
            case .user(let key) : return ["name":key as AnyObject]
            case .productByCategory(let catId, let sort, let current, let limit, let priceMin, let priceMax, let segment, let lastTimeUuid):
                return [
                    "category_id":catId as AnyObject,
                    "sort":sort as AnyObject,
                    "current":current as AnyObject,
                    "limit":limit as AnyObject,
                    "price_min":priceMin as AnyObject,
                    "price_max":priceMax as AnyObject,
                    "prelo":"true" as AnyObject,
                    "segment":segment,
                    "last_time_uuid" : lastTimeUuid
                ]
            case .getTopSearch(let limit):return ["limit":limit as AnyObject]
            case .find(let key, let catId, let brandId, let condition, let current, let limit, let priceMin, let priceMax):
                return [
                    "name":key as AnyObject,
                    "category_id":catId as AnyObject,
                    "brand_id":brandId as AnyObject,
                    "product_condition_id":condition as AnyObject,
                    "current":current as AnyObject,
                    "limit":limit as AnyObject,
                    "price_min":priceMin as AnyObject,
                    "price_max":priceMax,
                    "prelo":"true"
                ]
            case .insertTopSearch(let s):return ["name":s as AnyObject]
            case .brands(let name, let current, let limit):
                return [
                    "name": name as AnyObject,
                    "current": current as AnyObject,
                    "limit": limit as AnyObject
                ]
            case .productByFilter(let name, let categoryId, let brandIds, let productConditionIds, let segment, let priceMin, let priceMax, let isFreeOngkir, let sizes, let sortBy, let current, let limit, let lastTimeUuid):
                return [
                    "name" : name as AnyObject,
                    "category_id" : categoryId as AnyObject,
                    "brand_ids" : brandIds as AnyObject,
                    "product_condition_ids" : productConditionIds as AnyObject,
                    "segment" : segment as AnyObject,
                    "price_min" : priceMin,
                    "price_max" : priceMax,
                    "is_free_ongkir" : isFreeOngkir as AnyObject,
                    "sizes" : sizes as AnyObject,
                    "sort_by" : sortBy,
                    "current" : current,
                    "limit" : limit,
                    "last_time_uuid" : lastTimeUuid
                ]
            case .autocomplete(let key) :
                return [
                    "name": key as AnyObject
                ]
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = URL(string: prelloHost)?.appendingPathComponent(APISearch.basePath).appendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.httpMethod = method.rawValue
            
            let r = ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            return r
    }
}

enum APIDemo : URLRequestConvertible
{
    static let basePath = "demo/"
    
    case homeCategories
    
    var method : Method {
        switch self {
        case .homeCategories : return .GET
        }
    }
    
    var path : String {
        switch self {
        case .homeCategories : return "reference/categories/home"
        }
    }
    
    var param : [String : AnyObject]? {
        switch self {
        case .homeCategories : return [:]
        }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIDemo.basePath).appendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.httpMethod = method.rawValue
            return ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum References : URLRequestConvertible
{
    static let basePath = "reference/"
    
    case categoryList
    case provinceList
    case cityList(provinceId : String)
    case brandAndSizeByCategory(category : String)
    case homeCategories
    case formattedSizesByCategory(category : String)
    case getCategoryByPermalink(permalink : String)
    
    var method : Method
    {
        switch self
        {
        case .categoryList:return .GET
        case .provinceList:return .GET
        case .cityList(_):return .GET
        case .brandAndSizeByCategory(_) : return .GET
        case .homeCategories : return .GET
        case .formattedSizesByCategory(_) : return .GET
        case .getCategoryByPermalink(_) : return .GET
        }
    }
    
    var path : String
    {
        switch self
        {
        case .categoryList:return "categories"
        case .provinceList:return "provinces"
        case .cityList(_):return "cities"
        case .brandAndSizeByCategory(_) : return "brands_sizes"
        case .homeCategories : return "categories/home"
        case .formattedSizesByCategory(_) : return "formatted_sizes"
        case .getCategoryByPermalink(_) : return "category/by_permalink"
        }
    }
    
    var param : [String: AnyObject]?
    {
        switch self
        {
        case .categoryList:return ["prelo":"true" as AnyObject]
        case .provinceList:return ["prelo":"true" as AnyObject]
        case .cityList(let pId):return ["province":pId as AnyObject, "prelo":"true" as AnyObject]
        case .brandAndSizeByCategory(let catId) : return ["category_id":catId as AnyObject]
        case .homeCategories : return[:]
        case .formattedSizesByCategory(let catId) : return ["category_id":catId as AnyObject]
        case .getCategoryByPermalink(let permalink) : return ["permalink":permalink as AnyObject]
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(References.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        return ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum APIPeople : URLRequestConvertible
{
    static let basePath = "user/"
    
    case getShopPage(id : String, current : Int, limit : Int)
    case getSellerReviews(id : String)
    
    var method : Method
        {
            switch self
            {
            case .getShopPage(_, _, _): return .GET
            case .getSellerReviews(_): return .GET
            }
    }
    
    var path : String
        {
            switch self
            {
            case .getShopPage(let id, _, _):return id
            case .getSellerReviews(let id): return "\(id)/review"
            }
    }
    
    var param : [String: AnyObject]?
        {
            switch self
            {
            case .getShopPage(_, let current, let limit):
                return [
                    "current" : NSNumber(value: current as Int),
                    "limit" : NSNumber(value: limit as Int)
                ]
            case .getSellerReviews(_): return [:]
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIPeople.basePath).appendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.httpMethod = method.rawValue
            return ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum APIMisc : URLRequestConvertible {
    static let basePath = ""
    
    case getSubdistrictsByRegionID(id : String)
    
    var method : Method {
        switch self {
        case .getSubdistrictsByRegionID(_) : return .GET
        }
    }
    
    var path : String {
        switch self {
        case .getSubdistrictsByRegionID(let id) : return "subdistricts/region/\(id)"
        }
    }
    
    var param : [String : AnyObject]? {
        switch self {
        case .getSubdistrictsByRegionID(_) :
            return [:]
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIMisc.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        return ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum APIGarageSale : URLRequestConvertible {
    static let basePath = "garagesale/"
    
    case createReservation(productId : String)
    case cancelReservation(productId : String)
    
    var method : Method {
        switch self {
        case .createReservation(_) : return .POST
        case .cancelReservation(_) : return .POST
        }
    }
    
    var path : String {
        switch self {
        case .createReservation(_) : return "newreservation"
        case .cancelReservation(_) : return "cancelreservation"
        }
    }
    
    var param : [String : AnyObject]? {
        switch self {
        case .createReservation(let productId) :
            let p = [
                "product_id" : productId
            ]
            return p as [String : AnyObject]?
        case .cancelReservation(let productId) :
            let p = [
                "product_id" : productId
            ]
            return p as [String : AnyObject]?
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = URL(string: prelloHost)?.appendingPathComponent(APIGarageSale.basePath).appendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.httpMethod = method.rawValue
        return ParameterEncoding.url.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

class APIPrelo
{
    /*static func validate(showErrorDialog : Bool, err : NSError?, resp : NSHTTPURLResponse?) -> Bool
    {
        if let response = resp
        {
            if (response.statusCode == 500)
            {
                if (showErrorDialog)
                {
                    UIAlertView.SimpleShow("Gagal", message: "Ada masalah dengan server")
                }
                return false
            }
        }
        
        if let error = err
        {
            if (showErrorDialog)
            {
                UIAlertView.SimpleShow("Warning", message: "Terdapat error, silahkan coba beberapa saat lagi")//error.description)
            }
            return false
        } else
        {
            return true
        }
    }*/
    
    static func validate(_ showErrorDialog : Bool, req : Foundation.URLRequest, resp : HTTPURLResponse?, res : AnyObject?, err : NSError?, reqAlias : String) -> Bool
    {
        // Set crashlytics custom keys
        Crashlytics.sharedInstance().setObjectValue(reqAlias, forKey: "last_req_alias")
        Crashlytics.sharedInstance().setObjectValue(res, forKey: "last_api_result")
        if let resJson = (res as? JSON) {
            Crashlytics.sharedInstance().setObjectValue(resJson.stringValue, forKey: "last_api_result_string")
        }
        
        print("\(reqAlias) req = \(req)")
        
        if let response = resp
        {
            if (response.statusCode != 200)
            {
                if (res != nil) {
                    if let msg = JSON(res!)["_message"].string {
                        if (showErrorDialog) {
                            UIAlertView.SimpleShow(reqAlias, message: msg)
                        }
                        print("\(reqAlias) _message = \(msg)")
                        
                        if (msg == "user belum login") {
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
                        UIAlertView.SimpleShow(reqAlias, message: "Server Prelo sedang lelah, silahkan coba beberapa saat lagi")
                    } else {
                        UIAlertView.SimpleShow(reqAlias, message: "Oops, silahkan coba beberapa saat lagi")
                    }
                }
                return false
            }
        }
        
        if (res == nil)
        {
            if (showErrorDialog)
            {
                UIAlertView.SimpleShow(reqAlias, message: "Oops, tidak ada respon, silahkan coba beberapa saat lagi")
            }
            return false
        }
        
        if let error = err
        {
            if (showErrorDialog)
            {
                UIAlertView.SimpleShow(reqAlias, message: "Oops, terdapat kesalahan, silahkan coba beberapa saat lagi")
            }
            print("\(reqAlias) err = \(error.description)")
            return false
        }
        else
        {
            let json = JSON(res!)
            let data = json["_data"]
            print("\(reqAlias) _data = \(data)")
            return true
        }
    }
}
