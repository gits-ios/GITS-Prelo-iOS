//
//  ScannerViewController.swift
//  Prelo
//
//  Created by Djuned on 1/6/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
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
    
    var blockDone : BlockScanner?
    
    var counter = 0
    var timer = Timer()
    
    @IBOutlet weak var previewLayerParent: UIView!
    @IBOutlet weak var lblTimer: UILabel!
    
    @IBOutlet weak var barcodeCapturedView : UIView!
    // 5 detik
    var maxTime = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Barcode Reader"
        
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
        
        //---view to display a border around the captured barcode---
//        barcodeCapturedView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        //---draw a yellow border around the barcode scanned---
        barcodeCapturedView.layer.borderColor = Theme.PrimaryColor.cgColor
        barcodeCapturedView.layer.borderWidth = 5
        
        // iamge preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
        previewLayer.frame = view.layer.bounds;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//        view.layer.addSublayer(previewLayer);
        
        self.previewLayerParent.layer.addSublayer(previewLayer)
        
        // rotate to landscap
        lblTimer.transform = CGAffineTransform(rotationAngle: 1.5708 ) // radian = 90 degree
        lblTimer.textColor = Theme.PrimaryColor
        
        captureSession.startRunning();
        
    }
    
    func failed() {
        /*
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
         */
        
        Constant.showDialog("Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.")
        
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning();
        }
        
        counter = 0
        maxTime = 5
        lblTimer.text = maxTime.string
        
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
        
//        var barcodeCapturedRect = CGRect.zero
        
        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject;
//            barcodeCapturedRect = readableObject.bounds;
            
//            //---outline the barcode that is detected---
//            barcodeCapturedView.frame = barcodeCapturedRect;
            
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
        
        _ = self.navigationController?.popViewController(animated: true)
        
        dismiss(animated: true)
    }
    
    func found(code: String) {
        //print(code)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func timerCount() {
        counter += 1
        
        lblTimer.text = (maxTime - counter).string
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
        
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Override layout
    //
//    override func viewWillLayoutSubviews() {
//        
//        if previewLayer != nil {
//            
//            // Orientation
//            
//            if (previewLayer!.connection.isVideoOrientationSupported == true) {
//                
//                var newOrientation : AVCaptureVideoOrientation?
//                
//                switch UIDevice.current.orientation {
//                case UIDeviceOrientation.portrait:
//                    newOrientation = AVCaptureVideoOrientation.portrait
//                case UIDeviceOrientation.portraitUpsideDown:
//                    newOrientation = AVCaptureVideoOrientation.portraitUpsideDown
//                case UIDeviceOrientation.landscapeLeft:
//                    newOrientation = AVCaptureVideoOrientation.landscapeRight;
//                case UIDeviceOrientation.landscapeRight:
//                    newOrientation = AVCaptureVideoOrientation.landscapeLeft
//                default:
//                    newOrientation = AVCaptureVideoOrientation.portrait
//                }
//                
//                previewLayer!.connection.videoOrientation = newOrientation!
//                
//            }
//            
//            // Frame
//            
//            previewLayer!.bounds = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height)
//            
//            previewLayer!.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
//            
//            previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
//            
//        }
//    }
}
