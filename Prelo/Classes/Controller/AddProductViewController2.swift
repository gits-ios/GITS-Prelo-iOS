//
//  AddProductViewController2.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

typealias EditDoneBlock = () -> ()

class AddProductViewController2: BaseViewController, UIScrollViewDelegate, UITextViewDelegate, UIActionSheetDelegate, AdobeUXImageEditorViewControllerDelegate, UserRelatedDelegate, AKPickerViewDataSource, AKPickerViewDelegate, AddProductImageFullScreenDelegate
{

    @IBOutlet var txtName : SZTextView!
    @IBOutlet var txtDescription : SZTextView!
    var growerName : GrowingTextViewHandler?
    var growerDesc : GrowingTextViewHandler?
    
    @IBOutlet var conHeightTxtName : NSLayoutConstraint!
    @IBOutlet var conHeightTxtDesc : NSLayoutConstraint!
    @IBOutlet var conHeightWeightView : NSLayoutConstraint!
    @IBOutlet var conHeightSize : NSLayoutConstraint!
    
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var imageViews : [UIImageView] = []
    @IBOutlet var weightViews : [BorderedView] = []
    @IBOutlet var ongkirViews : [BorderedView] = []
    
    @IBOutlet var txtOldPrice : UITextField!
    @IBOutlet var txtNewPrice : UITextField!
    @IBOutlet var txtWeight : UITextField!
    
    @IBOutlet var captionKondisi : UILabel!
    @IBOutlet var captionMerek : UILabel!
    @IBOutlet var captionKategori : UILabel!
    
    @IBOutlet var btnSubmit : UIButton!
    
    @IBOutlet var sizePicker : AKPickerView!
    @IBOutlet var txtSize : UITextField!
    
    @IBOutlet var captionSize1 : UILabel!
    @IBOutlet var captionSize2 : UILabel!
    @IBOutlet var captionSize3 : UILabel!
    
    var sizes : Array<String> = []
    
    var productCategoryId = ""
    var kodindisiId = ""
    var merekId = ""
    var freeOngkir = 0
    
    var editProduct : ProductDetail?
    var editMode = false
    var editDoneBlock : EditDoneBlock = {}
    var images : [AnyObject] = [NSNull(), NSNull(), NSNull(), NSNull(), NSNull()]
    var rm_image1 = 0
    var rm_image2 = 0
    var rm_image3 = 0
    var rm_image4 = 0
    var rm_image5 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        sizes = ["8\nS\n10", "8\nS\n10", "8\nS\n10", "8\nS\n10", "8\nS\n10", "8\nS\n10", "8\nS\n10"]
        conHeightSize.constant = 0
        sizePicker.superview?.hidden = true
        
        sizePicker.dataSource = self
        sizePicker.delegate = self
        
        sizePicker.font = UIFont.systemFontOfSize(16)
        sizePicker.highlightedFont = UIFont(name: "HelveticaNeue-Light", size: 16)
        sizePicker.interitemSpacing = 20
        sizePicker.fisheyeFactor = 0.001
        sizePicker.pickerViewStyle = AKPickerViewStyle.Style3D
        sizePicker.maskDisabled = false
        
        txtWeight.hidden = true
        
        txtName.placeholder = "Nama Produk"
        txtDescription.placeholder = "Deskripsi"
        
        txtName.fadeTime = 0.2
        txtDescription.fadeTime = 0.2
        
        growerName = GrowingTextViewHandler(textView: txtName, withHeightConstraint: conHeightTxtName)
        growerName?.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 4)
        
        growerDesc = GrowingTextViewHandler(textView: txtDescription, withHeightConstraint: conHeightTxtDesc)
        growerDesc?.updateMinimumNumberOfLines(1, andMaximumNumberOfLine: 100)
        
        selectWeight(nil)
        selectOngkir(nil)
        
        var index = 0
        for i in imageViews
        {
            i.tag = index
            i.contentMode = UIViewContentMode.ScaleAspectFill
            i.clipsToBounds = true
            index++
            i.userInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: "imageTapped:")
            i.addGestureRecognizer(tap)
        }
        
        if (editMode)
        {
            self.title = "Edit Product"
            self.btnSubmit.setTitle("Simpan", forState: UIControlState.Normal)
            
            txtName.text = editProduct?.name
            txtDescription.text = editProduct?.json["_data"]["description"].string
            if let weight = editProduct?.json["_data"]["weight"].int
            {
                txtWeight.text = String(weight)
                txtWeight.hidden = false
                conHeightWeightView.constant = 158
                var index = 0
                if (weight >= 1000 && weight < 2000)
                {
                    index = 1
                } else if (weight >= 2000)
                {
                    index = 2
                }
                
                selectWeightByIndex(index, overrideWeight: false)
            }
            
            if let ongkir = editProduct?.json["_data"]["free_ongkir"].int
            {
                let index = (ongkir == 1) ? 0 : 1
                selectOngkirByIndex(index)
            }
            
            if let oldPrice = editProduct?.json["_data"]["price_original"].int
            {
                txtOldPrice.text = String(oldPrice)
            }
            
            if let oldPrice = editProduct?.json["_data"]["price"].int
            {
                txtNewPrice.text = String(oldPrice)
            }
            
            if let category_breadcrumbs = editProduct?.json["_data"]["category_breadcrumbs"].array
            {
                for i in 0...category_breadcrumbs.count-1
                {
                    let c = category_breadcrumbs[i]
                    productCategoryId = c["_id"].string!
                    captionKategori.text = c["name"].string!
                }
            }
            
            if let kondisi = editProduct?.json["_data"]["condition"].string, let kondisiId = editProduct?.json["_data"]["product_condition_id"].string
            {
                kodindisiId = kondisiId
                captionKondisi.text = kondisi
            }
            
            if let kondisi = editProduct?.json["_data"]["brand"].string, let kondisiId = editProduct?.json["_data"]["brand_id"].string
            {
                merekId = kondisiId
                captionMerek.text = kondisi
            }
            
            if let arr = editProduct?.json["_data"]["original_picts"].arrayObject
            {
                for i in 0...arr.count-1
                {
                    let o = arr[i]
                    if let s = o as? String
                    {
                        imageViews[i].setImageWithUrl(NSURL(string: s)!, placeHolderImage: UIImage(named: "raisa.jpg"))
                    }
                }
            }
            
        } else
        {
            self.title = "Add Product"
            self.btnSubmit.setTitle("Submit", forState: UIControlState.Normal)
        }
        
        self.btnSubmit.addTarget(self, action: "sendProduct", forControlEvents: UIControlEvents.TouchUpInside)
        self.btnSubmit.setTitle("Loading..", forState: UIControlState.Disabled)
    }
    
    var notPicked = true
    var allowLaunchLogin = true
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.an_subscribeKeyboardWithAnimations({ f, t, o in
            
            if (o)
            {
                self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, f.height, 0)
                println("an_subscribeKeyboardWithAnimations")
                
            } else
            {
                self.scrollView.contentInset = UIEdgeInsetsZero
            }
            
            }, completion: {f in
                if let a = self.activeTextview
                {
                    let f = self.scrollView.convertRect(a.frame, fromView: a)
                    self.scrollView.scrollRectToVisible(f, animated: true)
                }
        })
        
        if (User.IsLoggedIn == false)
        {
            if (allowLaunchLogin)
            {
                LoginViewController.Show(self, userRelatedDelegate: self, animated: true)
            }
        } else if (notPicked && editMode == false)
        {
            notPicked = false
            self.pickImage(0, forceBackOnCancel: true, directToCamera : true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.an_unsubscribeKeyboard()
    }
    
    @IBAction func showFAQ(sender : UIView?)
    {
        let w = self.storyboard?.instantiateViewControllerWithIdentifier("preloweb") as! PreloWebViewController
        w.url = "http://prelo.id/syarat-ketentuan"
        w.titleString = "Syarat & Ketentuan"
        let n = BaseNavigationController()
        n.setViewControllers([w], animated: false)
        self.presentViewController(n, animated: true, completion: nil)
    }
    
    func numberOfItemsInPickerView(pickerView: AKPickerView!) -> Int {
        return sizes.count
    }
    
    func pickerView(pickerView: AKPickerView!, titleForItem item: Int) -> String! {
        return sizes[item]
    }
    
    func pickerView(pickerView: AKPickerView!, didSelectItem item: Int) {
        let s = sizes[item]
        txtSize.text = s.stringByReplacingOccurrencesOfString("\n", withString: "/")
    }
    
    func userLoggedIn() {
        
    }
    
    func userCancelLogin() {
        allowLaunchLogin = false
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func imageTapped(sender : UITapGestureRecognizer)
    {
        let index = sender.view!.tag
     
        if (imageViews[index].image == nil)
        {
            self.pickImage(index, forceBackOnCancel: false)
        } else {
            let a = self.storyboard?.instantiateViewControllerWithIdentifier("AddProductFullscreen") as! AddProductImageFullScreen
            a.index = index
            let ap = APImage()
            ap.image = imageViews[index].image
            a.apImage = ap
            if (index == 0)
            {
                a.disableDelete = true
            }
            a.fullScreenDelegate = self
            let n = BaseNavigationController()
            n.setViewControllers([a], animated: false)
            self.presentViewController(n, animated: true, completion: nil)
            
//            let a = UIActionSheet(title: "Option", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: "Cancel")
//            a.addButtonWithTitle("Edit")
//            a.addButtonWithTitle("Ganti")
//            
//            if (index != 0)
//            {
//                a.addButtonWithTitle("Hapus")
//            }
//            a.tag = index
//            a.showInView(self.view)
        }
    }
    
    func imageFullScreenDidDelete(controller: AddProductImageFullScreen) {
        self.imageViews[controller.index].image = nil
        switch (controller.index)
        {
        case 0:rm_image1 = 1
        case 1:rm_image2 = 1
        case 2:rm_image3 = 1
        case 3:rm_image4 = 1
        case 4:rm_image5 = 1
        default:println("")
        }
    }
    
    func imageFullScreenDidReplace(controller: AddProductImageFullScreen, image: APImage) {
        imageViews[controller.index].image = image.image
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == 1)
        {
            AdobeImageEditorCustomization.setToolOrder([kAdobeImageEditorCrop, kAdobeImageEditorOrientation])
            AdobeImageEditorCustomization.setLeftNavigationBarButtonTitle("")
            let u = AdobeUXImageEditorViewController(image: imageViews[actionSheet.tag].image)
            u.delegate = self
            self.presentViewController(u, animated: true, completion: nil)
        } else if (buttonIndex == 2)
        {
            self.pickImage(actionSheet.tag, forceBackOnCancel: false)
        } else if (buttonIndex == 3)
        {
            self.imageViews[actionSheet.tag].image = nil
            switch (actionSheet.tag)
            {
            case 0:rm_image1 = 1
            case 1:rm_image2 = 1
            case 2:rm_image3 = 1
            case 3:rm_image4 = 1
            case 4:rm_image5 = 1
            default:println("")
            }
        }
    }
    
    func photoEditor(editor: AdobeUXImageEditorViewController!, finishedWithImage image: UIImage!) {
        imageViews[editor.view.tag].image = image
        editor.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func photoEditorCanceled(editor: AdobeUXImageEditorViewController!) {
        editor.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func pickImage(index : Int, forceBackOnCancel : Bool, directToCamera : Bool = false)
    {
        ImagePickerViewController.ShowFrom(self, maxSelect: 1, useAviary:true, diretToCamera : directToCamera, doneBlock: { imgs in
            if (imgs.count > 0)
            {
                let a = imgs[0]
                a.getImage({ img in
                    if let i = img
                    {
                        self.imageViews[index].image = i
                        self.images[index] = i
                    }
                })
                
                switch (index)
                {
                case 0:self.rm_image1=0
                case 1:self.rm_image2=0
                case 2:self.rm_image3=0
                case 3:self.rm_image4=0
                case 4:self.rm_image5=0
                default:println()
                }
                
            } else if (forceBackOnCancel)
            {
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
    }
    
    var activeTextview : UITextView?
    func textViewDidBeginEditing(textView: UITextView) {
        println("textViewDidBeginEditing")
        activeTextview = textView
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        activeTextview = nil
    }
    
    func textViewDidChange(textView: UITextView) {
        growerName?.resizeTextViewWithAnimation(false)
        growerDesc?.resizeTextViewWithAnimation(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    @IBAction func selectWeight(sender : UIButton?)
    {
        for w in weightViews
        {
            self.highlightWeightView(false, weightView: w)
        }
        
        if let b = sender
        {
            let w = weightViews[b.tag]
            self.highlightWeightView(true, weightView: w)
            
            if (txtWeight.hidden)
            {
                txtWeight.hidden = false
                conHeightWeightView.constant = 158
                UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    self.txtWeight.superview?.layoutIfNeeded()
                    }, completion: nil)
            }
            
            let berat = 500 + (b.tag * 1000)
            txtWeight.text = String(berat)
        }
    }
    
    func selectWeightByIndex(index : Int, overrideWeight : Bool)
    {
        let w = weightViews[index]
        self.highlightWeightView(true, weightView: w)
        
        if (txtWeight.hidden)
        {
            txtWeight.hidden = false
            conHeightWeightView.constant = 158
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.txtWeight.superview?.layoutIfNeeded()
                }, completion: nil)
        }
        
        if (overrideWeight)
        {
            let berat = 500 + (index * 1000)
            txtWeight.text = String(berat)
        }
    }
    
    @IBAction func selectOngkir(sender : UIButton?)
    {
        for o in ongkirViews
        {
            self.highlightWeightView(false, weightView: o)
        }
        
        if let b = sender
        {
            let o = ongkirViews[b.tag]
            self.highlightWeightView(true, weightView: o)
            if (b.tag == 0) {
                freeOngkir = 1
            } else
            {
                freeOngkir = 0
            }
        }
    }
    
    func selectOngkirByIndex(index : Int)
    {
        let o = ongkirViews[index]
        self.highlightWeightView(true, weightView: o)
    }
    
    func highlightWeightView(highlight : Bool, weightView : BorderedView)
    {
        let c = highlight ? Theme.PrimaryColorDark : Theme.GrayLight
        weightView.borderColor = c
        
        for v in weightView.subviews
        {
            if (v.isKindOfClass(UILabel.classForCoder()))
            {
                let l = v as! UILabel
                l.textColor = c
            } else if (v.isKindOfClass(TintedImageView.classForCoder()))
            {
                let t = v as! TintedImageView
                t.tintColor = c
            }
        }
    }
    
    @IBAction func pickKategori(sender : UIButton)
    {
        let p = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdCategoryPicker) as! CategoryPickerViewController
        p.blockDone = { data in
            let children = JSON(data["child"]!)
            
            if let name = children["name"].string
            {
                self.captionKategori.text = name
            }
            
            if let id = children["_id"].string
            {
                self.productCategoryId = id
            }
            
            self.getSizes()
        }
        self.navigationController?.pushViewController(p, animated: true)
    }
    
    func getSizes()
    {
        request(References.BrandAndSizeByCategory(category: self.productCategoryId)).responseJSON {req, resp, res, err in
            println(res)
            if let x: AnyObject = res
            {
                let json = JSON(x)
                let jsizes = json["_data"]["sizes"]
                if let arr = jsizes["size_types"].array
                {
                    self.captionSize1.text = ""
                    self.captionSize2.text = ""
                    self.captionSize3.text = ""
                    var sml : Array<String> = []
                    var usa : Array<String> = []
                    var eur : Array<String> = []
                    for i in 0...arr.count-1
                    {
                        let d = arr[i]
                        let name = d["name"].string!
                        if let strings = d["sizes"].arrayObject
                        {
                            for c in 0...strings.count-1
                            {
                                if (i == 0)
                                {
                                    self.captionSize1.text = name
                                    sml.append(strings[c] as! String)
                                }
                                
                                if (i == 1)
                                {
                                    self.captionSize2.text = name
                                    usa.append(strings[c] as! String)
                                }
                                
                                if (i == 2)
                                {
                                    self.captionSize3.text = name
                                    eur.append(strings[c] as! String)
                                }
                            }
                        }
                        
                    }
                    
                    self.sizes = []
                    for i in 0...sml.count-1
                    {
                        self.sizes.append(usa[i] + "\n" + ((sml.count > 0) ? sml[i] : "") + "\n" + ((eur.count > 0) ? eur[i] : ""))
                    }
                    
                    if (self.sizes.count > 0)
                    {
//                        self.sizePicker.selectItem(0, animated: false)
                        self.sizePicker.collectionView.reloadData()
                        self.sizePicker.selectItem(0, animated: false)
                        self.conHeightSize.constant = 146
                        self.sizePicker.superview?.hidden = false
                    } else
                    {
                        self.conHeightSize.constant = 0
                        self.sizePicker.superview?.hidden = true
                    }
                }
            } else
            {
                self.conHeightSize.constant = 0
                self.sizePicker.superview?.hidden = true
            }
            
        }
    }
    
    @IBAction func pickKondisi(sender : UIButton)
    {
        let p = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdPicker) as! PickerViewController
        p.prepDataBlock = { picker in
            
            picker.textTitle = "Pilih Kondisi"
            
            let s = NSBundle.mainBundle().URLForResource("merk", withExtension: "json")?.absoluteString
            if let url = s
            {
                request(Method.GET, url, parameters: nil, encoding: ParameterEncoding.URL, headers: nil).responseJSON{_, resp, res, err in
                    if (APIPrelo.validate(true, err: err, resp: resp))
                    {
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
                            self.kodindisiId = PickerViewController.RevealHiddenString(s)
                            self.captionKondisi.text = PickerViewController.HideHiddenString(s)
                        }
                        
                        picker.items = items
                        picker.tableView.reloadData()
                        picker.doneLoading()
                    } else {
                        
                    }
                }
            }
        }
        self.navigationController?.pushViewController(p, animated: true)
    }
    
    @IBAction func pickMerek(sender : UIButton)
    {
        let s = NSBundle.mainBundle().URLForResource("merk", withExtension: "json")?.absoluteString
        if let url = s
        {
            let p = self.storyboard?.instantiateViewControllerWithIdentifier(Tags.StoryBoardIdPicker) as! PickerViewController
            p.merkMode = true
            p.prepDataBlock = { picker in
                picker.textTitle = "Pilih Merek"
                request(Method.GET, url, parameters: nil, encoding: ParameterEncoding.URL, headers: nil).responseJSON{_, resp, res, err in
                    if (APIPrelo.validate(true, err: err, resp: resp))
                    {
                        let json = JSON(res!)
                        let brands = json["brands"]["_data"].array
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
                            self.merekId = PickerViewController.RevealHiddenString(s)
                            var x : String = PickerViewController.HideHiddenString(s)
                            x = x.stringByReplacingOccurrencesOfString("Tambahkan merek '", withString: "")
                            x = x.stringByReplacingOccurrencesOfString("'", withString: "")
                            self.captionMerek.text = x
                        }
                        
                        picker.items = items
                        picker.tableView.reloadData()
                        picker.doneLoading()
                        picker.showSearch = true
                    } else {
                        
                    }
                }
            }
            self.navigationController?.pushViewController(p, animated: true)
        }
    }
    
    func sendProduct()
    {
        let name = txtName.text
        let desc = txtDescription.text
        let weight = txtWeight.text
        let oldPrice = txtOldPrice.text
        let newPrice = txtNewPrice.text
        
        var imgs : [AnyObject] = []
        for v in imageViews
        {
            if let i = v.image
            {
                imgs.append(i)
            } else
            {
                imgs.append(NSNull())
            }
        }
        
        //validasi
        if (validateString(name, message: "Nama produk masih kosong") == false)
        {
            return
        }
        
        if (validateString(desc, message: "Deskripsi produk masih kosong") == false)
        {
            return
        }
        
        if (validateString(weight, message: "Berat produk masih kosong") == false)
        {
            return
        }
        
        if (validateString(oldPrice, message: "Harga Beli produk masih kosong") == false)
        {
            return
        }
        
        if (validateString(newPrice, message: "Harga Jual produk masih kosong") == false)
        {
            return
        }
        
        if (validateString(productCategoryId, message: "Silahkan pilih kategori produk") == false)
        {
            return
        }
        
        if (validateString(kodindisiId, message: "Silahkan pilih kondisi produk") == false)
        {
            return
        }
        
        if (validateString(merekId, message: "") == false && captionMerek.text == "")
        {
            UIAlertView.SimpleShow("Perhatian", message: "Silahkan pilih merek produk")
            return
        }
        
        if (conHeightSize.constant != 0 && txtSize.text == "")
        {
            UIAlertView.SimpleShow("Perhatian", message: "Silahkan pilih ukuran")
        }
        
        self.btnSubmit.enabled = false
        
        var param = ["name":name,
            "description":desc,
            "category_id":productCategoryId,
            "price":newPrice,
            "price_original":oldPrice,
            "weight":weight,
            "free_ongkir":String(freeOngkir),
            "product_condition_id":kodindisiId,
            "brand_id":merekId,
            "size":txtSize.text]
        
        if (merekId == "")
        {
            param.removeValueForKey("brand_id")
            param["proposed_brand"] = captionMerek.text
        }
        
        var url = "http://dev.prelo.id/api/product"
        
        if (editMode)
        {
            param["rm_image1"] = String(rm_image1)
            param["rm_image2"] = String(rm_image2)
            param["rm_image3"] = String(rm_image3)
            param["rm_image4"] = String(rm_image4)
            param["rm_image5"] = String(rm_image5)
            url = url + "/" + (editProduct?.productID)!
        } else
        {
            
        }
        
        func printFullname(name : String)
        {
            
        }
        
        AppToolsObjC.sendMultipart(param, images: images, withToken: User.Token!, to:url, success: {op, res in
            println(res)
            
            if (self.editMode)
            {
                Mixpanel.sharedInstance().track("Editing Product", properties: ["success":"1"])
                self.editDoneBlock()
                self.navigationController?.popViewControllerAnimated(true)
                return
            }
            
            Mixpanel.sharedInstance().track("Adding Product", properties: ["success":"1"])
            let json = JSON(res!)
            let s = self.storyboard?.instantiateViewControllerWithIdentifier("share") as! AddProductShareViewController
            if let price = json["_data"]["price"].int
            {
                s.basePrice = price
            }
            s.productID = (json["_data"]["_id"].string)!
            NSNotificationCenter.defaultCenter().postNotificationName("refreshHome", object: nil)
            self.navigationController?.pushViewController(s, animated: true)
            }, failure: {op, err in
                Mixpanel.sharedInstance().track("Adding Product", properties: ["success":"0"])
                self.navigationItem.rightBarButtonItem = self.confirmButton.toBarButton()
                self.btnSubmit.enabled = true
                UIAlertView.SimpleShow("Warning", message: "Gagal")
        })
    }
    
    func validateString(text : String, message : String) -> Bool
    {
        if (text == "")
        {
            if (message != "")
            {
                UIAlertView.SimpleShow("Perhatian", message: message)
            }
            return false
        }
        return true
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
