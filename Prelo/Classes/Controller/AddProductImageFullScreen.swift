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
    func imageFullScreenDidDelete(controller : AddProductImageFullScreen)
    func imageFullScreenDidReplace(controller : AddProductImageFullScreen, image : APImage)
}

class AddProductImageFullScreen: BaseViewController, UIScrollViewDelegate/* AVIARY IS DISABLED , AdobeUXImageEditorViewControllerDelegate*/
{

    @IBOutlet var btnDelete : UIBarButtonItem!
    @IBOutlet var btnEdit : UIBarButtonItem!
    @IBOutlet var btnReplace : UIBarButtonItem!
    @IBOutlet var toolBar : UIToolbar!
    @IBOutlet var imageView : UIImageView!
    @IBOutlet var buttonItemsWithoutDelete : Array<UIBarButtonItem> = []
    var index = 0
    var apImage : APImage!
    
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
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Batal", style: UIBarButtonItemStyle.Plain, target: self, action: "batal")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Selesai", style: UIBarButtonItemStyle.Plain, target: self, action: "done")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func batal()
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func done()
    {
        fullScreenDelegate?.imageFullScreenDidReplace(self, image: apImage)
        self.batal()
    }
    
    @IBAction func deleteImage(sender : UIView?)
    {
        fullScreenDelegate?.imageFullScreenDidDelete(self)
    }
    
    @IBAction func replace(sender : UIView?)
    {
        ImagePickerViewController.ShowFrom(self, maxSelect: 1, useAviary:true, doneBlock: { imgs in
            if (imgs.count > 0)
            {
                let a = imgs[0]
                a.getImage({ img in
                    if let i = img
                    {
                        self.apImage.image = i
                        self.imageView.image = i
                    }
                })
            }
        })
    }
    
    @IBAction func edit(sender : UIView?)
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
                println("Error highres render: \(error)")
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
