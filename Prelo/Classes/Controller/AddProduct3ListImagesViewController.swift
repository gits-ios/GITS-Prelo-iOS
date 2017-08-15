//
//  AddProduct3ListImagesViewController.swift
//  Prelo
//
//  Created by Djuned on 8/15/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

typealias BlockImagesSelected = (_ images: Array<PreviewImage>, _ index: Array<Int>) -> ()

class AddProduct3ListImagesViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var previewImages: Array<PreviewImage> = []
    var index: Array<Int> = []
    var maxImages = 10
    
    var labels: Array<String> = []
    
    // Delegate
    var blockDone : BlockImagesSelected?
    
    func setupTableView() {
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.contentInset = inset
        
        //tableView.separatorStyle = .none
        
        tableView.backgroundColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let AddProduct3ListImagesCell = UINib(nibName: "AddProduct3ListImagesCell", bundle: nil)
        tableView.register(AddProduct3ListImagesCell, forCellReuseIdentifier: "AddProduct3ListImagesCell")
        
        self.setupTableView()
        self.setEditButton()
        
        // MARK: - GESTURE HACK
        
        // swipe gesture for carbon (pop view)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        
        let vwLeft = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: UIScreen.main.bounds.height))
        vwLeft.backgroundColor = UIColor.clear
        vwLeft.addGestureRecognizer(swipeRight)
        self.view.addSubview(vwLeft)
        self.view.bringSubview(toFront: vwLeft)
        
        self.title = "Pilih Gambar"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    @IBAction func btnAddImagesPressed(_ sender: Any) {
        if self.maxImages - self.previewImages.count > 0 {
            let pickerController = DKImagePickerController()
            
            pickerController.didSelectAssets = { (assets: [DKAsset]) in
                //print("didSelectAssets")
                //print(assets)
                
                for asset in assets {
                    asset.fetchOriginalImage(true, completeBlock: { img, info in
                        self.previewImages.append(PreviewImage(image: img, url: "", label: "", labelOther: ""))
                        self.index.append(self.previewImages.count-1)
                    })
                }
                
                self.tableView.reloadData()
            }
            
            pickerController.maxSelectableCount = self.maxImages - self.previewImages.count
            pickerController.showsEmptyAlbums = false
            pickerController.allowMultipleTypes = false
            pickerController.showsCancelButton = true
            
            // gesture override
            //self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            
            self.present(pickerController, animated: true) {}
        } else {
            Constant.showDialog("Ambil Gambar", message: "Gambar sudah maksimal")
        }
    }
    
    override func backPressed(_ sender: UIBarButtonItem) {
        self.blockDone!(self.previewImages, self.index)
        
        // gesture override
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Swipe Navigation Override
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                //print("Swiped right")
                
                self.blockDone!(self.previewImages, self.index)
                
                // gesture override
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                
                _ = self.navigationController?.popViewController(animated: true)
                
            default:
                break
            }
        }
    }
    
    // MARK: - Edit Profile button (right top)
    func setEditButton() {
        let btnEdit = self.createButtonWithIcon(UIImage(named: "ic_edit_white")!)
        
        btnEdit.addTarget(self, action: #selector(AddProduct3ListImagesViewController.editTable), for: UIControlEvents.touchUpInside)
        
        self.navigationItem.rightBarButtonItem = btnEdit.toBarButton()
    }
    
    func editTable() {
        self.tableView.isEditing = !self.tableView.isEditing
    }
    
    // MARK: - Helper
    func removeImageFromArray(_ index: Int) {
        let idx = self.index[index]
        self.previewImages.remove(at: idx)
        
        for i in 0..<self.index.count {
            if self.index[i] > idx {
                self.index[i] -= 1
            }
        }
        
        self.index.remove(at: index)
    }
}

extension AddProduct3ListImagesViewController: UITableViewDelegate, UITableViewDataSource {
    // TODO: - tableview action
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.previewImages.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AddProduct3ListImagesCell.heightFor()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ListImagesCell") as! AddProduct3ListImagesCell
        
        cell.adapt(self.previewImages[self.index[indexPath.row]])
        
        return cell
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        
//    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove = self.index[sourceIndexPath.row]
        self.index.remove(at: sourceIndexPath.row)
        self.index.insert(itemToMove, at: destinationIndexPath.row)
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: .destructive, title: "Hapus") { action, index in
            self.removeImageFromArray(indexPath.row)
            
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        return [remove]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.tableView.isEditing {
            return true
        }
        return false
    }
}

class AddProduct3ListImagesCell: UITableViewCell {
    @IBOutlet weak var imgPreview: UIImageView!
    @IBOutlet weak var lblLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imgPreview.contentMode = .scaleAspectFill
        imgPreview.layer.cornerRadius = 0
        imgPreview.layer.masksToBounds = true
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ previewImage: PreviewImage) {
        self.imgPreview.image = previewImage.image ?? UIImage(named: "placeholder-standar-white")
        
        self.lblLabel.text = "coba" //previewImage.label
    }
    
    static func heightFor() -> CGFloat {
        return 98
    }
}
