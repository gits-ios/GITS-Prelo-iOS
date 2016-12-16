//
//  ProductCommentsController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Alamofire

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ProductCommentsController: BaseViewController, UITextViewDelegate, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate
{

    @IBOutlet var tableView : UITableView!
    @IBOutlet var txtMessage : UITextView!
    @IBOutlet var conHeightTxtMessage : NSLayoutConstraint!
    @IBOutlet var conMarginBottomSectionInput : NSLayoutConstraint!
    @IBOutlet var btnSend : UIButton!
    @IBOutlet var loading: UIActivityIndicatorView!
    
    @IBOutlet var consTopVwHeader: NSLayoutConstraint!
    @IBOutlet var vwHeader: UIView!
    
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
        btnSend.addTarget(self, action: #selector(ProductCommentsController.send), for: UIControlEvents.touchUpInside)
        
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorStyle = .none
        
        getComments()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        //Mixpanel.trackPageVisit(PageName.ProductDetailComment, otherParam: p)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.ProductDetailComment)
        
        self.an_subscribeKeyboard(animations: {i, f, o in
            
            if (o)
            {
                self.conMarginBottomSectionInput.constant = i.height
            } else
            {
                self.conMarginBottomSectionInput.constant = 0
            }
            
            }, completion: nil)
        
        // Init growing text handler
        growHandler = GrowingTextViewHandler(textView: txtMessage, withHeightConstraint: conHeightTxtMessage)
        growHandler?.updateMinimumNumber(ofLines: 1, andMaximumNumberOfLine: 4)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.an_unsubscribeKeyboard()
    }
    
    var sellerId : String = ""
    func getComments()
    {
        // API Migrasi
        let _ = request(APIProduct.getComment(productID: pDetail.productID)).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Komentar Barang"))
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
        //Mixpanel.trackEvent(MixpanelEvent.CommentedProduct, properties: pt)
        
        self.btnSend.isHidden = true
        
        txtMessage.resignFirstResponder()
        txtMessage.isEditable = false
        
        // API Migrasi
        let _ = request(APIProduct.postComment(productID: pDetail.productID, message: m!, mentions: "")).responseJSON {resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Kirim Komentar Barang"))
            {
                self.txtMessage.text = ""
                self.growHandler?.setText(self.txtMessage.text, withAnimation: true)
                self.txtMessage.isEditable = true
                self.btnSend.isHidden = false
                self.getComments()
            } else
            {
                self.txtMessage.isEditable = true
                self.btnSend.isHidden = false
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func textViewDidChange(_ textView: UITextView) {
//        if (textView.text == "")
//        {
//            btnSend.enabled = false
//        } else
//        {
//            btnSend.enabled = true
//        }
        growHandler?.resizeTextView(withAnimation: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = comments[(indexPath as NSIndexPath).row]
        let i = comment.isSeller(sellerId) ? "cell2" : "cell1"
        let c = tableView.dequeueReusableCell(withIdentifier: i) as! ProductCellDiscussion
        
        if (comment.posterImageURL != nil) {
            c.ivCover?.afSetImage(withURL: comment.posterImageURL!)
        }
        c.captionMessage?.text = comment.message
        if (comment.isDeleted) {
            c.captionMessage?.font = UIFont.italicSystemFont(ofSize: 13)
            c.captionMessage?.textColor = UIColor.lightGray
        } else {
            c.captionMessage?.font = UIFont.systemFont(ofSize: 13)
            c.captionMessage?.textColor = UIColor.darkGray
        }
        c.captionName?.text = comment.name
        c.captionDate?.text = comment.timestamp
        
        let userid = CDUser.getOne()?.id
        let senderid = comment.sender_id
        
        if userid != senderid && comment.isDeleted == false {
        c.showReportAlert = { sender, commentId in
            let alert = UIAlertController(title: nil, message: "Laporkan Komentar", preferredStyle: .actionSheet)
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.addAction(UIAlertAction(title: "Batal", style: .destructive, handler: { act in
                alert.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Mengganggu / spam", style: .default, handler: { act in
                self.reportComment(commentId: commentId, reportType: 0)
                alert.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Tidak layak", style: .default, handler: { act in
                self.reportComment(commentId: commentId, reportType: 1)
                alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
            
        } else{
            c.lblReport.isHidden = true
        }
        c.goToProfile = { userId in
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "productList") as! ListItemViewController
            vc.currentMode = .shop
            vc.shopId = userId
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        return c
    }
    
    func reportComment(commentId : String, reportType : Int) {
        request(APIProduct.reportComment(productId: self.pDetail.productID, commentId: commentId, reportType: reportType)).responseJSON { resp in
            if (PreloEndpoints.validate(true, dataResp: resp, reqAlias: "Laporkan Komentar")) {
                let json = JSON(resp.result.value!)
                if (json["_data"].boolValue == true) {
                    Constant.showDialog("Komentar Dilaporkan", message: "Terima kasih, Prelo akan meninjau laporan kamu")
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let s = comments[(indexPath as NSIndexPath).row].message.boundsWithFontSize(UIFont.systemFont(ofSize: 14), width: UIScreen.main.bounds.size.width-72)
        return 47+(s.height)
    }

    @IBAction func topHeaderPressed(_ sender: AnyObject) {
        self.consTopVwHeader.constant = -(self.vwHeader.height)
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
