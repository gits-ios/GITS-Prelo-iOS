//
//  PreloShareController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Social
import MessageUI

struct PreloShareItem
{
    var image : UIImage?
    var text : String?
    var url : NSURL?
}

struct PreloShareAgent
{
    var title : String = ""
    var icon : String = ""
    var font : UIFont = AppFont.Prelo2.getFont!
    var background : UIColor = UIColor.whiteColor()
    var availibility : Bool = false
}

class PreloShareController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIDocumentInteractionControllerDelegate, UIGestureRecognizerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate
{

    static var sharer : PreloShareController = PreloShareController()
    
    static func Share(item : PreloShareItem, inView:UIView)
    {
        let s = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPreloShare) as! PreloShareController
        s.item = item
        s.parentView = inView
        
        sharer = s
        
        sharer.show()
    }
    
    var item : PreloShareItem?
    var parentView : UIView?
    
    @IBOutlet var conGridViewBottomMargin : NSLayoutConstraint!
    @IBOutlet var gridView : UICollectionView!
    
    var agents : Array<PreloShareAgent> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = NSURL(string : "")
        let x = UIApplication.sharedApplication().canOpenURL(NSURL(string:"")!)
        agents.append(PreloShareAgent(title: "Instagram", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor.brownColor(), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"instagram://app")!)))
        agents.append(PreloShareAgent(title: "Facebook", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor(hex: "#3b5998"), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"fb://")!)))
        agents.append(PreloShareAgent(title: "Twitter", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor(hex: "#00aced"), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"twitter://timeline")!)))
        agents.append(PreloShareAgent(title: "Path", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor(hex: "#cb2027"), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"instagram://app")!)))
        agents.append(PreloShareAgent(title: "Whatsapp", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor(hex: "#4dc247"), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"whatsapp://app")!)))
        agents.append(PreloShareAgent(title: "Line", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor(hex: "#4dc247"), availibility: Line.isLineInstalled()))
        agents.append(PreloShareAgent(title: "Salin", icon: "", font: AppFont.PreloAwesome.getFont!, background: UIColor.darkGrayColor(), availibility: UIApplication.sharedApplication().canOpenURL(NSURL(string:"instagram://app")!)))
        agents.append(PreloShareAgent(title: "SMS", icon: "", font: AppFont.Prelo2.getFont!, background: UIColor.darkGrayColor(), availibility: MFMessageComposeViewController.canSendText()))
        agents.append(PreloShareAgent(title: "Email", icon: "", font: AppFont.PreloAwesome.getFont!, background: UIColor.darkGrayColor(), availibility: MFMailComposeViewController.canSendMail()))
        
        // Do any additional setup after loading the view.
        conGridViewBottomMargin.constant = -gridView.height
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func show()
    {
        self.view.alpha = 1
        self.view.backgroundColor = UIColor(white: 0.5, alpha: 0)
        self.view.frame = (parentView?.bounds)!
        
        parentView?.addSubview(self.view)
        
        self.conGridViewBottomMargin.constant = 0
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.view.backgroundColor = UIColor(white: 0.5, alpha: 0.8)
            self.gridView.layoutIfNeeded()
            }, completion: {s in
                self.gridView.dataSource = self
                self.gridView.delegate = self
        })
    }
    
    @IBAction func hide()
    {
        conGridViewBottomMargin.constant = -gridView.height
        self.gridView.dataSource = nil
        self.gridView.delegate = nil
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.view.backgroundColor = UIColor(white: 0.5, alpha: 0)
            self.gridView.layoutIfNeeded()
            }, completion: {s in
                if (s)
                {
                    self.view.removeFromSuperview()
                }
        })
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return agents.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let s = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ShareCell
        
        let a = agents[indexPath.item]
        
        if (a.availibility == false)
        {
            s.sectionIcon.backgroundColor = UIColor.lightGrayColor()
        } else {
            s.sectionIcon.backgroundColor = a.background
        }
        
        s.captionIcon.font = a.font
        s.captionIcon.text = a.icon
        s.captionTitle.text = a.title
        
        return s
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake((UIScreen.mainScreen().bounds.width/3)-4, 84)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let a = agents[indexPath.item]
        
        if (a.availibility == false)
        {
            return
        }
        
        println(item?.url)
        println(item?.text)
        
        request(Method.GET, (item?.url?.absoluteString)!).validate().response{ req, res, data, error in
            if let imgData = data
            {
                let i = UIImage(data: imgData)
                self.share(a, image: i!)
            }
        }
    }
    
    var mgInstagram : MGInstagram?
    func share(a : PreloShareAgent, image : UIImage)
    {
        if (a.title.lowercaseString == "instagram")
        {
            mgInstagram = MGInstagram()
            mgInstagram?.postImage(image, inView: self.view)
//            MGInstagram().postImage(image, inView: self.view)
        }
        
        if (a.title.lowercaseString == "whatsapp")
        {
            var message = item?.text!
            var name = ""
            if let n = item?.text
            {
                name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
            }
            name = "http://prelo.co.id.id/p/" + name
            message = (message! + "\n\n" + name).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            let url = NSURL(string : "whatsapp://send?text="+message!)
            UIApplication.sharedApplication().openURL(url!)
        }
        
        if (a.title.lowercaseString == "salin")
        {
            var name = ""
            if let n = item?.text
            {
                name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
            }
            name = "http://prelo.co.id.id/p/" + name
            UIPasteboard.generalPasteboard().string = name
            UIAlertView.SimpleShow("", message: "Sukses di salin")
        }
        
        if (a.title.lowercaseString == "sms")
        {
            var message = item?.text!
            var name = ""
            if let n = item?.text
            {
                name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
            }
            name = "http://prelo.co.id.id/p/" + name
            message = (message! + "\n\n" + name)
            let composer = MFMessageComposeViewController()
            composer.body = message
            composer.messageComposeDelegate = self
            
            self.presentViewController(composer, animated: true, completion: nil)
        }
        
        if (a.title.lowercaseString == "email")
        {
            var message = item?.text!
            var name = ""
            if let n = item?.text
            {
                name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
            }
            name = "http://prelo.co.id.id/p/" + name
            message = (message! + "\n\n" + name)
            let composer = MFMailComposeViewController()
            composer.setMessageBody(message, isHTML: false)
            composer.mailComposeDelegate = self
            
            self.presentViewController(composer, animated: true, completion: nil)
        }
        
        if (a.title.lowercaseString == "line")
        {
            var message = item?.text!
            var name = ""
            if let n = item?.text
            {
                name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
            }
            name = "http://prelo.co.id.id/p/" + name
            message = (message! + "\n\n" + name)
            Line.shareText(message)
        }
        
        if (a.title.lowercaseString == "facebook" || a.title.lowercaseString == "twitter")
        {
            let type = a.title.lowercaseString == "facebook" ? SLServiceTypeFacebook : SLServiceTypeTwitter
            
            if (SLComposeViewController.isAvailableForServiceType(type))
            {
                var name = ""
                if let n = item?.text
                {
                    name = n.stringByReplacingOccurrencesOfString(" ", withString: "-")
                }
                name = "http://prelo.co.id.id/p/" + name
                let url = NSURL(string:name)
                let composer = SLComposeViewController(forServiceType: type)
                composer.addURL(url!)
                composer.addImage(image)
                composer.setInitialText(""+(item?.text)!)
                self.presentViewController(composer, animated: true, completion: nil)
            } else
            {
                UIAlertView.SimpleShow(a.title, message: "Silakan login "+a.title+" dari Settings")
            }
        }
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view.isKindOfClass(UICollectionView.classForCoder()) || touch.view.tag == 1)
        {
            return false
        }
        
        return true
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

class ShareCell : UICollectionViewCell
{
    
    @IBOutlet var captionTitle : UILabel!
    @IBOutlet var captionIcon : UILabel!
    @IBOutlet var sectionIcon : UIView!
    
    override func awakeFromNib() {
        sectionIcon.layer.cornerRadius = sectionIcon.width/2
        sectionIcon.layer.masksToBounds = true
        sectionIcon.superview?.backgroundColor = UIColor.clearColor()
    }
}
