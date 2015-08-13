//
//  AddProductImageSourceViewController.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/12/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import UIKit
import AssetsLibrary

class AddProductImageSourceViewController: BaseViewController, UICollectionViewDataSource, ImageSourceCellDelegate {
    
    @IBOutlet var gridView : UICollectionView?
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var arrayProductRow : Array<ProductRowView> = []
    
    var arrayImages : [APImage] = []
    
    var _dragDropView : UIImageView?
    var dragDropView : UIImageView?
    {
        set {
            _dragDropView?.hidden = true
        }
        get {
            if (_dragDropView == nil) {
                _dragDropView = UIImageView(frame: CGRectMake(0, 0, 128, 128))
                _dragDropView?.backgroundColor = UIColor.clearColor()
                _dragDropView?.contentMode = UIViewContentMode.ScaleAspectFit
                self.view.addSubview(_dragDropView!)
            }
            _dragDropView?.hidden = false
            return _dragDropView!
        }
    }
    
    var currentDragImage : APImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        ImageSupplier.fetch(ImageSource.Gallery, complete: { r in
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
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ImageSourceCell
        c.apImage = arrayImages[indexPath.item]
        c.cellDelegate = self
        
        return c
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        
        println("touchesMoved")
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        println("touchesEnded")
        
        dragDropView = nil
        highlightProductRowView()
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)
        println("touchesCancelled")
        
        dragDropView = nil
        highlightProductRowView()
    }
    
    func imageSourceCellBeginDrag(cell: ImageSourceCell) {
        if (cell.longPress?.state == UIGestureRecognizerState.Ended || cell.longPress?.state == UIGestureRecognizerState.Cancelled || cell.longPress?.state == UIGestureRecognizerState.Failed) {
            cell.hidden = false
            dragDropView = nil
        } else {
            
            let p = cell.longPress?.locationInView(self.view)
            println("begin drag | x : " + String(Int((p?.x)!)) + ", y : " + String(Int((p?.y)!)))
            if (cell.longPress?.state == UIGestureRecognizerState.Began) {
                cell.hidden = true
                dragDropView?.center = (gridView?.convertPoint(cell.center, toView: self.view))!
                UIView.animateWithDuration(0.2, animations: {
                    dragDropView?.center = p!
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
        println("highlightting")
        let h = (dragDropView?.hidden)!
        for p in arrayProductRow
        {
            let r = scrollView.convertRect(p.frame, toView: self.view)
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
        if ((_dragDropView?.hidden)! == false) {
            let y = _dragDropView?.center.y
            if (y > UIScreen.mainScreen().bounds.size.height-128) {
                let p = scrollView.contentOffset
                var p2 = CGPointMake(p.x, p.y+CGFloat(1))
                
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
    func highlight(h : Bool)
    {
        if (h) {
            self.backgroundColor = UIColor.grayColor()
        } else {
            self.backgroundColor = UIColor.clearColor()
        }
    }
}

protocol ImageSourceCellDelegate
{
    func imageSourceCellBeginDrag(cell : ImageSourceCell)
}

class ImageSourceCell : UICollectionViewCell, UIGestureRecognizerDelegate
{
    static var defaultImage = UIImage(named: "dummy@2x.jpg")
    
    @IBOutlet var ivCover : UIImageView!
    
    var cellDelegate : ImageSourceCellDelegate?
    var longPress : UILongPressGestureRecognizer?
    
    var asset : ALAssetsLibrary?
    
    private var _apImage : APImage?
    var apImage : APImage?
    {
        set {
            _apImage = newValue
            ivCover.image = ImageSourceCell.defaultImage
            
            if ((_apImage?.usingAssets)! == true) {
                
                if (asset == nil) {
                    asset = ALAssetsLibrary()
                }
                
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    asset?.assetForURL((_apImage?.url)!, resultBlock: { asset in
                        if let ast = asset {
                            let rep = ast.defaultRepresentation()
                            let ref = rep.fullScreenImage().takeUnretainedValue()
                            let i = UIImage(CGImage: ref)
                            dispatch_async(dispatch_get_main_queue(), {
                                self.ivCover.image = i
                            })
                        }
                        }, failureBlock: { error in
                            
                    })
                })
            } else {
                ivCover.setImageWithUrl((_apImage?.url)!, placeHolderImage: nil)
            }
        }
        get {
            return _apImage
        }
    }
    
    @IBAction func longPressed(sender : UIGestureRecognizer)
    {
        cellDelegate?.imageSourceCellBeginDrag(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if (longPress == nil) {
            longPress = UILongPressGestureRecognizer(target: self, action: "longPressed:")
            self.addGestureRecognizer(longPress!)
        }
    }
}
