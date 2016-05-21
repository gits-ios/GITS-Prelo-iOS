//
//  OrderConfirmViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/7/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class OrderConfirmViewController: BaseViewController, UIScrollViewDelegate, UITextFieldDelegate, PickerViewDelegate {

    @IBOutlet var scrollView : UIScrollView!
    
    @IBOutlet var txtBankFrom : UITextField?
    @IBOutlet var txtAtasNama : UITextField?
    @IBOutlet var txtNominal : UITextField?
    @IBOutlet var captionOrderID2 : UILabel?
    @IBOutlet var captionSelectedBank : UILabel?
    
    @IBOutlet var captionBankInfoBankName : UILabel?
    @IBOutlet var captionBankInfoBankNumber : UILabel?
    @IBOutlet var captionBankInfoBankCabang : UILabel?
    @IBOutlet var captionBankInfoBankAtasNama : UILabel?
    
    @IBOutlet var sectionOptions : [BorderedView] = []
    @IBOutlet var firstTap : UITapGestureRecognizer!
    
//    @IBOutlet var tableView : UITableView?
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
    var kodeTransfer = 0
    
    let titleOrderID = "Order ID"
    let titleBankTujuan = "Bank Tujuan"
    let titleBankKamu = "Bank Kamu"
    let titleRekening = "Rekening Atas Nama"
    let titleNominal = "Nominal Transfer"
    
    var overBack = false
    var first = true
    
    var clearCart = false
    
    var rekenings = [
        ["name":"Fransiska PutriWinaHadiwidjana", "no":"06-404-72-677", "cabang":"Pucang Anom", "bank_name":"Bank BCA"],
        ["name":"Fransiska Putri Wina Hadiwidjana", "no":"131-007-304-1990", "cabang":"Cab. Bandung Dago", "bank_name":"Bank Mandiri"],
        ["name":"Fransiska Putri Wina Hadiwidjana", "no":"037-351-4488", "cabang":"Cab. Perguruan Tinggi Bandung", "bank_name":"Bank BNI"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        txtAtasNama?.delegate = self
        txtBankFrom?.delegate = self
        txtNominal?.delegate = self
        
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
        
        self.titleText = self.title
        
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
                v.removeFromSuperview()
            }
            
            captionDesc.text = "Kami segera memproses dan mengirim barang pesanan kamu. Silakan tunggu notifikasi Konfirmasi Pengiriman maximal 3 x 24 jam."
            cellData = [:]
            
            btnBack2.hidden = false
            
            self.btnBack2.superview?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[btn]-20-|", options: .AlignAllBaseline, metrics: nil, views: ["btn" : self.btnBack2]))
        } else
        {
            let text = "Lakukan pembayaran TEPAT hingga 3 digit terakhir. Perbedaan jumlah transfer akan memperlambat proses verifikasi."
            let mtext = NSMutableAttributedString(string: text)
            mtext.addAttributes([NSForegroundColorAttributeName:UIColor.darkGrayColor()], range: NSMakeRange(0, text.length))
            mtext.addAttributes([NSFontAttributeName:UIFont.boldSystemFontOfSize(14)], range: (text as NSString).rangeOfString("TEPAT"))
            mtext.addAttributes([NSFontAttributeName:UIFont.boldSystemFontOfSize(14)], range: (text as NSString).rangeOfString("3 digit terakhir"))
            captionDesc.attributedText = mtext
            
        }
        
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
        captionOrderTotal.text = (total + kodeTransfer).asPrice
        
        captionOrderID2?.text = orderID
        captionSelectedBank?.text = nil
        
        self.tapped(firstTap)
        
        let toolBar = UIToolbar(frame: CGRectMake(0, 0, 100, 44))
        toolBar.translucent = true
        toolBar.tintColor = Theme.PrimaryColor
        
        let done = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(OrderConfirmViewController.nominalDone))
        let space = UIBarButtonItem(barButtonSpaceType: .FlexibleSpace)
        toolBar.items = [space, done]
        txtNominal?.inputAccessoryView = toolBar
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
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
            } else {
                self.scrollView.contentInset = UIEdgeInsetsZero
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
    
    func nominalDone()
    {
        txtNominal?.resignFirstResponder()
    }
    
    @IBAction func copyPrice()
    {
        let s = String((total + kodeTransfer))
        UIPasteboard.generalPasteboard().string = s
        let a = UIAlertController(title: "Copied!", message: "Total harga sudah ada di clipboard!", preferredStyle: .Alert)
        a.addAction(UIAlertAction(title: "OK", style: .Default, handler: { act in }))
        self.presentViewController(a, animated: true, completion: nil)
    }
    
    @IBAction func tapped(sender : UITapGestureRecognizer)
    {
        let b = sender.view as! BorderedView
        
        for x in sectionOptions
        {
            x.borderColor = Theme.GrayLight
            for v in x.subviews
            {
                if (v.isKindOfClass(TintedImageView.classForCoder()))
                {
                    let t = v as! TintedImageView
                    t.tint = true
                    t.tintColor = Theme.GrayLight
                }
            }
        }
        
        b.borderColor = Theme.PrimaryColor
        for v in b.subviews
        {
            if (v.isKindOfClass(TintedImageView.classForCoder()))
            {
                let t = v as! TintedImageView
                t.tint = false
            }
        }
        
        setupViewRekeing(rekenings[b.tag])
    }
    
    func setupViewRekeing(data : [String : String])
    {
        captionBankInfoBankAtasNama?.text = data["name"]
        captionBankInfoBankCabang?.text = data["cabang"]
//        captionBankInfoBankCabang?.text = "alskjdalksjdlajsdlajd asldkjalsdkja sd lakdjsalks djalskdj alsdj alksdj alsdkj alksdjalk sjdalskdja"
        captionBankInfoBankName?.text = "Transfer melalui " + data["bank_name"]!
        captionBankInfoBankNumber?.text = data["no"]
    }
    
    @IBAction func selectBank()
    {
        let p = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = []
        p?.pickerDelegate = self
        p?.textTitle = "Bank Pilihan"
        p?.prepDataBlock = { picker in
            
            picker.items = ["Bank BCA", "Bank Mandiri", "Bank BNI"]
            picker.tableView.reloadData()
            
        }
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    func pickerDidSelect(item: String) {
        captionSelectedBank?.text = item
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if (textField == txtBankFrom)
        {
            txtAtasNama?.becomeFirstResponder()
        } else if (textField == txtAtasNama)
        {
            txtNominal?.becomeFirstResponder()
        }
        
        return false
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
                //NSUserDefaults.setObjectAndSync(PageName.UnpaidTransaction, forKey: UserDefaultsKey.RedirectFromHome)
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
        
        let orderId = transactionId
        let bankTo = captionSelectedBank?.text
        let bankFrom = txtBankFrom?.text
        let name = txtAtasNama?.text
        let nominal = txtNominal?.text
        
        if let f = bankFrom, let t = bankTo, let n = name, let nom = nominal
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
