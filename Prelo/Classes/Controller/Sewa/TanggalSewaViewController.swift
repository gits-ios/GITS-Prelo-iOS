//
//  TanggalSewaViewController.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/13/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class TanggalSewaViewController: UIViewController {
    @IBOutlet weak var calendarView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func lanjutClickAction(_ sender: Any) {
        self.performSegue(withIdentifier: "performSegueBarangSaya", sender: self)
    }
}
