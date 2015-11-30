//
//  SearchViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/6/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class SearchViewController: BaseViewController, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate
{
    
    @IBOutlet var txtSearch : UITextField!
    @IBOutlet var txtSearchWidth : NSLayoutConstraint!
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var tableView : UITableView!
    @IBOutlet var sectionTopSearch : UIView!
    @IBOutlet var sectionHistorySearch : UIView!
    @IBOutlet var topSearchLoading : UIActivityIndicatorView!
    
    @IBOutlet var conHeightSectionTopSearch : NSLayoutConstraint!
    @IBOutlet var conHeightSectionHistorySearch : NSLayoutConstraint!
    
    var foundItems : [Product] = []
    var foundUsers : [SearchUser] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)

        let t = UITextField(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width-52, 30))
        t.textColor = Theme.PrimaryColorDark
        t.borderStyle = UITextBorderStyle.None
        t.placeholder = "Cari"
        t.clearButtonMode = UITextFieldViewMode.Always
        t.returnKeyType = UIReturnKeyType.Done
        
        tableView.registerNib(UINib(nibName: "SearchResultHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "head")
        
        txtSearch = t
        
        txtSearch.delegate = self
        
        self.navigationItem.rightBarButtonItem = t.toBarButton()
        
        // Do any additional setup after loading the view.
        UIView.animateWithDuration(0.2, animations: {
            self.navigationController?.navigationBar.tintColor = Theme.PrimaryColor
            self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        })
        
        request(APISearch.GetTopSearch(limit: "10")).responseJSON{req, resp, res, err in
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                self.topSearchLoading.hidden = true
                let json = JSON(res!)
                if let data = json["_data"].array
                {
                    if (data.count > 0)
                    {
                        let width = UIScreen.mainScreen().bounds.width-16
                        var lastView : UIView?
                        for i in 0...data.count-1
                        {
                            let ts = data[i]
                            if let name = ts["name"].string
                            {
                                let searchTag = SearchTag.instance(name)
                                if let lv = lastView
                                {
                                    let x = lv.maxX + 8
                                    searchTag.x = x
                                    
                                    if (searchTag.maxX + 8 > self.sectionTopSearch.width)
                                    {
                                        searchTag.y = lv.maxY + 4
                                    }else
                                    {
                                        searchTag.y = lv.y
                                    }
                                } else
                                {
                                    searchTag.x = 0
                                    searchTag.y = 0
                                }
                                let tap = UITapGestureRecognizer(target: self, action: "searchTopKey:")
                                searchTag.addGestureRecognizer(tap)
                                searchTag.userInteractionEnabled = true
                                searchTag.captionTitle.userInteractionEnabled = true
                                self.sectionTopSearch.addSubview(searchTag)
                                lastView = searchTag
                            }
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
        
        setupHistory()
        
        scrollView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
    }
    
    func setupHistory()
    {
        let arrx = sectionHistorySearch.subviews as! [UIView]
        for v in arrx
        {
            v.removeFromSuperview()
        }
        
        let arr : [String] = AppToolsObjC.searchHistories() as! [String]
        var y : CGFloat = 0.0
        for s in arr
        {
            let tag = SearchTag.instance(s)
            tag.x = 0
            tag.y = y
            let tap = UITapGestureRecognizer(target: self, action: "searchTopKey:")
            tag.addGestureRecognizer(tap)
            tag.userInteractionEnabled = true
            tag.captionTitle.userInteractionEnabled = true
            sectionHistorySearch.addSubview(tag)
            conHeightSectionHistorySearch.constant = tag.maxY
            y = tag.maxY
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        Mixpanel.trackPageVisit("Search")
        
        NSNotificationCenter.defaultCenter().postNotificationName("changeStatusBarColor", object: UIColor.whiteColor())
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
        if (canAnimateBar)
        {
            // Do any additional setup after loading the view.
            UIView.animateWithDuration(0.2, animations: {
                self.navigationController?.navigationBar.tintColor = Theme.PrimaryColor
                self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.navigationController?.navigationBar.tintColor = Theme.PrimaryColor
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
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
    
    override func viewWillDisappear(animated: Bool) {
        UIView.animateWithDuration(0.2, animations: {
            self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
            self.navigationController?.navigationBar.barTintColor = Theme.PrimaryColor
        })
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if (string == "\n")
        {
            textField.resignFirstResponder()
            return false
        }
        var stringx = textField.text as NSString
        
        stringx = stringx.stringByReplacingCharactersInRange(range, withString: string)
        let keyword = stringx as String
        if (keyword == "")
        {
            scrollView.hidden = false
        } else
        {
            scrollView.hidden = true
        }
        
        find(keyword)
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
//        l.searchMode = true
//        l.searchKey = currentKeyword
//        self.navigationController?.pushViewController(l, animated: true)
        return false
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        scrollView.hidden = false
        return true
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
            let t = titleForSection(section)
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
                return ["","PRODUK"]
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
                var c = tableView.dequeueReusableCellWithIdentifier("viewmore") as? UITableViewCell
                if (c == nil)
                {
                    c = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "viewmore")
                }
                c?.textLabel?.text = "Lihat semua produk \"" + currentKeyword + "\""
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
                var c = tableView.dequeueReusableCellWithIdentifier("viewmore") as? UITableViewCell
                if (c == nil)
                {
                    c = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "viewmore")
                }
                c?.textLabel?.text = "Lihat semua user \"" + currentKeyword + "\""
                return c!
            }
            
            let c = tableView.dequeueReusableCellWithIdentifier("user") as! SearchUserCell
            let u = foundUsers[indexPath.row]
            c.captionName.text = u.fullname
            c.ivImage.setImageWithUrl(NSURL(string : u.pict)!, placeHolderImage: nil)
            return c
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.section == 0)
        {
            if (indexPath.row == foundItems.count)
            {
                let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                l.searchMode = true
                l.searchKey = currentKeyword
                request(APISearch.InsertTopSearch(search: txtSearch.text))
                AppToolsObjC.insertNewSearch(txtSearch.text)
                setupHistory()
                self.navigationController?.pushViewController(l, animated: true)
            } else
            {
                request(APISearch.InsertTopSearch(search: txtSearch.text))
                let d = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
                d.product = foundItems[indexPath.row]
                self.navigationController?.pushViewController(d, animated: true)
            }
        } else
        {
            if (indexPath.row == foundUsers.count)
            {
                let u = self.storyboard?.instantiateViewControllerWithIdentifier("searchuser") as! UserSearchViewController
                u.keyword = txtSearch.text
                request(APISearch.InsertTopSearch(search: txtSearch.text))
                self.navigationController?.pushViewController(u, animated: true)
                
            } else
            {
                let d = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
                let u = foundUsers[indexPath.row]
                d.storeMode = true
                d.storeName = u.fullname
                
                request(APISearch.InsertTopSearch(search: u.fullname))
                AppToolsObjC.insertNewSearch(u.fullname)
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
        txtSearch.text = searchTag.captionTitle.text
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
        let pt = [
            "Search Type" : "Product",
            "Search Query" : keyword
        ]
        Mixpanel.trackEvent(MixpanelEvent.Search, properties: pt)
        
        if let req = itemRequest
        {
            req.cancel()
        }
        
        itemRequest = request(APISearch.Find(keyword: keyword, categoryId: "", brandId: "", condition: "", current: 0, limit: 6, priceMin: 0, priceMax: 999999999))
        
        itemRequest?.responseJSON { req, resp, res, err in
            if (APIPrelo.validate(false, err: err, resp: resp))
            {
                self.foundItems = []
                let json = JSON(res!)
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
                self.tableView.reloadData()
            } else
            {
                
            }
        }
    }
    
    var userRequest : Request?
    func findUser(keyword : String)
    {
        // Mixpanel
        let pt = [
            "Search Type" : "User",
            "Search Query" : keyword
        ]
        Mixpanel.trackEvent(MixpanelEvent.Search, properties: pt)
        
        if let req = userRequest
        {
            req.cancel()
        }
        
        userRequest = request(APISearch.User(keyword: keyword))
        userRequest?.responseJSON {req, resp, res, err in
            if (APIPrelo.validate(false, err : err, resp : resp))
            {
                self.foundUsers = []
                let json = JSON(res!)
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
                self.tableView.reloadData()
            } else
            {
                
            }
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
