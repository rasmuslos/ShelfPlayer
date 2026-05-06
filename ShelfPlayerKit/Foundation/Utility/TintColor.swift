//
//  TintColor.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 01.06.25.
//

import Foundation
import SwiftUI

public enum TintColor: Identifiable, Codable, CaseIterable, Sendable {
    case shelfPlayer

    case yellow
    case red
    case purple
    case violet
    case blue
    case aqua
    case mint
    case green
    case black

    public var id: Self { self }

    private static let shelfPlayerBrandColor: Color = {
        #if DEBUG
        Color("ShelfPlayer Development")
        #else
        Color("ShelfPlayer")
        #endif
    }()

    public var color: Color {
        switch self {
        case .shelfPlayer:
            Self.shelfPlayerBrandColor
        case .yellow:
                .yellow
        case .purple:
                .purple
        case .red:
                .red
        case .violet:
                .indigo
        case .blue:
                .blue
        case .aqua:
                .cyan
        case .green:
                .green
        case .mint:
                .mint
        case .black:
                .black
        }
    }

    public var accent: Color {
        switch self {
        case .shelfPlayer:
                .orange
        case .yellow:
                .orange
        case .red:
                .yellow
        case .purple:
                .blue
        case .violet:
                .blue
        case .blue:
                .purple
        case .aqua:
                .orange
        case .mint:
                .blue
        case .green:
                .blue
        case .black:
                .gray
        }
    }
}
