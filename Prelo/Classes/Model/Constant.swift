//
//  Constant.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/28/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

var dateFormatter : DateFormatter = DateFormatter()

class Constant: NSObject {
    static var escapesSymbols : [String : String] = ["&amp;":"&"]
    
    static func showDialog(_ title : String, message : String)
    {
        let a = UIAlertView()
        a.title = title
        a.message = message
        a.addButton(withTitle: "OK")
        a.show()
    }
    
}

extension String
{
    func boundsWithFontSize(_ font : UIFont, width : CGFloat) -> CGRect
    {
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
    
    struct Date {
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
            return "\(detik) detik yang lalu"
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
