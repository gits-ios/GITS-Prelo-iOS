//
//  ImagePickerViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/20/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import AVFoundation

typealias ImagePickerBlock = ([APImage]) -> ()

class ImagePickerViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var maxSelectCount : Int = 1
    var selecteds : Array<NSIndexPath> = []
    
    var images : Array<APImage> = []
    
    @IBOutlet var gridView : UICollectionView!
    
    var doneBlock : ImagePickerBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navigationItem.leftBarButtonItem = self.dismissButton.toBarButton()
        self.navigationItem.rightBarButtonItem = self.confirmButton.toBarButton()
        
        ImageSupplier.fetch(ImageSource.Gallery, complete: {r in
                self.images = r
                self.gridView.dataSource = self
                self.gridView.delegate = self
            }, failed: { m in
                UIAlertView.SimpleShow("Warning", message: m)
        })
        
        self.title = String(selecteds.count) + "/" + String(maxSelectCount) + " Selected"
    }
    
    override func dismiss() {
        self.doneBlock!([])
        super.dismiss()
    }
    
    override func confirm() {
        var r : [APImage] = []
        for i in selecteds
        {
            r.append(images[i.item-cameraAdd])
        }
        self.doneBlock!(r)
        self.dismiss()
    }
    
    var cameraAdd = UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.Rear) == true ? 1 : 0
    var cameraBase = UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.Rear) == true ? 0 : -1
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count + cameraAdd
    }
    
    var cameraCell : UICollectionViewCell?
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var c : ImagePickerCell!
        
        if (indexPath.item == cameraBase)
        {
            c = collectionView.dequeueReusableCellWithReuseIdentifier("cell_video", forIndexPath: indexPath) as! ImagePickerCell
            c.isCamera = true
            c.startCamera()
            c.captionSelected.hidden = true
            return c!
        } else
        {
            c = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ImagePickerCell
            c.isCamera = false
            if let i = find(selecteds, indexPath)
            {
                c.captionSelected.hidden = false
            } else // not found
            {
                c.captionSelected.hidden = true
            }
            
            c.apImage = images[indexPath.item-cameraAdd]
            
            return c
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(20, 8, 20, 8)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 8
    }
    
    var size = CGSizeMake((UIScreen.mainScreen().bounds.width-24)/2, (UIScreen.mainScreen().bounds.width-24)/2)
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return size
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if (indexPath.item == cameraBase)
        {
            let c = collectionView.cellForItemAtIndexPath(indexPath) as! ImagePickerCell
            if let s = c.session
            {
                s.stopRunning()
            }
            
            let i = UIImagePickerController()
            i.sourceType = UIImagePickerControllerSourceType.Camera
            i.delegate = self
            self.presentViewController(i, animated: true, completion: nil)
        } else
        {
            if let i = find(selecteds, indexPath)
            {
                selecteds.removeAtIndex(i)
                let c = collectionView.cellForItemAtIndexPath(indexPath) as! ImagePickerCell
                c.captionSelected.hidden = true
            } else // not found
            {
                if (selecteds.count < maxSelectCount)
                {
                    selecteds.append(indexPath)
                    let c = collectionView.cellForItemAtIndexPath(indexPath) as! ImagePickerCell
                    c.captionSelected.hidden = false
                }
            }
            self.title = String(selecteds.count) + "/" + String(maxSelectCount) + " Selected"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func ShowFrom(v : UIViewController, maxSelect : Int, doneBlock : ImagePickerBlock)
    {
        let n = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdImagePicker) as! UINavigationController
        let i = n.viewControllers.first as! ImagePickerViewController
        i.maxSelectCount = maxSelect
        i.doneBlock = doneBlock
        v.presentViewController(n, animated: true, completion: nil)
    }
    
    var picker : UIImagePickerController?
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        self.picker = picker
        println(info)
        let apImage = APImage()
        apImage.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        var r : [APImage] = [apImage]
        self.doneBlock!(r)
        
        picker.dismissViewControllerAnimated(true, completion: {
            self.dismissViewControllerAnimated(true, completion: nil)
        })
//        UIImageWriteToSavedPhotosAlbum(info[UIImagePickerControllerOriginalImage] as! UIImage, self, "savedDone", nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        gridView.reloadData()
    }
    
    func savedDone()
    {
        picker?.dismissViewControllerAnimated(true, completion: {
            self.dismissViewControllerAnimated(true, completion: {
                
            })
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

class ImagePickerCell : UICollectionViewCell
{
    @IBOutlet var ivCover : UIImageView!
    @IBOutlet var camera : UIView!
    @IBOutlet var captionSelected : UILabel!
    
    var asset : ALAssetsLibrary?
    
    var isCamera : Bool = false
    var session : AVCaptureSession?
    
    private var _apImage : APImage?
    private var _url : String = ""
    var apImage : APImage?
        {
        set {
            _apImage = newValue
            ivCover.image = nil
            
            if ((_apImage?.usingAssets)! == true) {
                
                if (asset == nil) {
                    asset = ALAssetsLibrary()
                }
                
                
                _url = (_apImage?.url)!.absoluteString!
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    asset?.assetForURL(NSURL(string: _url)!, resultBlock: { asset in
                        if let ast = asset {
//                            let rep = ast.defaultRepresentation()
                            let ref = ast.thumbnail().takeUnretainedValue()
                            let i = UIImage(CGImage: ref)
                            let url = ast.defaultRepresentation().url().absoluteString
                            dispatch_async(dispatch_get_main_queue(), {
                                if (self._url == url)
                                {
                                    self.ivCover.image = i
                                }
                            })
                        }
                        }, failureBlock: { error in
                            
                    })
                })
            } else if let i = _apImage?.image
            {
                ivCover.image = i
            } else {
                ivCover.setImageWithUrl((_apImage?.url)!, placeHolderImage: nil)
            }
        }
        get {
            return _apImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if (session != nil)
        {
//            session?.stopRunning()
//            session = nil
//            ivCover.hidden = false
        }
    }
    
    func startCamera()
    {
        if (session == nil)
        {
            session = AVCaptureSession()
            session?.sessionPreset = AVCaptureSessionPresetLow
        } else if ((session?.running)! == true)
        {
            return
        } else {
            session?.startRunning()
            return
        }
        
        ivCover.hidden = true
        
        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        let s = CGSizeMake((UIScreen.mainScreen().bounds.width-24)/2, (UIScreen.mainScreen().bounds.width-24)/2)
        captureVideoPreviewLayer.frame = CGRectMake(0, 0, s.height, s.height)
        camera.backgroundColor = UIColor.yellowColor()
        camera.layer.addSublayer(captureVideoPreviewLayer)
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        var error : NSError?
        let input = AVCaptureDeviceInput.deviceInputWithDevice(device, error: &error) as? AVCaptureInput
        if (input == nil)
        {
            println("CAMERA ERROR")
        } else
        {
            session?.addInput(input!)
            session?.startRunning()
        }
    }
}
