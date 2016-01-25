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
    @IBOutlet var lblEmpty: UILabel!
    @IBOutlet var loadingPanel: UIView!
    @IBOutlet var loading: UIActivityIndicatorView!
    
    var userCheckouts : Array <UserCheckout>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        var paymentConfirmationCellNib = UINib(nibName: "PaymentConfirmationCell", bundle: nil)
        tableView.registerNib(paymentConfirmationCellNib, forCellReuseIdentifier: "PaymentConfirmationCell")
        
        // Title
        self.title = "Pesanan Saya"
        
        // DEBUG: Tableview bounds and frame
        //println("tableView bounds = \(tableView.bounds)")
        //println("tableView frame = \(tableView.frame)")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = false
        loading.startAnimating()
        tableView.hidden = true
        lblEmpty.hidden = true
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.UnpaidTransaction)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.UnpaidTransaction)
        
        if (userCheckouts == nil || userCheckouts?.count == 0) {
            if (userCheckouts == nil) {
                userCheckouts = []
            }
            getUserCheckouts()
        } else {
            self.loadingPanel.hidden = true
            self.loading.stopAnimating()
            if (self.userCheckouts?.count <= 0) {
                self.lblEmpty.hidden = false
            } else {
                self.tableView.hidden = false
                self.setupTable()
            }
        }
    }
    
    func getUserCheckouts() {
        request(APITransaction.CheckoutList(current: "", limit: "")).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Pesanan Saya")) {
                let json = JSON(res!)
                let data = json["_data"]
                
                // Store data into variable
                for (index : String, item : JSON) in data {
                    let u = UserCheckout.instance(item)
                    if (u != nil) {
                        self.userCheckouts?.append(u!)
                    }
                }
                
                // Show table or empty label
                self.loadingPanel.hidden = true
                self.loading.stopAnimating()
                if (self.userCheckouts?.count <= 0) {
                    self.lblEmpty.hidden = false
                } else {
                    self.tableView.hidden = false
                    self.setupTable()
                }
            } else {
                self.navigationController?.popViewControllerAnimated(true)
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
    
    // MARK: - UITableViewDelegate Functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (userCheckouts?.count > 0) {
            return (self.userCheckouts?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: PaymentConfirmationCell = self.tableView.dequeueReusableCellWithIdentifier("PaymentConfirmationCell") as! PaymentConfirmationCell
        cell.selectionStyle = .None
        let u = userCheckouts?[indexPath.item]
        cell.adapt(u!)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //println("Row \(indexPath.row) selected")
        
        let u : UserCheckout = (userCheckouts?[indexPath.item])!
        if (u.progress == 2) { // Pembayaran pending
            Constant.showDialog("", message: "Pembayaran sedang diproses Prelo, mohon ditunggu")
        } else {
            var imgs : [NSURL] = []
            for (var i = 0; i < u.transactionProducts.count; i++) {
                let c : UserCheckoutProduct = u.transactionProducts[i]
                imgs.append(c.productImageURL!)
            }
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let orderConfirmVC : OrderConfirmViewController = (mainStoryboard.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdOrderConfirm) as? OrderConfirmViewController)!
            orderConfirmVC.transactionId = u.id
            orderConfirmVC.orderID = u.orderId
            orderConfirmVC.total = u.totalPrice
            orderConfirmVC.images = imgs
            orderConfirmVC.fromCheckout = false
            self.navigationController?.pushViewController(orderConfirmVC, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 130
    }
}

class PaymentConfirmationCell : UITableViewCell {
    @IBOutlet var lblOrderId: UILabel!
    @IBOutlet var lblOrderTime: UILabel!
    @IBOutlet var lblProductCount: UILabel!
    @IBOutlet var imgProducts: [UIImageView]!
    @IBOutlet var vwEllipsis: UIView!
    @IBOutlet var lblPrice: UILabel!

    override func layoutSubviews() {
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        self.bounds = CGRectMake(0.0, 0.0, screenWidth, 130.0)
        super.layoutSubviews()
    }
    
    func adapt(userCheckout : UserCheckout) {
        lblOrderId.text = "Order ID #\(userCheckout.orderId)"
        lblOrderTime.text = userCheckout.time
        if (userCheckout.progress == 2) { // Pembayaran pending
            lblPrice.text = "Pembayaran diproses"
            lblPrice.textColor = Theme.PrimaryColor
        } else {
            lblPrice.text = "\(userCheckout.totalPrice.asPrice)"
            lblPrice.textColor = Theme.GrayDark
        }
        let pCount : Int = userCheckout.transactionProducts.count
        lblProductCount.text = "\(pCount) Barang"
        
        // Kosongkan gambar terlebih dahulu
        for (var j = 0; j < imgProducts.count; j++) {
            imgProducts[j].image = nil
        }
        
        // Tentukan jumlah gambar yang akan dimunculkan
        var imgCount = pCount
        if (imgCount > 4) {
            // Max gambar adalah 4
            imgCount = 4
            
            // Munculkan ellipsis
            vwEllipsis.hidden = false
        } else {
            // Sembunyikan ellipsis
            vwEllipsis.hidden = true
        }
        
        // Munculkan gambar
        for (var i = 1; i <= imgCount; i++) {
            imgProducts[imgCount - i].setImageWithUrl(userCheckout.transactionProducts[i - 1].productImageURL!, placeHolderImage: nil)
        }
    }
}