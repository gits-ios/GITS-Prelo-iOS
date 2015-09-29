//
//  TarikTunaiController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class TarikTunaiController: BaseViewController, UIScrollViewDelegate
{
    
    @IBOutlet var txtNamaBank : UITextField!
    @IBOutlet var txtNomerRekening : UITextField!
    @IBOutlet var txtNamaRekening : UITextField!
    @IBOutlet var txtPassword : UITextField!
    @IBOutlet var txtJumlah : UITextField!
    
    @IBOutlet var captionPreloBalance : UILabel!
    @IBOutlet var scrollView : UIScrollView!
    
    @IBOutlet var btnWithdraw : UIButton!
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Tarik Uang"
        
        scrollView.delegate = self
        
        captionPreloBalance.text = "0"
        
        txtNamaBank.textAlignment = NSTextAlignment.Right
        txtNomerRekening.textAlignment = NSTextAlignment.Right
        
        getBalance()
    }
    
    func getBalance()
    {
        request(APIWallet.GetBalance).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                let json = JSON(res!)
                if let i = json["_data"].int
                {
                    let f = NSNumberFormatter()
                    f.numberStyle = NSNumberFormatterStyle.CurrencyStyle
                    f.currencySymbol = ""
                    f.locale = NSLocale(localeIdentifier: "id_ID")
                    self.captionPreloBalance.text = f.stringFromNumber(NSNumber(integer: i))
                }
            } else
            {
                self.navigationController?.popViewControllerAnimated(true)
            }
            
        }
    }
    
    @IBAction func withdraw()
    {
        let amount = txtJumlah.text
        let namaBank = txtNamaBank.text
        let norek = txtNomerRekening.text
        let namarek = txtNamaRekening.text
        let pass = txtPassword.text
        
        self.btnWithdraw.enabled = false
        
        request(APIWallet.Withdraw(amount: amount, targetBank: namaBank, norek: norek, namarek: namarek, password: pass)).responseJSON { req, resp, res, err in
            self.btnWithdraw.enabled = true
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                let json = JSON(res!)
                if let message = json["_message"].string
                {
                    UIAlertView.SimpleShow("Perhatian", message: message)
                } else
                {
                    self.getBalance()
                }
            } else
            {
                
            }
            
        }
    }
}
