//
//  ListBrandViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/18/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Alamofire

class ListBrandViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate
{
    @IBOutlet var tableView : UITableView!
    @IBOutlet var searchBar : UISearchBar!
    
    var rawBrands : [JSON] = []
    var brands : [JSON] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.placeholder = "Cari Merek"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        getBrands()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
    }
    
    func getBrands()
    {
//        let s = NSBundle.mainBundle().URLForResource("merk", withExtension: "json")?.absoluteString
//        if let url = s
//        {
//                    }
        self.title = "Loading.."
        // API Migrasi
        let _ = request(APIApp.metadata(brands: "1", categories: "0", categorySizes: "0", shippings: "0", productConditions: "0", provincesRegions: "0")).responseJSON {resp in
            self.title = "Merek"
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "List Merk"))
            {
                let json = JSON(resp.result.value!)
                let brands = json["_data"]["brands"].array
                self.rawBrands = brands!
                self.filter()
                self.tableView.reloadData()
            } else
            {
                
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
                let s = name.lowercased() as NSString
                if (s.range(of: (self.searchBar.text == nil ? "" : self.searchBar.text!).lowercased()).location != NSNotFound)
                {
                    return true
                }
            }
            
            return false
        })
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filter()
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (searchBar.text == "")
        {
            return brands.count
        }
        return brands.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var c = tableView.dequeueReusableCell(withIdentifier: "cell")
        if (c == nil)
        {
            c = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        }
        
        let b = brands[(indexPath as NSIndexPath).row]
        if let name = b["name"].string
        {
            c?.textLabel?.text = name
        }
        
//        if (searchBar.text == "")
//        {
//            let b = brands[indexPath.row]
//            if let name = b["name"].string
//            {
//                c?.textLabel?.text = name
//            }
//        } else
//        {
        
//            if (indexPath.row == 0)
//            {
//                c?.textLabel?.text = "Gunakan '"+searchBar.text+"'"
//            } else
//            {
//                
//            }
//        }
        
        return c!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (searchBar.text == "")
        {
            
        } else
        {
            
        }
        
        let b = brands[(indexPath as NSIndexPath).row]
        if let id = b["_id"].string, let name = b["name"].string
        {
            let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            l.currentMode = .filter
            l.fltrSortBy = "recent"
            l.fltrBrands = [name : id]
            self.navigationController?.pushViewController(l, animated: true)
        }
    }
}


