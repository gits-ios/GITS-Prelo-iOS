//
//  AddProductViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import QuartzCore

class AddProductViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDataSource, ACEExpandableTableViewDelegate {

    @IBOutlet var tableView : UITableView?
    @IBOutlet var gridView : UICollectionView?
    @IBOutlet var sectionHeader : UIView?
    
    var s1 : CGSize = CGSizeZero
    var s2 : CGSize = CGSizeZero
    
    var sectionTitles : Array<[String : String]> = []
    var baseDatas : [NSIndexPath:BaseCartData] = [:]
    var cells : [NSIndexPath:UITableViewCell] = [:]
    var heights : [NSIndexPath:CGFloat] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        sectionHeader?.width = UIScreen.mainScreen().bounds.width
        sectionHeader?.height = UIScreen.mainScreen().bounds.width * 3 / 4
        
        s1 = CGSizeMake((UIScreen.mainScreen().bounds.width-2)/2, (sectionHeader?.height)!)
        s2 = CGSizeMake((s1.width)/2, (s1.height-2)/2)
        
        tableView?.registerNib(UINib(nibName: "AddProductHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
        
        sectionTitles.append(["title":"Detail Produk", "icon":""])
        sectionTitles.append(["title":"Ukuran", "icon":""])
        sectionTitles.append(["title":"Ongkos Kirim", "icon":""])
        sectionTitles.append(["title":"Berat", "icon":""])
        sectionTitles.append(["title":"Harga", "icon":""])
        sectionTitles.append(["title":"Share", "icon":""])
        
        baseDatas[NSIndexPath(forRow: 0, inSection: 0)] = BaseCartData.instanceWith(UIImage(named: "raisa.jpg")!, placeHolder: "", pickerPrepBlock : {picker in
            
            picker.textTitle = "Pilih Kategori"
            picker.items = ["Baju", "Celana", "Kaca Mata", "Daleman"]
            picker.tableView.reloadData()
            picker.doneLoading()
            
        })
        baseDatas[NSIndexPath(forRow: 1, inSection: 0)] = BaseCartData.instance("Nama Produk", placeHolder: "Nama Produk")
        baseDatas[NSIndexPath(forRow: 2, inSection: 0)] = BaseCartData.instance("Deskripsi", placeHolder: "Deskripsi")
        baseDatas[NSIndexPath(forRow: 3, inSection: 0)] = BaseCartData.instance("Kondisi", placeHolder: "Kondisi", value: "", pickerPrepBlock: { picker in
            
            picker.textTitle = "Pilih Kondisi"
            picker.items = ["Baru - Segel", "BNIB", "Mint", "Apa Adanya"]
            picker.tableView.reloadData()
            picker.doneLoading()
            
        })
        baseDatas[NSIndexPath(forRow: 4, inSection: 0)] = BaseCartData.instance("Merk", placeHolder: "Merk", value: "", pickerPrepBlock: { picker in
            
            picker.textTitle = "Pilih Merk"
            picker.items = ["LV", "Channel", "Dolce & Gabbana", "Proshop"]
            picker.tableView.reloadData()
            picker.doneLoading()
            
        })
        baseDatas[NSIndexPath(forRow: 1, inSection: 1)] = BaseCartData.instance("Ukuran", placeHolder: "Masukan Ukuran")
        baseDatas[NSIndexPath(forRow: 1, inSection: 3)] = BaseCartData.instance("Berat", placeHolder: "Masukan Berat")
        baseDatas[NSIndexPath(forRow: 0, inSection: 4)] = BaseCartData.instance("Harga Beli", placeHolder: "Masukan Harga")
        baseDatas[NSIndexPath(forRow: 1, inSection: 4)] = BaseCartData.instance("Harga Jual Prelo", placeHolder: "Masukan Harga")
        baseDatas[NSIndexPath(forRow: 2, inSection: 4)] = BaseCartData.instance("Komisi Prelo", placeHolder: "Komisi Prelo", value: "10%", enable: false)
        
        tableView?.dataSource = self
        tableView?.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.an_subscribeKeyboardWithAnimations({ r, t, o in
            
            if (o)
            {
                self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, r.size.height+40, 0)
            } else
            {
                self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, 40, 0)
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
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (section == 0) {
            return 1
        } else {
            return 4
        }
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let s = indexPath.section
        
        let c = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! UICollectionViewCell
        if (s == 0) {
            c.backgroundColor = UIColor.redColor()
        } else {
            c.backgroundColor = UIColor.greenColor()
        }
        
        return c
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let s = indexPath.section
        
        if (s == 0) {
            return s1
        } else {
            return s2
        }
    }
    
    // tableview
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 5
        } else if (section == 1) {
            return 2
        } else if (section == 2) {
            return 1
        } else if (section == 3) {
            return 2
        } else if (section == 5) {
            return 1
        }
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var c : UITableViewCell?
        let s = indexPath.section
        let r = indexPath.row
        
        c = cells[indexPath]
        if (c != nil) {
            return c!
        }
        
        if (s == 0) {
            if (r == 0) {
                let b = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_category")
                c = b
            } else if (r == 1 || r == 2) {
                let b = createExpandableCell(tableView, indexPath: indexPath)
                c = b
            } else {
                let b = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input_2")
                c = b
            }
        } else if (s == 1) {
            if (r == 0) {
                var g = tableView.dequeueReusableCellWithIdentifier("cell_size") as! AddProductSizeCell
                g.decorate()
                c = g
            } else if (r == 1) {
                let b = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
                c = b
            }
        } else if (s == 2) {
            c = tableView.dequeueReusableCellWithIdentifier("cell_ongkir") as? UITableViewCell
        } else if (s == 3) {
            if (r == 0) {
                c = tableView.dequeueReusableCellWithIdentifier("cell_weight") as? UITableViewCell
            } else if (r == 1) {
                let b = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
                c = b
            }
        } else if (s == 4) {
            let b = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
            c = b
        } else if (s == 5) {
            c = tableView.dequeueReusableCellWithIdentifier("cell_share") as? UITableViewCell
        }
        
        cells[indexPath] = c!
        
        return c!
    }
    
    func createExpandableCell(tableView : UITableView, indexPath : NSIndexPath) -> ACEExpandableTextCell?
    {
        var acee = tableView.dequeueReusableCellWithIdentifier("address_cell") as? CartAddressCell
        if (acee == nil) {
            acee = CartAddressCell(style: UITableViewCellStyle.Default, reuseIdentifier: "address_cell")
            acee?.selectionStyle = UITableViewCellSelectionStyle.None
            acee?.expandableTableView = tableView
            
            acee?.textView.font = UIFont.systemFontOfSize(16)
            acee?.textView.textColor = UIColor.darkGrayColor()
        }
        
        if (acee?.lastIndex != nil) {
            baseDatas[(acee?.lastIndex)!] = acee?.obtain()
        }
        
        acee?.adapt(baseDatas[indexPath]!)
        acee?.lastIndex = indexPath
        
        return acee
    }
    
    func createOrGetBaseCartCell(tableView : UITableView, indexPath : NSIndexPath, id : String) -> BaseCartCell
    {
        let b : BaseCartCell = tableView.dequeueReusableCellWithIdentifier(id) as! BaseCartCell
        
        if (b.lastIndex != nil) {
            baseDatas[b.lastIndex!] = b.obtainValue()
        }
        
        b.parent = self
        b.adapt(baseDatas[indexPath])
        b.lastIndex = indexPath
        return b
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var h = tableView.dequeueReusableHeaderFooterViewWithIdentifier("header") as! AddProductHeader
        h.width = UIScreen.mainScreen().bounds.size.width
        let d = sectionTitles[section]
        h.captionIcon.text = d["icon"]
        h.captionTitle.text = d["title"]
        return h
    }
    
    var h1 : CGFloat = 44
    var h2 : CGFloat = 44
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let s = indexPath.section
        let r = indexPath.row
        
        if (s == 0)
        {
            if (r == 0) {
                return 80
            } else if (r == 1) {
                return h1
            } else if (r == 2) {
                return h2
            } else {
                return 44
            }
        } else if (s == 1) {
            if (r == 0) {
                return 80
            } else {
                return 44
            }
        } else if (s == 2) {
            return 120
        } else if (s == 3) {
            if (r == 0)
            {
                return 96
            } else
            {
                return 44
            }
        } else if (s == 5) {
            return 332
        } else {
            return 44
        }
    }
    
    func tableView(tableView: UITableView!, updatedHeight height: CGFloat, atIndexPath indexPath: NSIndexPath!) {
        let s = indexPath.section
        let r = indexPath.row
        
        if (s == 0) {
            if (r == 1) {
                h1 = height
            }
            if (r == 2) {
                h2 = height
            }
        }
    }
    
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        baseDatas[indexPath]?.value = text
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let c = cells[indexPath]
        if ((c?.canBecomeFirstResponder())!) {
            c?.becomeFirstResponder()
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

}

class ProductCategoryCell : CartCellInput2
{
    @IBOutlet var ivImage : UIImageView!
    
    override func adapt(item: BaseCartData?) {
        super.adapt(item)
        ivImage.image = item?.image
    }
}

class AddProductSizeCell : UITableViewCell, UICollectionViewDataSource
{
    @IBOutlet var gridView : UICollectionView!
    @IBOutlet var leftPanel : UIView!
    @IBOutlet var rightPanel : UIView!
    
    var decorated : Bool = false
    
    var leftLayer : CAGradientLayer?
    var rightLayer : CAGradientLayer?
    
    func decorate()
    {
        if (decorated == false)
        {
            super.awakeFromNib()
            gridView.layer.borderColor = UIColor.lightGrayColor().CGColor
            gridView.layer.borderWidth = 1
            
            if (leftLayer != nil)
            {
                leftLayer?.removeFromSuperlayer()
            }
            
            if (rightLayer != nil)
            {
                rightLayer?.removeFromSuperlayer()
            }
            
            let x = leftPanel.frame
            leftLayer = AppToolsObjC.gradientViewWithColor([UIColor(white: 1, alpha: 1).CGColor, UIColor(white: 1, alpha: 0).CGColor], withView: leftPanel)
            let f = rightPanel.frame
            rightLayer = AppToolsObjC.gradientViewWithColor([UIColor(white: 1, alpha: 0).CGColor, UIColor(white: 1, alpha: 1).CGColor], withView: rightPanel)
            decorated = true
        }
    }
    
//    override func setNeedsLayout() {
//        super.setNeedsLayout()
//        decorated = false
//        decorate()
//    }
//    
//    override func setNeedsUpdateConstraints() {
//        super.setNeedsUpdateConstraints()
//        decorated = false
//        decorate()
//    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! UICollectionViewCell
    }
}

class AddProductShippingPaymentCell : UITableViewCell
{
    @IBOutlet var sectionShippingPayments : Array<BorderedView> = []
    @IBOutlet var btnShippingPayments : Array<UIButton> = []
    
    var setted = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if (setted == false)
        {
            for b in btnShippingPayments
            {
                b.addTarget(self, action: "setShippingPayment:", forControlEvents: UIControlEvents.TouchUpInside)
            }
            setted = true
        }
    }
    
    @IBAction func setShippingPayment(sender : UIButton)
    {
        for b in sectionShippingPayments
        {
            b.borderColor = UIColor.darkGrayColor()
            for l in b.subviews
            {
                if (l.isKindOfClass(UILabel.classForCoder()))
                {
                    let x = l as! UILabel
                    x.textColor = UIColor.darkGrayColor()
                }
            }
        }
        
        var c = sender.superview as! BorderedView
        for l in c.subviews
        {
            if (l.isKindOfClass(UILabel.classForCoder()))
            {
                let x = l as! UILabel
                x.textColor = Theme.DarkPurple
            }
        }
        c.borderColor = Theme.DarkPurple
    }
}

class AddProductSizeFlow : UICollectionViewFlowLayout
{
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.itemSize = CGSizeMake(40, 40)
        self.minimumInteritemSpacing = 10.0;
        self.minimumLineSpacing = 10.0;
        self.scrollDirection = UICollectionViewScrollDirection.Horizontal;
        self.sectionInset = UIEdgeInsetsMake(8, 2, 8, 2);
        let m = (UIScreen.mainScreen().bounds.size.width - 16 - 40)/2
        self.collectionView?.contentInset = UIEdgeInsetsMake(0, m, 0, m)
    }
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var offsetAdjustment = MAXFLOAT
        let m = (UIScreen.mainScreen().bounds.size.width - 16 - 40)/2
        let horizontalOffset = proposedContentOffset.x + m
        
        let targetRect = CGRectMake(proposedContentOffset.x, 0, (self.collectionView?.bounds.size.width)!, (self.collectionView?.bounds.size.height)!)
        
        let array:Array<UICollectionViewLayoutAttributes> = super.layoutAttributesForElementsInRect(targetRect) as! Array<UICollectionViewLayoutAttributes>
        
        for layoutAttributes in array
        {
            let itemOffset = layoutAttributes.frame.origin.x
            if (abs(itemOffset - horizontalOffset) < abs(offsetAdjustment)) {
                offsetAdjustment = Float(itemOffset) - Float(horizontalOffset)
            }
        }
        
        return CGPointMake(proposedContentOffset.x + CGFloat(offsetAdjustment), proposedContentOffset.y)
    }
}

class AddProductHeader : UITableViewHeaderFooterView
{
    @IBOutlet var captionIcon: UILabel!
    @IBOutlet var captionTitle: UILabel!
    
}
