//
//  OrderConfirmViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/7/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Alamofire

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
    @IBOutlet var btnDefault3Banks: UIButton!
    @IBOutlet var btnDefault4Banks: UIButton!
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
    var isBackToRoot = true
    
    // Data from previous page
    var orderID : String = ""
    var transactionId : String = ""
    var images : [URL] = []
    var total : Int = 0
    var kodeTransfer = 0
    
    // Prelo account data
    var rekenings = [
        [
            "name":"KLEO APPARA INDONESIA PT",
            "no":"777-16-13-113",
            "cabang":"KCU Dago",
            "bank_name":"BCA"
        ],
        [
            "name":"PT KLEO APPARA INDONESIA",
            "no":"131-0050-313-131",
            "cabang":"KCP Bandung Dago",
            "bank_name":"Mandiri"
        ],
        [
            "name":"PT KLEO APPARA INDONESIA",
            "no":"042-390-6140",
            "cabang":"Perguruan Tinggi Bandung",
            "bank_name":"BNI"
        ],
        [
            "name":"KLEO APPARA INDONESIA",
            "no":"040-501-000-570-304",
            "cabang":"Dago",
            "bank_name":"BRI"
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
                UIApplication.appDelegate.managedObjectContext.delete(p)
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
            self.vwUnpaidTrx.isHidden = true
            self.btnFreeTrx.isHidden = false
        } else {
            // Arrange views
            let text = "Lakukan pembayaran TEPAT hingga 3 digit terakhir. Perbedaan jumlah transfer akan memperlambat proses verifikasi."
            let mtext = NSMutableAttributedString(string: text)
            mtext.addAttributes([NSForegroundColorAttributeName:UIColor.darkGray], range: NSMakeRange(0, text.length))
            mtext.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)], range: (text as NSString).range(of: "TEPAT"))
            mtext.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)], range: (text as NSString).range(of: "3 digit terakhir"))
            captionDesc.attributedText = mtext
            self.vwUnpaidTrx.isHidden = false
            self.btnFreeTrx.isHidden = true
        }
        
        // Arrange product images
        for v in imgs {
            v.isHidden = true
        }
        if (images.count > 0) {
            for i in (0...images.count - 1) {
                let v = imgs[i]
                v.isHidden = false
                
                if (i < 3) {
                    let im = v as! UIImageView
                    im.afSetImage(withURL: images[i])
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
            self.vw3Banks.isHidden = true
            self.vw4Banks.isHidden = false
        } else {
            self.vw3Banks.isHidden = false
            self.vw4Banks.isHidden = true
        }
        
        // Default active bank option
        if (isShowBankBRI) {
            self.rekOptionsTapped(btnDefault4Banks)
        } else {
            self.rekOptionsTapped(btnDefault3Banks)
        }
        
        // Pop up init
        self.vwPaymentPopUp.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.5)
        self.vwPaymentPopUp.isHidden = true
        self.fldNominalTrf.text = "\(total + kodeTransfer)"
        
        // Date picker init
        datePicker.setValue(UIColor.darkGray, forKey: "textColor")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
//        let p = [
//            "ID" : self.orderID,
//            "Items" : "\(self.images.count)",
//            "Price" : "\(self.total + self.kodeTransfer)"
//        ]
//        Mixpanel.trackPageVisit(PageName.PaymentConfirmation, otherParam: p)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.PaymentConfirmation)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Content view height
        self.consHeightContentView.constant = vwTrxSummary.height + (isFreeTransaction ? btnFreeTrx.height : vwUnpaidTrx.height) + 16
        
        // Back action handling
        if (!isNavCtrlsChecked && isBackTwice) {
            var x = self.navigationController?.viewControllers
            x?.remove(at: (x?.count)! - 2)
            if (x == nil) {
                x = []
            }
            self.navigationController?.setViewControllers(x!, animated: false)
            isNavCtrlsChecked = true
        }
        
        // Keyboard handling
        self.an_subscribeKeyboard(animations: { r, t, o in
            if (o) {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                self.consTopPaymentPopUp.constant = 10
            } else {
                self.scrollView.contentInset = UIEdgeInsets.zero
                self.consTopPaymentPopUp.constant = 100
            }
        }, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func copyPrice() {
        let s = String((total + kodeTransfer))
        UIPasteboard.general.string = s
        let a = UIAlertController(title: "Copied!", message: "Total harga sudah ada di clipboard!", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default, handler: { act in }))
        self.present(a, animated: true, completion: nil)
    }
    
    @IBAction func rekOptionsTapped(_ sender: UIButton) {
        let b = sender.superview as! BorderedView
        
        for x in sectionRekOptions {
            x.borderColor = Theme.GrayLight
            for v in x.subviews {
                if (v.isKind(of: TintedImageView.classForCoder())) {
                    let t = v as! TintedImageView
                    t.tint = true
                    t.tintColor = Theme.GrayLight
                }
            }
        }
        
        b.borderColor = Theme.PrimaryColor
        for v in b.subviews {
            if (v.isKind(of: TintedImageView.classForCoder())) {
                let t = v as! TintedImageView
                t.tint = false
            }
        }
        
        setupViewRekening(rekenings[b.tag])
        
        // Set label in pop up
        self.lblBankTujuan.text = rekenings[b.tag]["bank_name"]
    }
    
    func setupViewRekening(_ data : [String : String]) {
        captionBankInfoBankAtasNama?.text = data["name"]
        captionBankInfoBankCabang?.text = data["cabang"]
        captionBankInfoBankName?.text = "Transfer melalui Bank " + data["bank_name"]!
        captionBankInfoBankNumber?.text = data["no"]
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        if (isFreeTransaction) {
            // Pop ke home, kemudian buka list belanjaan saya jika dari checkout
            if (self.isFromCheckout) {
                UserDefaults.setObjectAndSync(PageName.MyOrders as AnyObject?, forKey: UserDefaultsKey.RedirectFromHome)
            }
            if (isBackToRoot) {
                _ = self.navigationController?.popToRootViewController(animated: true)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        } else {
            // Pop ke home, kemudian buka list konfirmasi bayar jika dari checkout
            if (self.isFromCheckout) {
                //NSUserDefaults.setObjectAndSync(PageName.UnpaidTransaction, forKey: UserDefaultsKey.RedirectFromHome)
            }
            if (isBackToRoot) {
                _ = self.navigationController?.popToRootViewController(animated: true)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func lihatBelanjaanSayaPressed(_ sender: AnyObject) {
        UserDefaults.setObjectAndSync(PageName.MyOrders as AnyObject?, forKey: UserDefaultsKey.RedirectFromHome)
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func showPaymentPopUp(_ sender: AnyObject) {
        self.vwPaymentPopUp.isHidden = false
    }
    
    // MARK: - Pop up actions
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    @IBAction func disableTextFields(_ sender : AnyObject) {
        fldNominalTrf.resignFirstResponder()
    }
    
    @IBAction func bankTujuanPressed(_ sender: AnyObject) {
        let bankCount = rekenings.count - (isShowBankBRI ? 0 : 1)
        let bankAlert = UIAlertController(title: "Pilih Bank", message: nil, preferredStyle: .actionSheet)
        bankAlert.popoverPresentationController?.sourceView = sender as? UIView
        bankAlert.popoverPresentationController?.sourceRect = sender.bounds
        for i in 0...bankCount - 1 {
            bankAlert.addAction(UIAlertAction(title: rekenings[i]["bank_name"], style: .default, handler: { act in
                self.lblBankTujuan.text = self.rekenings[i]["bank_name"]
                bankAlert.dismiss(animated: true, completion: nil)
            }))
        }
        bankAlert.addAction(UIAlertAction(title: "Batal", style: .destructive, handler: { act in
            bankAlert.dismiss(animated: true, completion: nil)
        }))
        self.present(bankAlert, animated: true, completion: nil)
    }
    
    @IBAction func batalKonfPressed(_ sender: AnyObject) {
        self.vwPaymentPopUp.isHidden = true
    }
    
    @IBAction func kirimKonfirmasiPressed(_ sender: AnyObject) {
        if (fldNominalTrf.text == nil || fldNominalTrf.text == "") {
            Constant.showDialog("Perhatian", message: "Nominal transfer harus diisi")
            return
        }
        
        let timePaid = datePicker.date
        
        if timePaid.compare(Date()).rawValue > 0 {
            Constant.showDialog("Perhatian", message: "Tanggal transfer tidak boleh melebihi hari ini")
            return
        }
        
        btnKirimPayment.setTitle("MENGIRIM...", for: UIControlState())
        btnKirimPayment.isUserInteractionEnabled = false
        
        let timePaidFormatter = DateFormatter()
        timePaidFormatter.dateFormat = "EEEE, dd MMMM yyyy"
        let timePaidString = timePaidFormatter.string(from: timePaid)
        
        // API Migrasi
        let _ = request(APITransaction.confirmPayment(bankFrom: "", bankTo: self.lblBankTujuan.text!, name: "", nominal: Int(fldNominalTrf.text!)!, orderId: self.transactionId, timePaid: timePaidString)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Konfirmasi Bayar")) {
                // Mixpanel
                let pt = [
                    "Order ID" : self.orderID,
                    "Destination Bank" : self.lblBankTujuan.text!,
                    "Origin Bank" : "",
                    "Amount" : self.fldNominalTrf.text!
                ]
                Mixpanel.trackEvent(MixpanelEvent.PaymentClaimed, properties: pt)
                
                Constant.showDialog("Konfirmasi Bayar", message: "Terimakasih! Pembayaran kamu akan segera diverifikasi")
                self.navigationController?.popToRootViewController(animated: true)
            }
            self.btnKirimPayment.setTitle("KIRIM KONFIRMASI", for: UIControlState())
            self.btnKirimPayment.isUserInteractionEnabled = true
        }
    }
}
