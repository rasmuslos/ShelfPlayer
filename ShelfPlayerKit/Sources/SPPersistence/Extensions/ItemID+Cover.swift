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
    var coverURL: URL? {
        get async {
            await coverURL(size: .regular)
        }
    }
    
    func coverURL(size: CoverSize) async -> URL? {
        guard let connection = await PersistenceManager.shared.authorization[connectionID] else { return nil }
        var base = connection.host
        
        switch type {
        case .author:
            base.append(path: "api/authors/\(primaryID)/image")
        default:
            base.append(path: "api/items/\(primaryID)/cover")
        }
        
        return base.appending(queryItems: [
            .init(name: "token", value: connection.token),
            .init(name: "width", value: size.width.description),
        ])
    }
    
    var coverRequest: ImageRequest? {
        get async {
            guard let coverURL = await coverURL, let connection = await PersistenceManager.shared.authorization[connectionID] else { return nil }
            
            if coverURL.isFileURL {
                return .init(url: coverURL)
            }
            
            var request = URLRequest(url: coverURL)
            
            for header in connection.headers {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
            
            return ImageRequest(urlRequest: request)
        }
    }
    
    var data: Data? {
        get async {
            guard let coverRequest = await coverRequest else { return nil }
            
            return try? await ImagePipeline.shared.data(for: coverRequest).0
        }
    }
    
    var platformCover: Nuke.PlatformImage? {
        get async {
            guard let coverRequest = await coverRequest else { return nil }
            
            return try? await ImagePipeline.shared.image(for: coverRequest)
        }
    }
    
    
    enum CoverSize {
        case tiny
        case small
        case regular
        case large
        
        var width: Int {
            #if os(iOS)
            base
            #endif
        }
        
        private var base: Int {
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
