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
        let dat1 = "{\"message\":\"hahahaha\"}"
        let dum1 = NotificationItem.instance(JSON(dat1))
        let dat2 = "{\"message\":\"hihihihi\"}"
        let dum2 = NotificationItem.instance(JSON(dat2))
        let dat3 = "{\"message\":\"huhuhuhu\"}"
        let dum3 = NotificationItem.instance(JSON(dat3))
        let dat4 = "{\"message\":\"hehehehe\"}"
        let dum4 = NotificationItem.instance(JSON(dat4))
        let dat5 = "{\"message\":\"hohohoho\"}"
        let dum5 = NotificationItem.instance(JSON(dat5))
        let dat6 = "{\"message\":\"hohohoho\"}"
        let dum6 = NotificationItem.instance(JSON(dat6))
        let dat7 = "{\"message\":\"hohohoho\"}"
        let dum7 = NotificationItem.instance(JSON(dat7))
        let dat8 = "{\"message\":\"hohohoho\"}"
        let dum8 = NotificationItem.instance(JSON(dat8))
        
        var itemsT : [NotificationItem] = notifItems![TitleTransaksi]!
        itemsT.append(dum1!)
        itemsT.append(dum2!)
        var itemsI : [NotificationItem] = notifItems![TitleInbox]!
        itemsI.append(dum3!)
        itemsI.append(dum4!)
        var itemsA : [NotificationItem] = notifItems![TitleAktivitas]!
        itemsA.append(dum5!)
        itemsA.append(dum6!)
        itemsA.append(dum7!)
        itemsA.append(dum8!)
        notifItems?.updateValue(itemsT, forKey: TitleTransaksi)
        notifItems?.updateValue(itemsI, forKey: TitleInbox)
        notifItems?.updateValue(itemsA, forKey: TitleAktivitas)
        
        self.loadingPanel.hidden = true
        self.loading.stopAnimating()
        self.tableView.hidden = false
        self.setupTable()
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
        //lblMessage.text = notifItem.message
    }
}