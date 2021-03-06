//
//  UserSearchViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/29/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit
import Alamofire

class UserSearchViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate
{

    @IBOutlet var tableView : UITableView!
    
    var users : [SearchUser] = []
    var keyword = ""
    var failed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        getUsers()
    }
    
    func getUsers()
    {
        self.title = "Loading.."
        // API Migrasi
        let _ = request(APISearch.user(keyword: keyword))
//            .responseJSON {resp in
            .responseJSON { resp in
            ////print(res)
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Search User"))
            {
                let json = JSON(resp.result.value!)
                if let arr = json["_data"].array
                {
                    for i in 0...arr.count-1
                    {
                        let s = SearchUser.instance(arr[i])
                        self.users.append(s!)
                    }
                }
                self.title = "Pengguna bernama '"+self.keyword+"'"
            } else
            {
                self.title = "Gagal"
                self.failed = true
            }
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.failed == true)
        {
            return 1
        }
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (self.failed == true)
        {
            let c = tableView.dequeueReusableCell(withIdentifier: "cell2")
            return c!
        }
        
        let c = tableView.dequeueReusableCell(withIdentifier: "cell") as! SearchUserCell2
        
        let s = users[(indexPath as NSIndexPath).row]
        
        c.captionFullname.text = s.fullname
        c.captionUsername.text = s.username
        c.iv.afSetImage(withURL: URL(string : s.pict)!, withFilter: .circle)
        
        c.decorate()
        
        return c
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (self.failed == true)
        {
            getUsers()
        } else
        {
            let u = users[(indexPath as NSIndexPath).row]
            
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
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (self.failed == true)
        {
            return 44
        } else
        {
            return 80
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

class SearchUserCell2 : UITableViewCell
{
    @IBOutlet var iv : UIImageView!
    @IBOutlet var captionFullname : UILabel!
    @IBOutlet var captionUsername : UILabel!
    
    var decorated = false
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        iv.afCancelRequest()
    }
    
    func decorate()
    {
        self.iv.layoutIfNeeded()
        self.iv.layer.cornerRadius = self.iv.width / 2
        self.iv.layer.masksToBounds = true
        
        self.iv.layer.borderColor = Theme.GrayLight.cgColor
        self.iv.layer.borderWidth = 1.5

        decorated = true
    }
}
