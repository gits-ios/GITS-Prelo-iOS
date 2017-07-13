//
//  AddProductShare2ViewController.swift
//  Prelo
//
//  Created by Djuned on 7/11/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import UIKit
import TwitterKit
import Social
import Crashlytics
import Alamofire

//--------------------
// AddProductShare VC
//--------------------

// MARK: - Struct
struct SocmedItem {
    var name: String = "" // Google+, FB, TW
    var icon: String = "placeholder-standar-white"
    var perc: Double = 0.0 // percentage -> 3%, 4%
    var isChecked: Bool = false
}

// MARK: - Class
class AddProductShare2ViewController: BaseViewController {
    @IBOutlet weak var lbPrice: UILabel! // eq. captionPrice
    @IBOutlet weak var lbCharge: UILabel! // eq. captionCharge
    @IBOutlet weak var tbSocmed: UITableView!
    @IBOutlet weak var consHeightTbSocmed: NSLayoutConstraint!
    @IBOutlet weak var lbPercentage: UILabel! // eq. captionChargePercent
    @IBOutlet weak var btnSell: UIButton! // eq. btnSend
    @IBOutlet weak var vwLoading: UIView! // eq. loadingPanel
    
    var sendProductParam : [String : String?] = [:]
    var sendProductImages : [AnyObject] = []
    var sendProductBeforeScreen = ""
    var sendProductKondisi = ""
    
    var socmeds: Array<SocmedItem> = []
    
    var basePrice : Int64 = 925000
    
    var localId: String = ""
    var productId: String = ""
    var me = CDUser.getOne()
    
    var productImg: String?
    var productImgImage: UIImage?
    var productName: String = ""
    var permalink: String!
    var linkToShare: String = AppTools.PreloBaseUrl
    var textToShare: String = ""
    
    var first = true
    var shouldSkipBack = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.vwLoading.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.showLoading()
        
        // init tableView
        let AddProductShare2Cell = UINib(nibName: "AddProductShare2Cell", bundle: nil)
        self.tbSocmed.register(AddProductShare2Cell, forCellReuseIdentifier: "AddProductShare2Cell")
        
        self.title = "Kesempatan Terbatas"
        
        // init data -> socmeds
        // adapt tbSocmed (data from backend ?)
        self.getSocmedData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.first && self.shouldSkipBack {
            self.first = false
            super.viewDidAppear(animated)
            var m = self.navigationController?.viewControllers
            m?.remove(at: (m?.count)!-2)
            self.navigationController?.viewControllers = m!
        }
        
        self.linkToShare = "\(AppTools.PreloBaseUrl)/p/\(self.permalink)"
        self.textToShare = "Temukan barang bekas berkualitas-ku, \(self.productName) di Prelo hanya dengan harga \(self.basePrice.asPrice). Nikmati mudahnya jual-beli barang bekas berkualitas dengan aman dari ponselmu. Download aplikasinya sekarang juga di http://prelo.co.id #PreloID"
    }
    
    func getSocmedData() {
        self.socmeds = []
        self.socmeds.append(SocmedItem(name: "Google+", icon: "ic_socmed_path", perc: 3.0, isChecked: false))
        self.socmeds.append(SocmedItem(name: "Facebook", icon: "ic_socmed_facebook", perc: 4.0, isChecked: false))
        self.socmeds.append(SocmedItem(name: "Twitter", icon: "ic_socmed_twitter", perc: 3.0, isChecked: false))
        
        // TODO: - From backend
        
        self.setupSocmed()
    }
    
    func setupSocmed() {
        if self.tbSocmed.delegate == nil || self.tbSocmed.dataSource == nil {
            self.tbSocmed.delegate = self
            self.tbSocmed.dataSource = self
        }
        
        self.consHeightTbSocmed.constant = CGFloat(self.socmeds.count) * AddProductShare2Cell.heightFor()
        
        self.tbSocmed.reloadData()
        self.countPercentage()
        
        self.hideLoading()
    }
    
    // recount final percentage
    func countPercentage() {
        var p: Double = 0.0
        var percentage = "Charge Prelo: "
        var charge = 0.0
        var attString = NSMutableAttributedString()
        
        for socmedItem in socmeds {
            if !socmedItem.isChecked {
                p += socmedItem.perc
            }
        }
        if p > 0.0 {
            charge = Double(basePrice) * p / 100.0
            if charge > 200000.0 {
                charge = 200000.0
            }
            percentage += Int64(charge).asPrice + " (" + p.roundString + "%)"
            attString = NSMutableAttributedString(string: percentage)
            attString.addAttributes([NSForegroundColorAttributeName:UIColor.red], range: AppToolsObjC.range(of: p.roundString+"%", inside: percentage))
        } else {
            percentage += "FREE"
            attString = NSMutableAttributedString(string: percentage)
            attString.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColorLight], range: AppToolsObjC.range(of: "FREE", inside: percentage))
        }
        
        self.lbCharge.attributedText = attString
        self.lbPrice.text = (basePrice - Int64(charge)).asPrice
        self.lbPercentage.text = (100.0 - p).roundString + "%"
    }
    
    // MARK: - button action
    func setSelectShare(_ index: Int) {
        self.btnSell.setTitle("Loading..", for: UIControlState.disabled)
        
        if (self.socmeds[index].name == "Google+") {
            // Google+
            self.socmeds[index].isChecked = !self.socmeds[index].isChecked
            self.hideLoading()
        } else if (self.socmeds[index].name == "Facebook") {
            self.showLoading()
            
            if (FBSDKAccessToken.current() != nil && FBSDKAccessToken.current().permissions.contains("publish_actions")) {
                self.socmeds[index].isChecked = !self.socmeds[index].isChecked
                self.hideLoading()
            } else {
                let p = ["sender" : self]
                LoginViewController.LoginWithFacebook(p, onFinish: { result in
                    // Handle Profile Photo URL String
                    let userId =  result["id"] as? String
                    let name = result["name"] as? String
                    let accessToken = FBSDKAccessToken.current().tokenString
                    
                    //print("result = \(result)")
                    //print("accessToken = \(accessToken)")
                    
                    // userId & name is required
                    if (userId != nil && name != nil) {
                        // API Migrasi
                        let _ = request(APISocmed.postFacebookData(id: userId!, username: name!, token: accessToken!)).responseJSON {resp in
                            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Facebook")) {
                                
                                // Save in core data
                                let userOther : CDUserOther = CDUserOther.getOne()!
                                userOther.fbID = userId
                                userOther.fbUsername = name
                                userOther.fbAccessToken = accessToken
                                UIApplication.appDelegate.saveContext()
                                self.socmeds[index].isChecked = !self.socmeds[index].isChecked
                                self.hideLoading()
                            } else {
                                LoginViewController.LoginFacebookCancelled(self, reason: "Terdapat kesalahan saat menyimpan data Facebook")
                            }
                        }
                    } else {
                        LoginViewController.LoginFacebookCancelled(self, reason: "Terdapat kesalahan data saat login Facebook")
                    }
                })
            }
        } else if (self.socmeds[index].name == "Twitter") {
            self.showLoading()
            
            if (User.IsLoggedInTwitter) {
                self.socmeds[index].isChecked = !self.socmeds[index].isChecked
                self.hideLoading()
            } else {
                let p = ["sender" : self]
                LoginViewController.LoginWithTwitter(p, onFinish: { result in
                    guard let twId = result["twId"] as? String,
                        let twUsername = result["twUsername"] as? String,
                        let twToken = result["twToken"] as? String,
                        let twSecret = result["twSecret"] as? String else {
                            LoginViewController.LoginTwitterCancelled(self, reason: "Terdapat kesalahan saat memproses data Twitter")
                            return
                    }
                    
                    let _ = request(APISocmed.postTwitterData(id: twId, username: twUsername, token: twToken, secret: twSecret)).responseJSON { resp in
                        if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Login Twitter")) {
                            
                            // Save in core data
                            if let userOther : CDUserOther = CDUserOther.getOne() {
                                userOther.twitterID = twId
                                userOther.twitterUsername = twUsername
                                userOther.twitterAccessToken = twToken
                                userOther.twitterTokenSecret = twSecret
                                UIApplication.appDelegate.saveContext()
                            }
                            self.socmeds[index].isChecked = !self.socmeds[index].isChecked
                            self.hideLoading()
                        } else {
                            LoginViewController.LoginTwitterCancelled(self, reason: "Terdapat kesalahan saat menyimpan data Twitter")
                        }
                    }
                })
            }
        }
    }
    
    @IBAction func btnSellPressed(_ sender: Any) {
        
    }
    
    // MARK: - Other
    func showLoading() {
        self.vwLoading.isHidden = false
    }
    
    func hideLoading() {
        self.vwLoading.isHidden = true
    }
}

// MARK: - TableView Delegate
extension AddProductShare2ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.socmeds.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AddProductShare2Cell.heightFor()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddProductShare2Cell") as! AddProductShare2Cell
        
        cell.adapt(self.socmeds[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.btnSell.isEnabled = false
        self.setSelectShare(indexPath.row)
        self.btnSell.isEnabled = true
        self.tbSocmed.reloadRows(at: [indexPath], with: .fade)
        self.hideLoading()
        
        self.countPercentage()
    }
}

// MARK: - Cell
class AddProductShare2Cell: UITableViewCell {
    @IBOutlet weak var lbCheckbox: UILabel! // checked or not
    @IBOutlet weak var imgIcon: UIImageView! // icon of lbTitle
    @IBOutlet weak var lbTitle: UILabel! // Google+, FB, TW
    @IBOutlet weak var lbPercentage: UILabel! // dynamic -> 3%, 4%, etc
    
    var placeholderColor = UIColor.init(hex: "#CCCCCC")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    static func heightFor() -> CGFloat {
        return 40.0
    }
    
    func adapt(_ socmedItem: SocmedItem) {
        self.lbTitle.text = socmedItem.name
        self.imgIcon.image = UIImage(named: socmedItem.icon)?.withRenderingMode(.alwaysTemplate)
        self.lbPercentage.text = "+ " + socmedItem.perc.roundString + "%"
        
        self.selectionStyle = .none
        
        if socmedItem.isChecked {
            self.lbCheckbox.isHidden = false
            self.imgIcon.tintColor = Theme.ThemeOrange
            self.lbTitle.textColor = Theme.ThemeOrange
            self.lbPercentage.textColor = Theme.ThemeOrange
        } else {
            self.lbCheckbox.isHidden = true
            self.imgIcon.tintColor = placeholderColor
            self.lbTitle.textColor = placeholderColor
            self.lbPercentage.textColor = placeholderColor
        }
    }
}
