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
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var consHeightContentView: NSLayoutConstraint!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var consHeightTableView: NSLayoutConstraint!
    @IBOutlet var lblKurir: UILabel!
    @IBOutlet var lblDropdownKurir: UILabel!
    @IBOutlet var txtFldNoResi: UITextField!
    @IBOutlet var imgResi: UIImageView!
    @IBOutlet var consHeightVwKurirLainnya: NSLayoutConstraint!
    @IBOutlet var txtFldKurirLainnya: UITextField!
    
    // Loading
    @IBOutlet var loadingPanel: UIView!
    @IBOutlet var loading: UIActivityIndicatorView!
    
    // Predefined value
    var trxDetail : TransactionDetail!
    
    // Data container
    var trxProductDetails : [TransactionProductDetail]!
    var isCellSelected : [Bool]!
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
        tableView.register(confirmShippingCellNib, forCellReuseIdentifier: "ConfirmShippingCell")
        
        // Transaparent panel
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        // Hide kurir lainnya field
        self.hideFldKurirLainnya()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (isFirstAppearance) {
            isFirstAppearance = false
            trxProductDetails = trxDetail.transactionProducts
            if (trxProductDetails.count > 0) {
                // For default, all transaction product is set as selected
                isCellSelected = []
                for _ in 0 ..< trxProductDetails.count {
                    isCellSelected.append(true)
                }
                setupTable()
            }
        }
        
        self.an_subscribeKeyboard(animations: { r, t, o in
            if (o) {
                self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
            } else {
                self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
        }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func setDefaultKurir() {
        self.lblKurir.text = trxDetail.requestCourier.characters.split{$0 == "("}.map(String.init)[0]
    }
    
    // MARK: - TableView delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trxDetail.transactionProducts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (isCellSelected.count >= (indexPath as NSIndexPath).row + 1) {
            if (isCellSelected[(indexPath as NSIndexPath).row] == true) {
                return 102
            } else {
                return 178
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (trxProductDetails.count >= (indexPath as NSIndexPath).row + 1) {
            let cell : ConfirmShippingCell = self.tableView.dequeueReusableCell(withIdentifier: "ConfirmShippingCell") as! ConfirmShippingCell
            cell.selectionStyle = .none
            cell.adapt(trxProductDetails[(indexPath as NSIndexPath).row], isCellSelected: self.isCellSelected[(indexPath as NSIndexPath).row])
            cell.refreshTable = {
                self.isCellSelected[(indexPath as NSIndexPath).row] = !self.isCellSelected[(indexPath as NSIndexPath).row]
                self.setupTable()
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Do nothing
    }
    
    // MARK: - UIImagePickerController functions
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imgResi.image = img
            self.isPictSelected = true
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func btnKurirPressed(_ sender: AnyObject) {
        let kurirs = CDShipping.getAll()
        if (kurirs.count <= 0) {
            Constant.showDialog("Oops, gagal memproses data kurir", message: "Harap me-refresh data kurir melalui menu About > Reload App Data")
            return
        }
        let kurirAlert = UIAlertController(title: "Pilih Kurir", message: nil, preferredStyle: .actionSheet)
        kurirAlert.popoverPresentationController?.sourceView = self.lblDropdownKurir as UIView
        kurirAlert.popoverPresentationController?.sourceRect = self.lblDropdownKurir.bounds
        for i in 0..<kurirs.count {
            kurirAlert.addAction(UIAlertAction(title: kurirs[i].name, style: .default, handler: { act in
                self.lblKurir.text = kurirs[i].name
                self.hideFldKurirLainnya()
                kurirAlert.dismiss(animated: true, completion: nil)
            }))
        }
        kurirAlert.addAction(UIAlertAction(title: "Lainnya", style: .default, handler: { act in
            self.lblKurir.text = "Lainnya"
            self.showFldKurirLainnya()
            kurirAlert.dismiss(animated: true, completion: nil)
        }))
        self.present(kurirAlert, animated: true, completion: nil)
    }
    
    @IBAction func btnResiPressed(_ sender: AnyObject) {
        let i = UIImagePickerController()
        i.sourceType = .photoLibrary
        i.delegate = self
        
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            let a = UIAlertController(title: "Ambil gambar dari:", message: nil, preferredStyle: .actionSheet)
            a.popoverPresentationController?.sourceView = self.imgResi
            a.popoverPresentationController?.sourceRect = self.imgResi.bounds
            a.addAction(UIAlertAction(title: "Kamera", style: .default, handler: { act in
                i.sourceType = .camera
                self.present(i, animated: true, completion: nil)
            }))
            a.addAction(UIAlertAction(title: "Album", style: .default, handler: { act in
                self.present(i, animated: true, completion: nil)
            }))
            a.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { act in }))
            self.present(a, animated: true, completion: nil)
        } else {
            self.present(i, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnKonfKirimPressed(_ sender: AnyObject) {
        if (validateFields()) {
            self.showLoading()
            
            var sentTp : [String] = []
            let rejectedTp : NSMutableArray = []
            for i in 0 ..< trxProductDetails.count {
                let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! ConfirmShippingCell
                if (cell.isCellSelected == true) {
                    sentTp.append(trxProductDetails[i].id)
                } else {
                    let rTp = [
                        "tp_id" : trxProductDetails[i].id,
                        "reason" : cell.textView.text
                    ] as [String : Any]
                    rejectedTp.insert(rTp, at: 0)
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
                "kurir" : self.lblKurir.text?.lowercased() != "lainnya" ? self.lblKurir.text! : self.txtFldKurirLainnya.text!,
                "resi_number" : self.txtFldNoResi.text == nil ? "" : self.txtFldNoResi.text!
            ]
            var images : [UIImage] = []
            if let imgR = imgResi.image {
                images.append(imgR)
            }
            
            let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
            
            AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, andUserAgent: userAgent!, to: url, success: { op, res in
                print("Confirm shipping res = \(res)")
                let json = JSON(res)
                let data = json["_data"].boolValue
                if (data == true) {
                    Constant.showDialog("Konfirmasi Kirim/Tolak", message: "Konfirmasi berhasil dilakukan")
                    self.navigationController?.popToRootViewController(animated: true)
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
    
    @IBAction func btnContactPreloPressed(_ sender: AnyObject) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let c = mainStoryboard.instantiateViewController(withIdentifier: "contactus")
        self.contactUs = c
        if let v = c.view, let p = self.navigationController?.view {
            v.alpha = 0
            v.frame = p.bounds
            self.navigationController?.view.addSubview(v)
            
            v.alpha = 0
            UIView.animate(withDuration: 0.2, animations: {
                v.alpha = 1
            })
        }
    }
    
    // MARK: - GestureRecognizer Functions
    
    @IBAction func disableTextFields(_ sender : AnyObject) {
        for i in 0 ..< trxProductDetails.count {
            let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! ConfirmShippingCell
            cell.textView.resignFirstResponder()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: - Other functions
    
    func validateFields() -> Bool {
        var isAllRejected = true
        for i in 0 ..< isCellSelected.count {
            if (!isCellSelected[i]) {
                let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! ConfirmShippingCell
                if (cell.textView.text == "" || cell.textView.text == cell.TxtvwPlaceholder) {
                    Constant.showDialog("Warning", message: "Alasan tolak harus diisi")
                    return false
                }
            } else {
                isAllRejected = false
            }
        }
        if (!isAllRejected) {
            if (self.lblKurir.text == "") {
                Constant.showDialog("Warning", message: "Field kurir harus diisi")
                return false
            }
            if (self.lblKurir.text?.lowercased() == "lainnya" && (txtFldKurirLainnya.text == nil || txtFldKurirLainnya.text == "")) {
                Constant.showDialog("Warning", message: "Field nama kurir harus diisi")
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
        for i in 0 ..< isCellSelected.count {
            height += self.tableView(tableView, heightForRowAt: IndexPath(row: i, section: 0))
        }
        consHeightTableView.constant = height
        consHeightContentView.constant = height + 330
    }
    
    func hideLoading() {
        loadingPanel.isHidden = true
        loading.isHidden = true
        loading.stopAnimating()
    }
    
    func showLoading() {
        loadingPanel.isHidden = false
        loading.isHidden = false
        loading.startAnimating()
    }
    
    func hideFldKurirLainnya() {
        consHeightVwKurirLainnya.constant = 0
    }
    
    func showFldKurirLainnya() {
        consHeightVwKurirLainnya.constant = 55
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
    
    var isCellSelected : Bool!
    
    var refreshTable : RefreshTable = {}
    
    func adapt(_ trxProductDetail: TransactionProductDetail, isCellSelected : Bool) {
        super.adapt(trxProductDetail)
        
        // Set checkbox
        self.isCellSelected = isCellSelected
        self.setupCheckbox()
        
        // Configure textview
        textView.delegate = self
        textView.text = TxtvwPlaceholder
        textView.textColor = UIColor.lightGray
        txtvwGrowHandler = GrowingTextViewHandler(textView: textView, withHeightConstraint: consHeightTxtvw)
        txtvwGrowHandler.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 2)
    }
    
    @IBAction func cellTapped(_ sender: AnyObject) {
        isCellSelected = !isCellSelected
        self.setupCheckbox()
        self.refreshTable()
    }
    
    func setupCheckbox() {
        if (isCellSelected == true) {
            lblCheckbox.text = "";
            lblCheckbox.font = AppFont.prelo2.getFont(19)!
            lblCheckbox.textColor = Theme.PrimaryColor
            
            // Hide vwTolak
            vwTolak.isHidden = true
        } else {
            lblCheckbox.text = "";
            lblCheckbox.font = AppFont.preloAwesome.getFont(24)!
            lblCheckbox.textColor = Theme.GrayLight
            
            // Show vwTolak
            vwTolak.isHidden = false
        }
    }
    
    // MARK: - UITextViewDelegate functions
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView.textColor == UIColor.lightGray) {
            textView.text = ""
            textView.textColor = Theme.GrayDark
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        txtvwGrowHandler.resizeTextView(withAnimation: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView.text.isEmpty) {
            textView.text = TxtvwPlaceholder
            textView.textColor = UIColor.lightGray
        }
    }
}
