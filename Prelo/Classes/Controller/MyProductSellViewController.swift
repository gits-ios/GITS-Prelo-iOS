//
//  MyProductSellViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/24/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Alamofire

class MyProductSellViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var btnRefresh: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var vwBottomLoading: UIView!
    @IBOutlet weak var bottomLoading: UIActivityIndicatorView!
    
    var refreshControl : UIRefreshControl!
    
    let ItemPerLoad : Int = 10
    var nextIdx : Int = 0
    var isAllItemLoaded : Bool = false
    
    var products : Array<Product> = []
    
    var localProducts : Array<CDDraftProduct> = []
    
    var localProductPrimaryImages: Array<UIImage> = []
    
    weak var delegate: MyProductDelegate?
    
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
        
        self.getLocalProducts()
        self.getProducts()
        
        // Register custom cell
        let ItemListCellNib = UINib(nibName: "ItemListCell", bundle: nil)
        tableView.register(ItemListCellNib, forCellReuseIdentifier: "ItemListCell")
        
        // Hide bottom refresh first
        bottomLoading.stopAnimating()
        bottomLoading.isHidden = true
        self.vwBottomLoading.isHidden = true
        
        self.vwBottomLoading.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
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
                var dataCount = 0
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Jualan Saya")) {
                    if let result: AnyObject = resp.result.value as AnyObject?
                    {
                        let j = JSON(result)
                        let d = j["_data"].arrayObject
                        if let data = d
                        {
                            dataCount = data.count
                            
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
                self.vwBottomLoading.isHidden = true
                
                // Hide refreshControl (for refreshing)
                self.refreshControl.endRefreshing()
                
                if !self.isFirst {
                    self.addUploadingProducts()
                    self.isFirst = true
                }
                
                if self.nextIdx <= self.ItemPerLoad {
                    if (self.products.count > 0 || self.localProducts.count > 0) {
                        self.lblEmpty.isHidden = true
                        self.tableView.isHidden = false
                        self.tableView.reloadData()
                    } else {
                        self.lblEmpty.isHidden = false
                        self.btnRefresh.isHidden = false
                        self.tableView.isHidden = true
                    }
                } else if dataCount > 0 {
                    // section 0 -> local product (draft), 1 -> product
                    let lastRow = self.tableView.numberOfRows(inSection: 1) - 1
                    var idxs : Array<IndexPath> = []
                    for i in 1...dataCount {
                        idxs.append(IndexPath(row: lastRow+i, section: 1))
                    }
                    self.tableView.insertRows(at: idxs, with: .fade)
                }
            }
            
            self.isRefreshing = false
        }
    }
    
    func getLocalProducts() {
        localProducts = CDDraftProduct.getAllIsDraft()
        localProductPrimaryImages = []
    }
    
    func refresh(_ sender: AnyObject, isSearchMode : Bool) {
        self.isRefreshing = true
        
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
        let cell : ItemListCell = self.tableView.dequeueReusableCell(withIdentifier: "ItemListCell") as! ItemListCell
        if (!refreshControl.isRefreshing) {
            if (indexPath as NSIndexPath).section == 0 {
                let idx = (indexPath as NSIndexPath).row
                let p = localProducts[idx]
                
                cell.alpha = 1.0
                cell.backgroundColor = UIColor.white
                
                cell.lblProductName.text = p.name
                if p.price.int != 0 {
                    cell.lblPrice.text = p.price.int.asPrice
                }
                
                // Show draft status if item is not uploaded
                if p.isUploading != true {
                    cell.lblDraft.isHidden = false
                } else {
                    cell.lblDraft.isHidden = true
                }
                
                if p.priceRent.int != 0 {
                    cell.lblRentPrice.text = p.priceRent.int.asPrice
                }
                
                cell.imgProduct.image = nil
                
                if localProductPrimaryImages.count <= idx {
                    var image : UIImage?
                    
                    /*
                     if let data = NSData(contentsOfFile: p.imagePath1){
                     if let imageUrl = UIImage(data: data as Data) {
                     let img = UIImage(cgImage: imageUrl.cgImage!, scale: 1, orientation: UIImageOrientation(rawValue: p.imageOrientation1 as! Int)!).resizeWithWidth(120)
                     image = img
                     }
                     } else { // placeholder image
                     image = UIImage(named: "placeholder-standar-white")?.resizeWithWidth(120)
                     }
                     */
                    
                    // v2
                    let jsonstring = "{\"_data\":" + p.imagesPathAndLabel + "}"
                    //print(jsonstring)
                    
                    let json = jsonstring.convertToDictionary() ?? [:]
                    
                    // Images Preview Cell
                    if let imgs = JSON(json)["_data"].array, imgs.count > 0 {
                        
                        image = TemporaryImageManager.sharedInstance.loadImageFromDocumentsDirectory(imageName: imgs[0]["url"].stringValue)
                    }
                    
                    if image == nil {
                        image = UIImage(named: "placeholder-standar-white")?.resizeWithWidth(120)
                    }
                    
                    localProductPrimaryImages.append(image!)
                    cell.imgProduct.image = image!
                } else {
                    cell.imgProduct.image = localProductPrimaryImages[idx]
                }
                
                cell.imgProduct.afInflate()
                
                // Socmed share status
                cell.vwShareStatus.isHidden = false
                
                cell.lblPercentage.text = "90%"
            } else {
                let p = products[(indexPath as NSIndexPath).row]
                
                cell.alpha = 1.0
                cell.backgroundColor = UIColor.white
                
                cell.lblProductName.text = p.name
                cell.lblPrice.text = p.price
                
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
                ////print("size untuk '\(cell.lblOrderStatus.text)' = \(sizeThatShouldFitTheContent)")
                
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
                
                //Check State of Rent or Buy
                let rent = p.json["rent"]
                let price = p.json["price"]
                
                //Validation of rent
                if price != nil {
                    if price != 0 && (rent != nil && rent["price"].int != 0) {
                        var stringRentPriceValue: String = (rent["price"].int?.asPrice)!
                        if  rent["period_type"].int == 0 {
                            stringRentPriceValue = stringRentPriceValue + " / hari"
                        } else if rent["period_type"].int == 1 {
                            stringRentPriceValue = stringRentPriceValue + " / minggu"
                        } else {
                            stringRentPriceValue = stringRentPriceValue + " / bulan"
                        }
                        cell.showHideInfoProdTransCell(state: 0)
                        cell.lblRentPrice.text = stringRentPriceValue
                    }else if rent != nil {
                        var stringRentPriceValue: String = (rent["price"].int?.asPrice)!
                        if  rent["period_type"].int == 0 {
                            stringRentPriceValue = stringRentPriceValue + " / hari"
                        } else if rent["period_type"].int == 1 {
                            stringRentPriceValue = stringRentPriceValue + " / minggu"
                        } else {
                            stringRentPriceValue = stringRentPriceValue + " / bulan"
                        }
                        cell.showHideInfoProdTransCell(state: 2)
                        cell.lblRentPrice.text = stringRentPriceValue
                    }else {
                        cell.showHideInfoProdTransCell(state: 1)
                    }
                }else{
                    cell.showHideInfoProdTransCell(state: 4)
                }
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
            
            /*
             let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
             add.screenBeforeAddProduct = PageName.MyProducts
             add.draftMode = true
             add.draftProduct = localProducts[(indexPath as NSIndexPath).row]
             self.navigationController?.pushViewController(add, animated: true)
             */
            
            let addProduct3VC = Bundle.main.loadNibNamed(Tags.XibNameAddProduct3, owner: nil, options: nil)?.first as! AddProductViewController3
            addProduct3VC.screenBeforeAddProduct = PageName.ProductDetailMine
            addProduct3VC.draftProduct = localProducts[(indexPath as NSIndexPath).row]
            self.navigationController?.pushViewController(addProduct3VC, animated: true)
        } else {
            selectedProduct = products[(indexPath as NSIndexPath).row]
            if (selectedProduct!.isLokal)
            {
                return
            }
            
            /*
            let d:ProductDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
            d.product = selectedProduct!
            
            d.delegate = self.delegate
            
            d.previousScreen = PageName.MyProducts
            
            self.previousController?.navigationController?.pushViewController(d, animated: true)
            */
            
            let productDetail2VC = Bundle.main.loadNibNamed(Tags.XibNameProductDetail2, owner: nil, options: nil)?.first as! ProductDetailViewController2
            productDetail2VC.product = selectedProduct!
            productDetail2VC.delegate = self.delegate
            productDetail2VC.previousScreen = PageName.MyProducts
            self.navigationController?.pushViewController(productDetail2VC, animated: true)
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
        if (y > h + reloadDistance && !self.isRefreshing) {
            // Load next items only if all items not loaded yet and if its not currently loading items
            if (!self.isAllItemLoaded && !self.bottomLoading.isAnimating) {
                // Tampilkan loading di bawah
                bottomLoading.startAnimating()
                bottomLoading.isHidden = false
                self.vwBottomLoading.isHidden = false
                
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
