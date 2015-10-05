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
}

class PathLoginViewController : BaseViewController, UIWebViewDelegate {
    
    var delegate : PathLoginDelegate?
    
    @IBOutlet weak var webView: UIWebView!
    
    let pathClientId = "b0b1aca06485dadc5f9c04e799914107277a4a42"
    let pathClientSecret = "2f53945d5e9a94659dae8c982a47df24515cae79"
    let pathDeclineUrlString = "https://partner.path.com/oauth2/decline"
    let pathLoginSuccessUrlString = "https://prelo.id/path/callback"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = NSURL(string: "https://partner.path.com/oauth2/authenticate?response_type=code&client_id=\(pathClientId)")
        let requestObj = NSURLRequest(URL: url!)
        self.webView.loadRequest(requestObj)
        
        webView.delegate = self
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let currentURL = webView.request?.URL
        println("currentURL = \(currentURL)")
        
        if (currentURL?.absoluteString?.lowercaseString.rangeOfString(pathDeclineUrlString) != nil) { // User canceled path login
            // Back to prev scene
            self.navigationController?.popViewControllerAnimated(true)
        } else if (currentURL?.absoluteString?.lowercaseString.rangeOfString(pathLoginSuccessUrlString) != nil) { // User successfully login
            let codeParam : String = (currentURL?.query)!
            let code : String = codeParam.substringWithRange(Range(start: advance(codeParam.startIndex, 5), end: codeParam.endIndex))
            //println("code = \(code)")
            
            // Get token
            request(APIPathAuth.GetToken(clientId: pathClientId, clientSecret: pathClientSecret, code: code)).responseJSON {req, _, res, err in
                println("Request token req = \(req)")
                
                if (err != nil) { // Terdapat error
                    Constant.showDialog("Warning", message: (err?.description)!)
                } else {
                    let json = JSON(res!)
                    println("json = \(json)")
                    if (json["code"].int == 200) { // OK
                        let pathId : String = json["user_id"].string!
                        let pathToken : String = json["access_token"].string!
                        
                        // Get user Path data
                        request(APIPathUser.GetSelfData(token: pathToken)).responseJSON {req, _, res, err in
                            println("Request get self data = \(req)")
                            if (err != nil) { // Terdapat error
                                Constant.showDialog("Warning", message: (err?.description)!)
                            } else {
                                let json = JSON(res!)
                                println("json = \(json)")
                                if (json["code"].int == 200) { // OK
                                    self.delegate?.pathLoginSuccess(json["user"], token: pathToken)
                                } else { // Not OK
                                    Constant.showDialog("Warning", message: json["reason"].string!)
                                }
                            }
                        }
                    } else { // Not OK
                        Constant.showDialog("Warning", message: json["reason"].string!)
                    }
                }
            }
            
            // Back to prev scene
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
}