//
//  StorePageTabBarViewController.swift
//  Prelo
//
//  Created by Djuned on 1/14/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation


// MARK: - Class
class StorePageTabBarViewController: BaseViewController, CarbonTabSwipeDelegate {
    
    // MARK: - Properties
    var tabSwipe : CarbonTabSwipeNavigation?
    var listItemVC : ListItemViewController?
    var shopReviewVC : ShopReviewViewController?
    var shopBadgeVC : ShopReviewViewController? // TODO: - create ui vc
    
    // shop header
    var shopId : String!
    
    @IBOutlet weak var imageVIew: UIView!
    @IBOutlet weak var shopAvatar: UIImageView!
    @IBOutlet weak var shopName: UILabel!
    @IBOutlet weak var shopLocation: UILabel!
    @IBOutlet weak var shopBadges: UICollectionView!
    
    @IBOutlet weak var vwHeaderTabBar: UIView!
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
//        self.navigationController?.navigationBar.height = 194
        
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
        
        // MARK: - Register UIVC Component(s)
        if let mainStoryboard = self.storyboard {
            listItemVC = mainStoryboard.instantiateViewController(withIdentifier: "productList") as? ListItemViewController
        } else {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            listItemVC = mainStoryboard.instantiateViewController(withIdentifier: "productList") as? ListItemViewController
        }
        
        listItemVC?.currentMode = .shop
        listItemVC?.shopId = self.shopId
        
        shopReviewVC = Bundle.main.loadNibNamed(Tags.XibNameShopReview, owner: nil, options: nil)?.first as? ShopReviewViewController
        
        shopBadgeVC = Bundle.main.loadNibNamed(Tags.XibNameShopReview, owner: nil, options: nil)?.first as? ShopReviewViewController
        
        tabSwipe = CarbonTabSwipeNavigation().create(withRootViewController: self, tabNames: ["Toko" as AnyObject, "Review" as AnyObject, "Badge" as AnyObject] as [AnyObject], tintColor: UIColor.white, delegate: self)
        tabSwipe?.addShadow()
        tabSwipe?.setNormalColor(Theme.TabNormalColor)
        tabSwipe?.colorIndicator = Theme.PrimaryColorDark
        tabSwipe?.setSelectedColor(Theme.TabSelectedColor)
        
        transparentNavigationBar(true)
    }

    
    func tabSwipeNavigation(_ tabSwipe: CarbonTabSwipeNavigation!, viewControllerAt index: UInt) -> UIViewController! {
        if (index == 0) { // Shop
            return listItemVC
        } else if (index == 1) { // Review
            return shopReviewVC
        } else if (index == 2) { // Badge
            return shopBadgeVC
        }
        
        // Default
        let v = UIViewController()
        v.view.backgroundColor = UIColor.white
        return v
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
        
    }
    
    // MARK: - button
    @IBAction func shopAvatarButtonPressed(_ sender: Any) {
    }
    
    
    // MARK: - navbar styler
    func transparentNavigationBar(_ isActive: Bool) {
        if isActive {
            UIView.animate(withDuration: 0.5) {
                // Transparent navigation bar
                self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                self.navigationController?.navigationBar.shadowImage = UIImage()
                self.navigationController?.navigationBar.isTranslucent = true
//                
//                self.navigationController?.navigationBar.height = 194
                
                self.navigationController?.navigationBar.layoutIfNeeded()
            }
            
        } else {
            UIView.animate(withDuration: 0.5) {
                self.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
                self.navigationController?.navigationBar.shadowImage = nil
                //                self.navigationController?.navigationBar.tintColor = nil
                self.navigationController?.navigationBar.isTranslucent = true
                
                // default prelo
                //                UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
                UINavigationBar.appearance().barTintColor = Theme.PrimaryColor
                //                self.navigationController?.navigationBar.tintColor = UIColor.white
                
                self.navigationController?.navigationBar.layoutIfNeeded()
            }
        }
    }

}
