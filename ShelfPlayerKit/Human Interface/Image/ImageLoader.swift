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
    let cachePath: URL?
    let cache: URLCache
    let session: URLSession
    
    var pending = Set<ImageRequest>()
    var missing = Set<ImageRequest>()
    
    init() {
        if ShelfPlayerKit.enableCentralized {
            cachePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ShelfPlayerKit.groupContainer)?.appending(path: "ImageCache")
        } else {
            cachePath = URL.userDirectory.appending(path: "ShelfPlayer").appending(path: "ImageCache")
        }
        
        // 512 MiB & 6 GiB
        cache = .init(memoryCapacity: 536_870_912, diskCapacity: 6_442_450_944, directory: cachePath)
        
        let configuration = URLSessionConfiguration.ephemeral
        
        configuration.httpCookieStorage = ShelfPlayerKit.httpCookieStorage
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .onlyFromMainDocumentDomain
        
        configuration.timeoutIntervalForRequest = 120
        configuration.waitsForConnectivity = true
        
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = cache
        
        session = URLSession(configuration: configuration, delegate: APIClient.URLSessionDelegate(), delegateQueue: nil)
        session.sessionDescription = "ShelfPlayer ImageLoader"
    }
    
    public var currentDiskUsage: Int {
        return cache.currentDiskUsage
    }
    
    nonisolated func buildURLRequest(for request: ImageRequest) async -> URLRequest? {
        if let url = await PersistenceManager.shared.download.cover(for: request.itemID, size: request.size) {
            return .init(url: url)
        }
        
        if var request = try? await ABSClient[request.itemID.connectionID].coverRequest(from: request.itemID, width: request.size.width) {
            request.cachePolicy = .returnCacheDataElseLoad
            return request
        }
        
        return nil
    }
    
    func data(for request: ImageRequest) async throws -> Data {
        if missing.contains(request) {
            throw ImageLoadError.missing
        }
        
        while pending.contains(request) {
            try await Task.sleep(for: .seconds(0.14))
        }
        
        pending.insert(request)
        
        do {
            guard let urlRequest = await buildURLRequest(for: request) else {
                throw ImageLoadError.missingURLRequest
            }
            
            let (data, _) = try await session.data(for: urlRequest)
            pending.remove(request)
            
            return data
        } catch {
            pending.remove(request)
            missing.insert(request)
            
            throw error
        }
    }
    
    nonisolated func platformImage(for request: ImageRequest) async -> PlatformImage? {
        guard let data = try? await data(for: request) else {
            return nil
        }
        
        return UIImage(data: data)
    }
    
    public func purge() {
        cache.removeAllCachedResponses()
    }
    public nonisolated func purge(itemID: ItemIdentifier) async {
        for size in ImageSize.allCases {
            let request = ImageRequest(itemID: itemID, size: size)
            
            guard let urlRequest = await buildURLRequest(for: request) else {
                continue
            }
            
            cache.removeCachedResponse(for: urlRequest)
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
            } else {
                base
            }
            #endif
        }
    }
    
    public var base: Int {
        switch self {
            case .tiny:
                160
            case .small:
                220
            case .regular:
                400
            case .large:
                720
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
