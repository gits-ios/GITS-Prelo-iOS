//
//  TourViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/10/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class TourViewController: BaseViewController, UIScrollViewDelegate
{

    @IBOutlet var pager : UIPageControl!
    @IBOutlet var btnNext : UIButton!
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var scrollViewTitle : UIScrollView!
    @IBOutlet var scrollViewSubtitle : UIScrollView!
    
    var parentVC : BaseViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.Tour)
//        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Prelo Analytic - First Tutorial
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [:] as! [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.FinishFirst, data: pdata, previousScreen: PageName.Home, loginMethod: loginMethod)
        
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let p = scrollView.contentOffset
        
        var x = p.x * scrollViewTitle.width / ((scrollView.width > 0) ? scrollView.width : 1)
        scrollViewTitle.contentOffset = CGPoint(x: x, y: 0)
        
        x = p.x * scrollViewSubtitle.width / ((scrollView.width > 0) ? scrollView.width : 1)
        scrollViewSubtitle.contentOffset = CGPoint(x: x, y: 0)
        
        let scrWidth = UIScreen.main.bounds.width
        if (scrWidth > 0) {
            pager.currentPage = Int(p.x / scrWidth)
        }
        
        if (pager.currentPage == 4)
        {
            btnNext.setTitle("Mulai", for: UIControlState())
        } else
        {
            btnNext.setTitle("Selanjutnya", for: UIControlState())
        }
        
        // Only track if scrollView did finish the scroll
        if (Int(p.x) % Int(scrollView.width) == 0) {
            // Mixpanel
//            Mixpanel.trackPageVisit(PageName.FirstTimeTutorial + " \(pager.currentPage + 1)")
            
            // Google Analytics
            GAI.trackPageVisit(PageName.FirstTimeTutorial + " \(pager.currentPage + 1)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.FirstTimeTutorial + " 1")
        
        // Google Analytics
        GAI.trackPageVisit(PageName.FirstTimeTutorial + " 1")
        
        // Track first time user
        /*let pt = [
            "Category" : "All",
            "First Time" : false
        ]
        Mixpanel.trackEvent(MixpanelEvent.CategoryBrowsed, properties: pt as [NSObject : AnyObject])*/
    }
    
    var fromButton = false
    @IBAction func next(_ sender : UIButton)
    {
        if (pager.currentPage == 4)
        {
            /* CATEGPREF DISABLED
            let catPrefVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameCategoryPreferences, owner: nil, options: nil).first as! CategoryPreferencesViewController
            catPrefVC.parentVC = parentVC
            self.navigationController?.pushViewController(catPrefVC, animated: true)
            */
            self.dismiss(animated: true, completion: nil)
        } else {
            scrollView.setContentOffset(CGPoint(x: CGFloat(CGFloat(pager.currentPage+1) * UIScreen.main.bounds.width), y: CGFloat(0)), animated: true)
        }
    }
}
