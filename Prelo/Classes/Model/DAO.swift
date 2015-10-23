//
//  DAO.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Foundation

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
    
    // TODO : others: isPhoneVerified etc
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
    
    var shopAvatarURL : NSURL?
    {
        if let p = json["_data"]["seller"]["pict"].string
        {
            return NSURL(string : p)
        }
        return NSURL(string: "http://prelo.id/eweuh-gambar")
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
        return false
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
