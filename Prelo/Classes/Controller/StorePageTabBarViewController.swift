//
//  StorePageTabBarViewController.swift
//  Prelo
//
//  Created by Djuned on 1/14/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation



// MARK: - NewShopHeader Protocol

protocol NewShopHeaderDelegate {
    func dereaseHeader() // --> min 64
    func increaseHeader() // --> max
    func setupBanner(json: JSON)
    func setShopTitle(_ title: String)
    func setTransparentcy(_ isTransparent: Bool)
    func getTransparentcy() -> Bool
}

// MARK: - Class
class StorePageTabBarViewController: BaseViewController, NewShopHeaderDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Properties
//    var tabSwipe : CarbonTabSwipeNavigation?
    var listItemVC : ListItemViewController?
    var shopReviewVC : ShopReviewViewController?
    var shopBadgeVC : ShopAchievementViewController?
    
    var listVC : [UIViewController]!
    var avatarUrls : [String] = []
    var badges : Array<URL>! = []
    
    // shop header
    var shopId : String!
    
    @IBOutlet var imageVIew: UIView! // hide
    @IBOutlet var shopAvatar: UIImageView!
    @IBOutlet var shopName: UILabel! // hide
    @IBOutlet var shopLocation: UILabel!
    @IBOutlet var shopBadges: UICollectionView!
    
    @IBOutlet var vwHeaderTabBar: UIView!
    @IBOutlet var vwChild: UIView!
    @IBOutlet var consTopVw: NSLayoutConstraint! // 0 --> -170
    @IBOutlet var consWidthCollectionView: NSLayoutConstraint!
    
    @IBOutlet var vwCollection: UIView! // hide
    @IBOutlet var vwGeolocation: UIView! // hide
    
    var isTransparent : Bool = true
    var isFirst : Bool = true
    var curTop : CGFloat = 0
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        listVC = []
        
        listVC.append(listItemVC!)
        listVC.append(shopReviewVC!)
        listVC.append(shopBadgeVC!)
        
        // Set title
        self.title = "" // clear title
        
        // edit button
        setEditButton()
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
        
        if isFirst {
            listItemVC?.shopId = self.shopId
            shopReviewVC?.sellerId = self.shopId
            shopReviewVC?.sellerName = ""
            shopBadgeVC?.sellerId = self.shopId
            shopBadgeVC?.sellerName = ""
            
            
            setSubVC(0)
            isFirst = false
        }
        
        self.consTopVw.constant = self.curTop
        UIView.animate(withDuration: 0.5) {
            self.navigationController?.navigationBar.isTranslucent = true
        }
    }
    
    func setSubVC(_ index: Int) {
        let vc  = self.listVC[index]
        self.addChildViewController(vc)
        vc.view.frame = CGRect(x: 0, y: 0, width: self.vwHeaderTabBar.frame.size.width, height: self.vwChild.frame.size.height);
        self.vwChild.addSubview((vc.view)!)
        vc.didMove(toParentViewController: self)
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
    @IBAction func navBarPressed(_ sender: UISegmentedControl) {
        self.setSubVC(sender.selectedSegmentIndex)
    }
    
    // MARK: - delegate
    func increaseHeader() {
        if (self.consTopVw.constant < 0) {
            self.consTopVw.constant += 10
            
            self.curTop = self.consTopVw.constant
        }
    }
    
    func dereaseHeader() {
        
        if (self.consTopVw.constant > -170) {
            self.consTopVw.constant -= 10
            
            self.curTop = self.consTopVw.constant
        }
    }
    
    func setupBanner(json: JSON) {
        
        self.shopAvatar.superview?.layoutIfNeeded()
        self.shopAvatar.superview?.layer.cornerRadius = (self.shopAvatar.width)/2
        self.shopAvatar.superview?.layer.masksToBounds = true
        
        self.shopName.text = json["username"].stringValue
        let avatarThumbnail = json["profile"]["pict"].stringValue
        let shopAvatar = URL(string: avatarThumbnail)!
        self.shopAvatar.afSetImage(withURL: shopAvatar)
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
        
        // setup review
        self.shopReviewVC?.userReviews = []
        self.shopReviewVC?.setUserReviews(json["reviews"])
        self.shopReviewVC?.sellerName = self.shopName.text!
        self.shopBadgeVC?.userAchievements = []
        self.shopBadgeVC?.setUserAchievements(json["achievements"])
        self.shopBadgeVC?.sellerName = self.shopName.text!
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
        
        let width = 35 * CGFloat(self.badges.count) + 5
        
        // Set collection view
        self.shopBadges.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcProgressCell")
        self.shopBadges.delegate = self
        self.shopBadges.dataSource = self
        self.shopBadges.backgroundView = UIView(frame: self.shopBadges.bounds)
        self.shopBadges.backgroundColor = UIColor.clear
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        self.shopBadges.collectionViewLayout = layout
        
        self.shopBadges.isScrollEnabled = false
        self.consWidthCollectionView.constant = width
        
        self.vwCollection.isHidden = false
    }
    
    // MARK: - CollectionView delegate functions
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.badges!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = self.shopBadges.dequeueReusableCell(withReuseIdentifier: "collcProgressCell", for: indexPath)
        //        if (badges.count > (indexPath as NSIndexPath).row) {
        // Create icon view
        let vwIcon : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        
        let img = UIImageView(frame: CGRect(x: 2, y: 2, width: 28, height: 28))
        img.layoutIfNeeded()
        img.layer.cornerRadius = (img.width ) / 2
        img.layer.masksToBounds = true
        img.afSetImage(withURL: badges[(indexPath as NSIndexPath).row])
        
        vwIcon.addSubview(img)
        
        // Add view to cell
        cell.addSubview(vwIcon)
        //        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 30, height: 30)
    }

}
