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
   
    class func ProcessParam(oldParam : [String : AnyObject]) -> [String : AnyObject]
    {
        // Set crashlytics custom keys
        Crashlytics.sharedInstance().setObjectValue(oldParam, forKey: "last_req_param")
        
        
        return oldParam
    }
    
}

extension NSMutableURLRequest
{
    class func defaultURLRequest(url : NSURL) -> NSMutableURLRequest
    {
        let r = NSMutableURLRequest(URL: url)
        
        if (User.Token != nil) {
            let t = User.Token!
            r.setValue("Token " + t, forHTTPHeaderField: "Authorization")
            print("User token = \(t)")   
        }
        let userAgent : String? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.UserAgent) as? String
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
    
    case Version
    case Metadata(brands : String, categories : String, categorySizes : String, shippings : String, productConditions : String, provincesRegions : String)
    case MetadataCategories(currentVer : Int)
    case MetadataProductConditions
    case MetadataProvincesRegions(currentVer : Int)
    case MetadataShippings
    
    var method : Method
    {
        switch self
        {
        case .Version : return .GET
        case .Metadata(_, _, _, _, _, _) : return .GET
        case .MetadataCategories(_) : return .GET
        case .MetadataProductConditions : return .GET
        case .MetadataProvincesRegions(_) : return .GET
        case .MetadataShippings : return .GET
        }
    }
    
    var path : String
    {
        switch self
        {
        case .Version : return "version"
        case .Metadata(_, _, _, _, _, _) : return "metadata"
        case .MetadataCategories(_) : return "metadata/categories"
        case .MetadataProductConditions : return "metadata/product_condition"
        case .MetadataProvincesRegions(_) : return "metadata/provinces_regions"
        case .MetadataShippings : return "metadata/shippings"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .Version :
            let p = [
                "app_type" : "ios"
            ]
            return p
        case .Metadata(let brands, let categories, let categorySizes, let shippings, let productConditions, let provincesRegions) :
            let p = [
                "brands" : brands,
                "categories" : categories,
                "cateogry_sizes" : categorySizes,
                "shippings" : shippings,
                "product_conditions" : productConditions,
                "provinces_regions" : provincesRegions
            ]
            return p
        case .MetadataCategories(let currentVer) :
            let p = [
                "current_version" : currentVer
            ]
            return p
        case .MetadataProductConditions :
            return [:]
        case .MetadataProvincesRegions(let currentVer) :
            let p = [
                "current_version" : currentVer
            ]
            return p
        case .MetadataShippings :
            return [:]
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIApp.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APISocial : URLRequestConvertible
{
    static let basePath = "socmed/"
    
    case StoreInstagramToken(token : String)
    case PostInstagramData(id : String, username : String, token : String)
    case PostFacebookData(id : String, username : String, token : String)
    case PostPathData(id : String, username : String, token : String)
    case PostTwitterData(id : String, username : String, token : String, secret : String)
    
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
            case .StoreInstagramToken(_) : return "instagram"
            case .PostInstagramData(_, _, _) : return "instagram"
            case .PostFacebookData(_, _, _) : return "facebook"
            case .PostPathData(_, _, _) : return "path"
            case .PostTwitterData(_, _, _, _) : return "twitter"
            }
    }
    
    var param : [String : AnyObject]?
        {
            switch self
            {
            case .StoreInstagramToken(let appType) :
                let p = [
                    "access_token" : appType
                ]
                return p
            case .PostInstagramData(let id, let username, let token) :
                let p = [
                    "instagram_id" : id,
                    "instagram_username" : username,
                    "access_token" : token
                ]
                return p
            case .PostFacebookData(let id, let username, let token) :
                let p = [
                    "fb_id" : id,
                    "fb_username" : username,
                    "access_token" : token
                ]
                return p
            case .PostPathData(let id, let username, let token) :
                let p = [
                    "path_id" : id,
                    "path_username" : username,
                    "access_token" : token
                ]
                return p
            case .PostTwitterData(let id, let username, let token, let secret) :
                let p = [
                    "twitter_id" : id,
                    "twitter_username" : username,
                    "access_token" : token,
                    "token_secret" : secret
                ]
                return p
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APISocial.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            
            print("\(req.allHTTPHeaderFields)")
            
            let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            
            return r
    }
}

enum APIWallet : URLRequestConvertible
{
    static let basePath = "wallet/"
    
    case GetBalance
    case Withdraw(amount : String, targetBank : String, norek : String, namarek : String, password : String)
    
    var method : Method
        {
            switch self
            {
            case .Withdraw(_, _, _, _, _) : return .POST
            case .GetBalance : return .GET
            }
    }
    
    var path : String
        {
            switch self
            {
            case .Withdraw(_, _, _, _, _) : return "withdraw"
            case .GetBalance : return "balance"
            }
    }
    
    var param : [String : AnyObject]?
        {
            switch self
            {
            case .Withdraw(let amount, let namaBank, let norek, let namarek, let password) : return ["amount" : amount, "target_bank":namaBank, "nomor_rekening":norek, "name":namarek, "password":password]
            case .GetBalance : return [:]
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIWallet.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            
            print("\(req.allHTTPHeaderFields)")
            
            let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            
            return r
    }
}

enum APINotif : URLRequestConvertible
{
    static let basePath = "notification/"
    
    case GetNotifs
    case OpenNotifs
    case ReadNotif(notifId : String)
    case ReadMultiNotif(objectId : String, type : String)
    
    var method : Method
    {
        switch self
        {
        case .GetNotifs : return .GET
        case .OpenNotifs : return .POST
        case .ReadNotif(_) : return .POST
        case .ReadMultiNotif(_, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .GetNotifs : return ""
        case .OpenNotifs : return "open"
        case .ReadNotif(let notifId) : return "\(notifId)/read"
        case .ReadMultiNotif(_, _) : return "read_multiple"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .GetNotifs :
            return [:]
        case .OpenNotifs :
            return [:]
        case .ReadNotif(_) :
            return [:]
        case .ReadMultiNotif(let objectId, let type) :
            let p = [
                "object_id" : objectId,
                "type" : type
            ]
            return p
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APINotif.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APINotifAnggi : URLRequestConvertible
{
    static let basePath = "notification/"
    
    case GetNotifs(tab : String, page : Int)
    case GetUnreadNotifCount
    case ReadNotif(tab : String, id : String)
    
    var method : Method
    {
        switch self
        {
        case .GetNotifs(_, _) : return .GET
        case .GetUnreadNotifCount : return .GET
        case .ReadNotif(_, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .GetNotifs(let tab, let page) : return "new/\(tab)/\(page)"
        case .GetUnreadNotifCount : return "new/count"
        case .ReadNotif(let tab, _) : return "new/\(tab)/read"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .GetNotifs(_, _) :
            return [:]
        case .GetUnreadNotifCount :
            return [:]
        case .ReadNotif(_, let id) :
            let p = [
                "object_id" : id
            ]
            return p
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APINotifAnggi.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APIInbox : URLRequestConvertible
{
    static let basePath = "inbox/"
    
    case GetInboxes
    case GetInboxByProductID(productId : String)
    case GetInboxByProductIDSeller(productId : String, buyerId : String)
    case GetInboxMessage (inboxId : String)
    case StartNewOne (productId : String, type : Int, message : String)
    case StartNewOneBySeller (productId : String, type : Int, message : String, toId : String)
    case SendTo (inboxId : String, type : Int, message : String)
    
    var method : Method
        {
            switch self
            {
            case .GetInboxByProductID(_) : return .GET
            case .GetInboxByProductIDSeller(_, _) : return .GET
            case .GetInboxes : return .GET
            case .GetInboxMessage(_) : return .GET
            case .StartNewOne (_, _, _) : return .POST
            case .StartNewOneBySeller (_, _, _, _) : return .POST
            case .SendTo (_, _, _) : return .POST
            }
    }
    
    var path : String
        {
            switch self
            {
            case .GetInboxByProductID(let prodId) : return "product/"+prodId
            case .GetInboxByProductIDSeller(let prodId, _) : return "product/buyer/"+prodId
            case .GetInboxes : return ""
            case .GetInboxMessage(let inboxId) : return inboxId
            case .SendTo (let inboxId, _, _) : return inboxId
            case .StartNewOne(_, _, _) : return ""
            case .StartNewOneBySeller(_, _, _, _) : return ""
            }
    }
    
    var param : [String : AnyObject]?
        {
            switch self
            {
            case .GetInboxByProductID(_) : return [:]
            case .GetInboxByProductIDSeller(_, let buyerId) : return ["buyer_id":buyerId]
            case .GetInboxes : return [:]
            case .GetInboxMessage(_) : return [:]
            case .StartNewOne(let prodId, let type, let m) :
                return ["product_id":prodId, "message_type":String(type), "message":m]
            case .StartNewOneBySeller(let prodId, let type, let m, let toId) :
                return ["product_id":prodId, "message_type":String(type), "message":m, "to":toId]
            case .SendTo (_, let type, let message) : return ["message_type":type, "message":message]
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIInbox.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            
            print("\(req.allHTTPHeaderFields)")
            
            let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            
            return r
    }
}

enum APITransactionCheck : URLRequestConvertible
{
    static let basePath = "transaction_check"
    
    case CheckUnpaidTransaction
    
    var method : Method
    {
        switch self
        {
        case .CheckUnpaidTransaction : return .GET
        }
    }
    
    var path : String
    {
        switch self
        {
        case .CheckUnpaidTransaction : return ""
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .CheckUnpaidTransaction : return [:]
        }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APITransactionCheck.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            
            print("\(req.allHTTPHeaderFields)")
            
            let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            
            return r
    }
}

enum APITransaction : URLRequestConvertible
{
    static let basePath = "transaction_product/"
    
    case Purchases(status : String, current : String, limit : String)
    case Sells(status : String, current : String, limit : String)
    case TransactionDetail(id : String)
    case ConfirmShipping(tpId : String, resiNum : String)
    case CheckoutList(current : String, limit : String)
    case RejectTransaction(tpId : String, reason : String)
    
    var method : Method
    {
        switch self
        {
        case .Purchases(_, _, _) : return .GET
        case .Sells(_, _, _) : return .GET
        case .TransactionDetail(_) : return .GET
        case .ConfirmShipping(_, _) : return .POST
        case .CheckoutList(_, _) : return .GET
        case .RejectTransaction(_, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .Purchases(_, _, _) : return "buys"
        case .Sells(_, _, _) : return "sells"
        case .TransactionDetail(let id) : return id
        case .ConfirmShipping(let tpId, _) : return "\(tpId)/sent"
        case .CheckoutList(_, _) : return "checkouts"
        case .RejectTransaction(let tpId, _) : return "\(tpId)/reject"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .Purchases(let status, let current, let limit) :
            let p = [
                "status" : status,
                "current" : current,
                "limit" : limit
            ]
            return p
        case .Sells(let status, let current, let limit) :
            let p = [
                "status" : status,
                "current" : current,
                "limit" : limit
            ]
            return p
        case .TransactionDetail(_) :
            return [:]
        case .ConfirmShipping(_, let resiNum) :
            let p = [
                "resi_number" : resiNum
            ]
            return p
        case .CheckoutList(let current, let limit) :
            let p = [
                "current" : current,
                "limit" : limit
            ]
            return p
        case .RejectTransaction(_, let reason) :
            let p = [
                "reason" : reason
            ]
            return p
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APITransaction.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APITransaction2 : URLRequestConvertible
{
    static let basePath = "transaction/"
    
    case TransactionDetail(tId : String)
    case ConfirmPayment(bankFrom : String, bankTo : String, name : String, nominal : Int, orderId : String, timePaid : String)

    var method : Method {
        switch self
        {
        case .TransactionDetail(_) : return .GET
        case .ConfirmPayment(_, _, _, _, _, _) : return .POST
        }
    }
    
    var path : String {
        switch self
        {
        case .TransactionDetail(let tId) : return "\(tId)"
        case  .ConfirmPayment(_, _, _, _, let orderId, _) : return orderId + "/payment"
        }
    }
    
    var param : [String : AnyObject] {
        switch self
        {
        case .TransactionDetail(_) :
            return [:]
        case  .ConfirmPayment(let bankFrom, let bankTo, let nama, let nominal, _, let timePaid) :
            return [
                "target_bank":bankTo,
                "source_bank":bankFrom,
                "name":nama,
                "nominal":nominal,
                "time_paid":timePaid
            ]
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APITransaction2.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
            
        print("\(req.allHTTPHeaderFields)")
            
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param)).0
            
        return r
    }
}

enum APITransactionAnggi : URLRequestConvertible
{
    static let basePath = ""
    
    case GetSellerTransaction(id : String)
    case GetBuyerTransaction(id : String)
    case GetTransactionProduct(id : String)
    case DelayShipping(arrTpId : String)
    
    var method : Method
    {
        switch self
        {
        case .GetSellerTransaction(_) : return .GET
        case .GetBuyerTransaction(_) : return .GET
        case .GetTransactionProduct(_) : return .GET
        case .DelayShipping(_) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .GetSellerTransaction(let id) : return "transaction/seller/\(id)"
        case .GetBuyerTransaction(let id) : return "transaction/\(id)"
        case .GetTransactionProduct(let id) : return "transaction_product/\(id)"
        case .DelayShipping(_) : return "transaction/delay/shipping"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .GetSellerTransaction(_) : return [:]
        case .GetBuyerTransaction(_) : return [:]
        case .GetTransactionProduct(_) : return [:]
        case .DelayShipping(let arrTpId) :
            let p = [
                "arr_tp_id" : arrTpId
            ]
            return p
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APITransactionAnggi.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APICart : URLRequestConvertible
{
    static let basePath = "cart/"
    
    case Refresh(cart : String, address : String, voucher : String?)
    case Checkout(cart : String, address : String, voucher : String?, payment : String, usedPreloBalance : Int, usedReferralBonus : Int, kodeTransfer : Int, ccOrderId : String)
    case GenerateVeritransUrl(cart : String, address : String, voucher : String?, payment : String, usedPreloBalance : Int, usedReferralBonus : Int, kodeTransfer : Int)
    
    var method : Method
    {
        switch self
        {
        case .Refresh(_, _, _) : return .POST
        case .Checkout(_, _, _, _, _, _, _, _) : return .POST
        case .GenerateVeritransUrl(_, _, _, _, _, _, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .Refresh(_, _, _) : return ""
        case .Checkout(_, _, _, _, _, _, _, _) : return "checkout"
        case .GenerateVeritransUrl(_, _, _, _, _, _, _) : return "generate_veritrans_url"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .Refresh(let cart, let address, let voucher) :
                let p = [
                    "cart_products":cart,
                    "shipping_address":address,
                    "voucher_serial":(voucher == nil) ? "" : voucher!
                ]
                return p
        case .Checkout(let cart, let address, let voucher, let payment, let usedBalance, let usedBonus, let kodeTransfer, let ccOrderId) :
            var p = [
                "cart_products":cart,
                "shipping_address":address,
                "banktransfer_digit":NSNumber(integer: 1),
                "voucher_serial":(voucher == nil) ? "" : voucher!,
                "payment_method":payment
            ]
            if usedBalance != 0
            {
                p["prelobalance_used"] = NSNumber(integer: usedBalance)
            }
            
            if kodeTransfer != 0
            {
                p["banktransfer_digit"] = NSNumber(integer: kodeTransfer)
            }
            
            if usedBonus != 0 {
                p["bonus_used"] = NSNumber(integer: usedBonus)
            }
            
            if ccOrderId != "" {
                p["order_id"] = ccOrderId
            }
            
            return p
        case .GenerateVeritransUrl(let cart, let address, let voucher, let payment, let usedBalance, let usedBonus, let kodeTransfer) :
            var p = [
                "cart_products":cart,
                "shipping_address":address,
                "banktransfer_digit":NSNumber(integer: 1),
                "voucher_serial":(voucher == nil) ? "" : voucher!,
                "payment_method":payment
            ]
            if usedBalance != 0
            {
                p["prelobalance_used"] = NSNumber(integer: usedBalance)
            }
            
            if kodeTransfer != 0
            {
                p["banktransfer_digit"] = NSNumber(integer: kodeTransfer)
            }
            
            if usedBonus != 0 {
                p["bonus_used"] = NSNumber(integer: usedBonus)
            }
            
            return p
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
        
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APICart.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APIAuth : URLRequestConvertible
{
    static let basePath = "auth/"
    
    case Register(username : String, fullname : String, email : String, password : String)
    case Login(email : String, password : String)
    case LoginFacebook(email : String, fullname : String, fbId : String, fbUsername : String, fbAccessToken : String)
    case LoginPath(email : String, fullname : String, pathId : String, pathAccessToken : String)
    case LoginTwitter(email : String, fullname : String, username : String, id : String, accessToken : String, tokenSecret : String)
    case Logout
    
    var method : Method
        {
            switch self
            {
            case .Register(_, _, _, _) : return .POST
            case .Login(_, _) : return .POST
            case .LoginFacebook(_, _, _, _, _) : return .POST
            case .LoginPath(_, _, _, _) : return .POST
            case .LoginTwitter(_, _, _, _, _, _) : return .POST
            case .Logout : return .POST
            }
    }
    
    var path : String
        {
            switch self
            {
            case .Register(_, _, _, _) : return "register"
            case .Login(_, _) : return "login"
            case .LoginFacebook(_, _, _, _, _) : return "login/facebook"
            case .LoginPath(_, _, _, _) : return "login/path"
            case .LoginTwitter(_, _, _, _, _, _) : return "login/twitter"
            case .Logout : return "logout"
            }
    }
    
    var param : [String : AnyObject]?
        {
            switch self
            {
            case .Register(let username, let fullname, let email, let password) :
                let p = [
                    "username" : username,
                    "fullname" : fullname,
                    "email" : email,
                    "password" : password,
                    "device_id" : UIDevice.currentDevice().identifierForVendor!.UUIDString,
                    "fa_id" : UIDevice.currentDevice().identifierForVendor!.UUIDString
                ]
                return p
            case .Login(let usernameOrEmail, let password) :
                let p = [
                    "username_or_email" : usernameOrEmail,
                    "password" : password
                ]
                return p
            case .LoginFacebook(let email, let fullname, let fbId, let fbUsername, let fbAccessToken) :
                let p = [
                    "email" : email,
                    "fullname" : fullname,
                    "fb_id" : fbId,
                    "fb_username" : fbUsername,
                    "fb_access_token" : fbAccessToken
                ]
                return p
            case .LoginPath(let email, let fullname, let pathId, let pathAccessToken) :
                let p = [
                    "email" : email,
                    "fullname" : fullname,
                    "path_id" : pathId,
                    "path_access_token" : pathAccessToken
                ]
                return p
            case .LoginTwitter(let email, let fullname, let username, let id, let accessToken, let tokenSecret) :
                let p = [
                    "email" : email,
                    "fullname" : fullname,
                    "twitter_username" : username,
                    "twitter_id" : id,
                    "twitter_access_token" : accessToken,
                    "twitter_token_secret" : tokenSecret
                ]
                return p
            case .Logout :
                return [:]
            }
    }
    
    var URLRequest : NSMutableURLRequest {
        
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIAuth.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        // Selain logout jangan pake token
        switch self {
        case .Logout : break
        default :
            req.setValue("", forHTTPHeaderField: "Authorization")
        }
        
        print("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APIVisitor : URLRequestConvertible {
    static let basePath = "visitors/"
    
    case UpdateVisitor(deviceRegId : String)
    
    var method : Method {
        switch self {
        case .UpdateVisitor(_) : return .POST
        }
    }
    
    var path : String {
        switch self {
        case .UpdateVisitor(_) : return "update"
        }
    }
    
    var param : [String : AnyObject]? {
        switch self {
        case .UpdateVisitor(let deviceRegId) :
            let p = [
                "device_type" : "APNS",
                "device_registration_id" : deviceRegId
            ]
            return p
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIVisitor.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        return ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum APIUser : URLRequestConvertible
{
    static let basePath = "me/"
    
    case Login(email : String, password : String)
    case Register(fullname : String, email : String, password : String)
    case Logout
    case Me
    case OrderList(status : String)
    case MyProductSell
    case MyLovelist
    case SetupAccount(username : String, email: String, gender : Int, phone : String, province : String, region : String, subdistrict : String, shipping : String, referralCode : String, deviceId : String, deviceRegId : String)
    case SetProfile(fullname : String, address : String, province : String, region : String, subdistrict : String, postalCode : String, description : String, shipping : String)
    case ResendVerificationSms(phone : String)
    case VerifyPhone(phone : String, phoneCode : String)
    case ReferralData
    case SetReferral(referralCode : String, deviceId : String)
    case SetDeviceRegId(deviceRegId : String)
    case SetUserPreferencedCategories(categ1 : String, categ2 : String, categ3 : String)
    case CheckPassword
    case ResendVerificationEmail
    case GetBalanceMutations(current : Int, limit : Int)
    case SetUserUUID
    
    var method : Method
    {
        switch self
        {
        case .Login(_, _):return .POST
        case .Register(_, _, _): return .POST
        case .Logout:return .POST
        case .Me:return .GET
        case .OrderList(_):return .GET
        case .MyProductSell:return .GET
        case .MyLovelist : return .GET
        case .SetupAccount(_, _, _, _, _, _, _, _, _, _, _) : return .POST
        case .SetProfile(_, _, _, _, _, _, _, _) : return .POST
        case .ResendVerificationSms(_) : return .POST
        case .VerifyPhone(_, _) : return .POST
        case .ReferralData : return .GET
        case .SetReferral(_, _) : return .POST
        case .SetDeviceRegId(_) : return .POST
        case .SetUserPreferencedCategories(_, _, _) : return .POST
        case .CheckPassword : return .GET
        case .ResendVerificationEmail : return .POST
        case .GetBalanceMutations(_, _) : return .GET
        case .SetUserUUID : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .Login(_, _):return "login"
        case .Register(_, _, _): return "register"
        case .Logout:return "logout"
        case .Me : return "profile"
        case .OrderList(_):return "buy_list"
        case .MyProductSell:return "products"
        case .MyLovelist : return "lovelist"
        case .SetupAccount(_, _, _, _, _, _, _, _, _, _, _) : return "setup"
        case .SetProfile(_, _, _, _, _, _, _, _) : return "profile"
        case .ResendVerificationSms(_) : return "verify/resend_phone"
        case .VerifyPhone(_, _) : return "verify/phone"
        case .ReferralData : return "referral_bonus"
        case .SetReferral(_, _) : return "referral"
        case .SetDeviceRegId(_) : return "set_device_registration_id"
        case .SetUserPreferencedCategories(_, _, _) : return "category_preference"
        case .CheckPassword : return "checkpassword"
        case .ResendVerificationEmail : return "verify/resend_email"
        case .GetBalanceMutations(_, _) : return "getprelobalances"
        case .SetUserUUID : return "setgafaid"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .Login(let email, let password):
            return [
                "email":email,
                "password":password
            ]
        case .Register(let fullname, let email, let password):
            return [
                "fullname":fullname,
                "email":email,
                "password":password
            ]
        case .Logout:return [:]
        case .Me : return [:]
        case .OrderList(let status):
            return [
                "status":status
            ]
        case .MyProductSell:return [:]
        case .MyLovelist : return [:]
        case .SetupAccount(let username, let email, let gender, let phone, let province, let region, let subdistrict, let shipping, let referralCode, let deviceId, let deviceRegId):
            var p : [String : AnyObject] = [
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
            return p
        case .SetProfile(let fullname, let address, let province, let region, let subdistrict, let postalCode, let description, let shipping):
            return [
                "fullname":fullname,
                "address":address,
                "province":province,
                "region":region,
                "subdistrict":subdistrict,
                "postal_code":postalCode,
                "description":description,
                "shipping":shipping
            ]
        case .ResendVerificationSms(let phone) :
            return [
                "phone" : phone
            ]
        case .VerifyPhone(let phone, let phoneCode) :
            return [
                "phone" : phone,
                "phone_code" : phoneCode
            ]
        case .ReferralData :
            return [:]
        case .SetReferral(let referralCode, let deviceId) :
            let p = [
                "referral_code" : referralCode,
                "device_id" : deviceId
            ]
            return p
        case .SetDeviceRegId(let deviceRegId) :
            let p = [
                "registered_device_id" : deviceRegId,
                "device_type" : "APNS"
            ]
            return p
        case .SetUserPreferencedCategories(let categ1, let categ2, let categ3) :
            let p = [
                "category1" : categ1,
                "category2" : categ2,
                "category3" : categ3
            ]
            return p
        case .CheckPassword :
            return [:]
        case .ResendVerificationEmail :
            return [:]
        case .GetBalanceMutations(let current, let limit) :
            let p = [
                "current" : current,
                "limit" : limit
            ]
            return p
        case .SetUserUUID :
            let p = [
                "fa_id" : UIDevice.currentDevice().identifierForVendor!.UUIDString
            ]
            return p
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIUser.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        return ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum Products : URLRequestConvertible
{
    static let basePath = "product/"
    
    case MyProducts(current : Int, limit : Int)
    case ListByCategory(categoryId : String, location : String, sort : String, current : Int, limit : Int, priceMin : Int, priceMax : Int)
    case Detail(productId : String)
    case Add(name : String, desc : String, price : String, weight : String, category : String)
    case Love(productID : String)
    case Unlove(productID : String)
    case GetComment(productID : String)
    case PostComment(productID : String, message : String, mentions : String)
    case ShareCommission(pId : String, instagram : String, path : String, facebook : String, twitter : String)
    case PostReview(productID : String, comment : String, star : Int)
    case Activate(productID : String)
    case Deactivate(productID : String)
    case Delete(productID : String)
    case GetAllFeaturedProducts()
    case GetIdByPermalink(permalink : String)
    case GetExpiringProducts
    case SetSoldExpiringProduct(productId : String)
    case SetUnsoldExpiringProduct(productId : String)
    case FinishExpiringProducts
    
    var method : Method
    {
        switch self
        {
        case .MyProducts(_, _) : return .GET
        case .ListByCategory(_, _, _, _, _, _, _): return .GET
        case .Detail(_): return .GET
        case .Add(_, _, _, _, _) : return .POST
        case .Love(_):return .POST
        case .Unlove(_):return .POST
        case .PostComment(_, _, _) : return .POST
        case .GetComment(_) :return .GET
        case .ShareCommission(_, _, _, _, _) : return .POST
        case .PostReview(_, _, _) : return .POST
        case .Activate(_) : return .POST
        case .Deactivate(_) : return .POST
        case .Delete(_) : return .POST
        case .GetAllFeaturedProducts() : return .GET
        case .GetIdByPermalink(_) : return .GET
        case .GetExpiringProducts : return .GET
        case .SetSoldExpiringProduct(_) : return .POST
        case .SetUnsoldExpiringProduct(_) : return .POST
        case .FinishExpiringProducts : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .MyProducts(_, _) : return ""
        case .ListByCategory(_, _, _, _, _, _, _): return ""
        case .Detail(let prodId): return prodId
        case .Add(_, _, _, _, _) : return ""
        case .Love(let prodId):return prodId + "/love"
        case .Unlove(let prodId):return prodId + "/unlove"
        case .PostComment(let pId, _, _):return pId + "/comments"
        case .GetComment(let pId) :return pId + "/comments"
        case .ShareCommission(let pId, _, _, _, _) : return pId + "/shares_commission"
        case .PostReview(let pId, _, _) : return pId + "/review"
        case .Activate(let pId) : return pId + "/activate"
        case .Deactivate(let pId) : return pId + "/deactivate"
        case .Delete(let pId) : return pId + "/delete"
        case .GetAllFeaturedProducts() : return "editorspick/all"
        case .GetIdByPermalink(let permalink) : return "to_id/" + permalink
        case .GetExpiringProducts : return "expiring"
        case .SetSoldExpiringProduct(let productId) : return "expiring/\(productId)/sold"
        case .SetUnsoldExpiringProduct(let productId) : return "expiring/\(productId)/undo_sold"
        case .FinishExpiringProducts : return "expiring/finish"
        }
    }
    
    var param : [String: AnyObject]?
    {
        switch self
        {
        case .MyProducts(let current, let limit) :
            let p = [
                "current" : current,
                "limit" : limit
            ]
            return p
        case .ListByCategory(let catId, let location, let sort, let current, let limit, let priceMin, let priceMax):
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
        case .Detail(_): return ["prelo":"true"]
        case .Add(let name, let desc, let price, let weight, let category):
            return [
                "name":name,
                "category":category,
                "price":price,
                "weight":weight,
                "description":desc
            ]
        case .Love(let pId):return ["product_id":pId]
        case .Unlove(let pId):return ["product_id":pId]
        case .PostComment(let pId, let m, let mentions):return ["product_id":pId, "comment":m, "mentions":mentions]
        case .GetComment(_) : return [:]
        case .ShareCommission(_, let i, let p, let f, let t) : return ["instagram":i, "facebook":f, "path":p, "twitter":t]
        case .PostReview(_, let comment, let star) :
            return [
                "comment" : comment,
                "star" : star
            ]
        default : return [:]
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(Products.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        return r
    }
}

enum APIProduct : URLRequestConvertible
{
    static let basePath = "product/"
    
    case ListByCategory(categoryId : String, location : String, sort : String, current : Int, limit : Int, priceMin : Int, priceMax : Int)
    case Detail(productId : String, forEdit : Int)
    case Add(name : String, desc : String, price : String, weight : String, category : String)
    case Love(productID : String)
    case Unlove(productID : String)
    case GetComment(productID : String)
    case PostComment(productID : String, message : String, mentions : String)
    case MyProduct(current : Int, limit : Int)
    case Push(productId : String)
    case MarkAsSold(productId : String, soldTo : String)
    
    var method : Method
        {
            switch self
            {
            case .ListByCategory(_, _, _, _, _, _, _): return .GET
            case .Detail(_, _): return .GET
            case .Add(_, _, _, _, _) : return .POST
            case .Love(_):return .POST
            case .Unlove(_):return .POST
            case .PostComment(_, _, _) : return .POST
            case .GetComment(_) :return .GET
            case .MyProduct(_, _): return .GET
            case .Push(_) : return .POST
            case .MarkAsSold(_, _) : return .POST
            }
    }
    
    var path : String
        {
            switch self
            {
            case .ListByCategory(_, _, _, _, _, _, _): return ""
            case .Detail(let prodId, _): return prodId
            case .Add(_, _, _, _, _) : return ""
            case .Love(let prodId):return prodId + "/love"
            case .Unlove(let prodId):return prodId + "/unlove"
            case .PostComment(let pId, _, _):return pId + "/comments"
            case .GetComment(let pId) :return pId + "/comments"
            case .MyProduct(_, _): return ""
            case .Push(let pId) : return "push/\(pId)"
            case .MarkAsSold(let pId, _) : return "sold/\(pId)"
            }
    }
    
    var param : [String: AnyObject]?
        {
            switch self
            {
            case .ListByCategory(let catId, let location, let sort, let current, let limit, let priceMin, let priceMax):
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
            case .Detail(_, let forEdit): return ["inedit": forEdit]
            case .Add(let name, let desc, let price, let weight, let category):
                return [
                    "name":name,
                    "category":category,
                    "price":price,
                    "weight":weight,
                    "description":desc
                ]
            case .Love(let pId):return ["product_id":pId]
            case .Unlove(let pId):return ["product_id":pId]
            case .PostComment(let pId, let m, let mentions):return ["product_id":pId, "comment":m, "mentions":mentions]
            case .GetComment(_) :return [:]
            case .MyProduct(let c, let l): return ["current":c, "limit":l]
            case .Push(_) : return [:]
            case .MarkAsSold(_, let soldTo) : return ["sold_from":"ios", "sold_to":soldTo]
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIProduct.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            
            let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            return r
    }
}

enum APISearch : URLRequestConvertible
{
    static let basePath = "search/"
    
    case User(keyword : String)
    case Find(keyword : String, categoryId : String, brandId : String, condition : String, current : Int, limit : Int, priceMin : Int, priceMax : Int)
    case ProductByCategory(categoryId : String, sort : String, current : Int, limit : Int, priceMin : Int, priceMax : Int, segment: String)
    case GetTopSearch(limit : String)
    case InsertTopSearch(search : String)
    case Brands(name : String, current : Int, limit : Int)
    case ProductByFilter(name : String, categoryId : String, brandIds : String, productConditionIds : String, segment : String, priceMin : NSNumber, priceMax : NSNumber, isFreeOngkir : String, sizes : String, sortBy : String, current : NSNumber, limit : NSNumber, lastTimeUuid : String)
    
    var method : Method
        {
            switch self
            {
            case .User(_) : return .GET
            case .ProductByCategory(_, _, _, _, _, _, _): return .GET
            case .GetTopSearch(_): return .GET
            case .Find(_, _, _, _, _, _, _, _) : return .GET
            case .InsertTopSearch(_): return .POST
            case .Brands(_, _, _) : return .GET
            case .ProductByFilter(_, _, _, _, _, _, _, _, _, _, _, _, _) : return .GET
            }
    }
    
    var path : String
        {
            switch self
            {
            case .User(_) : return "users"
            case .ProductByCategory(_, _, _, _, _, _, _): return "products"
            case .GetTopSearch(_): return "top"
            case .Find(_, _, _, _, _, _, _, _) : return "products"
            case .InsertTopSearch(_):return "top"
            case .Brands(_, _, _) : return "brands"
            case .ProductByFilter(_, _, _, _, _, _, _, _, _, _, _, _, _) : return "products"
            }
    }
    
    var param : [String: AnyObject]?
        {
            switch self
            {
            case .User(let key) : return ["name":key]
            case .ProductByCategory(let catId, let sort, let current, let limit, let priceMin, let priceMax, let segment):
                return [
                    "category_id":catId,
                    "sort":sort,
                    "current":current,
                    "limit":limit,
                    "price_min":priceMin,
                    "price_max":priceMax,
                    "prelo":"true",
                    "segment":segment
                ]
            case .GetTopSearch(let limit):return ["limit":limit]
            case .Find(let key, let catId, let brandId, let condition, let current, let limit, let priceMin, let priceMax):
                return [
                    "name":key,
                    "category_id":catId,
                    "brand_id":brandId,
                    "product_condition_id":condition,
                    "current":current,
                    "limit":limit,
                    "price_min":priceMin,
                    "price_max":priceMax,
                    "prelo":"true"
                ]
            case .InsertTopSearch(let s):return ["name":s]
            case .Brands(let name, let current, let limit):
                return [
                    "name": name,
                    "current": current,
                    "limit": limit
                ]
            case .ProductByFilter(let name, let categoryId, let brandIds, let productConditionIds, let segment, let priceMin, let priceMax, let isFreeOngkir, let sizes, let sortBy, let current, let limit, let lastTimeUuid):
                return [
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
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APISearch.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            
            let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            return r
    }
}

enum APIDemo : URLRequestConvertible
{
    static let basePath = "demo/"
    
    case HomeCategories
    
    var method : Method {
        switch self {
        case .HomeCategories : return .GET
        }
    }
    
    var path : String {
        switch self {
        case .HomeCategories : return "reference/categories/home"
        }
    }
    
    var param : [String : AnyObject]? {
        switch self {
        case .HomeCategories : return [:]
        }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIDemo.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            return ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum References : URLRequestConvertible
{
    static let basePath = "reference/"
    
    case CategoryList
    case ProvinceList
    case CityList(provinceId : String)
    case BrandAndSizeByCategory(category : String)
    case HomeCategories
    case FormattedSizesByCategory(category : String)
    case GetCategoryByPermalink(permalink : String)
    
    var method : Method
    {
        switch self
        {
        case .CategoryList:return .GET
        case .ProvinceList:return .GET
        case .CityList(_):return .GET
        case .BrandAndSizeByCategory(_) : return .GET
        case .HomeCategories : return .GET
        case .FormattedSizesByCategory(_) : return .GET
        case .GetCategoryByPermalink(_) : return .GET
        }
    }
    
    var path : String
    {
        switch self
        {
        case .CategoryList:return "categories"
        case .ProvinceList:return "provinces"
        case .CityList(_):return "cities"
        case .BrandAndSizeByCategory(_) : return "brands_sizes"
        case .HomeCategories : return "categories/home"
        case .FormattedSizesByCategory(_) : return "formatted_sizes"
        case .GetCategoryByPermalink(_) : return "category/by_permalink"
        }
    }
    
    var param : [String: AnyObject]?
    {
        switch self
        {
        case .CategoryList:return ["prelo":"true"]
        case .ProvinceList:return ["prelo":"true"]
        case .CityList(let pId):return ["province":pId, "prelo":"true"]
        case .BrandAndSizeByCategory(let catId) : return ["category_id":catId]
        case .HomeCategories : return[:]
        case .FormattedSizesByCategory(let catId) : return ["category_id":catId]
        case .GetCategoryByPermalink(let permalink) : return ["permalink":permalink]
        }
    }
    
    var URLRequest : NSMutableURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(References.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        return ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum APIPeople : URLRequestConvertible
{
    static let basePath = "user/"
    
    case GetShopPage(id : String)
    case GetSellerReviews(id : String)
    
    var method : Method
        {
            switch self
            {
            case .GetShopPage(_): return .GET
            case .GetSellerReviews(_): return .GET
            }
    }
    
    var path : String
        {
            switch self
            {
            case .GetShopPage(let id):return id
            case .GetSellerReviews(let id): return "\(id)/review"
            }
    }
    
    var param : [String: AnyObject]?
        {
            switch self
            {
            case .GetShopPage(_):return [:]
            case .GetSellerReviews(_): return [:]
            }
    }
    
    var URLRequest : NSMutableURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIPeople.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            return ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum APIMisc : URLRequestConvertible {
    static let basePath = ""
    
    case GetSubdistrictsByRegionID(id : String)
    
    var method : Method {
        switch self {
        case .GetSubdistrictsByRegionID(_) : return .GET
        }
    }
    
    var path : String {
        switch self {
        case .GetSubdistrictsByRegionID(let id) : return "subdistricts/region/\(id)"
        }
    }
    
    var param : [String : AnyObject]? {
        switch self {
        case .GetSubdistrictsByRegionID(_) :
            return [:]
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIMisc.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        return ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

enum APIGarageSale : URLRequestConvertible {
    static let basePath = "garagesale/"
    
    case CreateReservation(productId : String)
    case CancelReservation(productId : String)
    
    var method : Method {
        switch self {
        case .CreateReservation(_) : return .POST
        case .CancelReservation(_) : return .POST
        }
    }
    
    var path : String {
        switch self {
        case .CreateReservation(_) : return "newreservation"
        case .CancelReservation(_) : return "cancelreservation"
        }
    }
    
    var param : [String : AnyObject]? {
        switch self {
        case .CreateReservation(let productId) :
            let p = [
                "product_id" : productId
            ]
            return p
        case .CancelReservation(let productId) :
            let p = [
                "product_id" : productId
            ]
            return p
        }
    }
    
    var URLRequest : NSMutableURLRequest {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIGarageSale.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        return ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
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
    
    static func validate(showErrorDialog : Bool, req : NSURLRequest, resp : NSHTTPURLResponse?, res : AnyObject?, err : NSError?, reqAlias : String) -> Bool
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
                            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                            if let childVCs = appDelegate.window?.rootViewController?.childViewControllers {
                                let rootVC = childVCs[0]
                                let uiNavigationController : UINavigationController? = rootVC as? UINavigationController
                                //let kumangTabBarVC : KumangTabBarViewController? = childVCs[0].viewControllers![0] as? KumangTabBarViewController
                                let kumangTabBarVC : KumangTabBarViewController? = (childVCs[0] as? UINavigationController)?.viewControllers[0] as? KumangTabBarViewController
                                if (uiNavigationController != nil && kumangTabBarVC != nil) {
                                    uiNavigationController!.popToRootViewControllerAnimated(true)
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
