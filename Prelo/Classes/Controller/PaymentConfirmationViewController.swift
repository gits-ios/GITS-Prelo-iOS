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
    
    var userOrders : Array <UserOrder>?
    var tableData: [String] = ["Hello", "My", "Table"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register custom cell
        var PaymentConfirmationCellNib = UINib(nibName: "PaymentConfirmationCell", bundle: nil)
        tableView.registerNib(PaymentConfirmationCellNib, forCellReuseIdentifier: "PaymentConfirmationCell")
        
        // DEBUG: Tableview bounds and frame
        //println("tableView bounds = \(tableView.bounds)")
        //println("tableView frame = \(tableView.frame)")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (userOrders?.count == 0 || userOrders == nil) {
            if (userOrders == nil) {
                userOrders = []
            }
            getUserOrders()
        }
    }
    
    func getUserOrders() {
        request(APIUser.OrderList(status:"process"))
        .responseJSON { req, _, res, err in
            if (err != nil) {
                println(err)
            } else {
                var obj = JSON(res!)
                for (index : String, item : JSON) in obj["_data"] {
                    let u = UserOrder.instance(item)
                    if (u != nil) {
                        self.userOrders?.append(u!)
                    }
                }
            }
            self.setupTable()
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
        return (self.userOrders?.count)!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: PaymentConfirmationCell = self.tableView.dequeueReusableCellWithIdentifier("PaymentConfirmationCell") as! PaymentConfirmationCell
        let u = userOrders?[indexPath.item]
        cell.adapt(u!)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //println("Row \(indexPath.row) selected")
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let orderConfirmVC : OrderConfirmViewController = (mainStoryboard.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdOrderConfirm) as? OrderConfirmViewController)!
        let u = userOrders?[indexPath.item]
        orderConfirmVC.orderID = u!.transactionID
        self.navigationController?.pushViewController(orderConfirmVC, animated: true)
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
    @IBOutlet var lblProductSeller: UILabel!
    
    override func layoutSubviews() {
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        self.bounds = CGRectMake(0.0, 0.0, screenWidth, 64.0)
        super.layoutSubviews()
    }
    
    func adapt(userOrder : UserOrder) {
        imgProduct.setImageWithUrl(userOrder.productImageURL!, placeHolderImage: nil)
        lblProductName.text = userOrder.productName
        lblPrice.text = userOrder.price
        lblOrderStatus.text = "DIPESAN"
        lblOrderTime.text = userOrder.timespan
        lblProductSeller.text = userOrder.productSeller
    }
}