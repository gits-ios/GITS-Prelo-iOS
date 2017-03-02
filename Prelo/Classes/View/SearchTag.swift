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
        
        var isOke = false
        var width : CGFloat = 0
        var multiplier : CGFloat = 1
        while (!isOke) {
            if (s.captionHide.width/multiplier + 16*multiplier <= UIScreen.main.bounds.width - 16) {
                width = s.captionHide.width/multiplier + 16*multiplier
                isOke = true
            } else {
                multiplier += 1
            }
        }
        
        let area = s.captionHide.text?.boundsWithFontSize(s.captionHide.font, width: width)
        
        let halfOriginalHeight = (s.captionHide.height+9)/2
        
//        s.bounds = CGRect(x: 0, y: 0, width: width, height: s.captionHide.height+8 >= (area?.height)!+8 ? s.captionHide.height+8 : (area?.height)!+8)
        
        s.bounds = CGRect(x: 0, y: 0, width: width, height: (area?.height)! + 9)
        
        s.layer.cornerRadius = halfOriginalHeight
        s.layer.masksToBounds = true
        
        s.captionTitle.numberOfLines = 0
//        s.captionTitle.textAlignment = NSTextAlignment.left
//        s.captionTitle.layoutMargins = UIEdgeInsetsMake(4, 8, 4, 8)
        
        return s
    }
    
}
