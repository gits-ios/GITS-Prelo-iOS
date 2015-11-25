//
//  TourViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/10/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class TourViewController: BaseViewController, UIScrollViewDelegate
{

    @IBOutlet var pager : UIPageControl!
    @IBOutlet var btnNext : UIButton!
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var scrollViewTitle : UIScrollView!
    @IBOutlet var scrollViewSubtitle : UIScrollView!
    
    var parent : BaseViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: UserDefaultsKey.Tour)
//        NSUserDefaults.standardUserDefaults().synchronize()
        
        self.navigationController?.navigationBarHidden = true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let p = scrollView.contentOffset
        
        var x = p.x * scrollViewTitle.width / scrollView.width
        scrollViewTitle.contentOffset = CGPointMake(x, 0)
        
        x = p.x * scrollViewSubtitle.width / scrollView.width
        scrollViewSubtitle.contentOffset = CGPointMake(x, 0)
        
        pager.currentPage = Int(p.x / UIScreen.mainScreen().bounds.width)
        
        if (pager.currentPage == 2)
        {
            btnNext.setTitle("Mulai", forState: UIControlState.Normal)
        } else
        {
            btnNext.setTitle("Selanjutnya", forState: UIControlState.Normal)
        }
        
        // Only track if scrollView did finish the scroll
        if (Int(p.x) % Int(scrollView.width) == 0) {
            Mixpanel.trackPageVisit("First Time Tutorial \(pager.currentPage + 1)")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.trackPageVisit("First Time Tutorial 1")
    }
    
    var fromButton = false
    @IBAction func next(sender : UIButton)
    {
        if (pager.currentPage == 2)
        {
            let catPrefVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameCategoryPreferences, owner: nil, options: nil).first as! CategoryPreferencesViewController
            catPrefVC.parent = parent
            self.navigationController?.pushViewController(catPrefVC, animated: true)
        } else
        {
            scrollView.setContentOffset(CGPointMake(CGFloat(CGFloat(pager.currentPage+1) * UIScreen.mainScreen().bounds.width), CGFloat(0)), animated: true)
        }
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
