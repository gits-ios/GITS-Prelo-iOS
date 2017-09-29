//
//  TanggalSewaViewController.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/13/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import JTAppleCalendar

class TanggalSewaViewController: BaseViewController {
    @IBOutlet var startDayLabel: UILabel!
    @IBOutlet var startDateLabel: UILabel!
    @IBOutlet var finishDayLabel: UILabel!
    @IBOutlet var finishDateLabel: UILabel!
    @IBOutlet var totalDayLabel: UILabel!
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    @IBOutlet var checkboxButton: UIButton!
    @IBOutlet var termAgreementLabel: UILabel!
    
    var iii: Date?
    let formatter = DateFormatter()
    var testCalendar = Calendar.current
    var isCheckboxAgreed: Bool = false
    var isStartSelected: Bool = false
    var isStartFinishAtSameDay: Bool = false
    var isFinishSelected: Bool = false
    var systemStartDate: Date?
    var systemFinishDate: Date?
    var startDate: Date?
    var finishDate: Date?
    var startBuffer: Int = 1
    var finishBuffer: Int = 1
    var startDateOpenDayRange: Int = 30
    
    var thisScreen: String!
    
    //from product detail for checkout
    var productID = ""
    var sellerId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.termAgreementLabel.colorString(text: "Saya setuju untuk mengembalikan barang pada akhir masa sewa sesuai dengan Syarat dan Ketentuan Prelo", coloredText: "Syarat dan Ketentuan Prelo")
        self.setupCalendar()
        
        self.thisScreen = PageName.TanggalSewa
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func termAgreementClickAction(_ sender: UIButton) {
        // Open web view
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let helpVC = mainStoryboard.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
        
        helpVC.url = "https://prelo.co.id/syarat-ketentuan"
        helpVC.titleString = title ?? "Syarat dan Ketentuan"
        helpVC.contactPreloMode = true
        let baseNavC = BaseNavigationController()
        baseNavC.setViewControllers([helpVC], animated: false)
        
        self.present(baseNavC, animated: true, completion: nil)
    }
    
    @IBAction func lanjutClickAction(_ sender: Any) {
        if isStartFinishAtSameDay || isFinishSelected {
            if !isCheckboxAgreed {
                Constant.showDialog("Perhatian", message: "Kamu belum menyetujui syarat dan ketentuan Prelo")
            } else {
                let checkout2VC = Bundle.main.loadNibNamed(Tags.XibNameCheckout2, owner: nil, options: nil)?.first as! Checkout2ViewController
                formatter.dateFormat = "yyyy-MM-dd"
                checkout2VC.isSewaProduct = true
                checkout2VC.start_date = formatter.string(from: startDate!)
                checkout2VC.buffer_start_date = formatter.string(from: (startDate?.dateByAddingDays(-startBuffer))!)
                if isStartFinishAtSameDay {
                    checkout2VC.end_date = formatter.string(from: startDate!)
                    checkout2VC.buffer_end_date = formatter.string(from: (startDate?.dateByAddingDays(finishBuffer))!)
                } else {
                    checkout2VC.end_date = formatter.string(from: finishDate!)
                    checkout2VC.buffer_end_date = formatter.string(from: (finishDate?.dateByAddingDays(finishBuffer))!)
                }
                checkout2VC.seller_id = sellerId
                checkout2VC.product_id = productID
                checkout2VC.previousController = self
                checkout2VC.previousScreen = thisScreen
                self.navigationController?.pushViewController(checkout2VC, animated: true)
            }
        } else {
            Constant.showDialog("Perhatian", message: "Mohon pilih tanggal penyewaan terlebih dahulu")
        }
    }
    
    @IBAction func checkboxClickAction(_ sender: UIButton) {
        if isCheckboxAgreed {
            self.isCheckboxAgreed = false
            self.checkboxButton.setBackgroundImage(UIImage(named: "uncheckedbox"), for: .normal)
        } else {
            self.isCheckboxAgreed = true
            self.checkboxButton.setBackgroundImage(UIImage(named: "checkedbox"), for: .normal)
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
    
    func convertDayNameEnglishToIndonesia(date: Date) -> String{
        switch date.dayFromWeekday(){
        case "Monday" :
            return "SENIN"
        case "Tuesday" :
            return "SELASA"
        case "Wednesday" :
            return "RABU"
        case "Thursday" :
            return "KAMIS"
        case "Friday" :
            return "JUMAT"
        case "Saturday" :
            return "SABTU"
        default:
            return "MINGGU"
        }
    }
    
    func configureMenuView() {
        formatter.dateFormat = "dd MMM"
        if isStartSelected {
            self.startDayLabel.text = convertDayNameEnglishToIndonesia(date: startDate!)
            self.startDayLabel.textColor = UIColor.darkGray
            self.startDateLabel.text = formatter.string(from: startDate!).uppercased()
            self.startDateLabel.textColor = UIColor.darkGray
        } else {
            self.startDayLabel.text = "TANGGAL"
            self.startDayLabel.textColor = UIColor.gray
            self.startDateLabel.text = "MULAI"
            self.startDateLabel.textColor = UIColor.gray
        }
        
        if isStartFinishAtSameDay {
            self.finishDayLabel.text = convertDayNameEnglishToIndonesia(date: startDate!)
            self.finishDayLabel.textColor = UIColor.darkGray
            self.finishDateLabel.text = formatter.string(from: startDate!).uppercased()
            self.finishDateLabel.textColor = UIColor.darkGray
        } else if isFinishSelected {
            self.finishDayLabel.text = convertDayNameEnglishToIndonesia(date: finishDate!)
            self.finishDayLabel.textColor = UIColor.darkGray
            self.finishDateLabel.text = formatter.string(from: finishDate!).uppercased()
            self.finishDateLabel.textColor = UIColor.darkGray
        } else {
            self.finishDayLabel.text = "TANGGAL"
            self.finishDayLabel.textColor = UIColor.gray
            self.finishDateLabel.text = "SELESAI"
            self.finishDateLabel.textColor = UIColor.gray
        }
        
        if isStartFinishAtSameDay {
            let totalBuffer: String = String(finishBuffer + startBuffer)
            let totalDay: String = "1 + " + totalBuffer
            self.totalDayLabel.text = totalDay + " hari"
        }
        else if isFinishSelected {
            let totalBuffer: String = String(finishBuffer + startBuffer)
            let totalDay: String = String(finishDate!.daysBetweenDate(startDate!)) + " + " + totalBuffer
            self.totalDayLabel.text = totalDay + " hari"
        } else {
            self.totalDayLabel.text = "0 hari"
        }
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
        myCustomCell.isSelected = false
        myCustomCell.configureDefaultView()
        let checkStartDateBuffer = startDate?.dateByAddingDays(-startBuffer)
        let checkSameStartFinishDateBuffer = startDate?.dateByAddingDays(finishBuffer)
        let checkFinishDateBuffer = finishDate?.dateByAddingDays(finishBuffer)
        
        if cellState.dateBelongsTo == .thisMonth {
            if isStartSelected {
                if cellDate.isSameDay(checkStartDateBuffer!) {
                    //configure buffer start date cell
                    myCustomCell.configureStartBufferView(isAtEndOfBuffer: true)
                }
                else if cellDate.isGreaterThanDate(checkStartDateBuffer!) &&
                    cellDate.isLessThanDate(startDate!) {
                    //configure cell range from buffer start cell to selected start date
                    myCustomCell.configureStartBufferView(isAtEndOfBuffer: false)
                }
                else if cellDate.isSameDay(startDate!) {
                    //configure selected start date cell
                    myCustomCell.isSelected = true
                    myCustomCell.configureStartView()
                } else {
                    if isStartFinishAtSameDay {
                        if cellDate.isGreaterThanDate(startDate!) && cellDate.isLessThanDate(checkSameStartFinishDateBuffer!) {
                            //configure cell range from selected finish date to buffer finish cell
                            myCustomCell.configureFinishBufferView(isAtEndOfBuffer: false)
                        } else if cellDate.isSameDay(checkSameStartFinishDateBuffer!) {
                            //configure buffer finish date cell
                            myCustomCell.configureFinishBufferView(isAtEndOfBuffer: true)
                        }
                    } else if isFinishSelected {
                        if cellDate.isGreaterThanDate(startDate!) &&
                            //configure cell range from selected start date to finish
                            cellDate.isLessThanDate(finishDate!) {
                            myCustomCell.configureRangeView()
                        }
                        else if cellDate.isSameDay(finishDate!) {
                            //selected finish date cell
                            myCustomCell.isSelected = true
                            myCustomCell.configureFinishView()
                        }
                        else if cellDate.isGreaterThanDate(finishDate!) &&
                            //configure cell range from selected finish date to buffer finish cell
                            cellDate.isLessThanDate(checkFinishDateBuffer!) {
                            myCustomCell.configureFinishBufferView(isAtEndOfBuffer: false)
                        }
                        else if cellDate.isSameDay(checkFinishDateBuffer!) {
                            //configure buffer finish date cell
                            myCustomCell.configureFinishBufferView(isAtEndOfBuffer: true)
                        }
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
                                                 hasStrictBoundaries: false)
        return parameters
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        configureCell(view: cell, cellState: cellState, cellDate: date)
        configureMenuView()
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "Cell", for: indexPath) as! TanggalViewCell
        configureCell(view: cell, cellState: cellState, cellDate: date)
        configureMenuView()
        return cell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        //override select & deselect cell function
        cell?.isSelected = false
        if !date.isLessThanDate(Date()) {
            handleCalendarDateCellClick(selectedDate: date)
        } else {
            Constant.showDialog("Perhatian", message: "Tidak dapat memulai penyewaan sebelum tanggal hari ini")
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        //override select & deselect cell function
        cell?.isSelected = false
        if !date.isLessThanDate(Date()) {
            handleCalendarDateCellClick(selectedDate: date)
        } else {
            Constant.showDialog("Perhatian", message: "Tidak dapat memulai penyewaan sebelum tanggal hari ini")
        }
    }
    
    func handleCalendarDateCellClick(selectedDate : Date) {
        //override select & deselect cell function
        if isStartSelected && !isFinishSelected {
            if selectedDate.isLessThanDate(startDate!){
                //selected date earlier than start date means reset start date
                //check if start buffer date's day is sunday
                if selectedDate.dateByAddingDays(-startBuffer).dayFromWeekday() == "Sunday" {
                    //show dialog that cannot send item on sunday
                    Constant.showDialog("Perhatian", message: "Pengiriman barang sewa tidak dapat dilakukan pada hari minggu")
                    isStartSelected = false
                    isFinishSelected = false
                    isStartFinishAtSameDay = false
                    startDate = nil
                    finishDate = nil
                } else {
                    isStartSelected = true
                    isFinishSelected = false
                    isStartFinishAtSameDay = true
                    startDate = selectedDate
                    finishDate = nil
                }
                
            } else if selectedDate.isSameDay(startDate!) {
                isStartSelected = true
                isFinishSelected = false
                isStartFinishAtSameDay = true
                startDate = selectedDate
                finishDate = nil
            } else {
                //selected finish date
                isFinishSelected = true
                isStartFinishAtSameDay = false
                finishDate = selectedDate
            }
        } else {
            let checkMaximumOpenDate = systemStartDate?.dateByAddingDays(startDateOpenDayRange)
            if selectedDate.isLessThanDate(checkMaximumOpenDate!) || selectedDate.isSameDay(checkMaximumOpenDate!) {
                //select start date OR reset start date if start and finish date already selected
                //check if start buffer date's day is sunday
                if selectedDate.dateByAddingDays(-startBuffer).dayFromWeekday() == "Sunday" {
                    //show dialog that cannot send item on sunday
                    Constant.showDialog("Perhatian", message: "Pengiriman barang sewa tidak dapat dilakukan pada hari minggu")
                    isStartSelected = false
                    isFinishSelected = false
                    isStartFinishAtSameDay = false
                    startDate = nil
                    finishDate = nil
                } else {
                    isStartSelected = true
                    isFinishSelected = false
                    isStartFinishAtSameDay = true
                    startDate = selectedDate
                    finishDate = nil
                }
            } else {
                //selected start date not available because more than open date limit
                Constant.showDialog("Perhatian", message: "Tidak dapat memulai tanggal penyewaan lebih dari " + startDateOpenDayRange.string + " hari dari sekarang")
                isStartSelected = false
                isFinishSelected = false
                isStartFinishAtSameDay = false
                startDate = nil
                finishDate = nil
            }
        }
        self.calendarView.reloadData()
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

extension UILabel {
    func colorString(text: String?, coloredText: String?, color: UIColor? = UIColor(hexString: "#14988B")) {
        
        let attributedString = NSMutableAttributedString(string: text!)
        let range = (text! as NSString).range(of: coloredText!)
        attributedString.setAttributes([NSForegroundColorAttributeName: color!],
                                       range: range)
        self.attributedText = attributedString
    }
}
