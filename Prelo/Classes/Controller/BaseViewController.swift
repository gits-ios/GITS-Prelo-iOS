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
    case Prelo2
    case PreloAwesome
    
    func getFont(size : CGFloat) -> UIFont?
    {
        var name = "Prelo2"
        switch self
        {
        case .Prelo2:name = "Prelo2"
        case .PreloAwesome:name = "PreloAwesome"
        }
        
        let f = UIFont(name: name, size: size)
        return f
    }
    
    var getFont : UIFont?
    {
        var name = "Prelo2"
        switch self
        {
        case .Prelo2:name = "Prelo2"
        case .PreloAwesome:name = "PreloAwesome"
        }
        
        let f = UIFont(name: name, size: 18)
        return f
    }
}

@objc protocol UserRelatedDelegate
{
    optional func userLoggedIn()
    optional func userLoggedOut()
    optional func userCancelLogin()
}

class BaseViewController: UIViewController, PreloNotifListenerDelegate {

    var userRelatedDelegate : UserRelatedDelegate?
    
    var previousController : UIViewController?
    
    private static var GlobalStoryboard : UIStoryboard?
    
    var badgeView : GIBadgeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if (BaseViewController.GlobalStoryboard == nil) {
            BaseViewController.GlobalStoryboard = self.storyboard
        }
        
        // Tombol back
        let dType = "\(self.dynamicType)"
        if ((dType != "KumangTabBarViewController") && (dType != "ListCategoryViewController")) {
            self.navigationItem.hidesBackButton = true
            let newBackButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(BaseViewController.backPressed(_:)))
            newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
            self.navigationItem.leftBarButtonItem = newBackButton
        }
    }
    
    func backPressed(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    static func instatiateViewControllerFromStoryboardWithID(id : String) -> UIViewController
    {
        let c = (BaseViewController.GlobalStoryboard?.instantiateViewControllerWithIdentifier(id))!
        return c
    }
    
    static func TitleLabel(title : String) -> UILabel
    {
        let l = UILabel(frame: CGRectZero)
        l.font = UIFont.systemFontOfSize(16)
        l.textColor = UIColor.whiteColor()
        l.text = title
        l.sizeToFit()
        l.backgroundColor = UIColor.clearColor()
        return l
    }
    
    private var _titleText : String?
    var titleText : String?
    {
        get
        {
            return _titleText
        }
        set(newValue)
        {
            let l = UILabel(frame: CGRectZero)
            l.font = UIFont.systemFontOfSize(16)
            l.textColor = UIColor.whiteColor()
            l.text = newValue
            l.sizeToFit()
            l.backgroundColor = UIColor.clearColor()
            self.navigationItem.titleView = l
            _titleText = newValue
        }
    }
    
    var dismissButton : UIButton
    {
        let b = self.createButtonWithIcon(AppFont.Prelo2, icon: "")
        b.addTarget(self, action: #selector(BaseViewController.dismiss), forControlEvents: UIControlEvents.TouchUpInside)
        return b
    }
    
    var confirmButton : UIButton
    {
        let b = self.createButtonWithIcon(AppFont.Prelo2, icon: "")
        b.addTarget(self, action: #selector(BaseViewController.confirm), forControlEvents: UIControlEvents.TouchUpInside)
        return b
    }
    
    func dismiss()
    {
        self.dismissViewControllerAnimated(true, completion: nil)
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
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let notifListener = delegate.preloNotifListener
        notifListener.delegate = self
        if (User.IsLoggedIn) {
            notifListener.setupSocket()
        }
        let newNotifCount = notifListener.newNotifCount
        
        // Set top right bar buttons
        let search = createSearchButton()
        let bell = createBellButton(newNotifCount)
        let troli = createTroliButton()
        
        troli.addTarget(self, action: #selector(BaseViewController.launchCart), forControlEvents: UIControlEvents.TouchUpInside)
        
        bell.addTarget(self, action: #selector(BaseViewController.launchNotifPage), forControlEvents: UIControlEvents.TouchUpInside)
        
        search.addTarget(self, action: #selector(BaseViewController.launchSearch), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.navigationItem.rightBarButtonItems = [troli.toBarButton(), bell.toBarButton(), search.toBarButton()]
    }
    
    func launchCart()
    {
        let cart = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdCart) as! BaseViewController
        cart.previousController = self
        self.navigationController?.pushViewController(cart, animated: true)
    }
    
    func launchSearch()
    {
        let search = (self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdSearch))!
        self.navigationController?.pushViewController(search, animated: true)
    }
    
    func launchNotifPage()
    {
        let notifPageVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameNotifAnggiTabBar, owner: nil, options: nil).first as! NotifAnggiTabBarViewController
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
        let i = TintedImageView(frame: CGRectMake(0, 0, 92, 92), backgroundColor: UIColor.clearColor())
        i.image = UIImage(named : "ic_prelo_logo_text")
        i.tintColor = UIColor.whiteColor()
        i.contentMode = UIViewContentMode.ScaleAspectFit
        i.tint = true
        
        self.navigationItem.leftBarButtonItem = i.toBarButton()
    }
    
    func createButtonWithIcon(appFont : AppFont, icon : String) ->UIButton
    {
        let b = UIButton(type: .Custom)
        var name = "Prelo2"
        switch appFont
        {
        case .Prelo2:name = "Prelo2"
        case .PreloAwesome:name = "PreloAwesome"
        }
        let f = UIFont(name: name, size: 21)
        b.titleLabel?.font = f
        b.setTitle(icon, forState: UIControlState.Normal)
        b.frame = CGRectMake(0, 0, 33, 46)
        return b
    }
    
    func createButtonWithIconAndNumber(appFont : AppFont, icon : String, num : Int) -> UIButton {
        let b = UIButton(type: .Custom)
        var name = "Prelo2"
        switch appFont
        {
        case .Prelo2:name = "Prelo2"
        case .PreloAwesome:name = "PreloAwesome"
        }
        let f = UIFont(name: name, size: 21)
        b.titleLabel?.font = f
        b.setTitle(icon, forState: UIControlState.Normal)
        b.frame = CGRectMake(0, 0, 33, 46)
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
    
    func createButtonWithIcon(img : UIImage) -> UIButton {
        let imgVw = UIImageView(frame: CGRectMake(4, 4, 25, 38), image: img)
        imgVw.contentMode = UIViewContentMode.ScaleAspectFit
        let b = UIButton(type: .Custom)
        b.frame = CGRectMake(0, 0, 33, 46)
        b.addSubview(imgVw)
        return b
    }
        
    func createSearchButton()->UIButton
    {
        return createButtonWithIcon(UIImage(named: "ic_search_filter.png")!)
    }
    
    func createBellButton(num : Int)->UIButton
    {
        return createButtonWithIconAndNumber(AppFont.Prelo2, icon: "", num: num)
    }
    
    func createTroliButton()->UIButton
    {
        return createButtonWithIcon(AppFont.Prelo2, icon: "")
    }
    
    // MARK: - PreloNotifListenerDelegate function
    
    func showNewNotifCount(count: Int) {
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
    class func defaultNavigation(root : UIViewController)->UINavigationController
    {
        let n = UINavigationController(rootViewController: root)
        n.navigationBar.barTintColor = Theme.navBarColor
        n.navigationBar.tintColor = UIColor.whiteColor()
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
