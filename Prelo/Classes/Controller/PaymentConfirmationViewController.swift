//
//  PaymentConfirmationViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/13/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


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
        let paymentConfirmationCellNib = UINib(nibName: "PaymentConfirmationCell", bundle: nil)
        tableView.register(paymentConfirmationCellNib, forCellReuseIdentifier: "PaymentConfirmationCell")
        
        // Title
        self.title = "Pesanan Saya"
        
        // DEBUG: Tableview bounds and frame
        ////print("tableView bounds = \(tableView.bounds)")
        ////print("tableView frame = \(tableView.frame)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        loadingPanel.isHidden = false
        loading.startAnimating()
        tableView.isHidden = true
        lblEmpty.isHidden = true
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.UnpaidTransaction)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.UnpaidTransaction)
        
        if (userCheckouts == nil || userCheckouts?.count == 0) {
            if (userCheckouts == nil) {
                userCheckouts = []
            }
            getUserCheckouts()
        } else {
            self.loadingPanel.isHidden = true
            self.loading.stopAnimating()
            if (self.userCheckouts?.count <= 0) {
                self.lblEmpty.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.setupTable()
            }
        }
    }
    
    func getUserCheckouts() {
        // API Migrasi
        let _ = request(APITransactionProduct.checkoutList(current: "", limit: "")).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Pesanan Saya")) {
                let json = JSON(resp.result.value!)
                //print(json)
                let data = json["_data"]
                
                // Store data into variable
                for (_, item) in data {
                    let u = UserCheckout.instance(item)
                    if (u != nil) {
                        self.userCheckouts?.append(u!)
                    }
                }
                
                // Show table or empty label
                self.loadingPanel.isHidden = true
                self.loading.stopAnimating()
                if (self.userCheckouts?.count <= 0) {
                    self.lblEmpty.isHidden = false
                } else {
                    self.tableView.isHidden = false
                    self.setupTable()
                }
            } else {
                _ = self.navigationController?.popViewController(animated: true)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (userCheckouts?.count > 0) {
            return (self.userCheckouts?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PaymentConfirmationCell = self.tableView.dequeueReusableCell(withIdentifier: "PaymentConfirmationCell") as! PaymentConfirmationCell
        cell.selectionStyle = .none
        let u = userCheckouts?[(indexPath as NSIndexPath).item]
        cell.adapt(u!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ////print("Row \(indexPath.row) selected")
        
        let u : UserCheckout = (userCheckouts?[(indexPath as NSIndexPath).item])!
        if (u.progress == 2) { // Pembayaran pending
            Constant.showDialog("", message: "Pembayaran sedang diproses Prelo, mohon ditunggu")
        } else {
            var imgs : [URL] = []
            for i in 0 ..< u.transactionProducts.count {
                let c : UserCheckoutProduct = u.transactionProducts[i]
                imgs.append(c.productImageURL! as URL)
            }
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let orderConfirmVC : OrderConfirmViewController = (mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdOrderConfirm) as? OrderConfirmViewController)!
            orderConfirmVC.transactionId = u.id
            orderConfirmVC.orderID = u.orderId
            orderConfirmVC.total = u.totalPrice
            orderConfirmVC.images = imgs
            orderConfirmVC.isFromCheckout = false
            orderConfirmVC.kodeTransfer = u.banktransferDigit
            self.navigationController?.pushViewController(orderConfirmVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        self.bounds = CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 130.0)
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if (imgProducts.count > 0) {
            let imgCount = imgProducts.count
            for i in 1 ..< imgCount {
                imgProducts[imgCount - i].afCancelRequest()
            }
        }
    }
    
    func adapt(_ userCheckout : UserCheckout) {
        lblOrderId.text = "Order ID #\(userCheckout.orderId)"
        lblOrderTime.text = userCheckout.time
        if (userCheckout.progress == 2) { // Pembayaran pending
            lblPrice.text = "Pembayaran diproses"
            lblPrice.textColor = Theme.PrimaryColor
        } else {
            lblPrice.text = "\((userCheckout.totalPrice + userCheckout.banktransferDigit).asPrice)"
            lblPrice.textColor = Theme.GrayDark
        }
        let pCount : Int = userCheckout.transactionProducts.count
        lblProductCount.text = "\(pCount) Barang"
        
        // Kosongkan gambar terlebih dahulu
//        for j in 0 ..< imgProducts.count {
//            imgProducts[j].image = nil
//        }
        
        // Tentukan jumlah gambar yang akan dimunculkan
        var imgCount = pCount
        if (imgCount > 4) {
            // Max gambar adalah 4
            imgCount = 4
            
            // Munculkan ellipsis
            vwEllipsis.isHidden = false
        } else {
            // Sembunyikan ellipsis
            vwEllipsis.isHidden = true
        }
        
        // Munculkan gambar
        for i in 1 ..< imgCount {
            imgProducts[imgCount - i].afSetImage(withURL: userCheckout.transactionProducts[i - 1].productImageURL!)
        }
    }
}
