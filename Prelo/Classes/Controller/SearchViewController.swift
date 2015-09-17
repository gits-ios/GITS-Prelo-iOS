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
    @IBOutlet var topSearchLoading : UIActivityIndicatorView!
    
    @IBOutlet var conHeightSectionTopSearch : NSLayoutConstraint!
    
    var foundItems : [Product] = []
    var foundUsers : [SearchUser] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)

        let t = UITextField(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width-52, 30))
        t.textColor = Theme.PrimaryColorDark
        t.borderStyle = UITextBorderStyle.None
        t.placeholder = "Cari"
        
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
        
        scrollView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
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
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0)
        {
            return "PRODUK"
        } else
        {
            return "USER"
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0)
        {
            return foundItems.count
        } else
        {
            return foundUsers.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 0)
        {
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
            let c = tableView.dequeueReusableCellWithIdentifier("user") as! SearchUserCell
            let u = foundUsers[indexPath.row]
            c.captionName.text = u.fullname
            c.ivImage.setImageWithUrl(NSURL(string : u.pict)!, placeHolderImage: nil)
            return c
        }
    }
    
    var itemRequest : Request?
    func find(keyword : String)
    {
        findItem(keyword)
        findUser(keyword)
    }
    
    func findItem(keyword : String)
    {
        if let req = itemRequest
        {
            req.cancel()
        }
        
        itemRequest = request(APISearch.Find(keyword: keyword, categoryId: "", brandId: "", condition: "", current: 0, limit: 5, priceMin: 0, priceMax: 999999999))
        
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
