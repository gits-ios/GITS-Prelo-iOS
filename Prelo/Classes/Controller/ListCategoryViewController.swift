//
//  ViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
//import CarbonKit

class ListCategoryViewController: BaseViewController, CarbonTabSwipeDelegate, UIScrollViewDelegate
{

    var tabSwipe : CarbonTabSwipeNavigation?
    var first = NO
    var categories : JSON?
    var dummyGrid : DummyGridViewController!
    
    @IBOutlet var scrollCategoryName: UIScrollView!
    @IBOutlet var scrollView : UIScrollView!
    
    var categoriesFix : [JSON] = []
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Mixpanel.trackPageVisit("Home", otherParam: ["Category" : "All"])
        Mixpanel.sharedInstance().timeEvent(MixpanelEvent.CategoryBrowsed)
        
        scrollView.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "grandRefresh", name: "refreshHome", object: nil)
//        setupScroll()
        // Do any additional setup after loading the view, typically from a nib.
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: "refreshcategory", object: nil)
//        
//        setupNormalOptions()
//        setupTitle()
//        let cache: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("pre_categories")
//        if (cache != nil) {
//            setupCategory()
//        } else {
//            
//        }
//        getCategory()
    }
    
    func grandRefresh()
    {
        listItemViews.removeAll(keepCapacity: false)
        
        for v in self.contentView?.subviews as! [UIView]
        {
            v.removeFromSuperview()
        }
        
        categoryNames.removeAll(keepCapacity: false)
        for v in self.contentCategoryNames?.subviews as! [UIView]
        {
            if (v != categoryIndicator)
            {
                v.removeFromSuperview()
            }
        }
        
        getCategory()
    }
    
    var contentView : UIView?
    var listItemViews : [UIView] = []
    func addChilds(count : Int)
    {
        var d = ["scroll":scrollView, "master":self.view]
        if let c = contentView
        {
            
        } else
        {
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.pagingEnabled = true
            let pContentView = UIView()
            pContentView.backgroundColor = UIColor.redColor()
            scrollView.addSubview(pContentView)
            
            pContentView.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            d["content"] = pContentView
            scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[content]-0-|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[content]-0-|", options: nil, metrics: nil, views: d))
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[content(==scroll)]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            contentView = pContentView
        }
        
        var colors = [UIColor.blueColor(), UIColor.clearColor()]
        
        var lastView : UIView?
        for i in 0...count-1
        {
            let li:ListItemViewController = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
            li.previousController = self.previousController
            
            li.category = categoriesFix[i]
            
            let v = li.view
            v.setTranslatesAutoresizingMaskIntoConstraints(false)
//            v.backgroundColor = colors.objectAtCircleIndex(i)
            contentView?.addSubview(v)
            self.addChildViewController(li)
            d["v"] = v
            if let lv = lastView
            {
                d["lv"] = lv
                contentView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("[lv]-0-[v]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
                
            } else {
                contentView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[v]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            }
            
            contentView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[v]-0-|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[v(==scroll)]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("[v(==master)]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            
            if (i == count-1)
            {
                contentView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("[v]-0-|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            }
            
            lastView = v
            listItemViews.append(v)
        }
        
        scrollView.layoutIfNeeded()
        contentView?.layoutIfNeeded()
        
        addCategoryNames(count)
    }
    
    var contentCategoryNames : UIView?
    var categoryIndicator : UIView?
    var indicatorWidth : NSLayoutConstraint?
    var indicatorMargin : NSLayoutConstraint?
    var categoryNames : [UIView] = []
    func addCategoryNames(count : Int)
    {
        var d = ["scroll":scrollCategoryName, "master":self.view]
        if let c = contentCategoryNames
        {
            
        } else
        {
            scrollCategoryName.showsHorizontalScrollIndicator = false
            scrollCategoryName.backgroundColor = UIColor.whiteColor()
            let pContentView = UIView()
            scrollCategoryName.addSubview(pContentView)
            
            pContentView.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            d["content"] = pContentView
            scrollCategoryName.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[content]-0-|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            scrollCategoryName.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[content]-0-|", options: nil, metrics: nil, views: d))
            pContentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[content(==44)]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            contentCategoryNames = pContentView
        }
        
        if (categoryIndicator == nil)
        {
            categoryIndicator = UIView()
            categoryIndicator?.setTranslatesAutoresizingMaskIntoConstraints(false)
            categoryIndicator?.backgroundColor = Theme.ThemeOrange
            contentCategoryNames?.addSubview(categoryIndicator!)
            d["indicator"] = categoryIndicator
            contentCategoryNames?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[indicator]-0-|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            categoryIndicator?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[indicator(==4)]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            indicatorMargin = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[indicator]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d).first as? NSLayoutConstraint
            indicatorWidth = NSLayoutConstraint.constraintsWithVisualFormat("[indicator(==100)]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d).first as? NSLayoutConstraint
            contentCategoryNames?.addConstraint(indicatorMargin!)
            categoryIndicator?.addConstraint(indicatorWidth!)
        }
        
        var colors = [UIColor.blueColor(), UIColor.whiteColor()]
        
        var lastView : UIView?
        for i in 0...count-1
        {
            let button = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            button.setTitleColor(Theme.GrayDark)
            button.titleLabel?.font = UIFont.systemFontOfSize(15)
            if let name = categoriesFix[i]["name"].string {
                button.setTitle(name, forState: UIControlState.Normal)
            }
            
            button.sizeToFit()
            
            button.addTarget(self, action: "categoryButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
            
            let width = button.width
            let v = button
            v.tag = i
            v.setTranslatesAutoresizingMaskIntoConstraints(false)
            contentCategoryNames?.addSubview(v)
            d["v"] = v
            if let lv = lastView
            {
                d["lv"] = lv
                contentCategoryNames?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("[lv]-20-[v]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
                
            } else {
                contentCategoryNames?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-20-[v]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            }
            
            contentCategoryNames?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[v]-0-|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[v(==44)]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("[v(==\(width))]", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            
            if (i == count-1)
            {
            contentCategoryNames?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("[v]-20-|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: d))
            }
            
            lastView = v
            categoryNames.append(v)
        }
        
        scrollCategoryName.layoutIfNeeded()
        contentCategoryNames?.layoutIfNeeded()
        
        setCurrentTab((categoryNames.count > 1) ? 0 : 0)
    }
    
    var currentTabIndex = 0
    func setCurrentTab(index : Int)
    {
        currentTabIndex = index
        if (index >= categoryNames.count)
        {
            return
        }
        
        let x = listItemViews[index].x
        let p = CGPointMake(x, 0)
        
        scrollView.setContentOffset(p, animated: true)
        
        adjustIndicator(index)
    }
    
    func adjustIndicator(index : Int)
    {
        let v = categoryNames[index]
        indicatorMargin?.constant = v.x
        indicatorWidth?.constant = v.width
        
        UIView.animateWithDuration(0.5, animations: {
            self.categoryIndicator?.layoutIfNeeded()
        })
    }
    
    func categoryButtonAction(sender : UIView)
    {
        let index = sender.tag
        setCurrentTab(index)
        
        centerCategoryView(currentTabIndex)
    }
    
    func centerCategoryView(index : Int)
    {
        let v = categoryNames[index]
        
        let p = v.frame.origin
        let px = self.scrollCategoryName.convertPoint(p, toView:nil)
        
        let centeredX = (UIScreen.mainScreen().bounds.width-v.width)/2
        var finalP = CGPointMake(p.x-centeredX, 0)
        
        if (finalP.x < 0)
        {
            finalP.x = 0
        }
        
        if (finalP.x > scrollCategoryName.contentSize.width-scrollCategoryName.width)
        {
            finalP.x = scrollCategoryName.contentSize.width-scrollCategoryName.width
        }
        
        if (!(finalP.x < 0) && !(finalP.x > scrollCategoryName.contentSize.width-scrollCategoryName.width))
        {
            scrollCategoryName.setContentOffset(finalP, animated: true)
        }
    }
    
    var lastContentOffset = CGPoint()
    var isPageTracked = false
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let i = Int(scrollView.contentOffset.x / scrollView.width)
        currentTabIndex = i
        centerCategoryView(currentTabIndex)
        adjustIndicator(currentTabIndex)
        
        //println("lastContentOffset = \(lastContentOffset)")
        //println("scrollView.contentOffset = \(scrollView.contentOffset)")
        if (lastContentOffset.x != scrollView.contentOffset.x) {
            isPageTracked = false
        }
        
        // Only track if scrollView did finish the left/right scroll
        if (lastContentOffset.y == scrollView.contentOffset.y && lastContentOffset.x != scrollView.contentOffset.x) {
            if (Int(scrollView.contentOffset.x) % Int(scrollView.width) == 0) {
                let pt = [
                    "Category" : categoriesFix[i]["name"].string!
                ]
                Mixpanel.trackPageVisit("Home", otherParam: pt)
                Mixpanel.trackEvent(MixpanelEvent.CategoryBrowsed, properties: pt)
                isPageTracked = true
            }
        }
        
        lastContentOffset = scrollView.contentOffset
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
//        setCurrentTab((categoryNames.count > 1) ? 1 : 0)
        
        // APNS redirect if any
        let apnsRedirect : String? = NSUserDefaults.standardUserDefaults().objectForKey("apnsredirect") as! String?
        if (apnsRedirect != nil) {
            if (apnsRedirect == "notification") {
                self.launchNotifPage()
            } else if (apnsRedirect == "inbox") {
                let i = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdInbox) as! InboxViewController
                self.navigationController?.pushViewController(i, animated: true)
            }
            NSUserDefaults.standardUserDefaults().removeObjectForKey("apnsredirect")
        }
    }
    
    func getCategory()
    {
        request(References.CategoryList)
            .responseString { req, resp, string, err in
                if (string != nil)
                {
                    println(string)
                } else
                {
                    println(err)
                }
            }
            .responseJSON { _, _, JSON, err in
                if (err != nil) {
                    println(err)
                } else {
                    println(JSON)
                    NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(JSON!), forKey: "pre_categories")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    self.setupCategory()
                }
        }
    }
    
    func setupCategory()
    {
        let data = NSUserDefaults.standardUserDefaults().objectForKey("pre_categories") as? NSData
        categories = JSON(NSKeyedUnarchiver.unarchiveObjectWithData(data!)!)
        
        if let arr = categories!["_data"][0]["children"].arrayObject // punya children
        {
            
        } else { // gak punya, gak dipake
            return
        }
        
        // Kumpulkan category sambil mengurutkan
        let level1 = categories!["_data"][0]["children"]
        
        categoriesFix = []
        var categoriesDummy : [JSON] = []
        var idxCateg1 : Int?
        var idxCateg2 : Int?
        var idxCateg3 : Int?
        for (index : String, child : JSON) in level1 {
            let categName = child["name"].string
            let categId = child["_id"].string
            if (categName != nil && categId != nil) {
                categoriesDummy.append(child)
                if (categId == NSUserDefaults.categoryPref1()) {
                    idxCateg1 = index.toInt()
                } else if (categId == NSUserDefaults.categoryPref2()) {
                    idxCateg2 = index.toInt()
                } else if (categId == NSUserDefaults.categoryPref3()) {
                    idxCateg3 = index.toInt()
                }
            }
        }
        // Di sini categoriesDummy berisi array json of child categories
        // Sudah didapatkan ketiga index yang akan ditaruh ke depan
        if (idxCateg1 != nil) {
            categoriesFix.append(categoriesDummy.objectAtCircleIndex(idxCateg1!))
        }
        if (idxCateg2 != nil) {
            categoriesFix.append(categoriesDummy.objectAtCircleIndex(idxCateg2!))
        }
        if (idxCateg3 != nil) {
            categoriesFix.append(categoriesDummy.objectAtCircleIndex(idxCateg3!))
        }
        for (var i = 0; i < categoriesDummy.count; i++) {
            if (i == idxCateg1 || i == idxCateg2 || i == idxCateg3) {
                // Skip
            } else {
                categoriesFix.append(categoriesDummy[i])
            }
        }
        // Di sini 3 kategori terpilih sudah ada di bagian depan categoriesFix
        // Tinggal tambahkan category "All"
        let categAllName = categories!["_data"][0]["name"].string
        let categAllId = categories!["_data"][0]["_id"].string
        if (categAllName != nil && categAllId != nil) {
            categoriesFix.insert(categories!["_data"][0], atIndex: 0)
        }
        print("categoriesFix: [")
        for (var j = 0; j < categoriesFix.count; j++) {
            print(categoriesFix[j]["name"].string!)
            if (j == categoriesFix.count - 1) {
                println("]")
            } else {
                print(", ")
            }
        }
        
        addChilds(categoriesFix.count)
    }
    
    func cikah()
    {
        tabSwipe?.view.hidden = false
        tabSwipe?.currentTabIndex = 1
    }
    
    var refreshed = false
    func refresh()
    {
        if (refreshed == false)
        {
            self.view.hidden = true
            NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "endRefresh", userInfo: nil, repeats: false)
        }
    }
    
    func endRefresh()
    {
        self.view.hidden = false
        refreshed = true
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tabSwipeNavigation(tabSwipe: CarbonTabSwipeNavigation!, viewControllerAtIndex index: UInt) -> UIViewController!
    {
        let v:ListItemViewController = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        v.previousController = self.previousController
        var i = Int(index)
        
        v.category = categoriesFix[i]
        
        return v
    }

}

