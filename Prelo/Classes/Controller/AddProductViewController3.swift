//
//  AddProductViewController3.swift
//  Prelo
//
//  Created by Djuned on 8/6/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

class AddProduct3Helper {
    // Charge label
    static let defaultChargeLabel = "Klik LANJUTKAN untuk menentukan Charge Prelo yang kamu mau"
    
    // Subtitle
    static let rentOngkirSubtitle = "Diwajibkan menggunakan kurir sehari sampai (seperti JNE YES, TIKI ONS)"
    static let rentOngkirSubtitleBoldStr = "JNE YES, TIKI ONS"
    static let rentPeriodSubtitle = "Tentukan satuan Periode Sewa yang diinginkan"
    
    // swicth
    // rent page
    static let rentSwitchTitleJual = "Barang ini juga boleh dijual"
    static let rentSwitchSubtitleJual = "Untuk barang yang dijual, ongkos kirim bisa Ditanggung Penjual atau Pembeli"
    static let rentSwitchSubtitleJualBoldStr = "Ditanggung Penjual atau Pembeli"
    
    // sell page
    static let rentSwitchTitleSewa = "Barang ini juga dapat disewa"
    static let rentSwitchSubtitleSewa = "Untuk Sewa, ongkos kirim akan selalu Ditanggung Penyewa / Buyer"
    static let rentSwitchSubtitleSewaBoldStr = "Ditanggung Penyewa / Buyer"
    
    static let boldingText = rentOngkirSubtitleBoldStr + "|" + rentSwitchSubtitleJualBoldStr + "|" + rentSwitchSubtitleSewaBoldStr
}

// MARK: - Enum
enum AddProduct3SectionType {
    // type    <---->    number of cell
    case imagesPreview    // 1
    case productDetail    // 2
    case size             // 2
    case authVerification // 2
    case checklist        // 2
    case weight           // 2
    case postalFee        // 2
    case rentPeriod       // 2
    case rentSellOnOff    // 3
    case price            // 3
    
    var numberOfCell: Int {
        switch(self) {
        case .imagesPreview    : return 1
        case .productDetail,
             .size,
             .authVerification,
             .checklist,
             .weight,
             .postalFee,
             .rentPeriod       : return 2
        case .rentSellOnOff,
             .price            : return 3
        }
    }
    
    var icon: String {
        switch(self) {
        case .imagesPreview    : return ""
        case .productDetail    : return "ic_edit"
        case .size             : return "ic_ukuran"
        case .authVerification : return "ic_luxury"
        case .checklist        : return "ic_box"
        case .weight           : return "ic_berat"
        case .postalFee        : return "ic_ongkir"
        case .rentPeriod       : return "placeholder-circle"
        case .rentSellOnOff    : return "placeholder-circle"
        case .price            : return "ic_harga"
        }
    }
    
    var title: String {
        switch(self) {
        case .imagesPreview    : return ""
        case .productDetail    : return "DETAIL BARANG"
        case .size             : return "UKURAN"
        case .authVerification : return "VERIFIKASI AUTENTIKASI"
        case .checklist        : return "KELENGKAPAN"
        case .weight           : return "BERAT"
        case .postalFee        : return "ONGKOS KIRIM"
        case .rentPeriod       : return "PERIODE SEWA"
        case .rentSellOnOff    : return "SEWA" // "SEWA" | "JUAL" // override
        case .price            : return "HARGA"
        }
    }
    
    var subtitle: String? {
        switch(self) {
        case .authVerification : return "Hanya dapat dilihat oleh admin Prelo"
        case .checklist        : return "Upload gambar kelengkapan yang kamu miliki agar lolos review kurator Prelo"
        case .postalFee        : return nil // nil | AddProduct3Helper.rentOngkirSubtitle // override
        case .rentPeriod       : return AddProduct3Helper.rentPeriodSubtitle
        default                : return nil
        }
    }
    
    var faq: String? {
        switch(self) {
        case .checklist        : return "faq"
        default                : return nil
        }
    }
}

enum AddProduct3Type: Int {
    case sell = 0
    case rent = 1
}

// MARK: - Struct
struct PreviewImage {
    var image: UIImage? // local image / downloaded image
    var url = "" // downloaded image url
    var label = ""
    //var labelOther = ""
    var orientation: Int?
}

struct FreeOngkirRegion {
    var name = ""
    var id = ""
}

struct SelectedProductItem {
    // default value
    var isSell = true
    var isRent = false
    
    // another default value
    var isEditMode = false
    var isDraftMode = false
    
    // helper value
    var addProductType: AddProduct3Type = .sell
    var isLuxuryMerk = false
    var isWomenMenCategory = false
    var isCategoryContainSize = false
    var localId = ""
    
    // helper for backpress
    var isStartInput: Bool = false
    
    // status -> Edit Product
    var status = 0
    var segment = ""
    
    // Images Preview Cell
    var imagesIndex: Array<Int> = []
    var imagesDetail: Array<PreviewImage> = []
    
    // Product Detail Cell
    var name = ""
    var category = ""
    var categoryId = ""
    var merk = ""
    var merkId = ""
    var conditionId = ""
    var condition = ""
    var cacat = ""
    var specialStory = ""
    var alasanJual = ""
    var description = ""
    
    // Auth Verification Cell
    // dependency -> isLuxuryMerk && isWomenMenCategory
    var styleName = ""
    var serialNumber = ""
    var lokasiBeli = ""
    var tahunBeli = ""
    
    // Weigt Cell
    var weight = ""
    
    // Size Cell
    // dependency -> isCategoryContainSize
    var size = ""
    
    // Postal Fee Cell
    var isFreeOngkir = "1"
    // asuransi & lokal free ongkir disable
    var freeOngkirRegions : Array<FreeOngkirRegion> = []
    var isInsurance = "0"
    
    // Price Cell
    var hargaBeli = ""
    var hargaJual = ""
    var hargaSewa = ""
    var deposit = ""
    
    // Rent
    var modeSewa = "hari" // per hari, minggu, bulan
    
    // Charge Cell
    var commision = "0%(Free) - 10%"
}

// MARK: - Class
class AddProductViewController3: BaseViewController {
    @IBOutlet weak var vwNotification: UIView!
    @IBOutlet weak var consHeightVwNotification: NSLayoutConstraint! // 0 -> dinamyc
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    // data
    var product = SelectedProductItem()
    var chargeLabel: String? = AddProduct3Helper.defaultChargeLabel
    
    var sizes: Array<String> = []
    var sizesTitle: String = ""
    
    // init labels
    var labels: Array<String> = ["Gambar Utama", "Label atau Merek", "Cacat (Opsional)"]
    var maxImages = 10
    
    var topBannerText: String?
    
    // for edit & draft
    var editProduct: ProductDetail?
    var draftProduct: CDDraftProduct?
    
    // add product v2
    var editDoneBlock : EditDoneBlock = {}
    var screenBeforeAddProduct = ""
    
    // for refresh product sell list when product deleted
    weak var delegate: MyProductDelegate?
    
    // view
    var listSections: Array<AddProduct3SectionType> = []
    var isFirst = true
    
    // login
    var allowLaunchLogin = true
    
    func setupTableView() {
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.contentInset = inset
        
        tableView.separatorStyle = .none
        
        tableView.backgroundColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.showLoading()
        
        let AddProduct3ImageTitleCell = UINib(nibName: "AddProduct3ImageTitleCell", bundle: nil)
        tableView.register(AddProduct3ImageTitleCell, forCellReuseIdentifier: "AddProduct3ImageTitleCell")
        
        let AddProduct3ImagesPreviewCell = UINib(nibName: "AddProduct3ImagesPreviewCell", bundle: nil)
        tableView.register(AddProduct3ImagesPreviewCell, forCellReuseIdentifier: "AddProduct3ImagesPreviewCell")
        
        let AddProduct3DetailProductCell = UINib(nibName: "AddProduct3DetailProductCell", bundle: nil)
        tableView.register(AddProduct3DetailProductCell, forCellReuseIdentifier: "AddProduct3DetailProductCell")
        
        let AddProduct3WeightCell = UINib(nibName: "AddProduct3WeightCell", bundle: nil)
        tableView.register(AddProduct3WeightCell, forCellReuseIdentifier: "AddProduct3WeightCell")
        
        let AddProduct3SizeCell = UINib(nibName: "AddProduct3SizeCell", bundle: nil)
        tableView.register(AddProduct3SizeCell, forCellReuseIdentifier: "AddProduct3SizeCell")
        
        let AddProduct3PostalFeeCell = UINib(nibName: "AddProduct3PostalFeeCell", bundle: nil)
        tableView.register(AddProduct3PostalFeeCell, forCellReuseIdentifier: "AddProduct3PostalFeeCell")
        
        let AddProduct3ProductAuthVerificationCell = UINib(nibName: "AddProduct3ProductAuthVerificationCell", bundle: nil)
        tableView.register(AddProduct3ProductAuthVerificationCell, forCellReuseIdentifier: "AddProduct3ProductAuthVerificationCell")
        
        let AddProduct3ImagesChecklistCell = UINib(nibName: "AddProduct3ImagesChecklistCell", bundle: nil)
        tableView.register(AddProduct3ImagesChecklistCell, forCellReuseIdentifier: "AddProduct3ImagesChecklistCell")
        
        let AddProduct3PriceCell = UINib(nibName: "AddProduct3PriceCell", bundle: nil)
        tableView.register(AddProduct3PriceCell, forCellReuseIdentifier: "AddProduct3PriceCell")
        
        let AddProduct3ChargeCell = UINib(nibName: "AddProduct3ChargeCell", bundle: nil)
        tableView.register(AddProduct3ChargeCell, forCellReuseIdentifier: "AddProduct3ChargeCell")
        
        // rent
        let AddProduct3RentPeriodCell = UINib(nibName: "AddProduct3RentPeriodCell", bundle: nil)
        tableView.register(AddProduct3RentPeriodCell, forCellReuseIdentifier: "AddProduct3RentPeriodCell")
        
        let AddProduct3SellRentSwitchCell = UINib(nibName: "AddProduct3SellRentSwitchCell", bundle: nil)
        tableView.register(AddProduct3SellRentSwitchCell, forCellReuseIdentifier: "AddProduct3SellRentSwitchCell")
        
        let AddProduct3RentPostalFeeCell = UINib(nibName: "AddProduct3RentPostalFeeCell", bundle: nil)
        tableView.register(AddProduct3RentPostalFeeCell, forCellReuseIdentifier: "AddProduct3RentPostalFeeCell")
        
        // hack commisions
        let comTwitter = UserDefaults.standard.integer(forKey: UserDefaultsKey.ComTwitter)
        let comFacebook = UserDefaults.standard.integer(forKey: UserDefaultsKey.ComFacebook)
        let comInstagram = UserDefaults.standard.integer(forKey: UserDefaultsKey.ComInstagram)
        
        let minCommission = 10 - (comTwitter + comFacebook + comInstagram)
        if minCommission > 0 {
            self.product.commision = "\(String(minCommission))% - 10%"
        }
        
        // MARK: - GESTURE HACK
        
        // swipe gesture for carbon (pop view)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        
        let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
        vwLeft.backgroundColor = UIColor.clear
        vwLeft.addGestureRecognizer(swipeRight)
        self.view.addSubview(vwLeft)
        self.view.bringSubview(toFront: vwLeft)
        
        self.setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        // TODO: Tracking - update data ?
        if self.editProduct != nil {
            // Google Analytics
            GAI.trackPageVisit(PageName.EditProduct)
        } else {
            // Google Analytics
            GAI.trackPageVisit(PageName.AddProduct)
        }
        
        if (User.IsLoggedIn == false) {
            if (allowLaunchLogin) {
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            }
        }
        
        if self.isFirst {
            self.isFirst = false
            
            // Handling keyboard animation
            self.an_subscribeKeyboard(
                animations: {r, t, o in
                    
                    if (o) {
                        self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                    } else {
                        self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                    }
                    
            }, completion: nil)
            
            // TEST
            //self.product.addProductType = .rent
            //self.product.isLuxuryMerk = true
            //self.product.isWomenMenCategory = true
            
            // TODO: fakeApprove
            
            // setup product from edit or draft
            if self.editProduct != nil {
                self.product.isEditMode = true
                
                self.chargeLabel = nil
                
                self.setupEditMode()
            } else if self.draftProduct != nil {
                self.product.isDraftMode = true
                
                self.chargeLabel = nil
                
                self.setupDraftMode()
            } else { // default init
                if self.product.addProductType == .sell {
                    self.product.isSell = true
                    self.product.isRent = false
                } else {
                    self.product.isSell = false
                    self.product.isRent = true
                }
            }
            
            // init title
            if self.product.addProductType == .sell {
                self.title = "Jual"
            } else {
                self.title = "Sewa"
            }
            
            if self.product.isEditMode {
                self.title = "Edit"
            } else {
                // handle if is new draft product
                if self.product.localId == "" {
                    // set init id
                    let uniqueCode : TimeInterval = Date().timeIntervalSinceReferenceDate
                    self.product.localId = uniqueCode.description
                }
            }
            
            // init default sections
            self.listSections.append(.imagesPreview)
            self.listSections.append(.productDetail)
            self.listSections.append(.weight)
            self.listSections.append(.postalFee)
            self.listSections.append(.rentSellOnOff)
            self.listSections.append(.price)
            
            // setup table view
            if self.product.addProductType == .sell { // JUAL
                if self.product.isRent { // SEWA
                    
                }
            } else { // SEWA
                let idx = self.findSectionFromType(.postalFee)
                self.listSections.insert(.rentPeriod, at: idx+1)
                
                if self.product.isSell { // JUAL
                    
                }
            }
            
            if self.product.isCategoryContainSize {
                let idx = self.findSectionFromType(.productDetail)
                self.listSections.insert(.size, at: idx+1)
            }
            
            if self.product.isLuxuryMerk && self.product.isWomenMenCategory {
                let idx = self.findSectionFromType(.productDetail)
                let idx2 = self.findSectionFromType(.size)
                
                var _idx = idx+1
                
                if idx2 > -1 {
                    _idx += 1
                }
                
                self.listSections.insert(.authVerification, at: _idx)
            }
            
            // labels checklist
            if self.labels.count > 0 {
                let idx = self.findSectionFromType(.weight)
                self.listSections.insert(.checklist, at: idx)
            }
            
            self.tableView.reloadData()
        }
        self.hideLoading()
    }
    
    func setupEditMode() {
        let product = self.editProduct!
        
        // Images Preview Cell
        if let imgs = product.json["_data"]["display_picts"].array, let lbls = product.json["_data"]["display_pict_labels"].array {
            
            var j = 0
            for i in 0..<imgs.count {
                if let _ = imgs[i].string {
                    self.product.imagesIndex.append(j)
                    j += 1
                    self.product.imagesDetail.append(PreviewImage.init(image: nil, url: imgs[i].stringValue, label: lbls[i].stringValue, orientation: nil))
                }
            }
        }
        
        // Product Details Cell
        self.product.name = product.name
        
        if let category_breadcrumbs = product.json["_data"]["category_breadcrumbs"].array {
            for i in 0...category_breadcrumbs.count-1 {
                let c = category_breadcrumbs[i]
                self.product.categoryId = c["_id"].string!
                self.product.category = c["name"].string!
                
                if (c["level"].intValue == 1) {
                    if (c["_id"].stringValue == "55de6dbc5f6522562a2c73ef" || c["_id"].stringValue == "55de6dbc5f6522562a2c73f0") {
                        self.product.isWomenMenCategory = true
                    } else {
                        self.product.isWomenMenCategory = false
                    }
                }
            }
        }
        
        self.product.merk = product.json["_data"]["brand"].stringValue
        self.product.merkId = product.json["_data"]["brand_id"].stringValue
        self.product.conditionId = product.json["_data"]["product_condition_id"].stringValue
        self.product.condition = product.json["_data"]["condition"].stringValue
        self.product.cacat = product.defectDescription
        self.product.specialStory = product.specialStory
        self.product.alasanJual = product.sellReason
        self.product.description = product.json["_data"]["description"].stringValue
        
        // Auth Verfication Cell
        if let luxData = editProduct?.json["_data"]["luxury_data"], luxData.count > 0 {
            self.product.isLuxuryMerk = true
            self.product.segment = "luxury"
            
            self.product.styleName = luxData["style_name"].stringValue
            self.product.serialNumber = luxData["serial_number"].stringValue
            self.product.lokasiBeli = luxData["purchase_location"].stringValue
            self.product.tahunBeli = luxData["purchase_year"].stringValue
        }
        
        // TODO: Segment & RENT
        
        // Checklist Cell
        self.getLabels(false)
        
        // Weight Cell
        self.product.weight = product.json["_data"]["weight"].intValue.string
        
        // Size Cell
        self.product.size = product.size
        if self.product.size != "" {
            self.getSizes()
        }
        
        // Postal Fee Cell
        self.product.isFreeOngkir = product.json["_data"]["free_ongkir"].intValue.string
        
        // Price Cell
        self.product.hargaBeli = product.json["_data"]["price_original"].int64Value.string
        self.product.hargaJual = product.json["_data"]["price"].int64Value.string
        //self.product.hargaSewa = ""
        //self.product.deposit = ""
        
        // Charge Cell
        self.product.commision = product.json["_data"]["commission"].intValue.string + "%"
        
        // helper
        self.product.status = product.status
        
        if self.product.hargaSewa != "" || self.product.deposit != "" {
            self.product.isRent = true
        }
        
        // TODO: load RENT mode
        
        self.setupTopBanner()
    }
    
    func setupDraftMode() {
        let product = self.draftProduct!
        let jsonstring = "{\"_data\":" + product.imagesPathAndLabel + "}"
        //print(jsonstring)
        
        let json = jsonstring.convertToDictionary() ?? [:]
        
        // Images Preview Cell
        if let imgs = JSON(json)["_data"].array, imgs.count > 0 {
            
            for i in 0..<imgs.count {
                self.product.imagesIndex.append(i)
                // load images
                
                let image = TemporaryImageManager.sharedInstance.loadImageFromDocumentsDirectory(imageName: imgs[i]["url"].stringValue)?.resizeWithMaxWidthOrHeight(82 * UIScreen.main.scale)
                if image == nil {
                    print ("Failed to load image")
                }
                
                self.product.imagesDetail.append(PreviewImage.init(image: image, url: imgs[i]["url"].stringValue, label: imgs[i]["label"].stringValue, orientation: imgs[i]["orientation"].stringValue.int))
            }
        }
        
        // Product Details Cell
        self.product.name = product.name
        
        self.product.categoryId = product.categoryId
        self.product.category = product.category
        self.product.isWomenMenCategory = product.isCategWomenOrMenSelected
        
        self.product.merk = product.brand
        self.product.merkId = product.brandId
        self.product.conditionId = product.conditionId
        self.product.condition = product.condition
        self.product.cacat = product.defectDescription
        self.product.specialStory = product.specialStory
        self.product.alasanJual = product.sellReason
        self.product.description = product.descriptionText
        
        // Auth Verfication Cell
        if product.isLuxury {
            self.product.isLuxuryMerk = true
            self.product.segment = "luxury"
            
            self.product.styleName = product.luxuryData_styleName
            self.product.serialNumber = product.luxuryData_serialNumber
            self.product.lokasiBeli = product.luxuryData_purchaseLocation
            self.product.tahunBeli = product.luxuryData_purchaseYear
        } else {
            self.product.segment = product.segment
        }
        
        // Checklist Cell
        self.getLabels(false)
        
        // Weight Cell
        self.product.weight = product.weight
        
        // Size Cell
        self.product.size = product.size
        if self.product.size != "" {
            self.getSizes()
        }
        
        // Postal Fee Cell
        self.product.isFreeOngkir = product.freeOngkir.stringValue
        
        // Price Cell
        self.product.hargaBeli = product.priceOriginal
        self.product.hargaJual = product.price
        self.product.hargaSewa = product.priceRent
        self.product.deposit = product.priceDeposit
        
        // Charge Cell
        self.product.commision = product.commission
        
        // local id
        self.product.localId = product.localId
        
        self.product.isStartInput = true
        
        if self.product.hargaSewa != "" || self.product.deposit != "" {
            self.product.isRent = true
        }
        
        self.product.addProductType = AddProduct3Type(rawValue: product.addProductType.intValue)!
        
        // TODO: load RENT mode
    }
    
    // MARK: - Other
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    func openWebView(_ urlPathString: String, title: String?) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let helpVC = mainStoryboard.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
        
        helpVC.url = "https://prelo.co.id/" + urlPathString + "?ref=preloapp"
        helpVC.titleString = title ?? "Bantuan"
        helpVC.contactPreloMode = true
        let baseNavC = BaseNavigationController()
        baseNavC.setViewControllers([helpVC], animated: false)
        
        self.present(baseNavC, animated: true, completion: nil)
    }
    
    // MARK: - Section Helper
    func findSectionFromType(_ type: AddProduct3SectionType) -> Int {
        if self.listSections.count > 0 {
            for i in 0..<self.listSections.count {
                if self.listSections[i] == type {
                    return i
                }
            }
        }
        
        return -1
    }
    
    func insertSizeSection() {
        let idx = self.findSectionFromType(.productDetail)
        
        if idx == -1 {
            return
        }
        
        var _idx = self.findSectionFromType(.size)
        if _idx == -1 {
            _idx = idx+1
            
            self.listSections.insert(.size, at: _idx)
            
            let array: Array<Int> = [_idx]
            let indexSet = NSMutableIndexSet()
            array.forEach(indexSet.add)
            
            self.tableView.insertSections(indexSet as IndexSet, with: .fade)
        } else {
            self.tableView.reloadRows(at: [ IndexPath.init(row: 1, section: _idx) ], with: .fade)
        }
    }
    
    func insertLuxurySection() {
        let idx = self.findSectionFromType(.productDetail)
        let idx2 = self.findSectionFromType(.size)
        
        if idx == -1 {
            return
        }
        
        var _idx = self.findSectionFromType(.authVerification)
        
        if _idx == -1 {
            if idx2 > -1 {
                _idx = idx+2
            } else {
                _idx = idx+1
            }
            
            self.listSections.insert(.authVerification, at: _idx)
            
            let array: Array<Int> = [_idx]
            let indexSet = NSMutableIndexSet()
            array.forEach(indexSet.add)
            
            self.tableView.insertSections(indexSet as IndexSet, with: .fade)
        } else {
            self.tableView.reloadRows(at: [ IndexPath.init(row: 1, section: _idx) ], with: .fade)
        }
    }
    
    func insertChecklistSection() {
        let idx = self.findSectionFromType(.weight)
        
        if idx == -1 {
            return
        }
        
        var _idx = self.findSectionFromType(.checklist)
        if _idx == -1 {
            _idx = idx
            
            self.listSections.insert(.checklist, at: _idx)
            
            let array: Array<Int> = [_idx]
            let indexSet = NSMutableIndexSet()
            array.forEach(indexSet.add)
            
            self.tableView.insertSections(indexSet as IndexSet, with: .fade)
        } else {
            self.tableView.reloadRows(at: [ IndexPath.init(row: 1, section: _idx) ], with: .fade)
        }
    }
    
    func removeSection(_ type: AddProduct3SectionType) {
        let _idx = self.findSectionFromType(type)
        
        if _idx > -1 {
            self.listSections.remove(at: _idx)
            
            let array: Array<Int> = [_idx]
            let indexSet = NSMutableIndexSet()
            array.forEach(indexSet.add)
            
            self.tableView.deleteSections(indexSet as IndexSet, with: .fade)
        }
    }
    
    // MARK: - size
    func getSizes() {
        let _ = request(APIReference.brandAndSizeByCategory(category: self.product.categoryId)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Product Brands and Sizes")) {
                if let x: AnyObject = resp.result.value as AnyObject? {
                    let json = JSON(x)
                    let jsizes = json["_data"]["sizes"]
                    if let arr = jsizes["size_types"].array {
                        
                        self.sizesTitle = ""
                        
                        var sml : Array<String> = [] // = UK, this var name is screwed
                        var usa : Array<String> = [] // = EU, this var name is screwed
                        var eur : Array<String> = [] // = USA, this var name is screwed
                        for i in 0...arr.count-1 {
                            let d = arr[i]
                            let name = d["name"].string!
                            self.sizesTitle += name
                            
                            if i != arr.count-1 {
                                self.sizesTitle += "\n"
                            }
                            
                            if let strings = d["sizes"].arrayObject {
                                for c in 0...strings.count-1 {
                                    if (i == 0) {
                                        sml.append(strings[c] as! String)
                                    }
                                    if (i == 1) {
                                        usa.append(strings[c] as! String)
                                    }
                                    if (i == 2) {
                                        eur.append(strings[c] as! String)
                                    }
                                }
                            }
                        }
                        
                        self.sizes = []
                        let tempCount = sml.count >= usa.count ? sml.count : usa.count
                        let sizeCount = tempCount >= eur.count ? tempCount : eur.count
                        for i in 0...sizeCount-1 {
                            var usaString = ""
                            if (i < usa.count) { // usa is safe
                                usaString = usa[i]
                            }
                            
                            var smlString = ""
                            if (i < sml.count) { // sml is safe
                                smlString = sml[i]
                            }
                            
                            var eurString = ""
                            if (i < eur.count) { // eur is safe
                                eurString = eur[i]
                            }
                            
                            let sizeString = smlString + "\n" + usaString + "\n" + eurString
                            self.sizes.append(sizeString)
                        }
                        
                        if self.sizes.last == "\n\n" {
                            self.sizes.removeLast()
                        }
                        
                        if self.product.size == "" || !self.sizes.contains(self.product.size) {
                            self.product.size = self.sizes[0]
                        }
                        self.product.isCategoryContainSize = true
                        DispatchQueue.main.async(execute: {
                            self.insertSizeSection()
                        })
                    } else {
                        self.sizes = []
                        self.product.isCategoryContainSize = false
                        DispatchQueue.main.async(execute: {
                            self.removeSection(.size)
                        })
                    }
                } else {
                    self.sizes = []
                    self.product.isCategoryContainSize = false
                    DispatchQueue.main.async(execute: {
                        self.removeSection(.size)
                    })
                }
            }
        }
    }
    
    func getLabels(_ isNeedSetup: Bool) {
        self.labels = ["Gambar Utama"]
        
        if self.product.merkId != "56ea7146788ae3c12eb06999" {
            self.labels.append(contentsOf: ["Label atau Merek"])
        }
        
        self.labels.append(contentsOf: ["Cacat (Opsional)"])
        
        if let cat = CDCategory.getCategoryWithID(self.product.categoryId) {
            
            //print(cat.debugDescription)
            
            if self.product.segment == "budget" && cat.image_label_budget != nil {
                self.labels.append(contentsOf: self.toArray(cat.image_label_budget!))
            } else if self.product.segment == "everyday" && cat.image_label_everyday != nil {
                self.labels.append(contentsOf: self.toArray(cat.image_label_everyday!))
            } else if self.product.segment == "luxury" && cat.image_label_luxury != nil {
                self.labels.append(contentsOf: self.toArray(cat.image_label_luxury!))
            }
        } else {
            Constant.showDialog("Peringatan", message: "Lokal data kamu belum terupdate, harap lakukan \"Reload App Data\" pada menu \"About\". Dan ulangi upload barang kamu dari menu \"Jualan Saya\"")
            
            if self.editProduct == nil {
                self.saveDraft(false)
            }
            
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        
        if isNeedSetup {
            self.setupLabels()
        }
    }
    
    func toArray(_ image_labels: String) -> Array<String> {
        let arr = image_labels.characters.split{$0 == ";"}.map(String.init)
        
        // Split based on characters.
        return arr
    }
    
    // images labels
    func setupLabels() {
        if self.labels.count > 0 {
            self.insertChecklistSection()
        } else {
            self.removeSection(.checklist)
        }
        
        self.resetImagesLabel()
    }
    
    func resetImagesLabel() {
        if self.product.imagesDetail.count > 0 {
            for i in 0..<self.product.imagesDetail.count {
                if self.labels.count > 0 {
                    if !self.labels.contains(self.product.imagesDetail[i].label) {
                        self.product.imagesDetail[i].label = "Lainnya"
                    }
                } else {
                    self.product.imagesDetail[i].label = "Lainnya"
                }
            }
            
            self.tableView.reloadRows(at: [IndexPath.init(row: 0, section: 0)], with: .fade)
        }
    }
    
    // MARK: - Warning top bar
    func setupTopBanner() {
        if let tbText = self.topBannerText {
            if (self.product.status == 5 && !tbText.isEmpty) {
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
                //if (self.product.status == 5) {
                    topLabel.text = tbText
                    self.vwNotification.addSubview(topBanner)
                    self.consHeightVwNotification.constant = topBannerHeight
                //}
            }
        }
    }
    
    // MARK: - validate & prepare for submit
    func validateField() -> Bool {
        // TODO: validate field
        
        return true
    }
    
    func setupParam() -> [String:String] {
        var param: [String:String] = [
            "name"                 : self.product.name,
            "category_id"          : self.product.categoryId,
            "price"                : self.product.hargaJual,
            "price_original"       : self.product.hargaBeli,
            "weight"               : self.product.weight,
            "free_ongkir"          : self.product.isFreeOngkir,
            "product_condition_id" : self.product.conditionId,
            "defect_description"   : self.product.cacat,
            "size"                 : self.product.size,
            "is_luxury"            : self.product.isLuxuryMerk ? "1" : "0",
            "style_name"           : self.product.styleName,
            "serial_number"        : self.product.serialNumber,
            "purchase_location"    : self.product.lokasiBeli,
            "purchase_year"        : self.product.tahunBeli,
            "platform_sent_from"   : "ios"
        ]
        
        if self.product.description != "" {
            param["description"]    = self.product.description
        }
        
        if self.product.merkId == "" {
            param["proposed_brand"] = self.product.merk
        } else {
            param["brand_id"]       = self.product.merkId
            param["brand_name"]     = self.product.merk
        }
        
        if self.product.specialStory != "" {
            param["special_story"]  = self.product.specialStory
        }
        
        if self.product.alasanJual != "" {
            param["sell_reason"]    = self.product.alasanJual
        }
        
        return param
    }
    
    func setupImagesForUpload(_ param: inout [String:String]) -> Array<UIImage> {
        var imagesParam: Array<UIImage> = []
        
        var images: Array<[String:String]> = []
        
        if self.product.imagesDetail.count > 0 {
            var j = 1
            for i in 0..<self.product.imagesDetail.count {
                var url = self.product.imagesDetail[self.product.imagesIndex[i]].url
                let lbl = self.product.imagesDetail[self.product.imagesIndex[i]].label
                if let _ = self.product.imagesDetail[self.product.imagesIndex[i]].image {
                    
                    let image = TemporaryImageManager.sharedInstance.loadImageFromDocumentsDirectory(imageName: url)?.resizeWithMaxWidthOrHeight(1600)
                    if image == nil {
                        print ("Failed to load image")
                        
                        continue
                    }
                    imagesParam.append(image!)
                    url = "image\(j)"
                    
                    j += 1
                }
                
                let image: [String:String] = [
                    "url"   : url,
                    "label" : lbl
                ]
                
                images.append(image)
            }
        }
        
        param["images"] = AppToolsObjC.jsonString(from: images)
        
        return imagesParam
    }
    
    // savedraft
    func saveDraft(_ isBack: Bool) {
        let backgroundQueue = DispatchQueue(label: "com.prelo.ios.Prelo",
                                            qos: .background,
                                            attributes: .concurrent,
                                            target: nil)
        backgroundQueue.async {
            //print("Work on background queue")
            
            // save to core data
            CDDraftProduct.saveDraftV2(self.product)
        }
        
        if isBack {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Navigation
    func handleBackPressedOrSwipe() {
        let title = self.product.isEditMode ? "Edit" : (self.product.addProductType == .sell ? "Jual" : "Sewa")
        
        var message = "Kamu yakin mau keluar dari \(title) Barang? "
        if title == "Edit" {
            message += "Seluruh perubahan akan dihapus"
        } else {
            message += "Seluruh keterangan yang telah diisi akan dihapus"
        }
        message += self.product.isStartInput && !self.product.isEditMode ? ". Ingin disimpan?" : ""
        
        let alertView = SCLAlertView(appearance: Constant.appearance)
        
        alertView.addButton((!self.product.isStartInput || self.product.isEditMode) ? "Keluar" : "Simpan") {
            
            // gesture override
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            
            if (self.product.isStartInput && !self.product.isEditMode){
                
                // save the draft
                self.saveDraft(true)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
        
        if (!self.product.isStartInput || self.product.isEditMode) {
            alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
        } else {
            alertView.addBorderButton("Keluar", backgroundColor: UIColor.white, textColor: Theme.PrimaryColor, borderColor: Theme.PrimaryColor, borderRadius: 4.0, borderWidth: 2.0, showDurationStatus: false) {
                
                // gesture override
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                
                _ = self.navigationController?.popViewController(animated: true)
            }
            alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
        }
        
        alertView.showCustom(title, subTitle: message, color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        self.handleBackPressedOrSwipe()
    }
    
    // MARK: - Swipe Navigation Override
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                //print("Swiped right")
                
                self.handleBackPressedOrSwipe()
                
            default:
                break
            }
        }
    }
}

extension AddProductViewController3: UITableViewDelegate, UITableViewDataSource {
    // TODO: tableview action
    func numberOfSections(in tableView: UITableView) -> Int {
        return listSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if listSections[section] == .rentSellOnOff && !(self.product.isRent && self.product.isSell) {
            return 2 // title only + switch
        }
        return listSections[section].numberOfCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section
        let row = indexPath.row
        switch(listSections[section]) {
        case .imagesPreview:
            return AddProduct3ImagesPreviewCell.heightFor()
        case .productDetail:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor(listSections[section].subtitle)
            } else {
                return AddProduct3DetailProductCell.heightFor(self.product) // description & cacat
            }
        case .size:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor(listSections[section].subtitle)
            } else {
                return AddProduct3SizeCell.heightFor()
            }
        case .authVerification:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor(listSections[section].subtitle)
            } else {
                return AddProduct3ProductAuthVerificationCell.heightFor()
            }
        case .checklist:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor(listSections[section].subtitle)
            } else {
                return AddProduct3ImagesChecklistCell.heightFor(self.labels.count)
            }
        case .weight:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor(listSections[section].subtitle)
            } else {
                return AddProduct3WeightCell.heightFor(self.product.weight)
            }
        case .postalFee:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor((self.product.addProductType == .sell ? listSections[section].subtitle : AddProduct3Helper.rentOngkirSubtitle))
            } else {
                if self.product.addProductType == .sell {
                    return AddProduct3PostalFeeCell.heightFor()
                } else {
                    return AddProduct3RentPostalFeeCell.heightFor()
                }
            }
        case .rentPeriod:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor(listSections[section].subtitle)
            } else {
                return AddProduct3RentPeriodCell.heightFor()
            }
        case .rentSellOnOff:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor(listSections[section].subtitle)
            } else if row == 1 {
                return AddProduct3SellRentSwitchCell.heightFor((self.product.addProductType == .sell ? AddProduct3Helper.rentSwitchSubtitleSewa + "\n" + AddProduct3Helper.rentOngkirSubtitle + "\n\n" + AddProduct3Helper.rentPeriodSubtitle : AddProduct3Helper.rentSwitchSubtitleJual), isOn: (self.product.isSell && self.product.isRent))
            } else {
                if self.product.addProductType == .sell {
                    return AddProduct3RentPeriodCell.heightFor()
                } else {
                    return AddProduct3PostalFeeCell.heightFor()
                }
            }
        case .price:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor(listSections[section].subtitle)
            } else if row == 1 {
                return AddProduct3PriceCell.heightFor(self.product.isSell, isRent: self.product.isRent)
            } else {
                return AddProduct3ChargeCell.heightFor(self.chargeLabel, isEditDraftMode: self.product.isEditMode || self.product.isDraftMode)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        switch(listSections[section]) {
        case .imagesPreview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImagesPreviewCell") as! AddProduct3ImagesPreviewCell
            cell.adapt(self.product, maxImages: self.maxImages)
            
            cell.openWebView = { urlString in
                self.openWebView(urlString, title: nil)
            }
            
            cell.openImagePicker = {
                let imagePicker = Bundle.main.loadNibNamed(Tags.XibNameMultipleImagePicker, owner: nil, options: nil)?.first as! AddProduct3ListImagesViewController
                
                imagePicker.previewImages = self.product.imagesDetail
                imagePicker.index = self.product.imagesIndex
                imagePicker.labels = self.labels
                imagePicker.maxImages = self.maxImages
                imagePicker.localId = self.product.localId
                
                imagePicker.blockDone = { previewImages, index in
                    self.product.imagesDetail = previewImages
                    self.product.imagesIndex = index
                    
                    var indexPaths: Array<IndexPath> = []
                    indexPaths.append(indexPath)
                    
                    let idx = self.findSectionFromType(.checklist)
                    if idx > -1 {
                        indexPaths.append(IndexPath.init(row: 1, section: idx))
                    }
                    
                    self.product.isStartInput = true
                    
                    self.tableView.reloadRows(at: indexPaths, with: .fade)
                }
                
                // gesture override
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                
                self.navigationController?.pushViewController(imagePicker, animated: true)
            }
            
            return cell
        case .productDetail:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: listSections[section].title, subtitle: listSections[section].subtitle, faqUrl: listSections[section].faq)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3DetailProductCell") as! AddProduct3DetailProductCell
                cell.adapt(self, product: self.product)
                
                cell.reloadTable = {
                    self.tableView.reloadData()
                }
                
                cell.reloadThisRow = {
                    self.tableView.reloadRows(at: [indexPath], with: .fade)
                }
                
                cell.updateSize = {
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                    
                    self.product.isStartInput = true
                    
                    cell.txtDescription.becomeFirstResponder()
                }
                
                cell.pickCategory = {
                    self.showLoading()
                    
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let p = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdCategoryPicker) as! CategoryPickerViewController
                    
                    p.blockDone = { data in
                        let children = JSON(data["child"]!)
                        
                        if let id = children["_id"].string
                        {
                            self.product.categoryId = id
                        }
                        
                        if let name = children["name"].string
                        {
                            self.product.category = name
                        }
                        
                        let dataJson = JSON(data)
                        /*
                        if let imgName = dataJson["category_image_name"].string
                        {
                            if let imgUrl = URL(string: imgName) {
                                self.ivImage.afSetImage(withURL: imgUrl)
                            }
                        }
                        */
                        
                        self.getSizes()
                        
                        /*
                        if let catLv2Name = dataJson["category_level2_name"].string {
                            // Set placeholder for item name and description
                            guard let filePath = Bundle.main.path(forResource: "AddProductPlaceholder", ofType: "plist"), let placeholdersDict = NSDictionary(contentsOfFile: filePath) else {
                                //print("Couldn't load .plist as a dictionary")
                                return
                            }
                            ////print("placehodlersDict = \(placeholdersDict)")
                            
                            let predicate = NSPredicate(format: "SELF CONTAINS[cd] %@", "\(catLv2Name.lowercased())")
                            let matchingKeys = placeholdersDict.allKeys.filter { predicate.evaluate(with: $0) }
                            if let placeholderDict = placeholdersDict.dictionaryWithValues(forKeys: matchingKeys as! [String]).first?.1 {
                                ////print("placehodlerDict = \(placeholderDict)")
                                if let itemNamePlaceholder = (placeholderDict as AnyObject).object(forKey: "name") {
                                    self.txtName.placeholder = "mis: \(itemNamePlaceholder)"
                                }
                                if let descPlaceholder = (placeholderDict as AnyObject).object(forKey: "desc") {
                                    self.txtDescription.placeholder = "Spesifikasi barang (Opsional)\nmis: \(descPlaceholder)"
                                }
                            }
                        }
                        */
                        if let catLv1Id = dataJson["category_level1_id"].string {
                            if (catLv1Id == "55de6dbc5f6522562a2c73ef" || catLv1Id == "55de6dbc5f6522562a2c73f0") {
                                self.product.isWomenMenCategory = true
                            } else {
                                self.product.isWomenMenCategory = false
                            }
                        }
                        
                        // Show luxury fields if isLuxury
                        if (self.product.isLuxuryMerk && self.product.isWomenMenCategory) {
                            self.insertLuxurySection()
                        } else {
                            self.removeSection(.authVerification)
                        }
                        
                        self.getLabels(true)
                        
                        self.product.isStartInput = true
                        
                        self.tableView.reloadRows(at: [indexPath], with: .fade)
                        
                        self.hideLoading()
                    }
                    p.root = self
                    
                    // gesture override
                    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                    
                    self.navigationController?.pushViewController(p, animated: true)
                }
                
                cell.pickMerk = {
                    self.showLoading()
                    
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let p = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdPicker) as! PickerViewController
                    
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
                                        var segment = ""
                                        if let seg = data[i]["segments"].array, seg.count > 0 {
                                            segment = seg[0].stringValue
                                        }
                                        strToHide += ";" + (isLuxury ? "1" : "0") + ";" + segment
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
                                        self.product.merkId = hiddenStr[0]
                                        self.product.isLuxuryMerk = (hiddenStr[1] == "1") ? true : false
                                        if hiddenStr.count > 2 {
                                            self.product.segment = hiddenStr[2]
                                        } else {
                                            self.product.segment = ""
                                        }
                                    } else {
                                        self.product.merkId = ""
                                        self.product.isLuxuryMerk = false
                                        self.product.segment = ""
                                    }
                                    var x : String = PickerViewController.HideHiddenString(s)
                                    
                                    // Set chosen brand
                                    x = x.replacingOccurrences(of: "Tambahkan merek '", with: "")
                                    x = x.replacingOccurrences(of: "'", with: "")
                                    self.product.merk = x
                                    
                                    // Show luxury fields if isLuxury
                                    if (self.product.isLuxuryMerk && self.product.isWomenMenCategory) {
                                        self.insertLuxurySection()
                                    } else {
                                        self.removeSection(.authVerification)
                                    }
                                    
                                    self.getLabels(true)
                                    
                                    /*
                                    // Show submit label
                                    if (self.editMode) {
                                        if ((self.editProduct?.isFakeApprove)! || (self.editProduct?.isFakeApproveV2)!) {
                                            self.lblSubmit.isHidden = true
                                        } else {
                                            self.lblSubmit.isHidden = false
                                        }
                                    }
                                    */
                                    
                                    self.product.isStartInput = true
                                    
                                    self.tableView.reloadRows(at: [indexPath], with: .fade)
                                }
                                p.showSearch = true
                                
                                // gesture override
                                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                                
                                self.navigationController?.pushViewController(p, animated: true)
                                
                                self.hideLoading()
                            } else {
                                Constant.showDialog("Pilih Merk", message: "Oops, terdapat kesalahan saat mengambil data merk")
                                
                                self.hideLoading()
                            }
                        } else {
                            Constant.showDialog("Pilih Merk", message: "Oops, terdapat kesalahan saat mengambil data merk")
                            
                            self.hideLoading()
                        }
                    }
                }
                
                cell.pickCondition = {
                    self.showLoading()
                    
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let p = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdPicker) as! PickerViewController
                    
                    p.title = "Pilih Kondisi"
                    
                    let names : [String] = CDProductCondition.getProductConditionPickerItems()
                    let details : [String] = CDProductCondition.getProductConditionPickerDetailItems()
                    
                    p.items = names
                    p.subtitles = details
                    
                    p.selectBlock = { s in
                        self.product.conditionId = PickerViewController.RevealHiddenString(s)
                        let x = PickerViewController.HideHiddenString(s)
                        self.product.condition = x
                        
                        self.product.isStartInput = true
                        
                        self.tableView.reloadRows(at: [indexPath], with: .fade)
                        
                        self.hideLoading()
                    }
                    
                    // gesture override
                    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                    
                    self.navigationController?.pushViewController(p, animated: true)
                }
                
                return cell
            }
        case .size:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: listSections[section].title, subtitle: listSections[section].subtitle, faqUrl: listSections[section].faq)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3SizeCell") as! AddProduct3SizeCell
                cell.adapt(self, product: self.product, sizes: self.sizes, sizesTitle: self.sizesTitle)
                return cell
            }
        case .authVerification:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: listSections[section].title, subtitle: listSections[section].subtitle, faqUrl: listSections[section].faq)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ProductAuthVerificationCell") as! AddProduct3ProductAuthVerificationCell
                cell.adapt(self, product: self.product)
                return cell
            }
        case .checklist:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: listSections[section].title, subtitle: listSections[section].subtitle, faqUrl: listSections[section].faq)
                
                cell.openWebView = { urlString in
                    self.openWebView(urlString, title: "Kelengkapan")
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImagesChecklistCell") as! AddProduct3ImagesChecklistCell
                cell.adapt(self.product, labels: self.labels)
                
                cell.openImagePicker = {
                    let imagePicker = Bundle.main.loadNibNamed(Tags.XibNameMultipleImagePicker, owner: nil, options: nil)?.first as! AddProduct3ListImagesViewController
                    
                    imagePicker.previewImages = self.product.imagesDetail
                    imagePicker.index = self.product.imagesIndex
                    imagePicker.labels = self.labels
                    imagePicker.maxImages = self.maxImages
                    imagePicker.localId = self.product.localId
                    
                    imagePicker.blockDone = { previewImages, index in
                        self.product.imagesDetail = previewImages
                        self.product.imagesIndex = index
                        
                        var indexPaths: Array<IndexPath> = []
                        indexPaths.append(indexPath)
                        
                        let idx = self.findSectionFromType(.imagesPreview)
                        if idx > -1 {
                            indexPaths.append(IndexPath.init(row: 0, section: idx))
                        }
                        
                        self.product.isStartInput = true
                        
                        self.tableView.reloadRows(at: indexPaths, with: .fade)
                    }
                    
                    // gesture override
                    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                    
                    self.navigationController?.pushViewController(imagePicker, animated: true)
                }
                
                return cell
            }
        case .weight:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: listSections[section].title, subtitle: listSections[section].subtitle, faqUrl: listSections[section].faq)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3WeightCell") as! AddProduct3WeightCell
                cell.adapt(self, weight: self.product.weight)
                
                cell.reloadThisRow = {
                    self.tableView.reloadRows(at: [indexPath], with: .fade)
                }
                
                cell.updateSize = {
                    self.tableView.beginUpdates()
                    
                    if cell.vwBerat.isHidden {
                        cell.vwBerat.isHidden = false
                    }
                    
                    self.product.isStartInput = true
                    
                    self.tableView.endUpdates()
                    
                    // hack
                    // make weight select all at the first
                    cell.txtWeight.becomeFirstResponder()
                    
                    cell.txtWeight.selectedTextRange = cell.txtWeight.textRange(from: cell.txtWeight.beginningOfDocument, to: cell.txtWeight.endOfDocument)
                }
                
                return cell
            }
        case .postalFee:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: listSections[section].title, subtitle: (self.product.addProductType == .sell ? listSections[section].subtitle : AddProduct3Helper.rentOngkirSubtitle), faqUrl: listSections[section].faq)
                return cell
            } else {
                if self.product.addProductType == .sell {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3PostalFeeCell") as! AddProduct3PostalFeeCell
                    cell.adapt(self, product: self.product)
                    
                    cell.openWebView = { urlString in
                        self.openWebView(urlString, title: nil)
                    }
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3RentPostalFeeCell") as! AddProduct3RentPostalFeeCell
                    // adapt - no need
                    return cell
                }
            }
        case .rentPeriod:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: listSections[section].title, subtitle: listSections[section].subtitle, faqUrl: listSections[section].faq)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3RentPeriodCell") as! AddProduct3RentPeriodCell
                cell.adapt(self, product: self.product)
                
                cell.reloadSections = { _sections in
                    var array: Array<Int> = []
                    for i in _sections {
                        array.append(self.findSectionFromType(i))
                    }
                    
                    let indexSet = NSMutableIndexSet()
                    array.forEach(indexSet.add)
                    
                    self.tableView.reloadSections(indexSet as IndexSet, with: .fade)
                }
                
                cell.reloadRows = { _rows, _section in
                    let sec = self.findSectionFromType(_section)
                    var indexPaths: Array<IndexPath> = []
                    
                    for i in _rows {
                        indexPaths.append(IndexPath.init(row: i, section: sec))
                    }
                    
                    self.tableView.reloadRows(at: indexPaths, with: .fade)
                }
                
                return cell
            }
        case .rentSellOnOff:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: (self.product.addProductType == .sell ? listSections[section].title : "JUAL"), subtitle: listSections[section].subtitle, faqUrl: listSections[section].faq)
                return cell
            } else if row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3SellRentSwitchCell") as! AddProduct3SellRentSwitchCell
                cell.adapt((self.product.addProductType == .sell ? AddProduct3Helper.rentSwitchTitleSewa : AddProduct3Helper.rentSwitchTitleJual), subtitle: (self.product.addProductType == .sell ? AddProduct3Helper.rentSwitchSubtitleSewa + "\n" + AddProduct3Helper.rentOngkirSubtitle + "\n\n" + AddProduct3Helper.rentPeriodSubtitle : AddProduct3Helper.rentSwitchSubtitleJual), isOn: (self.product.isRent && self.product.isSell))
                
                cell.reloadSections = { _sections in
                    // hack
                    if self.product.addProductType == .sell {
                        self.product.isRent = !self.product.isRent
                    } else {
                        self.product.isSell = !self.product.isSell
                    }
                    
                    var array: Array<Int> = []
                    for i in _sections {
                        array.append(self.findSectionFromType(i))
                    }
                    
                    let indexSet = NSMutableIndexSet()
                    array.forEach(indexSet.add)
                    
                    self.tableView.reloadSections(indexSet as IndexSet, with: .fade)
                }
                
                cell.reloadRows = { _rows, _section in
                    // hack
                    var isAppend = true
                    if self.product.addProductType == .sell {
                        self.product.isRent = !self.product.isRent
                        isAppend = self.product.isRent
                    } else {
                        self.product.isSell = !self.product.isSell
                        isAppend = self.product.isSell
                    }
                    
                    self.product.isStartInput = true
                    
                    if isAppend {
                        self.tableView.insertRows(at: [IndexPath.init(row: 2, section: section)], with: .fade)
                    } else {
                        self.tableView.deleteRows(at: [IndexPath.init(row: 2, section: section)], with: .fade)
                    }
                    
                    let sec = self.findSectionFromType(_section)
                    var indexPaths: Array<IndexPath> = []
                    
                    for i in _rows {
                        indexPaths.append(IndexPath.init(row: i, section: sec))
                    }
                    
                    self.tableView.reloadRows(at: indexPaths, with: .fade)
                }
                
                return cell
            } else {
                if self.product.addProductType == .sell {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3RentPeriodCell") as! AddProduct3RentPeriodCell
                    cell.adapt(self, product: self.product)
                    
                    cell.reloadSections = { _sections in
                        var array: Array<Int> = []
                        for i in _sections {
                            array.append(self.findSectionFromType(i))
                        }
                        
                        let indexSet = NSMutableIndexSet()
                        array.forEach(indexSet.add)
                        
                        self.tableView.reloadSections(indexSet as IndexSet, with: .fade)
                    }
                    
                    cell.reloadRows = { _rows, _section in
                        let sec = self.findSectionFromType(_section)
                        var indexPaths: Array<IndexPath> = []
                        
                        for i in _rows {
                            indexPaths.append(IndexPath.init(row: i, section: sec))
                        }
                        
                        self.tableView.reloadRows(at: indexPaths, with: .fade)
                    }
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3PostalFeeCell") as! AddProduct3PostalFeeCell
                    cell.adapt(self, product: self.product)
                    
                    cell.openWebView = { urlString in
                        self.openWebView(urlString, title: nil)
                    }
                    
                    return cell
                }
            }
        case .price:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: listSections[section].title, subtitle: listSections[section].subtitle, faqUrl: listSections[section].faq)
                return cell
            } else if row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3PriceCell") as! AddProduct3PriceCell
                cell.adapt(self, product: self.product)
                
                cell.openWebView = { urlString in
                    self.openWebView(urlString, title: nil)
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ChargeCell") as! AddProduct3ChargeCell
                cell.adapt(self.product, subtitle: self.chargeLabel)
                
                cell.submitPressed = {
                    self.showLoading()
                    
                    cell.btnSubmit.isEnabled = false
                    cell.btnRemove.isEnabled = false
                    
                    if !self.validateField() {
                        self.hideLoading()
                        
                        cell.btnSubmit.isEnabled = true
                        cell.btnRemove.isEnabled = true
                        
                        return
                    }
                    
                    var param = self.setupParam()
                    let imageParam = self.setupImagesForUpload(&param)
                    
                    // TEST
                    print(param.description)
                    print(imageParam.description)
                    
                    if self.product.isEditMode {
                        // TODO: save edited product
                        
                        
                        // refresh product detail
                        self.editDoneBlock()
                    } else { // new or draft
                        // TODO: goto share product & upload
                        
                        self.saveDraft(false)
                        
                        self.hideLoading()
                        self.tableView.reloadData()
                    }
                }
                
                cell.removePressed = {
                    self.showLoading()
                    
                    cell.btnSubmit.isEnabled = false
                    cell.btnRemove.isEnabled = false
                    
                    let alertView = SCLAlertView(appearance: Constant.appearance)
                    alertView.addButton("Ya") {
                        
                        if self.product.isEditMode {
                            // check local image & remove
                            for i in self.product.imagesDetail {
                                if i.url != "" && i.image != nil {
                                    _ = TemporaryImageManager.sharedInstance.deleteImage(imageName: i.url)
                                }
                            }
                            
                            // TODO: remove product
                            
                            
                        } else if self.product.isDraftMode {
                            CDDraftProduct.delete(self.product.localId)
                            _ = self.navigationController?.popViewController(animated: true)
                        }
                    }
                    alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
                    alertView.showCustom("Hapus", subTitle: "Hapus Barang?", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
                }
                
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // do nothing
        // TODO: next
    }
}

extension AddProductViewController3: UserRelatedDelegate {
    // MARK: - login functions
    
    func userLoggedIn() {
        
    }
    
    func userCancelLogin() {
        allowLaunchLogin = false
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        _ = self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - Title Cell
class AddProduct3ImageTitleCell: UITableViewCell {
    @IBOutlet weak var SectionImage: TintedImageView!
    @IBOutlet weak var SectionTitle: UILabel!
    @IBOutlet weak var SectionFAQ: UIView! // ? , hide
    @IBOutlet weak var SectionSubtitle: UILabel! // ?
    
    var url: String = ""
    var openWebView: (_ url: String)->() = {_ in }
    
    // 40, 60 & count
    override func awakeFromNib() {
        self.SectionSubtitle.text = nil
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ image: String, title: String, subtitle: String?, faqUrl: String?) {
        self.SectionImage.image = UIImage(named: image)!
        self.SectionTitle.text = title
        
        // hack
        if let mystr = subtitle {
            let searchstr = AddProduct3Helper.boldingText
            let ranges: [NSRange]
            
            do {
                // Create the regular expression.
                let regex = try NSRegularExpression(pattern: searchstr, options: [])
                
                // Use the regular expression to get an array of NSTextCheckingResult.
                // Use map to extract the range from each result.
                ranges = regex.matches(in: mystr, options: [], range: NSMakeRange(0, mystr.characters.count)).map {$0.range}
            }
            catch {
                // There was a problem creating the regular expression
                ranges = []
            }
            
            let attString : NSMutableAttributedString = NSMutableAttributedString(string: mystr)
            if ranges.count > 0 {
                for i in 0..<ranges.count {
                    attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 12)], range: ranges[i])
                }
            }
            
            self.SectionSubtitle.attributedText = attString
        } else {
            self.SectionSubtitle.text = subtitle
        }
        
        self.SectionImage.tint = true
        self.SectionImage.tintColor = self.SectionTitle.textColor
        
        self.SectionFAQ.isHidden = (faqUrl == nil)
        self.url = (faqUrl ?? "")
    }
    
    static func heightFor(_ subtitle: String?) -> CGFloat {
        if let sub = subtitle {
            let t = sub.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 12), width: AppTools.screenWidth - 24)
            return 40 + t.height // count subtitle height
        }
        return 40
    }
    
    @IBAction func btnFAQPressed(_ sender: Any) {
        self.openWebView(self.url)
    }
}

// MARK: - Images Preview Cell
class AddProduct3ImagesPreviewCell: UITableViewCell {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var images: Array<PreviewImage> = []
    var index: Array<Int> = []
    var url: String = ""
    var openWebView: (_ url: String)->() = {_ in }
    var openImagePicker: ()->() = {}
    
    var maxImages = 10
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // TODO: Lihat tips barang Editor's Pick.
        self.url = "faq"
        
        self.setupCollection()
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func setupCollection() {
        // Set collection view
        let AddProduct3ImagesPreviewCellCollectionCell = UINib(nibName: "AddProduct3ImagesPreviewCellCollectionCell", bundle: nil)
        self.collectionView.register(AddProduct3ImagesPreviewCellCollectionCell, forCellWithReuseIdentifier: "AddProduct3ImagesPreviewCellCollectionCell")
        
        let AddProduct3ImagesPreviewCellNewOneCell = UINib(nibName: "AddProduct3ImagesPreviewCellNewOneCell", bundle: nil)
        self.collectionView.register(AddProduct3ImagesPreviewCellNewOneCell, forCellWithReuseIdentifier: "AddProduct3ImagesPreviewCellNewOneCell")
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundView = UIView(frame: self.collectionView.bounds)
        self.collectionView.backgroundColor = UIColor.white
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        layout.itemSize = CGSize(width: 82, height: 82)
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.scrollDirection = .horizontal
        self.collectionView.collectionViewLayout = layout
        
        self.collectionView.isScrollEnabled = true
        self.collectionView.isPagingEnabled = false
        self.collectionView.isDirectionalLockEnabled = true
        self.collectionView.showsHorizontalScrollIndicator = false
    }
    
    func adapt(_ product: SelectedProductItem, maxImages: Int) {
        self.maxImages = maxImages
        self.images = product.imagesDetail
        self.index = product.imagesIndex
        
        self.collectionView.reloadData()
    }
    
    // 158 , (42) count teks height
    static func heightFor() -> CGFloat {
        let sub = "Foto yang sebaiknya kamu upload adalah tampak depan, foto label/merek, tampak belakang, dan cacat (jika ada). Lihat tips barang Editor's Pick."
        let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
        return 108 + t.height // count subtitle height
    }
    
    @IBAction func btnFAQPressed(_ sender: Any) {
        self.openWebView(self.url)
    }
}

extension AddProduct3ImagesPreviewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.images.count == self.maxImages ? self.maxImages : self.images.count + 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row < self.images.count {
            // Create cell
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "AddProduct3ImagesPreviewCellCollectionCell", for: indexPath) as! AddProduct3ImagesPreviewCellCollectionCell
            cell.adapt(self.images[self.index[indexPath.row]].image, urlString: self.images[self.index[indexPath.row]].url, label: self.images[self.index[indexPath.row]].label)
            
            return cell
        } else {
            // Create cell
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "AddProduct3ImagesPreviewCellNewOneCell", for: indexPath) as! AddProduct3ImagesPreviewCellNewOneCell
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 82, height: 82)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // open image picker
        self.openImagePicker()
    }
}

class AddProduct3ImagesPreviewCellCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imagesPreview: UIImageView!
    @IBOutlet weak var labelView: UIView! // backgrund
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imagesPreview.contentMode = .scaleAspectFill
        
        self.backgroundColor = UIColor.init(hexString: "#EDEDED")
        self.labelView.backgroundColor = UIColor.init(hexString: "#B4B4B4").alpha(0.75)
    }
    
    func adapt(_ image: UIImage?, urlString: String, label: String) {
        if image == nil && urlString != "" {
            if let url = URL(string: urlString) {
                self.imagesPreview.afSetImage(withURL: url)
            } else {
                self.imagesPreview.image = UIImage(named: "placeholder-standar-white")
            }
        } else {
            self.imagesPreview.image = (image ?? UIImage(named: "placeholder-standar-white"))
        }
        
        self.label.text = label
    }
    
    // 82 x 82
}

class AddProduct3ImagesPreviewCellNewOneCell: UICollectionViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.init(hexString: "#EDEDED")
    }
    
    // 82 x 82
}

// MARK: - Detail Product Cell
class AddProduct3DetailProductCell: UITableViewCell {
    @IBOutlet weak var txtProductName: UITextField!
    @IBOutlet weak var lblCategory: UILabel!
    @IBOutlet weak var lblMerk: UILabel!
    @IBOutlet weak var lblCondition: UILabel!
    @IBOutlet weak var txtCacat: UITextField!
    @IBOutlet weak var txtSpecialStory: UITextField!
    @IBOutlet weak var txtAlasanJual: UITextField!
    @IBOutlet weak var txtDescription: UITextView!
    
    @IBOutlet weak var vwCacat: UIView! // hide -> show
    @IBOutlet weak var consTopSpecialStory: NSLayoutConstraint! // 0 -> 40
    @IBOutlet weak var consHeightDescription: NSLayoutConstraint! // min 49.5
    
    var updateSize: ()->() = {}
    var reloadThisRow: ()->() = {}
    var reloadTable: ()->() = {}
    var parent: AddProductViewController3!
    
    var pickCategory: ()->() = {}
    var pickMerk: ()->() = {}
    var pickCondition: ()->() = {}
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.txtProductName.delegate = self
        self.txtCacat.delegate = self
        self.txtSpecialStory.delegate = self
        self.txtAlasanJual.delegate = self
        self.txtDescription.delegate = self
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ parent: AddProductViewController3, product: SelectedProductItem) {
        self.parent = parent
        
        self.txtProductName.text = product.name
        self.lblCategory.text = product.category
        self.lblMerk.text = product.merk
        self.lblCondition.text = product.condition
        self.txtCacat.text = product.cacat
        self.txtSpecialStory.text = product.specialStory
        self.txtAlasanJual.text = product.alasanJual
        self.txtDescription.text = product.description
        
        if (product.condition.lowercased() as NSString).range(of: "cukup").location != NSNotFound {
            self.consTopSpecialStory.constant = 40
            self.vwCacat.isHidden = false
        } else {
            self.consTopSpecialStory.constant = 0
            self.vwCacat.isHidden = true
        }
        
        let sizeThatShouldFitTheContent = txtDescription.sizeThatFits(txtDescription.frame.size)
        self.consHeightDescription.constant = sizeThatShouldFitTheContent.height < 49.5 ? 49.5 : sizeThatShouldFitTheContent.height
    }
    
    // 356 -> -40 // count description height
    // 266.5 + 40 + 49.5++
    static func heightFor(_ product: SelectedProductItem) -> CGFloat {
        let sub = product.description
        let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: AppTools.screenWidth - 24 - 8)
        return 266.5 + ((product.condition.lowercased() as NSString).range(of: "cukup").location != NSNotFound ? 40 : 0) + (t.height > 49.5 ? t.height : 49.5) // count subtitle height
    }
    
    @IBAction func btnPickCategoryPressed(_ sender: Any) {
        self.pickCategory()
    }
    
    @IBAction func btnPickMerkPressed(_ sender: Any) {
        self.pickMerk()
    }
    
    @IBAction func btnPickConditionPressed(_ sender: Any) {
        self.pickCondition()
    }
}

extension AddProduct3DetailProductCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.parent.product.isStartInput = true
        if textField == self.txtProductName {
            self.parent.product.name = self.txtProductName.text!
        } else if textField == self.txtCacat {
            self.parent.product.cacat = self.txtCacat.text!
        } else if textField == self.txtSpecialStory {
            self.parent.product.specialStory = self.txtSpecialStory.text!
        } else if textField == self.txtAlasanJual {
            self.parent.product.alasanJual = self.txtAlasanJual.text!
        }
        return true
    }
}

extension AddProduct3DetailProductCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.parent.product.description = textView.text
        
        let sizeThatShouldFitTheContent = txtDescription.sizeThatFits(txtDescription.frame.size)
        
        if self.consHeightDescription.constant != (sizeThatShouldFitTheContent.height < 49.5 ? 49.5 : sizeThatShouldFitTheContent.height) {
            self.consHeightDescription.constant = (sizeThatShouldFitTheContent.height < 49.5 ? 49.5 : sizeThatShouldFitTheContent.height)
            
            self.updateSize()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            self.parent.product.isStartInput = true
            return false
        }
        
        return true
    }
}

// MARK: - Weight Cell (Sell)
class AddProduct3WeightCell: UITableViewCell {
    @IBOutlet weak var vw1kg: BorderedView!
    @IBOutlet weak var img1kg: TintedImageView!
    @IBOutlet weak var lbl1kg: UILabel!
    @IBOutlet weak var vw12kg: BorderedView!
    @IBOutlet weak var img12kg: TintedImageView!
    @IBOutlet weak var lbl12kg: UILabel!
    @IBOutlet weak var vw2kg: BorderedView!
    @IBOutlet weak var img2kg: TintedImageView!
    @IBOutlet weak var lbl2kg: UILabel!
    
    @IBOutlet weak var vwBerat: UIView! // hide
    @IBOutlet weak var txtWeight: UITextField!
    
    var parent: AddProductViewController3!
    var updateSize: ()->() = {}
    var reloadThisRow: ()->() = {}
    var disactiveColor = UIColor.init(hexString: "#727272")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // numeric keyboards hack
        let ViewForDoneButtonOnKeyboard = UIToolbar()
        ViewForDoneButtonOnKeyboard.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let btnDoneOnKeyboard = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneBtnfromKeyboardClicked))
        ViewForDoneButtonOnKeyboard.items = [flex, btnDoneOnKeyboard, UIBarButtonItem()]
        self.txtWeight.inputAccessoryView = ViewForDoneButtonOnKeyboard
        
        self.img1kg.tint = true
        self.img12kg.tint = true
        self.img2kg.tint = true
        
        self.img1kg.tintColor = disactiveColor
        self.img12kg.tintColor = disactiveColor
        self.img2kg.tintColor = disactiveColor
        
        self.vwBerat.isHidden = true
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func doneBtnfromKeyboardClicked() {
        self.parent.product.weight = self.txtWeight.text!
        self.txtWeight.resignFirstResponder()
        self.parent.product.isStartInput = true
        self.reloadThisRow()
    }
    
    func adapt(_ parent: AddProductViewController3, weight: String) {
        self.parent = parent
        
        if weight != "" {
            self.txtWeight.text = weight
            if self.vwBerat.isHidden {
                self.vwBerat.isHidden = false
            }
            if weight.int < 1000 {
                self.vw1kg.borderColor = Theme.PrimaryColor
                self.img1kg.tintColor = Theme.PrimaryColor
                self.lbl1kg.textColor = Theme.PrimaryColor
                
                self.vw12kg.borderColor = disactiveColor
                self.img12kg.tintColor = disactiveColor
                self.lbl12kg.textColor = disactiveColor
                
                self.vw2kg.borderColor = disactiveColor
                self.img2kg.tintColor = disactiveColor
                self.lbl2kg.textColor = disactiveColor
            } else if weight.int < 2000 {
                self.vw1kg.borderColor = disactiveColor
                self.img1kg.tintColor = disactiveColor
                self.lbl1kg.textColor = disactiveColor
                
                self.vw12kg.borderColor = Theme.PrimaryColor
                self.img12kg.tintColor = Theme.PrimaryColor
                self.lbl12kg.textColor = Theme.PrimaryColor
                
                self.vw2kg.borderColor = disactiveColor
                self.img2kg.tintColor = disactiveColor
                self.lbl2kg.textColor = disactiveColor
            } else {
                self.vw1kg.borderColor = disactiveColor
                self.img1kg.tintColor = disactiveColor
                self.lbl1kg.textColor = disactiveColor
                
                self.vw12kg.borderColor = disactiveColor
                self.img12kg.tintColor = disactiveColor
                self.lbl12kg.textColor = disactiveColor
                
                self.vw2kg.borderColor = Theme.PrimaryColor
                self.img2kg.tintColor = Theme.PrimaryColor
                self.lbl2kg.textColor = Theme.PrimaryColor
            }
        }
    }
    
    // 72 , 118
    static func heightFor(_ weight: String) -> CGFloat {
        if weight != "" {
            return 118
        }
        return 72
    }
    
    @IBAction func btn1kgPressed(_ sender: Any) {
        if (self.txtWeight.text?.int)! >= 1000 || (self.txtWeight.text == nil || self.txtWeight.text == "") {
            self.vw1kg.borderColor = Theme.PrimaryColor
            self.img1kg.tintColor = Theme.PrimaryColor
            self.lbl1kg.textColor = Theme.PrimaryColor
            
            self.vw12kg.borderColor = disactiveColor
            self.img12kg.tintColor = disactiveColor
            self.lbl12kg.textColor = disactiveColor
            
            self.vw2kg.borderColor = disactiveColor
            self.img2kg.tintColor = disactiveColor
            self.lbl2kg.textColor = disactiveColor
            
            self.txtWeight.text = "500"
            self.parent.product.weight = self.txtWeight.text!
            self.updateSize()
        }
    }
    
    @IBAction func btn12kgPressed(_ sender: Any) {
        if (self.txtWeight.text?.int)! < 1000 || (self.txtWeight.text?.int)! > 2000 {
            self.vw1kg.borderColor = disactiveColor
            self.img1kg.tintColor = disactiveColor
            self.lbl1kg.textColor = disactiveColor
            
            self.vw12kg.borderColor = Theme.PrimaryColor
            self.img12kg.tintColor = Theme.PrimaryColor
            self.lbl12kg.textColor = Theme.PrimaryColor
            
            self.vw2kg.borderColor = disactiveColor
            self.img2kg.tintColor = disactiveColor
            self.lbl2kg.textColor = disactiveColor
            
            self.txtWeight.text = "1500"
            self.parent.product.weight = self.txtWeight.text!
            self.updateSize()
            
            if self.vwBerat.isHidden {
                self.vwBerat.isHidden = false
            }
        }
    }
    
    @IBAction func btn2kgPressed(_ sender: Any) {
        if (self.txtWeight.text?.int)! <= 2000 {
            self.vw1kg.borderColor = disactiveColor
            self.img1kg.tintColor = disactiveColor
            self.lbl1kg.textColor = disactiveColor
            
            self.vw12kg.borderColor = disactiveColor
            self.img12kg.tintColor = disactiveColor
            self.lbl12kg.textColor = disactiveColor
            
            self.vw2kg.borderColor = Theme.PrimaryColor
            self.img2kg.tintColor = Theme.PrimaryColor
            self.lbl2kg.textColor = Theme.PrimaryColor
            
            self.txtWeight.text = "2500"
            self.parent.product.weight = self.txtWeight.text!
            self.updateSize()
        }
    }
}

// MARK: - Postal Fee Cell (Sell)
// TODO: Aktifkan & Beri Fungsi (Action) -> Asuransi & Lokal Free Ongkir
class AddProduct3PostalFeeCell: UITableViewCell {
    @IBOutlet weak var vwFreeOngkir: BorderedView!
    @IBOutlet weak var imgFreeOngkir: TintedImageView!
    @IBOutlet weak var lblFreeOngkir: UILabel!
    @IBOutlet weak var vwPaidOngkir: BorderedView!
    @IBOutlet weak var imgPaidOngkir: TintedImageView!
    @IBOutlet weak var lblPaidOngkir: UILabel!
    @IBOutlet weak var lblRegion: UILabel!
    @IBOutlet weak var btnSwitch: UISwitch!
    
    var parent: AddProductViewController3!
    var disactiveColor = UIColor.init(hexString: "#727272")
    var url: String = ""
    var openWebView: (_ url: String)->() = {_ in }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // asuransi & lokal free ongkir disable
        // TODO: Lihat Syarat dan Ketentuan.
        self.url = "faq"
        
        self.imgFreeOngkir.tint = true
        self.imgPaidOngkir.tint = true
        
        self.imgFreeOngkir.tintColor = disactiveColor
        self.imgPaidOngkir.tintColor = disactiveColor
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_  parent: AddProductViewController3, product: SelectedProductItem) {
        self.parent = parent
        // asuransi & lokal free ongkir disable
        /*
        self.btnSwitch.isOn = (product.isInsurance == "1")
        */
        
        if product.isFreeOngkir == "1" {
            self.vwFreeOngkir.borderColor = Theme.PrimaryColor
            self.imgFreeOngkir.tintColor = Theme.PrimaryColor
            self.lblFreeOngkir.textColor = Theme.PrimaryColor
            
            self.vwPaidOngkir.borderColor = disactiveColor
            self.imgPaidOngkir.tintColor = disactiveColor
            self.lblPaidOngkir.textColor = disactiveColor
        } else {
            self.vwFreeOngkir.borderColor = disactiveColor
            self.imgFreeOngkir.tintColor = disactiveColor
            self.lblFreeOngkir.textColor = disactiveColor
            
            self.vwPaidOngkir.borderColor = Theme.PrimaryColor
            self.imgPaidOngkir.tintColor = Theme.PrimaryColor
            self.lblPaidOngkir.textColor = Theme.PrimaryColor
        }
        
        // asuransi & lokal free ongkir disable
        /*
        if product.freeOngkirRegions.count > 0 {
            var region = ""
            for i in product.freeOngkirRegions {
                region += i.name + ", "
            }
            self.lblRegion.text = region.trimmingCharacters(in: CharacterSet.init(charactersIn: ", "))
        }
        */
    }
    
    // 206, count teks height
    static func heightFor() -> CGFloat {
        // asuransi & lokal free ongkir disable
        /*
        let sub = "Barang yang biasanya butuh asuransi kurir: handphone, laptop, dll. Ongkos kirim barang jualan kamu akan sesuai dengan kurir yang tersimpan di sistem. Lihat Syarat dan Ketentuan."
        let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
        return 164 + t.height // count subtitle height
        */
        
        return 72
    }
    
    @IBAction func btnFAQPressed(_ sender: Any) {
        // asuransi & lokal free ongkir disable
        /*
        self.openWebView(self.url)
        */
    }
    
    @IBAction func btnFreeOngkirPressed(_ sender: Any) {
        if (self.parent.product.isFreeOngkir == "0") {
            self.vwFreeOngkir.borderColor = Theme.PrimaryColor
            self.imgFreeOngkir.tintColor = Theme.PrimaryColor
            self.lblFreeOngkir.textColor = Theme.PrimaryColor
            
            self.vwPaidOngkir.borderColor = disactiveColor
            self.imgPaidOngkir.tintColor = disactiveColor
            self.lblPaidOngkir.textColor = disactiveColor
            
            self.parent.product.isFreeOngkir = "1"
        }
    }
    
    @IBAction func btnPaidOngkirPressed(_ sender: Any) {
        if (self.parent.product.isFreeOngkir == "1") {
            self.vwFreeOngkir.borderColor = disactiveColor
            self.imgFreeOngkir.tintColor = disactiveColor
            self.lblFreeOngkir.textColor = disactiveColor
            
            self.vwPaidOngkir.borderColor = Theme.PrimaryColor
            self.imgPaidOngkir.tintColor = Theme.PrimaryColor
            self.lblPaidOngkir.textColor = Theme.PrimaryColor
            
            self.parent.product.isFreeOngkir = "0"
        }
    }
}

// MARK: - Product Auth Verification Cell (Luxury)
class AddProduct3ProductAuthVerificationCell: UITableViewCell {
    @IBOutlet weak var txtStyleName: UITextField!
    @IBOutlet weak var txtSerialNumber: UITextField!
    @IBOutlet weak var txtLokasiBeli: UITextField!
    @IBOutlet weak var txtTahunBeli: UITextField!
    
    var parent: AddProductViewController3!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.txtStyleName.delegate = self
        self.txtSerialNumber.delegate = self
        self.txtLokasiBeli.delegate = self
        
        // numeric keyboards hack
        let ViewForDoneButtonOnKeyboard = UIToolbar()
        ViewForDoneButtonOnKeyboard.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let btnDoneOnKeyboard = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneBtnfromKeyboardClicked))
        ViewForDoneButtonOnKeyboard.items = [flex, btnDoneOnKeyboard, UIBarButtonItem()]
        self.txtTahunBeli.inputAccessoryView = ViewForDoneButtonOnKeyboard
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func doneBtnfromKeyboardClicked() {
        self.parent.product.tahunBeli = self.txtTahunBeli.text!
        self.txtTahunBeli.resignFirstResponder()
        self.parent.product.isStartInput = true
    }
    
    func adapt(_ parent: AddProductViewController3, product: SelectedProductItem) {
        self.parent = parent
        
        self.txtStyleName.text = product.styleName
        self.txtSerialNumber.text = product.serialNumber
        self.txtLokasiBeli.text = product.lokasiBeli
        self.txtTahunBeli.text = product.tahunBeli
    }
    
    // 172
    static func heightFor() -> CGFloat {
        return 172
    }
}

extension AddProduct3ProductAuthVerificationCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.parent.product.isStartInput = true
        if textField == self.txtStyleName {
            self.parent.product.styleName = self.txtStyleName.text!
        } else if textField == self.txtSerialNumber {
            self.parent.product.serialNumber = self.txtSerialNumber.text!
        } else if textField == self.txtLokasiBeli {
            self.parent.product.lokasiBeli = self.txtLokasiBeli.text!
        }
        return true
    }
}

// MARK: - Images Checklist Cell
class AddProduct3ImagesChecklistCell: UITableViewCell {
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var consHeightCollectionView: NSLayoutConstraint!
    
    var images: Array<PreviewImage> = []
    var labels: Array<String> = []
    var openImagePicker: ()->() = {}
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupCollection()
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func setupCollection() {
        // Set collection view
        let AddProduct3ImagesChecklistCellCollectionCell = UINib(nibName: "AddProduct3ImagesChecklistCellCollectionCell", bundle: nil)
        self.collectionView.register(AddProduct3ImagesChecklistCellCollectionCell, forCellWithReuseIdentifier: "AddProduct3ImagesChecklistCellCollectionCell")
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundView = UIView(frame: self.collectionView.bounds)
        self.collectionView.backgroundColor = UIColor.white
        
        let layout: UICollectionViewFlowLayout = LeftAlignedCollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        layout.itemSize = CGSize(width: 120, height: 20)
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        self.collectionView.collectionViewLayout = layout
        
        self.collectionView.isScrollEnabled = false
        self.collectionView.isPagingEnabled = false
        self.collectionView.isDirectionalLockEnabled = true
    }
    
    func adapt(_ product: SelectedProductItem, labels: Array<String>) {
        self.images = product.imagesDetail
        self.labels = labels
        
        let count = labels.count
        if count > 0 {
            let w = AppTools.screenWidth - 24 - 8
            var c: CGFloat = 120
            var i = 1
            while true {
                if i == count {
                    break
                }
                if c + 4.0 + 120.0 > w {
                    break
                }
                i += 1
                c += 120.0 + 4.0
            }
            let h = 24.0 * ceil(Double(count) / Double(i)) + 4.0
            self.consHeightCollectionView.constant = CGFloat(h)
        }
        
        self.collectionView.reloadData()
    }
    
    // 66, count height collection view (20 x total/y), count teks height
    // count of labels
    static func heightFor(_ count: Int) -> CGFloat {
        let w = AppTools.screenWidth - 24 - 8
        var c: CGFloat = 130
        var i = 1
        while true {
            if i == count {
                break
            }
            if c + 4.0 + 130.0 > w {
                break
            }
            i += 1
            c += 130.0 + 4.0
        }
        let h = 24.0 * ceil(Double(count) / Double(i)) + 4.0
        return 46 + CGFloat(h) // count subtitle height
    }
    
    func isLabelExist(_ label: String) -> Bool {
        for i in self.images {
            if i.label == label {
                return true
            }
        }
        return false
    }
    
    @IBAction func btnPickImagePressed(_ sender: Any) {
        self.openImagePicker()
    }
}

extension AddProduct3ImagesChecklistCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.labels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Create cell
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "AddProduct3ImagesChecklistCellCollectionCell", for: indexPath) as! AddProduct3ImagesChecklistCellCollectionCell
        cell.adapt(self.labels[indexPath.row], isExist: self.isLabelExist(self.labels[indexPath.row]))
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 130, height: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // open image picker
        // show image
    }
}

class AddProduct3ImagesChecklistCellCollectionCell: UICollectionViewCell {
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblCheck: UILabel! // tosca
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.lblCheck.backgroundColor = UIColor.init(hexString: "#EAEAEA")
    }
    
    override func prepareForReuse() {
        self.lblCheck.backgroundColor = UIColor.init(hexString: "#EAEAEA")
    }
    
    func adapt(_ name: String, isExist: Bool) {
        self.lblName.text = name
        
        if isExist {
            self.lblCheck.backgroundColor = Theme.PrimaryColor
        }
    }
    
    // 120 x 20
}

// MARK: - Price Cell
class AddProduct3PriceCell: UITableViewCell {
    @IBOutlet weak var lblHargaSewa: UILabel! // update -> per Hari/Minggu/Bulan
    @IBOutlet weak var txtHargaBeli: UITextField!
    @IBOutlet weak var txtHargaJual: UITextField!
    @IBOutlet weak var txtHargaSewa: UITextField!
    @IBOutlet weak var txtDeposit: UITextField!
    
    @IBOutlet weak var vwHargaJual: UIView! // sell: unhide, rent: hide
    
    @IBOutlet weak var vwHargaSewa: UIView! // sell: hide, rent: unhide
    @IBOutlet weak var vwHargaDeposit: UIView! // sell: hide, rent: unhide
    @IBOutlet weak var vwNotifSewa: UIView! // sell: hide, rent: unhide
    @IBOutlet weak var consTopHargaSewa: NSLayoutConstraint! // 40 -> 0
    
    var parent: AddProductViewController3!
    var url: String = ""
    var openWebView: (_ url: String)->() = {_ in }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // TODO: Lihat Syarat dan Ketentuan.
        self.url = "faq"
        
        // numeric keyboards hack
        let ViewForDoneButtonOnKeyboard = UIToolbar()
        ViewForDoneButtonOnKeyboard.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let btnDoneOnKeyboard = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneBtnfromKeyboardClicked))
        ViewForDoneButtonOnKeyboard.items = [flex, btnDoneOnKeyboard, UIBarButtonItem()]
        self.txtHargaBeli.inputAccessoryView = ViewForDoneButtonOnKeyboard
        self.txtHargaJual.inputAccessoryView = ViewForDoneButtonOnKeyboard
        self.txtHargaSewa.inputAccessoryView = ViewForDoneButtonOnKeyboard
        self.txtDeposit.inputAccessoryView = ViewForDoneButtonOnKeyboard
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func doneBtnfromKeyboardClicked() {
        self.parent.product.hargaBeli = self.txtHargaBeli.text!
        self.parent.product.hargaJual = self.txtHargaJual.text!
        self.parent.product.hargaSewa = self.txtHargaSewa.text!
        self.parent.product.deposit = self.txtDeposit.text!
        self.txtHargaBeli.resignFirstResponder()
        self.txtHargaJual.resignFirstResponder()
        self.txtHargaSewa.resignFirstResponder()
        self.txtDeposit.resignFirstResponder()
        self.parent.product.isStartInput = true
    }
    
    func adapt(_ parent: AddProductViewController3, product: SelectedProductItem) {
        self.parent = parent
        
        if product.isRent && product.modeSewa != "" {
            self.lblHargaSewa.text = "Harga Sewa (Per " + product.modeSewa.uppercased() + ")"
        }
        
        self.txtHargaBeli.text = product.hargaBeli
        
        if !product.isSell {
            self.vwHargaJual.isHidden = true
            self.consTopHargaSewa.constant = 0
        } else {
            self.vwHargaJual.isHidden = false
            self.consTopHargaSewa.constant = 40
            
            self.txtHargaJual.text = product.hargaJual
        }
        
        if !product.isRent {
            self.vwHargaSewa.isHidden = true
            self.vwHargaDeposit.isHidden = true
            self.vwNotifSewa.isHidden = true
        } else {
            self.vwHargaSewa.isHidden = false
            self.vwHargaDeposit.isHidden = false
            self.vwNotifSewa.isHidden = false
            
            self.txtHargaSewa.text = product.hargaSewa
            self.txtDeposit.text = product.deposit
        }
    }
    
    // 258 (all), sell: 88, rent: 218
    static func heightFor(_ isSell: Bool, isRent: Bool) -> CGFloat {
        let sub = "Harga Deposit merupakan biaya maksimal yang dapatdikembalikan apabila ada kendala dalam proses penyewaan. Lihat Syarat dan Ketentuan."
        let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
        if isSell && isRent {
            return 216 + t.height // count subtitle height
        } else if isSell {
            return 88
        }
        return 176 + t.height // count subtitle height
    }
    
    @IBAction func btnFAQPressed(_ sender: Any) {
        self.openWebView(self.url)
    }
}

// MARK: - Charge Cell
class AddProduct3ChargeCell: UITableViewCell {
    @IBOutlet weak var lblComissions: UILabel!
    @IBOutlet weak var btnSubmit: UIButton! // -> Loading
    @IBOutlet weak var btnRemove: BorderedButton! // hide
    @IBOutlet weak var lblCharge: UILabel!
    
    @IBOutlet weak var consTopBtnSubmit: NSLayoutConstraint! // 8 + (8 + height)
    
    var submitPressed: ()->() = {}
    var removePressed: ()->() = {}
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.btnRemove.isHidden = true
        
        self.btnSubmit.setTitle("Loading...", for: .disabled)
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.btnSubmit.isEnabled = true
        self.btnRemove.isEnabled = true
    }
    
    func adapt(_ product: SelectedProductItem, subtitle: String?) {
        if product.isEditMode || product.isDraftMode {
            self.btnSubmit.setTitle("SIMPAN", for: .normal)
            self.btnRemove.isHidden = false
        }
        
        self.lblComissions.text = product.commision
        
        var h: CGFloat = 8
        if let sub = subtitle {
            let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
            h += t.height + 8
            
            self.lblCharge.text = sub // AddProduct3 VC:chargeLabel
        }
        
        self.consTopBtnSubmit.constant = h
    }
    
    // 162, count teks, hide unhide button hapus
    static func heightFor(_ subtitle: String?, isEditDraftMode: Bool) -> CGFloat {
        var h: CGFloat = -8
        if let sub = subtitle {
            let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
            h = t.height
        }
        return 104 + (isEditDraftMode ? 48.0 : 0) + h // count subtitle height
    }
    
    @IBAction func btnSubmitPressed(_ sender: Any) {
        self.submitPressed()
    }
    
    @IBAction func btnRemovePressed(_ sender: Any) {
        self.removePressed()
    }
}

// MARK: - Rent
// MARK: - Rent Period Cell
class AddProduct3RentPeriodCell: UITableViewCell {
    @IBOutlet weak var vwPerHari: BorderedView!
    @IBOutlet weak var lblPerHari: UILabel!
    @IBOutlet weak var vwPerMinggu: BorderedView!
    @IBOutlet weak var lblPerMinggu: UILabel!
    @IBOutlet weak var vwPerBulan: BorderedView!
    @IBOutlet weak var lblPerBulan: UILabel!
    
    var reloadRows: (_ rows: Array<Int>, _ section: AddProduct3SectionType)->() = {_, _ in }
    var reloadSections: (_ sections: Array<AddProduct3SectionType>)->() = {_ in }
    var parent: AddProductViewController3!
    var disactiveColor = UIColor.init(hexString: "#727272")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ parent: AddProductViewController3, product: SelectedProductItem) {
        self.parent = parent
        
        if product.modeSewa == "hari" {
            self.vwPerHari.borderColor = Theme.PrimaryColor
            self.lblPerHari.textColor = Theme.PrimaryColor
            
            self.vwPerMinggu.borderColor = disactiveColor
            self.lblPerMinggu.textColor = disactiveColor
            
            self.vwPerBulan.borderColor = disactiveColor
            self.lblPerBulan.textColor = disactiveColor
        } else if product.modeSewa == "minggu" {
            self.vwPerHari.borderColor = disactiveColor
            self.lblPerHari.textColor = disactiveColor
            
            self.vwPerMinggu.borderColor = Theme.PrimaryColor
            self.lblPerMinggu.textColor = Theme.PrimaryColor
            
            self.vwPerBulan.borderColor = disactiveColor
            self.lblPerBulan.textColor = disactiveColor
        } else if product.modeSewa == "bulan" {
            self.vwPerHari.borderColor = disactiveColor
            self.lblPerHari.textColor = disactiveColor
            
            self.vwPerMinggu.borderColor = disactiveColor
            self.lblPerMinggu.textColor = disactiveColor
            
            self.vwPerBulan.borderColor = Theme.PrimaryColor
            self.lblPerBulan.textColor = Theme.PrimaryColor
        }
    }
    
    // 72
    static func heightFor() -> CGFloat {
        return 72
    }
    
    @IBAction func btnPerHariPressed(_ sender: Any) {
        if self.parent.product.modeSewa != "hari" {
            self.vwPerHari.borderColor = Theme.PrimaryColor
            self.lblPerHari.textColor = Theme.PrimaryColor
            
            self.vwPerMinggu.borderColor = disactiveColor
            self.lblPerMinggu.textColor = disactiveColor
            
            self.vwPerBulan.borderColor = disactiveColor
            self.lblPerBulan.textColor = disactiveColor
            
            self.parent.product.modeSewa = "hari"
            self.reloadRows([ 1 ], .price)
            //self.reloadSections([ .price ])
        }
    }
    
    @IBAction func btnPerMingguPressed(_ sender: Any) {
        if self.parent.product.modeSewa != "minggu" {
            self.vwPerHari.borderColor = disactiveColor
            self.lblPerHari.textColor = disactiveColor
            
            self.vwPerMinggu.borderColor = Theme.PrimaryColor
            self.lblPerMinggu.textColor = Theme.PrimaryColor
            
            self.vwPerBulan.borderColor = disactiveColor
            self.lblPerBulan.textColor = disactiveColor
            
            self.parent.product.modeSewa = "minggu"
            self.reloadRows([ 1 ], .price)
            //self.reloadSections([ .price ])
        }
    }
    
    @IBAction func btnPerBulanPressed(_ sender: Any) {
        if self.parent.product.modeSewa != "bulan" {
            self.vwPerHari.borderColor = disactiveColor
            self.lblPerHari.textColor = disactiveColor
            
            self.vwPerMinggu.borderColor = disactiveColor
            self.lblPerMinggu.textColor = disactiveColor
            
            self.vwPerBulan.borderColor = Theme.PrimaryColor
            self.lblPerBulan.textColor = Theme.PrimaryColor
            
            self.parent.product.modeSewa = "bulan"
            self.reloadRows([ 1 ], .price)
            //self.reloadSections([ .price ])
        }
    }
}

// MARK: - Sell Rent Switch Cell
class AddProduct3SellRentSwitchCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var btnSwitch: UISwitch!
    
    var reloadRows: (_ rows: Array<Int>, _ section: AddProduct3SectionType)->() = {_, _ in }
    var reloadSections: (_ sections: Array<AddProduct3SectionType>)->() = {_ in }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ title: String, subtitle: String, isOn: Bool) {
        self.lblTitle.text = title
        //self.lblSubTitle.text = subtitle
        
        // hack
        let mystr = subtitle
        let searchstr = AddProduct3Helper.boldingText
        let ranges: [NSRange]
        
        do {
            // Create the regular expression.
            let regex = try NSRegularExpression(pattern: searchstr, options: [])
            
            // Use the regular expression to get an array of NSTextCheckingResult.
            // Use map to extract the range from each result.
            ranges = regex.matches(in: mystr, options: [], range: NSMakeRange(0, mystr.characters.count)).map {$0.range}
        }
        catch {
            // There was a problem creating the regular expression
            ranges = []
        }
        
        let attString : NSMutableAttributedString = NSMutableAttributedString(string: mystr)
        if ranges.count > 0 {
            for i in 0..<ranges.count {
                attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 12)], range: ranges[i])
            }
        }
        
        self.lblSubTitle.attributedText = attString
        
        self.btnSwitch.isOn = isOn
    }
    
    // 99 , (32) count teks
    static func heightFor(_ substring: String?, isOn: Bool) -> CGFloat {
        if isOn {
            var h: CGFloat = 0
            if let sub = substring {
                let t = sub.boundsWithFontSize(UIFont.boldSystemFont(ofSize: 12), width: AppTools.screenWidth - 24)
                h = t.height
            }
            return 71 + h // count subtitle height
        }
        return 60
    }
    
    @IBAction func btnSwitchPressed(_ sender: Any) {
        self.reloadRows([ 1 ], .price)
        //self.reloadSections([ .rentSellOnOff, .price ])
    }
}

// MARK: - Rent Postal Fee Cell
class AddProduct3RentPostalFeeCell: UITableViewCell {
    @IBOutlet weak var vwPaidOngkir: BorderedView!
    @IBOutlet weak var imgPaidOngkir: TintedImageView!
    @IBOutlet weak var lblPaidOngkir: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.vwPaidOngkir.borderColor = Theme.PrimaryColor
        self.imgPaidOngkir.tint = true
        self.imgPaidOngkir.tintColor = Theme.PrimaryColor
        self.lblPaidOngkir.textColor = Theme.PrimaryColor
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    // 72
    static func heightFor() -> CGFloat {
        return 72
    }
}

// MARK: - Size Cell -> shoes, etc
class AddProduct3SizeCell: UITableViewCell {
    @IBOutlet weak var sizePickerView: AKPickerView!
    @IBOutlet weak var lblTitle: UILabel!
    
    @IBOutlet weak var txtSize: UITextField!
    
    var parent: AddProductViewController3!
    var sizes: Array<String> = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.txtSize.delegate = self
        //self.txtSize.isEnabled = false
        
        self.setupPickerView()
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func setupPickerView() {
        self.sizePickerView.dataSource = self
        self.sizePickerView.delegate = self
        
        self.sizePickerView.font = UIFont.systemFont(ofSize: 12)
        self.sizePickerView.highlightedFont = UIFont(name: "HelveticaNeue-Light", size: 12)
        self.sizePickerView.highlightedTextColor = Theme.PrimaryColor
        self.sizePickerView.interitemSpacing = 20
        self.sizePickerView.fisheyeFactor = 0.001
        self.sizePickerView.pickerViewStyle = AKPickerViewStyle.style3D
        self.sizePickerView.isMaskDisabled = false
    }
    
    func adapt(_ parent: AddProductViewController3, product: SelectedProductItem, sizes: Array<String>, sizesTitle: String) {
        self.parent = parent
        self.txtSize.text = product.size
        self.sizes = sizes
        
        self.lblTitle.text = sizesTitle
        
        if (self.sizes.count > 0) {
            self.sizePickerView.collectionView.reloadData()
            self.sizePickerView.selectItem(0, animated: false)
            
            var s = product.size
            if s != "" {
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
                        self.sizePickerView.selectItem(UInt(index), animated: false)
                        break
                    }
                    
                    index += 1
                }
            }
        }
    }
    
    // 120
    static func heightFor() -> CGFloat {
        return 104
    }
}

extension AddProduct3SizeCell: AKPickerViewDelegate, AKPickerViewDataSource {
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
        self.txtSize.text = s
        self.parent.product.size = s
    }
}

extension AddProduct3SizeCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.parent.product.isStartInput = true
        if textField == self.txtSize {
            self.parent.product.size = self.txtSize.text!
        }
        return true
    }
}

class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    // https://stackoverflow.com/questions/22539979/left-align-cells-in-uicollectionview
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            
            layoutAttribute.frame.origin.x = leftMargin
            
            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY , maxY)
        }
        
        return attributes
    }
}
