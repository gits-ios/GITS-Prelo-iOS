//
//  AddProductViewController2.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CoreData
import Alamofire

typealias EditDoneBlock = () -> ()

// MARK: - class AddProductVC2

class AddProductViewController2: BaseViewController, UIScrollViewDelegate, UITextViewDelegate, UIActionSheetDelegate, /* AVIARY IS DISABLED AdobeUXImageEditorViewControllerDelegate,*/ UserRelatedDelegate, AKPickerViewDataSource, AKPickerViewDelegate, AddProductImageFullScreenDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UITextFieldDelegate
{

    // MARK: - Properties
    
    @IBOutlet var txtName : UITextField!
    @IBOutlet var txtAlasanJual : UITextField!
    @IBOutlet var txtSpesial : UITextField!
    @IBOutlet var txtDeskripsiCacat : UITextField!
    @IBOutlet var txtDescription : SZTextView!
    var growerName : GrowingTextViewHandler?
    var growerDesc : GrowingTextViewHandler?
    
    @IBOutlet var conHeightTxtName : NSLayoutConstraint!
    @IBOutlet var conHeightTxtDesc : NSLayoutConstraint!
    @IBOutlet var conHeightWeightView : NSLayoutConstraint!
    @IBOutlet var conHeightCacat : NSLayoutConstraint!
    @IBOutlet var conHeightSize : NSLayoutConstraint!
    
    // For luxury brand
    @IBOutlet var conTopOngkirGroup: NSLayoutConstraint! // Set to 498 if isLuxury, 8 if not
    @IBOutlet var groupVerifAuth: UIView!
    @IBOutlet var groupKelengkapan: UIView!
    @IBOutlet var txtLuxStyleName: UITextField!
    @IBOutlet var txtLuxSerialNumber: UITextField!
    @IBOutlet var txtLuxLokasiBeli: UITextField!
    @IBOutlet var txtLuxTahunBeli: UITextField!
    @IBOutlet var lblChkOriginalBox: UILabel!
    @IBOutlet var lblChkOriginalDustbox: UILabel!
    @IBOutlet var lblChkReceipt: UILabel!
    @IBOutlet var lblChkAuthCard: UILabel!
    var isOriginalBoxChecked = false
    var isOriginalDustboxChecked = false
    var isReceiptChecked = false
    var isAuthCardChecked = false
    var isCategWomenOrMenSelected = false
    
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var fakeScrollView : UIScrollView!
    @IBOutlet var dummyTitles : [UIView] = []
    @IBOutlet var imageViews : [UIImageView] = []
    @IBOutlet var fakeImageViews : [UIImageView] = []
    @IBOutlet var weightViews : [BorderedView] = []
    @IBOutlet var ongkirViews : [BorderedView] = []
    
    @IBOutlet var txtOldPrice : UITextField!
    @IBOutlet var txtNewPrice : UITextField!
    @IBOutlet var txtWeight : UITextField!
    @IBOutlet var txtCommission: UITextField!
    
    @IBOutlet var captionKondisi : UILabel!
    @IBOutlet var captionMerek : UILabel!
    @IBOutlet var captionKategori : UILabel!
    
    @IBOutlet var lblSubmit: UILabel!
    @IBOutlet var btnSubmit : UIButton!
    @IBOutlet var fakeBtnSubmit : UIButton!
    
    @IBOutlet var sizePicker : AKPickerView!
    @IBOutlet var txtSize : UITextField!
    
    @IBOutlet var captionSize1 : UILabel!
    @IBOutlet var captionSize2 : UILabel!
    @IBOutlet var captionSize3 : UILabel!
    
    @IBOutlet var captionImagesMakeSure : UILabel!
    @IBOutlet var captionImagesMakeSureFake : UILabel!
    
    @IBOutlet var btnDelete : UIButton!
    @IBOutlet var conHeightBtnDelete : NSLayoutConstraint!
    @IBOutlet var conMarginBtnDelete : NSLayoutConstraint!
    
    @IBOutlet var photosGroupView: UIView!
    
    @IBOutlet weak var ivImage: UIImageView!
    
    // Title icons
    @IBOutlet var imgTitleIcons : [UIImageView]!
    
    var sizes : Array<String> = []
    
    var productCategoryId = ""
    var kodindisiId = ""
    var merekId = ""
    var merekIsLuxury = false
    var freeOngkir = 0
    
    var editProduct : ProductDetail?
    var editMode = false
    var editDoneBlock : EditDoneBlock = {}
    var images : [AnyObject] = [NSNull(), NSNull(), NSNull(), NSNull(), NSNull()]
    var rm_image1 = 0
    var rm_image2 = 0
    var rm_image3 = 0
    var rm_image4 = 0
    var rm_image5 = 0
    var updt_image1 = 0
    var updt_image2 = 0
    var updt_image3 = 0
    var updt_image4 = 0
    var updt_image5 = 0
    
    var screenBeforeAddProduct = ""
    
    var localPath : Array<String> = ["", "", "", "", ""]
    var isCamera : Array<Bool> = [ false, false, false, false, false ]
    var imageOrientation : Array<Int> = [0, 0, 0, 0, 0]
    
    var isImage : Bool = false
    
    
    var notPicked = true
    var allowLaunchLogin = true
    
    var topBannerText: String!
    @IBOutlet var vwTopBannerParent: UIView!
    @IBOutlet var consHeightTopBannerParent: NSLayoutConstraint!
    
    var draftProduct : CDDraftProduct?
    var draftMode = false
    
    var uniqueCodeString : String!
    
    // for refresh product sell list when product deleted
    weak var delegate: MyProductDelegate?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captionImagesMakeSure.numberOfLines = 0
        captionImagesMakeSureFake.numberOfLines = 0
        
        let makeSureText = "Pastikan orientasi foto-foto di atas sudah tegak"
        let attMakeSureText = NSMutableAttributedString(string: makeSureText)
//        attMakeSureText.addAttributes([NSFontAttributeName:UIFont.italicSystemFont(ofSize: 14)], range: (makeSureText as NSString).range(of: "preview"))
        
        captionImagesMakeSure.attributedText = attMakeSureText
        captionImagesMakeSureFake.attributedText = attMakeSureText
        
        /*if (AppTools.isDev)
        {
            txtName.text = "qwerty"
            txtSpesial.text = "asdf"
            txtNewPrice.text = "1000"
            txtOldPrice.text = "1500"
            txtAlasanJual.text = "zxcvbnm"
            txtDescription.text = "asdkalskfas"
        }*/

        // Do any additional setup after loading the view.
        
        // make corner init image category
        self.ivImage.layer.cornerRadius = 5.0;
        self.ivImage.layer.masksToBounds = YES;
        
        
//        sizes = ["8\nS\n10", "8\nS\n10", "8\nS\n10", "8\nS\n10", "8\nS\n10", "8\nS\n10", "8\nS\n10"]
        conHeightSize.constant = 0
        sizePicker.superview?.isHidden = true
        
//        print(editProduct?.status)
//        print(editProduct?.isFakeApprove)
//        print(editProduct?.isFakeApproveV2)
        
        if (self.editMode) {
            lblSubmit.isHidden = true
//            if (editProduct?.isFakeApprove)! && editProduct?.status == 2 { // status 2 := under review --> fa 1 /  2 disabled
//                // do nothing --> lblSubmit.isHidden = false // aktif -> edit
//                lblSubmit.isHidden = true // fake approve -> edit
//            } else if (editProduct?.isFakeApproveV2)! {
//                lblSubmit.isHidden = true
//            }
            
//            if ((editProduct?.isFakeApprove)! || (editProduct?.isFakeApproveV2)!) {
//                lblSubmit.isHidden = true
//            }
        } else {
            lblSubmit.text = "Klik lanjutkan untuk menentukan charge Prelo yang kamu mau"
        }
        
        fakeScrollView.backgroundColor = .white
        if (editMode)
        {
            fakeScrollView.isHidden = true
            btnDelete.addTarget(self, action: #selector(AddProductViewController2.askDeleteProduct), for: .touchUpInside)
        } else if (draftMode) {
            fakeScrollView.isHidden = true
            btnDelete.addTarget(self, action: #selector(AddProductViewController2.askDeleteProduct), for: .touchUpInside)
        } else
        {
            btnDelete.isHidden = true
            conHeightBtnDelete.constant = 0
            conMarginBtnDelete.constant = 0
        }
        
        sizePicker.dataSource = self
        sizePicker.delegate = self
        
        sizePicker.font = UIFont.systemFont(ofSize: 16)
        sizePicker.highlightedFont = UIFont(name: "HelveticaNeue-Light", size: 16)
        sizePicker.highlightedTextColor = Theme.PrimaryColor
        sizePicker.interitemSpacing = 20
        sizePicker.fisheyeFactor = 0.001
        sizePicker.pickerViewStyle = AKPickerViewStyle.style3D
        sizePicker.isMaskDisabled = false
        
        txtWeight.isHidden = true
        
        txtName.delegate = self
        txtName.placeholder = "mis: iPod 5th Gen"
        txtDescription.placeholder = "Spesifikasi barang (Opsional)\nmis: 32 GB, dark blue, lightning charger"
        
//        txtName.fadeTime = 0.2
        txtDescription.fadeTime = 0.2
        
//        growerName = GrowingTextViewHandler(textView: txtName, withHeightConstraint: conHeightTxtName)
        growerName?.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 4)
        
        txtDescription.layoutIfNeeded()
        growerDesc = GrowingTextViewHandler(textView: txtDescription, withHeightConstraint: conHeightTxtDesc)
        growerDesc?.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 100)
        
        selectWeight(nil)
        selectOngkir(nil)
        
        var index = 0
        for i in imageViews
        {
            i.tag = index
            i.contentMode = UIViewContentMode.scaleAspectFill
            i.clipsToBounds = true
            index += 1
            i.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(AddProductViewController2.imageTapped(_:)))
            i.addGestureRecognizer(tap)
        }
        
        index = 0
        for i in fakeImageViews
        {
            i.tag = index
            i.contentMode = UIViewContentMode.scaleAspectFill
            i.clipsToBounds = true
            index += 1
            i.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(AddProductViewController2.imageTapped(_:)))
            i.addGestureRecognizer(tap)
        }
        
        for v in dummyTitles
        {
            let tap = UITapGestureRecognizer(target: self, action: #selector(AddProductViewController2.hideFakeScrollView))
            v.addGestureRecognizer(tap)
        }
        
        if (editMode)
        {
            self.title = PageName.EditProduct
            self.btnSubmit.setTitle("SIMPAN", for: UIControlState())
            self.fakeBtnSubmit.setTitle("SIMPAN", for: UIControlState())
            
            txtName.text = editProduct?.name
            txtDescription.text = editProduct?.json["_data"]["description"].string
            if let weight = editProduct?.json["_data"]["weight"].int
            {
                txtWeight.text = String(weight)
                txtWeight.isHidden = false
                conHeightWeightView.constant = 158
                var index = 0
                if (weight >= 1000 && weight < 2000)
                {
                    index = 1
                } else if (weight >= 2000)
                {
                    index = 2
                }
                
                selectWeightByIndex(index, overrideWeight: false)
            }
            
            if let ongkir = editProduct?.json["_data"]["free_ongkir"].int
            {
                freeOngkir = (ongkir == 1) ? 1 : 0
                let index = (ongkir == 1) ? 0 : 1
                selectOngkirByIndex(index)
            }
            
            if let oldPrice = editProduct?.json["_data"]["price_original"].int
            {
                txtOldPrice.text = String(oldPrice)
            }
            
            if let oldPrice = editProduct?.json["_data"]["price"].int
            {
                txtNewPrice.text = String(oldPrice)
            }
            
            if let commission = editProduct?.json["_data"]["commission"].int
            {
                txtCommission.text = "\(String(commission))%"
            }
            
            if let category_breadcrumbs = editProduct?.json["_data"]["category_breadcrumbs"].array
            {
                for i in 0...category_breadcrumbs.count-1
                {
                    let c = category_breadcrumbs[i]
                    productCategoryId = c["_id"].string!
                    captionKategori.text = c["name"].string!
                    
                    if (c["level"].intValue == 1) {
                        if (c["_id"].stringValue == "55de6dbc5f6522562a2c73ef" || c["_id"].stringValue == "55de6dbc5f6522562a2c73f0") {
                            self.isCategWomenOrMenSelected = true
                        } else {
                            self.isCategWomenOrMenSelected = false
                        }
                    }
                }
            }
            
            if let kondisi = editProduct?.json["_data"]["condition"].string, let kondisiId = editProduct?.json["_data"]["product_condition_id"].string
            {
                kodindisiId = kondisiId
                captionKondisi.text = kondisi
            }
            
            if let brnd = editProduct?.json["_data"]["brand"].string
            {
                captionMerek.text = brnd
            }
            
            if let brndId = editProduct?.json["_data"]["brand_id"].string
            {
                merekId = brndId
            }
            
            if let arr = editProduct?.json["_data"]["original_picts"].arrayObject
            {
                for i in 0...arr.count-1
                {
                    let o = arr[i]
                    if let s = o as? String
                    {
                        imageViews[i].afSetImage(withURL: URL(string: s)!, withFilter: .none)
                    }
                }
            }
            
            self.txtSize.text = editProduct?.size
            
            let def = editProduct?.defectDescription
            if (def != "")
            {
                self.txtDeskripsiCacat.text = def
                self.txtDeskripsiCacat.isHidden = false
                conHeightCacat.constant = 44
            }
            
            self.txtAlasanJual.text = editProduct?.sellReason
//            self.txtDeskripsiCacat.text = editProduct?.defectDescription
            self.txtSpesial.text = editProduct?.specialStory
            self.getSizes()
            
            // Luxury fields
            if let luxData = editProduct?.json["_data"]["luxury_data"] , luxData.count > 0 {
                self.merekIsLuxury = true
                
                // Show luxury fields
                self.groupVerifAuth.isHidden = false
                self.groupKelengkapan.isHidden = false
                self.conTopOngkirGroup.constant = 498 + 16
                
                // Set texts
                txtLuxStyleName.text = luxData["style_name"].stringValue
                txtLuxSerialNumber.text = luxData["serial_number"].stringValue
                txtLuxLokasiBeli.text = luxData["purchase_location"].stringValue
                txtLuxTahunBeli.text = luxData["purchase_year"].stringValue
                
                // Set checkboxes
                if (luxData["original_box"].bool == true) {
                    btnChkOriginalBoxPressed("" as AnyObject)
                }
                if (luxData["original_dustbox"].bool == true) {
                    btnChkOriginalDustboxPressed("" as AnyObject)
                }
                if (luxData["receipt"].bool == true) {
                    btnChkReceipt("" as AnyObject)
                }
                if (luxData["authenticity_card"].bool == true) {
                    btnChkAuthCard("" as AnyObject)
                }
            } else {
                // Hide luxury fields
                self.groupVerifAuth.isHidden = true
                self.groupKelengkapan.isHidden = true
                self.conTopOngkirGroup.constant = 8
            }
            
            setupTopBanner()
        }
        else if (draftMode)
        {
            self.title = PageName.AddProduct
            
            let product = draftProduct
            
            txtName.text = product?.name
            txtDescription.text = product?.descriptionText
            if var weight = product?.weight.int
            {
                weight = weight > 0 ? weight : 500
                txtWeight.text = String(weight)
                txtWeight.isHidden = false
                conHeightWeightView.constant = 158
                var index = 0
                if (weight >= 1000 && weight < 2000)
                {
                    index = 1
                } else if (weight >= 2000)
                {
                    index = 2
                }
                
                selectWeightByIndex(index, overrideWeight: false)
            }
            
            if let ongkir = product?.freeOngkir
            {
                freeOngkir = (ongkir == 1) ? 1 : 0
                let index = (ongkir == 1) ? 0 : 1
                selectOngkirByIndex(index)
            }
            
            if let oldPrice = product?.priceOriginal
            {
                txtOldPrice.text = oldPrice
            }
            
            if let oldPrice = product?.price
            {
                txtNewPrice.text = oldPrice
            }
            
            if let commission = product?.commission
            {
                txtCommission.text = commission
            }
            
            // category
            if (product?.categoryId != "" && product?.category != "") {
                productCategoryId = (product?.categoryId)!
                captionKategori.text = product?.category
                isCategWomenOrMenSelected = (product?.isCategWomenOrMenSelected)!
            }
            
            if let kondisi = product?.condition, let kondisiId = product?.conditionId
            {
                kodindisiId = kondisiId
                captionKondisi.text = kondisi
            }
            
            if let brnd = product?.brand
            {
                captionMerek.text = brnd
            }
            
            if let brndId = product?.brandId
            {
                merekId = brndId
            }
            
            if let arr = try? CDDraftProduct.getImagePaths((product?.localId)!)
            {
                let arrOr = CDDraftProduct.getImageOrientations((product?.localId)!)
                
                for i in 0...arr.count-1
                {
                    if let data = NSData(contentsOfFile: arr[i]){
                            if let imageUrl = UIImage(data: data as Data) {
                                
                                // save orientation
                                let img = UIImage(cgImage: imageUrl.cgImage!, scale: 1.0, orientation: UIImageOrientation(rawValue: arrOr[i])!)
                                imageViews[i].image = img  // you can use your imageUrl UIImage (note: imageUrl it is not an optional here)
                                images[i] = img
                                fakeImageViews[i].image = img
                            }
                        
                    }
                    localPath[i] = arr[i]
                    imageOrientation[i] = arrOr[i]
                }
            }
            
            self.txtSize.text = product?.size
            
            let def = product?.defectDescription
            if (def != "")
            {
                self.txtDeskripsiCacat.text = def
                self.txtDeskripsiCacat.isHidden = false
                conHeightCacat.constant = 44
            }
            
            self.txtAlasanJual.text = product?.sellReason
            self.txtSpesial.text = product?.specialStory
            
            if (product?.categoryId != "" && product?.category != "") {
                self.getSizes()
            }
            
            self.merekIsLuxury = (product?.isLuxury)!
            
            // Luxury fields
            if (product?.isLuxury)! {
                // Show luxury fields
                self.groupVerifAuth.isHidden = false
                self.groupKelengkapan.isHidden = false
                self.conTopOngkirGroup.constant = 498 + 16
                
                
                //  0  styleName : String
                //  1  serialNumber : String
                //  2  purchaseLocation : String
                //  3  purchaseYear : String
                //  4  originalBox : String
                //  5  originalDustbox : String
                //  6  receipt : String
                //  7  authenticityCard : String
                
                // Set texts
                txtLuxStyleName.text = product?.luxuryData_styleName
                txtLuxSerialNumber.text = product?.luxuryData_serialNumber
                txtLuxLokasiBeli.text = product?.luxuryData_purchaseLocation
                txtLuxTahunBeli.text = product?.luxuryData_purchaseYear
                
                // Set checkboxes
                if (product?.luxuryData_originalBox.contains("true") == true) {
                    btnChkOriginalBoxPressed("" as AnyObject)
                }
                if (product?.luxuryData_originalDustbox.contains("true") == true) {
                    btnChkOriginalDustboxPressed("" as AnyObject)
                }
                if (product?.luxuryData_receipt.contains("true") == true) {
                    btnChkReceipt("" as AnyObject)
                }
                if (product?.luxuryData_authenticityCard.contains("true") == true) {
                    btnChkAuthCard("" as AnyObject)
                }
            } else {
                // Hide luxury fields
                self.groupVerifAuth.isHidden = true
                self.groupKelengkapan.isHidden = true
                self.conTopOngkirGroup.constant = 8
            }
            
            hideFakeScrollView()
        }
        
        if (!draftMode) {
            // set init id
            
            let uniqueCode : TimeInterval = Date().timeIntervalSinceReferenceDate
            self.uniqueCodeString = uniqueCode.description
        }
        
        
        if (!editMode && !draftMode)
        {
            self.title = PageName.AddProduct
            self.btnSubmit.setTitle("LANJUTKAN", for: UIControlState())
            self.fakeBtnSubmit.setTitle("LANJUTKAN", for: UIControlState())
            
            // Hide luxury fields
            self.groupVerifAuth.isHidden = true
            self.groupKelengkapan.isHidden = true
            self.conTopOngkirGroup.constant = 8
        }
        
        self.btnSubmit.addTarget(self, action: #selector(AddProductViewController2.sendProduct), for: UIControlEvents.touchUpInside)
        self.fakeBtnSubmit.addTarget(self, action: #selector(AddProductViewController2.sendProduct), for: UIControlEvents.touchUpInside)
        self.btnSubmit.setTitle("Loading..", for: UIControlState.disabled)
        
        txtName.autocapitalizationType = .words
        txtAlasanJual.autocapitalizationType = .sentences
        txtSpesial.autocapitalizationType = .sentences
        txtDeskripsiCacat.autocapitalizationType = .sentences
        
        for i in 0..<imgTitleIcons.count {
            imgTitleIcons[i].image = imgTitleIcons[i].image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (self.editMode) {
            // Mixpanel
//            Mixpanel.trackPageVisit(PageName.EditProduct)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.EditProduct)
        } else {
            // Mixpanel
//            Mixpanel.trackPageVisit(PageName.AddProduct)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.AddProduct)
        }
        
        self.an_subscribeKeyboard(animations: { f, t, o in
            
            if (o)
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
                print("an_subscribeKeyboardWithAnimations")
                
            } else
            {
                self.scrollView.contentInset = UIEdgeInsets.zero
            }
            
            }, completion: {f in
                if let a = self.activeTextview
                {
                    let f = self.scrollView.convert(a.frame, from: a)
                    self.scrollView.scrollRectToVisible(f, animated: true)
                }
        })
        
        if (User.IsLoggedIn == false)
        {
            if (allowLaunchLogin)
            {
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            }
        } else if (notPicked && editMode == false)
        {
//            notPicked = false
//            self.pickImage(0, forceBackOnCancel: true, directToCamera : true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.an_unsubscribeKeyboard()
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        let title = editMode ? "Edit" : "Jual"
        
        
        var message = "Kamu yakin mau keluar dari \(title) Barang? "
        if title == "Edit" {
            message += "Seluruh perubahan akan dihapus"
        } else {
            message += "Seluruh keterangan yang telah diisi akan dihapus"
        }
        message += (self.fakeScrollView.isHidden == true || self.isImage == true) && self.editMode == false ? ". Ingin disimpan?" : ""
        
        let alert : UIAlertController = UIAlertController(title: " Perhatian", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        if (self.fakeScrollView.isHidden == false && self.isImage == false || self.editMode == true) {
            alert.addAction(UIAlertAction(title: "Tidak", style: .cancel, handler: nil))
        } else {
            alert.addAction(UIAlertAction(title: "Keluar", style: .cancel, handler: { action in
                
                self.navigationController?.popViewController(animated: true)
            }))
        }
        
        alert.addAction(UIAlertAction(title: (self.fakeScrollView.isHidden == false && self.isImage == false || self.editMode == true) ? "Ya" : "Simpan", style: .default, handler: { action in
            
            if ((self.fakeScrollView.isHidden == true || self.isImage == true) && self.editMode == false){
                
                // save the draft
                self.saveDraft(isBack: true)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }))
        
        let content =  " Perhatian"
        let attrStr = NSMutableAttributedString(string: content)
        
        attrStr.addAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16.0)], range: (content as NSString).range(of: "Perhatian"))
        
        attrStr.addAttributes([NSForegroundColorAttributeName:UIColor.orange], range: (content as NSString).range(of: ""))
        attrStr.addAttributes([NSFontAttributeName:UIFont(name: "preloAwesome", size: 16.0)!], range: (content as NSString).range(of: ""))
        
        alert.setValue(attrStr, forKeyPath: "attributedTitle")
        
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func showFAQ(_ sender : UIView?)
    {
        let w = self.storyboard?.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
        w.url = "https://prelo.co.id/syarat-ketentuan?ref=preloapp"
        w.titleString = "Syarat & Ketentuan"
        let n = BaseNavigationController()
        n.setViewControllers([w], animated: false)
        self.present(n, animated: true, completion: nil)
    }
    
    // MARK: - size functions
    
    func numberOfItems(in pickerView: AKPickerView!) -> Int {
        return sizes.count
    }
    
    func pickerView(_ pickerView: AKPickerView!, titleForItem item: Int) -> String! {
        return sizes[item]
    }
    
    func pickerView(_ pickerView: AKPickerView!, didSelectItem item: Int) {
        var s = sizes[item]
        s = s.replacingOccurrences(of: "\n", with: "/")
        if (String(s.characters.suffix(1)) == "/") {
            s = String(s.characters.dropLast())
        }
        txtSize.text = s
    }
    
    // MARK: - login functions
    
    func userLoggedIn() {
        
    }
    
    func userCancelLogin() {
        allowLaunchLogin = false
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Image processing
    
    func imageTapped(_ sender : UITapGestureRecognizer)
    {
        let index = sender.view!.tag
     
        if (imageViews[index].image == nil)
        {
            self.pickImage(index, forceBackOnCancel: false)
        } else {
            let a = self.storyboard?.instantiateViewController(withIdentifier: "AddProductFullscreen") as! AddProductImageFullScreen
            a.index = index
            let ap = APImage()
            ap.image = imageViews[index].image
            a.apImage = ap
            if (index == 0)
            {
                a.disableDelete = true
            }
            a.fullScreenDelegate = self
            let n = BaseNavigationController()
            n.setViewControllers([a], animated: false)
            self.present(n, animated: true, completion: nil)
            
//            let a = UIActionSheet(title: "Option", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: "Batal")
//            a.addButtonWithTitle("Ubah")
//            a.addButtonWithTitle("Ganti")
//            
//            if (index != 0)
//            {
//                a.addButtonWithTitle("Hapus")
//            }
//            a.tag = index
//            a.showInView(self.view)
        }
    }
    
    func imageFullScreenDidDelete(_ controller: AddProductImageFullScreen) {
        self.imageViews[controller.index].image = nil
        self.images[controller.index] = NSNull()
        switch (controller.index)
        {
        case 0:rm_image1 = 1
        case 1:rm_image2 = 1
        case 2:rm_image3 = 1
        case 3:rm_image4 = 1
        case 4:rm_image5 = 1
        default:print("")
        }
        
        self.localPath[controller.index] = ""
        self.imageOrientation[controller.index] = 0
    }
    
    func imageFullScreenDidReplace(_ controller: AddProductImageFullScreen, image: APImage, isCamera: Bool, name: String) {
        /** fix untuk : https://trello.com/c/ByNrWwTL
        ternyata walau masih ngirim multipart image, tapi kalo rm_imageN nya di isi 1, tetep di hapus si gambar nya.
        makadariitu, rm_imageN di kasih nilai kalaw bener2 di delete aja.
        */
        
//        switch (controller.index)
//        {
//        case 0:rm_image1 = 1
//        case 1:rm_image2 = 1
//        case 2:rm_image3 = 1
//        case 3:rm_image4 = 1
//        case 4:rm_image5 = 1
//        default:print("")
//        }
        switch (controller.index)
        {
        case 0:updt_image1 = 1
        case 1:updt_image2 = 1
        case 2:updt_image3 = 1
        case 3:updt_image4 = 1
        case 4:updt_image5 = 1
        default:print("")
        }
        if let i = image.image
        {
            imageViews[controller.index].image = i
            fakeImageViews[controller.index].image = i
            images[controller.index] = i
        } else {
            Constant.showBadgeDialog("Perhatian", message: "Terjadi kesalahan saat memuat gambar", badge: "warning", view: self, isBack: false)
        }
        
        if (self.editMode) {
            if ((editProduct?.isFakeApprove)! || (editProduct?.isFakeApproveV2)!) {
                lblSubmit.isHidden = true
            } else {
                self.lblSubmit.isHidden = false
            }
        }
        
        let img = images[controller.index] as! UIImage
        let index = controller.index
        // try save again if from album
        if isCamera == false {
            let imageName = name + "_" + index.string + "_" + (draftMode ? draftProduct?.localId : uniqueCodeString)!
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
            let localPath = documentDirectory.stringByAppendingPathComponent(imageName)
            
            // for temporer use
            let data = UIImageJPEGRepresentation(img, 1)
            do {
                try data?.write(to: URL(fileURLWithPath: localPath), options: .atomic)
            } catch {
                print("err")
            }
            
            let photoURL = NSURL(fileURLWithPath: localPath)
            
            self.localPath[index] = (photoURL.path)!
            self.isCamera[index] = false
            self.imageOrientation[index] = img.imageOrientation.rawValue
        
        } else {
            // reset
            self.localPath[index] = ""
            
            self.isCamera[index] = true
            
            // fast technique
            self.saveImages(self.images, index: index, uniqueCode: (draftMode ? draftProduct?.localId : uniqueCodeString)!)
        }

    }
    
    func actionSheet(_ actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == 1)
        {
            /* AVIARY IS DISABLED
            AdobeImageEditorCustomization.setToolOrder([kAdobeImageEditorCrop, kAdobeImageEditorOrientation])
            AdobeImageEditorCustomization.setLeftNavigationBarButtonTitle("")
            let u = AdobeUXImageEditorViewController(image: imageViews[actionSheet.tag].image)
            u.delegate = self
            self.presentViewController(u, animated: true, completion: nil)
            */
        } else if (buttonIndex == 2)
        {
            self.pickImage(actionSheet.tag, forceBackOnCancel: false)
        } else if (buttonIndex == 3)
        {
            self.imageViews[actionSheet.tag].image = nil
            self.fakeImageViews[actionSheet.tag].image = nil
            switch (actionSheet.tag)
            {
            case 0:rm_image1 = 1
            case 1:rm_image2 = 1
            case 2:rm_image3 = 1
            case 3:rm_image4 = 1
            case 4:rm_image5 = 1
            default:print("")
            }
        }
    }
    
    /* AVIARY IS DISABLED
    func photoEditor(editor: AdobeUXImageEditorViewController!, finishedWithImage image: UIImage!) {
        imageViews[editor.view.tag].image = image
        editor.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func photoEditorCanceled(editor: AdobeUXImageEditorViewController!) {
        editor.dismissViewControllerAnimated(true, completion: nil)
    }
    */
    
    func pickImage(_ index : Int, forceBackOnCancel : Bool, directToCamera : Bool = false)
    {
        let i = UIImagePickerController()
        i.sourceType = .photoLibrary
        i.delegate = self
        
        if (UIImagePickerController.isSourceTypeAvailable(.camera))
        {
            let a = UIAlertController(title: "Ambil gambar dari:", message: nil, preferredStyle: .actionSheet)
            a.popoverPresentationController?.sourceView = self.photosGroupView
            a.popoverPresentationController?.sourceRect = self.photosGroupView.bounds
            a.addAction(UIAlertAction(title: "Kamera", style: .default, handler: { act in
                i.sourceType = .camera
                self.present(i, animated: true, completion: {
                    i.view.tag = index
                })
            }))
            a.addAction(UIAlertAction(title: "Album", style: .default, handler: { act in
                self.present(i, animated: true, completion: {
                    i.view.tag = index
                })
            }))
            a.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in }))
            self.present(a, animated: true, completion: nil)
        } else
        {
            self.present(i, animated: true, completion: {
                i.view.tag = index
            })
        }
        
//        ImagePickerViewController.ShowFrom(self, maxSelect: 1, useAviary:true, diretToCamera : directToCamera, doneBlock: { imgs in
//            if (imgs.count > 0)
//            {
//                let a = imgs[0]
//                a.getImage({ img in
//                    if let i = img
//                    {
//                        self.imageViews[index].image = i
//                        self.fakeImageViews[index].image = i
//                        self.images[index] = i
//                    }
//                })
//                
//                switch (index)
//                {
//                case 0:self.rm_image1=0
//                case 1:self.rm_image2=0
//                case 2:self.rm_image3=0
//                case 3:self.rm_image4=0
//                case 4:self.rm_image5=0
//                default:print()
//                }
//
//            } else if (forceBackOnCancel)
//            {
//                self.navigationController?.popViewControllerAnimated(true)
//            }
//        })
    }
    
    // MARK: - camera
    
    func getDocumentsURL() -> NSURL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL as NSURL
    }
    
    func fileInDocumentsDirectory(filename: String) -> String {
        
        let fileURL = getDocumentsURL().appendingPathComponent(filename)
        return fileURL!.path
        
    }

    func saveImages(_ images: Array<AnyObject>, index: Int, uniqueCode: String) {
        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.Prelo",
                                            qos: .background,
                                            target: nil)
        backgroundQueue.async {
            print("Work on background queue -- Save Image \(index)")
            if self.isCamera[index] == true {
                if let img = (images[index] as! UIImage).resizeWithMaxWidthOrHeight(1600) {
                    
                    // save & get
                    let photoURLpath = CustomPhotoAlbum.sharedInstance.save(image: img)
                    let imageURL = NSURL(fileURLWithPath: self.fileInDocumentsDirectory(filename: photoURLpath))
                    let imageName = imageURL.path!.lastPathComponent + "_" + index.string + "_" + uniqueCode
                    let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
                    let localPath = documentDirectory.stringByAppendingPathComponent(imageName)
                    
                    // for temporer use
                    let data = UIImageJPEGRepresentation(img, 1)
                    do {
                        try data?.write(to: URL(fileURLWithPath: localPath), options: .atomic)
                    } catch {
                        print("err")
                    }
                    
                    let photoURL = NSURL(fileURLWithPath: localPath)
                    
                    self.localPath[index] = (photoURL.path)!
                    self.imageOrientation[index] = img.imageOrientation.rawValue
                }
            }
        }
    }
    
    // MARK: - UIImagePickerController functions
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            //print(img)
            let index = picker.view.tag
            self.imageViews[index].image = img
            self.fakeImageViews[index].image = img
            self.images[index] = img

            switch (index)
            {
            case 0:self.rm_image1=0
            case 1:self.rm_image2=0
            case 2:self.rm_image3=0
            case 3:self.rm_image4=0
            case 4:self.rm_image5=0
            default:print()
            }
            
            if (self.editMode) {
                if ((editProduct?.isFakeApprove)! || (editProduct?.isFakeApproveV2)!) {
                    lblSubmit.isHidden = true
                } else {
                    self.lblSubmit.isHidden = false
                }
            }
            
            // try save again if from album
            if picker.sourceType != .camera {
                let imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
                let imageName = imageURL.path!.lastPathComponent + "_" + index.string + "_" + (draftMode ? draftProduct?.localId : uniqueCodeString)!
                let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
                let localPath = documentDirectory.stringByAppendingPathComponent(imageName)
                
                // for temporer use
                let data = UIImageJPEGRepresentation(img, 1)
                do {
                    try data?.write(to: URL(fileURLWithPath: localPath), options: .atomic)
                } catch {
                    print("err")
                }
                
                let photoURL = NSURL(fileURLWithPath: localPath)
                
                self.localPath[index] = (photoURL.path)!
                self.isCamera[index] = false
                self.imageOrientation[index] = img.imageOrientation.rawValue
                
            } else {
                self.isCamera[index] = true
                
                // fast technique
                self.saveImages(self.images, index: index, uniqueCode: (draftMode ? draftProduct?.localId : uniqueCodeString)!)
            }
        }
        
        // set is image
        self.isImage = true
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.navigationBar.tintColor = UIColor.white
    }
    
    // MARK: - UITextfield & UITextView functions
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField.isEqual(self.txtName)) {
            if (editMode) {
                if ((editProduct?.isFakeApprove)! || (editProduct?.isFakeApproveV2)!) {
                    lblSubmit.isHidden = true
                } else {
                    self.lblSubmit.isHidden = false
                }
            }
        }
    }
    
    var activeTextview : UITextView?
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("textViewDidBeginEditing")
        activeTextview = textView
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        activeTextview = nil
    }
    
    func textViewDidChange(_ textView: UITextView) {
        growerName?.resizeTextView(withAnimation: false)
        growerDesc?.resizeTextView(withAnimation: false)
    }
    
    // MARK: - clean memory

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - scrollView functions
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func hideFakeScrollView()
    {
        fakeScrollView.isHidden = true
        scrollView.setContentOffset(fakeScrollView.contentOffset, animated: false)
    }
    
    // MARK: - button & related functions
    
    @IBAction func selectWeight(_ sender : UIButton?)
    {
        for w in weightViews
        {
            self.highlightWeightView(false, weightView: w)
        }
        
        if let b = sender
        {
            let w = weightViews[b.tag]
            self.highlightWeightView(true, weightView: w)
            
            if (txtWeight.isHidden)
            {
                txtWeight.isHidden = false
                conHeightWeightView.constant = 158
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                    self.txtWeight.superview?.layoutIfNeeded()
                    }, completion: nil)
            }
            
            let berat = 500 + (b.tag * 1000)
            if (b.tag == 0) {
                txtWeight.text = ""
            } else {
                txtWeight.text = String(berat)
            }
            
            
            
            // make weight select all at the first
            txtWeight.becomeFirstResponder()
            
            txtWeight.selectedTextRange = txtWeight.textRange(from: txtWeight.beginningOfDocument, to: txtWeight.endOfDocument)
        }
    }
    
    func selectWeightByIndex(_ index : Int, overrideWeight : Bool)
    {
        let w = weightViews[index]
        self.highlightWeightView(true, weightView: w)
        
        if (txtWeight.isHidden)
        {
            txtWeight.isHidden = false
            conHeightWeightView.constant = 158
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.txtWeight.superview?.layoutIfNeeded()
                }, completion: nil)
        }
        
        if (overrideWeight)
        {
            let berat = 500 + (index * 1000)
            txtWeight.text = String(berat)
        }
    }
    
    @IBAction func selectOngkir(_ sender : UIButton?)
    {
        for o in ongkirViews
        {
            self.highlightWeightView(false, weightView: o)
        }
        
        if let b = sender
        {
            let o = ongkirViews[b.tag]
            self.highlightWeightView(true, weightView: o)
            if (b.tag == 0) {
                freeOngkir = 1
            } else
            {
                freeOngkir = 0
            }
        } else
        {
            let o = ongkirViews[0]
            self.highlightWeightView(true, weightView: o)
            freeOngkir = 1
        }
    }
    
    func selectOngkirByIndex(_ index : Int)
    {
        for o in ongkirViews
        {
            self.highlightWeightView(false, weightView: o)
        }
        
        let o = ongkirViews[index]
        self.highlightWeightView(true, weightView: o)
    }
    
    func highlightWeightView(_ highlight : Bool, weightView : BorderedView)
    {
        let c = highlight ? Theme.PrimaryColorDark : Theme.GrayLight
        weightView.borderColor = c
        
        for v in weightView.subviews
        {
            if (v.isKind(of: UILabel.classForCoder()))
            {
                let l = v as! UILabel
                l.textColor = c
            } else if (v.isKind(of: TintedImageView.classForCoder()))
            {
                let t = v as! TintedImageView
                t.tintColor = c
            }
        }
    }
    
    @IBAction func pickKategori(_ sender : UIButton)
    {
        let p = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdCategoryPicker) as! CategoryPickerViewController
        p.blockDone = { data in
            let children = JSON(data["child"]!)
            
            if let id = children["_id"].string
            {
                self.productCategoryId = id
            }
            
            if let name = children["name"].string
            {
                self.captionKategori.text = name
            }
            
            let dataJson = JSON(data)
            if let imgName = dataJson["category_image_name"].string
            {
                if let imgUrl = URL(string: imgName) {
                    self.ivImage.afSetImage(withURL: imgUrl)
                }
            }
            
            self.getSizes()
            
            if let catLv2Name = dataJson["category_level2_name"].string {
                // Set placeholder for item name and description
                guard let filePath = Bundle.main.path(forResource: "AddProductPlaceholder", ofType: "plist"), let placeholdersDict = NSDictionary(contentsOfFile: filePath) else {
                    print("Couldn't load .plist as a dictionary")
                    return
                }
                //print("placehodlersDict = \(placeholdersDict)")
                
                let predicate = NSPredicate(format: "SELF CONTAINS[cd] %@", "\(catLv2Name.lowercased())")
                let matchingKeys = placeholdersDict.allKeys.filter { predicate.evaluate(with: $0) }
                if let placeholderDict = placeholdersDict.dictionaryWithValues(forKeys: matchingKeys as! [String]).first?.1 {
                    //print("placehodlerDict = \(placeholderDict)")
                    if let itemNamePlaceholder = (placeholderDict as AnyObject).object(forKey: "name") {
                        self.txtName.placeholder = "mis: \(itemNamePlaceholder)"
                    }
                    if let descPlaceholder = (placeholderDict as AnyObject).object(forKey: "desc") {
                        self.txtDescription.placeholder = "Spesifikasi barang (Opsional)\nmis: \(descPlaceholder)"
                    }
                }
            }
            
            if let catLv1Id = dataJson["category_level1_id"].string {
                if (catLv1Id == "55de6dbc5f6522562a2c73ef" || catLv1Id == "55de6dbc5f6522562a2c73f0") {
                    self.isCategWomenOrMenSelected = true
                } else {
                    self.isCategWomenOrMenSelected = false
                }
            }
            
            // Show luxury fields if isLuxury
            if (self.merekIsLuxury && self.isCategWomenOrMenSelected) {
                self.groupVerifAuth.isHidden = false
                self.groupKelengkapan.isHidden = false
                self.conTopOngkirGroup.constant = 498 + 16
            } else {
                self.groupVerifAuth.isHidden = true
                self.groupKelengkapan.isHidden = true
                self.conTopOngkirGroup.constant = 8
            }
        }
        p.root = self
        self.navigationController?.pushViewController(p, animated: true)
    }
    
    func getSizes()
    {
        let _ = request(APIReference.brandAndSizeByCategory(category: self.productCategoryId)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Product Brands and Sizes")) {
                if let x: AnyObject = resp.result.value as AnyObject?
                {
                    let json = JSON(x)
                    let jsizes = json["_data"]["sizes"]
                    if let arr = jsizes["size_types"].array
                    {
                        self.captionSize1.text = ""
                        self.captionSize2.text = ""
                        self.captionSize3.text = ""
                        var sml : Array<String> = [] // = UK, this var name is screwed
                        var usa : Array<String> = [] // = EU, this var name is screwed
                        var eur : Array<String> = [] // = USA, this var name is screwed
                        for i in 0...arr.count-1
                        {
                            let d = arr[i]
                            let name = d["name"].string!
                            if (i == 0) {
                                self.captionSize1.text = name
                            } else if (i == 1) {
                                self.captionSize2.text = name
                            } else if (i == 2) {
                                self.captionSize3.text = name
                            }
                            
                            if let strings = d["sizes"].arrayObject
                            {
                                for c in 0...strings.count-1
                                {
                                    if (i == 0)
                                    {
                                        sml.append(strings[c] as! String)
                                    }
                                    
                                    if (i == 1)
                                    {
                                        usa.append(strings[c] as! String)
                                    }
                                    
                                    if (i == 2)
                                    {
                                        eur.append(strings[c] as! String)
                                    }
                                }
                            }
                            
                        }
                        
                        self.sizes = []
                        let tempCount = sml.count >= usa.count ? sml.count : usa.count
                        let sizeCount = tempCount >= eur.count ? tempCount : eur.count
                        for i in 0...sizeCount-1
                        {
                            var usaString = ""
                            if (i < usa.count-1) // usa is safe
                            {
                                usaString = usa[i]
                            }
                            
                            var smlString = ""
                            if (i < sml.count-1) // sml is safe
                            {
                                smlString = sml[i]
                            }
                            
                            var eurString = ""
                            if (i < eur.count-1) // eur is safe
                            {
                                eurString = eur[i]
                            }
                            
                            let sizeString = smlString + "\n" + usaString + "\n" + eurString
                            self.sizes.append(sizeString)
                        }
                        
                        if (self.sizes.count > 0)
                        {
                            self.sizePicker.collectionView.reloadData()
                            self.sizePicker.selectItem(0, animated: false)
                            self.conHeightSize.constant = 146
                            self.sizePicker.superview?.isHidden = false
                            
                            var s = ""
                            if self.editMode {
                                if let x = self.editProduct?.size
                                {
                                    s = x
                                }
                            } else if self.draftMode {
                                if let x = self.draftProduct?.size
                                {
                                    s = x
                                }
                            }
                            if (s != "" && (self.editMode == true || self.draftMode == true))
                            {
                                s = s.replacingOccurrences(of: "/", with: "\n")
                                s = s.replacingOccurrences(of: " ", with: "-")
                                s = s.replacingOccurrences(of: "(", with: "")
                                s = s.replacingOccurrences(of: ")", with: "")
                                var index = 0
                                for s1 in self.sizes
                                {
                                    let s1s = s1.replacingOccurrences(of: " ", with: "")
                                    if (s1s == s)
                                    {
                                        self.sizePicker.selectItem(UInt(index), animated: false)
                                        break
                                    }
                                    
                                    index += 1
                                }
                            }
                        } else
                        {
                            self.conHeightSize.constant = 0
                            self.sizePicker.superview?.isHidden = true
                        }
                    } else
                    {
                        self.conHeightSize.constant = 0
                        self.sizePicker.superview?.isHidden = true
                    }
                } else
                {
                    self.conHeightSize.constant = 0
                    self.sizePicker.superview?.isHidden = true
                }
            }
        }
    }
    
    @IBAction func pickKondisi(_ sender : UIButton)
    {
        let p = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdPicker) as! PickerViewController
        
        p.title = "Pilih Kondisi"
        
        let names : [String] = CDProductCondition.getProductConditionPickerItems()
        let details : [String] = CDProductCondition.getProductConditionPickerDetailItems()
        
        p.items = names
        p.subtitles = details
        
        p.selectBlock = { s in
            self.kodindisiId = PickerViewController.RevealHiddenString(s)
            let x = PickerViewController.HideHiddenString(s)
            self.captionKondisi.text = x
            if ((x.lowercased() as NSString).range(of: "cukup").location != NSNotFound)
            {
                self.conHeightCacat.constant = 44
                self.txtDeskripsiCacat.isHidden = false
            }
            else
            {
                self.conHeightCacat.constant = 0
                self.txtDeskripsiCacat.isHidden = true
            }
        }
        
        self.navigationController?.pushViewController(p, animated: true)
    }
    
    @IBAction func pickMerek(_ sender : UIButton)
    {
        let p = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdPicker) as! PickerViewController
        
        p.title = "Pilih Merk"
        
        let cur = 0
        let lim = 25
        var names : [String] = []
        let _ = request(APISearch.brands(name: "", current: cur, limit: lim)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Merk")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                
                if (data.count > 0) {
                    for i in 0...(data.count - 1) {
                        if let merkName = data[i]["name"].string, let merkId = data[i]["_id"].string {
                            var strToHide = merkId
                            var isLuxury = false
                            if let isLux = data[i]["is_luxury"].bool {
                                isLuxury = isLux
                            }
                            strToHide += ";" + (isLuxury ? "1" : "0")
                            names.append(merkName + PickerViewController.TAG_START_HIDDEN + strToHide + PickerViewController.TAG_END_HIDDEN)
                        }
                    }
                    p.merkMode = true
                    p.pagingMode = true
                    p.pagingCurrent = cur + lim
                    p.pagingLimit = lim
                    if (data.count < lim) {
                        p.isPagingEnded = true
                    } else {
                        p.isPagingEnded = false
                    }
                    p.items = names
                    p.selectBlock = { s in
                        let hiddenStr = PickerViewController.RevealHiddenString(s).characters.split{$0 == ";"}.map(String.init)
                        if (hiddenStr.count >= 2) {
                            self.merekId = hiddenStr[0]
                            self.merekIsLuxury = (hiddenStr[1] == "1") ? true : false
                        } else {
                            self.merekId = ""
                            self.merekIsLuxury = false
                        }
                        var x : String = PickerViewController.HideHiddenString(s)
                        
                        // Set chosen brand
                        x = x.replacingOccurrences(of: "Tambahkan merek '", with: "")
                        x = x.replacingOccurrences(of: "'", with: "")
                        self.captionMerek.text = x
                        
                        // Show luxury fields if isLuxury
                        if (self.merekIsLuxury && self.isCategWomenOrMenSelected) {
                            self.groupVerifAuth.isHidden = false
                            self.groupKelengkapan.isHidden = false
                            self.conTopOngkirGroup.constant = 498 + 16
                        } else {
                            self.groupVerifAuth.isHidden = true
                            self.groupKelengkapan.isHidden = true
                            self.conTopOngkirGroup.constant = 8
                        }
                        
                        // Show submit label
                        if (self.editMode) {
                            if ((self.editProduct?.isFakeApprove)! || (self.editProduct?.isFakeApproveV2)!) {
                                self.lblSubmit.isHidden = true
                            } else {
                                self.lblSubmit.isHidden = false
                            }
                        }
                    }
                    p.showSearch = true
                    
                    self.navigationController?.pushViewController(p, animated: true)
                } else {
                    Constant.showBadgeDialog("Pilih Merk", message: "Oops, terdapat kesalahan saat mengambil data merk", badge: "warning", view: self, isBack: false)
                }
            } else {
                Constant.showBadgeDialog("Pilih Merk", message: "Oops, terdapat kesalahan saat mengambil data merk", badge: "warning", view: self, isBack: false)
            }
        }
    }
    
    @IBAction func btnChkOriginalBoxPressed(_ sender: AnyObject) {
        self.isOriginalBoxChecked = !self.isOriginalBoxChecked
        if (isOriginalBoxChecked) {
            lblChkOriginalBox.text = "";
            lblChkOriginalBox.font = AppFont.prelo2.getFont(19)!
            lblChkOriginalBox.textColor = Theme.PrimaryColor
        } else {
            lblChkOriginalBox.text = "";
            lblChkOriginalBox.font = AppFont.preloAwesome.getFont(24)!
            lblChkOriginalBox.textColor = Theme.GrayLight
        }
    }
    
    @IBAction func btnChkOriginalDustboxPressed(_ sender: AnyObject) {
        self.isOriginalDustboxChecked = !self.isOriginalDustboxChecked
        if (isOriginalDustboxChecked) {
            lblChkOriginalDustbox.text = "";
            lblChkOriginalDustbox.font = AppFont.prelo2.getFont(19)!
            lblChkOriginalDustbox.textColor = Theme.PrimaryColor
        } else {
            lblChkOriginalDustbox.text = "";
            lblChkOriginalDustbox.font = AppFont.preloAwesome.getFont(24)!
            lblChkOriginalDustbox.textColor = Theme.GrayLight
        }
    }
    
    @IBAction func btnChkReceipt(_ sender: AnyObject) {
        self.isReceiptChecked = !self.isReceiptChecked
        if (isReceiptChecked) {
            lblChkReceipt.text = "";
            lblChkReceipt.font = AppFont.prelo2.getFont(19)!
            lblChkReceipt.textColor = Theme.PrimaryColor
        } else {
            lblChkReceipt.text = "";
            lblChkReceipt.font = AppFont.preloAwesome.getFont(24)!
            lblChkReceipt.textColor = Theme.GrayLight
        }
    }
    
    @IBAction func btnChkAuthCard(_ sender: AnyObject) {
        self.isAuthCardChecked = !self.isAuthCardChecked
        if (isAuthCardChecked) {
            lblChkAuthCard.text = "";
            lblChkAuthCard.font = AppFont.prelo2.getFont(19)!
            lblChkAuthCard.textColor = Theme.PrimaryColor
        } else {
            lblChkAuthCard.text = "";
            lblChkAuthCard.font = AppFont.preloAwesome.getFont(24)!
            lblChkAuthCard.textColor = Theme.GrayLight
        }
    }
    
    // MARK: - Alert notifications
    
//    var loadingDelete = UIAlertController(title: "Menghapus barang...", message: nil, preferredStyle: .Alert)
//    var loadingDeleteOS7 = UIAlertView(title: "Menghapus barang...", message: nil, delegate: nil, cancelButtonTitle: nil)
    func askDeleteProduct()
    {
        if (UIDevice.current.systemVersion.floatValue >= 8)
        {
            askDeleteOS8()
        } else
        {
            askDeleteOS7()
        }
    }
    
    func askDeleteOS8()
    {
        let a = UIAlertController(title: "Hapus", message: "Hapus Barang?", preferredStyle: .alert)
        
        a.addAction(UIAlertAction(title: "Tidak", style: .cancel, handler: {act in }))
        a.addAction(UIAlertAction(title: "Ya", style: .default, handler: {act in
            self.deleteProduct()
        }))
        self.present(a, animated: true, completion: nil)
    }
    
    func askDeleteOS7()
    {
        let a = UIAlertView()
        a.title = "Hapus"
        a.message = "Hapus Barang?"
        a.addButton(withTitle: "Ya")
        a.addButton(withTitle: "Tidak")
        a.delegate = self
        a.tag = 123
        a.show()
    }
    
    func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if (alertView.tag == 123)
        {
            if (buttonIndex == 0)
            {
                self.deleteProduct()
            }
        }
    }
    
    // MARK: - delete
    
    func deleteProduct()
    {
        if (editMode) {
            if let prodId = editProduct?.productID
            {
                btnSubmit.isEnabled = false
                btnDelete.setTitle("Menghapus barang...", for: UIControlState.disabled)
                btnDelete.isEnabled = false
                
                let _ = request(APIProduct.delete(productID: prodId)).responseJSON {resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hapus Barang"))
                    {
                        if var v = self.navigationController?.viewControllers
                        {
                            v.removeLast()
                            v.removeLast()
                            
                            self.delegate?.setFromDraftOrNew(true)
                            self.navigationController?.setViewControllers(v, animated: true)
                        }
                        
                        //                    self.navigationController?.popViewControllerAnimated(true)
                    } else {
                        self.btnSubmit.isEnabled = true
                        self.btnDelete.isEnabled = true
                    }
                }
            }
        } else if (draftMode) {
            CDDraftProduct.delete((draftProduct?.localId)!)
            Constant.showBadgeDialog("Berhasil", message: "Draft barang berhasil dihapus", badge: "info", view: self, isBack: true)
        }
    }
    
    // MARK: - upload product
    
    func sendProduct()
    {
        let name = txtName.text!
        let desc = txtDescription.text!
        let weight = txtWeight.text!
        let oldPrice = txtOldPrice.text!
        let newPrice = txtNewPrice.text!
        let special = txtSpesial.text!
        let deflect = txtDeskripsiCacat.text!
        let alasan = txtAlasanJual.text!
        
        if (fakeScrollView.isHidden == false)
        {
            hideFakeScrollView()
        }
        
        var imgs : [AnyObject] = []
        for v in imageViews
        {
            if let i = v.image
            {
                imgs.append(i)
            } else
            {
                imgs.append(NSNull())
            }
        }
        
        
        
        if (imageViews[0].image == nil) // Main image
        {
            Constant.showBadgeDialog("Perhatian", message: "Gambar utama tidak boleh kosong", badge: "warning", view: self, isBack: false)
            return
        }
        
        if (imageViews[3].image == nil && captionMerek.text != "" && captionMerek.text != "Tanpa Merek") // Brand image
        {
            Constant.showBadgeDialog("Perhatian", message: "Gambar merek tidak boleh kosong", badge: "warning", view: self, isBack: false)
            return
        }
        
        if (validateString(name, message: "Nama barang masih kosong") == false)
        {
            return
        }
        
        // optional
//        if (validateString(desc, message: "Deskripsi barang masih kosong") == false)
//        {
//            return
//        }
        
        if (validateString(weight, message: "Berat barang masih kosong") == false)
        {
            return
        }
        
        if (weight == "0") {
            Constant.showBadgeDialog("Perhatian", message: "Berat barang tidak boleh 0", badge: "warning", view: self, isBack: false)
            return
        }
        
        let weightRegex = "^[0-9]+$"
        if (weight.match(weightRegex) == false) {
            Constant.showBadgeDialog("Perhatian", message: "Berat barang harus hanya berupa angka (contoh: 500)", badge: "warning", view: self, isBack: false)
            return
        }
        
        if (validateString(oldPrice, message: "Harga Beli barang masih kosong") == false)
        {
            return
        }
        
        if (validateString(newPrice, message: "Harga Jual barang masih kosong") == false)
        {
            return
        }
        
        if (validateString(productCategoryId, message: "Silahkan pilih kategori barang") == false)
        {
            return
        }
        
        if (validateString(kodindisiId, message: "Silahkan pilih kondisi barang") == false)
        {
            return
        }
        
        if (validateString(alasan, message: "Silahkan isi alasan jual kamu") == false)
        {
            return
        }
        
        if (validateString(deflect, message: "") == false && txtDeskripsiCacat.isHidden == false)
        {
            Constant.showBadgeDialog("Perhatian", message: "Silahkan jelaskan cacat barang kamu", badge: "warning", view: self, isBack: false)
            return
        }
        
        if (validateString(merekId, message: "") == false && captionMerek.text == "")
        {
            Constant.showBadgeDialog("Perhatian", message: "Silahkan pilih merek barang", badge: "warning", view: self, isBack: false)
            return
        }
        
        if (conHeightSize.constant != 0 && txtSize.text == "")
        {
            Constant.showBadgeDialog("Perhatian", message: "Silahkan pilih ukuran", badge: "warning", view: self, isBack: false)
        }
        
        // Compress images
        for i in 0...images.count - 1 {
            if let img = images[i] as? UIImage {
              if (img.size.width * img.scale < (AppTools.isDev ? 480 : 640) || img.size.height * img.scale < (AppTools.isDev ? 480 : 640)) {
                    var imgType = ""
                    if (i == 0) {
                        imgType = "Gambar Utama"
                    } else if (i == 1) {
                        imgType = "Gambar Tampak Belakang"
                    } else if (i == 2) {
                        imgType = "Gambar Ketika Dipakai"
                    } else if (i == 3) {
                        imgType = "Gambar Tampilan Label/Merek"
                    } else if (i == 4) {
                        imgType = "Gambar Cacat"
                    }
                Constant.showBadgeDialog("Perhatian", message: "\(imgType) tidak boleh lebih kecil dari \(AppTools.isDev ? "480x480" : "640x640") px", badge: "warning", view: self, isBack: false)
                    return
                }
            }
        }
        
        self.btnSubmit.isEnabled = false
        
        var param : [String : String] = [
            "name":name,
            "description":desc,
            "category_id":productCategoryId,
            "price":newPrice,
            "price_original":oldPrice,
            "weight":weight,
            "free_ongkir":String(freeOngkir),
            "product_condition_id":kodindisiId,
            "sell_reason":alasan,
            "defect_description":deflect,
            "special_story":special,
            "brand_id":merekId,
            "brand_name":captionMerek.text!,
            "proposed_brand":"",
            "size":txtSize.text!,
            "is_luxury":merekIsLuxury ? "1" : "0",
            "style_name":txtLuxStyleName.text!,
            "serial_number":txtLuxSerialNumber.text!,
            "purchase_location":txtLuxLokasiBeli.text!,
            "purchase_year":txtLuxTahunBeli.text!,
            "original_box":isOriginalBoxChecked ? "1" : "0",
            "original_dustbox":isOriginalDustboxChecked ? "1" : "0",
            "receipt":isReceiptChecked ? "1" : "0",
            "authenticity_card":isAuthCardChecked ? "1" : "0",
            "platform_sent_from":"ios"
        ]
        
        if (desc == "")
        {
            param.removeValue(forKey: "description")
        }
        
        if (merekId == "")
        {
            param.removeValue(forKey: "brand_id")
            param["proposed_brand"] = captionMerek.text
        }
        
        if (special == "")
        {
            param.removeValue(forKey: "special_story")
        }
        
        if (alasan == "")
        {
            param.removeValue(forKey: "sell_reason")
        }
        
        var url = "\(AppTools.PreloBaseUrl)/api/product"
        
        if (editMode)
        {
            param["rm_image1"] = String(rm_image1)
            param["rm_image2"] = String(rm_image2)
            param["rm_image3"] = String(rm_image3)
            param["rm_image4"] = String(rm_image4)
            param["rm_image5"] = String(rm_image5)
            param["update_image1"] = String(updt_image1)
            param["update_image2"] = String(updt_image2)
            param["update_image3"] = String(updt_image3)
            param["update_image4"] = String(updt_image4)
            param["update_image5"] = String(updt_image5)
            url = url + "/" + (editProduct?.productID)!
        }
        
        let userAgent : String? = UserDefaults.standard.object(forKey: UserDefaultsKey.UserAgent) as? String
        
        // Compress and remove exif from images
        for i in 0...images.count - 1 {
            if let img = images[i] as? UIImage {
                //print("Resizing image no-\(i) with width = \(img.size.width)")
                if let imgResized = img.resizeWithMaxWidthOrHeight(1600) { // max 1600 * 1600
//                    var curImg : UIImage?
//                    if let imgData = ImageHelper.removeExifData(UIImagePNGRepresentation(imgResized)!) {
//                        curImg = UIImage(data: imgData)!
//                    } else {
//                        curImg = imgResized
//                    }
                    //print("Image no-\(i) has been resized")
                    
                    // optimize
//                    var curImg = imgResized.compress(0.6)
//                    curImg = curImg.applyBlurEffect()
                    
                    // handle rotate
//                    if (SYSTEM_VERSION_LESS_THAN("10.0")) {
//                        curImg = UIImage(cgImage: (imgResized.cgImage)!, scale: 1.0, orientation: img.imageOrientation)
//                    } else {
//                        curImg = imgResized
//                    }
                    
                    images[i] = imgResized.correctlyOrientedImage()
                }
            }
        }

        if (editMode == false)
        {
            
            // save the draft
            saveDraft(isBack: false)
            
            let alert : UIAlertController = UIAlertController(title: " Jual", message: "Pastikan barang yang kamu jual original. Jika barang kamu terbukti bukan original, pembeli berhak melakukan refund atas barang tersebut.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { action in
                self.btnSubmit.isEnabled = true
            }))
            alert.addAction(UIAlertAction(title: "Ya", style: .default, handler: { action in
                
                // Prelo Analytic - Submit Product
                let backgroundQueue = DispatchQueue(label: "com.prelo.ios.PreloAnalytic",
                                                    qos: .background,
                                                    target: nil)
                backgroundQueue.async {
                    print("Work on background queue")
                    
                    let loginMethod = User.LoginMethod ?? ""
                    
                    var pdata = [
                        "Product Name" : name,
                        "Condition" : self.captionKondisi.text,
                        "Product Brand" : self.captionMerek.text,
                        "New Brand" : (self.merekId != "" ? false : true),
                        "Free Shipping" : (self.freeOngkir == 1 ? true : false),
                        "Weight" : self.txtWeight.text,
                        "Price Original" : self.txtOldPrice.text,
                        "Price" : self.txtNewPrice.text
                    ] as [String : Any]
                    
                    // cat
                    var cat : Array<String> = []
                    var temp = CDCategory.getCategoryWithID(self.productCategoryId)!
                    cat.append(temp.name)
                    while (true) {
                        if let cur = CDCategory.getLv1CategIDFromID(temp.id) {
                            temp = CDCategory.getCategoryWithID(cur)!
                            cat.append(temp.name)
                        } else {
                            break
                        }
                    }
                    var iter = 1
                    for item in cat.reversed() {
                        pdata["Category " + iter.string] = item
                        iter += 1
                    }
                    
                    // imgae
                    var count = 0
                    for i in 0...self.images.count - 1 {
                        if let _ = self.images[i] as? UIImage {
                            count += 1
                            if (i == 0) {
                                pdata["Main Picture Exist"] = true
                            } else if (i == 1) {
                                pdata["Back Picture Exist"] = true
                            } else if (i == 2) {
                                pdata["Wear Picture Exist"] = true
                            } else if (i == 3) {
                                pdata["Label Picture Exist"] = true
                            } else if (i == 4) {
                                pdata["Defect Picture Exist"] = true
                            }
                        } else {
                            if (i == 0) {
                                pdata["Main Picture Exist"] = false
                            } else if (i == 1) {
                                pdata["Back Picture Exist"] = false
                            } else if (i == 2) {
                                pdata["Wear Picture Exist"] = false
                            } else if (i == 3) {
                                pdata["Label Picture Exist"] = false
                            } else if (i == 4) {
                                pdata["Defect Picture Exist"] = false
                            }
                        }
                    }
                    pdata["Number of Picture Uploaded"] = count
                    
                    AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.SubmitProduct, data: pdata, previousScreen: self.screenBeforeAddProduct, loginMethod: loginMethod)
                }
                
                self.btnSubmit.isEnabled = true
                let share = self.storyboard?.instantiateViewController(withIdentifier: "share") as! AddProductShareViewController
                share.sendProductParam = param
                share.sendProductImages = self.images
                share.basePrice = (newPrice.int)
                share.productName = name
                share.productImgImage = self.images.first as? UIImage
                share.sendProductBeforeScreen = PageName.AddProduct //self.screenBeforeAddProduct
                share.sendProductKondisi = self.kodindisiId
                share.shouldSkipBack = false
                share.localId = self.draftMode ? (self.draftProduct?.localId)! : self.uniqueCodeString
                
                self.navigationController?.pushViewController(share, animated: true)
            }))
            
            let content =  " Jual"
            let attrStr = NSMutableAttributedString(string: content)
            
            attrStr.addAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16.0)], range: (content as NSString).range(of: "Jual"))
            
            attrStr.addAttributes([NSForegroundColorAttributeName:UIColor.orange], range: (content as NSString).range(of: ""))
            attrStr.addAttributes([NSFontAttributeName:UIFont(name: "preloAwesome", size: 16.0)!], range: (content as NSString).range(of: ""))
            
            alert.setValue(attrStr, forKeyPath: "attributedTitle")
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, andUserAgent: userAgent!, to:url, success: {op, res in
//            print(res)
            
            if (self.editMode)
            {
                self.delegate?.setFromDraftOrNew(true)
                
                //Mixpanel.sharedInstance().track("Editing Product", properties: ["success":"1"])
                self.editDoneBlock()
                self.navigationController?.popViewController(animated: true)
                return
            }
            
            let json = JSON(res)
            
            let s = self.storyboard?.instantiateViewController(withIdentifier: "share") as! AddProductShareViewController
            if let price = json["_data"]["price"].int
            {
                s.basePrice = price
            }
            if let img = json["_data"]["display_picts"][0].string {
                s.productImg = img
            }
            if let name = json["_data"]["name"].string {
                s.productName = name
            }
            if let permalink = json["_data"]["permalink"].string {
                s.permalink = permalink
            }
            s.productID = (json["_data"]["_id"].string)!
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: "refreshHome"), object: nil)
            self.navigationController?.pushViewController(s, animated: true)
            
            }, failure: { op, err in
                //Mixpanel.sharedInstance().track("Adding Product", properties: ["success":"0"])
                self.navigationItem.rightBarButtonItem = self.confirmButton.toBarButton()
                self.btnSubmit.isEnabled = true
                var msgContent = "Terdapat kesalahan saat upload barang, silahkan coba beberapa saat lagi"
                if let msg = op?.responseString {
                    if let range1 = msg.range(of: "{\"_message\":\"") {
                        //print(range1)
                        let msg1 = msg.substring(from: range1.upperBound)
                        if let range2 = msg1.range(of: "\"}") {
                            //print(range2)
                            msgContent = msg1.substring(to: range2.lowerBound)
                        }
                    }
                }
                Constant.showBadgeDialog("Upload Barang", message: msgContent, badge: "error", view: self, isBack: false)
                
                
        })
    }
    
    // MARK : - validation input
    
    func validateString(_ text : String?, message : String) -> Bool
    {
        if (text == nil || text == "")
        {
            if (message != "")
            {
                Constant.showBadgeDialog("Perhatian", message: message, badge: "warning", view: self, isBack: false)
            }
            return false
        }
        
        return true
    }
    
    // MARK: - saveDraft
    
    func saveDraft(isBack: Bool) {
        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.Prelo",
                                            qos: .background,
                                            target: nil)
        backgroundQueue.async {
            print("Work on background queue")
            
            //  0  styleName : String
            //  1  serialNumber : String
            //  2  purchaseLocation : String
            //  3  purchaseYear : String
            //  4  originalBox : String
            //  5  originalDustbox : String
            //  6  receipt : String
            //  7  authenticityCard : String
            
            var luxuryData : Array<String> = ["", "", "", "", "", "", "", ""]
            
            if (self.isOriginalBoxChecked || self.isOriginalDustboxChecked || self.isReceiptChecked || self.isAuthCardChecked) {
                luxuryData[0] = self.txtLuxStyleName.text!
                luxuryData[1] = self.txtLuxSerialNumber.text!
                luxuryData[2] = self.txtLuxLokasiBeli.text!
                luxuryData[3] = self.txtLuxTahunBeli.text!
                luxuryData[4] = self.isOriginalBoxChecked.description
                luxuryData[5] = self.isOriginalDustboxChecked.description
                luxuryData[6] = self.isReceiptChecked.description
                luxuryData[7] = self.isAuthCardChecked.description
            }
            
            // wait for all image saved
            for i in 0...self.images.count-1 {
                // save image first if from camera
                // now handling after image choose or taken by camera (auto save first)
//                self.saveImages(self.images, index: i, uniqueCode: (self.draftMode ? (self.draftProduct?.localId)! : self.uniqueCodeString)!)
                while (true) {
                    if (!self.isCamera[i]) {
                        break
                    } else if (self.isCamera[i] && self.localPath[i] != "") {
                        break
                    }
                }
            }
            
            // save to core data
            CDDraftProduct.saveDraft(self.draftMode == true ? (self.draftProduct?.localId)! : self.uniqueCodeString, name: self.txtName.text!, descriptionText: self.txtDescription.text, weight: self.txtWeight.text != nil ? self.txtWeight.text! : "", freeOngkir: self.freeOngkir, priceOriginal: self.txtOldPrice.text != nil ? self.txtOldPrice.text! : "", price: self.txtNewPrice.text != nil ? self.txtNewPrice.text! : "", commission: self.txtCommission.text != nil ? self.txtCommission.text! : "", category: self.captionKategori.text != nil ? self.captionKategori.text! : "", categoryId: self.productCategoryId, isCategWomenOrMenSelected: self.isCategWomenOrMenSelected, condition: self.captionKondisi.text != nil ? self.captionKondisi.text! : "", conditionId: self.kodindisiId, brand: self.captionMerek.text != nil ? self.captionMerek.text! : "", brandId: self.merekId, imagePath: self.localPath, imageOrientation: self.imageOrientation, size: self.txtSize.text != nil ? self.txtSize.text! : "", defectDescription: self.txtDeskripsiCacat.text != nil ? self.txtDeskripsiCacat.text! : "", sellReason: self.txtAlasanJual.text != nil ? self.txtAlasanJual.text! : "", specialStory: self.txtSpesial.text != nil ? self.txtSpesial.text!: "", luxuryData: luxuryData, isLuxury: self.merekIsLuxury)
            
            // Prelo Analytic - Save As Draft
            let loginMethod = User.LoginMethod ?? ""
            let pdata = [
                "Local ID": (self.draftMode == true ? (self.draftProduct?.localId)! : self.uniqueCodeString),
                "Product Name" : self.txtName.text!,
                "Username" : CDUser.getOne()?.username
            ] as [String : Any]
            AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.SaveAsDraft, data: pdata, previousScreen: self.screenBeforeAddProduct, loginMethod: loginMethod)
        }
        
        if isBack {
            Constant.showBadgeDialog("Berhasil", message: "Draft barang berhasil disimpan di menu Jualan Saya. Jika belum muncul, mohon tunggu beberapa saat dan coba untuk memperbarui menu Jualan Saya.", badge: "info", view: self, isBack: isBack)
        }
    }
    
    // MARK: - Warning top bar
    func setupTopBanner() {
        if let tbText = self.topBannerText {
            if (editProduct?.status != nil && !tbText.isEmpty) {
                let screenSize: CGRect = UIScreen.main.bounds
                let screenWidth = screenSize.width
                var topBannerHeight : CGFloat = 30.0
                let textRect = tbText.boundsWithFontSize(UIFont.systemFont(ofSize: 11), width: screenWidth - 16)
                topBannerHeight += textRect.height
                let topLabelMargin : CGFloat = 8.0
                let topBanner : UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: topBannerHeight), backgroundColor: Theme.ThemeOrange)
                let topLabel : UILabel = UILabel(frame: CGRect(x: topLabelMargin, y: 0, width: screenWidth - (topLabelMargin * 2), height: topBannerHeight))
                topLabel.textColor = UIColor.white
                topLabel.font = UIFont.systemFont(ofSize: 11)
                topLabel.lineBreakMode = .byWordWrapping
                topLabel.numberOfLines = 0
                topBanner.addSubview(topLabel)
                if (editProduct?.status == 5) {
                    topLabel.text = tbText
                    self.vwTopBannerParent.addSubview(topBanner)
                    self.consHeightTopBannerParent.constant = topBannerHeight
                }
            }
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
