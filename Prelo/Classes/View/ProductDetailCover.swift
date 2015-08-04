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
    
    private func setup(images : Array<String>)
    {
        for i in 0...images.count
        {
            let iv = imageViews?.objectAtCircleIndex(i)
            iv?.setImageWithUrl(NSURL(string: images.objectAtCircleIndex(i))!, placeHolderImage: nil)
        }
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
