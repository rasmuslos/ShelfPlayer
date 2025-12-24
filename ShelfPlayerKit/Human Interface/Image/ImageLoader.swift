//
//  ImageLoader.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 10.07.25.
//

import Foundation

#if canImport(UIKit)
import UIKit

public typealias PlatformImage = UIImage
#endif

public final actor ImageLoader {
    let cachePath = ShelfPlayerKit.cacheDirectoryURL.appending(path: "Images")
    
    var missing = Set<ImageRequest>()
    
    func data(for request: ImageRequest) async throws -> Data {
        if missing.contains(request) {
            throw ImageLoadError.missing
        }
        
        throw ImageLoadError.missingURLRequest
    }
    
    nonisolated func platformImage(for request: ImageRequest) async -> PlatformImage? {
        guard let data = try? await data(for: request) else {
            return nil
        }
        
        return UIImage(data: data)
    }
    
    public func purge() {
        
    }
    public nonisolated func purge(itemID: ItemIdentifier) async {
        for size in ImageSize.allCases {
            
        }
    }
    
    public static let shared = ImageLoader()
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

public enum ImageSize: Int, Identifiable, Equatable, Codable, Sendable, CaseIterable {
    case tiny
    case small
    case regular
    case large
    
    public var id: Int {
        rawValue
    }
    
    var width: Int {
        get async {
            #if os(iOS)
            if await UIDevice.current.userInterfaceIdiom == .pad {
                base * 2
            } else if Defaults[.ultraHighQuality] {
                base * 2
            } else {
                base
            }
            #endif
        }
    }
    
    public var base: Int {
        switch self {
            case .tiny:
                220
            case .small:
                320
            case .regular:
                600
            case .large:
                1000
        }
    }
}

enum ImageLoadError: Error {
    case missingURLRequest
    case missing
}

public extension ItemIdentifier {
    func data(size: ImageSize) async -> Data? {
        try? await ImageLoader.shared.data(for: .init(itemID: self, size: size))
    }
    func platformImage(size: ImageSize) async -> PlatformImage? {
        await ImageLoader.shared.platformImage(for: .init(itemID: self, size: size))
    }
}
