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
    var totalPayment = 0
    var paymentMethod = ""
    
    @IBOutlet var paymentDescription : UIView?
    @IBOutlet var paymentDescriptionHeight : NSLayoutConstraint?
    
    @IBOutlet var captionOrderID : UILabel?
    @IBOutlet var captionTotalPayment : UILabel?
    @IBOutlet var captionPaymentMethod : UILabel?
    @IBOutlet var captionName : UILabel?
    
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
        }
    }

}
