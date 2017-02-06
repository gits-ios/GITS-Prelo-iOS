//
//  AddressBookViewController.swift
//  Prelo
//
//  Created by Djuned on 2/6/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class
class AddressBookViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    var addresses: Array<AddressItem>? // addresses
    var isFirst: Bool = true

    // for new achievement unlock -- pop up
    @IBOutlet weak var vwBackgroundOverlay: UIView! // hidden
    @IBOutlet weak var vwOverlayPopUp: UIView! // hidden
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var consCenteryPopUp: NSLayoutConstraint! // align center y --> 603 [window height] -> 0
    @IBOutlet weak var vwPopUp: UIView!
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let AchievementDiamondCell = UINib(nibName: "AchievementDiamondCell", bundle: nil)
//        tableView.register(AchievementDiamondCell, forCellReuseIdentifier: "AchievementDiamondCell")
//        
//        let AchievementCelliOS9xx = UINib(nibName: "AchievementCelliOS9xx", bundle: nil)
//        tableView.register(AchievementCelliOS9xx, forCellReuseIdentifier: "AchievementCell")
        
        self.title = "Daftar Alamat"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirst {
            isFirst = false
            showLoading()
            
            // Setup table
            tableView.dataSource = self
            tableView.delegate = self
            tableView.tableFooterView = UIView()
            
            //TOP, LEFT, BOTTOM, RIGHT
            let inset = UIEdgeInsetsMake(5, 0, 5, 0)
            tableView.contentInset = inset
            
            tableView.separatorStyle = .none
            
            tableView.backgroundColor = UIColor(hex: "E5E9EB")
            
            getAddresses()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Achievement)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getAddresses() {
        self.addresses = []
        
//        let fakeres = [
//            "name":names[s],
//            "icon":images[s],
//            "progress": 0,
//            "progress_icon": [images[t], images[u]],
//            "conditions": [["fullfilled":(i % 2 == 0 ? true : false), "condition_text":"mantap"],["fullfilled":(i % 2 == 0 ? false : true), "condition_text":"gg"]]
//            ] as [String : Any]
//        
//        let json = JSON(fakeres)
//        let address = AddressItem.instance(json)
//        self.addresses?.append(address!)
        
        // TODO: - use API
        
    }
    
    
    // MARK: - Other
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ((indexPath as NSIndexPath).item < (self.addresses?.count)!) {
            return 185
        } else {
            return 57
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath as NSIndexPath).item < (self.addresses?.count)!) {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementDiamondCell") as! AchievementDiamondCell
//            
//            cell.selectionStyle = .none
//            cell.backgroundColor = UIColor(hex: "E5E9EB")
//            cell.clipsToBounds = true
//            cell.adapt(diamonds, isOpen: isOpens[(indexPath as NSIndexPath).row])
//            
//            return cell
        } else {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementDiamondCell") as! AchievementDiamondCell
//            
//            cell.selectionStyle = .none
//            cell.backgroundColor = UIColor(hex: "E5E9EB")
//            cell.clipsToBounds = true
//            cell.adapt(diamonds, isOpen: isOpens[(indexPath as NSIndexPath).row])
//            
//            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // do nothing
    }
    
    // MARK: - Pop up
    func setupPopUp() {
        self.lblDescription.text = "Alamat Utama adalah alamat yang digunakan untuk menghitung biaya pengiriman barang jualan kamu."
        
        // TODO: - attribute text - bold
    }
    
    func initPopUp() {
        // Transparent panel
        self.vwBackgroundOverlay.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        
        self.vwBackgroundOverlay.isHidden = false
        self.vwOverlayPopUp.isHidden = false
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
    }
    
    func displayPopUp() {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = (screenHeight - self.vwPopUp.frame.height) / 2
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = 0
    }
    
    func unDisplayPopUp() {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = 0
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = screenHeight + (screenHeight - self.vwPopUp.frame.height) / 2
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = screenHeight
    }
    
    @IBAction func btnOkePressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
            
            // TODO: - Set main Address
        })
    }
    
    @IBAction func btnTidakPressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
        })
    }
}
