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
    @IBOutlet var tableView : UITableView!
    var products : Array<Product> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.lblEmpty.hidden = true
        self.tableView.hidden = true
        getProducts()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register custom cell
        var transactionListCellNib = UINib(nibName: "TransactionListCell", bundle: nil)
        tableView.registerNib(transactionListCellNib, forCellReuseIdentifier: "TransactionListCell")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.MyProducts, otherParam: ["Tab" : "Active"])
        
        // Google Analytics
        GAI.trackPageVisit(PageName.MyProducts)
    }
    
    func getProducts()
    {
        request(APIProduct.MyProduct(current: products.count, limit: 10))
            .responseJSON{req, resp, res, err in
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
                    if let result: AnyObject = res
                    {
                        let j = JSON(result)
                        let d = j["_data"].arrayObject
                        if let data = d
                        {
                            println("Product list data = \(data)")
                            for json in data
                            {
                                self.products.append(Product.instance(JSON(json))!)
                                self.tableView.tableFooterView = UIView()
                            }
                            if (self.products.count > 0) {
                                self.lblEmpty.hidden = true
                                self.tableView.hidden = false
                                self.tableView.reloadData()
                            } else {
                                self.lblEmpty.hidden = false
                                self.tableView.hidden = true
                            }
                        }
                    }
                } else {
                    
                }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : TransactionListCell = self.tableView.dequeueReusableCellWithIdentifier("TransactionListCell") as! TransactionListCell
        let p = products[indexPath.row]
        
        cell.lblProductName.text = p.name
        cell.lblPrice.text = p.price
        cell.lblOrderTime.text = p.time
        
        let commentCount : Int = (p.json["num_comment"] != nil) ? p.json["num_comment"].int! : 0
        cell.lblCommentCount.text = "\(commentCount)"
        
        let loveCount : Int = (p.json["num_lovelist"] != nil) ? p.json["num_lovelist"].int! : 0
        cell.lblLoveCount.text = "\(loveCount)"
        
        cell.imgProduct.image = nil
        if let url = p.coverImageURL {
            cell.imgProduct.setImageWithUrl(url, placeHolderImage: nil)
        }
        
        let status : String = (p.json["status_text"] != nil) ? p.json["status_text"].string! : "-"
        cell.lblOrderStatus.text = status.uppercaseString
        if (status == "Aktif") {
            cell.lblOrderStatus.textColor = Theme.PrimaryColor
        } else {
            cell.lblOrderStatus.textColor = UIColor.redColor()
        }
        
        // Fix product status text width
        let sizeThatShouldFitTheContent = cell.lblOrderStatus.sizeThatFits(cell.lblOrderStatus.frame.size)
        //println("size untuk '\(cell.lblOrderStatus.text)' = \(sizeThatShouldFitTheContent)")
        cell.consWidthLblOrderStatus.constant = sizeThatShouldFitTheContent.width
        
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
        
        selectedProduct = products[indexPath.row]
        
        var d:ProductDetailViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
        d.product = selectedProduct!
        
        self.previousController?.navigationController?.pushViewController(d, animated: true)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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