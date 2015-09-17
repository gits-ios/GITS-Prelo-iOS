//
//  SearchViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class SearchViewController: BaseViewController, UIScrollViewDelegate, UITableViewDelegate
{
    
    @IBOutlet var txtSearch : UITextField!
    @IBOutlet var txtSearchWidth : NSLayoutConstraint!
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var tableView : UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)

        let t = UITextField(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width-52, 30))
        t.textColor = Theme.PrimaryColorDark
        t.borderStyle = UITextBorderStyle.None
        t.placeholder = "Cari"
        
        txtSearch = t
        
        self.navigationItem.rightBarButtonItem = t.toBarButton()
        
        // Do any additional setup after loading the view.
        UIView.animateWithDuration(0.2, animations: {
            self.navigationController?.navigationBar.tintColor = Theme.PrimaryColor
            self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        })
        
        scrollView.delegate = self
        tableView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    override func viewDidAppear(animated: Bool) {
        self.navigationController?.navigationBar.tintColor = Theme.PrimaryColor
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        txtSearch.becomeFirstResponder()
        
        self.an_subscribeKeyboardWithAnimations({f, t, o in
            
            if (o)
            {
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
            } else
            {
                self.tableView.contentInset = UIEdgeInsetsZero
                self.scrollView.contentInset = UIEdgeInsetsZero
            }
            
            }, completion: nil)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        UIView.animateWithDuration(0.2, animations: {
            self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
            self.navigationController?.navigationBar.barTintColor = Theme.PrimaryColor
        })
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
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
