//
//  AccentColorSelectionView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.04.24.
//

import SwiftUI
import ShelfPlayback

struct TintPicker<Label: View>: View {
    @Default(.tintColor) private var tintColor
    
    let buildLabel: (_ : LocalizedStringKey, _ : String) -> Label
    
    var body: some View {
        Picker(selection: $tintColor) {
            Row(tint: .shelfPlayer, labelStyle: .titleOnly)
            
            Divider()
            
            ForEach(TintColor.allCases.filter { $0 != .shelfPlayer }) {
                Row(tint: $0, labelStyle: .titleOnly)
            }
        } label: {
            buildLabel("preferences.tint", "circle.dashed")
        }
    }
    
    struct Row<S: LabelStyle>: View {
        @Default(.tintColor) private var tintColor
        
        let tint: TintColor
        let labelStyle: S
        
        var body: some View {
            Button(tint.title, systemImage: "circle.fill") {
                Defaults[.tintColor] = tint
            }
            .buttonStyle(.plain)
            .labelStyle(labelStyle)
            .tag(tint)
            .foregroundStyle(tint.color)
            .symbolRenderingMode(.palette)
        }
    }
}

extension TintColor {
    var title: LocalizedStringKey {
        switch self {
            case .shelfPlayer:
                "preferences.tint.shelfPlayer"
            case .yellow:
                "preferences.tint.yellow"
            case .purple:
                "preferences.tint.purple"
            case .red:
                "preferences.tint.red"
            case .violet:
                "preferences.tint.violet"
            case .blue:
                "preferences.tint.blue"
            case .aqua:
                "preferences.tint.aqua"
            case .green:
                "preferences.tint.green"
            case .mint:
                "preferences.tint.mint"
            case .black:
                "preferences.tint.black"
        }
    }
}

#Preview {
    List {
        TintPicker {
            Label($0, systemImage: $1)
        }
    }
}

#Preview {
    ScrollView {
        ForEach(TintColor.allCases, id: \.hashValue) { tint in
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
