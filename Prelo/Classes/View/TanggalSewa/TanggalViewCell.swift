//
//  TanggalViewCell.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/15/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import JTAppleCalendar

class TanggalViewCell: JTAppleCell {
    
    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var selectedView: UIView!
    @IBOutlet var startBufferView: UIView!
    @IBOutlet var finishBufferView: UIView!
    
    func configureDefaultView() {
        self.selectedView.isHidden = true
        self.startBufferView.isHidden = true
        self.finishBufferView.isHidden = true
        self.selectedView.layer.cornerRadius = self.frame.height / 2
        self.selectedView.layer.masksToBounds = true  // optional
    }
    
    func configureStartBufferView(isAtEndOfBuffer : Bool) {
        self.selectedView.backgroundColor = UIColor(hexString: "#147B8B")
        self.startBufferView.backgroundColor = UIColor(hexString: "#147B8B")
        self.finishBufferView.backgroundColor = UIColor(hexString: "#147B8B")
        self.dayLabel.textColor = UIColor.white
        if(isAtEndOfBuffer) {
            self.selectedView.isHidden = false
            self.startBufferView.isHidden = false
            self.finishBufferView.isHidden = true
        } else {
            self.selectedView.isHidden = false
            self.startBufferView.isHidden = false
            self.finishBufferView.isHidden = false
        }
    }
    
    func configureStartView() {
        self.selectedView.backgroundColor = UIColor(hexString: "#14988B")
        self.startBufferView.backgroundColor = UIColor(hexString: "#14988B")
        self.finishBufferView.backgroundColor = UIColor(hexString: "#14988B")
        self.dayLabel.textColor = UIColor.white
        self.selectedView.isHidden = false
        self.startBufferView.isHidden = false
        self.finishBufferView.isHidden = false
    }
    
    func configureRangeView() {
        self.selectedView.backgroundColor = UIColor(hexString: "#14988B")
        self.startBufferView.backgroundColor = UIColor(hexString: "#14988B")
        self.finishBufferView.backgroundColor = UIColor(hexString: "#14988B")
        self.dayLabel.textColor = UIColor.white
        self.selectedView.isHidden = false
        self.startBufferView.isHidden = false
        self.finishBufferView.isHidden = false
    }
    
    func configureFinishView() {
        self.selectedView.backgroundColor = UIColor(hexString: "#FD9809")
        self.startBufferView.backgroundColor = UIColor(hexString: "#FD9809")
        self.finishBufferView.backgroundColor = UIColor(hexString: "#FD9809")
        self.dayLabel.textColor = UIColor.white
        self.selectedView.isHidden = false
        self.startBufferView.isHidden = false
        self.finishBufferView.isHidden = false
    }
    
    func configureFinishBufferView(isAtEndOfBuffer : Bool) {
        self.selectedView.backgroundColor = UIColor(hexString: "#FD7B09")
        self.startBufferView.backgroundColor = UIColor(hexString: "#FD7B09")
        self.finishBufferView.backgroundColor = UIColor(hexString: "#FD7B09")
        self.dayLabel.textColor = UIColor.white
        if isAtEndOfBuffer {
            self.selectedView.isHidden = false
            self.startBufferView.isHidden = true
            self.finishBufferView.isHidden = false
        } else {
            self.selectedView.isHidden = false
            self.startBufferView.isHidden = false
            self.finishBufferView.isHidden = false
        }
    }
    
}
