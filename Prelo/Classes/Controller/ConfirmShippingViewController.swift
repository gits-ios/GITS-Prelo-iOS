//
//  ConfirmShippingViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/18/16.
//  Copyright (c) 2016 GITS Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class

class ConfirmShippingViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
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
    @IBOutlet var vwKurirResiFields: UIView!
    @IBOutlet var consHeightVwKurirResiFields: NSLayoutConstraint!
    @IBOutlet var consHeightLblDesc: NSLayoutConstraint!
    
    // Loading
    @IBOutlet var loadingPanel: UIView!
    @IBOutlet var loading: UIActivityIndicatorView!
    
    // Predefined value
    // For confirm shipping
    var trxDetail : TransactionDetail!
    // For refund
    var isRefundMode : Bool = false
    var tpId : String = ""
    
    // Data container
    var trxProductDetails : [TransactionProductDetail]!
    var isCellSelected : [Bool]!
    var selectedAvailabilities : [ConfirmShippingAvailability?]!
    var isFirstAppearance : Bool = true
    var isPictSelected : Bool = false
    
    // Contact us view
    var contactUs : UIViewController?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let confirmShippingCellNib = UINib(nibName: "ConfirmShippingCell", bundle: nil)
        tableView.register(confirmShippingCellNib, forCellReuseIdentifier: "ConfirmShippingCell")
        
        // Hide kurir lainnya field
        self.hideFldKurirLainnya()
        
        // Delegate
        self.txtFldNoResi.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (isRefundMode) {
            self.title = "Konfirmasi Pengembalian"
            self.consHeightTableView.constant = 0
            self.consHeightLblDesc.constant = 0
        } else {
            self.title = "Konfirmasi Kirim/Tolak"
            if (isFirstAppearance) {
                isFirstAppearance = false
                trxProductDetails = trxDetail.transactionProducts
                if (trxProductDetails.count > 0) {
                    // For default, all transaction product is set as selected
                    // All selected availability is nil
                    isCellSelected = []
                    selectedAvailabilities = []
                    for _ in 0 ..< trxProductDetails.count {
                        isCellSelected.append(true)
                        selectedAvailabilities.append(nil)
                    }
                    setupTable()
                }
            }
        }
        
        // Keyboard setup
        self.an_subscribeKeyboard(animations: { r, t, o in
            if (o) {
                self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
            } else {
                self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
        }, completion: nil)
        
        // Hide loading
        self.hideLoading()
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    func setDefaultKurir() {
        if (isRefundMode) {
            self.lblKurir.text = "JNE"
        } else {
            self.lblKurir.text = trxDetail.requestCourier.characters.split{$0 == "("}.map(String.init)[0]
        }
    }
    
    // MARK: - TableView delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (isRefundMode) {
            return 0
        } else {
            return trxDetail.transactionProducts.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (isCellSelected.count >= (indexPath as NSIndexPath).row + 1) {
            if (isCellSelected[(indexPath as NSIndexPath).row] == true) {
                return 102
            } else {
                return 245
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (trxProductDetails.count >= (indexPath as NSIndexPath).row + 1) {
            let cell : ConfirmShippingCell = self.tableView.dequeueReusableCell(withIdentifier: "ConfirmShippingCell") as! ConfirmShippingCell
            cell.selectionStyle = .none
            cell.adapt(trxProductDetails[(indexPath as NSIndexPath).row], isCellSelected: self.isCellSelected[(indexPath as NSIndexPath).row], selectedAvailability : self.selectedAvailabilities[(indexPath as NSIndexPath).row])
            cell.refreshTable = {
                self.isCellSelected[(indexPath as NSIndexPath).row] = !self.isCellSelected[(indexPath as NSIndexPath).row]
                self.setupTable()
                if (self.isAllCellUnselected()) {
                    self.consHeightVwKurirResiFields.constant = 0
                } else {
                    self.setDefaultKurir()
                    self.hideFldKurirLainnya() // This is actually showing vwKurirResiFields
                }
            }
            cell.availabilitySelected = { selection in
                self.selectedAvailabilities[(indexPath as NSIndexPath).row] = selection
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Do nothing
    }
    
    // MARK: - UITextfield functions
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.isEqual(txtFldNoResi) {
            txtFldNoResi.text = (textField.text! as NSString).replacingCharacters(in: range, with: string.uppercased())
            return false
        }
        return true
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
            a.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in }))
            self.present(a, animated: true, completion: nil)
        } else {
            self.present(i, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnKonfKirimPressed(_ sender: AnyObject) {
        if (isRefundMode) {
            if (validateShippingFields()) {
                self.showLoading()
                
                let url = "\(AppTools.PreloBaseUrl)/api/transaction_product/\(self.tpId)/refund_sent"
                let param = [
                    "kurir" : self.lblKurir.text?.lowercased() != "lainnya" ? self.lblKurir.text! : self.txtFldKurirLainnya.text!,
                    "resi_number" : self.txtFldNoResi.text == nil ? "" : self.txtFldNoResi.text!
                ]
                var images : [UIImage] = []
                if let imgR = imgResi.image {
                    images.append(imgR)
                }
                
                let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
                
                AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, andUserAgent: userAgent!, to: url, success: { op, res in
                    print("Refund sent res = \(res)")
                    let json = JSON(res!)
                    let data = json["_data"].boolValue
                    if (data == true) {
                        Constant.showDialog("Konfirmasi Pengembalian", message: "Konfirmasi berhasil dilakukan")
                        _ = self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        Constant.showDialog("Konfirmasi Pengembalian", message: "Gagal mengupload data")
                        self.hideLoading()
                    }
                }, failure: { op, err in
                    Constant.showDialog("Konfirmasi Pengembalian", message: "Gagal mengupload data")
                    self.hideLoading()
                })
            }
        } else {
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
                            "reason" : cell.textView.text,
                            "is_active" : (cell.selectedAvailability == .available) ? "1" : "0"
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
                    let rIsActive = r["is_active"]!
                    confirmData += "{\"tp_id\": \"\(rTpId)\", \"reason\": \"\(rReason)\", \"is_active\": \"\(rIsActive)\"}"
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
                    let json = JSON(res!)
                    let data = json["_data"].boolValue
                    if (data == true) {
                        Constant.showDialog("Konfirmasi Kirim/Tolak", message: "Konfirmasi berhasil dilakukan")
                        _ = self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        Constant.showDialog("Konfirmasi Kirim/Tolak", message: "Terdapat kesalahan saat memproses data")
                        self.hideLoading()
                    }
                }, failure: { op, err in
                    Constant.showDialog("Konfirmasi Kirim/Tolak", message: "Gagal mengupload data")
                    self.hideLoading()
                })
            }
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
        if (isRefundMode) {
            return
        }
        
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
    
    func isAllCellUnselected() -> Bool {
        for i in 0..<self.isCellSelected.count {
            if (isCellSelected[i]) {
                return false
            }
        }
        return true
    }
    
    func validateFields() -> Bool {
        var result : Bool = true
        
        var isAllRejected = true
        for i in 0 ..< isCellSelected.count {
            if (!isCellSelected[i]) {
                let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! ConfirmShippingCell
                if (cell.selectedAvailability == nil) {
                    Constant.showDialog("Warning", message: "Opsi ketersediaan barang harus diisi")
                    result = false
                }
                if (cell.textView.text == "" || cell.textView.text == cell.TxtvwPlaceholder) {
                    Constant.showDialog("Warning", message: "Alasan tolak harus diisi")
                    result = false
                }
            } else {
                isAllRejected = false
            }
        }
        if (!isAllRejected) {
            result = self.validateShippingFields()
        }
        return result
    }
    
    func validateShippingFields() -> Bool {
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
        return true
    }
    
    func setupTable() {
        if (isRefundMode) {
            consHeightTableView.constant = 0
            return
        }
        
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
        consHeightContentView.constant = height + (isAllCellUnselected() ? 275 : 330)
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
        consHeightVwKurirResiFields.constant = 177
    }
    
    func showFldKurirLainnya() {
        consHeightVwKurirLainnya.constant = 55
        consHeightVwKurirResiFields.constant = 232
    }
}

// MARK: - Enum

enum ConfirmShippingAvailability {
    case soldOut
    case available
}

// MARK: - Class

class ConfirmShippingCell: TransactionDetailProductCell, UITextViewDelegate {
    
    @IBOutlet weak var lblCheckbox: UILabel!
    @IBOutlet weak var vwTolak: UIView!
    @IBOutlet var lblRadioBtnHabis: UILabel!
    @IBOutlet var lblRadioBtnMasih: UILabel!
    @IBOutlet weak var textView: UITextView!
    var txtvwGrowHandler : GrowingTextViewHandler!
    @IBOutlet weak var consHeightTxtvw: NSLayoutConstraint!
    let TxtvwPlaceholder = "Tulis alasan kamu menolak pesanan."
    
    var isCellSelected : Bool!
    var selectedAvailability : ConfirmShippingAvailability?
    
    var refreshTable : () -> () = {}
    var availabilitySelected : (ConfirmShippingAvailability) -> () = { _ in }
    
    override func prepareForReuse() {
        lblRadioBtnHabis.text = ""
        lblRadioBtnMasih.text = ""
    }
    
    func adapt(_ trxProductDetail: TransactionProductDetail, isCellSelected : Bool, selectedAvailability : ConfirmShippingAvailability?) {
        super.adapt(trxProductDetail)
        
        // Set checkbox
        self.isCellSelected = isCellSelected
        self.setupCheckbox()
        
        // Set radiobtn
        self.selectedAvailability = selectedAvailability
        self.setupRadioBtn()
        
        // Configure textview
        textView.delegate = self
        textView.text = TxtvwPlaceholder
        textView.textColor = UIColor.lightGray
        textView.layoutIfNeeded()
        txtvwGrowHandler = GrowingTextViewHandler(textView: textView, withHeightConstraint: consHeightTxtvw)
        txtvwGrowHandler.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 2)
    }
    
    @IBAction func cellTapped(_ sender: AnyObject) {
        isCellSelected = !isCellSelected
        self.setupCheckbox()
        self.refreshTable()
    }
    
    @IBAction func radioBtnHabisPressed(_ sender: AnyObject) {
        self.selectedAvailability = .soldOut
        self.availabilitySelected(.soldOut)
        self.setupRadioBtn()
    }
    
    @IBAction func radioBtnMasihPressed(_ sender: AnyObject) {
        self.selectedAvailability = .available
        self.availabilitySelected(.available)
        self.setupRadioBtn()
    }
    
    func setupRadioBtn() {
        if (selectedAvailability == .soldOut) {
            self.lblRadioBtnHabis.text = ""
            self.lblRadioBtnHabis.textColor = Theme.ThemeOrange
            self.lblRadioBtnMasih.text = ""
            self.lblRadioBtnMasih.textColor = UIColor.lightGray
            if (self.textView.text.isEmpty || self.textView.text == TxtvwPlaceholder) {
                self.textView.text = "Sold"
            }
        } else if (selectedAvailability == .available) {
            self.lblRadioBtnHabis.text = ""
            self.lblRadioBtnHabis.textColor = UIColor.lightGray
            self.lblRadioBtnMasih.text = ""
            self.lblRadioBtnMasih.textColor = Theme.ThemeOrange
            if (self.textView.text == "Sold") {
                self.textView.text = TxtvwPlaceholder
            }
        } else {
            self.lblRadioBtnHabis.text = ""
            self.lblRadioBtnHabis.textColor = UIColor.lightGray
            self.lblRadioBtnMasih.text = ""
            self.lblRadioBtnMasih.textColor = UIColor.lightGray
        }
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
        if (textView.text == TxtvwPlaceholder) {
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
