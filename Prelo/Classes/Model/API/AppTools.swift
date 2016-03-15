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
    static var PreloBaseUrl = "http://dev.prelo.id" // Development
    
//    static var PreloBaseUrl = "https://prelo.co.id" // Production
    
    static var IsPreloProduction : Bool {
        return (AppTools.PreloBaseUrl == "https://prelo.co.id")
    }
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
    
    static var ThemeRed = UIColor(red: 197/255, green: 13/255, blue: 13/255, alpha: 1)
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
    static let XibNameTermCondition = "TermCondition"
    static let XibNameReferralPage = "ReferralPage"
    static let XibNameCategoryPreferences = "CategoryPreferences"
    static let XibNameShopReview = "ShopReview"
    static let XibNameSetupPasswordPopUp = "SetupPasswordPopUp"
    static let XibNameNotifAnggiTabBar = "NotifAnggiTabBar"
    static let XibNameNotifAnggiTransaction = "NotifAnggiTransaction"
    static let XibNameNotifAnggiConversation = "NotifAnggiConversation"
}

class OrderStatus : NSObject
{
    static let Dipesan = "Dipesan"
    static let BelumDibayar = "Belum Dibayar"
    static let Dibayar = "Dibayar"
    static let Dikirim = "Dikirim"
    static let PembayaranPending = "Pembayaran Pending"
    static let Direview = "Direview"
    static let TidakDikirimSeller = "Tidak Dikirim Seller"
    static let Diterima = "Diterima"
    static let DibatalkanSeller = "Dibatalkan Seller"
    static let Selesai = "Selesai"
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
    static let AppDataSaved = "appdatasaved"
    static let CategorySaved = "categorysaved"
    static let CategoryPref1 = "categorypref1"
    static let CategoryPref2 = "categorypref2"
    static let CategoryPref3 = "categorypref3"
    static let Tour = "tour"
    static let TourDone = "tourdone"
    static let RedirectFromHome = "redirectfromhome"
    static let UserAgent = "useragent"
    static let CoachmarkProductDetailDone = "coachmarkproductdetaildone"
    static let CoachmarkBrowseDone = "coachmarkbrowsedone"
}

class PageName
{
    static let SplashScreen = "Splash Screen"
    static let FirstTimeTutorial = "First Time Tutorial"
    static let SetCategoryPreferences = "Set Category Preferences"
    static let About = "About"
    static let AddProduct = "Add Product"
    static let ShareAddedProduct = "Share Added Product"
    static let Checkout = "Checkout"
    static let CheckoutConfirmation = "Checkout Confirmation"
    static let UnpaidTransaction = "Unpaid Transaction"
    static let PaymentConfirmation = "Payment Confirmation"
    static let EditProfile = "Edit Profile"
    static let ChangePhone = "Change Phone"
    static let EditProduct = "Edit Product"
    static let Home = "Home"
    static let Referral = "Referral"
    static let DashboardLoggedIn = "Dashboard Logged In"
    static let DashboardLoggedOut = "Dashboard Logged Out"
    static let Contact = "Contact"
    static let Login = "Login"
    static let Lovelist = "Lovelist"
    static let Notification = "Notification"
    static let Inbox = "Inbox"
    static let InboxDetail = "Inbox Detail"
    static let ProductDetail = "Product Detail"
    static let ProductDetailMine = "Product Detail Mine"
    static let ProductDetailShare = "Product Detail Share"
    static let ProductDetailComment = "Product Detail Comment"
    static let Register = "Register"
    static let Search = "Search"
    static let SetupAccount = "Setup Account"
    static let VerifyPhone = "Verify Phone"
    static let ShopMine = "Shop Mine"
    static let Shop = "Shop"
    static let ShopReviews = "Shop Reviews"
    static let Withdraw = "Withdraw"
    static let MyProducts = "My Products"
    static let MyOrders = "My Orders"
    static let TransactionDetail = "Transaction Detail"
    static let TermsAndConditions = "Terms and Conditions"
    static let CheckoutTutorial = "Checkout Tutorial"
}



class MixpanelEvent
{
    static let Register = "Register"
    static let SetupAccount = "Setup Account"
    static let PhoneVerified = "Phone Verified"
    static let Login = "Login"
    static let Logout = "Logout"
    static let CategoryBrowsed = "Category Browsed"
    static let Search = "Search"
    static let ToggledLikeProduct = "Toggled Like Product"
    static let SharedProduct = "Shared Product"
    static let CommentedProduct = "Commented Product"
    static let ChatSent = "Chat Sent"
    static let Bargain = "Bargain"
    static let PaymentClaimed = "Payment Claimed"
    static let ReferralUsed = "Referral Used"
    static let SharedReferral = "Shared Referral"
    static let RequestedWithdrawMoney = "Requested Withdraw Money"
    static let Checkout = "Checkout"
    static let AddedProduct = "Added Product"
}

extension GAI
{
    static func trackPageVisit(pageName : String)
    {
        // Send if Prelo production only (not development)
        if (AppTools.IsPreloProduction) {
            var tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: pageName)
            var builder = GAIDictionaryBuilder.createScreenView()
            tracker.send(builder.build() as [NSObject : AnyObject])
        }
    }
}

extension Mixpanel
{
    static func trackEvent(eventName : String)
    {
        Mixpanel.sharedInstance().track(eventName)
    }
    
    static func trackEvent(eventName : String, properties : [NSObject : AnyObject])
    {
        Mixpanel.sharedInstance().track(eventName, properties: properties)
    }
    
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
    
    // TODO: standardisasi, gunakan fungsi ini untuk semua pengesetan object nsuserdefaults
    static func setObjectAndSync(value : AnyObject?, forKey key : String) {
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}