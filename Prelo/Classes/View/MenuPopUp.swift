
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
    case facebook
    case twitter
    case instagram
    case gallery
    case camera
}

protocol MenuPopUpDelegate
{
    func menuSelected(_ option : MenuOption)
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
    
    let base = CGPoint(x: 85, y: 90)
    
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
    func setupView(_ parent : UIViewController)
    {
        self.parent = parent
        
        self.isHidden = true
        
        for m in menuButtons
        {
            m.layer.cornerRadius = m.width/2
            m.layer.masksToBounds = true
            
            animationPos[m] = MenuAnimPos.createOne(base, extended: CGPoint(x: m.x, y: m.y))
            m.moveTo(base)
        }
        
        btnClose.layer.cornerRadius = btnClose.width/2
        btnClose.layer.masksToBounds = true
    }
    
    func resize()
    {
        self.frame = CGRect(x: 0, y: 0, width: (_parent?.view.frame.width)!, height: (_parent?.view.frame.height)!)
    }
    
    func show(_ showing : Bool)
    {
        if (showing) {
            self.alpha = 0
            self.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 1
                self.btnClose.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2/2))
            })
            animate(showing)
        } else {
            animate(showing)
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0
                self.btnClose.transform = CGAffineTransform(rotationAngle: 0)
                }, completion: { c in
                    self.isHidden = true
            })
        }
    }
    
    func startAnim()
    {
        animate(true)
    }
    
    func animate(_ showing : Bool)
    {
        for (view, pos) in animationPos
        {
            UIView.animate(withDuration: 0.2, animations: {
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
    
    @IBAction func menuSelect(_ sender : AnyObject)
    {
        let m = sender as! MenuButton
        var o = MenuOption.facebook
        
        switch m.menu
        {
        case 1:o = MenuOption.facebook
        case 2:o = MenuOption.twitter
        case 3:o = MenuOption.instagram
        case 4:o = MenuOption.gallery
        case 5:o = MenuOption.camera
        default : o = MenuOption.gallery
        }
        
        menuDelegate?.menuSelected(o)
    }

}

class MenuAnimPos : NSObject
{
    var base : CGPoint = CGPoint.zero
    var extended : CGPoint = CGPoint.zero
    
    static func createOne(_ base : CGPoint, extended : CGPoint) -> MenuAnimPos
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
    
    func moveTo(_ p : CGPoint)
    {
        self.xCon?.constant = p.x
        self.yCon?.constant = p.y
        UIView.animate(withDuration: 0.4, animations: {
            self.layoutIfNeeded()
        })
    }
}
