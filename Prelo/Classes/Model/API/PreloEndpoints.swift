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

enum APICart : URLRequestConvertible
{
    static let basePath = "cart/"
    
    case Refresh(cart : String, address : String, voucher : String?)
    case Checkout(cart : String, address : String, voucher : String?, phone : String, payment : String)
    
    var method : Method
    {
        switch self
        {
        case .Refresh(_, _, _) : return .POST
        case .Checkout(_, _, _, _, _) : return .POST
        }
    }
    
    var path : String
    {
        switch self
        {
        case .Refresh(_, _, _) : return ""
        case .Checkout(_, _, _, _, _) : return "checkout"
        }
    }
    
    var param : [String : AnyObject]?
    {
        switch self
        {
        case .Refresh(let cart, let address, let voucher) :
                let p = [
                    "cart_items":cart,
                    "shipping_address":address,
                    "voucher_serial":(voucher == nil) ? "" : voucher!
                ]
                return p
        case .Checkout(let cart, let address, let voucher, let phone, let payment) :
            let p = [
                "cart_items":cart,
                "shipping_address":address,
                "voucher_serial":(voucher == nil) ? "" : voucher!,
                "payment_phone":phone,
                "payment_method":payment
            ]
            return p
        }
    }
    
    var URLRequest : NSURLRequest
    {
        let baseURL = NSURL(string: oldAPI)?.URLByAppendingPathComponent(APICart.basePath).URLByAppendingPathComponent(path)
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
    
    case Login(email : String, password : String)
    case Register(fullname : String, email : String, password : String)
    case Logout
    
    var method : Method
        {
            switch self
            {
            case .Login(_, _):return .POST
            case .Register(_, _, _): return .POST
            case .Logout:return .POST
            }
    }
    
    var path : String
        {
            switch self
            {
            case .Login(_, _):return "login"
            case .Register(_, _, _): return "register"
            case .Logout:return "logout"
            }
    }
    
    var param : [String : AnyObject]?
        {
            switch self
            {
            case .Login(let email, let password):
                return [
                    "username_or_email":email,
                    "password":password
                ]
            case .Register(let fullname, let email, let password):
                return [
                    "fullname":fullname,
                    "email":email,
                    "password":password,
                    "username":email
                ]
            case .Logout:return [:]
            }
    }
    
    var URLRequest : NSURLRequest
        {
            let baseURL = NSURL(string: prelloHost)?.URLByAppendingPathComponent(APIAuth.basePath).URLByAppendingPathComponent(path)
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
    case SetupAccount(province : String, region : String, phone : String, phoneCode : String, shippingPackages : String, referral : String)
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
        case .SetupAccount(_, _, _, _, _, _) : return .POST
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
        case .SetupAccount(_, _, _, _, _, _) : return "setup"
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
        case .SetupAccount(let province, let region, let phone, let phoneCode, let shippingPackages, let referral):
            return [
                "province":province,
                "region":region,
                "phone":phone,
                "phone_code":phoneCode,
                "shipping_packages":shippingPackages,
                "referral":referral
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
    
    case ListByCategory(categoryId : String, location : String, sort : String, current : Int, limit : Int, priceMin : Int, priceMax : Int)
    case Detail(productId : String)
    case Add(name : String, desc : String, price : String, weight : String, category : String)
    case Love(productID : String)
    case Unlove(productID : String)
    case GetComment(productID : String)
    case PostComment(productID : String, message : String, mentions : String)
    
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

enum APISearch : URLRequestConvertible
{
    static let basePath = "search/"
    
    case ProductByCategory(categoryId : String, sort : String, current : Int, limit : Int, priceMin : Int, priceMax : Int)
    
    var method : Method
        {
            switch self
            {
            case .ProductByCategory(_, _, _, _, _, _): return .GET
            }
    }
    
    var path : String
        {
            switch self
            {
            case .ProductByCategory(_, _, _, _, _, _): return "products"
            }
    }
    
    var param : [String: AnyObject]?
        {
            switch self
            {
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
