//
//  ProfileSetupViewController.swift
//  Prelo
//
//  Created by Fransiska on 9/1/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import CoreData
import Alamofire

class ProfileSetupViewController : BaseViewController, PickerViewDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate {
    
    @IBOutlet var loadingPanel: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var consHeightContentView: NSLayoutConstraint!
    
    @IBOutlet weak var lblHeaderAlert: UILabel!
    
    // Groups index:
    // 0 : Group Upload Foto
    // 1 : Group Fullname
    // 2 : Group Email
    // 3 : Group Jenis Kelamin
    // 4 : Group No HP
    // 5 : Group Verifikasi HP
    // 6 : Group Kota
    // 7 : Group Shipping Options
    // 8 : Group Referal
    // 9 : Group Apply
    @IBOutlet weak var groupUploadFoto: UIView!
    @IBOutlet weak var groupFullname: UIView!
    @IBOutlet weak var groupEmail: UIView!
    @IBOutlet weak var groupJenisKelamin: UIView!
    @IBOutlet weak var groupNoHp: UIView!
    @IBOutlet weak var groupVerifikasiHp: UIView!
    @IBOutlet weak var groupKota: UIView!
    @IBOutlet weak var groupShippingOptions: UIView!
    @IBOutlet weak var groupReferral: UIView!
    @IBOutlet weak var groupApply: UIView!
    var groups: [UIView] = []
    
    @IBOutlet weak var consTopUploadFoto: NSLayoutConstraint!
    @IBOutlet weak var consTopFullname: NSLayoutConstraint!
    @IBOutlet weak var consTopEmail: NSLayoutConstraint!
    @IBOutlet weak var consTopJenisKelamin: NSLayoutConstraint!
    @IBOutlet weak var consTopNoHp: NSLayoutConstraint!
    @IBOutlet weak var consTopVerifikasiHp: NSLayoutConstraint!
    @IBOutlet weak var consTopKota: NSLayoutConstraint!
    @IBOutlet weak var consTopShippingOptions: NSLayoutConstraint!
    @IBOutlet weak var consTopReferral: NSLayoutConstraint!
    @IBOutlet weak var consTopApply: NSLayoutConstraint!
    var consTopGroups: [NSLayoutConstraint] = []
    
    @IBOutlet var consHeightShippingOptions: NSLayoutConstraint!
    @IBOutlet var tableShipping: UITableView!
    var shippingList : [CDShipping] = []
    var shippingCellHeight : CGFloat = 40
    
    @IBOutlet weak var btnUserImage: UIButton!
    
    @IBOutlet weak var lblFullname: UILabel!
    @IBOutlet weak var fieldFullname: UITextField!
    
    @IBOutlet weak var fieldEmail: UITextField!
    
    @IBOutlet weak var lblJenisKelamin: UILabel!
    
    @IBOutlet weak var fieldNoHP: UITextField!
    
    @IBOutlet weak var fieldVerifikasiNoHP: UITextField!
    @IBOutlet weak var fieldKodeVerifikasi: UITextField!
    
    @IBOutlet var lblProvinsi: UILabel!
    @IBOutlet var lblKabKota: UILabel!
    @IBOutlet var lblKecamatan: UILabel!
    
    @IBOutlet weak var fieldKodeReferral: UITextField!
    
    @IBOutlet weak var btnApply: UIButton!
    
    var selectedProvinsiID = ""
    var selectedKabKotaID = ""
    var selectedKecamatanID = ""
    var selectedKecamatanName = ""
    var kecamatanPickerItems : [String] = []
    var isPickingProvinsi : Bool = false
    var isPickingKabKota : Bool = false
    var isPickingKecamatan : Bool = false
    var isPickingJenKel : Bool = false
    
    var deltaHeight : CGFloat = 0
    
    //var asset : ALAssetsLibrary?
    
    var isShowGender : Bool = true
    
    // Variable from previous scene
    var userId : String = ""
    var userToken : String = ""
    var userEmail : String = ""
    var isSocmedAccount : Bool!
    var loginMethod : String = "" // [Basic | Facebook | Twitter]
    var screenBeforeLogin : String = ""
    var isMixpanelPageVisitSent : Bool = false
    var isFromRegister : Bool!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        setupContent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Setelan Akun"
        
        // Transparent panel
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
        if (!self.isMixpanelPageVisitSent) {
//            Mixpanel.trackPageVisit(PageName.SetupAccount)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.SetupAccount)
            
            /*
            // Di sini akan dikirim mixpanel event register, hanya jika user baru saja melakukan register 
            // Pengecekan apakah baru register ada 2 lapis
            // Pertama: dicek apakah CDUser tidak nil, karena kalau login dan masuk ke ProfileSetupVC, seharusnya CDUser masih kosong, sedangkan kalau setelah register seharusnya CDUser terisi
            // Kedua: apakah registerTime terjadi kurang dari 1 menit yang lalu (karna profile setup pasti dipanggil setelah register berhasil)
            // Pengecekan kedua dilakukan karena pengecekan pertama terkadang bocor
            if let c = CDUser.getOne() {
                var minutesSinceReg = 0
                if let o = CDUserOther.getOne() {
                    if let regTime = o.registerTime {
                        minutesSinceReg = Date().minutesFromIsoFormatted(regTime)
                    }
                }
                if (minutesSinceReg <= 1) {
                    let sp = [
                        "Email" : c.email,
                        "Username" : c.username,
                        "Fullname" : c.fullname!,
                        "Login Method" : self.loginMethod
                    ]
                    Mixpanel.sharedInstance().registerSuperProperties(sp)
                    let spo = [
                        "Register Time" : Date().isoFormatted,
                        "Register Method" : self.loginMethod
                    ]
                    Mixpanel.sharedInstance().registerSuperPropertiesOnce(spo)
                    Mixpanel.sharedInstance().identify(c.id)
                    let p = [
                        "$email" : c.email,
                        "$username" : c.username,
                        "$name" : c.fullname!
                    ]
                    Mixpanel.sharedInstance().people.set(p)
                    let po = [
                        "$created" : Date().isoFormatted,
                        "Register Method" : self.loginMethod
                    ]
                    Mixpanel.sharedInstance().people.setOnce(po)
                    let pr = [
                        "Previous Screen" : self.screenBeforeLogin
                    ]
                    Mixpanel.trackEvent(MixpanelEvent.Register, properties: pr)
                }
            }
             */
            
            self.isMixpanelPageVisitSent = true
        }
        
        // Keyboard animation handling
        self.an_subscribeKeyboard(
            animations: {r, t, o in
                if (o) {
                    self.consHeightContentView.constant += r.height
                } else {
                    self.consHeightContentView.constant -= r.height
                }
            }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        /*
        let alert : UIAlertController = UIAlertController(title: "Perhatian", message: "Setelan akun belum selesai. Halaman ini akan muncul lagi ketika kamu login. Keluar?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ya", style: .default, handler: { action in
            User.Logout()
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
         */
        
        let alertView = SCLAlertView(appearance: Constant.appearance)
        alertView.addButton("Keluar") {
            User.Logout()
            self.dismiss(animated: true, completion: nil)
        }
        alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
        alertView.showCustom("Perhatian", subTitle: "Setelan akun belum selesai. Halaman ini akan muncul lagi ketika kamu login. Keluar?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    func setupContent() {
        // Shipping table setup
        self.shippingList = CDShipping.getPosBlaBlaBlaTiki()
        self.tableShipping.tableFooterView = UIView()
        self.tableShipping.delegate = self
        self.tableShipping.dataSource = self
        self.tableShipping.register(UINib(nibName: "ShippingCell", bundle: nil), forCellReuseIdentifier: "ShippingCell")
        
        // Set header alert
        if (!isFromRegister) {
            self.lblHeaderAlert.text = "Kamu perlu menyelesaikan Setelan Akun"
        }
        
        // Set groups and top constraints manually
        groups.append(self.groupUploadFoto)
        groups.append(self.groupFullname)
        groups.append(self.groupEmail)
        groups.append(self.groupJenisKelamin)
        groups.append(self.groupNoHp)
        groups.append(self.groupVerifikasiHp)
        groups.append(self.groupKota)
        groups.append(self.groupShippingOptions)
        groups.append(self.groupReferral)
        groups.append(self.groupApply)
        consTopGroups.append(self.consTopUploadFoto)
        consTopGroups.append(self.consTopFullname)
        consTopGroups.append(self.consTopEmail)
        consTopGroups.append(self.consTopJenisKelamin)
        consTopGroups.append(self.consTopNoHp)
        consTopGroups.append(self.consTopVerifikasiHp)
        consTopGroups.append(self.consTopKota)
        consTopGroups.append(self.consTopShippingOptions)
        consTopGroups.append(self.consTopReferral)
        consTopGroups.append(self.consTopApply)
        
        // Pengecekan versi, jika versi yg diinstall melebihi versi server, jangan munculkan field gender
        if let installedVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let serverVersion = CDVersion.getOne()?.appVersion {
                if (serverVersion.compare(installedVersion, options: .numeric, range: nil, locale: nil) == .orderedAscending) {
                    self.isShowGender = false
                }
            }
        }
        
        // Need layout
        for i in 0..<groups.count {
            groups[i].layoutIfNeeded()
        }
        
        // Arrange groups
        var p : [Bool]!
        if (self.isSocmedAccount == true) {
            p = [false, true, (self.userEmail == ""), isShowGender, true, false, true, true, false, true]
        } else {
            p = [false, false, (self.userEmail == ""), isShowGender, true, false, true, true, false, true]
        }
        arrangeGroups(p)
        
        // If user uses socmed account, change fullname field to username field
        if (self.isSocmedAccount == true) {
            lblFullname.text = "Username"
            fieldFullname.placeholder = "Username"
        }
        
        // Border untuk tombol user image
        btnUserImage.layer.borderWidth = 1
        btnUserImage.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func arrangeGroups(_ isShowGroups : [Bool]) {
        let narrowSpace : CGFloat = 15
        let wideSpace : CGFloat = 25
        var deltaX : CGFloat = 0
        for i in 0 ..< isShowGroups.count { // asumsi i = 0-9
            let isShowGroup : Bool = isShowGroups[i]
            if isShowGroup {
                groups[i].isHidden = false
                // Manual narrow/wide space
                if (i == 0 || i == 2 || (i == 3 && !groups[1].isHidden) || i == 4) { // Narrow space before group
                    deltaX += narrowSpace
                } else { // Wide space before group
                    deltaX += wideSpace
                }
                consTopGroups[i].constant = deltaX
                if (i == 7) { // Special case, because shipping group have its own table
                    let groupHeight = 44 + (self.shippingCellHeight * CGFloat(self.shippingList.count))
                    consHeightShippingOptions.constant = groupHeight
                    deltaX += groupHeight
                } else {
                    deltaX += groups[i].frame.size.height
                }
            } else {
                groups[i].isHidden = true
            }
        }
        // Set content view height
        consHeightContentView.constant = deltaX + narrowSpace
    }
    
    @IBAction func disableTextFields(_ sender : AnyObject)
    {
        fieldFullname?.resignFirstResponder()
        fieldNoHP?.resignFirstResponder()
        fieldVerifikasiNoHP?.resignFirstResponder()
        fieldKodeVerifikasi?.resignFirstResponder()
        fieldKodeReferral?.resignFirstResponder()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
    
    func pickerDidSelect(_ item: String) {
        if (isPickingJenKel) {
            lblJenisKelamin?.text = PickerViewController.HideHiddenString(item)
            lblJenisKelamin.textColor = Theme.GrayDark
            isPickingJenKel = false
        } else if (isPickingProvinsi) {
            lblProvinsi?.text = PickerViewController.HideHiddenString(item)
            lblProvinsi.textColor = Theme.GrayDark
            isPickingProvinsi = false
        } else if (isPickingKabKota) {
            lblKabKota?.text = PickerViewController.HideHiddenString(item)
            lblKabKota.textColor = Theme.GrayDark
            isPickingKabKota = false
            kecamatanPickerItems = []
        } else if (isPickingKecamatan) {
            lblKecamatan?.text = PickerViewController.HideHiddenString(item)
            lblKecamatan.textColor = Theme.GrayDark
            isPickingKecamatan = false
        }
    }
    
    func pickerCancelled() {
        isPickingJenKel = false
        isPickingProvinsi = false
        isPickingKabKota = false
        isPickingKecamatan = false
    }
    
    // MARK: - UITableView functions
    // Used for shipping table
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shippingList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.shippingCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ShippingCell = self.tableShipping.dequeueReusableCell(withIdentifier: "ShippingCell") as! ShippingCell
        cell.selectionStyle = .none
        cell.lblName.text = shippingList[(indexPath as NSIndexPath).row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ShippingCell {
            cell.cellTapped()
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func userImagePressed(_ sender: AnyObject) {
        /*
        ImagePickerViewController.ShowFrom(self, maxSelect: 1, doneBlock:
            { imgs in
                if (imgs.count > 0) {
                    self.btnUserImage.setImage(ImageSourceCell.defaultImage, for: UIControlState())
                    
                    let img : APImage = imgs[0]
                    
                    if ((img.image) != nil)
                    {
                        self.btnUserImage.setImage(img.image, for: UIControlState())
                    } else if (imgs[0].usingAssets == true) {
                        
                        if (self.asset == nil) {
                            self.asset = ALAssetsLibrary()
                        }
                        
//                        DispatchQueue.global( priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
                        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
                            self.asset?.asset(for: (img.url)!, resultBlock: { asset in
                                if let ast = asset {
                                    let rep = ast.defaultRepresentation()
                                    let ref = rep?.fullScreenImage().takeUnretainedValue()
                                    let i = UIImage(cgImage: ref!)
                                    DispatchQueue.main.async(execute: {
                                        self.btnUserImage.setImage(i, for: UIControlState())
                                    })
                                }
                                }, failureBlock: { error in
                                    // error
                            })
                        })
                    }
                }
            }
        )
         */
        
        let i = UIImagePickerController()
        i.sourceType = .photoLibrary
        i.delegate = self
        
        if (UIImagePickerController.isSourceTypeAvailable(.camera))
        {
            let a = UIAlertController(title: "Ambil gambar dari:", message: nil, preferredStyle: .actionSheet)
            a.popoverPresentationController?.sourceView = self.btnUserImage
            a.popoverPresentationController?.sourceRect = self.btnUserImage.bounds
            a.addAction(UIAlertAction(title: "Kamera", style: .default, handler: { act in
                i.sourceType = .camera
                self.present(i, animated: true, completion: {
                    i.view.tag = 0
                })
            }))
            a.addAction(UIAlertAction(title: "Album", style: .default, handler: { act in
                self.present(i, animated: true, completion: {
                    i.view.tag = 0
                })
            }))
            a.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in }))
            self.present(a, animated: true, completion: nil)
        } else
        {
            self.present(i, animated: true, completion: {
                i.view.tag = 0
            })
        }
    }
    
    // MARK: - UIImagePickerController functions
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            self.btnUserImage.setImage(img, for: UIControlState())
        } else {
            self.btnUserImage.setImage(ImageSourceCell.defaultImage, for: UIControlState())
        }
        picker.dismiss(animated: true, completion: nil)
    }

    
    @IBAction func uploadFotoPressed(_ sender: AnyObject) {
        if (btnUserImage.imageView?.image == nil) {
            Constant.showDialog("Warning", message: "Pilih foto terlebih dahulu")
        } else {
            Constant.showDialog("Success", message: "Upload foto berhasil")
        }
    }
    
    @IBAction func jenisKelaminPressed(_ sender: AnyObject) {
        isPickingJenKel = true
        
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = ["Wanita", "Pria"]
        p?.pickerDelegate = self
        p?.title = "Jenis Kelamin"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    @IBAction func verifikasiNoHPPressed(_ sender: AnyObject) {
        if (fieldVerifikasiNoHP.text == "") {
            Constant.showDialog("Warning", message: "Isi no HP terlebih dahulu")
        } else {
            Constant.showDialog("Success", message: "Verifikasi no HP berhasil")
            fieldKodeVerifikasi.text = "123456"
        }
    }
    
    @IBAction func provinsiPressed(_ sender: AnyObject) {
        isPickingProvinsi = true
        
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = CDProvince.getProvincePickerItems()
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.selectedProvinsiID = PickerViewController.RevealHiddenString(string)
            self.lblKabKota.text = "Pilih Kota/Kabupaten"
            self.lblKecamatan.text = "Pilih Kecamatan"
            self.lblKabKota.textColor = Theme.GrayLight
            self.lblKecamatan.textColor = Theme.GrayLight
        }
        p?.title = "Provinsi"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    @IBAction func kabKotaPressed(_ sender: AnyObject) {
        if (selectedProvinsiID == "") {
            Constant.showDialog("Warning", message: "Pilih provinsi terlebih dahulu")
        } else {
            isPickingKabKota = true
            
            let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
            p?.items = CDRegion.getRegionPickerItems(selectedProvinsiID)
            p?.pickerDelegate = self
            p?.selectBlock = { string in
                self.selectedKabKotaID = PickerViewController.RevealHiddenString(string)
                self.lblKecamatan.text = "Pilih Kecamatan"
                self.lblKecamatan.textColor = Theme.GrayLight
            }
            p?.title = "Kota/Kabupaten"
            self.view.endEditing(true)
            self.navigationController?.pushViewController(p!, animated: true)
        }
    }
    
    @IBAction func kecamatanPressed(_ sender: AnyObject) {
        if (selectedKabKotaID == "") {
            Constant.showDialog("Warning", message: "Pilih kota/kabupaten terlebih dahulu")
        } else {
            if (kecamatanPickerItems.count <= 0) {
                self.showLoading()
                
                // Retrieve kecamatanPickerItems
                let _ = request(APIMisc.getSubdistrictsByRegionID(id: self.selectedKabKotaID)).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Kecamatan")) {
                        let json = JSON(resp.result.value!)
                        let data = json["_data"].arrayValue
                        
                        if (data.count > 0) {
                            for i in 0...data.count - 1 {
                                self.kecamatanPickerItems.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)
                            }
                            
                            self.pickKecamatan()
                        } else {
                            Constant.showDialog("Warning", message: "Oops, kecamatan tidak ditemukan")
                        }
                    }
                    self.hideLoading()
                }
            } else {
                self.pickKecamatan()
            }
        }
    }
    
    func pickKecamatan() {
        self.isPickingKecamatan = true
        
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = kecamatanPickerItems
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.selectedKecamatanID = PickerViewController.RevealHiddenString(string)
            self.selectedKecamatanName = string.components(separatedBy: PickerViewController.TAG_START_HIDDEN)[0]
        }
        p?.title = "Kecamatan"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    
    func fieldsVerified() -> Bool {
        if (isSocmedAccount == true) { // fieldFullname menjadi fieldUsername
            if (fieldFullname.text == "") {
                Constant.showDialog("Warning", message: "Username harus diisi")
                return false
            } else {
                let usernameRegex = "^[a-zA-Z0-9_]{4,15}$"
                if (fieldFullname.text!.match(usernameRegex) == false) {
                    Constant.showDialog("Warning", message: "Username harus sepanjang 4-15 karakter (a-z, A-Z, 0-9, _)")
                    return false
                }
            }
        }
        if (self.userEmail == "" && fieldEmail.text == "") {
            Constant.showDialog("Warning", message: "E-mail harus diisi")
        }
        if (fieldNoHP.text == "") {
            Constant.showDialog("Warning", message: "Nomor HP harus diisi")
            return false
        }
        if (lblProvinsi.text == "Pilih Provinsi") {
            Constant.showDialog("Warning", message: "Provinsi harus diisi")
            return false
        }
        if (lblKabKota.text == "Pilih Kota/Kabupaten") {
            Constant.showDialog("Warning", message: "Kota/Kabupaten harus diisi")
            return false
        }
        if (lblKecamatan.text == "Pilih Kecamatan") {
            Constant.showDialog("Warning", message: "Kecamatan harus diisi")
            return false
        }
        var isShippingVerified = false
        for i in 0...self.shippingList.count - 1 {
            if let cell = self.tableShipping.cellForRow(at: IndexPath(row: i, section: 0)) as? ShippingCell {
                if (cell.isShippingSelected) {
                    isShippingVerified = true
                }
            }
        }
        if (!isShippingVerified) {
            Constant.showDialog("Warning", message: "Pilihan Kurir harus diisi")
            return false
        }
        return true
    }
    
    @IBAction func applyPressed(_ sender: AnyObject) {
        if (fieldsVerified()) {
            disableTextFields(NSNull.self)
            self.btnApply.isEnabled = false
            
            var username = ""
            if (self.isSocmedAccount == true) {
                username = (fieldFullname?.text)!
            }
            var email = ""
            if (self.userEmail == "") {
                email = fieldEmail.text!
            }
            _ = fieldFullname?.text
            let userGender = (lblJenisKelamin?.text == "Pria") ? 0 : 1
            let userPhone = fieldNoHP?.text
            var userShipping : String = ""
            for i in 0...self.shippingList.count - 1 {
                if let cell = self.tableShipping.cellForRow(at: IndexPath(row: i, section: 0)) as? ShippingCell {
                    if (cell.isShippingSelected) {
                        if (userShipping != "") {
                            userShipping += ","
                        }
                        userShipping += shippingList[i].id
                    }
                }
            }
            let userReferral = fieldKodeReferral.text!
            let userDeviceId = UIDevice.current.identifierForVendor!.uuidString
            
            // Get device token
            let deviceToken = UserDefaults.standard.string(forKey: "deviceregid")!
            //print("deviceToken = \(deviceToken)")
            
            // Token belum disimpan pake User.StoreUser karna di titik ini user belum dianggap login
            // Set token first, because APIMe.SetupAccount & APIMe.SetUserPreferencedCategories need token
            User.SetToken(self.userToken)
            
            // API Migrasi
            let _ = request(APIMe.setupAccount(username: username, email: email,gender: (isShowGender ? userGender : -999), phone: userPhone!, province: selectedProvinsiID, region: selectedKabKotaID, subdistrict: selectedKecamatanID, shipping: userShipping, referralCode: userReferral, deviceId: userDeviceId, deviceRegId: deviceToken)).responseJSON {resp in
                
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Setelan Akun")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    
                    /* CATEGPREF DISABLED
                    // Set user's preferenced categories by current stored categories
                    // Dilakukan di sini (bukan di register atau phone verification) karna register dibedakan antara normal dan via socmed, dan phone verification dilakukan bisa berkali2 saat edit profile
                    // API Migrasi
                    let _ = request(APIMe.SetUserPreferencedCategories(categ1: NSUserDefaults.categoryPref1(), categ2: NSUserDefaults.categoryPref2(), categ3: NSUserDefaults.categoryPref3())).responseJSON {resp in
                        if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Set User Preferenced Categories")) {
                            let json = JSON(resp.result.value!)
                            let isSuccess = json["_data"].bool!
                            if (isSuccess) { // Berhasil
                                print("Success setting user preferenced categories")
                            } else { // Gagal
                                print("Error setting user preferenced categories")
                            }
                        }
                        // Delete token because user is considered not logged in
                        User.SetToken(nil)
                    }
                    */
                    
                    guard let userProfileData = UserProfile.instance(data) else {
                        Constant.showDialog("Setelan Akun", message: "Oops, terdapat kesalahan saat memproses data")
                        self.btnApply.isEnabled = true
                        return
                    }
                    
                    /*
                    // Mixpanel
                    let sp = [
                        "User ID" : userProfileData.id,
                        "Username" : userProfileData.username,
                        "Gender" : userProfileData.gender,
                        "Email" : userProfileData.email,
                        "Province Input" : CDProvince.getProvinceNameWithID(userProfileData.provinceId)!,
                        "City Input" : CDRegion.getRegionNameWithID(userProfileData.regionId)!
                    ]
                    Mixpanel.sharedInstance().registerSuperProperties(sp)
                    Mixpanel.sharedInstance().identify(userProfileData.id)
                    let p = [
                        "User ID" : userProfileData.id,
                        "$username" : userProfileData.username,
                        "$email" : userProfileData.email,
                        "Gender" : userProfileData.gender,
                        "Province Input" : CDProvince.getProvinceNameWithID(userProfileData.provinceId)!,
                        "City Input" : CDRegion.getRegionNameWithID(userProfileData.regionId)!
                    ]
                    Mixpanel.sharedInstance().people.set(p)
                    var shippingArr : [String] = []
                    var shippingArrName : [String] = []
                    for i in 0 ..< data["shipping_preferences_ids"].count {
                        let s : String = data["shipping_preferences_ids"][i].string!
                        shippingArr.append(s)
                        if let sName = CDShipping.getShippingCompleteNameWithId(s) {
                            shippingArrName.append(sName)
                        }
                    }
                    var pt = [String : AnyObject]()
                    pt["Shipping Options"] = shippingArrName as AnyObject?
                    pt["Phone"] = userProfileData.phone as AnyObject?
                    Mixpanel.trackEvent(MixpanelEvent.SetupAccount, properties: pt as [AnyHashable: Any])
                    let pt2 = [
                        "Activation Screen" : "Setup Account"
                    ]
                    Mixpanel.trackEvent(MixpanelEvent.ReferralUsed, properties: pt2)
                     */
                    
                    // Prelo Analytic - Setup Profile
                    let backgroundQueue = DispatchQueue(label: "com.prelo.ios.PreloAnalytic",
                                                        qos: .background,
                                                        target: nil)
                    backgroundQueue.async {
                        print("Work on background queue")
                        var shippingArrName : Array<String> = []
                        for i in 0 ..< data["shipping_preferences_ids"].count {
                            let s : String = data["shipping_preferences_ids"][i].string!
                            if let sName = CDShipping.getShippingCompleteNameWithId(s) {
                                shippingArrName.append(sName)
                            }
                        }
                        
                        let address = [
                            "Province" : CDProvince.getProvinceNameWithID(userProfileData.provinceId)!,
                            "Region" : CDRegion.getRegionNameWithID(userProfileData.regionId)!,
                            "Subdistrict" : userProfileData.subdistrictName,
                        ] as [String : Any]
                        
                        let pdata = [
                            "Username" : userProfileData.username,
                            "Email" : userProfileData.email,
                            "Gender" : userProfileData.gender,
                            "Address" : address,
                            "Shipping Options" : shippingArrName
                        ] as [String : Any]
                        
                        AnalyticManager.sharedInstance.sendWithUserId(eventType: PreloAnalyticEvent.SetupAccount, data: pdata, previousScreen: self.screenBeforeLogin, loginMethod: self.loginMethod, userId: userProfileData.id)
                        
                        User.UpdateUsernameHistory(userProfileData.username)
                        User.SetLoginMethod(self.loginMethod)
                        
                        // Prelo Analytic - Update User - Init
                        AnalyticManager.sharedInstance.initUser(userProfileData: userProfileData)
                    }
                    
                    let phoneVerificationVC = Bundle.main.loadNibNamed(Tags.XibNamePhoneVerification, owner: nil, options: nil)?.first as! PhoneVerificationViewController
                    phoneVerificationVC.userRelatedDelegate = self.userRelatedDelegate
                    phoneVerificationVC.userId = self.userId
                    phoneVerificationVC.userToken = self.userToken
                    phoneVerificationVC.userEmail = userProfileData.email // Tidak menggunakan 'self.userEmail' karena mungkin kosong dan baru diset di halaman ini
                    phoneVerificationVC.isShowBackBtn = false
                    phoneVerificationVC.loginMethod = self.loginMethod
                    phoneVerificationVC.noHpToVerify = userProfileData.phone //userPhone!
                    phoneVerificationVC.userProfileData = userProfileData
                    phoneVerificationVC.previousScreen = PageName.SetupAccount
                    self.navigationController?.pushViewController(phoneVerificationVC, animated: true)
                } else {
                    self.btnApply.isEnabled = true
                }
                
                // Delete token because user is considered not logged in
                // Kalo API setUserPreferencedCategories diaktifkan, baris ini perlu dihapus karna nanti settoken to nil dilakukan setelah API tsb
                User.SetToken(nil)
            }
        }
    }
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
}

class ShippingCell : UITableViewCell {
    
    @IBOutlet var lblCheckbox: UILabel!
    @IBOutlet var lblName: UILabel!
    
    var isShippingSelected : Bool = false
    
    override func prepareForReuse() {
        setShippingDeselected()
        lblName.text = ""
    }
    
    func cellTapped() {
        isShippingSelected = !isShippingSelected
        if (isShippingSelected) {
            setShippingSelected()
        } else {
            setShippingDeselected()
        }
    }
    
    func setShippingSelected() {
        isShippingSelected = true
        lblCheckbox.text = "";
        lblCheckbox.font = AppFont.prelo2.getFont(19)!
        lblCheckbox.textColor = Theme.ThemeOrange
    }
    
    func setShippingDeselected() {
        isShippingSelected = false
        lblCheckbox.text = "";
        lblCheckbox.font = AppFont.preloAwesome.getFont(24)!
        lblCheckbox.textColor = Theme.GrayLight
    }
}
