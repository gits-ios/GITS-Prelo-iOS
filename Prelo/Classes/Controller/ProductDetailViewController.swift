//
//  ProductDetailViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/13/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import CoreData
//import FMMosaicLayout
//import ZSWTappableLabel
import MessageUI

protocol ProductCellDelegate
{
    func cellTappedCategory(categoryName : String, categoryID : String)
}

class ProductDetailViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, ProductCellDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate
{
    
    var product : Product?
    var detail : ProductDetail?
    
    var alreadyInCart : Bool = false
    
    @IBOutlet var tableView : UITableView?
    @IBOutlet var btnAddDiscussion : UIButton?
    
//    @IBOutlet var captionBeli: UILabel!
//    @IBOutlet var captionPrice: UILabel!
    
//    @IBOutlet var captionFreeOngkir: UILabel!
    
//    @IBOutlet var ivChat: UIImageView!
    
    var cellTitle : ProductCellTitle?
    var cellSeller : ProductCellSeller?
    var cellDesc : ProductCellDescription?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let i = UIImage(named: "ic_chat")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
//        ivChat.tintColor = UIColor.whiteColor()
//        ivChat.image = i
        
        btnAddDiscussion?.layer.cornerRadius = 4
        btnAddDiscussion?.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnAddDiscussion?.layer.borderWidth = 1
        
        var btnClose = self.createButtonWithIcon(AppFont.Prelo2, icon: "")
        btnClose.addTarget(self, action: "dismiss:", forControlEvents: UIControlEvents.TouchUpInside)
        
        tableView?.contentInset = UIEdgeInsetsMake(0, 0, 44, 0)
        
        var btnOption = self.createButtonWithIcon(AppFont.Prelo2, icon: "")
        btnOption.addTarget(self, action: "option", forControlEvents: UIControlEvents.TouchUpInside)
        self.navigationItem.rightBarButtonItem = btnOption.toBarButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        if (detail == nil) {
            getDetail()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Mixpanel.sharedInstance().track("Product Detail")
        self.titleText = detail?.json["_data"]["name"].string!
        
        if let d = self.detail
        {
            if (CartProduct.isExist((detail?.productID)!, email : User.EmailOrEmptyString)) {
                alreadyInCart = true
            } else {
                alreadyInCart = false
            }
        }
    }
    
    func option()
    {
        let a = UIActionSheet(title: "Option", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: "Cancel")
        a.addButtonWithTitle("Report")
        a.showInView(self.view)
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == 1)
        {
            // report
            let m = MFMailComposeViewController()
            m.setToRecipients(["contact@prelo.id"])
            m.setSubject("Product Report [" + (detail?.productID)! + "]")
            m.mailComposeDelegate = self
            self.presentViewController(m, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func getDetail()
    {
        request(Products.Detail(productId: (product?.json)!["_id"].string!))
            .responseJSON{_, resp, res, err in
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
                    self.detail = ProductDetail.instance(JSON(res!))
                    println(self.detail?.json)
                    self.tableView?.dataSource = self
                    self.tableView?.delegate = self
                    self.tableView?.reloadData()
                    self.setupView()
                } else {
                    
                }
        }
    }
    
    func setupView()
    {
        if (self.detail == nil)
        {
            return
        }
        let p = ProductDetailCover.instance((detail?.displayPicturers)!)
        p?.parent = self
        p?.height = UIScreen.mainScreen().bounds.size.width * 340 / 480
        tableView?.tableHeaderView = p
        
        if let price = detail?.json["_data"]["price"].int?.asPrice
        {
//            captionPrice.text = price
        } else {
//            captionPrice.text = Int(0).asPrice
        }
        
        if (CartProduct.isExist((detail?.productID)!, email : User.EmailOrEmptyString)) {
            alreadyInCart = true
        }
        
//        let freeOngkir = (detail?.json["_data"]["is_free_ongkir"].bool)!
        let freeOngkir = false
        if (freeOngkir)
        {
//            captionFreeOngkir.text = "FREE ONGKIR"
        } else
        {
//            captionFreeOngkir.text = "+ ONGKIR"
        }
    }

    @IBAction func dismiss(sender: AnyObject)
    {
        dismissViewControllerAnimated(YES, completion: nil)
    }
    
    // tableview
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 3
        } else {
            return 0+(detail?.discussions?.count)!
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 1+(((detail?.discussions?.count)! == 0) ? 0 : 1)
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                if (cellTitle == nil) {
                    cellTitle = tableView.dequeueReusableCellWithIdentifier("cell_title") as? ProductCellTitle
                }
                cellTitle?.parent = self
                cellTitle?.adapt(detail)
                return cellTitle!
            } else if (indexPath.row == 1) {
                if (cellSeller == nil) {
                    cellSeller = tableView.dequeueReusableCellWithIdentifier("cell_seller") as? ProductCellSeller
                }
                cellSeller?.adapt(detail)
                return cellSeller!
            } else {
                if (cellDesc == nil) {
                    cellDesc = tableView.dequeueReusableCellWithIdentifier("cell_desc") as? ProductCellDescription
                    cellDesc?.cellDelegate = self
                }
                cellDesc?.adapt(detail)
                return cellDesc!
            }
        } else {
            let cell : ProductCellDiscussion = (tableView.dequeueReusableCellWithIdentifier("cell_disc_1") as? ProductCellDiscussion)!
            cell.adapt(detail?.discussions?.objectAtCircleIndex(indexPath.row-3))
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (section == 0) {
            return nil
        } else {
            let l = UILabel()
            l.numberOfLines = 1
            l.textColor = UIColor.lightGrayColor()
            l.backgroundColor = UIColor.clearColor()
            l.text = "KOMENTAR"
            l.font = UIFont.boldSystemFontOfSize(14)
            l.sizeToFit()
            let v = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 40))
            v.backgroundColor = UIColor.whiteColor()
            v.addSubview(l)
            l.x = 8
            l.y = (40-l.height)/2
            return v
        }
        
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (section == 0) {
            return 0
        } else {
            return 40
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                return ProductCellTitle.heightFor(detail)
            } else if (indexPath.row == 1) {
                return ProductCellSeller.heightFor(detail?.json)
            } else {
                return ProductCellDescription.heightFor(detail)
            }
        } else {
            return ProductCellDiscussion.heightFor(detail?.discussions?.objectAtCircleIndex(indexPath.row))
        }
    }
    
    func cellTappedCategory(categoryName: String, categoryID: String) {
        let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        l.standalone = true
        l.standaloneCategoryName = categoryName
        l.standaloneCategoryID = categoryID
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    @IBAction func addToCart(sender: UIButton) {
        if (alreadyInCart) {
            self.performSegueWithIdentifier("segCart", sender: nil)
            return
        }
        
        if (CartProduct.newOne((detail?.productID)!, email : User.EmailOrEmptyString) == nil) {
            Constant.showDialog("Failed", message: "Gagal Menyimpan")
        } else {
            setupView()
            self.performSegueWithIdentifier("segCart", sender: nil)
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "segAddComment")
        {
            let c = segue.destinationViewController as! ProductCommentsController
            c.pDetail = self.detail
        } else
        {
            let c = segue.destinationViewController as! BaseViewController
            c.previousController = self
        }
    }

}

class ProductCellTitle : UITableViewCell, UserRelatedDelegate
{
    @IBOutlet var captionTitle : UILabel?
    @IBOutlet var captionOldPrice : UILabel?
    @IBOutlet var captionPrice : UILabel?
    @IBOutlet var captionCountLove : UILabel?
    @IBOutlet var captionCountComment : UILabel?
    
    @IBOutlet var sectionLove : UIView?
    @IBOutlet var sectionComment : UIView?
    
    @IBOutlet var btnShare : UIButton?
    
    var parent : UIViewController?
    
    var detail : ProductDetail?
    
    static func heightFor(obj : ProductDetail?)->CGFloat
    {
        if (obj == nil) {
            return 110
        }
        var product = (obj?.json)!["_data"]
        
        let name = product["name"].string!
        let s = name.boundsWithFontSize(UIFont.boldSystemFontOfSize(16), width: UIScreen.mainScreen().bounds.size.width-16)
        return 90+s.height
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        btnShare?.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnShare?.layer.borderWidth = 1
        
        btnShare?.addTarget(self, action: "share", forControlEvents: UIControlEvents.TouchUpInside)
        
        sectionLove?.layer.borderColor = UIColor.lightGrayColor().CGColor
        sectionLove?.layer.borderWidth = 1
        sectionLove?.layer.cornerRadius = 2
        sectionLove?.layer.masksToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: "love")
        sectionLove?.addGestureRecognizer(tap)
        
        sectionComment?.layer.borderColor = UIColor.lightGrayColor().CGColor
        sectionComment?.layer.borderWidth = 1
        sectionComment?.layer.cornerRadius = 2
        sectionComment?.layer.masksToBounds = true
        
        let tapcomment = UITapGestureRecognizer(target: self, action: "comment")
        sectionComment?.addGestureRecognizer(tapcomment)
    }
    
    func userLoggedIn() {
        if (loving == true)
        {
            callApiLove()
            loving = false
        }
    }
    
    func userCancelLogin() {
        
    }
    
    func userLoggedOut() {
        
    }
    
    func comment()
    {
        self.parent?.performSegueWithIdentifier("segAddComment", sender: nil)
    }
    
    var isLoved = false
    var loving = false
    func love()
    {
        if (User.IsLoggedIn == false)
        {
            loving = true
            LoginViewController.Show(self.parent!, userRelatedDelegate: self, animated: true)
        } else {
            callApiLove()
        }
    }
    
    func callApiLove()
    {
        if (isLoved)
        {
            callApiUnlove()
            return
        }
        isLoved = true
        setupLoveView()
        request(Products.Love(productID: (detail?.productID)!)).responseJSON{_, resp, res, err in
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                if let s = self.captionCountLove?.text
                {
                    let ns = s as NSString
                    self.captionCountLove?.text = String(ns.integerValue + 1)
                }
            } else
            {
                self.isLoved = false
                self.setupLoveView()
            }
        }
    }
    
    func callApiUnlove()
    {
        isLoved = false
        setupLoveView()
        request(Products.Unlove(productID: (detail?.productID)!)).responseJSON{_, resp, res, err in
            if (APIPrelo.validate(true, err: err, resp: resp))
            {
                if let s = self.captionCountLove?.text
                {
                    let ns = s as NSString
                    self.captionCountLove?.text = String(ns.integerValue - 1)
                }
            } else
            {
                self.isLoved = true
                self.setupLoveView()
            }
        }
    }
    
    func adapt(obj : ProductDetail?)
    {
        if (obj == nil) {
            return
        }
        
        detail = obj
        
        var product = (obj?.json)!["_data"]
        
        captionTitle?.text = obj?.name
        if let oldPrice = product["price_original"].int?.asPrice
        {
            captionOldPrice?.text = oldPrice
        } else
        {
            captionOldPrice?.text = ""
        }
        
        if let price = product["price"].int?.asPrice
        {
            captionPrice?.text = price
        } else
        {
            captionPrice?.text = ""
        }
        
        if let loved = product["love"].bool
        {
            isLoved = loved
            setupLoveView()
        }
        captionCountLove?.text = String(product["num_lovelist"].int!)
        captionCountComment?.text = obj?.discussionCountText
    }
    
    func setupLoveView()
    {
        if (isLoved == true)
        {
            sectionLove?.backgroundColor = Theme.PrimaryColor
            for v in (sectionLove?.subviews)!
            {
                if (v.isKindOfClass(UILabel.classForCoder()))
                {
                    let l = v as! UILabel
                    l.textColor = UIColor.whiteColor()
                } else
                {
                    (v as! UIView).backgroundColor = UIColor.whiteColor()
                }
            }
        } else
        {
            sectionLove?.backgroundColor = UIColor.whiteColor()
            for v in (sectionLove?.subviews)!
            {
                if (v.isKindOfClass(UILabel.classForCoder()))
                {
                    let l = v as! UILabel
                    l.textColor = UIColor(hex: "#858585")
                } else
                {
                    (v as! UIView).backgroundColor = UIColor(hex: "#858585")
                }
            }
        }
    }
    
    func share()
    {
        var item = PreloShareItem()
        let s = detail?.displayPicturers.first
        item.url = NSURL(string: s!)
        item.text = (detail?.name)!
        
        PreloShareController.Share(item, inView: (parent?.navigationController?.view)!)
    }
}

class ProductCellSeller : UITableViewCell
{
    @IBOutlet var captionSellerName : UILabel?
    @IBOutlet var captionSellerRating : UILabel?
    @IBOutlet var ivSellerAvatar : UIImageView?
    
    static func heightFor(obj : JSON?)->CGFloat
    {
        return 86
    }
    
    func adapt(obj : ProductDetail?)
    {
        if (obj == nil) {
            return
        }
        var product = (obj?.json)!["_data"]
        
        captionSellerName?.text = product["seller"]["fullname"].string!
        ivSellerAvatar?.setImageWithUrl((obj?.shopAvatarURL)!, placeHolderImage: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ivSellerAvatar?.layer.cornerRadius = (ivSellerAvatar?.frame.size.width)!/2
        ivSellerAvatar?.layer.masksToBounds = true
    }
}

class ProductCellDescription : UITableViewCell, ZSWTappableLabelTapDelegate
{
    @IBOutlet var captionDesc : UILabel?
    @IBOutlet var captionDate : UILabel?
    @IBOutlet var captionMerk : UILabel?
    @IBOutlet var captionSize : UILabel?
    @IBOutlet var captionCondition : UILabel?
    @IBOutlet var captionFrom : UILabel?
    
    @IBOutlet var captionCategory : ZSWTappableLabel?
    
    var cellDelegate : ProductCellDelegate?
    
    override func awakeFromNib() {
        captionCategory?.tapDelegate = self
    }
    
    static func heightFor(obj : ProductDetail?)->CGFloat
    {
        if (obj == nil) {
            return 202
        }
        var product = (obj?.json)!["_data"]
        
        let cons = CGSize(width: UIScreen.mainScreen().bounds.size.width-16, height: 0)
        let font = UIFont.systemFontOfSize(14)
        let desc = product["description"].string!
        var desc2 : NSString = NSString(string: desc)
        
        let size = desc2.boundingRectWithSize(cons, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil)
        
        let s = "Jaminan 100% uang kembali jika pesananmu tidak sampai".boundsWithFontSize(UIFont.systemFontOfSize(12), width: UIScreen.mainScreen().bounds.size.width-66)
        
        let arr = product["category_breadcrumbs"].array!
        var categoryString : String = ""
        if (arr.count > 0) {
            for i in 0...arr.count-1
            {
                let d = arr[i]
                let name = d["name"].string!
                categoryString += name
                if (i != arr.count-1) {
                    categoryString += " > "
                }
            }
        }
        
        let cs = categoryString.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.size.width-101)
        
        return 163+size.height+s.height+cs.height+8
    }
    
    func adapt(obj : ProductDetail?)
    {
        if (obj == nil) {
            return
        }
        var product = (obj?.json)!["_data"]
        
        captionDesc?.text = product["description"].string!
        captionDate?.text = product["time"].string!
        captionCondition?.text = product["condition"].string!
        if let region = product["seller_region"]["name"].string
        {
            captionFrom?.text = region
        } else {
            captionFrom?.text = "Unknown"
        }
        if let merk = product["brand"].string
        {
            captionMerk?.text = merk
        } else {
            captionMerk?.text = "Unknown"
        }
        captionSize?.text = " "
        
        let arr = product["category_breadcrumbs"].array!
        var categoryString : String = ""
        var param : Array<[String : AnyObject]> = []
        if (arr.count > 0) {
            for i in 0...arr.count-1
            {
                let d = arr[i]
                let name = d["name"].string!
                let p = [
                    "category_name":name,
                    "category_id":d["_id"].string!,
                    "range":NSStringFromRange(NSMakeRange(categoryString.length(), name.length())),
                    ZSWTappableLabelTappableRegionAttributeName: Int(true),
                    ZSWTappableLabelHighlightedBackgroundAttributeName : UIColor.darkGrayColor(),
                    ZSWTappableLabelHighlightedForegroundAttributeName : UIColor.whiteColor(),
                    NSForegroundColorAttributeName : Theme.PrimaryColorDark
                ]
                param.append(p)
                
                categoryString += name
                if (i != arr.count-1) {
                    categoryString += " > "
                }
            }
        }
        
        var attString : NSMutableAttributedString = NSMutableAttributedString(string: categoryString)
        for p in param
        {
            let r = NSRangeFromString(p["range"] as! String)
            attString.addAttributes(p, range: r)
        }
        
        captionCategory?.attributedText = attString
    }
    
    func tappableLabel(tappableLabel: ZSWTappableLabel!, tappedAtIndex idx: Int, withAttributes attributes: [NSObject : AnyObject]!) {
//        println(attributes)
        
        if (cellDelegate != nil) {
            let name = attributes["category_name"] as! String
            let id = attributes["category_id"] as! String
            cellDelegate?.cellTappedCategory(name, categoryID: id)
        }
        
    }
}

class ProductCellDiscussion : UITableViewCell
{
    @IBOutlet var captionMessage : UILabel?
    @IBOutlet var captionDate : UILabel?
    @IBOutlet var captionName : UILabel?
    @IBOutlet var ivCover : UIImageView?
    
    static func heightFor(obj : ProductDiscussion?)->CGFloat
    {
        if (obj == nil) {
            return 64
        }
        var json = (obj?.json)!
        
        let s = obj?.message.boundsWithFontSize(UIFont.systemFontOfSize(12), width: UIScreen.mainScreen().bounds.size.width-72)
        return 47+(s?.height)!
    }
    
    func adapt(obj : ProductDiscussion?)
    {
        if (obj == nil) {
            return
        }
        var json = (obj?.json)!
        
        captionDate?.text = json["time"].string!
        captionMessage?.text = obj?.message
        captionName?.text = json["sender_username"].string!
        ivCover?.setImageWithUrl((obj?.posterImageURL)!, placeHolderImage: nil)
    }
}
