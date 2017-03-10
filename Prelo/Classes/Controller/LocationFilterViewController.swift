//
//  LocationFilterViewController.swift
//  Prelo
//
//  Created by Djuned on 12/14/16.
//  Copyright © 2016 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

typealias BlockLocationSelected = ([String]) -> ()


class LocationFilterViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var tableView : UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
    // Predefined values
    var root : UIViewController?
    var selectedLocation : String?
    var selectedLocationName : String?
    var deep = 0
    
    // Data container
    // location -> province / region
    var locations : [String]?
    var stackLocationName : String = ""
    var stackLocationId : String = ""
    
    // Delegate
    var blockDone : BlockLocationSelected?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locations = []
        
        tableView.register(ProvinceCell.self, forCellReuseIdentifier: "cell")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        if deep == 0 {
            locations = CDProvince.getProvincePickerItems() as [String]
            let new_locations : [String] = ["Semua Provinsi"]
            locations?.insert(contentsOf: new_locations, at: 0)
            tableView.reloadData()
            self.hideLoading()
            self.title = "Daftar Provinsi"
        } else if deep == 1 {
            locations = CDRegion.getRegionPickerItems(selectedLocation!) as [String]
            let new_locations : [String] = ["Semua Kota/Kabupaten di " + selectedLocationName!]
            locations?.insert(contentsOf: new_locations, at: 0)
            tableView.reloadData()
            self.hideLoading()
            self.title = "Daftar Kota/Kabupaten"
        } else {
//            self.showLoading()
            let new_locations : [String] = ["Semua Kecamatan di " + selectedLocationName!]
            locations?.insert(contentsOf: new_locations, at: 0)
            let _ = request(APIMisc.getSubdistrictsByRegionID(id: selectedLocation!)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Kecamatan")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"].arrayValue
                    
                    if (data.count > 0) {
                        
                        for i in 0...data.count - 1 {
                            self.locations?.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)                        }
                        
                        self.tableView.reloadData()
                        self.hideLoading()
                    } else {
                        Constant.showDialog("Warning", message: "Oops, kecamatan tidak ditemukan")
                    }
                }
            }
            self.title = "Daftar Kecamatan"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getRegion(_selectedLocation : String, _selectedLocationName : String) {
        let loc = Bundle.main.loadNibNamed(Tags.XibNameLocationFilter, owner: nil, options: nil)?.first as! LocationFilterViewController
        loc.root = self.root
        loc.deep = self.deep + 1
        loc.selectedLocation = _selectedLocation
        loc.selectedLocationName = _selectedLocationName // parent name for all
        loc.blockDone = self.blockDone
        loc.stackLocationName = self.stackLocationName
        loc.stackLocationId = self.stackLocationId
        self.navigationController?.pushViewController(loc, animated: true)
    }
    
    func formatLocation(loc:String) -> Array<String> {
        // Create a NSCharacterSet of delimiters.
        let separators = NSCharacterSet(charactersIn: "œ∑")
        // Split based on characters.
        return loc.components(separatedBy: separators as CharacterSet)
    }
    
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }

    
    // MARK: - Table view functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations!.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let parts = formatLocation(loc: (locations?[(indexPath as NSIndexPath).row])!)
        
        let h = parts[0].boundsWithFontSize(UIFont.systemFont(ofSize: 17), width: (cell?.width)!-32)
        
        return 30 + h.height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 17)
        
        let parts = formatLocation(loc: (locations?[(indexPath as NSIndexPath).row])!)
        
        cell?.textLabel!.text = parts[0]
        cell?.textLabel!.numberOfLines = 0
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let parts = formatLocation(loc: (locations?[(indexPath as NSIndexPath).row])!)
        
        if (indexPath as NSIndexPath).row != 0 && self.deep != 2 {
//            self.selectedLocation = parts[1]
//            self.selectedLocationName = parts[0]
//            print(CDRegion.getRegionPickerItems(selectedLocation!))
            
            if (self.deep > 0) {
                self.stackLocationName += "  "
                self.stackLocationId += ";"
            }
            self.stackLocationName += parts[0]
            self.stackLocationId += parts[1]
//            self.stackLocationName += parts[0] + "  \n"
            getRegion(_selectedLocation: parts[1], _selectedLocationName: parts[0])
        } else {
            //return
//            print(parts[0])
            
            if (indexPath as NSIndexPath).row == 0 && self.deep != 0 {
                self.blockDone!([self.selectedLocationName!, self.selectedLocation!, (self.deep - 1).string, self.stackLocationName, self.stackLocationId] as [String])
            } else if (indexPath as NSIndexPath).row == 0 && self.deep == 0 {
                self.blockDone!([parts[0], "", self.deep.string, self.stackLocationName, self.stackLocationId] as [String])
            } else {
                self.blockDone!([parts[0], parts[1], self.deep.string, self.stackLocationName, self.stackLocationId] as [String])
            }
            
            if let r = self.root {
                _ = self.navigationController?.popToViewController(r, animated: true)
            }
        }
        
    }
}

class ProvinceCell : UITableViewCell {
    
}

//// MARK: - navigation
//let filterlocation = Bundle.main.loadNibNamed(Tags.XibNameLocationFilter, owner: nil, options: nil)?.first as! LocationFilterViewController
//filterlocation.root = self
//filterlocation.blockDone = { data in
//    print(data)
//}
//self.navigationController?.pushViewController(filterlocation, animated: true)
