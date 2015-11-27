//
//  AppTools.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/31/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

extension UIApplication
{
    static var appDelegate : AppDelegate
    {
        return UIApplication.sharedApplication().delegate as! AppDelegate
//        AFHTTPRequestOperationManager mana
    }
}

extension UIAlertView
{
    static func SimpleShow(title : String, message : String)
    {
        let a = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "OK")
        a.show()
    }
}

extension Int
{
    var string:String
        {
        return String(self)
    }
    
    var asPrice : String
    {
        let f = NSNumberFormatter()
        f.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        f.locale = NSLocale(localeIdentifier: "id_ID")
        return f.stringFromNumber(NSNumber(integer: self))!
    }
}

class AppTools: NSObject {
    // Development
//    static var PreloBaseUrl = "http://dev.prelo.id"
//    static var PreloBaseUrlShort = "dev.prelo.id"
    
    // Production
    static var PreloBaseUrl = "https://prelo.co.id"
    static var PreloBaseUrlShort = "prelo.co.id"
}

class Theme : NSObject
{
    static var PrimaryColor = UIColor(hex: "#00A79D")
    static var PrimaryColorDark = UIColor(hex: "#00747C")
    static var PrimaryColorLight = UIColor(hex: "#8CD7AE")
    
    static var ThemePurple = UIColor(hex: "#62115F")
    static var ThemePurpleDark = UIColor(hex: "#00A79D")
    
    static var ThemeOrage = UIColor(hex: "#F88218")
    static var ThemeOrange = UIColor(hex: "#FFA800")
    
    static var ThemePink = UIColor(hex: "#F1E3F2")
    static var ThemePinkDark = UIColor(hex: "#CB8FCC")
    
    static var navBarColor = UIColor(hex: "#00A79D")
    
    static var TabSelectedColor = UIColor(hex: "#858585")
    static var TabNormalColor = UIColor(hex: "#b7b7b7")
    
    static var GrayDark = UIColor(hex: "#858585")
    static var GrayLight = UIColor(hex: "#b7b7b7")
}

class Tags : NSObject
{
    static let StoryBoardIdBrowse = "productBrowse"
    static let StoryBoardIdDashboard = "dashboard"
    static let StoryBoardIdLogin = "login"
    static let StoryBoardIdProductDetail = "product_detail"
    static let StoryBoardIdPicker = "picker"
    static let StoryBoardIdImagePicker = "ImagePicker"
    static let StoryBoardIdImagePicker2 = "ImagePicker2"
    static let StoryBoardIdCart = "cart"
    static let StoryBoardIdSearch = "search"
    static let StoryBoardIdCartConfirm = "cartConfirm"
    static let StoryBoardIdAddProductImage = "addProductImage"
    static let StoryBoardIdAddProduct = "addProduct"
    static let StoryBoardIdAddProduct2 = "addProduct2"
    static let StoryBoardIdAddProductFullscreen = "AddProductFullscreen"
    static let StoryBoardIdNavigation = "nav"
    static let StoryBoardIdOrderConfirm = "orderConfirm"
    static let StoryBoardIdMyProducts = "MyProducts"
    static let StoryBoardIdMyProductSell = "MyProductSell"
    static let StoryBoardIdCategoryPicker = "CategoryPickerx"
    static let StoryBoardIdCategoryChildrenPicker = "CategoryChildrenPicker"
    static let StoryBoardIdAbout = "About"
    static let StoryBoardIdPreloShare = "PreloShare"
    static let StoryBoardIdPreloTour = "PreloTour"
    static let StoryBoardIdTarikTunai = "TarikTunai"
    static let StoryBoardIdTawar = "Tawar"
    static let StoryBoardIdInbox = "Inbox"
    static let StoryBoardIdProductComments = "ProductComments"
    
    static let Browse = "browse"
    static let Dashboard = "dashboard"
    
    static let XibNameDashboard2 = "Dashboard2"
    static let XibNameRegister = "Register"
    static let XibNamePaymentConfirmation = "PaymentConfirmation"
    static let XibNameUserProfile = "UserProfile"
    static let XibNameProfileSetup = "ProfileSetup"
    static let XibNamePhoneVerification = "PhoneVerification"
    static let XibNamePhoneReverification = "PhoneReverification"
    static let XibNameMyPurchase = "MyPurchase"
    static let XibNameMyPurchaseProcessing = "MyPurchaseProcessing"
    static let XibNameMyPurchaseCompleted = "MyPurchaseCompleted"
    static let XibNameMyPurchaseDetail = "MyPurchaseDetail"
    static let XibNameMyProductProcessing = "MyProductProcessing"
    static let XibNameMyProductCompleted = "MyProductCompleted"
    static let XibNameMyProductDetail = "MyProductDetail"
    static let XibNameMyLovelist = "MyLovelist"
    static let XibNamePathLogin = "PathLogin"
    static let XibNameNotificationPage = "NotificationPage"
    static let XibNameTermCondition = "TermCondition"
    static let XibNameReferralPage = "ReferralPage"
    static let XibNameCategoryPreferences = "CategoryPreferences"
    static let XibNameShopReview = "ShopReview"
}

class OrderStatus : NSObject
{
    static let Dipesan = "Dipesan"
    static let Dibayar = "Dibayar"
    static let Dikirim = "Dikirim"
    static let PembayaranPending = "Pembayaran Pending"
    static let Direview = "Direview"
    static let TidakDikirimSeller = "Tidak Dikirim Seller"
    static let Diterima = "Diterima"
    static let DibatalkanSeller = "Dibatalkan Seller"
}

class NotificationType : NSObject
{
    static let Transaksi = "Transaksi"
    static let Inbox = "Inbox"
    static let Aktivitas = "Aktivitas"
}

class NotificationName : NSObject
{
    static let PushNew = "pushnew"
}

class UserDefaultsKey : NSObject
{
    static let CategorySaved = "categorysaved"
    static let CategoryPref1 = "categorypref1"
    static let CategoryPref2 = "categorypref2"
    static let CategoryPref3 = "categorypref3"
    static let Tour = "tour"
    static let TourDone = "tourdone"
}

extension Mixpanel
{
    static func trackPageVisit(pageName : String)
    {
        let p = [
            "Page": pageName
        ]
        Mixpanel.sharedInstance().track("Page Visited", properties: p)
    }
    
    static func trackPageVisit(pageName : String, otherParam : [String : String])
    {
        var p = otherParam
        p["Page"] = pageName
        Mixpanel.sharedInstance().track("Page Visited", properties: p)
    }
    
    static let EventCategoryBrowsed = "Category Browsed"
    static let EventSearch = "Search"
    static let EventToggledLikeProduct = "Toggled Like Product"
    static let EventSharedProduct = "Shared Product"
    static let EventCommentedProduct = "Commented Product"
    static let EventChatSent = "Chat Sent"
    static let EventBargain = "Bargain"
    static let EventPaymentClaimed = "Payment Claimed"
    static let EventReferralUsed = "Referral Used"
}

extension NSUserDefaults
{
    static func lastSavedAssetURL() -> NSURL?
    {
        return NSUserDefaults.standardUserDefaults().objectForKey("lastAssetURL") as? NSURL
    }
    
    static func isCategorySaved() -> Bool
    {
        let saved : Bool? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.CategorySaved) as! Bool?
        if (saved == true) {
            return true
        }
        return false
    }
    
    static func categoryPref1() -> String
    {
        let c : String? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.CategoryPref1) as! String?
        if (c != nil) {
            return c!
        }
        return ""
    }
    
    static func categoryPref2() -> String
    {
        let c : String? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.CategoryPref2) as! String?
        if (c != nil) {
            return c!
        }
        return ""
    }
    
    static func categoryPref3() -> String
    {
        let c : String? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.CategoryPref3) as! String?
        if (c != nil) {
            return c!
        }
        return ""
    }
    
    static func isTourDone() -> Bool
    {
        let done : Bool? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.TourDone) as! Bool?
        if (done == true) {
            return true
        }
        return false
    }
    
    static func setTourDone(done : Bool)
    {
        NSUserDefaults.standardUserDefaults().setObject(done, forKey: UserDefaultsKey.TourDone)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}