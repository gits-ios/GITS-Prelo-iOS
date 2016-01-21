//
//  ShopReviewViewController.swift
//  Prelo
//
//  Created by Fransiska Hadiwidjana on 11/19/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class ShopReviewViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var userReviews : [UserReview] = []
    var sellerName : String = ""
    var sellerId : String = ""
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        var myLovelistCellNib = UINib(nibName: "ShopReviewCell", bundle: nil)
        tableView.registerNib(myLovelistCellNib, forCellReuseIdentifier: "ShopReviewCell")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = false
        loading.startAnimating()
        tableView.hidden = true
        lblEmpty.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set title
        self.title = "Review " + self.sellerName
        
        // Get reviews
        self.getUserReviews()
        
        // Mixpanel
        let p = [
            "Seller" : self.sellerName,
            "Seller ID" : self.sellerId
        ]
        Mixpanel.trackPageVisit(PageName.ShopReviews, otherParam: p)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ShopReviews)
    }
    
    func getUserReviews() {
        request(APIPeople.GetSellerReviews(id: self.sellerId)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Review Pengguna")) {
                let json = JSON(res!)
                let data = json["_data"]
                // Store data into variable
                for (index : String, item : JSON) in data {
                    let r = UserReview.instance(item)
                    if (r != nil) {
                        self.userReviews.append(r!)
                    }
                }
            }
            self.loadingPanel.hidden = true
            self.loading.stopAnimating()
            if (self.userReviews.count <= 0) {
                self.lblEmpty.hidden = false
            } else {
                self.tableView.hidden = false
                self.setupTable()
            }
        }
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            self.tableView.dataSource = self
            self.tableView.delegate = self
        }
        
        self.tableView.reloadData()
    }
    
    // MARK: - UITableView Functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userReviews.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : ShopReviewCell = self.tableView.dequeueReusableCellWithIdentifier("ShopReviewCell") as! ShopReviewCell
        cell.selectionStyle = .None
        let u = userReviews[indexPath.item]
        cell.adapt(u)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //println("Row \(indexPath.row) selected")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath:  NSIndexPath) -> CGFloat {
        let u = userReviews[indexPath.item]
        let commentHeight = u.comment.boundsWithFontSize(UIFont.systemFontOfSize(12), width: 240).height
        return 65 + commentHeight
    }
}

class ShopReviewCell : UITableViewCell {
    
    @IBOutlet var imgBuyer: UIImageView!
    @IBOutlet var lblBuyerName: UILabel!
    @IBOutlet var lblStar: UILabel!
    @IBOutlet var lblComment: UILabel!
    
    func adapt(userReview : UserReview) {
        imgBuyer.setImageWithUrl(userReview.buyerPictURL!, placeHolderImage: nil)
        lblBuyerName.text = userReview.buyerUsername
        lblComment.text = userReview.comment
        
        // Love
        var loveText = ""
        for (var i = 0; i < 5; i++) {
            if (i < userReview.star) {
                loveText += ""
            } else {
                loveText += ""
            }
        }
        let attrStringLove = NSMutableAttributedString(string: loveText)
        attrStringLove.addAttribute(NSKernAttributeName, value: CGFloat(1.4), range: NSRange(location: 0, length: loveText.length()))
        lblStar.attributedText = attrStringLove
    }
}