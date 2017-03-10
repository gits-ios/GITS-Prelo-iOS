//
//  CarConfirmViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/7/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
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
        
        captionName?.text = "Hai " + ((CDUser.getOne()?.fullname)!).capitalized + "\nKami baru saja mengirimkan e-mail konfirmasi pesanan Kamu :"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.CheckoutConfirmation)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.CheckoutConfirmation)
    }
    
    var first = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let arr = self.navigationController?.viewControllers
        {
            if (first)
            {
                var x = arr
                x.remove(at: x.count-2)
                x.remove(at: x.count-2)
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "segConfirm")
        {
            let o = segue.destination as! OrderConfirmViewController
            o.orderID = self.orderID
            o.transactionId = transactionId
            o.total = totalPayment
            
            var imgs : [URL] = []
            
            for i in 0...items.count-1
            {
                let json = items[i]
                if let raw : Array<AnyObject> = json["display_picts"].arrayObject as Array<AnyObject>?
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
                        if let u = URL(string: ori.first!)
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
