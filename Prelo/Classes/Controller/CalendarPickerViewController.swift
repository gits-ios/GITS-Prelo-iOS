//
//  CalendarPickerViewController.swift
//  Prelo
//
//  Created by Djuned on 8/11/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class CalendarPickerViewController: BaseViewController {
    @IBOutlet weak var calendar: FSCalendar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.calendar.delegate = self
        self.calendar.dataSource = self
        
        self.calendar.allowsMultipleSelection = true
        //self.calendar.pagingEnabled = false // continue view
        self.calendar.swipeToChooseGesture.isEnabled = true
        self.calendar.firstWeekday = 2 // senin
        self.calendar.appearance.titleWeekendColor = UIColor.red
        //self.calendar.today = nil // Hide the today circle
        
        self.title = "Pilih Tanggal"
    }
}

extension CalendarPickerViewController: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        //self.view.layoutIfNeeded()
    }
}
