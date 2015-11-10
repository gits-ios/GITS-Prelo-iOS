//
//  MyProductViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class MyProductViewController: BaseViewController, CarbonTabSwipeDelegate {
    
    var tabSwipe : CarbonTabSwipeNavigation?
    
    var productSell : BaseViewController?
    var productProcessing : BaseViewController?
    var productCompleted : BaseViewController?

    @IBOutlet weak var viewJualButton: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productSell = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdMyProductSell) as? BaseViewController
        productSell?.previousController = self
        
        productProcessing = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyProductProcessing, owner: nil, options: nil).first as! MyProductProcessingViewController
        
        productCompleted = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyProductCompleted, owner: nil, options: nil).first as! MyProductCompletedViewController
        
        // Do any additional setup after loading the view.
        tabSwipe = CarbonTabSwipeNavigation.alloc().createWithRootViewController(self, tabNames: ["PRODUK", "DIPROSES", "SELESAI"] as [AnyObject], tintColor: UIColor.whiteColor(), delegate: self)
        tabSwipe?.addShadow()
        
        tabSwipe?.setNormalColor(Theme.TabNormalColor)
        tabSwipe?.colorIndicator = Theme.PrimaryColorDark
        tabSwipe?.setSelectedColor(Theme.TabSelectedColor)
        
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: " Produk Saya", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
        
        // Buat tombol jual menjadi bentuk bulat dan selalu di depan
        viewJualButton.layer.cornerRadius = (viewJualButton.frame.size.width) / 2
        viewJualButton.layer.shadowColor = UIColor.blackColor().CGColor
        viewJualButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewJualButton.layer.shadowOpacity = 0.3
        self.view.bringSubviewToFront(viewJualButton)
    }
    
    var first = true
    
    var shouldSkipBack = true
    
    override func viewDidAppear(animated: Bool) {
        if first && shouldSkipBack
        {
            first = false
            super.viewDidAppear(animated)
            var m = self.navigationController?.viewControllers
            m?.removeAtIndex((m?.count)!-2)
            self.navigationController?.viewControllers = m!
        }
    }

    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var cs = [UIColor.blueColor(), UIColor.redColor()]
    func tabSwipeNavigation(tabSwipe: CarbonTabSwipeNavigation!, viewControllerAtIndex index: UInt) -> UIViewController!
    {
        if (index == 0)
        {
            return productSell
        }
        else if (index == 1)
        {
            return productProcessing
        }
        else if (index == 2)
        {
            return productCompleted
        }
        
        let v = UIViewController()
        v.view.backgroundColor = cs.objectAtCircleIndex(Int(index))
        return v
    }
    
    @IBAction func jualPressed(sender: AnyObject) {
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        self.navigationController?.pushViewController(add, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
