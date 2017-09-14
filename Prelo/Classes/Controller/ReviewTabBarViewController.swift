//
//  ReviewTabBarViewController.swift
//  Prelo
//
//  Created by Prelo on 7/17/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class ReviewTabBarViewController: BaseViewController, CarbonTabSwipeDelegate {
   
    var averageBuyer : Float = 0.0
    var averageSeller : Float = 0.0

    var sellerId = ""
    
    var tabSwipe : CarbonTabSwipeNavigation?
    var reviewAsSellerVC : ReviewAsSellerViewController?
    var reviewAsBuyerVC : ReviewAsBuyerViewController?
    
    var isFirst = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        reviewAsSellerVC = Bundle.main.loadNibNamed(Tags.XibNameReviewAsSeller, owner: nil, options: nil)?.first as? ReviewAsSellerViewController
        
        reviewAsBuyerVC = Bundle.main.loadNibNamed(Tags.XibNameReviewAsBuyer, owner: nil, options: nil)?.first as? ReviewAsBuyerViewController
        
        tabSwipe = CarbonTabSwipeNavigation().create(withRootViewController: self, tabNames: ["SEBAGAI PENJUAL" as AnyObject, "SEBAGAI PEMBELI" as AnyObject] as [AnyObject], tintColor: UIColor.white, delegate: self)
        tabSwipe?.addShadow()
        
        tabSwipe?.setNormalColor(Theme.TabNormalColor)
        tabSwipe?.colorIndicator = Theme.PrimaryColorDark
        tabSwipe?.setSelectedColor(Theme.TabSelectedColor)
        
        // Set title
        self.title = "Review"
        
        // swipe gesture for carbon (pop view)
        let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
        vwLeft.backgroundColor = UIColor.clear
        self.view.addSubview(vwLeft)
        self.view.bringSubview(toFront: vwLeft)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isFirst {
            reviewAsSellerVC?.averageSeller = averageSeller
            reviewAsBuyerVC?.averageBuyer = averageBuyer
            
            reviewAsSellerVC?.sellerId = self.sellerId
            reviewAsBuyerVC?.sellerId = self.sellerId
            
            reviewAsSellerVC?.setup()
            reviewAsBuyerVC?.setup()
            
            isFirst = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var cs = [UIColor.blue, UIColor.red]
    func tabSwipeNavigation(_ tabSwipe: CarbonTabSwipeNavigation!, viewControllerAt index: UInt) -> UIViewController!
    {
        if (index == 0)
        {
            return reviewAsSellerVC
        }
        else if (index == 1)
        {
            return reviewAsBuyerVC
        }
        
        let v = UIViewController()
        v.view.backgroundColor = cs.objectAtCircleIndex(Int(index))
        return v
    }
    
    
}
