//
//  TemporaryImageManager.swift
//  Prelo
//
//  Created by Djuned on 8/17/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

import Foundation

class TemporaryImageManager: NSObject {
    static let sharedInstance = TemporaryImageManager()
    
    // https://stackoverflow.com/questions/1934852/how-do-i-save-and-read-an-image-to-my-temp-folder-when-quitting-and-loading-my-a
    // Swift 3 xCode 8.2
    
    // Documents directory obtaining:
    func getDocumentDirectoryPath() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
    
    // Saving:
    func saveImageToDocumentsDirectory(image: UIImage, withName: String) -> String? {
        if let data = UIImagePNGRepresentation(image) {
            let dirPath = getDocumentDirectoryPath()
            let imageFileUrl = URL(fileURLWithPath: dirPath.appendingPathComponent(withName) as String)
            do {
                try data.write(to: imageFileUrl)
                print("Successfully saved image at path: \(imageFileUrl)")
                return imageFileUrl.absoluteString
            } catch {
                print("Error saving image: \(error)")
            }
        }
        return nil
    }
    
    // Loading:
    func loadImageFromDocumentsDirectory(imageName: String) -> UIImage? {
        let tempDirPath = getDocumentDirectoryPath()
        let imageFilePath = tempDirPath.appendingPathComponent(imageName)
        return UIImage(contentsOfFile:imageFilePath)
    }
}
