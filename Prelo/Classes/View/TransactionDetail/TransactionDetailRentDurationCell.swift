//
//  TransactionDetailRentDurationCell.swift
//  Prelo
//
//  Created by GITS INDONESIA on 10/19/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class TransactionDetailRentDurationCell: UITableViewCell {
    @IBOutlet weak var labelSentDate: UILabel!
    @IBOutlet weak var labelReceivedDate: UILabel!
    @IBOutlet weak var labelRentDuration: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func adapt(sentDate: String, receivedDate: String, rentDuration: String) {
        labelSentDate.text = sentDate
        labelReceivedDate.text = receivedDate
        labelRentDuration.text = rentDuration
    }
}
