//
//  AddProductImageSourceViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/12/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import AssetsLibrary
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class AddProductImageSourceViewController: BaseViewController, UICollectionViewDataSource, ImageSourceCellDelegate {
    
    @IBOutlet var gridView : UICollectionView?
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var arrayProductRow : Array<ProductRowView> = []
    
    var arrayImages : [APImage] = []
    
    var _dragDropView : UIImageView?
    var dragDropView : UIImageView?
    {
        set {
            _dragDropView?.isHidden = true
        }
        get {
            if (_dragDropView == nil) {
                _dragDropView = UIImageView(frame: CGRect(x: 0, y: 0, width: 128, height: 128))
                _dragDropView?.backgroundColor = UIColor.clear
                _dragDropView?.contentMode = UIViewContentMode.scaleAspectFit
                self.view.addSubview(_dragDropView!)
            }
            _dragDropView?.isHidden = false
            return _dragDropView!
        }
    }
    
    var currentDragImage : APImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        ImageSupplier.fetch(ImageSource.gallery, complete: { r in
            self.arrayImages = r
            self.gridView?.dataSource = self
            }, failed: { m in
            Constant.showDialog("Warning", message: m)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageSourceCell
        c.apImage = arrayImages[(indexPath as NSIndexPath).item]
        c.cellDelegate = self
        
        return c
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        dragDropView = nil
        highlightProductRowView()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        dragDropView = nil
        highlightProductRowView()
    }
    
    func imageSourceCellBeginDrag(_ cell: ImageSourceCell) {
        if (cell.longPress?.state == UIGestureRecognizerState.ended || cell.longPress?.state == UIGestureRecognizerState.cancelled || cell.longPress?.state == UIGestureRecognizerState.failed) {
            cell.isHidden = false
            dragDropView = nil
        } else {
            
            let p = cell.longPress?.location(in: self.view)
            print("begin drag | x : " + String(Int((p?.x)!)) + ", y : " + String(Int((p?.y)!)))
            if (cell.longPress?.state == UIGestureRecognizerState.began) {
                cell.isHidden = true
                dragDropView?.center = (gridView?.convert(cell.center, to: self.view))!
                UIView.animate(withDuration: 0.2, animations: {
                    self.dragDropView?.center = p!
                })
            } else {
                dragDropView?.center = p!
            }
            
            currentDragImage = cell.apImage
            dragDropView?.image = cell.ivCover.image
            highlightProductRowView()
//            adjustScrollView()
        }
    }
    
    var highlightting = false
    func highlightProductRowView()
    {
        if (highlightting) {
            return
        }
        highlightting = true
        print("highlightting")
        let h = (dragDropView?.isHidden)!
        for p in arrayProductRow
        {
            let r = scrollView.convert(p.frame, to: self.view)
            if (r.contains((dragDropView?.center)!) && h == false)
            {
                p.highlight(true)
            } else {
                p.highlight(false)
            }
        }
        highlightting = false
    }
    
    var scrolling = false
    func adjustScrollView()
    {
        if (scrolling) {
            return
        }
        scrolling = true
        if ((_dragDropView?.isHidden)! == false) {
            let y = _dragDropView?.center.y
            if (y > UIScreen.main.bounds.size.height-128) {
                let p = scrollView.contentOffset
                var p2 = CGPoint(x: p.x, y: p.y+CGFloat(1))
                
                if (p2.y > scrollView.contentSize.height-scrollView.height) {
                    p2.y = CGFloat(scrollView.contentSize.height-scrollView.height)
                    scrollView.setContentOffset(p2, animated: true)
                    scrolling = false
                } else {
                    scrollView.setContentOffset(p2, animated: true)
                    scrolling = false
                    adjustScrollView()
                    highlightProductRowView()
                }
            } else {
                scrolling = false
            }
        } else {
            scrolling = false
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

class ProductRowView : UIView
{
    func highlight(_ h : Bool)
    {
        if (h) {
            self.backgroundColor = UIColor.gray
        } else {
            self.backgroundColor = UIColor.clear
        }
    }
}

protocol ImageSourceCellDelegate
{
    func imageSourceCellBeginDrag(_ cell : ImageSourceCell)
}

class ImageSourceCell : UICollectionViewCell, UIGestureRecognizerDelegate
{
    static var defaultImage = UIImage(named: "dummy@2x.jpg")
    
    @IBOutlet var ivCover : UIImageView!
    
    var cellDelegate : ImageSourceCellDelegate?
    var longPress : UILongPressGestureRecognizer?
    
    var asset : ALAssetsLibrary?
    
    fileprivate var _apImage : APImage?
    var apImage : APImage?
    {
        set {
            _apImage = newValue
            ivCover.image = ImageSourceCell.defaultImage
            
            if ((_apImage?.usingAssets)! == true) {
                
                if (asset == nil) {
                    asset = ALAssetsLibrary()
                }
                
                DispatchQueue.global( priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
                    self.asset?.asset(for: (self._apImage?.url)! as URL, resultBlock: { asset in
                        if let ast = asset {
                            let rep = ast.defaultRepresentation()
                            let ref = rep?.fullScreenImage().takeUnretainedValue()
                            let i = UIImage(cgImage: ref!)
                            DispatchQueue.main.async(execute: {
                                self.ivCover.image = i
                            })
                        }
                        }, failureBlock: { error in
                            
                    })
                })
            } else {
                ivCover.afSetImage(withURL: (_apImage?.url)!)
            }
        }
        get {
            return _apImage
        }
    }
    
    @IBAction func longPressed(_ sender : UIGestureRecognizer)
    {
        cellDelegate?.imageSourceCellBeginDrag(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if (longPress == nil) {
            longPress = UILongPressGestureRecognizer(target: self, action: #selector(ImageSourceCell.longPressed(_:)))
            self.addGestureRecognizer(longPress!)
        }
    }
}
