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
    
    static let Browse = "browse"
    static let Dashboard = "dashboard"
    
    static let XibNameDashboard2 = "Dashboard2"
    static let XibNameRegister = "Register"
    static let XibNamePaymentConfirmation = "PaymentConfirmation"
    static let XibNameUserProfile = "UserProfile"
    static let XibNameProfileSetup = "ProfileSetup"
}

class NotificationName : NSObject
{
    static let PushNew = "pushnew"
}

extension NSUserDefaults
{
    static func lastSavedAssetURL() -> NSURL?
    {
        return NSUserDefaults.standardUserDefaults().objectForKey("lastAssetURL") as? NSURL
    }
}