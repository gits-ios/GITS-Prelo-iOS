//
//  RekeningListViewController.swift
//  Prelo
//
//  Created by Prelo on 6/12/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class
class RekeningListViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    var rekening: Array<RekeningItem> = [] // rekeninglist
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
        
        let RekeningListCell = UINib(nibName: "RekeningListCell", bundle: nil)
        tableView.register(RekeningListCell, forCellReuseIdentifier: "RekeningListCell")
        
        let RekeningListNewCell = UINib(nibName: "RekeningListNewCell", bundle: nil)
        tableView.register(RekeningListNewCell, forCellReuseIdentifier: "RekeningListNewCell")
        
        self.title = "Daftar Rekening"
        
        
        
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
        
        getRekening()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Google Analytics
        //GAI.trackPageVisit(PageName.AddressBook)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getRekening(){
        self.showLoading()
        rekening = []
        // use API
        let _ = request(APIMe.getBankAccount).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Rekening List")) {
                if let x: AnyObject = resp.result.value as AnyObject? {
                    var json = JSON(x)
                    json = json["_data"]
//                    print("ini json rekening")
//                    print(json)
                    if let arr = json.array {
                        
                        if(arr.count != 0){
                            for i in 0 ..< arr.count {
//                                print("isi array")
//                                print(i)
//                                print(arr[i])
                                let rekening2 = RekeningItem.instance(arr[i])
                                print(arr[i]["target_bank"])
                                self.rekening.append(rekening2!)
                            }
                            self.tableView.reloadData()
                        }
                    }
                    self.hideLoading()
                }
                
            } else {
                self.hideLoading()
                _ = self.navigationController?.popViewController(animated: true)
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
        if ((indexPath as NSIndexPath).item < (rekening.count)) {
            return 123
        } else {
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath as NSIndexPath).item < (rekening.count)) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RekeningListCell") as! RekeningListCell
            
            let idx = (indexPath as NSIndexPath).item
            
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor(hex: "E5E9EB")
            cell.clipsToBounds = true
            
            cell.adapt(rekening[idx])
            cell.btnEditAction = {
            let EditRekeningVC = Bundle.main.loadNibNamed(Tags.XibNameRekeningAdd, owner: nil, options: nil)?.first as! RekeningAddViewController
                EditRekeningVC.editMode = true
                EditRekeningVC.rekening = self.rekening[idx]
                self.navigationController?.pushViewController(EditRekeningVC, animated: true)
            }

            cell.btnDeleteAction = {
                // delete
                let alertView = SCLAlertView(appearance: Constant.appearance)
                alertView.addButton("Ya") {
//                    print("ini yang mau di delete")
//                    print(self.rekening[idx].id)
                    // api delete
                    let _ = request(APIMe.deleteBankAccount(bankAccountId: (self.rekening[idx].id))).responseJSON { resp in
                        print("masuk sini sih")
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Hapus Rekening")) {
                            print("masuk sini sih2")
                            Constant.showDialog("Hapus Rekening", message: "Rekening berhasil dihapus")
                            self.rekening.remove(at: idx)
                            tableView.reloadData()
                        } else {
                            print("salah masuk")
                        }
                    }                }
                alertView.addButton("Batal", backgroundColor: Theme.ThemeOrange, textColor: UIColor.white, showDurationStatus: false) {}
                alertView.showCustom("Hapus Rekening", subTitle: "Apakah kamu yakin ingin menghapus rekening \"" + (self.rekening[idx].account_number) + "\"? (Aksi ini tidak dapat dibatalkan)", color: Theme.PrimaryColor, icon: SCLAlertViewStyleKit.imageOfInfo)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "RekeningListNewCell") as! RekeningListNewCell
            
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor(hex: "E5E9EB")
            cell.clipsToBounds = true
            cell.adapt()
            
            return cell
        }

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ((indexPath as NSIndexPath).item < (rekening.count)) {
            // do nothing
        } else {
            // new rekening - tambah alamat
            let AddRekeningVC = Bundle.main.loadNibNamed(Tags.XibNameRekeningAdd, owner: nil, options: nil)?.first as! RekeningAddViewController
            self.navigationController?.pushViewController(AddRekeningVC, animated: true)
        }

    }
    
    // MARK: - Pop up
    func setupPopUp(_ index: Int) {
        let desc = "Rekening Utama."
        
        self.lblDescription.text = desc
        
        let attString : NSMutableAttributedString = NSMutableAttributedString(string: desc)
        attString.addAttributes([NSFontAttributeName:UIFont.boldSystemFont(ofSize: 16)], range: (desc as NSString).range(of: "Rekening Utama"))
        
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
        let _ = request(APIMe.setDefaultBankAccount(bankAccountId: self.rekening[self.selectedIndexForSetAsMain].id)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Set Default Rekening")) {
                Constant.showDialog("Set Default Rekening", message: "Pergantian rekening.")
                
                self.getRekening()
                self.tableView.reloadData()
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

// MARK: - Class RekeningListCell
class RekeningListCell: UITableViewCell { // height 192
    
    @IBOutlet weak var lblBank: UILabel!
    @IBOutlet weak var lblRekening: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var vwMain: UIView!
    @IBOutlet weak var btnSetMain: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var btnEdit: UIButton!
    
    
    var rekening: RekeningItem!
    
    var btnEditAction : () -> () = {}
    var btnDeleteAction : () -> () = {}
    var btnSetMainAction : () -> () = {}
    
    func adapt(_ rekening: RekeningItem) {
        // set button
        let insetBtn = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        
        btnEdit.setImage(UIImage(named: "ic_edit_white"), for: .normal)
        btnEdit.imageView?.contentMode = .scaleAspectFit
        btnEdit.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        btnEdit.tintColor = UIColor.darkGray
    
        if(rekening.isDefaultBankAccount){
            btnDelete.isHidden = true
            btnSetMain.isHidden = true
            btnEdit.isHidden = false
            vwMain.isHidden = false
            consBtnDeleteLeading.constant = -32
        } else {
            btnDelete.isHidden = false
            btnSetMain.isHidden = false
            btnEdit.isHidden = false
            vwMain.isHidden = true
            consBtnDeleteLeading.constant = 2
        }
        btnDelete.setImage(UIImage(named: "ic_delete"), for: .normal)
        btnDelete.imageView?.contentMode = .scaleAspectFit
        btnDelete.imageEdgeInsets = insetBtn
        btnDelete.tintColor = UIColor.darkGray
        
        lblBank.text = rekening.target_bank
        lblName.text = rekening.name
        lblRekening.text = rekening.account_number
        
        
    }
    @IBOutlet weak var consBtnDeleteLeading: NSLayoutConstraint!
    
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
        
        
        // Save data
        if (m.saveSave() == false) {
            //print("Failed")
        } else {
            //print("Data saved")
        }
    }
    
}


// MARK: - Class RekeningListNewCell
class RekeningListNewCell: UITableViewCell { // height 50
    @IBOutlet weak var vwPlus: UIView!
    
    func adapt() {
        self.vwPlus?.layoutIfNeeded()
        self.vwPlus?.layer.cornerRadius = (self.vwPlus?.width ?? 0) / 2
        self.vwPlus?.layer.masksToBounds = true
        
        self.vwPlus?.backgroundColor = UIColor(hex: "E5E9EB")
    }
}
