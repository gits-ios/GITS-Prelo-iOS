//
//  Constant.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/28/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import AVFoundation

var dateFormatter : DateFormatter = DateFormatter()

class Constant: NSObject {
    static var escapesSymbols : [String : String] = ["&amp;":"&"]
    
    static var appearance : SCLAlertView.SCLAppearance {
        get {
            var _appearance = SCLAlertView.SCLAppearance()
            /*
                //kCircleIconHeight: 56.0, // --> UIImage(named: "raisa.jpg")
            */
            
            _appearance.showCloseButton = false
            _appearance.showCircularIcon = false
            _appearance.buttonCornerRadius = 0.0
            _appearance.contentViewCornerRadius = 0.0
            
            return _appearance
        }
    }
    
    static func showDialog(_ title : String, message : String)
    {
//        let a = UIAlertView()
//        a.title = title
//        a.message = message
//        a.addButton(withTitle: "Oke")
//        a.show()
        
        // TODO: - fix bug navigation after show
//        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        a.addAction(UIAlertAction(title: "Oke", style: .default, handler: { action in
//            a.dismiss(animated: true, completion: nil)
//        }))
//        UIApplication.shared.keyWindow?.rootViewController?.present(a, animated: true, completion: nil)
        
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("Oke") {}
        alertView.showCustom(title, subTitle: message, color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    // disable
    /*
    static func showBadgeDialog(_ title : String, message : String, badge : String, view : UIViewController, isBack : Bool)
    {
        var name = ""
        var color : UIColor!
        if badge == "warning" {
            name = ""
            color = UIColor.orange  //(hex: "Ffa800")
        } else if badge == "error" {
            name = ""
            color = UIColor.red
        } else if badge == "info" {
            name = ""
            color = UIColor.black
        }

        
        let content = name + " " + title
        
        let a = UIAlertController(title: content, message: message, preferredStyle: .alert)
        
        let attrStr = NSMutableAttributedString(string: content)
        
        attrStr.addAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16.0)], range: (content as NSString).range(of: title))
        
        attrStr.addAttributes([NSForegroundColorAttributeName:color], range: (content as NSString).range(of: name))
        attrStr.addAttributes([NSFontAttributeName:UIFont(name: "preloAwesome", size: 16.0)!], range: (content as NSString).range(of: name))
        
        a.setValue(attrStr, forKeyPath: "attributedTitle")
        
        let action = UIAlertAction(title: "Oke", style: .default, handler: {  act in
            a.dismiss(animated: true, completion: nil)
            if isBack {
                _ = view.navigationController?.popViewController(animated: true)
            }
        })
        
        a.addAction(action)
        
//        let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 40, height: 40))
//        
//        var name = ""
//        if badge == "warning" {
//            name = "exclamation31.png"
//        }
//        
//        let bkgImg = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
//        imageView.image = bkgImg
//        
//        if badge == "warning" {
//            imageView.tintColor = UIColor.red
//        }
//        
//        a.view.addSubview(imageView)
        
        view.present(a, animated: true, completion: nil)
    }
     */
    
    static func forceUpdatePrompt() {
        // Show app store update pop up if necessary
        /*
        if let newVer = UserDefaults.standard.object(forKey: UserDefaultsKey.UpdatePopUpVer) as? String , newVer != "" {
            /*
            let alert : UIAlertController = UIAlertController(title: "New Version Available", message: "Prelo \(newVer) is available on App Store", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { action in
                UIApplication.shared.openURL(URL(string: "itms-apps://itunes.apple.com/id/app/prelo/id1027248488")!)
            }))
            alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { action in
                if let isForceUpdate = UserDefaults.standard.object(forKey: UserDefaultsKey.UpdatePopUpForced) as? Bool , !isForceUpdate {
                    // do nothing
                } else if let releaseNotes = UserDefaults.standard.object(forKey: UserDefaultsKey.UpdatePopUpNotes) as? String , releaseNotes != "" {
                    
                    let notes = releaseNotes + "\n\nKamu tidak akan mendapatkan fitur dan perbaikan terbaru jika tidak meng-update aplikasi."
                    
                    let alert2 : UIAlertController = UIAlertController(title: "Prelo \(newVer)", message: notes, preferredStyle: UIAlertControllerStyle.alert)
                    alert2.addAction(UIAlertAction(title: "Update", style: .default, handler: { action in
                        UIApplication.shared.openURL(URL(string: "itms-apps://itunes.apple.com/id/app/prelo/id1027248488")!)
                    }))
                    alert2.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert2, animated: true, completion: nil)
                }
            }))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
             */
            
            let alertView = SCLAlertView(appearance: appearance)
            alertView.addButton("Update") {
                UIApplication.shared.openURL(URL(string: "itms-apps://itunes.apple.com/id/app/prelo/id1027248488")!)
            }
            alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {
                if let isForceUpdate = UserDefaults.standard.object(forKey: UserDefaultsKey.UpdatePopUpForced) as? Bool , !isForceUpdate {
                    // do nothing
                } else if let releaseNotes = UserDefaults.standard.object(forKey: UserDefaultsKey.UpdatePopUpNotes) as? String, releaseNotes != "" {
                    let alertView2 = SCLAlertView(appearance: appearance)
                    
                    // release notes
                    let subtitle = UILabel()
                    
                    subtitle.font = appearance.kTextFont
                    subtitle.textColor = alertView2.labelTitle.textColor
                    subtitle.numberOfLines = 0
                    
                    /*
                    var notes = releaseNotes
                    notes = notes.replacingOccurrences(of: "+", with: " ")
                    notes = notes.replacingOccurrences(of: "-", with: " ")
                    
                    let mystr = notes
                    let searchstr = " | "
                    let ranges: [NSRange]
                    
                    do {
                        // Create the regular expression.
                        let regex = try NSRegularExpression(pattern: searchstr, options: [])
                        
                        // Use the regular expression to get an array of NSTextCheckingResult.
                        // Use map to extract the range from each result.
                        ranges = regex.matches(in: mystr, options: [], range: NSMakeRange(0, mystr.characters.count)).map {$0.range}
                    }
                    catch {
                        // There was a problem creating the regular expression
                        ranges = []
                    }
                    
                    let attString : NSMutableAttributedString = NSMutableAttributedString(string: notes)
                    for i in ranges {
                        attString.addAttributes([NSFontAttributeName:UIFont(name: "preloAwesome", size: 14.0)!], range: i)
                    }
                    
                    subtitle.attributedText = attString
                    */
                    
                    // Create a NSCharacterSet of delimiters.
                    let separators = NSCharacterSet(charactersIn: "\n")
                    // Split based on characters.
                    var strings = releaseNotes.components(separatedBy: separators as CharacterSet)
                    
                    // testing
                    //strings = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "This is a small string", "This is more of medium string with a few more words etc.", "Well this is certainly a longer string, with many more words than either of the previuos two strings", ""]
                    
                    if (strings.count > 0 && strings.last == "") {
                        strings.removeLast()
                    }
                    
                    let attributesDictionary = [NSFontAttributeName : subtitle.font]
                    let fullAttributedString = NSMutableAttributedString(string: "", attributes: attributesDictionary)
                    
                    for string: String in strings
                    {
                        let bulletPoint: String = "\u{2022}"
                        let formattedString: String = "\(bulletPoint) \(string)\n"
                        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: formattedString)
                        
                        var paragraphStyle: NSMutableParagraphStyle
                        paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 12, options: NSDictionary() as! [String : AnyObject])]
                        paragraphStyle.defaultTabInterval = 12
                        paragraphStyle.firstLineHeadIndent = 0
                        paragraphStyle.headIndent = 12
                        
                        attributedString.addAttributes([NSParagraphStyleAttributeName: paragraphStyle], range: NSMakeRange(0, attributedString.length))
                        
                        fullAttributedString.append(attributedString)
                    }
                    
                    subtitle.attributedText = fullAttributedString
                    
                    let width = appearance.kWindowWidth - 32
                    let frame = subtitle.text!.boundsWithFontSize(appearance.kTextFont, width: width)
                    
                    subtitle.frame = CGRect(x: 4, y: 0, width: width, height: frame.height)
                    
                    // notes apps
                    let subtitle2 = UILabel()
                    
                    let notes2 = "Kamu tidak akan mendapatkan fitur dan perbaikan terbaru jika tidak meng-update aplikasi."
                    subtitle2.font = appearance.kTextFont
                    subtitle2.textColor = alertView2.labelTitle.textColor
                    subtitle2.numberOfLines = 0
                    subtitle2.textAlignment = .center
                    
                    let attString2 : NSMutableAttributedString = NSMutableAttributedString(string: notes2)
                    
                    attString2.addAttributes([NSFontAttributeName:UIFont.italicSystemFont(ofSize: 14)], range: (notes2 as NSString).range(of: "update"))
                    
                    subtitle2.attributedText = attString2
                    
                    let frame2 = subtitle2.text!.boundsWithFontSize(appearance.kTextFont, width: width)
                    
                    subtitle2.frame = CGRect(x: 4, y: frame.height, width: width, height: frame2.height)
                    
                    // Creat the subview
                    let maxheight = UIScreen.main.bounds.height - 300
                    
                    let subview = UIView(frame: CGRect(x: 0, y: 0, width: width + 8, height: frame.height + frame2.height))
                    subview.addSubview(subtitle)
                    subview.addSubview(subtitle2)
                    subview.backgroundColor = UIColor.white
                    
                    let scrollview = UIScrollView()
                    scrollview.contentSize = subview.bounds.size
                    
                    scrollview.addSubview(subview)
                    
                    let subviewsuper = UIView(frame: CGRect(x: 0, y: 0, width: width + 8, height: (frame.height + frame2.height > maxheight ? maxheight : frame.height + frame2.height)))
                    
                    scrollview.frame = subviewsuper.bounds
                    subviewsuper.addSubview(scrollview)
                    
                    if (frame.height + frame2.height > maxheight) {
                        let gradient: CAGradientLayer = CAGradientLayer()
                        
                        gradient.colors = [UIColor.colorWithColor(UIColor.white, alpha: 0).cgColor, UIColor.colorWithColor(UIColor.white, alpha: 1).cgColor]
                        gradient.locations = [0.0 , 1.0]
//                        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
//                        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
                        gradient.frame = CGRect(x: 0.0, y: maxheight - 24, width: width + 8, height: 24)
                        
                        subviewsuper.layer.insertSublayer(gradient, at: 1)
                        
                        // bottom
                        scrollview.contentInset = UIEdgeInsetsMake(0, 0, 20, 0)
                    }
                    
                    alertView2.customSubview = subviewsuper
                    
                    alertView2.addButton("Update") {
                        UIApplication.shared.openURL(URL(string: "itms-apps://itunes.apple.com/id/app/prelo/id1027248488")!)
                    }
                    alertView2.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
                    
                    alertView2.showCustom("Prelo \(newVer)", subTitle: "", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                }
            }
            alertView.showCustom("New Version Available", subTitle: "Prelo \(newVer) is available on App Store", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
        }
         */
        
        // v2 -- disable force update
        if let newVer = UserDefaults.standard.object(forKey: UserDefaultsKey.UpdatePopUpVer) as? String , newVer != "" {
            if let releaseNotes = UserDefaults.standard.object(forKey: UserDefaultsKey.UpdatePopUpNotes) as? String , releaseNotes != "" {
                /*
                let notes = releaseNotes + "\n\nKamu tidak akan mendapatkan fitur dan perbaikan terbaru jika tidak meng-update aplikasi."
                
                let alert : UIAlertController = UIAlertController(title: "Prelo \(newVer)", message: notes, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { action in
                    UIApplication.shared.openURL(URL(string: "itms-apps://itunes.apple.com/id/app/prelo/id1027248488")!)
                }))
                alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { action in
                    showDialog("Perhatian", message: "Jika terjadi error, harap update aplikasi")
                }))
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                 */
                
                let alertView = SCLAlertView(appearance: appearance)
                
                // release notes
                let subtitle = UILabel()
                
                subtitle.font = appearance.kTextFont
                subtitle.textColor = alertView.labelTitle.textColor
                subtitle.numberOfLines = 0
                
                /*
                 var notes = releaseNotes
                 notes = notes.replacingOccurrences(of: "+", with: " ")
                 notes = notes.replacingOccurrences(of: "-", with: " ")
                 
                 let mystr = notes
                 let searchstr = " | "
                 let ranges: [NSRange]
                 
                 do {
                 // Create the regular expression.
                 let regex = try NSRegularExpression(pattern: searchstr, options: [])
                 
                 // Use the regular expression to get an array of NSTextCheckingResult.
                 // Use map to extract the range from each result.
                 ranges = regex.matches(in: mystr, options: [], range: NSMakeRange(0, mystr.characters.count)).map {$0.range}
                 }
                 catch {
                 // There was a problem creating the regular expression
                 ranges = []
                 }
                 
                 let attString : NSMutableAttributedString = NSMutableAttributedString(string: notes)
                 for i in ranges {
                 attString.addAttributes([NSFontAttributeName:UIFont(name: "preloAwesome", size: 14.0)!], range: i)
                 }
                 
                 subtitle.attributedText = attString
                 */
                
                // Create a NSCharacterSet of delimiters.
                let separators = NSCharacterSet(charactersIn: "\n")
                // Split based on characters.
                var strings = releaseNotes.components(separatedBy: separators as CharacterSet)
                
                // testing
                //strings = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "This is a small string", "This is more of medium string with a few more words etc.", "Well this is certainly a longer string, with many more words than either of the previuos two strings", ""]
                
                if (strings.count > 0 && strings.last == "") {
                    strings.removeLast()
                }
                
                let attributesDictionary = [NSFontAttributeName : subtitle.font]
                let fullAttributedString = NSMutableAttributedString(string: "", attributes: attributesDictionary)
                
                for string: String in strings
                {
                    let bulletPoint: String = "\u{2022}"
                    let formattedString: String = "\(bulletPoint) \(string)\n"
                    let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: formattedString)
                    
                    var paragraphStyle: NSMutableParagraphStyle
                    paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 12, options: NSDictionary() as! [String : AnyObject])]
                    paragraphStyle.defaultTabInterval = 12
                    paragraphStyle.firstLineHeadIndent = 0
                    paragraphStyle.headIndent = 12
                    
                    attributedString.addAttributes([NSParagraphStyleAttributeName: paragraphStyle], range: NSMakeRange(0, attributedString.length))
                    
                    fullAttributedString.append(attributedString)
                }
                
                subtitle.attributedText = fullAttributedString
                
                let width = appearance.kWindowWidth - 32
                let frame = subtitle.text!.boundsWithFontSize(appearance.kTextFont, width: width)
                
                subtitle.frame = CGRect(x: 4, y: 0, width: width, height: frame.height)
                
                // notes apps
                let subtitle2 = UILabel()
                
                let notes2 = "Kamu tidak akan mendapatkan fitur dan perbaikan terbaru jika tidak meng-update aplikasi."
                subtitle2.font = appearance.kTextFont
                subtitle2.textColor = alertView.labelTitle.textColor
                subtitle2.numberOfLines = 0
                subtitle2.textAlignment = .center
                
                let attString2 : NSMutableAttributedString = NSMutableAttributedString(string: notes2)
                
                attString2.addAttributes([NSFontAttributeName:UIFont.italicSystemFont(ofSize: 14)], range: (notes2 as NSString).range(of: "update"))
                
                subtitle2.attributedText = attString2
                
                let frame2 = subtitle2.text!.boundsWithFontSize(appearance.kTextFont, width: width)
                
                subtitle2.frame = CGRect(x: 4, y: frame.height, width: width, height: frame2.height)
                
                // Creat the subview
                let maxheight = UIScreen.main.bounds.height - 300
                
                let subview = UIView(frame: CGRect(x: 0, y: 0, width: width + 8, height: frame.height + frame2.height))
                subview.addSubview(subtitle)
                subview.addSubview(subtitle2)
                subview.backgroundColor = UIColor.white
                
                let scrollview = UIScrollView()
                scrollview.contentSize = subview.bounds.size
                
                scrollview.addSubview(subview)
                
                let subviewsuper = UIView(frame: CGRect(x: 0, y: 0, width: width + 8, height: (frame.height + frame2.height > maxheight ? maxheight : frame.height + frame2.height)))
                
                scrollview.frame = subviewsuper.bounds
                subviewsuper.addSubview(scrollview)
                
                if (frame.height + frame2.height > maxheight) {
                    let gradient: CAGradientLayer = CAGradientLayer()
                    
                    gradient.colors = [UIColor.colorWithColor(UIColor.white, alpha: 0).cgColor, UIColor.colorWithColor(UIColor.white, alpha: 1).cgColor]
                    gradient.locations = [0.0 , 1.0]
//                    gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
//                    gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
                    gradient.frame = CGRect(x: 0.0, y: maxheight - 24, width: width + 8, height: 24)
                    
                    subviewsuper.layer.insertSublayer(gradient, at: 1)
                    
                    // bottom
                    scrollview.contentInset = UIEdgeInsetsMake(0, 0, 20, 0)
                }
                
                alertView.customSubview = subviewsuper
                
                alertView.addButton("Update") {
                    UIApplication.shared.openURL(URL(string: "itms-apps://itunes.apple.com/id/app/prelo/id1027248488")!)
                }
                alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {
                    let alertView3 = SCLAlertView(appearance: appearance)
                    let subtitle3 = UILabel()
                    
                    let notes3 = "Jika terjadi error, harap update aplikasi"
                    subtitle3.font = appearance.kTextFont
                    subtitle3.textColor = alertView3.labelTitle.textColor
                    subtitle3.numberOfLines = 0
                    subtitle3.textAlignment = .center
                    
                    let attString3 : NSMutableAttributedString = NSMutableAttributedString(string: notes3)
                    
                    attString3.addAttributes([NSFontAttributeName:UIFont.italicSystemFont(ofSize: 14)], range: (notes3 as NSString).range(of: "error"))
                    
                    attString3.addAttributes([NSFontAttributeName:UIFont.italicSystemFont(ofSize: 14)], range: (notes3 as NSString).range(of: "update"))
                    
                    subtitle3.attributedText = attString3
                    
                    let width3 = appearance.kWindowWidth - 24
                    let frame3 = subtitle3.text!.boundsWithFontSize(appearance.kTextFont, width: width3)
                    
                    subtitle3.frame = frame3
                    
                    // Creat the subview
                    let subview3 = UIView(frame: CGRect(x: 0, y: 0, width: width3, height: frame3.height))
                    subview3.addSubview(subtitle3)
                    
                    subtitle3.frame = subview3.bounds
                    
                    alertView3.customSubview = subview3
                    
                    alertView3.addButton("Oke") {}
                    
                    alertView3.showCustom("Perhatian", subTitle: "", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                }
                
                alertView.showCustom("Prelo \(newVer)", subTitle: "", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
            }
        }
    }
    
    static func showDisconnectBanner() {
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        let c = statusBar.backgroundColor
        
        statusBar.backgroundColor = UIColor.clear
        
        let imageBanner = UIImage(named: "banner_exclamation.png")
        
        // banner
        let banner = Banner(title: "Tidak Ada Jaringan", subtitle: "Pastikan perangkat kamu terhubung dengan jaringan", image: imageBanner, backgroundColor: UIColor.red, didTapBlock: {
            
            statusBar.backgroundColor = c
        })
        
        banner.dismissesOnTap = true
        
        AudioServicesPlaySystemSound(SystemSoundID(1050)) // alert
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        banner.show(duration: 3.0)
    }
}

extension String
{
    func boundsWithFontSize(_ font : UIFont, width : CGFloat) -> CGRect {
        let cons = CGSize(width: width, height: 0)
        
        return self.boundingRect(with: cons, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil)
    }
    
    func heightWithConstrainedWidth(_ width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return boundingBox.height
    }
    
    func widthWithConstrainedHeight(_ height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return boundingBox.width
    }
    
    var escapedHTML : String
    {
        var s = self
        
        for (key, value) in Constant.escapesSymbols
        {
            s = self.replacingOccurrences(of: key, with: value, options: NSString.CompareOptions.caseInsensitive, range: nil)
        }
        
        return s
    }
    
    var int : Int {
        return (self as NSString).integerValue
    }
}

extension NSAttributedString {
    func heightWithConstrainedWidth(_ width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func widthWithConstrainedHeight(_ height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}

var CalendarOption = NSCalendar.Options.matchLast

extension Foundation.Date
{
    
    public struct Date {
        static let formatter = DateFormatter()
    }
    var isoFormatted: String {
        Date.formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        Date.formatter.timeZone = TimeZone(secondsFromGMT: 0)
        Date.formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
        Date.formatter.locale = Locale(identifier: "en_US_POSIX")
        return Date.formatter.string(from: self)
    }
    
    func rollbackIsoFormatted(_ formatted: String) -> Foundation.Date? {
        Date.formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        Date.formatter.timeZone = TimeZone(secondsFromGMT: 0)
        Date.formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
        Date.formatter.locale = Locale(identifier: "en_US_POSIX")
        return Date.formatter.date(from: formatted)
    }
    
    func yearsFrom(_ date:Foundation.Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.year, from: date, to: self, options: CalendarOption).year!
    }
    func monthsFrom(_ date:Foundation.Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.month, from: date, to: self, options: CalendarOption).month!
    }
    func weeksFrom(_ date:Foundation.Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.weekOfYear, from: date, to: self, options: CalendarOption).weekOfYear!
    }
    func daysFrom(_ date:Foundation.Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.day, from: date, to: self, options: CalendarOption).day!
    }
    func hoursFrom(_ date:Foundation.Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.hour, from: date, to: self, options: CalendarOption).hour!
    }
    func minutesFrom(_ date:Foundation.Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.minute, from: date, to: self, options: CalendarOption).minute!
    }
    func secondsFrom(_ date:Foundation.Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.second, from: date, to: self, options: CalendarOption).second!
    }
    
    func minutesFromIsoFormatted(_ formatted : String) -> Int {
        let calendar : Calendar = Calendar.current
//        var comp : NSDateComponents = calendar.components((.Era | .Year | .Month | .Day | .Hour | .Minute | .Second), fromDate: NSDate())
        var comp : DateComponents = (calendar as NSCalendar).components([.era, .year, .month, .day, .hour, .minute, .second], from: Foundation.Date())
        if let nowDate = calendar.date(from: comp) {
            //print("nowDate = \(nowDate)")
            if let rollbackNSDate = Foundation.Date().rollbackIsoFormatted(formatted) {
                //print("rollbackNSDate = \(rollbackNSDate)")
                comp = (calendar as NSCalendar).components([.era, .year, .month, .day, .hour, .minute, .second], from: rollbackNSDate)
                if let rollbackDate = calendar.date(from: comp) {
                    return nowDate.minutesFrom(rollbackDate)
                }
            }
        }
        return 0
    }
    
    var relativeDescription : String {
        let detik = Int(fabs(self.timeIntervalSinceNow))
        if (detik < 60)
        {
//            return "\(detik) detik yang lalu"
            return "Beberapa saat yang lalu"
        }
        
        let menit = detik / 60
        if (menit < 60)
        {
            return "\(menit) menit yang lalu"
        }
        
        let jam = menit / 60
        if (jam < 24)
        {
            return "\(jam) jam yang lalu"
        }
        
        let hari = jam / 24
        if (hari < 7)
        {
            return "\(hari) hari yang lalu"
        }
        
        dateFormatter.dateFormat = "dd MMM"
        let s = dateFormatter.string(from: self)
        if (s != "") {
            return s
        }
        
        return "Dari zaman batu"
    }
}

extension UIView
{
    var width:CGFloat
    {
        get {
            let w = self.frame.size.width
            return w
        }
        set(w) {
            let r = self.frame
            self.frame = CGRect(x: r.origin.x, y: r.origin.y, width: w, height: r.size.height)
        }
    }
    
    var height:CGFloat
        {
        get {
            return self.frame.size.height
        }
        set(h) {
            let r = self.frame
            self.frame = CGRect(x: r.origin.x, y: r.origin.y, width: r.size.width, height: h)
        }
    }
    
    var x:CGFloat
    {
        get {
            return self.frame.origin.x
        }
        set(newX) {
            self.frame = CGRect(x: newX, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
        }
    }
    
    var y:CGFloat
        {
        get {
            return self.frame.origin.y
        }
        set(newY) {
            self.frame = CGRect(x: self.frame.origin.x, y: newY, width: self.frame.size.width, height: self.frame.size.height)
        }
    }
    
    var maxX :CGFloat
    {
        return self.x + self.width
    }
    
    var maxY :CGFloat
        {
            return self.y + self.height
    }
}
