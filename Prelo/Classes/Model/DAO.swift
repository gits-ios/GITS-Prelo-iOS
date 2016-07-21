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
        let base = "\(AppTools.PreloBaseUrl)/images/users/" + userID + "/" + fileName
        return base
    }
    
    static func UrlForDisplayPicture(imageName : String, productID : String) -> String
    {
        let modifiedImageName = imageName.stringByReplacingOccurrencesOfString("..\\/", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        return "\(AppTools.PreloBaseUrl)/images/products/" + productID + "/" + modifiedImageName
        
    }
}

public class User : NSObject
{
    private static var TokenKey = "user_token"
    private static var IdKey = "user_id"
    private static var EmailKey = "user_email"
    
    static var IsLoggedIn : Bool
    {
        guard let _ = NSUserDefaults.standardUserDefaults().stringForKey(User.TokenKey), let _ = CDUser.getOne(), let _ = CDUserProfile.getOne(), let _ = CDUserOther.getOne() else {
            return false
        }
        return true
    }
    
    static var IsLoggedInTwitter : Bool
    {
        var loggedIn = false
        if let uOther = CDUserOther.getOne() {
            if (uOther.twitterID != nil && uOther.twitterID != "" && uOther.twitterUsername != nil && uOther.twitterUsername != "" && uOther.twitterAccessToken != nil && uOther.twitterAccessToken != "" && uOther.twitterTokenSecret != nil && uOther.twitterTokenSecret != "") {
                loggedIn = true
            }
        }
        return loggedIn
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
        /*Mixpanel.sharedInstance().track("Logged Out")
        Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
        Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])*/
        
        CDUser.deleteAll()
        CDUserProfile.deleteAll()
        CDUserOther.deleteAll()
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey(User.IdKey)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(User.TokenKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey("pathtoken")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("twittertoken")
        
        NSUserDefaults.setTourDone(false)
        
        self.LogoutFacebook()
        self.LogoutTwitter()
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
        if let userID = store.session()?.userID {
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
        if let i = json["_id"].string {
            return i
        }
        return ""
    }
    
    var username : String {
        if let u = json["username"].string {
            return u
        }
        return ""
    }
    
    var email : String {
        if let e = json["email"].string {
            return e
        }
        return ""
    }
    
    var fullname : String {
        if let f = json["fullname"].string {
            return f
        }
        return ""
    }
    
    var profPictURL : NSURL? {
        if let url = json["profile"]["pict"].string {
            return NSURL(string: url)
        }
        return nil
    }
    
    var phone : String {
        if let j = json["profile"]["phone"].string {
            return j
        }
        return ""
    }
    
    var regionId : String {
        if let r = json["profile"]["region_id"].string {
            return r
        }
        return ""
    }
    
    var provinceId : String {
        if let p = json["profile"]["province_id"].string {
            return p
        }
        return ""
    }
    
    var subdistrictId : String {
        if let j = json["profile"]["subdistrict_id"].string {
            return j
        }
        return ""
    }
    
    var subdistrictName : String {
        if let j = json["profile"]["subdistrict_name"].string {
            return j
        }
        return ""
    }
    
    var gender : String {
        if let j = json["profile"]["gender"].string {
            return j
        }
        return ""
    }
    
    var postalCode : String {
        if let j = json["profile"]["postal_code"].string {
            return j
        }
        return ""
    }
    
    var address : String {
        if let j = json["profile"]["address"].string {
            return j
        }
        return ""
    }
    
    var desc : String {
        if let j = json["profile"]["description"].string {
            return j
        }
        return ""
    }
    
    var shippingIds : [String] {
        var s : [String] = []
        if let j : JSON = json["shipping_preferences_ids"] {
            for i in 0 ..< j.count {
                if let shipId = j[i].string {
                    s.append(shipId)
                }
            }
        }
        return s
    }
    
    var categoryPrefIds : [String] {
        var c : [String] = []
        if let j : JSON = json["others"]["category_preferences_ids"] {
            for i in 0 ..< j.count {
                if let pref = j[i].string {
                    c.append(pref)
                }
            }
        }
        return c
    }
    
    var isPhoneVerified : Bool {
        if let j = json["others"]["is_phone_verified"].bool {
            return j
        }
        return false
    }
    
    var isEmailVerified : Bool {
        if let j = json["others"]["is_email_verified"].bool {
            return j
        }
        return false
    }
    
    var registerTime : String {
        if let j = json["others"]["register_time"].string {
            return j
        }
        return ""
    }
    
    var lastLogin : String {
        if let j = json["others"]["last_login"].string {
            return j
        }
        return ""
    }
    
    var userPermalink : String {
        if let j = json["others"]["user_permalink"].string {
            return j
        }
        return ""
    }
    
    var phoneCode : String {
        if let j = json["others"]["phone_code"].string {
            return j
        }
        return ""
    }
    
    var numReviewer : Int {
        if let j = json["others"]["num_reviewer"].int {
            return j
        }
        return 0
    }
    
    var totalStar : Int {
        if let j = json["others"]["total_star"].int {
            return j
        }
        return 0
    }
    
    var lastOpenNotif : String {
        if let j = json["others"]["last_open_notification"].string {
            return j
        }
        return ""
    }
    
    var resetPwdCode : String {
        if let j = json["others"]["reset_password_code"].string {
            return j
        }
        return ""
    }
    
    var resetPwdTime : String {
        if let j = json["others"]["reset_password_time"].string {
            return j
        }
        return ""
    }
    
    var deviceRegId : String {
        if let j = json["others"]["device_registration_id"].string {
            return j
        }
        return ""
    }
    
    var deviceType : String {
        if let j = json["others"]["device_type"].string {
            return j
        }
        return ""
    }
    
    var fbId : String {
        if let j = json["others"]["fb_id"].string {
            return j
        }
        return ""
    }
    
    var fbUsername : String {
        if let j = json["others"]["fb_username"].string {
            return j
        }
        return ""
    }
    
    var fbAccessToken : String {
        if let j = json["others"]["fb_access_token"].string {
            return j
        }
        return ""
    }
    
    var pathId : String {
        if let j = json["others"]["path_id"].string {
            return j
        }
        return ""
    }
    
    var pathUsername : String {
        if let j = json["others"]["path_username"].string {
            return j
        }
        return ""
    }
    
    var pathAccessToken : String {
        if let j = json["others"]["path_access_token"].string {
            return j
        }
        return ""
    }
    
    var instagramId : String {
        if let j = json["others"]["instagram_id"].string {
            return j
        }
        return ""
    }
    
    var instagramUsername : String {
        if let j = json["others"]["instagram_username"].string {
            return j
        }
        return ""
    }
    
    var instagramAccessToken : String {
        if let j = json["others"]["instagram_access_token"].string {
            return j
        }
        return ""
    }
    
    var twitterId : String {
        if let j = json["others"]["twitter_id"].string {
            return j
        }
        return ""
    }
    
    var twitterUsername : String {
        if let j = json["others"]["twitter_username"].string {
            return j
        }
        return ""
    }
    
    var twitterAccessToken : String {
        if let j = json["others"]["twitter_access_token"].string {
            return j
        }
        return ""
    }
    
    var twitterTokenSecret : String {
        if let j = json["others"]["twitter_token_secret"].string {
            return j
        }
        return ""
    }
}

public class ProductDetail : NSObject, TawarItem
{
    var json : JSON = JSON([:])
    
    static func instance(obj : JSON?)->ProductDetail?
    {
        if (obj == nil) {
            return nil
        } else {
            let p = ProductDetail()
            p.json = obj!
            return p
        }
    }
    
    private func urlForDisplayPicture(imageName : String, productID : String) -> String
    {
        let modifiedImageName = imageName.stringByReplacingOccurrencesOfString("..\\/", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        return "http://dev.kleora.com/images/products/" + productID + "/" + modifiedImageName
    }
    
    var isActive : Bool {
        return json["_data"]["status"].boolValue
    }
    
    var status : Int {
        return json["_data"]["status"].intValue
    }
    
    func setStatus(newStatus : Int) {
        json["_data"]["status"] = JSON(newStatus)
    }
    
    var rejectionText : String {
        return json["_data"]["rejection_text"].stringValue
    }
    
    var transactionProgress : Int {
        return json["_data"]["transaction_progress"].intValue
    }
    
    var boughtByMe : Bool {
        return json["_data"]["bought_by_me"].boolValue
    }
    
    func setBoughtByMe(val : Bool) {
        json["_data"]["bought_by_me"] = JSON(val)
    }
    
    var size : String {
        return json["_data"]["size"].stringValue
    }
    
    var specialStory : String {
        if let u = json["_data"]["special_story"].string
        {
            return u
        } else
        {
            return ""
        }
    }
    
    var defectDescription : String {
        if let u = json["_data"]["defect_description"].string
        {
            return u
        } else
        {
            return ""
        }
    }
    
    var sellReason : String {
        if let u = json["_data"]["sell_reason"].string
        {
            return u
        } else
        {
            return ""
        }
    }
    
    var productID : String
    {
        print(json)
        return json["_data"]["_id"].string!
    }
    
    var name : String
    {
        return (json["_data"]["name"].string)!.escapedHTML
    }
    
    var totalViews : Int {
        return json["_data"]["total_views"].intValue
    }
    
    var lastSeenSeller : String {
        return json["_data"]["seller"]["last_seen"].stringValue
    }
    
    var permalink : String
    {
        return (json["_data"]["permalink"].string)!
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
            print(json)
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
    
    var imageLabels : [String]
    {
        var labels : [String] = []
        print(json["_data"]["original_picts"])
        if let ori = json["_data"]["original_picts"].arrayObject
        {
            var i = 0
            for x in ori
            {
                if x is String
                {
                    switch (i)
                    {
                    case 0 : labels.append("Gambar Utama")
                    case 1 : labels.append("Tampak Belakang")
                    case 2 : labels.append("Ketika Dipakai")
                    case 3 : labels.append("Tampilan Label / Merek")
                    case 4 : labels.append("Cacat")
                    default : labels.append("unknown")
                    }
                }
                i += 1
            }
        }
        return labels
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
//                let f = a?.objectAtCircleIndex(0)
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
        
        if let sellerId = json["_data"]["seller"]["_id"].string, let userId = CDUser.getOne()?.id
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
    
    // tawar item
    
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
    
    var buyerId = ""
    var buyerName = ""
    var buyerImage = ""
    
    var theirId : String {
        if (reveresed)
        {
            return buyerId
        }
        if let fullname = json["_data"]["seller"]["_id"].string
        {
            return fullname
        }
        return ""
    }
    
    var theirImage : NSURL {
        if (reveresed)
        {
            if let pict = CDUser.getOne()?.profiles.pict
            {
                if let url = NSURL(string : pict)
                {
                    return url
                }
            }
        }
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
        if (reveresed)
        {
            return buyerName
        }
        if let username = json["_data"]["seller"]["username"].string
        {
            return username
        }
        return ""
    }
    
    var myId : String {
        if (reveresed)
        {
            if let fullname = json["_data"]["seller"]["_id"].string
            {
                return fullname
            }
        }
        if let id = CDUser.getOne()?.id
        {
            return id
        }
        return ""
    }
    
    var myImage : NSURL {
        if (reveresed)
        {
            if let fullname = json["_data"]["seller"]["pict"].string
            {
                if let url = NSURL(string : fullname)
                {
                    return url
                }
            }
        }
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
        if (reveresed)
        {
            if let fullname = json["_data"]["seller"]["fullname"].string
            {
                return fullname
            }
        }
        if let fullname = CDUser.getOne()?.fullname
        {
            return fullname
        }
        return ""
    }
    
    var categoryBreadcrumbs : [JSON] {
        if let arr = json["_data"]["category_breadcrumbs"].array {
            return arr
        }
        return []
    }
    
    var opIsMe : Bool {
        if (reveresed)
        {
            return false
        }
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
    
    func setBargainPrice(price: Int) {
        
    }
    
    var bargainerIsMe : Bool {
        if (reveresed)
        {
            return true
        }
        return false
    }
    
    var productStatus : Int {
        return json["_data"]["status"].intValue
    }
    
    var reveresed = false
    func reverse()
    {
        reveresed = !reveresed
    }
    
    var isGarageSale : Bool {
        if let j = json["_data"]["is_garage_sale"].bool {
            return j
        }
        return false
    }
    
    var sharedViaInstagram : Bool {
        if let j = json["_data"]["share_status"]["INSTAGRAM"].bool {
            return j
        }
        return false
    }
    
    var sharedViaFacebook : Bool {
        if let j = json["_data"]["share_status"]["FACEBOOK"].bool {
            return j
        }
        return false
    }
    
    var sharedViaTwitter : Bool {
        if let j = json["_data"]["share_status"]["TWITTER"].bool {
            return j
        }
        return false
    }
    
    func setSharedViaInstagram() {
        json["_data"]["share_status"]["INSTAGRAM"] = JSON(true)
    }
    
    func setSharedViaFacebook() {
        json["_data"]["share_status"]["FACEBOOK"] = JSON(true)
    }
    
    func setSharedViaTwitter() {
        json["_data"]["share_status"]["TWITTER"] = JSON(true)
    }
}

public class Product : NSObject
{
    static let StatusUploading = 999
    
    var json : JSON = JSON([:])
    var placeHolderImage : UIImage?
    var isLokal = false
    
    var id : String
    {
        if (isLokal)
        {
            return ""
        }
        return (json["_id"].string)!
    }
    
    var name : String
    {
        return (json["name"].string)!.escapedHTML
    }
    
    static func instance(obj:JSON?)->Product?
    {
        if (obj == nil) {
            return nil
        } else {
            let p = Product()
            p.json = obj!
            return p
        }
    }
    
    var coverImageURL : NSURL?
    {
        if (isLokal)
        {
            return nil
        }
        
        if json["display_picts"][0].error != nil
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
        print(json)
        if let p = json["price"].int
        {
            return p.asPrice
        }
        
        if (isLokal)
        {
            if let p = json["price"].string?.int
            {
                return p.asPrice
            }
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
    
    var specialStory : String? {
        if let s = json["special_story"].string
        {
            return s
        } else
        {
            return ""
        }
    }
    
    var avatar : NSURL? {
        if var seller_pict_thumb = json["seller_pict_thumb"].string
        {
            seller_pict_thumb = seller_pict_thumb.stringByReplacingOccurrencesOfString(" ", withString: "")
            let url = NSURL(string : seller_pict_thumb)
            return url!
        }
        return nil
    }
    
    var status : Int? {
        if (isLokal)
        {
            return Product.StatusUploading
        }
        if let s = json["status"].int {
            return s
        }
        return nil
    }
    
    var isFeatured : Bool {
        if let j = json["is_catalogue"].bool {
            return j
        }
        return false
    }
    
    func setToFeatured() {
        json["is_catalogue"] = JSON(true)
    }
    
    var isSharedInstagram : Bool {
        if let j = json["share_status"]["INSTAGRAM"].int {
            if (j == 1) {
                return true
            }
        }
        return false
    }
    
    var isSharedFacebook : Bool {
        if let j = json["share_status"]["FACEBOOK"].int {
            if (j == 1) {
                return true
            }
        }
        return false
    }
    
    var isSharedTwitter : Bool {
        if let j = json["share_status"]["TWITTER"].int {
            if (j == 1) {
                return true
            }
        }
        return false
    }
    
    var commission : Int {
        if let j = json["commission"].int {
            return j
        }
        return 10
    }
}

class MyProductItem : Product {
    
    static func instanceMyProduct(obj : JSON?) -> MyProductItem?
    {
        if (obj == nil) {
            return nil
        } else {
            let p = MyProductItem()
            p.json = obj!
            return p
        }
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
    
    override var status : Int {
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
        
        if arr[0]["display_picts"][0].error != nil
        {
            return nil
        }
        let url = arr[0]["display_picts"][0].string!
        return NSURL(string: url)
    }
    
    var productLoveCount : Int {
        if let p = (json["product"]["num_lovelist"].int) {
            return p
        } else {
            return 0
        }
    }
    
    var productCommentCount : Int {
        if let p = (json["product"]["num_comment"].int) {
            return p
        } else {
            return 0
        }
    }
}

class UserTransactionItem: UserTransaction {
    
    static func instanceTransactionItem(json : JSON?) -> UserTransactionItem? {
        if (json == nil) {
            return nil
        } else {
            let u = UserTransactionItem()
            u.json = json!
            return u
        }
    }
    
    override var productName : String {
        var x = "-"
        let p = json["product"]["name"].stringValue
        if (p != "")
        {
            x = p
        }
        
        return x
    }
    
    // Only take first image from json
    override var productImageURL : NSURL? {
        if json["product"]["display_picts"][0].error != nil
        {
            return nil
        }
        if let url = json["product"]["display_picts"][0].string {
            return NSURL(string: url)
        } else {
            return nil
        }
    }
}

class TransactionDetail : NSObject {
    var json : JSON!
    
    static func instance(json : JSON?) -> TransactionDetail? {
        if (json != nil) {
            let t = TransactionDetail()
            t.json = json!
            return t
        }
        return nil
    }
    
    var id : String {
        if let j = json["_id"].string {
            return j
        }
        return ""
    }
    
    var expireTime : String {
        if let j = json["expire_time"].string {
            return j
        }
        return ""
    }
    
    var shippingExpireTime : String {
        if let j = json["shipping_expire_time"].string {
            return j
        }
        return ""
    }
    
    var paymentMethod : String {
        if let j = json["payment_method"].string {
            return j
        }
        return ""
    }
    
    var paymentDate : String {
        if let j = json["payment_date"].string {
            return j
        }
        return ""
    }
    
    var paymentBankTarget : String {
        if let j = json["payment_method_param"]["target_bank"].string {
            return j
        }
        return ""
    }
    
    var paymentBankSource : String {
        if let j = json["payment_method_param"]["source_bank"].string {
            return j
        }
        return ""
    }
    
    var paymentBankAccount : String {
        if let j = json["payment_method_param"]["name"].string {
            return j
        }
        return ""
    }
    
    var paymentTime : String {
        if let j = json["payment_method_param"]["time"].string {
            return j
        }
        return ""
    }
    
    var paymentNominal : Int {
        if let j = json["payment_method_param"]["nominal"].int {
            return j
        }
        return 0
    }
    
    var progress : Int {
        if let j = json["progress"].int {
            return j
        }
        return -9999
    }
    
    var buyerId : String {
        if let j = json["buyer_id"].string {
            return j
        }
        return ""
    }
    
    var ipAddress : String {
        if let j = json["ip_address"].string {
            return j
        }
        return ""
    }
    
    var userAgent : String {
        if let j = json["user_agent"].string {
            return j
        }
        return ""
    }
    
    var bonusUsed : Int {
        if let j = json["bonus_used"].int {
            return j
        }
        return 0
    }
    
    var preloBalanceUsed : Int {
        if let j = json["prelobalance_used"].int {
            return j
        }
        return 0
    }
    
    var totalPrice : Int {
        if let j = json["total_price"].int {
            return j
        }
        return 0
    }
    
    var totalPriceTotall : Int {
        if let j = json["total_price_totall"].int {
            return j
        }
        return 0
    }
    
    var bankTransferDigit : Int {
        if let j = json["banktransfer_digit"].int {
            return j
        }
        return 0
    }
    
    var orderIdValid : Bool {
        if let j = json["order_id_valid"].bool {
            return j
        }
        return false
    }
    
    var orderId : String {
        if let j = json["order_id"].string {
            return j
        }
        return ""
    }
    
    var time : String {
        if let j = json["time"].string {
            return j
        }
        return ""
    }
    
    var transactionProducts : [TransactionProductDetail] {
        var tps : [TransactionProductDetail] = []
        for i in 0 ..< json["transaction_products"].count {
            if let tp = TransactionProductDetail.instance(json["transaction_products"][i]) {
                tps.append(tp)
            }
        }
        return tps
    }
    
    var voucherSerial : String {
        if let j = json["voucher_serial"].string {
            return j
        }
        return ""
    }
    
    var voucherAmount : Int {
        if let j = json["voucher_amount"].int {
            return j
        }
        return 0
    }
    
    var shippingAddress : String {
        if let j = json["shipping_address"]["address"].string {
            return j
        }
        return ""
    }
    
    var shippingPostalCode : String {
        if let j = json["shipping_address"]["postal_code"].string {
            return j
        }
        return ""
    }
    
    var shippingRecipientName : String {
        if let j = json["shipping_address"]["recipient_name"].string {
            return j
        }
        return ""
    }
    
    var shippingProvinceId : String {
        if let j = json["shipping_address"]["province_id"].string {
            return j
        }
        return ""
    }
    
    var shippingRegionId : String {
        if let j = json["shipping_address"]["region_id"].string {
            return j
        }
        return ""
    }
    
    var shippingRecipientPhone : String {
        if let j = json["shipping_address"]["recipient_phone"].string {
            return j
        }
        return ""
    }
    
    var shippingEmail : String {
        if let j = json["shipping_address"]["email"].string {
            return j
        }
        return ""
    }
    
    var shippingName : String {
        if let j = json["shipping_name"].string {
            return j
        }
        return ""
    }
    
    var resiNumber : String {
        if let j = json["resi_number"].string {
            return j
        }
        return ""
    }
    
    func isBuyer(compareId : String) -> Bool
    {
        if let buyerId = json["buyer_id"].string {
            return compareId == buyerId
        } else {
            return false
        }
    }
}

class TransactionProductDetail : NSObject {
    var json : JSON!
    
    static func instance(json : JSON?) -> TransactionProductDetail? {
        if (json == nil) {
            return nil
        } else {
            let t = TransactionProductDetail()
            t.json = json!
            return t
        }
    }
    
    var id : String {
        let i = (json["_id"].string)!
        return i
    }
    
    var orderId : String {
        let o = (json["order_id"].string)!
        return o
    }
    
    var orderIdValid : Bool {
        if let j = json["order_id_valid"].bool {
            return j
        }
        return false
    }
    
    var transactionId : String {
        if let j = json["transaction_id"].string {
            return j
        }
        return ""
    }
    
    var productId : String {
        let p = (json["product_id"].string)!
        return p
    }
    
    var buyerId : String {
        if let j = json["buyer_id"].string {
            return j
        }
        return ""
    }
    
    var buyerName : String {
        if let j = json["buyer_name"].string {
            return j
        }
        return ""
    }
    
    var buyerUsername : String {
        if let j = json["buyer_username"].string {
            return j
        }
        return ""
    }
    
    var sellerId : String {
        let s = (json["seller_id"].string)!
        return s
    }
    
    var sellerName : String {
        let s = (json["seller_name"].string)!
        return s
    }
    
    var sellerUsername : String {
        let s = (json["seller_username"].string)!
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
    
    var commissionPrice : Int {
        if let p = json["commission_price"].int {
            return p
        }
        return 0
    }
    
    var totalPriceTotall : Int {
        if let j = json["total_price_totall"].int {
            return j
        }
        return 0
    }
    
    var commission : Int {
        if let c = json["commission"].int {
            return c
        }
        return -9999
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
        if json["product"]["display_picts"][0].error != nil
        {
            return nil
        }
        let url = json["product"]["display_picts"][0].stringValue
        return NSURL(string: url)
    }
    
    var paymentMethod : String {
        if (json["payment_method"] != nil) {
            return json["payment_method"].stringValue
        } else {
            return ""
        }
    }
    
    var paymentDate : String {
        if (json["payment_date"] != nil) {
            return json["payment_date"].stringValue
        } else {
            return ""
        }
    }
    
    var paymentBankTarget : String {
        if let j = json["payment_method_param"]["target_bank"].string {
            return j
        }
        return ""
    }
    
    var paymentBankSource : String {
        if let j = json["payment_method_param"]["source_bank"].string {
            return j
        }
        return ""
    }
    
    var paymentBankAccount : String {
        if let j = json["payment_method_param"]["name"].string {
            return j
        }
        return ""
    }
    
    var paymentTime : String {
        if let j = json["payment_method_param"]["time"].string {
            return j
        }
        return ""
    }
    
    var paymentNominal : Int {
        if let j = json["payment_method_param"]["nominal"].int {
            return j
        }
        return 0
    }
    
    var expireTime : String? {
        if (json["expire_time"] != nil) {
            return json["expire_time"].string
        } else {
            return nil
        }
    }
    
    var shippingExpireTime : String {
        if let j = json["shipping_expire_time"].string {
            return j
        }
        return ""
    }
    
    var shippingName : String {
        if (json["shipping_name"] != nil) {
            return json["shipping_name"].stringValue
        } else {
            return ""
        }
    }
    
    var shippingTimeMin : Int {
        if let j = json["shipping_time_min"].int {
            return j
        }
        return -9999
    }
    
    var shippingTimeMax : Int {
        if let j = json["shipping_time_max"].int {
            return j
        }
        return -9999
    }
    
    var resiNumber : String {
        if (json["resi_number"] != nil) {
            return json["resi_number"].stringValue
        } else {
            return ""
        }
    }
    
    var shippingDate : String {
        if (json["shipping_date"] != nil) {
            return json["shipping_date"].stringValue
        } else {
            return ""
        }
    }
    
    var shippingAddress : String {
        if (json["shipping_address"]["address"] != nil) {
            return json["shipping_address"]["address"].stringValue
        } else {
            return ""
        }
    }
    
    var shippingPostalCode : String {
        if (json["shipping_address"]["postal_code"] != nil) {
            return json["shipping_address"]["postal_code"].stringValue
        } else {
            return ""
        }
    }
    
    var shippingRecipientName : String {
        if (json["shipping_address"]["recipient_name"] != nil) {
            return json["shipping_address"]["recipient_name"].stringValue
        } else {
            return ""
        }
    }
    
    var shippingProvinceId : String! {
        if (json["shipping_address"]["province_id"] != nil) {
            return json["shipping_address"]["province_id"].stringValue
        } else {
            return ""
        }
    }
    
    var shippingRegionId : String! {
        if (json["shipping_address"]["region_id"] != nil) {
            return json["shipping_address"]["region_id"].stringValue
        } else {
            return ""
        }
    }
    
    var shippingRecipientPhone : String {
        if (json["shipping_address"]["recipient_phone"] != nil) {
            return json["shipping_address"]["recipient_phone"].stringValue
        } else {
            return ""
        }
    }
    
    var shippingEmail : String? {
        if (json["shipping_address"]["email"] != nil) {
            return json["shipping_address"]["email"].string
        } else {
            return nil
        }
    }

    var shippingPrice : String {
        if (json["shipping_price"] != nil) {
            return json["shipping_price"].stringValue
        } else {
            return "0"
        }
    }
    
    var reviewerName : String {
        if (json["review"]["buyer_username"] != nil) {
            return json["review"]["buyer_username"].stringValue
        } else {
            return ""
        }
    }
    
    var reviewerImageURL : NSURL? {
        if json["review"]["buyer_pict"].error != nil
        {
            return nil
        }
        let url = json["review"]["buyer_pict"].string!
        return NSURL(string: url)
    }
    
    var reviewStar : Int {
        if (json["review"]["star"] != nil) {
            return json["review"]["star"].intValue
        } else {
            return 0
        }
    }
    
    var reviewComment : String {
        if (json["review"]["comment"] != nil) {
            return json["review"]["comment"].stringValue
        } else {
            return ""
        }
    }
    
    var myPreloBalance : Int {
        if let j = json["my_prelo_balance"].int {
            return j
        }
        return 0
    }
    
    var myPreloBonus : Int {
        if let j = json["my_prelo_bonus"].int {
            return j
        }
        return 0
    }
    
    func isSeller(compareId : String) -> Bool
    {
        if let sellerId = json["seller_id"].string {
            return compareId == sellerId
        } else {
            return false
        }
    }
    
    var garageSalePlace : String {
        if let j = json["garage_sale"]["place"].string {
            return j
        }
        return ""
    }
    
    var garageSaleEventDate : String {
        if let j = json["garage_sale"]["event_date"].string {
            return j
        }
        return ""
    }
    
    var garageSaleEventTime : String {
        if let j = json["garage_sale"]["event_time"].string {
            return j
        }
        return ""
    }
    
    var garageSaleMapsUrl : String {
        if let j = json["garage_sale"]["maps_url"].string {
            return j
        }
        return ""
    }
}

class UserReview : NSObject {
    
    var json : JSON!
    
    static func instance(json : JSON?) -> UserReview? {
        if (json == nil) {
            return nil
        } else {
            let u = UserReview()
            u.json = json!
            return u
        }
    }
    
    var id : String {
        if (json["_id"] != nil) {
            return json["_id"].string!
        } else {
            return ""
        }
    }
    
    var buyerFullname : String {
        if (json["buyer_fullname"] != nil) {
            return json["buyer_fullname"].string!
        } else {
            return ""
        }
    }
    
    var buyerUsername : String {
        if (json["buyer_username"] != nil) {
            return json["buyer_username"].string!
        } else {
            return ""
        }
    }
    
    var star : Int {
        if (json["star"] != nil) {
            return json["star"].int!
        } else {
            return 0
        }
    }
    
    var comment : String {
        if (json["comment"] != nil) {
            return json["comment"].string!
        } else {
            return ""
        }
    }
    
    var buyerPictURL : NSURL? {
        if (json["buyer_pict"] != nil) {
            let url = json["buyer_pict"].string!
            return NSURL(string: url)
        }
        return nil
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
            for i in 0 ..< u.json["transaction_products"].count {
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
    
    var banktransferDigit : Int
        {
        return json["banktransfer_digit"].intValue
    }
}

class UserCheckoutProduct : TransactionProductDetail {
    
    static func instanceCheckoutProduct(obj : JSON?) -> UserCheckoutProduct?
    {
        if (obj == nil) {
            return nil
        } else {
            let p = UserCheckoutProduct()
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
    
    // Only take first image from json
    override var productImageURL : NSURL? {
        if let u = json["display_picts"][0].string
        {
            return NSURL(string: u)
        }
        return NSURL(string: "\(AppTools.PreloBaseUrl)/images/products/default.png")
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
    var forceThreadState = -1
    
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
        if (forceThreadState != -1)
        {
            return forceThreadState
        }
        if let s = json["current_state"].int
        {
            return s
        }
        return 0
    }
    
    var settedBargainPrice = -1
    var bargainPrice : Int {
        if (settedBargainPrice != -1)
        {
            return settedBargainPrice
        }
        if let s = json["current_bargain_amount"].int
        {
            return s
        }
        return 0
    }
    
    func setBargainPrice(price: Int) {
        settedBargainPrice = price
//        json["current_bargain_amount"].int = price
//        print("current_bargain_amount : " + String(bargainPrice))
    }
    
    var bargainerIsMe : Bool {
        if let x = json["bargainer_id"].string, let myId = CDUser.getOne()?.id
        {
            return x == myId
        }
        
        return false
    }
    
    var productStatus : Int {
        if let p = json["product_status"].int
        {
            return p
        }
        return 0
    }
}

class InboxMessage : NSObject
{
    static var formatter : NSDateFormatter = NSDateFormatter()
    
    var sending : Bool = false
    var id : String = ""
    var senderId : String = ""
    var messageType : Int = 0
    var message : String = ""
    var bargainPrice = ""
    var dynamicMessage : String {
        
//        return message
        
        if (messageType == 1)
        {
            return "Tawar \n" + message.int.asPrice
        }
        
        if (messageType == 2)
        {
            if (message.int != 0)
            {
                return "Terima tawaran " + message.int.asPrice
            } else
            {
                return message
            }
        }
        
        if (messageType == 3)
        {
            if (message.int != 0)
            {
                return "Tolak tawaran " + message.int.asPrice
            } else
            {
                return message
            }
//            return "Tolak Tawar\n" + message.int.asPrice
//            return message
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
        
        if let id = CDUser.getOne()?.id
        {
            i.senderId = id
        }
//        i.senderId = CDUser.getOne()?.id
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
        print("sending chat to thread " + threadId)
        lastThreadId = threadId
        lastCompletion = completion
        sending = true
        self.failedToSend = false
        let m = bargainPrice != "" && messageType != 0 ? bargainPrice : message
        // API Migrasi
        request(APIInbox.SendTo(inboxId: threadId, type: messageType, message: m)).responseJSON {resp in
            self.sending = false
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Kirim chat"))
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

class Notification : NSObject
{
    var json : JSON = JSON([:])

    static func instance(json : JSON?) -> Notification? {
        if (json == nil) {
            return nil
        } else {
            let n = Notification()
            n.json = json!
            return n
        }
    }
    
    var id : String {
        if let j = json["_id"].string {
            return j
        }
        return ""
    }
    
    // 1000 : Transaksi
    // 2000 : Inbox
    // 3000 : Komentar
    // -9999 : Undefined
    var type : Int {
        if let j = json["type"].int {
            return j
        }
        return -9999
    }
    
    var shortPreview : String {
        if let j = json["short_preview"].string {
            return j
        }
        return "---"
    }
    
    var statusText : String {
        if let j = json["status_text"].string {
            return j
        }
        return "---"
    }
    
    var caption : String {
        if let j = json["caption"].string {
            return j
        }
        return "---"
    }
    
    var objectName : String {
        if let j = json["object_name"].string {
            return j
        }
        return "---"
    }
    
    var objectId : String {
        if let j = json["object_id"].string {
            return j
        }
        return ""
    }
    
    var time : String {
        if let j = json["time"].string {
            return j
        }
        return "---"
    }
    
    var productImages : [String] {
        if let j = json["product_images"].arrayObject as? [String] {
            return j
        }
        return []
    }
    
    var read : Bool {
        if let j = json["read"].bool {
            return j
        }
        return true
    }
    
    var ownerId : String {
        if let j = json["owner_id"].string {
            return j
        }
        return ""
    }
    
    var userIdFrom : String {
        if let j = json["user_id_from"].string {
            return j
        }
        return ""
    }
    
    var userUsernameFrom : String {
        if let j = json["user_username_from"].string {
            return j
        }
        return ""
    }
    
    var userIdOwner : String {
        if let j = json["user_id_owner"].string {
            return j
        }
        return ""
    }
    
    var progress : Int {
        if let j = json["progress"].int {
            return j
        }
        return -9999
    }
    
    var inboxType : Int {
        if let j = json["inbox_type"].int {
            return j
        }
        return -9999
    }
    
    var messageType : Int {
        if let j = json["message_type"].int {
            return j
        }
        return -9999
    }
    
    var activityType : Int {
        if let j = json["activity_type"].int {
            return j
        }
        return -9999
    }
    
    func setRead() {
        json["read"] = JSON(true)
    }
}

class BalanceMutationItem : NSObject {
    
    var json : JSON = JSON([:])
    
    static func instance(json : JSON?, totalAmount : Int) -> BalanceMutationItem? {
        if (json == nil) {
            return nil
        } else {
            let n = BalanceMutationItem()
            n.json = json!
            n.totalAmount = totalAmount
            return n
        }
    }
    
    var totalAmount : Int = 0
    
    var id : String {
        if let j = json["_id"].string {
            return j
        }
        return ""
    }
    
    var reasonId : String {
        if let j = json["reason_id"].string {
            return j
        }
        return ""
    }
    
    var reason : String {
        if let j = json["reason"].string {
            return j
        }
        return ""
    }
    
    var time : String {
        if let j = json["time"].string {
            return j
        }
        return ""
    }
    
    var amount : Int {
        if let j = json["amount"].int {
            return j
        }
        return 0
    }
    
    var entryType : Int {
        if let j = json["entry_type"].int {
            return j
        }
        return 0
    }
    
    var reasonDetail : String {
        if let j = json["reason_detail"].string {
            return j
        }
        return ""
    }
    
    var reasonAdmin : String {
        if let j = json["reason_admin"].string {
            return j
        }
        return ""
    }
    
    var type : String {
        if let j = json["type"].string {
            return j
        }
        return ""
    }
    
    var isSeller : Bool? {
        if let j = json["is_seller"].bool {
            return j
        }
        return nil
    }
}
