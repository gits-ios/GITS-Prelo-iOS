//
//  ShareProfileViewController.swift
//  Prelo
//
//  Created by Djuned on 5/5/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

// MARK: - Class
class ShareProfileViewController: BaseViewController, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: - Properties
    @IBOutlet weak var coverScrollView: UIScrollView! // define image of cover(s) here -> UIImageView (pagination)
    @IBOutlet weak var imgAvatar: UIImageView! // user
    @IBOutlet weak var mediaCollectionView: UICollectionView! // twitter, fb, etc
    @IBOutlet weak var btnPrev: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var lbSeller: UILabel!
    @IBOutlet weak var lbReferral: UILabel!
    
    var images: [String] = []
    var currentPage = 0
    var medias: [String] = []
    var isSelectedMedias: [Bool] = []
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup scorll-view
        self.coverScrollView?.isPagingEnabled = true
        self.coverScrollView?.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.2)
        self.coverScrollView?.delegate = self
        
        // setup media
        self.setupCollection()
        
        self.title = "Share Profile Shop"
        
        let uProf = CDUserProfile.getOne()
        if (uProf != nil) {
            let url = URL(string: uProf!.pict)
            if (url != nil) {
                self.imgAvatar?.afSetImage(withURL: url!, withFilter: .circle)
            }
        }
        
        self.lbSeller.text = CDUser.getOne()?.username
        
        self.lbReferral.text = "gunakan kode referral xxx\nuntuk mendapatkan potongan Rp25.000"
        
        self.medias = [
            "https://static.pexels.com/photos/23049/pexels-photo.jpg",
            "http://wallpapercave.com/wp/ZfzZaSM.jpg",
            "http://wallpaper-gallery.net/images/mountain-wallpaper/mountain-wallpaper-9.jpg",
            "http://wallpaper-gallery.net/images/mountain-wallpaper/mountain-wallpaper-12.jpg",
            "http://wallpaper-gallery.net/images/mountain-images-wallpaper/mountain-images-wallpaper-8.jpg",
            "https://i2.wp.com/techbeasts.com/wp-content/uploads/2016/12/4435004-mountain-wallpapers.jpeg"
        ]
        
        self.isSelectedMedias = [false, false, false, false, false, false]
        
        self.mediaCollectionView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // setup avatar
        self.imgAvatar?.layer.cornerRadius = (self.imgAvatar?.frame.size.width)!/2
        self.imgAvatar?.layer.masksToBounds = true
        
        // setup prev-next
        self.btnPrev.layer.cornerRadius = (self.btnPrev.frame.size.width)/2
        self.btnPrev.layer.masksToBounds = true
        
        self.btnNext.layer.cornerRadius = (self.btnNext.frame.size.width)/2
        self.btnNext.layer.masksToBounds = true
        
        // setup UI
        self.getCover()
    }
    
    func getCover() {
        self.images = [
            "https://trello-attachments.s3.amazonaws.com/55e7c516d9cac863ec924c21/57a1eff3c17d8b09447106bc/74e353fb6d62b48409fb8906854f1f30/all_category.png",
            "https://trello-attachments.s3.amazonaws.com/55e7c516d9cac863ec924c21/57a1eff3c17d8b09447106bc/0496b4318e3f9478d2d92f98dc9db6e6/hobby.png",
            "https://trello-attachments.s3.amazonaws.com/55e7c516d9cac863ec924c21/57a1eff3c17d8b09447106bc/a4d9e2ec77b04d857ed8ec9a57499436/gadget.png",
            "https://trello-attachments.s3.amazonaws.com/55e7c516d9cac863ec924c21/57a1eff3c17d8b09447106bc/72ade007cdd1664d0f8513a8887b1d85/fashion.png",
            "https://trello-attachments.s3.amazonaws.com/55e7c516d9cac863ec924c21/57a1eff3c17d8b09447106bc/4e3d0e8678a22eeb1199dac5694a6b68/book.png",
            "https://trello-attachments.s3.amazonaws.com/55e7c516d9cac863ec924c21/57a1eff3c17d8b09447106bc/f58e2638a4f524332b1dd7f5ed5e7cba/beauty.png"
        ]
        
        self.setupCover()
    }
    
    func setupCover() {
        var x : CGFloat = 0
        for i in 0...self.images.count - 1
        {
            let s = UIScrollView(frame : (self.coverScrollView?.bounds)!)
            let iv = UIImageView(frame : s.bounds)
            iv.afSetImage(withURL: URL(string: self.images[i])!, withFilter: .fit)
            iv.tag = 1
            s.addSubview(iv)
            s.x = x
            self.coverScrollView?.addSubview(s)
            
            s.delegate = self
            
            x += s.width
        }
    }
    
    func setupCollection() {
        
        // Set collection view
        self.mediaCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "collcProgressCell")
        self.mediaCollectionView.delegate = self
        self.mediaCollectionView.dataSource = self
        self.mediaCollectionView.backgroundView = UIView(frame: self.mediaCollectionView.bounds)
        self.mediaCollectionView.backgroundColor = UIColor.clear
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.scrollDirection = .horizontal
        self.mediaCollectionView.collectionViewLayout = layout
        
        self.mediaCollectionView.isScrollEnabled = true
        self.mediaCollectionView.isPagingEnabled = false
        self.mediaCollectionView.isDirectionalLockEnabled = true
    }
    
    // MARK: - ScrollView delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView == self.coverScrollView)
        {
            var p : CGFloat = 0
            if (scrollView.bounds.width > 0) {
                p = scrollView.contentOffset.x / scrollView.bounds.width
            }
            if (currentPage != Int(p + 0.5))
            {
                currentPage = Int(p + 0.5)
            }
        }
    }
    
    // MARK: - CollectionView delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.medias.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create cell
        let cell = self.mediaCollectionView.dequeueReusableCell(withReuseIdentifier: "collcProgressCell", for: indexPath)
        cell.viewWithTag(999)?.removeFromSuperview()
        
        // Create icon view
        let vwIcon : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        vwIcon.tag = 999
        
        let img = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        img.layoutIfNeeded()
        img.layer.cornerRadius = (img.width) / 2
        img.layer.masksToBounds = true
        img.afSetImage(withURL: URL(string: medias[(indexPath as NSIndexPath).item])!, withFilter: .circleWithBadgePlaceHolder)
        
        if !self.isSelectedMedias[(indexPath as IndexPath).item] {
            let vwTinted = UIView(frame: img.bounds)
            vwTinted.backgroundColor = UIColor.colorWithColor(UIColor.white, alpha: 0.7)
            
            img.addSubview(vwTinted)
        }
        
        vwIcon.addSubview(img)
        
        // Add view to cell
        cell.addSubview(vwIcon)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.isSelectedMedias[(indexPath as IndexPath).item] = !self.isSelectedMedias[(indexPath as IndexPath).item]
        
        self.mediaCollectionView.reloadData()
    }
    
    func scrollSubVC(_ index: Int) {
        self.coverScrollView.setContentOffset(CGPoint(x: CGFloat(CGFloat(index) * self.coverScrollView.bounds.width), y: CGFloat(0)), animated: true)
    }
    
    // MARK: - button
    @IBAction func btnPrevPressed(_ sender: Any) {
        self.scrollSubVC((self.images.count+currentPage-1) % self.images.count)
    }
    
    @IBAction func btnNextPressed(_ sender: Any) {
        self.scrollSubVC((self.images.count+currentPage+1) % self.images.count)
    }
}
