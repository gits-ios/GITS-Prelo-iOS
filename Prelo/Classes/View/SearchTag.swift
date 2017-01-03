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
    @IBOutlet fileprivate var captionHide : UILabel!
    
    static func instance(_ tagString : String) -> SearchTag
    {
        let s = Bundle.main.loadNibNamed("SearchTag", owner: nil, options: nil)?.first as! SearchTag
        s.captionTitle.text = tagString
        s.captionHide.text = tagString
        s.captionHide.sizeToFit()
        
        s.bounds = CGRect(x: 0, y: 0, width: s.captionHide.width+16 <= UIScreen.main.bounds.width-16 ? s.captionHide.width+16 : UIScreen.main.bounds.width-16, height: s.captionHide.height+8)
        
        s.layer.cornerRadius = s.height/2
        s.layer.masksToBounds = true
        
        return s
    }

}
