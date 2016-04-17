//
//  ProductCommentsController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class ProductCommentsController: BaseViewController, UITextViewDelegate, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate
{

    @IBOutlet var tableView : UITableView!
    @IBOutlet var txtMessage : UITextView!
    @IBOutlet var conHeightTxtMessage : NSLayoutConstraint!
    @IBOutlet var conMarginBottomSectionInput : NSLayoutConstraint!
    @IBOutlet var btnSend : UIButton!
    @IBOutlet var loading: UIActivityIndicatorView!
    
    var pDetail : ProductDetail!
    
    var growHandler : GrowingTextViewHandler?
    
    var total = 5
    var myComment : Set<Int> = [1, 2]
    
    var texts : Array<String> = ["wakaka"]
    
    var comments : [ProductDiscussion] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = "Komentar \(pDetail.name)"
        
        tableView.dataSource = self
        tableView.delegate = self
        
        txtMessage.delegate = self
        btnSend.addTarget(self, action: "send", forControlEvents: UIControlEvents.TouchUpInside)
        
        tableView.tableFooterView = UIView()
        
        growHandler = GrowingTextViewHandler(textView: txtMessage, withHeightConstraint: conHeightTxtMessage)
        growHandler?.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 4)
        
        getComments()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mixpanel
        let p = [
            "Product" : ((pDetail != nil) ? (pDetail!.name) : ""),
            "Product ID" : ((pDetail != nil) ? (pDetail!.productID) : ""),
            "Category 1" : ((pDetail != nil && pDetail?.categoryBreadcrumbs.count > 1) ? (pDetail!.categoryBreadcrumbs[1]["name"].string!) : ""),
            "Category 2" : ((pDetail != nil && pDetail?.categoryBreadcrumbs.count > 2) ? (pDetail!.categoryBreadcrumbs[2]["name"].string!) : ""),
            "Category 3" : ((pDetail != nil && pDetail?.categoryBreadcrumbs.count > 3) ? (pDetail!.categoryBreadcrumbs[3]["name"].string!) : ""),
            "Seller" : ((pDetail != nil) ? (pDetail!.theirName) : "")
        ]
        Mixpanel.trackPageVisit(PageName.ProductDetailComment, otherParam: p)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ProductDetailComment)
        
        self.an_subscribeKeyboardWithAnimations({i, f, o in
            
            if (o)
            {
                self.conMarginBottomSectionInput.constant = i.height
            } else
            {
                self.conMarginBottomSectionInput.constant = 0
            }
            
            }, completion: nil)
        
        // Remove redirect alert if any
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let redirAlert = appDelegate.redirAlert {
            redirAlert.dismissWithClickedButtonIndex(-1, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.an_unsubscribeKeyboard()
    }
    
    var sellerId : String = ""
    func getComments()
    {
        // API Migrasi
        request(APIProduct.GetComment(productID: pDetail.productID)).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Komentar Barang"))
            {
                self.comments = []
                self.tableView.reloadData()
                let json = JSON(resp.result.value!)
                if let id = json["_data"]["seller_id"].string
                {
                    self.sellerId = id
                    if let arr = json["_data"]["comments"].array
                    {
                        if (arr.count > 0)
                        {
                            for i in 0...arr.count-1
                            {
                                let comment = ProductDiscussion.instance(arr[i])
                                self.comments.append(comment!)
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
    
    @IBAction func send()
    {
        let m = txtMessage.text
        if (m == "")
        {
            return
        }
        
        // Mixpanel
        let pt = [
            "Product Name" : ((pDetail != nil) ? (pDetail!.name) : ""),
            "Category 1" : ((pDetail != nil && pDetail?.categoryBreadcrumbs.count > 1) ? (pDetail!.categoryBreadcrumbs[1]["name"].string!) : ""),
            "Category 2" : ((pDetail != nil && pDetail?.categoryBreadcrumbs.count > 2) ? (pDetail!.categoryBreadcrumbs[2]["name"].string!) : ""),
            "Category 3" : ((pDetail != nil && pDetail?.categoryBreadcrumbs.count > 3) ? (pDetail!.categoryBreadcrumbs[3]["name"].string!) : ""),
            "Seller Name" : ((pDetail != nil) ? (pDetail!.theirName) : "")
        ]
        Mixpanel.trackEvent(MixpanelEvent.CommentedProduct, properties: pt)
        
        self.btnSend.hidden = true
        
        txtMessage.resignFirstResponder()
        txtMessage.editable = false
        
        // API Migrasi
        request(APIProduct.PostComment(productID: pDetail.productID, message: m, mentions: "")).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Kirim Komentar Barang"))
            {
                self.txtMessage.text = ""
                self.growHandler?.setText(self.txtMessage.text, withAnimation: true)
                self.txtMessage.editable = true
                self.btnSend.hidden = false
                self.getComments()
            } else
            {
                self.txtMessage.editable = true
                self.btnSend.hidden = false
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func textViewDidChange(textView: UITextView) {
//        if (textView.text == "")
//        {
//            btnSend.enabled = false
//        } else
//        {
//            btnSend.enabled = true
//        }
        growHandler?.resizeTextViewWithAnimation(true)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let comment = comments[indexPath.row]
        let i = comment.isSeller(sellerId) ? "cell2" : "cell1"
        let c = tableView.dequeueReusableCellWithIdentifier(i) as! ProductCellDiscussion
        
        c.captionMessage?.text = comment.message
        c.captionName?.text = comment.name
        c.captionDate?.text = comment.timestamp
        
        return c
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let s = comments[indexPath.row].message.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.size.width-72)
        return 47+(s.height)
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
