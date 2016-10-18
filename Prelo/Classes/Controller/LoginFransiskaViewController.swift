//
//  LoginFransiskaViewController.swift
//  Prelo
//
//  Created by PreloBook on 9/26/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class

class LoginFransiskaViewController: BaseViewController, CarbonTabSwipeDelegate {
    
    // MARK: - Properties
    
    @IBOutlet var loadingPanel: UIView!
    
    var tabSwipe : CarbonTabSwipeNavigation?
    var loginVC : LoginViewController!
    var registerVC : RegisterViewController!
    
    var screenBeforeLogin : String = ""
    var isFromTourVC : Bool = false
    
    // MARK: - Init
    
    override func viewDidLoad() {
        
        // Setup close button
        self.navigationItem.hidesBackButton = true
        let btnClose = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(LoginFransiskaViewController.dismissLogin))
        btnClose.setTitleTextAttributes([NSFontAttributeName : UIFont(name: "Prelo2", size: 15)!], for: UIControlState())
        self.navigationItem.rightBarButtonItem = btnClose
        
        // Setup loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.hideLoading()
    }
    
    func dismissLogin() {
        loginVC.userRelatedDelegate?.userCancelLogin?()
        registerVC.userRelatedDelegate?.userCancelLogin?()
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupTabSwipe() {
        // Set view controllers
        loginVC = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdLogin) as! LoginViewController
        loginVC.screenBeforeLogin = screenBeforeLogin
        loginVC.isFromTourVC = isFromTourVC
        loginVC.userRelatedDelegate = userRelatedDelegate
        loginVC.loginTabSwipeVC = self
        registerVC = Bundle.main.loadNibNamed(Tags.XibNameRegister, owner: nil, options: nil)?.first as! RegisterViewController
        registerVC.screenBeforeLogin = screenBeforeLogin
        registerVC.userRelatedDelegate = userRelatedDelegate
        registerVC.loginTabSwipeVC = self
        
        tabSwipe = CarbonTabSwipeNavigation().create(withRootViewController: self, tabNames: ["LOG IN" as AnyObject, "DAFTAR" as AnyObject] as [AnyObject], tintColor: UIColor.clear, delegate: self)
        tabSwipe?.addShadow()
        tabSwipe?.setNormalColor(UIColor(hexString: "#f5f5f5"))
        tabSwipe?.colorIndicator = UIColor.white
        tabSwipe?.setSelectedColor(UIColor.white)
        
        // Set loadingPanel to front
        self.view.bringSubview(toFront: loadingPanel)
    }
    
    // MARK: - Tab swipe functions
    
    func tabSwipeNavigation(_ tabSwipe: CarbonTabSwipeNavigation!, viewControllerAt index: UInt) -> UIViewController! {
        if (index == 0) {
            return loginVC
        } else if (index == 1) {
            return registerVC
        }
        return UIViewController()
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
}
