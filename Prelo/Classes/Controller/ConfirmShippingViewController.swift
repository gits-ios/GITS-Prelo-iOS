//
//  ConfirmShippingViewController.swift
//  Prelo
//
//  Created by PreloBook on 3/18/16.
//  Copyright (c) 2016 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import DropDown

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
    
    var dataReject : Array<String> = []
    var dataRejectNote: Array<String> = []
    
    // Predefined value
    // For confirm shipping
    var trxDetail : TransactionDetail!
    // For refund
    var isRefundMode : Bool = false
    var tpId : String = ""
    
    // Data container
    var trxProductDetails : [TransactionProductDetail]!
    var isCellSelected : [Bool]!
    var selectedIndex : [Int] = []
    var selectedAvailabilities : [ConfirmShippingAvailability?]!
    var isFirstAppearance : Bool = true
    var isPictSelected : Bool = false
    
    // Contact us view
    var contactUs : UIViewController?
    
    var isBarcodeUsed = false
    
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
        
        DropDown.startListeningToKeyboard()
        
        let appearance = DropDown.appearance()
        
        //appearance.cellHeight = 60
        appearance.backgroundColor = UIColor(white: 1, alpha: 1)
        appearance.selectionBackgroundColor = UIColor(red: 0.6494, green: 0.8155, blue: 1.0, alpha: 0.2)
        appearance.separatorColor = UIColor(white: 0.7, alpha: 0.8)
        appearance.cornerRadius = 0
        appearance.shadowColor = UIColor(white: 0.6, alpha: 1)
        appearance.shadowOpacity = 1
        appearance.shadowRadius = 2
        appearance.animationduration = 0.25
        appearance.textColor = .darkGray
        
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
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
                    selectedIndex = []
                    selectedAvailabilities = []
                    for _ in 0 ..< trxProductDetails.count {
                        selectedIndex.append(0)
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
        
        // done button
        let ViewForDoneButtonOnKeyboard = UIToolbar()
        ViewForDoneButtonOnKeyboard.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let btnDoneOnKeyboard = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.dismissKeyboard))
        ViewForDoneButtonOnKeyboard.items = [flex, btnDoneOnKeyboard, UIBarButtonItem()]
        self.txtFldNoResi.inputAccessoryView = ViewForDoneButtonOnKeyboard
        
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
            let kurir = trxDetail.requestCourier.characters.split{$0 == "("}.map(String.init)[0]
            self.lblKurir.text = (kurir == "Free Ongkir" ? "Pilih Kurir" : kurir)
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
                if (selectedIndex[(indexPath as NSIndexPath).row] == 0 || self.dataReject[selectedIndex[(indexPath as NSIndexPath).row]].contains("SOLD")) {
                    return 180
                } else {
                    // + 30
                    let text = self.dataRejectNote[selectedIndex[(indexPath as NSIndexPath).row]]
                    let t = text.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 12), width: AppTools.screenWidth - (37 - 8))
                    
                    var h: CGFloat = 0
                    if self.dataReject[selectedIndex[(indexPath as NSIndexPath).row]].contains("lain") {
                        h = 50
                    }
                    
                    return 180 + h + t.height + 8
                }
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (trxProductDetails.count >= (indexPath as NSIndexPath).row + 1) {
            let cell : ConfirmShippingCell = self.tableView.dequeueReusableCell(withIdentifier: "ConfirmShippingCell") as! ConfirmShippingCell
            
            cell.selectionStyle = .none
            
            cell.dataReject = self.dataReject
            cell.dataRejectNote = self.dataRejectNote
            
            cell.adapt(trxProductDetails[ (indexPath as NSIndexPath).row],
                       isCellSelected: self.isCellSelected[(indexPath as NSIndexPath).row],
                       selectedAvailability: self.selectedAvailabilities[(indexPath as NSIndexPath).row],
                       selectedIndex: self.selectedIndex[indexPath.row])
            
            cell.refreshTable = {
                self.isCellSelected[(indexPath as NSIndexPath).row] = !self.isCellSelected[(indexPath as NSIndexPath).row]
                self.selectedIndex[(indexPath as NSIndexPath).row] = cell.selectedIndex
                self.setupTable()
                if (self.isAllCellUnselected()) {
                    self.consHeightVwKurirResiFields.constant = 0
                } else {
                    self.setDefaultKurir()
                    self.hideFldKurirLainnya() // This is actually showing vwKurirResiFields
                }
            }
            
            cell.refreshTable2 = {
                self.selectedIndex[(indexPath as NSIndexPath).row] = cell.selectedIndex
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
        /*let kurirs = CDShipping.getAll()
        if (kurirs.count <= 0) {
            Constant.showDialog("Oops, gagal memproses data kurir", message: "Harap me-refresh data kurir melalui menu About > Reload App Data")
            return
        }*/
        
        var kurirs: [String] = []
        if let arr = trxDetail.json["available_shippings"].array {
            for a in arr {
                if let kurir = a.string {
                    kurirs.append(kurir)
                }
            }
        }
        
        let kurirAlert = UIAlertController(title: "Pilih Kurir", message: nil, preferredStyle: .actionSheet)
        kurirAlert.popoverPresentationController?.sourceView = self.lblDropdownKurir as UIView
        kurirAlert.popoverPresentationController?.sourceRect = self.lblDropdownKurir.bounds
        for i in 0..<kurirs.count {
            kurirAlert.addAction(UIAlertAction(title: kurirs[i] /*kurirs[i].name*/, style: .default, handler: { act in
                self.lblKurir.text = kurirs[i] /*kurirs[i].name*/
                self.hideFldKurirLainnya()
                kurirAlert.dismiss(animated: true, completion: nil)
            }))
        }
        
        if !(trxDetail.preloBalanceUsed > 0 || trxDetail.bonusUsed > 0 || trxDetail.voucherAmount > 0) {
            kurirAlert.addAction(UIAlertAction(title: "Lainnya", style: .default, handler: { act in
                self.lblKurir.text = "Lainnya"
                self.showFldKurirLainnya()
                kurirAlert.dismiss(animated: true, completion: nil)
            }))
            
        }
        
        kurirAlert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in
            kurirAlert.dismiss(animated: true, completion: nil)
        }))
        self.present(kurirAlert, animated: true, completion: nil)
    }
    
    @IBAction func btnResiPressed(_ sender: AnyObject) {
        let i = UIImagePickerController()
        i.sourceType = .photoLibrary
        i.delegate = self
        
        let a = UIAlertController(title: "Ambil gambar dari:", message: nil, preferredStyle: .actionSheet)
        a.popoverPresentationController?.sourceView = self.imgResi
        a.popoverPresentationController?.sourceRect = self.imgResi.bounds
        
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            a.addAction(UIAlertAction(title: "Kamera", style: .default, handler: { act in
                i.sourceType = .camera
                self.isBarcodeUsed = false
                self.present(i, animated: true, completion: nil)
            }))
        }
        
        a.addAction(UIAlertAction(title: "Album", style: .default, handler: { act in
            self.isBarcodeUsed = false
            self.present(i, animated: true, completion: nil)
        }))
        
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            a.addAction(UIAlertAction(title: "Barcode Reader", style: .default, handler: { act in
                self.barcodeScanner()
            }))
        }
        a.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in }))
        self.present(a, animated: true, completion: nil)
    }
    
    @IBAction func btnKonfKirimPressed(_ sender: AnyObject) {
        if (isRefundMode) {
            if (validateShippingFields()) {
                self.showLoading()
                
                let url = "\(AppTools.PreloBaseUrl)/api/transaction_product/\(self.tpId)/refund_sent"
                let param = [
                    "kurir" : self.lblKurir.text?.lowercased() != "lainnya" ? self.lblKurir.text! : self.txtFldKurirLainnya.text!,
                    "resi_number" : self.txtFldNoResi.text == nil ? "" : self.txtFldNoResi.text!,
                    "platform_sent_from" : "ios"
                ]
                var images : [UIImage] = []
                if let imgR = imgResi.image {
                    images.append(imgR)
                }
                
                let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
                
                AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, andUserAgent: userAgent!, to: url, success: { op, res in
                    //print("Refund sent res = \(res)")
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
                            "reason" : cell.lblReason.text,
                            "is_active" : (cell.selectedAvailability == .available) ? "1" : "0",
                            "reason_number" : String(cell.selectedIndex-1)
                            ] as! [String : String]
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
                    let rReasonNumber = r["reason_number"]!
                    confirmData += "{\"tp_id\": \"\(rTpId)\", \"reason\": \"\(rReason)\", \"is_active\": \"\(rIsActive)\", \"reason_number\": \(rReasonNumber)}"
                    if (k < rejectedTp.count - 1) {
                        confirmData += ","
                    }
                }
                confirmData += "]}"
                print("ini confirm data")
                print(confirmData)
                
                let url = "\(AppTools.PreloBaseUrl)/api/new/transaction_products/confirm"
                let param = [
                    "confirmation_data" : confirmData,
                    "kurir" : self.lblKurir.text?.lowercased() != "lainnya" ? self.lblKurir.text! : self.txtFldKurirLainnya.text!,
                    "resi_number" : self.txtFldNoResi.text == nil ? "" : self.txtFldNoResi.text!,
                    "platform_sent_from" : "ios"
                ]
                var images : [UIImage] = []
                if let imgR = imgResi.image {
                    images.append(imgR)
                }
                
                let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
                
                AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, andUserAgent: userAgent!, to: url, success: { op, res in
                    //print("Confirm shipping res = \(res)")
                    let json = JSON(res!)
                    let data = json["_data"].boolValue
                    if (data == true) {
                        Constant.showDialog("Konfirmasi Kirim/Tolak", message: "Konfirmasi berhasil dilakukan")
                        
                        // Prelo Analytic - Confirm Shipping
                        self.sendConfirmShippingAnalytic()
                        
                        _ = self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        Constant.showDialog("Konfirmasi Kirim/Tolak", message: "Terdapat kesalahan saat memproses data")
                        self.hideLoading()
                    }
                    
                }, failure: { op, err in
                    //print("Ini error nya = \(err)")
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
                if (cell.lblReason.text == "Alasan Penolakan") {
                    Constant.showDialog("Warning", message: "Alasan tolak harus diisi")
                    result = false
                }
                if (cell.lblReason.text == "Ada kepentingan lain") {
                    if(cell.textView.text == nil){
                        Constant.showDialog("Warning", message: "Mohon sertakan alasan kamu menolak pesanan")
                        result = false
                    }
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
        if (self.lblKurir.text == "" || self.lblKurir.text == "Pilih Kurir") {
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
    
    func barcodeScanner() {
        let ScannerVC = Bundle.main.loadNibNamed(Tags.XibNameScanner, owner: nil, options: nil)?.first as! ScannerViewController
        ScannerVC.blockDone = { data in // [0] -> nomor resi : String, [1] -> foto resi : UIImage
            if let img = data[1] as? UIImage {
                self.imgResi.image = img
                self.isPictSelected = true
                
                self.isBarcodeUsed = true
            } else {
                self.isBarcodeUsed = false
                
                Constant.showDialog("Oops", message: "Foto resi gagal diperbarui. Silakan coba ambil gambar lagi")
            }
            
            if (data[0] as! String == "") {
                self.isBarcodeUsed = false
                
                Constant.showDialog("Oops", message: "Nomor resi pengiriman tidak ditemukan. Silakan coba ambil gambar lagi atau ketik langsung di kolom Nomor Resi.")
            } else {
                self.isBarcodeUsed = true
                
//                Constant.showDialog("Nomor Resi", message: data[0] as! String)
                self.txtFldNoResi.text = data[0] as? String
            }
            // coba screenshot
//            self.imgResi.image = self.view?.snapshot
        }
        self.navigationController?.pushViewController(ScannerVC, animated: true)

    }
    
    // Prelo Analytic - Confirm / Reject Shipping
    func sendConfirmShippingAnalytic() {
        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.PreloAnalytic",
                                            qos: .background,
                                            attributes: .concurrent,
                                            target: nil)
        backgroundQueue.async {
            
            /*
            var itemsObject : Array<[String : Any]> = []
            
            let arrayProduct = self.trxDetail.transactionProducts
            
            var totalCommissionPrice = 0
            var i = 0
            for tp in arrayProduct {
                let shippingPrice = Int(tp.shippingPrice) ?? 0
                
                var curItem : [String : Any] = [
                    "Product ID" : tp.productId ,
                    "Price" : tp.productPrice,
                    "Commission Percentage" : tp.commission,
                    "Commission Price" : tp.commissionPrice,
                    "Shipping Price" : shippingPrice,
                    "Rejected" : false
                ]
                
                if !self.isCellSelected[i] {
                    var isAvailable = true
                    
                    let cell = self.tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! ConfirmShippingCell
                    if (cell.selectedAvailability == .soldOut ) {
                        isAvailable = false
                    }
                    
                    let reason = cell.textView.text
                    
                    let rejectedReason : [String : Any] = [
                        "Is Available" : isAvailable,
                        "Reason" : reason
                    ]
                    
                    curItem["Rejected"] = rejectedReason
                }
                
                itemsObject.append(curItem)
                
                totalCommissionPrice += tp.commissionPrice
                
                i += 1
            }
            
            let loginMethod = User.LoginMethod ?? ""
            let province = CDProvince.getProvinceNameWithID(self.trxDetail.shippingProvinceId) ?? ""
            let region = CDRegion.getRegionNameWithID(self.trxDetail.shippingRegionId) ?? ""
            
            let shipping = [
                "Province" : province,
                "Region" : region
            ] as [String : Any]
            
            let pdata = [
                "Order ID" : self.trxDetail.orderId,
                "Seller Username" : (CDUser.getOne()?.username)!, // me
                "Items" : itemsObject,
//                "Total Original Price" : self.trxDetail.totalPrice,
                "Total Price" : self.trxDetail.totalPriceTotall,
                "Total Commission" : totalCommissionPrice,
                "Shipping" : shipping,
                "Barcode Used" : self.isBarcodeUsed
            ] as [String : Any]
            AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ConfirmShipping, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
             */
            
            let arrayProduct = self.trxDetail.transactionProducts
            let loginMethod = User.LoginMethod ?? ""
            
            var i = 0
            for tp in arrayProduct {
                let shippingPrice = Int(tp.shippingPrice) ?? 0
                
                var pdata : [String : Any] = [
                    "Order ID" : tp.orderId,
                    "Seller Username" : tp.sellerUsername, // me
                    "Product ID" : tp.productId ,
                    "Price" : tp.productPrice,
                    "Commission Percentage" : tp.commission,
                    "Commission Price" : tp.commissionPrice,
                ]
                
                if !self.isCellSelected[i] {
                    var isAvailable = true
                    
                    let cell = self.tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! ConfirmShippingCell
                    if (cell.selectedAvailability == .soldOut ) {
                        isAvailable = false
                    }
                    
                    let reason = cell.textView.text!
                    
                    pdata["Available"] = isAvailable
                    pdata["Reason"] = reason
                    
                    // Prelo Analytic - Reject Shipping
                    AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.RejectShipping, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
                } else {
                    pdata["Barcode Used"] = self.isBarcodeUsed
                    
                    let province = CDProvince.getProvinceNameWithID(self.trxDetail.shippingProvinceId) ?? ""
                    let region = CDRegion.getRegionNameWithID(self.trxDetail.shippingRegionId) ?? ""
                    let subdistrict = self.trxDetail.shippingSubdistrictName
                    
                    let shipping = [
                        "Price" : shippingPrice,
                        "Courier" : (self.lblKurir.text?.lowercased() != "lainnya" ? self.lblKurir.text! : self.txtFldKurirLainnya.text!) //tp.shippingName
                    ] as [String : Any]
                    
                    let address = [
                        "Province" : province,
                        "Region" : region,
                        "Subdistrict" : subdistrict
                    ] as [String : Any]
                    
                    
                    pdata["Shipping"] = shipping
                    pdata["Address"] = address
                    
                    // Prelo Analytic - Confirm Shipping
                    AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ConfirmShipping, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
                }
                
                i += 1
            }
        }
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
    @IBOutlet weak var textView: UITextView!
    var txtvwGrowHandler : GrowingTextViewHandler!
    @IBOutlet weak var consHeightTxtvw: NSLayoutConstraint!
    @IBOutlet weak var lblReason: UILabel!
    @IBOutlet weak var notification: UILabel!
    @IBOutlet weak var fieldCustomReason: UIView!
    @IBOutlet weak var consNotifTop: NSLayoutConstraint!
    
    var dataReject: Array<String> = []
    var dataRejectNote: Array<String> = []
    
    let TxtvwPlaceholder = "Tulis alasan kamu menolak pesanan."
    
    let dropDown = DropDown()
    var selectedIndex = 0
    
    var isCellSelected : Bool!
    var selectedAvailability : ConfirmShippingAvailability?
    
    var refreshTable : () -> () = {}
    var refreshTable2 : () -> () = {}
    var availabilitySelected : (ConfirmShippingAvailability) -> () = { _ in }
    
    override func prepareForReuse() {
        
    }
    
    func adapt(_ trxProductDetail: TransactionProductDetail, isCellSelected : Bool, selectedAvailability : ConfirmShippingAvailability?, selectedIndex: Int) {
        super.adapt(trxProductDetail)
        
        if self.dropDown.dataSource.count == 0 {
            setupDropdownReason()
        }
        
        // Set checkbox
        self.isCellSelected = isCellSelected
        self.setupCheckbox()
        
        // Configure textview
        textView.delegate = self
        textView.text = TxtvwPlaceholder
        textView.textColor = UIColor.lightGray
        textView.layoutIfNeeded()
        txtvwGrowHandler = GrowingTextViewHandler(textView: textView, withHeightConstraint: consHeightTxtvw)
        txtvwGrowHandler.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 2)
        
        self.selectedIndex = selectedIndex
    }
    
    @IBAction func cellTapped(_ sender: AnyObject) {
        isCellSelected = !isCellSelected
        if (selectedIndex == 0) { // alasan penolakan
            fieldCustomReason.isHidden = true
            notification.isHidden = true
        }
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
        if (textView.text == TxtvwPlaceholder) {
            textView.text = ""
            textView.textColor = Theme.GrayDark
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        txtvwGrowHandler.resizeTextView(withAnimation: true)
        consNotifTop.constant = 20
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView.text.isEmpty) {
            textView.text = TxtvwPlaceholder
            textView.textColor = UIColor.lightGray
        }
    }
    
    @IBOutlet weak var dropDownReason: UIButton!
    @IBAction func dropDownReasonPressed(_ sender: Any) {
        dropDown.hide()
        dropDown.show()
    }
    
    func setupDropdownReason() {
        //dropDown = DropDown()
        dropDown.dataSource = self.dataReject
        
        // Action triggered on selection
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            if index != self.selectedIndex {
                self.selectedIndex = index
                
                if index < self.dropDown.dataSource.count {
                    self.lblReason.text = self.dropDown.dataSource[index]
                    if index > 0 {
                        var notes = "Catatan: " + self.dataRejectNote[index]
                        var bold = ""
                        
                        if notes.contains("<b>") {
                            bold = notes.substring(from: notes.index(of: "<b>")!)
                            bold = bold.substring(to: bold.index(of: "</b>")!)
                            
                            notes = notes.replace("<b>", template: "").replace("</b>", template: "")
                            bold = bold.replace("<b>", template: "").replace("</b>", template: "")
                        }
                        
                        self.notification.text = notes
                        
                        if bold != "" {
                            self.notification.boldSubstring(bold)
                        }
                        
                        if self.dropDown.dataSource[index].contains("SOLD") {
                            self.notification.isHidden = true
                            self.fieldCustomReason.isHidden = true
                            self.selectedAvailability = .soldOut
                            
                        } else if self.dropDown.dataSource[index].contains("lain") {
                            self.notification.isHidden = false
                            self.fieldCustomReason.isHidden = false
                            self.consNotifTop.constant = 20
                            self.selectedAvailability = .available
                            
                        } else {
                            self.notification.isHidden = false
                            self.fieldCustomReason.isHidden = true
                            self.consNotifTop.constant = -30
                            self.selectedAvailability = .available
                            
                        }
                    } else { // Alasan Penolakan
                        self.notification.isHidden = true
                        self.fieldCustomReason.isHidden = true
                        
                    }
                    
                    self.refreshTable2()
                }
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        
        dropDown.cellHeight = 40
        
        dropDown.selectRow(at: self.selectedIndex)
        
        dropDown.direction = .bottom
    }
}
