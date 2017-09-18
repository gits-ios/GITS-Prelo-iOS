//
//  TanggalSewaViewController.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/13/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import JTAppleCalendar

class TanggalSewaViewController: UIViewController {
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    var iii: Date?
    let formatter = DateFormatter()
    var testCalendar = Calendar.current
    var isStartSelected: Bool = false
    var isFinishSelected: Bool = false
    var startDate: Date?
    var finishDate: Date?
    var startBuffer: Int = -3
    var finishBuffer: Int = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupCalendar()
        self.calendarView.visibleDates {[unowned self] (visibleDates: DateSegmentInfo) in
            self.setupViewsOfCalendar(from: visibleDates)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func lanjutClickAction(_ sender: Any) {
        self.performSegue(withIdentifier: "performSegueBarangSaya", sender: self)
    }
    
    func setupCalendar() {
        self.calendarView.minimumLineSpacing = 0
        self.calendarView.minimumInteritemSpacing = 0
        self.calendarView.sectionInset.top = 0
        self.calendarView.sectionInset.left = 0
        self.calendarView.sectionInset.right = 0
        self.calendarView.sectionInset.bottom = 0
        self.calendarView.allowsMultipleSelection = true
        self.calendarView.isRangeSelectionUsed = true
        self.calendarView.allowsDateCellStretching = true
        self.calendarView.scrollDirection = .vertical
        self.calendarView.scrollingMode = ScrollingMode.stopAtEachSection
        
        calendarView.register(UINib(nibName: "HeaderTanggalView", bundle: Bundle.main),
                              forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                              withReuseIdentifier: "HeaderTanggalView")
    }
    
    func setupViewsOfCalendar(from visibleDates: DateSegmentInfo) {
        guard let startDate = visibleDates.monthDates.first?.date else {
            return
        }
        let month = Calendar.current.dateComponents([.month], from: startDate).month!
        let monthName = DateFormatter().monthSymbols[(month-1) % 12]
        // 0 indexed array
        let year = Calendar.current.component(.year, from: startDate)
        //        monthLabel.text = monthName + " " + String(year)
    }
    
    func configureCell(view: JTAppleCell?, cellState: CellState, cellDate: Date) {
        guard let myCustomCell = view as? TanggalViewCell  else { return }
        
        
        //customize view each date cell
        myCustomCell.selectedView.layer.cornerRadius = myCustomCell.frame.height / 2
        myCustomCell.selectedView.layer.masksToBounds = true  // optional
        myCustomCell.dayLabel.text = cellState.text
        if cellState.dateBelongsTo == .thisMonth {
            myCustomCell.dayLabel.textColor = UIColor.black
        } else {
            //leftover date at beginning or end of the calendar's month section
            myCustomCell.dayLabel.textColor = UIColor.gray
        }
        if cellDate.dayFromWeekday() == "Sunday" {
            myCustomCell.backgroundColor = UIColor.lightGray
        } else {
            myCustomCell.backgroundColor = UIColor.white
        }
        
        
        //handle cell selection view status based on date selection status
        myCustomCell.isSelected = false
        myCustomCell.selectedView.isHidden = true
        if isStartSelected {
            if cellDate.isGreaterThanDate((startDate?.dateByAddingDays(startBuffer))!) &&
                //process buffer date of selected start date cell
                cellDate.isLessThanDate(startDate!) {
                myCustomCell.selectedView.isHidden = false
                myCustomCell.selectedView.backgroundColor = UIColor.blue
                myCustomCell.dayLabel.textColor = UIColor.white
            }
            else if cellDate.isSameDay(startDate!) {
                //selected start date cell
                myCustomCell.isSelected = true
                myCustomCell.selectedView.isHidden = false
                myCustomCell.selectedView.backgroundColor = UIColor.green
                myCustomCell.dayLabel.textColor = UIColor.white
            } else {
                if isFinishSelected {
                    if cellDate.isGreaterThanDate(startDate!) &&
                        cellDate.isLessThanDate(finishDate!) {
                        //start to finish range selected date cell
                        myCustomCell.selectedView.isHidden = false
                        myCustomCell.selectedView.backgroundColor = UIColor.green
                        myCustomCell.dayLabel.textColor = UIColor.white
                    }
                    else if cellDate.isSameDay(finishDate!) {
                        //selected finish date cell
                        myCustomCell.isSelected = true
                        myCustomCell.selectedView.isHidden = false
                        myCustomCell.selectedView.backgroundColor = UIColor.yellow
                        myCustomCell.dayLabel.textColor = UIColor.white
                    }
                    else if cellDate.isGreaterThanDate(finishDate!) &&
                        //process buffer date of selected finish date cell
                        cellDate.isLessThanDate((finishDate?.dateByAddingDays(finishBuffer))!) {
                        myCustomCell.selectedView.isHidden = false
                        myCustomCell.selectedView.backgroundColor = UIColor.red
                        myCustomCell.dayLabel.textColor = UIColor.white
                    }
                }
            }
        }
    }
}

extension TanggalSewaViewController: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        let startDate = formatter.date(from: "2017 01 01")!
        let endDate = formatter.date(from: "2030 02 01")!
        
        let parameters = ConfigurationParameters(startDate: startDate,
                                                 endDate: endDate,
                                                 numberOfRows: 5,
                                                 calendar: testCalendar,
                                                 generateInDates: .none,
                                                 generateOutDates: .off,
                                                 firstDayOfWeek: .monday,
                                                 hasStrictBoundaries: false)
        return parameters
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        configureCell(view: cell, cellState: cellState, cellDate: date)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "Cell", for: indexPath) as! TanggalViewCell
        configureCell(view: cell, cellState: cellState, cellDate: date)
        return cell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setupViewsOfCalendar(from: visibleDates)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        if !isStartSelected {
            isStartSelected = true
            startDate = date
        } else {
            if date.isLessThanDate(startDate!) {
                startDate = date
            } else {
                isFinishSelected = true
                finishDate = date
            }
        }
        
        calendar.reloadData()
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        if isStartSelected {
            if date.isSameDay(startDate!) {
                isStartSelected = false
                isFinishSelected = false
                startDate = nil
                finishDate = nil
            } else {
                if isFinishSelected {
                    if date.isSameDay(finishDate!) {
                        isFinishSelected = false
                        finishDate = nil
                    }
                }
            }
        }
        
        calendar.reloadData()
    }
    
    // This sets the height of your header
    func calendarSizeForMonths(_ calendar: JTAppleCalendarView?) -> MonthSize? {
        return MonthSize(defaultSize: 32)
    }
    
    // This setups the display of your header
    func calendar(_ calendar: JTAppleCalendarView, headerViewForDateRange range: (start: Date, end: Date), at indexPath: IndexPath) -> JTAppleCollectionReusableView {
        formatter.dateFormat = "MMMM"
        let date = range.start
        let month = formatter.string(from: date)
        let header: JTAppleCollectionReusableView
        header = calendar.dequeueReusableJTAppleSupplementaryView(withReuseIdentifier: "HeaderTanggalView", for: indexPath)
        (header as! HeaderTanggalView).headerLabel.text = month
        return header
    }
}
