//
//  RekeningAddViewController.swift
//  Prelo
//
//  Created by Prelo on 6/12/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Class

class RekeningAddViewController: BaseViewController, PickerViewDelegate, UITextFieldDelegate {
    // MARK: - Properties
    
    @IBOutlet weak var txtRekening: UITextField!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtCabang: UITextField!
    @IBOutlet weak var btnAction: UIButton! // Edit / Tambah Alamat
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var editMode: Bool = false
    var rekening: RekeningItem?

    var isFirst: Bool = true
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.an_subscribeKeyboard(animations: { f, i , o in
            
            if (o)
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
            } else
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
            
        }, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.title = "Tambah Rekening"
                self.btnAction.setTitle("TAMBAH Rekening", for: .normal)
                
                self.hideLoading()
        
    }
    
    func getAddress() {
        // load from API
        
        self.hideLoading()
    }
    
    
    // submit --> add / edit
    @IBAction func btnActionPressed(_ sender: Any) {
        
    }
    
    // MARK: - Other
    func showLoading() {
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    
}
