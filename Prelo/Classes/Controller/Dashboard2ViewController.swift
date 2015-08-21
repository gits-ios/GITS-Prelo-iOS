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
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC : LoginViewController? = mainStoryboard.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdLogin) as? LoginViewController
        loginVC?.navController = self.previousController?.navigationController
        self.previousController?.navigationController?.pushViewController(loginVC!, animated: true)
    }
    
    @IBAction func contactButtonTapped(sender : AnyObject) {
        
    }
}
