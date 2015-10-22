//
//  PreloEndpoints.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/23/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

let prelloHost = "http://dev.prelo.id/api/"
let oldAPI = "http://dev.preloapp.com/api/2/"
//let prelloHost = "http://dev.preloapp.com/api/2/"

//let prelloHost = "http://dev.preloapp.com/api/2/"
//let oldAPI = "http://dev.preloapp.com/api/2/"

class PreloEndpoints: NSObject {
   
    class func ProcessParam(oldParam : [String : AnyObject]) -> [String : AnyObject]
    {
        let newParam = oldParam
        return oldParam
    }
    
}

extension NSMutableURLRequest
{
    class func defaultURLRequest(url : NSURL) -> NSMutableURLRequest
    {
        let r = NSMutableURLRequest(URL: url)
        
        if (User.IsLoggedIn) {
//            r.setValue("Authorization", forHTTPHeaderField: "Token " + User.Token!)
            r.setValue("Token " + User.Token!, forHTTPHeaderField: "Authorization")
        }
        
        return r
    }
}

enum APIApp : URLRequestConvertible
{
    static let basePath = "app/"
    
    case Version(appType : String)
    case Metadata
    
    var method : Method
    {
        switch self
        {
        case .Version(_) : return .GET
        case .Metadata : return .GET
        }
    }
    
    var path : String
    {
        switch self
        {
        case .Version(_) : return "version"
        case .Metadata : return "metadata"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .Version(let appType) :
            let p = [
                "app_type" : appType
            ]
            return p
        case .Metadata : return [:]
        }
    }
    
    var URLRequest : NSURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIApp.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        println("\(req.allHTTPHeaderFields)")
        
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
    
    var URLRequest : NSURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIWallet.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            
            println("\(req.allHTTPHeaderFields)")
            
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
    
    var method : Method
    {
        switch self
        {
        case .GetNotifs : return .GET
        case .OpenNotifs : return .POST
        case .ReadNotif(_) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .GetNotifs : return ""
        case .OpenNotifs : return "open"
        case .ReadNotif(let notifId) : return "\(notifId)/read"
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
        }
    }
    
    var URLRequest : NSURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APINotif.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        println("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APIInbox : URLRequestConvertible
{
    static let basePath = "inbox/"
    
    case GetInboxes
    case GetInboxByProductID(productId : String)
    case GetInboxMessage (inboxId : String)
    case StartNewOne (productId : String, type : Int, message : String)
    case SendTo (inboxId : String, type : Int, message : String)
    
    var method : Method
        {
            switch self
            {
            case .GetInboxByProductID(_) : return .GET
            case .GetInboxes : return .GET
            case .GetInboxMessage(_) : return .GET
            case .StartNewOne (_, _, _) : return .POST
            case .SendTo (_, _, _) : return .POST
            }
    }
    
    var path : String
        {
            switch self
            {
            case .GetInboxByProductID(let prodId) : return "product/"+prodId
            case .GetInboxes : return ""
            case .GetInboxMessage(let inboxId) : return inboxId
            case .SendTo (let inboxId, _, _) : return inboxId
            case .StartNewOne(_, _, _) : return ""
            }
    }
    
    var param : [String : AnyObject]?
        {
            switch self
            {
            case .GetInboxByProductID(_) : return [:]
            case .GetInboxes : return [:]
            case .GetInboxMessage(_) : return [:]
            case .StartNewOne(let prodId, let type, let m) : return ["product_id":prodId, "message_type":String(type), "message":m]
            case .SendTo (_, let type, let message) : return ["message_type":type, "message":message]
            }
    }
    
    var URLRequest : NSURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIInbox.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            
            println("\(req.allHTTPHeaderFields)")
            
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
    
    var method : Method
    {
        switch self
        {
        case .Purchases(_, _, _) : return .GET
        case .Sells(_, _, _) : return .GET
        case .TransactionDetail(_) : return .GET
        }
    }
    
    var path : String
    {
        switch self
        {
        case .Purchases(_, _, _) : return "buys"
        case .Sells(_, _, _) : return "sells"
        case .TransactionDetail(let id) : return id
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
        }
    }
    
    var URLRequest : NSURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APITransaction.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        println("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APITransaction2 : URLRequestConvertible
{
    static let basePath = "transaction"
    case ConfirmPayment(bankFrom : String, bankTo : String, name : String, nominal : Int, orderId : String)

    var method : Method {
        switch self
        {
        default : return .POST
        }
    }
    
    var path : String {
        switch self
        {
        case  .ConfirmPayment(_, _, _, _, let orderId) : return orderId + "/payment"
        }
    }
    
    var param : [String : AnyObject] {
        switch self
        {
        case  .ConfirmPayment(let bankFrom, let bankTo, let nama, let nominal, _) :
            return [
                "target_bank":bankTo,
                "source_bank":bankFrom,
                "name":nama,
                "nominal":nominal
            ]
        }
    }
    
    var URLRequest : NSURLRequest {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APITransaction2.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
            
        println("\(req.allHTTPHeaderFields)")
            
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param)).0
            
        return r
    }
}

enum APICart : URLRequestConvertible
{
    static let basePath = "cart/"
    
    case Refresh(cart : String, address : String, voucher : String?)
    case Checkout(cart : String, address : String, voucher : String?, payment : String)
    
    var method : Method
    {
        switch self
        {
        case .Refresh(_, _, _) : return .POST
        case .Checkout(_, _, _, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .Refresh(_, _, _) : return ""
        case .Checkout(_, _, _, _) : return "checkout"
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
        case .Checkout(let cart, let address, let voucher, let payment) :
            let p = [
                "cart_products":cart,
                "shipping_address":address,
                "voucher_serial":(voucher == nil) ? "" : voucher!,
                "payment_method":payment
            ]
            return p
        }
    }
    
    var URLRequest : NSURLRequest
    {
        let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APICart.basePath).URLByAppendingPathComponent(path)
        let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
        req.HTTPMethod = method.rawValue
        
        println("\(req.allHTTPHeaderFields)")
        
        let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
        
        return r
    }
}

enum APIAuth : URLRequestConvertible
{
    static let basePath = "auth/"
    
    case Register(username : String, fullname : String, email : String, password : String)
    case Login(email : String, password : String)
    case LoginFacebook(email : String, fullname : String, fbId : String, fbAccessToken : String)
    case LoginPath(email : String, fullname : String, pathId : String, pathAccessToken : String)
    case Logout
    
    var method : Method
        {
            switch self
            {
            case .Register(_, _, _, _) : return .POST
            case .Login(_, _) : return .POST
            case .LoginFacebook(_, _, _, _) : return .POST
            case .LoginPath(_, _, _, _) : return .POST
            case .Logout : return .POST
            }
    }
    
    var path : String
        {
            switch self
            {
            case .Register(_, _, _, _) : return "register"
            case .Login(_, _) : return "login"
            case .LoginFacebook(_, _, _, _) : return "login/facebook"
            case .LoginPath(_, _, _, _) : return "login/path"
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
                    "password" : password
                ]
                return p
            case .Login(let usernameOrEmail, let password) :
                let p = [
                    "username_or_email" : usernameOrEmail,
                    "password" : password
                ]
                return p
            case .LoginFacebook(let email, let fullname, let fbId, let fbAccessToken) :
                let p = [
                    "email" : email,
                    "fullname" : fullname,
                    "fb_id" : fbId,
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
            case .Logout :
                return [:]
            }
    }
    
    var URLRequest : NSURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIAuth.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            
            println("\(req.allHTTPHeaderFields)")
            
            let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            
            return r
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
    case SetupAccount(username : String, gender : Int, phone : String, province : String, region : String, shipping : String, referralCode : String, deviceId : String)
    case SetProfile(fullname : String, phone : String, address : String, region : String, postalCode : String, shopName : String, Description : String, Shipping : String)
    
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
        case .SetupAccount(_, _, _, _, _, _, _, _) : return .POST
        case .SetProfile(_, _, _, _, _, _, _, _) : return .POST
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
        case .SetupAccount(_, _, _, _, _, _, _, _) : return "setup"
        case .SetProfile(_, _, _, _, _, _, _, _) : return ""
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
        case .SetupAccount(let username, let gender, let phone, let province, let region, let shipping, let referralCode, let deviceId):
            return [
                "username":username,
                "gender":gender,
                "phone":phone,
                "province":province,
                "region":region,
                "shipping":shipping,
                "referral_code":referralCode,
                "device_id":deviceId
            ]
        case .SetProfile(let fullname, let phone, let address, let region, let postalCode, let shopName, let description, let shipping):
            return [
                "fullname":fullname,
                "phone":phone,
                "address":address,
                "region":region,
                "postal_code":postalCode,
                "shop_name":shopName,
                "description":description,
                "shipping":shipping
            ]
        }
    }
    
    var URLRequest : NSURLRequest
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
    case PostReview(productID : String, comment : String, star : Int)
    
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
        case .PostReview(_, _, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .MyProducts(_, _) : return ""
        case .ListByCategory(_, _, _, _, _, _, _): return ""
        case .Detail(let prodId): return prodId
        case .Add(_, _, _, _, let category) : return ""
        case .Love(let prodId):return prodId + "/love"
        case .Unlove(let prodId):return prodId + "/unlove"
        case .PostComment(let pId, _, _):return pId + "/comments"
        case .GetComment(let pId) :return pId + "/comments"
        case .PostReview(let pId, _, _) : return pId + "/review"
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
        case .Detail(let prodId): return ["prelo":"true"]
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
        case .GetComment(let pId) :return [:]
        case .PostReview(_, let comment, let star) :
            return [
                "comment" : comment,
                "star" : star
            ]
        }
    }
    
    var URLRequest : NSURLRequest
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
    case Detail(productId : String)
    case Add(name : String, desc : String, price : String, weight : String, category : String)
    case Love(productID : String)
    case Unlove(productID : String)
    case GetComment(productID : String)
    case PostComment(productID : String, message : String, mentions : String)
    case MyProduct(current : Int, limit : Int)
    
    var method : Method
        {
            switch self
            {
            case .ListByCategory(_, _, _, _, _, _, _): return .GET
            case .Detail(_): return .GET
            case .Add(_, _, _, _, _) : return .POST
            case .Love(_):return .POST
            case .Unlove(_):return .POST
            case .PostComment(_, _, _) : return .POST
            case .GetComment(_) :return .GET
            case .MyProduct(_, _): return .GET
            }
    }
    
    var path : String
        {
            switch self
            {
            case .ListByCategory(_, _, _, _, _, _, _): return ""
            case .Detail(let prodId): return prodId
            case .Add(_, _, _, _, let category) : return ""
            case .Love(let prodId):return prodId + "/love"
            case .Unlove(let prodId):return prodId + "/unlove"
            case .PostComment(let pId, _, _):return pId + "/comments"
            case .GetComment(let pId) :return pId + "/comments"
            case .MyProduct(_, _): return ""
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
            case .Detail(let prodId): return ["prelo":"true"]
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
            case .GetComment(let pId) :return [:]
            case .MyProduct(let c, let l): return ["current":c, "limit":l]
            }
    }
    
    var URLRequest : NSURLRequest
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
    case ProductByCategory(categoryId : String, sort : String, current : Int, limit : Int, priceMin : Int, priceMax : Int)
    case GetTopSearch(limit : String)
    case InsertTopSearch(search : String)
    
    var method : Method
        {
            switch self
            {
            case .User(_) : return .GET
            case .ProductByCategory(_, _, _, _, _, _): return .GET
            case .GetTopSearch(_): return .GET
            case .Find(_, _, _, _, _, _, _, _) : return .GET
            case .InsertTopSearch(_): return .GET
            }
    }
    
    var path : String
        {
            switch self
            {
            case .User(_) : return "users"
            case .ProductByCategory(_, _, _, _, _, _): return "products"
            case .GetTopSearch(_): return "top"
            case .Find(_, _, _, _, _, _, _, _) : return "products"
            case .InsertTopSearch(_):return "top"
            }
    }
    
    var param : [String: AnyObject]?
        {
            switch self
            {
            case .User(let key) : return ["name":key]
            case .ProductByCategory(let catId, let sort, let current, let limit, let priceMin, let priceMax):
                return [
                    "category_id":catId,
                    "sort":sort,
                    "current":current,
                    "limit":limit,
                    "price_min":priceMin,
                    "price_max":priceMax,
                    "prelo":"true"
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
            }
    }
    
    var URLRequest : NSURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APISearch.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            
            let r = ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
            return r
    }
}

enum References : URLRequestConvertible
{
    static let basePath = "reference/"
    
    case CategoryList
    case ProvinceList
    case CityList(provinceId : String)
    
    var method : Method
    {
        switch self
        {
        case .CategoryList:return .GET
        case .ProvinceList:return .GET
        case .CityList(_):return .GET
        }
    }
    
    var path : String
    {
        switch self
        {
        case .CategoryList:return "categories"
        case .ProvinceList:return "provinces"
        case .CityList(_):return "cities"
        }
    }
    
    var param : [String: AnyObject]?
    {
        switch self
        {
        case .CategoryList:return ["prelo":"true"]
        case .ProvinceList:return ["prelo":"true"]
        case .CityList(let pId):return ["province":pId, "prelo":"true"]
        }
    }
    
    var URLRequest : NSURLRequest
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
    
    var method : Method
        {
            switch self
            {
            case .GetShopPage(_):return .GET
            }
    }
    
    var path : String
        {
            switch self
            {
            case .GetShopPage(let id):return id
            }
    }
    
    var param : [String: AnyObject]?
        {
            switch self
            {
            case .GetShopPage(_):return [:]
            }
    }
    
    var URLRequest : NSURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIPeople.basePath).URLByAppendingPathComponent(path)
            let req = NSMutableURLRequest.defaultURLRequest(baseURL!)
            req.HTTPMethod = method.rawValue
            return ParameterEncoding.URL.encode(req, parameters: PreloEndpoints.ProcessParam(param!)).0
    }
}

class APIPrelo
{
    static func validate(showErrorDialog : Bool, err : NSError?, resp : NSHTTPURLResponse?) -> Bool
    {
        if let response = resp
        {
            if (response.statusCode == 500 && showErrorDialog)
            {
                UIAlertView.SimpleShow("Gagal", message: "Ada masalah dengan server")
                return false
            }
        }
        
        if let error = err
        {
            if (showErrorDialog)
            {
                UIAlertView.SimpleShow("Gagal", message: error.description)
            }
            return false
        } else
        {
            return true
        }
    }
}
