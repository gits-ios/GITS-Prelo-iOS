//
//  CheckoutTourViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/26/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class CheckoutTourViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.CheckoutTutorial)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.CheckoutTutorial)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func next(_ sender : AnyObject?)
    {
        self.dismiss(animated: true, completion: nil)
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
