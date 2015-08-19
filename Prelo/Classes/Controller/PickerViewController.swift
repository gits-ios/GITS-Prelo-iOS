//
//  PickerViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/3/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

@objc protocol PickerViewDelegate
{
    optional func pickerDidSelect(item : String)
}

typealias PrepDataBlock = (picker : PickerViewController) -> ()
typealias PickerSelectBlock = (item : String) -> ()

class PickerViewController: UITableViewController {

    static let TAG_START_HIDDEN = "œ"
    static let TAG_END_HIDDEN = "∑"
    
    static func HideHiddenString(string : String) -> String
    {
        var sf = AppToolsObjC.stringByHideTextBetween(PickerViewController.TAG_START_HIDDEN, and: PickerViewController.TAG_END_HIDDEN, from: string)
        
        sf = sf.stringByReplacingOccurrencesOfString(PickerViewController.TAG_START_HIDDEN, withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        sf = sf.stringByReplacingOccurrencesOfString(PickerViewController.TAG_END_HIDDEN, withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        
        return sf
    }
    
    static func RevealHiddenString(string : String) -> String
    {
        let text = PickerViewController.HideHiddenString(string)
        var sf = string.stringByReplacingOccurrencesOfString(text, withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        sf = sf.stringByReplacingOccurrencesOfString(PickerViewController.TAG_START_HIDDEN, withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        sf = sf.stringByReplacingOccurrencesOfString(PickerViewController.TAG_END_HIDDEN, withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        return sf
    }
    
    var items : Array<String>?
    var pickerDelegate : PickerViewDelegate?
    
    var prepDataBlock : PrepDataBlock?
    var selectBlock : PickerSelectBlock?
    
    var textTitle : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableFooterView = UIView()
        
        if (prepDataBlock != nil) {
            startLoading()
            prepDataBlock!(picker: self)
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (items?.count)!
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell") as? UITableViewCell
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
        }
        
        let raw = items?.objectAtCircleIndex(indexPath.row)
        let s = PickerViewController.HideHiddenString(raw!)
        
        cell?.textLabel?.text = s
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (selectBlock != nil) {
            selectBlock!(item: (items?.objectAtCircleIndex(indexPath.row))!)
        }
        
        
        if (pickerDelegate != nil) {
            pickerDelegate?.pickerDidSelect!((items?.objectAtCircleIndex(indexPath.row))!)
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func startLoading()
    {
        self.textTitle = self.title
        self.navigationItem.titleView = BaseViewController.TitleLabel("Loading..")
    }
    
    func doneLoading()
    {
        self.navigationItem.titleView = BaseViewController.TitleLabel(textTitle!)
    }
    
    func dismiss()
    {
        if (self.navigationController != nil) {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
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
