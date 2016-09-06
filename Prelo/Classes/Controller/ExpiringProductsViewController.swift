//
//  ExpiringProductsViewController.swift
//  Prelo
//
//  Created by PreloBook on 9/1/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class

class ExpiringProductsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var vwContent: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var lblEmpty: UILabel!
    @IBOutlet var loadingPanel: UIView!
    
    // Data container
    var expiringProducts : [ExpiringProduct] = []
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let expProductsCellNib = UINib(nibName: "ExpiringProductsCell", bundle: nil)
        tableView.registerNib(expProductsCellNib, forCellReuseIdentifier: "ExpiringProductsCell")
        
        // Loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        self.showLoading()
        
        // Set title
        self.title = PageName.BarangExpired
        
        // Get data
        request(Products.GetExpiringProducts).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Expiring Products")) {
                let json = JSON(resp.result.value!)
                if let data = json["_data"].array where data.count > 0 {
                    for i in 0...data.count - 1 {
                        var img : UIImage = UIImage()
                        if let imgArr = data[i]["display_picts"].array where imgArr.count > 0 {
                            let url = imgArr[0].stringValue
                            if let nsUrl = NSURL(string: url) {
                                if let data = NSData(contentsOfURL: nsUrl) {
                                    if let uiimg = UIImage(data: data) {
                                        img = uiimg
                                    }
                                }
                            }
                        }
                        
                        let expP = ExpiringProduct(id: data[i]["_id"].stringValue, name: data[i]["name"].stringValue, image: img, isSold: false)
                        self.expiringProducts.append(expP)
                    }
                }
            }
            
            self.hideLoading()
            self.showContent()
        }
    }
    
    // MARK: - Tableview functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expiringProducts.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : ExpiringProductsCell = self.tableView.dequeueReusableCellWithIdentifier("ExpiringProductsCell") as! ExpiringProductsCell
        if (expiringProducts.count > indexPath.row) {
            cell.adapt(expiringProducts[indexPath.row])
            cell.btnSoldAction = {
                self.showLoading()
                let req : URLRequestConvertible!
                if (self.expiringProducts[indexPath.row].isSold) {
                    req = Products.SetUnsoldExpiringProduct(productId: self.expiringProducts[indexPath.row].id)
                } else {
                    req = Products.SetSoldExpiringProduct(productId: self.expiringProducts[indexPath.row].id)
                }
                request(req).responseJSON { resp in
                    if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Sold/Unsold")) {
                        let json = JSON(resp.result.value!)
                        if let isSuccess = json["_data"].bool where isSuccess {
                            self.expiringProducts[indexPath.row].isSold = !self.expiringProducts[indexPath.row].isSold
                            self.setupTable()
                        } else  {
                            Constant.showDialog("Oops", message: "Sold/Unsold gagal, silahkan dicoba kembali")
                        }
                    }
                    self.hideLoading()
                }
            }
        }
        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Do nothing
    }
    
    // MARK: - Actions
    @IBAction func simpanPressed(sender: AnyObject) {
        self.showLoading()
        request(Products.FinishExpiringProducts).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Finish Expiring Products")) {
                let json = JSON(resp.result.value!)
                if let isSuccess = json["_data"].bool where isSuccess {
                    Constant.showDialog("Success", message: "Submit Barang Expired berhasil")
                    self.navigationController?.popViewControllerAnimated(true)
                } else {
                    Constant.showDialog("Oops", message: "Submit Barang Expired gagal, silahkan dicoba kembali")
                }
            }
            self.hideLoading()
        }
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loadingPanel.hidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.hidden = true
    }
    
    func showContent() {
        if (self.expiringProducts.count <= 0) {
            self.lblEmpty.hidden = false
            self.vwContent.hidden = true
        } else {
            self.lblEmpty.hidden = true
            self.vwContent.hidden = false
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
}

// MARK: - Struct

struct ExpiringProduct {
    var id : String = ""
    var name : String = ""
    var image : UIImage = UIImage()
    var isSold : Bool = false
}

// MARK: - Class

class ExpiringProductsCell : UITableViewCell {
    @IBOutlet var imgProduct: UIImageView!
    @IBOutlet var lblName: UILabel!
    @IBOutlet var btnSold: UIButton!
    
    var btnSoldAction : () -> () = {}
    
    override func awakeFromNib() {
        btnSold.createBordersWithColor(Theme.PrimaryColor, radius: 0, width: 1)
    }
    
    func adapt(expProduct : ExpiringProduct) {
        imgProduct.image = expProduct.image
        lblName.text = expProduct.name
        if (expProduct.isSold) {
            btnSold.backgroundColor = Theme.PrimaryColor
            btnSold.setTitleColor(UIColor.whiteColor())
        } else {
            btnSold.backgroundColor = UIColor.whiteColor()
            btnSold.setTitleColor(Theme.PrimaryColor)
        }
    }
    
    @IBAction func soldPressed(sender: AnyObject) {
        self.btnSoldAction()
    }
}
