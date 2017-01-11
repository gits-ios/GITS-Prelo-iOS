//
//  AchievementViewController.swift
//  Prelo
//
//  Created by Djuned on 1/10/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation
import Alamofire


// MARK: - Class
class AchievementViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: AchievementCell!
    
    var achievements: Array<AchievementItem>? // badges --> AchievementItem, Diamonds
    var diamonds: Int = 0
    var isOpens: Array<Bool> = []
    
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let AchievementDiamondCell = UINib(nibName: "AchievementDiamondCell", bundle: nil)
        tableView.register(AchievementDiamondCell, forCellReuseIdentifier: "AchievementDiamondCell")
        
        let AchievementCell = UINib(nibName: "AchievementCell", bundle: nil)
        tableView.register(AchievementCell, forCellReuseIdentifier: "AchievementCell")
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showLoading()
        
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        
        getAchievement()
        
        
        // title
        self.title = "Achievement"
    }
    
    func getAchievement() {
        // clean badges
        self.achievements = []
        self.isOpens = []
        
        // fake json
        self.diamonds = 581
        self.isOpens.append(false)
        
//        let images = ["https://trello-avatars.s3.amazonaws.com/74a232623276d0ac160e0bc707c548ac/50.png", "https://trello-avatars.s3.amazonaws.com/6da61893718c325e1ea391dbcd80ef5d/50.png","https://trello-avatars.s3.amazonaws.com/3b704cc3f27e97a64f07036185bf5a61/50.png"]
//        let names = ["djuned", "algo", "nadine"]
//        
//        for i in 0...10 {
//            let s = i % 3
//            let t = (i+1) % 3
//            let u = (i+2) % 3
//            let fakeres = [
//                "name":names[s],
//                "icon":images[s],
//                "description":"sample deskripsi aja...",
//                "tier": 0,
//                "tier_icons": [images[t], images[u]],
//                "conditions": [["fulfilled":(i % 2 == 0 ? true : false), "condition_text":"mantap"],["fulfilled":(i % 2 == 0 ? false : true), "condition_text":"gg"]]
//                ] as [String : Any]
//            
//            let json = JSON(fakeres)
//            let achievement = AchievementItem.instance(json)
//            self.achievements?.append(achievement!)
//            
//            isOpens.append(false)
//        }
        
        // use API
        let _ = request(APIMe.achievement).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Achievement")) {
                if let x: AnyObject = resp.result.value as AnyObject? {
                    var json = JSON(x)
                    json = json["_data"]
                    
                    self.diamonds = json["diamonds"].int!
                    
                    if let arr = json["achievements"].array {
                        for i in 0...arr.count - 1 {
                            let achievement = AchievementItem.instance(arr[i])
                            self.achievements?.append(achievement!)
                            self.isOpens.append(false)
                        }
                    }
                    
                    self.tableView.reloadData()
                    self.hideLoading()
                }
                
            } else {
                
                self.hideLoading()
                self.navigationController?.popToViewController(self.previousController!, animated: true)
            }
        }
    }

    
    // MARK: - Other
    func showLoading() {
//        self.tableView.isHidden = true
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
//        self.tableView.isHidden = false
        self.loadingPanel.isHidden = true
    }
    
    // MARK: - Table View delegate methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return achievements!.count + 1
    }
    
    // MARK: - TableView functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ((indexPath as NSIndexPath).section == 0) { // diamond
            return AchievementDiamondCell.heightFor(isOpens[(indexPath as NSIndexPath).section])
        } else {
            let achievement = achievements?[(indexPath as NSIndexPath).section - 1]
            let count = achievement!.conditions.count
            return AchievementCell.heightFor(count, isOpen: isOpens[(indexPath as NSIndexPath).section], isProgress: achievement!.tierIcons.count > 0, desc: achievement!.desc)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath as NSIndexPath).section == 0) { // diamond
            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementDiamondCell") as! AchievementDiamondCell
            // load api call diamond badge
            cell.adapt(diamonds, isOpen: isOpens[(indexPath as NSIndexPath).section])
            
            
            cell.layer.masksToBounds = true
            cell.layer.borderColor = Theme.PrimaryColor.cgColor
            cell.layer.borderWidth = 1.0
            cell.layer.cornerRadius = 8
            cell.clipsToBounds = true
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCell") as! AchievementCell
            cell.setupTable()
            cell.adapt((achievements?[(indexPath as NSIndexPath).section - 1])!, isOpen: isOpens[(indexPath as NSIndexPath).section])
            
            cell.layer.masksToBounds = true
            cell.layer.borderColor = Theme.PrimaryColor.cgColor
            cell.layer.borderWidth = 1.0
            cell.layer.cornerRadius = 8
            cell.clipsToBounds = true
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        isOpens[(indexPath as NSIndexPath).section] = !isOpens[(indexPath as NSIndexPath).section]
        tableView.reloadData()
    }
    
    // Set the spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
}


// MARK: - AchievementCell after DiamondCell
class AchievementCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate { // height 70 + lbldesc
    @IBOutlet weak var badgeImage: UIImageView!
    @IBOutlet weak var lblTitke: UILabel!
    @IBOutlet weak var lblArrow: UILabel! // V
    @IBOutlet weak var tblConditions: UITableView!
    @IBOutlet weak var vwTable: UIView!
    
    var achievement : AchievementItem!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setupTable() {
        tblConditions.register(AchievementCellDescriptionCell.self, forCellReuseIdentifier: "AchievementCellDescriptionCell")
        
        let AchievementCellProgressCell = UINib(nibName: "AchievementCellProgressCell", bundle: nil)
        tblConditions.register(AchievementCellProgressCell, forCellReuseIdentifier: "AchievementCellProgressCell")
        
        let AchievementCellBadgeCell = UINib(nibName: "AchievementCellBadgeCell", bundle: nil)
        tblConditions.register(AchievementCellBadgeCell, forCellReuseIdentifier: "AchievementCellBadgeCell")
        
        // Setup table
        tblConditions.dataSource = self
        tblConditions.delegate = self
        tblConditions.tableFooterView = UIView()
        
        tblConditions.separatorStyle = .none

    }
    
    // kalau lbl desc
    // mungkin ga dipake
//    static func heightFor(_ text: String, isOpen: Bool) -> CGFloat {
//        let standardHeight : CGFloat = 70.0
//        let textRect : CGRect = text.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 16)
//        return standardHeight + (isOpen ? textRect.height : 0) + 4
//    }
    
    // kalau point point (fullfilled, condition) + progressicon
    static func heightFor(_ conditionCount: Int, isOpen: Bool, isProgress: Bool, desc: String) -> CGFloat {
        let standardHeight : CGFloat = 70.0
        var heightProgress = 30.0 * CGFloat(conditionCount) + (isProgress ? 56 : 0)
        let textRect = desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 16)
        heightProgress += textRect.height + 4
        return standardHeight + (isOpen ? heightProgress : 0) + 10
        
    }

    func adapt(_ achievement : AchievementItem, isOpen: Bool) {
        self.achievement = achievement
        
        self.badgeImage?.layoutIfNeeded()
        self.badgeImage?.layer.cornerRadius = (self.badgeImage?.width ?? 0) / 2
        self.badgeImage?.layer.masksToBounds = true
        
        self.badgeImage?.afSetImage(withURL: achievement.icon!)
        
        self.lblTitke.text = achievement.name
        
        self.vwTable.isHidden = !isOpen
        
        self.lblArrow.text = (isOpen ? "" : "")
        
        tblConditions.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (achievement != nil) {
            return achievement!.conditions.count + (achievement!.tierIcons.count > 0 ? 1 : 0) + 1 // desccell
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ((indexPath as NSIndexPath).row == 0) { // description cell
            let textRect = achievement!.desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 16)
            return textRect.height + 4
        } else if ((indexPath as NSIndexPath).row == achievement!.conditions.count + 1) { // badgecell
            return 56
        } else {
            return 30
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath as NSIndexPath).row == 0) { // description cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCellDescriptionCell") as! AchievementCellDescriptionCell
            cell.textLabel!.text = self.achievement!.desc
            cell.textLabel!.numberOfLines = 0
            cell.textLabel!.font = UIFont.systemFont(ofSize: 14)
            cell.textLabel!.textColor = UIColor.lightGray
            return cell
        } else if ((indexPath as NSIndexPath).row == achievement!.conditions.count + 1) { // badgecell
            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCellBadgeCell") as! AchievementCellBadgeCell
            cell.setupCollection()
            cell.adapt(achievement.tierIcons)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCellProgressCell") as! AchievementCellProgressCell
            print(achievement.conditions)
            cell.adapt(achievement.conditions[(indexPath as NSIndexPath).row - 1])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tblConditions.reloadData()
    }
}

class AchievementCellDescriptionCell : UITableViewCell { // height depent on description
    
    
}

class AchievementCellProgressCell: UITableViewCell { // height 30
    @IBOutlet weak var lblCondition: UILabel!
    @IBOutlet weak var lblFullfilled: UILabel!
    
    // adapt
    func adapt(_ condition: [String:Bool]) {
        
        
        
        for (key, value) in condition {
            self.lblCondition.text = key
//            self.lblFullfilled.isHidden = !value
            self.lblFullfilled.isHidden = false
            
            self.lblFullfilled.backgroundColor = (value == false ? UIColor.lightGray : UIColor.orange)
            
            print(key)
            print(value)
        }
    }
}

class AchievementCellBadgeCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate { // height 40
    @IBOutlet weak var progressIcon: UICollectionView!
    
    var imageURLS : Array<URL>! = []
    
    // adapt
    func adapt(_ imageURLS: Array<URL>) {
        self.imageURLS = imageURLS
        self.progressIcon.reloadData()
    }
    
    func setupCollection() {
        
        // Set collection view
        self.progressIcon.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcProgressCell")
        self.progressIcon.delegate = self
        self.progressIcon.dataSource = self
        //        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NotifAnggiTransactionCell.handleTap))
        //        tapGestureRecognizer.delegate = self
        self.progressIcon.backgroundView = UIView(frame: self.progressIcon.bounds)
        //        collcTrxProgress.backgroundView!.addGestureRecognizer(tapGestureRecognizer)
        self.progressIcon.backgroundColor = UIColor.clear
        
        self.progressIcon.isScrollEnabled = false
    }
    
    // MARK: - CollectionView delegate functions
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageURLS.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = self.progressIcon.dequeueReusableCell(withReuseIdentifier: "collcProgressCell", for: indexPath)
        
        if (imageURLS.count > (indexPath as NSIndexPath).row) {
            // Create icon view
            let vwIcon : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//            vwIcon.layer.cornerRadius = (vwIcon.frame.size.width) / 2
            
            let img = UIImageView(frame: CGRect(x: 2, y: 2, width: 28, height: 28))
            img.layoutIfNeeded()
            img.layer.cornerRadius = (img.width ) / 2
            img.layer.masksToBounds = true
            img.afSetImage(withURL: imageURLS[(indexPath as NSIndexPath).row])
            
            vwIcon.addSubview(img)
            
            // Add view to cell
            cell.addSubview(vwIcon)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 30, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if (idx != nil) {
//            delegate?.cellCollectionTapped(self.idx!)
//        }
    }
    
    
}

// MARK: - DiamondCell top
class AchievementDiamondCell: UITableViewCell { // 130 + lbldesc
    @IBOutlet weak var badgeImage: UIImageView!
    @IBOutlet weak var lblDiamond: UILabel!
    @IBOutlet weak var lblArrow: UILabel! // V
    @IBOutlet weak var lblDesc: UILabel! // hidden
    
    static func heightFor(_ isOpen: Bool) -> CGFloat {
        let standardHeight : CGFloat = 130.0
        let text = "Kumpulkan Diamond untuk dapat meng-up barang kamu secara gratis!"
        let textRect : CGRect = text.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 112)
        return standardHeight + (isOpen ? textRect.height : 0) + 10 + 10
    }
    
    // TODO: adapt & height
    func adapt(_ diamonds: Int, isOpen: Bool) {
        self.badgeImage?.layoutIfNeeded()
        self.badgeImage?.layer.cornerRadius = (self.badgeImage?.width ?? 0) / 2
        self.badgeImage?.layer.masksToBounds = true
        // local image
        self.badgeImage?.image = UIImage(named: "raisa.jpg")
        
        self.lblDiamond.text = diamonds.string + " Diamond Point"
        
        self.lblDesc.text = "Kumpulkan Diamond untuk dapat meng-up barang kamu secara gratis!"
        
        // disabled
//        self.lblArrow.isHidden = false
        
        self.lblDesc.isHidden = !isOpen
        
        self.lblArrow.text = (isOpen ? "" : "")
        
    }
}
