//
//  CartProduct.swift
//  Prelo
//
//  Created by Rahadian Kumang on 8/4/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CartProduct)
class CartProduct: NSManagedObject {

    @NSManaged var cpID: String
    @NSManaged var email: String

    static func newOne(cpID : String) -> CartProduct?
    {
        let m = UIApplication.appDelegate.managedObjectContext
        let c = NSEntityDescription.insertNewObjectForEntityForName("CartProduct", inManagedObjectContext: m!) as! CartProduct
        c.cpID = cpID
        c.email = User.EmailOrEmptyString
        var err : NSError?
        if ((m?.save(&err))! == false) {
            return nil
        } else {
            return c
        }
    }
    
    static func getOne(itemID : String) -> CartProduct?
    {
        let fetchReq = NSFetchRequest(entityName: "CartProduct")
        let p1 = NSPredicate(format: "email ==[c] %@", User.EmailOrEmptyString)
        let p2 = NSPredicate(format: "cpID ==[c] %@", itemID)
        let predicate = NSCompoundPredicate.andPredicateWithSubpredicates([p1, p2])
        fetchReq.predicate = predicate
        
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err) as? [CartProduct]
        
        return r?.first
    }
    
    static func isExist(itemID : String) -> Bool
    {
        return CartProduct.getOne(itemID) != nil
    }
    
    static func getAll() -> [CartProduct]
    {
        let fetchReq = NSFetchRequest(entityName: "CartProduct")
        let p1 = NSPredicate(format: "email ==[c] %@", User.EmailOrEmptyString)
        fetchReq.predicate = p1
        
        var err : NSError?
        let r = UIApplication.appDelegate.managedObjectContext?.executeFetchRequest(fetchReq, error: &err) as? [CartProduct]
        
        if (r == nil) {
            return []
        } else {
            return r!
        }
    }
}
