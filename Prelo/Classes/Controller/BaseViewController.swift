//
//  BaseViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

enum AppFont
{
    case prelo2
    case preloAwesome
    
    func getFont(_ size : CGFloat) -> UIFont?
    {
        var name = "Prelo2"
        switch self
        {
        case .prelo2:name = "Prelo2"
        case .preloAwesome:name = "PreloAwesome"
        }
        
        let f = UIFont(name: name, size: size)
        return f
    }
    
    var getFont : UIFont?
    {
        var name = "Prelo2"
        switch self
        {
        case .prelo2:name = "Prelo2"
        case .preloAwesome:name = "PreloAwesome"
        }
        
        let f = UIFont(name: name, size: 18)
        return f
    }
}

@objc protocol UserRelatedDelegate
{
    @objc optional func userLoggedIn()
    @objc optional func userLoggedOut()
    @objc optional func userCancelLogin()
}

class BaseViewController: UIViewController, PreloNotifListenerDelegate {

    var userRelatedDelegate : UserRelatedDelegate?
    
    var previousController : UIViewController?
    
    fileprivate static var GlobalStoryboard : UIStoryboard?
    
    var badgeView : GIBadgeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if (BaseViewController.GlobalStoryboard == nil) {
            BaseViewController.GlobalStoryboard = self.storyboard
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
        
        // Remove redirect alert if any
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let redirAlert = appDelegate.redirAlert {
            redirAlert.dismiss(withClickedButtonIndex: -1, animated: true)
        }
    }
    
    func backPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    static func instatiateViewControllerFromStoryboardWithID(_ id : String) -> UIViewController
    {
        let c = (BaseViewController.GlobalStoryboard?.instantiateViewController(withIdentifier: id))!
        return c
    }
    
    static func TitleLabel(_ title : String) -> UILabel
    {
        let l = UILabel(frame: CGRect.zero)
        l.font = UIFont.systemFont(ofSize: 16)
        l.textColor = UIColor.white
        l.text = title
        l.sizeToFit()
        l.backgroundColor = UIColor.clear
        return l
    }
    
    fileprivate var _titleText : String?
    var titleText : String?
    {
        get
        {
            return _titleText
        }
        set(newValue)
        {
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
    
    var dismissButton : UIButton
    {
        let b = self.createButtonWithIcon(AppFont.prelo2, icon: "")
        b.addTarget(self, action: #selector(BaseViewController.dismissBase), for: UIControlEvents.touchUpInside)
        return b
    }
    
    var confirmButton : UIButton
    {
        let b = self.createButtonWithIcon(AppFont.prelo2, icon: "")
        b.addTarget(self, action: #selector(BaseViewController.confirm), for: UIControlEvents.touchUpInside)
        return b
    }
    
    func dismissBase()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    func confirm()
    {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupNormalOptions()
    {
        // Get the number of new notifications
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let notifListener = delegate.preloNotifListener
        notifListener?.delegate = self
        if (User.IsLoggedIn) {
            notifListener?.setupSocket()
        }
        let newNotifCount = notifListener?.newNotifCount
        
        // Set top right bar buttons
        let search = createSearchButton()
        let bell = createBellButton(newNotifCount!)
        let troli = createTroliButton()
        
        troli.addTarget(self, action: #selector(BaseViewController.launchCart), for: UIControlEvents.touchUpInside)
        
        bell.addTarget(self, action: #selector(BaseViewController.launchNotifPage), for: UIControlEvents.touchUpInside)
        
        search.addTarget(self, action: #selector(BaseViewController.launchSearch), for: UIControlEvents.touchUpInside)
        
        self.navigationItem.rightBarButtonItems = [troli.toBarButton(), bell.toBarButton(), search.toBarButton()]
    }
    
    func launchCart()
    {
        let cart = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdCart) as! BaseViewController
        cart.previousController = self
        self.navigationController?.pushViewController(cart, animated: true)
    }
    
    func launchSearch()
    {
        let searchVC : SearchViewController = (self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdSearch))! as! SearchViewController
        if let ktbVC = self as? KumangTabBarViewController {
            if let lcVC = ktbVC.controllerBrowse as? ListCategoryViewController {
                searchVC.currentCategoryId = lcVC.currentCategoryId
            }
        }
        self.navigationController?.pushViewController(searchVC, animated: true)
    }
    
    func launchNotifPage()
    {
        let notifPageVC = Bundle.main.loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil)?.first as! NotifAnggiTabBarViewController
        self.navigationController?.pushViewController(notifPageVC, animated: true)
    }
    
    func setupTitle()
    {
//        let l = UILabel(frame: CGRectZero)
//        l.text = "Prelo"
//        l.textColor = UIColor.whiteColor()
//        l.sizeToFit()
//        
//        let iv = UIImageView(image: UIImage(named: "ic_logo_white"))
//        iv.frame = CGRectMake(0, 0, l.height+4, l.height+4)
//        
//        l.x = l.height + 4 + 8
//        l.y = ((l.height+4)-l.height)/2
//        
//        let v = UIView(frame: CGRectMake(0, 0, l.x+l.width, l.height+4))
//        v.addSubview(iv)
//        v.addSubview(l)
        let i = TintedImageView(frame: CGRect(x: 0, y: 0, width: 92, height: 92), backgroundColor: UIColor.clear)
        i.image = UIImage(named : "ic_prelo_logo_text_white")
        i.contentMode = UIViewContentMode.scaleAspectFit
        
        self.navigationItem.leftBarButtonItem = i.toBarButton()
    }
    
    func createButtonWithIcon(_ appFont : AppFont, icon : String) ->UIButton
    {
        let b = UIButton(type: .custom)
        var name = "Prelo2"
        switch appFont
        {
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
        switch appFont
        {
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
            badge.topOffset = 9
            badge.rightOffset = 5
            b.addSubview(badge)
        }
        return b
    }
        
    func createSearchButton()->UIButton
    {
        return createButtonWithIcon(UIImage(named: "ic_search_filter.png")!)
    }
    
    func createBellButton(_ num : Int)->UIButton
    {
        return createButtonWithIconAndNumber(UIImage(named: "ic_notif.png")!, num: num)
    }
    
    func createTroliButton()->UIButton
    {
        return createButtonWithIcon(UIImage(named: "ic_cart.png")!)
    }
    
    // MARK: - PreloNotifListenerDelegate function
    
    func showNewNotifCount(_ count: Int) {
        print("showNewNotifCount: \(count)")
        setupNormalOptions()
    }
    
    func refreshNotifPage() {
        // Do nothing, handled by NotificationPageVC itself
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

class AppButton : UIButton
{
    @IBInspectable var stringTag : String = ""
}

class AppUITextfield : UITextField
{
    @IBOutlet var nextTextfield : UITextField?
}

extension UINavigationController
{
    class func defaultNavigation(_ root : UIViewController)->UINavigationController
    {
        let n = UINavigationController(rootViewController: root)
        n.navigationBar.barTintColor = Theme.navBarColor
        n.navigationBar.tintColor = UIColor.white
        return n
    }
}

extension UIView
{
    func toBarButton()->UIBarButtonItem
    {
        return UIBarButtonItem(customView: self)
    }
}
