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
    @NSManaged var name: String
    @NSManaged var packageId: String
    @NSManaged var email: String

    static func newOne(_ cpID : String, email : String, name : String) -> CartProduct?
    {
        let m = UIApplication.appDelegate.managedObjectContext
        let c = NSEntityDescription.insertNewObject(forEntityName: "CartProduct", into: m) as! CartProduct
        c.cpID = cpID
        c.email = email
        c.packageId = ""
        c.name = name
        
        if (m.saveSave() == false) {
            return nil
        } else {
            return c
        }
    }
    
    static func registerAllAnonymousProductToEmail(_ email : String)
    {
        let all = CartProduct.getAll("")
        for cp in all
        {
            cp.email = email
        }
        
        UIApplication.appDelegate.saveContext()
    }
    
    static func getOne(_ itemID : String, email : String) -> CartProduct?
    {
        let fetchReq = NSFetchRequest(entityName: "CartProduct")
        let p1 = NSPredicate(format: "email ==[c] %@", email)
        let p2 = NSPredicate(format: "cpID ==[c] %@", itemID)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq) as? [CartProduct]
            
            return r?.first
        } catch
        {
            return nil
        }
    }
    
    static func isExist(_ itemID : String, email : String) -> Bool
    {
        return CartProduct.getOne(itemID, email : email) != nil
    }
    
    static func getAll(_ email : String) -> [CartProduct]
    {
        let fetchReq = NSFetchRequest(entityName: "CartProduct")
        let p1 = NSPredicate(format: "email ==[c] %@", email)
        fetchReq.predicate = p1
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq) as? [CartProduct]
            
            if (r == nil) {
                return []
            } else {
//                return (r?.sorted{ $0.name < $1.name})!
                return (r?.sorted(by: {c1, c2 in
                    return c1.name < c2.name
                }))!
            }
        } catch {
            return []
        }
    }
    
    static func getAllAsDictionary(_ email : String) -> [[String : String]]
    {
        var array : [[String : String]] = []
        
        let f = CartProduct.getAll(email)
        
        for cp in f
        {
            array.append(cp.toDictionary)
        }
        
        return array
    }
    
    static func deleteAll() {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "CartProduct")
        fetchRequest.includesPropertyValues = false
        
        do {
            if let results = try m.fetch(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    m.delete(result)
                }
                
                if (m.saveSave() != false) {
                    print("deleteAll CartProduct success")
                } else {
                    print("deleteAll CartProduct failed")
                }
            }
        } catch {
            print("deleteAll CartProduct failed")
        }
        print("deleteAll CartProduct success")
    }
    
    var toDictionary : [String : String]
    {
        return ["product_id":self.cpID, "email":self.email, "shipping_package_id":packageId]
    }
}
