//
//  NotifAnggiTabBarViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/3/16.
//  Copyright (c) 2016 GITS Indonesia. All rights reserved.
//

import Foundation

class NotifAnggiTabBarViewController: BaseViewController, CarbonTabSwipeDelegate, NotifAnggiTransactionDelegate, NotifAnggiConversationDelegate, UserRelatedDelegate {
    
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
        
        notifAnggiTransactionVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTransaction, owner: nil, options: nil)?.first as? NotifAnggiTransactionViewController
        notifAnggiTransactionVC?.delegate = self
        
        notifAnggiConversationVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiConversation, owner: nil, options: nil)?.first as? NotifAnggiConversationViewController
        notifAnggiConversationVC?.delegate = self
        
        tabSwipe = CarbonTabSwipeNavigation().create(withRootViewController: self, tabNames: ["TRANSAKSI" as AnyObject, "PERCAKAPAN" as AnyObject] as [AnyObject], tintColor: UIColor.white, delegate: self)
        tabSwipe?.addShadow()
        tabSwipe?.setNormalColor(Theme.TabNormalColor)
        tabSwipe?.colorIndicator = Theme.PrimaryColorDark
        tabSwipe?.setSelectedColor(Theme.TabSelectedColor)
        
        // Set title
        self.title = "Notifikasi"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.Notification)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Notification)
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let notifListener = delegate.preloNotifListener
            notifListener?.delegate = self
        }
    }
        
    func tabSwipeNavigation(_ tabSwipe: CarbonTabSwipeNavigation!, viewControllerAt index: UInt) -> UIViewController! {
        if (index == 0) { // Transaction
            return notifAnggiTransactionVC
        } else if (index == 1) { // Conversation
            return notifAnggiConversationVC
        }
        
        // Default
        let v = UIViewController()
        v.view.backgroundColor = UIColor.white
        return v
    }
    
    func getUnreadNotifCount() {
        // API Migrasi
        request(APINotifAnggi.getUnreadNotifCount).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Notifikasi - Unread Count")) {
                let json = JSON(resp.result.value!)
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
        self.navigationController?.popViewController(animated: true)
    }
    
    func userLoggedIn() {
        allowLaunchLogin = false
    }
    
    // MARK: - PreloNotifListenerDelegate functions
    
    override func showNewNotifCount(_ count: Int) {
        // Do nothing
    }
    
    override func refreshNotifPage() {
        self.notifAnggiTransactionVC?.refreshPage()
        self.notifAnggiConversationVC?.refreshPage()
    }
    
    // MARK: - NotifAnggi per tab delegate functions
    
    func decreaseTransactionBadgeNumber() {
        if (self.transactionBadgeNumber != nil && self.transactionBadgeNumber! > 0) {
            self.transactionBadgeNumber! -= 1
            if (self.isBadgeValuesCompleted()) {
                tabSwipe?.setBadgeValues([self.transactionBadgeNumber!, self.conversationBadgeNumber!], andRightOffsets: [TransactionBadgeRightOffset, ConversationBadgeRightOffset])
                let badgeNumberAll = transactionBadgeNumber! + conversationBadgeNumber!
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let notifListener = appDelegate.preloNotifListener
                notifListener?.setNewNotifCount(badgeNumberAll)
            }
        }
    }
    
    func decreaseConversationBadgeNumber() {
        if (self.conversationBadgeNumber != nil && self.conversationBadgeNumber! > 0) {
            self.conversationBadgeNumber! -= 1
            if (self.isBadgeValuesCompleted()) {
                tabSwipe?.setBadgeValues([self.transactionBadgeNumber!, self.conversationBadgeNumber!], andRightOffsets: [TransactionBadgeRightOffset, ConversationBadgeRightOffset])
                let badgeNumberAll = transactionBadgeNumber! + conversationBadgeNumber!
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let notifListener = appDelegate.preloNotifListener
                notifListener?.setNewNotifCount(badgeNumberAll)
            }
        }
    }
    
    // MARK: - Other functions
    
    func isBadgeValuesCompleted() -> Bool {
        return (self.transactionBadgeNumber != nil && self.conversationBadgeNumber != nil)
    }
}
