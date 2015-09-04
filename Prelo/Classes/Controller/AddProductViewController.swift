//
//  AddProductViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import QuartzCore

class AddProductViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDataSource, ACEExpandableTableViewDelegate, AddProductImageCellDelegate, UITextFieldDelegate, UIScrollViewDelegate, UIActionSheetDelegate, AdobeUXImageEditorViewControllerDelegate, UserRelatedDelegate, ProductCategoryDelegate, AddProductWeightDelegate
{
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var gridView : UICollectionView?
    @IBOutlet var sectionHeader : UIView?
    
    var s1 : CGSize = CGSizeZero
    var s2 : CGSize = CGSizeZero
    
    var sectionTitles : Array<[String : String]> = []
    var baseDatas : [NSIndexPath:BaseCartData] = [:]
    var cells : [NSIndexPath:UITableViewCell] = [:]
    var heights : [NSIndexPath:CGFloat] = [:]
    
    var selectedCategoryID = ""
    
    var imageHints = [["title":"Tampak Belakang", "image":"ic_backarrow"], ["title":"Tampilan Label / Merek", "image":"ic_tag"], ["title":"Digantung", "image":"ic_hanger"], ["title":"Cacat (Jika ada)", "image":"ic_cacat"]]
    
    var selectedMerk = ""
    var selectedKondisi = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Add Product"
        // Do any additional setup after loading the view.
        
        sectionHeader?.width = UIScreen.mainScreen().bounds.width
        sectionHeader?.height = UIScreen.mainScreen().bounds.width * 3 / 4
        
        s1 = CGSizeMake((UIScreen.mainScreen().bounds.width-2)/2, (sectionHeader?.height)!)
        s2 = CGSizeMake((s1.width)/2, (s1.height-2)/2)
        
        tableView?.registerNib(UINib(nibName: "AddProductHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
        
        sectionTitles.append(["title":"Detail Produk", "icon":""])
        //        sectionTitles.append(["title":"Ukuran", "icon":""])
        sectionTitles.append(["title":"Ongkos Kirim", "icon":""])
        sectionTitles.append(["title":"Berat", "icon":""])
        sectionTitles.append(["title":"Harga", "icon":""])
        //        sectionTitles.append(["title":"Share", "icon":""])
        
        baseDatas[NSIndexPath(forRow: 0, inSection: 0)] = BaseCartData.instanceWith(UIImage(named: "category_placeholder")!, placeHolder: "Pilih Kategori", pickerPrepBlock : {picker in
            
            picker.textTitle = "Pilih Kategori"
            picker.items = ["Baju", "Celana", "Kaca Mata", "Daleman"]
            picker.tableView.reloadData()
            picker.doneLoading()
            
        })
        baseDatas[NSIndexPath(forRow: 1, inSection: 0)] = BaseCartData.instance("Nama Produk", placeHolder: "Nama Produk")
        baseDatas[NSIndexPath(forRow: 2, inSection: 0)] = BaseCartData.instance("Deskripsi", placeHolder: "Deskripsi")
        baseDatas[NSIndexPath(forRow: 3, inSection: 0)] = BaseCartData.instance("Kondisi", placeHolder: "Kondisi", value: "", pickerPrepBlock: { picker in
            
            picker.textTitle = "Pilih Kondisi"
            
            let s = NSBundle.mainBundle().URLForResource("merk", withExtension: "json")?.absoluteString
            if let url = s
            {
                request(Method.GET, url, parameters: nil, encoding: ParameterEncoding.URL, headers: nil).responseJSON{_, _, res, err in
                    let json = JSON(res!)
                    let brands = json["product_conditions"].array
                    var items : Array<String> = []
                    if let arrBrands = brands
                    {
                        for i in 0...(arrBrands.count)-1
                        {
                            let j = arrBrands[i]
                            let m = (j["name"].string)! + PickerViewController.TAG_START_HIDDEN + (j["_id"].string)! + PickerViewController.TAG_END_HIDDEN
                            items.append(m)
                        }
                    }
                    
                    picker.selectBlock = { s in
                        self.selectedKondisi = PickerViewController.RevealHiddenString(s)
                    }
                    
                    picker.items = items
                    picker.tableView.reloadData()
                    picker.doneLoading()
                }
            }
        })
        baseDatas[NSIndexPath(forRow: 4, inSection: 0)] = BaseCartData.instance("Merk", placeHolder: "Merk", value: "", pickerPrepBlock: { picker in
            
            picker.textTitle = "Pilih Merk"
            
            let s = NSBundle.mainBundle().URLForResource("merk", withExtension: "json")?.absoluteString
            if let url = s
            {
                request(Method.GET, url, parameters: nil, encoding: ParameterEncoding.URL, headers: nil).responseJSON{_, _, res, err in
                    let json = JSON(res!)
                    let brands = json["brands"].array
                    var items : Array<String> = []
                    if let arrBrands = brands
                    {
                        for i in 0...(arrBrands.count)-1
                        {
                            let j = arrBrands[i]
                            let m = (j["name"].string)! + PickerViewController.TAG_START_HIDDEN + (j["_id"].string)! + PickerViewController.TAG_END_HIDDEN
                            items.append(m)
                        }
                    }
                    
                    picker.selectBlock = { s in
                        self.selectedMerk = PickerViewController.RevealHiddenString(s)
                    }
                    
                    picker.items = items
                    picker.tableView.reloadData()
                    picker.doneLoading()
                    picker.showSearch = true
                }
            }
        })
        //        baseDatas[NSIndexPath(forRow: 1, inSection: 1)] = BaseCartData.instance("Ukuran", placeHolder: "Masukan Ukuran")
        baseDatas[NSIndexPath(forRow: 1, inSection: 2)] = BaseCartData.instance("Berat", placeHolder: "Masukan Berat")
        baseDatas[NSIndexPath(forRow: 0, inSection: 3)] = BaseCartData.instance("Harga Beli", placeHolder: "Masukan Harga")
        baseDatas[NSIndexPath(forRow: 1, inSection: 3)] = BaseCartData.instance("Harga Jual Prelo", placeHolder: "Masukan Harga")
        baseDatas[NSIndexPath(forRow: 2, inSection: 3)] = BaseCartData.instance("Charge Prelo", placeHolder: "Komisi Prelo", value: "10%", enable: false)
        
        tableView?.dataSource = self
        tableView?.delegate = self
        
        self.navigationItem.rightBarButtonItem = self.confirmButton.toBarButton()
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
    
    var first = true
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().track("Add Product")
        
        if (User.IsLoggedIn)
        {
            if (first) // show picker!!
            {
                self.addImage()
            }
        } else {
            if (first)
            {
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            }
        }
    }
    
    func userLoggedIn() {
        
    }
    
    func userLoggedOut() {
        
    }
    
    func userCancelLogin() {
        self.first = false
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.an_unsubscribeKeyboard()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var sendIMGs : Array<UIImage> = []
    override func confirm() {
        populateImages(0)
        //        self.callAPI()
    }
    
    func populateImages(i : Int)
    {
        if (i == images.count) { // done with image
            callAPI()
        } else {
            let ap = images[i]
            ap.getImage({ im in
                if let img = im
                {
                    self.sendIMGs.append(img)
                    self.populateImages(i+1)
                }
            })
        }
    }
    
    @IBOutlet var btnSend : UIButton!
    func callAPI()
    {
        var xxx = false
        if (xxx)
        {
            let s = self.storyboard?.instantiateViewControllerWithIdentifier("share") as! AddProductShareViewController
            self.navigationController?.pushViewController(s, animated: true)
            return
        }
        
        var price : String?
        
        var imgs : Array<UIImage> = []
        
        for (i, c) in cells
        {
            if (c.isKindOfClass(BaseCartCell.classForCoder()))
            {
                let b = c as! BaseCartCell
                if let d = b.obtainValue()
                {
                    if let t = d.title
                    {
                        if (t == "Nama Produk")
                        {
                            name = d.value
                        }
                        
                        if (t == "Harga Jual Prelo")
                        {
                            price = d.value
                        }
                        
                        if (t == "Deskripsi")
                        {
                            desc = d.value
                        }
                        //
                        //                        if (t == "Berat")
                        //                        {
                        //                            weight = d.value!
                        //                        }
                    }
                }
            } else if (c.isKindOfClass(ACEExpandableTextCell.classForCoder()))
            {
                let a = c as! ACEExpandableTextCell
                if (i.row == 1) {
                    name = a.textView.text
                } else if (i.row == 2) {
                    desc = a.textView.text
                }
            }
        }
        
        // validation
        if (name == nil)
        {
            UIAlertView.SimpleShow("Warning", message: "Nama item masih kosong")
            return
        }
        
        if (desc == nil)
        {
            UIAlertView.SimpleShow("Warning", message: "Deskripsi item masih kosong")
            return
        }
        
        if (price == nil)
        {
            UIAlertView.SimpleShow("Warning", message: "Harga item masih kosong")
            return
        }
        let weight = currentWeight as NSString
        if (currentWeight == "" || weight.integerValue == 0)
        {
            UIAlertView.SimpleShow("Warning", message: "Berat item masih kosong")
            return
        }
        
        if (selectedCategoryID == "")
        {
            UIAlertView.SimpleShow("Warning", message: "Kategori item masih kosong")
            return
        }
        
        self.navigationItem.rightBarButtonItem = nil
        btnSend.enabled = false
        
        Mixpanel.sharedInstance().timeEvent("Adding Product")
        
        AppToolsObjC.sendMultipart(["name":name!, "description":desc!, "category":selectedCategoryID, "price":price!, "weight":currentWeight], images: self.sendIMGs, withToken: User.Token!, success: {op, res in
            println(res)
            Mixpanel.sharedInstance().track("Adding Product", properties: ["success":"1"])
            let json = JSON(res!)
            let s = self.storyboard?.instantiateViewControllerWithIdentifier("share") as! AddProductShareViewController
            if let price = json["_data"]["price"].int
            {
                s.basePrice = price
            }
            self.navigationController?.pushViewController(s, animated: true)
        }, failure: {op, err in
            Mixpanel.sharedInstance().track("Adding Product", properties: ["success":"0"])
            self.navigationItem.rightBarButtonItem = self.confirmButton.toBarButton()
            self.btnSend.enabled = true
            UIAlertView.SimpleShow("Warning", message: "Gagal")
        })
    
        // mark
        
        //        let manager = AFHTTPRequestOperationManager()
        //        manager.requestSerializer = AFJSONRequestSerializer()
        //        manager.requestSerializer.setValue("Token " + User.Token!, forHTTPHeaderField: "Authorization")
        //
        //        manager.POST("http://dev.preloapp.com/api/2/products", parameters: ["name":name!, "description":desc!, "category":selectedCategoryID, "price":price!, "weight":weight!], constructingBodyWithBlock: {form in
        //                if (self.sendIMGs.count > 0)
        //                {
        //                    for x in 0...self.sendIMGs.count
        //                    {
        //                        let img = UIImageJPEGRepresentation(self.sendIMGs[x], 0.5)
        //                        let name = "image" + String(x)
        //                    }
        //                }
        //            }, success: { op, res in
        //                let json = JSON(res)
        //            println(json)
        //            println("")
        //            }, failure: { op, err in
        //                println(op.request.allHTTPHeaderFields)
        //                println(op.responseObject)
        //                println(err)
        //        })
        
        //        request(Products.Add(name: name!, desc: desc!, price: price!, weight: weight!, category: selectedCategoryID)).responseJSON{_, resp, res, err in
        //            if (err != nil) {
        //                println(err)
        //            } else
        //            {
        //                let j = JSON(res!)
        //                println(j)
        //                println(resp)
        //                let s = self.storyboard?.instantiateViewControllerWithIdentifier("share") as! UIViewController
        //                self.navigationController?.pushViewController(s, animated: true)
        //            }
        //        }
        
        //        let param = JSON(["name":name!, "desc":desc!, "category":selectedCategoryID, "price":price!, "weight":weight!])
        //
        //        let parameterString = param.rawString(encoding: NSUTF8StringEncoding, options: nil)
        //        let jsonParameterData = parameterString!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        //        upload(Products.Add(name: name!, desc: desc!, price: price!, weight: weight!, category: selectedCategoryID), multipartFormData: { form in
        //
        //            }, encodingCompletion: { encodingResult in
        //                switch encodingResult {
        //                case .Success(let upload, _, _):
        //                    upload.responseJSON { request, response, JSON, error in
        //                        println(request)
        //                        println(response!)
        //                        println(JSON)
        //                    }
        //                case .Failure(let encodingError):
        //                    println(encodingError)
        //                }
        //        })
        
        //        upload(Products.Add(name: name!, desc: desc!, price: price!, weight: weight!, category: selectedCategoryID), multipartFormData: {form in
        //
        //            }, encodingCompletion: { result in
        //                switch result
        //                {
        //                case .Success(let upload, _, _):
        //                    upload.responseJSON { request, response, json, error in
        //                        let s = AppToolsObjC.stringWithData(request.HTTPBody!)
        //                        if (error != nil) {
        //                            UIAlertView.SimpleShow("Warning", message: "Gagal")
        //                        } else {
        //                            let j = JSON(json!)
        //                            println(j)
        //                            let s = self.storyboard?.instantiateViewControllerWithIdentifier("share") as! UIViewController
        //                            self.navigationController?.pushViewController(s, animated: true)
        //                            self.performSegueWithIdentifier("segShare", sender: nil)
        //                        }
        //                    }
        //                case .Failure(let encodingError):
        //                    self.performSegueWithIdentifier("segShare", sender: nil)
        //                    let s = self.storyboard?.instantiateViewControllerWithIdentifier("share") as! UIViewController
        //                    self.navigationController?.pushViewController(s, animated: true)
        //                }
        //        })
    }
    
    @IBAction func sendConfirm()
    {
        self.confirm()
    }
    
    var images : [APImage] = []
    
    var replaceIndex : Int = -1
    func addImage() {
        ImagePickerViewController.ShowFrom(self, maxSelect: (replaceIndex != -1) ? 1 : 5-self.images.count, doneBlock: {imgs in
            
            if (self.first)
            {
                if (imgs.count == 0)
                {
                    self.navigationController?.popViewControllerAnimated(true)
                }
                
                self.first = false
            }
            
            if (self.replaceIndex != -1)
            {
                self.images[self.replaceIndex] = imgs[0]
                self.replaceIndex = -1
            } else
            {
                for a in imgs
                {
                    self.images.append(a)
                }
            }
            self.gridView?.reloadData()
        })
    }
    
    func addImage(info: [String : AnyObject]) {
        let indexPath = info["replaceIndex"] as! NSIndexPath
        replaceIndex = indexPath.item + (indexPath.section == 0 ? indexPath.section : (gridView?.numberOfItemsInSection(indexPath.section-1))!)
        
        let a = UIActionSheet(title: "Option", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: "Cancel")
        a.addButtonWithTitle("Edit")
        a.addButtonWithTitle("Replace")
        
        if (replaceIndex != 0)
        {
            a.addButtonWithTitle("Delete")
        }
        
        //        self.addImage()
        a.showInView(self.view)
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        println("index \(buttonIndex)")
        if (buttonIndex == 0)
        {
            replaceIndex = -1
        } else if (buttonIndex == 1) // edit
        {
            let ap = images[replaceIndex]
            ap.getImage({image in
                if let i = image
                {
                    Mixpanel.sharedInstance().track("Edit Image")
                    let u = AdobeUXImageEditorViewController(image: i)
                    u.delegate = self
                    self.presentViewController(u, animated: true, completion: nil)
                }
            })
        } else if (buttonIndex == 2) // replace
        {
            self.addImage()
        } else if (buttonIndex == 3) // delete
        {
            self.images.removeAtIndex(replaceIndex)
            replaceIndex = -1
            self.gridView?.reloadData()
        }
    }
    
    func photoEditor(editor: AdobeUXImageEditorViewController!, finishedWithImage image: UIImage!) {
        
        Mixpanel.sharedInstance().track("Edit Image Success")
        let ap = images[replaceIndex]
        ap.image = image
        ap.assetLib = nil
        
        self.gridView?.reloadData()
        
        editor.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func photoEditorCanceled(editor: AdobeUXImageEditorViewController!) {
        Mixpanel.sharedInstance().track("Edit Image Cancel")
        editor.dismissViewControllerAnimated(true, completion: nil)
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
        
        let c = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! AddProductImageCell
        c.delegate = self
        let realIndex = indexPath.item + s
        if (realIndex < images.count)
        {
            c.apImage = images[realIndex]
        } else {
            c.apImage = nil
        }
        
        c.indexPath = indexPath
        
        if (indexPath.section == 1) {
            let hint = imageHints[indexPath.item]
            
            c.captionHint.text = hint["title"]
            c.ivHint.image = UIImage(named: hint["image"]!)!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            c.captionHint.hidden = false
            c.ivHint.hidden = false
        } else {
            c.captionHint.hidden = true
            c.ivHint.hidden = true
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
    
    //    var weightSelected = false
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 5
        } else if (section == 1) {
            return 1
        } else if (section == 2) {
            return 1
        } else if (section == 3) {
            return 3
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
                let a = b as! ProductCategoryCell
                a.categoryDelegate = self
                c = a
            } else if (r == 1 || r == 2) {
                let b = createExpandableCell(tableView, indexPath: indexPath)
                c = b
            } else {
                let b = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input_2")
                c = b
            }
        } else if (s == 10) {
            if (r == 0) {
                var g = tableView.dequeueReusableCellWithIdentifier("cell_size") as! AddProductSizeCell
                g.decorate()
                println("asd")
                c = g
            } else if (r == 1) {
                let b = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
                c = b
            }
        } else if (s == 1) {
            c = tableView.dequeueReusableCellWithIdentifier("cell_ongkir") as? UITableViewCell
        } else if (s == 2) {
            if (r == 0) {
                let w = tableView.dequeueReusableCellWithIdentifier("cell_weight") as? AddProductCellWeight
                w?.weightDelegate = self
                w?.showInput(allowShowWeightInput)
                c = w
            } else if (r == 1) {
                let b = createOrGetBaseCartCell(tableView, indexPath: indexPath, id: "cell_input")
                c = b
            }
        } else if (s == 3) {
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
            acee?.textView.textColor = Theme.GrayDark
        }
        
        if (acee?.lastIndex != nil) {
            baseDatas[(acee?.lastIndex)!] = acee?.obtain()
        }
        
        acee?.adapt(baseDatas[indexPath]!)
        acee?.lastIndex = indexPath
        
        if (indexPath.row == 1) { // Nama Barang, Bold
            acee?.textView.font = UIFont.systemFontOfSize(14)
        } else {
            acee?.textView.font = UIFont.systemFontOfSize(14)
        }
        
//        acee?.textView.textColor = UIColor(hex: "#858585")
        acee?.textView.textColor = UIColor.darkGrayColor()
        
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
        h.captionTitle.text = d["title"]?.uppercaseString
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
        } else if (s == 10) {
            if (r == 0) {
                return 80
            } else {
                return 44
            }
        } else if (s == 1) {
            return 120
        } else if (s == 2) {
            if (self.allowShowWeightInput == true)
            {
                return CGFloat(AddProductCellWeight.ExtendedHeight)
            } else {
                return CGFloat(AddProductCellWeight.StandardHeight)
            }
            //            return (allowShowWeightInput == true) ? AddProductCellWeight.ExtendedHeight : AddProductCellWeight.StandardHeight
            //            if (r == 0)
            //            {
            //                return 96
            //            } else
            //            {
            //                return 44
            //            }
        } else if (s == 20) {
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
    
    var name : String?
    var desc : String?
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        if (indexPath.section == 0 && indexPath.section == 1)
        {
            name = text
        } else if (indexPath.section == 0 && indexPath.section == 2)
        {
            desc = text
        }
        baseDatas[indexPath]?.value = text
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let c = cells[indexPath]
        if ((c?.canBecomeFirstResponder())!) {
            c?.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        var parent : UIView?
        if (((textField.superview?.superview!)?.isKindOfClass(UITableViewCell.classForCoder()))! == true)
        {
            parent = textField.superview?.superview!
        } else {
            parent = textField.superview?.superview?.superview!
        }
        let i = tableView.indexPathForCell(parent as! UITableViewCell)
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
    
    func categorySelected(id: String) {
        selectedCategoryID = id
    }
    
    var allowShowWeightInput = false
    func weightSelected(index: Int) {
        allowShowWeightInput = true
        tableView.reloadRowsAtIndexPaths([], withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    var currentWeight = ""
    func weightChanged(w: Int) {
        currentWeight = String(w)
    }
    
    func weightShouldReturn(textField: UITextField) {
        self.textFieldShouldReturn(textField)
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

protocol ProductCategoryDelegate
{
    func categorySelected(id : String)
}

class ProductCategoryCell : CartCellInput2
{
    @IBOutlet var ivImage : UIImageView!
    
    var categoryDelegate : ProductCategoryDelegate?
    
    override func adapt(item: BaseCartData?) {
        super.adapt(item)
        ivImage.image = item?.image
        if let v = item?.value
        {
            captionValue?.text = v
        } else if let p = item?.placeHolder
        {
            captionValue?.text = p
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        let c = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdCategoryPicker) as! CategoryPickerViewController
        c.blockDone = { data in
            let parent = JSON(data["parent"]!)
            let children = JSON(data["child"]!)
            
            if let name = children["name"].string
            {
                self.captionValue?.text = name
            }
            
            if let d = self.categoryDelegate, let id = children["_id"].string
            {
                d.categorySelected(id)
            }
        }
        self.parent?.navigationController?.pushViewController(c, animated: true)
        
        return true
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
    
    var adjusted = false
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (adjusted == false)
        {
            collectionView.contentOffset = CGPointMake(120, 0)
            adjusted = true
        }
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
    @IBOutlet weak var lblDescription: UILabel!
    
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
            b.borderColor = Theme.GrayLight
            for l in b.subviews
            {
                if (l.isKindOfClass(UILabel.classForCoder()))
                {
                    let x = l as! UILabel
                    x.textColor = Theme.GrayLight
                }
            }
        }
        
        var c = sender.superview as! BorderedView
        for l in c.subviews
        {
            if (l.isKindOfClass(UILabel.classForCoder()))
            {
                let x = l as! UILabel
                if (x.text == "Ditanggung Pembeli") {
                    var mainTxt = "Ongkos kirim sesuai dengan tarif kurir yang tersimpan di sistem.\nLihat syarat & ketentuan"
                    var greenTxt = "Lihat syarat & ketentuan"
                    var range = (mainTxt as NSString).rangeOfString(greenTxt)
                    var attrString = NSMutableAttributedString(string: mainTxt)
                    attrString.addAttribute(NSForegroundColorAttributeName, value: Theme.navBarColor, range: range)
                    lblDescription.attributedText = attrString
                } else if (x.text == "Ditanggung Penjual") {
                    lblDescription.text = "Produk akan diberi label FREE ONGKIR (Recommended)"
                }
                x.textColor = Theme.PrimaryColorDark
            }
        }
        c.borderColor = Theme.PrimaryColorDark
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

protocol AddProductImageCellDelegate
{
    func addImage()
    func addImage(info : [String : AnyObject])
}

class AddProductImageCell : UICollectionViewCell
{
    
    @IBOutlet var ivCover : UIImageView!
    var tapImg : UITapGestureRecognizer?
    
    var delegate : AddProductImageCellDelegate?
    var indexPath = NSIndexPath(forRow: 0, inSection: 0)
    
    @IBOutlet var ivHint : TintedImageView!
    @IBOutlet var captionHint : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if (tapImg == nil)
        {
            tapImg = UITapGestureRecognizer(target: self, action: "tapped")
            ivCover.addGestureRecognizer(tapImg!)
        }
    }
    
    func tapped()
    {
        if (delegate != nil) {
            if (ivCover.image != nil)
            {
                delegate?.addImage(["replaceIndex":self.indexPath])
            } else
            {
                delegate?.addImage()
            }
        }
    }
    
    var asset : ALAssetsLibrary?
    
    private var _apImage : APImage?
    var apImage : APImage?
        {
        set {
            _apImage = newValue
            if (newValue == nil)
            {
                ivCover.image = nil
            } else
            {
                ivCover.image = ImageSourceCell.defaultImage
                
                if let i = _apImage?.image
                {
                    ivCover.image = i
                } else if ((_apImage?.usingAssets)! == true) {
                    
                    if (asset == nil) {
                        asset = ALAssetsLibrary()
                    }
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        asset?.assetForURL((_apImage?.url)!, resultBlock: { asset in
                            if let ast = asset {
                                let rep = ast.defaultRepresentation()
                                let ref = rep.fullScreenImage().takeUnretainedValue()
                                let i = UIImage(CGImage: ref)
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.ivCover.image = i
                                })
                            }
                            }, failureBlock: { error in
                                
                        })
                    })
                } else {
                    ivCover.setImageWithUrl((_apImage?.url)!, placeHolderImage: nil)
                }
            }
        }
        get {
            return _apImage
        }
    }
}

class AddProductShareCell : UITableViewCell
{
    @IBOutlet var arrayRow1 : [AddProductShareButton] = []
    @IBOutlet var arrayRow2 : [AddProductShareButton] = []
    @IBOutlet var arrayRow3 : [AddProductShareButton] = []
    @IBOutlet var arrayRow4 : [AddProductShareButton] = []
    
    var arrayRows : [[AddProductShareButton]] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if (arrayRows.count == 0)
        {
            arrayRows.append(arrayRow1)
            arrayRows.append(arrayRow2)
            arrayRows.append(arrayRow3)
            arrayRows.append(arrayRow4)
        }
    }
    
    @IBAction func setSelectShare(sender : AddProductShareButton)
    {
        let tag = sender.tag
        let arr = arrayRows[tag]
        let c = sender.active ? sender.normalColor : sender.selectedColor
        sender.active = !sender.active
        for b in arr
        {
            b.setTitleColor(c, forState: UIControlState.Normal)
        }
    }
}

class AddProductShareButton : UIButton
{
    var active : Bool = false
    
    @IBInspectable var normalColor : UIColor = Theme.PrimaryColorDark
    @IBInspectable var selectedColor : UIColor = Theme.PrimaryColorDark
}

protocol AddProductWeightDelegate
{
    func weightSelected(index : Int)
    func weightChanged(w : Int)
    func weightShouldReturn(textField : UITextField)
}

class AddProductCellWeight : UITableViewCell, UITextFieldDelegate
{
    var weightDelegate : AddProductWeightDelegate?
    
    static var StandardHeight = 96
    static var ExtendedHeight = 140
    @IBOutlet var txtWeight : UITextField!
    func showInput(show : Bool)
    {
        if (show)
        {
            txtWeight.hidden = false
        } else
        {
            txtWeight.hidden = true
        }
    }
    
    @IBOutlet var sectionWeights : Array<BorderedView> = []
    
    @IBAction func setWeight(sender : UIButton)
    {
        var index = 0
        var found = false
        for b in sectionWeights
        {
            b.changeBorderColor(Theme.GrayLight)
            
            if (b == sender.superview)
            {
                found = true
            }
            
            if (found == false)
            {
                index++
            }
        }
        
        let b = sender.superview as! BorderedView
        b.changeBorderColor(Theme.PrimaryColorDark)
        
        txtWeight.delegate = self
        txtWeight.hidden = false
        let w = 500 + (index*1000)
        
        txtWeight.text = String(w)
        
        if let d = weightDelegate
        {
            d.weightChanged(w)
            d.weightSelected(index)
            let l = self.contentView.viewWithTag(666)
            l?.hidden = false
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        var s = textField.text as NSString
        s = s.stringByReplacingCharactersInRange(range, withString: string)
        
        if let d = weightDelegate
        {
            d.weightChanged(s.integerValue)
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let d = weightDelegate
        {
            d.weightShouldReturn(txtWeight)
        }
        return false
    }
}

extension BorderedView
{
    func changeBorderColor(c : UIColor)
    {
        self.borderColor = c
        for v in self.subviews
        {
            if (v.isKindOfClass(UILabel.classForCoder()))
            {
                let l = v as! UILabel
                l.textColor = c
            }
        }
    }
}

/**
Extension to the Alamofire MultipartFormData type to support direct
construction of `multipart/form-data` parts
*/
extension MultipartFormData {
    
    func appendBodyPart(part:MultipartProtocol) {
        
        let headers = part.headers
        let bodyStream = NSInputStream(data: part.body)
        let bodyContentLength = UInt64(part.body.length)
        appendBodyPart(stream: bodyStream, length: bodyContentLength, headers: headers.headers)
    }
}

/**
Protocol that defines the behavior of `multipart/form-data` parts, allowing
extension to parts of different types, while hiding implementation details
*/
protocol MultipartProtocol {
    /// The headers used to generate a part in a `multipart/form-data` part
    var headers:MultipartHeader { get }
    
    /// The body used to generate a part in a `multipart/form-data` part
    var body:NSData! { get }
}


/**
Builds legal `multipart/form-data` parts, conforming to MultipartProtocol
*/
class Multipart {
    
    class func json(name:String, parameters:[String:AnyObject]) -> MultipartProtocol? {
        return MultipartJson(name:name, parameters: parameters) }
    
    class func plain(name:String, text:String) -> MultipartProtocol? {
        return MultipartPlain(name:name, text:text) }
    
    /**
    Constructs an `application/json` part in a `multipart/form-data` body
    */
    class MultipartJson : MultipartProtocol {
        
        init?(name:String, parameters:[String:AnyObject]) {
            
            // initialize header
            self.headers = MultipartHeader()
                .contentType(.JSON)
                .contentDisposition(.Name(name))
            
            // serialize body
            let options = NSJSONWritingOptions.allZeros
            var error:NSError?
            self.body = NSJSONSerialization.dataWithJSONObject(parameters, options: options, error: &error)
            
            if self.body == nil {
                return nil
            }
        }
        
        /// The headers used to generate an `application/json` part in a `multipart/form-data` part
        let headers:MultipartHeader
        
        /// The body used to generate an `application/json` part in a `multipart/form-data` part
        var body:NSData!
    }
    
    /**
    Constructs a `text/plain` part in a `multipart/form-data` body
    */
    class MultipartPlain : MultipartProtocol {
        
        init?(name:String, text:String) {
            
            // initialize header
            self.headers = MultipartHeader()
                .contentType(.Plain)
                .contentDisposition(.Name(name))
            
            // serialize body
            self.body = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            if self.body == nil {
                return nil
            }
        }
        
        /// The headers used to generate a `text/plain` part in a `multipart/form-data` part
        let headers:MultipartHeader
        
        /// The body used to generate a `text/plain` part in a `multipart/form-data` part
        var body:NSData!
    }
}


/**
Defines legal `MIME` type values for the `Content-Type` header of `multipart/form-data`
*/
enum Mime : String {
    case MultipartMixed = "multipart/mixed"
    case JSON = "application/json"
    case Plain = "text/plain"
}


/**
Defines legal Disposition values for the `Content-Disposition` header of `multipart/form-data`
*/
enum Disposition {
    case FormData
    case Name(String)
    case FileName(String)
    
    var encoded:String {
        switch self {
            
        case FormData:
            return "form-data"
            
        case Name(let name):
            return "name=\"\(name)\""
            
        case FileName(let name):
            return "filename=\"\(name)\""
        }
    }
}


/**
Constructs `multipart/form-data` headers via the method chaining pattern.
*/
class MultipartHeader {
    
    enum Key : String {
        case ContentType = "Content-Type"
        case ContentDisposition = "Content-Disposition"
    }
    
    /**
    Defines the `Content-Type` header and returns the instance of MultipartHeader
    upon which this call is made
    
    :param: mimeType  The desired MIME type, as defined by the Mime enumeration
    
    :returns: The instance of Multipart header upon which this call is made
    */
    func contentType(mimeType:Mime) -> MultipartHeader {
        headers[Key.ContentType.rawValue] = "\(mimeType.rawValue)"
        return self
    }
    
    
    /**
    Defines the `Content-Disposition` header with a single disposition value and
    returns the instance of MultipartHeader upon which this call is made
    
    :param: mimeType  The desired MIME type, as defined by the Disposition enumeration
    
    :returns: The instance of Multipart header upon which this call is made
    */
    func contentDisposition(disposition:Disposition) -> MultipartHeader {
        
        headers[Key.ContentDisposition.rawValue] =
            Disposition.FormData.encoded + "; " + disposition.encoded
        return self
    }
    
    /**
    Defines the Content-Disposition header with multiple disposition value and
    returns the instance of MultipartHeader upon which this call is made
    
    :param: mimeType  The desired MIME type, as defined by the Disposition enumeration
    
    :returns: The instance of Multipart header upon which this call is made
    */
    func contentDisposition(values:Disposition...) -> MultipartHeader {
        
        headers[Key.ContentDisposition.rawValue] = Disposition.FormData.encoded + "; "
            + "; ".join(map(values) { (d:Disposition) in d.encoded})
        return self
    }
    
    /// The resulting set of `multipart/form-data` headers
    var headers:[String:String] = [Key.ContentDisposition.rawValue: Disposition.FormData.encoded]
}


extension MultipartHeader : Printable {
    var description:String {
        return "Headers: \n\t"
            + "\n\t".join(map(self.headers.keys) { key in "\(key): \(self.headers[key]!)" })
    }
}
