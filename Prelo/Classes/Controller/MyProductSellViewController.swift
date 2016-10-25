//
//  MyProductSellViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Alamofire

class MyProductSellViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet var btnRefresh: UIButton!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView : UITableView!
    @IBOutlet weak var bottomLoading: UIActivityIndicatorView!
    @IBOutlet weak var consBottomTableView: NSLayoutConstraint!
    let ConsBottomTableViewWhileUpdating : CGFloat = 36
    
    var refreshControl : UIRefreshControl!
    
    let ItemPerLoad : Int = 10
    var nextIdx : Int = 0
    var isAllItemLoaded : Bool = false
    
    var products : Array<Product> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.lblEmpty.isHidden = true
        self.tableView.isHidden = true
        self.btnRefresh.isHidden = true
        self.loading.startAnimating()
        self.loading.isHidden = false
//        getProducts()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0)
        
        self.getProducts()
        
        // Register custom cell
        let transactionListCellNib = UINib(nibName: "TransactionListCell", bundle: nil)
        tableView.register(transactionListCellNib, forCellReuseIdentifier: "TransactionListCell")
        
        // Hide bottom refresh first
        bottomLoading.stopAnimating()
        bottomLoading.isHidden = true
        consBottomTableView.constant = 0
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(MyProductSellViewController.refreshPressed(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        
        // Search bar setup
        searchBar.delegate = self
        searchBar.placeholder = "Cari Barang"
    }
    
    var first = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.MyProducts, otherParam: ["Tab" : "Active"])
        
        // Google Analytics
        GAI.trackPageVisit(PageName.MyProducts)
        
        if (!first)
        {
            self.refresh(0 as AnyObject, isSearchMode: false)
        }
        
        first = false
        
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
        Constant.showDialog("Upload Barang Berhasil", message: "Proses review barang akan memakan waktu maksimal 2 hari kerja. Mohon tunggu :)")
    }
    
    func uploadProdukGagal(_ notif : Foundation.Notification)
    {
        refresh(0 as AnyObject, isSearchMode: false)
        Constant.showDialog("Upload Barang Gagal", message: "Oops, upload barang gagal")
    }
    
    func addUploadingProducts()
    {
        let uploadingProducts = AppDelegate.Instance.produkUploader.getQueue()
        for p in uploadingProducts.reversedArray()
        {
            if let prod = p.toProduct
            {
                products.insert(prod, at: 0)
            }
        }
    }
    
    func getProducts()
    {
        var searchText = ""
        if let txt = searchBar.text {
            searchText = txt
        }
        let _ = request(APIProduct.myProduct(current: nextIdx, limit: (nextIdx + ItemPerLoad), name: searchText)).responseJSON {resp in
            if (searchText == self.searchBar.text) { // Jika response ini sesuai dengan request terakhir
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Jualan Saya")) {
                    if let result: AnyObject = resp.result.value as AnyObject?
                    {
                        let j = JSON(result)
                        let d = j["_data"].arrayObject
                        if let data = d
                        {
                            let dataCount = data.count
                            
                            for json in data
                            {
                                self.products.append(Product.instance(JSON(json))!)
                                self.tableView.tableFooterView = UIView()
                            }
                            
                            // Check if all data already loaded
                            if (dataCount < self.ItemPerLoad) {
                                self.isAllItemLoaded = true
                            }
                            
                            // Set next index
                            self.nextIdx += dataCount
                        }
                    }
                }
                
                // Hide loading (for first time request)
                self.loading.stopAnimating()
                self.loading.isHidden = true
                
                // Hide bottomLoading (for next request)
                self.bottomLoading.stopAnimating()
                self.bottomLoading.isHidden = true
                self.consBottomTableView.constant = 0
                
                // Hide refreshControl (for refreshing)
                self.refreshControl.endRefreshing()
                
                self.addUploadingProducts()
                
                if (self.products.count > 0) {
                    self.lblEmpty.isHidden = true
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                } else {
                    self.lblEmpty.isHidden = false
                    self.btnRefresh.isHidden = false
                    self.tableView.isHidden = true
                }
            }
        }
    }
    
    func refresh(_ sender: AnyObject, isSearchMode : Bool) {
        // Reset data
        self.products = []
        if (!isSearchMode) {
            self.addUploadingProducts()
        }
        self.nextIdx = 0
        self.isAllItemLoaded = false
        self.tableView.isHidden = true
        self.lblEmpty.isHidden = true
        self.btnRefresh.isHidden = true
        self.loading.isHidden = false
        getProducts()
    }
    
    @IBAction func refreshPressed(_ sender: AnyObject) {
        self.refresh(sender, isSearchMode : false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : TransactionListCell = self.tableView.dequeueReusableCell(withIdentifier: "TransactionListCell") as! TransactionListCell
        if (!refreshControl.isRefreshing) {
            let p = products[(indexPath as NSIndexPath).row]
            
            cell.lblProductName.text = p.name
            cell.lblPrice.text = p.price
            cell.lblOrderTime.text = p.time
            
            if (p.isFreeOngkir) {
                cell.imgFreeOngkir.isHidden = false
            }
            
            let commentCount : Int = (p.json["num_comment"] != nil) ? p.json["num_comment"].int! : 0
            cell.lblCommentCount.text = "\(commentCount)"
            
            let loveCount : Int = (p.json["num_lovelist"] != nil) ? p.json["num_lovelist"].int! : 0
            cell.lblLoveCount.text = "\(loveCount)"
            
            cell.imgProduct.image = nil
            if let url = p.coverImageURL {
                cell.imgProduct.downloadedFrom(url: url)
            } else if let img = p.placeHolderImage
            {
                cell.imgProduct.image = img
            }
            
            let status : String = (p.json["status_text"] != nil) ? p.json["status_text"].string! : "-"
            cell.lblOrderStatus.text = status.uppercased()
            if (p.isLokal)
            {
                cell.lblOrderStatus.text = "Uploading"
            }
            
            if (status.lowercased() == "aktif") {
                cell.lblOrderStatus.textColor = Theme.PrimaryColor
            } else if (status.lowercased() == "direview admin") {
                cell.lblOrderStatus.textColor = Theme.ThemeOrange
            } else {
                cell.lblOrderStatus.textColor = UIColor.red
            }
            
            // Fix product status text width
            let sizeThatShouldFitTheContent = cell.lblOrderStatus.sizeThatFits(cell.lblOrderStatus.frame.size)
            //print("size untuk '\(cell.lblOrderStatus.text)' = \(sizeThatShouldFitTheContent)")
            cell.consWidthLblOrderStatus.constant = sizeThatShouldFitTheContent.width
            
            // Socmed share status
            cell.vwShareStatus.isHidden = false
            if (p.isSharedInstagram) {
                cell.lblInstagram.textColor = Theme.PrimaryColor
            }
            if (p.isSharedFacebook) {
                cell.lblFacebook.textColor = Theme.PrimaryColor
            }
            if (p.isSharedTwitter) {
                cell.lblTwitter.textColor = Theme.PrimaryColor
            }
            cell.lblPercentage.text = "\(100 - p.commission) %"
        }
        
        return cell
        
        /* If using MyProductCell
        let m = tableView.dequeueReusableCellWithIdentifier("cell") as! MyProductCell
        let p = products[indexPath.row]
        m.captionName.text = p.name
        m.captionPrice.text = p.price
        m.captionTotalComment.text = p.discussionCountText
        m.captionTotalLove.text = p.loveCountText
        m.captionDate.text = p.time
        
        if let isActive = p.json["is_active"].bool
        {
            m.captionStatus.text = isActive ? "AKTIF" : "TIDAK AKTIF"
        }
        
        m.ivCover.image = nil
        if let url = p.coverImageURL
        {
            m.ivCover.downloadedFrom(url: url)
        }
        
        return m*/
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //return 80 // If using MyProductCell
        return 64
    }
    
    var selectedProduct : Product?
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedProduct = products[(indexPath as NSIndexPath).row]
        if (selectedProduct!.isLokal)
        {
            return
        }
        /* FIXME: Swift 3
        let d:ProductDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
        d.product = selectedProduct!
        
        self.previousController?.navigationController?.pushViewController(d, animated: true)*/
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset : CGPoint = scrollView.contentOffset
        let bounds : CGRect = scrollView.bounds
        let size : CGSize = scrollView.contentSize
        let inset : UIEdgeInsets = scrollView.contentInset
        let y : CGFloat = offset.y + bounds.size.height - inset.bottom
        let h : CGFloat = size.height
        
        let reloadDistance : CGFloat = 0
        if (y > h + reloadDistance) {
            // Load next items only if all items not loaded yet and if its not currently loading items
            if (!self.isAllItemLoaded && !self.bottomLoading.isAnimating) {
                // Tampilkan loading di bawah
                consBottomTableView.constant = ConsBottomTableViewWhileUpdating
                bottomLoading.startAnimating()
                bottomLoading.isHidden = false
                
                // Get user products
                self.getProducts()
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.refresh(0 as AnyObject, isSearchMode: true)
    }
}

class MyProductCell : UITableViewCell
{
    @IBOutlet var captionName : UILabel!
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var captionStatus : UILabel!
    @IBOutlet var captionDate : UILabel!
    @IBOutlet var captionTotalLove : UILabel!
    @IBOutlet var captionTotalComment : UILabel!
    @IBOutlet var ivCover : UIImageView!
}
