//
//  AccentColorSelectionView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayback

struct TintPicker: View {
    @Default(.tintColor) private var tintColor
    
    var body: some View {
        Picker("preferences.tint", systemImage: "circle.dashed", selection: $tintColor) {
            Row(tint: .shelfPlayer)
            
            Divider()
            
            ForEach(TintColor.allCases.filter { $0 != .shelfPlayer }) {
                Row(tint: $0)
            }
        }
    }
    
    struct Row: View {
        @Default(.tintColor) private var tintColor
        
        let tint: TintColor
        
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
}

#Preview {
    List {
        TintPicker()
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
