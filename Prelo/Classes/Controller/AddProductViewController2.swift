//
//  AddProductViewController2.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class AddProductViewController2: BaseViewController, UIScrollViewDelegate, UITextViewDelegate
{

    @IBOutlet var txtName : SZTextView!
    @IBOutlet var conHeightTxtName : NSLayoutConstraint!
    var growerName : GrowingTextViewHandler?
    @IBOutlet var txtDescription : SZTextView!
    @IBOutlet var conHeightTxtDesc : NSLayoutConstraint!
    var growerDesc : GrowingTextViewHandler?
    
    @IBOutlet var scrollView : UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        txtName.placeholder = "Nama Produk"
        txtDescription.placeholder = "Deskripsi"
        
        growerName = GrowingTextViewHandler(textView: txtName, withHeightConstraint: conHeightTxtName)
        growerName?.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 4)
        
        growerDesc = GrowingTextViewHandler(textView: txtDescription, withHeightConstraint: conHeightTxtDesc)
        growerDesc?.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 100)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboardWithAnimations({ f, t, o in
            
            if (o)
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
                println("an_subscribeKeyboardWithAnimations")
                
            } else
            {
                self.scrollView.contentInset = UIEdgeInsetsZero
            }
            
            }, completion: {f in
                if let a = self.activeTextview
                {
                    let f = self.scrollView.convertRect(a.frame, fromView: a)
                    self.scrollView.scrollRectToVisible(f, animated: true)
                }
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.an_unsubscribeKeyboard()
    }
    
    var activeTextview : UITextView?
    func textViewDidBeginEditing(textView: UITextView) {
        println("textViewDidBeginEditing")
        activeTextview = textView
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        activeTextview = nil
    }
    
    func textViewDidChange(textView: UITextView) {
        growerName?.resizeTextViewWithAnimation(false)
        growerDesc?.resizeTextViewWithAnimation(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
