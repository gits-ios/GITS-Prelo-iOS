//
//  TanggalTersewaViewController.swift
//  Prelo
//
//  Created by GITS INDONESIA on 10/17/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import JTAppleCalendar
import Alamofire

class TanggalTersewaViewController: BaseViewController {
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    @IBOutlet weak var loadingPanel: UIView!
    
    var iii: Date?
    let formatter = DateFormatter()
    var testCalendar = Calendar.current
    var systemStartDate: Date?
    var systemFinishDate: Date?
    var startDate: Date?
    var finishDate: Date?
    var isStartSelected: Bool = false
    var isFinishSelected: Bool = false
    var thisScreen: String!
    var productId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupCalendar()
        // Do any additional setup after loading the view.
        
        self.thisScreen = PageName.TanggalTersewa
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tandaiBarangAction(_ sender: Any) {
        if isStartSelected && isFinishSelected {
            if self.productId != nil || self.productId != "" {
                self.loadingPanel.isHidden = false
                formatter.dateFormat = "YYYY-MM-DD"
                let _ = request(APIProduct.markAsRent(productId: self.productId, endTime: formatter.string(from: finishDate!))).responseJSON { resp in
                    if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Mark As Rent")) {
                        let json = JSON(resp.result.value!)
                        let isSuccess = json["_data"].boolValue
                        
                        if isSuccess {
                            Constant.showDialog("Perhatian", message: "Barang telah berhasil ditandai tersewa")
                            self.loadingPanel.isHidden = true
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            Constant.showDialog("Perhatian", message: "Terjadi kesalahan, mohon coba kembali")
                            self.loadingPanel.isHidden = true
                        }
                    }
                    self.loadingPanel.isHidden = true
                }
            } else {
                Constant.showDialog("Perhatian", message: "Terjadi kesalahan, mohon coba kembali")
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            Constant.showDialog("Perhatian", message: "Mohon pilih tanggal barang tersewa terlebih dahulu")
        }
    }
    
    func setupCalendar() {
        self.calendarView.minimumLineSpacing = 0
        self.calendarView.minimumInteritemSpacing = 0
        self.calendarView.sectionInset.top = 1
        self.calendarView.sectionInset.left = 0
        self.calendarView.sectionInset.right = 0
        self.calendarView.sectionInset.bottom = 1
        self.calendarView.allowsMultipleSelection = true
        self.calendarView.isRangeSelectionUsed = true
        self.calendarView.allowsDateCellStretching = true
        self.calendarView.scrollDirection = .vertical
        self.calendarView.scrollingMode = ScrollingMode.none
        
        calendarView.register(UINib(nibName: "HeaderTanggalView", bundle: Bundle.main),
                              forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                              withReuseIdentifier: "HeaderTanggalView")
    }
    
    func configureCell(view: JTAppleCell?, cellState: CellState, cellDate: Date) {
        guard let myCustomCell = view as? TanggalViewCell  else { return }
        
        //customize view each date cell
        myCustomCell.dayLabel.text = cellState.text
        if cellState.dateBelongsTo == .thisMonth {
            if cellState.date.isLessThanDate(Date()) {
                myCustomCell.dayLabel.textColor = UIColor.lightGray
            } else {
                myCustomCell.dayLabel.textColor = UIColor.darkGray
            }
        } else {
            //leftover date at beginning or end of the calendar's month section
            myCustomCell.dayLabel.textColor = UIColor.lightGray
        }
        if cellDate.dayFromWeekday() == "Sunday" {
            myCustomCell.backgroundColor = UIColor(hexString: "#EBEBF1")
        } else {
            myCustomCell.backgroundColor = UIColor.white
        }
        
        //handle cell selection view status based on date selection status
        myCustomCell.configureDefaultView()
        
        if cellState.dateBelongsTo == .thisMonth {
            if isStartSelected && !isFinishSelected {
                if cellDate.isSameDay(startDate!) {
                    //configure single selection date
                    myCustomCell.configureSingleSelectionView()
                }
            } else if isStartSelected && isFinishSelected {
                if cellDate.isSameDay(startDate!) {
                    //configure start range selection date
                    myCustomCell.configureStartSelectionView()
                } else if cellDate.isGreaterThanDate(startDate!) &&
                    cellDate.isLessThanDate(finishDate!) {
                    //configure range selection date
                    myCustomCell.configureRangeSelectionView()
                } else if cellDate.isSameDay(finishDate!) {
                    //configure finish range selection date
                    myCustomCell.configureFinishSelectionView()
                }
            }
        }
    }
}

extension TanggalTersewaViewController: JTAppleCalendarViewDataSource, JTAppleCalendarViewDelegate {
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        //        self.systemStartDate = formatter.date(from: "2017 01 01")!
        self.systemStartDate = Date()
        self.systemFinishDate = systemStartDate?.dateByAddingDays(365)
        
        let parameters = ConfigurationParameters(startDate: self.systemStartDate!,
                                                 endDate: self.systemFinishDate!,
                                                 numberOfRows: 5,
                                                 calendar: testCalendar,
                                                 generateInDates: .none,
                                                 generateOutDates: .off,
                                                 firstDayOfWeek: .monday,
                                                 hasStrictBoundaries: true)
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
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        //override select & deselect cell function
        if date.isLessThanDate(Date()) {
            Constant.showDialog("Perhatian", message: "Tidak dapat memilih tanggal penyewaan sebelum hari ini")
        } else {
            handleCalendarDateSelection(selectedDate: date)
        }
    }
    
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        //override select & deselect cell function
        if date.isLessThanDate(Date()) {
            Constant.showDialog("Perhatian", message: "Tidak dapat memilih tanggal penyewaan sebelum hari ini")
        } else {
            handleCalendarDateSelection(selectedDate: date)
        }
    }
    
    func handleCalendarDateSelection(selectedDate : Date)  {
        if !isStartSelected && !isFinishSelected {
            //select start date
            isStartSelected = true
            isFinishSelected = false
            startDate = selectedDate
            finishDate = nil
        } else if isStartSelected && !isFinishSelected {
            if selectedDate.isGreaterThanDate(startDate!) {
                //select finish date
                isStartSelected = true
                isFinishSelected = true
                finishDate = selectedDate
            } else {
                //reset date selection
                isStartSelected = true
                isFinishSelected = false
                startDate = selectedDate
                finishDate = nil
            }
        } else if isStartSelected && isFinishSelected {
            //reset date selection
            isStartSelected = true
            isFinishSelected = false
            startDate = selectedDate
            finishDate = nil
        }
        
        self.calendarView.reloadData()
    }
    
    // This sets the height of your header
    func calendarSizeForMonths(_ calendar: JTAppleCalendarView?) -> MonthSize? {
        return MonthSize(defaultSize: 40)
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
