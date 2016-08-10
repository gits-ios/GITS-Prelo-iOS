//
//  FilterViewController.swift
//  Prelo
//
//  Created by PreloBook on 8/8/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class

class FilterViewController : BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Struct
    
    struct CategorySize {
        var name : String = ""
        var sizes : [String] = []
        var selecteds : [Bool] = []
        var hidden : Bool = true
    }
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingPanel: UIView!
    @IBOutlet var consBottomVwButtons: NSLayoutConstraint!
    
    // Variable from previous page
    var categoryId = ""
    
    // Data container
    let SortByData : [String] = ["Popular", "Recent", "Lowest Price", "Highest Price"]
    var selectedIdxSortBy : Int = 0
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
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        self.title = "Filter"
        
        // Init loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        self.showLoading()
        
        // Register custom cell
        let cell1 = UINib(nibName: IdFilterChecklistCell, bundle: nil)
        let cell2 = UINib(nibName: IdFilterSwitchCell, bundle: nil)
        let cell3 = UINib(nibName: IdFilterCollectionCell, bundle: nil)
        let cell4 = UINib(nibName: IdFilterPriceCell, bundle: nil)
        tableView.registerNib(cell1, forCellReuseIdentifier: IdFilterChecklistCell)
        tableView.registerNib(cell2, forCellReuseIdentifier: IdFilterSwitchCell)
        tableView.registerNib(cell3, forCellReuseIdentifier: IdFilterCollectionCell)
        tableView.registerNib(cell4, forCellReuseIdentifier: IdFilterPriceCell)
        
        // Init product conditions
        self.productConditions = CDProductCondition.getProductConditionNames()
        if (productConditions.count > 0) {
            for _ in 0...productConditions.count - 1 {
                selectedProductConditions.append(false)
            }
        }
        
        // Init category sizes
        categorySizes.append(CategorySize(name: "Sepatu & Sandal Wanita", sizes: ["abc", "def", "ghi", "klm", "nop"], selecteds: [false, false, false, false, false], hidden: true))
        categorySizes.append(CategorySize(name: "Atasan & Terusan Wanita", sizes: ["qrs", "tuv", "wxy", "zab", "cde", "fgh"], selecteds: [false, false, false, false, false, false], hidden: true))
        categorySizes.append(CategorySize(name: "Bawahan Wanita", sizes: ["ijk", "lmn", "opq", "rst", "uvw", "xyz", "abc"], selecteds: [false, false, false, false, false, false, false], hidden: true))
        
        // Setup table
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
        self.hideLoading()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboardWithAnimations({ r, t, o in
            if (o) {
                self.consBottomVwButtons.constant = r.height
            } else {
                self.consBottomVwButtons.constant = 0
            }
        }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    // MARK: - Tableview functions
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == SectionOngkir) {
            return 1
        } else if (section == SectionUkuran && !isCategorySizesAvailable()) {
            return 0
        }
        return 40
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (section == SectionOngkir) {
            return UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 1), backgroundColor: UIColor.lightGrayColor())
        }
        
        let vwHeader = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 40), backgroundColor: UIColor.whiteColor())
        
        var lblFrame = CGRectZero
        lblFrame.origin.x = 8
        let lblHeader = UILabel(frame: lblFrame)
        lblHeader.font = UIFont.boldSystemFontOfSize(15.5)
        lblHeader.textColor = UIColor.darkGrayColor()
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
        
        let separator = UIView(frame: CGRectMake(0, 0, vwHeader.width, 1), backgroundColor: UIColor.lightGrayColor())
        vwHeader.addSubview(separator)
        
        return vwHeader
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let section = indexPath.section
        if (section == SectionSortBy) {
            return 36
        } else if (section == SectionKondisi) {
            return 36
        } else if (section == SectionOngkir) {
            return 44
        } else if (section == SectionUkuran) {
            if (indexPath.row < categorySizes.count) {
                if (categorySizes[indexPath.row].hidden) {
                    return 37
                } else {
                    let rows = categorySizes[indexPath.row].sizes.count
                    return 45 + (CGFloat)(((rows + 1) / 2) * 28)
                }
            }
        } else if (section == SectionHarga) {
            return 40
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = indexPath.section
        if (section == SectionSortBy) {
            let cell : FilterChecklistCell = self.tableView.dequeueReusableCellWithIdentifier(IdFilterChecklistCell) as! FilterChecklistCell
            cell.adapt(SortByData[indexPath.row], isChecked: (indexPath.row == selectedIdxSortBy))
            return cell
        } else if (section == SectionKondisi) {
            let cell : FilterChecklistCell = self.tableView.dequeueReusableCellWithIdentifier(IdFilterChecklistCell) as! FilterChecklistCell
            if (indexPath.row < productConditions.count) {
                cell.adapt(productConditions[indexPath.row], isChecked: selectedProductConditions[indexPath.row])
            }
            return cell
        } else if (section == SectionOngkir) {
            let cell : FilterSwitchCell = self.tableView.dequeueReusableCellWithIdentifier(IdFilterSwitchCell) as! FilterSwitchCell
            cell.adapt("Free Ongkos Kirim", isOn: self.isFreeOngkir)
            cell.switched = {
                self.isFreeOngkir = !self.isFreeOngkir
            }
            return cell
        } else if (section == SectionUkuran) {
            let cell : FilterCollectionCell = self.tableView.dequeueReusableCellWithIdentifier(IdFilterCollectionCell) as! FilterCollectionCell
            if (indexPath.row < categorySizes.count) {
                cell.adapt(categorySizes[indexPath.row].name, sizes: categorySizes[indexPath.row].sizes, selecteds: categorySizes[indexPath.row].selecteds, hidden: categorySizes[indexPath.row].hidden)
                cell.checkboxTapped = { idx in
                    self.categorySizes[indexPath.row].selecteds[idx] = !self.categorySizes[indexPath.row].selecteds[idx]
                    self.tableView.reloadData()
                }
                cell.headerTapped = {
                    self.categorySizes[indexPath.row].hidden = !self.categorySizes[indexPath.row].hidden
                    self.tableView.reloadData()
                }
            }
            return cell
        } else if (section == SectionHarga) {
            let cell : FilterPriceCell = self.tableView.dequeueReusableCellWithIdentifier(IdFilterPriceCell) as! FilterPriceCell
            if (indexPath.row == 0) {
                cell.adapt("Harga Minimum", value: minPrice)
            } else if (indexPath.row == 1) {
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = indexPath.section
        if (section == SectionSortBy) {
            selectedIdxSortBy = indexPath.row
            tableView.reloadData()
        } else if (section == SectionKondisi) {
            selectedProductConditions[indexPath.row] = !selectedProductConditions[indexPath.row]
            tableView.reloadData()
        }
    }
    
    // MARK: - Textfield functions
    
    @IBAction func disableTextFields(sender : AnyObject) {
        self.activeField?.resignFirstResponder()
    }
    
    // MARK: - Actions
    
    @IBAction func resetPressed(sender: AnyObject) {
        selectedIdxSortBy = 0
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
    
    @IBAction func applyPressed(sender: AnyObject) {
        
    }
    
    func isCategorySizesAvailable() -> Bool {
        return (categorySizes.count > 0)
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        loadingPanel.hidden = false
    }
    
    func hideLoading() {
        loadingPanel.hidden = true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKindOfClass(UIButton.classForCoder()) || touch.view!.isKindOfClass(UITextField.classForCoder())) {
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
    
    func adapt(title : String, isChecked : Bool) {
        self.lblTitle.text = title
        self.selectionStyle = .None
        if (isChecked) {
            self.lblChecklist.hidden = false
            self.backgroundColor = UIColor(hexString: "#E8E8E8")
        } else {
            self.lblChecklist.hidden = true
            self.backgroundColor = UIColor.whiteColor()
        }
    }
}

// MARK: - Class

class FilterSwitchCell : UITableViewCell {
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var swtch: UISwitch!
    
    var switched : () -> () = {}
    
    func adapt(title : String, isOn : Bool) {
        self.lblTitle.text = title
        self.selectionStyle = .None
        self.swtch.setOn(isOn, animated: false)
    }
    
    @IBAction func switchPressed(sender: AnyObject) {
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
    
    var checkboxTapped : (Int) -> () = { _ in }
    var headerTapped : () -> () = {}
    
    func adapt(title : String, sizes : [String], selecteds : [Bool], hidden : Bool) {
        self.lblTitle.text = title
        self.sizes = sizes
        self.selecteds = selecteds
        self.selectionStyle = .None
        
        if (hidden) {
            lblArrow.text = ""
        } else {
            lblArrow.text = ""
            let cellNib = UINib(nibName: IdFilterCheckboxCell, bundle: nil)
            self.collectionVw.registerNib(cellNib, forCellWithReuseIdentifier: IdFilterCheckboxCell)
            self.collectionVw.delegate = self
            self.collectionVw.dataSource = self
            self.collectionVw.backgroundColor = UIColor.whiteColor()
            self.collectionVw.reloadData()
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sizes.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let viewWidth = UIScreen.mainScreen().bounds.size.width
        return CGSize(width: (viewWidth - 16) / 2, height: 28)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell : FilterCheckboxCell = collectionVw.dequeueReusableCellWithReuseIdentifier(IdFilterCheckboxCell, forIndexPath: indexPath) as! FilterCheckboxCell
        if (indexPath.item < sizes.count && indexPath.item < selecteds.count) {
            cell.adapt(sizes[indexPath.item], isChecked: selecteds[indexPath.item])
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.checkboxTapped(indexPath.item)
    }
    
    @IBAction func arrowPressed(sender: AnyObject) {
        self.headerTapped()
    }
}

// MARK: - Class

class FilterCheckboxCell : UICollectionViewCell {
    
    @IBOutlet var lblCheckbox: UILabel!
    @IBOutlet var lblTitle: UILabel!
    
    func adapt(title : String, isChecked : Bool) {
        self.lblTitle.text = title
        if (isChecked) {
            self.setChecked()
        } else {
            self.setUnchecked()
        }
    }
    
    func setChecked() {
        lblCheckbox.hidden = false
    }
    
    func setUnchecked() {
        lblCheckbox.hidden = true
    }
}

// MARK: - Class

class FilterPriceCell : UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var vwPricebox: UIView!
    @IBOutlet var fldPrice: UITextField!
    
    var fieldActivated : (UITextField) -> () = { _ in }
    var fieldEdited : (String, String?) -> () = { _, _ in }
    
    func adapt(title : String, value : String) {
        self.vwPricebox.createBordersWithColor(UIColor.lightGrayColor(), radius: 0, width: 1)
        self.selectionStyle = .None
        self.lblTitle.text = title
        self.fldPrice.text = value
        self.fldPrice.placeholder = nil
        self.fldPrice.delegate = self
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.fieldActivated(textField)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.fieldEdited(lblTitle.text!, textField.text)
    }
}
