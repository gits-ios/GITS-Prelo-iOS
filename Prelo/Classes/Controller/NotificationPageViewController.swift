//
//  NotificationPageViewController.swift
//  Prelo
//
//  Created by Fransiska on 10/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class NotificationPageViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    let TitleTransaksi : String = "Transaksi"
    let TitleInbox : String = "Inbox"
    let TitleAktivitas : String = "Aktivitas"
    lazy var notifSections : [String] = {
        [unowned self] in
        return [self.TitleTransaksi, self.TitleInbox, self.TitleAktivitas]
    }()
    var notifItems : [String : [NotificationItem]]?
    
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
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = false
        loading.startAnimating()
        tableView.hidden = true
        lblEmpty.hidden = true
        
        Mixpanel.sharedInstance().track("Notification Page")
        
        let notifCount = getNotifCount()
        if (notifCount == 0 || notifItems == nil) { // Mungkin belum getNotif atau memang notif kosong
            if (notifItems == nil) {
                // Inisiasi array
                notifItems = [:]
                for s in notifSections {
                    notifItems?.updateValue([], forKey: s)
                }
            }
            getNotificationItems()
        } else { // Sudah getNotif
            self.loadingPanel.hidden = true
            self.loading.stopAnimating()
            self.tableView.hidden = false
            self.setupTable()
        }
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // Get total notifications from all sections
    func getNotifCount() -> Int {
        var count : Int = 0
        for s in notifSections {
            if (notifItems?[s] != nil) {
                let notifCount = notifItems?[s]?.count
                count += notifCount!
            }
        }
        return count
    }
    
    func getNotificationItems() {
        request(APINotif.GetNotifs(time: "")).responseJSON {req, _, res, err in
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
                    
                    // Store data into variable
                    var itemsTransaction : [NotificationItem] = []
                    var itemsInbox : [NotificationItem] = []
                    var itemsActivity : [NotificationItem] = []
                    for (i : String, itemNotifs : JSON) in data {
                        for (j : String, itemNotif : JSON) in itemNotifs {
                            let n = NotificationItem.instance(itemNotif)
                            if (n != nil) {
                                if (i == "tp_notif") { // Transaksi
                                    itemsTransaction.append(n!)
                                } else if (i == "inbox") { // Inbox
                                    itemsInbox.append(n!)
                                } else if (i == "activity") { // Aktivitas
                                    itemsActivity.append(n!)
                                }
                            }
                        }
                    }
                    self.notifItems?.updateValue(itemsTransaction, forKey: self.TitleTransaksi)
                    self.notifItems?.updateValue(itemsInbox, forKey: self.TitleInbox)
                    self.notifItems?.updateValue(itemsActivity, forKey: self.TitleAktivitas)
                }
            }
            
            self.loadingPanel.hidden = true
            self.loading.stopAnimating()
            let notifCount = self.getNotifCount()
            if (notifCount <= 0) {
                self.lblEmpty.hidden = false
            } else {
                self.tableView.hidden = false
                self.setupTable()
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
        let sectionNotifItems : [NotificationItem] = notifItems![sectionTitle]!
        return sectionNotifItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: NotificationPageCell = self.tableView.dequeueReusableCellWithIdentifier("NotificationPageCell") as! NotificationPageCell
        cell.selectionStyle = .None
        let sectionTitle : String = notifSections[indexPath.section]
        let sectionNotifItems : [NotificationItem] = notifItems![sectionTitle]!
        let notifItem : NotificationItem = sectionNotifItems[indexPath.row]
        cell.adapt(notifItem)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("Row \(indexPath.row) in section \(indexPath.section) selected")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 72
    }
}

class NotificationPageCell : UITableViewCell {
    
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    
    func adapt(notifItem : NotificationItem) {
        // Set images
        imgUser.setImageWithUrl(notifItem.leftImageURL, placeHolderImage: nil)
        if (notifItem.rightImageURL != nil) {
            imgProduct.setImageWithUrl(notifItem.rightImageURL!, placeHolderImage: nil)
        }
        
        // Set texts
        let nsMsg = notifItem.message as NSString
        var msgAttrString = NSMutableAttributedString(string: notifItem.message, attributes: [NSFontAttributeName: AppFont.PreloAwesome.getFont(12)!])
        msgAttrString.addAttribute(NSForegroundColorAttributeName, value: Theme.GrayDark, range: nsMsg.rangeOfString(notifItem.message))
        msgAttrString.addAttribute(NSForegroundColorAttributeName, value: Theme.PrimaryColor, range: nsMsg.rangeOfString(notifItem.name))
        msgAttrString.addAttribute(NSForegroundColorAttributeName, value: Theme.PrimaryColor, range: nsMsg.rangeOfString(notifItem.objectName))
        lblMessage.attributedText = msgAttrString
        lblTime.text = notifItem.time
    }
}