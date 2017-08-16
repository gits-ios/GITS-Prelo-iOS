//
//  AddProduct3ListImagesViewController.swift
//  Prelo
//
//  Created by Djuned on 8/15/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation
import DropDown

typealias BlockImagesSelected = (_ images: Array<PreviewImage>, _ index: Array<Int>) -> ()

class AddProduct3ListImagesViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var vwLabels: UIView!
    @IBOutlet weak var consHeightVwLabels: NSLayoutConstraint!
    @IBOutlet weak var btnAddImages: UIButton!
    
    var previewImages: Array<PreviewImage> = []
    var index: Array<Int> = []
    var maxImages = 10
    
    var labels: Array<String> = []
    
    var isFirst = true
    
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
        
        // init dropdown
        DropDown.startListeningToKeyboard()
        let appearance = DropDown.appearance()
        appearance.backgroundColor = UIColor(white: 1, alpha: 1)
        appearance.selectionBackgroundColor = UIColor(red: 0.6494, green: 0.8155, blue: 1.0, alpha: 0.2)
        appearance.separatorColor = UIColor(white: 0.7, alpha: 0.8)
        appearance.cornerRadius = 0
        appearance.shadowColor = UIColor(white: 0.6, alpha: 1)
        appearance.shadowOpacity = 1
        appearance.shadowRadius = 2
        appearance.animationduration = 0.25
        appearance.textColor = .darkGray
        
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
        
        if self.isFirst {
            self.isFirst = false
            
            self.setupLabels()
        }
        
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
                        
                        let lastIndex = self.index.count-1
                        
                        if self.previewImages[self.index[lastIndex]].label == "" {
                            if lastIndex < self.labels.count && !self.isLabelExist(self.labels[lastIndex]) {
                                self.previewImages[self.index[lastIndex]].label = self.labels[lastIndex]
                            } else {
                                self.previewImages[self.index[lastIndex]].label = "Lainnya"
                            }
                        }
                    })
                }
                
                self.tableView.reloadData()
                
                let tinyDelay = DispatchTime.now() + Double(Int64(0.01 * Float(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: tinyDelay, execute: {
                    self.setupLabels()
                })
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
        let applyButton = UIBarButtonItem(title: "", style:UIBarButtonItemStyle.done, target:self, action: #selector(AddProduct3ListImagesViewController.backPressed(_:)))
        
        applyButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Prelo2", size: 18)!], for: UIControlState())
        
        let btnReorder = UIBarButtonItem(title: "", style:UIBarButtonItemStyle.done, target:self, action: #selector(AddProduct3ListImagesViewController.editTable))
        
        btnReorder.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "PreloAwesome", size: 18)!], for: UIControlState())
        
        self.navigationItem.rightBarButtonItems = [ applyButton, btnReorder ]
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
    
    func isLabelExist(_ label: String) -> Bool {
        for i in self.previewImages {
            if i.label == label {
                return true
            }
        }
        return false
    }
    
    func setupLabels() {
        // Remove all first
        self.consHeightVwLabels.constant = 0
        let arrx = vwLabels.subviews
        for v in arrx {
            v.removeFromSuperview()
        }
        
        // Adjust tags
        if self.labels.count > 0 {
            let arr : [String] = self.labels
            var y : CGFloat = 8.0
            var x : CGFloat = 8.0
            let sw = vwLabels.width - 16.0
            var curMaxY : CGFloat = 8.0
            for s in arr {
                if !self.isLabelExist(s) {
                    let tag = SearchTag.instance(s)
                    tag.x = x
                    tag.y = y
                    let maxx = tag.maxX
                    if (maxx > sw) {
                        x = 8.0
                        tag.x = x
                        y = curMaxY + 4.0
                        tag.y = y
                    }
                    
                    if curMaxY < tag.maxY {
                        curMaxY = tag.maxY
                    }
                    
                    let tap = UITapGestureRecognizer(target: self, action: #selector(AddProduct3ListImagesViewController.assignLabel(_:)))
                    tag.addGestureRecognizer(tap)
                    tag.isUserInteractionEnabled = true
                    tag.captionTitle.isUserInteractionEnabled = true
                    
                    self.vwLabels.addSubview(tag)
                    self.consHeightVwLabels.constant = tag.maxY
                    x = tag.maxX + 4.0
                }
            }
            
            if self.consHeightVwLabels.constant > 0 {
                self.consHeightVwLabels.constant += 9.0
                
                let line1px = UIView(frame: CGRect(x: 0, y: self.consHeightVwLabels.constant - 1, width: self.vwLabels.width, height: 1))
                line1px.backgroundColor = UIColor.darkGray
                self.vwLabels.addSubview(line1px)
            }
        }
        
        self.btnAddImages.setTitle("Tambah Gambar (\(self.maxImages - self.previewImages.count))", for: UIControlState.normal)
    }
    
    func assignLabel(_ sender : UITapGestureRecognizer) {
        let searchTag = sender.view as! SearchTag
        let label = searchTag.captionTitle.text
        
        for i in 0..<self.previewImages.count {
            if self.previewImages[self.index[i]].label == "Lainnya" {
                self.previewImages[self.index[i]].label = label!
                self.tableView.reloadRows(at: [IndexPath.init(row: i, section: 0)], with: .fade)
                
                break
            }
        }
        
        self.setupLabels()
        self.tableView.reloadData()
    }
}

extension AddProduct3ListImagesViewController: UITableViewDelegate, UITableViewDataSource {
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
        
        cell.setupDropDown = {
            cell.dropDown.dataSource = []
            
            if self.labels.count == 0 {
                return
            }
            
            var j = 0
            for i in 0..<self.labels.count {
                let label = self.labels[i]
                if !self.isLabelExist(label) || self.previewImages[self.index[indexPath.row]].label == label {
                    cell.dropDown.dataSource.append(label)
                    if label == cell.lblLabel.text {
                        cell.selectedIndex = j
                    }
                    j += 1
                }
            }
            
            // lainnya
            cell.dropDown.dataSource.append("Lainnya")
            if "Lainnya" == cell.lblLabel.text {
                cell.selectedIndex = j
            }
            
            // Action triggered on selection
            cell.dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
                if index != cell.selectedIndex {
                    cell.selectedIndex = index
                    cell.lblLabel.text = item
                    
                    self.previewImages[self.index[indexPath.row]].label = item
                    
                    self.tableView.reloadData()
                    self.setupLabels()
                }
            }
            
            cell.dropDown.textFont = UIFont.systemFont(ofSize: 14)
            cell.dropDown.cellHeight = 40
            cell.dropDown.selectRow(at: cell.selectedIndex)
            cell.dropDown.anchorView = cell.btnPickLabel
            
            // Top of drop down will be below the anchorView
            cell.dropDown.bottomOffset = CGPoint(x: 0, y:(cell.dropDown.anchorView?.plainView.bounds.height)! + 4)
            
            // When drop down is displayed with `Direction.top`, it will be above the anchorView
            cell.dropDown.topOffset = CGPoint(x: 0, y:-(cell.dropDown.anchorView?.plainView.bounds.height)! - 4)
        }
        
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
            
            // update dropDown
            self.setupLabels()
            self.tableView.reloadData()
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
    @IBOutlet weak var btnPickLabel: UIButton!
    
    var dropDown = DropDown()
    var setupDropDown: ()->() = {}
    
    var selectedIndex = -1
    
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
        if previewImage.image == nil && previewImage.url != "" {
            if let url = URL(string: previewImage.url) {
                self.imgPreview.afSetImage(withURL: url)
            } else {
                self.imgPreview.image = UIImage(named: "placeholder-standar-white")
            }
        } else {
            self.imgPreview.image = previewImage.image ?? UIImage(named: "placeholder-standar-white")
        }
        
        self.lblLabel.text = previewImage.label
        
        self.setupDropDown()
    }
    
    static func heightFor() -> CGFloat {
        return 98
    }
    
    @IBAction func btnPickLabelPressed(_ sender: Any) {
        self.dropDown.hide()
        self.dropDown.show()
    }
}
