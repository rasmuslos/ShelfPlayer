//
//  ImageLoader.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 10.07.25.
//

import Foundation
import OSLog

#if canImport(UIKit)
import UIKit

public typealias PlatformImage = UIImage
#endif

public final actor ImageLoader {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ImageLoader")
    let cachePath = ShelfPlayerKit.cacheDirectoryURL.appending(path: "Images")
    
    var cached = [ImageRequest: Task<Data, Error>]()
    
    func data(for request: ImageRequest) async throws -> Data {
        if cached[request] == nil {
            cached[request] = .init {
                let cacheURL = await cacheURL(for: request)
                
                if FileManager.default.fileExists(atPath: cacheURL.relativePath), let data = try? Data(contentsOf: cacheURL) {
                    return data
                }
                
                let result: Data
                
                if let url = await PersistenceManager.shared.download.cover(for: request.itemID, size: request.size), let data = try? Data(contentsOf: url) {
                    result = data
                } else {
                    result = try await ABSClient[request.itemID.connectionID].cover(from: request.itemID, width: request.size.width)
                }
                
                do {
                    try FileManager.default.createDirectory(at: directoryURL(for: request), withIntermediateDirectories: true)
                    try result.write(to: cacheURL)
                } catch {
                    logger.error("Failed to cache image: \(error)")
                }
                
                return result
            }
        }
        
        return try await cached[request]!.value
    }
    
    nonisolated func platformImage(for request: ImageRequest) async -> PlatformImage? {
        guard let data = try? await data(for: request) else {
            return nil
        }
        
        return UIImage(data: data)
    }
}

public extension ImageLoader {
    static let shared = ImageLoader()
    
    func purge() {
        do {
            try FileManager.default.removeItem(at: cachePath)
        } catch {
            logger.error("Failed to purge image cache: \(error)")
        }
    }
    func purge(itemID: ItemIdentifier) async {
        for size in ImageSize.allCases {
            let request = ImageRequest(itemID: itemID, size: size)
            cached[request] = nil
            
            do {
                try await FileManager.default.removeItem(at: cacheURL(for: request))
            } catch {
                logger.error("Failed to remove cached item: \(error)")
            }
        }
    }
}

private extension ImageLoader {
    func directoryURL(for request: ImageRequest) -> URL {
        cachePath
            .appending(path: request.itemID.connectionID)
            .appending(path: request.itemID.libraryID)
            .appending(path: "\(request.itemID.primaryID)_\(request.itemID.groupingID ?? "-")")
    }
    func cacheURL(for request: ImageRequest) async -> URL {
        await directoryURL(for: request)
            .appending(path: "\(request.size.width)")
    }
}

public final class ImageRequest: Sendable, Hashable {
    let itemID: ItemIdentifier
    let size: ImageSize
    
    init(itemID: ItemIdentifier, size: ImageSize) {
        self.itemID = itemID
        self.size = size
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(itemID)
        hasher.combine(size)
    }
    
    public static func == (lhs: ImageRequest, rhs: ImageRequest) -> Bool {
        lhs.itemID == rhs.itemID && lhs.size == rhs.size
    }
}

public extension ItemIdentifier {
    func data(size: ImageSize) async -> Data? {
        try? await ImageLoader.shared.data(for: .init(itemID: self, size: size))
    }
    func platformImage(size: ImageSize) async -> PlatformImage? {
        await ImageLoader.shared.platformImage(for: .init(itemID: self, size: size))
    }
}
