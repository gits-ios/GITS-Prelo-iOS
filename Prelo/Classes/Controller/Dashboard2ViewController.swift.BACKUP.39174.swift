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
    
    @IBAction func loginButtonTapped(sender : AnyObject) {
<<<<<<< HEAD
//        let loginVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdLogin) as! LoginViewController
//        loginVC.userRelatedDelegate = self.previousController as? UserRelatedDelegate
//        let n = BaseNavigationController(rootViewController : loginVC)
//        n.setNavigationBarHidden(true, animated: false)
//        self.previousController?.presentViewController(n, animated: true, completion: nil)
        LoginViewController.Show(self.previousController!, userRelatedDelegate: self.previousController as? UserRelatedDelegate, animated: true)
=======
        let loginVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdLogin) as! LoginViewController
        let n = BaseNavigationController(rootViewController : loginVC)
        n.setNavigationBarHidden(true, animated: false)
        self.presentViewController(n, animated: true, completion: nil)
>>>>>>> 744ae3013f2320503e8576aeb67b86fd33536c72
    }
    
    @IBAction func contactButtonTapped(sender : AnyObject) {
        
    }
    
    @IBAction func aboutButtonTapped(sender: UIButton) {
        
    }
    
}
