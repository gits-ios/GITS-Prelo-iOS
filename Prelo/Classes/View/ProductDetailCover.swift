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
    
    var imageURLS : Array<String> = []
    var largeImageURLS : Array<String> = []
    var labels : [String] = []
    
    var status : Int?
    
    var banner : UIImageView?
    
    var topBannerText : String?
    
    var isFeaturedProduct : Bool = false
    
    private func setup(images : Array<String>)
    {
        imageURLS = images
        for i in 0...images.count
        {
            if (i >= imageViews!.count)
            {
                break
            }
            var iv : UIImageView?
            
            for v in self.subviews
            {
                if v is UIImageView
                {
                    if (i == v.tag)
                    {
                        iv = v as? UIImageView
                        break
                    }
                }
            }
            
            print("Cover TAG : " + String(iv!.tag))
            iv?.tag = i
            iv?.userInteractionEnabled = true
            iv?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProductDetailCover.tapped(_:))))
            iv?.setImageWithUrl(NSURL(string: images.objectAtCircleIndex(i))!, placeHolderImage: nil)
        }
        
        self.setupTopBanner()
        self.setupBanner()
    }
    
    func setupTopBanner() {
        if let tbText = self.topBannerText {
            if (status != nil && !tbText.isEmpty) {
                let screenSize: CGRect = UIScreen.mainScreen().bounds
                let screenWidth = screenSize.width
                let topBannerHeight : CGFloat = 30.0
                let topLabelMargin : CGFloat = 8.0
                let topBanner : UIView = UIView(frame: CGRectMake(0, 0, screenWidth, topBannerHeight), backgroundColor: Theme.ThemeOrange)
                let topLabel : UILabel = UILabel(frame: CGRectMake(topLabelMargin, 0, screenWidth - (topLabelMargin * 2), topBannerHeight))
                topLabel.textColor = UIColor.whiteColor()
                topLabel.font = UIFont.systemFontOfSize(11)
                topLabel.lineBreakMode = .ByWordWrapping
                topLabel.numberOfLines = 0
                topBanner.addSubview(topLabel)
                if (status == 5) {
                    topLabel.text = tbText
                    self.addSubview(topBanner)
                }
            }
        }
    }
    
    func updateStatus(newStat : Int) {
        self.status = newStat
        self.setupBanner()
    }
    
    func setupBanner() {
        if (status != nil) {
            let screenSize: CGRect = UIScreen.mainScreen().bounds
            let screenWidth = screenSize.width
            if (status == 2) { // under review
                banner = UIImageView(image: UIImage(named: "banner_review.png"))
                if (banner != nil) {
                    banner!.frame = CGRect(x: screenWidth - 150, y: 0, width: 150, height: 149)
                    self.addSubview(banner!)
                }
            } else if (status == 4) { // sold
                self.addSoldBanner()
            } else if (status == 7) { // reserved
                banner = UIImageView(image: UIImage(named: "banner_reserved.png"))
                if (banner != nil) {
                    banner!.frame = CGRect(x: screenWidth - 150, y: 0, width: 150, height: 150)
                    self.addSubview(banner!)
                }
            } else if (isFeaturedProduct) {
                banner = UIImageView(image: UIImage(named: "banner_featured.png"))
                if (banner != nil) {
                    banner!.frame = CGRect(x: screenWidth - 150, y: 0, width: 150, height: 150)
                    self.addSubview(banner!)
                }
            } else {
                banner?.removeFromSuperview()
            }
        }
    }
    
    func addSoldBanner() {
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        banner = UIImageView(image: UIImage(named: "banner_sold.png"))
        if (banner != nil) {
            banner!.frame = CGRect(x: screenWidth - 150, y: 0, width: 150, height: 148)
            self.addSubview(banner!)
        }
    }
    
    func tapped(sender : UITapGestureRecognizer)
    {
        let index = (sender.view?.tag)!
        let c = CoverZoomController()
        c.labels = self.labels
        c.images = largeImageURLS
        c.index = index
        self.parent?.presentViewController(c, animated: true, completion: nil)
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    class func instance(images : Array<String>, status: Int, topBannerText : String?)->ProductDetailCover?
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
            p = NSBundle.mainBundle().loadNibNamed("ProductDetailCover", owner: nil, options: nil).objectAtCircleIndex(4) as? ProductDetailCover
        }
        
        p?.status = status
        
        p?.topBannerText = topBannerText
        
        p?.setup(images)
        
        return p
    }

}

class CoverZoomController : BaseViewController, UIScrollViewDelegate
{
    var scrollView : UIScrollView?
    var label : UILabel?
    
    var images : Array<String> = []
    var index = 0
    
    var labels : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blackColor()
        
        scrollView = UIScrollView(frame: UIScreen.mainScreen().bounds)
        scrollView?.pagingEnabled = true
        scrollView?.backgroundColor = UIColor.blackColor()
        
        self.view.addSubview(scrollView!)
        
        let b = self.dismissButton
        b.y = 20
        b.x = 16
        b.setTitleColor(Theme.PrimaryColor, forState: UIControlState.Normal)
        self.view.addSubview(b)
        
        var x : CGFloat = 0
        for i in images
        {
            let s = UIScrollView(frame : (scrollView?.bounds)!)
            let iv = UIImageView(frame : s.bounds)
            iv.contentMode = UIViewContentMode.ScaleAspectFit
            iv.setImageWithUrl(NSURL(string: i)!, placeHolderImage: nil)
            iv.tag = 1
            s.addSubview(iv)
            s.x = x
            scrollView?.addSubview(s)
            
            s.minimumZoomScale = 1
            s.maximumZoomScale = 3
            s.delegate = self
            
            x += s.width
        }
        
        scrollView?.contentSize = CGSizeMake(x, (scrollView?.height)!)
        scrollView?.hidden = true
        
        label = UILabel(frame: CGRectZero)
        label?.backgroundColor = Theme.PrimaryColorDark
        label?.textColor = .whiteColor()
        label?.font = UIFont.systemFontOfSize(14)
        label?.textAlignment = .Center
        
        self.view.addSubview(label!)
        
        label?.text = "Some Text"
        if let t = labels.first
        {
            label?.text = t
        }
        rearrangeLabel()
        label?.autoresizingMask = [.FlexibleLeftMargin, .FlexibleTopMargin]
        
        scrollView?.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        scrollView?.contentOffset = CGPoint(x: index*Int((scrollView?.width)!), y: 0)
        scrollView?.hidden = false
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        if (scrollView == self.scrollView)
        {
            return nil
        }
        return scrollView.viewWithTag(1)!
    }
    
    func rearrangeLabel()
    {
        label?.sizeToFit()
        var f = label!.frame
        f.size.width += 16;
        f.size.height += 8;
        f.origin.x = UIScreen.mainScreen().bounds.width - (f.size.width + 16)
        f.origin.y = UIScreen.mainScreen().bounds.height - (f.size.height + 16)
        label?.frame = f
    }
    
    var currentPage = 0
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView == self.scrollView)
        {
            var p : CGFloat = 0
            if (scrollView.bounds.width > 0) {
                p = scrollView.contentOffset.x / scrollView.bounds.width
            }
            if (currentPage != Int(p))
            {
                currentPage = Int(p)
                var text = ""
                if (Int(p) < labels.count)
                {
                    text = labels[Int(p)]
                }
                label?.text = text
                rearrangeLabel()
            }
        }
    }
}
