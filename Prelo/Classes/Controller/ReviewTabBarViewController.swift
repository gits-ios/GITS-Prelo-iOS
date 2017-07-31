//
//  ReviewTabBarViewController.swift
//  Prelo
//
//  Created by Prelo on 7/17/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//
import UIKit

protocol ReviewTabBarDelegate: class {
    func setFromDraftOrNew(_ isFromDraft: Bool)
    func getFromDraftOrNew() -> Bool
}

class ReviewTabBarViewController : BaseViewController, CarbonTabSwipeDelegate, ReviewTabBarDelegate {
   
    var averageBuyer : Float = 0.0
    var averageSeller : Float = 0.0
    
    // MARK: - Delegate
    func setFromDraftOrNew(_ isFromDraft: Bool) {
        self.isFromDraft = isFromDraft
    }
    
    func getFromDraftOrNew() -> Bool {
        return self.isFromDraft
    }

    
    var tabSwipe : CarbonTabSwipeNavigation?
    var reviewAsSellerVC : ReviewAsSellerViewController?
    var reviewAsBuyerVC : ReviewAsBuyerViewController?
    
    var isFromDraft = false
    
    var isNeedReload = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ini average nya")
        print(averageBuyer)
        print(averageSeller)
        reviewAsSellerVC = Bundle.main.loadNibNamed(Tags.XibNameReviewAsSeller, owner: nil, options: nil)?.first as! ReviewAsSellerViewController
        //reviewAsSellerVC?.adapt(averageSeller)
        
        reviewAsBuyerVC = Bundle.main.loadNibNamed(Tags.XibNameReviewAsBuyer, owner: nil, options: nil)?.first as! ReviewAsBuyerViewController
        //reviewAsBuyerVC?.adapt(averageBuyer)
        
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
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ReviewTabBarViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    func back(sender: UIBarButtonItem) {
        // Perform your custom actions
        // ...
        // Go back to the previous ViewController
        self.dismiss(animated: true, completion: nil)
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
    
    override func viewWillAppear(_ animated: Bool) {
        if isNeedReload {
            print("masuk sini kok")
            print("ini average nya")
            print(averageBuyer)
            print(averageSeller)
            reviewAsSellerVC = Bundle.main.loadNibNamed(Tags.XibNameReviewAsSeller, owner: nil, options: nil)?.first as! ReviewAsSellerViewController
            reviewAsSellerVC?.reload = true
            reviewAsSellerVC?.averageSeller = averageSeller
            reviewAsSellerVC?.adapt(averageSeller)
            reviewAsSellerVC?.tableView.reloadData()
            reviewAsBuyerVC = Bundle.main.loadNibNamed(Tags.XibNameReviewAsBuyer, owner: nil, options: nil)?.first as! ReviewAsBuyerViewController
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
