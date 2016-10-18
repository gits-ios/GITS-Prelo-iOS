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

class ImagePickerViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate /*, AVIARY IS DISABLED AdobeUXImageEditorViewControllerDelegate*/
{
    
    var useAviary = false
    var directToCameraFirst = true
    var directToCamera = false
    
    var maxSelectCount : Int = 1
    var selecteds : Array<IndexPath> = []
    
    var images : Array<APImage> = []
    
    /* AVIARY IS DISABLED var imgEditor : AdobeUXImageEditorViewController?*/
    
    @IBOutlet var gridView : UICollectionView!
    
    var doneBlock : ImagePickerBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navigationItem.leftBarButtonItem = self.dismissButton.toBarButton()
        self.navigationItem.rightBarButtonItem = self.confirmButton.toBarButton()
        
        ImageSupplier.fetch(ImageSource.gallery, complete: {r in
                self.images = r
                self.gridView.dataSource = self
                self.gridView.delegate = self
            }, failed: { m in
                UIAlertView.SimpleShow("Warning", message: m)
        })
        
        self.title = String(selecteds.count) + "/" + String(maxSelectCount) + " Selected"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (cameraAdd == 1 && directToCamera && directToCameraFirst)
        {
            let i = UIImagePickerController()
            i.sourceType = UIImagePickerControllerSourceType.camera
            i.delegate = self
            self.present(i, animated: true, completion: nil)
            directToCameraFirst = false
        }
    }
    
    // FIXME: Swift 3
//    override func dismiss() {
//        self.doneBlock!([])
//        super.dismiss()
//    }
    
    override func confirm() {
        
        if (useAviary && maxSelectCount == 1)
        {
            /* AVIARY IS DISABLED
            var ap : APImage = APImage()
            for i in selecteds
            {
                ap = images[i.item-cameraAdd]
            }
            ap.getImage({ img in
                AdobeImageEditorCustomization.setToolOrder([kAdobeImageEditorCrop, kAdobeImageEditorOrientation])
//                let u = AdobeUXImageEditorViewController(image: img)
//                u.delegate = self
//                self.presentViewController(u, animated: false, completion: nil)
                self.imgEditor = AdobeUXImageEditorViewController(image: img)
                self.imgEditor!.delegate = self
                self.presentViewController(self.imgEditor!, animated: true, completion: nil)
            })
            */
        } else
        {
            var r : [APImage] = []
            for i in selecteds
            {
                r.append(images[(i as NSIndexPath).item-cameraAdd])
            }
            self.dismiss(animated: true, completion: {
                self.doneBlock!(r)
            })
        }
    }
    
    /* AVIARY IS DISABLED
    func photoEditorCanceled(editor: AdobeUXImageEditorViewController!) {
        self.doneBlock!([])
        editor.dismissViewControllerAnimated(false, completion: {
            self.dismissViewControllerAnimated(true, completion: nil)
        })
    }
    
    func photoEditor(editor: AdobeUXImageEditorViewController!, finishedWithImage image: UIImage!) {
//        let ap = APImage()
//        ap.image = image
//        editor.dismissViewControllerAnimated(false, completion: {
//            self.dismissViewControllerAnimated(true, completion: {
//                self.doneBlock!([ap])
//            })
//        })
        
        let render = imgEditor?.enqueueHighResolutionRenderWithImage(image, maximumSize: CGSizeMake(1600, 1600), completion: { result, error in
            let ap = APImage()
            if (result != nil) {
                ap.image = result
            } else {
                print("Error highres render: \(error)")
                ap.image = image
            }
            editor.dismissViewControllerAnimated(false, completion: {
                self.dismissViewControllerAnimated(true, completion: {
                    self.doneBlock!([ap])
                })
            })

        })
    }
    */
    
    var cameraAdd = UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.rear) == true ? 1 : 0
    var cameraBase = UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.rear) == true ? 0 : -1
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count + cameraAdd
    }
    
    var cameraCell : UICollectionViewCell?
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var c : ImagePickerCell!
        
        if ((indexPath as NSIndexPath).item == cameraBase)
        {
            c = collectionView.dequeueReusableCell(withReuseIdentifier: "cell_video", for: indexPath) as! ImagePickerCell
            c.isCamera = true
            c.startCamera()
            c.captionSelected.isHidden = true
            return c!
        } else
        {
            c = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImagePickerCell
            c.isCamera = false
//            if let i = find(selecteds, indexPath)
            if selecteds.index(of: indexPath) != nil
            {
                c.captionSelected.isHidden = false
            } else // not found
            {
                c.captionSelected.isHidden = true
            }
            
            c.apImage = images[(indexPath as NSIndexPath).item-cameraAdd]
            
            return c
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(20, 8, 20, 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    var size = CGSize(width: (UIScreen.main.bounds.width-24)/2, height: (UIScreen.main.bounds.width-24)/2)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if ((indexPath as NSIndexPath).item == cameraBase)
        {
            let c = collectionView.cellForItem(at: indexPath) as! ImagePickerCell
            if let s = c.session
            {
                s.stopRunning()
            }
            
            let i = UIImagePickerController()
            i.sourceType = UIImagePickerControllerSourceType.camera
            i.delegate = self
            self.present(i, animated: true, completion: nil)
        } else
        {
            if let i = selecteds.index(of: indexPath)
            {
                selecteds.remove(at: i)
                let c = collectionView.cellForItem(at: indexPath) as! ImagePickerCell
                c.captionSelected.isHidden = true
            } else // not found
            {
                if (selecteds.count < maxSelectCount)
                {
                    selecteds.append(indexPath)
                    let c = collectionView.cellForItem(at: indexPath) as! ImagePickerCell
                    c.captionSelected.isHidden = false
                }
            }
            self.title = String(selecteds.count) + "/" + String(maxSelectCount) + " Selected"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func ShowFrom(_ v : UIViewController, maxSelect : Int, useAviary : Bool = false, diretToCamera : Bool = false, doneBlock : @escaping ImagePickerBlock)
    {
        let n = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdImagePicker) as! UINavigationController
        let i = n.viewControllers.first as! ImagePickerViewController
        i.maxSelectCount = maxSelect
        i.doneBlock = doneBlock
        i.useAviary = false /* AVIARY IS DISABLED useAviary*/
        i.directToCamera = diretToCamera
        v.present(n, animated: true, completion: nil)
    }
    
    var picker : UIImagePickerController?
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.picker = picker
        print(info)
        let apImage = APImage()
        apImage.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        let r : [APImage] = [apImage]
        self.doneBlock!(r)
        
        picker.dismiss(animated: true, completion: {
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        gridView.reloadData()
    }
    
    func savedDone()
    {
        picker?.dismiss(animated: true, completion: {
            self.dismiss(animated: true, completion: {
                
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
    
    fileprivate var _apImage : APImage?
    fileprivate var _url : String = ""
    var apImage : APImage?
        {
        set {
            _apImage = newValue
            ivCover.image = nil
            
            if ((_apImage?.usingAssets)! == true) {
                
                if (asset == nil) {
                    asset = ALAssetsLibrary()
                }
                
                
                _url = (_apImage?.url)!.absoluteString
                DispatchQueue.global( priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
                    self.asset?.asset(for: URL(string: self._url)!, resultBlock: { asset in
                        if let ast = asset {
                            let ref = ast.thumbnail().takeUnretainedValue()
                            let i = UIImage(cgImage: ref)
                            let url = ast.defaultRepresentation().url().absoluteString
                            DispatchQueue.main.async(execute: {
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
            
        }
    }
    
    func startCamera()
    {
        if (session == nil)
        {
            session = AVCaptureSession()
            session?.sessionPreset = AVCaptureSessionPresetLow
        } else if ((session?.isRunning)! == true)
        {
            return
        } else {
            session?.startRunning()
            return
        }
        
        ivCover.isHidden = true
        
        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
        captureVideoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        let s = CGSize(width: (UIScreen.main.bounds.width-24)/2, height: (UIScreen.main.bounds.width-24)/2)
        captureVideoPreviewLayer?.frame = CGRect(x: 0, y: 0, width: s.height, height: s.height)
        camera.backgroundColor = UIColor.yellow
        camera.layer.addSublayer(captureVideoPreviewLayer!)
        
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: device) as AVCaptureInput
            session?.addInput(input)
            session?.startRunning()
        } catch {
            print("CAMERA ERROR")
        }
    }
}
