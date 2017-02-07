//
//  AppTools.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/31/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CoreData
import AlamofireImage

class AppTools: NSObject {
    static let isDev = true // Set true for demo/testing purpose only
    
    fileprivate static var devURL = "http://dev.prelo.id"
    fileprivate static var prodURL = "https://prelo.co.id"
    
    fileprivate static var _PreloBaseUrl = isDev ? devURL : prodURL
    static var PreloBaseUrl : String {
        set {
            _PreloBaseUrl = newValue
        }
        get {
            return _PreloBaseUrl
        }
    }
    
    static var IsPreloProduction : Bool {
        return (PreloBaseUrl == "https://prelo.co.id")
    }
    
    static var isIPad : Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isSimulator : Bool {
        return UIDevice.current.isIOSSimulator
    }
    
    static var screenWidth : CGFloat {
        return UIScreen.main.bounds.width
    }
    
    static var screenHeight : CGFloat {
        return UIScreen.main.bounds.height
    }
    
    static var isNewShop : Bool { // new shop, TODO: - bisa setting di app
        return true
    }
    
    static let isOldShopWithBadges : Bool = false // set true kalau jadi bisa nampilin badge
    
    static var loadImageCounter: Int = 0
}

enum AppFont {
    case prelo2
    case preloAwesome
    
    func getFont(_ size : CGFloat) -> UIFont? {
        var name = "Prelo2"
        switch self {
        case .prelo2:name = "Prelo2"
        case .preloAwesome:name = "PreloAwesome"
        }
        
        let f = UIFont(name: name, size: size)
        return f
    }
    
    var getFont : UIFont? {
        var name = "Prelo2"
        switch self {
        case .prelo2:name = "Prelo2"
        case .preloAwesome:name = "PreloAwesome"
        }
        
        let f = UIFont(name: name, size: 18)
        return f
    }
}

extension UIApplication {
    static var appDelegate : AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
}

extension UINavigationController {
    class func defaultNavigation(_ root : UIViewController) -> UINavigationController {
        let n = UINavigationController(rootViewController: root)
        n.navigationBar.barTintColor = Theme.navBarColor
        n.navigationBar.tintColor = UIColor.white
        return n
    }
}

extension UIView {
    func toBarButton() -> UIBarButtonItem {
        return UIBarButtonItem(customView: self)
    }
    
    class func fromNib<T : UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
    var snapshot: UIImage {
//        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
//        drawHierarchy(in: bounds, afterScreenUpdates: true)
//        let result = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return result!
        
        UIGraphicsBeginImageContext(self.bounds.size);
        let context = UIGraphicsGetCurrentContext();
        self.layer.render(in: context!)
        let screenShot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return screenShot!
    }
}

extension UIAlertView {
    static func SimpleShow(_ title : String, message : String) {
        let a = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "Oke")
        a.show()
    }
}

extension Int {
    var string : String {
        return String(self)
    }
    
    var asPrice : String {
        let f = NumberFormatter()
        f.numberStyle = NumberFormatter.Style.currency
        f.locale = Locale(identifier: "id_ID")
        return f.string(from: NSNumber(value: self as Int))!
    }
}

extension String {
    func index(of string: String, options: String.CompareOptions = .literal) -> String.Index? {
        return range(of: string, options: options)?.lowerBound
    }
    func indexes(of string: String, options: String.CompareOptions = .literal) -> [String.Index] {
        var result: [String.Index] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range.lowerBound)
            start = range.upperBound
        }
        return result
    }
    func ranges(of string: String, options: String.CompareOptions = .literal) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.upperBound
        }
        return result
    }
    func indexDistance(of character: Character) -> Int? {
        guard let index = characters.index(of: character) else { return nil }
        return distance(from: startIndex, to: index)
    }
}

extension UILabel {
    func boldRange(_ range: Range<String.Index>) {
        if let text = self.attributedText {
            let attr = NSMutableAttributedString(attributedString: text)
            let start = text.string.characters.distance(from: text.string.startIndex, to: range.lowerBound)
            let length = text.string.characters.distance(from: range.lowerBound, to: range.upperBound)
            attr.addAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: self.font.pointSize)], range: NSMakeRange(start, length))
            self.attributedText = attr
        }
    }
    
    func boldSubstring(_ substr: String) {
        let range = self.text?.range(of: substr)
        if let r = range {
            boldRange(r)
        }
    }
    
    func setSubstringColor(_ substr: String, color: UIColor) {
        if let range = self.text?.range(of: substr) {
            if let text = self.attributedText {
                let attr = NSMutableAttributedString(attributedString: text)
                let start = text.string.characters.distance(from: text.string.startIndex, to: range.lowerBound)
                let length = text.string.characters.distance(from: range.lowerBound, to: range.upperBound)
                attr.addAttributes([NSForegroundColorAttributeName: color], range: NSMakeRange(start, length))
                self.attributedText = attr
            }
        }
    }
}

extension UITextView {
    func boldRange(_ range: Range<String.Index>) {
        if let text = self.attributedText {
            let attr = NSMutableAttributedString(attributedString: text)
            let start = text.string.characters.distance(from: text.string.startIndex, to: range.lowerBound)
            let length = text.string.characters.distance(from: range.lowerBound, to: range.upperBound)
            attr.addAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: (self.font?.pointSize)!)], range: NSMakeRange(start, length))
            self.attributedText = attr
        }
    }
    
    func boldSubstring(_ substr: String) {
        let range = self.text?.range(of: substr)
        if let r = range {
            boldRange(r)
        }
    }
    
    func setSubstringColor(_ substr: String, color: UIColor) {
        if let range = self.text?.range(of: substr) {
            if let text = self.attributedText {
                let attr = NSMutableAttributedString(attributedString: text)
                let start = text.string.characters.distance(from: text.string.startIndex, to: range.lowerBound)
                let length = text.string.characters.distance(from: range.lowerBound, to: range.upperBound)
                attr.addAttributes([NSForegroundColorAttributeName: color], range: NSMakeRange(start, length))
                self.attributedText = attr
            }
        }
    }
    
    func increaseSizeSubstring(_ substr: String, size: CGFloat) {
        if let range = self.text?.range(of: substr) {
            if let text = self.attributedText {
                let attr = NSMutableAttributedString(attributedString: text)
                let start = text.string.characters.distance(from: text.string.startIndex, to: range.lowerBound)
                let length = text.string.characters.distance(from: range.lowerBound, to: range.upperBound)
                attr.addAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: size)], range: NSMakeRange(start, length))
                self.attributedText = attr
            }
        }
    }
}

extension UIImage {
    func resizeWithPercentage(_ percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    
    func resizeWithWidth(_ width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    
    func resizeWithMaxWidth(_ width: CGFloat) -> UIImage? {
        if (self.size.width > width) {
            return self.resizeWithWidth(width)
        }
        return self
    }
    
    func correctlyOrientedImage() -> UIImage {
//        if self.imageOrientation == UIImageOrientation.up {
//            return self
//        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let normalizedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
        
        return normalizedImage;
    }
}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url)
            DispatchQueue.main.async {
                if (data != nil) {
                    self.image = UIImage(data: data!)
                }
            }
        }
        /* Another method
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
        }.resume()
        */
        
    }
    
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
    
    func sdSetImage(withURL: URL) {
//        self.sd_setImage(with: withURL)
        self.sd_setImage(with: withURL, placeholderImage: nil, options: SDWebImageOptions.scaleDownLargeImages)
    }
    
    // default fill
    func afSetImage(withURL: URL) {
        let filter = AspectScaledToFillSizeFilter(
            size: self.frame.size
        )
        
        self.af_setImage(
            withURL: withURL,
            filter: filter,
            imageTransition: .crossDissolve(0.3)
        )
    }
    
    func afSetImage(withURL: URL, withFilter: String) {
        if withFilter == "fit" {
            let filter = AspectScaledToFitSizeFilter(
                size: self.frame.size
            )
            
            self.af_setImage(
                withURL: withURL,
                filter: filter,
                imageTransition: .crossDissolve(0.3)
            )
        }
        
        else if withFilter == "circle" {
            let filter = AspectScaledToFillSizeCircleFilter(
                size: self.frame.size
            )
            
            self.af_setImage(
                withURL: withURL,
                filter: filter,
                imageTransition: .crossDissolve(0.3)
            )
        }
        
        else if withFilter == "none" {
            
            self.af_setImage(
                withURL: withURL,
                imageTransition: .crossDissolve(0.3)
            )
        }
        
        // default fill
        else {
            let filter = AspectScaledToFillSizeFilter(
                size: self.frame.size
            )
            
            self.af_setImage(
                withURL: withURL,
                filter: filter,
                imageTransition: .crossDissolve(0.3)
            )
        }
    }
}

extension UIDevice {
    var isIOSSimulator: Bool {
        #if IOS_SIMULATOR
            return true
        #else
            return false
        #endif
    }
}

class Theme : NSObject {
    static var PrimaryColor = UIColor(hexString: "#00A79D")
    static var PrimaryColorDark = UIColor(hexString: "#00747C")
    static var PrimaryColorLight = UIColor(hexString: "#8CD7AE")
    
    static var ThemePurple = UIColor(hexString: "#62115F")
    static var ThemePurpleDark = UIColor(hexString: "#00A79D")
    
    static var ThemeOrage = UIColor(hexString: "#F88218")
    static var ThemeOrange = UIColor(hexString: "#FFA800")
    static var ThemeOrangeDark = UIColor(hexString: "#996600")
    
    static var ThemePink = UIColor(hexString: "#F1E3F2")
    static var ThemePinkDark = UIColor(hexString: "#CB8FCC")
    
    static var navBarColor = UIColor(hexString: "#00A79D")
    
    static var TabSelectedColor = UIColor(hexString: "#858585")
    static var TabNormalColor = UIColor(hexString: "#b7b7b7")
    
    static var GrayDark = UIColor(hexString: "#858585")
    static var GrayLight = UIColor(hexString: "#b7b7b7")
    static var GrayGranite = UIColor(hexString: "#363636")
    
    static var ThemeRed = UIColor(red: 197/255, green: 13/255, blue: 13/255, alpha: 1)
}

class Tags : NSObject {
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
    static let StoryBoardIdListBrand = "ListBrand"
    
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
    static let XibNameMyPurchaseTransaction = "MyPurchaseTransaction"
    static let XibNameMyPurchaseProcessing = "MyPurchaseProcessing"
    static let XibNameMyPurchaseCompleted = "MyPurchaseCompleted"
    static let XibNameMyPurchaseDetail = "MyPurchaseDetail"
    static let XibNameMyProductProcessing = "MyProductProcessing"
    static let XibNameMyProductCompleted = "MyProductCompleted"
    static let XibNameMyProductTransaction = "MyProductTransaction"
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
    static let XibNameConfirmShipping = "ConfirmShipping"
    static let XibNameBalanceMutation = "BalanceMutation"
    static let XibNameFilter = "Filter"
    static let XibNameExpiringProducts = "ExpiringProducts"
    static let XibNameLoginFransiska = "LoginFransiska"
    static let XibNameProductCompare = "ProductCompare"
    static let XibNameProductLovelist = "ProductLovelist"
    static let XibNameRequestRefund = "RefundRequest"
    static let XibNameProductReport = "ReportProducts"
    static let XibNameLocationFilter = "LocationFilters"
    static let XibNameScanner = "Scanner"
    static let XibNameAchievement = "Achievement"
    static let XibNameStorePage = "StorePageTabBar"
    static let XibNameShopAchievement = "ShopAchievement"
    static let XibNameTarikTunai2 = "TarikTunai2"
}

class OrderStatus : NSObject {
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

class NotificationType : NSObject {
    static let Transaksi = "Transaksi"
    static let Inbox = "Inbox"
    static let Aktivitas = "Aktivitas"
}

class NotificationName : NSObject {
    static let ShowProduct = "showproduct"
}

class PageName {
    static let SplashScreen = "Splash Screen"
    static let FirstTimeTutorial = "First Time Tutorial"
    static let SetCategoryPreferences = "Set Category Preferences"
    static let About = "About"
    static let AddProduct = "Jual"
    static let ShareAddedProduct = "Share Added Product"
    static let Checkout = "Checkout"
    static let CheckoutConfirmation = "Checkout Confirmation"
    static let UnpaidTransaction = "Unpaid Transaction"
    static let PaymentConfirmation = "Payment Confirmation"
    static let EditProfile = "Edit Profile"
    static let ChangePhone = "Change Phone"
    static let EditProduct = "Edit"
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
    static let Mutation = "Mutasi"
    static let BarangExpired = "Barang Expired"
    static let Achievement = "Achievements"
    static let ShopAchievements = "Shop Achievements"
}

extension Mixpanel {
    static func trackEvent(_ eventName : String)
    {
        // Disable Category Browsed and Search Event
        if (eventName == MixpanelEvent.CategoryBrowsed || eventName == MixpanelEvent.Search) {
            return
        }
        
        Mixpanel.sharedInstance().track(eventName)
    }
    
    static func trackEvent(_ eventName : String, properties : [AnyHashable: Any])
    {
        // Disable Category Browsed and Search Event
        if (eventName == MixpanelEvent.CategoryBrowsed || eventName == MixpanelEvent.Search) {
            return
        }
        
        Mixpanel.sharedInstance().track(eventName, properties: properties)
    }
    
    static func trackPageVisit(_ pageName : String)
    {
        /* Disable Page Visit
         let p = [
         "Page": pageName
         ]
         Mixpanel.sharedInstance().track("Page Visited", properties: p)
         */
    }
    
    static func trackPageVisit(_ pageName : String, otherParam : [String : String])
    {
        /* Disable Page Visit
        var p = otherParam
        p["Page"] = pageName
        Mixpanel.sharedInstance().track("Page Visited", properties: p)
        */
    }
}

class MixpanelEvent {
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
    static let ChatMarkAsSold = "Chat Mark as Sold"
}

extension GAI {
    static func trackPageVisit(_ pageName : String) {
        // Send if Prelo production only (not development)
        if (AppTools.IsPreloProduction) {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker?.set(kGAIScreenName, value: pageName)
            let builder = GAIDictionaryBuilder.createScreenView()
            tracker?.send(builder?.build() as NSDictionary? as? [AnyHashable: Any])
        }
    }
}

class UserDefaultsKey : NSObject {
    static let CategorySaved = "categorysaved"
    static let CategoryPref1 = "categorypref1"
    static let CategoryPref2 = "categorypref2"
    static let CategoryPref3 = "categorypref3"
    static let Tour = "tour"
    static let TourDone = "tourdone"
    static let RedirectFromHome = "redirectfromhome"
    static let UserAgent = "useragent"
    static let CoachmarkProductDetailDone = "coachmarkproductdetaildone"
    static let CoachmarkProductDetailMineDone = "coachmarkproductdetailminedone"
    static let CoachmarkBrowseDone = "coachmarkbrowsedone"
    static let CoachmarkReserveDone = "coachmarkreservedone"
    static let UninstallIOIdentified = "uninstallioidentified"
    static let LastPromoTitle = "lastpromotitle"
    static let PreloBaseUrlJustChanged = "prelobaseurljustchanged"
    static let UpdatePopUpVer = "updatepopupver"
    static let UpdatePopUpForced = "updatepopupforced"
    static let AbTestFakeApprove = "abtestfakeapprove"
}

extension UserDefaults {
    static func lastSavedAssetURL() -> URL? {
        return UserDefaults.standard.object(forKey: "lastAssetURL") as? URL
    }
    
    static func isCategorySaved() -> Bool {
        let saved : Bool? = UserDefaults.standard.object(forKey: UserDefaultsKey.CategorySaved) as! Bool?
        if (saved == true) {
            return true
        }
        return false
    }
    
    static func categoryPref1() -> String {
        let c : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.CategoryPref1) as! String?
        if (c != nil) {
            return c!
        }
        return ""
    }
    
    static func categoryPref2() -> String {
        let c : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.CategoryPref2) as! String?
        if (c != nil) {
            return c!
        }
        return ""
    }
    
    static func categoryPref3() -> String {
        let c : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.CategoryPref3) as! String?
        if (c != nil) {
            return c!
        }
        return ""
    }
    
    static func isTourDone() -> Bool {
        let done : Bool? = UserDefaults.standard.object(forKey: UserDefaultsKey.TourDone) as! Bool?
        if (done == true) {
            return true
        }
        return false
    }
    
    static func setTourDone(_ done : Bool) {
        UserDefaults.standard.set(done, forKey: UserDefaultsKey.TourDone)
        UserDefaults.standard.synchronize()
    }
    
    // TODO: standardisasi, gunakan fungsi ini untuk semua pengesetan object nsuserdefaults
    static func setObjectAndSync(_ value : AnyObject?, forKey key : String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }
}

extension NSManagedObjectContext {
    public func saveSave() -> Bool {
        var success = true
        do {
            try self.save()
        } catch {
            success = false
        }
        return success
    }
    
    public func tryExecuteFetchRequest(_ req : NSFetchRequest<NSFetchRequestResult>) -> [NSManagedObject]? {
        var results : [NSManagedObject]?
        do {
            try results = self.fetch(req) as? [NSManagedObject]
            print("Fetch request success")
        } catch {
            print("Fetch request failed")
            results = nil
        }
        return results
    }
}

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if (AppTools.isSimulator) {
        Swift.print(items[0], separator:separator, terminator: terminator)
    }
}

class ImageHelper {
    static func removeExifData(_ data: Data) -> Data? {
        /* FIXME: Swift 3
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        guard let type = CGImageSourceGetType(source) else {
            return nil
        }
        let count = CGImageSourceGetCount(source)
        let mutableData = NSData(data: data) as Data
        guard let destination = CGImageDestinationCreateWithData(mutableData as! CFMutableData, type, count, nil) else {
            return nil
        }
        // Check the keys for what you need to remove
        // As per documentation, if you need a key removed, assign it kCFNull
        let removeExifProperties: CFDictionary = [String(kCGImagePropertyExifDictionary) : kCFNull, String(kCGImagePropertyOrientation): kCFNull] as CFDictionary
        
        for i in 0..<count {
            CGImageDestinationAddImageFromSource(destination, source, i, removeExifProperties)
        }
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return mutableData
        */
        
        return NSData(data: data) as Data
    }
}
