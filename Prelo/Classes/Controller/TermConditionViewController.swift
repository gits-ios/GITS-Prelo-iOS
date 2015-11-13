//
//  TermConditionViewController.swift
//  Prelo
//
//  Created by Fransiska on 10/23/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class TermConditionViewController : BaseViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = NSURL(string: "https://prelo.co.id/syarat-ketentuan?ref=preloapp")
        let requestObj = NSURLRequest(URL: url!)
        self.webView.loadRequest(requestObj)
        
        webView.delegate = self
        
        // Show loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = false
        loading.startAnimating()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.sharedInstance().track("Terms and Conditions")
    }
    
    @IBAction func backPressed(sender: AnyObject) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        // Back to prev scene
        self.navigationController?.popViewControllerAnimated(true)
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
    }
}