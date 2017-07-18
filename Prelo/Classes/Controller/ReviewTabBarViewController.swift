//
//  ReviewTabBarViewController.swift
//  Prelo
//
//  Created by Prelo on 7/17/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//
import Foundation

class ReviewTabBarViewController : BaseViewController, CarbonTabSwipeDelegate {
    
    var tabSwipe : CarbonTabSwipeNavigation?
    var reviewAsSellerVC : ReviewAsSellerViewController?
    var reviewAsBuyerVC : BaseViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reviewAsSellerVC = Bundle.main.loadNibNamed(Tags.XibNameReviewAsSeller, owner: nil, options: nil)?.first as! ReviewAsSellerViewController
        
        reviewAsBuyerVC = Bundle.main.loadNibNamed(Tags.XibNameReviewAsBuyer, owner: nil, options: nil)?.first as! MyPurchaseCompletedViewController
        
        tabSwipe = CarbonTabSwipeNavigation().create(withRootViewController: self, tabNames: ["SEBAGAI PENJUAL" as AnyObject, "SEBAGAI PEMBELI" as AnyObject] as [AnyObject], tintColor: UIColor.white, delegate: self)
        tabSwipe?.addShadow()
        
        tabSwipe?.setNormalColor(Theme.TabNormalColor)
        tabSwipe?.colorIndicator = Theme.PrimaryColorDark
        tabSwipe?.setSelectedColor(Theme.TabSelectedColor)
        
        // Set title
        self.title = "REVIEW"
        
        // swipe gesture for carbon (pop view)
        let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
        vwLeft.backgroundColor = UIColor.clear
        self.view.addSubview(vwLeft)
        self.view.bringSubview(toFront: vwLeft)
    }
    var first = true
    
    var shouldSkipBack = true
    
    override func viewDidAppear(_ animated: Bool) {
        if first && shouldSkipBack
        {
            first = false
            super.viewDidAppear(animated)
            var m = self.navigationController?.viewControllers
            m?.remove(at: (m?.count)!-2)
            m?.remove(at: (m?.count)!-2)
            self.navigationController?.viewControllers = m!
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var cs = [UIColor.blue, UIColor.red]
    func tabSwipeNavigation(_ tabSwipe: CarbonTabSwipeNavigation!, viewControllerAt index: UInt) -> UIViewController!
    {
//        if (index == 0)
//        {
//            return productSell
//        }
//        else if (index == 1)
//        {
//            return productTransaction
//        }
        
        let v = UIViewController()
        v.view.backgroundColor = cs.objectAtCircleIndex(Int(index))
        return v
    }
    
    
}
