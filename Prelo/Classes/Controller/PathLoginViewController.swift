//
//  PathLoginViewController.swift
//  Prelo
//
//  Created by Fransiska on 10/2/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

protocol PathLoginDelegate {
    func pathLoginSuccess(_ userData : JSON, token : String)
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
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Batal", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PathLoginViewController.batal))
        
        let url = URL(string: "https://partner.path.com/oauth2/authenticate?response_type=code&client_id=\(pathClientId)")
        let requestObj = Foundation.URLRequest(url: url!)
        self.webView.loadRequest(requestObj)
        
        webView.delegate = self
        
        // Show loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        loadingPanel.isHidden = false
        loading.startAnimating()
    }
    
    func batal()
    {
        if (self.standAlone)
        {
            self.dismiss(animated: true, completion: nil)
        } else
        {
            self.delegate?.hideLoading()
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        // Show loading
        loadingPanel.isHidden = false
        loading.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // Hide loading
        loadingPanel.isHidden = true
        loading.stopAnimating()
        
        let currentURL = webView.request?.url
        print("currentURL = \(currentURL)")
        
        if (currentURL?.absoluteString.lowercased().range(of: pathDeclineUrlString) != nil) { // User canceled path login
            self.delegate?.hideLoading()
            // Back to prev scene
            if (self.standAlone)
            {
                self.dismiss(animated: true, completion: nil)
            } else
            {
                _ = self.navigationController?.popViewController(animated: true)
            }
        } else if (currentURL?.absoluteString.lowercased().range(of: pathLoginSuccessUrlString) != nil) { // User successfully login
            let codeParam : String = (currentURL?.query)!
            let code : String = codeParam.substring(with: codeParam.characters.index(codeParam.startIndex, offsetBy: 5) ..< codeParam.endIndex)
            //print("code = \(code)")
            
            // Get token
            // API Migrasi
        let _ = request(APIPathAuth.getToken(clientId: pathClientId, clientSecret: pathClientSecret, code: code)).responseJSON {resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Path")) {
                    let json = JSON(resp.result.value!)
                    print("json = \(json)")
                    if (json["code"].int == 200) { // OK
                        _ = json["user_id"].string!
                        let pathToken : String = json["access_token"].string!
                        
                        // Get user Path data
                        // API Migrasi
        let _ = request(APIPathUser.getSelfData(token: pathToken)).responseJSON {resp in
                            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Path")) {
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
                self.dismiss(animated: true, completion: nil)
            } else
            {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
