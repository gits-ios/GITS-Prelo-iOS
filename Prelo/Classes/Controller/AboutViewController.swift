//
//  AboutViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class AboutViewController: BaseViewController {

    @IBOutlet var btnLogout : BorderedButton!
    @IBOutlet var btnClear : BorderedButton!
    @IBOutlet var btnClear2 : BorderedButton!
    
    
    var isShowLogout : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (!isShowLogout) {
            self.btnLogout.hidden = true
            self.btnClear.hidden = true
            self.btnClear2.hidden = false
        }
        
        self.title = "About"
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clearCache()
    {
        UIImageView.sharedImageCache().clearAll()
        UIAlertView.SimpleShow("Perhatian", message: "Cache Cleared")
    }
    
    @IBAction func logout()
    {
        User.Logout()
        if let d = self.userRelatedDelegate
        {
            d.userLoggedOut!()
        }
        request(APIAuth.Logout).responseJSON {_, _, res, err in
            if (err != nil) {
                println("Logout API error: \(err!.description)")
            } else {
                println("Logout API success")
            }
        }
        self.navigationController?.popViewControllerAnimated(true)
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
