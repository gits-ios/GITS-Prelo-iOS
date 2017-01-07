//
//  ScannerViewController.swift
//  Prelo
//
//  Created by Djuned on 1/6/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

//import Foundation
import AVFoundation
import UIKit

typealias BlockScanner = ([AnyObject]) -> () // UIImage , String

class ScannerViewController: BaseViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    // for capture image
    let stillImageOutput = AVCaptureStillImageOutput()
    
    var root : BaseViewController?
    var blockDone : BlockScanner?
    
    var counter = 0
    var timer = Timer()
    
//    var textLayer : CATextLayer!
    
    // 5 detik
    var maxTime = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed();
            return;
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            captureSession.addOutput(stillImageOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode]
        } else {
            failed()
            return
        }
        
        // iamge preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
        previewLayer.frame = view.layer.bounds;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        view.layer.addSublayer(previewLayer);

//        // text layer - counter
//        textLayer = CATextLayer()
//        textLayer.frame = view.bounds
//        let fontName: CFString = "Noteworthy-Light" as CFString
//        textLayer.font = CTFontCreateWithName(fontName, 30, nil)
//        textLayer.foregroundColor = UIColor.darkGray.cgColor
//        textLayer.isWrapped = true
//        textLayer.alignmentMode = kCAAlignmentLeft
//        textLayer.frame = CGRect(origin: CGPoint.init(x: 8, y: UIScreen.main.bounds.size.height - 58) , size: CGSize(width: 50, height: 50))
//        view.layer.addSublayer(textLayer)
//        
//        // overlay layer
//        let overlayLayer = CALayer()
//        overlayLayer.frame = view.layer.bounds
//        overlayLayer.addSublayer(textLayer)
//        
//        // parent layer
//        let parentLayer = CALayer()
//        parentLayer.frame = view.layer.bounds
//        
//        parentLayer.addSublayer(previewLayer)
//        parentLayer.addSublayer(overlayLayer)
//        
//        view.layer.addSublayer(parentLayer)
//        
//        let layercomposition = AVMutableVideoComposition()
//        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: previewLayer, in: parentLayer)
        
        captureSession.startRunning();
        
        self.title = "Barcode Reader"
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning();
        }
        
//        textLayer.string = maxTime.string
        
        counter = 0
        maxTime = 5
        
        // handled fire every 1 second
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector:  #selector(ScannerViewController.timerCount), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning();
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        timer.invalidate()
        
        var postImage: UIImage?
        
        var code = ""

        if let videoConnection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider(data: imageData as! CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.up)
                    postImage = image
                }
            })
        }
        
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject;
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
//            found(code: readableObject.stringValue);
            code = readableObject.stringValue
        }
        
//        // if more than 3 second
//        let seconds : TimeInterval = NSDate().timeIntervalSince1970
//        // wait until image captured
//        while (postImage == nil) {
//            // do notjing            
//            let seconds2 : TimeInterval = NSDate().timeIntervalSince1970
//            if (seconds2 - seconds > 3) {
//                postImage = view.screenshot()
//            }
//        }
        
        self.blockDone!([code as AnyObject, postImage != nil ? postImage! : NSNull()] as [AnyObject])
        
        if let r = self.root {
            self.navigationController?.popToViewController(r, animated: true)
        }
        
        dismiss(animated: true)
    }
    
    func found(code: String) {
        print(code)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func timerCount() {
        counter += 1
//        self.textLayer.string = (maxTime - counter).string
        if counter == maxTime {
            savePicture()
        }
    }
    
    func savePicture() {
        timer.invalidate()
        
        var postImage: UIImage?
        if let videoConnection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider(data: imageData as! CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.up)
                    postImage = image
                }
            })
        }
        
        captureSession.stopRunning()
        
//        // if more than 3 second
//        let seconds : TimeInterval = NSDate().timeIntervalSince1970
//        // wait until image captured
//        while (postImage == nil) {
//            // do notjing
//            let seconds2 : TimeInterval = NSDate().timeIntervalSince1970
//            if (seconds2 - seconds > 3) {
//                postImage = view.screenshot()
//            }
//        }
        
        self.blockDone!(["" as AnyObject, postImage != nil ? postImage! : NSNull()] as [AnyObject])
        
        if let r = self.root {
            self.navigationController?.popToViewController(r, animated: true)
        }
    }
}
