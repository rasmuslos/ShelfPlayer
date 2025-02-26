//
//  Cover.swift
//
//
//  Created by Rasmus Krämer on 25.06.24.
//

import Foundation
import SPFoundation
import Nuke

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
            #if os(iOS)
            base
            #endif
        }
        
        public var base: Int {
            switch self {
            case .tiny:
                100
            case .small:
                400
            case .regular:
                800
            case .large:
                1200
            }
        }
    }
}
