//
//  CircleMenuViewController.swift
//  Prelo
//
//  Created by Djuned on 8/20/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class CircleMenuViewController: KYCircleMenu {
    var root: BaseViewController!
    var screenBefore = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.colorWithColor(UIColor.black, alpha: 0.75)
        
        let swipeButtonDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeButtonDown.direction = UISwipeGestureRecognizerDirection.down
        
        self.centerButton.addGestureRecognizer(swipeButtonDown)
    }
    
    override func runButtonActions(_ sender: Any!) {
        super.runButtonActions(sender)
        
        let addProduct3VC = Bundle.main.loadNibNamed(Tags.XibNameAddProduct3, owner: nil, options: nil)?.first as! AddProductViewController3
        addProduct3VC.screenBeforeAddProduct = self.screenBefore
        
        if (sender as AnyObject).tag == 2 {
            addProduct3VC.product.addProductType = .rent
        }
        
        self.dismiss(animated: true, completion: {
            self.root.navigationController?.pushViewController(addProduct3VC, animated: true)
        })
    }
    
    // MARK: - Swipe Navigation Override
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.down:
                //print("Swiped right")
                
                self.dismiss(animated: true, completion: nil)
                
            default:
                break
            }
        }
    }
}
