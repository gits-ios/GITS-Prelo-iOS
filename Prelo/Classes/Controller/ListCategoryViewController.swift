//
//  ViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire

// MARK: - Class

class ListCategoryViewController: BaseViewController, UIScrollViewDelegate, CarbonTabSwipeDelegate {

    // MARK: - Properties
    
    @IBOutlet var scrollCategoryName: UIScrollView!
    @IBOutlet var scroll_View : UIScrollView!
    @IBOutlet weak var consHeightScrollCategoryName: NSLayoutConstraint!
    
    var tabSwipe : CarbonTabSwipeNavigation?
    var first = false
    var categories : JSON?
    var dummyGrid : DummyGridViewController!
    var pinchIn : UIPinchGestureRecognizer!
    var categoriesFix : [JSON] = []
    var currentCategoryId : String = ""
    
    var firstPinch : CGFloat = 0
    
    var contentView : UIView?
    var listItemViews : [UIView] = []
    
    var contentCategoryNames : UIView?
    var categoryIndicator : UIView?
    var indicatorWidth : NSLayoutConstraint?
    var indicatorMargin : NSLayoutConstraint?
    var categoryNames : [UIView] = []
    
    var currentTabIndex = 0
    
    var lastContentOffset = CGPoint()
    var isPageTracked = false
    
    var refreshed = false
    
    // Home promo
    var vwHomePromo : UIView?
    
    // Coachmark
    var vwCoachmark : UIView?
    var imgCoachmarkPinch : UIImageView?
    var imgCoachmarkSpread : UIImageView?
    
    var tabbarBtnMargin: CGFloat = 8 // 20 (previous) ; 8 -> iphone, 16 -> ipad
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinchIn = UIPinchGestureRecognizer(target: self, action: #selector(ListCategoryViewController.pinchedIn(_:)))
        self.view.addGestureRecognizer(pinchIn)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.Home, otherParam: ["Category" : "All"])
        //Mixpanel.sharedInstance().timeEvent(MixpanelEvent.CategoryBrowsed)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Home)
        
        scroll_View.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(ListCategoryViewController.grandRefresh), name: NSNotification.Name(rawValue: "refreshHome"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Redirect if any
        let redirectFromHome : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.RedirectFromHome) as! String?
        if (redirectFromHome != nil) {
            if (redirectFromHome == PageName.MyOrders) {
                let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
                self.previousController?.navigationController?.pushViewController(myPurchaseVC, animated: true)
            } else if (redirectFromHome == PageName.UnpaidTransaction) {
                // deprecated
                /*
                let paymentConfirmationVC = Bundle.main.loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil)?.first as! PaymentConfirmationViewController
                self.previousController!.navigationController?.pushViewController(paymentConfirmationVC, animated: true)
                */
            }
            UserDefaults.standard.removeObject(forKey: UserDefaultsKey.RedirectFromHome)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func grandRefresh() {
        if let kumangTabBarVC = self.previousController as? KumangTabBarViewController {
            kumangTabBarVC.showLoading()
            kumangTabBarVC.isAlreadyGetCategory = false
        }
        
        scroll_View.backgroundColor = UIColor.clear
        
        // lets cleaning
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
        
        getFullcategory()
    }
    
    func refresh() {
        if (refreshed == false) {
            self.view.isHidden = true
            Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(ListCategoryViewController.endRefresh), userInfo: nil, repeats: false)
        }
    }
    
    func endRefresh() {
        self.view.isHidden = false
        refreshed = true
    }
    
    func getFullcategory() {
        let _ = request(APIReference.categoryList).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Category List")) {
                UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: resp.result.value!), forKey: "pre_categories")
                UserDefaults.standard.synchronize()
                self.getCategory()
            }
        }
    }
    
    func getCategory() {
        let _ = request(APIReference.homeCategories)
            .responseString { resp in
                let string = resp.result.value
                if (string != nil)
                {
                    //print((string ?? ""))
                } else
                {
                    //print((resp.result.error ?? ""))
                }
            }
            .responseJSON {resp in
                if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Category Home")) {
                    UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: resp.result.value!), forKey: "pre_categories")
                    UserDefaults.standard.synchronize()
                    
                    let backgroundQueue = DispatchQueue(label: "com.prelo.ios.Prelo",
                                                        qos: .background,
                                                        //attributes: .concurrent, // -> raise error
                                                        target: nil)
                    backgroundQueue.async {
                        if let kumangTabBarVC = self.previousController as? KumangTabBarViewController {
                            kumangTabBarVC.isAlreadyGetCategory = true
                            if (kumangTabBarVC.isVersionChecked) { // Only hide loading if category is already loaded and version already checked
                                DispatchQueue.main.async(execute: {
                                    
                                    // continue to main async
                                    kumangTabBarVC.hideLoading()
                                })
                            }
                        }
                    }
                    
                    self.setupCategory()
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
    
    
    func setupCategory() {
        let data = UserDefaults.standard.object(forKey: "pre_categories") as? Data
        categories = JSON(NSKeyedUnarchiver.unarchiveObject(with: data!)!)
        
        categoriesFix = categories!["_data"].arrayValue
        
        
        // setup space
        let c = categoriesFix.count
        
        // iphone
        var small = c - 1 // 40 , 53 + 4
        var width = small*40 + 57
        
        var operanMin: CGFloat = 8
        
        if AppTools.isIPad {
            // ipad
            self.consHeightScrollCategoryName.constant = 66
            
            small = c - 1 // 60, 75 + 4
            width = small*60 + 79
            
            operanMin = 16
        }
        
        let nw = UIScreen.main.bounds.width - CGFloat(width)
        if nw > operanMin * CGFloat(c + 1) {
            let nnw = nw - nw / CGFloat(c)
            self.tabbarBtnMargin = nnw / CGFloat(c)
            
            self.scrollCategoryName.isScrollEnabled = false
        } else {
            self.tabbarBtnMargin = operanMin
        }
        
        self.scrollCategoryName.isDirectionalLockEnabled = true
        
        addChilds(categoriesFix.count)
    }
    
    func addChilds(_ count : Int) {
        var d : [String : UIView] = [
            "scroll" : scroll_View,
            "master" : self.view
        ]
        if contentView == nil {
            scroll_View.showsHorizontalScrollIndicator = false
            scroll_View.isPagingEnabled = true
            let pContentView : UIView = UIView()
            pContentView.backgroundColor = UIColor(hexString: "#E8ECEE")
            scroll_View.addSubview(pContentView)
            
            pContentView.translatesAutoresizingMaskIntoConstraints = false
            
            d["content"] = pContentView
            scroll_View.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[content]-0-|", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            // .alignAllLastBaseline asalnya nil suggested by kumang
            scroll_View.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[content]-0-|", options: .alignAllLastBaseline, metrics: nil, views: d))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[content(==scroll)]", options: .alignAllLastBaseline, metrics: nil, views: d))
            contentView = pContentView
        }
        
        //let count = 1 // FOR TESTING: Manual category count in home
        var lastView : UIView?
        if (count > 0) {
            for i in 0..<count {
                self.addChildAtIdx(i, count: count, d: &d, lastView: &lastView)
            }
        }
        
        /*
        if let firstChild = self.childViewControllers[0] as? ListItemViewController { // First child
            firstChild.setupContent()
            firstChild.tabNumber = 0
            HomeHelper.switchActiveTab(0)
        }
        */
        
        let idx = getHomeIndex()
        if let home = self.childViewControllers[idx] as? ListItemViewController { // First rendered view
            home.setupContent()
            home.tabNumber = idx
            HomeHelper.switchActiveTab(idx)
        }
        
        scroll_View.layoutIfNeeded()
        contentView?.layoutIfNeeded()
        addCategoryNames(count)
        
        scroll_View.backgroundColor = UIColor(hexString: "#E8ECEE")
    }
    
    func addChildAtIdx(_ i : Int, count : Int, d : inout [String : UIView], lastView : inout UIView?) {
        let li:ListItemViewController = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        li.previousController = self.previousController
        
        li.categoryJson = categoriesFix[i]
        li.scrollCategoryName = self.scrollCategoryName
        
        li.bannerImageUrl = categoriesFix[i]["banner"]["image_url"].stringValue
        li.bannerTargetUrl = categoriesFix[i]["banner"]["target_url"].stringValue
        
        let v = li.view
        v?.translatesAutoresizingMaskIntoConstraints = false
        contentView?.addSubview(v!)
        self.addChildViewController(li)
        li.didMove(toParentViewController: self)
        d["v"] = v
        if let lv = lastView {
            d["lv"] = lv
            contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[lv]-0-[v]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            
        } else {
            contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[v]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
        }
        
        contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(==scroll)]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[v(==master)]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
        
        if (i == count-1) {
            contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[v]-0-|", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
        }
        
        lastView = v
        listItemViews.append(v!)
    }
    
    func addCategoryNames(_ count : Int)
    {
        var d : [String : UIView] = ["scroll":scrollCategoryName, "master":self.view]
        if contentCategoryNames == nil
        {
            scrollCategoryName.showsHorizontalScrollIndicator = false
            scrollCategoryName.showsVerticalScrollIndicator = false
            scrollCategoryName.backgroundColor = UIColor.white
            let pContentView = UIView()
            scrollCategoryName.addSubview(pContentView)
            
            pContentView.translatesAutoresizingMaskIntoConstraints = false
            
            var h = 44 // content height
            if AppTools.isIPad {
                h = 66
            }
            
            d["content"] = pContentView
            scrollCategoryName.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[content]-0-|", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            scrollCategoryName.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[content]-0-|", options: .alignAllLastBaseline, metrics: nil, views: d))
            pContentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[content(==\(h))]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            contentCategoryNames = pContentView
        }
        
        if (categoryIndicator == nil)
        {
            var w = 44 // 100; width of indicator category
            if AppTools.isIPad {
                w = 66
            }
            
            categoryIndicator = UIView()
            categoryIndicator?.translatesAutoresizingMaskIntoConstraints = false
            categoryIndicator?.backgroundColor = Theme.ThemeOrange
            contentCategoryNames?.addSubview(categoryIndicator!)
            d["indicator"] = categoryIndicator
            contentCategoryNames?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[indicator]-0-|", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            categoryIndicator?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[indicator(==4)]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            indicatorMargin = NSLayoutConstraint.constraints(withVisualFormat: "|-0-[indicator]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d).first
            indicatorWidth = NSLayoutConstraint.constraints(withVisualFormat: "[indicator(==\(w))]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d).first
            contentCategoryNames?.addConstraint(indicatorMargin!)
            categoryIndicator?.addConstraint(indicatorWidth!)
        }
        
//        var colors = [UIColor.blueColor(), UIColor.whiteColor()]
        
        var lastView : UIView?
        for i in 0...count-1
        {
            let button = UIButton(type: .custom)
            //button.setTitleColor(Theme.GrayLight)
            //button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            
            // text only
            /*
            if let name = categoriesFix[i]["name"].string {
                var nameFix = name
                if (nameFix.lowercased() == "all") {
                    if let ftrd = categoriesFix[i]["is_featured"].bool , ftrd == true {
                        nameFix = "Home"
                    }
                }
                button.setTitle(nameFix, for: UIControlState())
            } */
            
            // icon only
            /*
            if let icon = categoriesFix[i]["image_name"].string {
                button.af_setImage(for: UIControlState(), url: URL(string: icon)!)
                button.imageView?.contentMode = .scaleAspectFit
                button.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            } */
            
            //button.sizeToFit()
            
            if let name = categoriesFix[i]["name"].string, let icon = categoriesFix[i]["image_name"].string {
                var nameFix = name
                if (nameFix.lowercased() == "all") {
                    if let ftrd = categoriesFix[i]["is_featured"].bool , ftrd == true {
                        nameFix = "Home"
                    }
                }
                
                var h: CGFloat = 10  // height label
                var w: CGFloat = 40  // width (btn default)
                var hI: CGFloat = 24 // height icon
                var y: CGFloat = 30  // y position of label
                if AppTools.isIPad {
                    h = 15
                    w = 60
                    hI = 40
                    y = 45
                }
                
                let imgLb = UILabel()
                imgLb.frame = CGRect(x: 0, y: y, width: w, height: h)
                imgLb.font = UIFont.systemFont(ofSize: h)
                imgLb.text = nameFix
                imgLb.tag = 999
                let c = imgLb.sizeThatFits(CGSize(width: w, height: h))
                if c.width > w {
                    //imgLb.sizeToFit()
                    imgLb.frame = CGRect(x: 0, y: y, width: c.width + 4, height: h)
                }
                imgLb.textAlignment = .center
                imgLb.textColor = Theme.TabNormalColor
                
                let imgVw = TintedImageView()
                imgVw.frame = CGRect(x: 0, y: 4, width: imgLb.width, height: hI)
                
                if nameFix == "Home" {
                    imgVw.image = UIImage(named: "ic_home")?.withRenderingMode(.alwaysTemplate)
                } else {
                    imgVw.af_setImage(
                        withURL: URL(string: icon)!,
                        imageTransition: .custom(
                            duration: 0.2,
                            animationOptions: .transitionCrossDissolve,
                            animations: { imageView, image in
                                imageView.image = image.withRenderingMode(.alwaysTemplate)
                        },
                            completion: nil
                        )
                    )
                }
                
                imgVw.contentMode = .scaleAspectFit
                imgVw.tag = 998
                imgVw.tint = true
                imgVw.tintColor = Theme.TabNormalColor
                
                button.viewWithTag(998)?.removeFromSuperview()
                button.viewWithTag(999)?.removeFromSuperview()
                
                button.addSubview(imgVw)
                button.addSubview(imgLb)
                
                button.frame = CGRect(x: 0, y: 0, width: imgLb.width, height: w) // height equal initial width
            }
            
            button.addTarget(self, action: #selector(ListCategoryViewController.categoryButtonAction(_:)), for: UIControlEvents.touchUpInside)
            
            //button.addTarget(self, action: #selector(ListCategoryViewController.longPressCategoryButtonAction(_:)), for: UIControlEvents.touchDownRepeat)
            
            let width = button.width
            let v = button
            v.tag = i
            v.translatesAutoresizingMaskIntoConstraints = false
            contentCategoryNames?.addSubview(v)
            d["v"] = v
            
            var h = 44 // content height
            if AppTools.isIPad {
                h = 66
            }
            
            if let lv = lastView
            {
                d["lv"] = lv
                contentCategoryNames?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[lv]-\(tabbarBtnMargin)-[v]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
                
            } else {
                contentCategoryNames?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-\(tabbarBtnMargin)-[v]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            }
            
            contentCategoryNames?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(==\(h))]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[v(==\(width))]", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            
            if (i == count-1)
            {
            contentCategoryNames?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[v]-\(tabbarBtnMargin)-|", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: d))
            }
            
            lastView = v
            categoryNames.append(v)
        }
        
        scrollCategoryName.layoutIfNeeded()
        contentCategoryNames?.layoutIfNeeded()
        
        // Home promo 
        // & Save ab testing (need improvement)
        // API Migrasi
        let _ = request(APIApp.version).responseJSON {resp in
            var isShowPromo = false
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Promo check")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                //print(data.debugDescription)
                
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
                                        let imgHomePromoSize = CGSize(width: 300, height: 400)
                                        imgHomePromo.frame = CGRect(x: (screenSize.width / 2) - (imgHomePromoSize.width / 2), y: (screenSize.height / 2) - (imgHomePromoSize.height / 2), width: imgHomePromoSize.width, height: imgHomePromoSize.height)
                                        imgHomePromo.afSetImage(withURL: promoUrl, withFilter: .fitWithoutPlaceHolder) // fix
                                        //imgHomePromo.contentMode = UIViewContentMode.scaleAspectFit
                                        
                                        let btnHomePromo : UIButton = UIButton(frame: screenSize)
                                        btnHomePromo.addTarget(self, action: #selector(ListCategoryViewController.btnHomePromoPressed(_:)), for: UIControlEvents.touchUpInside)
                                        
                                        self.vwHomePromo!.addSubview(imgHomePromo)
                                        self.vwHomePromo!.addSubview(btnHomePromo)
                                        
                                        if let kumangTabBarVC = self.previousController as? KumangTabBarViewController {
                                            kumangTabBarVC.view.addSubview(self.vwHomePromo!)
                                        }
                                        
                                        UserDefaults.setObjectAndSync(promoTitle as AnyObject?, forKey: UserDefaultsKey.LastPromoTitle)
                                        
                                        isShowPromo = true
                                    }
                                }
                            }
                        }
                    }
                }
                
                if let abTest = data["ab_test"].array {
                    if abTest.contains("fake_approve") {
                        UserDefaults.standard.set(true, forKey: UserDefaultsKey.AbTestFakeApprove)
                        UserDefaults.standard.synchronize()
                    }
                }
            }
            if (!isShowPromo) { // Jika tidak memunculkan promo, langsung munculkan coachmark
                self.processCoachmark()
            }
        }
        
        //setCurrentTab((categoryNames.count > 1) ? 0 : 0)
        /*
        let name = categoriesFix[1]["name"].string
        if (name?.lowercased() == "all" || name?.lowercased() == "home") {
            setCurrentTab(1)
            
            self.fixer(1)
        } else {
            setCurrentTab(0)
            
            self.fixer(0)
        }
        */
        
        let idx = getHomeIndex()
        self.setCurrentTab(idx)
        self.fixer(idx)
    }
    
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
        
        //adjustIndicator(index)
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
        
        self.coloringTitle(index)
        
        /*
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
         */
    }
    
    func coloringTitle(_ index: Int) {
        for i in 0...categoryNames.count-1 {
            if index != i {
                let button = categoryNames[i] as! UIButton
                //button.setTitleColor(Theme.GrayLight)
                if let imgLb = button.viewWithTag(999) {
                    let lb = imgLb as! UILabel
                    lb.textColor = Theme.TabNormalColor
                }
                if let imgVw = button.viewWithTag(998) {
                    let vw = imgVw as! TintedImageView
                    vw.tint = true
                    vw.tintColor = Theme.TabNormalColor
                }
            } else {
                let button = categoryNames[i] as! UIButton
                //button.setTitleColor(Theme.GrayDark)
                if let imgLb = button.viewWithTag(999) {
                    let lb = imgLb as! UILabel
                    lb.textColor = Theme.TabSelectedColor
                }
                if let imgVw = button.viewWithTag(998) {
                    let vw = imgVw as! TintedImageView
                    vw.tint = true
                    vw.tintColor = Theme.TabSelectedColor
                }
            }
        }
    }
    
    // for init only
    func fixer(_ index: Int) {
        let v = categoryNames[index]
        indicatorMargin?.constant = v.x
        indicatorWidth?.constant = v.width
        
        let button = categoryNames[index] as! UIButton
        //button.setTitleColor(Theme.GrayDark)
        if let imgLb = button.viewWithTag(999) {
            let lb = imgLb as! UILabel
            lb.textColor = Theme.TabSelectedColor
        }
        if let imgVw = button.viewWithTag(998) {
            let vw = imgVw as! TintedImageView
            vw.tint = true
            vw.tintColor = Theme.TabSelectedColor
        }
        
        centerCategoryView(index)
    }
    
    func categoryButtonAction(_ sender : UIView)
    {
        let index = sender.tag
        
        if self.currentTabIndex == index {
            if let child = self.childViewControllers[self.currentTabIndex] as? ListItemViewController {
                if child.isContentLoaded {
                    if child.gridView.indexPathsForVisibleItems.contains(IndexPath(item: 0, section: 0)) {
                        let _curTime = NSDate().timeIntervalSince1970
                        child.curTime = _curTime //- child.interval
                        //child.setupContent()
                        child.refresh()
                    } else {
                        // child.isScrolling = true // (jika pakai animasi)
                        UIView.animate(withDuration: 0.2, animations: {
                            child.gridView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
                        })
                    }
                }
            }
        } else {
            setCurrentTab(index)
            centerCategoryView(currentTabIndex)
        }
    }
    
    func longPressCategoryButtonAction(_ sender : UIView)
    {
        let index = sender.tag
        
        if self.currentTabIndex == index {
            if let child = self.childViewControllers[self.currentTabIndex] as? ListItemViewController {
                if child.isContentLoaded {
                    let _curTime = NSDate().timeIntervalSince1970
                    child.curTime = _curTime //- child.interval
                    //child.setupContent()
                    child.refresh()
                }
            }
        }
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
    
    // MARK: - Gesture recognizer
    
    func pinchedIn(_ p : UIPinchGestureRecognizer)
    {
        if (p.state == UIGestureRecognizerState.began)
        {
            firstPinch = p.scale
            //print("Start Scale : " + String(stringInterpolationSegment: p.scale))
        } else if (p.state == UIGestureRecognizerState.ended)
        {
            //print("End Scale : " + String(stringInterpolationSegment: p.scale) + " -> " + String(stringInterpolationSegment: firstPinch))
            
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
    
    // MARK: - Carbon tab swipe navigation

    func tabSwipeNavigation(_ tabSwipe: CarbonTabSwipeNavigation!, viewControllerAt index: UInt) -> UIViewController!
    {
        let v:ListItemViewController = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        v.previousController = self.previousController
        let i = Int(index)
        
        v.categoryJson = categoriesFix[i]
        
        return v
    }
    
    // MARK: - Scrollview functions
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var i = 0
        let width = scrollView.bounds.width
        let contentOffsetX = scrollView.contentOffset.x
        
        if (width > 0) {
            Crashlytics.sharedInstance().setObjectValue("width \(width) | offsetX \(contentOffsetX)", forKey: "ListCategoryViewController.scrollViewDidScroll")
            i = Int(contentOffsetX / width + 0.5)
        }
        
        if i != currentTabIndex {
            currentTabIndex = i
            centerCategoryView(currentTabIndex)
            adjustIndicator(currentTabIndex)
        }
        
        ////print("lastContentOffset = \(lastContentOffset)")
        ////print("scrollView.contentOffset = \(scrollView.contentOffset)")
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
//                Mixpanel.trackPageVisit(PageName.Home, otherParam: pt)
                Mixpanel.sharedInstance().timeEvent(MixpanelEvent.CategoryBrowsed)
                Mixpanel.trackEvent(MixpanelEvent.CategoryBrowsed, properties: pt)
                isPageTracked = true
                
                // Jika masuk ke kategori 'Women', munculkan navbar dkk karena kemungkinan scroll atas-bawah mati karena konten tidak panjang
                /*if (categoriesFix[i]["name"].stringValue.lowercased() == "women") {
                    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "showBottomBar"), object: nil)
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    
                    // repositionScrollCategoryNameContent
                    let bottomOffset = CGPoint(x: 0, y: Int(self.scrollCategoryName.contentSize.height - self.scrollCategoryName.bounds.size.height))
                    self.scrollCategoryName.setContentOffset(bottomOffset, animated: false)
                    
                    self.showStatusBar()
                }*/
                
                // Set current category id
                self.currentCategoryId = categoriesFix[i]["_id"].stringValue
            }
        }
        
        lastContentOffset = scrollView.contentOffset
    }
    
    // manualy scroll the content view
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setupContent(scrollView)
    }
    
    // from navigation
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        setupContent(scrollView)
    }
    
    // setup content view
    func setupContent(_ scrollView: UIScrollView) {
        if scrollView == scroll_View {
            let queue : OperationQueue = OperationQueue()
            let opLayout : Operation = BlockOperation(block: {
                DispatchQueue.main.async(execute: {
                    self.categoryIndicator?.layoutIfNeeded()
                })
            })
            queue.addOperation(opLayout)
            let opSetupContent : Operation = BlockOperation(block: {
                DispatchQueue.main.async(execute: {
                //DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    if let child = self.childViewControllers[self.currentTabIndex] as? ListItemViewController {
                        child.setupContent()
                        child.tabNumber = self.currentTabIndex
                        HomeHelper.switchActiveTab(self.currentTabIndex)
                    }
                })
            })
            opSetupContent.addDependency(opLayout)
            queue.addOperation(opSetupContent)
        }
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
            UserDefaults.setObjectAndSync(true as AnyObject?, forKey: UserDefaultsKey.CoachmarkBrowseDone)
        }
    }
    
    // MARK: - Other functions
    
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
    
    // helper
    func getHomeIndex() -> Int {
        var idx = 0
        if self.categoriesFix.count > 0 {
            for i in 0..<self.categoriesFix.count {
                if self.categoriesFix[i]["name"].stringValue.lowercased() == "all"
                || self.categoriesFix[i]["name"].stringValue.lowercased() == "home" {
                    idx = i
                    break
                }
            }
        }
        return idx
    }
}

