//
//  LoginViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/30/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CoreData
//import UIViewController_KeyboardAnimation

class LoginViewController: BaseViewController, UIGestureRecognizerDelegate, UITextFieldDelegate, UIScrollViewDelegate {

    @IBOutlet var scrollView : UIScrollView?
    @IBOutlet var txtEmail : UITextField?
    @IBOutlet var txtPassword : UITextField?
    
    @IBOutlet var btnLogin : UIButton?
    
    var navController : UINavigationController?
    
    static func Show(parent : UIViewController, userRelatedDelegate : UserRelatedDelegate?, animated : Bool)
    {
        let l = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdLogin) as! LoginViewController
        l.userRelatedDelegate = userRelatedDelegate
        
        let n = BaseNavigationController(rootViewController : l)
        n.setNavigationBarHidden(true, animated: false)
        
        parent.presentViewController(n, animated: animated, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)

        scrollView?.delegate = self
        
        scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().track("Login Page")
        
        self.an_subscribeKeyboardWithAnimations(
            {r, t, o in
                
                if (o) {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64+r.height, 0)
                } else {
                    self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
                }
                
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    @IBAction func viewTapped(sender : AnyObject)
    {
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
    }
    
    @IBAction func signUpTapped(sender : AnyObject)
    {
        let registerVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameRegister, owner: nil, options: nil).first as! RegisterViewController
        registerVC.userRelatedDelegate = self.userRelatedDelegate
        self.navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @IBAction func login(sender : AnyObject)
    {
        btnLogin?.enabled = false
        sendLogin()
    }
    
    func sendLogin()
    {
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
        
        btnLogin?.enabled = false
        
        let email = txtEmail?.text
        request(APIAuth.Login(email: email!, password: (txtPassword?.text)!))
            .responseJSON
            {_, _, json, err in
                if (err != nil) {
                    Constant.showDialog("Warning", message: (err?.description)!)
                    self.btnLogin?.enabled = true
                } else {
                    let res = JSON(json!)
                    let data = res["_data"]
                    if (data == nil) {
                        let obj : [String : String] = json as! [String : String]
                        let message = obj["_message"]
                        Constant.showDialog("Warning", message: message!)
                        self.btnLogin?.enabled = true
                    } else {
                        println(data)
                        User.StoreUser(data, email: email!)
                        self.getProfile()
                    }
                }
        }
    }
    
    func getProfile()
    {
        request(APIUser.Me)
            .responseJSON{_, resp, res, err in
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
                    self.btnLogin?.enabled = true
                    let json = JSON(res!)["_data"]
                    
                    println(json)
                    
                    let m = UIApplication.appDelegate.managedObjectContext
                    let c = NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser
                    c.id = json["_id"].string!
                    c.email = json["email"].string!
                    c.fullname = json["fullname"].string!
                    
                    let p = NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile
                    let pr = json["profiles"]
                    if let address = pr["address"].string
                    {
                        p.address = address
                    } else {
                        p.address = ""
                    }
                    if let desc = pr["description"].string
                    {
                        p.desc = desc
                    } else {
                        p.desc = ""
                    }
                    if let phone = pr["phone"].string
                    {
                        p.phone = phone
                    } else {
                        p.phone = ""
                    }
                    if let pict = pr["pict"].string
                    {
                        p.pict = pict
                    } else {
                        p.pict = ""
                    }
                    if let postal = pr["postal_code"].string
                    {
                        p.postalCode = postal
                    } else
                    {
                        p.postalCode = ""
                    }
                    if let region = pr["region_id"].string
                    {
                        p.regionID = region
                    } else
                    {
                        p.regionID = ""
                    }
                    if let province = pr["province_id"].string
                    {
                        p.provinceID = province
                    } else
                    {
                        p.provinceID = ""
                    }
                    
                    c.profiles = p
                    UIApplication.appDelegate.saveContext()
                    
                    CartProduct.registerAllAnonymousProductToEmail(User.EmailOrEmptyString)
                    NSNotificationCenter.defaultCenter().postNotificationName("userLoggedIn", object: nil)
                    if (self.userRelatedDelegate != nil) {
                        self.userRelatedDelegate?.userLoggedIn!()
                    }
                    
//                    Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                    
                    if let c = CDUser.getOne()
                    {
                        Mixpanel.sharedInstance().identify(c.id)
                        Mixpanel.sharedInstance().people.set(["$first_name":c.fullname, "$name":c.email, "user_id":c.id])
                    } else {
                        Mixpanel.sharedInstance().identify(Mixpanel.sharedInstance().distinctId)
                        Mixpanel.sharedInstance().people.set(["$first_name":"", "$name":"", "user_id":""])
                    }
                    
                    Mixpanel.sharedInstance().track("Logged In")
                    
                    self.dismiss()
                } else {
                    User.Logout()
                    self.btnLogin?.enabled = true
                }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UIButton.classForCoder()) || touch.view.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == txtEmail) {
            txtPassword?.becomeFirstResponder()
        } else {
            sendLogin()
        }
        
        return false
    }
    
    @IBAction func dismissLogin()
    {
        if (self.userRelatedDelegate != nil)
        {
            self.userRelatedDelegate?.userCancelLogin!()
        }
        self.dismiss()
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
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
