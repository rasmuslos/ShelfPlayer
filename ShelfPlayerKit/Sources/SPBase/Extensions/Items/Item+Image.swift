//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 04.02.24.
//

import Foundation
import SwiftUI

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
