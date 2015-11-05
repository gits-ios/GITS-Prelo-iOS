 //
//  AddProductShareViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class AddProductShareViewController: BaseViewController, PathLoginDelegate, InstagramLoginDelegate {
    
    @IBOutlet var arrayRow1 : [AddProductShareButton] = []
    @IBOutlet var arrayRow2 : [AddProductShareButton] = []
    @IBOutlet var arrayRow3 : [AddProductShareButton] = []
    @IBOutlet var arrayRow4 : [AddProductShareButton] = []
    
    var percentages = [3, 3, 2.5, 1.5]
    
    var arrayRows : [[AddProductShareButton]] = []
    
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var captionCharge : UILabel!
    @IBOutlet var captionChargePercent : UILabel!
    @IBOutlet var btnSend : UIButton!
    
    var chargePercent : Double = 10
    var basePrice = 925000
    
    var productID = ""
    var me = CDUser.getOne()
    
    var pathSender : AddProductShareButton?
    @IBAction func setSelectShare(sender : AddProductShareButton)
    {
        btnSend.setTitle("Loading..", forState: UIControlState.Disabled)
        let tag = sender.tag
        let arr = arrayRows[tag]
        let c = sender.active ? sender.normalColor : sender.selectedColor
        sender.active = !sender.active
        pathSender = sender
        for b in arr
        {
            b.setTitleColor(c, forState: UIControlState.Normal)
            b.active = sender.active
            
            if (b.titleLabel?.text == "") { // unchek, check it!
                b.setTitle("", forState: UIControlState.Normal)
                
                if (tag == 1 && CDUser.pathTokenAvailable() == false)
                {
                    let pathLoginVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePathLogin, owner: nil, options: nil).first as! PathLoginViewController
                    pathLoginVC.delegate = self
                    self.navigationController?.pushViewController(pathLoginVC, animated: true)
                }
                
                let o = me?.others
                
                let fbt = o?.fbAccessToken!
                var fbtoken = ""
                if let t = fbt
                {
                    fbtoken = t
                }
                if (tag == 2 &&  fbtoken == "")
                {
                    loginFacebook()
                }
                
                if (tag == 0)
                {
                    let ins = InstagramLoginViewController()
                    self.navigationController?.pushViewController(ins, animated: true)
                }
                
            } else if (b.titleLabel?.text == "") // checked, uncheck it
            {
                b.setTitle("", forState: UIControlState.Normal)
            }
        }
        
        let p = percentages[tag]
        chargePercent = chargePercent + (p * (sender.active ? -1 : 1))
        adaptCharge()
    }
    
    func instagramLoginFailed() {
        
    }
    
    func instagramLoginSuccess(token: String) {
        request(APISocial.StoreInstagramToken(token: token)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                
            } else
            {
                self.select(self.pathSender!)
            }
        }
    }
    
    func loginFacebook() {
        // Log in and get permission from facebook
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logInWithReadPermissions(["public_profile", "email"], handler: {(result : FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
            if (error != nil) { // Process error
                println("Process error")
                User.LogoutFacebook()
            } else if result.isCancelled { // User cancellation
                println("User cancel")
                User.LogoutFacebook()
            } else { // Success
                if result.grantedPermissions.contains("email") && result.grantedPermissions.contains("public_profile") {
                    // Do work
                    self.fbLogin()
                } else {
                    // Handle not getting permission
                }
            }
        })
    }
    
    func fbLogin()
    {
        // Show loading
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email, name"], tokenString: FBSDKAccessToken.currentAccessToken().tokenString, version: nil, HTTPMethod: "GET")
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                
                if ((error) != nil) {
                    // Handle error
                    println("Error fetching facebook profile")
                } else {
                    // Handle Profile Photo URL String
                    let userId =  result["id"] as! String
                    let name = result["name"] as! String
                    let email = result["email"] as! String
                    let profilePictureUrl = "https://graph.facebook.com/\(userId)/picture?type=large" // FIXME: harusnya dipasang di profile kan?
                    let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                    
                    request(APIAuth.LoginFacebook(email: email, fullname: name, fbId: userId, fbAccessToken: accessToken)).responseJSON {req, _, res, err in
                        println("Fb login req = \(req)")
                        if (err != nil) { // Terdapat error
                            println("")
                        } else {
                            self.me?.others.fbAccessToken = accessToken
                            UIApplication.appDelegate.saveContext()
                        }
                    }
                }
            })
        }
    }

    
    func pathLoginSuccess(userData : JSON, token : String) {
        let pathId = userData["id"].string!
        let pathName = userData["name"].string!
        let email = userData["email"].string!
        //let profilePictureUrl = userData["photo"]["medium"]["url"].string! // FIXME: harusnya dipasang di profile kan?
        
        request(APIAuth.LoginPath(email: email, fullname: pathName, pathId: pathId, pathAccessToken: token)).responseJSON {req, _, res, err in
            println("Path login req = \(req)")
            
            if (err != nil) { // Terdapat error
//                if let m = err?.description
//                {
//                    
//                }
//                Constant.showDialog("Warning", message: (err?.description)!)
                self.setSelectShare(self.pathSender!)
            } else {
                NSUserDefaults.standardUserDefaults().setObject(token, forKey: "pathtoken")
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }
    
    func hideLoading() {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Share"

        // Do any additional setup after loading the view.
        
        if (arrayRows.count == 0)
        {
            arrayRows.append(arrayRow1)
            arrayRows.append(arrayRow2)
            arrayRows.append(arrayRow3)
            arrayRows.append(arrayRow4)
        }
        
        adaptCharge()
        
        self.title = "Kesempatan Terbatas"
    }
    
    var first = true
    
    var shouldSkipBack = true
    
    override func viewDidAppear(animated: Bool) {
        if first && shouldSkipBack
        {
            first = false
            super.viewDidAppear(animated)
            var m = self.navigationController?.viewControllers
            m?.removeAtIndex((m?.count)!-2)
            self.navigationController?.viewControllers = m!
        }
    }
    
    func adaptCharge()
    {
        captionChargePercent.text = Double(100 - chargePercent).roundString + " %"
        if (captionChargePercent.text == "0 %")
        {
            captionChargePercent.text = "FREE!"
        }
        let charge = Double(basePrice) * chargePercent / 100
        var string = "Charge Prelo : " + Int(charge).asPrice + " (" + chargePercent.roundString + "%)"
        if (chargePercent == 0)
        {
            string = "Charge Prelo : FREE"
        }
        var attString = NSMutableAttributedString(string: string)
        attString.addAttributes([NSForegroundColorAttributeName:UIColor.redColor()], range: AppToolsObjC.rangeOf(chargePercent.roundString+"%", inside: string))
        attString.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColorLight], range: AppToolsObjC.rangeOf("FREE", inside: string))
        captionCharge.attributedText = attString
        captionPrice.text = (basePrice - Int(charge)).asPrice
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func shareDone()
    {
        btnSend.enabled = false
        var i = "0", p = "0", f = "0", t = "0"
        
        for x in 0...3
        {
            let arr = arrayRows[x]
            for b in arr
            {
                if (b.titleLabel?.text == "")
                {
                    if (x == 0)
                    {
                        i = "1"
                    }
                    
                    if (x == 1)
                    {
                        p = "1"
                    }
                    
                    if (x == 2)
                    {
                        f = "1"
                    }
                    
                    if (x == 3)
                    {
                        t = "1"
                    }
                }
            }
        }
        
        request(Products.ShareCommission(pId: productID, instagram: i, path: p, facebook: f, twitter: t))
            .responseJSON { req, resp, res, err in
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
                    let b = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdMyProducts) as! UIViewController
                    self.navigationController?.pushViewController(b, animated: true)
                } else
                {
                    self.btnSend.enabled = true
                }
        }
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

extension Double
{
    var roundString : String
    {
        if (self - Double(Int(self)) == 0) {
            return String(Int(self))
        } else
        {
            return String(stringInterpolationSegment: self)
        }
    }
}
