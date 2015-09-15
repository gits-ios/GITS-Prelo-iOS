//
//  MyPurchaseViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/14/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyPurchaseViewController : BaseViewController, CarbonTabSwipeDelegate {
    
    var tabSwipe : CarbonTabSwipeNavigation?
    var purchaseProcessingVC : BaseViewController?
    var purchaseCompletedVC : BaseViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        purchaseProcessingVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchaseProcessing, owner: nil, options: nil).first as! MyPurchaseProcessingViewController
        purchaseProcessingVC?.previousController = self
        
        purchaseCompletedVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchaseCompleted, owner: nil, options: nil).first as! MyPurchaseCompletedViewController
        
        tabSwipe = CarbonTabSwipeNavigation.alloc().createWithRootViewController(self, tabNames: ["DIPROSES", "SELESAI"] as [AnyObject], tintColor: UIColor.whiteColor(), delegate: self)
        tabSwipe?.addShadow()
        
        tabSwipe?.setNormalColor(Theme.TabNormalColor)
        tabSwipe?.colorIndicator = Theme.PrimaryColorDark
        tabSwipe?.setSelectedColor(Theme.TabSelectedColor)
    }
    
    func tabSwipeNavigation(tabSwipe: CarbonTabSwipeNavigation!, viewControllerAtIndex index: UInt) -> UIViewController! {
        if (index == 0) { // Diproses
            return purchaseProcessingVC
        } else if (index == 1) { // Selesai
            return purchaseCompletedVC
        }
        
        // Default
        let v = UIViewController()
        v.view.backgroundColor = UIColor.whiteColor()
        return v
    }
}
