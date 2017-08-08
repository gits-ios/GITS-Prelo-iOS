//
//  AddProductViewController3.swift
//  Prelo
//
//  Created by Djuned on 8/6/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

// MARK: - Struct
struct PreviewImage {
    var url = ""
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
    
    // Images Preview Cell
    var imagesIndex: Array<Int> = []
    var images: Array<UIImage> = []
    var imagesDetail: Array<PreviewImage> = []
    
    // Product Detail Cell
    var name = ""
    var category = ""
    var categoryId = ""
    var merk = ""
    var merkId = ""
    var condition = ""
    var cacat = ""
    var specialStory = ""
    var alasanJual = ""
    var description = ""
    
    // Auth Verification Cell
    var styleName = ""
    var serialNumber = ""
    var lokasiBeli = ""
    var tahunBeli = ""
    
    // Weigt Cell
    var weight = ""
    
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
    
    var product = SelectedProductItem()
    
    
}

// MARK: - Title Cell
class AddProduct3ImageTitleCell: UITableViewCell {
    @IBOutlet weak var SectionImage: TintedImageView!
    @IBOutlet weak var SectionTitle: UILabel!
    @IBOutlet weak var SectionFAQ: UIView! // ? , hide
    @IBOutlet weak var SectionSubtitle: UILabel! // ?
    
    // 40, 60 & count
    override func awakeFromNib() {
        self.SectionImage.tint = true
        self.SectionImage.tintColor = self.SectionTitle.textColor
        
        self.SectionSubtitle.text = ""
    }
    
    func adapt(_ image: String, title: String, subtitle: String?, isFaq: Bool) {
        self.SectionImage.image = UIImage(named: image)!
        self.SectionTitle.text = title
        self.SectionSubtitle.text = subtitle
        
        self.SectionFAQ.isHidden = !isFaq
    }
    
    static func heightFor(_ subtitle: String?) -> CGFloat {
        if let sub = subtitle {
            let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
            return 40 + t.height // count subtitle height
        }
        return 40
    }
}

// MARK: - Images Preview Cell
class AddProduct3ImagesPreviewCell: UITableViewCell {
    @IBOutlet weak var collectionView: UICollectionView!
    
    // TODO: - ADAPT, DELEGATE
    
    // 158 , (42) count teks height
    static func heightFor() -> CGFloat {
        let sub = "Foto yang sebaiknya kamu upload adalah tampak depan, foto label/merek, tampak belakang, dan cacat (jika ada). Lihat tips barang Editor's Pick."
        let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
        return 116 + t.height // count subtitle height
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
    static func sizeFor() -> CGSize {
        return CGSize(width: 82, height: 82)
    }
}

class AddProduct3ImagesPreviewCellNewOneCell: UICollectionViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.init(hexString: "#EDEDED")
    }
    
    // 82 x 82
    static func sizeFor() -> CGSize {
        return CGSize(width: 82, height: 82)
    }
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
    
    
    // 356 -> -40 // count description height
    // 266.5 + 40 + 49.5++
    
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
    
    var reloadThisRow: ()->() = {}
    var disactiveColor = UIColor.init(hexString: "#727272")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.img1kg.tint = true
        self.img12kg.tint = true
        self.img2kg.tint = true
        
        self.img1kg.tintColor = disactiveColor
        self.img12kg.tintColor = disactiveColor
        self.img2kg.tintColor = disactiveColor
        
        self.vwBerat.isHidden = true
    }
    
    func adapt(_ weight: String) {
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
    
    var disactiveColor = UIColor.init(hexString: "#727272")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imgFreeOngkir.tint = true
        self.imgPaidOngkir.tint = true
        
        self.imgFreeOngkir.tintColor = disactiveColor
        self.imgPaidOngkir.tintColor = disactiveColor
    }
    
    // TODO: - ADAPT
    
    // 206, count teks height
    static func heightFor() -> CGFloat {
        let sub = "Barang yang biasanya butuh asuransi kurir: handphone, laptop, dll. Ongkos kirim barang jualan kamu akan sesuai dengan kurir yang tersimpan di sistem. Lihat Syarat dan Ketentuan."
        let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: AppTools.screenWidth - 24)
        return 164 + t.height // count subtitle height
    }
}

// MARK: - Product Auth Verification Cell (Luxury)
class AddProduct3ProductAuthVerificationCell: UITableViewCell {
    @IBOutlet weak var txtStyleName: UITextField!
    @IBOutlet weak var txtSerialNumber: UITextField!
    @IBOutlet weak var txtLokasiBeli: UITextField!
    @IBOutlet weak var txtTahunBeli: UITextField!
    
    // 172
}

// MARK: - Images Checklist Cell
class AddProduct3ImagesChecklistCell: UITableViewCell {
    @IBOutlet weak var collectionView: UICollectionView!
    
    // TODO: - ADAPT
    
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
    static func sizeFor() -> CGSize {
        return CGSize(width: 120, height: 20)
    }
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
    
    // TODO: - ADAPT
    
    // 258 (all), sell: 88, rent: 218
    
    static func heightFor(_ isSell: Bool, isRent: Bool) -> CGFloat {
        if isSell && isRent {
            return 258
        } else if isSell {
            return 88
        }
        return 218
    }
}

// MARK: - Charge Cell
class AddProduct3ChargeCell: UITableViewCell {
    @IBOutlet weak var lblComissions: UILabel!
    @IBOutlet weak var btnSubmit: UIButton! // -> Loading
    @IBOutlet weak var btnRemove: BorderedButton! // hide
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.btnRemove.isHidden = true
    }
    
    func adapt(_ commisions: String, isEdit: Bool) {
        if isEdit {
            self.btnRemove.isHidden = false
        }
        
        self.lblComissions.text = commisions
    }
    
    // 162, count teks, hide unhide button hapus
    static func heightFor(_ isEdit: Bool) -> CGFloat {
        let sub = "Klik LANJUTKAN untukmenentukan Charge Prelo yang kamu mau"
        let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 10), width: AppTools.screenWidth - 24)
        return 104 + (isEdit ? 48.0 : 0) + t.height // count subtitle height
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
    
    var disactiveColor = UIColor.init(hexString: "#727272")
    
    func adapt(_ type: String) {
        if type == "hari" {
            self.vwPerHari.borderColor = Theme.PrimaryColor
            self.lblPerHari.textColor = Theme.PrimaryColor
            
            self.vwPerMinggu.borderColor = disactiveColor
            self.lblPerMinggu.textColor = disactiveColor
            
            self.vwPerBulan.borderColor = disactiveColor
            self.lblPerBulan.textColor = disactiveColor
        } else if type == "minggu" {
            self.vwPerHari.borderColor = disactiveColor
            self.lblPerHari.textColor = disactiveColor
            
            self.vwPerMinggu.borderColor = Theme.PrimaryColor
            self.lblPerMinggu.textColor = Theme.PrimaryColor
            
            self.vwPerBulan.borderColor = disactiveColor
            self.lblPerBulan.textColor = disactiveColor
        } else if type == "bulan" {
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
}

// MARK: - Sell Rent Switch Cell
class AddProduct3SellRentSwitchCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet weak var btnSwitch: UISwitch!
    
    func adapt(_ title: String, subtitle: String, isOn: Bool) {
        self.lblTitle.text = title
        self.lblSubTitle.text = subtitle
        self.btnSwitch.isOn = isOn
    }
    
    // 99 , (32) count teks
    static func heightFor(_ sub: String, isOn: Bool) -> CGFloat {
        if isOn {
            let t = sub.boundsWithFontSize(UIFont.systemFont(ofSize: 10), width: AppTools.screenWidth - 24)
            return 67 + t.height // count subtitle height
        }
        return 56
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
    }
    
    // 72
    static func heightFor() -> CGFloat {
        return 72
    }
}
