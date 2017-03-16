//
//  PreloMessageViewController.swift
//  Prelo
//
//  Created by Djuned on 3/15/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import Alamofire


// MARK: - Class
class PreloMessageViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    var messages: Array<PreloMessageItem>? // PreloMessageItem
    var isOpens: Array<Bool> = []
    var isFirst: Bool = true
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let PreloMessageCell = UINib(nibName: "PreloMessageCell", bundle: nil)
        tableView.register(PreloMessageCell, forCellReuseIdentifier: "PreloMessageCell")
        
        // title
        self.title = "Prelo Message"
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
            let inset = UIEdgeInsetsMake(0, 0, 4, 0)
            tableView.contentInset = inset
            
            tableView.separatorStyle = .none
            
            tableView.backgroundColor = UIColor(hexString: "#E8ECEE") //UIColor(hex: "E5E9EB")
            
            getMessage()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.PreloMessage)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getMessage() {
        // clean badges
        self.messages = []
        self.isOpens = []
        
        let _ = request(APIPreloMessage.getMessage).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Get Prelo Message")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if let _messages = data["messages"].array {
                    var curMessages : Array<PreloMessageItem> = []
                    for m in _messages {
                        let message = PreloMessageItem.instance(m)
                        curMessages.append(message!)
                        self.isOpens.append(false)
                    }
                    self.messages = curMessages.reversed()
                    self.tableView.reloadData()
                    self.hideLoading()
                } else {
                    _ = self.navigationController?.popViewController(animated: true)
                    self.hideLoading()
                }
            } else {
                _ = self.navigationController?.popViewController(animated: true)
                self.hideLoading()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages!.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return PreloMessageCell.heightFor((messages?[(indexPath as NSIndexPath).row])!, isOpen: isOpens[(indexPath as NSIndexPath).row])
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PreloMessageCell") as! PreloMessageCell
        
        let idx = (indexPath as NSIndexPath).row
        let m = (messages?[idx])!
        
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor(hexString: "#E8ECEE")
        cell.clipsToBounds = true
        cell.adapt(m, isOpen: isOpens[idx])
        
        cell.readMore = {
            self.isOpens[(indexPath as NSIndexPath).row] = true
            tableView.reloadData()
        }
        
        cell.zoomImage = {
//            if m.bannerUri != nil {
//                var urlStr = m.bannerUri!.absoluteString
//                if !urlStr.contains("http://") {
//                    urlStr = "http://" + m.bannerUri!.absoluteString
//                }
//                let curl = URL(string: urlStr)!
//                self.openUrl(url: curl)
//            } else {
                let c = CoverZoomController()
                c.labels = [(m.isContainAttachment ? "pesan gambar" : (m.title == "" ? "Prelo Message" : m.title))]
                c.images = [(m.banner?.absoluteString)!]
                c.index = 0
                self.navigationController?.present(c, animated: true, completion: nil)
//            }
        }
        
        cell.openUrl = { url in
            self.openUrl(url: url)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // do nothing
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
}

// MARK: - PreloMessageCell
class PreloMessageCell: UITableViewCell {
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDesc: ActiveLabel!
    @IBOutlet weak var consHeightBannerImage: NSLayoutConstraint! // default 0 -> 128
    @IBOutlet weak var vwBorder: UIView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var btnReadMore: UIButton! // hidden
    @IBOutlet weak var consTopLblDate: NSLayoutConstraint! // 25.5 -> 4
    @IBOutlet weak var vwGradient: UIView!
    
    var headerUri: URL?
    
    var readMore : ()->() = {}
    var zoomImage: ()->() = {}
    var openUrl  : (_ url: URL)->() = {_ in }
    
    static func heightFor(_ message : PreloMessageItem, isOpen: Bool) -> CGFloat {
        let standardHeight : CGFloat = 148.0 - 67.0 + 4
        let heightBanner : CGFloat = (((UIScreen.main.bounds.width - 8) / 1024.0) * 337.0)
        let textRect = message.desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 24)
        return standardHeight + (isOpen ? textRect.height - 21.5 : (84.0 > textRect.height ? textRect.height - 21.5 : 67.0)) + (message.banner != nil ? heightBanner : 0) + (message.title == "" ? -20 : 0)
        
    }
    
    func adapt(_ message : PreloMessageItem, isOpen: Bool) {
        if message.banner != nil {
            let height = (((UIScreen.main.bounds.width - 8) / 1024.0) * 337.0)
            self.consHeightBannerImage.constant = height
            self.bannerImage.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 8, height: height)
            
            self.bannerImage.afSetImage(withURL: message.banner!, withFilter: .fillWithPreloMessagePlaceHolder)
            
            if message.bannerUri != nil {
                self.headerUri = message.bannerUri!
                vwGradient.isHidden = false
                
                let gradient: CAGradientLayer = CAGradientLayer()
                
                gradient.frame = vwGradient.bounds
                
                gradient.colors = [UIColor.colorWithColor(UIColor.white, alpha: 0).cgColor, UIColor.colorWithColor(UIColor.white, alpha: 1).cgColor]
                gradient.locations = [0.0 , 1.0]
                gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
                gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
                
                if vwGradient.layer.sublayers?.count != nil && (vwGradient.layer.sublayers?.count)! > 1 {
                    vwGradient.layer.sublayers?[0].removeFromSuperlayer()
                }
                
                vwGradient.layer.insertSublayer(gradient, at: 0)
            } else {
                vwGradient.isHidden = true
            }
        } else {
            self.consHeightBannerImage.constant = 0
        }
        
        self.btnReadMore.setTitleColor(Theme.PrimaryColorDark)
        
        self.lblTitle.text = message.title
        self.lblDate.text = message.date
        
        let customType = ActiveType.custom(pattern: "\\sprelo.co.id[^\\s]*") //Regex that looks for " prelo.co.id/* "
        self.lblDesc.enabledTypes = [/*.mention, .hashtag,*/ .url, customType]
        
        self.lblDesc.URLColor = Theme.PrimaryColorDark
        self.lblDesc.URLSelectedColor = Theme.PrimaryColorDark
        
        self.lblDesc.customColor[customType] = Theme.PrimaryColorDark
        self.lblDesc.customSelectedColor[customType] = Theme.PrimaryColorDark
        
        self.lblDesc.handleURLTap{ url in
            var urlStr = url.absoluteString
            if !urlStr.contains("http://") {
                urlStr = "http://" + url.absoluteString
            }
            let curl = URL(string: urlStr)!
            self.openUrl(curl)
        }
        
        self.lblDesc.handleCustomTap(for: customType) { element in
            var urlStr = element
            if !urlStr.contains("http://") {
                urlStr = "http://" + element
            }
            let curl = URL(string: urlStr)!
            self.openUrl(curl)
        }
        
        self.lblDesc.text = message.desc
        
        if message.desc == "pesan gambar" {
            self.lblDesc.font = UIFont.italicSystemFont(ofSize: 14)
            self.lblDesc.textColor = UIColor.lightGray
        }
        
        if isOpen {
            self.lblDesc.numberOfLines = 0
        } else {
            self.lblDesc.numberOfLines = 4
        }
        
        let textRect = message.desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 24)
        if textRect.height <= 84.0 && textRect.height >= 67.0 {
            self.lblDesc.numberOfLines = 5
        }
        
        if textRect.height > 84.0 && !isOpen {
            self.btnReadMore.isHidden = false
            self.consTopLblDate.constant = 29.5
        } else {
            self.btnReadMore.isHidden = true
            self.consTopLblDate.constant = 8
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.bannerImage.afCancelRequest()
        self.lblDesc.font = UIFont.systemFont(ofSize: 14)
        self.lblDesc.textColor = UIColor.init(hex: "#555555")
    }
    
    @IBAction func btnReadMorePressed(_ sender: Any) {
        self.readMore()
    }
    
    @IBAction func btnBannerImagePressed(_ sender: Any) {
        self.zoomImage()
    }
    
    @IBAction func btnBannerLinkPressed(_ sender: Any) {
        if self.headerUri != nil {
            var urlStr = self.headerUri!.absoluteString
            if !urlStr.contains("http://") {
                urlStr = "http://" + self.headerUri!.absoluteString
            }
            let curl = URL(string: urlStr)!
            self.openUrl(curl)
        }
    }
}
