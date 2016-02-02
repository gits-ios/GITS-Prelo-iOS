//
//  NotificationPageViewController.swift
//  Prelo
//
//  Created by Fransiska on 10/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class NotificationPageViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, PreloNotifListenerDelegate, UserRelatedDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    lazy var notifSections : [String] = {
        [unowned self] in
        return [NotificationType.Transaksi, NotificationType.Inbox, NotificationType.Aktivitas]
    }()
    
    var notifications : [String : [CDNotification]]?
    
    var allowLaunchLogin = true
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        var notificationPageCellNib = UINib(nibName: "NotificationPageCell", bundle: nil)
        tableView.registerNib(notificationPageCellNib, forCellReuseIdentifier: "NotificationPageCell")
        
        // Set title
        self.title = "Notifikasi"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.Notification)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Notification)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
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
        
        // Tell server that the user opens notification page
        request(APINotif.OpenNotifs).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi")) {
                let json = JSON(res!)
                let data : Bool? = json["_data"].bool
                
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
            } else {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
    
    static func refreshNotifications() {
        CDNotification.deleteAll()
        if (User.IsLoggedIn) {
            request(APINotif.GetNotifs).responseJSON { req, resp, res, err in
                if (APIPrelo.validate(false, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi")) {
                    let json = JSON(res!)
                    let data = json["_data"]
                    
                    // No merge, after hours making merge notification, LOOOOOOOOOL
                    var resNotifs : [[String : AnyObject]] = [[String : AnyObject]]() // Untuk menyimpan daftar notif
                    for (i : String, jNotifs : JSON) in data {
                        var notifs : [JSON] = jNotifs.arrayValue
                        var j : Int = 0
                        while (j < notifs.count) {
                            let n : JSON = notifs[j]
                            println("n = \(n)")
                            var nWeight : Int = 1
                            var nNames : String = n["name"].string!
                            var nIds : String = n["_id"].string!
                            
                            // Bentuk resNotif
                            var resNotif : [String : AnyObject] = [:]
                            resNotif["ids"] = n["_id"].stringValue
                            resNotif["opened"] = n["opened"].boolValue
                            resNotif["read"] = n["read"].boolValue
                            resNotif["owner_id"] = n["owner_id"].stringValue
                            resNotif["type"] = n["type"].numberValue
                            resNotif["object_name"] = n["object_name"].stringValue
                            resNotif["object_id"] = n["object_id"].stringValue
                            resNotif["time"] = n["time"].stringValue
                            resNotif["left_image"] = n["left_image"].stringValue
                            resNotif["right_image"] = n["right_image"].stringValue
                            resNotif["weight"] = 1
                            resNotif["names"] = n["name"].stringValue
                            resNotif["name"] = n["name"].stringValue
                            resNotif["text"] = n["text"].stringValue
                            
                            var notifType : String = ""
                            if (i == "tp_notif") { // Transaksi
                                notifType = NotificationType.Transaksi
                            } else if (i == "inbox_notif") { // Inbox
                                notifType = NotificationType.Inbox
                            } else if (i == "activity") { // Aktivitas
                                notifType = NotificationType.Aktivitas
                            }
                            resNotif["notif_type"] = notifType
                            //println("resNotif = \(resNotif)")
                            
                            // Add to resNotifs
                            resNotifs.append(resNotif)
                            
                            // Next index
                            j++
                        }
                    }
                    
                    /* TO BE DELETED, merged version, hiks T^T
                    // Merge notif dengan objectId dan type yang sama sebelum disimpan di core data
                    // Khusus untuk transaksi, merge notif dengan objectId a.k.a transaction id yg sama
                    var resNotifs : [[String : AnyObject]] = [[String : AnyObject]]() // Untuk menyimpan daftar notif yang sudah di merge
                    for (i : String, jNotifs : JSON) in data {
                    var notifs : [JSON] = jNotifs.arrayValue
                    var j : Int = 0
                    while (j < notifs.count) {
                    let n : JSON = notifs[j]
                    //println("n = \(n)")
                    var nWeight : Int = 1
                    var nNames : String = n["name"].string!
                    var nIds : String = n["_id"].string!
                    var k : Int = j + 1
                    while (k < notifs.count) {
                    // Cari yang sama, kalo ketemu gabungin
                    let n2 : JSON = notifs[k]
                    //println("n2 = \(n2)")
                    
                    if ((i == "tp_notif") && (n["object_id"].string! == n2["object_id"].string!)) { // Notif transaksi yg sama
                    
                    //println("merge n2 to n")
                    // Tambahkan weight
                    nWeight++
                    
                    // Gabungkan id
                    let n2Id : String = n2["_id"].string!
                    nIds = "\(nIds);\(n2Id)"
                    
                    // Hapus n2
                    notifs.removeAtIndex(k)
                    } else if ((n["object_id"].string! == n2["object_id"].string!) && (n["type"].numberValue == n2["type"].numberValue)) { // Notif inbox/aktivitas yg sama
                    
                    //println("merge n2 to n")
                    // Tambahkan weight
                    nWeight++
                    
                    // Tambahkan jika nama belum ada di names
                    if (nNames.rangeOfString(n2["name"].string!) == nil) {
                    //println("merge n2 name to n")
                    let n2Name : String = n2["name"].string!
                    nNames = "\(nNames);\(n2Name)"
                    }
                    
                    // Gabungkan id
                    let n2Id : String = n2["_id"].string!
                    nIds = "\(nIds);\(n2Id)"
                    
                    // Hapus n2
                    notifs.removeAtIndex(k)
                    } else {
                    // Next index
                    k++
                    }
                    }
                    
                    // Di sini semua objek di notifs yang sama dengan n sudah dimerge dan dihapus
                    // Bentuk resNotif
                    var resNotif : [String : AnyObject] = [:]
                    resNotif["ids"] = nIds
                    resNotif["opened"] = n["opened"].bool!
                    resNotif["read"] = n["read"].bool!
                    resNotif["owner_id"] = n["owner_id"].string!
                    resNotif["type"] = n["type"].number!
                    resNotif["object_name"] = n["object_name"].string!
                    resNotif["object_id"] = n["object_id"].string!
                    resNotif["time"] = n["time"].string!
                    resNotif["left_image"] = n["left_image"].string!
                    resNotif["right_image"] = n["right_image"].string
                    resNotif["weight"] = nWeight
                    resNotif["names"] = nNames
                    // Sesuaikan text dan name
                    let namesArr = split(nNames) {$0 == ";"}
                    if (namesArr.count > 1) {
                    resNotif["name"] = n["name"].string! + " dan \(namesArr.count - 1) lainnya"
                    resNotif["text"] = n["text"].string!.stringByReplacingOccurrencesOfString(n["name"].string!, withString: n["name"].string! + " dan \(namesArr.count - 1) lainnya")
                    } else {
                    resNotif["name"] = n["name"].string!
                    resNotif["text"] = n["text"].string!
                    }
                    var notifType : String = ""
                    if (i == "tp_notif") { // Transaksi
                    notifType = NotificationType.Transaksi
                    } else if (i == "inbox_notif") { // Inbox
                    notifType = NotificationType.Inbox
                    } else if (i == "activity") { // Aktivitas
                    notifType = NotificationType.Aktivitas
                    }
                    resNotif["notif_type"] = notifType
                    //println("resNotif = \(resNotif)")
                    
                    // Add to resNotifs
                    resNotifs.append(resNotif)
                    
                    // Next index
                    j++
                    }
                    }*/
                    
                    // Simpan isi resNotifs ke core data
                    // Kondisi resNotifs, notif terbaru ada di index awal
                    // Simpan di core data dengan urutan notif terbaru ada di index akhir, agar bila ada notif baru dari socket tinggal dipasang di akhir sehingga urutannya tetap terjaga
                    for (var l = resNotifs.count - 1; l >= 0; l--) {
                        let rN = resNotifs[l]
                        CDNotification.newOne(rN["notif_type"]! as! String, ids: rN["ids"]! as! String, opened: rN["opened"]! as! Bool, read: rN["read"]! as! Bool, message: rN["text"]! as! String, ownerId: rN["owner_id"]! as! String, name: rN["name"]! as! String, type: rN["type"]! as! NSNumber, objectName: rN["object_name"]! as! String, objectId: rN["object_id"]! as! String, time: rN["time"]! as! String, leftImage: rN["left_image"]! as! String, rightImage: rN["right_image"] as? String, weight: rN["weight"]! as! NSNumber, names: rN["names"] as! String)
                    }
                    
                    // Set the number of notifications in top right bar
                    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let notifListener = delegate.preloNotifListener
                    notifListener.setNewNotifCount(CDNotification.getNewNotifCount())
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
    
    // MARK: - UserRelatedDelegate Functions
    
    func userCancelLogin() {
        allowLaunchLogin = false
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func userLoggedIn() {
        allowLaunchLogin = false
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
        var sectionNotifs : [CDNotification] = notifications![sectionTitle]!
        let notif : CDNotification = sectionNotifs[sectionNotifs.count - (indexPath.row + 1)]
        
        // Cek apakah notif yang dibaca merupakan hasil merge
        if (notif.weight.integerValue > 1) {
            request(APINotif.ReadMultiNotif(objectId: notif.objectId, type: notif.type.stringValue)).responseJSON { req, resp, res, err in
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi")) {
                    let json = JSON(res!)
                    let data : Bool? = json["_data"].bool
                    
                    self.navigateReadNotif(notif)
                    
                    // Delete read notif from variable and core data
                    CDNotification.deleteNotifWithIds(notif.ids)
                    self.notifications![sectionTitle]!.removeAtIndex(sectionNotifs.count - (indexPath.row + 1))
                }
            }
        } else { // weight = 1
            request(APINotif.ReadNotif(notifId: notif.ids)).responseJSON { req, resp, res, err in
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi")) {
                    let json = JSON(res!)
                    let data : Bool? = json["_data"].bool
                    
                    self.navigateReadNotif(notif)
                    
                    // Delete read notif from variable and core data
                    CDNotification.deleteNotifWithIds(notif.ids)
                    self.notifications![sectionTitle]!.removeAtIndex(sectionNotifs.count - (indexPath.row + 1))
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
    
    // MARK: - Other functions
    
    func navigateReadNotif(notif : CDNotification) {
        let notifType = notif.notifType
        if (notifType == NotificationType.Transaksi) {
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
        } else if (notifType == NotificationType.Inbox) {
            // Get inbox detail
            request(APIInbox.GetInboxMessage(inboxId: notif.objectId)).responseJSON { req, resp, res, err in
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi")) {
                    let json = JSON(res!)
                    let data = json["_data"]
                    
                    let inboxData = Inbox(jsn: data)
                    
                    // Goto inbox
                    let t = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdTawar) as! TawarViewController
                    t.tawarItem = inboxData
                    self.navigationController?.pushViewController(t, animated: true)
                }
            }
        } else if (notifType == NotificationType.Aktivitas) {
            // Get product detail
            request(Products.Detail(productId: notif.objectId)).responseJSON { req, resp, res, err in
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Notifikasi")) {
                    let json = JSON(res!)
                    let pDetail = ProductDetail.instance(json)
                    
                    // Goto product comments
                    let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdProductComments) as! ProductCommentsController
                    p.pDetail = pDetail
                    self.navigationController?.pushViewController(p, animated: true)
                }
            }
        }
    }
}

class NotificationPageCell : UITableViewCell {
    
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    
    override func prepareForReuse() {
        self.contentView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0)
        //self.imgUser.image = nil
        //self.imgProduct.image = nil
        self.lblMessage.text = ""
        self.lblTime.text = ""
    }
    
    func adapt(notif : CDNotification) {
        // Set background color
        if (!notif.read) {
            self.contentView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        }
        
        // Set images
        imgUser.setImageWithUrl(NSURL(string: notif.leftImage)!, placeHolderImage: nil)
        imgUser.layer.cornerRadius = (imgUser.frame.size.width) / 2
        imgUser.clipsToBounds = true
        if (notif.rightImage != nil) {
            imgProduct.setImageWithUrl(NSURL(string: notif.rightImage!)!, placeHolderImage: nil)
        } else {
            imgProduct.image = nil
        }
        
        // Set texts
        let nsMsg = notif.message as NSString
        var fontAttr = [NSFontAttributeName: AppFont.PreloAwesome.getFont(12)!]
        if (!notif.read) {
            fontAttr = [NSFontAttributeName: UIFont.boldSystemFontOfSize(12)]
        }
        var msgAttrString = NSMutableAttributedString(string: notif.message, attributes: fontAttr)
        msgAttrString.addAttribute(NSForegroundColorAttributeName, value: Theme.GrayDark, range: nsMsg.rangeOfString(notif.message))
        msgAttrString.addAttribute(NSForegroundColorAttributeName, value: Theme.PrimaryColor, range: nsMsg.rangeOfString(notif.name))
        msgAttrString.addAttribute(NSForegroundColorAttributeName, value: Theme.PrimaryColor, range: nsMsg.rangeOfString(notif.objectName))
        lblMessage.attributedText = msgAttrString
        lblTime.text = notif.time
    }
}