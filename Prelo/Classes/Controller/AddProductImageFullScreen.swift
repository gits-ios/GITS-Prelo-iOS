//
//  AddProductImageFullScreen.swift
//  Prelo
//
//  Created by Rahadian Kumang on 10/29/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit

protocol AddProductImageFullScreenDelegate
{
    func imageFullScreenDidDelete(_ controller : AddProductImageFullScreen)
    func imageFullScreenDidReplace(_ controller : AddProductImageFullScreen, image : APImage, isCamera : Bool, name : String)
}

class AddProductImageFullScreen: BaseViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate /* AVIARY IS DISABLED , AdobeUXImageEditorViewControllerDelegate*/
{

    @IBOutlet var btnDelete : UIBarButtonItem!
    @IBOutlet var btnEdit : UIBarButtonItem!
    @IBOutlet var btnReplace : UIBarButtonItem!
    @IBOutlet var toolBar : UIToolbar!
    @IBOutlet var imageView : UIImageView!
    @IBOutlet var buttonItemsWithoutDelete : Array<UIBarButtonItem> = []
    @IBOutlet var popOverSourceView: UIView!
    var index = 0
    var apImage : APImage!
    var isCamera : Bool = false
    var name : String = ""
    
    /* AVIARY IS DISABLED var imgEditor : AdobeUXImageEditorViewController?*/
    
    var disableDelete = false
    
    var fullScreenDelegate : AddProductImageFullScreenDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if (disableDelete)
        {
            toolBar.setItems(buttonItemsWithoutDelete, animated: false)
        }
        
        toolBar.barTintColor = Theme.PrimaryColor
        
        imageView.image = apImage.image
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Batal", style: UIBarButtonItemStyle.plain, target: self, action: #selector(AddProductImageFullScreen.batal))
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Selesai", style: UIBarButtonItemStyle.Plain, target: self, action: "done")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func batal()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done()
    {
        fullScreenDelegate?.imageFullScreenDidReplace(self, image: apImage, isCamera: isCamera, name: name)
        self.batal()
    }
    
    @IBAction func deleteImage(_ sender : UIView?)
    {
        fullScreenDelegate?.imageFullScreenDidDelete(self)
        self.batal()
    }
    
    @IBAction func replace(_ sender : UIView?)
    {
//        let i = UIImagePickerController()
//        i.sourceType = .PhotoLibrary
//        i.delegate = self
//        self.presentViewController(i, animated: true, completion: nil)
        let i = UIImagePickerController()
        i.sourceType = .photoLibrary
        i.delegate = self
        
        if (UIImagePickerController.isSourceTypeAvailable(.camera))
        {
            let a = UIAlertController(title: "Ambil gambar dari:", message: nil, preferredStyle: .actionSheet)
            a.popoverPresentationController?.sourceView = popOverSourceView
            a.popoverPresentationController?.sourceRect = popOverSourceView.bounds
            a.addAction(UIAlertAction(title: "Kamera", style: .default, handler: { act in
                i.sourceType = .camera
                self.present(i, animated: true, completion: {
                    
                })
            }))
            a.addAction(UIAlertAction(title: "Album", style: .default, handler: { act in
                self.present(i, animated: true, completion: {
                    
                })
            }))
            a.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { act in }))
            self.present(a, animated: true, completion: nil)
        } else
        {
            self.present(i, animated: true, completion: {
                
            })
        }
        
//        ImagePickerViewController.ShowFrom(self, maxSelect: 1, useAviary:true, doneBlock: { imgs in
//            if (imgs.count > 0)
//            {
//                let a = imgs[0]
//                a.getImage({ img in
//                    if let i = img
//                    {
//                        self.apImage.image = i
//                        self.imageView.image = i
//                    }
//                })
//            }
//        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            self.apImage.image = img
            self.imageView.image = img
        }
        
        if picker.sourceType == .camera {
            isCamera = true
        } else  {
            let imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
            let imageName = imageURL.path!.lastPathComponent + "_" + index.string
            name = imageName
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.navigationBar.tintColor = UIColor.white
    }
    
    @IBAction func edit(_ sender : UIView?)
    {
        /* AVIARY IS DISABLED
        AdobeImageEditorCustomization.setToolOrder([kAdobeImageEditorCrop, kAdobeImageEditorOrientation])
        AdobeImageEditorCustomization.setLeftNavigationBarButtonTitle("")
//        let u = AdobeUXImageEditorViewController(image: apImage.image)
//        u.delegate = self
//        self.presentViewController(u, animated: true, completion: nil)
        
        imgEditor = AdobeUXImageEditorViewController(image: apImage.image)
        imgEditor!.delegate = self
        self.presentViewController(imgEditor!, animated: true, completion: nil)
        */
    }
    
    /* AVIARY IS DISABLED
    func photoEditorCanceled(editor: AdobeUXImageEditorViewController!) {
        editor.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func photoEditor(editor: AdobeUXImageEditorViewController!, finishedWithImage image: UIImage!) {
//        apImage.image = image
//        imageView.image = image
//        editor.dismissViewControllerAnimated(true, completion: nil)
        
        let render = imgEditor?.enqueueHighResolutionRenderWithImage(image, maximumSize: CGSizeMake(1600, 1600), completion: { result, error in
            if (result != nil) {
                self.apImage.image = result
                self.imageView.image = result
            } else {
                print("Error highres render: \(error)")
                self.apImage.image = image
                self.imageView.image = image
            }
            editor.dismissViewControllerAnimated(true, completion: nil)
        })
    }
    */
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
