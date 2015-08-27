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
        let loginVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdLogin) as! LoginViewController
        let n = BaseNavigationController(rootViewController : loginVC)
        n.setNavigationBarHidden(true, animated: false)
        self.presentViewController(n, animated: true, completion: nil)
    }
    
    @IBAction func contactButtonTapped(sender : AnyObject) {
        
    }
    
    @IBAction func aboutButtonTapped(sender: UIButton) {
        
    }
    
}
