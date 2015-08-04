//
//  UIImage+BFKit.swift
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
import CoreImage
import Accelerate

/// This extesion adds some useful functions to UIImage
public extension UIImage
{
    // MARK: - Instance functions -
    
    /**
    Apply the given Blend Mode
    
    :param: blendMode The choosed Blend Mode
    
    :returns: Returns the image
    */
    public func blendMode(blendMode: CGBlendMode) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.size.width, self.size.height), false, UIScreen.mainScreen().scale)
        self.drawInRect(CGRectMake(0.0, 0.0, self.size.width, self.size.height), blendMode: blendMode, alpha: 1)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /**
    Apply the Blend Mode Overlay
    
    :returns: Returns the image
    */
    public func blendOverlay() -> UIImage
    {
        return self.blendMode(kCGBlendModeOverlay)
    }
    
    /**
    Create an image from a given rect of self
    
    :param: rect Rect to take the image
    
    :returns: Returns the image from a given rect
    */
    public func imageAtRect(rect: CGRect) -> UIImage
    {
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(self.CGImage, rect)
        let subImage: UIImage = UIImage(CGImage: imageRef)!
        
        return subImage
    }
    
    /**
    Scale the image to the minimum given size
    
    :param: targetSize The site to scale to
    
    :returns: Returns the scaled image
    */
    public func imageByScalingProportionallyToMinimumSize(targetSize: CGSize) -> UIImage?
    {
        var sourceImage: UIImage = self
        var newImage: UIImage? = nil
        var newTargetSize: CGSize = targetSize
        
        let imageSize: CGSize = sourceImage.size
        let width: CGFloat = imageSize.width
        let height: CGFloat = imageSize.height
        
        let targetWidth: CGFloat = newTargetSize.width
        let targetHeight: CGFloat = newTargetSize.height
        
        var scaleFactor: CGFloat = 0.0
        var scaledWidth: CGFloat = targetWidth
        var scaledHeight: CGFloat = targetHeight
        
        var thumbnailPoint: CGPoint = CGPointMake(0.0,0.0)
        
        if CGSizeEqualToSize(imageSize, newTargetSize) == false
        {
            let widthFactor: CGFloat = targetWidth / width
            let heightFactor: CGFloat = targetHeight / height
            
            if widthFactor > heightFactor
            {
                scaleFactor = widthFactor
            }
            else
            {
                scaleFactor = heightFactor
            }
            
            scaledWidth = width * scaleFactor
            scaledHeight = height * scaleFactor
            
            if widthFactor > heightFactor
            {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
            }
            else if widthFactor < heightFactor
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(newTargetSize, false, UIScreen.mainScreen().scale)
        var thumbnailRect: CGRect = CGRectZero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight
        
        sourceImage.drawInRect(thumbnailRect)
        
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if newImage == nil
        {
            BFLog("Could not scale image")
        }
        
        return newImage
    }
    
    /**
    Scale the image to the maxinum given size
    
    :param: targetSize The site to scale to
    
    :returns: Returns the scaled image
    */
    public func imageByScalingProportionallyToMaximumSize(targetSize: CGSize) -> UIImage
    {
        var newTargetSize: CGSize = targetSize
        
        if (self.size.width > newTargetSize.width || newTargetSize.width == newTargetSize.height) && self.size.width > self.size.height
        {
            let factor: CGFloat = (newTargetSize.width * 100)/self.size.width
            let newWidth: CGFloat = (self.size.width * factor)/100
            let newHeight: CGFloat = (self.size.height * factor)/100
            
            let newSize: CGSize = CGSizeMake(newWidth, newHeight)
            UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.mainScreen().scale)
            self.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        }
        else if (self.size.height > newTargetSize.height || newTargetSize.width == newTargetSize.height) && self.size.width < self.size.height
        {
            let factor: CGFloat = (newTargetSize.width * 100)/self.size.height
            let newWidth: CGFloat = (self.size.width * factor)/100
            let newHeight: CGFloat = (self.size.height * factor)/100
            
            let newSize: CGSize = CGSizeMake(newWidth, newHeight)
            UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.mainScreen().scale)
            self.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        }
        else if (self.size.height > newTargetSize.height || self.size.width > newTargetSize.width ) && self.size.width == self.size.height
        {
            let factor: CGFloat = (newTargetSize.height * 100) / self.size.height
            let newDimension: CGFloat = (self.size.height * factor) / 100
            
            let newSize: CGSize = CGSizeMake(newDimension, newDimension)
            UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.mainScreen().scale)
            self.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        }
        else
        {
            let newSize: CGSize = CGSizeMake(self.size.width, self.size.height)
            UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.mainScreen().scale)
            self.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        }
        
        let returnImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return returnImage
    }
    
    /**
    Scale the image proportionally to the given size
    
    :param: targetSize The site to scale to
    
    :returns: Returns the scaled image
    */
    public func imageByScalingProportionallyToSize(targetSize: CGSize) -> UIImage?
    {
        var sourceImage: UIImage = self
        var newImage: UIImage? = nil
        var newTargetSize: CGSize = targetSize

        let imageSize: CGSize = sourceImage.size
        let width: CGFloat = imageSize.width
        let height: CGFloat = imageSize.height
        
        let targetWidth: CGFloat = newTargetSize.width
        let targetHeight: CGFloat = newTargetSize.height
        
        var scaleFactor: CGFloat = 0.0
        var scaledWidth: CGFloat = targetWidth
        var scaledHeight: CGFloat = targetHeight
        
        var thumbnailPoint: CGPoint = CGPointMake(0.0, 0.0)
        
        if CGSizeEqualToSize(imageSize, newTargetSize) == false
        {
            let widthFactor: CGFloat = targetWidth / width
            let heightFactor: CGFloat = targetHeight / height
            
            if widthFactor < heightFactor
            {
                scaleFactor = widthFactor
            }
            else
            {
                scaleFactor = heightFactor
            }
            
            scaledWidth = width * scaleFactor
            scaledHeight = height * scaleFactor
            
            if widthFactor < heightFactor
            {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
            }
            else if widthFactor > heightFactor
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(newTargetSize, false, UIScreen.mainScreen().scale)
        
        var thumbnailRect: CGRect = CGRectZero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width = scaledWidth
        thumbnailRect.size.height = scaledHeight
        
        sourceImage.drawInRect(thumbnailRect)
        
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if(newImage == nil)
        {
            BFLog("Could not scale image")
        }
        
        return newImage
    }
    
    /**
    Scele the iamge to the given size
    
    :param: targetSize The site to scale to
    
    :returns: Returns the scaled image
    */
    public func imageByScalingToSize(targetSize: CGSize) -> UIImage?
    {
        var sourceImage: UIImage = self
        var newImage: UIImage? = nil
        
        let targetWidth: CGFloat = targetSize.width
        let targetHeight: CGFloat = targetSize.height
        
        let scaledWidth: CGFloat = targetWidth
        let scaledHeight: CGFloat = targetHeight
        
        let thumbnailPoint: CGPoint = CGPointMake(0.0, 0.0)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, UIScreen.mainScreen().scale)
        
        var thumbnailRect: CGRect = CGRectZero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width = scaledWidth
        thumbnailRect.size.height = scaledHeight
        
        sourceImage.drawInRect(thumbnailRect)
        
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if(newImage == nil)
        {
            BFLog("Could not scale image")
        }
        
        return newImage
    }
    
    /**
    Rotate the image to the given radians
    
    :param: radians Radians to rotate to
    
    :returns: Returns the rotated image
    */
    public func imageRotatedByRadians(radians: CGFloat) -> UIImage
    {
        return self.imageRotatedByDegrees(CGFloat(RadiansToDegrees(Float(radians))))
    }
    
    /**
    Rotate the image to the given degrees
    
    :param: degrees Degrees to rotate to
    
    :returns: Returns the rotated image
    */
    public func imageRotatedByDegrees(degrees: CGFloat) -> UIImage
    {
        let rotatedViewBox: UIView = UIView(frame: CGRectMake(0, 0, self.size.width, self.size.height))
        let t: CGAffineTransform = CGAffineTransformMakeRotation(CGFloat(DegreesToRadians(Float(degrees))))
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, UIScreen.mainScreen().scale)
        let bitmap: CGContextRef = UIGraphicsGetCurrentContext()
        
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2)
        
        CGContextRotateCTM(bitmap, CGFloat(DegreesToRadians(Float(degrees))))
        
        CGContextScaleCTM(bitmap, 1.0, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), self.CGImage)
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /**
    Check if the image has alpha
    
    :returns: Returns true if has alpha, false if not
    */
    public func hasAlpha() -> Bool
    {
        let alpha: CGImageAlphaInfo = CGImageGetAlphaInfo(self.CGImage)
        return (alpha == .First || alpha == .Last || alpha == .PremultipliedFirst || alpha == .PremultipliedLast)
    }
    
    /**
    Remove the alpha of the image
    
    :returns: Returns the image without alpha
    */
    public func removeAlpha() -> UIImage
    {
        if !self.hasAlpha()
        {
            return self
        }
        
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
        let mainViewContentContext: CGContextRef = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height), 8, 0, colorSpace, CGBitmapInfo(rawValue: 0))
        
        CGContextDrawImage(mainViewContentContext, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage)
        let mainViewContentBitmapContext: CGImageRef = CGBitmapContextCreateImage(mainViewContentContext)
        let returnImage: UIImage = UIImage(CGImage: mainViewContentBitmapContext)!
        
        return returnImage
    }
    
    /**
    Fill the alpha with the white color
    
    :returns: Returns the filled image
    */
    public func fillAlpha() -> UIImage
    {
        return self.fillAlphaWithColor(UIColor.whiteColor())
    }
    
    /**
    Fill the alpha with the given color
    
    :param: color Color to fill
    
    :returns: Returns the filled image
    */
    public func fillAlphaWithColor(color: UIColor) -> UIImage
    {
        var im_r: CGRect = CGRect(origin: CGPointZero, size: self.size)
        
        let cgColor: CGColorRef = color.CGColor
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.mainScreen().scale)
        let context: CGContextRef = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, cgColor)
        CGContextFillRect(context,im_r)
        self.drawInRect(im_r)
        
        let returnImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return returnImage
    }
    
    /**
    Check if the image is in grayscale
    
    :returns: Returns true if is in grayscale, false if not
    */
    public func isGrayscale() -> Bool
    {
        let imgRef: CGImageRef = self.CGImage
        let clrMod: CGColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imgRef))
        
        if clrMod.value == kCGColorSpaceModelMonochrome.value
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    /**
    Transform the image to grayscale
    
    :returns: Returns the transformed image
    */
    public func imageToGrayscale() -> UIImage
    {
        let rect: CGRect = CGRectMake(0.0, 0.0, size.width, size.height)
        
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceGray()
        let context: CGContextRef = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height), 8, 0, colorSpace, CGBitmapInfo(rawValue: 0))

        CGContextDrawImage(context, rect, self.CGImage)
        let grayscale: CGImageRef = CGBitmapContextCreateImage(context)
        let returnImage: UIImage = UIImage(CGImage: grayscale)!
        
        return returnImage
    }
    
    /**
    Transform the image to black and white
    
    :returns: Returns the transformed image
    */
    public func imageToBlackAndWhite() -> UIImage
    {
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceGray()
        let context: CGContextRef = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height), 8, 0, colorSpace, CGBitmapInfo(rawValue: 0))
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh)
        CGContextSetShouldAntialias(context, false)
        CGContextDrawImage(context, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage)
        
        let bwImage: CGImageRef = CGBitmapContextCreateImage(context)
        
        let returnImage: UIImage = UIImage(CGImage: bwImage)!
        
        return returnImage
    }
    
    /**
    Invert the color of the image
    
    :returns: Returns the transformed image
    */
    public func invertColors() -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen .mainScreen().scale)
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeCopy)
        self.drawInRect(CGRectMake(0, 0, self.size.width, self.size.height))
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDifference)
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), UIColor.whiteColor().CGColor)
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, self.size.width, self.size.height))
        
        let returnImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return returnImage
    }
    
    /**
    Apply the bloom effect to the image
    
    :param: radius    Radius of the bloom
    :param: intensity Intensity of the bloom
    
    :returns: Returns the transformed image
    */
    public func bloom(radius: Float, intensity: Float) -> UIImage
    {
        let context: CIContext = CIContext(options: nil)
        let filter: CIFilter = CIFilter(name: "CIBloom")
        
        filter.setValue(self.CIImage, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(float: radius), forKey: "inputRadius")
        filter.setValue(NSNumber(float: intensity), forKey: "inputIntensity")
        
        let returnImage: UIImage = UIImage(CIImage: filter.outputImage)!
        
        return returnImage
    }
    
    /**
    Apply the bump distortion effect to the image
    
    :param: center Vector of the distortion. Use CIVector(x: X, y: Y)
    :param: radius Radius of the effect
    :param: scale  Scale of the effect
    
    :returns: Returns the transformed image
    */
    public func bumpDistortion(center: CIVector, radius: Float, scale: Float) -> UIImage
    {
        let context: CIContext = CIContext(options: nil)
        let filter: CIFilter = CIFilter(name: "CIBumpDistortion")
        
        filter.setValue(self.CIImage, forKey: kCIInputImageKey)
        filter.setValue(center, forKey: "inputCenter")
        filter.setValue(NSNumber(float: radius), forKey: "inputRadius")
        filter.setValue(NSNumber(float: scale), forKey: "inputScale")
        
        let returnImage: UIImage = UIImage(CIImage: filter.outputImage)!
        
        return returnImage
    }
    
    /**
    Apply the bump distortion linear effect to the image
    
    :param: center Vector of the distortion. Use CIVector(x: X, y: Y)
    :param: radius Radius of the effect
    :param: angle  Angle of the effect in radians
    :param: scale  Scale of the effect
    
    :returns: Returns the transformed image
    */
    public func bumpDistortionLinear(center: CIVector, radius: Float, angle: Float, scale: Float) -> UIImage
    {
        let context: CIContext = CIContext(options: nil)
        let filter: CIFilter = CIFilter(name: "CIBumpDistortionLinear")
        
        filter.setValue(self.CIImage, forKey: kCIInputImageKey)
        filter.setValue(center, forKey: "inputCenter")
        filter.setValue(NSNumber(float: radius), forKey: "inputRadius")
        filter.setValue(NSNumber(float: angle), forKey: "inputAngle")
        filter.setValue(NSNumber(float: scale), forKey: "inputScale")
        
        let returnImage: UIImage = UIImage(CIImage: filter.outputImage)!
        
        return returnImage
    }
    
    /**
    Apply the circular splash distortion effect to the image
    
    :param: center Vector of the distortion. Use CIVector(x: X, y: Y)
    :param: radius Radius of the effect
    
    :returns: Returns the transformed image
    */
    public func circleSplashDistortion(center: CIVector, radius: Float) -> UIImage
    {
        let context: CIContext = CIContext(options: nil)
        let filter: CIFilter = CIFilter(name: "CICircleSplashDistortion")
        
        filter.setValue(self.CIImage, forKey: kCIInputImageKey)
        filter.setValue(center, forKey: "inputCenter")
        filter.setValue(NSNumber(float: radius), forKey: "inputRadius")
        
        let returnImage: UIImage = UIImage(CIImage: filter.outputImage)!
        
        return returnImage
    }
    
    /**
    Apply the circular wrap effect to the image
    
    :param: center Vector of the distortion. Use CIVector(x: X, y: Y)
    :param: radius Radius of the effect
    :param: angle  Angle of the effect in radians
    
    :returns: Returns the transformed image
    */
    public func circularWrap(center: CIVector, radius: Float, angle: Float) -> UIImage
    {
        let context: CIContext = CIContext(options: nil)
        let filter: CIFilter = CIFilter(name: "CICircularWrap")
        
        filter.setValue(self.CIImage, forKey: kCIInputImageKey)
        filter.setValue(center, forKey: "inputCenter")
        filter.setValue(NSNumber(float: radius), forKey: "inputRadius")
        filter.setValue(NSNumber(float: angle), forKey: "inputAngle")
        
        let returnImage: UIImage = UIImage(CIImage: filter.outputImage)!
        
        return returnImage
    }
    
    /**
    Apply the CMY halftone effect to the image
    
    :param: center    Vector of the distortion. Use CIVector(x: X, y: Y)
    :param: width     Width value
    :param: angle     Angle of the effect in radians
    :param: sharpness Sharpness Value
    :param: gcr       GCR value
    :param: ucr       UCR value
    
    :returns: Returns the transformed image
    */
    public func cmykHalftone(center: CIVector, width: Float, angle: Float, sharpness: Float, gcr: Float, ucr: Float) -> UIImage
    {
        let context: CIContext = CIContext(options: nil)
        let filter: CIFilter = CIFilter(name: "CICMYKHalftone")
        
        filter.setValue(self.CIImage, forKey: kCIInputImageKey)
        filter.setValue(center, forKey: "inputCenter")
        filter.setValue(NSNumber(float: width), forKey: "inputWidth")
        filter.setValue(NSNumber(float: angle), forKey: "inputAngle")
        filter.setValue(NSNumber(float: sharpness), forKey: "inputSharpness")
        filter.setValue(NSNumber(float: gcr), forKey: "inputGCR")
        filter.setValue(NSNumber(float: ucr), forKey: "inputUCR")
        
        let returnImage: UIImage = UIImage(CIImage: filter.outputImage)!
        
        return returnImage
    }
    
    /**
    Apply the sepia filter to the image
    
    :param: intensity Intensity of the filter
    
    :returns: Returns the transformed image
    */
    public func sepiaToneWithIntensity(intensity: Float) -> UIImage
    {
        let context: CIContext = CIContext(options: nil)
        let filter: CIFilter = CIFilter(name: "CISepiaTone")
        
        filter.setValue(self.CIImage, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(float: intensity), forKey: "inputIntensity")
        
        let returnImage: UIImage = UIImage(CIImage: filter.outputImage)!
        
        return returnImage
    }
    
    /**
    Apply the blur effect to the image
    
    :param: blurRadius            Blur radius
    :param: tintColor             Blur tint color
    :param: saturationDeltaFactor Saturation delta factor, leave it default (1.8) if you don't what is
    :param: maskImage             Apply a mask image, leave it default (nil) if you don't want to mask
    
    :returns: Return the transformed image
    */
    public func blur(radius blurRadius: CGFloat, tintColor: UIColor? = nil, saturationDeltaFactor: CGFloat = 1.8, maskImage: UIImage? = nil) -> UIImage?
    {
        if size.width < 1 || size.height < 1
        {
            BFLog("Invalid size: \(size.width) x \(size.height). Both dimensions must be >= 1: \(self)")
            return nil
        }
        
        if CGImage == nil
        {
            BFLog("Image must be backed by a CGImage: \(self)")
            return nil
        }
        
        if let maskImage = maskImage where maskImage.CGImage == nil
        {
            BFLog("maskImage must be backed by a CGImage: \(maskImage)")
            return nil
        }
        
        let imageRect = CGRect(origin: CGPointZero, size: size)
        var effectImage = self
        
        let hasBlur = Float(blurRadius) > FLT_EPSILON
        let hasSaturationChange = Float(abs(saturationDeltaFactor - 1)) > FLT_EPSILON
        
        if hasBlur || hasSaturationChange
        {
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
            let effectInContext = UIGraphicsGetCurrentContext()
            CGContextScaleCTM(effectInContext, 1, -1)
            CGContextTranslateCTM(effectInContext, 0, -size.height)
            CGContextDrawImage(effectInContext, imageRect, CGImage)
            var effectInBuffer = vImage_Buffer(data: CGBitmapContextGetData(effectInContext), height: UInt(CGBitmapContextGetHeight(effectInContext)), width: UInt(CGBitmapContextGetWidth(effectInContext)), rowBytes: CGBitmapContextGetBytesPerRow(effectInContext))
            
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
            let effectOutContext = UIGraphicsGetCurrentContext()
            var effectOutBuffer = vImage_Buffer(data: CGBitmapContextGetData(effectOutContext), height: UInt(CGBitmapContextGetHeight(effectOutContext)), width: UInt(CGBitmapContextGetWidth(effectOutContext)), rowBytes: CGBitmapContextGetBytesPerRow(effectOutContext))
            
            if hasBlur
            {
                let inputRadius = blurRadius * UIScreen.mainScreen().scale
                var radius = UInt32(floor(inputRadius * 3.0 * CGFloat(sqrt(2 * M_PI)) / 4 + 0.5))
                if radius % 2 != 1
                {
                    ++radius
                }
                
                let imageEdgeExtendFlags = vImage_Flags(kvImageEdgeExtend)
                vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
                vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
                vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
            }
            
            var effectImageBuffersAreSwapped = false
            if hasSaturationChange
            {
                let s = saturationDeltaFactor
                let floatingPointSaturationMatrix = [
                    0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                    0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                    0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                    0,                    0,                    0,                    1
                ]
                
                let divisor: CGFloat = 256
                let matrixSize = count(floatingPointSaturationMatrix)
                let saturationMatrix = map(floatingPointSaturationMatrix) {
                    return Int16(round($0 * divisor))
                }
                
                if hasBlur
                {
                    vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, Int32(divisor), nil, nil, vImage_Flags(kvImageNoFlags))
                    effectImageBuffersAreSwapped = true
                }
                else
                {
                    vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, Int32(divisor), nil, nil, vImage_Flags(kvImageNoFlags))
                }
            }
            
            if !effectImageBuffersAreSwapped
            {
                effectImage = UIGraphicsGetImageFromCurrentImageContext()
            }
            UIGraphicsEndImageContext()
            
            if effectImageBuffersAreSwapped
            {
                effectImage = UIGraphicsGetImageFromCurrentImageContext()
            }
            UIGraphicsEndImageContext()
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
        let outputContext = UIGraphicsGetCurrentContext()
        CGContextScaleCTM(outputContext, 1, -1)
        CGContextTranslateCTM(outputContext, 0, -size.height)
        
        CGContextDrawImage(outputContext, imageRect, CGImage)

        if hasBlur
        {
            CGContextSaveGState(outputContext)
            if let image = maskImage
            {
                CGContextClipToMask(outputContext, imageRect, image.CGImage)
            }
            CGContextDrawImage(outputContext, imageRect, effectImage.CGImage)
            CGContextRestoreGState(outputContext)
        }
        
        if let tintColor = tintColor
        {
            CGContextSaveGState(outputContext)
            CGContextSetFillColorWithColor(outputContext, tintColor.CGColor)
            CGContextFillRect(outputContext, imageRect)
            CGContextRestoreGState(outputContext)
        }
        
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return outputImage
    }
    
    // MARK: - Class functions -
    
    // MARK: First attempt to use UIImage(named: name) to create dummy images (Failed)
    /*private static func sizeForSizeString(sizeString: String) -> CGSize
    {
        let array: Array = sizeString.componentsSeparatedByString("x")
        if array.count != 2
        {
            return CGSizeZero
        }
        
        return CGSizeMake(CGFloat(array[0].floatValue), CGFloat(array[1].floatValue))
    }
    
    private static func colorForColorString(colorString: String?) -> UIColor
    {
        if colorString == nil
        {
            return UIColor.lightGrayColor()
        }
        
        let colorSelector = Selector(colorString!.stringByAppendingString("Color"))
        if UIColor.respondsToSelector(colorSelector)
        {
            return UIColor.forwardingTargetForSelector(colorSelector) as! UIColor
        }
        else
        {
            return UIColor(hex: colorString!)
        }
    }
    
    private static var predicate: dispatch_once_t = 0
    
    public override class func initialize()
    {
        dispatch_once(&predicate) {
            let originalSelector = Selector("named:")
            let swizzledSelector = Selector("dummyImageNamed:")
            
            let originalMethod = class_getClassMethod(self, originalSelector)
            let swizzledMethod = class_getClassMethod(self, swizzledSelector)
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    static func dummyImageNamed(name: String) -> UIImage?
    {
        var result: UIImage
        
        let array: Array = name.componentsSeparatedByString(".")
        if array[0].lowercaseString == "dummy"
        {
            let sizeString: String? = array[1]
            if sizeString == nil
            {
                return nil
            }
            
            var colorString: String? = nil
            if array.count >= 3
            {
                colorString = array[2]
            }
            
            return self.dummyImageWithSize(sizeForSizeString(sizeString!), color:colorForColorString(colorString))
        }
        else
        {
            result = self.dummyImageNamed(name)!
        }
        
        return result
    }
    
    static func dummyImageWithSize(size: CGSize, color: UIColor) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
        let context: CGContextRef = UIGraphicsGetCurrentContext()
        
        let rect: CGRect = CGRectMake(0.0, 0.0, size.width, size.height)
        
        color.setFill()
        CGContextFillRect(context, rect)
        
        let sizeString: String = "\(Int(size.width)) x \(Int(size.height))"
        let style: NSMutableParagraphStyle = NSParagraphStyle.defaultParagraphStyle() as! NSMutableParagraphStyle
        style.alignment = .Center
        style.minimumLineHeight = size.height / 2
        let attributes: Dictionary = [NSParagraphStyleAttributeName : style]
        sizeString.drawInRect(rect, withAttributes:attributes)
        
        let result: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return result
    }*/
    
    /**
    Private, create a CGSize with a given string (100x100)
    
    :param: sizeString String with the size
    
    :returns: Returns the created CGSize
    */
    private static func sizeForSizeString(sizeString: String) -> CGSize
    {
        let array: Array = sizeString.componentsSeparatedByString("x")
        if array.count != 2
        {
            return CGSizeZero
        }
        
        return CGSizeMake(CGFloat(array[0].floatValue), CGFloat(array[1].floatValue))
    }
    
    /**
    Create an UIColor from a given string ("blue" or "ff00ff" or "#00ff00")
    
    :param: colorString String with the color
    
    :returns: Returns the created UIColor
    */
    public static func colorForColorString(colorString: String?) -> UIColor
    {
        if colorString == nil
        {
            return UIColor.lightGrayColor()
        }
        
        if UIColor.respondsToSelector(Selector(colorString!.lowercaseString.stringByAppendingString("Color")))
        {
            return self.getColorFromColorString(colorString!)
        }
        else
        {
            return UIColor(hex: colorString!)
        }
    }
    
    /**
    Private, used the retrive the color from the string color ("blue" or "red")
    
    :param: color String with the color
    
    :returns: Returns the created UIColor
    */
    private static func getColorFromColorString(color: String) -> UIColor
    {
        switch color
        {
        case "black":
            return UIColor.blackColor()
        case "darkgray":
            return UIColor.darkGrayColor()
        case "lightgray":
            return UIColor.lightGrayColor()
        case "white":
            return UIColor.whiteColor()
        case "gray":
            return UIColor.grayColor()
        case "red":
            return UIColor.redColor()
        case "green":
            return UIColor.greenColor()
        case "blue":
            return UIColor.blueColor()
        case "cyan":
            return UIColor.cyanColor()
        case "yellow":
            return UIColor.yellowColor()
        case "magenta":
            return UIColor.magentaColor()
        case "orange":
            return UIColor.orangeColor()
        case "purple":
            return UIColor.purpleColor()
        case "brown":
            return UIColor.brownColor()
        case "clear":
            return UIColor.clearColor()
        default:
            return UIColor.grayColor()
        }
    }
    
    // MARK: - Init functions -
    
    /**
    Create a dummy image
    
    :param: dummy To use it, name parameter must contain: "dummy.100x100" and "dummy.100x100.#FFFFFF" or "dummy.100x100.blue" (if it's a color defined in UIColor class) if you want to define a color
    
    :returns: Returns the created dummy image
    */
    public convenience init?(dummyImageWithSizeAndColor dummy: String)
    {
        var size: CGSize = CGSizeZero, color: UIColor = UIColor.lightGrayColor()
        
        let array: Array = dummy.componentsSeparatedByString(".")
        if array.count > 0
        {
            let sizeString: String = array[0]
            
            var colorString: String
            if array.count >= 2
            {
                color = UIImage.colorForColorString(array[1])
            }
            
            size = UIImage.sizeForSizeString(sizeString)
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
        let context: CGContextRef = UIGraphicsGetCurrentContext()
        
        let rect: CGRect = CGRectMake(0.0, 0.0, size.width, size.height)
        
        color.setFill()
        CGContextFillRect(context, rect)
        
        let sizeString: String = "\(Int(size.width)) x \(Int(size.height))"
        let style: NSMutableParagraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        style.alignment = .Center
        style.minimumLineHeight = size.height / 2
        let attributes: Dictionary = [NSParagraphStyleAttributeName : style]
        sizeString.drawInRect(rect, withAttributes:attributes)
        
        let result: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        self.init(CGImage: result.CGImage)
    }
    
    /**
    Create an image from a given text
    
    :param: text      Text
    :param: font      Text's font name
    :param: fontSize  Text's font size
    :param: imageSize Image's size
    
    :returns: Returns the created UIImage
    */
    public convenience init?(fromText text: String, font: FontName, fontSize: CGFloat, imageSize: CGSize)
    {
        UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.mainScreen().scale)
        
        text.drawAtPoint(CGPointMake(0.0, 0.0), withAttributes: [NSFontAttributeName : UIFont(fontName: font, size:fontSize)!])
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        self.init(CGImage: image.CGImage)
    }
    
    /**
    Create an image with a background color and with a text with a mask
    
    :param: maskedText      Text to mask
    :param: font            Text's font name
    :param: fontSize        Text's font size
    :param: imageSize       Image's size
    :param: backgroundColor Image's background color
    
    :returns: Returns the created UIImage
    */
    public convenience init?(maskedText: String, font: FontName, fontSize: CGFloat, imageSize: CGSize, backgroundColor: UIColor)
    {
        let fontName: UIFont = UIFont(fontName: font, size: fontSize)!
        let textAttributes = [NSFontAttributeName : fontName]
        
        let textSize: CGSize = maskedText.sizeWithAttributes(textAttributes)
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.mainScreen().scale)
        let ctx: CGContextRef = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(ctx, backgroundColor.CGColor)
        
        let path: UIBezierPath = UIBezierPath(rect: CGRectMake(0, 0, imageSize.width, imageSize.height))
        CGContextAddPath(ctx, path.CGPath)
        CGContextFillPath(ctx)
        
        CGContextSetBlendMode(ctx, kCGBlendModeDestinationOut)
        let center: CGPoint = CGPointMake(imageSize.width / 2 - textSize.width / 2, imageSize.height / 2 - textSize.height / 2)
        maskedText.drawAtPoint(center, withAttributes: textAttributes)
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        self.init(CGImage: image.CGImage)
    }
    
    /**
    Create an image from a given color
    
    :param: color Color value
    
    :returns: Returns the created UIImage
    */
    public convenience init?(color: UIColor)
    {
        let rect: CGRect = CGRectMake(0, 0, 1, 1)
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContextRef = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        
        CGContextFillRect(context, rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.init(CGImage: image.CGImage)
    }
}
