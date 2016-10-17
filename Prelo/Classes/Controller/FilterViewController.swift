//
//  FilterViewController.swift
//  Prelo
//
//  Created by PreloBook on 8/8/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation

// MARK: - Protocol

protocol FilterDelegate {
    func adjustFilter(_ fltrProdCondIds : [String], fltrPriceMin : NSNumber, fltrPriceMax : NSNumber, fltrIsFreeOngkir : Bool, fltrSizes : [String], fltrSortBy : String)
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
    let CategSizeCellHeight : CGFloat = 28
    var selectedIdxSortBy : Int = 1
    var productConditions : [String] = []
    var selectedProductConditions : [Bool] = []
    var isFreeOngkir : Bool = false
    var categorySizes : [CategorySize] = []
    var minPrice : String = ""
    var maxPrice : String = ""
    var activeField : UITextField?
    
    // Sections
    let SectionSortBy = 0
    let SectionKondisi = 1
    let SectionOngkir = 2
    let SectionUkuran = 3
    let SectionHarga = 4
    
    // Custom cell ID
    let IdFilterChecklistCell = "FilterChecklistCell"
    let IdFilterSwitchCell = "FilterSwitchCell"
    let IdFilterCollectionCell = "FilterCollectionCell"
    let IdFilterPriceCell = "FilterPriceCell"
    
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
        let cell4 = UINib(nibName: IdFilterPriceCell, bundle: nil)
        tableView.register(cell1, forCellReuseIdentifier: IdFilterChecklistCell)
        tableView.register(cell2, forCellReuseIdentifier: IdFilterSwitchCell)
        tableView.register(cell3, forCellReuseIdentifier: IdFilterCollectionCell)
        tableView.register(cell4, forCellReuseIdentifier: IdFilterPriceCell)
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
        
        // Get sizes
        let _ = request(APIReference.formattedSizesByCategory(category: self.categoryId)).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Filter Ukuran")) {
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
        return 5
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
            lblHeader.text = "Sort By"
        } else if (section == SectionKondisi) {
            lblHeader.text = "Kondisi"
        } else if (section == SectionUkuran) {
            lblHeader.text = "Ukuran"
        } else if (section == SectionHarga) {
            lblHeader.text = "Rentang Harga"
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
        } else if (section == SectionHarga) {
            return 2
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = (indexPath as NSIndexPath).section
        if (section == SectionSortBy) {
            return 36
        } else if (section == SectionKondisi) {
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
        tableView.reloadData()
    }
    
    @IBAction func applyPressed(_ sender: AnyObject) {
        // Prepare product conditions param
        var fltrProdCondIds : [String] = []
        for i in 0...selectedProductConditions.count - 1 {
            if (selectedProductConditions[i] == true) {
                fltrProdCondIds.append(CDProductCondition.getProductConditionWithName(productConditions[i])!.id)
            }
        }
        
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
        var fltrPriceMin : NSNumber = 0
        var fltrPriceMax : NSNumber = 0
        if (self.minPrice != "") {
            fltrPriceMin = NSNumber(value: Int(self.minPrice)! as Int)
        }
        if (self.maxPrice != "") {
            fltrPriceMax = NSNumber(value: Int(self.maxPrice)! as Int)
        }
        
        if (self.previousController != nil) {
            delegate?.adjustFilter(fltrProdCondIds, fltrPriceMin: fltrPriceMin, fltrPriceMax: fltrPriceMax, fltrIsFreeOngkir: self.isFreeOngkir, fltrSizes: fltrSizes, fltrSortBy: self.SortByDataValue[self.selectedIdxSortBy])
            self.navigationController?.popViewController(animated: true)
        } else {
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let l = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            l.currentMode = .filter
            l.fltrCategId = self.categoryId
            l.isBackToFltrSearch = true
            l.fltrProdCondIds = fltrProdCondIds
            l.fltrPriceMin = fltrPriceMin
            l.fltrPriceMax = fltrPriceMax
            l.fltrIsFreeOngkir = self.isFreeOngkir
            l.fltrSizes = fltrSizes
            l.fltrSortBy = self.SortByDataValue[self.selectedIdxSortBy]
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
