//
//  CDDraftProduct.swift
//  Prelo
//
//  Created by Djuned on 1/4/17.
//  Copyright © 2017 GITS Indonesia. All rights reserved.
//

import Foundation
import CoreData

@objc(CDDraftProduct)
class CDDraftProduct: NSManagedObject {
    
    @NSManaged var localId: String
    @NSManaged var name: String
    @NSManaged var descriptionText : String
    @NSManaged var weight : String
    @NSManaged var freeOngkir : NSNumber
    @NSManaged var priceOriginal : String
    @NSManaged var price : String
    @NSManaged var commission : String
    @NSManaged var category : String
    @NSManaged var categoryId : String
    @NSManaged var isCategWomenOrMenSelected : Bool
    @NSManaged var condition : String
    @NSManaged var conditionId : String
    @NSManaged var brand : String
    @NSManaged var brandId : String
    @NSManaged var imagePath1 : String
    @NSManaged var imagePath2 : String
    @NSManaged var imagePath3 : String
    @NSManaged var imagePath4 : String
    @NSManaged var imagePath5 : String
    @NSManaged var imageOrientation1 : NSNumber
    @NSManaged var imageOrientation2 : NSNumber
    @NSManaged var imageOrientation3 : NSNumber
    @NSManaged var imageOrientation4 : NSNumber
    @NSManaged var imageOrientation5 : NSNumber
    @NSManaged var size : String
    @NSManaged var defectDescription : String
    @NSManaged var sellReason : String
    @NSManaged var specialStory : String
    @NSManaged var luxuryData_styleName : String
    @NSManaged var luxuryData_serialNumber : String
    @NSManaged var luxuryData_purchaseLocation : String
    @NSManaged var luxuryData_purchaseYear : String
    @NSManaged var luxuryData_originalBox : String
    @NSManaged var luxuryData_originalDustbox : String
    @NSManaged var luxuryData_receipt : String
    @NSManaged var luxuryData_authenticityCard : String
    
    @NSManaged var isUploading : Bool
    
    static func getAll() -> [CDDraftProduct] {
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDDraftProduct")
        fetchReq.sortDescriptors = [NSSortDescriptor(key: "localId", ascending: false)]
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq) as? [CDDraftProduct]
            return r!
        } catch {
            return []
        }
    }
    
    static func deleteAll() -> Bool {
        let m = UIApplication.appDelegate.managedObjectContext
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDDraftProduct")
        fetchRequest.includesPropertyValues = false
        
        do {
            let r = try m.fetch(fetchRequest) as? [NSManagedObject]
            if let results = r
            {
                for result in results {
                    m.delete(result)
                }
                
                if (m.saveSave() != false) {
                    print("deleteAll CDDraftProduct success")
                }
            }
        } catch
        {
            return false
        }
        
        return true
    }
    
    static func getAllIsDraft() -> [CDDraftProduct] {
        let predicate = NSPredicate(format: "isUploading != %@", NSNumber(value: true as Bool))
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDDraftProduct")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq) as? [CDDraftProduct]
            return r!
        } catch {
            return []
        }
    }
    
    static func getOne(_ localId: String) -> CDDraftProduct? {
        let predicate = NSPredicate(format: "localId == %@", localId)
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDDraftProduct")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : r.first as? CDDraftProduct
        } catch {
            return nil
        }
    }
    
    static func getOneIsUploading() -> CDDraftProduct? {
        let predicate = NSPredicate(format: "isUploading == %@", NSNumber(value: true as Bool))
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDDraftProduct")
        fetchReq.predicate = predicate
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : r.first as? CDDraftProduct
        } catch {
            return nil
        }
    }
    
//    static func getCount() -> Int {
//        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDDraftProduct")
//        
//        do {
//            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq);
//            return r.count
//        } catch {
//            return 0
//        }
//    }
    
    // new localId = -1
    static func saveDraft(_ localId: String, name: String, descriptionText : String, weight : String, freeOngkir : Int, priceOriginal : String, price : String, commission : String, category : String, categoryId : String, isCategWomenOrMenSelected : Bool, condition : String, conditionId : String, brand : String, brandId : String, imagePath : [String], imageOrientation : [Int], size : String, defectDescription : String, sellReason : String, specialStory : String, luxuryData : [String]) {
        
        let m = UIApplication.appDelegate.managedObjectContext
        let draft : CDDraftProduct? = self.getOne(localId)
        if (draft != nil) {
            // Update
            draft?.name = name
            draft?.descriptionText = descriptionText
            draft?.weight = weight
            draft?.freeOngkir = NSNumber(value: freeOngkir)
            draft?.priceOriginal = priceOriginal
            draft?.price = price
            draft?.commission = commission
            draft?.category = category
            draft?.categoryId = categoryId
            draft?.isCategWomenOrMenSelected = isCategWomenOrMenSelected
            draft?.condition = condition
            draft?.conditionId = conditionId
            draft?.brand = brand
            draft?.brandId = brandId
            draft?.imagePath1 = imagePath[0]
            draft?.imagePath2 = imagePath[1]
            draft?.imagePath3 = imagePath[2]
            draft?.imagePath4 = imagePath[3]
            draft?.imagePath5 = imagePath[4]
            draft?.imageOrientation1 = NSNumber(value: imageOrientation[0])
            draft?.imageOrientation2 = NSNumber(value: imageOrientation[1])
            draft?.imageOrientation3 = NSNumber(value: imageOrientation[2])
            draft?.imageOrientation4 = NSNumber(value: imageOrientation[3])
            draft?.imageOrientation5 = NSNumber(value: imageOrientation[4])
            draft?.size = size
            draft?.defectDescription = defectDescription
            draft?.sellReason = sellReason
            draft?.specialStory = specialStory
            draft?.luxuryData_styleName = luxuryData[0]
            draft?.luxuryData_serialNumber = luxuryData[1]
            draft?.luxuryData_purchaseLocation = luxuryData[2]
            draft?.luxuryData_purchaseYear = luxuryData[3]
            draft?.luxuryData_originalBox = luxuryData[4]
            draft?.luxuryData_originalDustbox = luxuryData[5]
            draft?.luxuryData_receipt = luxuryData[6]
            draft?.luxuryData_authenticityCard = luxuryData[7]
        } else {
            // Make new
            let newVer = NSEntityDescription.insertNewObject(forEntityName: "CDDraftProduct", into: m) as! CDDraftProduct
            newVer.localId = localId // generate when save
            newVer.name = name
            newVer.descriptionText = descriptionText
            newVer.weight = weight
            newVer.freeOngkir = NSNumber(value: freeOngkir)
            newVer.priceOriginal = priceOriginal
            newVer.price = price
            newVer.commission = commission
            newVer.category = category
            newVer.categoryId = categoryId
            newVer.isCategWomenOrMenSelected = isCategWomenOrMenSelected
            newVer.condition = condition
            newVer.conditionId = conditionId
            newVer.brand = brand
            newVer.brandId = brandId
            newVer.imagePath1 = imagePath[0]
            newVer.imagePath2 = imagePath[1]
            newVer.imagePath3 = imagePath[2]
            newVer.imagePath4 = imagePath[3]
            newVer.imagePath5 = imagePath[4]
            newVer.imageOrientation1 = NSNumber(value: imageOrientation[0])
            newVer.imageOrientation2 = NSNumber(value: imageOrientation[1])
            newVer.imageOrientation3 = NSNumber(value: imageOrientation[2])
            newVer.imageOrientation4 = NSNumber(value: imageOrientation[3])
            newVer.imageOrientation5 = NSNumber(value: imageOrientation[4])
            newVer.size = size
            newVer.defectDescription = defectDescription
            newVer.sellReason = sellReason
            newVer.specialStory = specialStory
            newVer.luxuryData_styleName = luxuryData[0]
            newVer.luxuryData_serialNumber = luxuryData[1]
            newVer.luxuryData_purchaseLocation = luxuryData[2]
            newVer.luxuryData_purchaseYear = luxuryData[3]
            newVer.luxuryData_originalBox = luxuryData[4]
            newVer.luxuryData_originalDustbox = luxuryData[5]
            newVer.luxuryData_receipt = luxuryData[6]
            newVer.luxuryData_authenticityCard = luxuryData[7]
        }
        
        if (m.saveSave() == false) {
            print("saveDraft failed")
        } else {
            print("saveDraft success")
        }
    }
    
    static func setUploading(_ localId: String, isUploading: Bool) {
        let m = UIApplication.appDelegate.managedObjectContext
        let draft : CDDraftProduct? = self.getOne(localId)
        if (draft != nil) {
            draft?.isUploading = isUploading
        }
        
        if (m.saveSave() == false) {
            print("saveDraft failed")
        } else {
            print("saveDraft success")
        }
    }
    
    static func delete(_ localId: String) {
        let m = UIApplication.appDelegate.managedObjectContext
        let result : CDDraftProduct? = self.getOne(localId)
        if (result != nil) {
            m.delete(result!)
        }
        if (m.saveSave() != false) {
            print("deleteDraft success")
        } else {
            print("deleteDraft failed")
        }
    }
    
    static func isLuxury(_ localId: String) -> Bool {
        let result : CDDraftProduct? = self.getOne(localId)
        if (result != nil) {
            return !(result!.luxuryData_styleName == "" &&
                result!.luxuryData_serialNumber == "" &&
                result!.luxuryData_purchaseLocation == "" &&
                result!.luxuryData_purchaseYear == "" &&
                result!.luxuryData_originalBox == "" &&
                result!.luxuryData_originalDustbox == "" &&
                result!.luxuryData_receipt == "" &&
                result!.luxuryData_authenticityCard == "")
        } else {
            return false
        }
    }

    static func getImagePaths(_ localId: String) -> Array<String> {
        let result : CDDraftProduct? = self.getOne(localId)
        var imagePaths : Array<String> = []
        if (result != nil) {
            imagePaths.append(result!.imagePath1)
            imagePaths.append(result!.imagePath2)
            imagePaths.append(result!.imagePath3)
            imagePaths.append(result!.imagePath4)
            imagePaths.append(result!.imagePath5)
        } else {
            imagePaths.append("")
            imagePaths.append("")
            imagePaths.append("")
            imagePaths.append("")
            imagePaths.append("")
        }
        return imagePaths
    }
    
    static func getImageOrientations(_ localId: String) -> Array<Int> {
        let result : CDDraftProduct? = self.getOne(localId)
        var imageOrientation : Array<Int> = []
        if (result != nil) {
            imageOrientation.append(result!.imageOrientation1 as Int)
            imageOrientation.append(result!.imageOrientation2 as Int)
            imageOrientation.append(result!.imageOrientation3 as Int)
            imageOrientation.append(result!.imageOrientation4 as Int)
            imageOrientation.append(result!.imageOrientation5 as Int)
        } else {
            imageOrientation.append(0)
            imageOrientation.append(0)
            imageOrientation.append(0)
            imageOrientation.append(0)
            imageOrientation.append(0)
        }
        return imageOrientation
    }
}
