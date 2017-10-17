//
//  StatusBarContainerViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/24/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import CoreData
import Crashlytics
import Alamofire

class StatusBarContainerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        reloadingAppData()
    }
    
    func changeStatusBarColor(_ notif : Foundation.Notification) {
        if let c = notif.object as? UIColor {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.backgroundColor = c
            })
        }
    }
}
