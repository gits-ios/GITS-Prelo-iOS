//
//  NotificationPageTabbedViewController.swift
//  Prelo
//
//  Created by Fransiska Hadiwidjana on 12/14/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class NotificationPageTabbedViewController: BaseViewController, CarbonTabSwipeDelegate, NotificationPageActivityDelegate, NotificationPageInboxDelegate, NotificationPageTransactionDelegate, PreloNotifListenerDelegate, UserRelatedDelegate {
    
    var tabSwipe : CarbonTabSwipeNavigation?
    var notificationPageTransactionVC : NotificationPageTransactionViewController?
    var notificationPageInboxVC : NotificationPageInboxViewController?
    var notificationPageActivityVC : NotificationPageActivityViewController?
    
    var isRefresh : Bool = false
    
    var transactionBadgeNumber : Int?
    var inboxBadgeNumber : Int?
    var activityBadgeNumber : Int?
    
    var allowLaunchLogin = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationPageTransactionVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameNotificationPageTransaction, owner: nil, options: nil).first as? NotificationPageTransactionViewController
        notificationPageTransactionVC?.delegate = self
        
        notificationPageInboxVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameNotificationPageInbox, owner: nil, options: nil).first as? NotificationPageInboxViewController
        notificationPageInboxVC?.delegate = self
        
        notificationPageActivityVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameNotificationPageActivity, owner: nil, options: nil).first as? NotificationPageActivityViewController
        notificationPageActivityVC?.delegate = self
                
        tabSwipe = CarbonTabSwipeNavigation.alloc().createWithRootViewController(self, tabNames: ["Transaksi", "Inbox", "Aktivitas"] as [AnyObject], tintColor: UIColor.whiteColor(), delegate: self)
        tabSwipe?.addShadow()
        
        tabSwipe?.setNormalColor(Theme.TabNormalColor)
        tabSwipe?.colorIndicator = Theme.PrimaryColorDark
        tabSwipe?.setSelectedColor(Theme.TabSelectedColor)
        
        // Set title
        self.title = "Notifikasi"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.Notification)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Notification)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (User.IsLoggedIn == false) {
            if (allowLaunchLogin) {
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            }
        } else {
            // isRefresh digunakan agar refresh tidak dilakukan waktu pertama kali appear, namun appear berikutnya selalu dilakukan
            if (isRefresh) {
                if let currentTabIndex = tabSwipe?.currentTabIndex {
                    //println("currentTabIndex = \(currentTabIndex)")
                    self.tabSwipeNavigation(self.tabSwipe, viewControllerAtIndex: currentTabIndex).viewDidAppear(true)
                }
            } else {
                isRefresh = true
                
                if let currentTabIndex = tabSwipe?.currentTabIndex {
                    //println("currentTabIndex = \(currentTabIndex)")
                    self.tabSwipeNavigation(self.tabSwipe, viewControllerAtIndex: currentTabIndex).viewDidAppear(true)
                }
                
                self.transactionBadgeNumber = CDNotification.getUnreadNotifCountInSection(NotificationType.Transaksi)
                self.inboxBadgeNumber = CDNotification.getUnreadNotifCountInSection(NotificationType.Inbox)
                self.activityBadgeNumber = CDNotification.getUnreadNotifCountInSection(NotificationType.Aktivitas)
                tabSwipe?.setBadgeValues([self.transactionBadgeNumber!, self.inboxBadgeNumber!, self.activityBadgeNumber!], andRightOffsets: [10, 24, 15])
            }
            
            // Activate PreloNotifListenerDelegate
            let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let notifListener = delegate.preloNotifListener
            notifListener.delegate = self
        }
    }
    
    func tabSwipeNavigation(tabSwipe: CarbonTabSwipeNavigation!, viewControllerAtIndex index: UInt) -> UIViewController! {
        if (index == 0) { // Transaksi
            return notificationPageTransactionVC
        } else if (index == 1) { // Inbox
            return notificationPageInboxVC
        } else if (index == 2) { // Aktivitas
            return notificationPageActivityVC
        }
        
        // Default
        let v = UIViewController()
        v.view.backgroundColor = UIColor.whiteColor()
        return v
    }
    
    // MARK: - UserRelatedDelegate Functions
    
    func userCancelLogin() {
        allowLaunchLogin = false
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func userLoggedIn() {
        allowLaunchLogin = false
    }
    
    // MARK: - PreloNotifListenerDelegate functions
    
    override func showNewNotifCount(count: Int) {
        // Do nothing
    }
    
    override func refreshNotifPage() {
        self.notificationPageTransactionVC?.refreshPage(true)
        self.notificationPageInboxVC?.refreshPage(true)
        self.notificationPageActivityVC?.refreshPage(true)
    }
    
    // MARK: - NotificationPage per tab delegate functions
    
    func updateTransactionBadgeNumber(count: Int) {
        self.transactionBadgeNumber = count
        if (self.isBadgeValuesCompleted()) {
            tabSwipe?.setBadgeValues([self.transactionBadgeNumber!, self.inboxBadgeNumber!, self.activityBadgeNumber!], andRightOffsets: [10, 24, 15])
        }
    }
    
    func updateInboxBadgeNumber(count: Int) {
        self.inboxBadgeNumber = count
        if (self.isBadgeValuesCompleted()) {
            tabSwipe?.setBadgeValues([self.transactionBadgeNumber!, self.inboxBadgeNumber!, self.activityBadgeNumber!], andRightOffsets: [10, 24, 15])
        }
    }
    
    func updateActivityBadgeNumber(count: Int) {
        self.activityBadgeNumber = count
        if (self.isBadgeValuesCompleted()) {
            tabSwipe?.setBadgeValues([self.transactionBadgeNumber!, self.inboxBadgeNumber!, self.activityBadgeNumber!], andRightOffsets: [10, 24, 15])
        }
    }
    
    // MARK: - Other functions
    
    func isBadgeValuesCompleted() -> Bool {
        return (self.transactionBadgeNumber != nil && self.inboxBadgeNumber != nil && self.activityBadgeNumber != nil)
    }
}