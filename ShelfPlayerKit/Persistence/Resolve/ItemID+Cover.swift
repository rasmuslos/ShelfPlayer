//
//  Cover.swift
//
//
//  Created by Rasmus Krämer on 25.06.24.
//

import Foundation
import Nuke

#if canImport(UIKit)
import UIKit
#endif

public extension ItemIdentifier {
    func coverRequest(size: CoverSize) async -> ImageRequest? {
        if let downloaded = await PersistenceManager.shared.download.cover(for: self, size: size) {
            return ImageRequest(url: downloaded)
        }
        
        if let urlRequest = try? await ABSClient[connectionID].coverRequest(from: self, width: size.width) {
            return ImageRequest(urlRequest: urlRequest)
        }
        
        return nil
    }
    
    func data(size: CoverSize) async -> Data? {
        guard let coverRequest = await coverRequest(size: size) else {
            return nil
        }
        
        return try? await ImagePipeline.shared.data(for: coverRequest).0
    }
    
    func platformCover(size: CoverSize) async -> Nuke.PlatformImage? {
        guard let coverRequest = await coverRequest(size: size) else {
            return nil
        }
        
        return try? await ImagePipeline.shared.image(for: coverRequest)
    }
    
    enum CoverSize: Int, Identifiable, Equatable, Codable, Sendable, CaseIterable {
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
}
