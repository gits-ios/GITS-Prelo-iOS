//
//  CartViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/3/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import Crashlytics

class CartViewController: BaseViewController, ACEExpandableTableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITextFieldDelegate, CartItemCellDelegate, UserRelatedDelegate {

    @IBOutlet var tableView : UITableView!
    @IBOutlet var txtVoucher : UITextField!
    
    @IBOutlet var btnSend : UIButton!
    
    @IBOutlet var sectionsPaymentOption : Array<BorderedView> = []
    
    @IBOutlet var consOffsetPaymentDesc : NSLayoutConstraint?
    @IBOutlet var sectionPaymentDesc: UIView!
    
    let titleNama = "Nama"
    let titleTelepon = "Telepon"
    let titleAlamat = "Mis: Jl. Tamansari III no. 1"
    let titleProvinsi = "Provinsi"
    let titleKota = "Kab / Kota"
    let titlePostal = "Kode Pos"
    
    var address = ""
    var addressHeight = 44
    
    var totalOngkir = 0
    
    var cells : [NSIndexPath : BaseCartData] = [:]
    var cellViews : [NSIndexPath : UITableViewCell] = [:]
    var voucher : String = ""
    
    var products : [CartProduct] = []
    var arrayItem : [JSON] = []
    
    var selectedPayment = "Bank Transfer"
    var availablePayments = ["Bank Transfer", "Credit Card", "Prelo Balance"]
    
    var selectedProvinsiID = ""
    var selectedKotaID = ""
    
    var user = CDUser.getOne()
    
    var checkoutResult : JSON?
    
    @IBOutlet weak var lblPaymentReminder: UILabel!
    @IBOutlet weak var consHeightPaymentReminder: NSLayoutConstraint!
    
    @IBOutlet var captionNoItem: UILabel!
    @IBOutlet var loadingCart: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = PageName.Checkout
        
        // API Migrasi
        request(APITransactionCheck.CheckUnpaidTransaction).responseJSON {resp in
            if (APIPrelo.validate(false, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Checkout - Unpaid Transaction")) {
                let json = JSON(resp.result.value!)
                let data = json["_data"]
                if (data["user_has_unpaid_transaction"].boolValue == true) {
                    let nUnpaid = data["n_transaction_unpaid"].intValue
                    self.lblPaymentReminder.text = "Kamu memiliki \(nUnpaid) transaksi yg belum dibayar"
                    self.consHeightPaymentReminder.constant = 40
                }
            }
        }
        
        products = CartProduct.getAll(User.EmailOrEmptyString)
        
        if (products.count == 0)
        {
            tableView.hidden = true
            loadingCart.hidden = true
            captionNoItem.hidden = false
        } else
        {
            //self.navigationItem.rightBarButtonItem = self.confirmButton.toBarButton()
            let c = CDUser.getOne()
            
            if (c == nil) {
                tableView.hidden = true
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            } else {
                createCells()
                synch()
            }
        }
        
        // Do any additional setup after loading the view.
    }
    
    func createCells()
    {
        var phone = ""
        var address = ""
        var fullname = ""
        var postalcode = ""
        
        if let profile = user?.profiles
        {
            if let x = profile.phone
            {
                phone = x
            }
            
            if let x = profile.address
            {
                address = x
            }
            
            if let x = profile.postalCode
            {
                postalcode = x
            }
        }
        
        if let x = user?.fullname
        {
            fullname = x
        }
        
        let c = BaseCartData.instance(titlePostal, placeHolder: "Kode Pos", value : postalcode)
        c.keyboardType = UIKeyboardType.NumberPad
        
        var pID = ""
        var rID = ""
        
        if let u = CDUser.getOne()
        {
            pID = u.profiles.provinceID
            rID = u.profiles.regionID
            
            if let i = CDProvince.getProvinceNameWithID(pID)
            {
                selectedProvinsiID = pID
                pID = i
            } else
            {
                pID = ""
            }
            
            if let i = CDRegion.getRegionNameWithID(rID)
            {
                selectedKotaID = rID
                rID = i
            } else
            {
                rID = ""
            }
        }
        
        self.cells = [
            NSIndexPath(forRow: 0, inSection: 1):BaseCartData.instance(titleNama, placeHolder: "Nama Lengkap Kamu", value : fullname),
            NSIndexPath(forRow: 1, inSection: 1):BaseCartData.instance(titleTelepon, placeHolder: "Nomor Telepon Kamu", value : phone),
            NSIndexPath(forRow: 0, inSection: 2):BaseCartData.instance(titleAlamat, placeHolder: "Alamat Lengkap Kamu", value : address),
            NSIndexPath(forRow: 1, inSection: 2):BaseCartData.instance(titleProvinsi, placeHolder: nil, value: pID, pickerPrepBlock: { picker in
                
                picker.items = CDProvince.getProvincePickerItems()
                picker.textTitle = "Pilih Provinsi"
                picker.doneLoading()
                
                // on select block
                picker.selectBlock = { string in
                    self.selectedProvinsiID = PickerViewController.RevealHiddenString(string)
                    let user = CDUser.getOne()!
                    user.profiles.provinceID = self.selectedProvinsiID
                }
            }),
            NSIndexPath(forRow: 2, inSection: 2):BaseCartData.instance(titleKota, placeHolder: nil, value: rID, pickerPrepBlock: { picker in
                
                picker.items = CDRegion.getRegionPickerItems(self.selectedProvinsiID)
                picker.textTitle = "Pilih Kota/Kabupaten"
                picker.doneLoading()
                
                picker.selectBlock = { string in
                    self.selectedKotaID = PickerViewController.RevealHiddenString(string)
                    let user = CDUser.getOne()!
                    user.profiles.regionID = self.selectedKotaID
                    self.synch()
                }
                
            }),
            NSIndexPath(forRow: 3, inSection: 2):c
        ]
    }
    
    func adjustTotal()
    {
        totalOngkir = 0
        for i in 0...products.count-1
        {
            let cp = products[i]
            
            let json = arrayItem[i]
            if let free = json["free_ongkir"].bool
            {
                if (free)
                {
                    continue
                }
            }
            
            if let arr = json["shipping_packages"].array
            {
                if (arr.count > 0)
                {
                    var sh = arr[0]
                    if (cp.packageId != "")
                    {
                        for x in 0...arr.count-1
                        {
                            let shipping = arr[x]
                            if let id = shipping["_id"].string
                            {
                                if (id == cp.packageId)
                                {
                                    sh = shipping
                                }
                            }
                        }
                    }
                    if let price = sh["price"].int
                    {
                        totalOngkir += price
                    }
                }
            }
            
        }
        
        let b = cells[NSIndexPath(forRow: products.count + (self.bonusAvailable == true ? 1 : 0), inSection: 0)]
        if let total = self.currentCart?["_data"]["total_price"].int, let d = b
        {
            var p = totalOngkir + total - self.bonusValue
            if (p < 0)
            {
                p = 0
            }
            d.value = p.asPrice
            
            if let c = cellViews[NSIndexPath(forRow: products.count, inSection: 0)] as? CartCellInput
            {
                c.txtField.text = d.value
            }
        }
        
        self.tableView.reloadData()
    }
    
    var bonusValue : Int = 0
    var currentCart : JSON?
    var bonusAvailable = false
    func synch()
    {
        tableView.hidden = true
        
        cellViews = [:]
        
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let p = AppToolsObjC.jsonStringFrom(c)
        
        print(p)
        
        var pID = ""
        var rID = ""
        if let u = CDUser.getOne()
        {
            pID = u.profiles.provinceID
            rID = u.profiles.regionID
        }
        
        let a = "{\"address\": \"alamat\", \"province_id\": \"" + pID + "\", \"region_id\": \"" + rID + "\", \"postal_code\": \"\"}"
        
        // API Migrasi
        request(APICart.Refresh(cart: p, address: a, voucher: voucher)).responseJSON {resp in
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Keranjang Belanja")) {
                let json = JSON(resp.result.value!)
                self.currentCart = json
                
                self.arrayItem = json["_data"]["cart_details"].array!
                print(self.arrayItem)
                
                if let bonus = json["_data"]["bonus_available"].int
                {
                    if (bonus != 0)
                    {
                        self.bonusValue = bonus
                        self.bonusAvailable = true
                        let b2 = BaseCartData.instance("Prelo Bonus", placeHolder: nil, enable : false)
                        if (json["_data"]["bonus_available"].int?.asPrice != nil)
                        {
                            var totalOngkir = 0
                            if (self.products.count > 0) {
                                for i in 0...self.products.count-1
                                {
                                    let cp = self.products[i]
                                    print("Cart product : \(cp.toDictionary)")
                                    
                                    let json = self.arrayItem[i]
                                    if let free = json["free_ongkir"].bool
                                    {
                                        if (free)
                                        {
                                            continue
                                        }
                                    }
                                    
                                    if let arr = json["shipping_packages"].array
                                    {
                                        if (arr.count > 0)
                                        {
                                            var sh = arr[0]
                                            if (cp.packageId != "")
                                            {
                                                for x in 0...arr.count-1
                                                {
                                                    let shipping = arr[x]
                                                    if let id = shipping["_id"].string
                                                    {
                                                        if (id == cp.packageId)
                                                        {
                                                            sh = shipping
                                                        }
                                                    }
                                                }
                                            }
                                            if let price = sh["price"].int
                                            {
                                                totalOngkir += price
                                            }
                                        }
                                    }
                                }
                            }
                            
                            let preloBonus = json["_data"]["bonus_available"].intValue
                            let totalPrice = json["_data"]["total_price"].intValue
                            
                            b2.value = (preloBonus < totalPrice+totalOngkir) ? ("-" + preloBonus.asPrice) : ("-" + (totalPrice + totalOngkir).asPrice)
                        }
                        b2.enable = false
                        let i2 = NSIndexPath(forRow: self.products.count, inSection: 0)
                        self.cells[i2] = b2
                        
                    } else {
                        if let modalText = json["_data"]["modal_verify_text"].string {
                            Constant.showDialog("Perhatian", message: modalText)
                        }
                    }
                }
                
                let i = NSIndexPath(forRow: self.products.count + (self.bonusAvailable == true ? 1 : 0), inSection: 0)
                let b = BaseCartData.instance("Total", placeHolder: nil, enable : false)
                if let price = json["_data"]["total_price"].int?.asPrice
                {
                    b.value = price
                }
                self.cells[i] = b
                
                self.tableView.dataSource = self
                self.tableView.delegate = self
                self.tableView.reloadData()
                self.tableView.hidden = false
                if (self.shouldBack == true)
                {
                    self.navigationController?.popViewControllerAnimated(true)
                } else if (self.products.count > 0)
                {
                    self.adjustTotal()
                }
            }
        }
        
    }
    
    @IBAction override func confirm()
    {
        for k in cellViews.keys
        {
            let c = cellViews[k]!
            let same = c.isKindOfClass(BaseCartCell.classForCoder())
            if (same == true) {
                let b = c as! BaseCartCell
                cells[b.lastIndex!] = b.obtainValue()
            }
        }
        
        var name = ""
        var phone = ""
        var postal = ""
        let email = (CDUser.getOne()?.email)!
        for i in cells.keys
        {
            let b = cells[i]
            if (b?.value == nil || b?.value == "") {
                Constant.showDialog("Warning", message: (b?.title)! + " still empty !")
                return
            }
            
            if (b?.title == titleNama)
            {
                name = (b?.value)!
            }
            
            if (b?.title == titleTelepon) {
                phone = (b?.value)!
            }
            
            if (b?.title == titleAlamat) {
                address = (b?.value)!
            }
            
            if (b?.title == titlePostal) {
                postal = (b?.value)!
            }
            
            print((b?.title)! + " : " + (b?.value)!)
        }
        
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let p = AppToolsObjC.jsonStringFrom(c)
        
        let user = CDUser.getOne()
        user?.profiles.address = address
        user?.profiles.postalCode = postal
        UIApplication.appDelegate.saveContext()
        
        let d = ["address":address, "province_id":selectedProvinsiID, "region_id":selectedKotaID, "postal_code":postal, "recipient_name":name, "recipient_phone":phone, "email":email]
        let a = AppToolsObjC.jsonStringFrom(d)
        
        if (p == "[]" || p == "")
        {
            Constant.showDialog("Warning", message: "Tidak ada barang")
            return
        }
        
        self.btnSend.enabled = false
        // API Migrasi
        request(APICart.Checkout(cart: p, address: a, voucher: voucher, payment: selectedPayment)).responseJSON {resp in
//            print(res)
            self.btnSend.enabled = true
            if (APIPrelo.validate(true, req: resp.request!, resp: resp.response, res: resp.result.value, err: resp.result.error, reqAlias: "Checkout")) {
                var json = JSON(resp.result.value!)
                print(json)
                if let error = json["_message"].string
                {
                    Constant.showDialog("Warning", message: error)
                } else {
//                    print(res)
                    let json = JSON(resp.result.value!)
                    self.checkoutResult = json["_data"]
                    
                    if (json["_data"]["_have_error"].intValue == 1)
                    {
                        let m = json["_data"]["_message"].stringValue
                        UIAlertView.SimpleShow("Perhatian", message: m)
                        return
                    }
                    
//                    let c = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdCartConfirm) as! CarConfirmViewController
                    
                    let o = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdOrderConfirm) as! OrderConfirmViewController
                    
                    o.orderID = (self.checkoutResult?["order_id"].string)!
                    o.total = (self.checkoutResult?["total_price"].int)!
                    o.transactionId = (self.checkoutResult?["transaction_id"].string)!
                    o.overBack = true
                    
                    var imgs : [NSURL] = []
                    
                    for i in 0...self.arrayItem.count-1
                    {
                        let json = self.arrayItem[i]
                        if let raw : Array<AnyObject> = json["display_picts"].arrayObject
                        {
                            var ori : Array<String> = []
                            for o in raw
                            {
                                if let s = o as? String
                                {
                                    ori.append(s)
                                }
                            }
                            
                            if (ori.count > 0)
                            {
                                if let u = NSURL(string: ori.first!)
                                {
                                    imgs.append(u)
                                }
                            }
                        }
                    }
                    
                    o.images = imgs
                    
                    // pindah ke OrderConfirmViewController
//                    for p in self.products
//                    {
//                        UIApplication.appDelegate.managedObjectContext?.deleteObject(p)
//                    }
//                    UIApplication.appDelegate.saveContext()
                    
                    // Mixpanel and Answers
                    if (self.checkoutResult != nil) {
                        var pName : String? = ""
                        var rName : String? = ""
                        if let u = CDUser.getOne()
                        {
                            pName = CDProvince.getProvinceNameWithID(u.profiles.provinceID)
                            if (pName == nil) {
                                pName = ""
                            }
                            rName = CDRegion.getRegionNameWithID(u.profiles.regionID)
                            if (rName == nil) {
                                rName = ""
                            }
                        }
                        
                        var items : [String] = []
                        var itemsId : [String] = []
                        var itemsCategory : [String] = []
                        var itemsSeller : [String] = []
                        var itemsPrice : [Int] = []
                        var itemsCommissionPercentage : [Int] = []
                        var itemsCommissionPrice : [Int] = []
                        var totalCommissionPrice = 0
                        var totalPrice = 0
                        for i in 0...self.arrayItem.count - 1 {
                            let json = self.arrayItem[i]
                            items.append(json["name"].stringValue)
                            itemsId.append(json["product_id"].stringValue)
                            var cName = CDCategory.getCategoryNameWithID(json["category_id"].stringValue)
                            if (cName == nil) {
                                cName = json["category_id"].stringValue
                            }
                            itemsCategory.append(cName!)
                            itemsSeller.append(json["seller_id"].stringValue)
                            itemsPrice.append(json["price"].intValue)
                            totalPrice += json["price"].intValue
                            itemsCommissionPercentage.append(json["commission"].intValue)
                            let cPrice = json["price"].intValue * json["commission"].intValue / 100
                            itemsCommissionPrice.append(cPrice)
                            totalCommissionPrice += cPrice
                        }
                        
                        let pt = [
                            "Order ID" : self.checkoutResult!["order_id"].stringValue,
                            "Items" : items,
                            "Items Category" : itemsCategory,
                            "Items Seller" : itemsSeller,
                            "Items Price" : itemsPrice,
                            "Items Commission Percentage" : itemsCommissionPercentage,
                            "Items Commission Price" : itemsCommissionPrice,
                            "Total Commission Price" : totalCommissionPrice,
                            "Shipping Price" : self.totalOngkir,
                            "Total Price" : totalPrice,
                            "Shipping Region" : rName!,
                            "Shipping Province" : pName!
                        ]
                        Mixpanel.trackEvent(MixpanelEvent.Checkout, properties: pt as [NSObject : AnyObject])
                        
                        if (AppTools.IsPreloProduction) {
                            Answers.logStartCheckoutWithPrice(NSDecimalNumber(integer: totalPrice), currency: "IDR", itemCount: NSNumber(integer: items.count), customAttributes: nil)
                            for j in 0...items.count-1 {
                                Answers.logPurchaseWithPrice(NSDecimalNumber(integer: itemsPrice[j]), currency: "IDR", success: true, itemName: items[j], itemType: itemsCategory[j], itemId: itemsId[j], customAttributes: nil)
                            }
                        }
                    }
                    
                    o.clearCart = true
                    self.navigateToVC(o)
                    
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Mixpanel
        Mixpanel.trackPageVisit(PageName.Checkout)
        
        // Google Analytics
        GAI.trackPageVisit(PageName.Checkout)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboardWithAnimations(
            { r, i, o in
                
                if (o) {
                    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, r.height, 0)
                } else {
                    self.tableView.contentInset = UIEdgeInsetsZero
                }
                
            },
            completion: nil)
        
        let checkTour = NSUserDefaults.standardUserDefaults().boolForKey("cartTour")
        if (checkTour == false)
        {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "cartTour")
            NSUserDefaults.standardUserDefaults().synchronize()
            _ = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(CartViewController.performSegTour), userInfo: nil, repeats: false)
        }
    }
    
    func performSegTour() {
        self.performSegueWithIdentifier("segTour", sender: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 2) {
            return 4
        } else if (section == 0) {
            return arrayItem.count+1+((self.bonusAvailable) ? 1 : 0)
        } else if (section == 1) {
            return 2
        } else {
            return 3
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let s = indexPath.section
        let r = indexPath.row
        var cell : UITableViewCell
        
        let cachedCell = cellViews[indexPath]
        if (cachedCell != nil) {
            return cachedCell!
        }
        
        if (s == 0) {
            if ((self.bonusAvailable && r == arrayItem.count + 1) || (!self.bonusAvailable && r == arrayItem.count)) { // Total
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
            } else if (self.bonusAvailable && r == arrayItem.count) { // Prelo Bonus
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
            } else {
                let i = tableView.dequeueReusableCellWithIdentifier("cell_item2") as! CartCellItem
                let cp = products[indexPath.row]
                i.selectedPaymentId = cp.packageId
                i.adapt(arrayItem[indexPath.row])
                i.cartItemCellDelegate = self
                
                if (r == 0)
                {
                    
                } else
                {
                    i.topLine?.hidden = true
                }
                
                i.indexPath = indexPath
                
                cell = i
            }
        } else if (s == 1) {
            if (r == 2) {
                cell = tableView.dequeueReusableCellWithIdentifier("cell_edit")!
            } else {
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
            }
        } else {
            if (r == 0 || r == 3) {
                if (r == 0) {
                    return createExpandableCell(tableView, indexPath: indexPath)!
                }
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
            } else {
                cell = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input_2")
            }
        }
        
        cellViews[indexPath] = cell
        
        return cell
    }
    
    func createOrGetBaseCartCell(tableView : UITableView, indexPath : NSIndexPath, id : String) -> BaseCartCell
    {
        let b : BaseCartCell = tableView.dequeueReusableCellWithIdentifier(id) as! BaseCartCell
        
        if (b.lastIndex != nil) {
            cells[b.lastIndex!] = b.obtainValue()
        }
        
        b.parent = self
        b.adapt(cells[indexPath])
        b.lastIndex = indexPath
        
        if (indexPath.section == 0 && indexPath.row == arrayItem.count)
        {
            b.bottomLine?.hidden = true
        }
        
        return b
    }
    
    func createExpandableCell(tableView : UITableView, indexPath : NSIndexPath) -> ACEExpandableTextCell?
    {
        var acee = tableView.dequeueReusableCellWithIdentifier("address_cell") as? CartAddressCell
        if (acee == nil) {
            acee = CartAddressCell(style: UITableViewCellStyle.Default, reuseIdentifier: "address_cell")
            acee?.selectionStyle = UITableViewCellSelectionStyle.None
            acee?.expandableTableView = tableView
            
            acee?.textView.font = UIFont.systemFontOfSize(16)
            acee?.textView.textColor = Theme.GrayDark
        }
        
        if (acee?.lastIndex != nil) {
            cells[(acee?.lastIndex)!] = acee?.obtain()
        }
        
        acee?.adapt(cells[indexPath]!)
        acee?.lastIndex = indexPath
        
        acee?.textView.textColor = UIColor(hexString: "#858585")
        
        return acee
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let s = indexPath.section
        let r = indexPath.row
        if (s == 0) {
            if (r >= arrayItem.count) {
                if (self.bonusAvailable && r == arrayItem.count)
                {
                    return 24
                }
                return 44
            } else {
                let json = arrayItem[indexPath.row]
                if let error = json["_error"].string
                {
                    let options : NSStringDrawingOptions = [.UsesLineFragmentOrigin, .UsesFontLeading]
                    let h = (error as NSString).boundingRectWithSize(CGSizeMake(UIScreen.mainScreen().bounds.width - 114, 0), options: options, attributes: [NSFontAttributeName:UIFont.systemFontOfSize(14)], context: nil).height
                    return 77 + h
                }
                return 94
            }
        } else if (s == 1) {
            if (r == 2) {
                return 20
            } else {
                return 44
            }
        } else {
            if (r == 0 || r == 3) {
                if (r == 0) {
                    return CGFloat(addressHeight)
                }
                return 44
            } else {
                return 44
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 44))
        
        v.backgroundColor = UIColor.whiteColor()
        
        let l = UILabel(frame: CGRectZero)
        l.font = UIFont.systemFontOfSize(16)
        
        if (section == 0) {
            l.text = "RINGKASAN BARANG"
        } else if (section == 1) {
            l.text = "DATA KAMU"
        } else {
            l.text = "ALAMAT PENGIRIMAN"
        }
        
        l.sizeToFit()
        
        l.y = (v.height-l.height)/2
        
        v.addSubview(l)
        
        return v
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let c = tableView.cellForRowAtIndexPath(indexPath)
        if ((c?.canBecomeFirstResponder())!) {
            c?.becomeFirstResponder()
        }
        // check if the cell is editable
    }
    
    func tableView(tableView: UITableView!, updatedHeight height: CGFloat, atIndexPath indexPath: NSIndexPath!) {
        addressHeight = Int(height)
    }
    
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        // crash
        if let i = indexPath
        {
            cells[i]?.value = text
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == txtVoucher) {
            voucher = txtVoucher.text == nil ? "" : txtVoucher.text!
            return false
        }
        
        textField.resignFirstResponder()
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            // This will be crash on iOS 7.1
            let i = tableView.indexPathForCell((textField.superview?.superview!) as! UITableViewCell)
            var s = (i?.section)!
            var r = (i?.row)!
            
            var cell : UITableViewCell?
            
            var con = true
            while (con) {
                let newIndex = NSIndexPath(forRow: r+1, inSection: s)
                cell = tableView.cellForRowAtIndexPath(newIndex)
                if (cell == nil) {
                    s += 1
                    r = -1
                    if (s == tableView.numberOfSections) { // finish, last cell
                        con = false
                    }
                } else {
                    if ((cell?.canBecomeFirstResponder())!) {
                        cell?.becomeFirstResponder()
                        con = false
                    } else {
                        r+=1
                    }
                }
            }
        }
        return true
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    @IBAction func saveVoucher()
    {
        voucher = txtVoucher.text!
        self.synch()
    }
    
    @IBAction func setPaymentOption(sender : UITapGestureRecognizer)
    {
        let v = sender.view!
        let i = v.tag
        
        if (i > 0)
        {
            UIAlertView.SimpleShow("Coming Soon :)", message: "")
            return
        }
        for b in sectionsPaymentOption
        {
            b.cartSelectAsPayment(false)
        }
        
        let b = sender.view as! BorderedView
        b.cartSelectAsPayment(true)
        
        let x = (UIScreen.mainScreen().bounds.size.width-32) * -CGFloat(i)
        consOffsetPaymentDesc?.constant = x
        
        selectedPayment = availablePayments[b.tag]
    }

    var shouldBack = false
    func itemNeedDelete(indexPath: NSIndexPath) {
        let j = arrayItem[indexPath.row]
        print(j)
        arrayItem.removeAtIndex(indexPath.row)
        
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let x = AppToolsObjC.jsonStringFrom(c)
        
        print(x)
        
        let pid = j["product_id"].stringValue
        
        var deletedProduct : CartProduct?
        var index = 0
        for cp in products
        {
            if (cp.cpID == pid) // delete cart product
            {
                deletedProduct = cp
                break
            }
            index += 1
        }
        
        if let p = deletedProduct
        {
            products.removeAtIndex(index)
            print(p.cpID)
            UIApplication.appDelegate.managedObjectContext.deleteObject(p)
            UIApplication.appDelegate.saveContext()
        }
        
//        let p = products[indexPath.row]
        
        
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        if (arrayItem.count == 0) {
            self.shouldBack = true
//            self.navigationController?.popViewControllerAnimated(true)
        } //else {
            cells = [:]
            for (_, c) in cellViews
            {
                if let b = c as? BaseCartCell
                {
                    b.lastIndex = nil
                } else if let b = c as? CartAddressCell
                {
                    b.lastIndex = nil
                }
            }
            cellViews = [:]
            createCells()
            synch()
        //}
    }
    
    func itemNeedUpdateShipping(indexPath: NSIndexPath) {
        let j = arrayItem[indexPath.row]
        let jid = j["product_id"].stringValue
        var cartProduct : CartProduct?
        for cp in products
        {
            if (cp.cpID == jid)
            {
                cartProduct = cp
                break
            }
        }
        
        if let cp = cartProduct
        {
            print(j)
            var names : Array<String> = []
            var arr = j["shipping_packages"].array
            if let shippings = j["shipping_packages"].arrayObject
            {
                for s in shippings
                {
                    let json = JSON(s)
                    if let name = json["name"].string
                    {
                        names.append(name)
                    }
                }
                
                if (names.count > 0)
                {
                    ActionSheetStringPicker.showPickerWithTitle("Select Shipping", rows: names, initialSelection: 0, doneBlock: {picker, index, value in
                        let sjson = arr?[index]
                        if let pid = sjson?["_id"].string
                        {
                            cp.packageId = pid
                            let c = self.cellViews[indexPath] as! CartCellItem
                            c.selectedPaymentId = pid
                            c.adapt(self.arrayItem[indexPath.row])
                            UIApplication.appDelegate.saveContext()
                            self.tableView.reloadData()
                            self.adjustTotal()
                        }
                        }, cancelBlock: {picker in
                            
                        }, origin: self.view)
                }
            }
        }
    }
    
    // MARK: - Payment Reminder
    
    @IBAction func paymentReminderPressed(sender: AnyObject) {
        let paymentConfirmationVC = NSBundle.mainBundle().loadNibNamed(Tags.XibNamePaymentConfirmation, owner: nil, options: nil).first as! PaymentConfirmationViewController
        self.navigateToVC(paymentConfirmationVC)
    }
    
    // MARK: - User Related Delegate
    func userLoggedIn() {
        user = CDUser.getOne()
        products = CartProduct.getAll(User.EmailOrEmptyString)
        tableView.hidden = false
        createCells()
        synch()
    }
    
    func userCancelLogin() {
        user = CDUser.getOne()
        if (user == nil)
        {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    // MARK: - Navigation
    
    func navigateToVC(vc: UIViewController) {
        if (previousController != nil) {
            self.previousController!.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "segOK") {
            let c = segue.destinationViewController as! CarConfirmViewController
            c.orderID = (checkoutResult?["order_id"].string)!
            c.totalPayment = (checkoutResult?["final_price"].int)!
            c.paymentMethod = (checkoutResult?["payment_method"].string)!
        }
        
    }

}

class BaseCartData : NSObject
{
    var title : String?
    var placeHolder : String?
    var value : String?
    var enable : Bool = true
    var image : UIImage?
    var keyboardType = UIKeyboardType.Default
    
    var pickerPrepDataBlock : PrepDataBlock?
    
    static func instance(title : String?, placeHolder : String?) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = true
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, enable : Bool) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = enable
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, value : String) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = true
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, value : String, pickerPrepBlock : PrepDataBlock?) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = true
        
        b.pickerPrepDataBlock = pickerPrepBlock
        
        return b
    }
    
    static func instance(title : String?, placeHolder : String?, value : String?, enable : Bool) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = title
        b.placeHolder = placeHolder
        b.value = value
        b.enable = enable
        
        return b
    }
    
    static func instanceWith(image : UIImage, placeHolder : String) -> BaseCartData
    {
        let b = BaseCartData()
        b.title = ""
        b.placeHolder = placeHolder
        b.value = nil
        b.enable = true
        b.image = image
        
        return b
    }
    
    static func instanceWith(image : UIImage, placeHolder : String, pickerPrepBlock : PrepDataBlock?) -> BaseCartData
    {
        let b = BaseCartData.instanceWith(image, placeHolder: placeHolder)
        b.pickerPrepDataBlock = pickerPrepBlock
        return b
    }
}

class BaseCartCell : UITableViewCell
{
    @IBOutlet var captionTitle : UILabel?
    var parent : UIViewController?
    
    var baseCartData : BaseCartData?
    var lastIndex : NSIndexPath?
    
    @IBOutlet var bottomLine : UIView?
    @IBOutlet var topLine : UIView?
    
    func obtainValue() -> BaseCartData?
    {
        return nil
    }
    
    func adapt(item : BaseCartData?)
    {
        
    }
}

class CartCellInput : BaseCartCell
{
    @IBOutlet var txtField : UITextField!
    
    override func canBecomeFirstResponder() -> Bool {
        return txtField.canBecomeFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        return txtField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return txtField.resignFirstResponder()
    }
    
    override func adapt(item : BaseCartData?) {
        baseCartData = item
        if (item == nil) {
            captionTitle?.text = "-"
            txtField.text = "-"
            return
        }
        captionTitle?.text = item?.title
        let placeholder = item?.placeHolder
        if (placeholder != nil) {
            txtField.placeholder = placeholder
        }
        
        let value = item?.value
        if (value != nil) {
            if (value! == "10%")
            {
                txtField.font = UIFont.boldSystemFontOfSize(14)
                let l = self.contentView.viewWithTag(666)
                l?.hidden = true
            }
            txtField.text = value
        } else {
            txtField.text = ""
        }
        
        if let t = captionTitle?.text
        {
            let s = t.lowercaseString as NSString
            let i = s.rangeOfString("harga")
            if (i.location != NSNotFound)
            {
                txtField.keyboardType = UIKeyboardType.DecimalPad
            } else
            {
                txtField.keyboardType = (item?.keyboardType)!
            }
        }
        
        txtField.enabled = (item?.enable)!
    }
    
    override func obtainValue() -> BaseCartData? {
        baseCartData?.value = txtField.text
        return baseCartData
    }
}

class CartCellInput2 : BaseCartCell, PickerViewDelegate
{
    @IBOutlet var captionValue : UILabel?
    
    override func canBecomeFirstResponder() -> Bool {
        return parent != nil
    }
    
    override func becomeFirstResponder() -> Bool {
        let p = parent?.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdPicker) as? PickerViewController
        p?.items = []
        p?.pickerDelegate = self
        p?.prepDataBlock = baseCartData?.pickerPrepDataBlock
        p?.title = baseCartData?.title
        parent?.view.endEditing(true)
        parent?.navigationController?.pushViewController(p!, animated: true)
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
    
    func pickerDidSelect(item: String) {
        captionValue?.text = PickerViewController.HideHiddenString(item)
    }
    
    override func adapt(item : BaseCartData?) {
        baseCartData = item
        captionTitle?.text = item?.title
        let value = item?.value
        if (value != nil) {
            captionValue?.text = value
        } else {
            captionValue?.text = ""
        }
    }
    
    override func obtainValue() -> BaseCartData? {
        baseCartData?.value = captionValue?.text
        return baseCartData
    }
}

class CartCellEdit : UITableViewCell
{
    override func canBecomeFirstResponder() -> Bool {
        return false
    }
}

protocol CartItemCellDelegate
{
    func itemNeedDelete(indexPath : NSIndexPath)
    func itemNeedUpdateShipping(indexPath : NSIndexPath)
}

class CartCellItem : UITableViewCell
{
    @IBOutlet var shade : UIView?
    @IBOutlet var captionName : UILabel?
    @IBOutlet var captionPrice : UILabel?
    @IBOutlet var captionLocation : UILabel?
    @IBOutlet var btnShippment : UIButton?
    @IBOutlet var ivCover : UIImageView?
    @IBOutlet var captionFrom : UILabel?
    
    @IBOutlet var bottomLine : UIView?
    @IBOutlet var topLine : UIView?
    
    override func canBecomeFirstResponder() -> Bool {
        return false
    }
    
    var selectedPaymentId : String = ""
    var cartItemCellDelegate : CartItemCellDelegate?
    
    func adapt (json : JSON)
    {
        print(json)
        captionName?.text = json["name"].stringValue
        captionLocation?.text = ""
        
        if let raw : Array<AnyObject> = json["display_picts"].arrayObject
        {
            var ori : Array<String> = []
            for o in raw
            {
                if let s = o as? String
                {
                    ori.append(s)
                }
            }
            
            if (ori.count > 0)
            {
                ivCover?.image = nil
                let u = NSURL(string: ori.first!)
                ivCover?.setImageWithUrl(u!, placeHolderImage: nil)
            }
        }
        
        if let error = json["_error"].string
        {
//            let string = "SOLD OUT"
            let string = error
            let attString = NSMutableAttributedString(string: string)
            attString.addAttributes([NSForegroundColorAttributeName:UIColor.redColor(), NSFontAttributeName:UIFont.systemFontOfSize(14)], range: AppToolsObjC.rangeOf(string, inside: string))
            captionPrice?.attributedText = attString
            captionPrice?.numberOfLines = 0
            shade?.hidden = false
        } else {
            let sh = json["shipping_packages"].array!
            var first = sh.first
            for i in 0...sh.count-1
            {
                let s = sh[i]
                let id = s["_id"].string!
                if (id == selectedPaymentId)
                {
                    first = s
                }
            }
            if (selectedPaymentId == "")
            {
                first = sh.first
            }
            let ongkir = json["free_ongkir"].bool == true ? 0 : first?["price"].int
            
            if let name = first?["name"].string
            {
                self.btnShippment?.setTitle(name, forState: UIControlState.Normal)
            }
            
            let ongkirString = ongkir == 0 ? "(FREE ONGKIR)" : " (+ONGKIR " + ongkir!.asPrice + ")"
            let priceString = json["price"].int!.asPrice + ongkirString
            let string = priceString + "" + ""
            let attString = NSMutableAttributedString(string: string)
            attString.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColorDark, NSFontAttributeName:UIFont.boldSystemFontOfSize(14)], range: AppToolsObjC.rangeOf(priceString, inside: string))
            attString.addAttributes([NSForegroundColorAttributeName:Theme.GrayDark, NSFontAttributeName:UIFont.systemFontOfSize(10)], range: AppToolsObjC.rangeOf(ongkirString, inside: string))
            captionPrice?.attributedText = attString
            shade?.hidden = true
            
            let sellerLocationID = json["seller_region"].stringValue
            if let regionName = CDRegion.getRegionNameWithID(sellerLocationID)
            {
                self.captionFrom?.text = "Dikirim dari " + regionName
            } else
            {
                self.captionFrom?.text = ""
            }
        }
        
    }
    
    var indexPath : NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    
    @IBAction func deleteMe()
    {
        if let d = cartItemCellDelegate
        {
            _ = indexPath.row
            d.itemNeedDelete(indexPath)
        }
    }
    
    @IBAction func switchShipping()
    {
        if let d = cartItemCellDelegate
        {
            d.itemNeedUpdateShipping(indexPath)
        }
    }
}

class CartAddressCell : ACEExpandableTextCell
{
    var baseCartData : BaseCartData?
    var lastIndex : NSIndexPath?
    
    func adapt(item : BaseCartData)
    {
        baseCartData = item
        self.textView.placeholder = item.title
        self.text = item.value
    }
    
    func obtain() -> BaseCartData?
    {
        return baseCartData
    }
}

extension BorderedView
{
    func cartSelectAsPayment(select : Bool)
    {
        setColor(select ? Theme.PrimaryColorDark : Theme.GrayLight)
    }
    
    private func setColor(c : UIColor)
    {
//        let tintedImageView = self.viewWithTag(1)
//        let text = self.viewWithTag(2) as? UILabel
//        
//        tintedImageView?.tintColor = c
//        text?.textColor = c
        for v in self.subviews
        {
            if (v.isKindOfClass(UILabel.classForCoder()))
            {
                let l = v as! UILabel
                l.textColor = c
            } else if (v.isKindOfClass(TintedImageView.classForCoder()))
            {
                let i = v as! TintedImageView
                i.tintColor = c
            }
        }
    }
}
