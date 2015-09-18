//
//  SearchTag.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/17/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

class SearchTag: BorderedView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBOutlet var captionTitle : UILabel!
    @IBOutlet private var captionHide : UILabel!
    
    static func instance(tagString : String) -> SearchTag
    {
        let s = NSBundle.mainBundle().loadNibNamed("SearchTag", owner: nil, options: nil).first as! SearchTag
        s.captionTitle.text = tagString
        s.captionHide.text = tagString
        s.captionHide.sizeToFit()
        
        s.bounds = CGRectMake(0, 0, s.captionHide.width+16, s.captionHide.height+8)
        
        s.layer.cornerRadius = s.height/2
        s.layer.masksToBounds = true
        
        return s
    }

}
