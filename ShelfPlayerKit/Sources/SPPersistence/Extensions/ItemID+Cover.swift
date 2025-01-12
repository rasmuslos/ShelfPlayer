//
//  Cover.swift
//  
//
//  Created by Rasmus Krämer on 25.06.24.
//

import Foundation
import SPFoundation

public extension ItemIdentifier {
    var cover: URL? {
        get async {
            await cover(size: .regular)
        }
    }
    
    func cover(size: CoverSize) async -> URL? {
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
