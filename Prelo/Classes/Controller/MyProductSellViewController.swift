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
    @IBOutlet weak var btnRefresh: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var bottomLoading: UIActivityIndicatorView!
    @IBOutlet weak var consBottomTableView: NSLayoutConstraint!
    let ConsBottomTableViewWhileUpdating : CGFloat = 36
    
    var refreshControl : UIRefreshControl!
    
    let ItemPerLoad : Int = 10
    var nextIdx : Int = 0
    var isAllItemLoaded : Bool = false
    
    var products : Array<Product> = []
    
    var localProducts : Array<CDDraftProduct> = []
    
    var localProductPrimaryImages: Array<UIImage> = []
    
    weak var delegate: MyProductDelegate?
    
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
        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0)
        
        self.getLocalProducts()
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
//        Mixpanel.trackPageVisit(PageName.MyProducts, otherParam: ["Tab" : "Active"])
        
        // Google Analytics
        GAI.trackPageVisit(PageName.MyProducts)
        
//        if (!first)
//        {
//            self.refresh(0 as AnyObject, isSearchMode: false)
//        }
        
//        first = false
        
        if (self.delegate?.getFromDraftOrNew())!
        {
            self.refresh(0 as AnyObject, isSearchMode: false)
            
            self.delegate?.setFromDraftOrNew(false)
        }
        
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
        
//        print(notif.object)
        let o = notif.object as! [Any]
        
//        let metaJson = JSON(notif.object)
        let metaJson = JSON(o[0])
        let metadata = metaJson["_data"]
        print(metadata)
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
            "Facebook" : metadata["share_status"]["FACEBOOK"].int!,
            "Twitter" : metadata["share_status"]["TWITTER"].int!,
            "Instagram" : metadata["share_status"]["INSTAGRAM"].int!
        ] as [String : Any]
        
        let images = metadata["display_picts"].array!
        
        // imgae
        var imagesOke : [Bool] = []
        for i in 0...images.count - 1 {
//            print(images[i].description)
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
    
    func getLocalProducts() {
        localProducts = CDDraftProduct.getAllIsDraft()
        localProductPrimaryImages = []
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
        
        getLocalProducts()
        getProducts()
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
        if (section == 0) {
            return localProducts.count
        } else {
            return products.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : TransactionListCell = self.tableView.dequeueReusableCell(withIdentifier: "TransactionListCell") as! TransactionListCell
        if (!refreshControl.isRefreshing) {
            if (indexPath as NSIndexPath).section == 0 {
                let idx = (indexPath as NSIndexPath).row
                let p = localProducts[idx]
                
                cell.lblProductName.text = p.name
                cell.lblPrice.text = p.price.int.asPrice
                cell.lblOrderTime.text = ""
                
                cell.imgProduct.image = nil
                
                if localProductPrimaryImages.count <= idx {
                    var image : UIImage?
                    if let data = NSData(contentsOfFile: p.imagePath1){
                        if let imageUrl = UIImage(data: data as Data) {
                            let img = UIImage(cgImage: imageUrl.cgImage!, scale: 1, orientation: UIImageOrientation(rawValue: p.imageOrientation1 as Int)!).resizeWithWidth(120)
                            image = img
                        }
                    } else { // placeholder image
                        image = UIImage(named: "placeholder-standar")?.resizeWithWidth(120)
                    }
                    
                    localProductPrimaryImages.append(image!)
                    cell.imgProduct.image = image!
                } else {
                    cell.imgProduct.image = localProductPrimaryImages[idx]
                }
                
                cell.imgProduct.afInflate()
                
                cell.lblOrderStatus.text = "DRAFT"
                cell.lblOrderStatus.textColor = UIColor.blue
                
                // Fix product status text width
                let sizeThatShouldFitTheContent = cell.lblOrderStatus.sizeThatFits(cell.lblOrderStatus.frame.size)
                //print("size untuk '\(cell.lblOrderStatus.text)' = \(sizeThatShouldFitTheContent)")
                cell.consWidthLblOrderStatus.constant = sizeThatShouldFitTheContent.width
                
                // Socmed share status
                cell.vwShareStatus.isHidden = false
                
                cell.lblPercentage.text = "90%"
            } else {
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
                    cell.imgProduct.afSetImage(withURL: url)
                } else if let img = p.placeHolderImage
                {
                    cell.imgProduct.image = img.resizeWithWidth(120)
                    cell.imgProduct.afInflate()
                }
                
                let status : String = (p.json["status_text"] != nil) ? p.json["status_text"].string! : "-"
                cell.lblOrderStatus.text = status.uppercased()
                if (p.isLokal)
                {
                    cell.lblOrderStatus.text = "UPLOADING"
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
                cell.lblPercentage.text = "\(100 - p.commission)%"
            }
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
            m.ivCover.afSetImage(withURL: url)
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
        if (indexPath as NSIndexPath).section == 0 {
            self.delegate?.setFromDraftOrNew(true)
            let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
            add.screenBeforeAddProduct = PageName.MyProducts
            add.draftMode = true
            add.draftProduct = localProducts[(indexPath as NSIndexPath).row]
            self.navigationController?.pushViewController(add, animated: true)
        } else {
            selectedProduct = products[(indexPath as NSIndexPath).row]
            if (selectedProduct!.isLokal)
            {
                return
            }
            
            let d:ProductDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
            d.product = selectedProduct!
            
            d.delegate = self.delegate
            
            d.previousScreen = PageName.MyProducts
            
            self.previousController?.navigationController?.pushViewController(d, animated: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset : CGPoint = scrollView.contentOffset
        let bounds : CGRect = scrollView.bounds
        let size : CGSize = scrollView.contentSize
        let inset : UIEdgeInsets = scrollView.contentInset
        let y : CGFloat = offset.y + bounds.size.height - inset.bottom
        let h : CGFloat = size.height
        
        let reloadDistance : CGFloat = 0
        if (y > h + reloadDistance && self.products.count >= 10) {
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        ivCover.afCancelRequest()
    }
}
