//
//  CircleMenu.swift
//  Prelo
//
//  Created by Djuned on 8/20/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class CircleMenu: NSObject {
    static let sharedInstance = CircleMenu()
    
    var btnCenter: UIButton!
    
    var menu: UIView!
    var btnSell: UIButton!
    var btnRent: UIButton!
    
    var isOpen = false

    var center: CGPoint!
    var root: UIViewController!
    var parent: UIView!
    
    var topLeft: CGPoint!
    var topRight: CGPoint!
    var menuFrame: CGRect!
    
    func setupView(_ root: UIViewController, parent: UIView, frame: CGRect) {
        
        for i in parent.subviews {
            i.isUserInteractionEnabled = false
        }
        
        self.root = root
        self.parent = parent
        self.center = CGPoint(x: frame.width/2.0, y: frame.height/2.0)
        
        self.btnCenter = UIButton()
        self.btnCenter.frame = frame
        self.btnCenter.center = self.center
        self.btnCenter.layoutIfNeeded()
        self.btnCenter.layer.cornerRadius = (self.btnCenter.frame.size.width)/2
        
        self.btnCenter.setTitle("Loh", for: UIControlState())
        self.btnCenter.backgroundColor = UIColor.white
        
        self.btnCenter.isUserInteractionEnabled = true
        self.btnCenter.addTarget(self, action: #selector(CircleMenu.btnCenterPressed), for: UIControlEvents.touchUpInside)
        
        
        self.menu = UIView()
        self.menu.frame.size = CGSize(width: AppTools.screenWidth - 64, height: AppTools.screenWidth - 64)
        self.menu.center = center
        self.menu.layoutIfNeeded()
        self.menu.layer.cornerRadius = (self.menu.frame.size.width)/2
        
        self.menu.isUserInteractionEnabled = false
        
        self.menu.alpha = 1
        self.menu.backgroundColor = UIColor.clear //UIColor.colorWithColor(UIColor.black, alpha: 0.5)
        
        self.menuFrame = self.menu.frame
        let frameCenter = CGPoint(x: self.menuFrame.width/2.0, y: self.menuFrame.height/2.0)
        
        self.topLeft = CGPoint(x: frameCenter.x - (frame.width * 9 / 10), y: frameCenter.y - (frame.height * 9 / 10))
        self.topRight = CGPoint(x: frameCenter.x + (frame.width * 9 / 10), y: frameCenter.y - (frame.height * 9 / 10))
        
        self.btnSell = UIButton()
        self.btnSell.frame = frame
        self.btnSell.center = self.topLeft
        self.btnSell.alpha = 1
        self.btnSell.layoutIfNeeded()
        self.btnSell.layer.cornerRadius = (self.btnSell.frame.size.width)/2
        
        self.btnSell.setTitle("Jual", for: UIControlState())
        self.btnSell.backgroundColor = Theme.ThemeOrange
        
        self.btnSell.isUserInteractionEnabled = true
        self.btnSell.addTarget(self, action: #selector(CircleMenu.btnCenterPressed), for: UIControlEvents.touchUpInside)
        
        self.btnRent = UIButton()
        self.btnRent.frame = frame
        self.btnRent.center = self.topRight
        self.btnRent.alpha = 1
        self.btnRent.layoutIfNeeded()
        self.btnRent.layer.cornerRadius = (self.btnRent.frame.size.width)/2
        
        self.btnRent.setTitle("Sewa", for: UIControlState())
        self.btnRent.backgroundColor = Theme.PrimaryColor
        
        self.btnRent.isUserInteractionEnabled = true
        self.btnRent.addTarget(self, action: #selector(CircleMenu.btnCenterPressed), for: UIControlEvents.touchUpInside)
        
        self.menu.addSubview(btnSell)
        self.menu.addSubview(btnRent)
        
        self.parent.addSubview(menu)
        self.parent.addSubview(btnCenter)
        
        self.root.view.bringSubview(toFront: btnCenter)
        self.root.view.bringSubview(toFront: btnSell)
        self.root.view.bringSubview(toFront: btnRent)
    }
    
    func btnCenterPressed() {
        if self.isOpen {
            self.close()
        } else {
            self.open()
        }
        
        self.isOpen = !self.isOpen
    }
    
    func open() {
        self.menu.alpha = 1
    }
    
    func close() {
        self.menu.alpha = 0
    }
    
    func btnSellPressed() {
        
    }
    
    func btnRentPressed() {
        
    }
}
