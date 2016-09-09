//
//  MyProductSellViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class MyProductSellViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet var btnRefresh: UIButton!
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
        self.lblEmpty.hidden = true
        self.tableView.hidden = true
        self.btnRefresh.hidden = true
        self.loading.startAnimating()
        self.loading.hidden = false
//        getProducts()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0)
        
        self.getProducts()
        
        // Register custom cell
        let transactionListCellNib = UINib(nibName: "TransactionListCell", bundle: nil)
        tableView.registerNib(transactionListCellNib, forCellReuseIdentifier: "TransactionListCell")
        
        // Hide bottom refresh first
        bottomLoading.stopAnimating()
        bottomLoading.hidden = true
        consBottomTableView.constant = 0
        
        // Refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = Theme.PrimaryColor
        self.refreshControl.addTarget(self, action: #selector(MyProductSellViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    var first = true
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.MyProducts, otherParam: ["Tab" : "Active"])
        
        // Google Analytics
        GAI.trackPageVisit(PageName.MyProducts)
        
        if (!first)
        {
            self.refresh(0)
        }
        
        first = false
        
        ProdukUploader.AddObserverForUploadSuccess(self, selector: #selector(MyProductSellViewController.uploadProdukSukses(_:)))
        ProdukUploader.AddObserverForUploadFailed(self, selector: #selector(MyProductSellViewController.uploadProdukGagal(_:)))
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        ProdukUploader.RemoveObserverForUploadSuccess(self)
        ProdukUploader.RemoveObserverForUploadFailed(self)
    }
    
    func uploadProdukSukses(notif : NSNotification)
    {
        refresh(0)
        Constant.showDialog("Upload Barang Berhasil", message: "Proses review barang akan memakan waktu maksimal 2 hari kerja. Mohon tunggu :)")
    }
    
    func uploadProdukGagal(notif : NSNotification)
    {
        refresh(0)
        Constant.showDialog("Upload Barang Gagal", message: "Oops, upload barang gagal")
    }
    
    func addUploadingProducts()
    {
        let uploadingProducts = AppDelegate.Instance.produkUploader.getQueue()
        for p in uploadingProducts.reversedArray()
        {
            if let prod = p.toProduct
            {
                products.insert(prod, atIndex: 0)
            }
        }
    }
    
    func getProducts()
    {
        // API Migrasi
        request(APIProduct.MyProduct(current: nextIdx, limit: (nextIdx + ItemPerLoad))).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Jualan Saya")) {
                if let result: AnyObject = resp.result.value
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
            self.loading.hidden = true
            
            // Hide bottomLoading (for next request)
            self.bottomLoading.stopAnimating()
            self.bottomLoading.hidden = true
            self.consBottomTableView.constant = 0
            
            // Hide refreshControl (for refreshing)
            self.refreshControl.endRefreshing()
            
            self.addUploadingProducts()
            
            if (self.products.count > 0) {
                self.lblEmpty.hidden = true
                self.tableView.hidden = false
                self.tableView.reloadData()
            } else {
                self.lblEmpty.hidden = false
                self.btnRefresh.hidden = false
                self.tableView.hidden = true
            }
        }
    }
    
    func refresh(sender: AnyObject) {
        // Reset data
        self.products = []
        self.addUploadingProducts()
        self.nextIdx = 0
        self.isAllItemLoaded = false
        self.tableView.hidden = true
        self.lblEmpty.hidden = true
        self.btnRefresh.hidden = true
        self.loading.hidden = false
        getProducts()
    }
    
    @IBAction func refreshPressed(sender: AnyObject) {
        self.refresh(sender)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : TransactionListCell = self.tableView.dequeueReusableCellWithIdentifier("TransactionListCell") as! TransactionListCell
        if (!refreshControl.refreshing) {
            let p = products[indexPath.row]
            
            cell.lblProductName.text = p.name
            cell.lblPrice.text = p.price
            cell.lblOrderTime.text = p.time
            
            if (p.isFreeOngkir) {
                cell.imgFreeOngkir.hidden = false
            }
            
            let commentCount : Int = (p.json["num_comment"] != nil) ? p.json["num_comment"].int! : 0
            cell.lblCommentCount.text = "\(commentCount)"
            
            let loveCount : Int = (p.json["num_lovelist"] != nil) ? p.json["num_lovelist"].int! : 0
            cell.lblLoveCount.text = "\(loveCount)"
            
            cell.imgProduct.image = nil
            if let url = p.coverImageURL {
                cell.imgProduct.setImageWithUrl(url, placeHolderImage: nil)
            } else if let img = p.placeHolderImage
            {
                cell.imgProduct.image = img
            }
            
            let status : String = (p.json["status_text"] != nil) ? p.json["status_text"].string! : "-"
            cell.lblOrderStatus.text = status.uppercaseString
            if (p.isLokal)
            {
                cell.lblOrderStatus.text = "Uploading"
            }
            
            if (status.lowercaseString == "aktif") {
                cell.lblOrderStatus.textColor = Theme.PrimaryColor
            } else if (status.lowercaseString == "direview admin") {
                cell.lblOrderStatus.textColor = Theme.ThemeOrange
            } else {
                cell.lblOrderStatus.textColor = UIColor.redColor()
            }
            
            // Fix product status text width
            let sizeThatShouldFitTheContent = cell.lblOrderStatus.sizeThatFits(cell.lblOrderStatus.frame.size)
            //print("size untuk '\(cell.lblOrderStatus.text)' = \(sizeThatShouldFitTheContent)")
            cell.consWidthLblOrderStatus.constant = sizeThatShouldFitTheContent.width
            
            // Socmed share status
            cell.vwShareStatus.hidden = false
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
            m.ivCover.setImageWithUrl(url, placeHolderImage: nil)
        }
        
        return m*/
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //return 80 // If using MyProductCell
        return 64
    }
    
    var selectedProduct : Product?
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        selectedProduct = products[indexPath.row]
        if (selectedProduct!.isLokal)
        {
            return
        }
        
        let d:ProductDetailViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
        d.product = selectedProduct!
        
        self.previousController?.navigationController?.pushViewController(d, animated: true)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset : CGPoint = scrollView.contentOffset
        let bounds : CGRect = scrollView.bounds
        let size : CGSize = scrollView.contentSize
        let inset : UIEdgeInsets = scrollView.contentInset
        let y : CGFloat = offset.y + bounds.size.height - inset.bottom
        let h : CGFloat = size.height
        
        let reloadDistance : CGFloat = 0
        if (y > h + reloadDistance) {
            // Load next items only if all items not loaded yet and if its not currently loading items
            if (!self.isAllItemLoaded && !self.bottomLoading.isAnimating()) {
                // Tampilkan loading di bawah
                consBottomTableView.constant = ConsBottomTableViewWhileUpdating
                bottomLoading.startAnimating()
                bottomLoading.hidden = false
                
                // Get user products
                self.getProducts()
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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