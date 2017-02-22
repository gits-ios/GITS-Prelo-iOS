//
//  MyLovelistViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/23/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
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
        let myLovelistCellNib = UINib(nibName: "MyLovelistCell", bundle: nil)
        tableView.register(myLovelistCellNib, forCellReuseIdentifier: "MyLovelistCell")
        
        // Set title
        self.title = PageName.Lovelist
        
        // Buat tombol jual menjadi bentuk bulat dan selalu di depan
        viewJualButton.layoutIfNeeded()
        viewJualButton.layer.cornerRadius = (viewJualButton.frame.size.width) / 2
        viewJualButton.layer.shadowColor = UIColor.black.cgColor
        viewJualButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewJualButton.layer.shadowOpacity = 0.3
        viewJualButton.layer.zPosition = CGFloat.greatestFiniteMagnitude;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        loadingPanel.isHidden = false
        loading.startAnimating()
        tableView.isHidden = true
        lblEmpty.isHidden = true
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.Lovelist)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Lovelist)
        
        if (userLovelist?.count == 0 || userLovelist == nil) {
            if (userLovelist == nil) {
                userLovelist = []
            }
            getUserLovelist()
        } else {
            self.loadingPanel.isHidden = true
            self.loading.stopAnimating()
            if (self.userLovelist?.count <= 0) {
                self.lblEmpty.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.setupTable()
            }
        }
    }
    
    func getUserLovelist() {
        // API Migrasi
        let _ = request(APIMe.myLovelist).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Lovelist")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                // Store data into variable
                for (_, item) in data {
                    let l = LovedProduct.instance(item)
                    if (l != nil) {
                        self.userLovelist?.append(l!)
                    }
                }
            }
            
            self.loadingPanel.isHidden = true
            self.loading.stopAnimating()
            if (self.userLovelist?.count <= 0) {
                self.lblEmpty.isHidden = false
            } else {
                self.tableView.isHidden = false
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
        loadingPanel.isHidden = false
        loading.startAnimating()
    }
    
    func hideLoading() {
        // Hilangkan loading
        loadingPanel.isHidden = true
        loading.stopAnimating()
    }
    
    func deleteCell(_ cell: MyLovelistCell) {
        print("delete cell with productId = \(cell.productId)")
        
        // Delete data in userLovelist
        for i in 0 ..< userLovelist!.count {
            let l = userLovelist?.objectAtCircleIndex(i)
            if (l?.id == cell.productId) {
                userLovelist?.remove(at: i)
            }
        }
        if (self.userLovelist?.count <= 0) {
            self.lblEmpty.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.lblEmpty.isHidden = true
            self.tableView.isHidden = false
            self.setupTable()
        }
    }
    
    func gotoCart() {
        let c = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdCart) as! BaseViewController
        self.navigationController?.pushViewController(c, animated: true)
    }
    
    // MARK: - UITableViewDelegate Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (userLovelist?.count > 0) {
            return (self.userLovelist?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MyLovelistCell = self.tableView.dequeueReusableCell(withIdentifier: "MyLovelistCell") as! MyLovelistCell
        cell.selectionStyle = .none
        cell.delegate = self
        let u = userLovelist?[(indexPath as NSIndexPath).item]
        cell.adapt(u!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("Row \(indexPath.row) selected")
        
        // Tampilkan loading
        loadingPanel.isHidden = false
        loading.startAnimating()
        
        // Load detail product
        let selectedLoved : LovedProduct = (userLovelist?[(indexPath as NSIndexPath).item])! as LovedProduct
        let _ = request(APIProduct.detail(productId: selectedLoved.id, forEdit: 0)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Detail Barang")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                // Store data into variable
                self.selectedProduct = Product.instance(data)
                
                // Launch detail scene
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NotificationName.ShowProduct), object: [ self.selectedProduct, PageName.Notification ])
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    // MARK: - IBActions
    
    @IBAction func sellPressed(_ sender: AnyObject) {
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        add.screenBeforeAddProduct = PageName.Lovelist
        self.navigationController?.pushViewController(add, animated: true)
    }
}

// MARK: - MyLovelistCell Protocol

protocol MyLovelistCellDelegate {
    func showLoading()
    func hideLoading()
    func deleteCell(_ cell : MyLovelistCell)
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imgProduct.afCancelRequest()
    }
    
    func adapt(_ lovedProduct : LovedProduct) {
        imgProduct.afSetImage(withURL: lovedProduct.productImageURL!)
        lblProductName.text = lovedProduct.name
        lblPrice.text = "\(lovedProduct.price.asPrice)"
        lblCommentCount.text = lovedProduct.numComment.string
        lblLoveCount.text = lovedProduct.numLovelist.string
        productId = lovedProduct.id
    }
    
    @IBAction func beliPressed(_ sender: AnyObject) {
        if (CartProduct.isExist(productId!, email : User.EmailOrEmptyString)) { // Already in cart
            Constant.showDialog("Warning", message: "Barang sudah ada di keranjang belanja Anda")
            self.delegate?.gotoCart()
        } else { // Not in cart
            if (CartProduct.newOne(productId!, email : User.EmailOrEmptyString, name : (lblProductName.text)!) == nil) { // Failed
                Constant.showDialog("Warning", message: "Gagal menyimpan barang ke keranjang belanja")
            } else { // Success
                // TODO: Kirim API add to cart
//                Constant.showDialog("Success", message: "Barang berhasil ditambahkan ke keranjang belanja")
                self.delegate?.gotoCart()
            }
        }
        // Delete cell after add to cart
        //self.deletePressed(nil)
    }
    
    @IBAction func deletePressed(_ sender: AnyObject?) {
        // Show loading
        self.delegate?.showLoading()
        
        // Send unlove API
        let _ = request(APIProduct.unlove(productID: productId)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Unlove")) {
                let json = JSON(resp.result.value!)
                let isLove : Bool = json["_data"]["love"].bool!
                if (!isLove) { // Berhasil unlove
                    // Delete cell
                    self.delegate?.deleteCell(self)
                }
                self.delegate?.hideLoading()
            }
        }
    }
}
