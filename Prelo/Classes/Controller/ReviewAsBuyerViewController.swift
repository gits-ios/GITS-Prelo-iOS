//
//  ReviewAsBuyerViewController.swift
//  Prelo
//
//  Created by Prelo on 7/18/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Alamofire

class ReviewAsBuyerViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var btnRefresh: UIButton!
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    @IBOutlet var vwLove: UIView!
    @IBOutlet weak var circularView: UIView!
    @IBOutlet weak var averageStar: UILabel!
    @IBOutlet weak var countReview: UILabel!
    
    var averageBuyer : Float = 0.0
    
    var floatRatingView: FloatRatingView!
    
    func adapt(_ star : Float) {
        circularView.createBordersWithColor(UIColor.clear, radius: circularView.width/2, width: 0)
        
        circularView.backgroundColor = UIColor.init(hex: "FFFFFF")
        
        averageStar.text = star.clean
        
        averageStar.textColor = UIColor.darkGray
        
        // Love floatable
        self.floatRatingView = FloatRatingView(frame: CGRect(x: 0, y: 0, width: 122.5, height: 21)) // 175 -> 122.5 -> 73.75  30 -> 21 -> 12.6
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
    
    var reviewBuyers : Array<BuyerReview> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.adapt(averageBuyer)
        
        print("masuk sini loh lalala")
        // Do any additional setup after loading the view.
        self.lblEmpty.isHidden = false
        self.tableView.isHidden = false
        self.btnRefresh.isHidden = false
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        self.getReviewBuyers()
        
        // Register custom cell
        let shopReviewCellNib = UINib(nibName: "ShopReviewCell", bundle: nil)
        tableView.register(shopReviewCellNib, forCellReuseIdentifier: "ShopReviewCell")
        
    }
    
    var first = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    func refresh(_ sender: AnyObject) {
        // Reset data
        self.reviewBuyers = []
        
        self.tableView.isHidden = true
        self.lblEmpty.isHidden = true
        self.btnRefresh.isHidden = true
        
        self.getReviewBuyers()
    }
    
    @IBAction func refreshPressed(_ sender: AnyObject) {
        self.refresh(sender)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // local , onstore
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviewBuyers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ShopReviewCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopReviewCell") as! ShopReviewCell
        cell.adapt2(reviewBuyers[(indexPath as NSIndexPath).row])
        cell.setCons(activeCons: false)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let u = reviewBuyers[(indexPath as NSIndexPath).item]
        let commentHeight = u.comment.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: 240).height
        return 65 + commentHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func getReviewBuyers(){
        self.loadingPanel.isHidden = false
        let _ = request(APIUser.getBuyerReview(id: User.Id!)).responseJSON {resp in
            
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Review Sebagai Pembeli")) {
                if let result: AnyObject = resp.result.value as AnyObject?
                {
                    let j = JSON(result)
                    let d = j["_data"].arrayObject
                    if let data = d
                    {
                        for json in data
                        {
                            self.reviewBuyers.append(BuyerReview.instance(JSON(json))!)
                            self.tableView.tableFooterView = UIView()
                            self.lblEmpty.isHidden = true
                            self.tableView.isHidden = false
                            self.btnRefresh.isHidden = true
                            self.tableView.reloadData()
                            self.loadingPanel.isHidden = true
                        }
                        self.countReview.text = String(self.reviewBuyers.count) + " review"
                    } else {
                        self.lblEmpty.isHidden = false
                        self.tableView.isHidden = true
                        self.btnRefresh.isHidden = false
                        self.loadingPanel.isHidden = true
                    }
                }
            }
        }
    }
}
