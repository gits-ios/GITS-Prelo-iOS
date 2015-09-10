//
//  MyProductSellViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class MyProductSellViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView : UITableView!
    var products : Array<Product> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        request(APIUser.MyProductSell)
            .responseJSON{_, resp, res, err in
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
                    if let result: AnyObject = res
                    {
                        let j = JSON(result)
                        let d = j["_data"].arrayObject
                        if let data = d
                        {
                            for json in data
                            {
                                self.products.append(Product.instance(JSON(json))!)
                                self.tableView.tableFooterView = UIView()
                                self.tableView.reloadData()
                            }
                        }
                    }
                } else {
                    
                }
        }
        
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let m = tableView.dequeueReusableCellWithIdentifier("cell") as! MyProductCell
        let p = products[indexPath.row]
        m.captionName.text = p.name
        m.captionPrice.text = p.price
        m.captionTotalComment.text = p.discussionCountText
        m.captionTotalLove.text = p.loveCountText
        m.captionDate.text = p.time
        
        if let isActive = p.json["is_active"].bool
        {
            m.captionStatus.text = isActive ? "AKTIF" : "TIDAK AKTIF"
        }
        
        m.ivCover.image = nil
        if let url = p.coverImageURL
        {
            m.ivCover.setImageWithUrl(url, placeHolderImage: nil)
        }
        
        return m
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    var selectedProduct : Product?
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        selectedProduct = products[indexPath.row]
        
        var d:ProductDetailViewController = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdProductDetail) as! ProductDetailViewController
        d.product = selectedProduct!
        
        self.previousController?.navigationController?.pushViewController(d, animated: true)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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

class MyProductCell : UITableViewCell
{
    @IBOutlet var captionName : UILabel!
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var captionStatus : UILabel!
    @IBOutlet var captionDate : UILabel!
    @IBOutlet var captionTotalLove : UILabel!
    @IBOutlet var captionTotalComment : UILabel!
    @IBOutlet var ivCover : UIImageView!
}