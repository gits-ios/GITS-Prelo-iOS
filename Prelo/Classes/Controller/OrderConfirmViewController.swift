//
//  OrderConfirmViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/7/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class OrderConfirmViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UITextFieldDelegate {

    @IBOutlet var tableView : UITableView?
    
    var cellData : [NSIndexPath : BaseCartData] = [:]
    
    var orderID : String?
    
    let titleOrderID = "Order ID"
    let titleBankTujuan = "Bank Tujuan"
    let titleBankKamu = "Bank Kamu"
    let titleRekening = "Rekening Atas Nama"
    let titleNominal = "Nominal Transfer"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleText = self.title

        // Do any additional setup after loading the view.
        
        cellData[NSIndexPath(forRow: 0, inSection: 0)] = BaseCartData.instance(titleOrderID, placeHolder: "", value: orderID!, enable : false)
        cellData[NSIndexPath(forRow: 1, inSection: 0)] = BaseCartData.instance(titleBankTujuan, placeHolder: "", value: "", pickerPrepBlock: { picker in
            
            picker.items = ["Bank BCA", "Bank Mandiri", "Bank BNI"]
            picker.tableView.reloadData()
            
        })
        cellData[NSIndexPath(forRow: 2, inSection: 0)] = BaseCartData.instance(titleBankKamu, placeHolder: "Nama Bank Kamu")
        cellData[NSIndexPath(forRow: 3, inSection: 0)] = BaseCartData.instance(titleRekening, placeHolder: "Nama Rekening Kamu")
        cellData[NSIndexPath(forRow: 4, inSection: 0)] = BaseCartData.instance(titleNominal, placeHolder: "Nominal Transfer")
        
        tableView?.dataSource = self
        tableView?.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().track("Checkout Confirmation")
        
        let v = [self.navigationController?.viewControllers.first! as! UIViewController, self]
        self.navigationController?.setViewControllers(v, animated: false)
        
        self.an_subscribeKeyboardWithAnimations({ r, t, o in
            
            if (o) {
                self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
            } else {
                self.tableView?.contentInset = UIEdgeInsetsZero
            }
            
        }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellData.keys.array.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var c : UITableViewCell?
        var b : BaseCartCell
        let r = indexPath.row
        if (r == 1) {
            b = tableView.dequeueReusableCellWithIdentifier("cell_input_2") as! CartCellInput2
        } else {
            b = tableView.dequeueReusableCellWithIdentifier("cell_input") as! CartCellInput
        }
        
        if (b.lastIndex != nil) {
            cellData[b.lastIndex!] = b.obtainValue()
        }
        
        b.lastIndex = indexPath
        b.adapt(cellData[indexPath])
        b.parent = self
        
        c = b
        return c!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let c = tableView.cellForRowAtIndexPath(indexPath)
        if ((c?.canBecomeFirstResponder())!) {
            c?.becomeFirstResponder()
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        let i = tableView!.indexPathForCell((textField.superview?.superview!) as! UITableViewCell)
        var s = (i?.section)!
        var r = (i?.row)!
        
        var cell : UITableViewCell?
        
        var con = true
        while (con) {
            let newIndex = NSIndexPath(forRow: r+1, inSection: s)
            cell = tableView!.cellForRowAtIndexPath(newIndex)
            if (cell == nil) {
                s += 1
                r = -1
                if (s == tableView!.numberOfSections()) { // finish, last cell
                    con = false
                }
            } else {
                if ((cell?.canBecomeFirstResponder())!) {
                    cell?.becomeFirstResponder()
                    con = false
                } else {
                    r+=1
                }
            }
        }
        return true
    }
    
    @IBAction func sendConfirm()
    {
        self.navigationController?.popToRootViewControllerAnimated(true)
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
