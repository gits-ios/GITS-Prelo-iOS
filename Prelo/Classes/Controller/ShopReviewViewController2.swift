//
//  ShopReviewViewController2.swift
//  Prelo
//
//  Created by Djuned on 8/25/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class ShopReviewViewController2: BaseViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var vwRvwasSeller: UIView!
    @IBOutlet weak var vwRvwAverageSeller: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var vwRvwasBuyer: UIView!
    @IBOutlet weak var vwRvwAverageBuyer: UIView!
    @IBOutlet weak var tableViewRvwasBuyer: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var btnMoreReview: UIButton!
    
    var userReviews : Array<UserReview> = []
    var userFeedbacks : Array<UserReview> = []
    var sellerName : String = ""
    var sellerId : String = ""
    
    weak var delegate : NewShopHeaderDelegate?
    var isTransparent = false
    var averageRate : Float = 0.0
    var averageFeedback : Float = 0.0
    var countReview : Int = 0
    var countFeedback: Int = 0
    
    var isFirst = true
    
    @IBAction func btnMoreReviewPressed(_ sender: Any) {
        let ReviewTabBarVC = Bundle.main.loadNibNamed(Tags.XibNameReviewTabBar, owner: nil, options: nil)?.first as! ReviewTabBarViewController
        ReviewTabBarVC.averageBuyer = self.averageFeedback
        ReviewTabBarVC.averageSeller = self.averageRate
        ReviewTabBarVC.sellerId = sellerId
        self.navigationController?.pushViewController(ReviewTabBarVC, animated: true)
    }
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnMoreReview.layer.borderColor = UIColor.lightGray.cgColor
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        tableViewRvwasBuyer.tableFooterView = UIView()
        
        // Register custom cell
        let myLovelistCellNib = UINib(nibName: "ShopReviewCell", bundle: nil)
        tableView.register(myLovelistCellNib, forCellReuseIdentifier: "ShopReviewCell")
        tableViewRvwasBuyer.register(myLovelistCellNib, forCellReuseIdentifier: "ShopReviewCell")
        
        
        // Belum ada review untuk user ini
        tableView.register(ProvinceCell.self, forCellReuseIdentifier: "cell")
        tableViewRvwasBuyer.register(ProvinceCell.self, forCellReuseIdentifier: "cell")
        
        self.scrollView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ShopReviews)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUserReviews(_ reviewData: JSON, feedbackData: JSON) {
        self.userReviews = []
        self.userFeedbacks = []
        
        var data = reviewData
        for (_, item) in data {
            if let r = UserReview.instance(item) {
                self.userReviews.append(r)
            }
        }
        
        data = feedbackData
        for (_, item) in data {
            if let r = UserReview.instance(item) {
                self.userFeedbacks.append(r)
            }
        }
        
        self.setupAverageView()
        self.setupTable()
        self.loadingPanel.isHidden = true
        self.loading.stopAnimating()
    }
    
    func setupAverageView() {
        if let customView = Bundle.main.loadNibNamed("ShopReview2Average", owner: self, options: nil)?.first as? ShopReview2Average {
            customView.adapt(self.averageRate, isAsSeller: true)
            vwRvwAverageSeller.addSubview(customView)
            
            customView.frame = vwRvwAverageSeller.bounds
        }
        if let customView = Bundle.main.loadNibNamed("ShopReview2Average", owner: self, options: nil)?.first as? ShopReview2Average {
            customView.adapt(self.averageFeedback, isAsSeller: false)
            vwRvwAverageBuyer.addSubview(customView)
            
            customView.frame = vwRvwAverageBuyer.bounds
        }
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.tableFooterView = UIView()
        }
        
        self.tableView.reloadData()
        
        if (self.tableViewRvwasBuyer.delegate == nil) {
            self.tableViewRvwasBuyer.dataSource = self
            self.tableViewRvwasBuyer.delegate = self
            self.tableViewRvwasBuyer.tableFooterView = UIView()
        }
        
        self.tableViewRvwasBuyer.reloadData()
        
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
        
        if(countReview > 3 || countFeedback > 3){
            btnMoreReview.setTitle("LIHAT SEMUA REVIEW (" + String(countReview + countFeedback) + ")", for: .normal)
            btnMoreReview.isHidden = false
            
        } else {
            btnMoreReview.isHidden = true
        }
    }
    
    // MARK: - UITableView Functions
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == self.tableView){
            return self.userReviews.count > 0 ? self.userReviews.count : 1
        } else {
            return self.userFeedbacks.count > 0 ? self.userFeedbacks.count : 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(tableView == self.tableView){
            
            if (self.userReviews.count > 0) {
                let cell : ShopReviewCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopReviewCell") as! ShopReviewCell
                
                cell.selectionStyle = .none
                cell.alpha = 1.0
                cell.backgroundColor = UIColor.white
                
                cell.lblComment.numberOfLines = 1
                
                let u = userReviews[(indexPath as NSIndexPath).row]
                cell.adapt(u)
                
                return cell
            } else { // Belum ada review untuk user ini
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
        else {
            
            if (self.userFeedbacks.count > 0) {
                let cell : ShopReviewCell = self.tableViewRvwasBuyer.dequeueReusableCell(withIdentifier: "ShopReviewCell") as! ShopReviewCell
                
                cell.selectionStyle = .none
                cell.alpha = 1.0
                cell.backgroundColor = UIColor.white
                
                cell.lblComment.numberOfLines = 1
                
                let u = userFeedbacks[(indexPath as NSIndexPath).row]
                cell.adapt(u)
                
                return cell
            } else { // Belum ada review untuk user ini
                let cell = tableViewRvwasBuyer.dequeueReusableCell(withIdentifier: "cell")
                
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
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath:  IndexPath) -> CGFloat {
        return 65 + 17
    }
    
    // MARK: - UIScrollView Functions
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewHeaderShop(scrollView)
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

class ShopReview2Average : UIView {
    @IBOutlet weak var reviewAs: UILabel!
    @IBOutlet var vwLove: UIView!
    @IBOutlet weak var circularView: UIView!
    @IBOutlet weak var averageStar: UILabel!
    
    var floatRatingView: FloatRatingView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Love floatable
        self.floatRatingView = FloatRatingView(frame: CGRect(x: 0, y: 0, width: 87.5, height: 15)) // 175 -> 122.5 -> 73.75 -> 87.5  30 -> 21 -> 12.6 -> 15
        self.floatRatingView.emptyImage = UIImage(named: "ic_love_96px_trp.png")?.withRenderingMode(.alwaysTemplate)
        self.floatRatingView.fullImage = UIImage(named: "ic_love_96px.png")?.withRenderingMode(.alwaysTemplate)
        
        // Optional params
        self.floatRatingView.contentMode = UIViewContentMode.scaleAspectFit
        self.floatRatingView.maxRating = 5
        self.floatRatingView.minRating = 0
        self.floatRatingView.editable = false
        self.floatRatingView.halfRatings = true
        self.floatRatingView.floatRatings = true
        self.floatRatingView.tintColor = Theme.ThemeRed
        
        self.vwLove.addSubview(self.floatRatingView )
        
        circularView.createBordersWithColor(UIColor.clear, radius: circularView.width/2, width: 0)
        
        circularView.backgroundColor = UIColor.init(hex: "FFFFFF")
        
        averageStar.textColor = UIColor.darkGray
        
        self.backgroundColor = UIColor.init(hexString: "#F0F0F0")
    }
    
    func adapt(_ star : Float, isAsSeller: Bool) {
        
        self.reviewAs.text = "Review sebagai " + (isAsSeller ? "penjual" : "pembeli")
        
        averageStar.text = String(round(10*star)/10)
        
        self.floatRatingView.rating = star
    }
}
