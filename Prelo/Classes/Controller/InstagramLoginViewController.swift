//
//  InstagramLoginViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/26/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

protocol InstagramLoginDelegate
{
    func instagramLoginSuccess(token : String)
    func instagramLoginSuccess(token : String, id : String, name : String)
    func instagramLoginFailed()
}

class InstagramLoginViewController: BaseViewController, UIWebViewDelegate
{
    @IBOutlet var webView : UIWebView!
    
    var urlCallback = "prelo.co.id/instagram/callback"
    var clientID = "cf1566e01d4143559694de1cfa63f8f3"
    var clientSecret = "e041efe11fc8486083c54dc09a0bd3f4"
    var grantType = "basic"

    var instagramLoginDelegate : InstagramLoginDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        webView = UIWebView(frame: self.view.bounds)
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(webView)
        
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[w]-0-|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: ["w":webView]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[w]-0-|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: nil, views: ["w":webView]))
        
        webView.delegate = self
        webView.loadRequest(NSURLRequest(URL: NSURL(string: "https://api.instagram.com/oauth/authorize/?client_id="+clientID+"&redirect_uri="+"http://"+urlCallback+"&response_type=code")!))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Batal", style: UIBarButtonItemStyle.Plain, target: self, action: "batal")
    }
    
    func batal()
    {
        webView.stopLoading()
        self.instagramLoginDelegate?.instagramLoginFailed()
        self.dismiss()
    }
    
    override func dismiss()
    {
        if let n = self.navigationController
        {
            n.popViewControllerAnimated(true)
        } else
        {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if let s = request.URL?.host
        {
            var ns = s as NSString
            if (ns.rangeOfString("prelo").location != NSNotFound)
            {
                ns = (request.URL?.absoluteString)!
                ns = ns.componentsSeparatedByString("=").last as! String
                getToken(ns as String)
                return false
            }
        }
        
        return true
    }
    
    func getToken(code : String)
    {
        request(.POST, "https://api.instagram.com/oauth/access_token", parameters: ["client_id":clientID, "client_secret":clientSecret, "grant_type":"authorization_code", "code":code, "redirect_uri":"http://"+urlCallback]).responseJSON { req, resp, res, err in
            
            let json = JSON(res!)
            if let token = json["access_token"].string
            {
                self.instagramLoginDelegate?.instagramLoginSuccess(token)
                
                let id = json["user"]["id"]
                let name = json["user"]["full_name"]
                if (id != nil && name != nil) {
                    self.instagramLoginDelegate?.instagramLoginSuccess(token, id: id.string!, name: name.string!)
                }
                
                self.dismiss()
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
