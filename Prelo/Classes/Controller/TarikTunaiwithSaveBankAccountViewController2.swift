//
//  TarikTunaiwithSaveBankAccountViewController2.swift
//  Prelo
//
//  Created by Prelo (Chyntia) on 6/15/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class TarikTunaiwithSaveBankAccountViewController2: BaseViewController, PickerViewDelegate
{
    
    @IBOutlet weak var vwRek: UIView!
    @IBOutlet weak var vwNewRek: UIView!
    
    @IBOutlet weak var vwWithRekening: UIView!
    @IBOutlet weak var vwWithoutRekening: UIView!
    @IBOutlet weak var jmlPTop: NSLayoutConstraint!
    
    @IBOutlet weak var vwDropDown: UIView!
    @IBOutlet weak var lblDropDown: UILabel!
    
    var rekening: Array<RekeningItem> = []
    var rekeningUtama: RekeningItem? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // kalau udah punya rekening
        if(rekening.count != 0){
            vwWithoutRekening.isHidden = true
            vwWithRekening.isHidden = false
            // kalau mau buat baru
            //        vwNewRek.isHidden = false
            //        vwRek.isHidden = true
            //        jmlPTop.constant = 100
            // kalau udah ada
                    vwNewRek.isHidden = true
                    vwRek.isHidden = false
                    lblDropDown.text = (rekeningUtama?.target_bank)! + "/" + (rekeningUtama?.account_number)! + "/" + (rekeningUtama?.name)!
        } else {
            // kalau belum punya rekening
            
            vwWithoutRekening.isHidden = false
            vwWithRekening.isHidden = true
            jmlPTop.constant = 50
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getRekening()
        
        

    }
    
    
    func getRekening(){
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
                                if(arr[i]["is_default"]).boolValue{
                                    self.rekeningUtama = RekeningItem.instance(arr[i])!
                                }
                            }
                        }
                    }
                    self.viewDidLoad()
                }
                
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
   
    var item = ""
    var bankPickerItems : [String] = []
    
    @IBAction func btnDropDownPressed(_ sender: Any) {
        // Retrieve bankPickerItems
        bankPickerItems = []
        let _ = request(APIReference.getAllBank()).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Daftar Bank")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"].arrayValue
                if (data.count > 0) {
                    for i in 0...data.count - 1 {
                        self.bankPickerItems.append(data[i]["name"].stringValue + PickerViewController.TAG_START_HIDDEN + data[i]["_id"].stringValue + PickerViewController.TAG_END_HIDDEN)
                    }
                    
                    self.pickBank()
                }
            }
        }
    }
    func pickBank(){
        
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.bankMode = true
        p?.items = self.bankPickerItems
        p?.pickerDelegate = self
        p?.selectBlock = { string in
            self.item = PickerViewController.RevealHiddenString(string)
        }
        p?.showSearch = true
        p?.title = "Bank"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
    func pickerDidSelect(_ item: String) {
        self.lblDropDown.text = PickerViewController.HideHiddenString(item)
        
        
    }
    
}
// MARK: - class TarikTunaiCell

class TarikTunai2Cell: UITableViewCell {
    @IBOutlet weak var lblTiket: UILabel!
    @IBOutlet weak var lblTanggal: UILabel!
    @IBOutlet weak var lblPenarikan: UILabel!
    
}
