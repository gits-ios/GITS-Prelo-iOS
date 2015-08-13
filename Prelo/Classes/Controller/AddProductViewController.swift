//
//  AddProductViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/11/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class AddProductViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet var gridView : UICollectionView?
    @IBOutlet var sectionHeader : UIView?
    
    var s1 : CGSize = CGSizeZero
    var s2 : CGSize = CGSizeZero
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        sectionHeader?.width = UIScreen.mainScreen().bounds.width
        sectionHeader?.height = UIScreen.mainScreen().bounds.width * 3 / 4
        
        s1 = CGSizeMake((UIScreen.mainScreen().bounds.width-2)/2, (sectionHeader?.height)!)
        s2 = CGSizeMake((s1.width)/2, (s1.height-2)/2)
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
    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
//        return UIEdgeInsetsZero
//    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
