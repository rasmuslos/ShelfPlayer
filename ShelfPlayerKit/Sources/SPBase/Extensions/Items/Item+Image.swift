//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 04.02.24.
//

import Foundation
import SwiftUI
import UIImageColors

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
                var primary = ImageColors.placeholder.primary
                var secondary = ImageColors.placeholder.secondary
                var detail = ImageColors.placeholder.detail
                
                let background = Color(colors.background)
                
                if let uiPrimary = colors.primary {
                    primary = Color(uiPrimary)
                }
                if let uiSecondary = colors.secondary {
                    secondary = Color(uiSecondary)
                }
                if let uiDetail = colors.detail {
                    detail = Color(uiDetail)
                }
                
                return .init(
                    primary: primary,
                    secondary: secondary,
                    detail: detail,
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
