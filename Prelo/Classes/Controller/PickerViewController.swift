//
//  PickerViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/3/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
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


@objc protocol PickerViewDelegate
{
    @objc optional func pickerDidSelect(_ item : String)
    @objc optional func pickerCancelled()
}

typealias PrepDataBlock = (_ picker : PickerViewController) -> ()
typealias PickerSelectBlock = (_ item : String) -> ()

class PickerViewController: UITableViewController, UISearchBarDelegate
{
    
    static let TAG_START_HIDDEN = "œ"
    static let TAG_END_HIDDEN = "∑"
    
    var merkMode = false
    
    var pagingMode = false
    var pagingCurrent = 0
    var pagingLimit = 10
    var isPagingEnded = true
    var isGettingData = false
    
    @IBOutlet var searchBar : UISearchBar!
    
    var showSearch : Bool
        {
        set {
            if (newValue == true)
            {
                tableView.tableHeaderView = searchBar
            } else
            {
                tableView.tableHeaderView = UIView()
            }
        }
        
        get {
            return tableView.tableHeaderView != nil
        }
    }
    
    static func HideHiddenString(_ string : String) -> String
    {
        var sf = AppToolsObjC.string(byHideTextBetween: PickerViewController.TAG_START_HIDDEN, and: PickerViewController.TAG_END_HIDDEN, from: string)
        
        sf = sf?.replacingOccurrences(of: PickerViewController.TAG_START_HIDDEN, with: "", options: NSString.CompareOptions.caseInsensitive, range: nil)
        sf = sf?.replacingOccurrences(of: PickerViewController.TAG_END_HIDDEN, with: "", options: NSString.CompareOptions.caseInsensitive, range: nil)
        
        return sf!
    }
    
    static func RevealHiddenString(_ string : String) -> String
    {
        let text = PickerViewController.HideHiddenString(string)
        var sf = string.replacingOccurrences(of: text, with: "", options: NSString.CompareOptions.caseInsensitive, range: nil)
        sf = sf.replacingOccurrences(of: PickerViewController.TAG_START_HIDDEN, with: "", options: NSString.CompareOptions.caseInsensitive, range: nil)
        sf = sf.replacingOccurrences(of: PickerViewController.TAG_END_HIDDEN, with: "", options: NSString.CompareOptions.caseInsensitive, range: nil)
        return sf
    }
    
    var _items : Array<String>?
    var items : Array<String>?
        {
        get {
            return _items
        }
        
        set {
            _items = newValue
        }
    }
    
    var subtitles : Array<String> = []
    
    var pickerDelegate : PickerViewDelegate?
    
    var prepDataBlock : PrepDataBlock?
    var selectBlock : PickerSelectBlock?
    
    var textTitle : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
        searchBar.delegate = self
        
        if (merkMode)
        {
            searchBar.placeholder = "Cari Atau Tambahkan Merek"
        }
        
        self.showSearch = false
        
        if (prepDataBlock != nil) {
            startLoading()
            prepDataBlock!(self)
        }
        
        searchBar.autocapitalizationType = .words
        
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PickerViewController.dismissPicker))
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], for: UIControlState())
        self.navigationItem.leftBarButtonItem = newBackButton
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var n = items!.count
        if (!self.isPagingEnded || n == 0) { // Jika paging belum selesai, atau jika sedang loading filter
            // Additional cell for loading indicator
            n += 1
        }
        return n
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let usedItems = items else {
            return UITableViewCell()
        }
        
        if ((indexPath as NSIndexPath).row >= usedItems.count) { // Make this loading cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "PickerVCCell") as! PickerVCCell
            
            cell.isBottomCell = true
            cell.adapt()
            
            return cell
        } else {
            var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            
            if (cell == nil) {
                if (subtitles.count != 0 && subtitles.count == usedItems.count)
                {
                    cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "cell")
                } else
                {
                    cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
                }
            }
            
            let raw = usedItems.objectAtCircleIndex((indexPath as NSIndexPath).row)
            let s = PickerViewController.HideHiddenString(raw)
            
            cell?.textLabel?.text = s
            
            if (subtitles.count != 0 && subtitles.count == usedItems.count)
            {
                cell?.detailTextLabel?.minimumScaleFactor = 0.5
                cell?.detailTextLabel?.adjustsFontSizeToFitWidth = true
                cell?.detailTextLabel?.text = subtitles[(indexPath as NSIndexPath).row]
            }
            
            return cell!
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let usedItems = items else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        if (selectBlock != nil) {
            selectBlock!((usedItems.objectAtCircleIndex((indexPath as NSIndexPath).row)))
        }
        
        if (pickerDelegate != nil) {
            pickerDelegate?.pickerDidSelect!((usedItems.objectAtCircleIndex((indexPath as NSIndexPath).row)))
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset : CGPoint = scrollView.contentOffset
        let bounds : CGRect = scrollView.bounds
        let size : CGSize = scrollView.contentSize
        let inset : UIEdgeInsets = scrollView.contentInset
        let y : CGFloat = offset.y + bounds.size.height - inset.bottom
        let h : CGFloat = size.height
        
        let reloadDistance : CGFloat = 0
        if (y > h + reloadDistance) {
            // Load next items only if all items not loaded yet and if its not currently loading items
            if (self.pagingMode && !self.isPagingEnded && !self.isGettingData) {
                if (self.merkMode) {
                    self.getBrands(self.searchBar.text!)
                }
            }
        }
    }
    
    func getBrands(_ name: String) {
        self.isGettingData = true
        let _ = request(APISearch.brands(name: name, current: self.pagingCurrent, limit: (self.pagingCurrent == 0 ? 25 : self.pagingLimit))).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Merk")) {
                if (name == self.searchBar.text) { // Jika belum ada rikues lain karena perubahan search text
                    let json = JSON(resp.result.value!)
                    let data = json["_data"]
                    
                    if (data.count < self.pagingLimit) {
                        self.isPagingEnded = true
                    }
                    var isShowAddNewBrandCell = true
                    if (data.count > 0) {
                        for i in 0...(data.count - 1) {
                            if let merkName = data[i]["name"].string, let merkId = data[i]["_id"].string {
                                var strToHide = merkId
                                var isLuxury = false
                                if let isLux = data[i]["is_luxury"].bool {
                                    isLuxury = isLux
                                }
                                if let segments = data[i]["segments"].array , segments.count > 0 {
                                    for j in 0...(segments.count - 1) {
                                        if (segments[j].stringValue.lowercased() == "luxury") {
                                            isLuxury = true
                                        }
                                    }
                                }
                                strToHide += ";" + (isLuxury ? "1" : "0")
                                self.items?.append(merkName + PickerViewController.TAG_START_HIDDEN + strToHide + PickerViewController.TAG_END_HIDDEN)
                                if (merkName.lowercased() == name.lowercased()) { // Jika ada merk yg sama dengan query search, tidak perlu memunculkan 'Tambahkan merek..'
                                    isShowAddNewBrandCell = false
                                }
                            }
                        }
                    }
                    if (self.isFiltering() && isShowAddNewBrandCell) {
                        self.items?.insert("Tambahkan merek '" + (self.searchBar.text == nil ? "" : self.searchBar.text!) + "'", at: 0)
                    }
                    self.tableView.reloadData()
                    self.pagingCurrent += self.pagingCurrent == 0 ? 25 : self.pagingLimit
                    self.isGettingData = false
                }
            }
        }
    }
    
    func startLoading()
    {
        self.textTitle = self.title
        self.navigationItem.titleView = BaseViewController.formattedTitleLabel("Loading..")
    }
    
    func doneLoading()
    {
        self.navigationItem.titleView = BaseViewController.formattedTitleLabel(textTitle!)
    }
    
    func dismissPicker()
    {
        if (pickerDelegate != nil) {
            pickerDelegate!.pickerCancelled?()
        }
        if (self.navigationController != nil) {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filter(searchText)
        tableView.reloadData()
    }
    
    func filter(_ k : String)
    {
        self.items?.removeAll()
        tableView.reloadData()
        if (self.isFiltering()) {
            // Jika sedang memfilter/mencari, tidak usah pakai paging
            self.isPagingEnded = true
        } else {
            // Jika tidak sedang memfilter/mencari, pakai paging
            self.isPagingEnded = false
        }
        self.pagingCurrent = 0
        
        if (self.merkMode) {
            self.getBrands(k)
        }
    }
    
    func isFiltering() -> Bool {
        return (self.searchBar.text?.length > 0)
    }
}

class PickerVCCell: UITableViewCell {

    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var isBottomCell : Bool = false
    
    override func prepareForReuse() {
        loading.isHidden = true
    }
    
    func adapt() {
        if (isBottomCell) {
            loading.isHidden = false
        }
    }
}
