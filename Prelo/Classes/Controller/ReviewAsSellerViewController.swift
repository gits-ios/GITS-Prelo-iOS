//
//  ReviewAsSellerViewController.swift
//  Prelo
//
//  Created by Prelo on 7/18/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Alamofire

class ReviewAsSellerViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var btnRefresh: UIButton!
    @IBOutlet weak var tableView : UITableView!
    
    var refreshControl : UIRefreshControl!
    
    let ItemPerLoad : Int = 10
    var nextIdx : Int = 0
    var isAllItemLoaded : Bool = false
    
    var reviewSellers : Array<UserReview> = []
    
    //weak var delegate: MyProductDelegate?
    
    var isFirst = false // adduploading product when first load
    
    var isRefreshing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.lblEmpty.isHidden = true
        self.tableView.isHidden = true
        self.btnRefresh.isHidden = true
        self.loading.startAnimating()
        self.loading.isHidden = false
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let shopReviewCellNib = UINib(nibName: "ShopReviewCell", bundle: nil)
        tableView.register(shopReviewCellNib, forCellReuseIdentifier: "ShopReviewCell")
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(MyProductSellViewController.refreshPressed(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        
    }
    
    var first = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        //        Mixpanel.trackPageVisit(PageName.MyProducts, otherParam: ["Tab" : "Active"])
        
        // Google Analytics
        GAI.trackPageVisit(PageName.MyProducts)
        
        //        if (!first)
        //        {
        //            self.refresh(0 as AnyObject, isSearchMode: false)
        //        }
        
        //        first = false
        
//        if (self.delegate?.getFromDraftOrNew())!
//        {
//            self.refresh(0 as AnyObject, isSearchMode: false)
//            
//            self.delegate?.setFromDraftOrNew(false)
//        }
        
        ProdukUploader.AddObserverForUploadSuccess(self, selector: #selector(MyProductSellViewController.uploadProdukSukses(_:)))
        ProdukUploader.AddObserverForUploadFailed(self, selector: #selector(MyProductSellViewController.uploadProdukGagal(_:)))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ProdukUploader.RemoveObserverForUploadSuccess(self)
        ProdukUploader.RemoveObserverForUploadFailed(self)
    }
    
    func uploadProdukSukses(_ notif : Foundation.Notification)
    {
        refresh(0 as AnyObject, isSearchMode: false)
        //        Constant.showDialog("Upload Barang Berhasil", message: "Proses review barang akan memakan waktu maksimal 2 hari kerja. Mohon tunggu :)")
        
        //        //print(notif.object)
        let o = notif.object as! [Any]
        
        //        let metaJson = JSON((notif.object ?? [:]))
        let metaJson = JSON(o[0])
        let metadata = metaJson["_data"]
        //print(metadata)
        if let message = metadata["message"].string {
            Constant.showDialog("Upload Barang Berhasil", message: message)
        }
        
        let p = o[1] as! [String : Any]
        var localId = p["Local ID"] as! String
        
        if (localId == "") {
            let uploadedProduct = CDDraftProduct.getOneIsUploading(metadata["name"].string!)
            localId = (uploadedProduct?.localId)!
        }
        
        // clear uploaded draft
        CDDraftProduct.delete(localId)
        
        // Prelo Analytic - Upload Success
        let loginMethod = User.LoginMethod ?? ""
        var pdata = [
            "Local ID": localId,
            "Product Name" : metadata["name"].string!,
            "Commission Percentage" : metadata["commission"].int!,
            "Facebook" : metadata["share_status"]["shared"]["FACEBOOK"].int!,
            "Twitter" : metadata["share_status"]["shared"]["TWITTER"].int!,
            "Instagram" : metadata["share_status"]["shared"]["INSTAGRAM"].int!
            ] as [String : Any]
        
        let images = metadata["display_picts"].array!
        
        // imgae
        var imagesOke : [Bool] = []
        for i in 0...images.count - 1 {
            //            //print(images[i].description)
            if images[i].description != "null" {
                imagesOke.append(true)
            } else {
                imagesOke.append(false)
            }
        }
        pdata["Images"] = imagesOke
        
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.UploadSuccess, data: pdata, previousScreen: PageName.ShareAddedProduct, loginMethod: loginMethod)
    }
    
    func uploadProdukGagal(_ notif : Foundation.Notification)
    {
        refresh(0 as AnyObject, isSearchMode: false)
        Constant.showDialog("Upload Barang Gagal", message: "Oops, upload barang gagal")
        
        let o = notif.object as! [Any]
        let p = o[1] as! [String : Any]
        var localId = p["Local ID"] as! String
        
        // if not found
        if (localId == "") {
            let uploadedProduct = CDDraftProduct.getOneIsUploading()
            localId = (uploadedProduct?.localId)!
        }
        
        // set status uploading
        CDDraftProduct.setUploading(localId, isUploading: false)
    }
    
    
    func refresh(_ sender: AnyObject, isSearchMode : Bool) {
        self.isRefreshing = true
        
        // Reset data
        self.reviewSellers = []
        
        self.nextIdx = 0
        self.isAllItemLoaded = false
        self.tableView.isHidden = true
        self.lblEmpty.isHidden = true
        self.btnRefresh.isHidden = true
        self.loading.isHidden = false
        
    }
    
    @IBAction func refreshPressed(_ sender: AnyObject) {
        self.refresh(sender, isSearchMode : false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // local , onstore
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviewSellers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ShopReviewCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopReviewCell") as! ShopReviewCell
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //return 80 // If using MyProductCell
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.refresh(0 as AnyObject, isSearchMode: true)
    }
}
