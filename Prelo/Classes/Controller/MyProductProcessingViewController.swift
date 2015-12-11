//
//  MyProductProcessingViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/21/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyProductProcessingViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var lblEmpty : UILabel!
    @IBOutlet var loading : UIActivityIndicatorView!
    
    var userProducts : Array <UserTransactionItem>?
    
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
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.MyProducts, otherParam: ["Tab" : "In Progress"])
        
        // Google Analytics
        GAI.trackPageVisit(PageName.MyProducts)
        
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
        request(APITransaction.Sells(status: "process", current: "", limit: "")).responseJSON {_, _, res, err in
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
                        let u = UserTransactionItem.instanceTransactionItem(item)
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
            cell.adaptItem(u!)
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let myProductDetailVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyProductDetail, owner: nil, options: nil).first as! MyProductDetailViewController
        myProductDetailVC.transactionId = userProducts?[indexPath.item].id
        self.navigationController?.pushViewController(myProductDetailVC, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
}