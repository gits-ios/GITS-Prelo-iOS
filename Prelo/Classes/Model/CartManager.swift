//
//  CartManager.swift
//  Prelo
//
//  Created by Djuned on 5/4/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

// For Checkout V2

import Foundation

class CartManager: NSObject {
    static let sharedInstance = CartManager()
    
    fileprivate static var cartProductsKey = "cartproducts" // UserDefaultsKey
    
    fileprivate func getCart() -> Array<[String : Any]> {
        var currentCart: Array<[String : Any]> = []
        
        if let x = UserDefaults.standard.array(forKey: CartManager.cartProductsKey) {
            currentCart = x as! Array<[String : Any]>
        }
        
        return currentCart
    }
    
    fileprivate func saveCart(_ cartProducts: Array<[String : Any]>) {
        UserDefaults.standard.set(cartProducts, forKey: CartManager.cartProductsKey)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - CRUD
    func insertProduct(_ sellerId: String, productId: String) -> Bool {
        let currentCart: Array<[String : Any]> = self.getCart()
        var newCart: Array<[String : Any]> = []
        
        var isOke = false
        
        for c in currentCart {
            var _c = c
            if (c["seller_id"] as! String) == sellerId {
                var pIds = c["product_ids"] as! Array<String>
                if pIds.contains(productId) {
                    return false
                } else {
                    pIds.append(productId)
                    _c["product_ids"] = pIds
                    
                    isOke = true
                }
            }
            newCart.append(_c)
        }
        
        if !isOke {
            let _c: [String : Any] = [
                "seller_id" : sellerId,
                "product_ids" : [productId],
                "shipping_package_id" : ""
            ]
            newCart.append(_c)
            
            isOke = true
        }
        
        self.saveCart(newCart)
        return isOke
    }
    
    func updateShippingPackageId(_ sellerId: String, shippingPackageId: String) {
        let currentCart: Array<[String : Any]> = self.getCart()
        var newCart: Array<[String : Any]> = []
        
        for c in currentCart {
            var _c = c
            if (c["seller_id"] as! String) == sellerId {
                _c["shipping_package_id"] = shippingPackageId
            }
            newCart.append(_c)
        }
        
        self.saveCart(newCart)
    }
    
    func deleteProduct(_ sellerId: String, productId: String) {
        let currentCart: Array<[String : Any]> = self.getCart()
        var newCart: Array<[String : Any]> = []
        
        for c in currentCart {
            var _c = c
            if (c["seller_id"] as! String) == sellerId {
                var pIds = c["product_ids"] as! Array<String>
                if let idx = pIds.index(of: productId) {
                    if pIds.count > 1 {
                        pIds.remove(at: idx)
                        _c["product_ids"] = pIds
                        newCart.append(_c)
                    }
                }
            } else {
                newCart.append(_c)
            }
        }
        
        self.saveCart(newCart)
    }
    
    func getCartJsonString() -> String {
        let currentCart: Array<[String : Any]> = self.getCart()
        return AppToolsObjC.jsonString(from: currentCart)
    }
    
    func deleteAll() {
        UserDefaults.standard.set([], forKey: CartManager.cartProductsKey)
        UserDefaults.standard.synchronize()
    }
    
    func getAllProductIds() -> [String] {
        let currentCart: Array<[String : Any]> = self.getCart()
        var _pIds: Array<String> = []
        
        for c in currentCart {
            let pIds = c["product_ids"] as! Array<String>
            
            _pIds.append(contentsOf: pIds)
        }
        
        return _pIds
    }
}
