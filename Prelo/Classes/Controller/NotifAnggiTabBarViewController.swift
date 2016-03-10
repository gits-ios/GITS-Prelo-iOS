//
//  NotifAnggiTabBarViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/3/16.
//  Copyright (c) 2016 GITS Indonesia. All rights reserved.
//

import Foundation

class NotifAnggiTabBarViewController: BaseViewController, CarbonTabSwipeDelegate, NotifAnggiTransactionDelegate, NotifAnggiConversationDelegate, PreloNotifListenerDelegate, UserRelatedDelegate {
    
    var tabSwipe : CarbonTabSwipeNavigation?
    var notifAnggiTransactionVC : NotifAnggiTransactionViewController?
    var notifAnggiConversationVC : NotifAnggiConversationViewController?
    
    var transactionBadgeNumber : Int?
    var conversationBadgeNumber : Int?
    
    var allowLaunchLogin = true
    
    var isFirstAppear : Bool = true
    
    let TransactionBadgeRightOffset = 18
    let ConversationBadgeRightOffset = 13
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notifAnggiTransactionVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameNotifAnggiTransaction, owner: nil, options: nil).first as? NotifAnggiTransactionViewController
        notifAnggiTransactionVC?.delegate = self
        
        notifAnggiConversationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameNotifAnggiConversation, owner: nil, options: nil).first as? NotifAnggiConversationViewController
        notifAnggiConversationVC?.delegate = self
        
        tabSwipe = CarbonTabSwipeNavigation.alloc().createWithRootViewController(self, tabNames: ["TRANSACTION", "CONVERSATION"] as [AnyObject], tintColor: UIColor.whiteColor(), delegate: self)
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
            if (isFirstAppear) {
                isFirstAppear = false
                
                self.getUnreadNotifCount()
                self.refreshNotifPage()
            } else {
                self.notifAnggiTransactionVC?.hideLoading()
                self.notifAnggiTransactionVC?.showContent()
                self.notifAnggiConversationVC?.hideLoading()
                self.notifAnggiConversationVC?.showContent()
            }
            
            // Activate self as PreloNotifListenerDelegate
            let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let notifListener = delegate.preloNotifListener
            notifListener.delegate = self
        }
        
        // Remove redirect alert if any
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let redirAlert = appDelegate.redirAlert {
            redirAlert.dismissWithClickedButtonIndex(-1, animated: true)
        }
    }
        
    func tabSwipeNavigation(tabSwipe: CarbonTabSwipeNavigation!, viewControllerAtIndex index: UInt) -> UIViewController! {
        if (index == 0) { // Transaction
            return notifAnggiTransactionVC
        } else if (index == 1) { // Conversation
            return notifAnggiConversationVC
        }
        
        // Default
        let v = UIViewController()
        v.view.backgroundColor = UIColor.whiteColor()
        return v
    }
    
    func getUnreadNotifCount() {
        request(APINotifAnggi.GetUnreadNotifCount).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi - Unread Count")) {
                let json = JSON(res!)
                let data = json["_data"]
                
                self.transactionBadgeNumber = data["tp_notif"].intValue
                self.conversationBadgeNumber = data["conversation"].intValue
                
                self.tabSwipe?.setBadgeValues([self.transactionBadgeNumber!, self.conversationBadgeNumber!], andRightOffsets: [self.TransactionBadgeRightOffset, self.ConversationBadgeRightOffset])
            }
        }
    }
    
    // MARK: - UserRelatedDelegate functions
    
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
        self.notifAnggiTransactionVC?.refreshPage()
        self.notifAnggiConversationVC?.refreshPage()
    }
    
    // MARK: - NotifAnggi per tab delegate functions
    
    func decreaseTransactionBadgeNumber() {
        if (self.transactionBadgeNumber != nil && self.transactionBadgeNumber! > 0) {
            self.transactionBadgeNumber!--
            if (self.isBadgeValuesCompleted()) {
                tabSwipe?.setBadgeValues([self.transactionBadgeNumber!, self.conversationBadgeNumber!], andRightOffsets: [TransactionBadgeRightOffset, ConversationBadgeRightOffset])
                let badgeNumberAll = transactionBadgeNumber! + conversationBadgeNumber!
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let notifListener = appDelegate.preloNotifListener
                notifListener.setNewNotifCount(badgeNumberAll)
            }
        }
    }
    
    func decreaseConversationBadgeNumber() {
        if (self.conversationBadgeNumber != nil && self.conversationBadgeNumber! > 0) {
            self.conversationBadgeNumber!--
            if (self.isBadgeValuesCompleted()) {
                tabSwipe?.setBadgeValues([self.transactionBadgeNumber!, self.conversationBadgeNumber!], andRightOffsets: [TransactionBadgeRightOffset, ConversationBadgeRightOffset])
                let badgeNumberAll = transactionBadgeNumber! + conversationBadgeNumber!
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let notifListener = appDelegate.preloNotifListener
                notifListener.setNewNotifCount(badgeNumberAll)
            }
        }
    }
    
    // MARK: - Other functions
    
    func isBadgeValuesCompleted() -> Bool {
        return (self.transactionBadgeNumber != nil && self.conversationBadgeNumber != nil)
    }
}