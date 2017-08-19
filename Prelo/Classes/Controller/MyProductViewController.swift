//
//  MyProductViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/24/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

// MARK: - NewShopHeader Protocol

protocol MyProductDelegate: class {
    func setFromDraftOrNew(_ isFromDraft: Bool)
    func getFromDraftOrNew() -> Bool
}

class MyProductViewController: BaseViewController, CarbonTabSwipeDelegate, MyProductDelegate {
    
    var tabSwipe : CarbonTabSwipeNavigation?
    
    var productSell : MyProductSellViewController?
    var productTransaction : MyProductTransactionViewController?

    @IBOutlet weak var viewJualButton: UIView!
    
    var isFromDraft = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productSell = self.storyboard?.instantiateViewController(withIdentifier: Tags.StoryBoardIdMyProductSell) as? MyProductSellViewController
        productSell?.previousController = self
        productSell?.delegate = self
        
        productTransaction = Bundle.main.loadNibNamed(Tags.XibNameMyProductTransaction, owner: nil, options: nil)?.first as? MyProductTransactionViewController
        
        // Do any additional setup after loading the view.
        tabSwipe = CarbonTabSwipeNavigation().create(withRootViewController: self, tabNames: ["BARANG" as AnyObject, "TRANSAKSI" as AnyObject] as [AnyObject], tintColor: UIColor.white, delegate: self)
        tabSwipe?.addShadow()
        
        tabSwipe?.setNormalColor(Theme.TabNormalColor)
        tabSwipe?.colorIndicator = Theme.PrimaryColorDark
        tabSwipe?.setSelectedColor(Theme.TabSelectedColor)
        
        // Set title
        self.title = "Jualan Saya"
        
        // Buat tombol jual menjadi bentuk bulat dan selalu di depan
        viewJualButton.layer.cornerRadius = (viewJualButton.frame.size.width) / 2
        viewJualButton.layer.shadowColor = UIColor.black.cgColor
        viewJualButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        viewJualButton.layer.shadowOpacity = 0.3
        self.view.bringSubview(toFront: viewJualButton)
        
        // swipe gesture for carbon (pop view)
        let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
        vwLeft.backgroundColor = UIColor.clear
        self.view.addSubview(vwLeft)
        self.view.bringSubview(toFront: vwLeft)
    }
    
    var first = true
    
    var shouldSkipBack = true
    
    override func viewDidAppear(_ animated: Bool) {
        if first && shouldSkipBack
        {
            first = false
            super.viewDidAppear(animated)
            var m = self.navigationController?.viewControllers
            m?.remove(at: (m?.count)!-2)
            m?.remove(at: (m?.count)!-2)
            self.navigationController?.viewControllers = m!
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var cs = [UIColor.blue, UIColor.red]
    func tabSwipeNavigation(_ tabSwipe: CarbonTabSwipeNavigation!, viewControllerAt index: UInt) -> UIViewController!
    {
        if (index == 0)
        {
            return productSell
        }
        else if (index == 1)
        {
            return productTransaction
        }
        
        let v = UIViewController()
        v.view.backgroundColor = cs.objectAtCircleIndex(Int(index))
        return v
    }
    
    @IBAction func jualPressed(_ sender: AnyObject) {
        self.isFromDraft = true
        
        /*
        let add = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdAddProduct2) as! AddProductViewController2
        add.screenBeforeAddProduct = PageName.MyProducts
        self.navigationController?.pushViewController(add, animated: true)
        */
        
        let addProduct3VC = Bundle.main.loadNibNamed(Tags.XibNameAddProduct3, owner: nil, options: nil)?.first as! AddProductViewController3
        addProduct3VC.screenBeforeAddProduct = PageName.MyProducts
        self.navigationController?.pushViewController(addProduct3VC, animated: true)
    }
    
    // MARK: - Delegate
    func setFromDraftOrNew(_ isFromDraft: Bool) {
        self.isFromDraft = isFromDraft
    }
    
    func getFromDraftOrNew() -> Bool {
        return self.isFromDraft
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
