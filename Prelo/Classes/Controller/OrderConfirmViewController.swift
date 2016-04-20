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
    @IBOutlet var unneededViewsIfFree : [UIView] = []
    @IBOutlet var conMarginTitle : NSLayoutConstraint!
    @IBOutlet var captionTitle : UILabel!
    @IBOutlet var captionDesc : UILabel!
    @IBOutlet var btnBack2 : UIButton!
    var fromCheckout = true
    var free = false
    
    var cellData : [NSIndexPath : BaseCartData] = [:]
    var cellViews : [NSIndexPath : UITableViewCell] = [:]
    
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
    
    var clearCart = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // clearCart = true kalaw dari Cart
        if (clearCart)
        {
            let products = CartProduct.getAll(User.EmailOrEmptyString)
            for p in products
            {
                UIApplication.appDelegate.managedObjectContext.deleteObject(p)
            }
            UIApplication.appDelegate.saveContext()
        }
        
        free = total == 0
//        free = true
        
        self.titleText = self.title
        
//        if var f = captionTitle.superview?.frame
//        {
//            f.size.height -= CGFloat(10)
//            captionTitle.superview?.frame = f
//        }
        
        // Do any additional setup after loading the view.
        
        cellData[NSIndexPath(forRow: 0, inSection: 0)] = BaseCartData.instance(titleOrderID, placeHolder: "", value: orderID, enable : false)
        cellData[NSIndexPath(forRow: 1, inSection: 0)] = BaseCartData.instance(titleBankTujuan, placeHolder: "", value: "", pickerPrepBlock: { picker in
            
            picker.items = ["Bank BCA", "Bank Mandiri", "Bank BNI"]
            picker.tableView.reloadData()
            
        })
        cellData[NSIndexPath(forRow: 2, inSection: 0)] = BaseCartData.instance(titleBankKamu, placeHolder: "Nama Bank Kamu")
        cellData[NSIndexPath(forRow: 3, inSection: 0)] = BaseCartData.instance(titleRekening, placeHolder: "Nama Rekening Kamu")
        let b = BaseCartData.instance(titleNominal, placeHolder: "Nominal Transfer")
        b.keyboardType = UIKeyboardType.NumberPad
        cellData[NSIndexPath(forRow: 4, inSection: 0)] = b
        
        if (fromCheckout == false)
        {
            conMarginTitle.constant = 0
            captionTitle.text = ""
            if var f = captionTitle.superview?.frame
            {
                f.size.height -= CGFloat(44)
                captionTitle.superview?.frame = f
            }
        }
        
        btnBack2.hidden = true
        if (free)
        {
            captionTitle.text = "Selamat! Transaksi kamu berhasil"
            
            for v in unneededViewsIfFree
            {
                v.hidden = true
            }
            
            if var f = captionTitle.superview?.frame
            {
//                f.size.height = CGFloat(260)
                captionTitle.superview?.frame = f
            }
            
//            captionTitle.superview?.backgroundColor = .redColor()
            
            captionDesc.text = "Kami segera memproses dan mengirim barang pesanan kamu. Silakan tunggu notifikasi Konfirmasi Pengiriman maximal 3 x 24 jam."
            cellData = [:]
            
            btnBack2.hidden = false
            self.tableView?.tableFooterView = UIView()
        }
        
        createCells()
        
        tableView?.dataSource = self
        tableView?.delegate = self
        
        for v in imgs
        {
            v.hidden = true
        }
        if (images.count > 0) {
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
                    break
                }
            }
        }
        
        captionOrderID.text = orderID
        captionOrderTotal.text = total.asPrice
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        let p = [
            "ID" : self.orderID,
            "Items" : "\(self.images.count)",
            "Price" : "\(self.total)"
        ]
        Mixpanel.trackPageVisit(PageName.PaymentConfirmation, otherParam: p)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.PaymentConfirmation)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (first && overBack)
        {
            var x = self.navigationController?.viewControllers
            x?.removeAtIndex((x?.count)!-2)
            if (x == nil)
            {
                x = []
            }
            self.navigationController?.setViewControllers(x!, animated: false)
            first = false
        }
        
        self.an_subscribeKeyboardWithAnimations({ r, t, o in
            
            if (o) {
                self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
            } else {
                self.tableView?.contentInset = UIEdgeInsetsZero
            }
            
        }, completion: nil)
        
        // Remove redirect alert if any
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let redirAlert = appDelegate.redirAlert {
            redirAlert.dismissWithClickedButtonIndex(-1, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return cellData.keys.array.count
        return cellData.keys.count
    }
    
    var rawCells : [UITableViewCell] = []
    func createCells()
    {
        if (!free) {
            for i in 0...cellData.keys.count-1
            {
                var c : UITableViewCell?
                var b : BaseCartCell
                let r = i
                if (r == 1) {
                    b = tableView!.dequeueReusableCellWithIdentifier("cell_input_2") as! CartCellInput2
                } else {
                    b = tableView!.dequeueReusableCellWithIdentifier("cell_input") as! CartCellInput
                }
                
    //            if (b.lastIndex != nil) {
    //                cellData[b.lastIndex!] = b.obtainValue()
    //            }
                
                b.parent = self
                
                c = b
                rawCells.append(c!)
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cachedCell = cellViews[indexPath]
        if (cachedCell != nil) {
            return cachedCell!
        }
        
        var c : UITableViewCell?
//        var b : BaseCartCell
        let r = indexPath.row
//        if (r == 1) {
//            b = tableView.dequeueReusableCellWithIdentifier("cell_input_2") as! CartCellInput2
//        } else {
//            b = tableView.dequeueReusableCellWithIdentifier("cell_input") as! CartCellInput
//        }
        
        var b = rawCells[r] as! BaseCartCell
        
        if (b.lastIndex != nil) {
            cellData[b.lastIndex!] = b.obtainValue()
        }
        
        b.lastIndex = indexPath
        b.adapt(cellData[indexPath])
        b.parent = self
        
        c = b
        
        cellViews[indexPath] = c!
        
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
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            // This will be crash on iOS 7.1
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
                    if (s == tableView!.numberOfSections) { // finish, last cell
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
        }
        return true
    }
    
    override func backPressed(sender: UIBarButtonItem) {
        if (free) {
            // Pop ke home, kemudian buka list belanjaan saya jika dari checkout
            if (self.fromCheckout) {
                NSUserDefaults.setObjectAndSync(PageName.MyOrders, forKey: UserDefaultsKey.RedirectFromHome)
            }
            self.navigationController?.popToRootViewControllerAnimated(true)
        } else {
            // Pop ke home, kemudian buka list konfirmasi bayar jika dari checkout
            if (self.fromCheckout) {
                NSUserDefaults.setObjectAndSync(PageName.UnpaidTransaction, forKey: UserDefaultsKey.RedirectFromHome)
            }
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    @IBAction func sendConfirm()
    {
        if (free)
        {
            // Pop ke home, kemudian buka list belanjaan saya jika dari checkout
            if (self.fromCheckout) {
                NSUserDefaults.setObjectAndSync(PageName.MyOrders, forKey: UserDefaultsKey.RedirectFromHome)
            }
            self.navigationController?.popToRootViewControllerAnimated(true)
            return
        }
        
        for k in cellViews.keys
        {
            let c = cellViews[k]!
            let same = c.isKindOfClass(BaseCartCell.classForCoder())
            if (same == true) {
                let b = c as! BaseCartCell
                cellData[b.lastIndex!] = b.obtainValue()
            }
        }
        
        var orderId = transactionId
        var bankTo = cellData[NSIndexPath(forRow: 1, inSection: 0)]
        var bankFrom = cellData[NSIndexPath(forRow: 2, inSection: 0)]
        var name = cellData[NSIndexPath(forRow: 3, inSection: 0)]
        var nominal = cellData[NSIndexPath(forRow: 4, inSection: 0)]
        
        if let f = bankFrom?.value, let t = bankTo?.value, let n = name?.value, let nom = nominal?.value
        {
            // Mixpanel
            let pt = [
                "Order ID" : orderId,
                "Destination Bank" : t,
                "Origin Bank" : f,
                "Amount" : nom
            ]
            Mixpanel.trackEvent(MixpanelEvent.PaymentClaimed, properties: pt)
            
            if (f == "" || t == "" || n == "" || nom == "")
            {
                UIAlertView.SimpleShow("Perhatian", message: "Silakan isi semua data")
                return
            }
            let x = (nom as NSString).integerValue
            // API Migrasi
        request(APITransaction2.ConfirmPayment(bankFrom: f, bankTo: t, name: n, nominal: x, orderId: orderId)).responseJSON {resp in
                if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Konfirmasi Bayar")) {
                    Constant.showDialog("Konfirmasi Bayar", message: "Terimakasih! Pembayaran kamu akan segera diverifikasi")
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
