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
    case facebook
    case twitter
    case instagram
    case gallery
    case camera
}

class ImageSupplier: NSObject {
    
    fileprivate var source : ImageSource = .facebook
    
    static func fetch(_ source : ImageSource, ascending : Bool = false, complete : @escaping ([APImage]) -> (), failed : @escaping (String) -> ())
    {
        if (source == .gallery) {
            
            AppToolsObjC.fetchAsset(withAlbumName: "Camera Roll", onComplete: { r in
            
                var result : Array<APImage> = []
                for d in r!
                {
                    let i = d as! URL
                    let ap = APImage()
                    ap.url = i
                    ap.usingAssets = true
                    result.append(ap)
                }
                
                if (ascending)
                {
                    result = result.reversed()
                }
                
                complete(result)
                
                }, onFailed: { m in
                    failed(m!)
            })
        }
    }
    
}

class APImage
{
    var uri : String = ""
    var url : URL?
    var image : UIImage?
    var usingAssets : Bool = false
    var asset : ALAsset?
    
    var assetLib : ALAssetsLibrary?
    func getImage(_ doneBlock : @escaping (UIImage?)->())
    {
        if let i = self.image
        {
            doneBlock(i)
        } else if (usingAssets)
        {
            if (assetLib == nil)
            {
                assetLib = ALAssetsLibrary()
            }
            
            DispatchQueue.global( priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
                self.assetLib?.asset(for: self.url!, resultBlock: { asset in
                    if let ast = asset {
                        let rep = ast.defaultRepresentation()
                        let ref = rep?.fullScreenImage().takeUnretainedValue()
                        let i = UIImage(cgImage: ref!)
                        DispatchQueue.main.async(execute: {
                            doneBlock(i)
                        })
                    }
                    }, failureBlock: { error in
                        doneBlock(nil)
                })
            })
        }
    }
}
