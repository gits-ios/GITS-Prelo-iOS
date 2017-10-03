//
//  CheckoutSewaDescriptionCell.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/19/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

protocol CheckoutSewaDescriptionDelegate{
    func durasiSewaClick()
}

class CheckoutSewaDescriptionCell: UITableViewCell {
    var delegate: CheckoutSewaDescriptionDelegate?
    
    @IBOutlet weak var durasiSewaLabel: UILabel!
    @IBOutlet weak var tanggalKembaliLabel: UILabel!
    @IBOutlet weak var hargaSewaLabel: UILabel!
    @IBOutlet weak var ongkosLabel: UILabel!
    @IBOutlet weak var depositLabel: UILabel!
    @IBOutlet weak var subtotalLabel: UILabel!

    @IBAction func durasiSewaClickAction(_ sender: UIButton) {
        self.delegate?.durasiSewaClick()
    }
}
