//
//  InboxViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/9/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Alamofire

class InboxViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, TawarDelegate
{

    @IBOutlet var tableView : UITableView!
    var inboxes : [Inbox] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = PageName.Inbox
        
        tableView.tableFooterView = UIView()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        getInboxes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        //Mixpanel.trackPageVisit(PageName.Inbox)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Inbox)
    }
    
    func getInboxes()
    {
        // API Migrasi
        let _ = request(APIInbox.getInboxes).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Inbox"))
            {
                let json = JSON(resp.result.value!)
                if let arr = json["_data"].array
                {
                    if (arr.count > 0)
                    {
                        for i in 0...arr.count-1
                        {
                            let inbox = arr[i]
                            //print(inbox)
                            self.inboxes.append(Inbox(jsn: inbox))
                        }
                    }
                }
                self.tableView.reloadData()
            } else
            {
                
            }
        }.responseString { resp in
            //print(string)
        }
//        let url = NSBundle.mainBundle().URLForResource("inbox", withExtension: ".json")
//        request(.GET, (url?.absoluteString)!).responseJSON {resp in
//            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Inbox"))
//            {
//                let json = JSON(resp.result.value!)
//                if let arr = json["_data"].array
//                {
//                    if (arr.count > 0)
//                    {
//                        for i in 0...arr.count-1
//                        {
//                            let inbox = arr[i]
//                            print(inbox)
//                            self.inboxes.append(Inbox(jsn: inbox))
//                        }
//                    }
//                }
//                self.tableView.reloadData()
//            } else
//            {
//                
//            }
//
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inboxes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! InboxCell
        let i = inboxes[(indexPath as NSIndexPath).row]
        
        cell.captionName.text = i.theirName
        cell.captionMessage.text = i.message
        cell.captionProductName.text = i.itemName
        cell.iv.downloadedFrom(url: i.imageURL)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let t = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdTawar) as! TawarViewController
        t.tawarItem = inboxes[(indexPath as NSIndexPath).row]
        t.tawarDelegate = self
        self.navigationController?.pushViewController(t, animated: true)
    }
    
    func tawarNeedReloadList()
    {
        self.tableView.reloadData()
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
    
    override func prepareForReuse() {
        iv.image = nil
    }
}
