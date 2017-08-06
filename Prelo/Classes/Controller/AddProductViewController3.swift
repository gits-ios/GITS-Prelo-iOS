//
//  AddProductViewController3.swift
//  Prelo
//
//  Created by Djuned on 8/6/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class

class AddProductViewController3: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingPanel: UIView!
    
}

// MARK: - Title Cell
class AddProduct3ImageTitleCell: UITableViewCell {
    @IBOutlet weak var SectionImage: UIImageView!
    @IBOutlet weak var SectionTitle: UILabel!
    @IBOutlet weak var SectionFAQ: UIView! // ? , hide
    @IBOutlet weak var SectionSubtitle: UILabel! // ?
    
    // 40, 60
    
}

// MARK: - Images Preview Cell
class AddProduct3ImagesPreviewCell: UITableViewCell {
    @IBOutlet weak var collectionView: UICollectionView!
    
    // 158 , count teks height
    
}

class AddProduct3ImagesPreviewCellCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imagesPreview: UIImageView!
    @IBOutlet weak var labelView: UIView! // backgrund
    @IBOutlet weak var label: UILabel!
    
    // 82 x 82
    
}

class AddProduct3ImagesPreviewCellNewOneCell: UICollectionViewCell {
    
    // 82 x 82
    
}

// MARK: - Detail Product Cell
class AddProduct3DetailProductCell: UITableViewCell {
    
}

// MARK: - Weight Cell (Sell)
class AddProduct3WeightCell: UITableViewCell {
    
}

// MARK: - Postal Fee Cell (Sell)
class AddProduct3PostalCell: UITableViewCell {
    
}

// MARK: - Product Auth Verification Cell (Luxury)
class AddProduct3ProductAuthVerificationCell: UITableViewCell {
    
}

// MARK: - Images Checklist Cell
class AddProduct3ImagesChecklistCell: UITableViewCell {
    
}

class AddProduct3ImagesChecklistCellCollectionCell: UICollectionViewCell {
    
}
