//
//  StatusBarContainerViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class StatusBarContainerViewController: UIViewController
{

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(StatusBarContainerViewController.changeStatusBarColor(_:)), name: NSNotification.Name(rawValue: "changeStatusBarColor"), object: nil)
    }
    
    func changeStatusBarColor(_ notif : Foundation.Notification)
    {
        if let c = notif.object as? UIColor
        {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.backgroundColor = c
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
