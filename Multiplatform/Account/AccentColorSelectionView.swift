//
//  AccentColorSelectionView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.04.24.
//

import SwiftUI
import Defaults

struct AccentColorSelectionView: View {
    var body: some View {
        List {
            Section {
                Row(tint: .shelfPlayer)
            }
            
            ForEach(TintColor.allCases.filter { $0 != .shelfPlayer }, id: \.hashValue) {
                Row(tint: $0)
            }
        }
        .navigationTitle("account.tint")
    }
    
    struct Row: View {
        @Default(.tintColor) private var tintColor
        
        let tint: AccentColorSelectionView.TintColor
        
        private var active: Bool {
            tint == tintColor
        }
        
        var body: some View {
            Button {
                Defaults[.tintColor] = tint
            } label: {
                HStack {
                    Rectangle()
                        .foregroundStyle(tint.color)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 10000))
                        .padding(.trailing, 5)
                    
                    Text(tint.title)
                    
                    Spacer()
                    
                    if active {
                        
                        Label("active", systemImage: "checkmark")
                            .labelStyle(.iconOnly)
                    }
                }
                .contentShape(.hoverMenuInteraction, Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

extension AccentColorSelectionView {
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

extension AccentColorSelectionView.TintColor {
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
    NavigationStack {
        AccentColorSelectionView()
    }
}
