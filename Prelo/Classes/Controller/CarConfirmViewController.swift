//
//  CarConfirmViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/7/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class CarConfirmViewController: BaseViewController {

    var orderID = ""
    var transactionId = ""
    var totalPayment = 0
    var paymentMethod = ""
    
    var items : [JSON] = []
    
    @IBOutlet var paymentDescription : UIView?
    @IBOutlet var paymentDescriptionHeight : NSLayoutConstraint?
    
    @IBOutlet var captionOrderID : UILabel?
    @IBOutlet var captionTotalPayment : UILabel?
    @IBOutlet var captionPaymentMethod : UILabel?
    @IBOutlet var captionName : UILabel?
    
//    @IBOutlet var iv1 : UIImageView!
//    @IBOutlet var iv2 : UIImageView!
//    @IBOutlet var iv3 : UIImageView!
//    @IBOutlet var captionIVMore : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.titleText = self.title
        
//        self.navigationItem.backBarButtonItem.set
        
        captionOrderID?.text = orderID
        captionTotalPayment?.text = "Rp. " + String(totalPayment)
        captionPaymentMethod?.text = paymentMethod
        
        captionName?.text = "Hai " + ((CDUser.getOne()?.fullname)!).capitalizedString + "\nKami baru saja mengirimkan email konfirmasi pesanan Kamu :"
    }
    
    var first = true
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let arr = self.navigationController?.viewControllers
        {
            if (first)
            {
                var x = arr
                x.removeAtIndex(x.count-2)
                x.removeAtIndex(x.count-2)
                self.navigationController?.setViewControllers(x, animated: false)
                first = false
            }
        }
    }
    
    func backSkipTwo()
    {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "segConfirm")
        {
            let o = segue.destinationViewController as! OrderConfirmViewController
            o.orderID = self.orderID
            o.transactionId = transactionId
            o.total = totalPayment
            
            var imgs : [NSURL] = []
            
            for i in 0...items.count-1
            {
                let json = items[i]
                if let raw : Array<AnyObject> = json["display_picts"].arrayObject
                {
                    var ori : Array<String> = []
                    for o in raw
                    {
                        if let s = o as? String
                        {
                            ori.append(s)
                        }
                    }
                    
                    if (ori.count > 0)
                    {
                        if let u = NSURL(string: ori.first!)
                        {
                            imgs.append(u)
                        }
                    }
                }
            }
            
            o.images = imgs
        }
    }

}
