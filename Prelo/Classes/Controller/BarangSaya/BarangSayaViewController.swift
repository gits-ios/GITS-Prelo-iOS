//
//  BarangSayaViewController.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/13/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import MXSegmentedPager

class BarangSayaViewController: UIViewController {
    @IBOutlet weak var segmentedPager: MXSegmentedPager!
    @IBOutlet weak var navTitle: UINavigationItem!
    
    var segmentTitle:[String] = ["BARANG", "TRANSAKSI"]
    var VC: [SegmentBarangViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupSegmentPage()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension BarangSayaViewController: MXSegmentedPagerDelegate, MXSegmentedPagerDataSource{
    func setupSegmentPage(){
        let VCSegmentBarang = (self.storyboard?.instantiateViewController(withIdentifier: "SegmentBarang") as? SegmentBarangViewController)!
        VCSegmentBarang.mainVC = self
        VCSegmentBarang.delegate = self
        
        let VCSegmentTransaksi = (self.storyboard?.instantiateViewController(withIdentifier: "SegmentBarang") as? SegmentBarangViewController)!
        VCSegmentTransaksi.mainVC = self
        VCSegmentTransaksi.delegate = self
        
        VC = [VCSegmentBarang, VCSegmentTransaksi]
        segmentedPager.delegate = self
        segmentedPager.dataSource = self
        
        segmentedPager.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocation.down
        segmentedPager.segmentedControl.backgroundColor = UIColor.white
        segmentedPager.backgroundColor = UIColor.white
        segmentedPager.segmentedControl.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.gray,
            NSFontAttributeName : UIFont.boldSystemFont(ofSize: 12) ]
        segmentedPager.segmentedControl.selectedTitleTextAttributes = [NSForegroundColorAttributeName : UIColor.black, NSFontAttributeName : UIFont.boldSystemFont(ofSize: 12) ]
        segmentedPager.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyle.fullWidthStripe
        segmentedPager.segmentedControl.layoutMargins.left = 4
        segmentedPager.segmentedControl.layoutMargins.right = 4
        segmentedPager.segmentedControl.segmentWidthStyle = .fixed
        segmentedPager.segmentedControl.selectionIndicatorColor = #colorLiteral(red: 0.07668348402, green: 0.5975784063, blue: 0.5461774468, alpha: 1)
        segmentedPager.segmentedControl.selectionIndicatorHeight = 3
    }
    
    func numberOfPages(in segmentedPager: MXSegmentedPager) -> Int {
        if segmentTitle.count != 0 {
            return segmentTitle.count
        } else {
            return 1
        }
    }
    
    func segmentedPager(_ segmentedPager: MXSegmentedPager, titleForSectionAt index: Int) -> String {
        if segmentTitle.count != 0 {
            return self.segmentTitle[index];
        } else {
            return ""
        }
    }
    
    func segmentedPager(_ segmentedPager: MXSegmentedPager, viewForPageAt index: Int) -> UIView {
        if segmentTitle.count != 0 {
            return VC[index].view
        } else {
            let emptyView = UIViewController()
            return emptyView.view
        }
    }
}

extension BarangSayaViewController: SegmentBarangDelegate {
    
}

