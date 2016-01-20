//
//  UIImageView+BFKit.swift
//  BFKit
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Fabrizio Brancati. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import UIKit
import QuartzCore

/// This extesion adds some useful functions to UIImageView
public extension UIImageView
{
    // MARK: - Instance functions -
    
    /**
    Create a drop shadow effect
    
    :param: color   Shadow's color
    :param: radius  Shadow's radius
    :param: offset  Shadow's offset
    :param: opacity adow's opacity
    */
    public func setImageShadowColor(color: UIColor, radius: CGFloat, offset: CGSize, opacity: Float)
    {
        self.layer.shadowColor = color.CGColor
        self.layer.shadowRadius = radius
        self.layer.shadowOffset = offset
        self.layer.shadowOpacity = opacity
        self.clipsToBounds = false
    }
    
    /**
    Mask the current UIImageView with an UIImage
    
    :param: image The mask UIImage
    */
    public func setMaskImage(image: UIImage)
    {
        let mask: CALayer = CALayer()
        mask.contents = image.CGImage
        mask.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)
        self.layer.mask = mask
        self.layer.masksToBounds = false
    }
    
    // MARK: - Init functions -
    
    /**
    Create an UIImageView with the given image and frame
    
    :param: frame UIImageView frame
    :param: image UIImageView image
    
    :returns: Returns the created UIImageView
    */
    public convenience init(frame: CGRect, image: UIImage)
    {
        self.init(frame: frame)
        self.image = image
    }
    
    /**
    Create an UIImageView with the given image, size and center
    
    :param: image  UIImageView image
    :param: size   UIImageView size
    :param: center UIImageView center
    
    :returns: Returns the created UIImageView
    */
    public convenience init(image: UIImage, size: CGSize, center: CGPoint)
    {
        self.init(frame: CGRectMake(0, 0, size.width, size.height))
        self.image = image
        self.center = center
    }
    
    /**
    Create an UIImageView with the given image and center
    
    :param: image  UIImageView image
    :param: center UIImageView center
    
    :returns: Returns the created UIImageView
    */
    public convenience init(image: UIImage, center: CGPoint)
    {
        self.init(image: image)
        self.center = center
    }
}
