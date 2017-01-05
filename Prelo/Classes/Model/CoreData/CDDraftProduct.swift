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
    
    static func getOne() -> CDDraftProduct? {
        let fetchReq : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName : "CDDraftProduct")
        
        do {
            let r = try UIApplication.appDelegate.managedObjectContext.fetch(fetchReq)
            return r.count == 0 ? nil : r.first as? CDDraftProduct
        } catch {
            return nil
        }
    }
    
    static func saveDraft(_ name: String, descriptionText : String, weight : String, freeOngkir : NSNumber, priceOriginal : String, price : String, commission : String, category : String, categoryId : String, isCategWomenOrMenSelected : Bool, condition : String, conditionId : String, brand : String, brandId : String, imagePath : [String], size : String, defectDescription : String, sellReason : String, specialStory : String, luxuryData : [String]) {
        
        let m = UIApplication.appDelegate.managedObjectContext
        let draft : CDDraftProduct? = self.getOne()
        if (draft != nil) {
            // Update
            draft?.name = name
            draft?.descriptionText = descriptionText
            draft?.weight = weight
            draft?.freeOngkir = freeOngkir
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
            newVer.name = name
            newVer.descriptionText = descriptionText
            newVer.weight = weight
            newVer.freeOngkir = freeOngkir
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
    
    static func delete() {
        let m = UIApplication.appDelegate.managedObjectContext
        let result : CDDraftProduct? = self.getOne()
        if (result != nil) {
            m.delete(result!)
        }
        if (m.saveSave() != false) {
            print("deleteDraft success")
        } else {
            print("deleteDraft failed")
        }
    }
    
    static func isLuxury() -> Bool {
        let result : CDDraftProduct? = self.getOne()
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

    static func getImagePaths() -> Array<String> {
        let result : CDDraftProduct? = self.getOne()
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
}
