//
//  PreloWebViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/29/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class PreloWebViewController: UIViewController
{
    @IBOutlet var webView : UIWebView!
    var url : String = ""
    var titleString : String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let req = NSURLRequest(URL: NSURL(string: url)!)
        webView.loadRequest(req)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Selesai", style: .Plain, target: self, action: "done")
        
        self.title = titleString
    }
    
    func done()
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
