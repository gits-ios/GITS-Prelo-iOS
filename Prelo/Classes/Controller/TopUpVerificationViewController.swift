//
//  TopUpVerificationViewController.swift
//  Prelo
//
//  Created by Djuned on 9/11/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class TopUpVerificationViewController: BaseViewController {
    
    // Contact us view
    var contactUs : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Verifikasi Identitas"
    }
    
    @IBAction func btnVerifikasiPressed(_ sender: AnyObject) {
        
    }
    
    @IBAction func btnContactPreloPressed(_ sender: AnyObject) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let c = mainStoryboard.instantiateViewController(withIdentifier: "contactus")
        self.contactUs = c
        if let v = c.view, let p = self.navigationController?.view {
            v.alpha = 0
            v.frame = p.bounds
            self.navigationController?.view.addSubview(v)
            
            v.alpha = 0
            UIView.animate(withDuration: 0.2, animations: {
                v.alpha = 1
            })
        }
    }
}
