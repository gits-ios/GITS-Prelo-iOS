//
//  AddressBookViewController.swift
//  Prelo
//
//  Created by Djuned on 2/6/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
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

    // fpop up
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
            
            // Setup table
            tableView.dataSource = self
            tableView.delegate = self
            tableView.tableFooterView = UIView()
            
            //TOP, LEFT, BOTTOM, RIGHT
            let inset = UIEdgeInsetsMake(4, 0, 0, 0)
            tableView.contentInset = inset
            
            tableView.separatorStyle = .none
            
            tableView.backgroundColor = UIColor(hex: "E5E9EB")
        }
        
        getAddresses()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.AddressBook)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getAddresses() {
        showLoading()
        
        addresses = []
        
//        for i in 0...2 {
//            let fakeres = [
//                "address_name":"coba-" + i.description,
//                "owner_name":"djuned",
//                "address": "Jl kartini 44",
//                "province_id": "533f81506d07364195779449", // jawa timur
//                "region_id": "53a6e369490cd61d3a00001b", // kab kediri
//                "subdistrict_id":"5758f2a1f8ec1c50289c78d5", // plemahan
//                "subdistrict_name":"Plemahan",
//                "phone": "087759035853",
//                "postal_code": "64155",
//                "is_default": i % 3 == 0
//                ] as [String : Any]
//            
//            let json = JSON(fakeres)
//            let address = AddressItem.instance(json)
//            self.addresses?.append(address!)
//        }
//        
//        self.hideLoading()
        
        // TODO: - use API
        // use API
        let _ = request(APIMe.getAddressBook).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Address Book")) {
                if let x: AnyObject = resp.result.value as AnyObject? {
                    var json = JSON(x)
                    json = json["_data"]
                    
                    if let arr = json.array {
                        for i in 0...arr.count - 1 {
                            let address = AddressItem.instance(arr[i])
                            self.addresses?.append(address!)
                        }
                    }
                    
                    self.tableView.reloadData()
                    self.hideLoading()
                }
                
            } else {
                
                self.hideLoading()
                self.navigationController?.popViewController(animated: true)
            }
        }
        
    }
    
    
    // MARK: - Other
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    // MARK: - Tableview delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ((indexPath as NSIndexPath).item < (self.addresses?.count)!) {
            return 192
        } else {
            return 50
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
            
            cell.btnEditAction = {
                let EditAddressVC = Bundle.main.loadNibNamed(Tags.XibNameAddressAddEdit, owner: nil, options: nil)?.first as! AddressAddEditViewController
                EditAddressVC.editMode = true
                EditAddressVC.address = self.addresses?[idx]
                self.navigationController?.pushViewController(EditAddressVC, animated: true)
            }
            
            cell.btnDeleteAction = {
                // delete
                
                let alert : UIAlertController = UIAlertController(title: "Hapus Alamat", message: "Apakah kamu yakin ingin menghapus alamat \"" + (self.addresses?[idx].addressName)! + "\"? (Aksi ini tidak dapat dibatalkan)", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Ya", style: .default, handler: { action in
                    // api delete
                    let _ = request(APIMe.deleteAddress(addressId: (self.addresses?[idx].id)!)).responseJSON { resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hapus Alamat")) {
                            Constant.showDialog("Hapus Alamat", message: "Alamat berhasil dihapus")
                            self.addresses?.remove(at: idx)
                            tableView.reloadData()
                        }
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
            cell.btnSetMainAction = {
                self.initPopUp()
                
                self.selectedIndexForSetAsMain = idx
                
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
            let AddAddressVC = Bundle.main.loadNibNamed(Tags.XibNameAddressAddEdit, owner: nil, options: nil)?.first as! AddressAddEditViewController
            self.navigationController?.pushViewController(AddAddressVC, animated: true)
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
        
        // api set default
        let _ = request(APIMe.setDefaultAddress(addressId: (self.addresses?[self.selectedIndexForSetAsMain].id)!)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Set Default Alamat")) {
                Constant.showDialog("Set Default Alamat", message: "Pergantian alamat ini akan berpengaruh kepada hasil pencarian barang kamu berdasarkan lokasi.")
                
                self.getAddresses()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.vwOverlayPopUp.isHidden = true
            self.vwBackgroundOverlay.isHidden = true
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
class AddressBookCell: UITableViewCell { // height 192
    @IBOutlet weak var lblType: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblRegion: UILabel! // subdistrict, region
    @IBOutlet weak var lblProvince: UILabel! // province postal_code
    @IBOutlet weak var lblPhone: UILabel!
    @IBOutlet weak var vwMain: UIView!
    @IBOutlet weak var btnSetMain: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    
    var address: AddressItem!
    
    var btnEditAction : () -> () = {}
    var btnDeleteAction : () -> () = {}
    var btnSetMainAction : () -> () = {}
    
    func adapt(_ address: AddressItem) {
        self.address = address
        
        let regionName = CDRegion.getRegionNameWithID(address.regionId)
        let provinceName = CDProvince.getProvinceNameWithID(address.provinceId)
        
        lblType.text = address.addressName
        lblName.text = address.recipientName
        if address.address == "" {
            lblAddress.text = "- (belum ada jalan)"
            lblAddress.font = UIFont.italicSystemFont(ofSize: 14)
            lblAddress.textColor = UIColor.lightGray
        } else {
            lblAddress.text = address.address
            lblAddress.font = UIFont.systemFont(ofSize: 14)
            lblAddress.textColor = UIColor.darkGray
        }
        lblRegion.text = address.subdisrictName + ", " + regionName!
        lblProvince.text = provinceName! + " " + address.postalCode
        lblPhone.text = address.phone
        
        if address.isMainAddress {
            vwMain.isHidden = false
            btnSetMain.isHidden = true
            btnDelete.isHidden = true
            //btnDelete.isEnabled = false
            //btnDelete.setTitleColor(UIColor.lightGray)
        } else {
            vwMain.isHidden = true
            btnSetMain.isHidden = false
            btnDelete.isHidden = false
            //btnDelete.isEnabled = true
            //btnDelete.setTitleColor(UIColor.darkGray)
        }
    }
    
    @IBAction func btnEditAddressPressed(_ sender: Any) {
        btnEditAction()
    }
    
    @IBAction func btnDeleteAddressPressed(_ sender: Any) {
        btnDeleteAction()
    }
    
    @IBAction func btnSetMainPressed(_ sender: Any) {
        setupProfile()
        btnSetMainAction()
    }
    
    // MARK: - Update user Profile
    func setupProfile() {
        let m = UIApplication.appDelegate.managedObjectContext
        
        if let userProfile = CDUserProfile.getOne() {
            userProfile.address = address.address
            userProfile.postalCode = address.postalCode
            userProfile.regionID = address.regionId
            userProfile.provinceID = address.provinceId
            userProfile.subdistrictID = address.subdisrictId
            userProfile.subdistrictName = address.subdisrictName
            userProfile.addressName = address.addressName
            userProfile.recipientName = address.recipientName
        }
        
        // Save data
        if (m.saveSave() == false) {
            print("Failed")
        } else {
            print("Data saved")
        }
    }

}


// MARK: - Class AddressBookNewCell
class AddressBookNewCell: UITableViewCell { // height 50
    @IBOutlet weak var vwPlus: UIView!
    
    func adapt() {
        self.vwPlus?.layoutIfNeeded()
        self.vwPlus?.layer.cornerRadius = (self.vwPlus?.width ?? 0) / 2
        self.vwPlus?.layer.masksToBounds = true
        
        self.vwPlus?.backgroundColor = UIColor(hex: "E5E9EB")
    }
    
}
