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

class LoginViewController: BaseViewController, UIGestureRecognizerDelegate, UITextFieldDelegate {

    @IBOutlet var scrollView : UIScrollView?
    @IBOutlet var txtEmail : UITextField?
    @IBOutlet var txtPassword : UITextField?
    
    @IBOutlet var btnLogin : UIButton?
    
    var navController : UINavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
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
    }
    
    @IBAction func viewTapped(sender : AnyObject)
    {
        txtEmail?.resignFirstResponder()
        txtPassword?.resignFirstResponder()
    }
    
    @IBAction func signUpTapped(sender : AnyObject)
    {
        let registerVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameRegister, owner: nil, options: nil).first as! RegisterViewController
        navController?.pushViewController(registerVC, animated: true)
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
        request(APIUser.Login(email: email!, password: (txtPassword?.text)!))
            .responseJSON
            {_, _, json, err in
                self.btnLogin?.enabled = true
                if (err != nil) {
                    Constant.showDialog("Warning", message: (err?.description)!)
                } else {
                    let res = JSON(json!)
                    let data = res["_data"]
                    if (data == nil) {
                        let obj : [String : String] = json as! [String : String]
                        let message = obj["_message"]
                        Constant.showDialog("Warning", message: message!)
                    } else {
                        User.StoreUser(data, email: email!)
                        self.getProfile()
                    }
                }
        }
    }
    
    func getProfile()
    {
        request(APIUser.Me)
            .responseJSON{_, _, res, err in
        
                if (err != nil) {
                    Constant.showDialog("Warning", message: (err?.description)!)
                    User.Logout()
                } else {
                    let json = JSON(res!)["_data"]
                    
                    let m = UIApplication.appDelegate.managedObjectContext
                    let c = NSEntityDescription.insertNewObjectForEntityForName("CDUser", inManagedObjectContext: m!) as! CDUser
                    c.id = json["_id"].string!
                    c.email = json["email"].string!
                    c.fullname = json["fullname"].string!
                    
                    let p = NSEntityDescription.insertNewObjectForEntityForName("CDUserProfile", inManagedObjectContext: m!) as! CDUserProfile
                    let pr = json["profiles"]
                    p.address = pr["address"].string!
                    p.desc = pr["description"].string!
                    p.phone = pr["phone"].string!
                    p.pict = pr["pict"].string!
                    p.postalCode = pr["postal_code"].string!
                    p.regionID = pr["region_id"].string!
                    p.provinceID = pr["province_id"].string!
                    
                    c.profiles = p
                    UIApplication.appDelegate.saveContext()
                    
                    CartProduct.registerAllAnonymousProductToEmail(User.EmailOrEmptyString)
                    if (self.userRelatedDelegate != nil) {
                        self.userRelatedDelegate?.userLoggedIn!()
                    }
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
