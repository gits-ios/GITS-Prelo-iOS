//
//  PreloShareController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/2/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

struct PreloShareItem
{
    var image : UIImage?
    var text : String?
    var url : NSURL?
}

class PreloShareController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{

    static var sharer : PreloShareController = PreloShareController()
    
    static func Share(item : PreloShareItem, inView:UIView)
    {
        let s = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdPreloShare) as! PreloShareController
        s.item = item
        s.parentView = inView
        
        sharer = s
        
        sharer.show()
    }
    
    var item : PreloShareItem?
    var parentView : UIView?
    
    @IBOutlet var conGridViewBottomMargin : NSLayoutConstraint!
    @IBOutlet var gridView : UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        conGridViewBottomMargin.constant = -gridView.height
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func show()
    {
        self.view.alpha = 1
        self.view.backgroundColor = UIColor(white: 0.5, alpha: 0)
        self.view.frame = (parentView?.bounds)!
        
        conGridViewBottomMargin.constant = 0
        
        parentView?.addSubview(self.view)
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.view.backgroundColor = UIColor(white: 0.5, alpha: 0.8)
                self.gridView.layoutIfNeeded()
            }, completion: {s in
                self.gridView.dataSource = self
                self.gridView.delegate = self
        })
    }
    
    @IBAction func hide()
    {
        conGridViewBottomMargin.constant = -gridView.height
        self.gridView.dataSource = nil
        self.gridView.delegate = nil
        
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.view.backgroundColor = UIColor(white: 0.5, alpha: 0)
            self.gridView.layoutIfNeeded()
            }, completion: {s in
                if (s)
                {
                    self.view.removeFromSuperview()
                }
        })
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let s = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ShareCell
        return s
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake((UIScreen.mainScreen().bounds.width/3)-4, 84)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
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

class ShareCell : UICollectionViewCell
{
    
    @IBOutlet var captionTitle : UILabel!
    @IBOutlet var captionIcon : UILabel!
    @IBOutlet var sectionIcon : UIView!
    
    override func awakeFromNib() {
        sectionIcon.layer.cornerRadius = sectionIcon.width/2
        sectionIcon.layer.masksToBounds = true
        sectionIcon.superview?.backgroundColor = UIColor.clearColor()
    }
}
