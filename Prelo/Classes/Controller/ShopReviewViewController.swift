//
//  ShopReviewViewController.swift
//  Prelo
//
//  Created by Fransiska Hadiwidjana on 11/19/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

enum ReviewMode {
    case `default`
    case inject
}

class ShopReviewViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var userReviews : Array<UserReview> = []
    var sellerName : String = ""
    var sellerId : String = ""
    
    var currentMode : ReviewMode! = .default
    
    weak var delegate : NewShopHeaderDelegate?
    var isTransparent = false
    var averageRate : Float = 0.0
    var countReview : Int = 0
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let myLovelistCellNib = UINib(nibName: "ShopReviewCell", bundle: nil)
        tableView.register(myLovelistCellNib, forCellReuseIdentifier: "ShopReviewCell")
        
        let myLovelistAverageCellNib = UINib(nibName: "ShopReviewAverageCell", bundle: nil)
        tableView.register(myLovelistAverageCellNib, forCellReuseIdentifier: "ShopReviewAverageCell")
        
        // for button baca lebih lanjut
        tableView.register(ButtonCell.self, forCellReuseIdentifier: "ButtonCell")
        
        // Belum ada review untuk user ini
        tableView.register(ProvinceCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        if (currentMode == .default) {
            loadingPanel.isHidden = false
            loading.startAnimating()
            
            tableView.isHidden = true
            lblEmpty.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set title
        self.title = "Review " + self.sellerName
        
        // Get reviews
        
        if (currentMode == .default) {
//            self.userReviews = []
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
//        if (self.userReviews.count <= 0) {
//            self.lblEmpty.isHidden = false
//            self.tableView.isHidden = true
//        } else {
//            self.tableView.isHidden = false
            self.setupTable()
//        }
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            self.tableView.dataSource = self
            self.tableView.delegate = self
        }
        
        self.tableView.reloadData()
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - (64 + 45) // (170 + 45)
        
//        let tableHeight = CGFloat((self.userReviews.count + (self.userReviews.count > 5 ? 2 : 1)) * 65) // min height
        let tableHeight = self.tableView.contentSize.height
        
        var bottom = CGFloat(1)
        if (tableHeight < screenHeight) {
            bottom += (screenHeight - tableHeight)
        }
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(0, 0, bottom, 0)
        tableView.contentInset = inset
        
        if (userReviews.count <= 0) {
            
            tableView.separatorStyle = .none
        }
    }
    
    // MARK: - UITableView Functions
    func numberOfSections(in tableView: UITableView) -> Int {
        if (currentMode == .inject) {
            if (self.userReviews.count > 0) {
                if (countReview > 5) {
                    return 3
                } else {
                    return 2
                }
            } else {
                return 1
            }
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (currentMode == .inject) {
            if (self.userReviews.count > 0) {
                if (section == 1) {
                    return self.userReviews.count
                } else {
                    return 1
                }
            } else {
                return 1
            }
        } else {
            return self.userReviews.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (currentMode == .inject) {
            if (self.userReviews.count > 0) {
                if ((indexPath as NSIndexPath).section == 0) {
                    let cell : ShopReviewAverageCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopReviewAverageCell") as! ShopReviewAverageCell
                    cell.selectionStyle = .none
                    cell.adapt(self.averageRate)
                    return cell
                } else if ((indexPath as NSIndexPath).section == 2) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell") as! ButtonCell
                    
                    cell.selectionStyle = .none
                    cell.backgroundColor = UIColor.clear
                    cell.clipsToBounds = true
                    cell.separatorInset = UIEdgeInsetsMake(0, UIScreen.main.bounds.size.width, 0, 0);
                    
                    let lblButton = UILabel(frame: CGRect(x: 16, y: 16, width: tableView.width - 32, height: 30))
                    
                    lblButton.text = "LIHAT SEMUA REVIEW (\(self.countReview))"
                    lblButton.textColor = Theme.GrayLight
                    lblButton.backgroundColor = UIColor.clear
                    lblButton.textAlignment = .center
                    lblButton.font = UIFont.systemFont(ofSize: 15)
                    lblButton.createBordersWithColor(Theme.GrayLight, radius: 4, width: 1)
                    
                    let vwBorder = UIView(frame: CGRect(x: 0, y: 0, width: tableView.width, height: 62))
                    
                    vwBorder.backgroundColor = UIColor.white
                    
                    vwBorder.addSubview(lblButton)
                    
                    cell.contentView.addSubview(vwBorder)
                    
                    return cell
                    
                } else {
                    let cell : ShopReviewCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopReviewCell") as! ShopReviewCell
                    cell.selectionStyle = .none
                    let u = userReviews[(indexPath as NSIndexPath).row]
                    cell.adapt(u)
                    return cell
                }
            } else { // Belum ada review untuk user ini
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
                
                cell?.selectionStyle = .none
                
                cell?.textLabel!.text = "Belum ada review untuk user ini"
                cell?.textLabel!.font = UIFont.systemFont(ofSize: 12)
                cell?.textLabel!.textAlignment = .center
                cell?.textLabel!.textColor = Theme.GrayDark
                
                return cell!
            }
        } else {
            let cell : ShopReviewCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopReviewCell") as! ShopReviewCell
            cell.selectionStyle = .none
            let u = userReviews[(indexPath as NSIndexPath).row]
            cell.adapt(u)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (currentMode == .inject && (indexPath as NSIndexPath).section == 2) {
            let shopReviewVC = Bundle.main.loadNibNamed(Tags.XibNameShopReview, owner: nil, options: nil)?.first as! ShopReviewViewController
            shopReviewVC.sellerId = self.sellerId
            shopReviewVC.sellerName = self.sellerName
            self.navigationController?.pushViewController(shopReviewVC, animated: true)
        }
        //print("Row \(indexPath.row) selected")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath:  IndexPath) -> CGFloat {
        if (currentMode == .inject) {
            if (self.userReviews.count > 0) {
                if ((indexPath as NSIndexPath).section == 0) {
                    return 140
                } else if ((indexPath as NSIndexPath).section == 2) {
                    return 62
                    
                } else {
                    let u = userReviews[(indexPath as NSIndexPath).item]
                    let commentHeight = u.comment.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: 240).height
                    return 65 + commentHeight
                }
            } else {
                return 90
            }
        } else {
            let u = userReviews[(indexPath as NSIndexPath).item]
            let commentHeight = u.comment.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: 240).height
            return 65 + commentHeight
        }
    }
    
    // MARK: - UIScrollView Functions
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (currentMode == .inject) {
            scrollViewHeaderShop(scrollView)
        }
    }
    
    func scrollViewHeaderShop(_ scrollView: UIScrollView) {
//        let pointY = CGFloat(1)
//        let screenSize = UIScreen.main.bounds
//        let screenHeight = screenSize.height - 170
//        let height = scrollView.contentSize.height
//        if (scrollView.contentOffset.y < pointY && height >= screenHeight) {
//            self.delegate?.increaseHeader()
//            self.transparentNavigationBar(true)
//        } else if (scrollView.contentOffset.y >= pointY && height >= screenHeight) {
//            self.delegate?.dereaseHeader()
//            self.transparentNavigationBar(false)
//        }
        
        let pointY = CGFloat(1)
        if (scrollView.contentOffset.y < pointY) {
//            self.delegate?.increaseHeader()
            self.transparentNavigationBar(true)
        } else if (scrollView.contentOffset.y >= pointY) {
//            self.delegate?.dereaseHeader()
            self.transparentNavigationBar(false)
        }
    }
    
    // MARK: - navbar styler
    func transparentNavigationBar(_ isActive: Bool) {
        if (currentMode == .inject) {
            if isActive && !(self.delegate?.getTransparentcy())! {
                self.delegate?.increaseHeader()
                
                UIView.animate(withDuration: 0.5) {
                    // Transparent navigation bar
                    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                    self.navigationController?.navigationBar.shadowImage = UIImage()
                    self.navigationController?.navigationBar.isTranslucent = true
                    
                    self.navigationController?.navigationBar.layoutIfNeeded()
                    
                    self.delegate?.setShopTitle("")
                }
                self.delegate?.setTransparentcy(true)
            } else if !isActive && (self.delegate?.getTransparentcy())!  {
                self.delegate?.dereaseHeader()
                
                UIView.animate(withDuration: 0.5) {
                    self.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
                    self.navigationController?.navigationBar.shadowImage = nil
                    self.navigationController?.navigationBar.isTranslucent = true
                    
                    // default prelo
                    UINavigationBar.appearance().barTintColor = Theme.PrimaryColor
                    
                    self.navigationController?.navigationBar.layoutIfNeeded()
                    
                    self.delegate?.setShopTitle(self.sellerName)
                }
                self.delegate?.setTransparentcy(false)
            }
        }
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
        super.prepareForReuse()
        
//        imgBuyer.image = nil
        imgBuyer.afCancelRequest()
        lblStar.attributedText = nil
        if self.floatRatingView != nil {
            self.floatRatingView.rating = 0
        }
    }
    
    func adapt(_ userReview : UserReview) {
        imgBuyer.afSetImage(withURL: userReview.buyerPictURL!, withFilter: .circle)
        imgBuyer.layoutIfNeeded()
        imgBuyer.layer.masksToBounds = true
        imgBuyer.layer.cornerRadius = (imgBuyer.frame.size.width) / 2
        
        imgBuyer.layer.borderColor = Theme.GrayLight.cgColor
        imgBuyer.layer.borderWidth = 2
        
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

class ShopReviewAverageCell : UITableViewCell {
    @IBOutlet var vwLove: UIView!
    @IBOutlet weak var circularView: UIView!
    @IBOutlet weak var averageStar: UILabel!
    
    var floatRatingView: FloatRatingView!
    
    func adapt(_ star : Float) {
        circularView.createBordersWithColor(UIColor.clear, radius: circularView.width/2, width: 0)

        circularView.backgroundColor = UIColor.init(hex: "D1D1D1")
        
        averageStar.text = star.clean
        
        averageStar.textColor = UIColor.white
        
        // Love floatable
        self.floatRatingView = FloatRatingView(frame: CGRect(x: 0, y: 0, width: 122.5, height: 21)) // 175 -> 122.5  30 -> 21
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
