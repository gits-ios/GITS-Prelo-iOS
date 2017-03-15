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
        
        var fakeres = [
            "title":"Prelo Mesage",
            "banner":"http://www.dmidgroup.com/wp-content/uploads/2015/07/indomaret-01-01.jpg",
            "description":"sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja https://prelo.co.id prelo.co.id/ Prelo.co.Id/santensuru",
            "date": "7 November 2017"
            ] as [String : Any]
        
        var json = JSON(fakeres)
        var message = PreloMessageItem.instance(json)
        self.messages?.append(message!)
        
        isOpens.append(false)
        
        fakeres = [
            "title":"Prelo Mesage 2",
            "description":"sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja https://prelo.co.id prelo.co.id/ Prelo.co.Id/santensuru",
            "date": "7 November 2017"
            ] as [String : Any]
        
        json = JSON(fakeres)
        message = PreloMessageItem.instance(json)
        self.messages?.append(message!)
        
        isOpens.append(false)
        
        fakeres = [
            "title":"Prelo Mesage 3",
            "description":"sample deskripsi aja sample deskripsi aja sample deskripsi aja sample deskripsi aja https://google.co.id",
            "date": "7 November 2017"
            ] as [String : Any]
        
        json = JSON(fakeres)
        message = PreloMessageItem.instance(json)
        self.messages?.append(message!)
        
        isOpens.append(false)
        
        self.hideLoading()
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
        
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor(hexString: "#E8ECEE") //UIColor(hex: "E5E9EB")
        cell.clipsToBounds = true
        cell.adapt((messages?[(indexPath as NSIndexPath).row])!, isOpen: isOpens[(indexPath as NSIndexPath).row])
        
        cell.readMore = {
            self.isOpens[(indexPath as NSIndexPath).row] = true
            tableView.reloadData()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

class PreloMessageCell: UITableViewCell {
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDesc: ActiveLabel!
    @IBOutlet weak var consHeightBannerImage: NSLayoutConstraint! // default 0 -> 128
    @IBOutlet weak var vwBorder: UIView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var btnReadMore: UIButton! // hidden
    @IBOutlet weak var consTopLblDate: NSLayoutConstraint! // 25.5 -> 4
    
    var readMore : ()->() = {}
    
    static func heightFor(_ message : PreloMessageItem, isOpen: Bool) -> CGFloat {
        let standardHeight : CGFloat = 148.0 - 67.0 + 4
        let heightBanner : CGFloat = 128.0
        let textRect = message.desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 24)
        return standardHeight + (isOpen ? textRect.height - 21.5 : (67.0 > textRect.height ? textRect.height - 21.5 : 67.0)) + (message.banner != nil ? heightBanner : 0)
        
    }
    
    func adapt(_ message : PreloMessageItem, isOpen: Bool) {
        if message.banner != nil {
            self.consHeightBannerImage.constant = 128
            self.bannerImage.afSetImage(withURL: message.banner!)
        } else {
            self.consHeightBannerImage.constant = 0
        }
        
        self.btnReadMore.setTitleColor(Theme.PrimaryColorDark)
        
        self.lblTitle.text = message.title
        self.lblDate.text = message.date
        
        let customType = ActiveType.custom(pattern: "prelo.co.id[^\\s]*") //Regex that looks for "prelo.co.id/"
        self.lblDesc.enabledTypes = [/*.mention, .hashtag,*/ .url, customType]
        
        self.lblDesc.URLColor = Theme.PrimaryColorDark
        self.lblDesc.URLSelectedColor = Theme.PrimaryColorDark
        
        self.lblDesc.customColor[customType] = Theme.PrimaryColorDark
        self.lblDesc.customSelectedColor[customType] = Theme.PrimaryColorDark
        
        self.lblDesc.handleURLTap{ url in
            self.openUrl(url: url)
        }
        
        self.lblDesc.handleCustomTap(for: customType) { element in
            var urlStr = element
            if !urlStr.contains("https://") {
                urlStr = "https://" + element
            }
            let url = URL(string: urlStr)!
            self.openUrl(url: url)
        }
        
        self.lblDesc.text = message.desc
        
        if isOpen {
            self.lblDesc.numberOfLines = 0
        } else {
            self.lblDesc.numberOfLines = 4
        }
        
        let textRect = message.desc.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width - 24)
        if textRect.height > 67.0 && !isOpen {
            self.btnReadMore.isHidden = false
            self.consTopLblDate.constant = 25.5
        } else {
            self.btnReadMore.isHidden = true
            self.consTopLblDate.constant = 4
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.bannerImage.afCancelRequest()
    }
    
    @IBAction func btnReadMorePressed(_ sender: Any) {
        self.readMore()
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
