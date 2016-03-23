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
    func cellTappedBrand(brandId : String, brandName : String)
}

class ProductDetailViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, ProductCellDelegate, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, UserRelatedDelegate
{
    
    var product : Product?
    var detail : ProductDetail?
    
    var alreadyInCart : Bool = false
    
    @IBOutlet var tableView : UITableView?
    @IBOutlet var btnAddDiscussion : UIButton?
    @IBOutlet var btnBuy : UIButton!
    @IBOutlet var btnTawar : BorderedButton!
    @IBOutlet var btnActivate : UIButton!
    @IBOutlet var btnDelete : UIButton!
    @IBOutlet var btnEdit : UIButton!
    @IBOutlet var vwCoachmark: UIView!
    
    @IBOutlet weak var konfirmasiBayarBtnSet: UIView!
    @IBOutlet weak var tpDetailBtnSet: UIView!
    
    var cellTitle : ProductCellTitle?
    var cellSeller : ProductCellSeller?
    var cellDesc : ProductCellDescription?
    
    var activated = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let i = UIImage(named: "ic_chat")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        self.btnAddDiscussion?.addTarget(self, action: "segAddComment:", forControlEvents: UIControlEvents.TouchUpInside)
        
        btnDelete.addTarget(self, action: "deleteProduct", forControlEvents: .TouchUpInside)
        
        btnBuy.hidden = true
        btnTawar.hidden = true
        
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
            getDetail(false)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.title = product?.name
        
        if let d = self.detail
        {
            if (CartProduct.isExist((detail?.productID)!, email : User.EmailOrEmptyString)) {
                alreadyInCart = true
            } else {
                alreadyInCart = false
            }
        }
        
        if (self.navigationController != nil) {
            if ((self.navigationController?.navigationBarHidden)! == true)
            {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }
        }
        
        if (UIApplication.sharedApplication().statusBarHidden)
        {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
        }
        
        let p = [
            "Product" : ((product != nil) ? (product!.name) : ""),
            "Product ID" : ((product != nil) ? (product!.id) : ""),
            "Category 1" : ((detail != nil && detail?.categoryBreadcrumbs.count > 1) ? (detail!.categoryBreadcrumbs[1]["name"].string!) : ""),
            "Category 2" : ((detail != nil && detail?.categoryBreadcrumbs.count > 2) ? (detail!.categoryBreadcrumbs[2]["name"].string!) : ""),
            "Category 3" : ((detail != nil && detail?.categoryBreadcrumbs.count > 3) ? (detail!.categoryBreadcrumbs[3]["name"].string!) : ""),
            "Seller" : ((detail != nil) ? (detail!.theirName) : "")
        ]
        if (detail != nil && detail!.isMyProduct == true) {
            // Mixpanel
            Mixpanel.trackPageVisit(PageName.ProductDetailMine, otherParam: p)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.ProductDetailMine)
        } else {
            // Mixpanel
            Mixpanel.trackPageVisit(PageName.ProductDetail, otherParam: p)
            
            // Google Analytics
            GAI.trackPageVisit(PageName.ProductDetail)
        }
    }
    
    var processingActivation = false
    @IBAction func setProductActive()
    {
        if (processingActivation)
        {
            return
        }
        processingActivation = true
        btnActivate.setTitle("LOADING..", forState: .Disabled)
        btnActivate.enabled = false
        
        if (activated)
        {
            request(Products.Deactivate(productID: (detail?.productID)!)).responseJSON { req, resp, res, err in
                self.processingActivation = false
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Deaktivasi Produk"))
                {
                    self.activated = false
                    self.adjustButtonActivation()
                } else {
                    
                }
            }
        } else
        {
            request(Products.Activate(productID: (detail?.productID)!)).responseJSON { req, resp, res, err in
                self.processingActivation = false
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Aktivasi Produk"))
                {
                    self.activated = true
                    self.adjustButtonActivation()
                } else {
                    
                }
            }
        }
    }
    
    func adjustButtonActivation()
    {
        btnActivate.enabled = true
        if (activated)
        {
            btnActivate.setTitle(" DEACTIVATE", forState: .Normal)
        } else
        {
            btnActivate.setTitle(" ACTIVATE", forState: .Normal)
        }
    }
    
    var deleting = false
    func deleteProduct()
    {
        if (deleting)
        {
            return
        }
        if (UIDevice.currentDevice().systemVersion.floatValue >= 8)
        {
            askDeleteOS8()
        } else
        {
            askDeleteOS7()
        }
    }
    
    func askDeleteOS8()
    {
        let a = UIAlertController(title: "Hapus", message: "Hapus Produk ?", preferredStyle: .Alert)
        a.addAction(UIAlertAction(title: "Ya", style: .Default, handler: {act in
            self.confirmDeleteProduct()
        }))
        a.addAction(UIAlertAction(title: "Tidak", style: .Cancel, handler: {act in }))
        self.presentViewController(a, animated: true, completion: nil)
    }
    
    func askDeleteOS7()
    {
        let a = UIAlertView()
        a.title = "Hapus"
        a.message = "Hapus Produk ?"
        a.addButtonWithTitle("Ya")
        a.addButtonWithTitle("Tidak")
        a.delegate = self
        a.show()
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == 0)
        {
            println("DELETE")
            self.confirmDeleteProduct()
        } else
        {
            println("NO DELETE")
        }
    }
    
    func confirmDeleteProduct()
    {
        deleting = true
        self.btnDelete.setTitle("LOADING..", forState: .Disabled)
        self.btnDelete.enabled = false
        request(Products.Delete(productID: (detail?.productID)!)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Hapus Produk"))
            {
                self.navigationController?.popViewControllerAnimated(true)
            } else {
                self.deleting = false
                self.btnDelete.enabled = true
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
            if (MFMailComposeViewController.canSendMail()) {
                m.setToRecipients(["contact@prelo.id"])
                m.setSubject("Product Report [" + (detail?.productID)! + "]")
                m.mailComposeDelegate = self
                self.presentViewController(m, animated: true, completion: nil)
            } else {
                Constant.showDialog("No Active Email", message: "Untuk dapat mengirim Report, aktifkan akun email kamu di menu Settings > Mail, Contacts, Calendars")
            }
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func getDetail(forEdit : Bool)
    {
        request(APIProduct.Detail(productId: (product?.json)!["_id"].string!, forEdit: (forEdit ? 1 : 0)))
            .responseJSON { req, resp, res, err in
                if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Detail Produk"))
                {
                    self.detail = ProductDetail.instance(JSON(res!))
                    self.activated = (self.detail?.isActive)!
                    self.adjustButtonActivation()
                    self.adjustButtonIfBought()
                    println(self.detail?.json)
                    self.tableView?.dataSource = self
                    self.tableView?.delegate = self
                    self.tableView?.hidden = false
                    self.tableView?.reloadData()
                    self.setupView()
                } else {
                    
                }
        }
    }
    
    func adjustButtonIfBought()
    {
        if (self.detail?.status == 4) {
            self.btnTawar.borderColor = Theme.GrayLight
            self.btnTawar.titleLabel?.textColor = Theme.GrayLight
            self.btnTawar.userInteractionEnabled = false
            self.btnBuy.setBackgroundImage(nil, forState: .Normal)
            self.btnBuy.backgroundColor = nil
            self.btnBuy.setTitleColor(Theme.GrayLight)
            self.btnBuy.layer.borderColor = Theme.GrayLight.CGColor
            self.btnBuy.layer.borderWidth = 1
            self.btnBuy.layer.cornerRadius = 1
            self.btnBuy.layer.masksToBounds = true
            self.btnBuy.userInteractionEnabled = false
            if (self.detail?.boughtByMe == true) {
                self.btnTawar.hidden = true
                self.btnBuy.hidden = true
                if (self.detail?.transactionProgress == 1 || self.detail?.transactionProgress == 2) {
                    // Tampilkan button konfirmasi bayar
                    self.konfirmasiBayarBtnSet.hidden = false
                } else if (self.detail?.transactionProgress > 2) {
                    // Tampilkan button transaction product detail
                    self.tpDetailBtnSet.hidden = false
                }
            }
        }
    }
    
    func setupView()
    {
        if (self.detail == nil)
        {
            return
        }
        let p = ProductDetailCover.instance((detail?.displayPicturers)!, status: (detail?.status)!)
        p?.parent = self
        p?.largeImageURLS = (detail?.originalPicturers)!
        if let labels = detail?.imageLabels
        {
            p?.labels = labels
        }
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
        
        if let arr = detail?.json["_data"]["category_breadcrumbs"].array
        {
            if let id = detail?.productID
            {
                if let catName = arr.last?["name"].string
                {
                    if let price = detail?.json["_data"]["price"].int
                    {
                        ACTRemarketingReporter.reportWithConversionID("953474992", customParameters: ["dynx_itemid":id, "dynx_pagetype":catName, "dynx_totalvalue":price])
                    }
                }
            }
        }
        
        if ((detail?.isMyProduct)! == true)
        {
//            if let b : UIButton = self.view.viewWithTag(12) as? UIButton
//            {
//                b.hidden = false
//                b.titleLabel?.font = AppFont.PreloAwesome.getFont(15)
//                b.setTitle(" EDIT", forState: UIControlState.Normal)
//            }
            self.btnBuy.hidden = true
            self.btnTawar.hidden = true
            btnEdit.hidden = false
            btnActivate.hidden = false
            btnDelete.hidden = false
            btnDelete.superview?.hidden = false
        } else
        {
            btnBuy.hidden = false
            btnTawar.hidden = false
        }
        
        self.btnTawar.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
        self.btnTawar.addTarget(self, action: "tawar:", forControlEvents: UIControlEvents.TouchUpInside)
        
        let coachmarkDone : Bool? = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKey.CoachmarkProductDetailDone) as! Bool?
        if (coachmarkDone != true) {
            NSUserDefaults.setObjectAndSync(true, forKey: UserDefaultsKey.CoachmarkProductDetailDone)
            vwCoachmark.backgroundColor = UIColor.colorWithColor(UIColor.blackColor(), alpha: 0.7)
            vwCoachmark.hidden = false
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
                cellTitle?.product = self.product
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
            return ProductCellDiscussion.heightFor(detail?.discussions?.objectAtCircleIndex(indexPath.row-3))
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == 1)
        {
            let d = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
            d.storeMode = true
            if let name = detail?.json["_data"]["seller"]["username"].string
            {
                d.storeName = name
            }
            
            if let name = detail?.json["_data"]["seller"]["_id"].string
            {
                d.storeId = name
            }
            
            if let name = detail?.json["_data"]["seller"]["pict"].string
            {
                d.storePictPath = name
            }
            
            self.navigationController?.pushViewController(d, animated: true)
        }
    }
    
    func cellTappedCategory(categoryName: String, categoryID: String) {
        let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        l.standalone = true
        l.standaloneCategoryName = categoryName
        l.standaloneCategoryID = categoryID
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    func cellTappedBrand(brandId: String, brandName: String) {
        let l = self.storyboard?.instantiateViewControllerWithIdentifier("productList") as! ListItemViewController
        l.searchMode = true
        l.searchBrand = true
        l.searchBrandId = brandId
        l.searchKey = brandName
        self.navigationController?.pushViewController(l, animated: true)
    }
    
    @IBAction func addToCart(sender: UIButton) {
        if ((detail?.isMyProduct)! == true)
        {
            let a = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
            a.editMode = true
            a.editDoneBlock = {
                self.tableView?.hidden = true
                self.getDetail(true)
            }
            a.editProduct = self.detail
            self.navigationController?.pushViewController(a, animated: true)
            return
        }
        
        if (alreadyInCart) {
            self.performSegueWithIdentifier("segCart", sender: nil)
            return
        }
        
        if (CartProduct.newOne((detail?.productID)!, email : User.EmailOrEmptyString, name : (detail?.name)!) == nil) {
            Constant.showDialog("Failed", message: "Gagal Menyimpan")
        } else {
            setupView()
            self.performSegueWithIdentifier("segCart", sender: nil)
        }
    }
    
    @IBAction func tawar(sender : UIView)
    {
        if let d = self.detail
        {
            let t = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdTawar) as! TawarViewController
            t.tawarItem = d
            t.loadInboxFirst = true
            t.prodId = d.productID
            self.navigationController?.pushViewController(t, animated: true)
        }
    }
    
    var loginComment = false
    @IBAction func segAddComment(sender : UIView?)
    {
        if (User.IsLoggedIn == false)
        {
            loginComment = true
            LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
        } else
        {
            self.performSegueWithIdentifier("segAddComment", sender: nil)
        }
    }
    
    func userCancelLogin() {
        
    }
    
    func userLoggedIn() {
        if (loginComment)
        {
            self.performSegueWithIdentifier("segAddComment", sender: nil)
        }
    }
    
    func userLoggedOut() {
        
    }
    
    // MARK: - Coachmark
    
    @IBAction func coachmarkTapped(sender: AnyObject) {
        self.vwCoachmark.hidden = true
    }
    
    // MARK: - If product is bought
    
    @IBAction func toPaymentConfirm(sender: AnyObject) {
        let paymentConfirmationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil).first as! PaymentConfirmationViewController
        self.navigationController?.pushViewController(paymentConfirmationVC, animated: true)
    }
    
    @IBAction func toTransactionProductDetail(sender: AnyObject) {
        let myPurchaseVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNameMyPurchase, owner: nil, options: nil).first as! MyPurchaseViewController
        self.navigationController?.pushViewController(myPurchaseVC, animated: true)
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
    @IBOutlet var sectionBrandReview : UIView?
    
    @IBOutlet var btnShare : UIButton?
    
    @IBOutlet var conWidthOngkir : NSLayoutConstraint!
    @IBOutlet var conMarginOngkir : NSLayoutConstraint!
    
    var parent : UIViewController?
    
    var product : Product?
    var detail : ProductDetail?
    
    static func heightFor(obj : ProductDetail?)->CGFloat
    {
        if (obj == nil) {
            return 110
        }
        var product = (obj?.json)!["_data"]
        
        let name = product["name"].string!
        let s = name.boundsWithFontSize(UIFont.boldSystemFontOfSize(16.5), width: UIScreen.mainScreen().bounds.size.width-16.0)
        
        var reviewHeight : CGFloat = 32.0
        if let brand_under_review = product["brand_under_review"].bool
        {
            if (brand_under_review == false)
            {
                reviewHeight = 0.0
            }
        }
        
        return CGFloat(90.0) + s.height + reviewHeight
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
        } else
        {
            self.parent?.performSegueWithIdentifier("segAddComment", sender: nil)
        }
    }
    
    func userCancelLogin() {
        
    }
    
    func userLoggedOut() {
        
    }
    
    func comment()
    {
        if (User.IsLoggedIn == false)
        {
            LoginViewController.Show(self.parent!, userRelatedDelegate: self, animated: true)
        } else
        {
            self.parent?.performSegueWithIdentifier("segAddComment", sender: nil)
        }
    }
    
    var isLoved = false
    var loving = false
    var loveCount = 0
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
        // Mixpanel
        let pt = [
            "Product Name" : ((product != nil) ? (product!.name) : ""),
            "Category 1" : ((detail != nil && detail?.categoryBreadcrumbs.count > 1) ? (detail!.categoryBreadcrumbs[1]["name"].string!) : ""),
            "Category 2" : ((detail != nil && detail?.categoryBreadcrumbs.count > 2) ? (detail!.categoryBreadcrumbs[2]["name"].string!) : ""),
            "Category 3" : ((detail != nil && detail?.categoryBreadcrumbs.count > 3) ? (detail!.categoryBreadcrumbs[3]["name"].string!) : ""),
            "Seller Name" : ((detail != nil) ? (detail!.theirName) : "")
        ]
        Mixpanel.trackEvent(MixpanelEvent.ToggledLikeProduct, properties: pt)
        
        if (isLoved)
        {
            callApiUnlove()
            return
        }
        isLoved = true
        loveCount+=1
        setupLoveView()
        request(APIProduct.Love(productID: (detail?.productID)!)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Love Product"))
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
        loveCount-=1
        setupLoveView()
        request(APIProduct.Unlove(productID: (detail?.productID)!)).responseJSON { req, resp, res, err in
            if (APIPrelo.validate(true, req: req, resp: resp, res: res, err: err, reqAlias: "Unlove Product"))
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
        
        var product = (obj?.json)!["_data"]
        if (detail == nil)
        {
            detail = obj
            isLoved = (product["love"].bool)!
            loveCount = product["num_lovelist"].int!
        }
        
        if let free_ongkir = product["free_ongkir"].int
        {
            if (free_ongkir == 0)
            {
                conWidthOngkir.constant = 0
//                conMarginOngkir.constant = 0
            }
        } else
        {
            conWidthOngkir.constant = 0
//            conMarginOngkir.constant = 0
        }
        
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
        
        if (isLoved)
        {
            setupLoveView()
        }
        captionCountLove?.text = String(loveCount)
        captionCountComment?.text = obj?.discussionCountText
        
        if let brand_under_review = product["brand_under_review"].bool
        {
            if (brand_under_review == false)
            {
                sectionBrandReview?.hidden = true
            }
        }
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
        item.permalink  = (detail?.permalink)
        item.price = (detail?.price)
        
        PreloShareController.Share(item, inView: (parent?.navigationController?.view)!, detail : self.detail)
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
        
        captionSellerName?.text = product["seller"]["username"].stringValue
        let average_star = product["seller"]["average_star"].intValue
        var stars = ""
        for x in 1...5
        {
            if (x <= average_star)
            {
                stars = stars+""
            } else
            {
                stars = stars+""
            }
        }
        captionSellerRating?.text = stars
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
    @IBOutlet var captionSize : UILabel?
    @IBOutlet var captionCondition : UILabel?
    @IBOutlet var captionFrom : UILabel?
    @IBOutlet var captionConditionDesc : UILabel?
    @IBOutlet var captionAlasanJual : UILabel?
    
    @IBOutlet var captionMerk : ZSWTappableLabel?
    @IBOutlet var captionCategory : ZSWTappableLabel?
    
    var cellDelegate : ProductCellDelegate?
    
    override func awakeFromNib() {
        captionCategory?.tapDelegate = self
        captionMerk?.tapDelegate = self
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
        
        var desc3 = ""
        if let ss = obj?.specialStory
        {
            if (ss != "")
            {
                desc3 = "\"" + ss + "\"\n\n"
            }
        }
        
        desc2 = desc3 + (desc2 as String)
        
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
        
        var cs2 = (obj?.defectDescription)!
        if (cs2 == "")
        {
            cs2 = "-"
        }
        let cs2Size = cs2.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.size.width-136)
        
//        var al = (obj?.sellReason)!
        var sellReason = (obj?.sellReason)!
        if (sellReason == "")
        {
            sellReason = "-"
        }
        let alSize = sellReason.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.size.width-100)
        
        return 163+size.height+s.height+cs.height+8+8+cs2Size.height+8+alSize.height
    }
    
    func adapt(obj : ProductDetail?)
    {
        if (obj == nil) {
            return
        }
        var product = (obj?.json)!["_data"]
        
        var desc = ""
        if let ss = obj?.specialStory
        {
            if (ss != "")
            {
                desc = "\"" + ss + "\"\n\n"
            }
        }
        
        captionDesc?.text = desc + product["description"].string!
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
            let p = [
                "brand_id":product["brand_id"].stringValue,
                "brand":product["brand"].stringValue,
                "range":NSStringFromRange(NSMakeRange(0, merk.length())),
                ZSWTappableLabelTappableRegionAttributeName: Int(true),
                ZSWTappableLabelHighlightedBackgroundAttributeName : UIColor.darkGrayColor(),
                ZSWTappableLabelHighlightedForegroundAttributeName : UIColor.whiteColor(),
                NSForegroundColorAttributeName : Theme.PrimaryColorDark
            ]
            captionMerk?.attributedText = NSAttributedString(string: merk, attributes: p)
        } else {
            captionMerk?.text = "Unknown"
        }
        
        let regionid = product["seller"]["region_id"].stringValue
        if let name = CDRegion.getRegionNameWithID(regionid)
        {
            captionFrom?.text = name
        }
        
        var s = obj!.size
        if (s == "")
        {
            s = "-"
        }
        captionSize?.text = s;
        
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
        
        var sellReason = (obj?.sellReason)!
        if (sellReason == "")
        {
            sellReason = "-"
        }
        
        captionAlasanJual?.numberOfLines = 0
        captionAlasanJual?.text = sellReason
        
        var defect = (obj?.defectDescription)!
        if (defect == "")
        {
            defect = "-"
        }
        captionConditionDesc?.text = defect
    }
    
    func tappableLabel(tappableLabel: ZSWTappableLabel!, tappedAtIndex idx: Int, withAttributes attributes: [NSObject : AnyObject]!) {
        //println(attributes)
        
        if (cellDelegate != nil) {
            if let brandName = attributes["brand"] as? String { // Brand clicked
                let brandId = attributes["brand_id"] as! String
                cellDelegate!.cellTappedBrand(brandId, brandName: brandName)
            } else {
                let name = attributes["category_name"] as! String
                let id = attributes["category_id"] as! String
                cellDelegate!.cellTappedCategory(name, categoryID: id)
            }
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
        
        let s = obj?.message.boundsWithFontSize(UIFont.systemFontOfSize(14), width: UIScreen.mainScreen().bounds.size.width-72)
        let h = 47+(s?.height)!
        return h
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
