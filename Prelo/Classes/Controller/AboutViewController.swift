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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.trackPageVisit("About")
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
        // Remove deviceRegId so the device won't receive push notification
        LoginViewController.SendDeviceRegId(onFinish: nil)
        
        // Clear local data
        User.Logout()
        
        // Tell delegate class if any
        if let d = self.userRelatedDelegate
        {
            d.userLoggedOut!()
        }
        
        // Tell server
        request(APIAuth.Logout).responseJSON {_, _, res, err in
            if (err != nil) {
                println("Logout API error: \(err!.description)")
            } else {
                println("Logout API success")
            }
        }
        
        let del = UIApplication.sharedApplication().delegate as! AppDelegate
        del.messagePool.stop()
        
        // Disconnect socket
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let notifListener = delegate.preloNotifListener
        notifListener.willReconnect = true // Pengganti disconnect
        // Set top bar notif number to 0
        if (notifListener.newNotifCount != 0) {
            notifListener.setNewNotifCount(0)
        }
        
        // Reset crashlytics
        Mixpanel.sharedInstance().reset()
        let uuid = UIDevice.currentDevice().identifierForVendor!.UUIDString
        Mixpanel.sharedInstance().identify(uuid)
        
        // Back to previous page
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
