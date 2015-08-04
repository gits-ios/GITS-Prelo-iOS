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
        let base = "http://images.kleora.com/images/users/" + userID + "/" + fileName
        return base
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
    
    static func StoreUser(user : JSON)
    {
        let id = user["user_id"].string!
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
        return "http://images.kleora.com/images/products/" + productID + "/" + modifiedImageName
        
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
    }
    
    var discussionCountText : String
    {
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
            return nil
        }
        let base = "http://images.kleora.com/images/products/" + json["_id"].string! + "/" + json["display_picts"][0].string!
        return NSURL(string: base)
    }
    
    var discussionCountText : String
        {
            let a = json["discussions"].array
            if (a?.count == 0) {
                return "0"
            } else {
                let f = a?.objectAtCircleIndex(0)
                let d = f?["discussions"].array
                return String((d?.count)!)
            }
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
