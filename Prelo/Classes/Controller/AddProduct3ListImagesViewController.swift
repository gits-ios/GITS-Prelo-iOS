//
//  AddProduct3ListImagesViewController.swift
//  Prelo
//
//  Created by Djuned on 8/15/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class AddProduct3ListImagesViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var images: Array<UIImage?> = []
    var maxImages = 10
    
    func setupTableView() {
        // Setup table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        //TOP, LEFT, BOTTOM, RIGHT
        let inset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.contentInset = inset
        
        tableView.separatorStyle = .none
        
        tableView.backgroundColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let AddProduct3ListImagesCell = UINib(nibName: "AddProduct3ListImagesCell", bundle: nil)
        tableView.register(AddProduct3ListImagesCell, forCellReuseIdentifier: "AddProduct3ListImagesCell")
        
        self.setupTableView()
    }
    
    @IBAction func btnAddImagesPressed(_ sender: Any) {
        if self.maxImages - self.images.count > 0 {
            let pickerController = DKImagePickerController()
            
            pickerController.didSelectAssets = { (assets: [DKAsset]) in
                //print("didSelectAssets")
                //print(assets)
                
                for asset in assets {
                    asset.fetchOriginalImage(true, completeBlock: { img, info in
                        self.images.append(img)
                    })
                }
                
                self.tableView.reloadData()
            }
            
            pickerController.maxSelectableCount = self.maxImages - self.images.count
            pickerController.showsEmptyAlbums = false
            pickerController.allowMultipleTypes = false
            
            self.present(pickerController, animated: true) {}
        } else {
            Constant.showDialog("Ambil Gambar", message: "Gambar sudah maksimal")
        }
    }
}

extension AddProduct3ListImagesViewController: UITableViewDelegate, UITableViewDataSource {
    // TODO: - tableview action
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AddProduct3ListImagesCell.heightFor()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddProduct3ListImagesCell") as! AddProduct3ListImagesCell
        
        cell.adapt(self.images[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

class AddProduct3ListImagesCell: UITableViewCell {
    @IBOutlet weak var imgPreview: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imgPreview.contentMode = .scaleAspectFill
        
        self.selectionStyle = .none
        self.alpha = 1.0
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
    }
    
    func adapt(_ image: UIImage?) {
        self.imgPreview.image = image ?? UIImage(named: "placeholder-standar-white")
    }
    
    static func heightFor() -> CGFloat {
        return 98
    }
}
