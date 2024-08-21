//
//  OfflineManager+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SPFoundation

// MARK: Image

internal extension DownloadManager {
    func download(cover: Cover?, itemId: String) async throws {
        if let cover = cover {
            let request = URLRequest(url: cover.url)
            
            let (location, _) = try await URLSession.shared.download(for: request)
            var destination = imageURL(identifiedBy: itemId)
            
            try? destination.setResourceValues({
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                
                return values
            }())
            
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
        }
    }
    
    func deleteImage(identifiedBy itemId: String) throws {
        try FileManager.default.removeItem(at: imageURL(identifiedBy: itemId))
    }
    
    func imageURL(identifiedBy itemId: String) -> URL {
        documentsURL.appending(path: "images").appending(path: "\(itemId).png")
    }
}
