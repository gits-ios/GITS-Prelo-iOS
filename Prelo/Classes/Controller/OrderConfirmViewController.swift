//
//  OrderConfirmViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/7/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

// MARK: - Class

class OrderConfirmViewController: BaseViewController, UIScrollViewDelegate, UITextFieldDelegate, PickerViewDelegate {

    // Main views
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var consHeightContentView: NSLayoutConstraint!
    @IBOutlet var vwTrxSummary: UIView!
    @IBOutlet var captionTitle : UILabel!
    @IBOutlet var captionOrderID : UILabel!
    @IBOutlet var captionOrderTotal : UILabel!
    @IBOutlet var captionMore : UILabel!
    @IBOutlet var img1 : UIImageView!
    @IBOutlet var img2 : UIImageView!
    @IBOutlet var img3 : UIImageView!
    @IBOutlet var imgs : [UIView] = []
    @IBOutlet var captionDesc : UILabel!
    @IBOutlet var btnFreeTrx : UIButton! // Back button (for free transaction)
    @IBOutlet var vwUnpaidTrx: UIView! // Views for unfree transaction
    @IBOutlet var sectionRekOptions : [BorderedView] = []
    @IBOutlet var btnDefaultBank: [UIButton]!
    @IBOutlet var vw3Banks: UIView!
    @IBOutlet var vw4Banks: UIView!
    @IBOutlet var captionBankInfoBankName : UILabel?
    @IBOutlet var captionBankInfoBankNumber : UILabel?
    @IBOutlet var captionBankInfoBankCabang : UILabel?
    @IBOutlet var captionBankInfoBankAtasNama : UILabel?
    
    // Payment pop up
    @IBOutlet var vwPaymentPopUp: UIView!
    @IBOutlet var lblBankTujuan: UILabel!
    @IBOutlet var fldNominalTrf: UITextField!
    @IBOutlet var consTopPaymentPopUp: NSLayoutConstraint!
    @IBOutlet var btnKirimPayment: UIButton!
    @IBOutlet var datePicker: UIDatePicker!
    
    // Flags
    var isFromCheckout = true
    var isFreeTransaction = false
    var isBackTwice = false
    var isNavCtrlsChecked = false
    var isShowBankBRI = false
    
    // Data from previous page
    var orderID : String = ""
    var transactionId : String = ""
    var images : [NSURL] = []
    var total : Int = 0
    var kodeTransfer = 0
    
    // Prelo account data
    var rekenings = [
        [
            "name":"KLEO APPARA INDONESIA PT",
            "no":"777-16-13-113",
            "cabang":"KCU Dago",
            "bank_name":"Bank BCA"
        ],
        [
            "name":"PT KLEO APPARA INDONESIA",
            "no":"131-0050-313-131",
            "cabang":"KCP Bandung Dago",
            "bank_name":"Bank Mandiri"
        ],
        [
            "name":"PT KLEO APPARA INDONESIA",
            "no":"042-390-6140",
            "cabang":"Perguruan Tinggi Bandung",
            "bank_name":"Bank BNI"
        ],
        [
            "name":"KLEO APPARA INDONESIA",
            "no":"040-501-000-570-304",
            "cabang":"Dago",
            "bank_name":"Bank BRI"
        ]
    ]
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        self.titleText = self.title
        
        // Delegate set
        scrollView.delegate = self
        
        // After checkout check
        if (isFromCheckout) {
            // Clear cart right after checkout
            let products = CartProduct.getAll(User.EmailOrEmptyString)
            for p in products {
                UIApplication.appDelegate.managedObjectContext.deleteObject(p)
            }
            UIApplication.appDelegate.saveContext()
        } else {
            // Hide unneeded caption title
            captionTitle.text = ""
            if var f = captionTitle.superview?.frame {
                f.size.height -= CGFloat(44)
                captionTitle.superview?.frame = f
            }
        }
        
        // Free transaction check
        isFreeTransaction = total == 0
        if (isFreeTransaction) {
            // Arrange views
            captionTitle.text = "Selamat! Transaksi kamu berhasil"
            captionDesc.text = "Kami segera memproses dan mengirim barang pesanan kamu. Silakan tunggu notifikasi Konfirmasi Pengiriman maximal 3 x 24 jam."
            self.vwUnpaidTrx.hidden = true
            self.btnFreeTrx.hidden = false
        } else {
            // Arrange views
            let text = "Lakukan pembayaran TEPAT hingga 3 digit terakhir. Perbedaan jumlah transfer akan memperlambat proses verifikasi."
            let mtext = NSMutableAttributedString(string: text)
            mtext.addAttributes([NSForegroundColorAttributeName:UIColor.darkGrayColor()], range: NSMakeRange(0, text.length))
            mtext.addAttributes([NSFontAttributeName:UIFont.boldSystemFontOfSize(14)], range: (text as NSString).rangeOfString("TEPAT"))
            mtext.addAttributes([NSFontAttributeName:UIFont.boldSystemFontOfSize(14)], range: (text as NSString).rangeOfString("3 digit terakhir"))
            captionDesc.attributedText = mtext
            self.vwUnpaidTrx.hidden = false
            self.btnFreeTrx.hidden = true
        }
        
        // Arrange product images
        for v in imgs {
            v.hidden = true
        }
        if (images.count > 0) {
            for i in (0...images.count - 1) {
                let v = imgs[i]
                v.hidden = false
                
                if (i < 3) {
                    let im = v as! UIImageView
                    im.setImageWithUrl(images[i], placeHolderImage: nil)
                } else if (i < 4) {
                    captionMore.text = String(images.count - 3) + "+"
                    break
                }
            }
        }
        
        // Order ID and Total price
        captionOrderID.text = orderID
        captionOrderTotal.text = (total + kodeTransfer).asPrice
        
        if (self.isShowBankBRI) {
            self.vw3Banks.hidden = true
            self.vw4Banks.hidden = false
        } else {
            self.vw3Banks.hidden = false
            self.vw4Banks.hidden = true
        }
        
        // Default active bank option
        for i in 0...btnDefaultBank.count - 1 {
            self.rekOptionsTapped(btnDefaultBank[i])
        }
        
        // Pop up init
        self.vwPaymentPopUp.backgroundColor = UIColor.colorWithColor(UIColor.blackColor(), alpha: 0.5)
        self.vwPaymentPopUp.hidden = true
        self.fldNominalTrf.text = "\(total + kodeTransfer)"
        
        // Date picker init
        datePicker.setValue(UIColor.darkGrayColor(), forKey: "textColor")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        let p = [
            "ID" : self.orderID,
            "Items" : "\(self.images.count)",
            "Price" : "\(self.total + self.kodeTransfer)"
        ]
        Mixpanel.trackPageVisit(PageName.PaymentConfirmation, otherParam: p)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.PaymentConfirmation)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Content view height
        self.consHeightContentView.constant = vwTrxSummary.height + (isFreeTransaction ? btnFreeTrx.height : vwUnpaidTrx.height) + 16
        
        // Back action handling
        if (!isNavCtrlsChecked && isBackTwice) {
            var x = self.navigationController?.viewControllers
            x?.removeAtIndex((x?.count)! - 2)
            if (x == nil) {
                x = []
            }
            self.navigationController?.setViewControllers(x!, animated: false)
            isNavCtrlsChecked = true
        }
        
        // Keyboard handling
        self.an_subscribeKeyboardWithAnimations({ r, t, o in
            if (o) {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                self.consTopPaymentPopUp.constant = 10
            } else {
                self.scrollView.contentInset = UIEdgeInsetsZero
                self.consTopPaymentPopUp.constant = 100
            }
        }, completion: nil)
        
        // Remove redirect alert if any
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let redirAlert = appDelegate.redirAlert {
            redirAlert.dismissWithClickedButtonIndex(-1, animated: true)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func copyPrice() {
        let s = String((total + kodeTransfer))
        UIPasteboard.generalPasteboard().string = s
        let a = UIAlertController(title: "Copied!", message: "Total harga sudah ada di clipboard!", preferredStyle: .Alert)
        a.addAction(UIAlertAction(title: "OK", style: .Default, handler: { act in }))
        self.presentViewController(a, animated: true, completion: nil)
    }
    
    @IBAction func rekOptionsTapped(sender: UIButton) {
        let b = sender.superview as! BorderedView
        
        for x in sectionRekOptions {
            x.borderColor = Theme.GrayLight
            for v in x.subviews {
                if (v.isKindOfClass(TintedImageView.classForCoder())) {
                    let t = v as! TintedImageView
                    t.tint = true
                    t.tintColor = Theme.GrayLight
                }
            }
        }
        
        b.borderColor = Theme.PrimaryColor
        for v in b.subviews {
            if (v.isKindOfClass(TintedImageView.classForCoder())) {
                let t = v as! TintedImageView
                t.tint = false
            }
        }
        
        setupViewRekening(rekenings[b.tag])
    }
    
    func setupViewRekening(data : [String : String]) {
        captionBankInfoBankAtasNama?.text = data["name"]
        captionBankInfoBankCabang?.text = data["cabang"]
        captionBankInfoBankName?.text = "Transfer melalui " + data["bank_name"]!
        captionBankInfoBankNumber?.text = data["no"]
    }
    
    override func backPressed(sender: UIBarButtonItem) {
        if (isFreeTransaction) {
            // Pop ke home, kemudian buka list belanjaan saya jika dari checkout
            if (self.isFromCheckout) {
                NSUserDefaults.setObjectAndSync(PageName.MyOrders, forKey: UserDefaultsKey.RedirectFromHome)
            }
            self.navigationController?.popToRootViewControllerAnimated(true)
        } else {
            // Pop ke home, kemudian buka list konfirmasi bayar jika dari checkout
            if (self.isFromCheckout) {
                //NSUserDefaults.setObjectAndSync(PageName.UnpaidTransaction, forKey: UserDefaultsKey.RedirectFromHome)
            }
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    @IBAction func lihatBelanjaanSayaPressed(sender: AnyObject) {
        NSUserDefaults.setObjectAndSync(PageName.MyOrders, forKey: UserDefaultsKey.RedirectFromHome)
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func showPaymentPopUp(sender: AnyObject) {
        self.vwPaymentPopUp.hidden = false
    }
    
    // MARK: - Pop up actions
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKindOfClass(UIButton.classForCoder()) || touch.view!.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    @IBAction func disableTextFields(sender : AnyObject) {
        fldNominalTrf.resignFirstResponder()
    }
    
    @IBAction func bankTujuanPressed(sender: AnyObject) {
        var bankOpt = ["BCA", "Mandiri", "BNI"]
        if (self.isShowBankBRI) {
            bankOpt.append("BRI")
        }
        let bankAlert = UIAlertController(title: "Pilih Bank", message: nil, preferredStyle: .ActionSheet)
        bankAlert.popoverPresentationController?.sourceView = sender as? UIView
        bankAlert.popoverPresentationController?.sourceRect = sender.bounds
        for i in 0...bankOpt.count - 1 {
            bankAlert.addAction(UIAlertAction(title: bankOpt[i], style: .Default, handler: { act in
                self.lblBankTujuan.text = bankOpt[i]
                bankAlert.dismissViewControllerAnimated(true, completion: nil)
            }))
        }
        bankAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { act in
            bankAlert.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(bankAlert, animated: true, completion: nil)
    }
    
    @IBAction func batalKonfPressed(sender: AnyObject) {
        self.vwPaymentPopUp.hidden = true
    }
    
    @IBAction func kirimKonfirmasiPressed(sender: AnyObject) {
        if (fldNominalTrf.text == nil || fldNominalTrf.text == "") {
            Constant.showDialog("Perhatian", message: "Nominal transfer harus diisi")
            return
        }
        btnKirimPayment.setTitle("MENGIRIM...", forState: .Normal)
        btnKirimPayment.userInteractionEnabled = false
        
        let timePaid = datePicker.date
        let timePaidFormatter = NSDateFormatter()
        timePaidFormatter.dateFormat = "EEEE, dd MMMM yyyy"
        let timePaidString = timePaidFormatter.stringFromDate(timePaid)
        
        // API Migrasi
        request(APITransaction2.ConfirmPayment(bankFrom: "", bankTo: self.lblBankTujuan.text!, name: "", nominal: Int(fldNominalTrf.text!)!, orderId: self.transactionId, timePaid: timePaidString)).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Konfirmasi Bayar")) {
                // Mixpanel
                let pt = [
                    "Order ID" : self.orderID,
                    "Destination Bank" : self.lblBankTujuan.text!,
                    "Origin Bank" : "",
                    "Amount" : self.fldNominalTrf.text!
                ]
                Mixpanel.trackEvent(MixpanelEvent.PaymentClaimed, properties: pt)
                
                Constant.showDialog("Konfirmasi Bayar", message: "Terimakasih! Pembayaran kamu akan segera diverifikasi")
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
            self.btnKirimPayment.setTitle("KIRIM KONFIRMASI", forState: .Normal)
            self.btnKirimPayment.userInteractionEnabled = true
        }
    }
}
