//
//  ListRekeningViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/26/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class ListRekeningViewController: BaseViewController {

    @IBOutlet var sectionOptions : Array<BorderedView> = []
    
    @IBOutlet var captionNorek : UILabel!
    @IBOutlet var captionCabang : UILabel!
    @IBOutlet var captionAtasNama : UILabel!
    @IBOutlet var captionName : UILabel!
    
    @IBOutlet var firstTap : UITapGestureRecognizer!
    
    var rekenings = [["name":"Lord Kumang", "no":"123187263", "cabang":"Sorong", "bank_name":"Bank BCA"], ["name":"Lord Atep", "no":"878346587", "cabang":"Bandung", "bank_name":"Bank Mandiri"], ["name":"Lord Bendtner", "no":"298172391", "cabang":"Aceh", "bank_name":"Bank BNI"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tapped(firstTap)
//        setupViewRekeing(rekenings[0])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapped(sender : UITapGestureRecognizer)
    {
        let b = sender.view as! BorderedView
        
        for x in sectionOptions
        {
            x.borderColor = Theme.GrayLight
            for v in x.subviews
            {
                if (v.isKindOfClass(TintedImageView.classForCoder()))
                {
                    let t = v as! TintedImageView
                    t.tint = true
                    t.tintColor = Theme.GrayLight
                }
            }
        }
        
        b.borderColor = Theme.PrimaryColor
        for v in b.subviews
        {
            if (v.isKindOfClass(TintedImageView.classForCoder()))
            {
                let t = v as! TintedImageView
                t.tint = false
            }
        }
        
        setupViewRekeing(rekenings[b.tag])
    }
    
    func setupViewRekeing(data : [String : String])
    {
        captionAtasNama.text = data["name"]
        captionCabang.text = data["cabang"]
        captionName.text = "Transfer melalui " + data["bank_name"]!
        captionNorek.text = data["no"]
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
