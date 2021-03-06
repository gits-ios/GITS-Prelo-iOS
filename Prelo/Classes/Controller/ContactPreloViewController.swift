//
//  ContactPreloViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/19/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
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
        if let url = URL(string: "tel:+62227320555") // 0222503593
        {
            if (UIApplication.shared.canOpenURL(url))
            {
                UIApplication.shared.openURL(url)
            } else
            {
                putToPasteBoard("+62227320555")
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
//        //print("this is my_device")
//        //print(my_device)
        
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
        Constant.showDialog("Line", message: "Find us on Line\nUserId : @prelo_id\n\nInformasi kontak sudah disalin ke clipboard")
        putToPasteBoard("@prelo_id")
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
