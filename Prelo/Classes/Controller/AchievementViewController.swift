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
    @IBOutlet weak var loadingPanel: UIView!
    var achievements: Array<AchievementItem>? // badges --> AchievementItem, Diamonds
    var diamonds: Int = 0
    var isOpens: Array<Bool> = []
    var isFirst: Bool = true
    
    // for new achievement unlock -- pop up
    @IBOutlet weak var vwBackgroundOverlay: UIView! // hidden
    @IBOutlet weak var vwOverlayPopUp: UIView! // hidden
    @IBOutlet weak var imgAchivement: UIImageView!
    @IBOutlet weak var lblAchievement: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var consCenteryPopUp: NSLayoutConstraint! // align center y --> 603 [window height] -> 0
    @IBOutlet weak var vwPopUp: UIView!
    
    var achievementsUnlocked: Array<AchievementUnlockedItem>? // pop up --> achievement achievementsUnlocked
    var achievementsUnlockedPosition: Int = 0
    
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
        
        // only once
//        getAchievement()
        
        // title
        self.title = "Achievement"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirst {
            isFirst = false
            showLoading()
            
            // Setup table
            tableView.dataSource = self
            tableView.delegate = self
            tableView.tableFooterView = UIView()
            
            //TOP, LEFT, BOTTOM, RIGHT
            let inset = UIEdgeInsetsMake(4, 0, 4, 0)
            tableView.contentInset = inset
            
            tableView.separatorStyle = .none
            
            tableView.backgroundColor = UIColor(hex: "E5E9EB")
        
            getAchievement()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Achievement)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getAchievement() {
        // clean badges
        self.achievements = []
        self.isOpens = []
        
        self.achievementsUnlocked = []
        
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
                            self.isOpens.append((achievement?.isAchieved)!)
//                            self.isOpens.append(false)
                        }
                    }
                    
                    // achievement unlock popup items
                    if let arr = json["notifications"].array {
                        if (arr.count > 0) {
                            for i in 0...arr.count - 1 {
                                let achievementUnlocked = AchievementUnlockedItem.instance(arr[i])
                                self.achievementsUnlocked?.append(achievementUnlocked!)
                            }
                        }
                    }
                    
                    self.tableView.reloadData()
                    self.hideLoading()
                    
                    // show pop up
                    if (self.achievementsUnlocked?.count)! > 0 {
                        self.initPopUp()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                            self.setupPopUp((self.achievementsUnlocked?[0])!)
                            self.displayPopUp()
                        })
                    }
                }
                
            } else {
                
                self.hideLoading()
                self.navigationController?.popViewController(animated: true)
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
                return 1 + 1 + achievements![section - 1].conditions.count + achievements![section - 1].tiers.count + (achievements![section - 1].actionUri != nil ? 1 : 0) + 1
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
            // always open
            if ((indexPath as NSIndexPath).row == 0) {
                return 80
                
                // description cell
            } else if ((indexPath as NSIndexPath).row == 1) {
                let textRect = achievements![(indexPath as NSIndexPath).section - 1].desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 42)
                return CGFloat(Int(textRect.height + 4.5))
                
                // condition cell
            } else if ((indexPath as NSIndexPath).row > 1 && (indexPath as NSIndexPath).row <= achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1) {
                let textRect = achievements![(indexPath as NSIndexPath).section - 1].conditions[(indexPath as NSIndexPath).row - 2].conditionText.boundsWithFontSize(UIFont.systemFont(ofSize: 11), width: UIScreen.main.bounds.size.width - 80)
                return CGFloat(Int(textRect.height + 17.5)) + 4
                
                // tier icons cell
            } else if ((indexPath as NSIndexPath).row > achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1 && (indexPath as NSIndexPath).row <= achievements![(indexPath as NSIndexPath).section - 1].tiers.count + achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1) {
                let textRect = achievements![(indexPath as NSIndexPath).section - 1].tiers[(indexPath as NSIndexPath).row - (achievements?[(indexPath as NSIndexPath).section - 1].conditions.count)! - 2].name.boundsWithFontSize(UIFont.systemFont(ofSize: 11), width: UIScreen.main.bounds.size.width - 80)
                var incrementConstant = CGFloat(4)
                if ((indexPath as NSIndexPath).row - (achievements?[(indexPath as NSIndexPath).section - 1].conditions.count)! - 2) == 0 {
                    incrementConstant = 6
                }
                return CGFloat(Int(textRect.height + 17.5)) + incrementConstant
                
                // action cell
            } else if ((indexPath as NSIndexPath).row == achievements![(indexPath as NSIndexPath).section - 1].tiers.count + achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1 + 1 && achievements![(indexPath as NSIndexPath).section - 1].actionUri != nil) {
                let textRect = achievements![(indexPath as NSIndexPath).section - 1].actionTitle.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 42)
                return CGFloat(Int(textRect.height + 4.5))
                
                // border bottom
            } else {
                return 7
                
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
            
            let lblButton = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.width - 8, height: 40))
            
            lblButton.text = "BACA LEBIH LANJUT"
            lblButton.textColor = Theme.PrimaryColor
            lblButton.backgroundColor = UIColor.clear
            lblButton.textAlignment = .center
            
            let vwBorder = UIView(frame: CGRect(x: 4, y: 4, width: tableView.width - 8, height: 40))
            
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
                cell.lblDesc.textColor = Theme.GrayDark
                
                return cell
            } else if ((indexPath as NSIndexPath).row > 1 && (indexPath as NSIndexPath).row <= achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1) { // condition cell
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCellProgressCell") as! AchievementCellProgressCell
                
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor(hex: "E5E9EB")
                cell.clipsToBounds = true
                cell.adapt((achievements?[(indexPath as NSIndexPath).section - 1].conditions[(indexPath as NSIndexPath).row - 2])!)
                
                return cell
            } else if ((indexPath as NSIndexPath).row > achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1 && (indexPath as NSIndexPath).row <= achievements![(indexPath as NSIndexPath).section - 1].tiers.count + achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1) { // tier icons cell
                let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCellBadgeCell") as! AchievementCellBadgeCell
                
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor(hex: "E5E9EB")
                cell.clipsToBounds = true
                
                if ((indexPath as NSIndexPath).row - (achievements?[(indexPath as NSIndexPath).section - 1].conditions.count)! - 2) == 0 {
                    cell.vwSeparator.isHidden = false
                    cell.vwSeparator.backgroundColor = Theme.GrayDark
                    cell.consCentery.constant = 3
                    cell.consCenteryImage.constant = 3
                }
                
                cell.adapt((achievements?[(indexPath as NSIndexPath).section - 1].tiers[(indexPath as NSIndexPath).row - (achievements?[(indexPath as NSIndexPath).section - 1].conditions.count)! - 2])!)
                
                return cell
            } else if ((indexPath as NSIndexPath).row == achievements![(indexPath as NSIndexPath).section - 1].tiers.count + achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1 + 1 && achievements![(indexPath as NSIndexPath).section - 1].actionUri != nil) { // action cell
                let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCellDescriptionCell") as! AchievementCellDescriptionCell
                
                cell.selectionStyle = .none
                cell.backgroundColor = UIColor(hex: "E5E9EB")
                cell.clipsToBounds = true
                // adapt
                cell.lblDesc.isHidden = false
                cell.lblDesc.text = self.achievements![(indexPath as NSIndexPath).section - 1].actionTitle
                cell.lblDesc.textColor = Theme.PrimaryColor
                
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
            helpVC.url = "https://prelo.co.id/syarat-ketentuan/badge-achievement"
            helpVC.titleString = "Syarat dan Ketentuan"
            helpVC.contactPreloMode = true
            let baseNavC = BaseNavigationController()
            baseNavC.setViewControllers([helpVC], animated: false)
            self.present(baseNavC, animated: true, completion: nil)
        } else {
            if ((indexPath as NSIndexPath).row == 0) {
                isOpens[(indexPath as NSIndexPath).section] = !isOpens[(indexPath as NSIndexPath).section]
                tableView.reloadData()
            } else if ((indexPath as NSIndexPath).row == achievements![(indexPath as NSIndexPath).section - 1].tiers.count + achievements![(indexPath as NSIndexPath).section - 1].conditions.count + 1 + 1 && achievements![(indexPath as NSIndexPath).section - 1].actionUri != nil) { // action cell
                
                // deeplinking
                
//                Constant.showDialog("Open Deplink", message: ((achievements![(indexPath as NSIndexPath).section - 1].actionUri)?.path)! )
                
                self.openUrl(url: achievements![(indexPath as NSIndexPath).section - 1].actionUri!)
            }
        }
    }
    
    // MARK: - Deeplink
    func openUrl(url: URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            var param : [URLQueryItem] = []
            if let items = components.queryItems {
                param = items
            }
            if let del = UIApplication.shared.delegate as? AppDelegate {
                del.handleUniversalLink(url, path: components.path, param: param)
            }
        }
    }
    
    // MARK: - Pop up
    func setupPopUp(_ achievementUnlocked: AchievementUnlockedItem) {
        self.imgAchivement?.layoutIfNeeded()
        self.imgAchivement?.layer.cornerRadius = (self.imgAchivement?.width ?? 0) / 2
        self.imgAchivement?.layer.masksToBounds = true
        
        self.imgAchivement?.afSetImage(withURL: achievementUnlocked.icon!, withFilter: .circleWithBadgePlaceHolder)
        
        self.lblAchievement.text = achievementUnlocked.name
        self.lblDescription.text = achievementUnlocked.desc
    }
    
    func initPopUp() {
        // Transparent panel
        self.vwBackgroundOverlay.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        
        self.vwBackgroundOverlay.isHidden = false
        self.vwOverlayPopUp.isHidden = false
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
    }
    
    func displayPopUp() {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = screenHeight
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = (screenHeight - self.vwPopUp.frame.height) / 2
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = 0
    }
    
    func unDisplayPopUp() {
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height - 64 // navbar
        
        // force to bottom first
        self.consCenteryPopUp.constant = 0
        
        // 1
        let placeSelectionBar = { () -> () in
            // parent
            var curView = self.vwPopUp.frame
            curView.origin.y = screenHeight + (screenHeight - self.vwPopUp.frame.height) / 2
            self.vwPopUp.frame = curView
        }
        
        // 2
        UIView.animate(withDuration: 0.3, animations: {
            placeSelectionBar()
        })
        
        self.consCenteryPopUp.constant = screenHeight
    }
    
    @IBAction func btnAchievementPressed(_ sender: Any) {
        self.unDisplayPopUp()
        
        // increase position
        self.achievementsUnlockedPosition += 1
        
        if ((self.achievementsUnlocked?.count)! > self.achievementsUnlockedPosition) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                self.setupPopUp((self.achievementsUnlocked?[self.achievementsUnlockedPosition])!)
                self.displayPopUp()
            })
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                self.vwOverlayPopUp.isHidden = true
                self.vwBackgroundOverlay.isHidden = true
            })
        }
    }
}

class AchievementCelliOS9xx: UITableViewCell { // height 75 ++
    @IBOutlet weak var badgeImage: UIImageView!
    @IBOutlet weak var lblTitke: UILabel!
    @IBOutlet weak var lblArrow: UILabel! // V
    @IBOutlet weak var vwProgressBar: UIView! // default hidden
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var lblProgressView: UILabel!
    @IBOutlet weak var consHeightLblTitke: NSLayoutConstraint! // default 0 -> 15 -- progressbar height
    @IBOutlet weak var vwBorder: UIView!
    
    var achievement : AchievementItem!
    
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
        
        self.badgeImage?.afSetImage(withURL: achievement.icon!, withFilter: .circleWithBadgePlaceHolder)
        
        self.lblTitke.text = achievement.name
        
        if achievement.progressMax > 0 {
            self.consHeightLblTitke.constant = 15
            
            self.progressView.setProgress(Float(achievement.progressCurrent) / Float(achievement.progressMax) , animated: false)
            self.lblProgressView.text = achievement.progressCurrent.string + " / " + achievement.progressMax.string
            self.lblProgressView.textColor = (achievement.progressCurrent == 0 ? Theme.GrayLight : Theme.PrimaryColor)
        } else {
            self.consHeightLblTitke.constant = 0
            
        }
        
        
        self.lblArrow.text = (isOpen ? "" : "")
    }
    
}

class AchievementCellDescriptionCell : UITableViewCell { // height depent on description
    @IBOutlet weak var lblDesc: UILabel! // hidden
    @IBOutlet weak var vwBorder: UIView!
}

class AchievementCellProgressCell: UITableViewCell { // height 30
    @IBOutlet weak var lblCondition: UILabel!
    @IBOutlet weak var lblFullfilled: UILabel!
    
    // adapt
    func adapt(_ condition: AchievementConditionItem) {
        
        self.lblCondition.text = condition.conditionText
        self.lblFullfilled.isHidden = false
        self.lblFullfilled.backgroundColor = (condition.fulfilled == false ? UIColor.lightGray : Theme.PrimaryColor)
        
    }
}

class AchievementCellBadgeCell: UITableViewCell { // height 30
    @IBOutlet weak var tierImage: UIImageView!
    @IBOutlet weak var lblTierName: UILabel!
    @IBOutlet weak var vwBorder: UIView!
    @IBOutlet weak var vwSeparator: UIView! // height 1 default hidden
    @IBOutlet weak var consCentery: NSLayoutConstraint!
    @IBOutlet weak var consCenteryImage: NSLayoutConstraint!
    
    override func prepareForReuse() {
        self.vwSeparator.isHidden = true
        self.consCentery.constant = 0
        self.consCenteryImage.constant = 0
        
        self.tierImage?.afCancelRequest()
    }
    
    // adapt
    func adapt(_ tier: AchievementTierItem) {
        
        self.tierImage?.layoutIfNeeded()
        self.tierImage?.layer.cornerRadius = (self.tierImage?.width ?? 0) / 2
        self.tierImage?.layer.masksToBounds = true
        // local image
        self.tierImage?.afSetImage(withURL: tier.icon!, withFilter: .circleWithBadgePlaceHolder)
        
        self.lblTierName.text = tier.name
        self.lblTierName.textColor = (tier.isAchieved ? Theme.GrayDark : Theme.GrayLight)
    }
}


// MARK: - DiamondCell top
class AchievementDiamondCell: UITableViewCell { // 135 + lbldesc
    @IBOutlet weak var badgeImage: UIImageView!
    @IBOutlet weak var lblDiamond: UILabel!
    @IBOutlet weak var lblArrow: UILabel! // V
    @IBOutlet weak var lblDesc: UILabel! // hidden
    @IBOutlet weak var vwBorder: UIView!
    
    static func heightFor(_ isOpen: Bool) -> CGFloat {
        let standardHeight : CGFloat = 125.0
        let text = "Kumpulkan Diamond untuk dapat meng-up barang kamu secara gratis!"
        let textRect : CGRect = text.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 112)
        return standardHeight + (isOpen ? textRect.height + (AppTools.isIPad ? 30 : 10) : 0) + 10
    }
    
    func adapt(_ diamonds: Int, isOpen: Bool) {

        self.badgeImage?.layoutIfNeeded()
        self.badgeImage?.layer.cornerRadius = (self.badgeImage?.width ?? 0) / 2
        self.badgeImage?.layer.masksToBounds = true
        // local image
        self.badgeImage?.image = UIImage(named: "ic_coin.png")
        
        self.lblDiamond.text = diamonds.string + " Poin"
        
        self.lblDesc.text = "Kumpulkan Poin untuk digunakan di aplikasi Prelo. Saat ini Poin sudah dapat digunakan untuk meng-up barang secara gratis!"
        
        self.lblDesc.isHidden = !isOpen
        
        self.lblArrow.text = (isOpen ? "" : "")
        
    }
}

class ButtonCell : UITableViewCell { // height 40
    
}
