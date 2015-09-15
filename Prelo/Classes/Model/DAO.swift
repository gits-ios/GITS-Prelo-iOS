//
//  DAO.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class DAO: NSObject {
    static func UserPhotoStringURL(fileName : String, userID : String) -> String
    {
        let base = "http://dev.kleora.com/images/users/" + userID + "/" + fileName
        return base
    }
    
    static func UrlForDisplayPicture(imageName : String, productID : String) -> String
    {
        let modifiedImageName = imageName.stringByReplacingOccurrencesOfString("..\\/", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        return "http://dev.kleora.com/images/products/" + productID + "/" + modifiedImageName
        
    }
}

public class User : NSObject
{
    private static var TokenKey = "user_token"
    private static var IdKey = "user_id"
    private static var EmailKey = "user_email"
    
    static var IsLoggedIn : Bool
    {
        let s = NSUserDefaults.standardUserDefaults().stringForKey(User.TokenKey)
        if (s == nil) {
            return false
        } else {
            return true
        }
    }
    
    static var Token : String?
    {
        let s = NSUserDefaults.standardUserDefaults().stringForKey(User.TokenKey)
        return s
    }
    
    static var Email : String?
    {
        let e = NSUserDefaults.standardUserDefaults().stringForKey(User.EmailKey)
        return e
    }
    
    static var EmailOrEmptyString : String
    {
        let m = User.Email
        if (m == nil) {
            return ""
        } else {
            return m!
        }
    }
    
    static func StoreUser(user : JSON)
    {
        var id = ""
        if let user_id = user["user_id"].string
        {
            id = user_id
        } else if let _id = user["_id"].string
        {
            id = _id
        }
        let token = user["token"].string!
        
        NSUserDefaults.standardUserDefaults().setObject(id, forKey: User.IdKey)
        NSUserDefaults.standardUserDefaults().setObject(token, forKey: User.TokenKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    static func StoreUser(user : JSON, email : String)
    {
        User.StoreUser(user)
        NSUserDefaults.standardUserDefaults().setObject(email, forKey: User.EmailKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    static func Logout()
    {
        Mixpanel.sharedInstance().track("Logged Out")
        Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
        Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
        
        if let u = CDUser.getOne()
        {
            UIApplication.appDelegate.managedObjectContext?.deleteObject(u)
            UIApplication.appDelegate.saveContext()
        }
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey(User.IdKey)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(User.TokenKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

public class ProductDetail : NSObject
{
    var json : JSON!
    
    static func instance(obj : JSON?)->ProductDetail?
    {
        if (obj == nil) {
            return nil
        } else {
            var p = ProductDetail()
            p.json = obj!
            return p
        }
    }
    
    private func urlForDisplayPicture(imageName : String, productID : String) -> String
    {
        let modifiedImageName = imageName.stringByReplacingOccurrencesOfString("..\\/", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        return "http://dev.kleora.com/images/products/" + productID + "/" + modifiedImageName
        
    }
    
    var productID : String
    {
        return json["_data"]["_id"].string!
    }
    
    var name : String
    {
        return (json["_data"]["name"].string)!.escapedHTML
    }
    
    var displayPicturers : Array<String>
    {
        let ori : Array<String> = json["_data"]["display_picts"].arrayObject as! Array<String>
        var arr : Array<String> = []
        for name in ori
        {
            let url = urlForDisplayPicture(name, productID: productID)
            arr.append(url)
        }
        return arr
    }
    
    var shopAvatarURL : NSURL?
    {
        let base = "http://images.kleora.com/images/users/" + json["_data"]["seller_id"].string! + "/" + json["_data"]["shop_profpict"].string!
        return NSURL(string: base)
//        if let p = json["_data"]["seller"]["pict"].string
//        {
//            return NSURL(string : p)
//        }
//        return NSURL(string: "http://prelo.id/eweuh-gambar")
    }
    
    var discussionCountText : String
    {
//        if let num_comment = json["_data"]["num_comment"].int
//        {
//            return String(num_comment)
//        }
//        let a = json["_data"]["discussions"].array
//        if (a?.count == 0) {
//            return "0"
//        } else {
//            let f = a?.objectAtCircleIndex(0)
//            let d = f?["discussions"].array
//            return String((d?.count)!)
//        }
        let a = json["_data"]["discussions"].array
        if (a?.count == 0) {
            return "0"
        } else {
            let f = a?.objectAtCircleIndex(0)
            let d = f?["discussions"].array
            return String((d?.count)!)
        }
    }
    
    var discussions : Array<ProductDiscussion>?
        {
//            let a = json["_data"]["comments"].array
//            if (a?.count == 0) {
//                return []
//            } else {
//                let f = a?.objectAtCircleIndex(0)
//                let d = f?["comments"].array
//                var r : Array<ProductDiscussion> = []
//                
//                for i in 0...(d?.count)!-1
//                {
//                    let j = d?[i]
//                    let dx = ProductDiscussion.instance(j)
//                    r.append(dx!)
//                }
//                
//                return r
            let a = json["_data"]["discussions"].array
            if (a?.count == 0) {
                return []
            } else {
                let f = a?.objectAtCircleIndex(0)
                let d = f?["discussions"].array
                var r : Array<ProductDiscussion> = []
                
                for i in 0...(d?.count)!-1
                {
                    let j = d?[i]
                    let dx = ProductDiscussion.instance(j)
                    r.append(dx!)
                }
                
                return r
            }
    }
}

public class Product : NSObject
{
    var json : JSON!
    
    var name : String
    {
        return (json["name"].string)!.escapedHTML
    }
    
    static func instance(obj:JSON?)->Product?
    {
        if (obj == nil) {
            return nil
        } else {
            var p = Product()
            p.json = obj!
            return p
        }
    }
    
    var coverImageURL : NSURL?
    {
        if let err = json["display_picts"][0].error
        {
            return NSURL(string: "http://dev.kleora.com/images/products/")
        }
        let base = "http://dev.kleora.com/images/products/" + json["_id"].string! + "/" + json["display_picts"][0].string!
//        let base = "" + json["display_picts"][0].string!
        if let url = NSURL(string : base)
        {
            return url
        } else {
            return NSURL(string: "http://dev.kleora.com/images/products/")
        }
//        return NSURL(string: base)
    }
    
    var discussionCountText : String
        {
            if let d = json["discussions"].int
            {
                return String(d)
            }
            
            let a = json["discussions"].array
            if (a?.count == 0) {
                return "0"
            } else {
                let f = a?.objectAtCircleIndex(0)
                let d = f?["discussions"].array
                return String((d?.count)!)
            }
    }
    
    var loveCountText : String
    {
            if let l = json["love"].int
            {
                return String(l)
            }
        return ""
    }
    
    var discussions : [JSON]?
        {
            let a = json["discussions"].array
            if (a?.count == 0) {
                return []
            } else {
                let f = a?.objectAtCircleIndex(0)
                let d = f?["discussions"].array
                return d
            }
    }
    
    var price : String
    {
        if let p = json["price"].int
        {
            return p.asPrice
        }
        
        return ""
    }
    
    var time : String
    {
        if let t = json["time"].string
        {
            return t
        }
        return ""
    }
}

class ProductDiscussion : NSObject
{
    var json : JSON!
    
    static func instance(json : JSON?) -> ProductDiscussion?
    {
        if (json == nil) {
            return nil
        } else {
            let p = ProductDiscussion()
            p.json = json!
            return p
        }
    }
    
    var message : String
    {
        let m = (json["message"].string)!.escapedHTML
        return m
    }
    
    var posterImageURL : NSURL?
    {
        let filename = (json["user_pict"].string!).stringByReplacingOccurrencesOfString("..\\", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        let base = DAO.UserPhotoStringURL(filename, userID: json["user_id"].string!)
        return NSURL(string: base)
    }
}

class UserOrder : NSObject {
    
    var json : JSON!
    
    static func instance(json : JSON?) -> UserOrder? {
        if (json == nil) {
            return nil
        } else {
            let u = UserOrder()
            u.json = json!
            return u
        }
    }
    
    var transactionID : String {
        let t = (json["transaction_id"].string)!
        return t
    }
    
    var productImageURL : NSURL? {
        if let err = json["product_display_pict"].error
        {
            return nil
        }
        let url = "http://dev.kleora.com/images/products/" + json["product_id"].string! + "/" + json["product_display_pict"].string!
        return NSURL(string: url)
    }
    
    var productName : String {
        let n = (json["product_name"].string)!.escapedHTML
        return n
    }
    
    var price : String {
        let p = (json["transaction_product_price_formatted"].string)!.escapedHTML
        return p
    }
    
    var timespan : String {
        let t = (json["time_from_now"].string)!.escapedHTML
        return t
    }
    
    var productSeller : String {
        let s = (json["seller_name"].string)!.escapedHTML
        return s
    }
    
}
