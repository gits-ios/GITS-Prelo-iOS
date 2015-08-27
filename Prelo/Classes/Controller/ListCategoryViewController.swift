//
//  ViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
//import CarbonKit

class ListCategoryViewController: BaseViewController, CarbonTabSwipeDelegate {

    var tabSwipe : CarbonTabSwipeNavigation?
    var first = NO
    var categories : JSON?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupNormalOptions()
        setupTitle()
        let cache: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("pre_categories")
        if (cache != nil) {
            setupCategory()
        } else {
            
        }
        getCategory()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    func getCategory()
    {
        request(References.CategoryList)
            .responseJSON { _, _, JSON, err in
                if (err != nil) {
                    println(err)
                } else {
                    println(JSON)
                    NSUserDefaults.standardUserDefaults().setObject(JSON, forKey: "pre_categories")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    self.setupCategory()
                }
        }
    }
    
    func setupCategory()
    {
        categories = JSON(NSUserDefaults.standardUserDefaults().objectForKey("pre_categories")!)
        
        let level1 = categories!["_data"][0]["children"]
        
        let tabs = NSMutableArray()
        for (index : String, child : JSON) in level1
        {
            if let name = child["name"].string
            {
                tabs.addObject(name.uppercaseString)
            }
        }
        
        tabSwipe = CarbonTabSwipeNavigation.alloc().createWithRootViewController(self, tabNames: tabs as [AnyObject], tintColor: UIColor.whiteColor(), delegate: self)
        tabSwipe?.addShadow()
        
        tabSwipe?.setNormalColor(Theme.TabNormalColor)
        tabSwipe?.colorIndicator = Theme.PrimaryColorDark
        tabSwipe?.setSelectedColor(Theme.TabSelectedColor)
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "cikah", userInfo: nil, repeats: false)
        tabSwipe?.view.hidden = true
    }
    
    func cikah()
    {
        tabSwipe?.view.hidden = false
        tabSwipe?.currentTabIndex = 1
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tabSwipeNavigation(tabSwipe: CarbonTabSwipeNavigation!, viewControllerAtIndex index: UInt) -> UIViewController!
    {
        let v:ListItemViewController = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        
        let i = Int(index)
        
        let arr = categories!["_data"][0]["children"]
        
        v.category = arr[i]
        
        return v
    }

}

