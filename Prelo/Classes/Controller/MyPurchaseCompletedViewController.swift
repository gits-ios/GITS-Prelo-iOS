//
//  MyPurchaseCompletedViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/14/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyPurchaseCompletedViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var lblEmpty: UILabel!
    
    var userPurchases : Array <UserPurchase>?
    
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
        
        Mixpanel.sharedInstance().track("My Purchase - Completed")
        
        if (userPurchases?.count == 0 || userPurchases == nil) {
            if (userPurchases == nil) {
                userPurchases = []
            }
            getUserPurchases()
        }
    }
    
    func getUserPurchases() {
        request(APITransaction.Purchases(status: "done", current: "", limit: "")).responseJSON {_, _, res, err in
            if (err != nil) { // Terdapat error
                println("Error getting purchase data: \(err!.description)")
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                if (data == nil) { // Data kembalian kosong
                    let obj : [String : String] = res as! [String : String]
                    let message = obj["_message"]
                    println("Empty purchase data, message: \(message)")
                } else { // Berhasil
                    println("Purchase data: \(data)")
                    
                    // Store data into variable
                    for (index : String, item : JSON) in data {
                        let u = UserPurchase.instance(item)
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
            cell.adapt(u!)
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("Row \(indexPath.row) selected")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
}
