//
//  KDEDateLabel.swift
//  KDEDateLabelExample
//
//  Created by Kevin DELANNOY on 23/12/14.
//  Copyright (c) 2014 Kevin Delannoy. All rights reserved.
//

import UIKit

// MARK: - KDEWeakReferencer
////////////////////////////////////////////////////////////////////////////////

private class KDEWeakReferencer<T: NSObject>: NSObject {
    fileprivate(set) weak var value: T?

    init(value: T) {
        self.value = value
        super.init()
    }

    fileprivate override func isEqual(_ object: Any?) -> Bool {
        return value?.isEqual(object) ?? false
    }

    fileprivate override var hash: Int {
        return value?.hash ?? 0
    }

    fileprivate override var hashValue: Int {
        return value?.hashValue ?? 0
    }
}

////////////////////////////////////////////////////////////////////////////////


// MARK: - KDEDateLabelsHolder
////////////////////////////////////////////////////////////////////////////////

class KDEDateLabelsHolder: NSObject {
    fileprivate var dateLabels = [KDEWeakReferencer<KDEDateLabel>]()
    fileprivate var timer: Timer?

    fileprivate static var instance = KDEDateLabelsHolder()

    fileprivate override init() {
        super.init()
        self.createNewTimer()
    }


    fileprivate func addReferencer(_ referencer: KDEWeakReferencer<KDEDateLabel>) {
        self.dateLabels.append(referencer)
    }

    fileprivate func removeReferencer(_ referencer: KDEWeakReferencer<KDEDateLabel>) {
        if let index = self.dateLabels.index(of: referencer) {
            self.dateLabels.remove(at: index)
        }
        self.dateLabels = self.dateLabels.filter { $0.value != nil }
    }


    fileprivate func createNewTimer() {
        self.timer?.invalidate()

        self.timer = Timer(timeInterval: KDEDateLabel.refreshFrequency,
            target: self,
            selector: #selector(KDEDateLabelsHolder.timerTicked(_:)),
            userInfo: nil,
            repeats: true)
        RunLoop.main.add(self.timer!, forMode: RunLoopMode.commonModes)
    }


    @objc fileprivate func timerTicked(_: Timer) {
        for referencer in self.dateLabels {
            referencer.value?.updateText()
        }
    }
}

////////////////////////////////////////////////////////////////////////////////


// MARK: - KDEDateLabel
////////////////////////////////////////////////////////////////////////////////

open class KDEDateLabel: UILabel {
    fileprivate lazy var holder: KDEWeakReferencer<KDEDateLabel> = {
        return KDEWeakReferencer<KDEDateLabel>(value: self)
    }()


    // MARK: Initialization
    public convenience init() {
        self.init(frame: .zero)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    fileprivate func commonInit() {
        KDEDateLabelsHolder.instance.addReferencer(self.holder)
    }

    // MARK: Deinit
    deinit {
        KDEDateLabelsHolder.instance.removeReferencer(self.holder)
    }


    // MARK: Configuration
    open static var refreshFrequency: TimeInterval = 0.2 {
        didSet {
            KDEDateLabelsHolder.instance.createNewTimer()
        }
    }


    // MARK: Date & Text updating
    open var date: Date? = nil {
        didSet {
            self.updateText()
        }
    }

    open var dateFormatTextBlock: ((_ date: Date) -> String)? {
        didSet {
            self.updateText()
        }
    }

    open var dateFormatAttributedTextBlock: ((_ date: Date) -> NSAttributedString)? {
        didSet {
            self.updateText()
        }
    }

    fileprivate func updateText() {
        if let date = date {
            if let dateFormatAttributedTextBlock = self.dateFormatAttributedTextBlock {
                self.attributedText = dateFormatAttributedTextBlock(date)
            }
            else if let dateFormatTextBlock = self.dateFormatTextBlock {
                self.text = dateFormatTextBlock(date)
            }
            else {
                self.text = "\(Int(fabs(date.timeIntervalSinceNow)))s ago"
            }
        }
        else {
            self.text = nil
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
