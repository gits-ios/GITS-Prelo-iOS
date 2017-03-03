//
//  ListBrandViewController2.swift
//  Prelo
//
//  Created by PreloBook on 5/23/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//
//  This class is used for brand filtering in search page

import Foundation
import Alamofire

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


// MARK: - Protocol

protocol ListBrandDelegate {
    func adjustBrand(_ fltrBrands : [String : String])
}

// MARK: - Class

class ListBrandViewController2: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var tableView : UITableView!
    @IBOutlet var btnSubmit: UIButton!
    var searchBar : UISearchBar!
    
    // Data containers
    var brands : [String : String] = [:] // [<merkName> : <merkId>]
    var sortedBrandKeys : [String] = [] // [<merkName>]
    var selectedBrands : [String : String] = [:] // [<merkName> : <merkId>], might be predefined
    
    // Flags
    var pagingCurrent = 0
    var pagingLimit = 10
    var isPagingEnded = false
    var isGettingData = false
    var isSearchSelectedBrand = false
    
    // Placeholder
    let NotFoundPlaceholder = "(merek tidak ditemukan)"
    
    // Delegate
    var delegate : ListBrandDelegate? = nil
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search bar setup
        var searchBarWidth = UIScreen.main.bounds.size.width * 0.8375
        if (AppTools.isIPad) {
            searchBarWidth = UIScreen.main.bounds.size.width - 68
        }
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: searchBarWidth, height: 30))
        if let searchField = self.searchBar.value(forKey: "searchField") as? UITextField {
            searchField.backgroundColor = Theme.PrimaryColorDark
            searchField.textColor = UIColor.white
            let attrPlaceholder = NSAttributedString(string: "Cari Merek", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
            searchField.attributedPlaceholder = attrPlaceholder
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.withRenderingMode(.alwaysTemplate)
                icon.tintColor = UIColor.lightGray
            }
            searchField.borderStyle = UITextBorderStyle.none
        }
        searchBar.delegate = self
        searchBar.placeholder = "Cari Merek"
        self.navigationItem.rightBarButtonItem = searchBar.toBarButton()
        
        // Table setup
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Get initial brands
        getBrands()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
    }
    
    func getBrands() {
        var name = ""
        if let searchText = searchBar.text {
            name = searchText
        }
        self.isGettingData = true
        let _ = request(APISearch.brands(name: name, current: self.pagingCurrent, limit: (self.pagingCurrent == 0 ? 25 : self.pagingLimit))).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Merk")) {
                if (name == self.searchBar.text) { // Jika response ini sesuai dengan request terakhir
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    
                    if (data.count < self.pagingLimit) {
                        self.isPagingEnded = true
                    }
                    if (data.count > 0) {
                        for i in 0...(data.count - 1) {
                            if let merkName = data[i]["name"].string, let merkId = data[i]["_id"].string {
                                if (self.selectedBrands[merkName] == nil) { // If not already in selected brands
                                    self.brands[merkName] = merkId
                                } else {
                                    // Set true, supaya ga perlu munculin loading di baris paling bawah, karena sebenarnya brand sudah ada di selectedBrand
                                    self.isSearchSelectedBrand = true
                                }
                            }
                        }
                    } else {
                        if (self.brands.count == 0) { // Which means no brand found after search
                            self.brands[self.NotFoundPlaceholder] = ""
                        }
                    }
                    self.adaptSortedBrandKeys()
                    self.tableView.reloadData()
                    self.pagingCurrent += self.pagingCurrent == 0 ? 25 : self.pagingLimit
                    self.isGettingData = false
                }
            }
        }
    }
    
    // MARK: - UITableView functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var n = brands.count + selectedBrands.count
        if (!isSearchSelectedBrand && (!self.isPagingEnded || brands.count == 0)) { // Jika tidak sedang mencari brand yg sudah dipilih, dan (paging belum selesai atau jika sedang loading filter)
            // Additional cell for loading indicator or not found indicator
            n += 1
        }
        return n
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListBrandVC2Cell") as! ListBrandVC2Cell
        cell.selectionStyle = .none
        
        if ((indexPath as NSIndexPath).row >= brands.count + selectedBrands.count) { // Make this loading cell
            cell.isBottomCell = true
            cell.adapt("", isChecked: false)
        } else {
            // selectedBrands selalu dipasang di atas
            cell.isBottomCell = false
            let name = self.sortedBrandKeys[(indexPath as NSIndexPath).row]
            if (name == self.NotFoundPlaceholder) {
                cell.isNotFoundCell = true
            } else {
                cell.isNotFoundCell = false
            }
            cell.adapt(name, isChecked: ((indexPath as NSIndexPath).row < self.selectedBrands.count))
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ((indexPath as NSIndexPath).row >= (brands.count + selectedBrands.count) || self.sortedBrandKeys[(indexPath as NSIndexPath).row] == self.NotFoundPlaceholder) { // Jika yg diklik adl loading atau 'merk tidak ditemukan'
            return
        }
        
        if ((indexPath as NSIndexPath).row >= self.selectedBrands.count) { // Which means select unselected brand
            // Pindahkan elemen dictionary dari brand ke selectedBrand, kemudian pindahkan index pada sortedBrandKeys ke bagian atas
            self.selectedBrands[self.sortedBrandKeys[(indexPath as NSIndexPath).row]] = self.brands[self.sortedBrandKeys[(indexPath as NSIndexPath).row]]
            self.brands.removeValue(forKey: self.sortedBrandKeys[(indexPath as NSIndexPath).row])
            self.sortedBrandKeys.insert(self.sortedBrandKeys.remove(at: (indexPath as NSIndexPath).row), at: self.selectedBrands.count - 1)
            self.isSearchSelectedBrand = true
        } else { // Which means unselect selected brand
            // Pindahkan elemen dictionary dari selectedBrand ke brand, kemudian pindahkan index pada sortedBrandKeys ke bukan bagian atas
            self.brands[self.sortedBrandKeys[(indexPath as NSIndexPath).row]] = self.selectedBrands[self.sortedBrandKeys[(indexPath as NSIndexPath).row]]
            self.selectedBrands.removeValue(forKey: self.sortedBrandKeys[(indexPath as NSIndexPath).row])
            self.sortedBrandKeys.insert(self.sortedBrandKeys.remove(at: (indexPath as NSIndexPath).row), at: selectedBrands.count)
            self.adaptSortedBrandKeys()
        }
        
        // Update button title
        if (self.selectedBrands.count > 0) {
            self.btnSubmit.setTitle("FILTER (\(self.selectedBrands.count))", for: UIControlState())
        } else {
            self.btnSubmit.setTitle("FILTER", for: UIControlState())
        }
        
        // Reload table
        tableView.reloadData()
    }
    
    // MARK: - Scroll view functions
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset : CGPoint = scrollView.contentOffset
        let bounds : CGRect = scrollView.bounds
        let size : CGSize = scrollView.contentSize
        let inset : UIEdgeInsets = scrollView.contentInset
        let y : CGFloat = offset.y + bounds.size.height - inset.bottom
        let h : CGFloat = size.height
        
        let reloadDistance : CGFloat = 0
        if (y > h + reloadDistance) {
            // Load next items only if all items not loaded yet and if its not currently loading items
            if (!self.isPagingEnded && !self.isGettingData) {
                self.getBrands()
            }
        }
    }
    
    // MARK: - Search bar functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.brands.removeAll()
        self.isSearchSelectedBrand = false
        tableView.reloadData()
        if (self.isFiltering()) {
            // Jika sedang memfilter/mencari, tidak usah pakai paging
            self.isPagingEnded = true
        } else {
            // Jika tidak sedang memfilter/mencari, pakai paging
            self.isPagingEnded = false
        }
        self.pagingCurrent = 0
        
        self.getBrands()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if let searchField = searchBar.value(forKey: "searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.withRenderingMode(.alwaysTemplate)
                icon.tintColor = UIColor.white
            }
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if let searchField = searchBar.value(forKey: "searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.withRenderingMode(.alwaysTemplate)
                icon.tintColor = UIColor.lightGray
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func disableFields(_ sender : AnyObject) {
        searchBar.resignFirstResponder()
    }
    
    @IBAction func submitPressed(_ sender: AnyObject) {
        //if (selectedBrands.count <= 0) {
        //    Constant.showDialog("Perhatian", message: "Pilih satu atau lebih merek terlebih dahulu")
        //    return
        //}
        
        if (self.previousController != nil) {
            delegate?.adjustBrand(selectedBrands)
            self.navigationController?.popViewController(animated: true)
        } else {
            let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            l.currentMode = .filter
            l.isBackToFltrSearch = true
            l.fltrBrands = selectedBrands
            l.fltrSortBy = "recent"
            self.navigationController?.pushViewController(l, animated: true)
        }
    }
    
    // MARK: - Helper functions
    
    func adaptSortedBrandKeys() {
        self.sortedBrandKeys.removeLast(self.sortedBrandKeys.count - self.selectedBrands.count)
        self.sortedBrandKeys.append(contentsOf: self.sortCaseInsensitive([String](self.brands.keys)))
        if (self.selectedBrands["Tanpa Merek"] == nil) { // Which means 'tanpa merek' is unselected
            if let noBrandIdx = self.sortedBrandKeys.index(of: "Tanpa Merek") {
                self.sortedBrandKeys.insert(self.sortedBrandKeys.remove(at: noBrandIdx), at: self.selectedBrands.count)
            }
        }
    }
    
    func sortCaseInsensitive(_ values:[String]) -> [String]{
        
        let sortedValues = values.sorted(by: { (value1, value2) -> Bool in
            
            if (value1.lowercased() < value2.lowercased()) {
                return true
            } else {
                return false
            }
        })
        return sortedValues
    }
    
    func isFiltering() -> Bool {
        return (self.searchBar.text?.length > 0)
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

class ListBrandVC2Cell: UITableViewCell {
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var loading: UIActivityIndicatorView!
    @IBOutlet var vwCheckbox: UIView!
    @IBOutlet var lblCheck: UILabel!
    
    var isBottomCell : Bool = false
    var isNotFoundCell : Bool = false
    
    override func prepareForReuse() {
        lblTitle.text = ""
        lblTitle.textColor = UIColor.darkGray
        loading.isHidden = true
        vwCheckbox.isHidden = false
        isBottomCell = false
        isNotFoundCell = false
    }
    
    func adapt(_ text : String, isChecked : Bool) {
        if (isBottomCell) {
            loading.isHidden = false
            loading.startAnimating()
            vwCheckbox.isHidden = true
        } else {
            loading.isHidden = true
            loading.stopAnimating()
        }
        lblTitle.text = text
        if (isNotFoundCell) {
            lblTitle.textColor = UIColor.lightGray
            vwCheckbox.isHidden = true
        }
        if (isChecked) {
            lblCheck.isHidden = false
        } else {
            lblCheck.isHidden = true
        }
    }
}
