//
//  NotifAnggiTabBarViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/3/16.
//  Copyright (c) 2016 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Main Class

class NotifAnggiTabBarViewController: BaseViewController, CarbonTabSwipeDelegate, NotifAnggiTransactionDelegate, NotifAnggiConversationDelegate, UserRelatedDelegate/*, UIActionSheetDelegate, UIAlertViewDelegate*/ {
    
    var tabSwipe : CarbonTabSwipeNavigation?
    var notifAnggiTransactionVC : NotifAnggiTransactionViewController?
    var notifAnggiConversationVC : NotifAnggiConversationViewController?
    
    var transactionBadgeNumber : Int?
    var conversationBadgeNumber : Int?
    
    var allowLaunchLogin = true
    
    var isFirstAppear : Bool = true
    
    let TransactionBadgeRightOffset = 18
    let ConversationBadgeRightOffset = 13
    
    var isBackTwice : Bool = false
    var isNavCtrlsChecked : Bool = false
    
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
        
        // option button
        setOptionButton()
        
        // swipe gesture for carbon (pop view)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        
        let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
        vwLeft.backgroundColor = UIColor.clear
        vwLeft.addGestureRecognizer(swipeRight)
        self.view.addSubview(vwLeft)
        self.view.bringSubview(toFront: vwLeft)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.Notification)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Notification)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        if (User.IsLoggedIn == false) {
            if (allowLaunchLogin) {
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            }
        } else {
            if (isFirstAppear) {
                isFirstAppear = false
                
                self.notifAnggiTransactionVC?.previousScreen = self.previousScreen
                self.notifAnggiConversationVC?.previousScreen = self.previousScreen
                
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
        
        /*
        // Back action handling
        if (!isNavCtrlsChecked && isBackTwice) {
            var x = self.navigationController?.viewControllers
            x?.remove(at: (x?.count)! - 2)
            if (x == nil) {
                x = []
            }
            self.navigationController?.setViewControllers(x!, animated: false)
            isNavCtrlsChecked = true
        }
         */
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        if let count = self.navigationController?.viewControllers.count, isBackTwice {
            _ = self.navigationController?.popToViewController((self.navigationController?.viewControllers[count-3])!, animated: true)
        }
        
        _ = self.navigationController?.popViewController(animated: true)
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
        let _ = request(APINotification.getUnreadNotifCount).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Notifikasi - Unread Count")) {
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
        _ = self.navigationController?.popViewController(animated: true)
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
    
    override func showCartCount(_ count: Int) {
        // Do nothing
    }
    
    override func refreshCartPage() {
        // Do nothing
    }
    
    override func increaseCartCount(_ value: Int) {
        // Do nothing
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
    
    // MARK: - option button (right top)
    func setOptionButton() {
        let btnOption = self.createButtonWithIcon(AppFont.prelo2, icon: "")
        
        btnOption.addTarget(self, action: #selector(NotifAnggiTabBarViewController.option), for: UIControlEvents.touchUpInside)
        
        self.navigationItem.rightBarButtonItem = btnOption.toBarButton()
    }
    
    func option()
    {
//        let a = UIActionSheet(title: "Opsi", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)
//        a.addButton(withTitle: "Hapus Pesan")
//        a.addButton(withTitle: "Batal")
//        a.cancelButtonIndex = 1
//        
//        // bound location
//        let screenSize: CGRect = UIScreen.main.bounds
//        let screenWidth = screenSize.width
//        let bounds = CGRect(x: screenWidth - 65.0, y: 0.0, width: screenWidth, height: 0.0)
//        
//        a.show(from: bounds, in: self.view, animated: true)
        
        let a = UIAlertController(title: "Opsi", message: nil, preferredStyle: .actionSheet)
        a.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        a.addAction(UIAlertAction(title: "Hapus Pesan", style: .default, handler: { action in
            let activeTab = self.tabSwipe?.currentTabIndex
            if (activeTab == 0) { // Transaction
                self.notifAnggiTransactionVC?.isToDelete = true
                self.notifAnggiTransactionVC?.consHeightCheckBoxAll.constant = 56
                self.notifAnggiTransactionVC?.consHeightButtonView.constant = 56
                self.notifAnggiTransactionVC?.tableView.reloadData()
            } else { // Conversation
                self.notifAnggiConversationVC?.isToDelete = true
                self.notifAnggiConversationVC?.consHeightCheckBoxAll.constant = 56
                self.notifAnggiConversationVC?.consHeightButtonView.constant = 56
                self.notifAnggiConversationVC?.tableView.reloadData()
            }
            a.dismiss(animated: true, completion: nil)
        }))
        a.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { action in
            a.dismiss(animated: true, completion: nil)
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(a, animated: true, completion: nil)
    }
    
//    func actionSheet(_ actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
//        if (buttonIndex == 0)
//        {
//            // do something
//            let activeTab = self.tabSwipe?.currentTabIndex
//            if (activeTab == 0) { // Transaction
////                Constant.showDialog("Hapus Notifikasi", message: "Transaksi")
//                self.notifAnggiTransactionVC?.isToDelete = true
//                self.notifAnggiTransactionVC?.consHeightCheckBoxAll.constant = 56
//                self.notifAnggiTransactionVC?.consHeightButtonView.constant = 56
//                self.notifAnggiTransactionVC?.tableView.reloadData()
//            } else { // Conversation
////                Constant.showDialog("Hapus Notifikasi", message: "Percakapan")
//                self.notifAnggiConversationVC?.isToDelete = true
//                self.notifAnggiConversationVC?.consHeightCheckBoxAll.constant = 56
//                self.notifAnggiConversationVC?.consHeightButtonView.constant = 56
//                self.notifAnggiConversationVC?.tableView.reloadData()
//            }
//        }
//    }
    
    // MARK: - Other functions
    
    func isBadgeValuesCompleted() -> Bool {
        return (self.transactionBadgeNumber != nil && self.conversationBadgeNumber != nil)
    }
    
    // MARK: - Swipe Navigation Override
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                //print("Swiped right")
                
                // gesture override
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                
                if let count = self.navigationController?.viewControllers.count, isBackTwice {
                    _ = self.navigationController?.popToViewController((self.navigationController?.viewControllers[count-3])!, animated: true)
                }
                
                _ = self.navigationController?.popViewController(animated: true)
                
            default:
                break
            }
        }
    }
}
