//
//  ViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CarbonKit
import KYDrawerController

class ViewController: UIViewController, CarbonTabSwipeDelegate, KYDrawerControllerDelegate {

    var tabSwipe : CarbonTabSwipeNavigation?
    var drawerController : KYDrawerController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabSwipe = CarbonTabSwipeNavigation.alloc().createWithRootViewController(self, tabNames: ["One", "Two", "Three", "Four", "Five"], tintColor: UIColor.whiteColor(), delegate: self)
        tabSwipe?.addShadow()
        if (drawerController != nil) {
            tabSwipe?.failGesture = drawerController?.getSscreenEdgePanGestureX()
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tabSwipeNavigation(tabSwipe: CarbonTabSwipeNavigation!, viewControllerAtIndex index: UInt) -> UIViewController! {
        let v:UIViewController = self.storyboard?.instantiateViewControllerWithIdentifier("test") as! UIViewController
        return v
    }
    
    func drawerControllerCameForVisit(drawerController: KYDrawerController) {
        self.drawerController = drawerController
        self.tabSwipe?.failGesture = drawerController.getSscreenEdgePanGestureX()
    }

}

