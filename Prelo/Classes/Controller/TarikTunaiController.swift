//
//  TarikTunaiController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class TarikTunaiController: BaseViewController {
    
    @IBOutlet var txtNamaBank : UITextField!
    @IBOutlet var txtNomerRekening : UITextField!
    @IBOutlet var txtNamaRekening : UITextField!
    @IBOutlet var txtPassword : UITextField!
    @IBOutlet var txtJumlah : UITextField!
    
    @IBOutlet var captionPreloBalance : UILabel!
    @IBOutlet var scrollView : UIScrollView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.an_subscribeKeyboardWithAnimations({ f, i , o in
            
            if (o)
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
            } else
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
            
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.an_unsubscribeKeyboard()
    }
}
