//
//  PickerViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/3/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

@objc protocol PickerViewDelegate
{
    optional func pickerDidSelect(item : String)
}

typealias PrepDataBlock = (picker : PickerViewController) -> ()
typealias PickerSelectBlock = (item : String) -> ()

class PickerViewController: UITableViewController, UISearchBarDelegate
{
    
    static let TAG_START_HIDDEN = "œ"
    static let TAG_END_HIDDEN = "∑"
    
    var merkMode = false
    
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
    
    static func HideHiddenString(string : String) -> String
    {
        var sf = AppToolsObjC.stringByHideTextBetween(PickerViewController.TAG_START_HIDDEN, and: PickerViewController.TAG_END_HIDDEN, from: string)
        
        sf = sf.stringByReplacingOccurrencesOfString(PickerViewController.TAG_START_HIDDEN, withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        sf = sf.stringByReplacingOccurrencesOfString(PickerViewController.TAG_END_HIDDEN, withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        
        return sf
    }
    
    static func RevealHiddenString(string : String) -> String
    {
        let text = PickerViewController.HideHiddenString(string)
        var sf = string.stringByReplacingOccurrencesOfString(text, withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        sf = sf.stringByReplacingOccurrencesOfString(PickerViewController.TAG_START_HIDDEN, withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        sf = sf.stringByReplacingOccurrencesOfString(PickerViewController.TAG_END_HIDDEN, withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
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
            let v = ""
            let x = v as NSString
            if (x.rangeOfString("").location != NSNotFound)
            {
                
            }
            
            let k = ""
            if let arr = newValue
            {
                usedItems = arr.filter({
                    let s = $0 as NSString
                    if (s.rangeOfString("").location != NSNotFound || k == "")
                    {
                        return true
                    }
                    return false
                })
            }
        }
    }
    
    var subtitles : Array<String> = []
    
    var usedItems : Array<String> = []
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
            prepDataBlock!(picker: self)
        }
        
        searchBar.autocapitalizationType = .Words
        
        // Tombol back
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PickerViewController.dismiss))
        newBackButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = newBackButton
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedItems.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        if (cell == nil) {
            if (subtitles.count != 0 && subtitles.count == usedItems.count)
            {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cell")
            } else
            {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
            }
        }
        
        let raw = usedItems.objectAtCircleIndex(indexPath.row)
        let s = PickerViewController.HideHiddenString(raw)
        
        cell?.textLabel?.text = s
        
        if (subtitles.count != 0 && subtitles.count == usedItems.count)
        {
            cell?.detailTextLabel?.minimumScaleFactor = 0.5
            cell?.detailTextLabel?.adjustsFontSizeToFitWidth = true
            cell?.detailTextLabel?.text = subtitles[indexPath.row]
        }
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (selectBlock != nil) {
            selectBlock!(item: (usedItems.objectAtCircleIndex(indexPath.row)))
        }
        
        
        if (pickerDelegate != nil) {
            pickerDelegate?.pickerDidSelect!((usedItems.objectAtCircleIndex(indexPath.row)))
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func startLoading()
    {
        self.textTitle = self.title
        self.navigationItem.titleView = BaseViewController.TitleLabel("Loading..")
    }
    
    func doneLoading()
    {
        self.navigationItem.titleView = BaseViewController.TitleLabel(textTitle!)
    }
    
    func dismiss()
    {
        if (self.navigationController != nil) {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.filter(searchText)
        tableView.reloadData()
    }
    
    func filter(k : String)
    {
        let key = k.lowercaseString
        if let arr = self.items
        {
            usedItems = arr.filter({
                let s = $0.lowercaseString as NSString
                if (s.rangeOfString(key).location != NSNotFound || k == "")
                {
                    return true
                }
                return false
            })
            
            usedItems.insert("Tambahkan merek '" + (searchBar.text == nil ? "" : searchBar.text!) + "'", atIndex: 0)
        }
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
