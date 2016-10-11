//
//  NSDate+BFKit.swift
//  BFKit
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 - 2016 Fabrizio Brancati. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

/// This extension add some useful functions to NSDate
public extension Foundation.Date {
    // MARK: - Variables -
    
    /**
     The simplified date structure
     */
    public struct BFDateInformation {
        /// Year
        var year = 0
        /// Month of the year
        var month = 0
        /// Day of the month
        var day = 0
        
        /// Day of the week
        var weekday = 0
        
        /// Hour of the day
        var hour = 0
        /// Minute of the hour
        var minute = 0
        /// Second of the minute
        var second = 0
        /// Nanosecond of the second
        var nanosecond = 0
    }
    
    // MARK: - Instance functions -
    
    /**
     Get self as a BFDateInformation structure with a given time zone
    
     - parameter timeZone: The timezone
    
     - returns: Return self as a BFDateInformation structure with a given time zone
     */
    public func dateInformation(_ timeZone: TimeZone = TimeZone.current) -> BFDateInformation {
        var info = BFDateInformation()
        
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = timeZone
        let comp = (calendar as NSCalendar).components(NSCalendar.Unit(rawValue: UInt.max), from: self)
        
        info.day = comp.day!
        info.month = comp.month!
        info.year = comp.year!
        
        info.hour = comp.hour!
        info.minute = comp.minute!
        info.second = comp.second!
        info.nanosecond = comp.nanosecond!
        
        info.weekday = comp.weekday!
        
        return info
    }
    
    /**
     Get the month from today
    
     - returns: Return the month
     */
    public func month() -> Foundation.Date {
        let calendar = Calendar.autoupdatingCurrent
        let comp = (calendar as NSCalendar).components([.year, .month], from: self)
        
        if #available(iOS 8.0, *)
        {
            (comp as NSDateComponents).setValue(1, forComponent: .day)
        } else {
            return calendar.date(from: comp)!
        }
        return calendar.date(from: comp)!
    }
    
    /**
     Get the weekday number from self
     - 1 - Sunday
     - 2 - Monday
     - 3 - Tuerday
     - 4 - Wednesday
     - 5 - Thursday
     - 6 - Friday
     - 7 - Saturday
     
     - returns: Return weekday number
     */
    public func weekday() -> Int {
        let calendar = Calendar.autoupdatingCurrent
        let comp = (calendar as NSCalendar).components([.year, .month, .day, .weekday], from: self)
        
        return comp.weekday!
    }
    
    /**
     Get the weekday as a localized string from self
     - 1 - Sunday
     - 2 - Monday
     - 3 - Tuerday
     - 4 - Wednesday
     - 5 - Thursday
     - 6 - Friday
     - 7 - Saturday
     
     - returns: Return weekday as a localized string
     */
    public func dayFromWeekday() -> NSString {
        switch self.weekday() {
        case 1:
            return BFLocalizedString("SUNDAY")
        case 2:
            return BFLocalizedString("MONDAY")
        case 3:
            return BFLocalizedString("TUESDAY")
        case 4:
            return BFLocalizedString("WEDNESDAY")
        case 5:
            return BFLocalizedString("THURSDAY")
        case 6:
            return BFLocalizedString("FRIDAY")
        case 7:
            return BFLocalizedString("SATURDAY")
        default:
            return ""
        }
    }
    
    /**
     Private, return the date with time informations
    
     - returns: Return the date with time informations
     */
    fileprivate func timelessDate() -> Foundation.Date {
        let calendar = Calendar.autoupdatingCurrent
        let comp = (calendar as NSCalendar).components([.year, .month, .day], from: self)
        
        return calendar.date(from: comp)!
    }
    
    /**
     Private, return the date with time informations
    
     - returns: Return the date with time informations
     */
    fileprivate func monthlessDate() -> Foundation.Date {
        let calendar = Calendar.autoupdatingCurrent
        let comp = (calendar as NSCalendar).components([.year, .month, .day, .weekday], from: self)
        
        return calendar.date(from: comp)!
    }
    
    /**
     Compare self with another date
    
     - parameter anotherDate: The another date to compare as NSDate
    
     - returns: Returns true if is same day, false if not
     */
    public func isSameDay(_ anotherDate: Foundation.Date) -> Bool {
        let calendar = Calendar.autoupdatingCurrent
        let components1 = (calendar as NSCalendar).components([.year, .month, .day], from: self)
        let components2 = (calendar as NSCalendar).components([.year, .month, .day], from: anotherDate)
        
        return components1.year == components2.year && components1.month == components2.month && components1.day == components2.day
    }
    
    /**
     Get the months number between self and another date
    
     - parameter toDate: The another date
    
     - returns: Returns the months between the two dates
     */
    public func monthsBetweenDate(_ toDate: Foundation.Date) -> Int {
        let calendar = Calendar.autoupdatingCurrent
        let components = (calendar as NSCalendar).components(.month, from: self.monthlessDate(), to: toDate.monthlessDate(), options: NSCalendar.Options.wrapComponents)
        
        return abs(components.month!)
    }
    
    /**
     Get the days number between self and another date
    
     - parameter anotherDate: The another date
    
     - returns: Returns the days between the two dates
     */
    public func daysBetweenDate(_ anotherDate: Foundation.Date) -> Int {
        let time: TimeInterval = self.timeIntervalSince(anotherDate)
        return Int(abs(time / 60 / 60 / 24))
    }
    
    /**
     Returns if self is today
    
     - returns: Returns if self is today
     */
    public func isToday() -> Bool {
        return self.isSameDay(Foundation.Date())
    }
    
    /**
     Add days to self
    
     - parameter days: The number of days to add
    
     - returns: Returns self by adding the gived days number
     */
    public func dateByAddingDays(_ days: Int) -> Foundation.Date {
        return self.addingTimeInterval(TimeInterval(days * 24 * 60 * 60))
    }
    
    /**
     Get the month string from self
    
     - returns: Returns the month string
     */
    public func monthString() -> String {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        return dateFormatter.string(from: self)
    }
    
    /**
     Get the year string from self
    
     - returns: Returns the year string
     */
    public func yearString() -> String {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        
        return dateFormatter.string(from: self)
    }
    
    /**
     Returns date with the year, month and day only.
     
     - returns: Date after removing all components but not year, month and day
     */
    public func shortData() -> Foundation.Date {
        let calendar = Calendar.autoupdatingCurrent
        let comp = (calendar as NSCalendar).components([.year, .month, .day], from:self)
        
        return calendar.date(from: comp)!
    }
    
    // MARK: - Class functions -
    
    /**
     Create a NSDate with the yesterday date
    
     - returns: Returns a NSDate with the yesterday date
     */
    public static func yesterday() -> Foundation.Date {
        var inf: BFDateInformation = Foundation.Date().dateInformation()
        inf.day -= 1
        return self.dateFromDateInformation(inf)
    }
    
    /**
     Get the month from today
    
     - returns: Returns the month
     */
    public static func month() -> Foundation.Date {
        return Foundation.Date().month()
    }
    
    /**
     Returns a date from a given BFDateInformation structure with a given time zone
    
     - parameter info:     The BFDateInformation to be converted
     - parameter timeZone: The timezone
    
     - returns: Returns a NSDate from a given BFDateInformation structure with a given time zone
     */
    public static func dateFromDateInformation(_ info: BFDateInformation, timeZone: TimeZone = TimeZone.current) -> Foundation.Date {
        let calendar = Calendar.autoupdatingCurrent
        let comp = (calendar as NSCalendar).components([.year, .month], from:Foundation.Date())
        
        if #available(iOS 8.0, *) {
            (comp as NSDateComponents).setValue(info.day, forComponent:.day)
            (comp as NSDateComponents).setValue(info.month, forComponent:.month)
            (comp as NSDateComponents).setValue(info.year, forComponent:.year)
            
            (comp as NSDateComponents).setValue(info.hour, forComponent:.hour)
            (comp as NSDateComponents).setValue(info.minute, forComponent:.minute)
            (comp as NSDateComponents).setValue(info.second, forComponent:.second)
            (comp as NSDateComponents).setValue(info.nanosecond, forComponent:.nanosecond)
            
            (comp as NSDateComponents).setValue(0, forComponent:.timeZone)
        } else {
            return calendar.date(from: comp)!
        }
        
        return calendar.date(from: comp)!
    }
    
    /**
     Create an NSDate with other two NSDate objects.
     Taken from the first date: day, month and year.
     Taken from the second date: hours and minutes.
    
     - parameter date: The first date for date
     - parameter time: The second date for time
    
     - returns: Returns the created NSDate
     */
    public static func dateWithDatePart(_ date: Foundation.Date, andTimePart time: Foundation.Date) -> Foundation.Date {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let datePortion: String = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "HH:mm"
        let timePortion: String = dateFormatter.string(from: time)
        
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        let dateTime = String(format: "%@ %@", datePortion, timePortion)
        
        return dateFormatter.date(from: dateTime)!
    }
    
    /**
     Get the month as a localized string from the given month number
     - 1 - January
     - 2 - February
     - 3 - March
     - 4 - April
     - 5 - May
     - 6 - June
     - 7 - July
     - 8 - August
     - 9 - September
     - 10 - October
     - 11 - November
     - 12 - December
     
     - parameter month: The month to be converted in string
    
     - returns: Returns the given month as a localized string
     */
    public static func monthStringWithMonthNumber(_ month: Int) -> String {
        switch month {
        case 1:
            return BFLocalizedString("JANUARY")
        case 2:
            return BFLocalizedString("FEBRUARY")
        case 3:
            return BFLocalizedString("MARCH")
        case 4:
            return BFLocalizedString("APRIL")
        case 5:
            return BFLocalizedString("MAY")
        case 6:
            return BFLocalizedString("JUNE")
        case 7:
            return BFLocalizedString("JULY")
        case 8:
            return BFLocalizedString("AUGUST")
        case 9:
            return BFLocalizedString("SEPTEMBER")
        case 10:
            return BFLocalizedString("OCTOBER")
        case 11:
            return BFLocalizedString("NOVEMBER")
        case 12:
            return BFLocalizedString("DECEMBER")
        default:
            return ""
        }
    }
    
    /**
     Get the given BFDateInformation structure as a formatted string
    
     - parameter info:          The BFDateInformation to be formatted
     - parameter dateSeparator: The string to be used as date separator
     - parameter usFormat:      Set if the timestamp is in US format or not
     - parameter nanosecond:    Set if the timestamp has to have the nanosecond
    
     - returns: Returns a String in the following format (dateSeparator = "/", usFormat to false and nanosecond to false). D/M/Y H:M:S. Example: 15/10/2013 10:38:43
     */
    public static func dateInformationDescriptionWithInformation(_ info: BFDateInformation, dateSeparator: String = "/", usFormat: Bool = false, nanosecond: Bool = false) -> String {
        var description: String
        
        if usFormat {
            description = String(format: "%04li%@%02li%@%02li %02li:%02li:%02li", info.year, dateSeparator, info.month, dateSeparator, info.day, info.hour, info.minute, info.second)
        } else {
            description = String(format: "%02li%@%02li%@%04li %02li:%02li:%02li", info.month, dateSeparator, info.day, dateSeparator, info.year, info.hour, info.minute, info.second)
        }
        
        if nanosecond {
            description += String(format: ":%03li", info.nanosecond / 1000000)
        }
        
        return description
    }
}
