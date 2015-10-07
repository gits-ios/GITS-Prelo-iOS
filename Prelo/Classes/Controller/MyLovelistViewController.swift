//
//  MyLovelistViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/23/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class MyLovelistViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, MyLovelistCellDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var viewJualButton: UIView!
    
    var userLovelist : Array <LovedProduct>?
    var selectedProduct : Product?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        var myLovelistCellNib = UINib(nibName: "MyLovelistCell", bundle: nil)
        tableView.registerNib(myLovelistCellNib, forCellReuseIdentifier: "MyLovelistCell")
        
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: " Lovelist", style: UIBarButtonItemStyle.Bordered, target: self, action: "backPressed:")
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
        
        // Buat tombol jual menjadi bentuk bulat dan selalu di depan
        viewJualButton.layer.cornerRadius = (viewJualButton.frame.size.width) / 2
        viewJualButton.layer.shadowColor = UIColor.blackColor().CGColor
        viewJualButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewJualButton.layer.shadowOpacity = 0.3
        viewJualButton.layer.zPosition = CGFloat.max;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = false
        loading.startAnimating()
        tableView.hidden = true
        lblEmpty.hidden = true
        
        Mixpanel.sharedInstance().track("My Lovelist")
        
        if (userLovelist?.count == 0 || userLovelist == nil) {
            if (userLovelist == nil) {
                userLovelist = []
            }
            getUserLovelist()
        } else {
            self.loadingPanel.hidden = true
            self.loading.stopAnimating()
            self.loading.hidden = true
            if (self.userLovelist?.count <= 0) {
                self.lblEmpty.hidden = false
            } else {
                self.tableView.hidden = false
                self.setupTable()
            }
        }
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func getUserLovelist() {
        request(APIUser.MyLovelist).responseJSON {req, _, res, err in
            println("My lovelist req = \(req)")
            if (err != nil) { // Terdapat error
                println("Error getting lovelist: \(err!.description)")
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                if (data == nil) { // Data kembalian kosong
                    let obj : [String : String] = res as! [String : String]
                    let message = obj["_message"]
                    println("Empty lovelist, message: \(message)")
                } else { // Berhasil
                    println("Lovelist: \(data)")
                    
                    // Store data into variable
                    for (index : String, item : JSON) in data {
                        let l = LovedProduct.instance(item)
                        if (l != nil) {
                            self.userLovelist?.append(l!)
                        }
                    }
                }
            }
            
            self.loadingPanel.hidden = true
            self.loading.stopAnimating()
            self.loading.hidden = true
            if (self.userLovelist?.count <= 0) {
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
    
    // MARK: - MyLovelistCellDelegate Functions
    
    func showLoading() {
        // Tampilkan loading
        loadingPanel.hidden = false
        loading.startAnimating()
    }
    
    func hideLoading() {
        // Hilangkan loading
        loadingPanel.hidden = true
        loading.stopAnimating()
    }
    
    func deleteCell(cell: MyLovelistCell) {
        println("delete cell with productId = \(cell.productId)")
        
        // Delete data in userLovelist
        for (var i = 0; i < userLovelist!.count; i++) {
            let l = userLovelist?.objectAtCircleIndex(i)
            if (l?.id == cell.productId) {
                userLovelist?.removeAtIndex(i)
            }
        }
        if (self.userLovelist?.count <= 0) {
            self.lblEmpty.hidden = false
            self.tableView.hidden = true
        } else {
            self.lblEmpty.hidden = true
            self.tableView.hidden = false
            self.setupTable()
        }
    }
    
    func gotoCart() {
        let c = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdCart) as! BaseViewController
        self.navigationController?.pushViewController(c, animated: true)
    }
    
    // MARK: - UITableViewDelegate Functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (userLovelist?.count > 0) {
            return (self.userLovelist?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: MyLovelistCell = self.tableView.dequeueReusableCellWithIdentifier("MyLovelistCell") as! MyLovelistCell
        cell.selectionStyle = .None
        cell.delegate = self
        let u = userLovelist?[indexPath.item]
        cell.adapt(u!)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //println("Row \(indexPath.row) selected")
        
        // Tampilkan loading
        loadingPanel.hidden = false
        loading.startAnimating()
        
        // Load detail product
        let selectedLoved : LovedProduct = (userLovelist?[indexPath.item])! as LovedProduct
        request(Products.Detail(productId: selectedLoved.id)).responseJSON {req, _, res, err in
            println("Loved product detail req = \(req)")
            if (err != nil) { // Terdapat error
                println("Error getting product detail: \(err!.description)")
            } else {
                let json = JSON(res!)
                let data = json["_data"]
                if (data == nil) { // Data kembalian kosong
                    let obj : [String : String] = res as! [String : String]
                    let message = obj["_message"]
                    println("Empty product detail, message: \(message)")
                } else { // Berhasil
                    println("Loved product detail: \(data)")
                    
                    // Store data into variable
                    self.selectedProduct = Product.instance(data)
                    
                    // Launch detail scene
                    NSNotificationCenter.defaultCenter().postNotificationName("pushnew", object: self.selectedProduct)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
    
    // MARK: - IBActions
    
    @IBAction func sellPressed(sender: AnyObject) {
        let addProductVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct) as! AddProductViewController
        self.navigationController?.pushViewController(addProductVC, animated: true)
    }
}

// MARK: - MyLovelistCell Protocol

protocol MyLovelistCellDelegate {
    func showLoading()
    func hideLoading()
    func deleteCell(cell : MyLovelistCell)
    func gotoCart()
}

class MyLovelistCell : UITableViewCell {
    @IBOutlet weak var imgProduct: UIImageView!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblCommentCount: UILabel!
    @IBOutlet weak var lblLoveCount: UILabel!
    
    var productId : String!
    
    var delegate : MyLovelistCellDelegate?
    
    func adapt(lovedProduct : LovedProduct) {
        imgProduct.setImageWithUrl(lovedProduct.productImageURL!, placeHolderImage: nil)
        lblProductName.text = lovedProduct.name
        lblPrice.text = "Rp " + lovedProduct.price.string
        lblCommentCount.text = lovedProduct.numComment.string
        lblLoveCount.text = lovedProduct.numLovelist.string
        productId = lovedProduct.id
    }
    
    @IBAction func beliPressed(sender: AnyObject) {
        if (CartProduct.isExist(productId!, email : User.EmailOrEmptyString)) { // Already in cart
            Constant.showDialog("Warning", message: "Produk sudah ada di keranjang belanja Anda")
            self.delegate?.gotoCart()
        } else { // Not in cart
            if (CartProduct.newOne(productId!, email : User.EmailOrEmptyString) == nil) { // Failed
                Constant.showDialog("Warning", message: "Gagal menyimpan produk ke keranjang belanja")
            } else { // Success
                // TODO: Kirim API add to cart
                Constant.showDialog("Success", message: "Produk berhasil ditambahkan ke keranjang belanja")
                self.delegate?.gotoCart()
            }
        }
        // Delete cell after add to cart
        self.deletePressed(nil)
    }
    
    @IBAction func deletePressed(sender: AnyObject?) {
        // Show loading
        self.delegate?.showLoading()
        
        // Send unlove API
        request(Products.Unlove(productID: productId)).responseJSON {req, _, res, err in
            println("Unlove req = \(req)")
            if (err != nil) { // Terdapat error
                println("error unlove: \(err!.description)")
            } else {
                let json = JSON(res!)
                let isLove : Bool = json["_data"]["love"].bool!
                if (!isLove) { // Berhasil unlove
                    // Delete cell
                    self.delegate?.deleteCell(self)
                } else { // Gagal unlove
                    Constant.showDialog("Warning", message: "Terdapat kesalahan pada server, silahkan coba beberapa saat lagi")
                }
                self.delegate?.hideLoading()
            }
        }
    }
}