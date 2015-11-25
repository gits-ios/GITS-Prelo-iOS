//
//  InboxViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/9/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class InboxViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate
{

    @IBOutlet var tableView : UITableView!
    var inboxes : [Inbox] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Inbox"
        
        tableView.tableFooterView = UIView()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        getInboxes()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.trackPageVisit("Inbox")
    }
    
    func getInboxes()
    {
        request(APIInbox.GetInboxes).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                let json = JSON(res!)
                if let arr = json["_data"].array
                {
                    if (arr.count > 0)
                    {
                        for i in 0...arr.count-1
                        {
                            let inbox = arr[i]
                            println(inbox)
                            self.inboxes.append(Inbox(jsn: inbox))
                        }
                    }
                }
                self.tableView.reloadData()
            } else
            {
                
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inboxes.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! InboxCell
        let i = inboxes[indexPath.row]
        
        cell.captionName.text = i.theirName
        cell.captionMessage.text = i.message
        cell.captionProductName.text = i.itemName
        cell.iv.setImageWithUrl(i.imageURL, placeHolderImage: nil)
        cell.captionTime.text = i.date.relativeDescription
        
        if (i.threadState == 0)
        {
            cell.captionType.text = "PESAN"
        }
        
        if (i.threadState == 1)
        {
            cell.captionType.text = "TAWARAN BARU"
        }
        
        if (i.threadState == 2)
        {
            cell.captionType.text = "TAWARAN DITERIMA"
        }
        
        if (i.threadState == 3)
        {
            cell.captionType.text = "TAWARAN DITOLAK"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let t = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdTawar) as! TawarViewController
        t.tawarItem = inboxes[indexPath.row]
        self.navigationController?.pushViewController(t, animated: true)
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

class InboxCell : UITableViewCell
{
    @IBOutlet var captionName : UILabel!
    @IBOutlet var captionProductName : UILabel!
    @IBOutlet var captionMessage : UILabel!
    @IBOutlet var captionType : UILabel!
    @IBOutlet var captionTime : UILabel!
    @IBOutlet var iv : UIImageView!
}
