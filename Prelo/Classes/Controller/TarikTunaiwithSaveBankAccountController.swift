//
//  TarikTunaiwithSaveBankAccountController.swift
//  Prelo
//
//  Created by Prelo on 6/9/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Alamofire

class TarikTunaiwithSaveBankAccountController: BaseViewController, UIScrollViewDelegate, PickerViewDelegate{
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var jPenarikan: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Tarik Tunai"
        
        // kalau udah punya rekening
        // kalau rekening nya udah ada
        self.noRekening.isHidden = true
        let verticalSpace = NSLayoutConstraint(item: jPenarikan, attribute: .top, relatedBy: .equal, toItem: self.haveRekening, attribute: .bottom, multiplier: 1, constant: 3)
//        let distance = NSLayoutConstraint(item: haveRekening, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .bottom, multiplier: 1, constant: 100)

        view.addConstraints([verticalSpace])
        
        // kalau mau buat rekening baru
//        self.noRekening.height = 3000
        
        // kalau belum punya rekening
//        self.haveRekening.isHidden = true
        
    }
    @IBOutlet weak var noRekening: UIView!
    @IBOutlet weak var haveRekening: UIView!
    
    @IBAction func btnListBankPressed(_ sender: Any) {
        let p = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = ["BCA", "BNI", "Mandiri", "BRI"]
        p?.pickerDelegate = self
        p?.title = "Bank"
        self.view.endEditing(true)
        self.navigationController?.pushViewController(p!, animated: true)
    }
}
