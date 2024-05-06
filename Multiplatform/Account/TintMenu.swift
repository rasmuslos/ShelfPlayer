//
//  AccentColorSelectionView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.04.24.
//

import SwiftUI
import Defaults

struct TintMenu: View {
    var body: some View {
        Menu {
            Row(tint: .shelfPlayer)
            
            Divider()
            
            ForEach(TintColor.allCases.filter { $0 != .shelfPlayer }, id: \.hashValue) {
                Row(tint: $0)
            }
        } label: {
            Label("account.tint", systemImage: "circle.dashed")
        }
    }
    
    struct Row: View {
        @Default(.tintColor) private var tintColor
        
        let tint: TintMenu.TintColor
        
        private var active: Bool {
            tint == tintColor
        }
        
        var body: some View {
            Button {
                Defaults[.tintColor] = tint
            } label: {
                Label(tint.title, systemImage: active ? "checkmark" : "circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(tint.color)
            }
            .buttonStyle(.plain)
        }
    }
}

extension TintMenu {
    enum TintColor: CaseIterable, Codable, _DefaultsSerializable {
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
    }
}

extension TintMenu.TintColor {
    var title: LocalizedStringKey {
        switch self {
            case .shelfPlayer:
                "account.tint.shelfPlayer"
            case .yellow:
                "account.tint.yellow"
            case .purple:
                "account.tint.purple"
            case .red:
                "account.tint.red"
            case .violet:
                "account.tint.violet"
            case .blue:
                "account.tint.blue"
            case .aqua:
                "account.tint.aqua"
            case .green:
                "account.tint.green"
            case .mint:
                "account.tint.mint"
            case .black:
                "account.tint.black"
        }
    }
    
    var color: Color {
        switch self {
            case .shelfPlayer:
                    .accent
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
}

#Preview {
    List {
        TintMenu()
    }
}
