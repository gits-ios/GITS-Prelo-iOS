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
    var myId : String {get}
    var myImage : NSURL {get}
    var myName : String {get}
    var theirId : String {get}
    var theirImage : NSURL {get}
    var theirName : String {get}
    var opIsMe : Bool {get}
    var threadId : String {get}
    var threadState : Int {get}
    var bargainPrice : Int {get}
}

class TawarViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIScrollViewDelegate, MessagePoolDelegate
{

    @IBOutlet var tableView : UITableView!
    @IBOutlet var header : TawarHeader!
    @IBOutlet var btnSend : UIButton!
    @IBOutlet var textView : UITextView!
    @IBOutlet var conMarginBottom : NSLayoutConstraint!
    @IBOutlet var conHeightTextView : NSLayoutConstraint!
    var textViewGrowHandler : GrowingTextViewHandler!
    
    var prodId : String = ""
    var loadInboxFirst = false
    var tawarItem : TawarItem!
    var inboxMessages : [InboxMessage] = []
    var first = true
    var isAtBottom = false
    
    @IBOutlet var btnTawar1 : UIButton!
    @IBOutlet var btnTawar2 : UIButton!
    @IBOutlet var btnBeli : UIButton!
    @IBOutlet var btnBatal : UIButton!
    @IBOutlet var btnTolak : UIButton!
    @IBOutlet var btnConfirm : UIButton!
    @IBOutlet var txtTawar : UITextField!
    @IBOutlet var sectionTawar : UIView!
    @IBOutlet var conMarginBottomSectionTawar : NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        textViewGrowHandler = GrowingTextViewHandler(textView: textView, withHeightConstraint: conHeightTextView)
        textViewGrowHandler.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 4)
        
        self.title = tawarItem.title
        header.captionProductName.text = tawarItem.itemName
        if (tawarItem.bargainPrice != 0)
        {
            header.captionPrice.text = tawarItem.bargainPrice.asPrice
            header.captionOldPrice.text = tawarItem.price
        } else
        {
            header.captionPrice.text = tawarItem.price
            header.captionOldPrice.text = ""
        }
        header.captionUsername.text = tawarItem.myName
        header.ivProduct.setImageWithUrl(tawarItem.productImage, placeHolderImage: nil)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        self.btnSend.userInteractionEnabled = false
        textView.delegate = self
        
        btnTawar1.addTarget(self, action: "showTawar:", forControlEvents: UIControlEvents.TouchUpInside)
        btnTawar2.addTarget(self, action: "showTawar:", forControlEvents: UIControlEvents.TouchUpInside)
        
        adjustButtons()
        
        if (loadInboxFirst)
        {
            getInbox()
        } else
        {
            if (tawarItem.threadId != "")
            {
                getMessages()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.sharedInstance().track("Inbox Detail")
    }
    
    func adjustButtons()
    {
        if (tawarItem.opIsMe == false && tawarItem.threadState == 0)
        {
            btnTawar1.hidden = true
            btnBeli.hidden = true
            btnTawar2.hidden = false
        }
        
        if (tawarItem.threadState == 1) // udah di tawar
        {
            
            if (tawarItem.opIsMe == false)
            {
                btnTawar1.hidden = true
                btnBeli.hidden = true
                
                btnTolak.hidden = false
                btnConfirm.hidden = false
                
                btnTolak.addTarget(self, action: "rejectTawar:", forControlEvents: UIControlEvents.TouchUpInside)
                btnConfirm.addTarget(self, action: "confirmTawar:", forControlEvents: UIControlEvents.TouchUpInside)
            } else
            {
                btnTawar1.hidden = true
                btnBatal.hidden = false
                
                btnBatal.addTarget(self, action: "rejectTawar:", forControlEvents: UIControlEvents.TouchUpInside)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.an_subscribeKeyboardWithAnimations({ frame, interval, opening in
            
            if (opening)
            {
                self.conMarginBottom.constant = frame.height
                self.conMarginBottomSectionTawar.constant = frame.height
            } else
            {
                self.conMarginBottom.constant = 0
                self.conMarginBottomSectionTawar.constant = 0
            }
            
            }, completion: {finish in
                
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let del = UIApplication.sharedApplication().delegate as! AppDelegate
        del.messagePool.removeDelegate(tawarItem.threadId)
        self.an_unsubscribeKeyboard()
    }
    
    func getInbox()
    {
        self.tableView.hidden = true
        request(APIInbox.GetInboxByProductID(productId: prodId)).responseJSON { req, resp, res, err in
            self.tableView.hidden = false
            let json = JSON(res!)
            let data = json["_data"]
            let i = Inbox(jsn: data)
            println(data)
            self.tawarItem = i
            self.adjustButtons()
            self.getMessages()
            println(res)
        }
    }
    
    func getMessages()
    {
        inboxMessages.removeAll(keepCapacity: false)
        request(APIInbox.GetInboxMessage(inboxId: tawarItem.threadId)).responseJSON {req, resp, res, err in
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                let json = JSON(res!)
                println(res)
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
                if (self.first)
                {
                    self.first = false
                    self.scroll()
                }
                
                let del = UIApplication.sharedApplication().delegate as! AppDelegate
                del.messagePool.registerDelegate(self.tawarItem.threadId, d: self)
            } else
            {
                
            }
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        textViewGrowHandler.resizeTextViewWithAnimation(true)
        if (textView.text == "")
        {
            btnSend.userInteractionEnabled = false
        } else
        {
            btnSend.userInteractionEnabled = true
        }
    }
    
    @IBAction func beli(sender : UIView?)
    {
        var success = true
        if let x = CartProduct.getOne(tawarItem.itemId, email: User.EmailOrEmptyString)
        {
            
        } else
        {
            if (CartProduct.newOne(tawarItem.itemId, email : User.EmailOrEmptyString, name : tawarItem.itemName) == nil) {
                success = false
                Constant.showDialog("Failed", message: "Gagal Menyimpan")
            }
        }
        
        if (success)
        {
            self.performSegueWithIdentifier("segCart", sender: nil)
        }
    }
    
    @IBAction func showTawar(sender : UIView?)
    {
        sectionTawar.hidden = false
        txtTawar.becomeFirstResponder()
    }
    
    @IBAction func hideTawar(sender : UIView?)
    {
        sectionTawar.hidden = true
        txtTawar.resignFirstResponder()
    }
    
    @IBAction func sendTawar(sender : UIView?)
    {
        if (txtTawar.text == "")
        {
            
        } else
        {
            self.hideTawar(nil)
            if (tawarItem.threadId == "")
            {
                startNew(1, message : txtTawar.text)
            } else {
                sendChat(1, message: txtTawar.text)
            }
            txtTawar.text = ""
            btnTawar1.hidden = true
            btnTawar2.hidden = true
            btnBatal.hidden = false
        }
    }
    
    func rejectTawar(sender : UIView?)
    {
        sendChat(3, message: String(tawarItem.bargainPrice))
    }
    
    func confirmTawar(sender : UIView?)
    {
        sendChat(2, message : String(tawarItem.bargainPrice))
    }
    
    @IBAction func addChat(sender : UIView?)
    {
        if (tawarItem.threadId == "")
        {
            startNew(0, message : textView.text)
            return
        }
        
        sendChat(0, message: textView.text)
    }
    
    func sendChat(type : Int, message : String)
    {
        let localId = inboxMessages.count
        let date = NSDate()
        let f = NSDateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        var time = f.stringFromDate(date)
        let i = InboxMessage.messageFromMe(localId, type: type, message: message, time: time)
        inboxMessages.append(i)
        
        self.textView.text = ""
        
        i.sendTo(tawarItem.threadId, completion: { m in
            self.tableView.reloadData()
        })
        
        self.tableView.reloadData()
        self.scrollToBottom()
    }
    
    func startNew(type : Int, message : String)
    {
        request(APIInbox.StartNewOne(productId: prodId, type: type, message: message)).responseJSON {req, resp, res, err in
            println(res)
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                let json = JSON(res!)
                let data = json["_data"]
                let inbox = Inbox(jsn: data)
                self.tawarItem = inbox
                
                let localId = self.inboxMessages.count
                let date = NSDate()
                let f = NSDateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                var time = f.stringFromDate(date)
                let i = InboxMessage.messageFromMe(localId, type: type, message: message, time: time)
                self.inboxMessages.append(i)
                self.textView.text = ""
                self.tableView.reloadData()
                self.scrollToBottom()
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
        if (inboxMessages.count > 0)
        {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: inboxMessages.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
        }
        self.isAtBottom = true
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
        
        cell.inboxMessage = m
        cell.decor()
        
        if (m.isMe)
        {
            
        } else
        {
            cell.avatar.setImageWithUrl(tawarItem.theirImage, placeHolderImage: nil)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let chat = inboxMessages[indexPath.row]
        var m = chat.dynamicMessage
        if (chat.failedToSend)
        {
            m = "[GAGAL MENGIRIM]\n\n" + m
        }
        let s = m.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.width-204)
        return 57 + s.height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(true)
    }
    
    var dragged = false
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        dragged = true
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = scrollView.contentSize.height
        let contentYOffset = scrollView.contentOffset.y
        let distanceFromBottom = height - contentYOffset
        if (distanceFromBottom >= scrollView.height)
        {
            self.isAtBottom = false
        } else
        {
            self.isAtBottom = true
        }
    }
    
    func messageArrived(message: InboxMessage) {
        
        inboxMessages.append(message)
        self.tableView.reloadData()
        
        if (self.isAtBottom)
        {
            self.scrollToBottom()
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
    @IBOutlet var captionArrow : UILabel!
    @IBOutlet var captionTime : KDEDateLabel!
    @IBOutlet var sectionMessage : UIView!
    @IBOutlet var captionSending : UILabel?
    @IBOutlet var btnRetry : UIButton?
    
    var inboxMessage : InboxMessage?
    
    let formatter = NSDateFormatter()
    var formattedLongTime : String?
    
    var decorated = false
    func decor()
    {
        if (decorated == false)
        {
            formatter.dateFormat = "dd MMM"
            self.avatar.layer.cornerRadius = self.avatar.width / 2
            self.avatar.layer.masksToBounds = true
            self.sectionMessage.layer.cornerRadius = 4
            self.sectionMessage.layer.masksToBounds = true
            decorated = true
            
            self.captionTime.dateFormatTextBlock = { (date) in
                return date.relativeDescription
            }
        }
        
        if let m = inboxMessage
        {
            if (m.isMe)
            {
                self.sectionMessage.backgroundColor = Theme.PrimaryColor
                self.captionMessage.textColor = UIColor.whiteColor()
            } else
            {
                self.sectionMessage.backgroundColor = UIColor(hex: "#E8ECEE")
                self.captionMessage.textColor = UIColor.darkGrayColor()
            }
            
            self.btnRetry?.hidden = true
            self.captionSending?.hidden = true
            
            if (m.failedToSend)
            {
                self.captionMessage.text = "[GAGAL MENGIRIM]\n\n" + m.message
                self.captionMessage.textColor = UIColor.whiteColor()
                self.sectionMessage.backgroundColor = UIColor(hex : "#AC281C")
                self.btnRetry?.hidden = false
            } else
            {
                self.captionMessage.text = m.dynamicMessage
            }
            
            if (m.sending)
            {
                self.captionSending?.hidden = false
                self.captionTime.text = "sending..."
            } else {
                self.captionTime.date = m.dateTime
            }
            
            if (m.messageType == 1)
            {
                self.sectionMessage.backgroundColor = Theme.ThemeOrage
                self.captionMessage.textColor = UIColor.whiteColor()
            }
            
            if (m.messageType == 3)
            {
                self.sectionMessage.backgroundColor = UIColor(hex: "#E8ECEE")
                self.captionMessage.textColor = UIColor.darkGrayColor()
            }
            
            self.captionArrow.textColor = self.sectionMessage.backgroundColor
            
            self.selectionStyle = UITableViewCellSelectionStyle.None
        }
    }
    
    @IBAction func resendMe(sender : UIView)
    {
        if let m = inboxMessage
        {
            m.resend()
            self.decor()
        }
    }
}

class TawarHeader : UIView
{
    @IBOutlet var ivProduct : UIImageView!
    @IBOutlet var captionProductName : UILabel!
    @IBOutlet var captionPrice : UILabel!
    @IBOutlet var captionOldPrice : UILabel!
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
