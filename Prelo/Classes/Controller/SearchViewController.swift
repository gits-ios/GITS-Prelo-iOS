//
//  SearchViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import MessageUI

class SearchViewController: BaseViewController, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, MFMailComposeViewControllerDelegate
{
    
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var tableView : UITableView!
    @IBOutlet var sectionTopSearch : UIView!
    @IBOutlet var sectionHistorySearch : UIView!
    @IBOutlet var topSearchLoading : UIActivityIndicatorView!
    
    @IBOutlet var conHeightSectionTopSearch : NSLayoutConstraint!
    @IBOutlet var conHeightSectionHistorySearch : NSLayoutConstraint!
    
    var searchBar : UISearchBar!
    
    var foundItems : [Product] = []
    var foundUsers : [SearchUser] = []
    
    var currentCategoryId : String = "" // Category id terakhir yg dilihat di home
    
    var findingUser : Bool = false
    var findingItem : Bool = false
    
    @IBOutlet var vwZeroResult: UIView!
    @IBOutlet var lblZeroResult: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
        
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
        
        // API Migrasi
        request(APISearch.GetTopSearch(limit: "10")).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Top Search"))
            {
                self.topSearchLoading.hidden = true
                let json = JSON(resp.result.value!)
                if let data = json["_data"].array
                {
                    if (data.count > 0)
                    {
                        _ = UIScreen.mainScreen().bounds.width-16
                        var lastView : UIView?
                        for i in 0...data.count-1
                        {
                            let ts = data[i]
                            let name = ts["name"].stringValue
                            if (name.stringByReplacingOccurrencesOfString(" ", withString: "") == "")
                            {
                                continue
                            }
                            let searchTag = SearchTag.instance(name)
                            if let lv = lastView
                            {
                                let x = lv.maxX + 8
                                searchTag.x = x
                                
                                if (searchTag.maxX + 8 > self.sectionTopSearch.width)
                                {
                                    searchTag.y = lv.maxY + 4
                                    searchTag.x = 0
                                }else
                                {
                                    searchTag.y = lv.y
                                }
                            } else
                            {
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
                        if let lv = lastView
                        {
                            self.conHeightSectionTopSearch.constant = lv.maxY
                        }
                        
                        self.sectionTopSearch.layoutIfNeeded()
                    }
                }
            } else
            {
                
            }
        }
        
//        setupHistory()
        
        scrollView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
    }
    
    
    func setupHistory()
    {
        conHeightSectionHistorySearch.constant = 0
        
        let arrx = sectionHistorySearch.subviews 
        for v in arrx
        {
            v.removeFromSuperview()
        }
        
        let arr : [String] = AppToolsObjC.searchHistories() as! [String]
        var y : CGFloat = 0.0
        var x : CGFloat = 0.0
        let sw = sectionHistorySearch.width
        for s in arr
        {
            let tag = SearchTag.instance(s)
            tag.x = x
            tag.y = y
            _ = tag.frame
            let maxx = tag.maxX
            if (maxx > sw)
            {
                x = 0
                tag.x = x
                let maxY = tag.maxY
                y = maxY + 4
                tag.y = y
                _ = tag.bounds
                _ = tag.frame
                print("tag new y : \(y)")
            }
//            tag.y = y
            let tap = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.searchTopKey(_:)))
            tag.addGestureRecognizer(tap)
            tag.userInteractionEnabled = true
            tag.captionTitle.userInteractionEnabled = true
            sectionHistorySearch.addSubview(tag)
            conHeightSectionHistorySearch.constant = tag.maxY
            x = tag.maxX + 8
        }
    }
    
    @IBAction func clearHistory()
    {
        AppToolsObjC.clearSearch()
        setupHistory()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // Mixpanel
        //Mixpanel.trackPageVisit(PageName.Search)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Search)
        

        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        setupHistory()
        
        self.an_subscribeKeyboardWithAnimations({f, t, o in
            
            if (o)
            {
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
            } else
            {
                self.tableView.contentInset = UIEdgeInsetsZero
                self.scrollView.contentInset = UIEdgeInsetsZero
            }
            
            }, completion: nil)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.navigationController?.view.endEditing(true)
    }
    
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
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == 0)
        {
            if (foundItems.count > 0)
            {
                return 32
            } else
            {
                return 0
            }
        } else
        {
            if (foundUsers.count > 0)
            {
                return 32
            } else
            {
                return 0
            }
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let arr:[AnyObject] = (section == 0) ? foundItems : foundUsers
        if (arr.count > 0)
        {
            let s = tableView.dequeueReusableHeaderFooterViewWithIdentifier("head") as! SearchResultHeader
            _ = titleForSection(section)
            let ss = titleForSection(section)
            s.captionName.text = ss[1]
            s.captionIcon.text = ss[0]
            return s
        } else
        {
            return nil
        }
    }
    
    func titleForSection(section : Int) -> [String]
    {
        if (section == 0)
        {
            if (foundItems.count > 0)
            {
                return ["","BARANG"]
            } else
            {
                return ["", ""]
            }
        } else
        {
            if (foundUsers.count > 0)
            {
                return ["","PENGGUNA"]
            } else
            {
                return ["", ""]
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0)
        {
            return foundItems.count+((foundItems.count == 5) ? 1 : 0)
        } else
        {
            return foundUsers.count+((foundUsers.count == 5) ? 1 : 0)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 0)
        {
            if (indexPath.row == foundItems.count)
            {
                var c = tableView.dequeueReusableCellWithIdentifier("viewmore")
                if (c == nil)
                {
                    c = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "viewmore")
                }
                c?.textLabel?.text = "Lihat semua barang \"" + currentKeyword + "\""
                return c!
            }
            
            let c = tableView.dequeueReusableCellWithIdentifier("item") as! SearchItemCell
            let p = foundItems[indexPath.row]
            c.captionName.text = p.name
            c.captionPrice.text = p.price
            if let url = p.coverImageURL
            {
                c.ivImage.setImageWithUrl(url, placeHolderImage: nil)
            }
            return c
        } else
        {
            if (indexPath.row == foundUsers.count)
            {
                var c = tableView.dequeueReusableCellWithIdentifier("viewmore")
                if (c == nil)
                {
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
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.section == 0)
        {
            if (indexPath.row == foundItems.count)
            {
                // API Migrasi
                request(APISearch.InsertTopSearch(search: searchBar.text == nil ? "" : searchBar.text!)).responseJSON {resp in
                    if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Insert Top Search")) {
                        //print("TOP")
                        //print(resp.result.value)
                        //print("TOPEND")
                    }
                }
                AppToolsObjC.insertNewSearch(searchBar.text)
                setupHistory()
                
                let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                l.filterMode = true
                l.fltrCategId = self.currentCategoryId
                l.fltrSortBy = "recent"
                if let searchText = self.searchBar.text {
                    l.fltrName = searchText
                }
                self.navigationController?.pushViewController(l, animated: true)
            } else
            {
                // API Migrasi
                request(APISearch.InsertTopSearch(search: searchBar.text == nil ? "" : searchBar.text!)).responseJSON {resp in
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
        } else
        {
            if (indexPath.row == foundUsers.count)
            {
                let u = self.storyboard?.instantiateViewControllerWithIdentifier("searchuser") as! UserSearchViewController
                u.keyword = searchBar.text == nil ? "" : searchBar.text!
                // API Migrasi
                request(APISearch.InsertTopSearch(search: searchBar.text == nil ? "" : searchBar.text!))
                self.navigationController?.pushViewController(u, animated: true)
                
            } else
            {
                let d = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                let u = foundUsers[indexPath.row]
                d.storeMode = true
                d.storeName = u.username
                
                // API Migrasi
                request(APISearch.InsertTopSearch(search: u.username))
                AppToolsObjC.insertNewSearch(u.username)
                setupHistory()
                
                d.storeId = u.id
                d.storePictPath = u.pict
                self.navigationController?.pushViewController(d, animated: true)
            }
        }
    }
    
    func searchTopKey(sender : UITapGestureRecognizer)
    {
        let searchTag = sender.view as! SearchTag
        searchBar.text = searchTag.captionTitle.text
        scrollView.hidden = true
        find(searchTag.captionTitle.text!)
    }
    
    var itemRequest : Request?
    var currentKeyword = ""
    func find(keyword : String)
    {
        currentKeyword = keyword
        findItem(keyword)
        findUser(keyword)
    }
    
    func findItem(keyword : String)
    {
        // Mixpanel
        if (!keyword.isEmpty) {
            let pt = [
                "Search Type" : "Product",
                "Search Query" : keyword
            ]
            Mixpanel.trackEvent(MixpanelEvent.Search, properties: pt)
        }
        
        self.findingItem = true
        
        if let req = itemRequest
        {
            req.cancel()
        }
        
        itemRequest = // API Migrasi
        request(APISearch.Find(keyword: keyword, categoryId: "", brandId: "", condition: "", current: 0, limit: 6, priceMin: 0, priceMax: 999999999))
        
        itemRequest?.responseJSON {resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Search Item"))
            {
                self.foundItems = []
                let json = JSON(resp.result.value!)
                if let arr = json["_data"].array
                {
                    if (arr.count > 0)
                    {
                        for i in 0...arr.count-1
                        {
                            let p = Product.instance(arr[i])
                            if let product = p
                            {
                                self.foundItems.append(product)
                            }
                            if (self.foundItems.count == 5)
                            {
                                break
                            }
                        }
                    }
                }
                self.tableView.hidden = false
                self.tableView.reloadData()
                if (!self.findingUser && self.foundUsers.isEmpty && self.foundItems.isEmpty) {
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
            }
            self.findingItem = false
        }
    }
    
    var userRequest : Request?
    func findUser(keyword : String)
    {
        // Mixpanel
        if (!keyword.isEmpty) {
            let pt = [
                "Search Type" : "User",
                "Search Query" : keyword
            ]
            Mixpanel.trackEvent(MixpanelEvent.Search, properties: pt)
        }
        
        self.findingUser = true
        
        if let req = userRequest
        {
            req.cancel()
        }
        
        userRequest = // API Migrasi
        request(APISearch.User(keyword: keyword))
        userRequest?.responseJSON {resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Search User"))
            {
                self.foundUsers = []
                let json = JSON(resp.result.value!)
                if let arr = json["_data"].array
                {
                    if (arr.count > 0)
                    {
                        for i in 0...arr.count-1
                        {
                            let p = SearchUser.instance(arr[i])
                            if let product = p
                            {
                                self.foundUsers.append(product)
                            }
                            if (self.foundUsers.count == 5)
                            {
                                break
                            }
                        }
                    }
                }
                self.tableView.hidden = false
                self.tableView.reloadData()
                if (!self.findingItem && self.foundUsers.isEmpty && self.foundItems.isEmpty) {
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
            }
            self.findingUser = false
        }
    }
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    // MARK: - Navigation
    var canAnimateBar = false
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        canAnimateBar = true
        if (segue.identifier == "segAllCategory")
        {
            let c = segue.destinationViewController as! CategoryPickerViewController
            c.searchMode = true
        }
    }

    @IBAction func filterPressed(sender: AnyObject) {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let l = mainStoryboard.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        l.fltrCategId = self.currentCategoryId
        l.filterMode = true
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
}

class SearchUserCell : UITableViewCell
{
    @IBOutlet var captionName : UILabel!
    @IBOutlet var btnFollow : BorderedButton!
    @IBOutlet var ivImage : UIImageView!
}

class SearchItemCell : UITableViewCell
{
    @IBOutlet var captionName : UILabel!
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var ivImage : UIImageView!
}

class SearchResultHeader : UITableViewHeaderFooterView
{
    @IBOutlet var captionIcon : UILabel!
    @IBOutlet var captionName : UILabel!
}
