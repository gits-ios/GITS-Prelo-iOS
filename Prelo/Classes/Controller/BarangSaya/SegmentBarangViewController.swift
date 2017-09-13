//
//  SegmentBarangViewController.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/13/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

protocol SegmentBarangDelegate {
    
}

class SegmentBarangViewController: UIViewController {
    @IBOutlet weak var listBarangTableView: UITableView!
    
    var delegate:SegmentBarangDelegate!
    var mainVC: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTableView()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Register view cell
    func setupTableView(){
        //        delegate.setupTableView()
        
        self.listBarangTableView.register(UINib(nibName: "BarangTableViewCell", bundle: self.nibBundle), forCellReuseIdentifier: "BarangTableViewCell")
        
        self.listBarangTableView.rowHeight = UITableViewAutomaticDimension
        self.listBarangTableView.estimatedRowHeight = 500
        self.listBarangTableView.delegate = self
        self.listBarangTableView.dataSource = self
    }
}

extension SegmentBarangViewController: UITableViewDataSource, UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.listBarangTableView.dequeueReusableCell(withIdentifier: "BarangTableViewCell", for: indexPath) as! BarangTableViewCell
        return cell
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

