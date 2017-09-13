//
//  MyPurchaseViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/14/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class MyPurchaseViewController : BaseViewController, CarbonTabSwipeDelegate {
    
    var tabSwipe : CarbonTabSwipeNavigation?
    var purchaseProcessingVC : BaseViewController?
    var purchaseCompletedVC : BaseViewController?
    
    @IBOutlet weak var viewJualButton: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        purchaseProcessingVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseProcessing, owner: nil, options: nil)?.first as! MyPurchaseProcessingViewController
        
        purchaseCompletedVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseCompleted, owner: nil, options: nil)?.first as! MyPurchaseCompletedViewController
        
        tabSwipe = CarbonTabSwipeNavigation().create(withRootViewController: self, tabNames: ["DIPROSES" as AnyObject, "SELESAI" as AnyObject] as [AnyObject], tintColor: UIColor.white, delegate: self)
        tabSwipe?.addShadow()
        
        tabSwipe?.setNormalColor(Theme.TabNormalColor)
        tabSwipe?.colorIndicator = Theme.PrimaryColorDark
        tabSwipe?.setSelectedColor(Theme.TabSelectedColor)
        
        // Set title
        self.title = "Belanjaan Saya"
        
        // Buat tombol jual menjadi bentuk bulat dan selalu di depan
        viewJualButton.layer.cornerRadius = (viewJualButton.frame.size.width) / 2
        viewJualButton.layer.shadowColor = UIColor.black.cgColor
        viewJualButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewJualButton.layer.shadowOpacity = 0.3
        self.view.bringSubview(toFront: viewJualButton)
    }
    
    @IBAction func sellPressed(_ sender: AnyObject) {
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        add.screenBeforeAddProduct = PageName.MyOrders
        self.navigationController?.pushViewController(add, animated: true)
    }
    
    func tabSwipeNavigation(_ tabSwipe: CarbonTabSwipeNavigation!, viewControllerAt index: UInt) -> UIViewController! {
        if (index == 0) { // Diproses
            return purchaseProcessingVC
        } else if (index == 1) { // Selesai
            return purchaseCompletedVC
        }
        
        // Default
        let v = UIViewController()
        v.view.backgroundColor = UIColor.white
        return v
    }
}
