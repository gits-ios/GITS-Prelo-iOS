//
//  CheckoutSewaPopupView.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/20/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class CheckoutSewaPopupView: UIView {
    @IBOutlet weak var dateStartLabel: UILabel!
    @IBOutlet weak var dateEndLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    func create(_ view: UIView){
        self.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        view.addSubview(self)
    }
    
    func destroy(){
        self.removeFromSuperview()
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        destroy()
    }
}
