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
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingPanel: UIView!
    var achievements: Array<AchievementItem>? // badges --> AchievementItem, Diamonds
    var diamonds: Int = 0
    var isOpens: Array<Bool> = []
    
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let AchievementDiamondCell = UINib(nibName: "AchievementDiamondCell", bundle: nil)
        tableView.register(AchievementDiamondCell, forCellReuseIdentifier: "AchievementDiamondCell")
        
        let AchievementCelliOS9xx = UINib(nibName: "AchievementCelliOS9xx", bundle: nil)
        tableView.register(AchievementCelliOS9xx, forCellReuseIdentifier: "AchievementCell")

        // for button baca lebih lanjut
        tableView.register(ButtonCell.self, forCellReuseIdentifier: "ButtonCell")
        
        let AchievementCellProgressCell = UINib(nibName: "AchievementCellProgressCell", bundle: nil)
        tableView.register(AchievementCellProgressCell, forCellReuseIdentifier: "AchievementCellProgressCell")
        
        let AchievementCellBadgeCell = UINib(nibName: "AchievementCellBadgeCell", bundle: nil)
        tableView.register(AchievementCellBadgeCell, forCellReuseIdentifier: "AchievementCellBadgeCell")
        
        let AchievementCellDescriptionCell = UINib(nibName: "AchievementCellDescriptionCell", bundle: nil)
        tableView.register(AchievementCellDescriptionCell, forCellReuseIdentifier: "AchievementCellDescriptionCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showLoading()
        
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(5, 0, 5, 0)
        tableView.contentInset = inset
        
        
        tableView.separatorStyle = .none
        
        tableView.backgroundColor = UIColor(hex: "E5E9EB")
        
        getAchievement()
        
        
        // title
        self.title = "Achievement"
    }
    
    func getAchievement() {
        // clean badges
        self.achievements = []
        self.isOpens = []
        
        self.isOpens.append(false)
        
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
//                            self.isOpens.append((achievement?.isAchieved)!)
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
        self.loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        self.loadingPanel.isHidden = true
    }
    
    // MARK: - TableView functions
    func numberOfSections(in tableView: UITableView) -> Int {
        if (achievements != nil) {
            return achievements!.count + 1 + 1 // diamonds & button
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section > 0 && section <= (achievements?.count)!) {
            if (isOpens[section]) {
                return 1 + 1 + achievements![section - 1].conditions.count + (achievements![section - 1].tierIcons.count > 0 ? 1 : 0) + 1
            } else {
                return 1
            }
        } else {
            return 1 // diamonds & baca lebih lanjut
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ((indexPath as NSIndexPath).section == 0) { // diamond
            return AchievementDiamondCell.heightFor(isOpens[(indexPath as NSIndexPath).row])
        } else if ((indexPath as NSIndexPath).section == (achievements?.count)! + 1) {
            return 45
        } else {
            if ((indexPath as NSIndexPath).row == 0) { // always open
                return 70
            } else if ((indexPath as NSIndexPath).row == 1) { // description cell
                let textRect = achievements![(indexPath as NSIndexPath).section - 1].desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 42)
                return textRect.height + 4
            } else if ((indexPath as NSIndexPath).row > 1 && (indexPath as NSIndexPath).row <= achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1) { // condition cell
                return 30 + 4
            } else if ((indexPath as NSIndexPath).row == achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 2 && achievements![(indexPath as NSIndexPath).section - 1].tierIcons.count > 0) { // tier icons cell
                return 40 + 4
            } else {
                return 7 // border bottom
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath as NSIndexPath).section == 0) { // diamond
            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementDiamondCell") as! AchievementDiamondCell
            
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor(hex: "E5E9EB")
            cell.clipsToBounds = true
            cell.adapt(diamonds, isOpen: isOpens[(indexPath as NSIndexPath).row])
            
            return cell
        } else if ((indexPath as NSIndexPath).section == (achievements?.count)! + 1) { // button
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell") as! ButtonCell
            
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor(hex: "E5E9EB")
            cell.clipsToBounds = true
            
            let lblButton = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.width - 10, height: 40))
            
            lblButton.text = "BACA LEBIH LANJUT"
            lblButton.textColor = Theme.PrimaryColor
            lblButton.backgroundColor = UIColor.clear
            lblButton.textAlignment = .center
            
            let vwBorder = UIView(frame: CGRect(x: 5, y: 5, width: tableView.width - 10, height: 40))
            
            vwBorder.backgroundColor = UIColor.white
            
            vwBorder.addSubview(lblButton)
            
            cell.contentView.addSubview(vwBorder)
            
            return cell
        } else {
            if ((indexPath as NSIndexPath).row == 0) { // always open
                let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCell") as! AchievementCelliOS9xx
                
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor(hex: "E5E9EB")
                cell.clipsToBounds = true
                cell.adapt((achievements?[(indexPath as NSIndexPath).section - 1])!, isOpen: isOpens[(indexPath as NSIndexPath).section])
                
                return cell
            } else if ((indexPath as NSIndexPath).row == 1) { // description cell
                let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCellDescriptionCell") as! AchievementCellDescriptionCell
                
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor(hex: "E5E9EB")
                cell.clipsToBounds = true
                // adapt
                cell.lblDesc.isHidden = false
                cell.lblDesc.text = self.achievements![(indexPath as NSIndexPath).section - 1].desc
                
                return cell
            } else if ((indexPath as NSIndexPath).row > 1 && (indexPath as NSIndexPath).row <= achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1) { // condition cell
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCellProgressCell") as! AchievementCellProgressCell
                
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor(hex: "E5E9EB")
                cell.clipsToBounds = true
                cell.adapt((achievements?[(indexPath as NSIndexPath).section - 1].conditions[(indexPath as NSIndexPath).row - 2])!)
                
                return cell
            } else if ((indexPath as NSIndexPath).row == achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 2 && achievements![(indexPath as NSIndexPath).section - 1].tierIcons.count > 0) { // tier icons cell
                let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCellBadgeCell") as! AchievementCellBadgeCell
                
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor(hex: "E5E9EB")
                cell.clipsToBounds = true
                cell.setupCollection()
                cell.adapt((achievements?[(indexPath as NSIndexPath).section - 1].tierIcons)!)
                
                return cell
            } else { // border bottom
                let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCellDescriptionCell") as! AchievementCellDescriptionCell
                
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor(hex: "E5E9EB")
                cell.clipsToBounds = true
                // adapt
                cell.lblDesc.isHidden = true
                
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ((indexPath as NSIndexPath).section == (achievements?.count)! + 1) {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let helpVC = mainStoryboard.instantiateViewController(withIdentifier: "preloweb") as! PreloWebViewController
            helpVC.url = "https://prelo.co.id/faq?ref=preloapp"
            helpVC.titleString = "Bantuan"
            helpVC.contactPreloMode = true
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([helpVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        } else {
            if ((indexPath as NSIndexPath).row == 0) {
                isOpens[(indexPath as NSIndexPath).section] = !isOpens[(indexPath as NSIndexPath).section]
                tableView.reloadData()
            }
        }
    }
}

class AchievementCelliOS9xx: UITableViewCell { // height 75 ++
    @IBOutlet var badgeImage: UIImageView!
    @IBOutlet var lblTitke: UILabel!
    @IBOutlet var lblArrow: UILabel! // V
    @IBOutlet var vwProgressBar: UIView! // default hidden
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var lblProgressView: UILabel!
    @IBOutlet var consHeightLblTitke: NSLayoutConstraint! // default 56 --> 40
    @IBOutlet var vwBorder: UIView!
    
    var achievement : AchievementItem!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        self.consHeightLblTitke.constant = 56
        self.vwProgressBar.isHidden = true
    }
    
    // kalau point point (fullfilled, condition) + progressicon
    static func heightFor(_ conditionCount: Int, isOpen: Bool, isProgress: Bool, desc: String) -> CGFloat {
        let standardHeight : CGFloat = 75.0
        var heightProgress = 30.0 * CGFloat(conditionCount) + (isProgress ? 40 : 0)
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
        
        if achievement.progressMax > 0 {
            self.consHeightLblTitke.constant = 40
            self.vwProgressBar.isHidden = false
            self.progressView.setProgress(Float(achievement.progressCurrent) / Float(achievement.progressMax) , animated: false)
            self.lblProgressView.text = achievement.progressCurrent.string + " / " + achievement.progressMax.string
            self.lblProgressView.textColor = (achievement.progressCurrent == 0 ? Theme.GrayLight : Theme.PrimaryColor)
        }
        
        
        self.lblArrow.text = (isOpen ? "" : "")
    }
    
}

class AchievementCellDescriptionCell : UITableViewCell { // height depent on description
    @IBOutlet var lblDesc: UILabel! // hidden
    @IBOutlet var vwBorder: UIView!
}

class AchievementCellProgressCell: UITableViewCell { // height 30
    @IBOutlet var lblCondition: UILabel!
    @IBOutlet var lblFullfilled: UILabel!
    
    // adapt
    func adapt(_ condition: [String:Bool]) {
        
        for (key, value) in condition {
            self.lblCondition.text = key
//            self.lblFullfilled.isHidden = !value
            self.lblFullfilled.isHidden = false
            
            self.lblFullfilled.backgroundColor = (value == false ? UIColor.lightGray : Theme.PrimaryColor)
            
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
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if (idx != nil) {
//            delegate?.cellCollectionTapped(self.idx!)
//        }
//    }
}


// MARK: - DiamondCell top
class AchievementDiamondCell: UITableViewCell { // 135 + lbldesc
    @IBOutlet var badgeImage: UIImageView!
    @IBOutlet var lblDiamond: UILabel!
    @IBOutlet var lblArrow: UILabel! // V
    @IBOutlet var lblDesc: UILabel! // hidden
    @IBOutlet var vwBorder: UIView!
    
    static func heightFor(_ isOpen: Bool) -> CGFloat {
        let standardHeight : CGFloat = 125.0
        let text = "Kumpulkan Diamond untuk dapat meng-up barang kamu secara gratis!"
        let textRect : CGRect = text.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 112)
        return standardHeight + (isOpen ? textRect.height - 5 : 0) + 10
    }
    
    func adapt(_ diamonds: Int, isOpen: Bool) {

        self.badgeImage?.layoutIfNeeded()
        self.badgeImage?.layer.cornerRadius = (self.badgeImage?.width ?? 0) / 2
        self.badgeImage?.layer.masksToBounds = true
        // local image
        self.badgeImage?.image = UIImage(named: "raisa.jpg")
        
        self.lblDiamond.text = diamonds.string + " Diamond"
        
        self.lblDesc.text = "Kumpulkan Diamond untuk dapat meng-up barang kamu secara gratis!"
        
        self.lblDesc.isHidden = !isOpen
        
        self.lblArrow.text = (isOpen ? "" : "")
        
    }
}

class ButtonCell : UITableViewCell { // height 40
    
}
