//
//  ProductDetailCover.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/28/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class ProductDetailCover: UIView {

    @IBOutlet var imageViews : Array<UIImageView>?
    
    var parent : UIViewController?
    
    private func setup(images : Array<String>)
    {
        for i in 0...images.count
        {
            let iv = imageViews?.objectAtCircleIndex(i)
            iv?.tag = i
            iv?.userInteractionEnabled = true
            iv?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapped:"))
            iv?.setImageWithUrl(NSURL(string: images.objectAtCircleIndex(i))!, placeHolderImage: nil)
        }
    }
    
    func tapped(sender : UITapGestureRecognizer)
    {
        let index = (sender.view?.tag)!
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    class func instance(images : Array<String>)->ProductDetailCover?
    {
        var p : ProductDetailCover?
        if (images.count == 1) {
            p = NSBundle.mainBundle().loadNibNamed("ProductDetailCover", owner: nil, options: nil).objectAtCircleIndex(0) as? ProductDetailCover
        } else if (images.count == 2) {
            p = NSBundle.mainBundle().loadNibNamed("ProductDetailCover", owner: nil, options: nil).objectAtCircleIndex(1) as? ProductDetailCover
        } else if (images.count == 3) {
            p = NSBundle.mainBundle().loadNibNamed("ProductDetailCover", owner: nil, options: nil).objectAtCircleIndex(2) as? ProductDetailCover
        } else if (images.count == 4) {
            p = NSBundle.mainBundle().loadNibNamed("ProductDetailCover", owner: nil, options: nil).objectAtCircleIndex(3) as? ProductDetailCover
        } else if (images.count >= 5) {
            p = NSBundle.mainBundle().loadNibNamed("ProductDetailCover", owner: nil, options: nil).objectAtCircleIndex(2) as? ProductDetailCover
        }
        
        p?.setup(images)
        
        return p
    }

}

class CoverZoomController : BaseViewController, UIScrollViewDelegate
{
    var scrollView : UIScrollView?
    
    var images : Array<UIImage> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView(frame: UIScreen.mainScreen().bounds)
        scrollView?.pagingEnabled = true
        
        self.view.addSubview(scrollView!)
        
        let b = self.dismissButton
        b.y = 20
        b.x = 16
        self.view.addSubview(b)
        
        var x : CGFloat = 0
        for i in images
        {
            let s = UIScrollView(frame : (scrollView?.bounds)!)
            let iv = UIImageView(frame : s.bounds)
            iv.contentMode = UIViewContentMode.ScaleAspectFit
            iv.image = i
            iv.tag = 1
            s.addSubview(iv)
            s.x = x
            scrollView?.addSubview(s)
            
            s.minimumZoomScale = 1
            s.maximumZoomScale = 3
            
            x += s.width
        }
        
        scrollView?.contentSize = CGSizeMake(x, (scrollView?.height)!)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return scrollView.viewWithTag(1)!
    }
}
