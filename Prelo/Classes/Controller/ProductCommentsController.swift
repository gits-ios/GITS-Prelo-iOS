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
    
    var growHandler : GrowingTextViewHandler?
    
    var total = 5
    var myComment : Set<Int> = [1, 2]
    
    var texts : Array<String> = ["wakaka"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.dataSource = self
        tableView.delegate = self
        
        txtMessage.delegate = self
        btnSend.addTarget(self, action: "send", forControlEvents: UIControlEvents.TouchUpInside)
        
        growHandler = GrowingTextViewHandler(textView: txtMessage, withHeightConstraint: conHeightTxtMessage)
        growHandler?.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 4)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboardWithAnimations({i, f, o in
            
            if (o)
            {
                self.conMarginBottomSectionInput.constant = i.height
            } else
            {
                self.conMarginBottomSectionInput.constant = 0
            }
            
            }, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.an_unsubscribeKeyboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func textViewDidChange(textView: UITextView) {
        growHandler?.resizeTextViewWithAnimation(true)
    }
    
    @IBAction func send()
    {
        txtMessage.text = ""
        growHandler?.setText(txtMessage.text, withAnimation: true)
        
        myComment.insert(total)
        total++
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return total
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let i = myComment.contains(indexPath.row) ? "cell2" : "cell1"
        let c = tableView.dequeueReusableCellWithIdentifier(i) as! ProductCellDiscussion
        
        c.captionMessage?.text = texts.objectAtCircleIndex(indexPath.row)
        c.captionName?.text = "Vito Scaletta"
        c.captionDate?.text = "2 Abad Lalu"
        
        return c
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let s = texts.objectAtCircleIndex(indexPath.row).boundsWithFontSize(UIFont.systemFontOfSize(12), width: UIScreen.mainScreen().bounds.size.width-72)
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
