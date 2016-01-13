//
//  UIDevice+BFKit.swift
//  BFKit
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Fabrizio Brancati. All rights reserved.
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
import UIKit

// MARK: - Global variables -

/// Used to store the BFUniqueIdentifier in defaults
private let BFUniqueIdentifierDefaultsKey = "BFUniqueIdentifier"

/// Get the screen width
public var SCREEN_WIDTH: CGFloat
{
    get
    {
        return (UIApplication.sharedApplication().statusBarOrientation == .Portrait || UIApplication.sharedApplication().statusBarOrientation == .PortraitUpsideDown) ? UIScreen.mainScreen().bounds.size.width : UIScreen.mainScreen().bounds.size.height
    }
}

/// Get the screen height
public var SCREEN_HEIGHT: CGFloat
{
    get
    {
        return (UIApplication.sharedApplication().statusBarOrientation == .Portrait || UIApplication.sharedApplication().statusBarOrientation == .PortraitUpsideDown) ? UIScreen.mainScreen().bounds.size.height : UIScreen.mainScreen().bounds.size.width
    }
}

// MARK: - Global functions -

/**
Get the iOS version string

:returns: Get the iOS version string
*/
public func IOS_VERSION() -> String
{
    return UIDevice.currentDevice().systemVersion
}

/**
Compare system versions

:param: v Version, like "9.0"

:returns: Returns a Bool
*/
public func SYSTEM_VERSION_EQUAL_TO(v: String) -> Bool
{
    return UIDevice.currentDevice().systemVersion.compare(v, options: .NumericSearch) == .OrderedSame
}

/**
Compare system versions

:param: v Version, like "9.0"

:returns: Returns a Bool
*/
public func SYSTEM_VERSION_GREATER_THAN(v: String) -> Bool
{
    return UIDevice.currentDevice().systemVersion.compare(v, options: .NumericSearch) == .OrderedDescending
}

/**
Compare system versions

:param: v Version, like "9.0"

:returns: Returns a Bool
*/
public func SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v: String) -> Bool
{
    return UIDevice.currentDevice().systemVersion.compare(v, options: .NumericSearch) != .OrderedAscending
}

/**
Compare system versions

:param: v Version, like "9.0"

:returns: Returns a Bool
*/
public func SYSTEM_VERSION_LESS_THAN(v: String) -> Bool
{
    return UIDevice.currentDevice().systemVersion.compare(v, options: .NumericSearch) == .OrderedAscending
}

/**
Compare system versions

:param: v Version, like "9.0"

:returns: Returns a Bool
*/
public func SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v: String) -> Bool
{
    return UIDevice.currentDevice().systemVersion.compare(v, options: .NumericSearch) != .OrderedDescending
}

/**
Returns if the iOS version is greater or equal to choosed one

:returns: Returns if the iOS version is greater or equal to choosed one
*/
public func IS_IOS_5_OR_LATER() -> Bool
{
    return UIDevice.currentDevice().systemVersion.floatValue >= 5.0
}

/**
Returns if the iOS version is greater or equal to choosed one

:returns: Returns if the iOS version is greater or equal to choosed one
*/
public func IS_IOS_6_OR_LATER() -> Bool
{
    return UIDevice.currentDevice().systemVersion.floatValue >= 6.0
}

/**
Returns if the iOS version is greater or equal to choosed one

:returns: Returns if the iOS version is greater or equal to choosed one
*/
public func IS_IOS_7_OR_LATER() -> Bool
{
    return UIDevice.currentDevice().systemVersion.floatValue >= 7.0
}

/**
Returns if the iOS version is greater or equal to choosed one

:returns: Returns if the iOS version is greater or equal to choosed one
*/
public func IS_IOS_8_OR_LATER() -> Bool
{
    return UIDevice.currentDevice().systemVersion.floatValue >= 8.0
}

/**
Returns if the iOS version is greater or equal to choosed one

:returns: Returns if the iOS version is greater or equal to choosed one
*/
public func IS_IOS_9_OR_LATER() -> Bool
{
    return UIDevice.currentDevice().systemVersion.floatValue >= 9.0
}

/// This extesion adds some useful functions to UIDevice
public extension UIDevice
{
    // MARK: - Class functions -
    
    /**
    Returns the device platform string
    Example: "iPhone7,2"
    
    :returns: Returns the device platform string
    */
    public static func devicePlatform() -> String
    {
        var name: [Int32] = [CTL_HW, HW_MACHINE]
        var size: Int = 2
        sysctl(&name, 2, nil, &size, &name, 0)
        var hw_machine = [CChar](count: Int(size), repeatedValue: 0)
        sysctl(&name, 2, &hw_machine, &size, &name, 0)
        
        let hardware: String = String.fromCString(hw_machine)!
        return hardware
    }
    
    /**
    Returns the user-friendly device platform string
    Example: "iPad Air (Cellular)"
    
    :returns: Returns the user-friendly device platform string
    */
    public static func devicePlatformString() -> String
    {
        var platform: String = self.devicePlatform()
        
        switch platform
        {
        // iPhone
        case "iPhone1,1":       return "iPhone 2G"
        case "iPhone1,2":       return "iPhone 3G"
        case "iPhone2,1":       return "iPhone 4"
        case "iPhone3,1":       return "iPhone 4 (CDMA)"
        case "iPhone4,1":       return "iPhone 4S"
        case "iPhone5,1":       return "iPhone 5 (GSM)"
        case "iPhone5,2":       return "iPhone 5 (CDMA)"
        case "iPhone5,3":       return "iPhone 5C (GSM)"
        case "iPhone5,4":       return "iPhone 5C (Global)"
        case "iPhone6,1":       return "iPhone 5S (GSM)"
        case "iPhone6,2":       return "iPhone 5S (Global)"
        case "iPhone7,1":       return "iPhone 6 Plus"
        case "iPhone7,2":       return "iPhone 6"
        // iPod
        case "iPod1,1":         return "iPod Touch 1G"
        case "iPod2,1":         return "iPod Touch 2G"
        case "iPod3,1":         return "iPod Touch 3G"
        case "iPod4,1":         return "iPod Touch 4G"
        case "iPod5,1":         return "iPod Touch 5G"
        // iPad
        case "iPad1,1":         return "iPad 1"
        case "iPad2,1":         return "iPad 2 (WiFi)"
        case "iPad2,2":         return "iPad 2 (GSM)"
        case "iPad2,3":         return "iPad 2 (CDMA)"
        case "iPad2,4":         return "iPad 2 (32nm)"
        case "iPad3,1":         return "iPad 3 (WiFi)"
        case "iPad3,2":         return "iPad 3 (CDMA)"
        case "iPad3,3":         return "iPad 3 (GSM)"
        case "iPad3,4":         return "iPad 4 (WiFi)"
        case "iPad3,5":         return "iPad 4 (GSM)"
        case "iPad3,6":         return "iPad 4 (CDMA)"
        case "iPad4,1":         return "iPad Air (WiFi)"
        case "iPad4,2":         return "iPad Air (Cellular)"
        case "iPad4,3":         return "iPad Air (China)"
        case "iPad5,3":         return "iPad Air 2 (WiFi)"
        case "iPad5,4":         return "iPad Air 2 (Cellular)"
        // iPad mini
        case "iPad2,5":         return "iPad mini (WiFi)"
        case "iPad2,6":         return "iPad mini (GSM)"
        case "iPad2,7":         return "iPad mini (CDMA)"
        case "iPad4,4":         return "iPad mini 2 (WiFi)"
        case "iPad4,5":         return "iPad mini 2 (Cellular)"
        case "iPad4,6":         return "iPad mini 2 (China)"
        case "iPad4,7":         return "iPad mini 3 (WiFi)"
        case "iPad4,8":         return "iPad mini 3 (Cellular)"
        case "iPad4,9":         return "iPad mini 3 (China)"
        // Apple TV
        case "AppleTV2,1":      return "Apple TV 2G"
        case "AppleTV3,1":      return "Apple TV 3G"
        case "AppleTV3,2":      return "Apple TV 3G"
        // Apple Watch
        case "Watch1,1":        return "Apple Watch 38mm"
        case "Watch1,2":        return "Apple Watch 42mm"
        case "i386", "x86_64":  return "Simulator"
        default:
            return platform
        }
    }
    
    /**
    Check if the current device is an iPad
    
    :returns: Returns true if it's an iPad, fasle if not
    */
    public static func isiPad() -> Bool
    {
        if self.devicePlatform().substringToIndex(4) == "iPad"
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    /**
    Check if the current device is an iPhone
    
    :returns: Returns true if it's an iPhone, false if not
    */
    public static func isiPhone() -> Bool
    {
        if self.devicePlatform().substringToIndex(6) == "iPhone"
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    /**
    Check if the current device is an iPod
    
    :returns: Returns true if it's an iPod, false if not
    */
    public static func isiPod() -> Bool
    {
        if self.devicePlatform().substringToIndex(4) == "iPod"
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    /**
    Check if the current device is an Apple TV
    
    :returns: Returns true if it's an Apple TV, false if not
    */
    public static func isAppleTV() -> Bool
    {
        if self.devicePlatform().substringToIndex(7) == "AppleTV"
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    /**
    Check if the current device is an Apple Watch
    
    :returns: Returns true if it's an Apple Watch, false if not
    */
    public static func isAppleWatch() -> Bool
    {
        if self.devicePlatform().substringToIndex(5) == "Watch"
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    /**
    Check if the current device is a Simulator
    
    :returns: Returns true if it's a Simulator, false if not
    */
    public static func isSimulator() -> Bool
    {
        if self.devicePlatform() == "i386" || self.devicePlatform() == "x86_64"
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    /**
    Check if the current device has a Retina display
    
    :returns: Returns true if it has a Retina display, false if not
    */
    public static func isRetina() -> Bool
    {
        if UIScreen.mainScreen().respondsToSelector("displayLinkWithTarget:selector:") && (UIScreen.mainScreen().scale == 2.0 || UIScreen.mainScreen().scale == 3.0)
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    /**
    Check if the current device has a Retina HD display
    
    :returns: Returns true if it has a Retina HD display, false if not
    */
    public static func isRetinaHD() -> Bool
    {
        if UIScreen.mainScreen().respondsToSelector("displayLinkWithTarget:selector:") && UIScreen.mainScreen().scale == 3.0
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    /**
    Returns the iOS version without the subversion
    Example: 7
    
    :returns: Returns the iOS version
    */
    public static func iOSVersion() -> Int
    {
        return UIDevice.currentDevice().systemVersion.toInt()!
    }
    
    /**
    Private, used to get the system info
    
    :param: typeSpecifier Type of the system info
    
    :returns: Return the sysyem info
    */
    private static func getSysInfo(typeSpecifier: Int32) -> Int
    {
        var name: [Int32] = [CTL_HW, typeSpecifier]
        var size: Int = 2
        sysctl(&name, 2, nil, &size, &name, 0)
        var results: Int = 0
        sysctl(&name, 2, &results, &size, &name, 0)
        
        return results
    }
    
    /**
    Returns the current device CPU frequency
    
    :returns: Returns the current device CPU frequency
    */
    public static func cpuFrequency() -> Int
    {
        return self.getSysInfo(HW_CPU_FREQ)
    }
    
    /**
    Returns the current device BUS frequency
    
    :returns: Returns the current device BUS frequency
    */
    public static func busFrequency() -> Int
    {
        return self.getSysInfo(HW_TB_FREQ)
    }
    
    /**
    Returns the current device RAM size
    
    :returns: Returns the current device RAM size
    */
    public static func ramSize() -> Int
    {
        return self.getSysInfo(HW_MEMSIZE)
    }
    
    /**
    Returns the current device CPU number
    
    :returns: Returns the current device CPU number
    */
    public static func cpuNumber() -> Int
    {
        return self.getSysInfo(HW_NCPU)
    }
    
    /**
    Returns the current device total memory
    
    :returns: Returns the current device total memory
    */
    public static func totalMemory() -> Int
    {
        return self.getSysInfo(HW_PHYSMEM)
    }
    
    /**
    Returns the current device non-kernel memory
    
    :returns: Returns the current device non-kernel memory
    */
    public static func userMemory() -> Int
    {
        return self.getSysInfo(HW_USERMEM)
    }
    
    /**
    Returns the current device total disk space
    
    :returns: Returns the current device total disk space
    */
    public static func totalDiskSpace() -> AnyObject
    {
        let attributes: NSDictionary = NSFileManager.defaultManager().attributesOfFileSystemForPath(NSHomeDirectory(), error: nil)!
        return attributes.objectForKey(NSFileSystemSize)!
    }
    
    /**
    Returns the current device free disk space
    
    :returns: Returns the current device free disk space
    */
    public static func freeDiskSpace() -> AnyObject
    {
        let attributes: NSDictionary = NSFileManager.defaultManager().attributesOfFileSystemForPath(NSHomeDirectory(), error: nil)!
        return attributes.objectForKey(NSFileSystemFreeSize)!
    }
    
    /**
    Generate an unique identifier and store it into standardUserDefaults
    
    :returns: Returns a unique identifier as a String
    */
    public static func uniqueIdentifier() -> String
    {
        var uuid: String?
        if UIDevice.currentDevice().respondsToSelector("identifierForVendor")
        {
            uuid = UIDevice.currentDevice().identifierForVendor.UUIDString
        }
        else
        {
            let defaults = NSUserDefaults.standardUserDefaults()
            uuid = defaults.objectForKey(BFUniqueIdentifierDefaultsKey) as? String
            if uuid == nil
            {
                uuid = self.generateUUID()
                defaults.setObject(uuid, forKey: BFUniqueIdentifierDefaultsKey)
                defaults.synchronize()
            }
        }
        return uuid!
    }
    
    /**
    Private, used to create an UUID as String
    
    :returns: Returns the created UUID string
    */
    private static func generateUUID() -> String
    {
        let theUUID: CFUUIDRef? = CFUUIDCreate(kCFAllocatorDefault)
        let string: CFStringRef? = CFUUIDCreateString(kCFAllocatorDefault, theUUID)
        return string! as String
    }
}
