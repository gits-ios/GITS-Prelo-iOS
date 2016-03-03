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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        for v in self.view.subviews
        {
            if (v.isKindOfClass(UIButton.classForCoder()))
            {
                continue
            }
            if let view = v as? UIView
            {
                view.backgroundColor = UIColor.whiteColor()
            }
        }
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.Contact)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Contact)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func call(sender : UIView)
    {
        if let url = NSURL(string: "tel:0222503593")
        {
            if (UIApplication.sharedApplication().canOpenURL(url))
            {
                UIApplication.sharedApplication().openURL(url)
            } else
            {
                putToPasteBoard("0222503593")
                UIAlertView.SimpleShow("Perhatian", message: "Nomor kami sudah ada di clipboard :)")
            }
        }
        
        self.batal(nil)
    }
    
    @IBAction func sms(sender : UIView)
    {
        if (MFMessageComposeViewController.canSendText())
        {
            let composer = MFMessageComposeViewController()
            composer.recipients = ["08112353131"]
            composer.messageComposeDelegate = self
            self.presentViewController(composer, animated: true, completion: nil)
        }
        
//        self.batal(nil)
    }
    
    @IBAction func email(sender : UIView)
    {
        let composer = MFMailComposeViewController()
        if (MFMailComposeViewController.canSendMail()) {
            composer.mailComposeDelegate = self
            composer.setToRecipients(["contact@prelo.co.id"])
            self.presentViewController(composer, animated: true, completion: nil)
        } else {
            Constant.showDialog("No Active Email", message: "Untuk dapat menghubungi Prelo via email, aktifkan akun email kamu di menu Settings > Mail, Contacts, Calendars")
        }
        
//        self.batal(nil)
    }
    
    @IBAction func line(sender : UIView)
    {
        UIAlertView.SimpleShow("Line", message: "Find us on Line\nUserId : @prelo_id\n\nInformasi kontak sudah disalin ke clipboard")
        putToPasteBoard("@prelo_id")
        self.batal(nil)
    }

    @IBAction func wasap(sender : UIView)
    {
        UIAlertView.SimpleShow("Whatsapp", message: "Find us on Whatsapp\nNumber : 08112353131\n\nInformasi kontak sudah disalin ke clipboard")
        putToPasteBoard("08112353131")
        self.batal(nil)
    }
    
    @IBAction func bbm(sender : UIView)
    {
        UIAlertView.SimpleShow("BBM", message: "Find us on Whatsapp\nPIN : 51ac2b2e\n\nInformasi kontak sudah disalin ke clipboard")
        putToPasteBoard("51ac2b2e")
        self.batal(nil)
    }
    
    @IBAction func batal(sender : UIView?)
    {
        UIView.animateWithDuration(0.2, animations: {
                self.view.alpha = 0
            }, completion: { complete in
                self.view.removeFromSuperview()
        })
    }
    
    func putToPasteBoard(text : String)
    {
        UIPasteboard.generalPasteboard().string = text
        
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller .dismissViewControllerAnimated(true, completion: nil)
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
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
