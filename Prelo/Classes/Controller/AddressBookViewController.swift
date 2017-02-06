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
    var selectedIndexForSetAsMain: Int = 0
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let AddressBookCell = UINib(nibName: "AddressBookCell", bundle: nil)
        tableView.register(AddressBookCell, forCellReuseIdentifier: "AddressBookCell")
        
        let AddressBookNewCell = UINib(nibName: "AddressBookNewCell", bundle: nil)
        tableView.register(AddressBookNewCell, forCellReuseIdentifier: "AddressBookNewCell")
        
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
            let inset = UIEdgeInsetsMake(4, 0, 0, 0)
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
        
        for i in 0...2 {
            let fakeres = [
                "address_name":"coba-" + i.description,
                "recipient_name":"djuned",
                "address": "Jl kartini 44",
                "province_id": "533f81506d07364195779449", // jawa timur
                "region_id": "53a6e369490cd61d3a00001b", // kab kediri
                "subdistrict_id":"5758f2a1f8ec1c50289c78d5", // plemahan
                "subdistrict_name":"Plemahan",
                "phone": "087759035853",
                "postal_code": "64155",
                "is_main_address": i % 3 == 0
                ] as [String : Any]
            
            let json = JSON(fakeres)
            let address = AddressItem.instance(json)
            self.addresses?.append(address!)
        }
        
        self.hideLoading()
        
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
            return 204
        } else {
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath as NSIndexPath).item < (self.addresses?.count)!) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddressBookCell") as! AddressBookCell
            
            let idx = (indexPath as NSIndexPath).item
            
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor(hex: "E5E9EB")
            cell.clipsToBounds = true
            cell.adapt((addresses?[idx])!)
            
            cell.btnSetMainAction = {
                self.initPopUp()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    self.setupPopUp(idx)
                    self.displayPopUp()
                })
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddressBookNewCell") as! AddressBookNewCell
            
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor(hex: "E5E9EB")
            cell.clipsToBounds = true
            cell.adapt()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ((indexPath as NSIndexPath).item < (self.addresses?.count)!) {
            // do nothing
        } else {
            // new address - tambah alamat
        }
    }
    
    // MARK: - Pop up
    func setupPopUp(_ index: Int) {
        let desc = "Alamat Utama adalah alamat yang digunakan untuk menghitung biaya pengiriman barang jualan kamu."
        
        self.lblDescription.text = desc
        
        let attString : NSMutableAttributedString = NSMutableAttributedString(string: desc)
        attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 16)], range: (desc as NSString).range(of: "Alamat Utama"))
        
        self.lblDescription.attributedText = attString
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
            // by index
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


// MARK: - Class AddressBookCell
class AddressBookCell: UITableViewCell { // height 204
    @IBOutlet weak var lblType: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblRegion: UILabel! // subdistrict, region
    @IBOutlet weak var lblProvince: UILabel! // province postal_code
    @IBOutlet weak var lblPhone: UILabel!
    @IBOutlet weak var vwMain: UIView!
    @IBOutlet weak var btnSetMain: UIButton!
    
    var btnSetMainAction : () -> () = {}
    
    func adapt(_ address: AddressItem) {
        let regionName = CDRegion.getRegionNameWithID(address.regionId)
        let provinceName = CDProvince.getProvinceNameWithID(address.provinceId)
        
        lblType.text = address.addressName
        lblName.text = address.recipientName
        lblAddress.text = address.address
        lblRegion.text = address.subdisrictName + ", " + regionName!
        lblProvince.text = provinceName! + " " + address.postalCode
        lblPhone.text = address.phone
        
        if address.isMainAddress {
            vwMain.isHidden = false
            btnSetMain.isHidden = true
        } else {
            vwMain.isHidden = true
            btnSetMain.isHidden = false
        }
    }
    
    @IBAction func btnEditAddressPressed(_ sender: Any) {
    }
    
    @IBAction func btnDeleteAddressPressed(_ sender: Any) {
    }
    
    @IBAction func btnSetMainPressed(_ sender: Any) {
        btnSetMainAction()
    }
}


// MARK: - Class AddressBookNewCell
class AddressBookNewCell: UITableViewCell { // height 60
    @IBOutlet weak var vwPlus: UIView!
    
    func adapt() {
        self.vwPlus?.layoutIfNeeded()
        self.vwPlus?.layer.cornerRadius = (self.vwPlus?.width ?? 0) / 2
        self.vwPlus?.layer.masksToBounds = true
        
        self.vwPlus?.backgroundColor = UIColor(hex: "E5E9EB")
    }
    
}
