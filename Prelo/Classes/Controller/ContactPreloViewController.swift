//
//  ContactPreloViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/19/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import MessageUI

class ContactPreloViewController: UIViewController, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate
{
    var order_id : String? // jika dipanggil dari transaksi
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        for v in self.view.subviews
        {
            if (v.isKind(of: UIButton.classForCoder()))
            {
                continue
            }
            v.backgroundColor = UIColor.white
        }
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.Contact)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Contact)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func call(_ sender : UIView)
    {
        if let url = URL(string: "tel:0222503593")
        {
            if (UIApplication.shared.canOpenURL(url))
            {
                UIApplication.shared.openURL(url)
            } else
            {
                putToPasteBoard("0222503593")
                Constant.showDialog("Perhatian", message: "Nomor kami sudah ada di clipboard :)")
            }
        }
        
        self.batal(nil)
    }
    
    @IBAction func sms(_ sender : UIView)
    {
        if (MFMessageComposeViewController.canSendText())
        {
            let composer = MFMessageComposeViewController()
            composer.recipients = ["08112353131"]
            composer.messageComposeDelegate = self
            self.present(composer, animated: true, completion: nil)
        }
        
//        self.batal(nil)
    }
    
    @IBAction func email(_ sender : UIView)
    {
        let my_device = UserDefaults().value(forKey: UserDefaultsKey.UserAgent)
//        print("this is my_device")
//        print(my_device)
        
//        Constant.showDialog("Device Info", message: String(describing: my_device))
        
        let composer = MFMailComposeViewController()
        if (MFMailComposeViewController.canSendMail()) {
            composer.mailComposeDelegate = self
            composer.setToRecipients(["contact@prelo.co.id"])
            
            // adding title and message email
            //composer.setSubject("")
            
            var msg = ""
            let user = CDUser.getOne()
            let username = user?.username
            let no_hp = user?.profiles.phone
            
            msg += "Order Id: " + (order_id != nil ? order_id! : "") + "\n"
            msg += "Berita / Laporan: \n\n" + "\n---\n"
            
            
            if (user != nil) {
                msg += "Username: " + username! + "\n"
                msg += "No. HP: " + no_hp! + "\n"
            }
            
            msg += "Versi App: " + (CDVersion.getOne()?.appVersion)! + "\n"
            msg += "User Agent: " + String(describing: my_device)
            
            composer.setMessageBody(msg, isHTML: false)
            
            self.present(composer, animated: true, completion: nil)
        } else {
            Constant.showDialog("No Active E-mail", message: "Untuk dapat menghubungi Prelo via e-mail, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
        }
        
//        self.batal(nil)
    }
    
    @IBAction func line(_ sender : UIView)
    {
//        Constant.showDialog("Line", message: "Find us on Line\nUserId : @prelo_id\n\nInformasi kontak sudah disalin ke clipboard")
//        putToPasteBoard("@prelo_id")
        
        // Hotline
        // override with last user in this phone
        settingHotline()
        Hotline.sharedInstance().showConversations(self)
        self.batal(nil)
    }

    // disabled
    @IBAction func wasap(_ sender : UIView)
    {
        Constant.showDialog("Whatsapp", message: "Find us on Whatsapp\nNumber : 08112353131\n\nInformasi kontak sudah disalin ke clipboard")
        putToPasteBoard("08112353131")
        self.batal(nil)
    }
    
    // disabled
    @IBAction func bbm(_ sender : UIView)
    {
        Constant.showDialog("BBM", message: "Find us on Whatsapp\nPIN : 51ac2b2e\n\nInformasi kontak sudah disalin ke clipboard")
        putToPasteBoard("51ac2b2e")
        self.batal(nil)
    }
    
    @IBAction func batal(_ sender : UIView?)
    {
        UIView.animate(withDuration: 0.2, animations: {
                self.view.alpha = 0
            }, completion: { complete in
                self.view.removeFromSuperview()
        })
    }
    
    func putToPasteBoard(_ text : String)
    {
        UIPasteboard.general.string = text
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller .dismiss(animated: true, completion: nil)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Hotline
    func settingHotline() {
        /*
         * Following three methods are to identify a user.
         * These user properties will be viewable on the Hotline web dashboard.
         * The externalID (identifier) set will also be used to identify the specific user for any APIs
         * targeting a user or list of users in pro-active messaging or marketing
         */
        
        // Create a user object
        let user = HotlineUser.sharedInstance();
        
        // To set an identifiable name for the user
        user?.name = CDUser.getOne()?.fullname
        
        //To set user's email id
        user?.email = CDUser.getOne()?.email
        
        //To set user's phone number
//        user?.phoneCountryCode="62"; // indonesia
        user?.phoneNumber = CDUser.getOne()?.profiles.phone
        
        
        
        //To set user's identifier (external id to map the user to a user in your system. Setting an external ID is COMPULSARY for many of Hotline’s APIs
        user?.externalID = CDUser.getOne()?.username
        
        
        // FINALLY, REMEMBER TO SEND THE USER INFORMATION SET TO HOTLINE SERVERS
        Hotline.sharedInstance().update(user)
        
        /* Custom properties & Segmentation - You can add any number of custom properties. An example is given below.
         These properties give context for your conversation with the user and also serve as segmentation criteria for your marketing messages
         */
        
//        //You can set custom user properties for a particular user
//        Hotline.sharedInstance().updateUserPropertyforKey("customerType", withValue: "Premium")
        
        let city = CDUser.getOne()?.profiles.subdistrictName
        
        //You can set user demographic information
        Hotline.sharedInstance().updateUserPropertyforKey("city", withValue: city)
        
        //You can segment based on where the user is in their journey of using your app
        Hotline.sharedInstance().updateUserPropertyforKey("loggedIn", withValue: User.IsLoggedIn.description)
        
//        //You can capture a state of the user that includes what the user has done in your app
//        Hotline.sharedInstance().updateUserPropertyforKey("transactionCount", withValue: "3")
        
        
        /* If you want to indicate to the user that he has unread messages in his inbox, you can retrieve the unread count to display. */
        //returns an int indicating the of number of unread messages for the user
        Hotline.sharedInstance().unreadCount()
        
        
//        /* 
//         Managing Badge number for unread messages - Manual
//         */
//        Hotline.sharedInstance().initWithConfig(config)
//        print("Unread messages count \(Hotline.sharedInstance().unreadCount()) .")
//        
//        
//        Hotline.sharedInstance().unreadCountWithCompletion { (count:Int) -> Void in
//            print("Unread count (Async) :\(count)")
//        }
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
