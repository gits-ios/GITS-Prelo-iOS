//
//  InstagramLoginViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/26/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Alamofire

protocol InstagramLoginDelegate
{
    func instagramLoginSuccess(_ token : String)
    func instagramLoginSuccess(_ token : String, id : String, name : String)
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
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[w]-0-|", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: ["w":webView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[w]-0-|", options: NSLayoutFormatOptions.alignAllLastBaseline, metrics: nil, views: ["w":webView]))
        
        webView.delegate = self
        webView.loadRequest(Foundation.URLRequest(url: URL(string: "https://api.instagram.com/oauth/authorize/?client_id="+clientID+"&redirect_uri="+"http://"+urlCallback+"&response_type=code")!))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Batal", style: UIBarButtonItemStyle.plain, target: self, action: #selector(InstagramLoginViewController.batal))
    }
    
    func batal()
    {
        webView.stopLoading()
        self.instagramLoginDelegate?.instagramLoginFailed()
        self.dismiss()
    }
    
    func dismiss()
    {
        if let n = self.navigationController
        {
            n.popViewController(animated: true)
        } else
        {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if let s = request.url?.host
        {
            let ns = s as NSString
            if (ns.range(of: "prelo").location != NSNotFound)
            {
                let string = request.url?.absoluteString
                let token = string?.components(separatedBy: "=").last
//                ns = (request.URL?.absoluteString)!
//                ns = ns.componentsSeparatedByString("=").last!
                getToken(token == nil ? "" : token!)
                return false
            }
        }
        
        return true
    }
    
    func getToken(_ code : String)
    {
        request("https://api.instagram.com/oauth/access_token", method: .post, parameters: ["client_id":clientID, "client_secret":clientSecret, "grant_type":"authorization_code", "code":code, "redirect_uri":"http://"+urlCallback]).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Login Instagram"))
            {
                let json = JSON(resp.result.value!)
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
