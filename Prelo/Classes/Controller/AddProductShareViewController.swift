//
//  AddProductShareViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/27/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class AddProductShareViewController: BaseViewController {
    
    @IBOutlet var arrayRow1 : [AddProductShareButton] = []
    @IBOutlet var arrayRow2 : [AddProductShareButton] = []
    @IBOutlet var arrayRow3 : [AddProductShareButton] = []
    @IBOutlet var arrayRow4 : [AddProductShareButton] = []
    
    var percentages = [3, 3, 2.5, 1.5]
    
    var arrayRows : [[AddProductShareButton]] = []
    
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var captionCharge : UILabel!
    @IBOutlet var captionChargePercent : UILabel!
    
    var chargePercent : Double = 10
    var basePrice = 925000
    
    var productID = ""
    
    @IBAction func setSelectShare(sender : AddProductShareButton)
    {
        let tag = sender.tag
        let arr = arrayRows[tag]
        let c = sender.active ? sender.normalColor : sender.selectedColor
        sender.active = !sender.active
        for b in arr
        {
            b.setTitleColor(c, forState: UIControlState.Normal)
            b.active = sender.active
        }
        
        let p = percentages[tag]
        chargePercent = chargePercent + (p * (sender.active ? -1 : 1))
        adaptCharge()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if (arrayRows.count == 0)
        {
            arrayRows.append(arrayRow1)
            arrayRows.append(arrayRow2)
            arrayRows.append(arrayRow3)
            arrayRows.append(arrayRow4)
        }
        
        adaptCharge()
    }
    
    var first = true
    
    var shouldSkipBack = true
    
    override func viewDidAppear(animated: Bool) {
        if first && shouldSkipBack
        {
            first = false
            super.viewDidAppear(animated)
            var m = self.navigationController?.viewControllers
            m?.removeAtIndex((m?.count)!-2)
            self.navigationController?.viewControllers = m!
        }
    }
    
    func adaptCharge()
    {
        captionChargePercent.text = Double(100 - chargePercent).roundString + " %"
        let charge = Double(basePrice) * chargePercent / 100
        captionCharge.text = "Charge Prelo " + Int(charge).asPrice + " (" + chargePercent.roundString + " %)"
        captionPrice.text = (basePrice - Int(charge)).asPrice
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func shareDone()
    {
        let b = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdMyProducts) as! UIViewController
        self.navigationController?.pushViewController(b, animated: true)
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

extension Double
{
    var roundString : String
    {
        if (self - Double(Int(self)) == 0) {
            return String(Int(self))
        } else
        {
            return String(stringInterpolationSegment: self)
        }
    }
}
