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
    
    @IBOutlet weak var viewJualButton: UIView!
    
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
        
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: " Pembelian Saya", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
        
        // Buat tombol jual menjadi bentuk bulat dan selalu di depan
        viewJualButton.layer.cornerRadius = (viewJualButton.frame.size.width) / 2
        viewJualButton.layer.shadowColor = UIColor.blackColor().CGColor
        viewJualButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewJualButton.layer.shadowOpacity = 0.3
        viewJualButton.layer.zPosition = CGFloat.max;
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
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
