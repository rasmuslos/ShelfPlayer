//
//  Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import UIImageColors
import SwiftUI

public class Item: Identifiable {
    public let id: String
    public let libraryId: String
    
    public let name: String
    public let author: String?
    
    public let description: String?
    
    public let image: Image?
    public let genres: [String]
    
    public let addedAt: Date
    public let released: String?
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Image?, genres: [String], addedAt: Date, released: String?) {
        self.id = id
        self.libraryId = libraryId
        self.name = name
        self.author = author
        self.description = description
        self.image = image
        self.genres = genres
        self.addedAt = addedAt
        self.released = released
    }
}

public extension Item {
    var sortName: String {
        get {
            var sortName = name.lowercased()
            
            if sortName.starts(with: "a ") {
                sortName = String(sortName.dropFirst(2))
            }
            if sortName.starts(with: "the ") {
                sortName = String(sortName.dropFirst(4))
            }
            
            return sortName
        }
    }
}

extension Item: Equatable {
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

extension Item: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension Item {
    struct Image: Codable {
        public let url: URL
        public let type: ImageType
        
        public init(url: URL, type: ImageType) {
            self.url = url
            self.type = type
        }
        
        public enum ImageType: Codable {
            case local
            case audiobookshelf
            case remote
        }
    }
}

public extension Item {
    func getImageColors() -> ImageColors {
        if let image = self.image, let data = try? Data(contentsOf: image.url) {
            let image = UIImage(data: data)
            
            if let colors = image?.getColors(quality: .low) {
                let background = Color(colors.background)
                
                return .init(
                    primary: Color(colors.primary),
                    secondary: Color(colors.secondary),
                    detail: Color(colors.detail),
                    background: background,
                    isLight: background.isLight())
            }
        }
        
        return .placeholder
    }
    
    struct ImageColors: Equatable {
        public let primary: Color
        public let secondary: Color
        public let detail: Color
        public let background: Color
        
        public let isLight: Bool
        
        public static let placeholder = ImageColors(primary: .primary, secondary: .secondary, detail: .accentColor, background: .gray.opacity(0.25), isLight: true)
    }
}
