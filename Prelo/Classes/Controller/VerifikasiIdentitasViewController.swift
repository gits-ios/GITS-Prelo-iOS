//
//  VerifikasiIdentitasViewController.swift
//  Prelo
//
//  Created by Prelo on 6/19/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire
import DropDown

class VerifikasiIdentitasViewController: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, VerifikasiImagePreviewDelegate, UIScrollViewDelegate {
    // yang mana yang dipilih
    var isKartuIdentitasClicked: Bool = false
    var isKartuKeluargaClicked: Bool = false
    var isInstitusiImageClicked: Bool = false
    
    // kartu identitas
    @IBOutlet weak var btnKartuIdentitas: UIButton!
    @IBOutlet weak var imgKartuIdentitas: UIImageView!
    var isKartuIdentitasPictUpdated: Bool = false
    @IBOutlet weak var imgPilihFotoIdentitas: UIImageView!
    
    // kartu keluarga
    @IBOutlet weak var btnKartuKeluarga: UIButton!
    @IBOutlet weak var imgKartuKeluarga: UIImageView!
    var isKartuKeluargaPictUpdated: Bool = false
    @IBOutlet weak var imgPilihFotoKK: UIImageView!
    
    // institusi
    @IBOutlet weak var btnInstitusiImage: UIButton!
    @IBOutlet weak var imgInstitusiImage: UIImageView!
    var isInstitusiImagePictUpdated: Bool = false
    @IBOutlet weak var imgPilihFotoInstitusi: UIImageView!
    
    let dropDown = DropDown()
    var selectedIndex = 0
    var isNeedSetup = false
    @IBOutlet weak var lblInstansi: UILabel!
    @IBOutlet weak var txtInstitusi: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loadingPanel: UIView!
    
    @IBOutlet weak var vwWarning: UIView!
    @IBOutlet weak var consHeightVwWarning: NSLayoutConstraint!
    @IBOutlet weak var lblWarning: UILabel!
    @IBOutlet weak var consViewIdentitasTop: NSLayoutConstraint!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var imgContohFoto: UIImageView!
    
    var isNeedReload = false
    var isEdit = false
    var isEditImageKK = false
    var isEditImageIdentitas = false
    var isEditImageInstitusi = false
    var tempSelectedIndex = 0
    var tempTxtInstitusi = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self;
        scrollView.isScrollEnabled = YES;
        self.scrollView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        self.scrollView.contentSize = self.contentView.bounds.size
        self.title = "Verifikasi Identitas"
        self.hideKeyboardWhenTappedAround()
        initiateField()
        getUserRentData()
    }
    
    func initiateField(){
        print("Selected Index")
        print(selectedIndex)
        if(selectedIndex == 0){
            self.imgContohFoto.image = nil
        }
        if(selectedIndex == 1){
            self.imgContohFoto.image = UIImage(named: "arrow_right.png")
        } else if(selectedIndex == 2){
            self.imgContohFoto.image = UIImage(named: "arrow_down.png")
        } else if(selectedIndex == 3){
            self.imgContohFoto.image = UIImage(named: "arrow_left.png")
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupDropdownInstitusi()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(imgKartuIdentitas.image != nil){
            imgPilihFotoIdentitas.isHidden = true
        } else if(imgKartuIdentitas.image == nil){
            imgPilihFotoIdentitas.isHidden = false
        }
        if(imgKartuKeluarga.image != nil){
            imgPilihFotoKK.isHidden = true
        } else if(imgKartuKeluarga.image == nil){
            imgPilihFotoKK.isHidden = false
        }
        if(imgInstitusiImage.image != nil){
            imgPilihFotoInstitusi.isHidden = true
        } else if(imgInstitusiImage.image == nil){
            imgPilihFotoInstitusi.isHidden = false
        }
    }
    
    
    @IBOutlet weak var dropDownInstitusi: UIButton!
    @IBAction func dropDownInstitusiPressed(_ sender: Any) {
        setupDropdownInstitusi()
        dropDown.hide()
        dropDown.show()
        
    }
    
    @IBAction func pilihKartuIdentitasPressed(_ sender: UIButton) {
        self.isKartuIdentitasClicked = true
        isKartuKeluargaClicked = false
        isInstitusiImageClicked = false
        if(imgKartuIdentitas.image == nil){
            imagePicker()
        } else {
            let verifikasiImagePreviewVC = Bundle.main.loadNibNamed(Tags.XibNameVerifikasiImagePreview, owner: nil, options: nil)?.first as! VerifikasiImagePreview
            verifikasiImagePreviewVC.index = 1
            let ap = APImage()
            ap.image = imgKartuIdentitas.image
            verifikasiImagePreviewVC.apImage = ap
            verifikasiImagePreviewVC.fullScreenDelegate = self
            self.navigationController?.pushViewController(verifikasiImagePreviewVC, animated: true)
        }
    }
    
    @IBAction func pilihKartuKeluargaPressed(_ sender: UIButton) {
        isKartuIdentitasClicked = false
        isKartuKeluargaClicked = true
        isInstitusiImageClicked = false
        if(imgKartuKeluarga.image == nil){
            imagePicker()
        } else {
            let verifikasiImagePreviewVC = Bundle.main.loadNibNamed(Tags.XibNameVerifikasiImagePreview, owner: nil, options: nil)?.first as! VerifikasiImagePreview
            verifikasiImagePreviewVC.index = 1
            let ap = APImage()
            ap.image = imgKartuKeluarga.image
            verifikasiImagePreviewVC.apImage = ap
            verifikasiImagePreviewVC.fullScreenDelegate = self
            self.navigationController?.pushViewController(verifikasiImagePreviewVC, animated: true)
        }
    }
    
    @IBAction func pilihInstitusiImagePressed(_ sender: UIButton) {
        isKartuIdentitasClicked = false
        isKartuKeluargaClicked = false
        isInstitusiImageClicked = true
        if(imgInstitusiImage.image == nil){
            imagePicker()
        } else {
            let verifikasiImagePreviewVC = Bundle.main.loadNibNamed(Tags.XibNameVerifikasiImagePreview, owner: nil, options: nil)?.first as! VerifikasiImagePreview
            verifikasiImagePreviewVC.index = 1
            let ap = APImage()
            ap.image = imgInstitusiImage.image
            verifikasiImagePreviewVC.apImage = ap
            verifikasiImagePreviewVC.fullScreenDelegate = self
            self.navigationController?.pushViewController(verifikasiImagePreviewVC, animated: true)
        }
    }
    
    func imagePicker(){
        let i = UIImagePickerController()
        i.sourceType = .photoLibrary
        i.delegate = self
        
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            let a = UIAlertController(title: "Ambil gambar dari:", message: nil, preferredStyle: .actionSheet)
            a.popoverPresentationController?.sourceView = self.btnKartuIdentitas
            a.popoverPresentationController?.sourceRect = self.btnKartuIdentitas.bounds
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
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if (isKartuIdentitasClicked){
            if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.imgKartuIdentitas.image = img
                self.isKartuIdentitasPictUpdated = true
            }
        } else if(isKartuKeluargaClicked){
            if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.imgKartuKeluarga.image = img
                self.isKartuKeluargaPictUpdated = true
            }
        } else if(isInstitusiImageClicked){
            if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.imgInstitusiImage.image = img
                self.isInstitusiImagePictUpdated = true
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func setupDropdownInstitusi() {
        //dropDown = DropDown()
        
        // The list of items to display. Can be changed dynamically                        
        dropDown.dataSource = ["Pilih Institusi","Sekolah/Kuliah", "Kantor", "Kantor kelurahan/kecamatan sesuai KTP/KK"]
        lblInstansi.text = dropDown.dataSource[selectedIndex]
        
        // Action triggered on selection
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            if index != self.selectedIndex {
                if index < 4 {
                    self.isNeedSetup = false
                    self.selectedIndex = index
                    self.lblInstansi.text = self.dropDown.dataSource[self.selectedIndex]
                    print("ini index "+String(index))
                    if(index == 0){
                        self.imgContohFoto.image = nil
                    }
                    if(index == 1){
                        self.imgContohFoto.image = UIImage(named: "arrow_right.png")
                    } else if(index == 2){
                        self.imgContohFoto.image = UIImage(named: "arrow_down.png")
                    } else if(index == 3){
                        self.imgContohFoto.image = UIImage(named: "arrow_left.png")
                    }
                } else {
                    self.isNeedSetup = true
                    self.selectedIndex = 4
                }
            }
        }
        
        dropDown.textFont = UIFont.systemFont(ofSize: 14)
        
        dropDown.cellHeight = 40
        
        dropDown.selectRow(at: self.selectedIndex)
        
        dropDown.direction = .bottom
    }
    
    func isValidateField() -> Bool{
        if(imgKartuIdentitas.image == nil){
            Constant.showDialog("Perhatian", message: "Sertakan foto kartu identitas yang masih berlaku")
            return false
        }
        if(imgKartuKeluarga.image == nil){
            Constant.showDialog("Perhatian", message: "Sertakan foto kartu keluarga yang masih berlaku")
            return false
        }
        if(lblInstansi.text == "Pilih Institusi"){
            Constant.showDialog("Perhatian", message: "Pilih institusi yang kamu inginkan")
            return false
        }
        if(txtInstitusi.text == ""){
            Constant.showDialog("Perhatian", message: "Masukkan nama institusi yang kamu pilih")
            return false
        }
        if(imgInstitusiImage.image == nil){
            Constant.showDialog("Perhatian", message: "Sertakan foto kamu di depan institusi yang kamu pilih")
            return false
        }
        return true
    }
    
    @IBAction func ajukanVerifikasiPressed(_ sender: Any) {
        if(isValidateField()){
            setEditUserRentData()
        }
    }
    func getUserRentData(){
        self.showLoading()
        isNeedReload = true
        let _ = request(APIMe.getUserRentData).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Rent Data")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if(data.isEmpty){
                    self.isEdit = false
                    self.vwWarning.isHidden = true
                    self.hideLoading()
                } else {
                    self.isEdit = true
                    
                    if(data["verification_status"] == 0) {
                        self.vwWarning.isHidden = true
                    } else if (data["verification_status"] == 1) {
                        self.vwWarning.isHidden = false
                        self.consHeightVwWarning.constant = 68
                        self.consViewIdentitasTop.constant = 80
                        
                        let text1 = "Verifikasi ditolak karena "
                        var lblWarningText = NSMutableAttributedString(string:text1)
                        
                        var commentAdmin  = data["admin_comment"].string!
                        var attrs = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 12)]
                        
                        var attributedStringCommentAdmin = NSMutableAttributedString(string:commentAdmin, attributes:attrs)
                        
                        let text2 = ". Mohon upload ulang dan ajukan verifikasi kembali."
                        var normalString2 = NSMutableAttributedString(string:text2)
                        
                        lblWarningText.append(attributedStringCommentAdmin)
                        lblWarningText.append(normalString2)
                        
                        self.lblWarning.attributedText = lblWarningText
                    
                    } else if (data["verification_status"] == 2) {
                        self.vwWarning.isHidden = false
                        self.consHeightVwWarning.constant = 68
                        self.consViewIdentitasTop.constant = 80
                        self.lblWarning.text = "Jika kamu mengubah data yang sudah dimasukkan, maka transaksi sewa selanjutnya baru dapat dilakukan jika sudah lolos verifikasi ulang"
                    }
                    
                    if let typeInstitution = data["institution_type"].int{
                        if(data["institution_type"].int! == 0){
                            self.selectedIndex = 1
                            self.lblInstansi.text = "Sekolah/Kuliah"
                        } else if(data["institution_type"].int! == 1){
                            self.selectedIndex = 2
                            self.lblInstansi.text = "Kantor"
                        } else if(data["institution_type"].int! == 2){
                            self.selectedIndex = 3
                            self.lblInstansi.text = "Kantor kelurahan/kecamatan sesuai KTP/KK"
                        }
                        self.selectedIndex = (data["institution_type"].int!) + 1
                        self.tempSelectedIndex = (data["institution_type"].int!) + 1
                        self.txtInstitusi.text = data["institution_name"].string!
                        self.tempTxtInstitusi = data["institution_name"].string!
                    }
                    
                    if let arr = data["identity_verification"].array {
                        if let url = NSURL(string: arr[0]["url"].string!) {
                            if let data = NSData(contentsOf: url as URL) {
                                self.imgKartuIdentitas.image = UIImage(data: data as Data)
                            }
                        }
                        if let url = NSURL(string: arr[1]["url"].string!) {
                            if let data = NSData(contentsOf: url as URL) {
                                self.imgKartuKeluarga.image = UIImage(data: data as Data)
                            }
                        }
                        
                        if let url = NSURL(string: arr[2]["url"].string!) {
                            if let data = NSData(contentsOf: url as URL) {
                                self.imgInstitusiImage.image = UIImage(data: data as Data)
                            }
                        }
                    }
                    self.initiateField()
                    self.hideLoading()
                }
            }
        }
    }
    func checkEdit() -> Bool{
        print("check edit")
        if(isEditImageKK || isEditImageInstitusi || isEditImageIdentitas || (selectedIndex != tempSelectedIndex || txtInstitusi.text != tempTxtInstitusi)){
            return true
        } else {
            return false
        }
    }
    
    var images : [AnyObject] = [NSNull(), NSNull(), NSNull()]
    
    func setEditUserRentData(){
        self.showLoading()
        let url : String
        if(isEdit){
            if(checkEdit()){
                url = "\(AppTools.PreloBaseUrl)/api/me/edit_rent_data"
                setAPI(url: url)
            } else {
                Constant.showDialog("Perhatian", message: "Anda belum melakukan perubahan apapun")
                self.hideLoading()
            }
        } else {
            url = "\(AppTools.PreloBaseUrl)/api/me/set_rent_data"
            setAPI(url: url)
        }
    }
    
    func setAPI(url: String){
        let param = [
            "institution_type":selectedIndex - 1,
            "institution_name":txtInstitusi.text == nil ? "" : txtInstitusi.text!
            ] as [String : Any]
        let images = [
            "image1": imgKartuIdentitas.image!,
            "image2": imgKartuKeluarga.image!,
            "image3": imgInstitusiImage.image!
            ] as [String : Any]
        
        let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
        
        AppToolsObjC.sendMultipart(param, imagesDict: images, withToken: User.Token!, andUserAgent: userAgent!, to: url, success: { op, res in
            print("Edit verifikasi res = \(res)")
            print("berhasil")
            self.hideLoading()
            Constant.showDialog("Edit Verifikasi", message: "Berhasil")
            self.navigationController?.popViewController(animated: true)
        }, failure: { op, err in
            print((err ?? "")) // failed
            Constant.showDialog("Edit Verifikasi", message: "Gagal mengupload data")//:err.description)
            self.hideLoading()
        })
    }
    
    func imageFullScreenDidReplace(_ controller: VerifikasiImagePreview, image: APImage, isCamera: Bool, name: String, isEditImage: Bool) {
        if let i = image.image
        {
            print("didreplace")
            print(isEditImage)
            if(isKartuKeluargaClicked){
                self.imgKartuKeluarga.image = i
                self.isEditImageKK = isEditImage
            } else if (isKartuIdentitasClicked){
                self.imgKartuIdentitas.image = i
                self.isEditImageIdentitas = isEditImage
            } else if (isInstitusiImageClicked){
                self.imgInstitusiImage.image = i
                self.isEditImageInstitusi = isEditImage
            }
        } else {
            //Constant.showBadgeDialog("Perhatian", message: "Terjadi kesalahan saat memuat gambar", badge: "warning", view: self, isBack: false)
            Constant.showDialog("Perhatian", message: "Terjadi kesalahan saat memuat gambar")
        }
        
    }
    
    func imageFullScreenDidDelete(_ controller: VerifikasiImagePreview) {
        if(isKartuKeluargaClicked){
            self.imgKartuKeluarga.image = nil
        } else if (isKartuIdentitasClicked){
            self.imgKartuIdentitas.image = nil
        } else if (isInstitusiImageClicked){
            self.imgInstitusiImage.image = nil
        }
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(VerifikasiIdentitasViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showLoading(){
        print("loading")
        self.loadingPanel.isHidden = false
    }
    func hideLoading(){
        print("loading ilang")
        self.loadingPanel.isHidden = true
    }
}
