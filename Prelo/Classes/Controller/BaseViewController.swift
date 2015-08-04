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
}

class BaseViewController: UIViewController {

    var userRelatedDelegate : UserRelatedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupNormalOptions()
    {
        let search = createSearchButton()
        let bell = createBellButton()
        let troli = createTroliButton()
        
        self.navigationItem.rightBarButtonItems = [troli.toBarButton(), bell.toBarButton(), search.toBarButton()]
    }
    
    func setupTitle()
    {
        let l = UILabel(frame: CGRectZero)
        l.text = "Prelo"
        l.textColor = UIColor.whiteColor()
        l.sizeToFit()
        
        let iv = UIImageView(image: UIImage(named: "ic_logo_white"))
        iv.frame = CGRectMake(0, 0, l.height+4, l.height+4)
        
        l.x = l.height + 4 + 8
        l.y = ((l.height+4)-l.height)/2
        
        let v = UIView(frame: CGRectMake(0, 0, l.x+l.width, l.height+4))
        v.addSubview(iv)
        v.addSubview(l)
        
        self.navigationItem.leftBarButtonItem = v.toBarButton()
    }
    
    func createButtonWithIcon(appFont : AppFont, icon : String) ->UIButton
    {
        var b : UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var name = "Prelo2"
        switch appFont
        {
        case .Prelo2:name = "Prelo2"
        case .PreloAwesome:name = "PreloAwesome"
        }
        let f = UIFont(name: name, size: 18)
        b.titleLabel?.font = f
        b.setTitle(icon, forState: UIControlState.Normal)
        b.frame = CGRectMake(0, 0, 24, 36)
        return b
    }
    
    func createSearchButton()->UIButton
    {
        return createButtonWithIcon(AppFont.Prelo2, icon: "")
    }
    
    func createBellButton()->UIButton
    {
        return createButtonWithIcon(AppFont.Prelo2, icon: "")
    }
    
    func createTroliButton()->UIButton
    {
        return createButtonWithIcon(AppFont.Prelo2, icon: "")
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
