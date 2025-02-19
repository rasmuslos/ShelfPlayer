//
//  AccentColorSelectionView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.04.24.
//

import SwiftUI
import Defaults

struct TintPicker: View {
    @Default(.tintColor) private var tintColor
    
    var body: some View {
        Picker("account.tint", systemImage: "circle.dashed", selection: $tintColor) {
            Row(tint: .shelfPlayer)
            
            Divider()
            
            ForEach(TintColor.allCases.filter { $0 != .shelfPlayer }) {
                Row(tint: $0)
            }
        }
    }
    
    struct Row: View {
        @Default(.tintColor) private var tintColor
        
        let tint: TintPicker.TintColor
        
        var body: some View {
            Button(tint.title, systemImage: "circle.fill") {
                Defaults[.tintColor] = tint
            }
            .buttonStyle(.plain)
            .tag(tint)
            .foregroundStyle(tint.color)
            .symbolRenderingMode(.palette)
        }
    }
    
    enum TintColor: Identifiable, Codable, Defaults.Serializable, CaseIterable {
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
        
        var id: Self { self }
        
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
        
        var accent: Color {
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
}

#Preview {
    List {
        TintPicker()
    }
}

#Preview {
    ScrollView {
        ForEach(TintPicker.TintColor.allCases, id: \.hashValue) { tint in
            HStack {
                Group {
                    Rectangle()
                        .foregroundStyle(tint.color)
                    
                    Rectangle()
                        .foregroundStyle(tint.accent)
                }
                .overlay {
                    Rectangle()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 100)
        }
    }
}
