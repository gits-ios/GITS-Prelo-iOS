//
//  CircleMenu.swift
//  Prelo
//
//  Created by Djuned on 8/20/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class CircleMenu: UIView {
    
    var overlayTotal: UIView!
    
    var btnCenter: UIButton!
    
    var menu: UIView!
    var btnSell: UIButton!
    var btnRent: UIButton!
    
    var isOpen = false

    //var center: CGPoint!
    var root: BaseViewController!
    var parent: UIView!
    
    var topLeft: CGPoint!
    var topRight: CGPoint!
    var menuFrame: CGRect!
    var frameCenter: CGPoint!
    
    var screenBefore = ""
    var isHideNavBar = false
    
    func setupView(_ root: BaseViewController, name: String, parent: UIView, frame: CGRect) {
        
        for i in parent.subviews {
            i.isUserInteractionEnabled = false
        }
        
        self.isUserInteractionEnabled = false
        
        // Try
        self.overlayTotal = UIView()
        self.overlayTotal.frame = UIScreen.main.bounds
        self.overlayTotal.backgroundColor = UIColor.colorWithColor(UIColor.lightGray, alpha: 0.5)
        self.overlayTotal.frame.origin = CGPoint(x: 0, y: AppTools.screenHeight)
        
        self.root = root
        self.parent = parent
        self.center = CGPoint(x: frame.width/2.0, y: frame.height/2.0)
        self.screenBefore = name
        
        self.btnCenter = UIButton()
        self.btnCenter.frame = frame
        self.btnCenter.center = self.center
        self.btnCenter.layoutIfNeeded()
        //self.btnCenter.layer.cornerRadius = (self.btnCenter.frame.size.width)/2
        self.btnCenter.createBordersWithColor(UIColor.lightGray, radius: (self.btnCenter.frame.size.width)/2, width: 1.0)
        
        self.btnCenter.setTitle("Loh", for: UIControlState())
        self.btnCenter.backgroundColor = UIColor.white
        
        self.btnCenter.isUserInteractionEnabled = true
        self.btnCenter.addTarget(self.root, action: #selector(self.root.btnCenterPressed), for: UIControlEvents.touchUpInside)
        
        self.btnCenter.layoutIfNeeded()
        self.btnCenter.clipsToBounds = true
        
        let width: CGFloat = 320 // AppTools.screenWidth
        
        self.menu = UIView()
        self.menu.frame.size = CGSize(width: width - 64, height: width - 64)
        self.menu.center = CGPoint(x: width / 2.0, y: AppTools.screenHeight - (self.isHideNavBar ? 0 : 64) - ((width - 256) / 2.0))
        self.menu.layoutIfNeeded()
        self.menu.layer.cornerRadius = (self.menu.frame.size.width)/2
        
        self.menu.isUserInteractionEnabled = true
        
        print(menu.frame)
        
        self.menu.alpha = 0
        self.menu.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.5)
        
        self.menu.layoutIfNeeded()
        self.menu.clipsToBounds = true
        
        self.menuFrame = self.menu.frame
        self.menu.frame = self.parent.frame
        self.frameCenter = CGPoint(x: self.menuFrame.width/2.0, y: self.menuFrame.height/2.0)
        
        self.topLeft = CGPoint(x: frameCenter.x - (frame.width * 9 / 10), y: frameCenter.y - (frame.height * 9 / 10))
        self.topRight = CGPoint(x: frameCenter.x + (frame.width * 9 / 10), y: frameCenter.y - (frame.height * 9 / 10))
        
        self.btnSell = UIButton()
        self.btnSell.frame = frame
        self.btnSell.center = self.center //frameCenter //self.topLeft
        self.btnSell.alpha = 0
        self.btnSell.layoutIfNeeded()
        self.btnSell.layer.cornerRadius = (self.btnSell.frame.size.width)/2
        
        self.btnSell.setTitle("Jual", for: UIControlState())
        self.btnSell.backgroundColor = Theme.ThemeOrange
        
        self.btnSell.isUserInteractionEnabled = true
        self.btnSell.addTarget(self.root, action: #selector(self.root.btnSellPressed), for: UIControlEvents.touchUpInside)
        
        self.btnSell.layoutIfNeeded()
        self.btnSell.clipsToBounds = true
        
        self.btnRent = UIButton()
        self.btnRent.frame = frame
        self.btnRent.center = self.center //frameCenter //self.topRight
        self.btnRent.alpha = 0
        self.btnRent.layoutIfNeeded()
        self.btnRent.layer.cornerRadius = (self.btnRent.frame.size.width)/2
        
        self.btnRent.setTitle("Sewa", for: UIControlState())
        self.btnRent.backgroundColor = Theme.PrimaryColor
        
        self.btnRent.isUserInteractionEnabled = true
        self.btnRent.addTarget(self.root, action: #selector(self.root.btnRentPressed), for: UIControlEvents.touchUpInside)
        
        self.btnRent.layoutIfNeeded()
        self.btnRent.clipsToBounds = true
        
        self.menu.addSubview(btnSell)
        self.menu.addSubview(btnRent)
        
        self.parent.addSubview(btnCenter)
        
        self.parent.superview?.addSubview(overlayTotal)
        self.parent.superview?.addSubview(menu)
        self.parent.superview?.bringSubview(toFront: self.parent)
        
        // bug fix
        self.isOpen = true
        self.btnCenterPressed()
        
        // first init
        let addTour = UserDefaults.standard.bool(forKey: "newAddProductTourV3")
        if (addTour == false) {
            UserDefaults.standard.set(true, forKey: "newAddProductTourV3")
            UserDefaults.standard.synchronize()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.btnCenterPressed()
            }
        }
    }
    
    func btnCenterPressed() {
        if self.isOpen {
            self.close()
        } else {
            self.open()
        }
    }
    
    func open() {
        self.menu.alpha = 1
        
        self.menu.addCornerRadiusAnimation(from: self.parent.frame.width / 2, to: self.menuFrame.width / 2, duration: 0.3)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.btnSell.center = self.topLeft
            self.btnRent.center = self.topRight
            
            self.menu.frame = self.menuFrame
            self.overlayTotal.frame.origin = CGPoint(x: 0, y: 0)
            
            self.btnSell.alpha = 1
            self.btnRent.alpha = 1
            
            self.isOpen = true
        })
    }
    
    func close() {
        
        self.menu.addCornerRadiusAnimation(from: self.menuFrame.width / 2, to: self.parent.frame.width / 2, duration: 0.3)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.btnSell.center = self.center //self.frameCenter
            self.btnRent.center = self.center //self.frameCenter
            
            self.menu.frame = self.parent.frame
            self.overlayTotal.frame.origin = CGPoint(x: 0, y: AppTools.screenHeight)
            
            self.btnSell.alpha = 0
            self.btnRent.alpha = 0
            
            self.menu.alpha = 0
            self.isOpen = false
        })
    }
    
    func btnSellPressed() {
        let addProduct3VC = Bundle.main.loadNibNamed(Tags.XibNameAddProduct3, owner: nil, options: nil)?.first as! AddProductViewController3
        addProduct3VC.screenBeforeAddProduct = self.screenBefore
        
        //addProduct3VC.product.addProductType = .sell // default
        
        self.close()
        
        self.root.navigationController?.pushViewController(addProduct3VC, animated: true)
    }
    
    func btnRentPressed() {
        let addProduct3VC = Bundle.main.loadNibNamed(Tags.XibNameAddProduct3, owner: nil, options: nil)?.first as! AddProductViewController3
        addProduct3VC.screenBeforeAddProduct = self.screenBefore
        
        addProduct3VC.product.addProductType = .rent
        
        self.close()
        
        self.root.navigationController?.pushViewController(addProduct3VC, animated: true)
    }
}

extension UIView
{
    func addCornerRadiusAnimation(from: CGFloat, to: CGFloat, duration: CFTimeInterval)
    {
        let animation = CABasicAnimation(keyPath:"cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        self.layer.add(animation, forKey: "cornerRadius")
        self.layer.cornerRadius = to
    }
}
