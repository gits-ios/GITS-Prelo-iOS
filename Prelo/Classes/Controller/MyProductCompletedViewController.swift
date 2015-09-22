//
//  MyProductCompletedViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/22/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyProductCompletedViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var lblEmpty : UILabel!
    @IBOutlet var loading : UIActivityIndicatorView!
    
    var userProducts : Array <UserTransaction>?
    
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
        
        Mixpanel.sharedInstance().track("My Product - Completed")
        
        if (userProducts?.count == 0 || userProducts == nil) {
            if (userProducts == nil) {
                userProducts = []
            }
            getUserProducts()
        } else {
            self.loading.stopAnimating()
            self.loading.hidden = true
            if (self.userProducts?.count <= 0) {
                self.lblEmpty.hidden = false
            } else {
                self.tableView.hidden = false
                self.setupTable()
            }
        }
    }
    
    func getUserProducts() {
        request(APITransaction.Sells(status: "done", current: "", limit: "")).responseJSON {_, _, res, err in
            if (err != nil) { // Terdapat error
                println("Error getting product data: \(err!.description)")
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                if (data == nil) { // Data kembalian kosong
                    let obj : [String : String] = res as! [String : String]
                    let message = obj["_message"]
                    println("Empty product data, message: \(message)")
                } else { // Berhasil
                    println("Product data: \(data)")
                    
                    // Store data into variable
                    for (index : String, item : JSON) in data {
                        let u = UserTransaction.instance(item)
                        if (u != nil) {
                            self.userProducts?.append(u!)
                        }
                    }
                }
            }
            
            self.loading.stopAnimating()
            self.loading.hidden = true
            if (self.userProducts?.count <= 0) {
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
        if (userProducts?.count > 0) {
            return (self.userProducts?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->
        UITableViewCell {
            var cell : TransactionListCell = self.tableView.dequeueReusableCellWithIdentifier("TransactionListCell") as! TransactionListCell
            let u = userProducts?[indexPath.item]
            cell.adapt(u!)
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let purchaseDetailVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePurchaseDetail, owner: nil, options: nil).first as! PurchaseDetailViewController
        purchaseDetailVC.transactionId = userProducts?[indexPath.item].id
        self.navigationController?.pushViewController(purchaseDetailVC, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
}
