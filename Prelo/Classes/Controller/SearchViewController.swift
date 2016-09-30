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
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
        
        // Init loading
        loadingPanel.backgroundColor = UIColor.colorWithColor(UIColor.whiteColor(), alpha: 0.5)
        self.hideLoading()
        
        // Nib register
        tableView.registerNib(UINib(nibName: "SearchResultHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "head")
        
        // Search bar setup
        var searchBarWidth = UIScreen.mainScreen().bounds.size.width * 0.8375
        if (AppTools.isIPad) {
            searchBarWidth = UIScreen.mainScreen().bounds.size.width - 68
        }
        searchBar = UISearchBar(frame: CGRectMake(0, 0, searchBarWidth, 30))
        if let searchField = self.searchBar.valueForKey("searchField") as? UITextField {
            searchField.backgroundColor = Theme.PrimaryColorDark
            searchField.textColor = UIColor.whiteColor()
            let attrPlaceholder = NSAttributedString(string: "Cari di Prelo", attributes: [NSForegroundColorAttributeName : UIColor.lightGrayColor()])
            searchField.attributedPlaceholder = attrPlaceholder
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.imageWithRenderingMode(.AlwaysTemplate)
                icon.tintColor = UIColor.lightGrayColor()
            }
            searchField.borderStyle = UITextBorderStyle.None
        }
        searchBar.delegate = self
        searchBar.placeholder = "Cari di Prelo"
        self.navigationItem.rightBarButtonItem = searchBar.toBarButton()
        
        // Top search setup
        request(APISearch.GetTopSearch(limit: "10")).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Top Search")) {
                self.topSearchLoading.hidden = true
                let json = JSON(resp.result.value!)
                if let data = json["_data"].array {
                    if (data.count > 0) {
                        var lastView : UIView?
                        for i in 0...data.count - 1 {
                            let ts = data[i]
                            let name = ts["name"].stringValue
                            if (name.stringByReplacingOccurrencesOfString(" ", withString: "") == "") {
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
                            searchTag.userInteractionEnabled = true
                            searchTag.captionTitle.userInteractionEnabled = true
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
               self.topSearchLoading.hidden = true
            }
        }
        
        // Scrollview and tableview setup
        scrollView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // Mixpanel
        //Mixpanel.trackPageVisit(PageName.Search)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Search)
        
        // Status bar style
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        // Setup history
        setupHistory()
        
        // Setup keyboard appearance
        self.an_subscribeKeyboardWithAnimations({ f, t, o in
            if (o) {
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
            } else {
                self.tableView.contentInset = UIEdgeInsetsZero
                self.scrollView.contentInset = UIEdgeInsetsZero
            }
        }, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
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
            tag.userInteractionEnabled = true
            tag.captionTitle.userInteractionEnabled = true
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
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText == "\n") {
            searchBar.resignFirstResponder()
        }
       
        if (searchText == "") {
            scrollView.hidden = false
        } else {
            scrollView.hidden = true
        }
        
        find(searchText)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if let searchField = searchBar.valueForKey("searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.imageWithRenderingMode(.AlwaysTemplate)
                icon.tintColor = UIColor.whiteColor()
            }
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        if let searchField = searchBar.valueForKey("searchField") as? UITextField {
            if let icon = searchField.leftView as? UIImageView {
                icon.image = icon.image?.imageWithRenderingMode(.AlwaysTemplate)
                icon.tintColor = UIColor.lightGrayColor()
            }
        }
    }
    
    // MARK: - Scroll view functions
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.navigationController?.view.endEditing(true)
    }
    
    // MARK: - Table view functions
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var arr : [AnyObject] = []
        if (section == SectionItem) {
            arr = foundItems
        } else if (section == SectionUser) {
            arr = foundUsers
        } else if (section == SectionBrand) {
            arr = foundBrands
        }
        if (arr.count > 0) {
            let s = tableView.dequeueReusableHeaderFooterViewWithIdentifier("head") as! SearchResultHeader
            let ss = titleForSection(section)
            s.captionName.text = ss[1]
            s.captionIcon.text = ss[0]
            return s
        } else {
            return nil
        }
    }
    
    func titleForSection(section : Int) -> [String] {
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == SectionItem) {
            return foundItems.count + ((foundItems.count == ResultLimit) ? 1 : 0)
        } else if (section == SectionUser) {
            return foundUsers.count + ((foundUsers.count == ResultLimit) ? 1 : 0)
        } else if (section == SectionBrand) {
            return  foundBrands.count + ((foundBrands.count == ResultLimit) ? 1 : 0)
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == SectionItem) {
            if (indexPath.row == foundItems.count) { // View more
                var c = tableView.dequeueReusableCellWithIdentifier("viewmore")
                if (c == nil) {
                    c = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "viewmore")
                }
                c?.textLabel?.text = "Lihat semua barang \"" + currentKeyword + "\""
                return c!
            }
            
            let c = tableView.dequeueReusableCellWithIdentifier("item") as! SearchItemCell
            let p = foundItems[indexPath.row]
            c.captionName.text = p.name
            c.captionPrice.text = p.price
            if let url = p.coverImageURL {
                c.ivImage.setImageWithUrl(url, placeHolderImage: nil)
            }
            return c
        } else if (indexPath.section == SectionUser) {
            if (indexPath.row == foundUsers.count) { // View more
                var c = tableView.dequeueReusableCellWithIdentifier("viewmore")
                if (c == nil) {
                    c = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "viewmore")
                }
                c?.textLabel?.text = "Lihat semua user \"" + currentKeyword + "\""
                return c!
            }
            
            let c = tableView.dequeueReusableCellWithIdentifier("user") as! SearchUserCell
            let u = foundUsers[indexPath.row]
            c.captionName.text = u.username
            c.ivImage.setImageWithUrl(NSURL(string : u.pict)!, placeHolderImage: nil)
            c.ivImage.layer.cornerRadius = (c.ivImage.frame.size.width) / 2
            c.ivImage.clipsToBounds = true
            return c
        } else if (indexPath.section == SectionBrand) {
            if (indexPath.row == foundBrands.count) { // View more
                var c = tableView.dequeueReusableCellWithIdentifier("viewmore")
                if (c == nil) {
                    c = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "viewmore")
                }
                c?.textLabel?.text = "Lihat semua merek \"" + currentKeyword + "\""
                c?.textLabel?.textColor = UIColor.darkGrayColor()
                c?.textLabel?.font = c?.textLabel?.font.fontWithSize(15)
                return c!
            }
            
            // Reuse templatenya view more karena mirip
            var c = tableView.dequeueReusableCellWithIdentifier("viewmore")
            if (c == nil) {
                c = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "viewmore")
            }
            c?.textLabel?.text = foundBrands[indexPath.row].name
            c?.textLabel?.textColor = UIColor.darkGrayColor()
            c?.textLabel?.font = c?.textLabel?.font.fontWithSize(15)
            return c!
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.section == SectionItem) {
            if (indexPath.row == foundItems.count) {
                // Insert top search
                request(APISearch.InsertTopSearch(search: searchBar.text == nil ? "" : searchBar.text!)).responseJSON { resp in
                    if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Insert Top Search")) {
                        //print("TOP")
                        //print(resp.result.value)
                        //print("TOPEND")
                    }
                }
                AppToolsObjC.insertNewSearch(searchBar.text)
                setupHistory()
                
                let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                l.currentMode = .Filter
                l.isBackToFltrSearch = true
                l.fltrCategId = self.currentCategoryId
                l.fltrSortBy = "recent"
                if let searchText = self.searchBar.text {
                    l.fltrName = searchText
                }
                self.navigationController?.pushViewController(l, animated: true)
            } else {
                // Insert top search
                request(APISearch.InsertTopSearch(search: foundItems[indexPath.row].name)).responseJSON {resp in
                    if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Insert Top Search")) {
                        //print("TOP")
                        //print(resp.result.value)
                        //print("TOPEND")
                    }
                }
                let d = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                d.product = foundItems[indexPath.row]
                self.navigationController?.pushViewController(d, animated: true)
            }
        } else if (indexPath.section == SectionUser) {
            if (indexPath.row == foundUsers.count) {
                let u = self.storyboard?.instantiateViewControllerWithIdentifier("searchuser") as! UserSearchViewController
                u.keyword = searchBar.text == nil ? "" : searchBar.text!
                // Insert top search
                request(APISearch.InsertTopSearch(search: searchBar.text == nil ? "" : searchBar.text!))
                self.navigationController?.pushViewController(u, animated: true)
            } else {
                let d = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                let u = foundUsers[indexPath.row]
                d.currentMode = .Shop
                d.shopName = u.username
                
                // Insert top search
                request(APISearch.InsertTopSearch(search: u.username))
                AppToolsObjC.insertNewSearch(u.username)
                setupHistory()
                
                d.shopId = u.id
                self.navigationController?.pushViewController(d, animated: true)
            }
        } else if (indexPath.section == SectionBrand) {
            let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
            l.currentMode = .Filter
            l.isBackToFltrSearch = true
            l.fltrCategId = self.currentCategoryId
            l.fltrSortBy = "recent"
            var fltrBrands : [String : String] = [:]
            if (indexPath.row == foundBrands.count) {
                for i in 0...foundBrands.count - 1 {
                    let brand = foundBrands[i]
                    fltrBrands[brand.name] = brand.id
                }
                
                // Insert top search
                request(APISearch.InsertTopSearch(search: searchBar.text == nil ? "" : searchBar.text!))
            } else {
                let brand = foundBrands[indexPath.row]
                fltrBrands[brand.name] = brand.id
                
                // Insert top search
                request(APISearch.InsertTopSearch(search: brand.name))
            }
            l.fltrBrands = fltrBrands
            self.navigationController?.pushViewController(l, animated: true)
        }
    }
    
    // MARK: - Search functions
    
    func searchTopKey(sender : UITapGestureRecognizer) {
        let searchTag = sender.view as! SearchTag
        searchBar.text = searchTag.captionTitle.text
        scrollView.hidden = true
        find(searchTag.captionTitle.text!)
    }
    
    
    func find(keyword : String) {
        if (keyword == "") {
            self.tableView.hidden = true
            return
        }
        
        self.showLoading()
        
        currentKeyword = keyword
        
        // Cancel unfinished previous request
        if let req = currentRequest {
            req.cancel()
        }
        
        currentRequest = request(APISearch.Autocomplete(key: keyword))
        currentRequest?.responseJSON { resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Search Autocomplete")) {
                let json = JSON(resp.result.value!)
                if let items = json["_data"]["products"].array where items.count > 0 {
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
                if let users = json["_data"]["users"].array where users.count > 0 {
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
                if let brands = json["_data"]["brands"].array where brands.count > 0 {
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
                self.tableView.hidden = false
                self.tableView.reloadData()
                if (self.foundItems.isEmpty && self.foundUsers.isEmpty && self.foundBrands.isEmpty) {
                    self.tableView.hidden = true
                    self.vwZeroResult.hidden = false
                    var txt = "Tidak ada hasil yang ditemukan"
                    if let searchText = self.searchBar.text {
                        txt += " untuk '\(searchText)'"
                    }
                    self.lblZeroResult.text = txt
                } else {
                    self.vwZeroResult.hidden = true
                }
                self.hideLoading()
            }
        }
    }
    
    // MARK: - Actions

    @IBAction func filterPressed(sender: AnyObject) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let l = mainStoryboard.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        l.fltrCategId = self.currentCategoryId
        l.currentMode = .Filter
        l.isBackToFltrSearch = true
        l.fltrSortBy = "recent"
        self.navigationController?.pushViewController(l, animated: true)
        
        /* FOR MORE LOGICAL UX
         let filterVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameFilter, owner: nil, options: nil).first as! FilterViewController
        filterVC.categoryId = self.currentCategoryId
        self.navigationController?.pushViewController(filterVC, animated: true)*/
    }
    
    @IBAction func requestBarangPressed(sender: AnyObject) {
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
            self.presentViewController(m, animated: true, completion: nil)
        } else {
            Constant.showDialog("No Active E-mail", message: "Untuk dapat mengirim Request Barang, aktifkan akun e-mail kamu di menu Settings > Mail, Contacts, Calendars")
        }
    }
    
    // MARK: - Mail compose delegate functions
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        if (result == MFMailComposeResultSent) {
            Constant.showDialog("Request Barang", message: "E-mail terkirim")
        } else if (result == MFMailComposeResultFailed) {
            Constant.showDialog("Request Barang", message: "E-mail gagal dikirim")
        }
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "segAllCategory") {
            let c = segue.destinationViewController as! CategoryPickerViewController
            c.searchMode = true
        }
    }
    
    // MARK: - Other functions
    
    func showLoading() {
        loadingPanel.hidden = false
    }
    
    func hideLoading() {
        loadingPanel.hidden = true
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
