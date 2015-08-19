//
//  KumangCustomView.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/5/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class KumangCustomView: NSObject {
   
}

class BorderedView : UIView
{
    
    @IBInspectable var borderColor : UIColor {
        get {
            return UIColor(CGColor: self.layer.borderColor)!
        }
        set (newColor) {
            self.layer.borderColor = newColor.CGColor
        }
    }
    
    @IBInspectable var borderWidth : CGFloat {
        get {
            return self.layer.borderWidth
        }
        set (newWidth) {
            self.layer.borderWidth = newWidth
        }
    }
    
    override func awakeFromNib() {
        self.layer.borderWidth = self.borderWidth
        self.layer.borderColor = self.borderColor.CGColor
    }
}

class TintedImageView : UIImageView
{

    override func awakeFromNib() {
        let i = self.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        let c = self.tintColor
        self.tintColor = c
        self.image = i
    }
}
