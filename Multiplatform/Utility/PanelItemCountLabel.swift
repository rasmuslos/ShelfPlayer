//
//  PanelItemCountLabel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 10.01.26.
//

import SwiftUI
import ShelfPlayback

struct PanelItemCountLabel: View {
    let total: Int
    
    var type: ItemIdentifier.ItemType? = nil
    var isLoading = false
    
    var label: LocalizedStringKey {
        switch type {
            case .episode: "item.count.episodes \(total)"
            case .audiobook: "item.count.audiobooks \(total)"
            default: "item.count \(total)"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.4)
                    .transition(.opacity)
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 20))
        .padding(.vertical, 16)
        .animation(.smooth, value: isLoading)
    }
}

#Preview {
    @Previewable @State var isLoading = true
    
    PanelItemCountLabel(total: 67, type: .none, isLoading: isLoading)
        .onTapGesture {
            isLoading.toggle()
        }
}
