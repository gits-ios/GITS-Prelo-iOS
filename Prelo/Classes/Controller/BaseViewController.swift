//
//  BaseViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/27/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import AlamofireImage

// MARK: - Protocol

@objc protocol UserRelatedDelegate {
    @objc optional func userLoggedIn()
    @objc optional func userLoggedOut()
    @objc optional func userCancelLogin()
}

// MARK: - Class

class BaseViewController: UIViewController, PreloNotifListenerDelegate {
    
    // MARK: - Static var and func
    
    fileprivate static var globalStoryboard : UIStoryboard?
    
    static func instatiateViewControllerFromStoryboardWithID(_ id : String) -> UIViewController {
        let c = (BaseViewController.globalStoryboard?.instantiateViewController(withIdentifier: id))!
        return c
    }
    
    static func formattedTitleLabel(_ title : String) -> UILabel {
        let l = UILabel(frame: CGRect.zero)
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = UIColor.white
        l.text = title
        l.sizeToFit()
        l.backgroundColor = UIColor.clear
        return l
    }
    
    // MARK: - Properties

    var userRelatedDelegate : UserRelatedDelegate?
    var previousController : UIViewController?
    var previousScreen : String! = ""
    var badgeView : GIBadgeView!
    fileprivate var _titleText : String?
    var titleText : String? {
        get {
            return _titleText
        }
        set(newValue) {
            let l = UILabel(frame: CGRect.zero)
            l.font = UIFont.systemFont(ofSize: 16)
            l.textColor = UIColor.white
            l.text = newValue
            l.sizeToFit()
            l.backgroundColor = UIColor.clear
            self.navigationItem.titleView = l
            _titleText = newValue
        }
    }
    var dismissButton : UIButton {
        let b = self.createButtonWithIcon(AppFont.prelo2, icon: "")
        b.addTarget(self, action: #selector(BaseViewController.dismissMe), for: UIControlEvents.touchUpInside)
        return b
    }
    var confirmButton : UIButton {
        let b = self.createButtonWithIcon(AppFont.prelo2, icon: "")
        b.addTarget(self, action: #selector(BaseViewController.confirm), for: UIControlEvents.touchUpInside)
        return b
    }
    var isStatusBarHidden : Bool = false
    var statusBarStyle : UIStatusBarStyle = .default
    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if (BaseViewController.globalStoryboard == nil) {
            BaseViewController.globalStoryboard = self.storyboard
        }
        
        // Tombol back
        let dType = "\(type(of: self))"
        if ((dType != "KumangTabBarViewController") && (dType != "ListCategoryViewController")) {
            self.navigationItem.hidesBackButton = true
            let newBackButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: self, action: #selector(BaseViewController.backPressed(_:)))
            newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], for: UIControlState())
            self.navigationItem.leftBarButtonItem = newBackButton
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !Reachability.isConnectedToNetwork() {
            Constant.showDisconnectBanner()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        AutoPurgingImageCache().removeAllImages()
    }
    
    func backPressed(_ sender: UIBarButtonItem) {
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func dismissMe() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupNormalOptions() {
        // Get the number of new notifications
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = delegate.preloNotifListener
        notifListener?.delegate = self
        if (User.IsLoggedIn) {
            notifListener?.setupSocket()
        }
        let newNotifCount = notifListener?.newNotifCount
        
        let cartCount = notifListener?.cartCount
        
        // Set top right bar buttons
        let search = createSearchButton()
        let bell = createBellButton(newNotifCount!)
        let troli = createTroliButton(cartCount!)
        
        troli.addTarget(self, action: #selector(BaseViewController.launchCart), for: UIControlEvents.touchUpInside)
        
        let troliRecognizer = UITapGestureRecognizer(target: self, action: #selector(BaseViewController.launchCart))
        troli.viewWithTag(100)?.addGestureRecognizer(troliRecognizer)
        
        bell.addTarget(self, action: #selector(BaseViewController.launchNotifPage), for: UIControlEvents.touchUpInside)
        
        let bellRecognizer = UITapGestureRecognizer(target: self, action: #selector(BaseViewController.launchNotifPage))
        bell.viewWithTag(100)?.addGestureRecognizer(bellRecognizer)
        
        search.addTarget(self, action: #selector(BaseViewController.launchSearch), for: UIControlEvents.touchUpInside)
        
        self.navigationItem.rightBarButtonItems = [troli.toBarButton(), bell.toBarButton(), search.toBarButton()]
        
        // badge notif update
        UIApplication.shared.applicationIconBadgeNumber = newNotifCount!
    }

    func setupTitle() {
        //let i = TintedImageView(frame: CGRect(x: 0, y: 0, width: 92, height: 92), backgroundColor: UIColor.clear)
        let i = TintedImageView(frame: CGRect(x: 0, y: 0, width: 92, height: 92))
        i.backgroundColor = UIColor.clear
        i.image = UIImage(named : "ic_prelo_logo_text_white")
        i.contentMode = UIViewContentMode.scaleAspectFit
        
        self.navigationItem.leftBarButtonItem = i.toBarButton()
    }
    
    // MARK: - Button creation
    
    func createButtonWithIcon(_ appFont : AppFont, icon : String) -> UIButton {
        let b = UIButton(type: .custom)
        var name = "Prelo2"
        switch appFont {
        case .prelo2:name = "Prelo2"
        case .preloAwesome:name = "PreloAwesome"
        }
        let f = UIFont(name: name, size: 21)
        b.titleLabel?.font = f
        b.setTitle(icon, for: UIControlState())
        b.frame = CGRect(x: 0, y: 0, width: 33, height: 46)
        return b
    }
    
    func createButtonWithIcon(_ img : UIImage) -> UIButton {
        let imgVw = UIImageView(frame: CGRect(x: 4, y: 4, width: 25, height: 38), image: img)
        imgVw.contentMode = UIViewContentMode.scaleAspectFit
        let b = UIButton(type: .custom)
        b.frame = CGRect(x: 0, y: 0, width: 33, height: 46)
        b.addSubview(imgVw)
        return b
    }
    
    func createButtonWithIconAndNumber(_ appFont : AppFont, icon : String, num : Int) -> UIButton {
        let b = UIButton(type: .custom)
        var name = "Prelo2"
        switch appFont {
        case .prelo2:name = "Prelo2"
        case .preloAwesome:name = "PreloAwesome"
        }
        let f = UIFont(name: name, size: 21)
        b.titleLabel?.font = f
        b.setTitle(icon, for: UIControlState())
        b.frame = CGRect(x: 0, y: 0, width: 33, height: 46)
        if (num > 0) {
            let badge = GIBadgeView()
            badge.badgeValue = num
            badge.backgroundColor = Theme.ThemeOrage
            badge.topOffset = 9
            badge.rightOffset = 5
            badge.tag = 100
            b.addSubview(badge)
        }
        return b
    }
    
    func createButtonWithIconAndNumber(_ img : UIImage, num : Int) -> UIButton {
        let imgVw = UIImageView(frame: CGRect(x: 4, y: 4, width: 25, height: 38), image: img)
        imgVw.contentMode = UIViewContentMode.scaleAspectFit
        let b = UIButton(type: .custom)
        b.frame = CGRect(x: 0, y: 0, width: 33, height: 46)
        b.addSubview(imgVw)
        if (num > 0) {
            let badge = GIBadgeView()
            badge.badgeValue = num
            badge.backgroundColor = Theme.ThemeOrage
            badge.topOffset = 14
            badge.rightOffset = 5
            badge.tag = 100
            b.addSubview(badge)
        }
        return b
    }
    
    func createSearchButton()->UIButton {
        return createButtonWithIcon(UIImage(named: "ic_search_filter.png")!)
    }
    
    func createBellButton(_ num : Int)->UIButton {
        return createButtonWithIconAndNumber(UIImage(named: "ic_notif.png")!, num: num)
    }
    
    func createTroliButton(_ num : Int)->UIButton {
        return createButtonWithIconAndNumber(UIImage(named: "ic_cart.png")!, num: num)
    }
    
    // MARK: - Navigation
    
    func launchCart() {
        if AppTools.isNewCart {
            let checkout2ShipVC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2Ship, owner: nil, options: nil)?.first as! Checkout2ShipViewController
            checkout2ShipVC.previousController = self
            checkout2ShipVC.previousScreen = PageName.Home
            self.navigationController?.pushViewController(checkout2ShipVC, animated: true)
        } else {
            let cart = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdCart) as! CartViewController
            cart.previousController = self
            cart.previousScreen = PageName.Home
            self.navigationController?.pushViewController(cart, animated: true)
        }
    }
    
    func launchSearch() {
        let searchVC : SearchViewController = (self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdSearch))! as! SearchViewController
        searchVC.previousScreen = PageName.Home
        if let ktbVC = self as? KumangTabBarViewController {
            if let lcVC = ktbVC.controllerBrowse as? ListCategoryViewController {
                searchVC.currentCategoryId = lcVC.currentCategoryId
            }
        }
        self.navigationController?.pushViewController(searchVC, animated: true)
    }
    
    func launchNotifPage() {
        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
        notifPageVC.previousScreen = PageName.Home
        self.navigationController?.pushViewController(notifPageVC, animated: true)
    }
    
    // MARK: - Overrideable func
    
    func confirm() {
        
    }
    
    // MARK: - PreloNotifListenerDelegate function
    
    func showNewNotifCount(_ count: Int) {
        //print("showNewNotifCount: \(count)")
        setupNormalOptions()
    }
    
    func refreshNotifPage() {
        // Do nothing, handled by NotificationPageVC itself
    }
    
    func showCartCount(_ count: Int) {
        //print("showCartCount: \(count)")
        setupNormalOptions()
    }
    
    func refreshCartPage() {
        // Do nothing, handled by NotificationPageVC itself
    }
    
    func increaseCartCount(_ value: Int) {
        //print("increaseCartCount: \(value)")
        setupNormalOptions()
    }
    
    // MARK: - Status bar
    
    func showStatusBar() {
        self.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func hideStatusBar() {
        self.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func setStatusBarStyle(style: UIStatusBarStyle) {
        self.statusBarStyle = style
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func setStatusBarBackgroundColor(color: UIColor) {
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        statusBar.backgroundColor = color
    }
}

class AppButton : UIButton {
    @IBInspectable var stringTag : String = ""
}

class AppUITextfield : UITextField {
    @IBOutlet var nextTextfield : UITextField?
}
