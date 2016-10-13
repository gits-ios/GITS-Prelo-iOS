//
//  SearchViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import MessageUI

// MARK: - Class

class SearchViewController: BaseViewController, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, MFMailComposeViewControllerDelegate {
    
    // MARK: - Properties
    
    // Views
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var tableView : UITableView!
    @IBOutlet var sectionTopSearch : UIView!
    @IBOutlet var sectionHistorySearch : UIView!
    @IBOutlet var topSearchLoading : UIActivityIndicatorView!
    @IBOutlet var conHeightSectionTopSearch : NSLayoutConstraint!
    @IBOutlet var conHeightSectionHistorySearch : NSLayoutConstraint!
    @IBOutlet var vwZeroResult: UIView!
    @IBOutlet var lblZeroResult: UILabel!
    @IBOutlet var loadingPanel: UIView!
    var searchBar : UISearchBar!
    
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
        
        // Status bar style
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.default, animated: true)
        
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
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Top Search")) {
                self.topSearchLoading.isHidden = true
                let json = JSON(resp.result.value!)
                if let data = json["_data"].array {
                    if (data.count > 0) {
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
                                let x = lv.maxX + 8
                                searchTag.x = x
                                
                                if (searchTag.maxX + 8 > self.sectionTopSearch.width) {
                                    searchTag.y = lv.maxY + 4
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
                            self.conHeightSectionTopSearch.constant = lv.maxY
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
        //Mixpanel.trackPageVisit(PageName.Search)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Search)
        
        // Status bar style
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.default, animated: true)
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
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default
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
        for s in arr {
            let tag = SearchTag.instance(s)
            tag.x = x
            tag.y = y
            let maxx = tag.maxX
            if (maxx > sw) {
                x = 0
                tag.x = x
                let maxY = tag.maxY
                y = maxY + 4
                tag.y = y
                //print("tag new y : \(y)")
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.searchTopKey(_:)))
            tag.addGestureRecognizer(tap)
            tag.isUserInteractionEnabled = true
            tag.captionTitle.isUserInteractionEnabled = true
            sectionHistorySearch.addSubview(tag)
            conHeightSectionHistorySearch.constant = tag.maxY
            x = tag.maxX + 8
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
        if ((indexPath as NSIndexPath).section == SectionItem) {
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
                c.ivImage.setImageWithUrl(url, placeHolderImage: nil)
            }
            return c
        } else if ((indexPath as NSIndexPath).section == SectionUser) {
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
            c.ivImage.setImageWithUrl(URL(string : u.pict)!, placeHolderImage: nil)
            c.ivImage.layer.cornerRadius = (c.ivImage.frame.size.width) / 2
            c.ivImage.clipsToBounds = true
            return c
        } else if ((indexPath as NSIndexPath).section == SectionBrand) {
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
                        if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Insert Top Search")) {
                            //print("TOP")
                            //print(resp.result.value)
                            //print("TOPEND")
                        }
                    }
                    // Save history
                    AppToolsObjC.insertNewSearch(searchText)
                    setupHistory()
                }
                
                let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                l.currentMode = .filter
                l.isBackToFltrSearch = true
                l.fltrCategId = self.currentCategoryId
                l.fltrSortBy = "recent"
                if let searchText = self.searchBar.text {
                    l.fltrName = searchText
                }
                self.navigationController?.pushViewController(l, animated: true)
            } else {
                // Insert top search
                let _ = request(APISearch.insertTopSearch(search: foundItems[(indexPath as NSIndexPath).row].name)).responseJSON {resp in
                    if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Insert Top Search")) {
                        //print("TOP")
                        //print(resp.result.value)
                        //print("TOPEND")
                    }
                }
                // Save history
                AppToolsObjC.insertNewSearch(foundItems[(indexPath as NSIndexPath).row].name)
                setupHistory()
                
                let d = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                d.product = foundItems[(indexPath as NSIndexPath).row]
                self.navigationController?.pushViewController(d, animated: true)
            }
        } else if ((indexPath as NSIndexPath).section == SectionUser) {
            if ((indexPath as NSIndexPath).row == foundUsers.count) {
                let u = self.storyboard?.instantiateViewController(withIdentifier: "searchuser") as! UserSearchViewController
                u.keyword = searchBar.text == nil ? "" : searchBar.text!
                if let searchText = self.searchBar.text {
                    // Insert top search
                    let _ = request(APISearch.insertTopSearch(search: searchText))
                    // Save history
                    AppToolsObjC.insertNewSearch(searchText)
                    setupHistory()
                }
                self.navigationController?.pushViewController(u, animated: true)
            } else {
                let d = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
                let u = foundUsers[(indexPath as NSIndexPath).row]
                d.currentMode = .shop
                d.shopName = u.username
                
                // Insert top search
                let _ = request(APISearch.insertTopSearch(search: u.username))
                // Save history
                AppToolsObjC.insertNewSearch(u.username)
                setupHistory()
                
                d.shopId = u.id
                self.navigationController?.pushViewController(d, animated: true)
            }
        } else if ((indexPath as NSIndexPath).section == SectionBrand) {
            let l = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            l.currentMode = .filter
            l.isBackToFltrSearch = true
            l.fltrCategId = self.currentCategoryId
            l.fltrSortBy = "recent"
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
                    AppToolsObjC.insertNewSearch(searchText)
                    setupHistory()
                }
            } else {
                let brand = foundBrands[(indexPath as NSIndexPath).row]
                fltrBrands[brand.name] = brand.id
                
                // Insert top search
                let _ = request(APISearch.insertTopSearch(search: brand.name))
                // Save history
                AppToolsObjC.insertNewSearch(brand.name)
                setupHistory()
            }
            l.fltrBrands = fltrBrands
            self.navigationController?.pushViewController(l, animated: true)
        }
    }
    
    // MARK: - Search functions
    
    func searchTopKey(_ sender : UITapGestureRecognizer) {
        let searchTag = sender.view as! SearchTag
        searchBar.text = searchTag.captionTitle.text
        scrollView.isHidden = true
        find(searchTag.captionTitle.text!)
    }
    
    
    func find(_ keyword : String) {
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
        
        currentRequest = request(APISearch.autocomplete(key: keyword))
        currentRequest?.responseJSON { resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Search Autocomplete")) {
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
}

// MARK: - Class

class SearchItemCell : UITableViewCell {
    @IBOutlet var captionName : UILabel!
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var ivImage : UIImageView!
}

// MARK: - Class

class SearchResultHeader : UITableViewHeaderFooterView {
    @IBOutlet var captionIcon : UILabel!
    @IBOutlet var captionName : UILabel!
}
