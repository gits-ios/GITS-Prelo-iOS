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
    
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var averageSeller : Float = 0.0
    var sellerId = ""
    var floatRatingView: FloatRatingView!
    
    var reviewSellers : Array<UserReview> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let shopReviewCellNib = UINib(nibName: "ShopReviewCell", bundle: nil)
        tableView.register(shopReviewCellNib, forCellReuseIdentifier: "ShopReviewCell")
        
        let myLovelistAverageCellNib = UINib(nibName: "ShopReviewAverageCell", bundle: nil)
        tableView.register(myLovelistAverageCellNib, forCellReuseIdentifier: "ShopReviewAverageCell")
        
        // Belum ada review untuk user ini
        tableView.register(ProvinceCell.self, forCellReuseIdentifier: "cell")
    }
    
    func setup() {
        self.getReviewSellers()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if reviewSellers.count > 0 {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if reviewSellers.count > 0 {
            if section == 0 {
                return 1
            }
            return reviewSellers.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if reviewSellers.count > 0 {
            if indexPath.section == 0 {
                let cell : ShopReviewAverageCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopReviewAverageCell") as! ShopReviewAverageCell
                cell.adapt(self.averageSeller, countReview: self.reviewSellers.count, type: nil)
                return cell
                
            } else {
                let cell : ShopReviewCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopReviewCell") as! ShopReviewCell
                cell.adapt(reviewSellers[(indexPath as NSIndexPath).row])
                return cell
                
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            
            cell?.selectionStyle = .none
            cell?.alpha = 1.0
            cell?.backgroundColor = UIColor.white
            
            cell?.textLabel!.text = "Belum ada review untuk user ini"
            cell?.textLabel!.font = UIFont.systemFont(ofSize: 12)
            cell?.textLabel!.textAlignment = .center
            cell?.textLabel!.textColor = Theme.GrayDark
            
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if reviewSellers.count > 0 {
            if indexPath.section == 0 {
                return 104
                
            } else {
                let u = reviewSellers[(indexPath as NSIndexPath).item]
                let commentHeight = u.comment.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: 240).height
                return 65 + commentHeight
                
            }
        } else {
            return 90
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func getReviewSellers(){
        self.reviewSellers = []
        self.loadingPanel.isHidden = false
        let _ = request(APIUser.getSellerReviews(id: sellerId)).responseJSON {resp in
            
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Review Sebagai Penjual")) {
                if let result: AnyObject = resp.result.value as AnyObject?
                {
                    let j = JSON(result)
                    let d = j["_data"].arrayObject
                    if let data = d
                    {
                        for json in data
                        {
                            self.reviewSellers.append(UserReview.instance(JSON(json))!)
                        }
                    }
                    if d?.count == 0 {
                        self.tableView.separatorStyle = .none
                    }
                    self.loadingPanel.isHidden = true
                    self.tableView.reloadData()
                } else {
                    self.tableView.separatorStyle = .none
                }
            } else {
                self.tableView.separatorStyle = .none
            }
        }
    }
}
