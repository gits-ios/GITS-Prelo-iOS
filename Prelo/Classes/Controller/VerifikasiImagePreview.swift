//
//  VerifikasiImagePreview.swift
//  Prelo
//
//  Created by Prelo on 6/20/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

protocol VerifikasiImagePreviewDelegate
{
    func imageFullScreenDidDelete(_ controller : VerifikasiImagePreview)
    func imageFullScreenDidReplace(_ controller : VerifikasiImagePreview, image : APImage, isCamera : Bool, name : String)
}

class VerifikasiImagePreview: BaseViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate /* AVIARY IS DISABLED , AdobeUXImageEditorViewControllerDelegate*/
{
    
    @IBOutlet var btnDelete : UIBarButtonItem!
    @IBOutlet var btnEdit : UIBarButtonItem!
    @IBOutlet var btnReplace : UIBarButtonItem!
    @IBOutlet var toolBar : UIToolbar!
    @IBOutlet var imageView : UIImageView!
    @IBOutlet var buttonItemsWithoutDelete : Array<UIBarButtonItem> = []
    @IBOutlet var popOverSourceView: UIView!
    var index : Int?
    var apImage : APImage?
    var isCamera : Bool = false
    var name : String = ""
    
    /* AVIARY IS DISABLED var imgEditor : AdobeUXImageEditorViewController?*/
    
    var disableDelete = false
    
    var fullScreenDelegate : VerifikasiImagePreviewDelegate?
    
    override func viewDidAppear(_ animated: Bool) {
        if (disableDelete)
        {
            toolBar.setItems(buttonItemsWithoutDelete, animated: false)
        }
        
        toolBar.barTintColor = Theme.PrimaryColor
        
        imageView.image = apImage?.image
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Batal", style: UIBarButtonItemStyle.plain, target: self, action: #selector(VerifikasiImagePreview.batal))
        //        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Selesai", style: UIBarButtonItemStyle.Plain, target: self, action: "done")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        
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
        print("masuk sini ga?")
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func done()
    {
        fullScreenDelegate?.imageFullScreenDidReplace(self, image: apImage!, isCamera: isCamera, name: name)
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
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            self.apImage?.image = img
            self.imageView.image = img
        }
        
        if picker.sourceType == .camera {
            isCamera = true
        } else  {
            let imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
            let imageName = imageURL.path!.lastPathComponent + "_" + (index?.string)!
            name = imageName
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.navigationBar.tintColor = UIColor.white
    }
    
    @IBAction func edit(_ sender : UIView?)
    {
        
    }
    
}
