//
//  DAO.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Foundation
import TwitterKit

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
    
    static var Id : String?
    {
        let i = NSUserDefaults.standardUserDefaults().stringForKey(User.IdKey)
        return i
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
    
    static func SetToken(token : String?)
    {
        NSUserDefaults.standardUserDefaults().setObject(token, forKey: User.TokenKey)
        NSUserDefaults.standardUserDefaults().synchronize()
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
    
    static func StoreUser(id : String, token : String, email : String)
    {
        NSUserDefaults.standardUserDefaults().setObject(id, forKey: User.IdKey)
        NSUserDefaults.standardUserDefaults().setObject(token, forKey: User.TokenKey)
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
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey("pathtoken")
        
        self.LogoutFacebook()
    }
    
    static func LogoutFacebook()
    {
        let fbManager = FBSDKLoginManager()
        fbManager.logOut()
        FBSDKAccessToken.setCurrentAccessToken(nil)
    }
    
    static func LogoutTwitter()
    {
        let store = Twitter.sharedInstance().sessionStore
        if let userID = store.session()!.userID {
            store.logOutUserID(userID)
        }
    }
}

class UserProfile : NSObject {
    var json : JSON!

    static func instance(json : JSON?) -> UserProfile? {
        if (json == nil) {
            return nil
        } else {
            let u = UserProfile()
            u.json = json!
            return u
        }
    }
    
    var id : String {
        let i = (json["_id"].string)!
        return i
    }
    
    var username : String {
        let u = (json["username"].string)!
        return u
    }
    
    var email : String {
        let e = (json["email"].string)!
        return e
    }
    
    var fullname : String {
        let f = (json["fullname"].string)!
        return f
    }
    
    var profPictURL : NSURL? {
        if let err = json["profile"]["pict"].error {
            return nil
        }
        let url = json["profile"]["pict"].string!
        return NSURL(string: url)
    }
    
    var phone : String? {
        if (json["profile"]["phone"] != nil) {
            return json["profile"]["phone"].string
        } else {
            return nil
        }
    }
    
    var regionId : String? {
        if (json["profile"]["region_id"] != nil) {
            return json["profile"]["region_id"].string
        } else {
            return nil
        }
    }
    
    var provinceId : String? {
        if (json["profile"]["province_id"] != nil) {
            return json["profile"]["province_id"].string
        } else {
            return nil
        }
    }
    
    var gender : String? {
        if (json["profile"]["gender"] != nil) {
            return json["profile"]["gender"].string
        } else {
            return nil
        }
    }
    
    var postalCode : String? {
        if (json["profile"]["postal_code"] != nil) {
            return json["profile"]["postal_code"].string
        } else {
            return nil
        }
    }
    
    var address : String? {
        if (json["profile"]["address"] != nil) {
            return json["profile"]["address"].string
        } else {
            return nil
        }
    }
    
    var desc : String? {
        if (json["profile"]["description"] != nil) {
            return json["profile"]["description"].string
        } else {
            return nil
        }
    }
    
    var shippingIds : [String]? {
        let s : [String]?
        if (json["shipping_preferences_ids"] != nil) {
            s = []
            for (var i = 0; i < json["shipping_preferences_ids"].count; i++) {
                s!.append(json["shipping_preferences_ids"][i].string!)
            }
            return s
        } else {
            return nil
        }
    }
    
    var isPhoneVerified : Bool? {
        if (json["others"]["is_phone_verified"] != nil) {
            return json["others"]["is_phone_verified"].bool
        } else {
            return nil
        }
    }
    
    var registerTime : String? {
        let j = json["others"]["register_time"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var lastLogin : String? {
        let j = json["others"]["last_login"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var userPermalink : String? {
        let j = json["others"]["user_permalink"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var phoneCode : String? {
        let j = json["others"]["phone_code"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var numReviewer : Int? {
        let j = json["others"]["num_reviewer"]
        if (j != nil) {
            return j.int
        } else {
            return nil
        }
    }
    
    var totalStar : Int? {
        let j = json["others"]["total_star"]
        if (j != nil) {
            return j.int
        } else {
            return nil
        }
    }
    
    var lastOpenNotif : String? {
        let j = json["others"]["last_open_notification"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var resetPwdCode : String? {
        let j = json["others"]["reset_password_code"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var resetPwdTime : String? {
        let j = json["others"]["reset_password_time"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var deviceRegId : String? {
        let j = json["others"]["device_registration_id"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var deviceType : String? {
        let j = json["others"]["device_type"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    
    
    var fbId : String? {
        let j = json["others"]["fb_id"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var fbUsername : String? {
        let j = json["others"]["fb_username"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var fbAccessToken : String? {
        let j = json["others"]["fb_access_token"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var pathId : String? {
        let j = json["others"]["path_id"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var pathUsername : String? {
        let j = json["others"]["path_username"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var pathAccessToken : String? {
        let j = json["others"]["path_access_token"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var instagramId : String? {
        let j = json["others"]["instagram_id"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var instagramUsername : String? {
        let j = json["others"]["instagram_username"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var instagramAccessToken : String? {
        let j = json["others"]["instagram_access_token"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var twitterId : String? {
        let j = json["others"]["twitter_id"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var twitterUsername : String? {
        let j = json["others"]["twitter_username"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var twitterAccessToken : String? {
        let j = json["others"]["twitter_access_token"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
    
    var twitterTokenSecret : String? {
        let j = json["others"]["twitter_token_secret"]
        if (j != nil) {
            return j.string
        } else {
            return nil
        }
    }
}

public class ProductDetail : NSObject, TawarItem
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
        println(json)
        return json["_data"]["_id"].string!
    }
    
    var name : String
    {
        return (json["_data"]["name"].string)!.escapedHTML
    }
    
    var displayPicturers : Array<String>
    {
        if let ori : Array<String> = json["_data"]["display_picts"].arrayObject as? Array<String>
        {
            return ori
        } else if let ori = json["_data"]["display_picts"].arrayObject
        {
            if (ori.count > 0)
            {
                var arr : [String] = []
                for i in 0...ori.count-1
                {
                    if let o = ori[i] as? String
                    {
                        arr.append(o)
                    }
                }
                return arr
            }
        }
        return []
    }
    
    var originalPicturers : Array<String>
        {
            println(json)
            if let ori : Array<String> = json["_data"]["original_picts"].arrayObject as? Array<String>
            {
                return ori
            } else if let ori = json["_data"]["original_picts"].arrayObject
            {
                if (ori.count > 0)
                {
                    var arr : [String] = []
                    for i in 0...ori.count-1
                    {
                        if let o = ori[i] as? String
                        {
                            arr.append(o)
                        }
                    }
                    return arr
                }
            }
            return []
    }
    
    var shopAvatarURL : NSURL?
    {
        if let p = json["_data"]["seller"]["pict"].string
        {
            return NSURL(string : p)
        }
        return NSURL(string: "\(AppTools.PreloBaseUrl)/eweuh-gambar")
    }
    
    var discussionCountText : String
    {
        if let num_comment = json["_data"]["num_comment"].int
        {
            return String(num_comment)
        }
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
            let a = json["_data"]["comments"].array
            if (a?.count == 0) {
                return []
            } else {
                let f = a?.objectAtCircleIndex(0)
                var r : Array<ProductDiscussion> = []
                if (a != nil)
                {
                    for i in 0...(a?.count)!-1
                    {
                        let j = a?[i]
                        let dx = ProductDiscussion.instance(j)
                        r.append(dx!)
                    }
                }
                
                return r
            }
    }
    
    private var _isMyProduct : Bool?
    var isMyProduct : Bool
    {
        if (_isMyProduct != nil)
        {
            return _isMyProduct!
        }
        
        if let sellerId = json?["_data"]["seller"]["_id"].string, let userId = CDUser.getOne()?.id
        {
            _isMyProduct = sellerId == userId
            return _isMyProduct!
        }
        
        return false
    }
    
    var productImage : NSURL {
        if let s = displayPicturers.first
        {
            if let url = NSURL(string : s)
            {
                return url
            }
        }
        
        return NSURL(string : "http://prelo.do")!
    }
    
    var itemName : String
    {
        return name
    }
    
    var title : String {
        return name
    }
    
    var price : String {
        if let fullname = json["_data"]["price"].int
        {
            return fullname.asPrice
        }
        return ""
    }
    
    var theirId : String {
        if let fullname = json["_data"]["seller"]["_id"].string
        {
            return fullname
        }
        return ""
    }
    
    var theirImage : NSURL {
        if let fullname = json["_data"]["seller"]["pict"].string
        {
            if let url = NSURL(string : fullname)
            {
                return url
            }
        }
        return NSURL(string : "http://prelo.do")!
    }
    
    var theirName : String {
        if let fullname = json["_data"]["seller"]["fullname"].string
        {
            return fullname
        }
        return ""
    }
    
    var myId : String {
        if let id = CDUser.getOne()?.id
        {
            return id
        }
        return ""
    }
    
    var myImage : NSURL {
        if let pict = CDUser.getOne()?.profiles.pict
        {
            if let url = NSURL(string : pict)
            {
                return url
            }
        }
        return NSURL(string : "http://prelo.do")!
    }
    
    var myName : String {
        if let fullname = CDUser.getOne()?.fullname
        {
            return fullname
        }
        return ""
    }
    
    var opIsMe : Bool {
        return true
    }
    
    var threadId : String {
        return ""
    }
    
    var itemId : String {
        return productID
    }
    
    var threadState : Int {
        return 0
    }
    
    var bargainPrice : Int {
        return 0
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
        if let base = json["display_picts"][0].string
        {
            if let url = NSURL(string : base)
            {
                return url
            }
        }
        
        return NSURL(string: "http://dev.kleora.com/images/products/")
    }
    
    var discussionCountText : String
        {
            if let d = json["comments"].int
            {
                return String(d)
            }
            
            let a = json["comments"].array
            if (a?.count == 0) {
                return "0"
            } else {
                let f = a?.objectAtCircleIndex(0)
                if let d = f?["comments"].array
                {
                    return String(d.count)
                } else if let n = f?["num_comment"].int
                {
                    return String(n)
                }
                return "0"
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
            let a = json["comments"].array
            if (a?.count == 0) {
                return []
            } else {
                let f = a?.objectAtCircleIndex(0)
                let d = f?["comments"].array
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

class MyProductItem : Product {
    
    static func instanceMyProduct(obj : JSON?) -> MyProductItem?
    {
        if (obj == nil) {
            return nil
        } else {
            var p = MyProductItem()
            p.json = obj!
            return p
        }
    }
    
    var id : String {
        let i = (json["_id"].string)!
        return i
    }
    
    override var price : String {
        if let l = json["price"].int {
            return String(l)
        }
        return ""
    }
    
    override var loveCountText : String {
        if let l = json["num_lovelist"].int {
            return String(l)
        }
        return ""
    }
    
    override var discussionCountText : String {
        if let d = json["num_comment"].int {
            return String(d)
        }
        return ""
    }
    
    var status : Int {
        let s = (json["status"].int)!
        return s
    }
    
    var statusText : String {
        let s = (json["status_text"].string)!
        return s
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
    
    var name : String
    {
        if let n = json["sender_username"].string
        {
            return n
        } else
        {
            return ""
        }
    }
    
    var message : String
    {
        let m = (json["comment"].string)!.escapedHTML
        return m
    }
    
    var posterImageURL : NSURL?
    {
        return NSURL(string: json["sender_pict"].string!)
    }
    
    var date : NSDate?
    var formatter : NSDateFormatter?
    var timestamp : String
    {
        if (date == nil)
        {
            if let s = json["time"].string
            {
                return s
            }
        }
        
        formatter?.dateFormat = "eee"
        
        return (formatter?.stringFromDate(date!))!
    }
    
    func isSeller(compareId : String) -> Bool
    {
        if let id = json["_id"].string
        {
            return compareId == id
        } else
        {
            return false
        }
    }
}

class UserTransaction: NSObject {
    
    var json : JSON!
    
    static func instance(json : JSON?) -> UserTransaction? {
        if (json == nil) {
            return nil
        } else {
            let u = UserTransaction()
            u.json = json!
            return u
        }
    }
    
    var productImages : [NSURL] {
        let arr = json["transaction_products"].array!
        var images : [NSURL] = []
        if (arr.count == 0) {
            return images
        }
        for i in 0...arr.count-1
        {
            let d = arr[i]
            let p = Product.instance(d)
            if let url = p?.coverImageURL
            {
                images.append(url)
            }
        }
        return images
    }
    
    var id : String {
        let t = (json["_id"].string)!
        return t
    }
    
    var productId : String {
        let p = (json["product_id"].string)!
        return p
    }
    
    var progress : Int {
        let p = (json["progress"].int)!
        return p
    }
    
    var progressText : String {
        let p = (json["progress_text"].string)!
        return p
    }
    
    var productPrice : Int {
        let p = (json["product_price"].int)!
        return p
    }
    
    var totalPrice : Int {
        let t = (json["total_price"].int)!
        return t
    }
    
    var time : String {
        let t = (json["time"].string)!
        return t
    }
    
    var productName : String {
        let arr = json["transaction_products"].array!
        let p = arr[0]["product_name"].string!
//        let p = (json["product"]["name"].string)!
        return p
    }
    
    // Only take first image from json
    var productImageURL : NSURL? {
        let arr = json["transaction_products"].array!
        
        if let err = arr[0]["display_picts"][0].error
        {
            return nil
        }
        let url = arr[0]["display_picts"][0].string!
        return NSURL(string: url)
    }
    
    var productLoveCount : Int {
        let p = (json["product"]["num_lovelist"].int)!
        return p
    }
    
    var productCommentCount : Int {
        let p = (json["product"]["num_comment"].int)!
        return p
    }
}

class TransactionDetail : NSObject {
    var json : JSON!
    
    static func instance(json : JSON?) -> TransactionDetail? {
        if (json == nil) {
            return nil
        } else {
            let t = TransactionDetail()
            t.json = json!
            return t
        }
    }
    
    var id : String {
        let i = (json["_id"].string)!
        return i
    }
    
    var productId : String {
        let p = (json["product_id"].string)!
        return p
    }
    
    var sellerId : String {
        let s = (json["seller_id"].string)!
        return s
    }
    
    var sellerName : String {
        let s = (json["seller_name"].string)!
        return s
    }
    
    var progress : Int {
        let p = (json["progress"].int)!
        return p
    }
    
    var progressText : String {
        let p = (json["progress_text"].string)!
        return p
    }
    
    var productPrice : Int {
        let p = (json["product_price"].int)!
        return p
    }
    
    var totalPrice : Int {
        let t = (json["total_price"].int)!
        return t
    }
    
    var time : String {
        let t = (json["time"].string)!
        return t
    }
    
    var productName : String {
        let p = (json["product"]["name"].string)!
        return p
    }
    
    // Only take first image from json
    var productImageURL : NSURL? {
        if let err = json["product"]["display_picts"][0].error
        {
            return nil
        }
        let url = json["product"]["display_picts"][0].string!
        return NSURL(string: url)
    }
    
    var paymentMethod : String? {
        if (json["payment_method"] != nil) {
            return json["payment_method"].string
        } else {
            return nil
        }
    }
    
    var paymentDate : String? {
        if (json["payment_date"] != nil) {
            return json["payment_date"].string
        } else {
            return nil
        }
    }
    
    var shippingName : String? {
        if (json["shipping_name"] != nil) {
            return json["shipping_name"].string
        } else {
            return nil
        }
    }
    
    var resiNumber : String? {
        if (json["resi_number"] != nil) {
            return json["resi_number"].string
        } else {
            return nil
        }
    }
    
    var shippingDate : String? {
        if (json["shipping_date"] != nil) {
            return json["shipping_date"].string
        } else {
            return nil
        }
    }
    
    var reviewerName : String? {
        if (json["review"]["buyer_fullname"] != nil) {
            return json["review"]["buyer_fullname"].string
        } else {
            return nil
        }
    }
    
    var reviewerImageURL : NSURL? {
        if let err = json["review"]["buyer_pict"].error
        {
            return nil
        }
        let url = json["review"]["buyer_pict"].string!
        return NSURL(string: url)
    }
    
    var reviewStar : Int? {
        if (json["review"]["star"] != nil) {
            return json["review"]["star"].int
        } else {
            return nil
        }
    }
    
    var reviewComment : String? {
        if (json["review"]["comment"] != nil) {
            return json["review"]["comment"].string
        } else {
            return nil
        }
    }
}

class LovedProduct : NSObject {
    
    var json : JSON!
    
    static func instance(json : JSON?) -> LovedProduct? {
        if (json == nil) {
            return nil
        } else {
            let l = LovedProduct()
            l.json = json!
            return l
        }
    }
    
    var id : String {
        let i = (json["_id"].string)!
        return i
    }
    
    var name : String {
        let n = (json["name"].string)!
        return n
    }
    
    var price : Int {
        let p = (json["price"].int)!
        return p
    }
    
    var priceOriginal : Int {
        let p = (json["price_original"].int)!
        return p
    }
    
    var numLovelist : Int {
        let n = (json["num_lovelist"].int)!
        return n
    }
    
    var numComment : Int {
        let n = (json["num_comment"].int)!
        return n
    }
    
    var productImageURL : NSURL? {
        if (json["display_picts"][0].string == nil)
        {
            return nil
        }
        let url = json["display_picts"][0].string!
        return NSURL(string: url)
    }
}

class UserCheckout : NSObject {
    
    var json : JSON!
    var transactionProducts : [UserCheckoutProduct]!
    
    static func instance(json : JSON?) -> UserCheckout? {
        if (json == nil) {
            return nil
        } else {
            let u = UserCheckout()
            u.json = json!
            u.transactionProducts = []
            for (var i = 0; i < u.json["transaction_products"].count; i++) {
                let t = u.json["transaction_products"][i]
                if (t != nil) {
                    u.transactionProducts.append(UserCheckoutProduct.instanceCheckoutProduct(t)!)
                }
            }
            return u
        }
    }
    
    var id : String {
        if let i = json["_id"].string {
            return i
        }
        return ""
    }
    
    var paymentMethod : String {
        if let p = json["payment_method"].string {
            return p
        }
        return ""
    }
    
    var progress : Int {
        if let p = json["progress"].int {
            return p
        }
        return 0
    }
    
    var buyerId : String {
        if let b = json["buyer_id"].string {
            return b
        }
        return ""
    }
    
    var totalPrice : Int {
        if let t = json["total_price"].int {
            return t
        }
        return 0
    }
    
    var v : Int {
        if let v = json["__v"].int {
            return v
        }
        return 0
    }
    
    var orderIdValid : Bool {
        if let o = json["order_id_valid"].bool {
            return o
        }
        return false
    }
    
    var orderId : String {
        if let o = json["order_id"].string {
            return o
        }
        return ""
    }
    
    var time : String {
        if let t = json["time"].string {
            return t
        }
        return ""
    }
    
    var progressText : String {
        if let p = json["progress_text"].string {
            return p
        }
        return ""
    }
}

class UserCheckoutProduct : TransactionDetail {
    
    static func instanceCheckoutProduct(obj : JSON?) -> UserCheckoutProduct?
    {
        if (obj == nil) {
            return nil
        } else {
            var p = UserCheckoutProduct()
            p.json = obj!
            return p
        }
    }
    
    var orderIndex : Int {
        if let o = json["order_index"].int
        {
            return o
        }
        return 0
    }
    
    var shippingTimeMin : Int {
        if let s = json["shipping_time_min"].int
        {
            return s
        }
        return 0
    }
    
    var shippingTimeMax : Int {
        if let s = json["shipping_time_max"].int
        {
            return s
        }
        return 0
    }
    
    // Only take first image from json
    override var productImageURL : NSURL? {
        if let err = json["display_picts"][0].error
        {
            return nil
        }
        let url = json["display_picts"][0].string!
        return NSURL(string: url)
    }
}

class SearchUser : NSObject
{
    var json : JSON!
    
    static func instance(json : JSON?) -> SearchUser? {
        if (json == nil) {
            return nil
        } else {
            let u = SearchUser()
            u.json = json!
            return u
        }
    }
    
    var fullname : String
    {
        if let name = json?["fullname"].string
        {
            return name
        }
        return ""
    }
    
    var username : String
        {
            if let name = json?["username"].string
            {
                return name
            }
            return ""
    }
    
    var id : String
    {
        if let name = json?["_id"].string
        {
            return name
        }
        return ""
    }
    
    var pict : String
        {
            if let name = json?["profile"]["pict"].string
            {
                return name
            }
            return ""
    }
}

class Inbox : NSObject, TawarItem
{
    var json : JSON!
    var date : NSDate = NSDate()
    
    init (jsn : JSON)
    {
        json = jsn
        
        if let dateString = json["update_time"].string
        {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let x = formatter.dateFromString(dateString)
            {
                date = x
            }
        }
    }
    
    var id : String
    {
        if let x = json["_id"].string
        {
            return x
        }
        return ""
    }
    
    var judul : String
    {
        if let x = json["title"].string
        {
            return x
        }
        return ""
    }
    
    var message : String
    {
        if let x = json["preview_message"].string
        {
            return x
        }
        return ""
    }
    
    var imageURL : NSURL
    {
        if let x = json["image_path"].string
        {
            if let url = NSURL(string : x)
            {
                return url
            }
        }
        return NSURL(string : "http://prelo.do")!
    }
    
    var type : String
    {
        if let x = json["inbox_type"].int
        {
            return String(x)
        }
        return ""
    }
    
    var itemName : String {
        return judul
    }
    
    var productImage : NSURL {
        return imageURL
    }
    
    var title : String {
        return judul
    }
    
    var price : String {
        if let x = json["product_price"].int
        {
            return x.asPrice
        }
        return ""
    }
    
    var myId : String {
        let identifier = opIsMe ? "user_id1" : "user_id2"
        if let x = json[identifier].string
        {
            return x
        }
        return ""
    }
    
    var myImage : NSURL {
        let identifier = opIsMe ? "image_path_user1" : "image_path_user2"
        if let x = json[identifier].string
        {
            if let url = NSURL(string : x)
            {
                return url
            }
        }
        return NSURL(string : "http://prelo.do")!
    }
    
    var myName : String {
        let identifier = opIsMe ? "fullname_user1" : "fullname_user2"
        if let x = json[identifier].string
        {
            return x
        }
        return ""
    }
    
    var theirId : String {
        let identifier = opIsMe ? "user_id2" : "user_id1"
        if let x = json[identifier].string
        {
            return x
        }
        return ""
    }
    
    var theirImage : NSURL {
        let identifier = opIsMe ? "image_path_user2" : "image_path_user1"
        if let x = json[identifier].string
        {
            if let url = NSURL(string : x)
            {
                return url
            }
        }
        return NSURL(string : "http://prelo.do")!
    }
    
    var theirName : String {
        let identifier = opIsMe ? "fullname_user2" : "fullname_user1"
        if let x = json[identifier].string
        {
            return x
        }
        return ""
    }
    
    var opIsMe : Bool {
        if let x = json["user_id1"].string, let myId = CDUser.getOne()?.id
        {
            return x == myId
        }
        return false
    }
    
    var threadId : String {
        return id
    }
    
    var itemId : String {
        if let x = json["object_id"].string
        {
            return x
        }
        return ""
    }
    
    var threadState : Int {
        if let s = json["current_state"].int
        {
            return s
        }
        return 0
    }
    
    var bargainPrice : Int {
        if let s = json["current_bargain_amount"].int
        {
            return s
        }
        return 0
    }
}

class InboxMessage : NSObject
{
    static var formatter : NSDateFormatter = NSDateFormatter()
    
    var sending : Bool = false
    var id : String!
    var senderId : String!
    var messageType : Int = 0
    var message : String!
    var dynamicMessage : String {
        
        if (messageType == 1)
        {
            return "Tawar \n" + message.int.asPrice
        }
        
        if (messageType == 2)
        {
            return "Terima Tawaran\n" + message.int.asPrice
        }
        
        if (messageType == 3)
        {
            return "Tolak Tawar\n" + message.int.asPrice
        }
        
        return message
    }
    var dateTime : NSDate = NSDate()
    private var _time : String = ""
    var time : String {
        
        set {
            _time = newValue
            InboxMessage.formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = InboxMessage.formatter.dateFromString(_time)
            {
                dateTime = date
            }
        }
        
        get {
            return _time
        }
        
    }
    var isMe : Bool = false
    var failedToSend : Bool = false
    
    init (msgJSON : JSON)
    {
        super.init()
        if let x = msgJSON["_id"].string
        {
            id = x
        }
        
        if let x = msgJSON["sender_id"].string
        {
            senderId = x
        }
        
        if let x = msgJSON["message_type"].int
        {
            messageType = x
        }
        
        if let x = msgJSON["message"].string
        {
            message = x
        }
        
        if let x = msgJSON["time"].string
        {
            time = x
        }
        
        if let myId = CDUser.getOne()?.id
        {
            if (myId == senderId)
            {
                isMe = true
            }
        }
    }
    
    override init() {
        
    }
    
    static func messageFromMe(localIndex : Int, type : Int, message : String, time : String) -> InboxMessage
    {
        let i = InboxMessage()
        
        i.senderId = CDUser.getOne()?.id
        i.id = String(localIndex)
        i.messageType = type
        i.message = message
        i.time = time
        i.isMe = true
        i.failedToSend = false
        
        return i
    }
    
    private var lastThreadId = ""
    private var lastCompletion : (InboxMessage)->() = {m in }
    func sendTo(threadId : String, completion : (InboxMessage)->())
    {
        lastThreadId = threadId
        lastCompletion = completion
        sending = true
        self.failedToSend = false
        request(APIInbox.SendTo(inboxId: threadId, type: messageType, message: message)).responseJSON { req, resp, res, err in
            self.sending = false
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                
            } else
            {
                self.failedToSend = true
            }
            completion(self)
        }
    }
    
    func resend()
    {
        self.sendTo(lastThreadId, completion: lastCompletion)
    }
}
