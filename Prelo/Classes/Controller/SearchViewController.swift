//
//  SearchViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/6/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import MessageUI
import Alamofire

// MARK: - Class

class SearchViewController: BaseViewController, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, MFMailComposeViewControllerDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var sectionTopSearch : UIView!
    @IBOutlet weak var sectionHistorySearch : UIView!
    @IBOutlet weak var topSearchLoading : UIActivityIndicatorView!
    @IBOutlet weak var conHeightSectionTopSearch : NSLayoutConstraint!
    @IBOutlet weak var conHeightSectionHistorySearch : NSLayoutConstraint!
    @IBOutlet weak var vwZeroResult: UIView!
    @IBOutlet weak var lblZeroResult: UILabel!
    @IBOutlet weak var loadingPanel: UIView!
    var searchBar : UISearchBar!
    @IBOutlet weak var btnHapusRiwayat: BorderedButton!
    
    // Data container
    var foundItems : [Product] = []
    var foundUsers : [SearchUser] = []
    var foundBrands : [SearchBrand] = []
    var currentRequest : Request?
    var currentKeyword = ""
    let ResultLimit = 3
    
    // Section
    let SectionItem = 0
    let SectionUser = 1
    let SectionBrand = 2
    
    // Predefined value
    var currentCategoryId : String = "" // Category id terakhir yg dilihat di home
    
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.5)
        self.hideLoading()
        
        // Nib register
        tableView.register(UINib(nibName: "SearchResultHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "head")
        
        // Search bar setup
        var searchBarWidth = UIScreen.main.bounds.size.width * 0.8375
        if (AppTools.isIPad) {
            searchBarWidth = UIScreen.main.bounds.size.width - 68
        }
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: searchBarWidth, height: 30))
        if let searchField = self.searchBar.value(forKey: "searchField") as? UITextField {
            searchField.backgroundColor = Theme.PrimaryColorDark
            searchField.textColor = UIColor.white
            let attrPlaceholder = NSAttributedString(string: "Cari di Prelo", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
            searchField.attributedPlaceholder = attrPlaceholder
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.withRenderingMode(.alwaysTemplate)
                icon.tintColor = UIColor.lightGray
            }
            searchField.borderStyle = UITextBorderStyle.none
        }
        searchBar.delegate = self
        searchBar.placeholder = "Cari di Prelo"
        self.navigationItem.rightBarButtonItem = searchBar.toBarButton()
        
        // Top search setup
        let _ = request(APISearch.getTopSearch(limit: "10")).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Top Search")) {
                self.topSearchLoading.isHidden = true
                let json = JSON(resp.result.value!)
                if let data = json["_data"].array {
                    if (data.count > 0) {
                        var saveY : CGFloat! = 0
                        var lastView : UIView?
                        for i in 0...data.count - 1 {
                            let ts = data[i]
                            let name = ts["name"].stringValue
                            if (name.replacingOccurrences(of: " ", with: "") == "") {
                                continue
                            }
                            // Adjust search tag
                            let searchTag = SearchTag.instance(name)
                            if let lv = lastView {
                                saveY = lv.maxY > saveY ? lv.maxY : saveY
                                let x = lv.maxX + 8
                                searchTag.x = x
                                
                                if (searchTag.maxX + 8 > self.sectionTopSearch.width) {
                                    searchTag.y = saveY + 4
                                    searchTag.x = 0
                                } else {
                                    searchTag.y = lv.y
                                }
                            } else {
                                searchTag.x = 0
                                searchTag.y = 0
                            }
                            let tap = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.searchTopKey(_:)))
                            searchTag.addGestureRecognizer(tap)
                            searchTag.isUserInteractionEnabled = true
                            searchTag.captionTitle.isUserInteractionEnabled = true
                            self.sectionTopSearch.addSubview(searchTag)
                            lastView = searchTag
                        }
                        if let lv = lastView {
                            saveY = lv.maxY > saveY ? lv.maxY : saveY
                            self.conHeightSectionTopSearch.constant = saveY
                        }
                        self.sectionTopSearch.layoutIfNeeded()
                    }
                }
            } else {
               self.topSearchLoading.isHidden = true
            }
        }
        
        // Scrollview and tableview setup
        scrollView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Mixpanel
//        Mixpanel.trackPageVisit(PageName.Search)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Search)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Setup history
        setupHistory()
        
        // Setup keyboard appearance
        self.an_subscribeKeyboard(animations: { f, t, o in
            if (o) {
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
            } else {
                self.tableView.contentInset = UIEdgeInsets.zero
                self.scrollView.contentInset = UIEdgeInsets.zero
            }
        }, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - History setup
    
    func setupHistory() {
        
        // Remove all first
        conHeightSectionHistorySearch.constant = 0
        let arrx = sectionHistorySearch.subviews 
        for v in arrx {
            v.removeFromSuperview()
        }
        
        // Adjust tags
        let arr : [String] = AppToolsObjC.searchHistories() as! [String]
        var y : CGFloat = 0.0
        var x : CGFloat = 0.0
        let sw = sectionHistorySearch.width
        var curMaxY : CGFloat = 0.0
        for s in arr {
            let tag = SearchTag.instance(s)
            tag.x = x
            tag.y = y
            let maxx = tag.maxX
            if (maxx > sw) {
                x = 0
                tag.x = x
                //let maxY = tag.maxY
                y = curMaxY + 4 //maxY + 4
                tag.y = y
                ////print("tag new y : \(y)")
            }
            
            if curMaxY < tag.maxY {
                curMaxY = tag.maxY
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.searchTopKey(_:)))
            tag.addGestureRecognizer(tap)
            tag.isUserInteractionEnabled = true
            tag.captionTitle.isUserInteractionEnabled = true
            sectionHistorySearch.addSubview(tag)
            conHeightSectionHistorySearch.constant = tag.maxY
            x = tag.maxX + 8
        }
        
        if arr.count == 0 {
            self.btnHapusRiwayat.isHidden = true
        } else {
            self.btnHapusRiwayat.isHidden = false
        }
    }
    
    @IBAction func clearHistory(){
        AppToolsObjC.clearSearch()
        setupHistory()
    }
    
    // MARK: - Search bar functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText == "\n") {
            searchBar.resignFirstResponder()
        }
       
        if (searchText == "") {
            scrollView.isHidden = false
        } else {
            scrollView.isHidden = true
        }
        
        find(searchText)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if let searchField = searchBar.value(forKey: "searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.withRenderingMode(.alwaysTemplate)
                icon.tintColor = UIColor.white
            }
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if let searchField = searchBar.value(forKey: "searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.withRenderingMode(.alwaysTemplate)
                icon.tintColor = UIColor.lightGray
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Scroll view functions
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.navigationController?.view.endEditing(true)
    }
    
    // MARK: - Table view functions
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == SectionItem) {
            if (foundItems.count > 0) {
                return 32
            }
        } else if (section == SectionUser) {
            if (foundUsers.count > 0) {
                return 32
            }
        } else if (section == SectionBrand) {
            if (foundBrands.count > 0) {
                return 32
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var arr : [AnyObject] = []
        if (section == SectionItem) {
            arr = foundItems
        } else if (section == SectionUser) {
            arr = foundUsers
        } else if (section == SectionBrand) {
            arr = foundBrands
        }
        if (arr.count > 0) {
            let s = tableView.dequeueReusableHeaderFooterView(withIdentifier: "head") as! SearchResultHeader
            let ss = titleForSection(section)
            s.captionName.text = ss[1]
            s.captionIcon.text = ss[0]
            return s
        } else {
            return nil
        }
    }
    
    func titleForSection(_ section : Int) -> [String] {
        if (section == SectionItem) {
            if (foundItems.count > 0) {
                return ["", "BARANG"]
            }
        } else if (section == SectionUser) {
            if (foundUsers.count > 0) {
                return ["", "PENGGUNA"]
            }
        } else if (section == SectionBrand) {
            if (foundBrands.count > 0) {
                return ["", "MEREK"]
            }
        }
        return ["", ""]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == SectionItem) {
            return foundItems.count + ((foundItems.count == ResultLimit) ? 1 : 0)
        } else if (section == SectionUser) {
            return foundUsers.count + ((foundUsers.count == ResultLimit) ? 1 : 0)
        } else if (section == SectionBrand) {
            return  foundBrands.count + ((foundBrands.count == ResultLimit) ? 1 : 0)
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath as NSIndexPath).section == SectionItem && (indexPath as NSIndexPath).row <= foundItems.count) {
            if ((indexPath as NSIndexPath).row == foundItems.count) { // View more
                var c = tableView.dequeueReusableCell(withIdentifier: "viewmore")
                if (c == nil) {
                    c = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "viewmore")
                }
                c?.textLabel?.text = "Lihat semua barang \"" + currentKeyword + "\""
                return c!
            }
            
            let c = tableView.dequeueReusableCell(withIdentifier: "item") as! SearchItemCell
            let p = foundItems[(indexPath as NSIndexPath).row]
            c.captionName.text = p.name
            c.captionPrice.text = p.price
            if let url = p.coverImageURL {
                c.ivImage.afSetImage(withURL: url)
            }
            return c
        } else if ((indexPath as NSIndexPath).section == SectionUser && (indexPath as NSIndexPath).row <= foundUsers.count) {
            if ((indexPath as NSIndexPath).row == foundUsers.count) { // View more
                var c = tableView.dequeueReusableCell(withIdentifier: "viewmore")
                if (c == nil) {
                    c = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "viewmore")
                }
                c?.textLabel?.text = "Lihat semua user \"" + currentKeyword + "\""
                return c!
            }
            
            let c = tableView.dequeueReusableCell(withIdentifier: "user") as! SearchUserCell
            let u = foundUsers[(indexPath as NSIndexPath).row]
            c.captionName.text = u.username
            c.ivImage.afSetImage(withURL: URL(string : u.pict)!, withFilter: .circle)
            c.ivImage.layer.cornerRadius = (c.ivImage.frame.size.width) / 2
            c.ivImage.clipsToBounds = true
            
            c.ivImage.layer.borderColor = Theme.GrayLight.cgColor
            c.ivImage.layer.borderWidth = 1.5
            return c
        } else if ((indexPath as NSIndexPath).section == SectionBrand && (indexPath as NSIndexPath).row <= foundBrands.count) {
            if ((indexPath as NSIndexPath).row == foundBrands.count) { // View more
                var c = tableView.dequeueReusableCell(withIdentifier: "viewmore")
                if (c == nil) {
                    c = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "viewmore")
                }
                c?.textLabel?.text = "Lihat semua merek \"" + currentKeyword + "\""
                c?.textLabel?.textColor = UIColor.darkGray
                c?.textLabel?.font = c?.textLabel?.font.withSize(15)
                return c!
            }
            
            // Reuse templatenya view more karena mirip
            var c = tableView.dequeueReusableCell(withIdentifier: "viewmore")
            if (c == nil) {
                c = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "viewmore")
            }
            c?.textLabel?.text = foundBrands[(indexPath as NSIndexPath).row].name
            c?.textLabel?.textColor = UIColor.darkGray
            c?.textLabel?.font = c?.textLabel?.font.withSize(15)
            return c!
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ((indexPath as NSIndexPath).section == SectionItem) {
            if ((indexPath as NSIndexPath).row == foundItems.count) {
                if let searchText = self.searchBar.text {
                    // Insert top search
                    let _ = request(APISearch.insertTopSearch(search: searchText)).responseJSON { resp in
                        if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Insert Top Search")) {
                            ////print("TOP")
                            ////print(resp.result.value)
                            ////print("TOPEND")
                        }
                    }
                    // Save history
                    doSearch(keyword: searchText)
                    
                }
                
                let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                l.currentMode = .filter
                l.isBackToFltrSearch = true
                l.fltrCategId = self.currentCategoryId
                l.fltrSortBy = "recent"
                l.previousScreen = PageName.Search
                if let searchText = self.searchBar.text {
                    l.fltrName = searchText
                }
                self.navigationController?.pushViewController(l, animated: true)
            } else {
                // Insert top search
                let _ = request(APISearch.insertTopSearch(search: foundItems[(indexPath as NSIndexPath).row].name)).responseJSON {resp in
                    if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Insert Top Search")) {
                        ////print("TOP")
                        ////print(resp.result.value)
                        ////print("TOPEND")
                    }
                }
                // Save history
                doSearch(keyword: foundItems[(indexPath as NSIndexPath).row].name)
                
                let selectedProduct = foundItems[(indexPath as NSIndexPath).row]
                
                if selectedProduct.isAggregate == false && selectedProduct.isAffiliate == false {
                    let d = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                    d.product = foundItems[(indexPath as NSIndexPath).row]
                    d.previousScreen = PageName.Search
                    self.navigationController?.pushViewController(d, animated: true)
                } else if selectedProduct.isAffiliate == false {
                    let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                    l.currentMode = .filter
                    l.fltrAggregateId = selectedProduct.id
                    l.fltrName = ""
                    l.previousScreen = PageName.Search
                    self.navigationController?.pushViewController(l, animated: true)
                } else {
                    let urlString = selectedProduct.json["affiliate_data"]["affiliate_url"].stringValue
                    
                    let url = NSURL(string: urlString)!
                    UIApplication.shared.openURL(url as URL)
                }
            }
        } else if ((indexPath as NSIndexPath).section == SectionUser) {
            if ((indexPath as NSIndexPath).row == foundUsers.count) {
                let u = self.storyboard?.instantiateViewController(withIdentifier: "searchuser") as! UserSearchViewController
                u.keyword = searchBar.text == nil ? "" : searchBar.text!
                if let searchText = self.searchBar.text {
                    // Insert top search
                    let _ = request(APISearch.insertTopSearch(search: searchText))
                    // Save history
                    doSearch(keyword: searchText)
                    
                }
                self.navigationController?.pushViewController(u, animated: true)
            } else {
                let u = foundUsers[(indexPath as NSIndexPath).row]
                
                // Insert top search
                let _ = request(APISearch.insertTopSearch(search: u.username))
                // Save history
                doSearch(keyword: u.username)
                
                if (!AppTools.isNewShop) {
                    let d = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                    d.currentMode = .shop
                    d.shopName = u.username
                    d.shopId = u.id
                    d.previousScreen = PageName.Search
                    self.navigationController?.pushViewController(d, animated: true)
                } else {
                    let storePageTabBarVC = Bundle.main.loadNibNamed(Tags.XibNameStorePage, owner: nil, options: nil)?.first as! StorePageTabBarViewController
                    storePageTabBarVC.shopId = u.id
                    storePageTabBarVC.previousScreen = PageName.Search
                    self.navigationController?.pushViewController(storePageTabBarVC, animated: true)
                }
            }
        } else if ((indexPath as NSIndexPath).section == SectionBrand) {
            let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            l.currentMode = .filter
            l.isBackToFltrSearch = true
            l.fltrCategId = self.currentCategoryId
            l.fltrSortBy = "recent"
            l.previousScreen = PageName.Search
            var fltrBrands : [String : String] = [:]
            if ((indexPath as NSIndexPath).row == foundBrands.count) {
                for i in 0...foundBrands.count - 1 {
                    let brand = foundBrands[i]
                    fltrBrands[brand.name] = brand.id
                }
                
                if let searchText = self.searchBar.text {
                    // Insert top search
                    let _ = request(APISearch.insertTopSearch(search: searchText))
                    // Save history
                    doSearch(keyword: searchText)
                    
                }
            } else {
                let brand = foundBrands[(indexPath as NSIndexPath).row]
                fltrBrands[brand.name] = brand.id
                
                // Insert top search
                let _ = request(APISearch.insertTopSearch(search: brand.name))
                // Save history
                doSearch(keyword: brand.name)
                
            }
            l.fltrBrands = fltrBrands
            self.navigationController?.pushViewController(l, animated: true)
        }
    }
    
    // MARK: - Search functions
    
    func doSearch(keyword : String) {
        let index = AppToolsObjC.index(ofSearch: keyword)
        if index != NSNotFound {
            AppToolsObjC.removeSearch(at: index)
        }
        AppToolsObjC.insertNewSearch(keyword)
        setupHistory()
        
        // Prelo Analytic - Search by Keyword
        let loginMethod = User.LoginMethod ?? ""
        let pdata = [
            "Search Query" : keyword
        ]
        AnalyticManager.sharedInstance.send(eventType: PreloAnalyticEvent.SearchByKeyword, data: pdata, previousScreen: self.previousScreen, loginMethod: loginMethod)
    }
    
    func searchTopKey(_ sender : UITapGestureRecognizer) {
        let searchTag = sender.view as! SearchTag
        searchBar.text = searchTag.captionTitle.text
        scrollView.isHidden = true
        find(searchTag.captionTitle.text!)
    }
    
    
    func find(_ keyword : String) {
        // reset found
        self.foundItems = []
        self.foundUsers = []
        self.foundBrands = []
        
        if (keyword == "") {
            self.tableView.isHidden = true
            return
        }
        
        self.showLoading()
        
        currentKeyword = keyword
        
        // Cancel unfinished previous request
        if let req = currentRequest {
            req.cancel()
        }
        
        currentRequest = request(APISearch.autocomplete(key: keyword)).responseJSON { resp in
            if (PreloEndpoints.validate(false, dataResp: resp, reqAlias: "Search Autocomplete")) {
                let json = JSON(resp.result.value!)
                if let items = json["_data"]["products"].array , items.count > 0 {
                    self.foundItems = []
                    for i in 0...items.count - 1 {
                        let p = Product.instance(items[i])
                        if p != nil {
                            self.foundItems.append(p!)
                        }
                        if (self.foundItems.count == self.ResultLimit) {
                            break
                        }
                    }
                }
                if let users = json["_data"]["users"].array , users.count > 0 {
                    self.foundUsers = []
                    for i in 0...users.count - 1 {
                        let u = SearchUser.instance(users[i])
                        if u != nil {
                            self.foundUsers.append(u!)
                        }
                        if (self.foundUsers.count == self.ResultLimit) {
                            break
                        }
                    }
                }
                if let brands = json["_data"]["brands"].array , brands.count > 0 {
                    self.foundBrands = []
                    for i in 0...brands.count - 1 {
                        let b = SearchBrand.instance(brands[i])
                        if b != nil {
                            self.foundBrands.append(b!)
                        }
                        if (self.foundBrands.count == self.ResultLimit) {
                            break
                        }
                    }
                }
                self.tableView.isHidden = false
                self.tableView.reloadData()
                if (self.foundItems.isEmpty && self.foundUsers.isEmpty && self.foundBrands.isEmpty) {
                    self.tableView.isHidden = true
                    self.vwZeroResult.isHidden = false
                    var txt = "Tidak ada hasil yang ditemukan"
                    if let searchText = self.searchBar.text {
                        txt += " untuk '\(searchText)'"
                    }
                    self.lblZeroResult.text = txt
                } else {
                    self.vwZeroResult.isHidden = true
                }
                self.hideLoading()
            }
        }
    }
    
    // MARK: - Actions

    @IBAction func filterPressed(_ sender: AnyObject) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let l = mainStoryboard.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
        l.fltrCategId = self.currentCategoryId
        l.currentMode = .filter
        l.isBackToFltrSearch = true
        l.fltrSortBy = "recent"
        l.previousScreen = PageName.Search
        self.navigationController?.pushViewController(l, animated: true)
        
        /* FOR MORE LOGICAL UX
         let filterVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameFilter, owner: nil, options: nil).first as! FilterViewController
        filterVC.categoryId = self.currentCategoryId
        self.navigationController?.pushViewController(filterVC, animated: true)*/
    }
    
    @IBAction func requestBarangPressed(_ sender: AnyObject) {
        var username = "Your beloved user"
        if let u = CDUser.getOne() {
            username = u.username
        }
        var txt = ""
        if let searchText = self.searchBar.text {
            txt = searchText
        }
        let msgBody = "Dear Prelo,<br/><br/>Saya sedang mencari barang bekas berkualitas ini:<br/>\(txt)<br/><br/>Jika ada pengguna di Prelo yang menjual barang tersebut, harap memberitahu saya melalui e-mail.<br/><br/>Terima kasih Prelo <3<br/><br/>--<br/>\(username)<br/>Sent from Prelo iOS"
        
        let m = MFMailComposeViewController()
        if (MFMailComposeViewController.canSendMail()) {
            m.setToRecipients(["contact@prelo.id"])
            m.setSubject("Request Barang")
            m.setMessageBody(msgBody, isHTML: true)
            m.mailComposeDelegate = self
            self.present(m, animated: true, completion: nil)
        } else {
            Constant.showDialog("No Active E-mail", message: "Untuk dapat mengirim Request Barang, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
        }
    }
    
    // MARK: - Mail compose delegate functions
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if (result == MFMailComposeResult.sent) {
            Constant.showDialog("Request Barang", message: "E-mail terkirim")
        } else if (result == MFMailComposeResult.failed) {
            Constant.showDialog("Request Barang", message: "E-mail gagal dikirim")
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "segAllCategory") {
            let c = segue.destination as! CategoryPickerViewController
            c.searchMode = true
        }
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        loadingPanel.isHidden = false
    }
    
    func hideLoading() {
        loadingPanel.isHidden = true
    }
}

// MARK: - Class

class SearchUserCell : UITableViewCell {
    @IBOutlet var captionName : UILabel!
    @IBOutlet var btnFollow : BorderedButton!
    @IBOutlet var ivImage : UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        ivImage.afCancelRequest()
    }
}

// MARK: - Class

class SearchItemCell : UITableViewCell {
    @IBOutlet var captionName : UILabel!
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var ivImage : UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        ivImage.afCancelRequest()
    }
}

// MARK: - Class

class SearchResultHeader : UITableViewHeaderFooterView {
    @IBOutlet var captionIcon : UILabel!
    @IBOutlet var captionName : UILabel!
}
