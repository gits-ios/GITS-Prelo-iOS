//
//  LocationFilterViewController.swift
//  Prelo
//
//  Created by Djuned on 12/14/16.
//  Copyright © 2016 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

typealias BlockLocationSelected = ([String]) -> ()


class LocationFilterViewController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var tableView : UITableView!
    
    // Predefined values
    var root : UIViewController?
    var selectedLocation : String?
    var selectedLocationName : String?
    
    // Data container
    // location -> province / region
    var locations : [String]?
    var deep = 0
    
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
        } else if deep == 1 {
            locations = CDRegion.getRegionPickerItems(selectedLocation!) as [String]
            let new_locations : [String] = ["Semua Kota/Kabupaten"]
            locations?.insert(contentsOf: new_locations, at: 0)
            tableView.reloadData()
        } else {
            let new_locations : [String] = ["Semua Kecamatan"]
            locations?.insert(contentsOf: new_locations, at: 0)
            let _ = request(APIMisc.getSubdistrictsByRegionID(id: selectedLocation!)).responseJSON { resp in
                if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Kecamatan")) {
                    let json = JSON(resp.result.value!)
                    let data = json["_data"].arrayValue
                    
                    if (data.count > 0) {
                        
                        for i in 0...data.count - 1 {
                            self.locations?.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)                        }
                        
                        self.tableView.reloadData()
                    } else {
                        Constant.showDialog("Warning", message: "Oops, kecamatan tidak ditemukan")
                    }
                }
            }
            
//            print(self.locations)
        }
    }
    
    func getRegion(_selectedLocation : String) {
        let loc = Bundle.main.loadNibNamed(Tags.XibNameLocationFilter, owner: nil, options: nil)?.first as! LocationFilterViewController
        loc.root = self.root
        loc.deep = self.deep + 1
        loc.selectedLocation = _selectedLocation
        loc.selectedLocationName = self.selectedLocationName // parent name for all
        loc.blockDone = self.blockDone
        self.navigationController?.pushViewController(loc, animated: true)
    }
    
    func formatLocation(loc:String) -> Array<String> {
        // Create a NSCharacterSet of delimiters.
        let separators = NSCharacterSet(charactersIn: "œ∑")
        // Split based on characters.
        return loc.components(separatedBy: separators as CharacterSet)
    }
    
    // MARK: - Table view functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations!.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        let parts = formatLocation(loc: (locations?[(indexPath as NSIndexPath).row])!)
        
        cell?.textLabel!.text = parts[0]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let parts = formatLocation(loc: (locations?[(indexPath as NSIndexPath).row])!)
        
        if (indexPath as NSIndexPath).row != 0 && self.deep != 2 {
            self.selectedLocation = parts[1]
            self.selectedLocationName = parts[0]
//            print(CDRegion.getRegionPickerItems(selectedLocation!))
            getRegion(_selectedLocation: parts[1])
        } else {
            //return
//            print(parts[0])
            
            if (indexPath as NSIndexPath).row == 0 && self.deep != 0 {
                self.blockDone!([self.selectedLocationName!, self.selectedLocation!] as [String])
            } else if (indexPath as NSIndexPath).row == 0 && self.deep == 0 {
                self.blockDone!([parts[0], ""] as [String])
            } else {
                self.blockDone!([parts[0], parts[1]] as [String])
            }
            
            if let r = self.root {
                self.navigationController?.popToViewController(r, animated: true)
            }
        }
        
    }
}

class ProvinceCell : UITableViewCell {
    
}

//// MARK: - navigation
//let productReportVC = Bundle.main.loadNibNamed(Tags.XibNameLocationFilter, owner: nil, options: nil)?.first as! LocationFilterViewController
//productReportVC.root = self
//productReportVC.blockDone = { data in
//    print(data)
//}
//self.navigationController?.pushViewController(productReportVC, animated: true)
