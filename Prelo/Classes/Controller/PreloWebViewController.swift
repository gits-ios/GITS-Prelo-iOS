//
//  PreloWebViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/29/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class PreloWebViewController: UIViewController, UIWebViewDelegate
{
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    @IBOutlet var webView : UIWebView!
    var url : String = ""
    var titleString : String = ""
    
    var creditCardMode : Bool = false
    var ccModeSuccessUrl : String = "\(AppTools.PreloBaseUrl)/payment/finish"
    var ccModeUnfinishUrl : String = "\(AppTools.PreloBaseUrl)/payment/unfinish"
    var ccModeFailUrl : String = "\(AppTools.PreloBaseUrl)/payment/error"
    var ccPaymentSucceed : () -> () = {}
    var ccPaymentUnfinished : () -> () = {}
    var ccPaymentFailed : () -> () = {}
    
    var contactPreloMode : Bool = false
    @IBOutlet var btnStickyFooter: BorderedButton!
    @IBOutlet var consHeightStickyFooter: NSLayoutConstraint!
    var contactUs : UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let req = NSURLRequest(URL: NSURL(string: url)!)
        webView.loadRequest(req)
        webView.delegate = self
        
        let btnClose = UIBarButtonItem(title: "", style: .Plain, target: self, action: #selector(PreloWebViewController.closePressed))
        btnClose.setTitleTextAttributes([NSFontAttributeName : UIFont(name: "Prelo2", size: 15)!], forState: UIControlState.Normal)
        self.navigationItem.rightBarButtonItem = btnClose
        
        self.title = titleString
        
        // Show loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        loadingPanel.hidden = false
        loading.startAnimating()
        
        // Sticky footer
        self.btnStickyFooter.borderColor = Theme.PrimaryColor
        self.btnStickyFooter.borderWidth = 1
        
        // Contact prelo mode
        if (self.contactPreloMode) {
            self.consHeightStickyFooter.constant = 56
        } else {
            self.consHeightStickyFooter.constant = 0
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (titleString == "Syarat dan Ketentuan") {
            // Mixpanel
            //Mixpanel.trackPageVisit(PageName.TermsAndConditions)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.TermsAndConditions)
        }
    }
    
    func closePressed() {
        if (creditCardMode) {
            ccPaymentUnfinished()
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        // Show loading
        loadingPanel.hidden = false
        loading.startAnimating()
        
        //let currentURL = webView.request // Not incoming URL
        //print(currentURL)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        // Hide loading
        loadingPanel.hidden = true
        loading.stopAnimating()
        
        //let currentURL = webView.request?.URL // Incoming URL
        //print(currentURL)
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print("Load webview failed!")
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let auth = request.valueForHTTPHeaderField("Authorization")
        print("Auth = \(auth)")
        print("URL = \(webView.request?.URL), INCOMING REQUEST = \(request), NAVIGATION TYPE = \(navigationType.rawValue)")
        
        if (creditCardMode) {
            let incomingURL = request.URL
            if (incomingURL?.absoluteString.lowercaseString.rangeOfString(ccModeSuccessUrl) != nil) { // Success
                ccPaymentSucceed()
                self.dismissViewControllerAnimated(true, completion: nil)
            } else if (incomingURL?.absoluteString.lowercaseString.rangeOfString(ccModeUnfinishUrl) != nil) { // Unfinished
                ccPaymentUnfinished()
                self.dismissViewControllerAnimated(true, completion: nil)
            } else if (incomingURL?.absoluteString.lowercaseString.rangeOfString(ccModeFailUrl) != nil) { // Failed
                ccPaymentFailed()
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            /* Adding Auth to HTTPHeader, cancelling current request, and performing new request (Unused)
             if (request.URLString.containsString("http://dev.prelo.id") && auth == nil) {
                let username = "klora.ops"
                let password = "BekasBerkualitas31!"
                let loginString = NSString(format: "%@:%@", username, password)
                let loginData : NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
                let base64LoginString = loginData.base64EncodedStringWithOptions([])
                
                let mutableReq = NSMutableURLRequest(URL: request.URL!)
                mutableReq.HTTPMethod = request.HTTPMethod!
                mutableReq.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
                webView.delegate = self
                webView.loadRequest(mutableReq)
                return false
            }*/
        }
        
        return true
    }
    
    @IBAction func btnStickyFooterPressed(sender: AnyObject) {
        if (contactPreloMode) {
            let c = (self.storyboard?.instantiateViewControllerWithIdentifier("contactus"))!
            contactUs = c
            if let v = c.view, let p = self.navigationController?.view {
                v.alpha = 0
                v.frame = p.bounds
                self.navigationController?.view.addSubview(v)
                
                v.alpha = 0
                UIView.animateWithDuration(0.2, animations: {
                    v.alpha = 1
                })
            }
        }
    }
}
