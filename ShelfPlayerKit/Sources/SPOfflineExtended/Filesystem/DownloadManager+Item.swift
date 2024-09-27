//
//  OfflineManager+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SPFoundation
import SPNetwork

// MARK: Image

internal extension DownloadManager {
    func download(cover: Cover?, itemId: String) async throws {
        if let data = await cover?.data {
            let destination = imageURL(identifiedBy: itemId)
            
            try? FileManager.default.removeItem(at: destination)
            FileManager.default.createFile(atPath: destination.path, contents: data)
        }
    }

    
    func deleteImage(identifiedBy itemId: String) throws {
        try FileManager.default.removeItem(at: imageURL(identifiedBy: itemId))
    }
    
    func imageURL(identifiedBy itemId: String) -> URL {
        documentsURL.appending(path: "images").appending(path: "\(itemId).png")
    }
}

public extension DownloadManager {
    func isDownloaded(itemID: String) -> Bool {
        FileManager.default.fileExists(atPath: imageURL(identifiedBy: itemID).path)
    }
}
