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
            return UIColor(CGColor: self.layer.borderColor!)
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

class BorderedButton : UIButton
{
    @IBInspectable var cornerRadius : CGFloat = 0
    
    var _borderColor : UIColor?
    @IBInspectable var borderColor : UIColor {
        get {
            return _borderColor!
        }
        set (newColor) {
            _borderColor = newColor
            self.layer.borderColor = newColor.CGColor
        }
    }
    
    var _borderColorHighlight : UIColor?
    @IBInspectable var borderColorHighlight : UIColor {
        get {
            return _borderColorHighlight!
        }
        set (newColor) {
            _borderColorHighlight = newColor
            //self.layer.borderColor = newColor.CGColor
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
        self.layer.borderColor = _borderColor!.CGColor
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
        
        self.setTitleColor(_borderColorHighlight, forState: UIControlState.Selected)
        self.setTitleColor(_borderColorHighlight, forState: UIControlState.Highlighted)
        
        self.addTarget(self, action: #selector(BorderedButton.highlightBorder), forControlEvents: UIControlEvents.TouchDown)
        self.addTarget(self, action: #selector(BorderedButton.defaultBorder), forControlEvents: UIControlEvents.TouchUpInside)
        self.addTarget(self, action: #selector(BorderedButton.defaultBorder), forControlEvents: UIControlEvents.TouchUpOutside)
        self.addTarget(self, action: #selector(BorderedButton.defaultBorder), forControlEvents: UIControlEvents.TouchDragOutside)
    }
    
    func highlightBorder()
    {
        self.layer.borderColor = _borderColorHighlight!.CGColor
    }
    
    func defaultBorder()
    {
        self.layer.borderColor = _borderColor!.CGColor
    }
}

class TintedImageView : UIImageView
{
    override func awakeFromNib() {
        self.tint = true
    }
    
    private var _tint : Bool = true
    var tint : Bool
    {
        get {
            return _tint
        }
        
        set {
            _tint = newValue
            if (_tint)
            {
                let i = self.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                let c = self.tintColor
                self.tintColor = c
                self.image = i
            } else
            {
                let i = self.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
                self.image = i
            }
        }
    }
}
