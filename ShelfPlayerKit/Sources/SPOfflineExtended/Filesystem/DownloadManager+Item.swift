//
//  OfflineManager+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SPBase

// MARK: Image

extension DownloadManager {
    func downloadImage(itemId: String, image: Item.Image?) async throws {
        if let image = image {
            let request = URLRequest(url: image.url)
            
            let (location, _) = try await URLSession.shared.download(for: request)
            var destination = getImageUrl(itemId: itemId)
            try? destination.setResourceValues({
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                
                return values
            }())
            
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
        }
    }
    
    func deleteImage(itemId: String) throws {
        try FileManager.default.removeItem(at: getImageUrl(itemId: itemId))
    }
    
    func getImageUrl(itemId: String) -> URL {
        documentsURL.appending(path: "images").appending(path: "\(itemId).png")
    }
}
