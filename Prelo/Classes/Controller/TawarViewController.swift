//
//  TawarViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/7/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

protocol  TawarItem
{
    var itemName : String {get}
    var itemId : String {get}
    var productImage : NSURL {get}
    var title : String {get}
    var price : String {get}
    var sellerId : String {get}
    var sellerImage : NSURL {get}
    var sellerName : String {get}
    var buyerId : String {get}
    var buyerImage : NSURL {get}
    var buyerName : String {get}
    var sellerIsMe : Bool {get}
    var threadId : String {get}
}

class TawarViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate
{

    @IBOutlet var tableView : UITableView!
    @IBOutlet var header : TawarHeader!
//    var messages = Set(["Tes tes", "Kenapa ?", "Bagus euy..\nDapet dari mana ?\nboleh jadi reseller gaakkk :)", "gamauuuu", "liat aja harganya diatas atuuh -__-", "wkwkwkwk da gitu dia mah"])
//    var isme = Set([false, true])
    
    var tawarItem : TawarItem!
    var inboxMessages : [InboxMessage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = tawarItem.title
        header.captionProductName.text = tawarItem.itemName
        header.captionPrice.text = tawarItem.price
        header.captionUsername.text = tawarItem.sellerName
        header.ivProduct.setImageWithUrl(tawarItem.productImage, placeHolderImage: nil)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        getMessages()
    }
    
    func getMessages()
    {
        inboxMessages.removeAll(keepCapacity: false)
        request(APIInbox.GetInboxMessage(inboxId: tawarItem.threadId)).responseJSON {req, resp, res, err in
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                let json = JSON(res!)
                if let arr = json["_data"]["messages"].array
                {
                    if (arr.count > 0)
                    {
                        for i in 0...arr.count-1
                        {
                            self.inboxMessages.append(InboxMessage(msgJSON: arr[i]))
                        }
                    }
                }
                self.tableView.reloadData()
                self.scroll()
            } else
            {
                
            }
        }
    }
    
    @IBAction func addChat(sender : UIView?)
    {
        if (tawarItem.threadId == "")
        {
            startNew()
            return
        }
        
        request(APIInbox.SendTo(inboxId: tawarItem.threadId, type: 0, message: "Hardcode Kumang")).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                self.getMessages()
            } else
            {
                
            }
        }
    }
    
    func startNew()
    {
        request(APIInbox.StartNewOne(productId: tawarItem.itemId, type: 0, message: "Starter Kumang")).responseJSON {req, resp, res, err in
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                self.navigationController?.popViewControllerAnimated(true)
            } else
            {
                
            }
        }
    }
    
    func scroll()
    {
        NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "scrollToBottom", userInfo: nil, repeats: false)
    }
    
    func scrollToBottom()
    {
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: inboxMessages.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var chats : Array<DummyChat> = []
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inboxMessages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let m = inboxMessages[indexPath.row]
        var id = m.isMe ? "me" : "them"
        var cell = tableView.dequeueReusableCellWithIdentifier(id) as! TawarCell
        
        cell.decor()
        
        cell.captionMessage.text = m.message
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let chat = inboxMessages[indexPath.row]
        let s = chat.message.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.width-204)
        return 57 + s.height
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func randomElementIndex<T>(s: Set<T>) -> T {
        let n = Int(arc4random_uniform(UInt32(s.count)))
        let i = advance(s.startIndex, n)
        return s[i]
    }
}

class TawarCell : UITableViewCell
{
    @IBOutlet var avatar : UIImageView!
    @IBOutlet var captionMessage : UILabel!
    @IBOutlet var captionTime : UILabel!
    @IBOutlet var sectionMessage : UIView!
    
    var decorated = false
    func decor()
    {
        if (decorated == false)
        {
            self.avatar.layer.cornerRadius = self.avatar.width / 2
            self.avatar.layer.masksToBounds = true
            self.sectionMessage.layer.cornerRadius = 4
            self.sectionMessage.layer.masksToBounds = true
            decorated = true
        }
    }
}

class TawarHeader : UIView
{
    @IBOutlet var ivProduct : UIImageView!
    @IBOutlet var captionProductName : UILabel!
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var captionUsername : UILabel!
    @IBOutlet var btnTawar : UIButton!
    @IBOutlet var btnTawarFull : UIButton!
    @IBOutlet var btnBeli : UIButton!
    @IBOutlet var btnBatal : UIButton!
}

class DummyChat : NSObject
{
    var message = ""
    var isMe = false
    
    init(m : String, me : Bool)
    {
        message = m
        isMe = me
    }
}
