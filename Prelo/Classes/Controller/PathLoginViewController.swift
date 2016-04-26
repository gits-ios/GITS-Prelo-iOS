//
//  PathLoginViewController.swift
//  Prelo
//
//  Created by Fransiska on 10/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

protocol PathLoginDelegate {
    func pathLoginSuccess(userData : JSON, token : String)
    func hideLoading()
}

class PathLoginViewController : BaseViewController, UIWebViewDelegate {
    
    var delegate : PathLoginDelegate?
    
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var standAlone = false
    
    let pathClientId = "b0b1aca06485dadc5f9c04e799914107277a4a42"
    let pathClientSecret = "2f53945d5e9a94659dae8c982a47df24515cae79"
    let pathDeclineUrlString = "https://partner.path.com/oauth2/decline"
    let pathLoginSuccessUrlString = "https://prelo.co.id/path/callback"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PathLoginViewController.batal))
        
        let url = NSURL(string: "https://partner.path.com/oauth2/authenticate?response_type=code&client_id=\(pathClientId)")
        let requestObj = NSURLRequest(URL: url!)
        self.webView.loadRequest(requestObj)
        
        webView.delegate = self
        
        // Show loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = false
        loading.startAnimating()
    }
    
    func batal()
    {
        if (self.standAlone)
        {
            self.dismissViewControllerAnimated(true, completion: nil)
        } else
        {
            self.delegate?.hideLoading()
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        // Show loading
        loadingPanel.hidden = false
        loading.startAnimating()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        // Hide loading
        loadingPanel.hidden = true
        loading.stopAnimating()
        
        let currentURL = webView.request?.URL
        print("currentURL = \(currentURL)")
        
        if (currentURL?.absoluteString.lowercaseString.rangeOfString(pathDeclineUrlString) != nil) { // User canceled path login
            self.delegate?.hideLoading()
            // Back to prev scene
            if (self.standAlone)
            {
                self.dismissViewControllerAnimated(true, completion: nil)
            } else
            {
                self.navigationController?.popViewControllerAnimated(true)
            }
        } else if (currentURL?.absoluteString.lowercaseString.rangeOfString(pathLoginSuccessUrlString) != nil) { // User successfully login
            let codeParam : String = (currentURL?.query)!
            let code : String = codeParam.substringWithRange(codeParam.startIndex.advancedBy(5) ..< codeParam.endIndex)
            //print("code = \(code)")
            
            // Get token
            // API Migrasi
        request(APIPathAuth.GetToken(clientId: pathClientId, clientSecret: pathClientSecret, code: code)).responseJSON {resp in
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Login Path")) {
                    let json = JSON(resp.result.value!)
                    print("json = \(json)")
                    if (json["code"].int == 200) { // OK
                        _ = json["user_id"].string!
                        let pathToken : String = json["access_token"].string!
                        
                        // Get user Path data
                        // API Migrasi
        request(APIPathUser.GetSelfData(token: pathToken)).responseJSON {resp in
                            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Login Path")) {
                                let json = JSON(resp.result.value!)
                                print("json = \(json)")
                                if (json["code"].int == 200) { // OK
                                    self.delegate?.pathLoginSuccess(json["user"], token: pathToken)
                                } else { // Not OK
                                    Constant.showDialog("Warning", message: json["reason"].string!)
                                    self.delegate?.hideLoading()
                                }
                            }
                        }
                    } else { // Not OK
                        Constant.showDialog("Warning", message: json["reason"].string!)
                        self.delegate?.hideLoading()
                    }
                }
            }
            
            // Back to prev scene
//            self.navigationController?.popViewControllerAnimated(true)
            if (self.standAlone)
            {
                self.dismissViewControllerAnimated(true, completion: nil)
            } else
            {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
}