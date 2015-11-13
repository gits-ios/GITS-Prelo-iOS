//
//  MyPurchaseProcessingViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/14/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyPurchaseProcessingViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var lblEmpty : UILabel!
    @IBOutlet var loading: UIActivityIndicatorView!
    
    var userPurchases : Array <UserTransactionItem>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        var transactionListCellNib = UINib(nibName: "TransactionListCell", bundle: nil)
        tableView.registerNib(transactionListCellNib, forCellReuseIdentifier: "TransactionListCell")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loading.startAnimating()
        tableView.hidden = true
        lblEmpty.hidden = true
        
        Mixpanel.trackPageVisit("My Orders In Progress")
        
        if (userPurchases?.count == 0 || userPurchases == nil) {
            if (userPurchases == nil) {
                userPurchases = []
            }
            getUserPurchases()
        } else {
            self.loading.stopAnimating()
            self.loading.hidden = true
            if (self.userPurchases?.count <= 0) {
                self.lblEmpty.hidden = false
            } else {
                self.tableView.hidden = false
                self.setupTable()
            }
        }
    }
    
    func getUserPurchases() {
        request(APITransaction.Purchases(status: "process", current: "", limit: "")).responseJSON {_, _, res, err in
            println(res)
            if (err != nil) { // Terdapat error
                println("Error getting purchase data: \(err!.description)")
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                if (data == nil || data == []) { // Data kembalian kosong
                    println("Empty purchase data")
                } else { // Berhasil
                    println("Purchase data: \(data)")
                    
                    // Store data into variable
                    for (index : String, item : JSON) in data {
                        let u = UserTransactionItem.instanceTransactionItem(item)
                        if (u != nil) {
                            self.userPurchases?.append(u!)
                        }
                    }
                }
            }
            
            self.loading.stopAnimating()
            self.loading.hidden = true
            if (self.userPurchases?.count <= 0) {
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (userPurchases?.count > 0) {
            return (self.userPurchases?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->
        UITableViewCell {
        var cell : TransactionListCell = self.tableView.dequeueReusableCellWithIdentifier("TransactionListCell") as! TransactionListCell
        let u = userPurchases?[indexPath.item]
        cell.adaptItem(u!)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let myPurchaseDetailVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchaseDetail, owner: nil, options: nil).first as! MyPurchaseDetailViewController
        myPurchaseDetailVC.transactionId = userPurchases?[indexPath.item].id
        self.navigationController?.pushViewController(myPurchaseDetailVC, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
}

