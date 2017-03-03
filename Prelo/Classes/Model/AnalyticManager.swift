//
//  AnalyticManager.swift
//  Prelo
//
//  Created by Djuned on 2/20/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

class AnalyticManager: NSObject {
    static let sharedInstance = AnalyticManager()
    
    let token = "ZldVDK0Xca1v_osoTSiCdCngZ_r7iR1ZW6fpC3BscfCuHOYUYjLrlw"
    
    let devAnalyticURL = "http://analytics.dev.prelo.id"
    let prodAnalyticURL = "https://analytics.prelo.co.id"
    
    var isShowDialog = false
    
    var PreloAnalyticBaseUrl : String {
        return (AppTools.isDev ? devAnalyticURL : prodAnalyticURL)
    }
    
    // skeleton generator + append data
    fileprivate func skeletonData(data : [String : Any], previousScreen : String, loginMethod : String) -> [String : Any] {
        var appVersion = ""
        if let installedVer = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            appVersion = installedVer // installed
        } else {
            appVersion = CDVersion.getOne()!.appVersion // new
        }
        
        // skeleton data
        var wrappedData = [
            "OS" : UIDevice.current.systemName + " (" + UIDevice.current.systemVersion + ")",
            "App Version" : appVersion,
            "Device Model" : (AppTools.isSimulator ? UIDevice.current.model + " Simulator" : platform()),
            "Previous Screen" : previousScreen,
            "Login Method" : loginMethod
        ] as [String : Any]
        
        wrappedData.update(other: data)
        
        return wrappedData
    }
    
    // send record to Analytic Server
    func send(eventType : String, data : [String : Any], previousScreen : String, loginMethod : String) {
        
        // not allow
        if !isWhiteList(eventType) {
            print("Analytics - " + eventType + ", Disabled")
            if self.isShowDialog {
                Constant.showDialog("Analytics - " + eventType, message: "BlackList")
            }
            return
        }
        
        let wrappedData = skeletonData(data: data, previousScreen: previousScreen, loginMethod: loginMethod)
        
        let _ = request(APIAnalytic.event(eventType: eventType, data: wrappedData)).responseJSON {resp in
            if (PreloAnalyticEndpoints.validate(self.isShowDialog, dataResp: resp, reqAlias: "Analytics - " + eventType)) {
                print("Analytics - " + eventType + ", Sent!")
                if self.isShowDialog {
                    Constant.showDialog("Analytics - " + eventType, message: "Success")
                }
            }
        }
    }
    
    // send record to Analytic Server with defined userid
    func sendWithUserId(eventType : String, data : [String : Any], previousScreen : String, loginMethod : String, userId: String) {
        
        // not allow
        if !isWhiteList(eventType) {
            print("Analytics - " + eventType + ", Disabled")
            if self.isShowDialog {
                Constant.showDialog("Analytics - " + eventType, message: "BlackList")
            }
            return
        }
        
        let wrappedData = skeletonData(data: data, previousScreen: previousScreen, loginMethod: loginMethod)
        
        let _ = request(APIAnalytic.eventWithUserId(eventType: eventType, data: wrappedData, userId: userId)).responseJSON {resp in
            if (PreloAnalyticEndpoints.validate(self.isShowDialog, dataResp: resp, reqAlias: "Analytics - " + eventType)) {
                print("Analytics - " + eventType + ", Sent!")
                if self.isShowDialog {
                    Constant.showDialog("Analytics - " + eventType, message: "Success")
                }
            }
        }
    }
    
    // user must login
    func updateUser(isNeedPayload: Bool) {
        if (User.IsLoggedIn) {
            let _ = request(APIAnalytic.user(isNeedPayload: isNeedPayload)).responseJSON {resp in
                if (PreloAnalyticEndpoints.validate(self.isShowDialog, dataResp: resp, reqAlias: "Analytics - User")) {
                    print("Analytics - User, Sent!")
                    if self.isShowDialog {
                        Constant.showDialog("Analytics - User", message: "Success")
                    }
                }
            }
        }
    }
    
    // only from register
    func registerUser(method: String, metadata: JSON) {
        let _ = request(APIAnalytic.userRegister(registerMethod: method, metadata: metadata)).responseJSON {resp in
            if (PreloAnalyticEndpoints.validate(self.isShowDialog, dataResp: resp, reqAlias: "Analytics - User")) {
                print("Analytics - User, Sent!")
                if self.isShowDialog {
                    Constant.showDialog("Analytics - User", message: "Success")
                }
            }
        }
    }
    
    // only from setup profil
    func initUser(userProfileData: UserProfile) {
        let _ = request(APIAnalytic.userInit(userProfileData: userProfileData)).responseJSON {resp in
            if (PreloAnalyticEndpoints.validate(self.isShowDialog, dataResp: resp, reqAlias: "Analytics - User")) {
                print("Analytics - User, Sent!")
                if self.isShowDialog {
                    Constant.showDialog("Analytics - User", message: "Success")
                }
            }
        }
    }
    
    // only from setup, edit phone - verified
    func updateUserPhone(phone: String) {
        let _ = request(APIAnalytic.userUpdate(phone: phone)).responseJSON {resp in
            if (PreloAnalyticEndpoints.validate(self.isShowDialog, dataResp: resp, reqAlias: "Analytics - User")) {
                print("Analytics - User, Sent!")
                if self.isShowDialog {
                    Constant.showDialog("Analytics - User", message: "Success")
                }
            }
        }
    }
    
    /*
    // helper
    func dictToJSON(dict:[String: AnyObject]) -> AnyObject {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        let decoded = try! JSONSerialization.jsonObject(with: jsonData, options: [])
        return decoded as AnyObject
    }
    
    func arrayToJSON(array:[String]) -> AnyObject {
        let jsonData = try! JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
        let decoded = try! JSONSerialization.jsonObject(with: jsonData, options: [])
        return decoded as AnyObject
    }
     */
    
    func platform() -> String {
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    // MARK: - WhiteList
    // TODO: - Enable all analytics
    fileprivate func isWhiteList(_ preloAnalyticEvent: String) -> Bool {
        let _whiteList = [
            // Add Product
            PreloAnalyticEvent.SaveAsDraft,
            PreloAnalyticEvent.SubmitProduct,
            PreloAnalyticEvent.ShareProduct,
            PreloAnalyticEvent.UploadSuccess,
            
            // Auth
            PreloAnalyticEvent.Register,
            PreloAnalyticEvent.SetupAccount,
            PreloAnalyticEvent.SetupPhone,
            PreloAnalyticEvent.Login,
            PreloAnalyticEvent.Logout,
            
            // Chat
            PreloAnalyticEvent.StartChat,
            
            // Feedback
            PreloAnalyticEvent.Rate,
            
            // Love
            PreloAnalyticEvent.LoveProduct,
            PreloAnalyticEvent.UnloveProduct,
            
            // Notification
            PreloAnalyticEvent.ClickPushNotification,
            PreloAnalyticEvent.ClickNotificationInApp,
            
            // Product
            PreloAnalyticEvent.UpProduct,
            PreloAnalyticEvent.VisitProductDetail,
            
            // Purchase
            PreloAnalyticEvent.GoToCart,
            PreloAnalyticEvent.Checkout,
            PreloAnalyticEvent.ClaimPayment,
            
            // Referral
            PreloAnalyticEvent.RedeemReferralCode,
            
            // Report
            PreloAnalyticEvent.ReportProduct,
            
            // Transaction
            PreloAnalyticEvent.ConfirmShipping,
            PreloAnalyticEvent.RejectShipping,
            PreloAnalyticEvent.ReviewAndRateSeller,
            
            // Withdraw
            PreloAnalyticEvent.RequestWithdrawMoney,
        ]
        
        if _whiteList.contains(preloAnalyticEvent) {
            return true
        } else {
            return false
        }
    }
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}
