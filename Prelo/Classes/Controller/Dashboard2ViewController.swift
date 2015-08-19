//
//  Dashboard2ViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/10/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

protocol Dashboard2Delegate {
    func navigateToLogin()
    func navigateToContactPrelo()
}

class Dashboard2ViewController : BaseViewController {
    
    var dashboard2Delegate : Dashboard2Delegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loginButtonTapped(sender : AnyObject) {
        dashboard2Delegate?.navigateToLogin()
//        var controllerLogin : LoginViewController? = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdLogin) as? LoginViewController
//        self.navigationController?.pushViewController(controllerLogin!, animated: true)
    }
    
    @IBAction func contactButtonTapped(sender : AnyObject) {
        
    }
}
