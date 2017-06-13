//
//  OrderConfirmViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/7/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Alamofire

// MARK: - Class

class OrderConfirmViewController: BaseViewController, UIScrollViewDelegate, UITextFieldDelegate, PickerViewDelegate {

    // Main views
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var consHeightContentView: NSLayoutConstraint!
    @IBOutlet weak var vwTrxSummary: UIView!
    @IBOutlet weak var captionTitle : UILabel!
    @IBOutlet weak var captionOrderID : UILabel!
    @IBOutlet weak var captionOrderTotal : UILabel!
    @IBOutlet weak var captionMore : UILabel!
    @IBOutlet weak var img1 : UIImageView!
    @IBOutlet weak var img2 : UIImageView!
    @IBOutlet weak var img3 : UIImageView!
    @IBOutlet var imgs : [UIView] = []
    @IBOutlet weak var captionDesc : UILabel!
    @IBOutlet weak var btnFreeTrx : UIButton! // Back button (for free transaction)
    @IBOutlet weak var vwUnpaidTrx: UIView! // Views for unfree transaction
    @IBOutlet var sectionRekOptions : [BorderedView] = []
    @IBOutlet weak var btnDefault3Banks: UIButton!
    @IBOutlet weak var btnDefault4Banks: UIButton!
    @IBOutlet weak var vw3Banks: UIView!
    @IBOutlet weak var vw4Banks: UIView!
    @IBOutlet weak var captionBankInfoBankName : UILabel?
    @IBOutlet weak var captionBankInfoBankNumber : UILabel?
    @IBOutlet weak var captionBankInfoBankCabang : UILabel?
    @IBOutlet weak var captionBankInfoBankAtasNama : UILabel?
    @IBOutlet weak var consHeightBankInfo: NSLayoutConstraint!
    
    // Payment pop up
    @IBOutlet weak var vwPaymentPopUp: UIView!
    @IBOutlet weak var lblBankTujuan: UILabel!
    @IBOutlet weak var fldNominalTrf: UITextField!
    //@IBOutlet weak var consTopPaymentPopUp: NSLayoutConstraint!
    @IBOutlet weak var consCenteryPaymentPopUp: NSLayoutConstraint!
    @IBOutlet weak var btnKirimPayment: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // Flags
    var isFromCheckout = true
    var isFreeTransaction = false
    var isBackTwice = false
    var isNavCtrlsChecked = false
    var isShowBankBRI = false
    var isBackToRoot = true
    var isMidtrans = false
    
    // Data from previous page
    var orderID : String = ""
    var transactionId : String = ""
    var images : [URL] = []
    var total : Int64 = 0
    var kodeTransfer : Int64 = 0
    
    // new UI
    var targetBank : String!
    @IBOutlet weak var vw1Bank: UIView!
    @IBOutlet weak var imgSelectedBank: TintedImageView! // -> setup image
    @IBOutlet weak var lblDropdownBank: UILabel! // -> hidden
    @IBOutlet weak var btnDropdownBank: UIButton! // -> hidden
    @IBOutlet weak var consTraillingLblDropdownBank: NSLayoutConstraint! // 0 -> -22
    
    var date : String?
    var remaining : Int = 24
    
    // Prelo account data
    var rekenings = [
        [
            "name":"KLEO APPARA INDONESIA PT",
            "no":"777-16-13-113 ",
            "cabang":"KCU Dago",
            "bank_name":"BCA",
            "icon":"rsz_ic_bca@2x"
        ],
        /*[
            "name":"PT KLEO APPARA INDONESIA",
            "no":"131-0050-313-131 ",
            "cabang":"KCP Bandung Dago",
            "bank_name":"Mandiri",
            "icon":"rsz_ic_mandiri@2x"
        ],*/
        [
            "name":"PT KLEO APPARA INDONESIA",
            "no":"131-003-3111-313 ",
            "cabang":"KCP Bandung Dago",
            "bank_name":"Mandiri",
            "icon":"rsz_ic_mandiri@2x"
        ],
        [
            "name":"PT KLEO APPARA INDONESIA",
            "no":"042-390-6140 ",
            "cabang":"Perguruan Tinggi Bandung",
            "bank_name":"BNI",
            "icon":"rsz_ic_bni@2x"
        ],
        [
            "name":"KLEO APPARA INDONESIA",
            "no":"040-501-000-570-304 ",
            "cabang":"Dago",
            "bank_name":"BRI",
            "icon":"rsz_ic_bri@2x"
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
        if (isMidtrans) {
            // Arrange views
            captionTitle.text = "Selamat! Transaksi kamu berhasil."
            captionDesc.text = ""
            self.vwUnpaidTrx.isHidden = true
            self.btnFreeTrx.isHidden = false
        } else if (isFreeTransaction) {
            // Arrange views
            captionTitle.text = "Selamat! Transaksi kamu berhasil."
            captionDesc.text = "Kami segera memproses dan mengirim barang pesanan kamu. Silakan tunggu notifikasi Konfirmasi Pengiriman maximal 3 x 24 jam."
            self.vwUnpaidTrx.isHidden = true
            self.btnFreeTrx.isHidden = false
        } else {
            let date = Date().dateByAddingDays(1) // tomorrow after expire or after now
            let f = DateFormatter()
            f.dateFormat = "dd/MM/yyyy HH:mm:ss"
            let time = f.string(from: date)
            // Arrange views
            let text = "Lakukan pembayaran TEPAT hingga 3 digit terakhir dalam waktu " + remaining.string + " jam (" + (self.date != nil ? self.date! : time) + ") ke " + (targetBank != nil && targetBank != "" ? "" : "salah satu ") + "rekening di bawah. Perbedaan jumlah transfer akan memperlambat proses verifikasi."
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
        
        // new UI
        if (targetBank != nil && targetBank != "") {
            self.vw3Banks.isHidden = true
            self.vw4Banks.isHidden = true
            
            self.vw1Bank.isHidden = false
            
            for i in 0...rekenings.count - 1 {
                if (rekenings[i]["bank_name"] == targetBank) {
                    self.imgSelectedBank.image = UIImage(named: rekenings[i]["icon"]!)
                    self.setupViewRekening(rekenings[i])
                    self.lblBankTujuan.text = targetBank
                    break
                }
            }
            
            self.lblDropdownBank.isHidden = true
            self.btnDropdownBank.isHidden = true
            self.consTraillingLblDropdownBank.constant = -22 // hide this
        }
        else {
            self.vw1Bank.isHidden = true
            
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
        }
        
        // Pop up init
        self.vwPaymentPopUp.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.5)
        self.vwPaymentPopUp.isHidden = true
        self.fldNominalTrf.text = "\(total + kodeTransfer)"
        
        // Date picker init
        datePicker.setValue(UIColor.darkGray, forKey: "textColor")
        
        // copy rek number
        self.captionBankInfoBankNumber?.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(OrderConfirmViewController.tapFunction))
        self.captionBankInfoBankNumber?.addGestureRecognizer(tap)
        
        let content = self.captionBankInfoBankNumber?.text!
        let attrStr = NSMutableAttributedString(string: content!)
        attrStr.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColor], range: (content! as NSString).range(of: ""))
        attrStr.addAttributes([NSFontAttributeName:UIFont(name: "preloAwesome", size: 14.0)!], range: (content! as NSString).range(of: ""))
        self.captionBankInfoBankNumber?.attributedText = attrStr
        
        self.captionBankInfoBankName?.isHidden = true
        self.consHeightBankInfo.constant = 0

        // swipe gesture for carbon (pop view)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        
        let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
        vwLeft.backgroundColor = UIColor.clear
        vwLeft.addGestureRecognizer(swipeRight)
        self.view.addSubview(vwLeft)
        self.view.bringSubview(toFront: vwLeft)
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
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        // Content view height
        self.consHeightContentView.constant = vwTrxSummary.height + (isFreeTransaction ? btnFreeTrx.height : vwUnpaidTrx.height) + 16
        
        /*
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
         */
        
        // Keyboard handling
        self.an_subscribeKeyboard(animations: { r, t, o in
            if (o) {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                //self.consTopPaymentPopUp.constant = 10
                self.consCenteryPaymentPopUp.constant = -(r.height / 2)
            } else {
                self.scrollView.contentInset = UIEdgeInsets.zero
                //self.consTopPaymentPopUp.constant = 100
                self.consCenteryPaymentPopUp.constant = 0
            }
        }, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // fixer
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    // MARK: - Actions
    
    func tapFunction(sender:MyTapGestureRecognizer) {
        let bankName = self.captionBankInfoBankName?.text
        Constant.showDialog("Copied!", message: "Nomor Rekening \(bankName!) telah disalin ke clipboard!")
        let textToCopy = self.captionBankInfoBankNumber?.text?.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: NSCharacterSet (charactersIn: " ") as CharacterSet )
        UIPasteboard.general.string = textToCopy
    }
    
    @IBAction func copyPrice() {
        let s = String((total + kodeTransfer))
        UIPasteboard.general.string = s
        Constant.showDialog("Copied!", message: "Total harga telah disalin ke clipboard!")
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
        captionBankInfoBankName?.text = "Bank \(data["bank_name"]!)" // "Transfer melalui Bank " + data["bank_name"]!
        captionBankInfoBankNumber?.text = data["no"]
        
        let content = self.captionBankInfoBankNumber?.text!
        let attrStr = NSMutableAttributedString(string: content!)
        attrStr.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColor], range: (content! as NSString).range(of: ""))
        attrStr.addAttributes([NSFontAttributeName:UIFont(name: "preloAwesome", size: 14.0)!], range: (content! as NSString).range(of: ""))
        self.captionBankInfoBankNumber?.attributedText = attrStr
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        if let count = self.navigationController?.viewControllers.count, count > 3 && isBackTwice {
            //_ = self.navigationController?.popToViewController((self.navigationController?.viewControllers[count-3])!, animated: true)
            
            let navController = self.navigationController!
            var controllers = navController.viewControllers
            controllers.removeLast()
            controllers.removeLast()
            
            navController.setViewControllers(controllers, animated: false)
            
            let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
            
            navController.pushViewController(myPurchaseVC, animated: true)
        }
        if (isBackToRoot) {
            _ = self.navigationController?.popToRootViewController(animated: true)
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
        
        /*
        if (isFreeTransaction) {
            // Pop ke home, kemudian buka list belanjaan saya jika dari checkout
            if (self.isFromCheckout) {
//                UserDefaults.setObjectAndSync(PageName.MyOrders as AnyObject?, forKey: UserDefaultsKey.RedirectFromHome)
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
         */
    }
    
    @IBAction func lihatBelanjaanSayaPressed(_ sender: AnyObject) {
        UserDefaults.setObjectAndSync(PageName.MyOrders as AnyObject?, forKey: UserDefaultsKey.RedirectFromHome)
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func showPaymentPopUp(_ sender: AnyObject) {
        self.vwPaymentPopUp.isHidden = false
    }
    
    // MARK: - Swipe Navigation Override
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                //print("Swiped right")
                
                // gesture override
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                
                if let count = self.navigationController?.viewControllers.count, count > 3 && isBackTwice {
                    //_ = self.navigationController?.popToViewController((self.navigationController?.viewControllers[count-3])!, animated: true)
                    
                    let navController = self.navigationController!
                    var controllers = navController.viewControllers
                    controllers.removeLast()
                    controllers.removeLast()
                    
                    navController.setViewControllers(controllers, animated: false)
                    
                    let myPurchaseVC = Bundle.main.loadNibNamed(Tags.XibNameMyPurchaseTransaction, owner: nil, options: nil)?.first as! MyPurchaseTransactionViewController
                    
                    navController.pushViewController(myPurchaseVC, animated: true)
                }
                if (isBackToRoot) {
                    _ = self.navigationController?.popToRootViewController(animated: true)
                } else {
                    _ = self.navigationController?.popViewController(animated: true)
                }
                
            default:
                break
            }
        }
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
        bankAlert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in
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
        let _ = request(APITransaction.confirmPayment(bankFrom: "", bankTo: self.lblBankTujuan.text!, name: "", nominal: Int64(fldNominalTrf.text!)!, orderId: self.transactionId, timePaid: timePaidString)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Konfirmasi Bayar")) {
                /*
                // Mixpanel
                let pt = [
                    "Order ID" : self.orderID,
                    "Destination Bank" : self.lblBankTujuan.text!,
                    "Origin Bank" : "",
                    "Amount" : self.fldNominalTrf.text!
                ]
                Mixpanel.trackEvent(MixpanelEvent.PaymentClaimed, properties: pt)
                */
                
                // Prelo Analytic - Claim Payment
                let loginMethod = User.LoginMethod ?? ""
                let pdata = [
                    "Order ID" : self.orderID,
                    "Destination Bank" : self.lblBankTujuan.text!,
                    "Amount" : self.fldNominalTrf.text!
                ] as [String : Any]
                AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ClaimPayment, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
                
                // reduce badge troli
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let notifListener = appDelegate.preloNotifListener
                notifListener?.increaseCartCount(-1)
                
                Constant.showDialog("Konfirmasi Bayar", message: "Terimakasih! Pembayaran kamu akan segera diverifikasi")
                
                // gesture override
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                
                _ = self.navigationController?.popToRootViewController(animated: true)
            }
            self.btnKirimPayment.setTitle("KIRIM KONFIRMASI", for: UIControlState())
            self.btnKirimPayment.isUserInteractionEnabled = true
        }
    }
}
