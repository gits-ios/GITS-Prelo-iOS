//
//  ListBrandViewController2.swift
//  Prelo
//
//  Created by PreloBook on 5/23/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation

class ListBrandViewController2: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @IBOutlet var tableView : UITableView!
    @IBOutlet var searchBar : UISearchBar!
    
    var brands : [String : String] = [:]
    var sortedBrandKeys : [String] = []
    
    var pagingCurrent = 0
    var pagingLimit = 10
    var isPagingEnded = false
    var isGettingData = false
    
    var NotFoundPlaceholder = "(merk tidak ditemukan)"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.placeholder = "Cari Merek"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
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
                        if (self.brands.count == 0) { // Which means no brand found after filter/search
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
            cell.adapt("")
        } else {
            cell.isBottomCell = false
            let name = self.sortedBrandKeys[indexPath.row]
            if (name == self.NotFoundPlaceholder) {
                cell.isNotFoundCell = true
            } else {
                cell.isNotFoundCell = false
            }
            cell.adapt(name)
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
}

class ListBrandVC2Cell: UITableViewCell {
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var isBottomCell : Bool = false
    var isNotFoundCell : Bool = false
    
    override func prepareForReuse() {
        loading.hidden = true
        self.textLabel?.textColor = UIColor.blackColor()
    }
    
    func adapt(text : String) {
        if (isBottomCell) {
            loading.hidden = false
        } else {
            loading.hidden = true
        }
        self.textLabel?.text = text
        if (isNotFoundCell) {
            self.textLabel?.textColor = UIColor.lightGrayColor()
        }
    }
}