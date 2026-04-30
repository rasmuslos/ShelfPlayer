//
//  ImageSize.swift
//  ShelfPlayerKit
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

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
            #if canImport(UIKit)
            if await UIDevice.current.userInterfaceIdiom == .pad {
                base * 2
            } else if AppSettings.shared.ultraHighQuality && !ShelfPlayerKit.isWidgetExtension {
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
