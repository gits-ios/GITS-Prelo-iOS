//
//  ImageSupplier.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/12/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import AssetsLibrary

enum ImageSource
{
    case Facebook
    case Twitter
    case Instagram
    case Gallery
    case Camera
}

class ImageSupplier: NSObject {
    
    private var source : ImageSource = .Facebook
    
    static func fetch(source : ImageSource, complete : ([APImage]) -> (), failed : (String) -> ())
    {
        if (source == .Gallery) {
            
            AppToolsObjC.fetchAssetWithAlbumName("Camera Roll", onComplete: { r in
            
                var result : Array<APImage> = []
                for d in r
                {
                    let i = d as! NSURL
                    let ap = APImage()
                    ap.url = i
                    ap.usingAssets = true
                    result.append(ap)
                }
                
                complete(result)
                
                }, onFailed: { m in
                    failed(m)
            })
        }
    }
    
}

class APImage
{
    var uri : String = ""
    var url : NSURL?
    var image : UIImage?
    var usingAssets : Bool = false
}
