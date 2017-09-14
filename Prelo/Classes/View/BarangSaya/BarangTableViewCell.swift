//
//  BarangTableViewCell.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/13/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class BarangTableViewCell: UITableViewCell {
    @IBOutlet weak var sellPriceView: UIView!
    @IBOutlet weak var rentPriceView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func isNotForRent() {
    }
}
