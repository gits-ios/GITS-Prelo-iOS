//
//  ShopAchievementViewController.swift
//  Prelo
//
//  Created by Djuned on 1/15/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire

enum AchievementMode {
    case `default`
    case inject
}

class ShopAchievementViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var userAchievements : Array<UserAchievement> = []
    var sellerId : String = ""
    var sellerName : String = ""
    
    var currentMode : AchievementMode! = .default
    
    weak var delegate : NewShopHeaderDelegate?
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menghilangkan garis antar cell di baris kosong
        tableView.tableFooterView = UIView()
        
        // Register custom cell
        let ShopAchievementCell = UINib(nibName: "ShopAchievementCell", bundle: nil)
        tableView.register(ShopAchievementCell, forCellReuseIdentifier: "ShopAchievementCell")
        
        // Belum ada badge untuk user ini
        tableView.register(ProvinceCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        
        
        if (currentMode == .default) {
            loadingPanel.isHidden = false
            loading.startAnimating()
            
            tableView.isHidden = true
            lblEmpty.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set title
        self.title = "Achievement " + self.sellerName
        
        // Get achievements
        
        if (currentMode == .default) {
//            self.userAchievements = []
            self.getUserAchievements()
        }
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ShopAchievements)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    func setUserAchievements(_ achievementData: JSON) {
        let data = achievementData
        // Store data into variable
        for (_, item) in data {
            let r = UserAchievement.instance(item)
            if (r != nil) {
                self.userAchievements.append(r!)
            }
        }
        
        self.loadingPanel.isHidden = true
        self.loading.stopAnimating()
//        if (self.userAchievements.count <= 0) {
//            self.lblEmpty.isHidden = false
//            self.tableView.isHidden = true
//        } else {
//            self.tableView.isHidden = false
            self.setupTable()
//        }
    }
    
    func setupTable() {
        if (self.tableView.delegate == nil) {
            self.tableView.dataSource = self
            self.tableView.delegate = self
        }
        
        self.tableView.reloadData()
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - (64 + 45) // (170 + 45)
        
//        let tableHeight = CGFloat(self.userAchievements.count * 65) // min height
        let tableHeight = self.tableView.contentSize.height
        
        var bottom = CGFloat(24)
        if (tableHeight < screenHeight) {
            bottom += (screenHeight - tableHeight)
        }
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(0, 0, bottom, 0)
        tableView.contentInset = inset
        
        
        tableView.separatorStyle = .none
        
        if (userAchievements.count > 0) {
            tableView.backgroundColor = UIColor(hex: "E5E9EB")
        }
    }
    
    // MARK: - UITableView Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.userAchievements.count > 0) {
            return self.userAchievements.count
        } else {
            return 1 // Belum ada badge untuk user ini
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (currentMode == .inject) {
            if (self.userAchievements.count > 0) {
                let cell : ShopAchievementCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopAchievementCell") as! ShopAchievementCell
                
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor(hex: "E5E9EB")
                cell.clipsToBounds = true
                
                let u = userAchievements[(indexPath as NSIndexPath).item]
                cell.adapt(u)
                return cell
            } else { // Belum ada badge untuk user ini
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
                
                cell?.selectionStyle = .none
                
                cell?.textLabel!.text = "Belum ada badge untuk user ini"
                cell?.textLabel!.font = UIFont.systemFont(ofSize: 12)
                cell?.textLabel!.textAlignment = .center
                
                return cell!
            }
        } else {
            let cell : ShopAchievementCell = self.tableView.dequeueReusableCell(withIdentifier: "ShopAchievementCell") as! ShopAchievementCell
            
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor(hex: "E5E9EB")
            cell.clipsToBounds = true
            
            let u = userAchievements[(indexPath as NSIndexPath).item]
            cell.adapt(u)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("Row \(indexPath.row) selected")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath:  IndexPath) -> CGFloat {
        if (self.userAchievements.count > 0) {
            let u = userAchievements[(indexPath as NSIndexPath).item]
            let descHeight = u.desc.boundsWithFontSize(UIFont.systemFont(ofSize: 12), width: tableView.width - 42).height
            return 85 + CGFloat(Int(descHeight)) + 4
        } else {
            return 90
        }
    }
    
    // MARK: - UIScrollView Functions
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (currentMode == .inject) {
            scrollViewHeaderShop(scrollView)
        }
    }
    
    func scrollViewHeaderShop(_ scrollView: UIScrollView) {
//        let pointY = CGFloat(1)
//        let screenSize = UIScreen.main.bounds
//        let screenHeight = screenSize.height - 170
//        let height = scrollView.contentSize.height
//        if (scrollView.contentOffset.y < pointY && height >= screenHeight) {
//            self.delegate?.increaseHeader()
//            self.transparentNavigationBar(true)
//        } else if (scrollView.contentOffset.y >= pointY && height >= screenHeight) {
//            self.delegate?.dereaseHeader()
//            self.transparentNavigationBar(false)
//        }
        
        let pointY = CGFloat(1)
        if (scrollView.contentOffset.y < pointY) {
            self.delegate?.increaseHeader()
            self.transparentNavigationBar(true)
        } else if (scrollView.contentOffset.y >= pointY) {
            self.delegate?.dereaseHeader()
            self.transparentNavigationBar(false)
        }
    }
    
    // MARK: - navbar styler
    func transparentNavigationBar(_ isActive: Bool) {
        if (currentMode == .inject) {
            if isActive && !(self.delegate?.getTransparentcy())! {
                UIView.animate(withDuration: 0.5) {
                    // Transparent navigation bar
                    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                    self.navigationController?.navigationBar.shadowImage = UIImage()
                    self.navigationController?.navigationBar.isTranslucent = true
                    
                    self.navigationController?.navigationBar.layoutIfNeeded()
                    
                    self.delegate?.setShopTitle("")
                }
                self.delegate?.setTransparentcy(true)
            } else if !isActive && (self.delegate?.getTransparentcy())!  {
                UIView.animate(withDuration: 0.5) {
                    self.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
                    self.navigationController?.navigationBar.shadowImage = nil
                    self.navigationController?.navigationBar.isTranslucent = true
                    
                    // default prelo
                    UINavigationBar.appearance().barTintColor = Theme.PrimaryColor
                    
                    self.navigationController?.navigationBar.layoutIfNeeded()
                    
                    self.delegate?.setShopTitle(self.sellerName)
                }
                self.delegate?.setTransparentcy(false)
            }
        }
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
