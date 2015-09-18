//
//  ListBrandViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/18/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class ListBrandViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate
{
    @IBOutlet var tableView : UITableView!
    @IBOutlet var searchBar : UISearchBar!
    
    var rawBrands : [JSON] = []
    var brands : [JSON] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        getBrands()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    func getBrands()
    {
        let s = NSBundle.mainBundle().URLForResource("merk", withExtension: "json")?.absoluteString
        if let url = s
        {
            request(Method.GET, url, parameters: nil, encoding: ParameterEncoding.URL, headers: nil).responseJSON{_, resp, res, err in
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
                    let json = JSON(res!)
                    if let arr = json["brands"].array
                    {
                        self.rawBrands = arr
                    }
                    self.filter()
                    self.tableView.reloadData()
                } else
                {
                    
                }
            }
        }
    }
    
    func filter()
    {
        self.brands = rawBrands.filter({
            if let name = $0["name"].string
            {
                if (self.searchBar.text == "")
                {
                    return true
                }
                let s = name.lowercaseString as NSString
                if (s.rangeOfString(self.searchBar.text.lowercaseString).location != NSNotFound)
                {
                    return true
                }
            }
            
            return false
        })
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.filter()
        self.tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return brands.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var c = tableView.dequeueReusableCellWithIdentifier("cell") as? UITableViewCell
        if (c == nil)
        {
            c = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
        }
        
        let b = brands[indexPath.row]
        if let name = b["name"].string
        {
            c?.textLabel?.text = name
        }
        
        return c!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let b = brands[indexPath.row]
        if let id = b["_id"].string, name = b["name"].string
        {
            let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
            l.searchMode = true
            l.searchBrand = true
            l.searchBrandId = id
            l.searchKey = name
            self.navigationController?.pushViewController(l, animated: true)
        }
    }
}


