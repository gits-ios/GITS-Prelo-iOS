//
//  ListRekeningViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/26/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class ListRekeningViewController: BaseViewController {

    @IBOutlet var sectionOptions : Array<BorderedView> = []
    
    @IBOutlet var captionNorek : UILabel!
    @IBOutlet var captionCabang : UILabel!
    @IBOutlet var captionAtasNama : UILabel!
    @IBOutlet var captionName : UILabel!
    
    @IBOutlet var firstTap : UITapGestureRecognizer!
    
    var rekenings = [
        ["name":"Fransiska PutriWinaHadiwidjana", "no":"06-404-72-677", "cabang":"Pucang Anom", "bank_name":"Bank BCA"],
        ["name":"Fransiska Putri Wina Hadiwidjana", "no":"131-007-304-1990", "cabang":"Cab. Bandung Dago", "bank_name":"Bank Mandiri"],
        ["name":"Fransiska Putri Wina Hadiwidjana", "no":"037-351-4488", "cabang":"Cab. Perguruan Tinggi Bandung", "bank_name":"Bank BNI"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tapped(firstTap)
    }
    
    var first = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapped(_ sender : UITapGestureRecognizer)
    {
        let b = sender.view as! BorderedView
        
        for x in sectionOptions
        {
            x.borderColor = Theme.GrayLight
            for v in x.subviews
            {
                if (v.isKind(of: TintedImageView.classForCoder()))
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
            if (v.isKind(of: TintedImageView.classForCoder()))
            {
                let t = v as! TintedImageView
                t.tint = false
            }
        }
        
        setupViewRekeing(rekenings[b.tag])
    }
    
    func setupViewRekeing(_ data : [String : String])
    {
        captionAtasNama.text = data["name"]
        captionCabang.text = data["cabang"]
        captionName.text = "Transfer melalui " + data["bank_name"]!
        captionNorek.text = data["no"]
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
    }

}
