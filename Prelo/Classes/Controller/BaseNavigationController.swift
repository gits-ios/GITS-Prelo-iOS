//
//  BaseNavigationController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/20/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class BaseNavigationController: AHKNavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        // Do any additional setup after loading the view.
        
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        UINavigationBar.appearance().barTintColor = Theme.PrimaryColor
        self.navigationBar.tintColor = UIColor.white
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        return super.popViewController(animated: animated)
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        return super.popToRootViewController(animated: animated)
    }
    
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        return super.popToViewController(viewController, animated: animated)
    }
}
