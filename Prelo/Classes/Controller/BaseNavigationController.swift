//
//  BaseNavigationController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/20/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        UINavigationBar.appearance().barTintColor = Theme.PrimaryColor
        self.navigationBar.tintColor = UIColor.white
    }
}
