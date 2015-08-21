//
//  KumangTabBarViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class KumangTabBarViewController: BaseViewController, UserRelatedDelegate, MenuPopUpDelegate {
    
    var numberOfControllers : Int = 0
    
    @IBOutlet var sectionContent : UIView?
    @IBOutlet var segmentBar : UISegmentedControl?
    @IBOutlet var btnAdd : UIView?
    
    var menuPopUp : MenuPopUp?
    
    var changeToBrowseCount = 0
    
    var _controllerDashboard : BaseViewController?
    @IBOutlet var controllerDashboard : BaseViewController?
    {
        get {
            return _controllerDashboard
        }
        set(newController) {
            _controllerDashboard = newController
            _controllerDashboard?.userRelatedDelegate = self
        }
    }
    @IBOutlet var controllerDashboard2 : Dashboard2ViewController?
    @IBOutlet var controllerBrowse : UIViewController?
    @IBOutlet var controllerLogin : LoginViewController?
    @IBOutlet var controllerContactPrelo : BaseViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        let v = UIView()
        v.frame = CGRectMake(0, 0, 10, 10)
        v.backgroundColor = UIColor.clearColor()
        self.navigationItem.titleView = v
        
        self.setupNormalOptions()
        self.setupTitle()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "pushNew:", name: NotificationName.PushNew, object: nil)

        // Do any additional setup after loading the view.
        btnAdd?.layer.cornerRadius = (btnAdd?.frame.size.width)!/2
        btnAdd?.layer.shadowColor = UIColor.blackColor().CGColor
        btnAdd?.layer.shadowOffset = CGSize(width: 0, height: 5)
        btnAdd?.layer.shadowOpacity = 0.3
        
        controllerBrowse = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdBrowse) as? UIViewController
        changeToController(controllerBrowse!)
        
        controllerDashboard = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdDashboard) as? BaseViewController
        controllerDashboard2 = Dashboard2ViewController(nibName:Tags.XibNameDashboard2, bundle: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (menuPopUp == nil) {
            menuPopUp = NSBundle.mainBundle().loadNibNamed("MenuPopUp", owner: nil, options: nil).first as? MenuPopUp
            menuPopUp?.menuDelegate = self
            menuPopUp?.setupView(self.navigationController!)
        }
    }
    
    func pushNew(sender : AnyObject)
    {
        let n : NSNotification = sender as! NSNotification
        var d:ProductDetailViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
        var nav = UINavigationController(rootViewController: d)
        nav.navigationBar.translucent = false
        nav.navigationBar.barTintColor = Theme.navBarColor
        nav.navigationBar.tintColor = UIColor.whiteColor()
        d.product = n.object as? Product
        self.navigationController?.pushViewController(d, animated: true)
    }
    
    func changeToController(newController : UIViewController)
    {
        let oldView = sectionContent?.viewWithTag(1)
        oldView?.removeFromSuperview()
        
        var v : UIViewController? = newController
        v?.view.tag = 1
        v?.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        sectionContent?.addSubview((v?.view)!)
        let horizontalConstraint = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[v1]-0-|", options: .AlignAllTop, metrics: nil, views: ["v1": v!.view])
        let verticalConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[v1]-0-|", options: .AlignAllTop, metrics: nil, views: ["v1": v!.view])
        
        sectionContent?.addConstraints(horizontalConstraint)
        sectionContent?.addConstraints(verticalConstraint)
    }
    
    @IBAction func switchController(sender: AnyObject) {
        let btn : AppButton = sender as! AppButton
        if (btn.stringTag == Tags.Browse) {
            changeToController(controllerBrowse!)
            
            if (changeToBrowseCount == 0) {
                changeToBrowseCount = 1
                sectionContent?.hidden = true
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "delayBrowseSwitch", userInfo: nil, repeats: false)
            }
            
        } else {
            if (User.IsLoggedIn) {
                println("To Dashboard")
                controllerDashboard?.previousController = self
                changeToController(controllerDashboard!)
            } else {
                println("To Dashboard2")
                controllerDashboard2?.previousController = self
                changeToController(controllerDashboard2!)
            }
        }
    }
    
    @IBAction func launchMenu()
    {
//        menuPopUp?.show(true)
        
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct) as! AddProductViewController
        self.navigationController?.pushViewController(add, animated: true)
//        let i = UIImage(named: "raisa.jpg")
//        var editor = AdobeUXImageEditorViewController(image: i)
//        self.presentViewController(editor, animated: true, completion: nil)
    }
    
    func delayBrowseSwitch()
    {
        sectionContent?.hidden = false
        changeToController(controllerBrowse!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func userLoggedIn() {
        let d : BaseViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdDashboard) as! BaseViewController
        changeToController(d)
        controllerDashboard = d
    }
    
    func userLoggedOut() {
        let d : BaseViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdLogin) as! BaseViewController
        changeToController(d)
        controllerDashboard = d
    }
    
    func menuSelected(option: MenuOption) {
        menuPopUp?.hide()
        
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProductImage) as! AddProductImageSourceViewController
        self.navigationController?.pushViewController(add, animated: true)
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
