//
//  CartViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/3/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class CartViewController: BaseViewController, ACEExpandableTableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITextFieldDelegate, CartItemCellDelegate, UserRelatedDelegate {

    @IBOutlet var tableView : UITableView!
    @IBOutlet var txtVoucher : UITextField!
    
    @IBOutlet var btnSend : UIButton!
    
    @IBOutlet var sectionsPaymentOption : Array<BorderedView> = []
    
    @IBOutlet var consOffsetPaymentDesc : NSLayoutConstraint?
    @IBOutlet var sectionPaymentDesc: UIView!
    
    let titleNama = "Nama"
    let titleTelepon = "Telepon"
    let titleAlamat = "Alamat"
    let titleProvinsi = "Provinsi"
    let titleKota = "Kab / Kota"
    let titlePostal = "Kode Pos"
    
    var address = ""
    var addressHeight = 44
    
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
    
    @IBOutlet var captionNoItem: UILabel!
    @IBOutlet var loadingCart: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Checkout"
        
        products = CartProduct.getAll(User.EmailOrEmptyString)
        
        if (products.count == 0)
        {
            tableView.hidden = true
            loadingCart.hidden = true
            captionNoItem.hidden = false
        } else
        {
            self.navigationItem.rightBarButtonItem = self.confirmButton.toBarButton()
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
        
        var c = BaseCartData.instance(titlePostal, placeHolder: "Kode Pos", value : postalcode)
        c.keyboardType = UIKeyboardType.NumberPad
        
        self.cells = [
            NSIndexPath(forRow: 0, inSection: 1):BaseCartData.instance(titleNama, placeHolder: "Nama Lengkap Kamu", value : fullname),
            NSIndexPath(forRow: 1, inSection: 1):BaseCartData.instance(titleTelepon, placeHolder: "Nomor Telepon Kamu", value : phone),
            NSIndexPath(forRow: 0, inSection: 2):BaseCartData.instance(titleAlamat, placeHolder: "Alamat Lengkap Kamu", value : address),
            NSIndexPath(forRow: 1, inSection: 2):BaseCartData.instance(titleProvinsi, placeHolder: nil, value: "", pickerPrepBlock: { picker in
                
                picker.startLoading()
                picker.items = CDProvince.getProvincePickerItems()
                
                // on select block
                picker.selectBlock = { string in
                    self.selectedProvinsiID = PickerViewController.RevealHiddenString(string)
                }
            }),
            NSIndexPath(forRow: 2, inSection: 2):BaseCartData.instance(titleKota, placeHolder: nil, value: "", pickerPrepBlock: { picker in
                
                picker.startLoading()
                picker.items = CDRegion.getRegionPickerItems(self.selectedProvinsiID)
                
                picker.selectBlock = { string in
                    self.selectedKotaID = PickerViewController.RevealHiddenString(string)
                }
                
            }),
            NSIndexPath(forRow: 3, inSection: 2):c
        ]
    }
    
    func adjustTotal()
    {
        var totalOngkir = 0
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
        
        let b = cells[NSIndexPath(forRow: products.count, inSection: 0)]
        if let total = self.currentCart?["_data"]["total_price"].int, let d = b
        {
            d.value = (totalOngkir + total).asPrice
            if let c = cellViews[NSIndexPath(forRow: products.count, inSection: 0)] as? CartCellInput
            {
                c.txtField.text = d.value
            }
        }
        
        self.tableView.reloadData()
    }
    
    var currentCart : JSON?
    var bonusAvailable = false
    func synch()
    {
        tableView.hidden = true
        
        cellViews = [:]
        
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let p = AppToolsObjC.jsonStringFrom(c)
        
        println(p)
        
        let a = "{\"address\": \"alamat\", \"province_id\": \"533f812d6d07364195779445\", \"region_id\": \"53a6b95d0ceb958f78000026\", \"postal_code\": \"12345\"}"
        
        request(APICart.Refresh(cart: p, address: a, voucher: voucher))
            .responseJSON {req, resp, res, err in
                
                println(res)
                println()
                
                if let result: AnyObject = res
                {
                    let json = JSON(result)
                    self.currentCart = json
                    
                    if let error = json["_data"].error
                    {
                        Constant.showDialog("Warning", message: json["_message"].string!)
                    }
                    else
                    {
                        let i = NSIndexPath(forRow: self.products.count, inSection: 0)
                        let b = BaseCartData.instance("Total", placeHolder: nil, enable : false)
                        if let price = json["_data"]["total_price"].int?.asPrice
                        {
                            b.value = price
                        }
                        self.cells[i] = b
                        
                        if let bonus = json["_data"]["bonus_available"].int
                        {
                            if (bonus != 0)
                            {
                                self.bonusAvailable = true
                                let b2 = BaseCartData.instance("Bonus Prelo", placeHolder: nil, enable : false)
                                if let price = json["_data"]["bonus_available"].int?.asPrice
                                {
                                    b2.value = price
                                }
                                b2.enable = false
                                let i2 = NSIndexPath(forRow: self.products.count+1, inSection: 0)
                                self.cells[i2] = b2
                            }
                        }
                        
                        self.arrayItem = json["_data"]["cart_details"].array!
                        
                        self.tableView.dataSource = self
                        self.tableView.delegate = self
                        self.tableView.reloadData()
                        self.tableView.hidden = false
                        self.adjustTotal()
                    }
                } else
                {
                    println(err)
                    println(resp)
                    println(req)
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
        
        var phone = ""
        var postal = ""
        for i in cells.keys
        {
            let b = cells[i]
            if (b?.value == nil || b?.value == "") {
                Constant.showDialog("Warning", message: (b?.title)! + " still empty !")
                return
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
            
            println((b?.title)! + " : " + (b?.value)!)
        }
        
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let p = AppToolsObjC.jsonStringFrom(c)
        
        var user = CDUser.getOne()
        user?.profiles.address = address
        user?.profiles.postalCode = postal
        UIApplication.appDelegate.saveContext()
        
        let d = ["address":address, "province_id":selectedProvinsiID, "region_id":selectedKotaID, "postal_code":postal]
        let a = AppToolsObjC.jsonStringFrom(d)
        
        self.btnSend.enabled = false
        request(APICart.Checkout(cart: p, address: a, voucher: voucher, payment: selectedPayment))
            .responseJSON{_, resp, res, err in
                self.btnSend.enabled = true
                if (APIPrelo.validate(true, err: err, resp: resp))
                {
                    println(res)
                    var json = JSON(res!)
                    if let error = json["_message"].string
                    {
                        Constant.showDialog("Warning", message: error)
                    } else {
                        println(res)
                        self.checkoutResult = JSON(res!)["_data"]
                        let c = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdCartConfirm) as! CarConfirmViewController
                        c.orderID = (self.checkoutResult?["order_id"].string)!
                        c.totalPayment = (self.checkoutResult?["total_price"].int)!
                        c.paymentMethod = (self.checkoutResult?["payment_method"].string)!
                        c.transactionId = (self.checkoutResult?["transaction_id"].string)!
                        c.items = self.arrayItem
                        
                        for p in self.products
                        {
                            UIApplication.appDelegate.managedObjectContext?.deleteObject(p)
                        }
                        UIApplication.appDelegate.saveContext()
                        
                        self.previousController?.navigationController?.pushViewController(c, animated: true)
                        
                    }
                } else {
                    
                }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().track("Checkout Page")
        
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
            self.performSegueWithIdentifier("segTour", sender: nil)
            
        }
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
                let i = tableView.dequeueReusableCellWithIdentifier("cell_item") as! CartCellItem
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
                cell = tableView.dequeueReusableCellWithIdentifier("cell_edit") as! UITableViewCell
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
            if (r == arrayItem.count) {
                return 44
            } else {
                return 74
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
            l.text = "RINGKASAN PRODUK"
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
            voucher = txtVoucher.text
            return false
        }
        
        textField.resignFirstResponder()
        
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
                if (s == tableView.numberOfSections()) { // finish, last cell
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

    func itemNeedDelete(indexPath: NSIndexPath) {
        let j = arrayItem[indexPath.row]
        println(j)
        arrayItem.removeAtIndex(indexPath.row)
        
        let c = CartProduct.getAllAsDictionary(User.EmailOrEmptyString)
        let x = AppToolsObjC.jsonStringFrom(c)
        
        println(x)
        
        let p = products[indexPath.row]
        products.removeAtIndex(indexPath.row)
        println(p.cpID)
        UIApplication.appDelegate.managedObjectContext?.deleteObject(p)
        UIApplication.appDelegate.saveContext()
        
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        if (arrayItem.count == 0) {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            synch()
        }
    }
    
    func itemNeedUpdateShipping(indexPath: NSIndexPath) {
        let j = arrayItem[indexPath.row]
        let cp = products[indexPath.row]
        println(j)
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
    
    @IBOutlet var bottomLine : UIView?
    @IBOutlet var topLine : UIView?
    
    override func canBecomeFirstResponder() -> Bool {
        return false
    }
    
    var selectedPaymentId : String = ""
    var cartItemCellDelegate : CartItemCellDelegate?
    
    func adapt (json : JSON)
    {
        println(json)
        captionName?.text = json["name"].string!
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
            let string = "SOLD OUT"
            let attString = NSMutableAttributedString(string: string)
            attString.addAttributes([NSForegroundColorAttributeName:UIColor.redColor(), NSFontAttributeName:UIFont.systemFontOfSize(14)], range: AppToolsObjC.rangeOf(string, inside: string))
            captionPrice?.attributedText = attString
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
            var ongkir = json["free_ongkir"].bool == true ? 0 : first?["price"].int
            
            if let name = first?["name"].string
            {
                self.btnShippment?.setTitle(name, forState: UIControlState.Normal)
            }
            
            let ongkirString = ongkir == 0 ? "(FREE ONGKIR)" : " (+ONGKIR " + ongkir!.asPrice + ")"
            var priceString = json["price"].int!.asPrice + ongkirString
            let string = priceString + "" + ""
            let attString = NSMutableAttributedString(string: string)
            attString.addAttributes([NSForegroundColorAttributeName:Theme.PrimaryColorDark, NSFontAttributeName:UIFont.boldSystemFontOfSize(14)], range: AppToolsObjC.rangeOf(priceString, inside: string))
            attString.addAttributes([NSForegroundColorAttributeName:Theme.GrayDark, NSFontAttributeName:UIFont.systemFontOfSize(10)], range: AppToolsObjC.rangeOf(ongkirString, inside: string))
            captionPrice?.attributedText = attString
            shade?.hidden = true
        }
        
    }
    
    var indexPath : NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    
    @IBAction func deleteMe()
    {
        if let d = cartItemCellDelegate
        {
            var row = indexPath.row
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
