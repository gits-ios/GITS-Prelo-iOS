//
//  UserProfileViewController.swift
//  Prelo
//
//  Created by Fransiska on 8/24/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation

class UserProfileViewController : BaseViewController {
    
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var btnLoginInstagram: UIButton!
    @IBOutlet weak var btnLoginFacebook: UIButton!
    @IBOutlet weak var btnLoginTwitter: UIButton!
    @IBOutlet weak var btnLoginPath: UIButton!
    
    @IBOutlet weak var fieldTentangShop: UITextView!
    @IBOutlet weak var fieldTentangShopHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Border untuk tombol login social media
        btnLoginInstagram.layer.borderWidth = 1
        btnLoginFacebook.layer.borderWidth = 1
        btnLoginTwitter.layer.borderWidth = 1
        btnLoginPath.layer.borderWidth = 1
        btnLoginInstagram.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnLoginFacebook.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnLoginTwitter.layer.borderColor = UIColor.lightGrayColor().CGColor
        btnLoginPath.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        let fieldTentangShopHeight = fieldTentangShop.frame.size.height
        var sizeThatShouldFitTheContent = fieldTentangShop.sizeThatFits(fieldTentangShop.frame.size)
        println("sizeThatShouldFitTheContent.height = \(sizeThatShouldFitTheContent.height)")
        // Tambahkan tinggi scrollview content sesuai dengan penambahan tinggi textview
        contentViewHeightConstraint.constant = contentViewHeightConstraint.constant + sizeThatShouldFitTheContent.height - fieldTentangShopHeight
        // Update tinggi textview
        fieldTentangShopHeightConstraint.constant = sizeThatShouldFitTheContent.height
    }
    
    // TODO: Update tinggi textview sembari mengisi
}