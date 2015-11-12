//
//  Dashboard2ViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/10/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class Dashboard2ViewController : BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.sharedInstance().track("Dashboard Logged Out")
    }
    
    @IBAction func loginButtonTapped(sender : AnyObject) {
//        let loginVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdLogin) as! LoginViewController
//        loginVC.userRelatedDelegate = self.previousController as? UserRelatedDelegate
//        let n = BaseNavigationController(rootViewController : loginVC)
//        n.setNavigationBarHidden(true, animated: false)
//        self.previousController?.presentViewController(n, animated: true, completion: nil)
        LoginViewController.Show(self.previousController!, userRelatedDelegate: self.previousController as? UserRelatedDelegate, animated: true)
    }
    
    @IBAction func contactButtonTapped(sender : AnyObject) {
        
    }
    
    @IBAction func aboutButtonTapped(sender: UIButton) {
        let a = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAbout) as! AboutViewController
        a.userRelatedDelegate = self.previousController as? UserRelatedDelegate
        a.isShowLogout = false
        self.previousController?.navigationController?.pushViewController(a, animated: true)
    }
    
}
