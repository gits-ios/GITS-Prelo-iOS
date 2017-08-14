//
//  AddProductViewController3.swift
//  Prelo
//
//  Created by Djuned on 8/6/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class AddProduct3Helper {
    // Charge label
    static let defaultChargeLabel = "Klik LANJUTKAN untuk menentukan Charge Prelo yang kamu mau"
    
    // Subtitle
    static let rentOngkirSubtitle = "Diwajibkan menggunakan kurir sehari sampai (seperti JNE YES, TIKI ONS)"
    static let rentOngkirSubtitleBoldStr = "JNE YES, TIKI ONS"
    static let rentPeriodSubtitle = "Tentutkan satuan Periode Sewa yang diinginkan"
    
    // swicth
    // rent page
    static let rentSwitchTitleJual = "Barang ini juga boleh dijual"
    static let rentSwitchSubtitleJual = "Untuk barang yang dijual, ongkos kirim bisa Ditanggung Penjual atau Pembeli"
    static let rentSwitchSubtitleJualBoldStr = "Ditanggung Penjual atau Pembeli"
    
    // sell page
    static let rentSwitchTitleSewa = "Barang ini juga dapat disewa"
    static let rentSwitchSubtitleSewa = "Untuk Sewa, ongkos kirim akan selalu Ditanggung Penyewa / Buyer"
    static let rentSwitchSubtitleSewaBoldStr = "Ditanggung Penyewa / Buyer"
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
    
    // TODO: - icon
    var icon: String {
        switch(self) {
        case .imagesPreview    : return ""
        case .productDetail    : return "placeholder-standar-white"
        case .size             : return "placeholder-standar-white"
        case .authVerification : return "placeholder-standar-white"
        case .checklist        : return "placeholder-standar-white"
        case .weight           : return "placeholder-standar-white"
        case .postalFee        : return "placeholder-standar-white"
        case .rentPeriod       : return "placeholder-standar-white"
        case .rentSellOnOff    : return "placeholder-standar-white"
        case .price            : return "placeholder-standar-white"
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
        default                : return nil
        }
    }
}

// MARK: - Struct
struct PreviewImage {
    var image: UIImage! // local image / downloaded image
    var url = "" // downloaded image url
    var label = ""
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
    var addProductType = 0 // 0 sell, 1 rent
    var isLuxuryMerk = false
    var isWomenMenCategory = false
    var isCategoryContainSize = false
    
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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    // data
    var product = SelectedProductItem()
    var chargeLabel: String? = AddProduct3Helper.defaultChargeLabel
    
    var sizes: Array<String> = []
    var isOpenAll = false
    
    // view
    var listSections: Array<AddProduct3SectionType> = []
    
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
        
        self.setupTableView()
        
        self.title = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // setup product from edit or draft
        if self.product.isEditMode {
            self.chargeLabel = nil
            self.setupEditMode()
        } else if self.product.isDraftMode {
            self.chargeLabel = nil
            self.setupDraftMode()
        } else { // default init
            if self.product.addProductType == 0 {
                self.product.isSell = true
                self.product.isRent = false
            } else {
                self.product.isSell = false
                self.product.isRent = true
            }
        }
        
        // setup table view
        if self.product.addProductType == 0 {
            
            self.listSections.append(.imagesPreview)
            self.listSections.append(.productDetail)
            self.listSections.append(.weight)
            self.listSections.append(.postalFee)
            self.listSections.append(.rentSellOnOff)
            self.listSections.append(.price)
            
            if self.isOpenAll {
                
            }
        } else {
            
            if self.isOpenAll {
                
            }
        }
        
        self.tableView.reloadData()
        self.hideLoading()
    }
    
    func setupEditMode() {
        // TODO: - setupEditMode
    }
    
    func setupDraftMode() {
        // TODO: - setupDraftMode
    }
    
    // MARK: - Other
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
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
}

extension AddProductViewController3: UITableViewDelegate, UITableViewDataSource {
    // TODO: - tableview action
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
                return AddProduct3ImagesChecklistCell.heightFor(self.product.imagesDetail.count)
            }
        case .weight:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor(listSections[section].subtitle)
            } else {
                return AddProduct3WeightCell.heightFor(self.product.weight)
            }
        case .postalFee:
            if row == 0 {
                return AddProduct3ImageTitleCell.heightFor(listSections[section].subtitle)
            } else {
                if self.product.isSell {
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
                return AddProduct3SellRentSwitchCell.heightFor(nil, isOn: self.product.isSell && self.product.isRent)
            } else {
                if self.product.isSell {
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
            cell.adapt(self.product)
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
                    
                    cell.txtDescription.becomeFirstResponder()
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
                cell.adapt(self, product: self.product, sizes: self.sizes)
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
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImagesChecklistCell") as! AddProduct3ImagesChecklistCell
                cell.adapt(self.product)
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
                
                return cell
            }
        case .postalFee:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: listSections[section].title, subtitle: (self.product.isSell ? listSections[section].subtitle : AddProduct3Helper.rentOngkirSubtitle), faqUrl: listSections[section].faq)
                return cell
            } else {
                if self.product.isSell {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3PostalFeeCell") as! AddProduct3PostalFeeCell
                    cell.adapt(self, product: self.product)
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
                
                cell.reloadSections = { sections in
                    var array: Array<Int> = []
                    for i in sections {
                        array.append(self.findSectionFromType(i))
                    }
                    
                    let indexSet = NSMutableIndexSet()
                    array.forEach(indexSet.add)
                    
                    self.tableView.reloadSections(indexSet as IndexSet, with: .fade)
                }
                
                return cell
            }
        case .rentSellOnOff:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ImageTitleCell") as! AddProduct3ImageTitleCell
                cell.adapt(listSections[section].icon, title: (self.product.isSell ? listSections[section].title : "JUAL"), subtitle: listSections[section].subtitle, faqUrl: listSections[section].faq)
                return cell
            } else if row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3SellRentSwitchCell") as! AddProduct3SellRentSwitchCell
                cell.adapt((self.product.isSell ? AddProduct3Helper.rentSwitchTitleSewa : AddProduct3Helper.rentSwitchTitleJual), subtitle: (self.product.isSell ? AddProduct3Helper.rentSwitchSubtitleSewa + "\n" + AddProduct3Helper.rentOngkirSubtitle + "\n\n" + AddProduct3Helper.rentPeriodSubtitle : AddProduct3Helper.rentSwitchSubtitleJual), isOn: (self.product.isRent && self.product.isSell))
                
                cell.reloadSections = { sections in
                    // hack
                    if self.product.addProductType == 0 {
                        self.product.isRent = !self.product.isRent
                    } else {
                        self.product.isSell = !self.product.isSell
                    }
                    
                    var array: Array<Int> = []
                    for i in sections {
                        array.append(self.findSectionFromType(i))
                    }
                    
                    let indexSet = NSMutableIndexSet()
                    array.forEach(indexSet.add)
                    
                    self.tableView.reloadSections(indexSet as IndexSet, with: .fade)
                }
                
                return cell
            } else {
                if self.product.isSell {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3RentPeriodCell") as! AddProduct3RentPeriodCell
                    cell.adapt(self, product: self.product)
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3PostalFeeCell") as! AddProduct3PostalFeeCell
                    cell.adapt(self, product: self.product)
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
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ChargeCell") as! AddProduct3ChargeCell
                cell.adapt(self.product, subtitle: self.chargeLabel)
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // do nothing
        // TODO: - next
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
        self.SectionImage.tint = true
        self.SectionImage.tintColor = self.SectionTitle.textColor
        
        self.SectionSubtitle.text = ""
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ image: String, title: String, subtitle: String?, faqUrl: String?) {
        self.SectionImage.image = UIImage(named: image)!
        self.SectionTitle.text = title
        self.SectionSubtitle.text = subtitle
        
        self.SectionFAQ.isHidden = (faqUrl == nil)
    }
    
    static func heightFor(_ subtitle: String?) -> CGFloat {
        if let sub = subtitle {
            let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // TODO: - Lihat tips barang Editor's Pick.
        self.url = ""
        
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
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        layout.itemSize = CGSize(width: 82, height: 82)
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        self.collectionView.collectionViewLayout = layout
    }
    
    func adapt(_ product: SelectedProductItem) {
        self.images = product.imagesDetail
        self.index = product.imagesIndex
    }
    
    // 158 , (42) count teks height
    static func heightFor() -> CGFloat {
        let sub = "Foto yang sebaiknya kamu upload adalah tampak depan, foto label/merek, tampak belakang, dan cacat (jika ada). Lihat tips barang Editor's Pick."
        let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
        return 116 + t.height // count subtitle height
    }
    
    @IBAction func btnFAQPressed(_ sender: Any) {
        self.openWebView(self.url)
    }
}

extension AddProduct3ImagesPreviewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row < self.images.count {
            // Create cell
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "AddProduct3ImagesPreviewCellCollectionCell", for: indexPath) as! AddProduct3ImagesPreviewCellCollectionCell
            cell.adapt(self.images[self.index[indexPath.row]].image, label: self.images[indexPath.row].label)
            
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
    }
}

class AddProduct3ImagesPreviewCellCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imagesPreview: UIImageView!
    @IBOutlet weak var labelView: UIView! // backgrund
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.init(hexString: "#EDEDED")
        self.labelView.backgroundColor = UIColor.init(hexString: "#B4B4B4").alpha(0.75)
    }
    
    func adapt(_ image: UIImage?, label: String) {
        self.imagesPreview.image = image
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
        } else {
            self.consTopSpecialStory.constant = 0
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
        // TODO: pick Category
    }
    
    @IBAction func btnPickMerkPressed(_ sender: Any) {
        // TODO: pick Merk
    }
    
    @IBAction func btnPickConditionPressed(_ sender: Any) {
        // TODO: pick Condition
    }
}

extension AddProduct3DetailProductCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
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
        self.reloadThisRow()
    }
    
    func adapt(_ parent: AddProductViewController3, weight: String) {
        self.parent = parent
        
        if weight != "" {
            self.txtWeight.text = weight
            if self.vwBerat.isHidden {
                self.vwBerat.isHidden = false
                self.reloadThisRow()
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
        if (self.txtWeight.text?.int)! >= 1000 {
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
            self.reloadThisRow()
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
            self.reloadThisRow()
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
            self.reloadThisRow()
        }
    }
}

// MARK: - Postal Fee Cell (Sell)
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
        
        // TODO: - Lihat Syarat dan Ketentuan.
        self.url = ""
        
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
        self.btnSwitch.isOn = (product.isInsurance == "1")
        
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
        
        if product.freeOngkirRegions.count > 0 {
            var region = ""
            for i in product.freeOngkirRegions {
                region += i.name + ", "
            }
            self.lblRegion.text = region.trimmingCharacters(in: CharacterSet.init(charactersIn: ", "))
        }
    }
    
    // 206, count teks height
    static func heightFor() -> CGFloat {
        let sub = "Barang yang biasanya butuh asuransi kurir: handphone, laptop, dll. Ongkos kirim barang jualan kamu akan sesuai dengan kurir yang tersimpan di sistem. Lihat Syarat dan Ketentuan."
        let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
        return 164 + t.height // count subtitle height
    }
    
    @IBAction func btnFAQPressed(_ sender: Any) {
        self.openWebView(self.url)
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
    
    var images: Array<PreviewImage> = []
    var index: Array<Int> = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
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
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        layout.itemSize = CGSize(width: 120, height: 20)
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        self.collectionView.collectionViewLayout = layout
    }
    
    func adapt(_ product: SelectedProductItem) {
        self.images = product.imagesDetail
        self.index = product.imagesIndex
    }
    
    // 66, count height collection view (20 x total/y), count teks height
    static func heightFor(_ count: Int) -> CGFloat {
        let w = AppTools.screenWidth - 24 - 8
        var c: CGFloat = 120
        var i = 0
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
        let h = 20.0 * ceil(Double(count) / Double(i))
        return 46 + CGFloat(h) // count subtitle height
    }
}

extension AddProduct3ImagesChecklistCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Create cell
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "AddProduct3ImagesChecklistCellCollectionCell", for: indexPath) as! AddProduct3ImagesChecklistCellCollectionCell
        cell.adapt(self.images[self.index[indexPath.row]].label, isExist: self.images[indexPath.row].image != nil)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120, height: 20)
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
        
        self.lblCheck.textColor = UIColor.init(hexString: "#727272")
    }
    
    override func prepareForReuse() {
        self.lblCheck.textColor = UIColor.init(hexString: "#727272")
    }
    
    func adapt(_ name: String, isExist: Bool) {
        self.lblName.text = name
        
        if isExist {
            self.lblCheck.textColor = Theme.ThemeOrange
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
        
        // TODO: - Lihat Syarat dan Ketentuan.
        self.url = ""
        
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.btnRemove.isHidden = true
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ product: SelectedProductItem, subtitle: String?) {
        if product.isEditMode || product.isDraftMode {
            self.btnRemove.isHidden = false
        }
        
        self.lblComissions.text = product.commision
        
        var h: CGFloat = 8
        if let sub = subtitle {
            let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 10), width: AppTools.screenWidth - 24)
            h += t.height + 8
            
            self.lblCharge.text = sub // AddProduct3 VC:chargeLabel
        }
        
        self.consTopBtnSubmit.constant = h
    }
    
    // 162, count teks, hide unhide button hapus
    static func heightFor(_ subtitle: String?, isEditDraftMode: Bool) -> CGFloat {
        var h: CGFloat = -8
        if let sub = subtitle {
            let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 10), width: AppTools.screenWidth - 24)
            h = t.height
        }
        return 104 + (isEditDraftMode ? 48.0 : 0) + h // count subtitle height
    }
    
    @IBAction func btnSubmitPressed(_ sender: Any) {
        // TODO: - btnSubmitPressed
    }
    
    @IBAction func btnRemovePressed(_ sender: Any) {
        // TODO: - btnRemovePressed
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
            self.reloadSections([ .price ])
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
            self.reloadSections([ .price ])
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
            self.reloadSections([ .price ])
        }
    }
}

// MARK: - Sell Rent Switch Cell
class AddProduct3SellRentSwitchCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var btnSwitch: UISwitch!
    
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
        self.lblSubTitle.text = subtitle
        self.btnSwitch.isOn = isOn
    }
    
    // 99 , (32) count teks
    static func heightFor(_ substring: String?, isOn: Bool) -> CGFloat {
        if isOn {
            var h: CGFloat = 0
            if let sub = substring {
                let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 10), width: AppTools.screenWidth - 24)
                h = t.height
            }
            return 67 + h // count subtitle height
        }
        return 56
    }
    
    @IBAction func btnSwitchPressed(_ sender: Any) {
        self.reloadSections([ .rentSellOnOff, .price ])
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
    
    @IBOutlet weak var txtSize: UITextField!
    
    var parent: AddProductViewController3!
    var sizes: Array<String> = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.txtSize.delegate = self
        
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
    
    func adapt(_ parent: AddProductViewController3, product: SelectedProductItem, sizes: Array<String>) {
        self.txtSize.text = product.size
        self.sizes = sizes
        
        if (self.sizes.count > 0) {
            self.sizePickerView.collectionView.reloadData()
            self.sizePickerView.selectItem(0, animated: false)
            self.sizePickerView.superview?.isHidden = false
            
            var s = ""
            if product.isEditMode || product.isDraftMode {
                s = product.size
            }
            if s != "" && (product.isEditMode || product.isDraftMode)
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
        return 120
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
        if textField == self.txtSize {
            self.parent.product.size = self.txtSize.text!
        }
        return true
    }
}
