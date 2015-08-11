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
    static let StoryBoardIdCart = "cart"
    static let StoryBoardIdSearch = "search"
    static let StoryBoardIdCartConfirm = "cartConfirm"
    
    static let Browse = "browse"
    static let Dashboard = "dashboard"
    
    static let LoginButton = "login"
    static let ContactPreloButton = "contact_prelo"
}

class NotificationName : NSObject
{
    static let PushNew = "pushnew"
}