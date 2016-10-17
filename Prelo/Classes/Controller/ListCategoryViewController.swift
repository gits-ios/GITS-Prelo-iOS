//
//  ViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire

class ListCategoryViewController: BaseViewController, CarbonTabSwipeDelegate, UIScrollViewDelegate
{

    var tabSwipe : CarbonTabSwipeNavigation?
    var first = NO
    var categories : JSON?
    var dummyGrid : DummyGridViewController!
    var pinchIn : UIPinchGestureRecognizer!
    
    @IBOutlet var scrollCategoryName: UIScrollView!
    @IBOutlet var scroll_View : UIScrollView!
    
    var categoriesFix : [JSON] = []
    
    var currentCategoryId : String = ""
    
    // Home promo
    var vwHomePromo : UIView?
    
    // Coachmark
    var vwCoachmark : UIView?
    var imgCoachmarkPinch : UIImageView?
    var imgCoachmarkSpread : UIImageView?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        pinchIn = UIPinchGestureRecognizer(target: self, action: #selector(ListCategoryViewController.pinchedIn(_:)))
        self.view.addGestureRecognizer(pinchIn)
        
        // Mixpanel
        //Mixpanel.trackPageVisit(PageName.Home, otherParam: ["Category" : "All"])
        //Mixpanel.sharedInstance().timeEvent(MixpanelEvent.CategoryBrowsed)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Home)
        
        scroll_View.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(ListCategoryViewController.grandRefresh), name: NSNotification.Name(rawValue: "refreshHome"), object: nil)
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
    func pinchedIn(_ p : UIPinchGestureRecognizer)
    {
        if (p.state == UIGestureRecognizerState.began)
        {
            firstPinch = p.scale
            print("Start Scale : " + String(stringInterpolationSegment: p.scale))
        } else if (p.state == UIGestureRecognizerState.ended)
        {
            print("End Scale : " + String(stringInterpolationSegment: p.scale) + " -> " + String(stringInterpolationSegment: firstPinch))
            
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
        listItemViews.removeAll(keepingCapacity: false)
        
        if (childViewControllers.count > 0) {
            for vc in childViewControllers {
                vc.willMove(toParentViewController: nil)
                vc.removeFromParentViewController()
                vc.view.removeFromSuperview()
            }
        }
        
        if (contentView != nil) {
            for v in self.contentView!.subviews
            {
                v.removeFromSuperview()
            }
        }
        
        categoryNames.removeAll(keepingCapacity: false)
        if (contentCategoryNames != nil) {
            for v in (self.contentCategoryNames?.subviews)!
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
    func addChilds(_ count : Int)
    {
        var d = ["scroll":scroll_View, "master":self.view]
        if contentView == nil
        {
            scroll_View.showsHorizontalScrollIndicator = false
            scroll_View.isPagingEnabled = true
            let pContentView = UIView()
            pContentView.backgroundColor = UIColor(hexString: "#E8ECEE")
            scroll_View.addSubview(pContentView)
            
            pContentView.translatesAutoresizingMaskIntoConstraints = false
            
            d["content"] = pContentView
            scroll_View.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[content]-0-|", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            // .AlignAllBaseline asalnya nil suggested by kumang
            scroll_View.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[content]-0-|", options: .alignAllBaseline, metrics: nil, views: d))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[content(==scroll)]", options: .alignAllBaseline, metrics: nil, views: d))
            contentView = pContentView
        }
        
        //let count = 1 // FOR TESTING: Manual category count in home
        var lastView : UIView?
        if (count > 0) {
            for i in 0..<count {
                self.addChildAtIdx(i, count: count, d: &d, lastView: &lastView)
            }
        }
        if let firstChild = self.childViewControllers[0] as? ListItemViewController { // First child
            firstChild.setupContent()
        }
        
        scroll_View.layoutIfNeeded()
        contentView?.layoutIfNeeded()
        addCategoryNames(count)
    }
    
    func addChildAtIdx(_ i : Int, count : Int, d : inout [String : UIView?], lastView : inout UIView?) {
        let li:ListItemViewController = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        li.previousController = self.previousController
        
        li.categoryJson = categoriesFix[i]
        
        li.bannerImageUrl = categoriesFix[i]["banner"]["image_url"].stringValue
        li.bannerTargetUrl = categoriesFix[i]["banner"]["target_url"].stringValue
        
        let v = li.view
        v?.translatesAutoresizingMaskIntoConstraints = false
        contentView?.addSubview(v!)
        self.addChildViewController(li)
        li.didMove(toParentViewController: self)
        d["v"] = v
        if let lv = lastView
        {
            d["lv"] = lv
            contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[lv]-0-[v]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            
        } else {
            contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[v]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
        }
        
        contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(==scroll)]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[v(==master)]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
        
        if (i == count-1)
        {
            contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[v]-0-|", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
        }
        
        lastView = v
        listItemViews.append(v!)
    }
    
    var contentCategoryNames : UIView?
    var categoryIndicator : UIView?
    var indicatorWidth : NSLayoutConstraint?
    var indicatorMargin : NSLayoutConstraint?
    var categoryNames : [UIView] = []
    func addCategoryNames(_ count : Int)
    {
        var d = ["scroll":scrollCategoryName, "master":self.view]
        if contentCategoryNames == nil
        {
            scrollCategoryName.showsHorizontalScrollIndicator = false
            scrollCategoryName.backgroundColor = UIColor.white
            let pContentView = UIView()
            scrollCategoryName.addSubview(pContentView)
            
            pContentView.translatesAutoresizingMaskIntoConstraints = false
            
            d["content"] = pContentView
            scrollCategoryName.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[content]-0-|", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            scrollCategoryName.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[content]-0-|", options: .alignAllBaseline, metrics: nil, views: d))
            pContentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[content(==44)]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            contentCategoryNames = pContentView
        }
        
        if (categoryIndicator == nil)
        {
            categoryIndicator = UIView()
            categoryIndicator?.translatesAutoresizingMaskIntoConstraints = false
            categoryIndicator?.backgroundColor = Theme.ThemeOrange
            contentCategoryNames?.addSubview(categoryIndicator!)
            d["indicator"] = categoryIndicator
            contentCategoryNames?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[indicator]-0-|", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            categoryIndicator?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[indicator(==4)]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            indicatorMargin = NSLayoutConstraint.constraints(withVisualFormat: "|-0-[indicator]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d).first
            indicatorWidth = NSLayoutConstraint.constraints(withVisualFormat: "[indicator(==100)]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d).first
            contentCategoryNames?.addConstraint(indicatorMargin!)
            categoryIndicator?.addConstraint(indicatorWidth!)
        }
        
//        var colors = [UIColor.blueColor(), UIColor.whiteColor()]
        
        var lastView : UIView?
        for i in 0...count-1
        {
            let button = UIButton(type: .custom)
            button.setTitleColor(Theme.GrayDark)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            if let name = categoriesFix[i]["name"].string {
                var nameFix = name
                if (nameFix.lowercased() == "all") {
                    if let ftrd = categoriesFix[i]["is_featured"].bool , ftrd == true {
                        nameFix = "Home"
                    }
                }
                button.setTitle(nameFix, for: UIControlState())
            }
            
            button.sizeToFit()
            
            button.addTarget(self, action: #selector(ListCategoryViewController.categoryButtonAction(_:)), for: UIControlEvents.touchUpInside)
            
            let width = button.width
            let v = button
            v.tag = i
            v.translatesAutoresizingMaskIntoConstraints = false
            contentCategoryNames?.addSubview(v)
            d["v"] = v
            if let lv = lastView
            {
                d["lv"] = lv
                contentCategoryNames?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[lv]-20-[v]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
                
            } else {
                contentCategoryNames?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-20-[v]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            }
            
            contentCategoryNames?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(==44)]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[v(==\(width))]", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            
            if (i == count-1)
            {
            contentCategoryNames?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[v]-20-|", options: NSLayoutFormatOptions.alignAllBaseline, metrics: nil, views: d))
            }
            
            lastView = v
            categoryNames.append(v)
        }
        
        scrollCategoryName.layoutIfNeeded()
        contentCategoryNames?.layoutIfNeeded()
        
        // Home promo
        // API Migrasi
        let _ = request(APIApp.version).responseJSON {resp in
            var isShowPromo = false
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Promo check")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                if let isPromo = data["is_promo"].bool {
                    if (isPromo) {
                        if let promoTitle = data["promo_data"]["title"].string {
                            if let promoUrlString = data["promo_data"]["url"].string {
                                if let promoUrl = URL(string: promoUrlString) {
                                    let lastPromoTitle : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.LastPromoTitle) as! String?
                                    if (promoTitle != lastPromoTitle) { // Artinya blm pernah dimunculkan
                                        let screenSize : CGRect = UIScreen.main.bounds
                                        self.vwHomePromo = UIView(frame: screenSize, backgroundColor: UIColor.colorWithColor(UIColor.black, alpha: 0.7))
                                        
                                        let imgHomePromo = UIImageView()
                                        imgHomePromo.setImageWithUrl(promoUrl, placeHolderImage: nil)
                                        let imgHomePromoSize = CGSize(width: 300, height: 400)
                                        imgHomePromo.frame = CGRect(x: (screenSize.width / 2) - (imgHomePromoSize.width / 2), y: (screenSize.height / 2) - (imgHomePromoSize.height / 2), width: imgHomePromoSize.width, height: imgHomePromoSize.height)
                                        imgHomePromo.contentMode = UIViewContentMode.scaleAspectFit
                                        
                                        let btnHomePromo : UIButton = UIButton(frame: screenSize)
                                        btnHomePromo.addTarget(self, action: #selector(ListCategoryViewController.btnHomePromoPressed(_:)), for: UIControlEvents.touchUpInside)
                                        
                                        self.vwHomePromo!.addSubview(imgHomePromo)
                                        self.vwHomePromo!.addSubview(btnHomePromo)
                                        
                                        if let kumangTabBarVC = self.previousController as? KumangTabBarViewController {
                                            kumangTabBarVC.view.addSubview(self.vwHomePromo!)
                                        }
                                        
                                        UserDefaults.setObjectAndSync(promoTitle, forKey: UserDefaultsKey.LastPromoTitle)
                                        
                                        isShowPromo = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if (!isShowPromo) { // Jika tidak memunculkan promo, langsung munculkan coachmark
                self.processCoachmark()
            }
        }
        
        //setCurrentTab((categoryNames.count > 1) ? 0 : 0)
        let name = categoriesFix[1]["name"].string
        if (name?.lowercased() == "all" || name?.lowercased() == "home") {
            setCurrentTab(1)
        } else {
            setCurrentTab(0)
        }
        
        // Show app store update pop up if necessary
        if let newVer = UserDefaults.standard.object(forKey: UserDefaultsKey.UpdatePopUpVer) as? String , newVer != "" {
            let alert : UIAlertController = UIAlertController(title: "New Version Available", message: "Prelo \(newVer) is available on App Store", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { action in
                UIApplication.shared.openURL(URL(string: "itms-apps://itunes.apple.com/id/app/prelo/id1027248488")!)
            }))
            if let isForceUpdate = UserDefaults.standard.object(forKey: UserDefaultsKey.UpdatePopUpForced) as? Bool , !isForceUpdate {
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            }
            UserDefaults.standard.set("", forKey: UserDefaultsKey.UpdatePopUpVer)
            UserDefaults.standard.synchronize()
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    var currentTabIndex = 0
    func setCurrentTab(_ index : Int)
    {
        currentTabIndex = index
        if (index >= categoryNames.count)
        {
            return
        }
        
        let x = listItemViews[index].x
        let p = CGPoint(x: x, y: 0)
        
        scroll_View.setContentOffset(p, animated: true)
        
        adjustIndicator(index)
    }
    
    func adjustIndicator(_ index : Int)
    {
        if (index >= categoryNames.count)
        {
            return
        }
        
        let v = categoryNames[index]
        indicatorMargin?.constant = v.x
        indicatorWidth?.constant = v.width
        
        let queue : OperationQueue = OperationQueue()
        let opLayout : Operation = BlockOperation(block: {
            DispatchQueue.main.async(execute: {
                self.categoryIndicator?.layoutIfNeeded()
            })
        })
        queue.addOperation(opLayout)
        let opSetupContent : Operation = BlockOperation(block: {
            DispatchQueue.main.async(execute: {
                if let child = self.childViewControllers[index] as? ListItemViewController {
                    child.setupContent()
                }
            })
        })
        opSetupContent.addDependency(opLayout)
        queue.addOperation(opSetupContent)
    }
    
    func categoryButtonAction(_ sender : UIView)
    {
        let index = sender.tag
        setCurrentTab(index)
        
        centerCategoryView(currentTabIndex)
    }
    
    func centerCategoryView(_ index : Int)
    {
        // crashfix for : http://crashes.to/s/04a5d882ec0 (maybe)
        if (index < 0 || index >= categoryNames.count)
        {
            return
        }
        
        let v = categoryNames[index]
        
        let p = v.frame.origin
//        let px = self.scrollCategoryName.convertPoint(p, toView:nil)
        
        let centeredX = (UIScreen.main.bounds.width-v.width)/2
        var finalP = CGPoint(x: p.x-centeredX, y: 0)
        
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
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var i = 0
        let width = scrollView.bounds.width
        let contentOffsetX = scrollView.contentOffset.x
        
        if (width > 0) {
            Crashlytics.sharedInstance().setObjectValue("width \(width) | offsetX \(contentOffsetX)", forKey: "ListCategoryViewController.scrollViewDidScroll")
            i = Int(contentOffsetX / width)
        }
        currentTabIndex = i
        centerCategoryView(currentTabIndex)
        adjustIndicator(currentTabIndex)
        
        //print("lastContentOffset = \(lastContentOffset)")
        //print("scrollView.contentOffset = \(scrollView.contentOffset)")
        if (lastContentOffset.x != scrollView.contentOffset.x) {
            isPageTracked = false
        }
        
        // Only track if scrollView did finish the left/right scroll
        if (lastContentOffset.y == scrollView.contentOffset.y && lastContentOffset.x != scrollView.contentOffset.x) {
            let i1 = Int(contentOffsetX)
            let i2 = Int(width)
            if (i2 > 0 && (i1 % i2) == 0) {
                let pt = [
                    "Category" : categoriesFix[i]["name"].string!
                ]
                //Mixpanel.trackPageVisit(PageName.Home, otherParam: pt)
                Mixpanel.sharedInstance().timeEvent(MixpanelEvent.CategoryBrowsed)
                Mixpanel.trackEvent(MixpanelEvent.CategoryBrowsed, properties: pt)
                isPageTracked = true
                
                // Jika masuk ke kategori 'Women', munculkan navbar dkk karena kemungkinan scroll atas-bawah mati karena konten tidak panjang
                if (categoriesFix[i]["name"].stringValue.lowercased() == "women") {
                    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "showBottomBar"), object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.slide)
                }
                
                // Set current category id
                self.currentCategoryId = categoriesFix[i]["_id"].stringValue
            }
        }
        
        lastContentOffset = scrollView.contentOffset
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
//        setCurrentTab((categoryNames.count > 1) ? 1 : 0)
        
        // Redirect if any
        let redirectFromHome : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.RedirectFromHome) as! String?
        if (redirectFromHome != nil) {
            if (redirectFromHome == PageName.MyOrders) {
                let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchase, owner: nil, options: nil)?.first as! MyPurchaseViewController
                self.previousController?.navigationController?.pushViewController(myPurchaseVC, animated: true)
            } else if (redirectFromHome == PageName.UnpaidTransaction) {
                let paymentConfirmationVC = Bundle.main.loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil)?.first as! PaymentConfirmationViewController
                self.previousController!.navigationController?.pushViewController(paymentConfirmationVC, animated: true)
            }
            UserDefaults.standard.removeObject(forKey: UserDefaultsKey.RedirectFromHome)
        }
    }
    
    func getFullcategory()
    {
        let _ = request(APIReference.categoryList).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Category List")) {
                UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: resp.result.value!), forKey: "pre_categories")
                UserDefaults.standard.synchronize()
                self.getCategory()
            }
        }
    }
    
    func getCategory()
    {
        let _ = request(APIReference.homeCategories)
            .responseString { resp in
                let string = resp.result.value
                if (string != nil)
                {
                    print(string)
                } else
                {
                    print(resp.result.error)
                }
            }
            .responseJSON {resp in
                if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Category Home")) {
                    UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: resp.result.value!), forKey: "pre_categories")
                    UserDefaults.standard.synchronize()
                    self.setupCategory()
                    
                    if let kumangTabBarVC = self.previousController as? KumangTabBarViewController {
                        kumangTabBarVC.isAlreadyGetCategory = true
                        if (kumangTabBarVC.isVersionChecked) { // Only hide loading if category is already loaded and version already checked
                            kumangTabBarVC.hideLoading()
                        }
                    }
                }
        }
        // FOR TESTING: DISABLE HOME LOAD
        /*if let kumangTabBarVC = self.previousController as? KumangTabBarViewController {
            kumangTabBarVC.isAlreadyGetCategory = true
            if (kumangTabBarVC.isVersionChecked) { // Only hide loading if category is already loaded and version already checked
                kumangTabBarVC.hideLoading()
            }
        }*/
    }
    
    func getIndexInArrayJSON(_ arr : [JSON], withId id : String) -> Int? {
        for i in 0...arr.count - 1 {
            if (arr[i]["_id"].string == id) {
                return i
            }
        }
        return nil
    }
    
    func getAllCategoryIndexInArrayJSON(_ arr : [JSON]) -> Int? {
        for i in 0...arr.count - 1 {
            if (arr[i]["name"].stringValue.lowercased() == "all") {
                return i
            }
        }
        return nil
    }
    
    func setupCategory()
    {
        let data = UserDefaults.standard.object(forKey: "pre_categories") as? Data
        categories = JSON(NSKeyedUnarchiver.unarchiveObject(with: data!)!)
        
        categoriesFix = categories!["_data"].arrayValue
        /* CATEGPREF DISABLED
        if (!User.IsLoggedIn) {
            if let idxAllCateg = getAllCategoryIndexInArrayJSON(categoriesFix) {
                if let idxC1 = getIndexInArrayJSON(categoriesFix, withId: NSUserDefaults.categoryPref1()) {
                    categoriesFix.insert(categoriesFix.removeAtIndex(idxC1), atIndex: idxAllCateg + 1)
                    if let idxC2 = getIndexInArrayJSON(categoriesFix, withId: NSUserDefaults.categoryPref2()) {
                        categoriesFix.insert(categoriesFix.removeAtIndex(idxC2), atIndex: idxAllCateg + 2)
                        if let idxC3 = getIndexInArrayJSON(categoriesFix, withId: NSUserDefaults.categoryPref3()) {
                            categoriesFix.insert(categoriesFix.removeAtIndex(idxC3), atIndex: idxAllCateg + 3)
                        }
                    }
                }
            }
        }
        */
        addChilds(categoriesFix.count)
        
        // FIXME: kondisi kalo user ga login, harusnya categorypref ditaro depan
//        if (User.IsLoggedIn) {
//            categoriesFix = categories!["_data"].arrayValue
//            addChilds(categoriesFix.count)
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
                print("]")
            } else {
                print(", ")
            }
        }
        
        addChilds(categoriesFix.count)*/
    }
    
    func cikah()
    {
        tabSwipe?.view.isHidden = false
        tabSwipe?.currentTabIndex = 1
    }
    
    var refreshed = false
    func refresh()
    {
        if (refreshed == false)
        {
            self.view.isHidden = true
            Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(ListCategoryViewController.endRefresh), userInfo: nil, repeats: false)
        }
    }
    
    func endRefresh()
    {
        self.view.isHidden = false
        refreshed = true
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tabSwipeNavigation(_ tabSwipe: CarbonTabSwipeNavigation!, viewControllerAt index: UInt) -> UIViewController!
    {
        let v:ListItemViewController = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        v.previousController = self.previousController
        let i = Int(index)
        
        v.categoryJson = categoriesFix[i]
        
        return v
    }
    
    // MARK: - Home promo
    
    func btnHomePromoPressed(_ sender: UIButton) {
        vwHomePromo!.isHidden = true
        processCoachmark()
    }
    
    // MARK: - Coachmark
    
    func processCoachmark() {
        // Coachmark
        let coachmarkDone : Bool? = UserDefaults.standard.object(forKey: UserDefaultsKey.CoachmarkBrowseDone) as! Bool?
        if (coachmarkDone != true && vwCoachmark == nil) {
            let screenSize : CGRect = UIScreen.main.bounds
            vwCoachmark = UIView(frame: screenSize, backgroundColor: UIColor.colorWithColor(UIColor.black, alpha: 0.7))
            imgCoachmarkPinch = UIImageView(image: UIImage(named: "cchmrk_pinch"))
            let imgCoachmarkPinchSize : CGSize = CGSize(width: 180, height: 134)
            imgCoachmarkPinch?.frame = CGRect(x: (screenSize.width / 2) - (imgCoachmarkPinchSize.width / 2), y: (screenSize.height / 2) - (imgCoachmarkPinchSize.height / 2), width: imgCoachmarkPinchSize.width, height: imgCoachmarkPinchSize.height)
            imgCoachmarkSpread = UIImageView(image: UIImage(named: "cchmrk_spread"))
            let imgCoachmarkSpreadSize : CGSize = CGSize(width: 180, height: 136)
            imgCoachmarkSpread?.frame = CGRect(x: (screenSize.width / 2) - (imgCoachmarkSpreadSize.width / 2), y: (screenSize.height / 2) - (imgCoachmarkSpreadSize.height / 2), width: imgCoachmarkSpreadSize.width, height: imgCoachmarkSpreadSize.height)
            
            let btnCoachmark : UIButton = UIButton(frame: screenSize)
            btnCoachmark.addTarget(self, action: #selector(ListCategoryViewController.btnCoachmarkPressed(_:)), for: UIControlEvents.touchUpInside)
            
            if (vwCoachmark != nil && imgCoachmarkPinch != nil && imgCoachmarkSpread != nil) {
                vwCoachmark!.addSubview(imgCoachmarkPinch!)
                vwCoachmark!.addSubview(imgCoachmarkSpread!)
                imgCoachmarkSpread!.isHidden = true
                vwCoachmark!.addSubview(btnCoachmark)
                if let kumangTabBarVC = self.previousController as? KumangTabBarViewController {
                    kumangTabBarVC.view.addSubview(vwCoachmark!)
                }
            }
        }
    }
    
    func btnCoachmarkPressed(_ sender: UIButton!) {
        if (imgCoachmarkSpread!.isHidden) {
            imgCoachmarkPinch!.isHidden = true
            imgCoachmarkSpread!.isHidden = false
        } else if (imgCoachmarkPinch!.isHidden) {
            vwCoachmark!.isHidden = true
            UserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.CoachmarkBrowseDone)
        }
    }
}

