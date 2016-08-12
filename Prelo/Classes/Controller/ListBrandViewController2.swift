//
//  ListBrandViewController2.swift
//  Prelo
//
//  Created by PreloBook on 5/23/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//
//  This class is used for brand filtering in search page

import Foundation

// MARK: - Class

class ListBrandViewController2: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var tableView : UITableView!
    var searchBar : UISearchBar!
    
    // Data containers
    var brands : [String : String] = [:]
    var sortedBrandKeys : [String] = []
    
    // Flags
    var pagingCurrent = 0
    var pagingLimit = 10
    var isPagingEnded = false
    var isGettingData = false
    
    // Placeholder
    let NotFoundPlaceholder = "(merk tidak ditemukan)"
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search bar setup
        var searchBarWidth = UIScreen.mainScreen().bounds.size.width * 0.8375
        if (AppTools.isIPad) {
            searchBarWidth = UIScreen.mainScreen().bounds.size.width - 68
        }
        searchBar = UISearchBar(frame: CGRectMake(0, 0, searchBarWidth, 30))
        if let searchField = self.searchBar.valueForKey("searchField") as? UITextField {
            searchField.backgroundColor = Theme.PrimaryColorDark
            searchField.textColor = UIColor.whiteColor()
            let attrPlaceholder = NSAttributedString(string: "Cari Merek", attributes: [NSForegroundColorAttributeName : UIColor.lightGrayColor()])
            searchField.attributedPlaceholder = attrPlaceholder
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.imageWithRenderingMode(.AlwaysTemplate)
                icon.tintColor = UIColor.lightGrayColor()
            }
            searchField.borderStyle = UITextBorderStyle.None
        }
        searchBar.delegate = self
        searchBar.placeholder = "Cari Merek"
        self.navigationItem.rightBarButtonItem = searchBar.toBarButton()
        
        // Table setup
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        // Get initial brands
        getBrands()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    func getBrands() {
        var name = ""
        if let searchText = searchBar.text {
            name = searchText
        }
        self.isGettingData = true
        request(APISearch.Brands(name: name, current: self.pagingCurrent, limit: (self.pagingCurrent == 0 ? 25 : self.pagingLimit))).responseJSON { resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Merk")) {
                if (name == self.searchBar.text) { // Jika belum ada rikues lain karena perubahan search text
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    
                    if (data.count < self.pagingLimit) {
                        self.isPagingEnded = true
                    }
                    if (data.count > 0) {
                        for i in 0...(data.count - 1) {
                            if let merkName = data[i]["name"].string, let merkId = data[i]["_id"].string {
                                self.brands[merkName] = merkId
                            }
                        }
                    } else {
                        if (self.brands.count == 0) { // Which means no brand found after search
                            self.brands[self.NotFoundPlaceholder] = ""
                        }
                    }
                    self.sortedBrandKeys = self.sortCaseInsensitive(Array(self.brands.keys))
                    if let noBrandIdx = self.sortedBrandKeys.indexOf("Tanpa Merek") {
                        self.sortedBrandKeys.insert(self.sortedBrandKeys.removeAtIndex(noBrandIdx), atIndex: 0)
                    }
                    self.tableView.reloadData()
                    self.pagingCurrent += self.pagingCurrent == 0 ? 25 : self.pagingLimit
                    self.isGettingData = false
                }
            }
        }
    }
    
    // MARK: - UITableView functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var n = brands.count
        if (!self.isPagingEnded || n == 0) { // Jika paging belum selesai, atau jika sedang loading filter
            // Additional cell for loading indicator or not found indicator
            n += 1
        }
        return n
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListBrandVC2Cell") as! ListBrandVC2Cell
        cell.selectionStyle = .None
        
        if (indexPath.row >= brands.count) { // Make this loading cell
            cell.isBottomCell = true
            cell.adapt("", isChecked: false)
        } else {
            cell.isBottomCell = false
            let name = self.sortedBrandKeys[indexPath.row]
            if (name == self.NotFoundPlaceholder) {
                cell.isNotFoundCell = true
            } else {
                cell.isNotFoundCell = false
            }
            cell.adapt(name, isChecked: false)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let brandId = self.brands[self.sortedBrandKeys[indexPath.row]] where self.sortedBrandKeys[indexPath.row] != self.NotFoundPlaceholder else {
            return
        }
        let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        l.searchMode = true
        l.searchBrand = true
        l.searchBrandId = brandId
        l.searchKey = self.sortedBrandKeys[indexPath.row]
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
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
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.brands.removeAll()
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
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if let searchField = searchBar.valueForKey("searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.imageWithRenderingMode(.AlwaysTemplate)
                icon.tintColor = UIColor.whiteColor()
            }
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        if let searchField = searchBar.valueForKey("searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.imageWithRenderingMode(.AlwaysTemplate)
                icon.tintColor = UIColor.lightGrayColor()
            }
        }
    }
    
    @IBAction func disableFields(sender : AnyObject) {
        searchBar.resignFirstResponder()
    }
    
    
    @IBAction func submitPressed(sender: AnyObject) {
    }
    
    // MARK: - Helper functions
    
    func sortCaseInsensitive(values:[String]) -> [String]{
        
        let sortedValues = values.sort({ (value1, value2) -> Bool in
            
            if (value1.lowercaseString < value2.lowercaseString) {
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
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isKindOfClass(UIButton.classForCoder()) || touch.view!.isKindOfClass(UITextField.classForCoder())) {
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
        lblTitle.textColor = UIColor.darkGrayColor()
        loading.hidden = true
        vwCheckbox.hidden = false
        isBottomCell = false
        isNotFoundCell = false
    }
    
    func adapt(text : String, isChecked : Bool) {
        if (isBottomCell) {
            loading.hidden = false
            loading.startAnimating()
            vwCheckbox.hidden = true
        } else {
            loading.hidden = true
            loading.stopAnimating()
        }
        lblTitle.text = text
        if (isNotFoundCell) {
            lblTitle.textColor = UIColor.lightGrayColor()
            vwCheckbox.hidden = true
        }
        if (isChecked) {
            lblCheck.hidden = false
        } else {
            lblCheck.hidden = true
        }
    }
}