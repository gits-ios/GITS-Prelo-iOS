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
    var pinchIn : UIPinchGestureRecognizer!
    
    @IBOutlet var scrollCategoryName: UIScrollView!
    @IBOutlet var scrollView : UIScrollView!
    
    var categoriesFix : [JSON] = []
    
    // Coachmark
    var vwCoachmark : UIView?
    var imgCoachmarkPinch : UIImageView?
    var imgCoachmarkSpread : UIImageView?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        pinchIn = UIPinchGestureRecognizer(target: self, action: "pinchedIn:")
        self.view.addGestureRecognizer(pinchIn)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.Home, otherParam: ["Category" : "All"])
        Mixpanel.sharedInstance().timeEvent(MixpanelEvent.CategoryBrowsed)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Home)
        
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
    
    var firstPinch : CGFloat = 0
    func pinchedIn(p : UIPinchGestureRecognizer)
    {
        if (p.state == UIGestureRecognizerState.Began)
        {
            firstPinch = p.scale
            println("Start Scale : " + String(stringInterpolationSegment: p.scale))
        } else if (p.state == UIGestureRecognizerState.Ended)
        {
            println("End Scale : " + String(stringInterpolationSegment: p.scale) + " -> " + String(stringInterpolationSegment: firstPinch))
            
            if (abs(firstPinch - p.scale) > 0.3)
            {
                // firstPinch < p.scale == pinched out / zoom in
                for v in self.childViewControllers
                {
                    if let i = v as? ListItemViewController
                    {
                        i.pinch(firstPinch < p.scale)
                    }
                }
            }
        }
    }
    
    func grandRefresh()
    {
        listItemViews.removeAll(keepCapacity: false)
        
        if (contentView != nil) {
            for v in self.contentView!.subviews as! [UIView]
            {
                v.removeFromSuperview()
            }
        }
        
        categoryNames.removeAll(keepCapacity: false)
        if (contentCategoryNames != nil) {
            for v in self.contentCategoryNames?.subviews as! [UIView]
            {
                if (v != categoryIndicator)
                {
                    v.removeFromSuperview()
                }
            }
        }
        
//        getCategory()
        getFullcategory()
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
        
        // Coachmark
        let coachmarkDone : Bool? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.CoachmarkBrowseDone) as! Bool?
        if (coachmarkDone != true && vwCoachmark == nil) {
            let screenSize : CGRect = UIScreen.mainScreen().bounds
            vwCoachmark = UIView(frame: screenSize, backgroundColor: UIColor.colorWithColor(UIColor.blackColor(), alpha: 0.7))
            imgCoachmarkPinch = UIImageView(image: UIImage(named: "cchmrk_pinch"))
            let imgCoachmarkPinchSize : CGSize = CGSizeMake(180, 134)
            imgCoachmarkPinch?.frame = CGRectMake((screenSize.width / 2) - (imgCoachmarkPinchSize.width / 2), (screenSize.height / 2) - (imgCoachmarkPinchSize.height / 2), imgCoachmarkPinchSize.width, imgCoachmarkPinchSize.height)
            imgCoachmarkSpread = UIImageView(image: UIImage(named: "cchmrk_spread"))
            let imgCoachmarkSpreadSize : CGSize = CGSizeMake(180, 136)
            imgCoachmarkSpread?.frame = CGRectMake((screenSize.width / 2) - (imgCoachmarkSpreadSize.width / 2), (screenSize.height / 2) - (imgCoachmarkSpreadSize.height / 2), imgCoachmarkSpreadSize.width, imgCoachmarkSpreadSize.height)
            
            let btnCoachmark : UIButton = UIButton(frame: screenSize)
            btnCoachmark.addTarget(self, action: "btnCoachmarkPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            
            if (vwCoachmark != nil && imgCoachmarkPinch != nil && imgCoachmarkSpread != nil) {
                vwCoachmark!.addSubview(imgCoachmarkPinch!)
                vwCoachmark!.addSubview(imgCoachmarkSpread!)
                imgCoachmarkSpread!.hidden = true
                vwCoachmark!.addSubview(btnCoachmark)
                //UIApplication.sharedApplication().keyWindow?.addSubview(vwCoachmark!)
                if let kumangTabBarVC = self.previousController as? KumangTabBarViewController {
                    kumangTabBarVC.view.addSubview(vwCoachmark!)
                }
                //self.view.addSubview(vwCoachmark!)
            }
        }
        
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
                Mixpanel.trackPageVisit(PageName.Home, otherParam: pt)
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
        
        // Redirect if any
        let redirectFromHome : String? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.RedirectFromHome) as! String?
        if (redirectFromHome != nil) {
            if (redirectFromHome == PageName.MyOrders) {
                let myPurchaseVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchase, owner: nil, options: nil).first as! MyPurchaseViewController
                self.previousController?.navigationController?.pushViewController(myPurchaseVC, animated: true)
            } else if (redirectFromHome == PageName.UnpaidTransaction) {
                let paymentConfirmationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil).first as! PaymentConfirmationViewController
                self.previousController!.navigationController?.pushViewController(paymentConfirmationVC, animated: true)
            }
            NSUserDefaults.standardUserDefaults().removeObjectForKey(UserDefaultsKey.RedirectFromHome)
        }
    }
    
    func getFullcategory()
    {
        request(References.CategoryList).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Category List")) {
                NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(res!), forKey: "pre_categories")
                NSUserDefaults.standardUserDefaults().synchronize()
                self.getCategory()
            }
        }
    }
    
    func getCategory()
    {
        request(References.HomeCategories)
            .responseString { req, resp, string, err in
                if (string != nil)
                {
                    println(string)
                } else
                {
                    println(err)
                }
            }
            .responseJSON { req, resp, res, err in
                if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Category Home")) {
                    NSUserDefaults.standardUserDefaults().setObject(NSKeyedArchiver.archivedDataWithRootObject(res!), forKey: "pre_categories")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    self.setupCategory()
                }
        }
    }
    
    func setupCategory()
    {
        let data = NSUserDefaults.standardUserDefaults().objectForKey("pre_categories") as? NSData
        categories = JSON(NSKeyedUnarchiver.unarchiveObjectWithData(data!)!)
        
        // FIXME: kondisi kalo user ga login, harusnya categorypref ditaro depan
//        if (User.IsLoggedIn) {
            categoriesFix = categories!["_data"].arrayValue
            addChilds(categoriesFix.count)
//        } else {
//            let categoriesData = categories!["_data"].arrayValue
//            
//        }
        
        /* TO BE DELETED, salah penggunaan endpoint
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
        
        addChilds(categoriesFix.count)*/
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
    
    // MARK: - Coachmark
    
    func btnCoachmarkPressed(sender: UIButton!) {
        if (imgCoachmarkSpread!.hidden) {
            imgCoachmarkPinch!.hidden = true
            imgCoachmarkSpread!.hidden = false
        } else if (imgCoachmarkPinch!.hidden) {
            vwCoachmark!.hidden = true
            NSUserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.CoachmarkBrowseDone)
        }
    }

}

