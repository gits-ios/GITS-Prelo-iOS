//
//  Constant.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/28/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

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
        
        for (key : String, value : String) in Constant.escapesSymbols
        {
            s = self.stringByReplacingOccurrencesOfString(key, withString: value, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        }
        
        return s
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
}
