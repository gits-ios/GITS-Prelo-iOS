//
//  PaymentConfirmationViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/13/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class PaymentConfirmationViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
//    var products : Array <Product>?
    var tableData: [String] = ["Hello", "My", "Table"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register custom cell
        var PaymentConfirmationCellNib = UINib(nibName: "PaymentConfirmationCell", bundle: nil)
        tableView.registerNib(PaymentConfirmationCellNib, forCellReuseIdentifier: "PaymentConfirmationCell")
        
        // DEBUG: Tableview bounds and frame
//        println("tableView bounds = \(tableView.bounds)")
//        println("tableView frame = \(tableView.frame)")
    }
    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        if (products?.count == 0 || products == nil) {
//            if (products == nil) {
//                products = []
//            }
//            getProducts()
//        }
//    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: PaymentConfirmationCell = self.tableView.dequeueReusableCellWithIdentifier("PaymentConfirmationCell") as! PaymentConfirmationCell
        cell.lblCommentCount.text = "888"
        //cell.textLabel?.text = self.tableData[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("Row \(indexPath.row) selected")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
}

class PaymentConfirmationCell : UITableViewCell {
    @IBOutlet var imgProduct: UIImageView!
    @IBOutlet var lblProductName: UILabel!
    @IBOutlet var lblPrice: UILabel!
    @IBOutlet var lblOrderStatus: UILabel!
    @IBOutlet var lblOrderTime: UILabel!
    @IBOutlet var lblCommentCount: UILabel!
    @IBOutlet var lblLoveCount: UILabel!
    
    override func layoutSubviews() {
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        self.bounds = CGRectMake(0.0, 0.0, screenWidth, 64.0)
        super.layoutSubviews()
    }
}