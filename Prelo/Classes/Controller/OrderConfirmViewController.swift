//
//  OrderConfirmViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/7/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class OrderConfirmViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UITextFieldDelegate {

    @IBOutlet var tableView : UITableView?
    @IBOutlet var captionOrderID : UILabel!
    @IBOutlet var captionOrderTotal : UILabel!
    @IBOutlet var captionMore : UILabel!
    @IBOutlet var img1 : UIImageView!
    @IBOutlet var img2 : UIImageView!
    @IBOutlet var img3 : UIImageView!
    @IBOutlet var imgs : [UIView] = []
    
    var cellData : [NSIndexPath : BaseCartData] = [:]
    
    var orderID : String = ""
    var transactionId : String = ""
    var images : [NSURL] = []
    var total : Int = 0
    
    let titleOrderID = "Order ID"
    let titleBankTujuan = "Bank Tujuan"
    let titleBankKamu = "Bank Kamu"
    let titleRekening = "Rekening Atas Nama"
    let titleNominal = "Nominal Transfer"
    
    var overBack = false
    var first = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleText = self.title

        // Do any additional setup after loading the view.
        
        cellData[NSIndexPath(forRow: 0, inSection: 0)] = BaseCartData.instance(titleOrderID, placeHolder: "", value: orderID, enable : false)
        cellData[NSIndexPath(forRow: 1, inSection: 0)] = BaseCartData.instance(titleBankTujuan, placeHolder: "", value: "", pickerPrepBlock: { picker in
            
            picker.items = ["Bank BCA", "Bank Mandiri", "Bank BNI"]
            picker.tableView.reloadData()
            
        })
        cellData[NSIndexPath(forRow: 2, inSection: 0)] = BaseCartData.instance(titleBankKamu, placeHolder: "Nama Bank Kamu")
        cellData[NSIndexPath(forRow: 3, inSection: 0)] = BaseCartData.instance(titleRekening, placeHolder: "Nama Rekening Kamu")
        let b = BaseCartData.instance(titleNominal, placeHolder: "Nominal Transfer")
        b.keyboardType = UIKeyboardType.DecimalPad
        cellData[NSIndexPath(forRow: 4, inSection: 0)] = b
        
        tableView?.dataSource = self
        tableView?.delegate = self
        
        for v in imgs
        {
            v.hidden = true
        }
        for i in 0...images.count-1
        {
            let v = imgs[i]
            v.hidden = false
            
            if (i < 3)
            {
                let im = v as! UIImageView
                im.setImageWithUrl(images[i], placeHolderImage: nil)
            } else if (i < 4)
            {
                captionMore.text = String(images.count-3) + "+"
            }
        }
        
        captionOrderID.text = orderID
        captionOrderTotal.text = total.asPrice
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let p = [
            "ID" : self.orderID,
            "Items" : "\(self.images.count)",
            "Price" : "\(self.total)"
        ]
        Mixpanel.trackPageVisit("Payment Confirmation", otherParam: p)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (first && overBack)
        {
            var x = self.navigationController?.viewControllers
            x?.removeAtIndex((x?.count)!-2)
            x?.removeAtIndex((x?.count)!-2)
            self.navigationController?.setViewControllers(x, animated: false)
            first = false
        }
        
        self.an_subscribeKeyboardWithAnimations({ r, t, o in
            
            if (o) {
                self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
            } else {
                self.tableView?.contentInset = UIEdgeInsetsZero
            }
            
        }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellData.keys.array.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var c : UITableViewCell?
        var b : BaseCartCell
        let r = indexPath.row
        if (r == 1) {
            b = tableView.dequeueReusableCellWithIdentifier("cell_input_2") as! CartCellInput2
        } else {
            b = tableView.dequeueReusableCellWithIdentifier("cell_input") as! CartCellInput
        }
        
        if (b.lastIndex != nil) {
            cellData[b.lastIndex!] = b.obtainValue()
        }
        
        b.lastIndex = indexPath
        b.adapt(cellData[indexPath])
        b.parent = self
        
        c = b
        return c!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let c = tableView.cellForRowAtIndexPath(indexPath)
        if ((c?.canBecomeFirstResponder())!) {
            c?.becomeFirstResponder()
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        let i = tableView!.indexPathForCell((textField.superview?.superview!) as! UITableViewCell)
        var s = (i?.section)!
        var r = (i?.row)!
        
        var cell : UITableViewCell?
        
        var con = true
        while (con) {
            let newIndex = NSIndexPath(forRow: r+1, inSection: s)
            cell = tableView!.cellForRowAtIndexPath(newIndex)
            if (cell == nil) {
                s += 1
                r = -1
                if (s == tableView!.numberOfSections()) { // finish, last cell
                    con = false
                }
            } else {
                if ((cell?.canBecomeFirstResponder())!) {
                    cell?.becomeFirstResponder()
                    con = false
                } else {
                    r+=1
                }
            }
        }
        return true
    }
    
    @IBAction func sendConfirm()
    {
        var orderId = transactionId
        var bankTo = cellData[NSIndexPath(forRow: 0, inSection: 0)]
        var bankFrom = cellData[NSIndexPath(forRow: 0, inSection: 0)]
        var name = cellData[NSIndexPath(forRow: 0, inSection: 0)]
        var nominal = cellData[NSIndexPath(forRow: 0, inSection: 0)]
        
        if let f = bankFrom?.value, let t = bankTo?.value, let n = name?.value, let nom = nominal?.value
        {
            let x = (nom as NSString).integerValue
            request(APITransaction2.ConfirmPayment(bankFrom: f, bankTo: t, name: n, nominal: x, orderId: orderId)).responseJSON { req, resp, res, err in
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
            }
        } else
        {
            UIAlertView.SimpleShow("Perhatian", message: "Silakan isi semua data")
        }
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
