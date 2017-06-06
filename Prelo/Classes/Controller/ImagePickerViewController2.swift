//
//  ImagePickerViewController2.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/11/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class ImagePickerViewController2: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    
    var maxSelectCount : Int = 1
    var selecteds : Array<IndexPath> = []
    
    var images : Array<APImage> = []
    
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
                Constant.showDialog("Warning", message: m)
        })
        
        self.title = String(selecteds.count) + "/" + String(maxSelectCount) + " Selected"
    }
    
    // FIXME: Swift 3
//    override func dismiss() {
//        self.doneBlock!([])
//        super.dismiss()
//    }
    
    override func confirm() {
        var r : [APImage] = []
        for i in selecteds
        {
            r.append(images[(i as NSIndexPath).item-cameraAdd])
        }
        self.dismiss(animated: true, completion: {
            self.doneBlock!(r)
        })
    }
    
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
    
    static func ShowFrom(_ v : UIViewController, maxSelect : Int, doneBlock : @escaping ImagePickerBlock)
    {
        let n = BaseViewController.instatiateViewControllerFromStoryboardWithID(Tags.StoryBoardIdImagePicker) as! UINavigationController
        let i = n.viewControllers.first as! ImagePickerViewController2
        i.maxSelectCount = maxSelect
        i.doneBlock = doneBlock
        v.present(n, animated: true, completion: nil)
    }
    
    var picker : UIImagePickerController?
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.picker = picker
        //print(info)
        let apImage = APImage()
        apImage.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        let r : [APImage] = [apImage]
        self.doneBlock!(r)
        
        picker.dismiss(animated: true, completion: {
            self.dismiss(animated: true, completion: nil)
        })
        //        UIImageWriteToSavedPhotosAlbum(info[UIImagePickerControllerOriginalImage] as! UIImage, self, "savedDone", nil)
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
