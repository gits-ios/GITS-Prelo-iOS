//
//  NotificationPageInboxViewController.swift
//  Prelo
//
//  Created by Fransiska Hadiwidjana on 12/14/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

protocol NotificationPageInboxDelegate {
    func updateInboxBadgeNumber(count: Int)
}

class NotificationPageInboxViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UserRelatedDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var notifications : [CDNotification]?
    
    var allowLaunchLogin = true
    
    var delegate : NotificationPageInboxDelegate?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        var notificationPageCellNib = UINib(nibName: "NotificationPageCell", bundle: nil)
        tableView.registerNib(notificationPageCellNib, forCellReuseIdentifier: "NotificationPageCell")
        
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (User.IsLoggedIn == false) {
            if (allowLaunchLogin) {
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            }
        } else {
            self.refreshPage(false)
        }
    }
    
    func refreshPage(isRefreshFromSocket : Bool) {
        loadingPanel.hidden = false
        loading.startAnimating()
        tableView.hidden = true
        lblEmpty.hidden = true
        
        /* BLOK INI GA DIPAKE KARENA SEKARANG ANGKA NOTIF ADALAH ANGKA UNREAD BUKAN UNOPENED
        // Tell server that user opens notification page inbox
        // FIXME: OpenNotifs ganti dengan open inbox notif doang
        request(APINotif.OpenNotifs).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err)) {
                let json = JSON(res!)
                let data : Bool? = json["_data"].bool
                if (data != nil || data == true) {
                    println("data = \(data)")
                    
                    // Set number of notifications in top right bar with transaction & activity notifs, because inbox notifs have already opened
                    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let notifListener = delegate.preloNotifListener
                    if let nCount = CDNotification.setAllNotifInboxToOpened() {
                        notifListener.setNewNotifCount(nCount)
                    }
                    
                    // Retrieve notif data
                    if (self.notifications == nil || isRefreshFromSocket) { // Belum mengambil dari core data (baru membuka notif page) atau ada notif dari socket saat membuka notif page
                        // Ambil dari core data
                        self.notifications = CDNotification.getNotifInSection(NotificationType.Inbox)
                    }
                    
                    self.loadingPanel.hidden = true
                    self.loading.stopAnimating()
                    if (CDNotification.getNotifCountInSection(NotificationType.Inbox) == 0) { // Notif kosong
                        self.lblEmpty.hidden = false
                    } else { // Notif tidak kosong
                        self.tableView.hidden = false
                        self.setupTable()
                    }
                    
                    // Activate PreloNotifListenerDelegate
                    notifListener.delegate = self
                }
            } else {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        */
        
        // Retrieve notif data
        if (self.notifications == nil || isRefreshFromSocket) { // Belum mengambil dari core data (baru membuka notif page) atau ada notif dari socket saat membuka notif page
            // Ambil dari core data
            self.notifications = CDNotification.getNotifInSection(NotificationType.Inbox)
            let badgeNumber = CDNotification.getUnreadNotifCountInSection(NotificationType.Inbox)
            self.delegate?.updateInboxBadgeNumber(badgeNumber)
        }
        
        self.loadingPanel.hidden = true
        self.loading.stopAnimating()
        if (CDNotification.getNotifCountInSection(NotificationType.Inbox) == 0) { // Notif kosong
            self.lblEmpty.hidden = false
        } else { // Notif tidak kosong
            self.tableView.hidden = false
            self.setupTable()
        }
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func setupTable() {
        
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
    
    // MARK: - UserRelatedDelegate Functions
    
    func userCancelLogin() {
        allowLaunchLogin = false
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func userLoggedIn() {
        allowLaunchLogin = false
    }
    
    // MARK: - TableView Functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (notifications != nil) {
            return notifications!.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: NotificationPageCell = self.tableView.dequeueReusableCellWithIdentifier("NotificationPageCell") as! NotificationPageCell
        cell.selectionStyle = .None
        if (notifications != nil) {
            let notif : CDNotification = notifications![notifications!.count - (indexPath.row + 1)]
            cell.adapt(notif)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("Row \(indexPath.row) in section \(indexPath.section) selected")
        if (notifications != nil) {
            let notif : CDNotification = notifications![notifications!.count - (indexPath.row + 1)]
            
            // Cek apakah notif yang dibaca merupakan hasil merge
            if (notif.weight.integerValue > 1) {
                request(APINotif.ReadMultiNotif(objectId: notif.objectId, type: notif.type.stringValue)).responseJSON { req, resp, res, err in
                    if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err)) {
                        let json = JSON(res!)
                        let data : Bool? = json["_data"].bool
                        if (data != nil || data == true) {
                            println("data = \(data)")
                            
                            self.setNotifReadAndSetBadgeNumber(notif, index: indexPath.row)
                        }
                    }
                }
            } else { // weight = 1
                request(APINotif.ReadNotif(notifId: notif.ids)).responseJSON { req, resp, res, err in
                    if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err)) {
                        let json = JSON(res!)
                        let data : Bool? = json["_data"].bool
                        if (data != nil || data == true) {
                            println("data = \(data)")
                            
                            self.setNotifReadAndSetBadgeNumber(notif, index: indexPath.row)
                        }
                    }
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 72
    }
    
    // MARK: - Other functions
    
    func setNotifReadAndSetBadgeNumber(notif : CDNotification, index : Int) {
        // Set notif read attribute to true and set badge number in inbox tab
        self.notifications![self.notifications!.count - (index + 1)].read = true
        if let badgeNumber = CDNotification.setReadNotifInboxAndGetUnreadCount(notif.ids) {
            self.delegate?.updateInboxBadgeNumber(badgeNumber)
            let badgeNumberAll = CDNotification.getNewNotifCount()
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let notifListener = appDelegate.preloNotifListener
            notifListener.setNewNotifCount(badgeNumberAll)
            
            self.navigateReadNotif(notif)
        }
    }
    
    func navigateReadNotif(notif : CDNotification) {
        // Get inbox detail
        request(APIInbox.GetInboxMessage(inboxId: notif.objectId)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err)) {
                let json = JSON(res!)
                let data = json["_data"]
                println("data = \(data)")
                let inboxData = Inbox(jsn: data)
                
                // Goto inbox
                let t = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdTawar) as! TawarViewController
                t.tawarItem = inboxData
                self.navigationController?.pushViewController(t, animated: true)
            }
        }
    }
}