//
//  StorePageTabBarViewController.swift
//  Prelo
//
//  Created by Djuned on 1/14/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation



// MARK: - NewShopHeader Protocol

protocol NewShopHeaderDelegate: class {
    func dereaseHeader() // --> min 64
    func increaseHeader() // --> max
    func setupBanner(json: JSON)
    func setShopTitle(_ title: String)
    func setTransparentcy(_ isTransparent: Bool)
    func getTransparentcy() -> Bool
    
    func popView()
}

// MARK: - Class
class StorePageTabBarViewController: BaseViewController, NewShopHeaderDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    
    // MARK: - Properties
    var listItemVC : ListItemViewController?
    var shopReviewVC : ShopReviewViewController?
    var shopBadgeVC : ShopAchievementViewController?
    
    var avatarUrls : [String] = []
    var badges : Array<URL>! = []
    
    // shop header
    var shopId : String! = ""
    
    @IBOutlet weak var imageVIew: UIView! // hide
    @IBOutlet weak var shopAvatar: UIImageView!
    @IBOutlet weak var shopName: UILabel! // hide
    @IBOutlet weak var shopLocation: UILabel!
    @IBOutlet weak var shopBadges: UICollectionView!
    
    @IBOutlet weak var vwHeaderTabBar: UIView!
    @IBOutlet weak var vwChild: UIView!
    @IBOutlet weak var vwToko: UIView!
    @IBOutlet weak var vwReview: UIView!
    @IBOutlet weak var vwBadge: UIView!
    @IBOutlet weak var consTopVw: NSLayoutConstraint! // 0 --> -170
    @IBOutlet weak var consWidthCollectionView: NSLayoutConstraint!
    
    @IBOutlet weak var vwCollection: UIView! // hide
    @IBOutlet weak var vwGeolocation: UIView! // hide
    
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var isTransparent : Bool = true
    var isFirst : Bool = true
    var curTop : CGFloat = 0
    var isOnTop : Bool = false
    
    var currentPage = 0
    
    @IBOutlet weak var vwNavBar: UIView!
    var segmentView : SMSegmentView!
    var seletionBar: UIView = UIView()
    
    @IBOutlet weak var dashboardCover: UIImageView!
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = true
        
        // MARK: - Register UIVC Component(s)
        if let mainStoryboard = self.storyboard {
            listItemVC = mainStoryboard.instantiateViewController(withIdentifier: "productList") as? ListItemViewController
        } else {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            listItemVC = mainStoryboard.instantiateViewController(withIdentifier: "productList") as? ListItemViewController
        }
        
        listItemVC?.currentMode = .newShop
        listItemVC?.delegate = self
        
        shopReviewVC = Bundle.main.loadNibNamed(Tags.XibNameShopReview, owner: nil, options: nil)?.first as? ShopReviewViewController
        shopReviewVC?.currentMode = .inject
        shopReviewVC?.delegate = self
        
        shopBadgeVC = Bundle.main.loadNibNamed(Tags.XibNameShopAchievement, owner: nil, options: nil)?.first as? ShopAchievementViewController
        shopBadgeVC?.currentMode = .inject
        shopBadgeVC?.delegate = self
        
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        
        // Set title
        self.title = "" // clear title
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Google Analytics
        if (CDUser.getOne()?.id == shopId) {
            GAI.trackPageVisit(PageName.ShopMine)
        } else {
            GAI.trackPageVisit(PageName.Shop)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (self.shopId == nil || self.shopId == "") {
            _ = self.navigationController?.popViewController(animated: true)
            
            Constant.showDialog("Data Shop Pengguna", message: "Oops, profil seller tidak ditemukan")
        } else {
        
        if isFirst {
            listItemVC?.shopId = self.shopId
            listItemVC?.previousScreen = self.previousScreen
            shopReviewVC?.sellerId = self.shopId
            shopReviewVC?.sellerName = ""
            shopBadgeVC?.sellerId = self.shopId
            shopBadgeVC?.sellerName = ""
            
            // edit button
            if (self.shopId == CDUser.getOne()?.id) {
                setEditButton()
            }
            
            setupNavBar()
            setupSubView()
            setSelectionBar(0)
            segmentView.selectedSegmentIndex = 0
            
            isFirst = false
        }
        
        UIView.animate(withDuration: 0.5) {
            self.navigationController?.navigationBar.isTranslucent = true
        }
        
        if (self.isOnTop) {
            self.isOnTop = false
            self.dereaseHeader()
        }
        }
    }
    
    func setupNavBar() {
        // custom navbar
        // need size & style
        let appearance = SMSegmentAppearance()
        
        appearance.segmentOnSelectionColour = UIColor.white
        appearance.segmentOffSelectionColour = UIColor.white
        
        appearance.titleOnSelectionColour = Theme.TabSelectedColor
        appearance.titleOffSelectionColour = Theme.TabNormalColor
        
        appearance.titleOnSelectionFont = UIFont.systemFont(ofSize: 16.0)
        appearance.titleOffSelectionFont = UIFont.systemFont(ofSize: 16.0)
        
        appearance.contentVerticalMargin = 8
        
        let subFrame = CGRect(x: 0, y: 0, width: self.vwNavBar.width, height: 44)
        
        segmentView = SMSegmentView(frame: subFrame , dividerColour: UIColor.white, dividerWidth: 1, segmentAppearance: appearance)
        segmentView.tintColor = UIColor.clear
        segmentView.addTarget(self, action: #selector(StorePageTabBarViewController.navigateSegment(_:)), for: .valueChanged)
        
        segmentView.addSegmentWithTitle("Shop", onSelectionImage: nil, offSelectionImage: nil)
        
//        segmentView.addSegmentWithTitle("Review", onSelectionImage: nil, offSelectionImage: nil)
//        
//        segmentView.addSegmentWithTitle("Badge", onSelectionImage: nil, offSelectionImage: nil)
        
        self.vwNavBar.addSubview(segmentView)
        
        // only 3 -- toko, review, badge
        self.seletionBar.frame = CGRect(x: 0.0, y: 40.0, width: self.segmentView.frame.size.width/3, height: 4.0)
        self.seletionBar.backgroundColor = Theme.PrimaryColorDark
        
        self.vwNavBar.addSubview(seletionBar)
    }
    
    func setupSubView() {
        // toko
        let vc1 = self.listItemVC
        self.addChildViewController(vc1!)
        vc1?.view.frame = CGRect(x: 0, y: 0, width: self.vwHeaderTabBar.frame.size.width, height: self.vwChild.frame.size.height);
        self.vwToko.addSubview((vc1?.view)!)
        vc1?.didMove(toParentViewController: self)
        
        // review
        let vc2 = self.shopReviewVC
        self.addChildViewController(vc2!)
        vc2?.view.frame = CGRect(x: 0, y: 0, width: self.vwHeaderTabBar.frame.size.width, height: self.vwChild.frame.size.height);
        self.vwReview.addSubview((vc2?.view)!)
        vc2?.didMove(toParentViewController: self)
        
        // badge
        let vc3 = self.shopBadgeVC
        self.addChildViewController(vc3!)
        vc3?.view.frame = CGRect(x: 0, y: 0, width: self.vwHeaderTabBar.frame.size.width, height: self.vwChild.frame.size.height);
        self.vwBadge.addSubview((vc3?.view)!)
        vc3?.didMove(toParentViewController: self)
    }
    
    func scrollSubVC(_ index: Int) {
        scrollView.setContentOffset(CGPoint(x: CGFloat(CGFloat(index) * UIScreen.main.bounds.width), y: CGFloat(0)), animated: true)
    }
    
    func setSelectionBar(_ index: Int) {
        // 1
        let placeSelectionBar = { () -> () in
            var barFrame = self.seletionBar.frame
            barFrame.origin.x = barFrame.size.width * CGFloat(index)
            self.seletionBar.frame = barFrame
        }
        
        // 2
        if self.seletionBar.superview == nil {
            self.segmentView.addSubview(self.seletionBar)
            placeSelectionBar()
        }
        else {
            UIView.animate(withDuration: 0.3, animations: {
                placeSelectionBar()
            })
        }
    }
    
    // MARK: - Scrollview delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == self.scrollView)
        {
            var p : CGFloat = 0
            if (scrollView.bounds.width > 0) {
                p = scrollView.contentOffset.x / scrollView.bounds.width
            }

            if (currentPage != Int(p + 0.5) && p.remainder(dividingBy: 1) == 0)
            {
                currentPage = Int(p)
                setSelectionBar(currentPage)
                segmentView.selectedSegmentIndex = currentPage
            }
        }
    }
    
    // MARK: - Edit Profile button (right top)
    func setEditButton() {
        let btnEdit = self.createButtonWithIcon(AppFont.preloAwesome, icon: "")
        
        btnEdit.addTarget(self, action: #selector(StorePageTabBarViewController.editProfile), for: UIControlEvents.touchUpInside)
        
        self.navigationItem.rightBarButtonItem = btnEdit.toBarButton()
    }
    
    func editProfile()
    {
        // open edit profile vc
        let userProfileVC = Bundle.main.loadNibNamed(Tags.XibNameUserProfile, owner: nil, options: nil)?.first as! UserProfileViewController
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    // MARK: - button
    @IBAction func shopAvatarButtonPressed(_ sender: Any) {
        let c = CoverZoomController()
        c.labels = [self.shopName.text!]
        c.images = (self.avatarUrls)
        c.index = 0
        self.navigationController?.present(c, animated: true, completion: nil)
    }
    
    // button move view VC
    func navigateSegment(_ segmentView: SMSegmentView) {
        print("Select segment at index: \(segmentView.selectedSegmentIndex)")
        setSelectionBar(segmentView.selectedSegmentIndex)
        scrollSubVC(segmentView.selectedSegmentIndex)
    }
    
    // MARK: - delegate
    func increaseHeader() {
        
        
        if (self.isOnTop) {
            self.isOnTop = false
            
            // 1
            let placeSelectionBar = { () -> () in
                // parent
                var curView = self.vwHeaderTabBar.frame
                curView.origin.y = 0
                self.vwHeaderTabBar.frame = curView
                
                var cur2View = self.vwNavBar.frame
                cur2View.origin.y = 170 + 64
                self.vwNavBar.frame = cur2View
                
                var cur3View = self.vwChild.frame
                cur3View.origin.y = 215 + 64
                self.vwChild.frame = cur3View
                
                var cur4View = self.dashboardCover.frame
                cur4View.origin.y = -110
                self.dashboardCover.frame = cur4View
            }
            
            // 2
            UIView.animate(withDuration: 0.5, animations: {
                placeSelectionBar()
            })
            
            // inject center (fixer)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.consTopVw.constant = 0
            })
        }
    }
    
    func dereaseHeader() {
        
        if (!self.isOnTop) {
            self.isOnTop = true
            
            // 1
            let placeSelectionBar = { () -> () in
                // parent
                var curView = self.vwHeaderTabBar.frame
                curView.origin.y = -170
                self.vwHeaderTabBar.frame = curView
                
                var cur2View = self.vwNavBar.frame
                cur2View.origin.y = 0 + 64
                self.vwNavBar.frame = cur2View
                
                var cur3View = self.vwChild.frame
                cur3View.origin.y = 45 + 64
                self.vwChild.frame = cur3View
                
                var cur4View = self.dashboardCover.frame
                cur4View.origin.y = -280
                self.dashboardCover.frame = cur4View
            }
            
            // 2
            UIView.animate(withDuration: 0.5, animations: {
                placeSelectionBar()
            })
            
            // inject center (fixer)
            self.consTopVw.constant = -170
        }
    }
    
    func setupBanner(json: JSON) {
        
        self.shopAvatar.superview?.layoutIfNeeded()
        self.shopAvatar.superview?.layer.cornerRadius = (self.shopAvatar.width)/2
        self.shopAvatar.superview?.layer.masksToBounds = true
        
        self.shopAvatar.superview?.layer.borderColor = Theme.GrayLight.cgColor
        self.shopAvatar.superview?.layer.borderWidth = 3.5
        
        self.shopName.text = json["username"].stringValue
        let avatarThumbnail = json["profile"]["pict"].stringValue
        let shopAvatar = URL(string: avatarThumbnail)!
        self.shopAvatar.afSetImage(withURL: shopAvatar, withFilter: .circle)
        let avatarFull = avatarThumbnail.replacingOccurrences(of: "thumbnails/", with: "", options: NSString.CompareOptions.literal, range: nil)
        self.avatarUrls.append(avatarFull)
        
//        self.badges = [ (URL(string: "https://trello-avatars.s3.amazonaws.com/c86b504990d8edbb569ab7c02fb55e3d/50.png")!), (URL(string: "https://trello-avatars.s3.amazonaws.com/3a83ed4d4b42810c05608cdc5547e709/50.png")!), (URL(string: "https://trello-avatars.s3.amazonaws.com/7a98b746bc71ccaf9af1d16c4a6b152e/50.png")!) ]
        
        self.badges = []
        
        if let arr = json["featured_badges"].array {
            if arr.count > 0 {
                for i in 0...arr.count-1 {
                    self.badges.append(URL(string: arr[i]["icon"].string!)!)
                }
            }
        }
        
        self.setupCollection()
        
        self.shopLocation.text = "Unknown"
        
        if let regionId = json["profile"]["region_id"].string, let province_id = json["profile"]["province_id"].string
        {
            // yang ini go, region sama province nya null.
            if let region = CDRegion.getRegionNameWithID(regionId), let province = CDProvince.getProvinceNameWithID(province_id)
            {
                self.shopLocation.text = region + ", " + province
            }
        }
        
        self.imageVIew.isHidden = false
        self.shopName.isHidden = false
        self.vwGeolocation.isHidden = false
        
        let countReview = json["num_reviewer"].int
//        let countAchievement = (json["achievements"].array)?.count
        
        if self.segmentView.numberOfSegments == 1 {
            /*
            self.segmentView.addSegmentWithTitle("Toko", onSelectionImage: nil, offSelectionImage: nil)
            
            self.segmentView.addSegmentWithTitle("Review", onSelectionImage: nil, offSelectionImage: nil)
            
            self.segmentView.addSegmentWithTitle("Badge", onSelectionImage: nil, offSelectionImage: nil)
            */
            
            self.segmentView.addSegmentWithTitle("Review (" + countReview!.string + ")", onSelectionImage: nil, offSelectionImage: nil)
            
            self.segmentView.addSegmentWithTitle("Badge", onSelectionImage: nil, offSelectionImage: nil)
        }
        self.loadingPanel.isHidden = true
        
        // setup review
        self.shopReviewVC?.userReviews = []
        self.shopReviewVC?.sellerName = self.shopName.text!
        self.shopReviewVC?.averageRate = json["average_star"].float!
        self.shopReviewVC?.countReview = countReview!
        self.shopReviewVC?.setUserReviews(json["reviews"]["as_seller"])
        
        self.shopBadgeVC?.userAchievements = []
        self.shopBadgeVC?.sellerName = self.shopName.text!
        self.shopBadgeVC?.setUserAchievements(json["achievements"])
    }
    
    func setShopTitle(_ title: String) {
        self.title = title
    }
    
    func setTransparentcy(_ isTransparent: Bool) {
        self.isTransparent = isTransparent
    }
    
    func getTransparentcy() -> Bool {
        return self.isTransparent
    }
    
    func setupCollection() {
        
        let width = 39 * CGFloat(self.badges.count) + 9
        
        // Set collection view
        self.shopBadges.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcProgressCell")
        self.shopBadges.delegate = self
        self.shopBadges.dataSource = self
        self.shopBadges.backgroundView = UIView(frame: self.shopBadges.bounds)
        self.shopBadges.backgroundColor = UIColor.clear
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        layout.itemSize = CGSize(width: 38, height: 38)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        self.shopBadges.collectionViewLayout = layout
        
        self.shopBadges.isScrollEnabled = false
        self.consWidthCollectionView.constant = width
        
        self.vwCollection.isHidden = false
    }
    
    func popView() {
        if (self.previousScreen != "Push Notification" || self.previousScreen != "") {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - CollectionView delegate functions
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.badges!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = self.shopBadges.dequeueReusableCell(withReuseIdentifier: "collcProgressCell", for: indexPath)
        // Create icon view
        let vwIcon : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
        
        let img = UIImageView(frame: CGRect(x: 2, y: 2, width: 34, height: 34))
        img.layoutIfNeeded()
        img.layer.cornerRadius = (img.width ) / 2
        img.layer.masksToBounds = true
        img.afSetImage(withURL: badges[(indexPath as NSIndexPath).row], withFilter: .circleWithBadgePlaceHolder)
        
        vwIcon.addSubview(img)
        
        // Add view to cell
        cell.addSubview(vwIcon)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 38, height: 38)
    }

}
