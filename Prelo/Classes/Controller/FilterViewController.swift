//
//  FilterViewController.swift
//  Prelo
//
//  Created by PreloBook on 8/8/16.
//  Copyright © 2016 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Protocol

protocol FilterDelegate {
    func adjustFilter(_ fltrProdCondIds : [String], fltrPriceMin : Int64, fltrPriceMax : Int64, fltrIsFreeOngkir : Bool, fltrSizes : [String], fltrSortBy : String, fltrLocation: [String], fltrProdKind: String)
}

// MARK: - Class

class FilterViewController : BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Struct
    
    struct CategorySize {
        var id : String = ""
        var name : String = ""
        var sizes : [String] = []
        var selecteds : [Bool] = []
        var values : [String] = []
        var hidden : Bool = true
        var nColumn : Int = 3
    }
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingPanel: UIView!
    @IBOutlet var consBottomVwButtons: NSLayoutConstraint!
    
    // Predefined values
    var categoryId = ""
    var initSelectedProdCondId : [String] = []
    var initSelectedCategSizeVal : [String] = []
    
    // Data container
    let SortByData : [String] = ["Populer", "Terkini", "Harga Terendah", "Harga Tertinggi"]
    let SortByDataValue : [String] = ["popular", "recent", "lowest_price", "highest_price"]
    
    
    let jenisListing : [String] = ["Jual", "Sewa"]
    var jenisListingChecked : [Bool] = [true, true]
    var selectedJenisListing : String = ""
    
    
    let CategSizeCellHeight : CGFloat = 28
    var selectedIdxSortBy : Int = 1
    var productConditions : [String] = []
    var selectedProductConditions : [Bool] = [false, false]
    var isFreeOngkir : Bool = false
    var categorySizes : [CategorySize] = []
    var minPrice : String = ""
    var maxPrice : String = ""
    var activeField : UITextField?
    var locationId : String = ""
    var locationName : String = "Semua Provinsi"
    var locationType : Int = 0
    var locationParentIDs : String = ""
    
    // Sections
    let SectionSortBy = 0
    let SectionJenis = 1
    let SectionKondisi = 2
    let SectionOngkir = 3
    let SectionUkuran = 4
    let SectionLokasi = 5
    let SectionHarga = 6
    
    // Custom cell ID
    let IdFilterChecklistCell = "FilterChecklistCell"
    let IdFilterSwitchCell = "FilterSwitchCell"
    let IdFilterCollectionCell = "FilterCollectionCell"
    let IdFilterPriceCell = "FilterPriceCell"
    let IdFilterLokasi = "FilterLocationCell"
    
    // Delegate
    var delegate : FilterDelegate? = nil
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        self.title = "Filter"
        
        // Init loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.showLoading()
        
        // Register custom cell
        let cell1 = UINib(nibName: IdFilterChecklistCell, bundle: nil)
        let cell2 = UINib(nibName: IdFilterSwitchCell, bundle: nil)
        let cell3 = UINib(nibName: IdFilterCollectionCell, bundle: nil)
        let cell5 = UINib(nibName: IdFilterPriceCell, bundle: nil)
        let cell4 = UINib(nibName: IdFilterLokasi, bundle: nil)
        tableView.register(cell1, forCellReuseIdentifier: IdFilterChecklistCell)
        tableView.register(cell2, forCellReuseIdentifier: IdFilterSwitchCell)
        tableView.register(cell3, forCellReuseIdentifier: IdFilterCollectionCell)
        tableView.register(cell4, forCellReuseIdentifier: IdFilterLokasi)
        tableView.register(cell5, forCellReuseIdentifier: IdFilterPriceCell)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboard(animations: { r, t, o in
            if (o) {
                self.consBottomVwButtons.constant = r.height
            } else {
                self.consBottomVwButtons.constant = 0
            }
        }, completion: nil)
        
        // Init product conditions
        self.productConditions = CDProductCondition.getProductConditionNames()
        if (productConditions.count > 0) {
            for i in 0...productConditions.count - 1 {
                if (initSelectedProdCondId.index(of: CDProductCondition.getProductConditionWithName(productConditions[i])!.id) != nil) {
                    selectedProductConditions.append(true)
                } else {
                    selectedProductConditions.append(false)
                }
            }
        }
        
        var tempCategorySize = false;
        
        // Get sizes
        let _ = request(APIReference.formattedSizesByCategory(category: self.categoryId)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Filter Ukuran")) {
                let json = JSON(resp.result.value!)
                if let data = json["_data"].array , data.count > 0 {
                    let collViewWidth = UIScreen.main.bounds.size.width - 16
                    for i in 0...data.count - 1 {
                        let id = data[i]["_id"].stringValue
                        let name = data[i]["name"].stringValue
                        var sizes : [String] = []
                        var selecteds : [Bool] = []
                        var values : [String] = []
                        var nColumn : Int = 3
                        if let fSizes = data[i]["formatted_sizes"].array , fSizes.count > 0 {
                            for j in 0...fSizes.count - 1 {
                                let sizeName = fSizes[j]["name"].stringValue
                                sizes.append(sizeName)
                                if (self.initSelectedCategSizeVal.index(of: fSizes[j]["value"].stringValue) != nil) {
                                    selecteds.append(true)
                                    tempCategorySize = true
                                } else {
                                    selecteds.append(false)
                                }
                                values.append(fSizes[j]["value"].stringValue)
                                
                                let cellWidth = sizeName.widthWithConstrainedHeight(self.CategSizeCellHeight, font: UIFont.systemFont(ofSize: 11)) + 34
                                let nColumnCell = (Int)(collViewWidth / cellWidth)
                                if (nColumnCell < nColumn) {
                                    nColumn = nColumnCell
                                }
                            }
                        }
                        self.categorySizes.append(CategorySize(id: id, name: name, sizes: sizes, selecteds: selecteds, values: values, hidden: true, nColumn: nColumn))
                    }
                }
            }
            
            // reload filter ukuran
            if tempCategorySize == true {
                self.uhideCategorySizes()
            }
            
            // Setup table
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0)
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.reloadData()
            self.hideLoading()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    // MARK: - Tableview functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == SectionOngkir) {
            return 1
        } else if (section == SectionUkuran && !isCategorySizesAvailable()) {
            return 0
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (section == SectionOngkir) {
            return UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1), backgroundColor: UIColor.lightGray)
        }
        
        let vwHeader = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40), backgroundColor: UIColor.white)
        
        var lblFrame = CGRect.zero
        lblFrame.origin.x = 8
        let lblHeader = UILabel(frame: lblFrame)
        lblHeader.font = UIFont.boldSystemFont(ofSize: 15.5)
        lblHeader.textColor = UIColor.darkGray
        if (section == SectionSortBy) {
            lblHeader.text = "Urutan"
        } else if (section == SectionKondisi) {
            lblHeader.text = "Kondisi"
        } else if (section == SectionUkuran) {
            lblHeader.text = "Ukuran"
        } else if (section == SectionHarga) {
            lblHeader.text = "Rentang Harga"
        } else if (section == SectionJenis) {
            lblHeader.text = "Jenis"
        } else if (section == SectionLokasi) {
            lblHeader.text = "Lokasi Penjual"
        }
        lblHeader.sizeToFit()
        lblHeader.y = (vwHeader.height - lblHeader.height) / 2
        vwHeader.addSubview(lblHeader)
        
        let separator = UIView(frame: CGRect(x: 0, y: 0, width: vwHeader.width, height: 1), backgroundColor: UIColor.lightGray)
        vwHeader.addSubview(separator)
        
        return vwHeader
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == SectionSortBy) {
            return 4
        } else if (section == SectionKondisi) {
            return productConditions.count
        } else if (section == SectionOngkir) {
            return 1
        } else if (section == SectionUkuran) {
            return categorySizes.count
        } else if (section == SectionJenis) {
            return 2
        } else if (section == SectionHarga) {
            return 2
        } else if (section == SectionLokasi) {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = (indexPath as NSIndexPath).section
        if (section == SectionSortBy) {
            return 36
        } else if (section == SectionKondisi) {
            return 36
        } else if (section == SectionJenis) {
            return 36
        } else if (section == SectionOngkir) {
            return 44
        } else if (section == SectionUkuran) {
            if ((indexPath as NSIndexPath).row < categorySizes.count) {
                if (categorySizes[(indexPath as NSIndexPath).row].hidden) {
                    return 37
                } else {
                    let elmtCount = categorySizes[(indexPath as NSIndexPath).row].sizes.count
                    let colCount = categorySizes[(indexPath as NSIndexPath).row].nColumn
                    let rowCount = (elmtCount / colCount) + (elmtCount % colCount > 0 ? 1 : 0)
                    return 45 + ((CGFloat)(rowCount) * self.CategSizeCellHeight)
                }
            }
        } else if (section == SectionHarga) {
            return 40
        } else if (section == SectionLokasi) {
//            if (locationName == "Semua Provinsi") {
//                return 40
//            } else if (locationType < 2) {
//                let multiplier = 1 + locationType
//                let result = 14 * multiplier
//                return (CGFloat)(result + 40)
//            } else {
//                let multiplier = locationType
//                let result = 14 * multiplier
//                return (CGFloat)(result + 40)
//            }
            return 40
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = (indexPath as NSIndexPath).section
        if (section == SectionSortBy) {
            let cell : FilterChecklistCell = self.tableView.dequeueReusableCell(withIdentifier: IdFilterChecklistCell) as! FilterChecklistCell
            cell.adapt(SortByData[(indexPath as NSIndexPath).row], isChecked: ((indexPath as NSIndexPath).row == selectedIdxSortBy))
            return cell
        } else if (section == SectionKondisi) {
            let cell : FilterChecklistCell = self.tableView.dequeueReusableCell(withIdentifier: IdFilterChecklistCell) as! FilterChecklistCell
            if ((indexPath as NSIndexPath).row < productConditions.count) {
                cell.adapt(productConditions[(indexPath as NSIndexPath).row], isChecked: selectedProductConditions[(indexPath as NSIndexPath).row])
            }
            return cell
        } else if (section == SectionJenis) {
            let cell : FilterChecklistCell = self.tableView.dequeueReusableCell(withIdentifier: IdFilterChecklistCell) as! FilterChecklistCell
            if ((indexPath as NSIndexPath).row < jenisListing.count) {
                cell.adapt(jenisListing[(indexPath as NSIndexPath).row], isChecked: jenisListingChecked[(indexPath as NSIndexPath).row])
            }
            return cell
        } else if (section == SectionOngkir) {
            let cell : FilterSwitchCell = self.tableView.dequeueReusableCell(withIdentifier: IdFilterSwitchCell) as! FilterSwitchCell
            cell.adapt("Free Ongkos Kirim", isOn: self.isFreeOngkir)
            cell.switched = {
                self.isFreeOngkir = !self.isFreeOngkir
            }
            return cell
        } else if (section == SectionUkuran) {
            let cell : FilterCollectionCell = self.tableView.dequeueReusableCell(withIdentifier: IdFilterCollectionCell) as! FilterCollectionCell
            if ((indexPath as NSIndexPath).row < categorySizes.count) {
                cell.adapt(categorySizes[(indexPath as NSIndexPath).row].name, sizes: categorySizes[(indexPath as NSIndexPath).row].sizes, selecteds: categorySizes[(indexPath as NSIndexPath).row].selecteds, hidden: categorySizes[(indexPath as NSIndexPath).row].hidden, nColumn: categorySizes[(indexPath as NSIndexPath).row].nColumn)
                cell.checkboxTapped = { idx in
                    self.categorySizes[(indexPath as NSIndexPath).row].selecteds[idx] = !self.categorySizes[(indexPath as NSIndexPath).row].selecteds[idx]
                    self.tableView.reloadData()
                }
                cell.headerTapped = {
                    self.categorySizes[(indexPath as NSIndexPath).row].hidden = !self.categorySizes[(indexPath as NSIndexPath).row].hidden
                    self.tableView.reloadData()
                }
            }
            return cell
        } else if (section == SectionHarga) {
            let cell : FilterPriceCell = self.tableView.dequeueReusableCell(withIdentifier: IdFilterPriceCell) as! FilterPriceCell
            if ((indexPath as NSIndexPath).row == 0) {
                cell.adapt("Harga Minimum", value: minPrice)
            } else if ((indexPath as NSIndexPath).row == 1) {
                cell.adapt("Harga Maksimum", value: maxPrice)
            }
            cell.fieldActivated = { fld in
                self.activeField = fld
            }
            cell.fieldEdited = { title, txt in
                var val = ""
                if (txt != nil) {
                    val = txt!
                }
                if (title == "Harga Minimum") {
                    self.minPrice = val
                } else if (title == "Harga Maksimum") {
                    self.maxPrice = val
                }
            }
            return cell
        } else if (section == SectionLokasi) {
            let cell : LocationCell = self.tableView.dequeueReusableCell(withIdentifier: IdFilterLokasi) as! LocationCell
            cell.adapt(locationName)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = (indexPath as NSIndexPath).section
        if (section == SectionSortBy) {
            selectedIdxSortBy = (indexPath as NSIndexPath).row
            tableView.reloadData()
        } else if (section == SectionKondisi) {
            selectedProductConditions[(indexPath as NSIndexPath).row] = !selectedProductConditions[(indexPath as NSIndexPath).row]
            tableView.reloadData()
        } else if (section == SectionJenis) {
            jenisListingChecked[(indexPath as NSIndexPath).row] = !jenisListingChecked[(indexPath as NSIndexPath).row]
            tableView.reloadData()
        } else if (section == SectionLokasi) {
            let filterlocation = Bundle.main.loadNibNamed(Tags.XibNameLocationFilter, owner: nil, options: nil)?.first as! LocationFilterViewController
            filterlocation.root = self
            filterlocation.blockDone = { data in
                //print(data)
                self.locationId = data[1]
//                self.locationName = data[0]
                self.locationType = data[2].int
                if (self.locationType == 2) {
                    self.locationName = data[3] + "  " + data[0]
//                    self.locationName = data[3] + data[0]
                }
                else if (self.locationType == 1) {
                    self.locationName = data[3]
//                    self.locationName = data[3] + "Semua Kecamatan"
                }
                else if (self.locationType == 0 && data[0] != "Semua Provinsi") {
                    self.locationName = data[3]
//                    self.locationName = data[3] + "Semua Kota / Kabupaten"
                }
                else {
                    self.locationName = data[0]
                }
                
                self.locationParentIDs = data[4]
            }
            self.navigationController?.pushViewController(filterlocation, animated: true)
        }
    }
    
    // MARK: - Textfield functions
    
    @IBAction func disableTextFields(_ sender : AnyObject) {
        self.activeField?.resignFirstResponder()
    }
    
    // MARK: - Actions
    
    @IBAction func resetPressed(_ sender: AnyObject) {
        selectedIdxSortBy = 1
        selectedProductConditions = []
        if (productConditions.count > 0) {
            for _ in 0...productConditions.count - 1 {
                selectedProductConditions.append(false)
            }
        }
        isFreeOngkir = false
        if (categorySizes.count > 0) {
            for i in 0...categorySizes.count - 1 {
                if (categorySizes[i].selecteds.count > 0) {
                    for j in 0...categorySizes[i].selecteds.count - 1 {
                        categorySizes[i].selecteds[j] = false
                    }
                }
                categorySizes[i].hidden = true
            }
        }
        minPrice = ""
        maxPrice = ""
        
        selectedJenisListing = "2"
        locationId = ""
        locationName = "Semua Provinsi"
        locationType = 0
        locationParentIDs = ""
        tableView.reloadData()
    }
    
    // digunakan untuk unhide filter ukuran bila ada salah satu atau lebih yang terpilih
    func uhideCategorySizes() {
        if (categorySizes.count > 0) {
            for i in 0...categorySizes.count - 1 {
                categorySizes[i].hidden = false
            }
        }
    }
    
    @IBAction func applyPressed(_ sender: AnyObject) {
        // Prepare product conditions param
        var fltrProdCondIds : [String] = []
        for i in 0...selectedProductConditions.count - 1 {
            if (selectedProductConditions[i] == true) {
                fltrProdCondIds.append(CDProductCondition.getProductConditionWithName(productConditions[i])!.id)
            }
        }
        
        //Prepare Jenis
        var fltrProdKind : String = ""
        if jenisListingChecked[0] && !jenisListingChecked[1] { // 0 & ~1
            fltrProdKind = "0"
        } else if !jenisListingChecked[0] && jenisListingChecked[1] { // ~0 $ 1
            fltrProdKind = "1"
        } else {
            fltrProdKind = "2"
        }
        
//        fltrProdKind = Int64(fltrProdKind)
        print (fltrProdKind)
        
        // Prepare category sizes param
        var fltrSizes : [String] = []
        if (categorySizes.count > 0) {
            for i in 0...categorySizes.count - 1 {
                for j in 0...categorySizes[i].sizes.count - 1 {
                    if (categorySizes[i].selecteds[j] == true) {
                        fltrSizes.append(categorySizes[i].values[j])
                    }
                }
            }
        }
        
        // Prepare price param
        var fltrPriceMin : Int64 = 0
        var fltrPriceMax : Int64 = 0
        if (self.minPrice != "") {
            fltrPriceMin = Int64(self.minPrice)!
        }
        if (self.maxPrice != "") {
            fltrPriceMax = Int64(self.maxPrice)!
        }
        
        if (self.previousController != nil) {
            delegate?.adjustFilter(fltrProdCondIds, fltrPriceMin: fltrPriceMin, fltrPriceMax: fltrPriceMax, fltrIsFreeOngkir: self.isFreeOngkir, fltrSizes: fltrSizes, fltrSortBy: self.SortByDataValue[self.selectedIdxSortBy], fltrLocation: [self.locationName, self.locationId, self.locationType.string, self.locationParentIDs], fltrProdKind: fltrProdKind)
            _ = self.navigationController?.popViewController(animated: true)
        } else {
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let l = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            l.currentMode = .filter
            l.fltrCategId = self.categoryId
            l.isBackToFltrSearch = true
            l.fltrProdKind = fltrProdKind
            l.fltrProdCondIds = fltrProdCondIds
            l.fltrPriceMin = fltrPriceMin
            l.fltrPriceMax = fltrPriceMax
            l.fltrIsFreeOngkir = self.isFreeOngkir
            l.fltrProdKind = fltrProdKind
            l.fltrSizes = fltrSizes
            l.fltrSortBy = self.SortByDataValue[self.selectedIdxSortBy]
            l.fltrLocation = [self.locationName, self.locationId, self.locationType.string, self.locationParentIDs]
            l.previousScreen = PageName.Search
            self.navigationController?.pushViewController(l, animated: true)
        }
    }
    
    func isCategorySizesAvailable() -> Bool {
        return (categorySizes.count > 0)
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        loadingPanel.isHidden = true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKind(of: UIButton.classForCoder()) || touch.view!.isKind(of: UITextField.classForCoder())) {
            return false
        } else {
            return true
        }
    }
}

// MARK: - Class

class FilterChecklistCell : UITableViewCell {
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblChecklist: UILabel!
    
    func adapt(_ title : String, isChecked : Bool) {
        self.lblTitle.text = title
        self.selectionStyle = .none
        if (isChecked) {
            self.lblChecklist.isHidden = false
            self.backgroundColor = UIColor(hexString: "#E8E8E8")
        } else {
            self.lblChecklist.isHidden = true
            self.backgroundColor = UIColor.white
        }
    }
}

// MARK: - Class

class FilterSwitchCell : UITableViewCell {
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var swtch: UISwitch!
    
    var switched : () -> () = {}
    
    func adapt(_ title : String, isOn : Bool) {
        self.lblTitle.text = title
        self.selectionStyle = .none
        self.swtch.setOn(isOn, animated: false)
    }
    
    @IBAction func switchPressed(_ sender: AnyObject) {
        self.switched()
    }
}


// MARK: - Class

class FilterCollectionCell : UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblArrow: UILabel!
    @IBOutlet var collectionVw: UICollectionView!
    
    let IdFilterCheckboxCell = "FilterCheckboxCell"
    
    var sizes : [String] = []
    var selecteds : [Bool] = []
    var nColumn : CGFloat = 3
    
    var checkboxTapped : (Int) -> () = { _ in }
    var headerTapped : () -> () = {}
    
    func adapt(_ title : String, sizes : [String], selecteds : [Bool], hidden : Bool, nColumn : Int) {
        self.lblTitle.text = title
        self.sizes = sizes
        self.selecteds = selecteds
        self.nColumn = CGFloat(nColumn)
        self.selectionStyle = .none
        
        if (hidden) {
            lblArrow.text = ""
        } else {
            lblArrow.text = ""
            let cellNib = UINib(nibName: IdFilterCheckboxCell, bundle: nil)
            self.collectionVw.register(cellNib, forCellWithReuseIdentifier: IdFilterCheckboxCell)
            self.collectionVw.delegate = self
            self.collectionVw.dataSource = self
            self.collectionVw.backgroundColor = UIColor.white
            self.collectionVw.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sizes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let viewWidth = UIScreen.main.bounds.size.width
        return CGSize(width: (viewWidth - 16) / self.nColumn, height: 28)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell : FilterCheckboxCell = collectionVw.dequeueReusableCell(withReuseIdentifier: IdFilterCheckboxCell, for: indexPath) as! FilterCheckboxCell
        if ((indexPath as NSIndexPath).item < sizes.count && (indexPath as NSIndexPath).item < selecteds.count) {
            cell.adapt(sizes[(indexPath as NSIndexPath).item], isChecked: selecteds[(indexPath as NSIndexPath).item])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.checkboxTapped((indexPath as NSIndexPath).item)
    }
    
    @IBAction func arrowPressed(_ sender: AnyObject) {
        self.headerTapped()
    }
}

// MARK: - Class

class FilterCheckboxCell : UICollectionViewCell {
    
    @IBOutlet var lblCheckbox: UILabel!
    @IBOutlet var lblTitle: UILabel!
    
    func adapt(_ title : String, isChecked : Bool) {
        self.lblTitle.text = title
        if (isChecked) {
            self.setChecked()
        } else {
            self.setUnchecked()
        }
    }
    
    func setChecked() {
        lblCheckbox.isHidden = false
    }
    
    func setUnchecked() {
        lblCheckbox.isHidden = true
    }
}

// MARK: - Class

class FilterPriceCell : UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var vwPricebox: UIView!
    @IBOutlet var fldPrice: UITextField!
    
    var fieldActivated : (UITextField) -> () = { _ in }
    var fieldEdited : (String, String?) -> () = { _, _ in }
    
    func adapt(_ title : String, value : String) {
        self.vwPricebox.createBordersWithColor(UIColor.lightGray, radius: 0, width: 1)
        self.selectionStyle = .none
        self.lblTitle.text = title
        self.fldPrice.text = value
        self.fldPrice.placeholder = nil
        self.fldPrice.delegate = self
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.fieldActivated(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.fieldEdited(lblTitle.text!, textField.text)
    }
}

class LocationCell : UITableViewCell
{
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var lblPicker: UILabel!
    
    func adapt(_ title : String) {
        
//        let mystr = title
//        let searchstr = ""
//        let ranges: [NSRange]
//        
//        do {
//            // Create the regular expression.
//            let regex = try NSRegularExpression(pattern: searchstr, options: [])
//            
//            // Use the regular expression to get an array of NSTextCheckingResult.
//            // Use map to extract the range from each result.
//            ranges = regex.matches(in: mystr, options: [], range: NSMakeRange(0, mystr.characters.count)).map {$0.range}
//        }
//        catch {
//            // There was a problem creating the regular expression
//            ranges = []
//        }
//        
//        if ranges.count > 0 {
//            let attrString = NSMutableAttributedString(string: title)
//            let small = UIFont (name: "prelo2", size: 7)
//            
//            for i in 0...ranges.count - 1 {
//                attrString.addAttribute(kCTFontAttributeName as String, value: small, range: NSMakeRange(ranges[i].location, 1))
//            
//            }
//        
//            self.lblText.attributedText = attrString
//        }
        
        self.lblText.text = title
    }
}
