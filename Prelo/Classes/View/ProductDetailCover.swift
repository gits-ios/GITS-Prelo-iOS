//
//  ProductDetailCover.swift
//  Prelo
//
//  Created by Rahadian Kumang on 7/28/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
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
    
    var isFakeApprove : Bool = false
    var isFakeApproveV2 : Bool = false
    
    @IBOutlet var vwTopBannerParent: UIView!
    @IBOutlet var consHeightTopBannerParent: NSLayoutConstraint!
    
    var topBannerHeight : CGFloat = 0
    
    
    fileprivate func setup(_ images : Array<String>, width: CGFloat, height: CGFloat)
    {
        imageURLS = images
        for i in 0...images.count - 1 {
            
            var iv : UIImageView?
            
            for v in self.subviews {
                if v is UIImageView {
                    if (i == v.tag) {
                        iv = v as? UIImageView
                        break
                    }
                }
            }
            
            print("Cover TAG : " + String(iv!.tag))
            
            // set frame size
            if (i == 0) {
                if images.count == 1 {
                    iv?.width = width - 4
                    iv?.height = height - 4
                } else {
                    iv?.width = width/2 - 6
                    iv?.height = height - 4
                }
            }
            
            else if (i == 1) {
                if images.count == 2 {
                    iv?.width = width/2 - 6
                    iv?.height = height - 4
                } else if images.count == 5 {
                    iv?.width = (width/2)/2 - 8
                    iv?.height = height/2 - 6
                } else {
                    iv?.width = width/2 - 6
                    iv?.height = height/2 - 6
                }
            }
            
            else if (i == 2) {
                if images.count == 3 {
                    iv?.width = width/2 - 6
                    iv?.height = height/2 - 6
                } else {
                    iv?.width = (width/2)/2 - 8
                    iv?.height = height/2 - 6
                }
            }
            
            else {
                iv?.width = (width/2)/2 - 8
                iv?.height = height/2 - 6
            }
            
            let fr = iv?.frame
            print((fr ?? ""))
            
            iv?.tag = i
            iv?.isUserInteractionEnabled = true
            iv?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProductDetailCover.tapped(_:))))
            
            iv?.afSetImage(withURL: URL(string: images.objectAtCircleIndex(i))!)
        }
        
        self.setupTopBanner()
        self.setupBanner()
    }
    
    func setupTopBanner() {
        if let tbText = self.topBannerText {
            if (status != nil && !tbText.isEmpty) {
                let screenSize: CGRect = UIScreen.main.bounds
                let screenWidth = screenSize.width
                topBannerHeight = 30.0
                let textRect = tbText.boundsWithFontSize(UIFont.systemFont(ofSize: 11), width: screenWidth - 16)
                topBannerHeight += textRect.height
                let topLabelMargin : CGFloat = 8.0
                let topBanner : UIView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: topBannerHeight), backgroundColor: Theme.ThemeOrange)
                let topLabel : UILabel = UILabel(frame: CGRect(x: topLabelMargin, y: 0, width: screenWidth - (topLabelMargin * 2), height: topBannerHeight))
                topLabel.textColor = UIColor.white
                topLabel.font = UIFont.systemFont(ofSize: 11)
                topLabel.lineBreakMode = .byWordWrapping
                topLabel.numberOfLines = 0
                topBanner.addSubview(topLabel)
                if (status == 5) {
                    topLabel.text = tbText
                    self.vwTopBannerParent.addSubview(topBanner)
                    self.consHeightTopBannerParent.constant = topBannerHeight
                }
            }
        }
    }
    
    func updateStatus(_ newStat : Int) {
        self.status = newStat
        self.setupBanner()
    }
    
    func setupBanner() {
        if (status != nil) {
            let screenSize: CGRect = UIScreen.main.bounds
            let screenWidth = screenSize.width
            let bannerWidth = screenWidth/3 // 150
            if (status == 2 && !isFakeApprove && !isFakeApproveV2) { // under review
                banner = UIImageView(image: UIImage(named: "banner_review.png"))
                if (banner != nil) {
                    banner!.frame = CGRect(x: screenWidth - bannerWidth - 2, y: self.topBannerHeight + 2, width: bannerWidth, height: bannerWidth)
                    self.addSubview(banner!)
                }
            } else if (status == 4) { // sold
                self.addSoldBanner()
            } else if (status == 7) { // reserved
                banner = UIImageView(image: UIImage(named: "banner_reserved.png"))
                if (banner != nil) {
                    banner!.frame = CGRect(x: screenWidth - bannerWidth - 2, y: self.topBannerHeight + 2, width: bannerWidth, height: bannerWidth)
                    self.addSubview(banner!)
                }
            } else if (isFeaturedProduct) {
                banner = UIImageView(image: UIImage(named: "banner_featured.png"))
                if (banner != nil) {
                    banner!.frame = CGRect(x: screenWidth - bannerWidth - 2, y: self.topBannerHeight + 2, width: bannerWidth, height: bannerWidth)
                    self.addSubview(banner!)
                }
            } else {
                banner?.removeFromSuperview()
            }
        }
    }
    
    func addSoldBanner() {
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let bannerWidth = screenWidth/3 // 150
        banner = UIImageView(image: UIImage(named: "banner_sold.png"))
        if (banner != nil) {
            banner!.frame = CGRect(x: screenWidth - bannerWidth - 2, y: self.topBannerHeight + 2, width: bannerWidth, height: bannerWidth)
            self.addSubview(banner!)
        }
    }
    
    func tapped(_ sender : UITapGestureRecognizer)
    {
        let index = (sender.view?.tag)!
        let c = CoverZoomController()
        c.labels = self.labels
        c.images = largeImageURLS
        c.index = index
        self.parent?.present(c, animated: true, completion: nil)
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    class func instance(_ images : Array<String>, status: Int, topBannerText : String?, isFakeApprove: Bool, isFakeApproveV2: Bool, width: CGFloat)->ProductDetailCover?
    {
        var p : ProductDetailCover?
        if (images.count == 1) {
            p = Bundle.main.loadNibNamed("ProductDetailCover", owner: nil, options: nil)?.objectAtCircleIndex(0) as? ProductDetailCover
        } else if (images.count == 2) {
            p = Bundle.main.loadNibNamed("ProductDetailCover", owner: nil, options: nil)?.objectAtCircleIndex(1) as? ProductDetailCover
        } else if (images.count == 3) {
            p = Bundle.main.loadNibNamed("ProductDetailCover", owner: nil, options: nil)?.objectAtCircleIndex(2) as? ProductDetailCover
        } else if (images.count == 4) {
            p = Bundle.main.loadNibNamed("ProductDetailCover", owner: nil, options: nil)?.objectAtCircleIndex(3) as? ProductDetailCover
        } else if (images.count >= 5) {
            p = Bundle.main.loadNibNamed("ProductDetailCover", owner: nil, options: nil)?.objectAtCircleIndex(4) as? ProductDetailCover
        }
        
        let height = width * 17 / 24
        
        p?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        p?.isFakeApprove = isFakeApprove
        p?.isFakeApproveV2 = isFakeApproveV2
        
        p?.status = status
        
        p?.topBannerText = topBannerText
        
        p?.setup(images, width: width, height: height)
        
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
    
    var indicator : UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        
        scrollView = UIScrollView(frame: UIScreen.main.bounds)
        scrollView?.isPagingEnabled = true
        scrollView?.backgroundColor = UIColor.black
        
        self.view.addSubview(scrollView!)
        
        self.showLoading()
        
        let b = self.dismissButton
        b.y = 20
        b.x = 16
        b.setTitleColor(Theme.PrimaryColor, for: UIControlState())
        self.view.addSubview(b)
        
        var x : CGFloat = 0
        for i in 0...images.count - 1
        {
            let s = UIScrollView(frame : (scrollView?.bounds)!)
            let iv = UIImageView(frame : s.bounds)
            iv.contentMode = UIViewContentMode.scaleAspectFit
            
            // online image
            if images[i].contains("https://") || images[i].contains("http://") {
                iv.afSetImage(withURL: URL(string: images[i])!, withFilter: .fit)
            } else { // local image
                iv.image = TemporaryImageManager.sharedInstance.loadImageFromDocumentsDirectory(imageName: images[i])
            }
            
            iv.tag = 1
            s.addSubview(iv)
            s.x = x
            scrollView?.addSubview(s)
            
            s.minimumZoomScale = 1
            s.maximumZoomScale = 3
            s.delegate = self
            
            x += s.width
        }
        
        scrollView?.contentSize = CGSize(width: x, height: (scrollView?.height)!)
        scrollView?.isHidden = true
        
        label = UILabel(frame: CGRect.zero)
        label?.backgroundColor = Theme.PrimaryColorDark
        label?.textColor = UIColor.white
        label?.font = UIFont.systemFont(ofSize: 14)
        label?.textAlignment = .center
        
        self.view.addSubview(label!)
        
        label?.text = "Some Text"
        if let t = labels.first
        {
            label?.text = t
        }
        rearrangeLabel()
        label?.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        
        scrollView?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView?.contentOffset = CGPoint(x: index*Int((scrollView?.width)!), y: 0)
        scrollView?.isHidden = false
        
        self.hideLoading()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
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
        f.origin.x = UIScreen.main.bounds.width - (f.size.width + 16)
        f.origin.y = UIScreen.main.bounds.height - (f.size.height + 16)
        label?.frame = f
    }
    
    var currentPage = 0
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    
    func showLoading() {
        indicator = UIActivityIndicatorView()
        indicator?.center = CGPoint(x: UIScreen.main.bounds.width/2 , y: UIScreen.main.bounds.height/2)
        indicator?.startAnimating()
        indicator?.color = UIColor.white
        indicator?.tag = 888
        
        self.view.addSubview(indicator!)
    }
    
    func hideLoading() {
        indicator?.isHidden = true
        indicator?.stopAnimating()
        
        self.view.viewWithTag(888)?.removeFromSuperview()
    }
}
