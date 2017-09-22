//
//  ViewExtension.swift
//  Prelo
//
//  Created by GITS INDONESIA on 9/22/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

public extension UIView {
    
    public class func instantiateFromNib<T: UIView>(_ viewType: T.Type) -> T {
        let url = URL(string: NSStringFromClass(viewType))
        return Bundle.main.loadNibNamed((url?.pathExtension)!, owner: nil, options: nil)!.first as! T
    }
    
    public class func instantiateFromNib() -> Self {
        return instantiateFromNib(self)
    }
}
