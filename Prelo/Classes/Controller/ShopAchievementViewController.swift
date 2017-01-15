//
//  ShopAchievementViewController.swift
//  Prelo
//
//  Created by Djuned on 1/15/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

class ShopAchievementViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var userAchievements : [UserAchievement] = []
    var sellerId : String = ""
    var sellerName : String = ""
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let ShopAchievementCell = UINib(nibName: "ShopAchievementCell", bundle: nil)
        tableView.register(ShopAchievementCell, forCellReuseIdentifier: "ShopAchievementCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        loadingPanel.isHidden = false
        loading.startAnimating()
        tableView.isHidden = true
        lblEmpty.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set title
        self.title = "Achievement " + self.sellerName
        
        // Get reviews
        self.getUserAchievements()
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ShopAchievements)
    }
    
    func getUserAchievements() {
        // API Migrasi
        let _ = request(APIUser.getAchievement(id: self.sellerId)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Achievement Pengguna")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                // Store data into variable
                for (_, item) in data {
                    let r = UserAchievement.instance(item)
                    if (r != nil) {
                        self.userAchievements.append(r!)
                    }
                }
            }
            self.loadingPanel.isHidden = true
            self.loading.stopAnimating()
            if (self.userAchievements.count <= 0) {
                self.lblEmpty.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.setupTable()
            }
        }
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            self.tableView.dataSource = self
            self.tableView.delegate = self
        }
        
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(0, 0, 5, 0)
        tableView.contentInset = inset
        
        
        tableView.separatorStyle = .none
        
        tableView.backgroundColor = UIColor(hex: "E5E9EB")
        
        self.tableView.reloadData()
    }
    
    // MARK: - UITableView Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userAchievements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ShopAchievementCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopAchievementCell") as! ShopAchievementCell
        
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor(hex: "E5E9EB")
        cell.clipsToBounds = true
        
        let u = userAchievements[(indexPath as NSIndexPath).item]
        cell.adapt(u)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("Row \(indexPath.row) selected")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath:  IndexPath) -> CGFloat {
        let u = userAchievements[(indexPath as NSIndexPath).item]
        let descHeight = u.desc.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: tableView.width - 42).height
        return 85 + CGFloat(Int(descHeight)) + 4
    }
}

class ShopAchievementCell : UITableViewCell {
    
    @IBOutlet var imgBadge: UIImageView!
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDesc: UILabel!
    
    override func prepareForReuse() {
        imgBadge.image = nil
    }
    
    func adapt(_ userAchievement : UserAchievement) {
        imgBadge.afSetImage(withURL: userAchievement.icon!)
        imgBadge.layoutIfNeeded()
        imgBadge.layer.masksToBounds = true
        imgBadge.layer.cornerRadius = (imgBadge.frame.size.width) / 2
        lblTitle.text = userAchievement.name
        lblDesc.text = userAchievement.desc
    }
}
