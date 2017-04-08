//
//  KumangCustomView.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/5/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class KumangCustomView: NSObject {
   
}

class BorderedView : UIView {
    
    @IBInspectable var borderColor : UIColor {
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
        set (newColor) {
            self.layer.borderColor = newColor.cgColor
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
        self.layer.borderColor = self.borderColor.cgColor
    }
}

class BorderedButton : UIButton {
    @IBInspectable var cornerRadius : CGFloat = 0
    
    var _borderColor : UIColor?
    @IBInspectable var borderColor : UIColor {
        get {
            return _borderColor!
        }
        set (newColor) {
            _borderColor = newColor
            self.layer.borderColor = newColor.cgColor
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
        self.layer.borderColor = _borderColor!.cgColor
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
        
        self.setTitleColor(_borderColorHighlight, for: UIControlState.selected)
        self.setTitleColor(_borderColorHighlight, for: UIControlState.highlighted)
        
        self.addTarget(self, action: #selector(BorderedButton.highlightBorder), for: UIControlEvents.touchDown)
        self.addTarget(self, action: #selector(BorderedButton.defaultBorder), for: UIControlEvents.touchUpInside)
        self.addTarget(self, action: #selector(BorderedButton.defaultBorder), for: UIControlEvents.touchUpOutside)
        self.addTarget(self, action: #selector(BorderedButton.defaultBorder), for: UIControlEvents.touchDragOutside)
    }
    
    func highlightBorder()
    {
        self.layer.borderColor = _borderColorHighlight!.cgColor
    }
    
    func defaultBorder()
    {
        self.layer.borderColor = _borderColor!.cgColor
    }
}

class TintedImageView : UIImageView {
    override func awakeFromNib() {
        self.tint = true
    }
    
    fileprivate var _tint : Bool = true
    var tint : Bool
    {
        get {
            return _tint
        }
        
        set {
            _tint = newValue
            if (_tint) {
                let i = self.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                let c = self.tintColor
                self.tintColor = c
                self.image = i
            } else {
                let i = self.image?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
                self.image = i
            }
        }
    }
}
