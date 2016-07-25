//
//  ConfirmShippingViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/18/16.
//  Copyright (c) 2016 GITS Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class

class ConfirmShippingViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var consHeightContentView: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var consHeightTableView: NSLayoutConstraint!
    @IBOutlet weak var txtFldKurir: UITextField!
    @IBOutlet weak var txtFldNoResi: UITextField!
    @IBOutlet weak var imgResi: UIImageView!
    
    // Loading
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    // Variable from previous screen
    var trxDetail : TransactionDetail!
    
    // Data container
    var trxProductDetails : [TransactionProductDetail]!
    var isSelected : [Bool]!
    var isFirstAppearance : Bool = true
    var isPictSelected : Bool = false
    
    // Image picker
    var asset : ALAssetsLibrary?
    
    // Contact us view
    var contactUs : UIViewController?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Screen title
        self.title = "Konfirmasi Kirim/Tolak"
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Hide loading
        self.hideLoading()
        
        // Register custom cell
        let confirmShippingCellNib = UINib(nibName: "ConfirmShippingCell", bundle: nil)
        tableView.registerNib(confirmShippingCellNib, forCellReuseIdentifier: "ConfirmShippingCell")
        
        // Transaparent panel
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (isFirstAppearance) {
            isFirstAppearance = false
            trxProductDetails = trxDetail.transactionProducts
            if (trxProductDetails.count > 0) {
                // For default, all transaction product is set as selected
                isSelected = []
                for _ in 0 ..< trxProductDetails.count {
                    isSelected.append(true)
                }
                setupTable()
            }
        }
        
        self.an_subscribeKeyboardWithAnimations({ r, t, o in
            if (o) {
                self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
            } else {
                self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
        }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    // MARK: - TableView delegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trxDetail.transactionProducts.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (isSelected.count >= indexPath.row + 1) {
            if (isSelected[indexPath.row] == true) {
                return 102
            } else {
                return 178
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (trxProductDetails.count >= indexPath.row + 1) {
            let cell : ConfirmShippingCell = self.tableView.dequeueReusableCellWithIdentifier("ConfirmShippingCell") as! ConfirmShippingCell
            cell.selectionStyle = .None
            cell.adapt(trxProductDetails[indexPath.row], isSelected: self.isSelected[indexPath.row])
            cell.refreshTable = {
                self.isSelected[indexPath.row] = !self.isSelected[indexPath.row]
                self.setupTable()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Do nothing
    }
    
    // MARK: - UIImagePickerController functions
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imgResi.image = img
            self.isPictSelected = true
        }
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func btnResiPressed(sender: AnyObject) {
        let i = UIImagePickerController()
        i.sourceType = .PhotoLibrary
        i.delegate = self
        
        if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
            let a = UIAlertController(title: "Ambil gambar dari:", message: nil, preferredStyle: .ActionSheet)
            a.popoverPresentationController?.sourceView = self.imgResi
            a.popoverPresentationController?.sourceRect = self.imgResi.bounds
            a.addAction(UIAlertAction(title: "Kamera", style: .Default, handler: { act in
                i.sourceType = .Camera
                self.presentViewController(i, animated: true, completion: nil)
            }))
            a.addAction(UIAlertAction(title: "Album", style: .Default, handler: { act in
                self.presentViewController(i, animated: true, completion: nil)
            }))
            a.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { act in }))
            self.presentViewController(a, animated: true, completion: nil)
        } else {
            self.presentViewController(i, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnKonfKirimPressed(sender: AnyObject) {
        if (validateFields()) {
            self.showLoading()
            
            var sentTp : [String] = []
            let rejectedTp : NSMutableArray = []
            for i in 0 ..< trxProductDetails.count {
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! ConfirmShippingCell
                if (cell.isSelected == true) {
                    sentTp.append(trxProductDetails[i].id)
                } else {
                    let rTp = [
                        "tp_id" : trxProductDetails[i].id,
                        "reason" : cell.textView.text
                    ]
                    rejectedTp.insertObject(rTp, atIndex: 0)
                }
            }
            var confirmData = "{\"sent\":["
            for j in 0 ..< sentTp.count {
                let s = sentTp[j]
                confirmData += "\"\(s)\""
                if (j < sentTp.count - 1) {
                    confirmData += ","
                }
            }
            confirmData += "], \"rejected\":["
            for k in 0 ..< rejectedTp.count {
                let r : [String:String] = rejectedTp[k] as! [String : String]
                let rTpId = r["tp_id"]!
                let rReason = r["reason"]!
                confirmData += "{\"tp_id\": \"\(rTpId)\", \"reason\": \"\(rReason)\"}"
                if (k < rejectedTp.count - 1) {
                    confirmData += ","
                }
            }
            confirmData += "]}"
            
            let url = "\(AppTools.PreloBaseUrl)/api/new/transaction_products/confirm"
            let param = [
                "confirmation_data" : confirmData,
                "kurir" : self.txtFldKurir.text == nil ? "" : self.txtFldKurir.text!,
                "resi_number" : self.txtFldNoResi.text == nil ? "" : self.txtFldNoResi.text!
            ]
            var images : [UIImage] = []
            if let imgR = imgResi.image {
                images.append(imgR)
            }
            
            let userAgent : String? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.UserAgent) as? String
            
            AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, andUserAgent: userAgent!, to: url, success: { op, res in
                print("Confirm shipping res = \(res)")
                let json = JSON(res)
                let data = json["_data"].boolValue
                if (data == true) {
                    Constant.showDialog("Konfirmasi Kirim/Tolak", message: "Konfirmasi berhasil dilakukan")
                    self.navigationController?.popToRootViewControllerAnimated(true)
                } else {
                    Constant.showDialog("Konfirmasi Kirim/Tolak", message: "Gagal mengupload data")
                    self.hideLoading()
                }
            }, failure: { op, err in
                Constant.showDialog("Konfirmasi Kirim/Tolak", message: "Gagal mengupload data")
                self.hideLoading()
            })
        }
    }
    
    @IBAction func btnContactPreloPressed(sender: AnyObject) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let c = mainStoryboard.instantiateViewControllerWithIdentifier("contactus")
        self.contactUs = c
        if let v = c.view, let p = self.navigationController?.view {
            v.alpha = 0
            v.frame = p.bounds
            self.navigationController?.view.addSubview(v)
            
            v.alpha = 0
            UIView.animateWithDuration(0.2, animations: {
                v.alpha = 1
            })
        }
    }
    
    // MARK: - GestureRecognizer Functions
    
    @IBAction func disableTextFields(sender : AnyObject) {
        for i in 0 ..< trxProductDetails.count {
            let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! ConfirmShippingCell
            cell.textView.resignFirstResponder()
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKindOfClass(UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - Other functions
    
    func validateFields() -> Bool {
        var isAllRejected = true
        for i in 0 ..< isSelected.count {
            if (!isSelected[i]) {
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! ConfirmShippingCell
                if (cell.textView.text == "" || cell.textView.text == cell.TxtvwPlaceholder) {
                    Constant.showDialog("Warning", message: "Alasan tolak harus diisi")
                    return false
                }
            } else {
                isAllRejected = false
            }
        }
        if (!isAllRejected) {
            if (self.txtFldKurir.text == "") {
                Constant.showDialog("Warning", message: "Field kurir harus diisi")
                return false
            }
            if (self.txtFldNoResi.text == "") {
                Constant.showDialog("Warning", message: "Field nomor resi harus diisi")
                return false
            }
            if (!self.isPictSelected) {
                Constant.showDialog("Warning", message: "Harap melampirkan foto bukti resi")
                return false
            }
        }
        return true
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        tableView.reloadData()
        var height : CGFloat = 0
        for i in 0 ..< isSelected.count {
            height += self.tableView(tableView, heightForRowAtIndexPath: NSIndexPath(forRow: i, inSection: 0))
        }
        consHeightTableView.constant = height
        consHeightContentView.constant = height + 330
    }
    
    func hideLoading() {
        loadingPanel.hidden = true
        loading.hidden = true
        loading.stopAnimating()
    }
    
    func showLoading() {
        loadingPanel.hidden = false
        loading.hidden = false
        loading.startAnimating()
    }
}

// MARK: - Class

typealias RefreshTable = () -> ()

class ConfirmShippingCell: TransactionDetailProductCell, UITextViewDelegate {
    
    @IBOutlet weak var lblCheckbox: UILabel!
    @IBOutlet weak var vwTolak: UIView!
    @IBOutlet weak var textView: UITextView!
    var txtvwGrowHandler : GrowingTextViewHandler!
    @IBOutlet weak var consHeightTxtvw: NSLayoutConstraint!
    let TxtvwPlaceholder = "Tulis alasan kamu menolak pesanan."
    
    var isSelected : Bool!
    
    var refreshTable : RefreshTable = {}
    
    func adapt(trxProductDetail: TransactionProductDetail, isSelected : Bool) {
        super.adapt(trxProductDetail)
        
        // Set checkbox
        self.isSelected = isSelected
        self.setupCheckbox()
        
        // Configure textview
        textView.delegate = self
        textView.text = TxtvwPlaceholder
        textView.textColor = UIColor.lightGrayColor()
        txtvwGrowHandler = GrowingTextViewHandler(textView: textView, withHeightConstraint: consHeightTxtvw)
        txtvwGrowHandler.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 2)
    }
    
    @IBAction func cellTapped(sender: AnyObject) {
        isSelected = !isSelected
        self.setupCheckbox()
        self.refreshTable()
    }
    
    func setupCheckbox() {
        if (isSelected == true) {
            lblCheckbox.text = "";
            lblCheckbox.font = AppFont.Prelo2.getFont(19)!
            lblCheckbox.textColor = Theme.PrimaryColor
            
            // Hide vwTolak
            vwTolak.hidden = true
        } else {
            lblCheckbox.text = "";
            lblCheckbox.font = AppFont.PreloAwesome.getFont(24)!
            lblCheckbox.textColor = Theme.GrayLight
            
            // Show vwTolak
            vwTolak.hidden = false
        }
    }
    
    // MARK: - UITextViewDelegate functions
    
    func textViewDidBeginEditing(textView: UITextView) {
        if (textView.textColor == UIColor.lightGrayColor()) {
            textView.text = ""
            textView.textColor = Theme.GrayDark
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        txtvwGrowHandler.resizeTextViewWithAnimation(true)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if (textView.text.isEmpty) {
            textView.text = TxtvwPlaceholder
            textView.textColor = UIColor.lightGrayColor()
        }
    }
}