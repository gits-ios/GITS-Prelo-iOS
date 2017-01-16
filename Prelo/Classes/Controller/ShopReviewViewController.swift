//
//  ShopReviewViewController.swift
//  Prelo
//
//  Created by Fransiska Hadiwidjana on 11/19/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

enum ReviewMode {
    case `default`
    case inject
}

class ShopReviewViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var userReviews : [UserReview] = []
    var sellerName : String = ""
    var sellerId : String = ""
    
    var reviewMode : ReviewMode!
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let myLovelistCellNib = UINib(nibName: "ShopReviewCell", bundle: nil)
        tableView.register(myLovelistCellNib, forCellReuseIdentifier: "ShopReviewCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        if reviewMode == .default{
            loadingPanel.isHidden = false
            loading.startAnimating()
            
            tableView.isHidden = true
        }
        
        lblEmpty.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set title
        self.title = "Review " + self.sellerName
        
        // Get reviews
        
        if (reviewMode == .default) {
            self.userReviews = []
            self.getUserReviews()
        }
        
        // Mixpanel
//        let p = [
//            "Seller" : self.sellerName,
//            "Seller ID" : self.sellerId
//        ]
//        Mixpanel.trackPageVisit(PageName.ShopReviews, otherParam: p)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ShopReviews)
    }
    
    func getUserReviews() {
        // API Migrasi
        let _ = request(APIUser.getSellerReviews(id: self.sellerId)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Review Pengguna")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                // Store data into variable
                for (_, item) in data {
                    let r = UserReview.instance(item)
                    if (r != nil) {
                        self.userReviews.append(r!)
                    }
                }
            }
            self.loadingPanel.isHidden = true
            self.loading.stopAnimating()
            if (self.userReviews.count <= 0) {
                self.lblEmpty.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.setupTable()
            }
        }
    }
    
    func setUserReviews(_ reviewData: JSON) {
        let data = reviewData
        // Store data into variable
        for (_, item) in data {
            let r = UserReview.instance(item)
            if (r != nil) {
                self.userReviews.append(r!)
            }
        }
        
        self.loadingPanel.isHidden = true
        self.loading.stopAnimating()
        if (self.userReviews.count <= 0) {
            self.lblEmpty.isHidden = false
        } else {
            self.tableView.isHidden = false
            self.setupTable()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userReviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ShopReviewCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopReviewCell") as! ShopReviewCell
        cell.selectionStyle = .none
        let u = userReviews[(indexPath as NSIndexPath).item]
        cell.adapt(u)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("Row \(indexPath.row) selected")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath:  IndexPath) -> CGFloat {
        let u = userReviews[(indexPath as NSIndexPath).item]
        let commentHeight = u.comment.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: 240).height
        return 65 + commentHeight
    }
}

class ShopReviewCell : UITableViewCell {
    
    @IBOutlet var imgBuyer: UIImageView!
    @IBOutlet var lblBuyerName: UILabel!
    @IBOutlet var lblStar: UILabel!
    @IBOutlet var lblComment: UILabel!
    
    @IBOutlet var vwLove: UIView!
    var floatRatingView: FloatRatingView!
    
    override func prepareForReuse() {
        imgBuyer.image = nil
        lblStar.attributedText = nil
        if self.floatRatingView != nil {
            self.floatRatingView.rating = 0
        }
    }
    
    func adapt(_ userReview : UserReview) {
        imgBuyer.afSetImage(withURL: userReview.buyerPictURL!)
        imgBuyer.layoutIfNeeded()
        imgBuyer.layer.masksToBounds = true
        imgBuyer.layer.cornerRadius = (imgBuyer.frame.size.width) / 2
        lblBuyerName.text = userReview.buyerUsername
        lblComment.text = userReview.comment
        
//        // Love
//        var loveText = ""
//        for i in 0 ..< 5 {
//            if (i < userReview.star) {
//                loveText += ""
//            } else {
//                loveText += ""
//            }
//        }
//        let attrStringLove = NSMutableAttributedString(string: loveText)
//        attrStringLove.addAttribute(NSKernAttributeName, value: CGFloat(1.4), range: NSRange(location: 0, length: loveText.length))
//        lblStar.attributedText = attrStringLove
        
        let star = Float(userReview.star)
        
        // Love floatable
        self.floatRatingView = FloatRatingView(frame: CGRect(x: 0, y: 2.5, width: 90, height: 16))
        self.floatRatingView.emptyImage = UIImage(named: "ic_love_96px_trp.png")?.withRenderingMode(.alwaysTemplate)
        self.floatRatingView.fullImage = UIImage(named: "ic_love_96px.png")?.withRenderingMode(.alwaysTemplate)
        // Optional params
        //                self.floatRatingView.delegate = self
        self.floatRatingView.contentMode = UIViewContentMode.scaleAspectFit
        self.floatRatingView.maxRating = 5
        self.floatRatingView.minRating = 0
        self.floatRatingView.rating = star
        self.floatRatingView.editable = false
        self.floatRatingView.halfRatings = true
        self.floatRatingView.floatRatings = true
        self.floatRatingView.tintColor = Theme.ThemeRed
        
        self.vwLove.addSubview(self.floatRatingView )
    }
}
