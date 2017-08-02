//
//  AddProductShareViewController2.swift
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
    var icon: String = "" // Google+
    var perc: Double = 0.0 // percentage -> 3%, 4%
    var isChecked: Bool = false
}

// MARK: - Class
class AddProductShareViewController2: BaseViewController {
    @IBOutlet weak var lbPrice: UILabel! // eq. captionPrice
    @IBOutlet weak var lbCharge: UILabel! // eq. captionCharge
    @IBOutlet weak var lbMaxCommisions: UILabel!
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
    
    var basePrice : Int64 = 0
    
    var localId: String = ""
    var productID: String = ""
    var me = CDUser.getOne()
    
    var productImg: String?
    var productImgImage: UIImage?
    var productName: String = ""
    var permalink: String!
    var linkToShare: String = AppTools.PreloBaseUrl
    var textToShare: String = ""
    
    var mgInstagram : MGInstagram?
    
    var first = true
    var shouldSkipBack = true
    
    var commisions = 10.0
    var maxCommisions = 200000.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.vwLoading.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.showLoading()
        
        // init tableView
        let AddProductShare2Cell = UINib(nibName: "AddProductShare2Cell", bundle: nil)
        self.tbSocmed.register(AddProductShare2Cell, forCellReuseIdentifier: "AddProductShare2Cell")
        
        self.title = "Kesempatan Terbatas"
        
        let maxCommisions = UserDefaults.standard.double(forKey: UserDefaultsKey.MaxCommisions)
        if maxCommisions > 0 {
            self.maxCommisions = maxCommisions
        }
        
        self.lbMaxCommisions.text = "Maksimal Charge Prelo sebesar " + Int(self.maxCommisions).asPrice
        
        // init data -> socmeds
        // adapt tbSocmed (data from backend ?)
        self.getSocmedData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ShareAddedProduct)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.first && self.shouldSkipBack {
            self.first = false
            super.viewDidAppear(animated)
            var m = self.navigationController?.viewControllers
            m?.remove(at: (m?.count)!-2)
            self.navigationController?.viewControllers = m!
        } else {
            self.countPercentage()
        }
        
        self.linkToShare = "\(AppTools.PreloBaseUrl)/p/\(self.permalink)"
        self.textToShare = "Temukan barang bekas berkualitas-ku, \(self.productName) di Prelo hanya dengan harga \(self.basePrice.asPrice). Nikmati mudahnya jual-beli barang bekas berkualitas dengan aman dari ponselmu. Download aplikasinya sekarang juga di http://prelo.co.id #PreloID"
    }
    
    func getSocmedData() {
        let comTwitter = UserDefaults.standard.double(forKey: UserDefaultsKey.ComTwitter)
        let comFacebook = UserDefaults.standard.double(forKey: UserDefaultsKey.ComFacebook)
        let comInstagram = UserDefaults.standard.double(forKey: UserDefaultsKey.ComInstagram)
        
        //self.commisions = comTwitter + comFacebook + comInstagram // 10
        
        self.socmeds = []
        //self.socmeds.append(SocmedItem(name: "Google+", icon: "", perc: 3.0, isChecked: false))
        self.socmeds.append(SocmedItem(name: "Instagram", icon: "", perc: comInstagram, isChecked: false))
        self.socmeds.append(SocmedItem(name: "Facebook", icon: "", perc: comFacebook, isChecked: false))
        self.socmeds.append(SocmedItem(name: "Twitter", icon: "", perc: comTwitter, isChecked: false))
        
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
        
        var selisih = self.commisions
        
        for socmedItem in socmeds {
            if !socmedItem.isChecked {
                p += socmedItem.perc
            }
            selisih -= socmedItem.perc
        }
        p += selisih
        if p > 0.0 {
            charge = Double(basePrice) * p / 100.0
            if charge > maxCommisions {
                charge = maxCommisions
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
    func setSelectShare(_ indexPath: IndexPath) {
        
        let index = indexPath.row
        
        self.btnSell.setTitle("Loading..", for: UIControlState.disabled)
        
        if !self.socmeds[index].isChecked { // Akan mengaktifkan tombol share
            self.showLoading()
            if (self.socmeds[index].name == "Google+") {
                // Google+
                
                // TODO: - Implement Google+ Share
                // Dependent on Google Sign-in (maybe)
                // Tutorial: https://developers.google.com/+/mobile/ios/share/
                
                self.updateButton(indexPath)
                self.hideLoading()
            } else if (self.socmeds[index].name == "Instagram") {
                if (UIApplication.shared.canOpenURL(URL(string: "instagram://app")!)) {
                    var hashtags = ""
                    if let categId = sendProductParam["category_id"] {
                        if let h = CDCategory.getCategoryHashtagsWithID(categId!) {
                            hashtags = " \(h)"
                        }
                    }
                    
                    if let img = self.productImgImage {
                        let instagramSharePreview : InstagramSharePreview = .fromNib()
                        instagramSharePreview.textToShare.text = "\(self.textToShare)\(hashtags)"
                        instagramSharePreview.textToShare.layoutIfNeeded()
                        instagramSharePreview.imgToShare.image = img
                        instagramSharePreview.copyAndShare = {
                            UIPasteboard.general.string = "\(self.textToShare)\(hashtags)"
                            Constant.showDialog("Text sudah disalin ke clipboard", message: "Silakan paste sebagai deskripsi post Instagram kamu")
                            self.mgInstagram = MGInstagram()
                            self.mgInstagram?.post(img, withCaption: self.textToShare, in: self.view, delegate: self)
                            
                            self.updateButton(indexPath)
                            self.hideLoading()
                            instagramSharePreview.removeFromSuperview()
                        }
                        instagramSharePreview.frame = CGRect(x: 0, y: -64, width: AppTools.screenWidth, height: AppTools.screenHeight)
                        self.view.addSubview(instagramSharePreview)
                    } else {
                        Constant.showDialog("Instagram Share", message: "Oops, terdapat kesalahan saat pemrosesan")
                        self.hideLoading()
                    }
                } else {
                    Constant.showDialog("No Instagram app", message: "Silakan install Instagram dari app store terlebih dahulu")
                    self.hideLoading()
                }
            } else if (self.socmeds[index].name == "Facebook") {
                if (FBSDKAccessToken.current() != nil && FBSDKAccessToken.current().permissions.contains("publish_actions")) {
                    self.updateButton(indexPath)
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
                                    
                                    self.updateButton(indexPath)
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
                if (User.IsLoggedInTwitter) {
                    self.updateButton(indexPath)
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
                                
                                self.updateButton(indexPath)
                                self.hideLoading()
                            } else {
                                LoginViewController.LoginTwitterCancelled(self, reason: "Terdapat kesalahan saat menyimpan data Twitter")
                            }
                        }
                    })
                }
            }
        } else { // Akan menonaktifkan tombol share
            self.updateButton(indexPath)
        }
    }
    
    func updateButton(_ indexPath: IndexPath) {
        self.socmeds[indexPath.row].isChecked = !self.socmeds[indexPath.row].isChecked
        self.tbSocmed.reloadRows(at: [indexPath], with: .fade)
        self.countPercentage()
    }
    
    // btnSend
    @IBAction func btnSellPressed(_ sender: Any) {
        btnSell.isEnabled = false
        
        var g = "0", i = "0", f = "0", t = "0"
        
        for s in socmeds {
            if s.isChecked {
                if s.name == "Google+" {
                    g = "1"
                } else if s.name == "Instagram" {
                    i = "1"
                } else if s.name == "Facebook" {
                    f = "1"
                } else if s.name == "Twitter" {
                    t = "1"
                }
            }
        }
        
        sendProduct(g, instagram: i, facebook: f, twitter: t)
    }
    
    // after btnSellPressed
    func sendProduct(_ google : String = "0", instagram : String = "0", facebook : String = "0", twitter : String = "0")
    {
        self.sendProductParam["google+"] = google
        self.sendProductParam["instagram"] = instagram
        self.sendProductParam["facebook"] = facebook
        self.sendProductParam["twitter"] = twitter
        
        // auto approve
        if AppTools.isDev && !AppTools.IsPreloProduction {
            self.sendProductParam["status"] = "1"
        }
        
        // Prelo Analytic - Share Product
        let loginMethod = User.LoginMethod ?? ""
        let ig = Int(instagram) ?? 0
        let fb = Int(facebook) ?? 0
        let tw = Int(twitter) ?? 0
        let gp = Int(google) ?? 0
        let pdata = [
            "Local ID": self.localId,
            "Product Name" : productName,
            "Instagram" : ig,
            "Facebook" : fb,
            "Twitter" : tw,
            "Google+" : gp
        ] as [String : Any]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.ShareProduct, data: pdata, previousScreen: self.sendProductBeforeScreen, loginMethod: loginMethod)
        
        // Add product to product uploader
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
            AppDelegate.Instance.produkUploader.addToQueue(ProdukUploader.ProdukLokal(produkParam: self.sendProductParam, produkImages: self.sendProductImages, preloAnalyticParam: pdata as [AnyHashable: Any]))
            DispatchQueue.main.async(execute: {
                if (AppDelegate.Instance.produkUploader.getQueue().count > 0) {
                    
                    // set state is uploading
                    CDDraftProduct.setUploading(self.localId, isUploading: true)
                    
                    let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let b = mainStoryboard.instantiateViewController(withIdentifier: Tags.StoryBoardIdMyProducts) as! MyProductViewController
                    self.navigationController?.pushViewController(b, animated: true)
                } else {
                    Crashlytics.sharedInstance().recordCustomExceptionName("ProdukUploader", reason: "Empty Queue", frameArray: [])
                    Constant.showDialog("Warning", message: "Oops, terdapat kesalahan saat mengupload barang kamu.\nMohon coba upload foto utama dan foto merek terlebih dahulu, kemudian tambah foto melalui fitur edit.")
                }
            })
        })
        return
    }
    
    // MARK: - Other
    func showLoading() {
        self.vwLoading.isHidden = false
        self.btnSell.isEnabled = false
    }
    
    func hideLoading() {
        self.vwLoading.isHidden = true
        self.btnSell.isEnabled = true
    }
}

// MARK: - TableView Delegate
extension AddProductShareViewController2: UITableViewDelegate, UITableViewDataSource {
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
        self.setSelectShare(indexPath)
    }
}

extension AddProductShareViewController2: InstagramLoginDelegate, UIDocumentInteractionControllerDelegate {
    func instagramLoginFailed() {
        
    }
    
    func instagramLoginSuccess(_ token: String, id: String, name: String) {
        
    }
    
    func instagramLoginSuccess(_ token: String) {
        // API Migrasi
        let _ = request(APISocmed.storeInstagramToken(token: token)).responseJSON {resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Store Instagram Token")) {
                
            } else {
                // TODO: disable
            }
        }
    }
}

// MARK: - Cell
class AddProductShare2Cell: UITableViewCell {
    @IBOutlet weak var lbCheckbox: UILabel! // checked or not
    @IBOutlet weak var imgIcon: UILabel! // icon of lbTitle
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
        self.imgIcon.text = socmedItem.icon
        self.lbPercentage.text = "+ " + socmedItem.perc.roundString + "%"
        
        self.selectionStyle = .none
        
        if socmedItem.isChecked {
            self.lbCheckbox.isHidden = false
            self.imgIcon.textColor = Theme.ThemeOrange
            self.lbTitle.textColor = Theme.ThemeOrange
            self.lbPercentage.textColor = Theme.ThemeOrange
        } else {
            self.lbCheckbox.isHidden = true
            self.imgIcon.textColor = placeholderColor
            self.lbTitle.textColor = placeholderColor
            self.lbPercentage.textColor = placeholderColor
        }
    }
}
