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

class AppTools: NSObject {
   
}

class Theme : NSObject
{
    static var navBarColor : UIColor {
        return UIColor(hex: "#62115F")
    }
    
    static var DarkPurple : UIColor {
        return UIColor(hex: "#3f1044")
    }
    
    static var TabSelectedColor : UIColor {
        return UIColor(hex: "#858585")
    }
    
    static var TabNormalColor : UIColor {
        return UIColor(hex: "#b7b7b7")
    }
}

class Tags : NSObject
{
    static let StoryBoardIdBrowse = "productBrowse"
    static let StoryBoardIdDashboard = "dashboard"
    static let StoryBoardIdLogin = "login"
    static let StoryBoardIdProductDetail = "product_detail"
    static let StoryBoardIdPicker = "picker"
    static let StoryBoardIdImagePicker = "ImagePicker"
    static let StoryBoardIdCart = "cart"
    static let StoryBoardIdSearch = "search"
    static let StoryBoardIdCartConfirm = "cartConfirm"
    static let StoryBoardIdAddProductImage = "addProductImage"
    static let StoryBoardIdAddProduct = "addProduct"
    static let StoryBoardIdNavigation = "nav"
    static let StoryBoardIdOrderConfirm = "orderConfirm"
    
    static let Browse = "browse"
    static let Dashboard = "dashboard"
    
    static let XibNameDashboard2 = "Dashboard2"
    static let XibNameRegister = "Register"
    static let XibNamePaymentConfirmation = "PaymentConfirmation"
}

class NotificationName : NSObject
{
    static let PushNew = "pushnew"
}