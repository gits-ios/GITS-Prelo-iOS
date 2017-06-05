//
//  DummyGridViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 9/23/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

import UIKit

class DummyGridViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {

    @IBOutlet var gridView : UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        gridView.dataSource = self
        gridView.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) 
        return c
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print("SELECT")
    }
    
    var dragging = false
    var currPoint = CGPoint.zero
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        currPoint = scrollView.contentOffset
        dragging = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (dragging) {
            if (currPoint.y < scrollView.contentOffset.y) {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
            } else {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        dragging = false
    }
}
