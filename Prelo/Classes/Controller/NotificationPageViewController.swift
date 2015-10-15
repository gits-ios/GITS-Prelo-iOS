//
//  NotificationPageViewController.swift
//  Prelo
//
//  Created by Fransiska on 10/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class NotificationPageViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, PreloNotifListenerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    lazy var notifSections : [String] = {
        [unowned self] in
        return [NotificationType.Transaksi, NotificationType.Inbox, NotificationType.Aktivitas]
    }()
    
    var notifications : [String : [CDNotification]]?
    
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
        let newBackButton = UIBarButtonItem(title: " Notifikasi", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.sharedInstance().track("Notification Page")
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        self.refreshPage(false)
    }
    
    func refreshPage(isRefreshFromSocket : Bool) {
        loadingPanel.hidden = false
        loading.startAnimating()
        tableView.hidden = true
        lblEmpty.hidden = true
        
        // Tell server that the user opens notification page
        request(APINotif.OpenNotifs).responseJSON {req, _, res, err in
            println("Open notif req = \(req)")
            if (err != nil) { // Terdapat error
                Constant.showDialog("Warning", message: "Refreshing notifications error: \(err!.description)")
                self.navigationController?.popViewControllerAnimated(true)
            } else {
                let json = JSON(res!)
                let data : Bool? = json["_data"].bool
                if (data == nil || data == false) { // Gagal
                    Constant.showDialog("Warning", message: "Refreshing notifications error")
                    self.navigationController?.popViewControllerAnimated(true)
                } else { // Berhasil
                    println("Data: \(data)")
                    
                    // Set the number of notifications in top right bar to 0
                    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let notifListener = delegate.preloNotifListener
                    if (notifListener.newNotifCount != 0) {
                        notifListener.setNewNotifCount(0)
                        // Set all notif data to opened
                        CDNotification.setAllNotifToOpened()
                    }
                    
                    // Retrieve notif data
                    if (self.notifications == nil || isRefreshFromSocket) { // Belum mengambil dari core data (baru membuka notif page) atau ada notif dari socket saat membuka notif page
                        // Ambil dari core data
                        self.notifications = [:]
                        for s in self.notifSections {
                            self.notifications!.updateValue(CDNotification.getNotifInSection(s), forKey: s)
                        }
                    }
                    
                    self.loadingPanel.hidden = true
                    self.loading.stopAnimating()
                    if (CDNotification.getNotifCount() == 0) { // Notif kosong
                        self.lblEmpty.hidden = false
                    } else { // Notif tidak kosong
                        self.tableView.hidden = false
                        self.setupTable()
                    }
                    
                    // Activate PreloNotifListenerDelegate
                    notifListener.delegate = self
                }
            }
        }
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    static func refreshNotifications() {
        CDNotification.deleteAll()
        if (User.IsLoggedIn) {
            request(APINotif.GetNotifs).responseJSON {req, _, res, err in
                println("Get notif req = \(req)")
                if (err != nil) { // Terdapat error
                    Constant.showDialog("Warning", message: "Error getting notifications: \(err!.description)")
                } else {
                    let json = JSON(res!)
                    let data = json["_data"]
                    if (data == nil || data == []) { // Data kembalian kosong
                        println("Empty notif")
                    } else { // Berhasil
                        println("Notifs: \(data)")
                        
                        // Store data into core data
                        // Tambahin dengan urutan notif terbaru ada di index akhir, agar bila ada notif baru dari socket urutannya tetap terjaga
                        for (i : String, notifs : JSON) in data {
                            for (var j = notifs.count - 1; j >= 0; j--) {
                                let n : JSON = notifs[j]
                                var notifType : String = ""
                                if (i == "tp_notif") { // Transaksi
                                    notifType = NotificationType.Transaksi
                                } else if (i == "inbox") { // Inbox FIXME: keyword "inbox" belum fix
                                    notifType = NotificationType.Inbox
                                } else if (i == "activity") { // Aktivitas
                                    notifType = NotificationType.Aktivitas
                                }
                                CDNotification.newOne(notifType, id : n["_id"].string!, opened : n["opened"].bool!, read : n["read"].bool!, message: n["text"].string!, ownerId: n["owner_id"].string!, name: n["name"].string!, type: n["type"].int!, objectName: n["object_name"].string!, objectId: n["object_id"].string!, time: n["time"].string!, leftImage: n["left_image"].string!, rightImage: n["right_image"].string)
                            }
                        }
                        
                        // Set the number of notifications in top right bar
                        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
                        let notifListener = delegate.preloNotifListener
                        notifListener.setNewNotifCount(CDNotification.getNewNotifCount())
                    }
                }
            }
        }
    }
    
    func setupTable() {
        
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
    }
    
    // MARK: - TableViewDelegate Functions
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return notifSections.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return notifSections[section]
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle : String = notifSections[section]
        let sectionNotifs : [CDNotification] = notifications![sectionTitle]!
        return sectionNotifs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: NotificationPageCell = self.tableView.dequeueReusableCellWithIdentifier("NotificationPageCell") as! NotificationPageCell
        let sectionTitle : String = notifSections[indexPath.section]
        let sectionNotifs : [CDNotification] = notifications![sectionTitle]!
        let notif : CDNotification = sectionNotifs[sectionNotifs.count - (indexPath.row + 1)]
        cell.adapt(notif)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("Row \(indexPath.row) in section \(indexPath.section) selected")
        let sectionTitle : String = notifSections[indexPath.section]
        let sectionNotifs : [CDNotification] = notifications![sectionTitle]!
        let notif : CDNotification = sectionNotifs[sectionNotifs.count - (indexPath.row + 1)]
        request(APINotif.ReadNotif(notifId: notif.id)).responseJSON {req, _, res, err in
            println("Read notif req = \(req)")
            if (err != nil) { // Terdapat error
                println("Send read notifications error: \(err!.description)")
            } else {
                let json = JSON(res!)
                let data : Bool? = json["_data"].bool
                if (data == nil || data == false) { // Gagal
                    println("Send read notifications error")
                } else { // Berhasil
                    println("Data: \(data)")
                    
                    if (sectionTitle == NotificationType.Transaksi) {
                        // Goto transaction detail
                        if (notif.ownerId == User.Id) { // User is seller
                            // Goto MyProductDetail
                            let myProductDetailVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyProductDetail, owner: nil, options: nil).first as! MyProductDetailViewController
                            myProductDetailVC.transactionId = notif.objectId
                            self.navigationController?.pushViewController(myProductDetailVC, animated: true)
                        } else { // User is buyer
                            // Goto MyPurchaseDetail
                            let myPurchaseDetailVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchaseDetail, owner: nil, options: nil).first as! MyPurchaseDetailViewController
                            myPurchaseDetailVC.transactionId = notif.objectId
                            self.navigationController?.pushViewController(myPurchaseDetailVC, animated: true)
                        }
                    } else if (sectionTitle == NotificationType.Inbox) {
                        // TODO: goto inbox
                    } else if (sectionTitle == NotificationType.Aktivitas) {
                        // Get product detail from API
                        request(Products.Detail(productId: notif.objectId)).responseJSON {req, _, res, err in
                            println("Get product detail req = \(req)")
                            if (err != nil) { // Terdapat error
                                Constant.showDialog("Warning", message: "Error getting product detail: \(err!.description)")
                            } else {
                                let json = JSON(res!)
                                if (json == nil || json == []) { // Data kembalian kosong
                                    println("Empty product detail")
                                } else { // Berhasil
                                    let pDetail = ProductDetail.instance(json)
                                    
                                    // Goto product comments
                                    let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdProductComments) as! ProductCommentsController
                                    p.pDetail = pDetail
                                    self.navigationController?.pushViewController(p, animated: true)
                                }
                            }
                        }
                    }
                    
                    // TODO: Delete notif from core data and refresh table
                    
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 72
    }
    
    // MARK: - PreloNotifListenerDelegate function
    
    override func showNewNotifCount(count: Int) {
        // Do nothing
    }
    
    override func refreshNotifPage() {
        self.refreshPage(true)
    }
}

class NotificationPageCell : UITableViewCell {
    
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    
    func adapt(notif : CDNotification) {
        // Set images
        imgUser.setImageWithUrl(NSURL(string: notif.leftImage)!, placeHolderImage: nil)
        if (notif.rightImage != nil) {
            imgProduct.setImageWithUrl(NSURL(string: notif.rightImage!)!, placeHolderImage: nil)
        }
        
        // Set texts
        let nsMsg = notif.message as NSString
        var msgAttrString = NSMutableAttributedString(string: notif.message, attributes: [NSFontAttributeName: AppFont.PreloAwesome.getFont(12)!])
        msgAttrString.addAttribute(NSForegroundColorAttributeName, value: Theme.GrayDark, range: nsMsg.rangeOfString(notif.message))
        msgAttrString.addAttribute(NSForegroundColorAttributeName, value: Theme.PrimaryColor, range: nsMsg.rangeOfString(notif.name))
        msgAttrString.addAttribute(NSForegroundColorAttributeName, value: Theme.PrimaryColor, range: nsMsg.rangeOfString(notif.objectName))
        lblMessage.attributedText = msgAttrString
        lblTime.text = notif.time
    }
}