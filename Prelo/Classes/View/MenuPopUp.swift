
//
//  MenuPopUp.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/10/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

enum MenuOption
{
    case Facebook
    case Twitter
    case Instagram
    case Gallery
    case Camera
}

protocol MenuPopUpDelegate
{
    func menuSelected(option : MenuOption)
}

class MenuPopUp: UIView {

    @IBOutlet var menuButtons : Array<MenuButton> = []
    @IBOutlet var btnClose : UIView!
    
    var menuDelegate : MenuPopUpDelegate?
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    let base = CGPointMake(85, 90)
    
    var _parent : UIViewController?
    
    var parent : UIViewController?
    {
        set (new) {
            _parent = new
            resize()
            _parent?.view.addSubview(self)
        }
        get {
            return _parent
        }
    }
    
    var animationPos : [UIView : MenuAnimPos] = [:]
    func setupView(parent : UIViewController)
    {
        self.parent = parent
        
        self.hidden = true
        
        for m in menuButtons
        {
            m.layer.cornerRadius = m.width/2
            m.layer.masksToBounds = true
            
            animationPos[m] = MenuAnimPos.createOne(base, extended: CGPointMake(m.x, m.y))
            m.moveTo(base)
        }
        
        btnClose.layer.cornerRadius = btnClose.width/2
        btnClose.layer.masksToBounds = true
    }
    
    func resize()
    {
        self.frame = CGRectMake(0, 0, (_parent?.view.frame.width)!, (_parent?.view.frame.height)!)
    }
    
    func show(showing : Bool)
    {
        if (showing) {
            self.alpha = 0
            self.hidden = false
            UIView.animateWithDuration(0.2, animations: {
                self.alpha = 1
                self.btnClose.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2/2))
            })
            animate(showing)
        } else {
            animate(showing)
            UIView.animateWithDuration(0.2, animations: {
                self.alpha = 0
                self.btnClose.transform = CGAffineTransformMakeRotation(0)
                }, completion: { c in
                    self.hidden = true
            })
        }
    }
    
    func startAnim()
    {
        animate(true)
    }
    
    func animate(showing : Bool)
    {
        for (view : UIView, pos : MenuAnimPos) in animationPos
        {
            UIView.animateWithDuration(0.2, animations: {
                let m = view as! MenuButton
                if (showing) {
                    m.moveTo(pos.extended)
                } else {
                    m.moveTo(pos.base)
                }
                }, completion: { c in
                    
            })
        }
    }
    
    @IBAction func hide()
    {
        self.show(false)
    }
    
    @IBAction func menuSelect(sender : AnyObject)
    {
        let m = sender as! MenuButton
        var o = MenuOption.Facebook
        
        switch m.menu
        {
        case 1:o = MenuOption.Facebook
        case 2:o = MenuOption.Twitter
        case 3:o = MenuOption.Instagram
        case 4:o = MenuOption.Gallery
        case 5:o = MenuOption.Camera
        default : o = MenuOption.Gallery
        }
        
        menuDelegate?.menuSelected(o)
    }

}

class MenuAnimPos : NSObject
{
    var base : CGPoint = CGPointZero
    var extended : CGPoint = CGPointZero
    
    static func createOne(base : CGPoint, extended : CGPoint) -> MenuAnimPos
    {
        let m = MenuAnimPos()
        m.base = base
        m.extended = extended
        
        return m
    }
}

class MenuButton : UIButton
{
    @IBOutlet var xCon : NSLayoutConstraint?
    @IBOutlet var yCon : NSLayoutConstraint?
    
    @IBInspectable var menu : Int = 0
    
    func moveTo(p : CGPoint)
    {
        self.xCon?.constant = p.x
        self.yCon?.constant = p.y
        UIView.animateWithDuration(0.4, animations: {
            self.layoutIfNeeded()
        })
    }
}