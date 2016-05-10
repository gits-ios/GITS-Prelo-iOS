//
//  Constant.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/28/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

var dateFormatter : NSDateFormatter = NSDateFormatter()

class Constant: NSObject {
    static var escapesSymbols : [String : String] = ["&amp;":"&"]
    
    static func showDialog(title : String, message : String)
    {
        let a = UIAlertView()
        a.title = title
        a.message = message
        a.addButtonWithTitle("OK")
        a.show()
    }
    
}

extension String
{
    func boundsWithFontSize(font : UIFont, width : CGFloat) -> CGRect
    {
        let cons = CGSizeMake(width, 0)
        
        return self.boundingRectWithSize(cons, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil)
    }
    
    var escapedHTML : String
    {
        var s = self
        
        for (key, value) in Constant.escapesSymbols
        {
            s = self.stringByReplacingOccurrencesOfString(key, withString: value, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        }
        
        return s
    }
    
    var int : Int {
        return (self as NSString).integerValue
    }
}

extension NSAttributedString {
    func heightWithConstrainedWidth(width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.max)
        let boundingBox = self.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func widthWithConstrainedHeight(height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.max, height: height)
        
        let boundingBox = self.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}

var CalendarOption = NSCalendarOptions.MatchLast

extension NSDate
{
    
    struct Date {
        static let formatter = NSDateFormatter()
    }
    var isoFormatted: String {
        Date.formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        Date.formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        Date.formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)!
        Date.formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        return Date.formatter.stringFromDate(self)
    }
    
    func rollbackIsoFormatted(formatted: String) -> NSDate? {
        Date.formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        Date.formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        Date.formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)!
        Date.formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        return Date.formatter.dateFromString(formatted)
    }
    
    func yearsFrom(date:NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Year, fromDate: date, toDate: self, options: CalendarOption).year
    }
    func monthsFrom(date:NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Month, fromDate: date, toDate: self, options: CalendarOption).month
    }
    func weeksFrom(date:NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.WeekOfYear, fromDate: date, toDate: self, options: CalendarOption).weekOfYear
    }
    func daysFrom(date:NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Day, fromDate: date, toDate: self, options: CalendarOption).day
    }
    func hoursFrom(date:NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Hour, fromDate: date, toDate: self, options: CalendarOption).hour
    }
    func minutesFrom(date:NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Minute, fromDate: date, toDate: self, options: CalendarOption).minute
    }
    func secondsFrom(date:NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Second, fromDate: date, toDate: self, options: CalendarOption).second
    }
    
    func minutesFromIsoFormatted(formatted : String) -> Int {
        let calendar : NSCalendar = NSCalendar.currentCalendar()
//        var comp : NSDateComponents = calendar.components((.Era | .Year | .Month | .Day | .Hour | .Minute | .Second), fromDate: NSDate())
        var comp : NSDateComponents = calendar.components([.Era, .Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: NSDate())
        if let nowDate = calendar.dateFromComponents(comp) {
            //print("nowDate = \(nowDate)")
            if let rollbackNSDate = NSDate().rollbackIsoFormatted(formatted) {
                //print("rollbackNSDate = \(rollbackNSDate)")
                comp = calendar.components([.Era, .Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: rollbackNSDate)
                if let rollbackDate = calendar.dateFromComponents(comp) {
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
        let s = dateFormatter.stringFromDate(self)
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
            self.frame = CGRectMake(r.origin.x, r.origin.y, w, r.size.height)
        }
    }
    
    var height:CGFloat
        {
        get {
            return self.frame.size.height
        }
        set(h) {
            let r = self.frame
            self.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, h)
        }
    }
    
    var x:CGFloat
    {
        get {
            return self.frame.origin.x
        }
        set(newX) {
            self.frame = CGRectMake(newX, self.frame.origin.y, self.frame.size.width, self.frame.size.height)
        }
    }
    
    var y:CGFloat
        {
        get {
            return self.frame.origin.y
        }
        set(newY) {
            self.frame = CGRectMake(self.frame.origin.x, newY, self.frame.size.width, self.frame.size.height)
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
